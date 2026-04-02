#!/bin/bash
set -e

sudo apt-get update && sudo apt-get upgrade -y

# Docker install
echo "Installing Docker..."
# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


sudo systemctl start docker

sudo systemctl enable docker

sudo usermod -aG docker admin

echo "Checking Docker installation..."


# Check if Docker command exists
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed."
    exit 1
fi

echo "Docker is installed."

# Check if Docker daemon is running
if docker info > /dev/null 2>&1
then
    echo "Docker is running."
else
    echo "Docker is installed but NOT running."
    echo "Try starting it with:"
    echo "sudo systemctl start docker"
fi
