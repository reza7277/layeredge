#!/bin/bash
# Logo installation script
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 successful${NC}"
    else
        echo -e "${RED}✗ Failed $1${NC}"
        exit 1
    fi
}

echo "Starting automatic installation of light-node and its dependencies..."

# Update the system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y
check_status "system update"

# Install essential dependencies (git, curl, screen)
echo "Installing essential dependencies..."
sudo apt install -y git curl screen
check_status "installing essential dependencies"

# Check and install Go (version 1.21.6)
if ! command -v go >/dev/null 2>&1 || [ "$(go version | cut -d' ' -f3 | cut -d'.' -f2)" -lt 21 ]; then
    echo "Go is not installed or version is lower than 1.21.6. Installing Go 1.21.6..."

    # Download and install Go 1.21.6
    wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
    rm go1.21.6.linux-amd64.tar.gz

    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc

    # Verify installation
    go version
    check_status "installing Go"
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
    check_status "installing Rust"
else
    echo -e "${GREEN}Rust $(rustc --version) is already installed and meets the requirements (1.85.1)${NC}"
fi

# Install RISC0 toolchain
echo "Installing RISC0 toolchain..."
curl -L https://risczero.com/install | bash
echo 'export PATH=$PATH:$HOME/.risc0/bin' >> ~/.bashrc
source ~/.bashrc
rzup install
check_status "installing RISC0 toolchain"

# Clone light-node repository
if [ ! -d "~/light-node" ]; then
    echo "Cloning light-node repository..."
    git clone https://github.com/Layer-Edge/light-node.git ~/light-node
    check_status "cloning repository"
fi

# Navigate to light-node folder
cd ~/light-node || exit

# Request private key from user and remove 0x if present
echo "Enter private key for light-node (without '0x' prefix, leave blank for default 'cli-node-private-key'):"
read -r user_private_key
if [ -z "$user_private_key" ]; then
    user_private_key="cli-node-private-key"
    echo -e "${RED}Using default PRIVATE_KEY='cli-node-private-key'${NC}"
else
    # Remove 0x prefix if entered by user
    user_private_key=$(echo "$user_private_key" | sed 's/^0x//')
    echo -e "${GREEN}Private key received: $user_private_key${NC}"
fi

# Create .env file with configuration
echo "Creating .env file in ~/light-node..."
cat <<EOL > ~/light-node/.env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='$user_private_key'
EOL
check_status "creating .env file"

# Navigate to risc0-merkle-service folder
cd ~/light-node/risc0-merkle-service || exit

# Run risc0-merkle-service in screen
echo "Running risc0-merkle-service..."
screen -dmS risc0-merkle bash -c "cargo build && cargo run; exec bash"
check_status "running risc0-merkle-service"

# Wait a few minutes for risc0-merkle-service to be ready
echo "Waiting 5 minutes for risc0-merkle-service..."
sleep 300

# Ensure we are back in the light-node directory before running light-node
cd ~/light-node || exit

# Run light-node in screen
echo "Building and running light-node..."
go build
check_status "building light-node"
screen -dmS light-node bash -c "./light-node; exec bash"
check_status "running light-node"

echo -e "${GREEN}Automatic installation completed!${NC}"
echo "Check status with:"
echo "  - screen -r risc0-merkle"
echo "  - screen -r light-node"
echo "Exit screen with Ctrl+A then D"
