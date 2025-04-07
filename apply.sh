#!/usr/bin/env sh
while ! terraform -chdir=terraform apply -auto-approve -refresh=false -var ampere_ad_number=$(shuf -i 1-3 -n 1); do
  echo "Retrying in 5 seconds..."
  sleep 5
done
