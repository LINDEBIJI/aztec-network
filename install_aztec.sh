#!/bin/bash

# Aztec One-Click Setup Script for Ubuntu
# This script automates the installation of dependencies, Docker, and Aztec tools

# Print header
echo "================================================"
echo "       Aztec One-Click Setup for Ubuntu         "
echo "================================================"
echo ""

# Function to print section headers
print_section() {
  echo ""
  echo "------------------------------------------------"
  echo "  $1"
  echo "------------------------------------------------"
  echo ""
}

# Function to check for errors
check_error() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# 1. Update and upgrade packages
print_section "1. Updating system packages"
sudo apt-get update && sudo apt-get upgrade -y
check_error "Failed to update system packages"

# 2. Install required packages
print_section "2. Installing dependencies"
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
check_error "Failed to install dependencies"

# 3. Install Docker
print_section "3. Installing Docker"
# Remove conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
  sudo apt-get remove $pkg -y
done

# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
check_error "Failed to install Docker"

# Test Docker
echo "Testing Docker installation..."
sudo docker run hello-world
check_error "Docker test failed"

# Enable Docker service
sudo systemctl enable docker
sudo systemctl restart docker
check_error "Failed to enable Docker service"

# 4. Install Aztec Tools
print_section "4. Installing Aztec Tools"
echo "Installing Aztec Tools (automatically accepting the prompt)..."

# Create a temporary expect script to handle the interactive prompt
cat > /tmp/aztec_install.exp << 'EOF'
#!/usr/bin/expect -f
spawn bash -i -c "curl -s https://install.aztec.network | bash -i"
expect "Do you wish to continue? (y/n)"
send "y\r"
expect eof
EOF

# Make the expect script executable
chmod +x /tmp/aztec_install.exp

# Check if expect is installed, if not install it
if ! command -v expect &> /dev/null; then
    echo "Installing 'expect' package to handle interactive prompts..."
    sudo apt-get install expect -y
    check_error "Failed to install 'expect' package"
fi

# Run the expect script
/tmp/aztec_install.exp
check_error "Failed to install Aztec Tools"

# Clean up the temporary expect script
rm /tmp/aztec_install.exp

# Add Aztec to PATH
echo 'export PATH=$PATH:$HOME/.aztec/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$HOME/.aztec/bin' >> $HOME/.bashrc
source $HOME/.bash_profile
source $HOME/.bashrc
check_error "Failed to update PATH"

# 5. Update Aztec
print_section "5. Updating Aztec"
export PATH=$PATH:$HOME/.aztec/bin
$HOME/.aztec/bin/aztec-up alpha-testnet
check_error "Failed to update Aztec"

# 6. Configure Firewall
print_section "6. Configuring Firewall"
# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
    echo "Installing ufw..."
    sudo apt-get install ufw -y
    check_error "Failed to install ufw"
fi

# Configure firewall
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080

# Enable firewall if it's not already enabled
sudo ufw --force enable
check_error "Failed to configure firewall"

# Final summary
print_section "Aztec Setup Complete!"
echo "The following has been installed and configured:"
echo "- System packages updated"
echo "- All required dependencies installed"
echo "- Docker installed and running"
echo "- Aztec Tools installed and updated"
echo "- Firewall configured with necessary ports"
echo ""
echo "Aztec binary location: $HOME/.aztec/bin/aztec"
echo "Current Aztec version:"
$HOME/.aztec/bin/aztec --version
echo ""
echo "To use Aztec commands, you may need to start a new terminal session"
echo "or run: source $HOME/.bashrc"
echo ""
echo "Thank you for using the Aztec One-Click Setup Script!"
echo "================================================"
