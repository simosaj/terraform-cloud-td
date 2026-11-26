#!/usr/bin/env bash
# Plans pédagogiques sur un état vide. Les deux providers travaillent avec des valeurs de démonstration.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
export TF_IN_AUTOMATION=1
export CHECKPOINT_DISABLE=1
export TF_PLUGIN_CACHE_DIR="$out/providers"
mkdir -p "$TF_PLUGIN_CACHE_DIR" "$out/modules"
unset TF_DATA_DIR TF_CLI_ARGS TF_CLI_ARGS_init TF_CLI_ARGS_plan AWS_PROFILE AWS_SESSION_TOKEN AWS_WEB_IDENTITY_TOKEN_FILE
unset GOOGLE_CREDENTIALS GOOGLE_APPLICATION_CREDENTIALS GOOGLE_OAUTH_ACCESS_TOKEN
export AWS_ACCESS_KEY_ID=offline AWS_SECRET_ACCESS_KEY=offline AWS_EC2_METADATA_DISABLED=true
export GOOGLE_OAUTH_ACCESS_TOKEN=offline TF_VAR_project_id=td-demo-project

for cloud in gcp aws; do
  src="$root/TD/2_terraform"
  dir="$out/foundation-$cloud"
  mod="$out/modules/$cloud"
  mkdir -p "$dir" "$mod"
  cp "$src/foundation-$cloud/"{main.tf,variables.tf,versions.tf,.terraform.lock.hcl} "$dir/"
  cp "$src/modules/$cloud/"{variables.tf,versions.tf} "$mod/"
  if [[ $cloud == aws ]]; then
    cat > "$dir/offline_override.tf" <<'HCL'
provider "aws" {
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}
HCL
  fi
  terraform -chdir="$dir" init -backend=false -input=false -lockfile=readonly >/dev/null
  for step in provider network compute database dns replicas; do
    case "$step" in
      provider) ;;
      replicas)
        export TF_VAR_vm_count=2
        cp "$src/modules/$cloud/outputs.tf" "$mod/"
        cp "$src/foundation-$cloud/outputs.tf" "$dir/"
        ;;
      *) cp "$src/modules/$cloud/$step.tf" "$mod/" ;;
    esac
    if [[ $step == provider ]]; then export TF_VAR_vm_count=1; fi
    terraform -chdir="$dir" validate -no-color
    terraform -chdir="$dir" plan -no-color -refresh=false -input=false > "$out/$cloud.txt"
    echo "$cloud / $step"
    awk '/^Plan:|^No changes\./ { print }' "$out/$cloud.txt"
  done
  printf '\n--- %s ---\n' "$cloud"
  cat "$out/$cloud.txt"
done
