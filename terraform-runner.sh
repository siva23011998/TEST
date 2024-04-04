set -o nounset -o errexit
# Debian's default shell (dash) doesn't support pipefail
if set -o | grep pipefail>/dev/null; then
  set -o pipefail
fi
case "$(uname -s)" in
    Darwin*)  export SCRIPTDIR="$( cd "$( dirname "${0}" )" && pwd -P)";;
    *)        export SCRIPTDIR="$(dirname $(readlink -f "$0"))"
esac

if [ "${environment-}" == "" ]; then
  echo "Error: 'environment' environment variable is not set!"
  exit 1
fi
echo "Environment: ${environment}"
echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION-}"
echo "CI: ${CI-}"

# Experience in Github Actions runners is inconsistent with caching. Let's observe without it.
if [ "_${CI-}" != "_true" ]; then
  # Location to store Terraform plugin binaries. This is useful locally to reduce duplicates.
  [ -z "${TF_PLUGIN_CACHE_DIR-}_" ] || export TF_PLUGIN_CACHE_DIR=~/terrraform.plugin.cache
  mkdir -p ${TF_PLUGIN_CACHE_DIR}
  ls -la ${TF_PLUGIN_CACHE_DIR}
  find ${TF_PLUGIN_CACHE_DIR}
else
  unset TF_PLUGIN_CACHE_DIR
fi

# BACKEND_KEY should be the same for all environments for Workspaces to work seamlessly
# If you add -${environment} prefix to it, Terraform will ask to migrate state

echo "desired TF_WORKSPACE: ${TF_WORKSPACE}"

# Output of current credentials for debugging
if ! AWS_PAGER="" aws sts get-caller-identity; then
  echo "Please check that you supply proper AWS credentials and that you actually have them configured and available at the run time."
  exit 1
fi

if ls tf*.log>/dev/null 2>&1; then
  rm tf*.log
fi

# A command similar to next one could be put after terraform init to remove a stubborn resource which got removed somehow, but Terraform can't deal with it
# terraform state rm module.cluster_internal2.aws_launch_configuration.default
# terraform state rm module.nonprod-ecs.aws_ecs_cluster.ecs-cluster
# terraform import module.nonprod-ecs.aws_ecs_cluster.ecs-cluster ade-widgets-nonprod

# CircleCI has environment variables CI=true and CIRCLECI=true
# TF_IN_AUTOMATION disables some output which doesn't make sense in non-interactive environment like CI/CD
[ "_${CI-}" != "_true" ] || export TF_IN_AUTOMATION=true

EXECUTE_COMMAND="cd ${EXEC_DIR_ON_TF} && source ${SCRIPTDIR}/terraform-commands.sh"

DOCKER_NEEDED=false
if [ -n "${TF_VERSION-}" ] && terraform --version 2>/dev/null | grep 'Terraform v' | grep "${TF_VERSION}"; then
  echo "Found exact version ${TF_VERSION} in PATH"
elif which tfswitch; then
  # https://tfswitch.warrensbox.com
  # It will install maximum version according to constraint in `versions.tf` file. to /usr/local/bin/terraform -> ~/.terraform.versions/terraform_0.12.28
  echo "Using tfswitch"
  cd "${EXEC_DIR_ON_TF}" && tfswitch && cd "${SCRIPTDIR}"
elif which tfenv; then
  # https://github.com/tfutils/tfenv
  echo "Using tfenv. WARNING - this might change current version of TF"
  echo "And it probably will break something when multiple terraform CLI are executed in parallel."
  # How it works: /usr/local/bin/terraform -> ../Cellar/tfenv/2.1.0/bin/terraform
  if ! tfenv list | grep "${TF_VERSION}"; then
    echo "Installing Terraform ${TF_VERSION}"
    tfenv install "${TF_VERSION}"
  fi
  cd "${EXEC_DIR_ON_TF}" && tfenv use "${TF_VERSION}" && cd "${SCRIPTDIR}"
# asdf seems to throw errors about shell integration
# elif which asdf; then
#   echo "Using asdf"
#   cd "${EXEC_DIR_ON_TF}"
#   asdf plugin add terraform || true
#   asdf install terraform ${TF_VERSION}
#   asdf shell terraform ${TF_VERSION}
#   asdf current
#   cd "${SCRIPTDIR}"
else
  DOCKER_NEEDED=true
fi

# Output log path when TF_LOG is set. If set earlier, test for `terraform --version` will dump stuff at the root.
export TF_LOG_PATH="terraform.trace.${TF_WORKSPACE}.log"

if [ "${DOCKER_NEEDED}" == "false" ]; then
  pwd
  eval "${EXECUTE_COMMAND}"
else
  echo "Assuming execution in non-CI environment, such as local machine"
  echo "Using docker"

  [ -t 1 ] && TERMOPT=-t

  # Current user ID on Mac is 1000, releaseman in Jenkins is 5000.
  # Correct user Id should be used for using mounted .ssh folder which usually has mode 700
  dockerUser=$(id -u)
  # [ ${dockerUser} == 5000 ] || dockerUser=1000
  [ ${dockerUser} == 5000 ] || dockerUser=root
  if [ "${dockerUser}" == "root" ]; then
    HOME_DIR="/${dockerUser}"
  else
    HOME_DIR="/home/${dockerUser}"
  fi

  # 50 works for Mac(authedusers), where by default there is no docker user
  # It could be 127 in Ubuntu inside VirtualBox
  dockerGroup=$(cat /etc/group | grep docker | cut -d: -f3) || dockerGroup=50

  # This is needed to avoid SSL issues with ZScaler inside the Terraform docker container:
  #   -v "/etc/ssl/":"/etc/ssl/" \

  # What is ssh is needed for?
  # -v ~/.ssh:"${HOME_DIR}/.ssh:ro" \

  # /bin/sh used as the entrypoint here is mostly ok since we're using base images which didn't give any issues so far.
  docker run --rm -i ${TERMOPT-} -u ${dockerUser}:`id -g $USER` --group-add ${dockerGroup} \
    -v "${WORKDIR_ON_TF}":"/workdir" -w "/workdir" \
    -v "/etc/ssl/":"/etc/ssl/:ro" \
    -v ~/.ssh:"${HOME_DIR}/.ssh:ro" \
    -v "${SCRIPTDIR}":"${SCRIPTDIR}:ro" \
    -v "${TF_PLUGIN_CACHE_DIR}:${TF_PLUGIN_CACHE_DIR}" \
    --env CUSTOM_TF_USE_LOCAL_BACKEND \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_DEFAULT_REGION \
    --env AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN \
    --env TF_VAR_application \
    --env TF_VAR_platform \
    --env TF_VAR_runteam \
    --env TF_VAR_NR_API_KEY \
    --env TF_VAR_NR_ACCOUNT_ID \
    --env TF_VAR_aws_account \
    --env TF_IN_AUTOMATION \
    --env TF_LOG \
    --env TF_STATE_BUCKET_NAME \
    --env TF_STATE_BACKEND_KEY \
    --env TF_STATE_BACKEND_REGION \
    --env TF_PLUGIN_CACHE_DIR \
    --env DRY_RUN \
    --env TARGET \
    --env VAR_FILE \
    --env DESTROY \
    --env TF_WORKSPACE \
    --entrypoint /bin/sh \
    ${TF_IMAGE} \
    -c "set -o nounset -o pipefail -o errexit && ${EXECUTE_COMMAND}"
fi
date
