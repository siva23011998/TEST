# Infrastructure for Content Search

![Terraform 1.19](https://img.shields.io/badge/Terraform-1.1.9-623ce4.svg?labelColor=171e21&style=for-the-badge&logo=terraform)


Services deployed:

* Content Search


It's possible to deploy infrastructure from local laptop or from Github Actions.
Manually you need to use `./tf.sh` file with environment variables, which requires AWS credentials available in the environment (discouraged) or aws-vault set up with credentials from service user and/or AWS accounts.
CircleCI uses the same script, but credentials are provided using 2 environment variables.

## Structure

Infrastructure consist of 3 layers, managed in corresponding subfolder:

* `init`: Chicken and egg resources: state file and service user. After initial setup, you don't need you personal credentials anymore
* `shared`: account-level shared resources, such as ALB, ECS cluster, etc
* `SDLC` - resources duplicated for each SDLC environment, such as different service, log groups

### External resources

#### DNS

DNS is controlled by delegating zones from UltraDNS. For regular updates it should not be required. Torchwood team can do it in nonprod, but Prod changes require opening tickets with network team.

#### Turbot Account

* Create zone with records in Turbot account
* New ARN format should be enabled <https://github.mheducation.com/terraform/docs/wiki/New-ARN-and-resource-ID-format-must-be-enabled>
* Modify Turbot policies: TODO TBD

## Manual apply

Requirements:

* [aws-vault](https://confluence.mheducation.com/display/EPS/Running+aws-vault+in+macOS+with+local+Docker+containers) for storing and retrieving AWS credentials and exposing them to running commands.
* In your `~/.aws/config` file, you should have a block for `[profile aam]` and `[profile act]`. See [this link](https://github.mheducation.com/torchwood/turbot-scripts/tree/master/aws-vault-turbot-to-control-tower) for adding these profiles once you have access to the proper AWS accounts (aam & act)
* [tfswitch](https://tfswitch.warrensbox.com/) for switching Terraform versions according to specifications in `versions.tf` files. For Mac: `brew install warrensbox/tap/tfswitch`.
* Credentials for accounts specified in [.env](./.env). By default we're using AWS profiles configured in aws-vault.
* Docker
* For working with ./monitoring layer locally, create `.env.local` file and add these lines:

```bash
NR_API_KEY_PROD=NRAK-EXAMPLE_REPLACE_ME
NR_API_KEY_NONPROD=NRAK-EXAMPLE_REPLACE_ME
```

### General guidelines

**Do the dry-run first**. If you're satisfied, modify the value of the `DRY_RUN` variable to `false` and apply the changes by executing the command.

### Init

When executing init step first time (or after previous destroy operation, when state bucket doesn't exist), there is an additional step as a workaround for the chicken and egg issue of state file and state file bucket. This step is expected to be done locally once per account (prod/nonprod).

1. Comment the whole `backend "s3"` stanza in `./init/versions.tf` file.
1. Copy dry run command, remove `-svc` suffix from the profile since the service user doesn't exist yet and execute it. Validate the output. Then execute the same command with `DRY_RUN` set to `false` in order to create resources in the cloud and to have the state file **locally**.
1. Redo the step 1 (uncomment `backend "s3" stanza`).
1. Repeat step 2 which will save the state file into the state bucket. Answer `yes` to 'Do you want to migrate all workspaces to "s3"?' question. To confirm state migration, check the S3 state bucket.

Nonprod:

```bash
AWS_PROFILE=aam environment=nonprod EXEC_DIR_ON_TF=./init DRY_RUN=true ./tf.sh
```

Prod:

```bash
AWS_PROFILE=act environment=prod EXEC_DIR_ON_TF=./init DRY_RUN=true ./tf.sh
```

### Service user credentials

Service user is created during the Init phase.

#### Obtain the credentials

You can get credentials either manually through AWS Console or using CLI command `aws-vault exec PROFILE --no-session -- aws iam create-access-key --user-name SERVICE_USER_NAME`, where `PROFILE` is usually the same as Turbot account name (i.e. `aef` for nonprod) and `SERVICE_USER_NAME` is the name of the service user created during the Init phase, such as `aef-app-nonprod-svc-user`.

#### Save the credentials

Locally you can save them as a profile, preferably through `aws-vault`, because that method is more secure. In CI (Jenkins, CircleCI, GHA) you probably will use them as separate environment variables.

For `aws-vault` users: execute following command: `aws-vault add PROFILE_NAME_HERE`. Alternatively, use `aws configure --profile PROFILE_NAME_HERE`. Where `PROFILE_NAME_HERE` should be the value of `AWS_PROFILE_NONPROD` or `AWS_PROFILE_PROD` variable from `.env` file (i.e. `aef-svc` for nonprod).

### Shared

On the first creation or recreation of shared resources, NS entries for the public DNS zone will be generated. Upstream NS servers should be repointed to newly created NS records.

Note:

* On the first run (both initial creation or recreation) the script may fail at module creating certificate validation due to the fact that the NS records have changed. Once the records are updated in ultraDNS (get the latest ns records from AWS R53 hosted zones and update in ultraDNS) then rerun the script and it should work.
* Unlikely but in case if you run into any permissions issue with the service user like 'Access Denied errors for service user "aef-archivedb-nonprod-svc-user"' then please use your AWS account profile access key and secret (follow the instructions above for setting up profile in aws-vault or an alternative way)
* In order to modify the list of os processes monitoring data to be collected by newrelic supply the following input argument 'include_matching_metrics' to module 'aws_ecs_newrelic_service" with a value something like "process.name:\\n - regex \\\".*supervise.*|.*httpd.*|.*java.*|.*crond.*|.#*BESClient*|.*amazon-cloudwat.*|.*servicenow.*|.*apache.*\\\" \\n" .

Nonprod:

```bash
AWS_PROFILE=aam environment=nonprod EXEC_DIR_ON_TF=./shared DRY_RUN=true ./tf.sh
```

Prod:

```bash
AWS_PROFILE=act environment=prod EXEC_DIR_ON_TF=./shared DRY_RUN=true ./tf.sh
```

### SDLC

One of nonprod SDLCs, such as `qastg`:

```bash
AWS_PROFILE=aam environment=qastg EXEC_DIR_ON_TF=./SDLC DRY_RUN=true ./tf.sh
```

Prod:

```bash
AWS_PROFILE=act environment=prod EXEC_DIR_ON_TF=./SDLC DRY_RUN=true ./tf.sh
```

### Validating

Open a URL such as <TBA>.

### Additional flags

* `DESTROY=true` could be used to destroy specific layer. Value of `DRY_RUN` variable will affect whether it will be plan or apply.

## Destruction

In case there is a need to destroy some layers, keep in mind:

* Destroy steps to be followed in reverse order as opposed to create steps. Destroy SDLC layer --> Shared layer --> init layer
* DNS Public Hosted Zone by default doesn't have `force_destroy` flag set to avoid accidental removal, because recreation will require update of upstream NS entries for the zone.

### Notes for Shared layer destroy steps

* ALB has deletion protection flag on, so you need to disable that to avoid an error.
* There is a known issue with ECS Cluster delete module. Please ensure to make autoscaling group attributes to update min, max and desired Node count to zero before running the destroy.

### Notes for Init layer destroy steps

* Detach all policies associated with IAM service user (for ex: aef-archivedb-nonprod-ec2-role) to avoid an error.
* Delete the folders in S3 bucket (aef-remote-state-archivedb-nonprod) prior to running init layer destruction to avoid an error.

### Monitoring & Alerting

Follow the steps below to create newrelic workload, alert policy, alert conditions and add notification channels

Nonprod:

```bash
AWS_PROFILE=aam environment=nonprod EXEC_DIR_ON_TF=./monitoring-observability DRY_RUN=true ./tf.sh
```

Prod:

```bash
AWS_PROFILE=act environment=prod EXEC_DIR_ON_TF=./monitoring-observability DRY_RUN=true ./tf.sh
```

Note:

* Change NR_ALERT_COND_FLAG default value in ./monitoring-observability/variables.tf file to 'true' to enable the alert conditions and false to disable.

## Troubleshooting

### Error: error initializing newrelic-client-go: must use at least one of: ConfigPersonalAPIKey, ConfigAdminAPIKey, ConfigInsightsInsertKey

This means that `newrelic` provider could not find API key. Environment variable names (and potentially provider property names) were changed at version 2 of the provider. Verify that `api_key` property of the provider or `NEW_RELIC_API_KEY` environment variable are not empty.

## TODO

* Update layers to reflect ArchiveDB migration requirements

When all 3 layers are working, look into:

* Updating versions of Terraform and corresponding modules.
* GHA
* Check Capacity Providers again.
* Simplify the .tf script and make it work with asdf or tfswitch

## Links

* Source: <TBA>
* Application-related Links: <TBA>
* Test users: <TBA>
* Migration page: <TBA>
