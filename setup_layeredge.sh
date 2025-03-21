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
    
    # Typing effect for name
    echo -n "LayerEdge Node :)"
    for ((i=0; i<${#name}; i++)); do
        echo -n "${name:$i:1}"
        sleep 0.2
    done
    echo ""

    echo -n "Created by: "
    name="Reza"
    for ((i=0; i<${#name}; i++)); do
        echo -n "${name:$i:1}"
        sleep 0.2
    done
    echo ""
    
    echo "Join us: https://t.me/Web3loverz"
    sleep 1
}

# Call the function
display_banner

# Update & Install Dependencies
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl jq unzip wget tmux software-properties-common

# Install Go
echo "Installing Go..."
wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

go version

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustc --version

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash && rzup install

# Clone Full Node Repository
echo "Cloning LayerEdge Full Node repository..."
git clone https://github.com/Layer-Edge/full-node.git
cd full-node

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
POINTS_API=https://full-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF

echo "Configuration saved. Starting Merkle Service..."

# Start Merkle Service
cd risc0-merkle-service
cargo build && cargo run &

# Wait for Service to Initialize
sleep 10

# Build & Run Full Node
echo "Building and running LayerEdge Full Node..."
cd ../full-node
go build
./full-node &

echo "Full Node setup complete!"
echo "Monitor logs using: tail -f /var/log/layeredge.log"
