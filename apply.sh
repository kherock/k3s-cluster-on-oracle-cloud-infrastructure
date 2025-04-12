#!/usr/bin/env sh

terraform -chdir=terraform refresh

for i in {1..3}; do
  terraform -chdir=terraform plan -refresh=false -var ampere_ad_number=$i -out=ad-$i.tfplan
done

trap 'echo "Exiting on Ctrl+C"; exit 1' SIGINT

set -x
while ! terraform -chdir=terraform apply ad-$(shuf -i 1-3 -n 1).tfplan; do
  echo "Retrying..."
  cp -f terraform/terraform.tfstate.backup terraform/terraform.tfstate
  sleep 1
done
