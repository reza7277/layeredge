#!/bin/bash

# Display a banner with animation
display_banner() {
    echo "
██████╗ ███████╗███████╗ █████╗     ███████╗██████╗ ███████╗███████╗
██╔══██╗██╔════╝╚══███╔╝██╔══██╗    ╚════██║╚════██╗╚════██║╚════██║
██████╔╝█████╗    ███╔╝ ███████║        ██╔╝ █████╔╝    ██╔╝    ██╔╝
██╔══██╗██╔══╝   ███╔╝  ██╔══██║       ██╔╝ ██╔═══╝    ██╔╝    ██╔╝ 
██║  ██║███████╗███████╗██║  ██║       ██║  ███████╗   ██║     ██║  
╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝       ╚═╝  ╚══════╝   ╚═╝     ╚═╝  
"
    echo "LayerEdge Light Node :)"
    echo "Created by: Reza"
    echo "Join us: https://t.me/Web3loverz"
    sleep 1
}

# Call the banner function
display_banner
sleep 5

# Define colors for output messages
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check command execution status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 completed successfully${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

echo "Starting automatic installation of Light Node and dependencies..."

# Update the system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y
check_status "System update"

# Install essential dependencies (git, curl, screen)
echo "Installing essential dependencies..."
sudo apt install -y git curl screen
check_status "Essential dependencies installation"

# Check and install Go (version 1.21.6)
if ! command -v go >/dev/null 2>&1 || [ "$(go version | cut -d' ' -f3 | cut -d'.' -f2)" -lt 21 ]; then
    echo "Installing Go 1.21.6..."
    wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
    rm go1.21.6.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc  # Apply the changes to .bashrc after Go installation
    go version
    check_status "Go installation"
else
    echo -e "${GREEN}Go $(go version) is already installed and meets the requirements (1.21.6 or higher)${NC}"
fi

# Check and install Rust (version 1.85.1)
if ! command -v rustc >/dev/null 2>&1 || [ "$(rustc --version | cut -d' ' -f2 | cut -d'.' -f1).$(rustc --version | cut -d' ' -f2 | cut -d'.' -f2)" \< "1.85" ]; then
    echo "Installing Rust 1.85.1..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup install 1.85.1
    rustup default 1.85.1
    rustc --version
    check_status "Rust installation"
else
    echo -e "${GREEN}Rust $(rustc --version) is already installed and meets the requirements (1.85.1)${NC}"
fi

# Install RISC0 toolchain
echo "Installing RISC0 toolchain..."
curl -L https://risczero.com/install | bash
echo 'export PATH=$PATH:$HOME/.risc0/bin' >> ~/.bashrc
source ~/.bashrc  # Apply the changes to .bashrc after RISC0 installation
rzup install
check_status "RISC0 toolchain installation"

# Clone the Light Node repository
if [ ! -d "~/light-node" ]; then
    echo "Cloning Light Node repository..."
    git clone https://github.com/Layer-Edge/light-node.git ~/light-node
    check_status "Repository cloning"
fi

# Navigate to the light-node folder
cd ~/light-node || exit

# Prompt the user for the private key and remove "0x" if present
echo "Enter your private key for Light Node (without '0x' prefix, leave empty for default 'cli-node-private-key'):"
read -r user_private_key
if [ -z "$user_private_key" ]; then
    user_private_key="cli-node-private-key"
    echo -e "${RED}Using default PRIVATE_KEY='cli-node-private-key'${NC}"
else
    user_private_key=$(echo "$user_private_key" | sed 's/^0x//')
    echo -e "${GREEN}Private key received: $user_private_key${NC}"
fi

# Create .env file for configuration
echo "Creating .env file in ~/light-node..."
cat <<EOL > ~/light-node/.env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='$user_private_key'
EOL
check_status "Creating .env file"

# Navigate to risc0-merkle-service directory
cd ~/light-node/risc0-merkle-service || exit

# Run risc0-merkle-service in a screen session
echo "Starting risc0-merkle-service..."
screen -dmS risc0-merkle bash -c "cargo build && cargo run; exec bash"
check_status "Running risc0-merkle-service"

# Wait 5 minutes for risc0-merkle-service to initialize
echo "Waiting 5 minutes for risc0-merkle-service..."
sleep 300

# Ensure we are back in the light-node directory before running Light Node
cd ~/light-node || exit

# Build and run Light Node in a screen session
echo "Building and running Light Node..."
go build
check_status "Building Light Node"
screen -dmS light-node bash -c "./light-node; exec bash"
check_status "Running Light Node"

echo -e "${GREEN}Automatic installation complete!${NC}"
echo "Check the status using:"
echo "  - screen -r risc0-merkle"
echo "  - screen -r light-node"
echo "Exit screen with Ctrl+A then D"
