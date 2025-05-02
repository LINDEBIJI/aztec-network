#!/bin/bash

# Aztec One-Click Setup Script for Ubuntu
# This script automates the installation of dependencies, Docker, and Aztec tools
# and provides options to install or run an Aztec node

# Default language setting
LANGUAGE="en"

# Language strings
declare -A MSG

# English messages
MSG[en,header]="Aztec Network Setup for Ubuntu"
MSG[en,choose_option]="Please select an option:"
MSG[en,install_option]="Install Aztec Node (dependencies, Docker, Aztec tools, firewall)"
MSG[en,run_option]="Run Aztec Node (start node in screen session)"
MSG[en,status_option]="Check Status"
MSG[en,language_option]="Change Language (Current: English)"
MSG[en,exit_option]="Exit"
MSG[en,enter_choice]="Enter your choice"
MSG[en,current_status]="Current status: Aztec is"
MSG[en,status_installed]="installed"
MSG[en,status_not_installed]="not installed"
MSG[en,status_running]="running"
MSG[en,status_not_running]="not running"
MSG[en,node_is]="node is"
MSG[en,eth_deposit_reminder]="IMPORTANT: Please deposit Sepolia ETH (recommend at least 0.01 ETH) to your coinbase address for the node to function properly."

# Chinese messages
MSG[zh,header]="Aztec网络Ubuntu安装脚本"
MSG[zh,choose_option]="请选择一个选项："
MSG[zh,install_option]="安装Aztec节点（依赖项、Docker、Aztec工具、防火墙）"
MSG[zh,run_option]="运行Aztec节点（在screen会话中启动节点）"
MSG[zh,status_option]="检查状态"
MSG[zh,language_option]="更改语言（当前：中文）"
MSG[zh,exit_option]="退出"
MSG[zh,enter_choice]="输入您的选择"
MSG[zh,current_status]="当前状态：Aztec已"
MSG[zh,status_installed]="安装"
MSG[zh,status_not_installed]="未安装"
MSG[zh,status_running]="运行中"
MSG[zh,status_not_running]="未运行"
MSG[zh,node_is]="节点"
MSG[zh,eth_deposit_reminder]="重要提示：请向您的coinbase地址转入Sepolia ETH测试代币（建议0.01ETH以上），以确保节点正常运行。"

