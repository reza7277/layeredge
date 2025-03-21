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

# Call the banner function
display_banner

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Update system and install dependencies
echo "Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y build-essential git curl jq unzip wget tmux software-properties-common lsof

# Install Go 1.23.1 with explicit PATH setup
echo "Installing Go 1.23.1..."
wget -q https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to download Go 1.23.1"
    exit 1
fi
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to extract Go 1.23.1"
    exit 1
fi

# Set PATH explicitly for this session
export PATH=$PATH:/usr/local/go/bin
# Persist PATH for future sessions
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Verify Go installation
if ! command -v go >/dev/null 2>&1; then
    echo "Go installation failed: 'go' command not found"
    exit 1
fi
go version || { echo "Go installation failed"; exit 1; }
echo "Go installed successfully: $(go version)"

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustc --version || { echo "Rust installation failed"; exit 1; }

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash
source ~/.bashrc
rzup install || { echo "Risc0 Toolchain installation failed"; exit 1; }

# Clean up and clone the repository
echo "Cloning LayerEdge Light Node repository..."
rm -rf ~/light-node  # Remove old version if exists
git clone https://github.com/Layer-Edge/light-node.git ~/light-node || { echo "Git clone failed"; exit 1; }
cd ~/light-node || exit 1

# Fix Go version in go.mod
echo "Fixing Go version in go.mod..."
[ -f go.mod ] && sed -i 's/go 1.23.1/go 1.23/' go.mod

# Get user input for configuration
echo "Enter your private key: "
read -s PRIVATE_KEY
echo "Enter your Wallet Address: "
read WALLET_ADDRESS

# Create environment file (.env)
echo "Saving configuration..."
cat <<EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY=$PRIVATE_KEY
WALLET_ADDRESS=$WALLET_ADDRESS
EOF

# Create log directory
mkdir -p /var/log/light-node
touch /var/log/light-node.log

# Check and free port 3001 if in use
echo "Checking port 3001..."
PORT_PID=$(lsof -t -i:3001)
if [ -n "$PORT_PID" ]; then
    echo "Port 3001 is in use by PID $PORT_PID. Killing it..."
    kill -9 "$PORT_PID"
    sleep 2
fi

# Build and start Merkle Service
echo "Building and starting Merkle Service..."
cd ~/light-node/risc0-merkle-service || exit 1
tmux new-session -d -s merkle-service 'cargo build --release && cargo run --release >> /var/log/light-node.log 2>&1'

# Wait for Merkle Service to initialize
sleep 10

# Build and run Light Node
echo "Building and running Light Node..."
cd ~/light-node/light-node || exit 1
go build -v || { echo "Light Node build failed"; exit 1; }
tmux new-session -d -s light-node './light-node >> /var/log/light-node.log 2>&1'

echo "Light Node setup completed successfully!"
echo "Monitor logs with: tail -f /var/log/light-node.log"

# Manual run instructions
echo "To run the servers manually, use these commands:"
echo "1. Merkle Service: tmux attach-session -t merkle-service"
echo "2. Light Node: tmux attach-session -t light-node"
echo "Check logs: tail -f /var/log/light-node.log"
