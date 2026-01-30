#!/bin/bash

# ComputePortal Cluster Node Installation and Network Join Script
# Supports both amd64 (x86_64) and arm64 (aarch64) Ubuntu systems

set -e

echo "=========================================="
echo "ComputePortal Cluster Node Setup"
echo "=========================================="

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
    echo "WARNING: Unsupported architecture '$ARCH'. This script is tested on x86_64 and aarch64."
    echo "Proceeding anyway..."
fi

# Step 1: Fix any existing APT repository issues
echo ""
echo "[1/7] Checking and fixing APT repositories..."

# Remove problematic NVIDIA workbench repository if it exists (causes GPG errors on some systems)
for repo_file in /etc/apt/sources.list.d/*nvidia*workbench* /etc/apt/sources.list.d/*workbench*; do
    if [ -f "$repo_file" ]; then
        echo "Removing problematic repository: $repo_file"
        sudo rm -f "$repo_file"
    fi
done

# Update package lists
echo "Updating package lists..."
sudo apt-get update --fix-missing 2>/dev/null || sudo apt-get update || true
sudo apt-get upgrade -y

# Step 2: Clean up any previous tailscale installation
echo ""
echo "[2/7] Cleaning up any previous tailscale installation..."
sudo systemctl stop snap.tailscale.tailscaled.service 2>/dev/null || true
sudo snap remove tailscale 2>/dev/null || true

# Remove any existing systemd overrides (these cause issues on arm64)
if [ -d "/etc/systemd/system/snap.tailscale.tailscaled.service.d" ]; then
    echo "Removing existing systemd overrides..."
    sudo rm -rf /etc/systemd/system/snap.tailscale.tailscaled.service.d
    sudo systemctl daemon-reload
fi

# Step 3: Install tailscale
echo ""
echo "[3/7] Installing Cluster Node Interface (tailscale)..."
sudo snap install tailscale

# Wait for snap to fully initialize
echo "Waiting for tailscale to initialize..."
sleep 5

# Step 4: Start tailscaled service BEFORE running tailscale up
echo ""
echo "[4/7] Starting tailscale service..."
sudo systemctl start snap.tailscale.tailscaled.service
sleep 3

# Verify service is running
if ! systemctl is-active --quiet snap.tailscale.tailscaled.service; then
    echo "WARNING: tailscaled service may not be running. Attempting to continue..."
    sudo systemctl status snap.tailscale.tailscaled.service || true
fi

# Step 5: Connect to ComputePortal network
echo ""
echo "[5/7] Connecting to ComputePortal network..."
sudo tailscale up --auth-key=tskey-auth-d2d63b15ee202cc9d7f12880d9d5d8a2662f50c52a848f04 --login-server=https://headscale.computeportal.net:8080 --accept-routes

# Check status
echo ""
echo "Cluster Node Interface service status:"
sudo tailscale status

# Step 6: Install SSH Server
echo ""
echo "[6/7] Installing SSH Server..."
sudo apt-get install -y openssh-server

# Wait a moment for service to start
sleep 3

# Step 7: Create user account
echo ""
echo "[7/7] Setting up user account..."

# Create worker user if it doesn't exist
if ! id worker &>/dev/null; then
    echo "Creating user 'worker'..."
    sudo useradd -m -s /bin/bash worker
else
    echo "User 'worker' already exists"
fi

sudo usermod -aG sudo worker

# Set up SSH key authentication (no password)
sudo mkdir -p /home/worker/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUUE9BNVpjQgwG1oNHikldvI5kLU/6cY3YzhkE92h1t vm@computeportal.io" | sudo tee /home/worker/.ssh/authorized_keys > /dev/null
sudo chown -R worker:worker /home/worker/.ssh
sudo chmod 700 /home/worker/.ssh
sudo chmod 600 /home/worker/.ssh/authorized_keys

# Disable password authentication for worker
sudo passwd -d worker 2>/dev/null || true
echo "User 'worker' created with SSH key authentication (no password)"

echo ""
echo "=========================================="
echo "Installation and network join complete!"
echo "=========================================="
echo ""
echo "Tailscale status:"
sudo tailscale status
echo ""
echo "Note: You may need to authorize this device in your network controller."
