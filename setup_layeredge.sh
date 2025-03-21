#!/bin/bash

# Function to display a banner with animation
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

# Call the function to display the banner
display_banner

# Update & Install Dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl jq unzip wget tmux software-properties-common

# Install Go (1.23.1)
echo "Installing Go version 1.23.1..."
wget https://dl.google.com/go/go1.23.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify Go installation
go version || { echo "Go installation failed"; exit 1; }

# Install Rust (1.81.0 or higher)
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustc --version || { echo "Rust installation failed"; exit 1; }

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash
source ~/.bashrc
export PATH=$PATH:/root/.risc0/bin
rzup install || { echo "Risc0 toolchain installation failed"; exit 1; }

# Clone Light Node Repository
echo "Cloning LayerEdge Light Node repository..."
git clone https://github.com/Layer-Edge/light-node.git || { echo "Git clone failed"; exit 1; }
cd light-node

# Get User Input for Configuration
echo "Enter your private key: "
read -s PRIVATE_KEY
echo "Enter your Wallet Address: "
read WALLET_ADDRESS

# Set Environment Variables
cat <<EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY=$PRIVATE_KEY
EOF

echo "Configuration saved. Starting Merkle Service..."

# Start Merkle Service
cd risc0-merkle-service
cargo build && cargo run &

# Wait for Merkle Service to Initialize
sleep 10

# Build & Run Light Node
echo "Building and running LayerEdge Light Node..."
cd ../light-node
go build || { echo "Go build failed"; exit 1; }
./light-node &

echo "Light Node setup complete!"
echo "Monitoring logs: tail -f /var/log/light-node.log"

# Additional steps for manual server start (in case user wants to do it manually)
echo "To run the servers manually, use these commands in separate terminals:"
echo "1. Run Merkle Service: cd risc0-merkle-service && cargo build && cargo run"
echo "2. Run Light Node: cd light-node && go build && ./light-node"
