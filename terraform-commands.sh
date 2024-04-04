set -o nounset -o errexit
# Debian's default shell (dash) doesn't support pipefail
if set -o | grep pipefail>/dev/null; then
  set -o pipefail
fi

case "$(uname -s)" in
    Darwin*)  export SCRIPTDIR="$( cd "$( dirname "${0}" )" && pwd -P)";;
    *)        export SCRIPTDIR="$(dirname $(readlink -f "$0"))"
esac

# Be careful to do not run apply command with existing old(obsolete) plan
[ -n "${PLAN_FILE-}" ] || export PLAN_FILE=terraform.plan.${TF_WORKSPACE}
[ -n "${APPLY_FILE-}" ] || export APPLY_FILE=terraform.apply.${TF_WORKSPACE}

echo "TF_PLUGIN_CACHE_DIR=${TF_PLUGIN_CACHE_DIR-}"
# find ${TF_PLUGIN_CACHE_DIR} || true
echo "TF_IN_AUTOMATION=${TF_IN_AUTOMATION-}"
echo "TARGET=${TARGET-}"

echo "Intermediate time: $(date)"
# Using one of well-known apps to automatically switch to required Terraform version.
tfswitch || true

ls -la $(which terraform)
terraform version
# terraform workspace select default || true
# terraform providers || true

# Additional Terraform environment variables: https://www.terraform.io/docs/commands/environment-variables.html
# TF_IN_AUTOMATION  https://www.terraform.io/docs/commands/environment-variables.html

##
## INIT
##
# Local caching is supported by using TF_PLUGIN_CACHE_DIR environment variable defined outside. See https://www.terraform.io/docs/configuration/providers.html#provider-plugin-cache
# - When possible, Terraform will use hardlinks or symlinks to avoid storing a separate copy of a cached plugin
# - The plugin cache directory must not be the third-party plugin directory or any other directory Terraform searches for pre-installed plugins
# - Terraform will never itself delete a plugin from the plugin cache. Unused versions which must be manually deleted.
##
# Reconfigure option will drop any current setups, which get in the way of switching workspaces between accounts. A little bit better than deleting files and folders manually.
export TF_VAR_TF_STATE_BUCKET_NAME="${TF_STATE_BUCKET_NAME}"
echo "Intermediate time: $(date)"
if [ "_${CUSTOM_TF_USE_LOCAL_BACKEND-}" == "_true" ]; then
  echo "Using local backend"
  terraform init ${TF_IN_AUTOMATION:+-input=false} \
    ${TF_INIT_UPGRADE:+-upgrade} \
    -reconfigure
    # \
    #${CUSTOM_TF_PLUGIN_DIR:+-plugin-dir=}${CUSTOM_TF_PLUGIN_DIR-} \
    #${CUSTOM_TF_PLUGIN_DIR:+-get-plugins=true}
else
  echo "Using remote backend"
  echo "TF_STATE_BUCKET_NAME=${TF_STATE_BUCKET_NAME}"
  echo "TF_STATE_BACKEND_KEY=${TF_STATE_BACKEND_KEY}"
  echo "TF_STATE_BACKEND_REGION=${TF_STATE_BACKEND_REGION}"

  # ${VAR_BACKEND_FILE:+--backend-config=}${VAR_BACKEND_FILE-}
  terraform init ${TF_IN_AUTOMATION:+-input=false} \
    ${TF_INIT_UPGRADE:+-upgrade} \
    -reconfigure \
    -backend-config="bucket=${TF_STATE_BUCKET_NAME}"\
    -backend-config="key=${TF_STATE_BACKEND_KEY}"\
    -backend-config="region=${TF_STATE_BACKEND_REGION}"
    # ${CUSTOM_TF_PLUGIN_DIR:+-plugin-dir=}${CUSTOM_TF_PLUGIN_DIR-} \
    # ${CUSTOM_TF_PLUGIN_DIR:+-get-plugins=true} \
fi

