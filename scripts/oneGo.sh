
# echo "Enter cluster name:"
# read cluster_name
# sudo apt update && sudo apt upgrade -y


# sudo apt install -y python3 python3-pip python3-venv


# sudo apt update
# sudo apt install fontconfig openjdk-21-jre
# java -version




# sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
#   https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
# echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
#   https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
#   /etc/apt/sources.list.d/jenkins.list > /dev/null
# sudo apt update
# sudo apt install jenkins -y



# sudo apt-get install ca-certificates curl
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc

# # Add the repository to Apt sources:
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#   $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt-get update
# sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y




# curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
# chmod +x ./kind
# sudo mv ./kind /usr/local/bin/kind



# sudo rm -f /etc/apt/sources.list.d/kubernetes.list
# sudo rm -f /etc/apt/keyrings/kubernetes-*.gpg
# sudo mkdir -p /etc/apt/keyrings


# curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
#  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# #Add the repo pointing to that key
# echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
# https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" \
#  | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# #Update and install
# sudo apt update
# sudo apt install -y kubectl

# # Verify
# kubectl version --client


# kind create cluster --name ${cluster_name} --config=./scripts/config.yml




















#===========================================================================================================================



#!/usr/bin/env bash
#
# Purpose: Provision a DevOps workstation on Ubuntu/Debian and create a kind cluster.
# Components: Python3 + pip + venv, OpenJDK 21, Jenkins, Docker, kubectl, kind.
# Assumptions:
#   - You are on Ubuntu/Debian with systemd.
#   - You have sudo privileges.
#   - Cluster config file exists at ./scripts/config.yml (adjust CONFIG_PATH if needed).

set -euo pipefail

# -------- Parameters --------
# CONFIG_PATH="config.yml"   # Path to kind cluster config
UBUNTU_DOCKER_REPO_NAME="docker"     # Name for Docker apt source list file
K8S_APT_KEYRING="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
K8S_APT_LIST="/etc/apt/sources.list.d/kubernetes.list"
JENKINS_KEY="/etc/apt/keyrings/jenkins-keyring.asc"
JENKINS_LIST="/etc/apt/sources.list.d/jenkins.list"

# -------- Helpers --------
command_exists() { command -v "$1" >/dev/null 2>&1; }

require_file() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Required file not found: $f" >&2
    exit 1
  fi
}

detect_arch() {
  # Map kernel arch to kind download arch label
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

# -------- Input --------
echo -n "Enter cluster name: "
read -r cluster_name
if [[ -z "${cluster_name}" ]]; then
  echo "ERROR: Cluster name cannot be empty." >&2
  exit 1
fi

# Validate config file early
require_file "${CONFIG_PATH}"

# -------- System update --------
echo "[System] Updating base packages..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# -------- Python3, pip, venv --------
echo "[Python] Installing Python 3, pip, and venv..."
sudo apt-get install -y python3 python3-pip python3-venv
python3 --version || true
pip3 --version || true
python3 -m venv --help >/dev/null || true

# -------- Java 21 (OpenJDK) --------
echo "[Java] Installing OpenJDK 21 runtime..."
sudo apt-get install -y fontconfig openjdk-21-jre
java -version || true

# -------- Jenkins repo and install --------
echo "[Jenkins] Configuring apt repository..."
# Create keyrings dir if missing
sudo install -m 0755 -d /etc/apt/keyrings
# Import Jenkins key
if [[ ! -f "${JENKINS_KEY}" ]]; then
  sudo wget -qO "${JENKINS_KEY}" https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
fi
# Add Jenkins repo (idempotent)
echo "deb [signed-by=${JENKINS_KEY}] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee "${JENKINS_LIST}" >/dev/null

echo "[Jenkins] Installing Jenkins..."
sudo apt-get update -y
sudo apt-get install -y jenkins
# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl restart jenkins
sudo systemctl --no-pager --full status jenkins || true

# -------- Docker Engine (official repo) --------
echo "[Docker] Installing prerequisites and repository..."
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
# Import Docker GPG key
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
fi
# Add Docker repo (idempotent)
UBUNTU_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | \
  sudo tee "/etc/apt/sources.list.d/${UBUNTU_DOCKER_REPO_NAME}.list" >/dev/null

echo "[Docker] Installing Engine, CLI, containerd, Buildx, and Compose plugin..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group to run docker without sudo (effective next login)
if getent group docker >/dev/null 2>&1; then
  sudo usermod -aG docker "$USER" || true
fi

# Start and verify Docker
sudo systemctl enable docker
sudo systemctl restart docker
sudo docker version || true

sudo usermod -aG docker $USER 
sudo usermod -aG docker jenkins
newgrp docker


# -------- kind (Kubernetes in Docker) --------
echo "[kind] Installing kind binary..."
ARCH="$(detect_arch)"
tmp_kind="$(mktemp)"
# Using 'latest' to keep it simple. For reproducible builds, pin a version like v0.24.0.
curl -fsSL -o "${tmp_kind}" "https://kind.sigs.k8s.io/dl/latest/kind-linux-${ARCH}"
chmod +x "${tmp_kind}"
sudo mv "${tmp_kind}" /usr/local/bin/kind
kind --version

# -------- kubectl (Kubernetes CLI) --------
echo "[kubectl] Configuring Kubernetes apt repository (v1.31 stable)..."
# Clean any old Kubernetes repo definitions
sudo rm -f "${K8S_APT_LIST}" || true
sudo rm -f /etc/apt/keyrings/kubernetes-*.gpg || true
sudo install -m 0755 -d /etc/apt/keyrings

# Import new key and repo
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key" | \
  sudo gpg --dearmor -o "${K8S_APT_KEYRING}"
sudo chmod 0644 "${K8S_APT_KEYRING}"

echo "deb [signed-by=${K8S_APT_KEYRING}] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | \
  sudo tee "${K8S_APT_LIST}" >/dev/null

echo "[kubectl] Installing kubectl..."
sudo apt-get update -y
sudo apt-get install -y kubectl
kubectl version --client || true

# -------- kind cluster creation --------
echo "[kind] Creating cluster '${cluster_name}' using config '${CONFIG_PATH}'..."
# Helpful prechecks
if ! command_exists docker; then
  echo "ERROR: Docker is not installed correctly. Cannot proceed with kind." >&2
  exit 1
fi
if ! systemctl is-active --quiet docker; then
  echo "ERROR: Docker service is not active. Start Docker and retry." >&2
  exit 1
fi

# kind create cluster --name "${cluster_name}" --config "${CONFIG_PATH}"

# -------- Post-create checks --------
echo "[kube] Verifying cluster access..."
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A --no-headers || true

echo
echo "Done."
echo "- Jenkins runs on port 8080 by default: http://<host>:8080"
echo "- First Jenkins admin password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "- If 'docker' needs no sudo: log out and log back in to refresh group membership."
# echo "- Current KUBECONFIG: ${KUBECONFIG:-$HOME/.kube/config}"



echo "cat ~/.kube/config"
