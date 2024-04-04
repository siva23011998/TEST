#-------------------------------------------------------------------------------
# Running `make` will show the list of subcommands that will run.

all: help

.PHONY: help
## help: prints this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

#-------------------------------------------------------------------------------
# Variables

export AWS_DEFAULT_REGION ?= us-east-1
# Directories (including current and all subdirectories) having terraform('*.tf') files
TF_DIRS := ${shell find . -name '*.tf' | ( grep -v '.terraform' | grep -v '.git' | grep -v 'skip' || true) | xargs -I{} dirname {} | sort -r | uniq}
# Terraform directories having different state file
TF_TOP_DIRS=init shared SDLC monitoring-observability

export MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
export MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))

# Path to cache terraform plugin versions, which is used by TF_PLUGIN_CACHE_DIR environment variable.
export SRC_PLUGIN_CACHE_DIR ?= $$HOME/terraform.plugin.cache
#mkdir -p "${SRC_PLUGIN_CACHE_DIR}"
# Folder containing terraform binary versions, used by `tfswitch` tool
export SRC_TFSWITCH_LINUX_CACHE ?= $$HOME/.terraform.versions.linux
#mkdir -p "${SRC_TFSWITCH_LINUX_CACHE}"
export DEFAULT_PROFILE ?= aam-svc
export BUILD_TOOLS_VERSION ?= latest

# Default TF version to use if it's not defined in versions.tf
export TF_VERSION ?= 1.5.7

# Enable fix flags for linters only if NO_FIX variable is not set to true (as in CI/CD)
ifeq ($(NO_FIX),true)
export FMT_FLAGS = --check -diff
else
export MARKDOWNLINT_FIX = --fix
endif

# WARNING! After adding any variable above, add it to the pass-through variables in the recipie for docker_%
#  at the bottom of this file.

#-------------------------------------------------------------------------------
# Documentation

# The script makes a few replacements in the README.md file based on tokens.
# `awk -v <var_name> ... gsub ...` makes a replacement on one line. This works for simple and short replacements.
# `node -e ... replace ...` makes a multi-line replacement. This is useful for big chunks of data, such as input/output documentation.
# `terraform-docs` against the *.tf files in the current directory. Outputs a Markdown-formatted table with some quirks.
#  - Quirk #1 is that all underscores are prefixed with a back-slash. Use `sed` to remove the back-slashes.
#  - Quirk #2 is that the input/output variable names should be formatted as "code". Use `sed` and some PCRE regexes to parse the
#			 first table column (starts with a vertical pipe, space, alphanum with underscores). This is incompatible with macOS's BSD-flavored
#			 `sed`. If someone wants to contribute a version with identical results using POSIX-style regexes (sed -e), PRs are welcome.
#  - `markdown-table-formatter` which aligns Markdown table columns with whitespace.
#  Use `gh-md-toc` to read the headers in the Markdown, and generate a Table of Contents.
#  .trim() in Node.js script trimes multiple empty lines in the end of the file after processing.

.PHONY: readme
## readme: [docs] replaces `@@` markers in the README with consistently-formatted output from `terraform-docs` and `gh-md-toc`
readme:
	@ echo " "
	@ echo "=====> Running terraform-docs and gh-md-toc..."
	@ cat README.md \
		| awk -v tf_supported="<!--TF_VER-->$$(hcledit --file versions.tf attribute get terraform.required_version)<!--TF_VER-->" '{ gsub(/<!--TF_VER-->.*<!--TF_VER-->/, tf_supported); print }' \
		| awk -v tf_current="0.15" '{ gsub(/@@TF_CURRENT@@/, tf_current); print }' \
		| awk -v tf_legacy="0.11" '{ gsub(/@@TF_LEGACY@@/, tf_legacy); print }' \
		| awk -v node_current="16" '{ gsub(/@@NODE_CURRENT@@/, node_current); print }' \
		| awk -v go_current="1.16" '{ gsub(/@@GO_CURRENT@@/, go_current); print }' \
		| input_output="$$(terraform-docs markdown . --config ${MAKEFILE_DIR}/configs/.terraform-docs.yml | sed -r 's/^####\s/## /g' | markdown-table-formatter)" \
			node -e 'console.log(require("fs").readFileSync(0).toString().replace(/<!--DOCS-->[^]*<!--DOCS-->/, "<!--DOCS-->\n"+process.env.input_output+"\n<!--DOCS-->").trim())' \
		> README.md.tmp
	@	export toc="$$(gh-md-toc --hide-header --hide-footer --no-escape --indent=4 README.md)" && \
		cat README.md.tmp \
		| node -e 'console.log(require("fs").readFileSync(0).toString().replace(/<!--TOC-->[^]*<!--TOC-->/, "<!--TOC-->\n\n"+process.env.toc+"\n<!--TOC-->").trim())' \
		> README.md
		rm README.md.tmp

