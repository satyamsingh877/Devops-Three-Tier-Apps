#!/bin/bash
# DevOps Tools Uninstall Script for Ubuntu 22.04
# Removes all components installed by the installation script

echo "=== Starting DevOps Tools Uninstallation ==="
echo "This will remove all installed DevOps tools"
echo "-------------------------------------------"

# Function to safely remove packages
safe_apt_remove() {
    echo -n "Removing $@... "
    sudo DEBIAN_FRONTEND=noninteractive apt-get remove -qqy --purge "$@" > /dev/null
    sudo apt-get autoremove -qqy > /dev/null
    echo "✓"
}

# Stop and remove Jenkins
echo -e "\n[1/12] Removing Jenkins..."
sudo systemctl stop jenkins > /dev/null 2>&1
safe_apt_remove jenkins
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

# Remove Java
echo -e "\n[2/12] Removing Java..."
safe_apt_remove openjdk-17-jre openjdk-17-jdk

# Stop and remove SonarQube container
echo -e "\n[3/12] Removing SonarQube..."
docker stop sonar > /dev/null 2>&1
docker rm sonar > /dev/null 2>&1
echo "✓ SonarQube container removed"

# Remove Docker
echo -e "\n[4/12] Removing Docker..."
sudo systemctl stop docker > /dev/null 2>&1
safe_apt_remove docker.io docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo groupdel docker > /dev/null 2>&1
echo "✓ Docker removed"

# Remove AWS CLI
echo -e "\n[5/12] Removing AWS CLI..."
sudo rm -rf /usr/local/aws
sudo rm -f /usr/local/bin/aws
echo "✓ AWS CLI removed"

# Remove kubectl
echo -e "\n[6/12] Removing kubectl..."
sudo rm -f /usr/local/bin/kubectl
echo "✓ kubectl removed"

# Remove eksctl
echo -e "\n[7/12] Removing eksctl..."
sudo rm -f /usr/local/bin/eksctl
echo "✓ eksctl removed"

# Remove Terraform
echo -e "\n[8/12] Removing Terraform..."
safe_apt_remove terraform
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/hashicorp.list
echo "✓ Terraform removed"

# Remove Trivy
echo -e "\n[9/12] Removing Trivy..."
safe_apt_remove trivy
sudo rm -f /etc/apt/sources.list.d/trivy.list
sudo apt-key del "CE8F 3F6D 6A6D F693 F22D  8A8A 8F3A 49EA D366 7CA2" > /dev/null 2>&1
echo "✓ Trivy removed"

# Remove Helm
echo -e "\n[10/12] Removing Helm..."
sudo snap remove helm > /dev/null 2>&1
echo "✓ Helm removed"

# Remove ArgoCD
echo -e "\n[11/12] Removing ArgoCD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null 2>&1
kubectl delete namespace argocd > /dev/null 2>&1
echo "✓ ArgoCD removed"

# Clean up remaining packages
echo -e "\n[12/12] Cleaning up remaining packages..."
safe_apt_remove unzip curl gnupg lsb-release software-properties-common apt-transport-https
sudo apt-get clean > /dev/null
sudo apt-get autoclean > /dev/null
echo "✓ System cleaned"

# Final check for remaining containers
echo -e "\nChecking for remaining Docker containers..."
if [ "$(docker ps -aq)" ]; then
    echo "Warning: The following containers still exist:"
    docker ps -a
    read -p "Would you like to remove all Docker containers? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker stop $(docker ps -aq) > /dev/null 2>&1
        docker rm $(docker ps -aq) > /dev/null 2>&1
        echo "✓ All containers removed"
    fi
else
    echo "✓ No containers remaining"
fi

echo -e "\n=== Uninstallation Summary ==="
echo "The following components were removed:"
echo "1. Jenkins"
echo "2. Java (OpenJDK 17)"
echo "3. SonarQube container"
echo "4. Docker"
echo "5. AWS CLI"
echo "6. kubectl"
echo "7. eksctl"
echo "8. Terraform"
echo "9. Trivy"
echo "10. Helm"
echo "11. ArgoCD"
echo "12. Supporting packages"

echo -e "\nNote: The following user data was NOT removed:"
echo "- Jenkins home directory (/var/lib/jenkins)"
echo "- Docker volumes"
echo "- Kubernetes clusters"
echo "- Any configuration files in your home directory"

echo -e "\n✓ Uninstallation completed successfully!"
