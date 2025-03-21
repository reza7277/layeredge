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

# Install Go (1.21.6)
echo "Installing Go version 1.21.6..."
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
rm go1.21.6.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

go version || { echo "Go installation failed"; exit 1; }

# Install Rust (1.85.1)
echo "Installing Rust 1.85.1..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup install 1.85.1
rustup default 1.85.1
rustc --version || { echo "Rust installation failed"; exit 1; }

# Install RISC0 Toolchain
echo "Installing RISC0 Toolchain..."
curl -L https://risczero.com/install | bash
echo 'export PATH=$PATH:$HOME/.risc0/bin' >> ~/.bashrc
source ~/.bashrc
rzup install || { echo "Risc0 toolchain installation failed"; exit 1; }

# Clone Light Node Repository
echo "Cloning LayerEdge Light Node repository..."
git clone https://github.com/Layer-Edge/light-node.git ~/light-node || { echo "Git clone failed"; exit 1; }

# Navigate to light-node directory
cd ~/light-node || exit

# Get User Input for Private Key
echo "Enter your private key (without '0x' prefix, leave empty for default 'cli-node-private-key'):"
read -r user_private_key
if [ -z "$user_private_key" ]; then
    user_private_key="cli-node-private-key"
    echo "Using default PRIVATE_KEY='cli-node-private-key'"
else
    user_private_key=$(echo "$user_private_key" | sed 's/^0x//')
    echo "Private key accepted: $user_private_key"
fi

# Create .env Configuration File
echo "Creating .env file in ~/light-node..."
cat <<EOL > ~/light-node/.env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='$user_private_key'
EOL

# Navigate to risc0-merkle-service directory
cd ~/light-node/risc0-merkle-service || exit

# Run risc0-merkle-service in a detached screen
echo "Starting risc0-merkle-service..."
screen -dmS risc0-merkle bash -c "cargo build && cargo run; exec bash"

# Wait for 5 minutes to ensure risc0-merkle-service is ready
echo "Waiting 5 minutes for risc0-merkle-service..."
sleep 300

# Navigate back to light-node directory
cd ~/light-node || exit

# Build and run light-node in a detached screen
echo "Building and running light-node..."
go build || { echo "Go build failed"; exit 1; }
screen -dmS light-node bash -c "./light-node; exec bash"

echo "Installation completed successfully!"
echo "Check status with:"
echo "  - screen -r risc0-merkle"
echo "  - screen -r light-node"
echo "Exit screen with Ctrl+A then D"