# .PHONY: workflows
## workflows: [docs] updates .github/workflows/terraform.yml with the Terraform versions supported by this module
# workflows:
# 	@ echo " "
# 	@ echo "=====> Updating .github/workflows/terraform.yml..."
# 	- content="$$(bin/update-github-actions-terraform.py --versions="$$(bin/supported-versions.py < versions.tf)" < .github/workflows/terraform.yml)" && echo "$$content" > .github/workflows/terraform.yml

.PHONY: docs
## docs: [docs] runs ALL documentation tasks except `make resources`
docs: readme markdownlint
# workflows

#-------------------------------------------------------------------------------
# Linting

.PHONY: tfswitch
## tfswitch: [chores] runs tfswitch
tfswitch:
	tfswitch

# https://github.com/igorshubovych/markdownlint-cli
# Config is baked-in inside the build-tools docker image in /root/.markdownlintrc
.PHONY: markdownlint
## markdownlint: [lint] runs `markdownlint` (formatting, spelling) against all Markdown (*.md) documents with a standardized set of rules
markdownlint:
	@ echo " "
	@ echo "=====> Running Markdownlint ${MARKDOWNLINT_FIX}..."
	@ if which markdownlint 2>&1 >/dev/null; then \
			echo "markdownlint $$(markdownlint --version)" && \
			markdownlint \
				${MARKDOWNLINT_FIX} '**/*.md' --ignore '**/node_modules/**' --config ${MAKEFILE_DIR}/configs/.markdownlint.json; \
		else \
			npx markdownlint-cli \
				${MARKDOWNLINT_FIX} '**/*.md' --ignore '**/node_modules/**' --config ${MAKEFILE_DIR}/configs/.markdownlint.json; \
		fi

# https://github.mheducation.com/terraform/build-tools/wiki/tflint
.PHONY: tflint
## tflint: [lint] runs `tflint` (formatting, value validation) against all Terraform (*.tf) code with a standardized set of rules
tflint:
	@ echo " "
	@ echo "=====> Running tflint... $$(tflint --version)"
	# - echo 'echo find . -type d -name ".terraform" | xargs rm -Rf'
	@ tflint --config="${MAKEFILE_DIR}/configs/.tflint.hcl" --init
	@ export ERROR_CODE=0 && for dir in ${TF_DIRS}; do \
		echo "-- tflint: $${dir}" && cd "$${dir}" && \
		tflint --config="${MAKEFILE_DIR}/configs/.tflint.hcl" . || export ERROR_CODE=$$?; \
		cd "${MAKEFILE_DIR}"; \
	done && exit $$ERROR_CODE
# @ tflint --init # added in 0.29

# whether a configuration is syntactically valid and internally consistent, regardless of any provided variables or existing state.
.PHONY: tfvalidate
## tfvalidate: [lint] runs `terraform validate` (valid syntax) against all Terraform (*.tf) code
# It also creates a symlink in each folder to
tfvalidate:
	@ echo " " && \
	echo "=====> Running terraform's internal validate command..." && \
	for dir in ${TF_DIRS}; do \
		echo "-- tfvalidate: $${dir}" && \
		cd "$${dir}" && \
		if [ "$${dir}" == "." ] && [ ! -f ".terraform.lock.hcl" ]; then ln -s "tests/.terraform.lock.hcl" ".terraform.lock.hcl"; fi && \
		TF_IN_AUTOMATION=true terraform init -backend=false && terraform validate || exit $$?; \
		cd $(MAKEFILE_DIR); \
	done

# tfvalidator is a system for validating Terraform plans to ensure conformity in resource naming and tagging.
.PHONY: tfvalidator
## tfvalidator: [lint] runs `terraform-validator` (file consistency) against all Terraform (*.tf) code with a standardized set of rules
tfvalidator:
	@ echo " "
	@ echo "=====> Running terraform-validator..."
	terraform-validator .

