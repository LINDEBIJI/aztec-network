#!/bin/bash

# Aztec One-Click Setup Script for Ubuntu
# This script automates the installation of dependencies, Docker, and Aztec tools
# and provides options to install or run an Aztec node

# Print header
print_header() {
  clear
  echo "================================================"
  echo "       Aztec Network Setup for Ubuntu           "
  echo "================================================"
  echo ""
}

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

# Function to check if Aztec is installed
check_aztec_installed() {
  if [ -d "$HOME/.aztec/bin" ] && [ -f "$HOME/.aztec/bin/aztec" ]; then
    return 0
  else
    return 1
  fi
}

# Function to check if Docker is installed
check_docker_installed() {
  if command -v docker &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to install dependencies and Aztec
install_aztec() {
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

  # Handle PATH update properly
  print_section "Setting up Aztec PATH"
  echo "Ensuring Aztec binaries are in PATH..."
  
  # Add to current session PATH
  export PATH="$PATH:$HOME/.aztec/bin"
  
  # Add to profile files for persistence
  grep -qxF 'export PATH="$PATH:$HOME/.aztec/bin"' $HOME/.bash_profile || echo 'export PATH="$PATH:$HOME/.aztec/bin"' >> $HOME/.bash_profile
  grep -qxF 'export PATH="$PATH:$HOME/.aztec/bin"' $HOME/.bashrc || echo 'export PATH="$PATH:$HOME/.aztec/bin"' >> $HOME/.bashrc
  grep -qxF 'export PATH="$PATH:$HOME/.aztec/bin"' $HOME/.profile || echo 'export PATH="$PATH:$HOME/.aztec/bin"' >> $HOME/.profile
  
  # Also add to root user if running as root
  if [ "$(id -u)" -eq 0 ]; then
    grep -qxF 'export PATH="$PATH:/root/.aztec/bin"' /root/.bash_profile || echo 'export PATH="$PATH:/root/.aztec/bin"' >> /root/.bash_profile
    grep -qxF 'export PATH="$PATH:/root/.aztec/bin"' /root/.bashrc || echo 'export PATH="$PATH:/root/.aztec/bin"' >> /root/.bashrc
    grep -qxF 'export PATH="$PATH:/root/.aztec/bin"' /root/.profile || echo 'export PATH="$PATH:/root/.aztec/bin"' >> /root/.profile
  fi
  
  # Create Aztec directory if it doesn't exist yet
  mkdir -p "$HOME/.aztec/bin" 2>/dev/null || true
  
  # Wait for Docker pull to complete
  print_section "Waiting for Aztec installation to complete..."
  echo "This may take several minutes depending on your internet connection..."
  
  # Wait loop to ensure Docker image download is complete
  MAX_WAIT=600  # 10 minutes max wait time
  WAIT_INTERVAL=15
  ELAPSED=0
  AZTEC_BIN_PATH=""
  
  # Determine the correct path based on user
  if [ "$(id -u)" -eq 0 ]; then
    AZTEC_BIN_PATH="/root/.aztec/bin/aztec"
  else
    AZTEC_BIN_PATH="$HOME/.aztec/bin/aztec"
  fi
  
  while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check if the aztec binary exists
    if [ -f "$AZTEC_BIN_PATH" ]; then
      echo "✅ Aztec binary found at $AZTEC_BIN_PATH"
      echo "✅ Installation complete after $ELAPSED seconds"
      break
    fi
    
    echo "⏳ Waiting for installation to complete... ($ELAPSED seconds elapsed)"
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
  done
  
  # Final check
  if [ ! -f "$AZTEC_BIN_PATH" ]; then
    echo "⚠️ Warning: Aztec binary not found after waiting $MAX_WAIT seconds."
    echo "Installation may still be in progress in the background."
    echo "We'll continue with the rest of the setup."
    echo ""
    echo "You may need to manually check if the installation completed by running:"
    echo "  ls -la $AZTEC_BIN_PATH"
    echo ""
    echo "Press Enter to continue anyway, or Ctrl+C to cancel."
    read -p ""
  fi
  
  # 5. Update Aztec
  print_section "5. Updating Aztec"
  
  # Determine the correct up-command path
  if [ "$(id -u)" -eq 0 ]; then
    AZTEC_UP_PATH="/root/.aztec/bin/aztec-up"
  else 
    AZTEC_UP_PATH="$HOME/.aztec/bin/aztec-up"
  fi
  
  # Check if aztec-up exists before running it
  if [ -f "$AZTEC_UP_PATH" ]; then
    echo "Running aztec-up alpha-testnet..."
    "$AZTEC_UP_PATH" alpha-testnet
    if [ $? -ne 0 ]; then
      echo "⚠️ Warning: aztec-up command encountered an error."
      echo "This might be temporary. We'll continue with the rest of the setup."
    fi
  else
    echo "⚠️ Warning: aztec-up command not found at $AZTEC_UP_PATH"
    echo "This could be because:"
    echo "1. The installation is still in progress in the background"
    echo "2. There was an issue with the Aztec installation"
    echo ""
    echo "We'll continue with the rest of the setup."
    echo "Once installation completes, you may need to run 'aztec-up alpha-testnet' manually."
  fi

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

  print_section "Installation Complete!"
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
  echo "You can now run the script again and select option 2 to start your node."
  echo ""
  
  read -p "Press Enter to return to the main menu..."
  main_menu
}

# Function to run Aztec node
run_aztec_node() {
  print_section "Running Aztec Node"
  
  # Check if Aztec is installed
  if ! check_aztec_installed; then
    echo "Error: Aztec is not installed. Please install it first."
    read -p "Press Enter to return to the main menu..."
    main_menu
    return
  fi
  
  # Installing screen if not available
  if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    sudo apt-get install screen -y
    check_error "Failed to install screen"
  fi

  # Get public IP address
  echo "Detecting your public IP address..."
  PUBLIC_IP=$(curl -s ipv4.icanhazip.com)
  check_error "Failed to detect public IP address"
  echo "Your public IP address is: $PUBLIC_IP"

  # Collect information from user
  echo ""
  echo "Please provide the following information to start your Aztec node:"
  echo "(Press Ctrl+C at any time to cancel)"
  echo ""

  read -p "Enter your L1 RPC URL: " RPC_URL
  check_error "Failed to read RPC URL"

  read -p "Enter your L1 Consensus Host URL (Beacon URL): " BEACON_URL
  check_error "Failed to read Beacon URL"

  read -p "Enter your Validator Private Key (starts with 0x): " VALIDATOR_KEY
  check_error "Failed to read Validator Private Key"

  read -p "Enter your Coinbase Address (starts with 0x): " COINBASE_ADDRESS
  check_error "Failed to read Coinbase Address"

  # Confirm information
  echo ""
  echo "Please confirm your node configuration:"
  echo "L1 RPC URL: $RPC_URL"
  echo "L1 Consensus Host URL: $BEACON_URL"
  echo "Validator Private Key: ${VALIDATOR_KEY:0:6}...${VALIDATOR_KEY: -4}"
  echo "Coinbase Address: $COINBASE_ADDRESS"
  echo "Public IP: $PUBLIC_IP"
  echo ""
  read -p "Is this information correct? (y/n): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Setup canceled. You can try again."
    read -p "Press Enter to return to the main menu..."
    main_menu
    return
  fi

  # Create start script
  SCRIPT_PATH="$HOME/start-aztec-node.sh"
  cat > $SCRIPT_PATH << EOL
#!/bin/bash
export PATH=\$PATH:\$HOME/.aztec/bin
aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls $RPC_URL \\
  --l1-consensus-host-urls $BEACON_URL \\
  --sequencer.validatorPrivateKey $VALIDATOR_KEY \\
  --sequencer.coinbase $COINBASE_ADDRESS \\
  --p2p.p2pIp $PUBLIC_IP
EOL

  chmod +x $SCRIPT_PATH
  check_error "Failed to create start script"

  # Start the node in a screen session
  echo "Starting Aztec node in a screen session..."
  screen -dmS aztec bash -c "$SCRIPT_PATH"
  check_error "Failed to start screen session"

  echo ""
  echo "Your Aztec node is now running in a screen session named 'aztec'"
  echo ""
  echo "To attach to the screen session and see the node output:"
  echo "  screen -r aztec"
  echo ""
  echo "To detach from the screen session (without stopping the node):"
  echo "  Press Ctrl+A, then D"
  echo ""
  echo "If you need to restart the node later, you can run:"
  echo "  $SCRIPT_PATH"
  echo ""
  
  read -p "Press Enter to return to the main menu..."
  main_menu
}

# Function to display status
display_status() {
  print_section "Aztec Node Status"
  
  # Check if Aztec is installed
  if check_aztec_installed; then
    echo "✅ Aztec is installed"
    echo "   Version: $($HOME/.aztec/bin/aztec --version 2>/dev/null || echo 'Unknown')"
  else
    echo "❌ Aztec is not installed"
  fi
  
  # Check if Docker is installed
  if check_docker_installed; then
    echo "✅ Docker is installed"
    echo "   Version: $(docker --version | cut -d ' ' -f3 | tr -d ',')"
  else
    echo "❌ Docker is not installed"
  fi
  
  # Check if screen session exists
  if screen -list | grep -q aztec; then
    echo "✅ Aztec node is running in screen session"
  else
    echo "❌ No running Aztec node detected"
  fi
  
  # Check if start script exists
  if [ -f "$HOME/start-aztec-node.sh" ]; then
    echo "✅ Node start script exists: $HOME/start-aztec-node.sh"
  else
    echo "❌ Node start script not found"
  fi
  
  echo ""
  read -p "Press Enter to return to the main menu..."
  main_menu
}

# Function to display main menu
main_menu() {
  print_header
  
  # Check installation status for menu display
  AZTEC_INSTALLED="not installed"
  if check_aztec_installed; then
    AZTEC_INSTALLED="installed"
  fi
  
  NODE_RUNNING="not running"
  if screen -list | grep -q aztec; then
    NODE_RUNNING="running"
  fi
  
  echo "Current status: Aztec is $AZTEC_INSTALLED, node is $NODE_RUNNING"
  echo ""
  echo "Please select an option:"
  echo "1. Install Aztec Node (dependencies, Docker, Aztec tools, firewall)"
  echo "2. Run Aztec Node (start node in screen session)"
  echo "3. Check Status"
  echo "4. Exit"
  echo ""
  read -p "Enter your choice [1-4]: " choice
  
  case $choice in
    1)
      install_aztec
      ;;
    2)
      run_aztec_node
      ;;
    3)
      display_status
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      sleep 2
      main_menu
      ;;
  esac
}

# Start the script with the main menu
main_menu
