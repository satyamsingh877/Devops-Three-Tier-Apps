#!/bin/bash
# DevOps Tools Installation Script for Ubuntu 22.04
# Includes version checks for all installed components

echo "=== Starting DevOps Tools Installation ==="
echo "System will now install and verify multiple DevOps tools"
echo "-------------------------------------------"

# Update system
echo -e "\n[1/12] Updating system packages..."
sudo apt update -y > /dev/null
sudo apt upgrade -y > /dev/null
echo "System updated successfully."

# Install Java
echo -e "\n[2/12] Installing Java..."
sudo apt install openjdk-17-jre -y > /dev/null
sudo apt install openjdk-17-jdk -y > /dev/null
echo "Java installation complete:"
java --version | head -n 1

# Install Docker
echo -e "\n[3/12] Installing Docker..."
sudo apt install docker.io -y > /dev/null
sudo systemctl enable docker > /dev/null
sudo systemctl start docker > /dev/null
echo "Docker installation complete:"
docker --version

# Configure Docker permissions
echo -e "\n[4/12] Configuring Docker permissions..."
sudo usermod -aG docker jenkins > /dev/null
sudo usermod -aG docker ubuntu > /dev/null
sudo systemctl restart docker > /dev/null
sudo chmod 777 /var/run/docker.sock > /dev/null
echo "Docker permissions configured."

# Install Jenkins
echo -e "\n[5/12] Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y > /dev/null
sudo apt-get install jenkins -y > /dev/null
echo "Jenkins installation complete."
echo "Jenkins service status:"
sudo systemctl status jenkins | grep "Active:"

# Install SonarQube
echo -e "\n[6/12] Installing SonarQube container..."
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community > /dev/null
echo "SonarQube container running:"
docker ps | grep sonar

# Install AWS CLI
echo -e "\n[7/12] Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" > /dev/null
sudo apt install unzip -y > /dev/null
unzip awscliv2.zip > /dev/null
sudo ./aws/install > /dev/null
rm awscliv2.zip
rm -rf aws
echo "AWS CLI installation complete:"
aws --version | head -n 1

# Install kubectl
echo -e "\n[8/12] Installing kubectl..."
sudo curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl" > /dev/null
sudo chmod +x kubectl > /dev/null
sudo mv kubectl /usr/local/bin/ > /dev/null
echo "kubectl installation complete:"
kubectl version --client --short

# Install eksctl
echo -e "\n[9/12] Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp > /dev/null
sudo mv /tmp/eksctl /usr/local/bin > /dev/null
echo "eksctl installation complete:"
eksctl version

# Install Terraform
echo -e "\n[10/12] Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt update > /dev/null
sudo apt install terraform -y > /dev/null
echo "Terraform installation complete:"
terraform --version | head -n 1

# Install Trivy
echo -e "\n[11/12] Installing Trivy..."
sudo apt-get install wget apt-transport-https gnupg lsb-release -y > /dev/null
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - > /dev/null
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt update > /dev/null
sudo apt install trivy -y > /dev/null
echo "Trivy installation complete:"
trivy --version | head -n 1

# Install Helm
echo -e "\n[12/12] Installing Helm..."
sudo snap install helm --classic > /dev/null
echo "Helm installation complete:"
helm version --short

# Install ArgoCD
echo -e "\n[Bonus] Installing ArgoCD..."
echo "Installing ArgoCD in Kubernetes..."
kubectl create namespace argocd > /dev/null
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null
echo "ArgoCD installed in Kubernetes cluster."

echo -e "\n=== Installation Summary ==="
echo "Java: $(java --version | head -n 1)"
echo "Docker: $(docker --version)"
echo "Jenkins: $(sudo systemctl status jenkins | grep "Active:" | awk '{print $2, $3, $4, $5, $6, $7}')"
echo "SonarQube: $(docker inspect --format '{{.Config.Image}}' sonar) (Container ID: $(docker ps -q --filter name=sonar | cut -c1-12))"
echo "AWS CLI: $(aws --version | head -n 1)"
echo "kubectl: $(kubectl version --client --short | awk '{print $3}')"
echo "eksctl: $(eksctl version | awk '{print $3}')"
echo "Terraform: $(terraform --version | head -n 1)"
echo "Trivy: $(trivy --version | head -n 1)"
echo "Helm: $(helm version --short)"
echo "ArgoCD: Installed in Kubernetes (namespace: argocd)"
echo -e "\nAccess URLs:"
echo "- Jenkins: http://$(curl -s ifconfig.me):8080"
echo "- SonarQube: http://$(curl -s ifconfig.me):9000"
echo "================================="
echo "All installations completed successfully!"
