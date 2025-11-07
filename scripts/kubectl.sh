sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo rm -f /etc/apt/keyrings/kubernetes-*.gpg
sudo mkdir -p /etc/apt/keyrings


curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
 | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#Add the repo pointing to that key
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" \
 | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

#Update and install
sudo apt update
sudo apt install -y kubectl

# Verify
kubectl version --client

