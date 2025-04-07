#!/bin/bash
set -eu -o pipefail

# https://docs.k3s.io/installation/requirements#operating-systems

firewall-offline-cmd --add-service=kube-apiserver --add-service=etcd-client --add-service=etcd-server
firewall-offline-cmd --add-port=10250/tcp # kubelet API
firewall-offline-cmd --add-port=8472/udp # flannel vxlan
firewall-offline-cmd --zone=trusted --add-source=10.42.0.0/16 # pods
firewall-offline-cmd --zone=trusted --add-source=10.43.0.0/16 # services

firewall-offline-cmd --add-port=30000-32767/tcp # nodeport services
firewall-offline-cmd --add-service=http --add-service=https

systemctl reload firewalld

export PATH=$PATH:/usr/local/bin

if ! command -v oci; then
  yum install -y python3-oci-cli
fi

export OCI_CLI_AUTH=instance_principal

if ! command -v k3s; then
  # provision this instance for use as either a server or an agent
  export INSTALL_K3S_SKIP_ENABLE=true
  export K3S_TOKEN=$(oci secrets secret-bundle get-secret-bundle-by-name \
    --vault-id '${vault_id}' \
    --secret-name k3s-token \
    --query 'data."secret-bundle-content".content' \
    --raw-output | base64 -d --ignore-garbage)

  curl -sfL https://get.k3s.io | sh -s - agent
  curl -sfL https://get.k3s.io | sh -s - server
fi
