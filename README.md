

# LayerEdge Full Node Setup Script

## Introduction

This script automates the setup of a LayerEdge Full Node from scratch. It will prompt you for necessary inputs and configure everything accordingly.

### Prerequisites

Ensure you have a fresh Ubuntu 20.04+ server with at least:

- **CPU**: 4 cores
- **RAM**: 8GB (16GB recommended)
- **Storage**: 200GB SSD
- **Stable Internet Connection**

## Setup Instructions

1. **Run the setup script with a single command:**

   To install and configure the full node, run the following command on your server:

   ```bash
   bash <(curl -s https://raw.githubusercontent.com/reza7277/layeredge/main/setup_layeredge.sh)
   ```

2. The script will automatically update your system, install the necessary dependencies, and configure the full node. During the process, you will be prompted for required inputs such as your private key and wallet address.

### What the script does:

- **Updates and installs necessary dependencies** (Go, Rust, Risc0 toolchain, etc.)
- **Clones the LayerEdge Full Node repository** from GitHub
- **Configures environment variables** and saves them in a `.env` file
- **Starts the Merkle service** using Cargo (Rust)
- **Builds and runs the LayerEdge Full Node** (Go)
- **Logs are saved and can be monitored** with `tail -f /var/log/layeredge.log`