# Formats all Terraform code to its canonical format.
# --recursive flag is available for sure in 0.12+
.PHONY: fmt
## fmt: [lint] runs `terraform fmt` (formatting) against all Terraform (*.tf) code
fmt: tfswitch
	@ echo " "
	@ echo "=====> Running Terraform fmt ${FMT_FLAGS}..."
	@ cd "$${MAKEFILE_DIR}" && pwd && terraform fmt --recursive ${FMT_FLAGS};


.PHONY: lint
## lint: [lint] runs ALL linting/validation tasks
# tfvalidate is excluded because of too many hiccups related to workspace selection, old naming, etc
lint: fmt tflint markdownlint

#-------------------------------------------------------------------------------
# Release and commit Tasks

.PHONY: upgrade_tf_providers
## upgrade_tf_providers: [commit] updates lock file for Terraform 0.14+. Commit that file afterwards.
# WARNING! TF_PLUGIN_CACHE_DIR is set to a wrong path to avoid Terraform errors about mismatch of version,
#  which seems to be silly because it needs to download new versions anyways. It's very annoying when trying to upgrade locally.
upgrade_tf_providers:
	@echo "TF_TOP_DIRS: ${TF_TOP_DIRS}"
	@export TF_LOG=trace && set -o nounset -o pipefail -o errexit && exec 2>&1 && \
	for dir in ${TF_TOP_DIRS}; do \
		echo "TF Top dir: $${dir}" && \
		cd $(MAKEFILE_DIR) && \
		rm "$${dir}/.terraform.lock.hcl" || true && rm -rf "$${dir}/.terraform" || true && \
		TF_INIT_UPGRADE="true" ONLY_INIT="true" environment="upgrade_tf_providers" EXEC_DIR_ON_TF="$${dir}" ./tf.sh && \
		rm "$${dir}/.terraform.lock.hcl" || true && \
		cd "$${dir}" && \
		terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 && \
		cd $(MAKEFILE_DIR); \
	done


.PHONY: prepush
## prepush: [commit] runs all commands which fix something
prepush: docs lint

.PHONY: cicd
## cicd: [commit] runs all CI/CD commands in a sequence
cicd: prepush test

#-------------------------------------------------------------------------------
# Docker Tasks

.PHONY: shell
## shell: [docker] shell command for shortcut to get inside the build tools container here as `make docker_shell`
shell:
	bash

.PHONY: docker_%
## docker_%: [docker] runs the make target inside the build-tools docker container. Could be useful locally. Example - make docker_lint
docker_%:
	@echo "Running make $(*F) in the build-tools docker container"
	@ for VAR in $$(aws-vault exec ${DEFAULT_PROFILE} -- printenv | grep --color=never ^AWS_ 2>&1); do export $${VAR}; done && \
		docker run -ti --rm \
		-e AWS_DEFAULT_REGION -e AWS_REGION -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_SECURITY_TOKEN -e AWS_SESSION_EXPIRATION \
    -e GH_TOC_TOKEN \
    -e GHE_TOKEN \
    -e NEW_RELIC_ACCOUNT_ID \
    -e NEW_RELIC_API_KEY \
    -e NEW_RELIC_ADMIN_API_KEY \
    -e PAGERDUTY_TOKEN \
    -e CHECKPOINT_DISABLE=true \
    -e TERRAGRUNT_SOURCE_UPDATE=false \
    -e TF_PLUGIN_CACHE_DIR="/root/terraform.plugin.cache" \
    -v $(shell pwd):/workspace:rw \
    -v "${SRC_PLUGIN_CACHE_DIR}":/root/terraform.plugin.cache \
    -v "${SRC_TFSWITCH_LINUX_CACHE}":/root/.terraform.versions \
    -v "${HOME}/.ssh/id_rsa":/root/.ssh/id_rsa:ro \
	-e START_TEST_INDEX \
	-e END_TEST_INDEX \
	-e NO_CLEANUP \
	-e CONTINUE_TESTS \
	-e TF_VERSION \
	-e NO_FIX \
    containers.mheducation.com/torchwood/build-tools:${BUILD_TOOLS_VERSION} -c "make $(*F)"