# Print header
print_header() {
  clear
  echo "================================================"
  echo "       ${MSG[$LANGUAGE,header]}           "
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

# Function to change language
change_language() {
  if [ "$LANGUAGE" = "en" ]; then
    LANGUAGE="zh"
    echo "语言已更改为中文"
  else
    LANGUAGE="en"
    echo "Language changed to English"
  fi
  
  sleep 1
  main_menu
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
set timeout -1
spawn bash -i -c "curl -s https://install.aztec.network | bash -i"
expect "Do you wish to continue? (y/n)"
send "y\r"
expect "Building initial Docker image"
expect "Aztec is ready to use"
send_user "\nAztec installation completed successfully!\n"
exit 0
EOF

  # Make the expect script executable
  chmod +x /tmp/aztec_install.exp

  # Check if expect is installed, if not install it
  if ! command -v expect &> /dev/null; then
      echo "Installing 'expect' package to handle interactive prompts..."
      sudo apt-get install expect -y
      check_error "Failed to install 'expect' package"
  fi

  # Run the expect script and wait for it to complete
  echo "Starting Aztec installation. This may take several minutes..."
  echo "Please be patient while Docker downloads and builds the Aztec image."
  echo ""
  /tmp/aztec_install.exp
  EXPECT_EXIT_CODE=$?
  
  # Clean up the temporary expect script
  rm /tmp/aztec_install.exp

  # Check if the installation was successful
  if [ $EXPECT_EXIT_CODE -ne 0 ]; then
    echo "⚠️ Warning: Aztec installation might not have completed properly."
    echo "We'll continue with the setup, but you might need to run the installation again if needed."
  else
    echo "✅ Aztec installation completed successfully!"
  fi

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
  
  # Determine the correct path based on user
  if [ "$(id -u)" -eq 0 ]; then
    AZTEC_BIN_PATH="/root/.aztec/bin/aztec"
    AZTEC_UP_PATH="/root/.aztec/bin/aztec-up"
  else
    AZTEC_BIN_PATH="$HOME/.aztec/bin/aztec"
    AZTEC_UP_PATH="$HOME/.aztec/bin/aztec-up"
  fi
  
  # 5. Update Aztec
  print_section "5. Updating Aztec"
  
  # Check if aztec exists before running update
  if [ -f "$AZTEC_BIN_PATH" ]; then
    echo "Aztec binary found at $AZTEC_BIN_PATH"
    
    # Check if aztec-up exists
    if [ -f "$AZTEC_UP_PATH" ]; then
      echo "Running aztec-up alpha-testnet..."
      "$AZTEC_UP_PATH" alpha-testnet
      if [ $? -ne 0 ]; then
        echo "⚠️ Warning: aztec-up command encountered an error."
        echo "This might be temporary. We'll continue with the rest of the setup."
      else
        echo "✅ Aztec updated successfully to alpha-testnet!"
      fi
    else
      echo "⚠️ Warning: aztec-up command not found at $AZTEC_UP_PATH"
      echo "Trying alternative approach using the aztec command directly..."
      
      # Try using the aztec command directly instead
      "$AZTEC_BIN_PATH" up alpha-testnet
      if [ $? -ne 0 ]; then
        echo "⚠️ Warning: Failed to update Aztec using direct command."
        echo "We'll continue with the rest of the setup."
        echo "You may need to run 'aztec up alpha-testnet' manually after installation."
      else
        echo "✅ Aztec updated successfully to alpha-testnet!"
      fi
    fi
  else
    echo "⚠️ Warning: Aztec binary not found at $AZTEC_BIN_PATH after installation."
    echo "This could be because:"
    echo "1. The installation is still in progress in the background"
    echo "2. There was an issue with the Aztec installation"
    echo ""
    echo "We'll continue with the rest of the setup."
    echo "You may need to manually check the installation by running:"
    echo "  ls -la $HOME/.aztec/bin/"
    echo "Once installation completes, you may need to run 'aztec up alpha-testnet' manually."
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
    if [ "$LANGUAGE" = "en" ]; then
      echo "Error: Aztec is not installed. Please install it first."
      read -p "Press Enter to return to the main menu..."
    else
      echo "错误：Aztec未安装。请先安装Aztec。"
      read -p "按Enter键返回主菜单..."
    fi
    main_menu
    return
  fi
  
  # Installing screen if not available
  if ! command -v screen &> /dev/null; then
    if [ "$LANGUAGE" = "en" ]; then
      echo "Installing screen..."
    else
      echo "正在安装screen..."
    fi
    sudo apt-get install screen -y
    check_error "Failed to install screen"
  fi

  # Get public IP address
  if [ "$LANGUAGE" = "en" ]; then
    echo "Detecting your public IP address..."
  else
    echo "正在检测您的公共IP地址..."
  fi
  PUBLIC_IP=$(curl -s ipv4.icanhazip.com)
  check_error "Failed to detect public IP address"
  
  if [ "$LANGUAGE" = "en" ]; then
    echo "Your public IP address is: $PUBLIC_IP"
    echo ""
    echo "Please provide the following information to start your Aztec node:"
    echo "(Press Ctrl+C at any time to cancel)"
  else
    echo "您的公共IP地址是：$PUBLIC_IP"
    echo ""
    echo "请提供以下信息以启动您的Aztec节点："
    echo "（随时按Ctrl+C取消）"
  fi
  echo ""

  if [ "$LANGUAGE" = "en" ]; then
    read -p "Enter your L1 RPC URL: " RPC_URL
  else
    read -p "输入您的L1 RPC URL: " RPC_URL
  fi
  check_error "Failed to read RPC URL"

  if [ "$LANGUAGE" = "en" ]; then
    read -p "Enter your L1 Consensus Host URL (Beacon URL): " BEACON_URL
  else
    read -p "输入您的L1共识主机URL（Beacon URL）: " BEACON_URL
  fi
  check_error "Failed to read Beacon URL"

  if [ "$LANGUAGE" = "en" ]; then
    read -p "Enter your Validator Private Key (starts with 0x): " VALIDATOR_KEY
  else
    read -p "输入您的验证者私钥（以0x开头）: " VALIDATOR_KEY
  fi
  check_error "Failed to read Validator Private Key"

  if [ "$LANGUAGE" = "en" ]; then
    read -p "Enter your Coinbase Address (starts with 0x): " COINBASE_ADDRESS
  else
    read -p "输入您的Coinbase地址（以0x开头）: " COINBASE_ADDRESS
  fi
  check_error "Failed to read Coinbase Address"

  # Confirm information
  echo ""
  if [ "$LANGUAGE" = "en" ]; then
    echo "Please confirm your node configuration:"
    echo "L1 RPC URL: $RPC_URL"
    echo "L1 Consensus Host URL: $BEACON_URL"
    echo "Validator Private Key: ${VALIDATOR_KEY:0:6}...${VALIDATOR_KEY: -4}"
    echo "Coinbase Address: $COINBASE_ADDRESS"
    echo "Public IP: $PUBLIC_IP"
    echo ""
    echo "${MSG[$LANGUAGE,eth_deposit_reminder]}"
    echo ""
    read -p "Is this information correct? (y/n): " CONFIRM
  else
    echo "请确认您的节点配置："
    echo "L1 RPC URL: $RPC_URL"
    echo "L1共识主机URL: $BEACON_URL"
    echo "验证者私钥: ${VALIDATOR_KEY:0:6}...${VALIDATOR_KEY: -4}"
    echo "Coinbase地址: $COINBASE_ADDRESS"
    echo "公共IP: $PUBLIC_IP"
    echo ""
    echo "${MSG[$LANGUAGE,eth_deposit_reminder]}"
    echo ""
    read -p "这些信息正确吗？(y/n): " CONFIRM
  fi
  
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    if [ "$LANGUAGE" = "en" ]; then
      echo "Setup canceled. You can try again."
      read -p "Press Enter to return to the main menu..."
    else
      echo "设置已取消。您可以重试。"
      read -p "按Enter键返回主菜单..."
    fi
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
  if [ "$LANGUAGE" = "en" ]; then
    echo "Starting Aztec node in a screen session..."
  else
    echo "正在screen会话中启动Aztec节点..."
  fi
  screen -dmS aztec bash -c "$SCRIPT_PATH"
  check_error "Failed to start screen session"

  echo ""
  if [ "$LANGUAGE" = "en" ]; then
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
  else
    echo "您的Aztec节点现在正在名为'aztec'的screen会话中运行"
    echo ""
    echo "要连接到screen会话并查看节点输出："
    echo "  screen -r aztec"
    echo ""
    echo "要从screen会话分离（不停止节点）："
    echo "  按Ctrl+A，然后按D"
    echo ""
    echo "如果您需要稍后重新启动节点，可以运行："
    echo "  $SCRIPT_PATH"
    echo ""
    read -p "按Enter键返回主菜单..."
  fi
  main_menu
}

# Function to display status
display_status() {
  print_section "Aztec Node Status"
  
  # Check if Aztec is installed
  if check_aztec_installed; then
    if [ "$LANGUAGE" = "en" ]; then
      echo "✅ Aztec is installed"
      echo "   Version: $($HOME/.aztec/bin/aztec --version 2>/dev/null || echo 'Unknown')"
    else
      echo "✅ Aztec已安装"
      echo "   版本: $($HOME/.aztec/bin/aztec --version 2>/dev/null || echo '未知')"
    fi
  else
    if [ "$LANGUAGE" = "en" ]; then
      echo "❌ Aztec is not installed"
    else
      echo "❌ Aztec未安装"
    fi
  fi
  
  # Check if Docker is installed
  if check_docker_installed; then
    if [ "$LANGUAGE" = "en" ]; then
      echo "✅ Docker is installed"
      echo "   Version: $(docker --version | cut -d ' ' -f3 | tr -d ',')"
    else
      echo "✅ Docker已安装"
      echo "   版本: $(docker --version | cut -d ' ' -f3 | tr -d ',')"
    fi
  else
    if [ "$LANGUAGE" = "en" ]; then
      echo "❌ Docker is not installed"
    else
      echo "❌ Docker未安装"
    fi
  fi
  
  # Check if screen session exists
  if screen -list | grep -q aztec; then
    if [ "$LANGUAGE" = "en" ]; then
      echo "✅ Aztec node is running in screen session"
    else
      echo "✅ Aztec节点正在screen会话中运行"
    fi
  else
    if [ "$LANGUAGE" = "en" ]; then
      echo "❌ No running Aztec node detected"
    else
      echo "❌ 未检测到运行中的Aztec节点"
    fi
  fi
  
  # Check if start script exists
  if [ -f "$HOME/start-aztec-node.sh" ]; then
    if [ "$LANGUAGE" = "en" ]; then
      echo "✅ Node start script exists: $HOME/start-aztec-node.sh"
    else
      echo "✅ 节点启动脚本存在: $HOME/start-aztec-node.sh"
    fi
  else
    if [ "$LANGUAGE" = "en" ]; then
      echo "❌ Node start script not found"
    else
      echo "❌ 未找到节点启动脚本"
    fi
  fi
  
  echo ""
  if [ "$LANGUAGE" = "en" ]; then
    read -p "Press Enter to return to the main menu..."
  else
    read -p "按Enter键返回主菜单..."
  fi
  main_menu
}

# Function to display main menu
main_menu() {
  print_header
  
  # Check installation status for menu display
  AZTEC_INSTALLED="not installed"
  if check_aztec_installed; then
    AZTEC_INSTALLED="${MSG[$LANGUAGE,status_installed]}"
  else
    AZTEC_INSTALLED="${MSG[$LANGUAGE,status_not_installed]}"
  fi
  
  NODE_RUNNING="not running"
  if screen -list | grep -q aztec; then
    NODE_RUNNING="${MSG[$LANGUAGE,status_running]}"
  else
    NODE_RUNNING="${MSG[$LANGUAGE,status_not_running]}"
  fi
  
  echo "${MSG[$LANGUAGE,current_status]} $AZTEC_INSTALLED, ${MSG[$LANGUAGE,node_is]} $NODE_RUNNING"
  echo ""
  echo "${MSG[$LANGUAGE,choose_option]}"
  echo "1. ${MSG[$LANGUAGE,install_option]}"
  echo "2. ${MSG[$LANGUAGE,run_option]}"
  echo "3. ${MSG[$LANGUAGE,status_option]}"
  echo "4. ${MSG[$LANGUAGE,language_option]}"
  echo "5. ${MSG[$LANGUAGE,exit_option]}"
  echo ""
  read -p "${MSG[$LANGUAGE,enter_choice]} [1-5]: " choice
  
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
      change_language
      ;;
    5)
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
