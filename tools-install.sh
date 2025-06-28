#!/bin/bash
# DevOps Tools Installation Script for Ubuntu 22.04
# Properly handles APT warnings and shows clean version output

echo "=== Starting DevOps Tools Installation ==="
echo "System will now install and verify multiple DevOps tools"
echo "-------------------------------------------"

# Function to handle apt installs without CLI warnings
safe_apt_install() {
    # Set DEBIAN_FRONTEND to noninteractive to suppress warnings
    DEBIAN_FRONTEND=noninteractive \
    apt-get -o Dpkg::Options::="--force-confold" -qqy install "$@" > /dev/null
}

# Update system
echo -e "\n[1/12] Updating system packages..."
sudo apt-get update -qqy > /dev/null
sudo apt-get upgrade -qqy > /dev/null
echo "✓ System updated successfully"

# Install Java
echo -e "\n[2/12] Installing Java..."
safe_apt_install openjdk-17-jre openjdk-17-jdk
echo "✓ Java installed: $(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')"

# Install Docker
echo -e "\n[3/12] Installing Docker..."
safe_apt_install docker.io
sudo systemctl enable --now docker > /dev/null
echo "✓ Docker installed: $(docker --version | awk '{print $3}' | tr -d ',')"

# Configure Docker permissions
echo -e "\n[4/12] Configuring Docker permissions..."
sudo usermod -aG docker jenkins > /dev/null 2>&1
sudo usermod -aG docker ubuntu > /dev/null 2>&1
sudo systemctl restart docker > /dev/null
sudo chmod 777 /var/run/docker.sock
echo "✓ Docker permissions configured"

# Install Jenkins
echo -e "\n[5/12] Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian binary/" | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -qqy > /dev/null
safe_apt_install jenkins
echo "✓ Jenkins installed (service: $(sudo systemctl is-active jenkins))"

# Install SonarQube
echo -e "\n[6/12] Installing SonarQube container..."
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community > /dev/null
echo "✓ SonarQube container running: $(docker inspect -f '{{.Config.Image}}' sonar)"

# Install AWS CLI
echo -e "\n[7/12] Installing AWS CLI..."
TMP_DIR=$(mktemp -d)
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMP_DIR/awscliv2.zip"
unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
sudo "$TMP_DIR/aws/install" > /dev/null
rm -rf "$TMP_DIR"
echo "✓ AWS CLI installed: $(aws --version 2>&1 | awk '{print $1}' | tr -d '\n')"

# Install kubectl
echo -e "\n[8/12] Installing kubectl..."
KUBECTL_VERSION="v1.28.4"
curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl > /dev/null
rm kubectl
echo "✓ kubectl installed: $(kubectl version --client --short 2>&1 | awk '{print $3}')"

# Install eksctl
echo -e "\n[9/12] Installing eksctl..."
curl -sSL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
echo "✓ eksctl installed: $(eksctl version | awk '{print $3}')"

# Install Terraform
echo -e "\n[10/12] Installing Terraform..."
sudo apt-get install -y gnupg software-properties-common > /dev/null
wget -qO- https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt-get update -qqy > /dev/null
safe_apt_install terraform
echo "✓ Terraform installed: $(terraform version | head -n 1 | awk '{print $2}')"

# Install Trivy
echo -e "\n[11/12] Installing Trivy..."
sudo apt-get install -y wget apt-transport-https gnupg lsb-release > /dev/null
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    sudo apt-key add - > /dev/null
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
    sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt-get update -qqy > /dev/null
safe_apt_install trivy
echo "✓ Trivy installed: $(trivy --version | head -n 1 | awk '{print $2}')"

# Install Helm
echo -e "\n[12/12] Installing Helm..."
sudo snap install helm --classic > /dev/null
echo "✓ Helm installed: $(helm version --short | awk -F '+' '{print $1}')"

# Install ArgoCD
echo -e "\n[Bonus] Installing ArgoCD..."
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null
echo "✓ ArgoCD installed in namespace: argocd"

# Final summary
echo -e "\n=== Installation Summary ==="
echo "Java: $(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')"
echo "Docker: $(docker --version | awk '{print $3}' | tr -d ',')"
echo "Jenkins: $(sudo systemctl is-active jenkins) (running)"
echo "SonarQube: $(docker inspect -f '{{.Config.Image}}' sonar) (running)"
echo "AWS CLI: $(aws --version 2>&1 | awk '{print $1}' | tr -d '\n')"
echo "kubectl: $(kubectl version --client --short 2>&1 | awk '{print $3}')"
echo "eksctl: $(eksctl version | awk '{print $3}')"
echo "Terraform: $(terraform version | head -n 1 | awk '{print $2}')"
echo "Trivy: $(trivy --version | head -n 1 | awk '{print $2}')"
echo "Helm: $(helm version --short | awk -F '+' '{print $1}')"
echo "ArgoCD: Installed in namespace 'argocd'"

echo -e "\nAccess URLs:"
echo "- Jenkins: http://$(curl -s ifconfig.me):8080"
echo "- SonarQube: http://$(curl -s ifconfig.me):9000"
echo "================================="
echo "✓ All installations completed successfully!"
