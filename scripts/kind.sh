curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind


# kind create cluster --name "${cluster_name}" --config "${CONFIG_PATH}"
# echo "cat ~/.kube/config"