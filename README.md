# Aztec Network 一键安装脚本 | Aztec Network One-Click Setup Script

[English](#english) | [中文](#中文)

## 中文

### 概述

这个一键安装脚本可以帮助你在Ubuntu系统上快速部署Aztec Network节点。脚本提供了完整的自动化安装过程，包括系统依赖、Docker、Aztec工具和防火墙配置，以及节点的启动和管理。

### 快速开始

使用以下命令下载并运行安装脚本：

```bash
wget -O setup-aztec.sh https://raw.githubusercontent.com/LINDEBIJI/aztec-network/main/setup-aztec.sh && chmod +x setup-aztec.sh && ./setup-aztec.sh
```

### 使用说明

脚本启动后会显示主菜单，提供以下选项：

1. **安装Aztec节点** - 安装所有依赖、Docker、Aztec工具和配置防火墙
2. **运行Aztec节点** - 在screen会话中启动节点
3. **检查状态** - 显示安装和运行状态，及节点日志
4. **Change Language** - 切换为英文界面
5. **退出** - 退出脚本

### 安装步骤

1. 选择选项 **1** 开始安装过程

### 运行节点

1. 完成安装后，选择选项 **2** 运行节点
2. 按提示输入以下信息：
   - L1 RPC URL
   - L1共识主机URL (Beacon URL)
   - 钱包私钥 (以0x开头)
   - 钱包地址 (以0x开头)
3. 确认信息后，节点将在后台screen会话中启动
4. **重要提示**：请向您的钱包地址转入Sepolia ETH测试代币（建议0.01ETH以上），以确保节点正常运行

### 节点管理

- 使用 `screen -r aztec` 查看节点输出
- 按 `Ctrl+A` 然后按 `D` 可以从screen会话分离而不停止节点
- 使用选项 **3** 随时检查节点状态和最近日志

### 系统要求

- Ubuntu Linux系统
- 至少8核CPU 16GB RAM和512GB存储空间

---

## English

### Overview

This one-click installation script helps you quickly deploy an Aztec Network node on Ubuntu systems. The script provides a fully automated installation process, including system dependencies, Docker, Aztec tools, and firewall configuration, as well as node startup and management.

### Features

- Fully automated installation of all necessary components
- Automatic network and firewall configuration
- Bilingual interface supporting English and Chinese
- Simplified node startup and management
- Detailed status monitoring and log viewing

### Quick Start

Use the following command to download and run the installation script:

```bash
wget -O setup-aztec.sh https://raw.githubusercontent.com/LINDEBIJI/aztec-network/main/setup-aztec.sh && chmod +x setup-aztec.sh && ./setup-aztec.sh
```

### Usage Instructions

After the script starts, it will display a main menu with the following options:

1. **Install Aztec Node** - Install all dependencies, Docker, Aztec tools, and configure firewall
2. **Run Aztec Node** - Start the node in a screen session
3. **Check Status** - Display installation and running status, along with node logs
4. **更改语言** - Switch to Chinese interface
5. **Exit** - Exit the script

### Installation Steps

1. Select option **1** to begin the installation process

### Running the Node

1. After completing the installation, select option **2** to run the node
2. Enter the following information when prompted:
   - L1 RPC URL
   - L1 Consensus Host URL (Beacon URL)
   - Wallet Private Key (starts with 0x)
   - Wallet Address (starts with 0x)
3. After confirming the information, the node will start in a background screen session
4. **Important Note**: Please deposit Sepolia ETH (recommend at least 0.01 ETH) to your Wallet address for the node to function properly

### Node Management

- Use `screen -r aztec` to view node output
- Press `Ctrl+A` then `D` to detach from the screen session without stopping the node
- Use option **3** to check node status and recent logs at any time

### System Requirements

- Ubuntu Linux system (recommended 22.04 LTS or higher)
- At least 8 Core CPU 16GB RAM and 512GB storage space
