#!/bin/bash

# 显示彩色输出的函数
print_colored() {
    echo -e "\e[1;36m$1\e[0m"
}

print_success() {
    echo -e "\e[1;32m$1\e[0m"
}

print_error() {
    echo -e "\e[1;31m$1\e[0m"
}

# 1. 安装依赖项
print_colored "1. 安装依赖项"

# 更新包
print_colored "更新包..."
sudo apt-get update && sudo apt-get upgrade -y

# 安装软件包
print_colored "安装软件包..."
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# 安装Docker
print_colored "安装Docker..."
sudo apt update -y && sudo apt upgrade -y
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    sudo apt-get remove $pkg -y
done

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y && sudo apt upgrade -y

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# 测试Docker
print_colored "测试Docker..."
sudo docker run hello-world

sudo systemctl enable docker
sudo systemctl restart docker

# 2. 安装Aztec工具
print_colored "2. 安装Aztec工具"

# 创建一个临时预期文件来自动回答"y"
print_colored "准备安装Aztec工具（将自动接受PATH更新）..."
expect_script=$(cat << 'EOF'
#!/usr/bin/expect -f
spawn bash -i -c "curl -s https://install.aztec.network | bash -i"
expect "Add it to * to make the aztec binaries accessible? (y/n)"
send "y\r"
expect eof
EOF
)

# 检查expect是否安装
if ! command -v expect &> /dev/null; then
    print_colored "安装expect工具..."
    sudo apt-get install expect -y
fi

# 使用expect执行安装
echo "$expect_script" > /tmp/aztec_install_expect.sh
chmod +x /tmp/aztec_install_expect.sh
/tmp/aztec_install_expect.sh
rm /tmp/aztec_install_expect.sh

# 手动更新PATH（以防自动添加失败）
if [ -f "$HOME/.bash_profile" ]; then
    if ! grep -q ".aztec/bin" "$HOME/.bash_profile"; then
        echo 'export PATH="$PATH:$HOME/.aztec/bin"' >> "$HOME/.bash_profile"
    fi
fi

if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q ".aztec/bin" "$HOME/.bashrc"; then
        echo 'export PATH="$PATH:$HOME/.aztec/bin"' >> "$HOME/.bashrc"
    fi
fi

# 更新当前会话的PATH
export PATH="$PATH:$HOME/.aztec/bin"

print_colored "Aztec工具安装完成"

# 提示重启终端
print_colored "请重启您的终端以应用更改，然后继续下面的步骤"
print_colored "按回车键继续..."
read

# 3. 验证安装
print_colored "3. 检查是否安装成功"
# 确保可以找到 aztec 命令
if [ -f "$HOME/.aztec/bin/aztec-nargo" ]; then
    $HOME/.aztec/bin/aztec-nargo --help
    print_success "Aztec Nargo 已成功安装"
else
    print_error "无法找到 aztec-nargo 命令，安装可能不完整"
fi

if [ -f "$HOME/.aztec/bin/aztec-wallet" ]; then
    $HOME/.aztec/bin/aztec-wallet --help
    print_success "Aztec Wallet 已成功安装"
else
    print_error "无法找到 aztec-wallet 命令，安装可能不完整"
fi

# 4. 更新Aztec
print_colored "4. 更新Aztec"
if [ -f "$HOME/.aztec/bin/aztec-up" ]; then
    $HOME/.aztec/bin/aztec-up alpha-testnet
else
    print_colored "尝试从其他位置寻找 aztec-up..."
    if command -v aztec-up &> /dev/null; then
        aztec-up alpha-testnet
    else
        print_error "无法找到 aztec-up 命令，请在完成安装后手动运行: aztec-up alpha-testnet"
    fi
fi

# 5. 启用防火墙并开放端口
print_colored "5. 启用防火墙并开放端口"

# 防火墙
sudo ufw allow 22
sudo ufw allow ssh

# Sequencer
sudo ufw allow 40400
sudo ufw allow 8080

# 启用防火墙
print_colored "启用防火墙..."
echo "y" | sudo ufw enable

# 显示完成信息
print_success "Aztec安装和配置完成!"
print_success "防火墙规则已配置，开放端口: 22(SSH), 40400, 8080"