##
## WORKSPACE SELECTION
##
# echo "Intermediate time: $(date)"
# CUR_WORKSPACE=$(terraform workspace show)
# if [ "_${CUR_WORKSPACE}" != "_${TF_WORKSPACE}" ]; then
#   terraform workspace list | grep ${TF_WORKSPACE}\
#     && terraform workspace select ${TF_WORKSPACE}\
#     || terraform workspace new ${TF_WORKSPACE}
# fi

echo "Intermediate time: $(date)"
# Usage of this command requires modules to be initialized
terraform providers || true

# A quick exit when only init of S3 state is needed. For example to upgrade provider versions without commenting out anything in files.
if [ "_${ONLY_INIT-}" == "_true" ]; then exit 0; fi

# terraform state rm module.acm.aws_acm_certificate.default
#terraform import 'aws_s3_bucket.remote_state' act-remote-state-contentsearch-prod

# Terraform 0.12 to 0.13 upgrade for messages like "Failed to instantiate provider "registry.terraform.io/-/aws" to obtain schema"
# It's safe to re-run, you'll see "No matching resources found." messages
# Terraform will write backup of the state file to a file with a ".backup" extension by default. This behavior can't be disabled.
# terraform state replace-provider -auto-approve registry.terraform.io/-/archive  registry.terraform.io/hashicorp/archive || true
# terraform state replace-provider -auto-approve registry.terraform.io/-/null  registry.terraform.io/hashicorp/null || true
# terraform state replace-provider -auto-approve registry.terraform.io/-/template  registry.terraform.io/hashicorp/template || true
# terraform state replace-provider -auto-approve registry.terraform.io/-/aws  registry.terraform.io/hashicorp/aws || true

##
## Plan
##
echo "Intermediate time: $(date)"

if [ "_${CREATE_NEW_PLAN-}" != "_false" ]; then
  terraform plan ${TF_IN_AUTOMATION:+-input=false} \
    ${TARGET:+-target=}${TARGET-} \
    ${VAR_FILE:+-var-file=}${VAR_FILE-} \
    ${DESTROY:+--destroy} \
    -out=${PLAN_FILE} 2>&1 | tee "${PLAN_FILE}.log"
  # cat "${PLAN_FILE}.${TF_WORKSPACE}.log" | sed $'s/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' > "${PLAN_FILE}.${TF_WORKSPACE}.colorless.log"
fi

## 
## Refresh only
## 
if [ "_${REFRESH-}" == "_true" ]; then
  if [ "_${DRYRUN-}" == "_false" ]; then
    echo "Intermediate time: $(date)"
    terraform apply -refresh-only ${TF_IN_AUTOMATION:+-input=false} \
    ${VAR_FILE:+-var-file=}${VAR_FILE-}
  else
    echo "DRYRUN needs to be disabled to complete state refresh"
  fi
fi

##
## Apply or destroy
##
echo "Intermediate time: $(date)"
if [ "_${DRY_RUN-}" == "_false" ]; then
  if [ "_${DESTROY-}" == "_true" ]; then
    TF_WARN_OUTPUT_ERRORS=1 terraform destroy \
      ${VAR_FILE:+-var-file=}${VAR_FILE-} \
      -auto-approve | tee "${APPLY_FILE}.log"
  else
    terraform apply ${TF_IN_AUTOMATION:+-input=false} \
    ${TARGET:+-target=}${TARGET-} \
    ${PLAN_FILE} 2>&1 | tee "${APPLY_FILE}.log"
  fi
  if [ "_${CI-}" != "_true" ]; then
    terraform output -no-color -json > "./terraform.output.${TF_WORKSPACE}.log"
  fi
else
  echo DRY_RUN is enabled. Skippling apply stage
  if [ "_${CI-}" != "_true" ]; then
    terraform output -no-color -json > "./terraform.output.${TF_WORKSPACE}.log" || echo "Output might be not available before first apply."
  fi
fi

echo "Intermediate time: $(date)"
echo "End of script ${0}"
