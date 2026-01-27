#!/bin/bash

sudo apt update && sudo apt upgrade -y

# ComputePortal Cluster Node Installation and Network Join Script
echo "Installing Cluster Node Interface..."
sudo snap install tailscale
sudo tailscale up --auth-key=d2d63b15ee202cc9d7f12880d9d5d8a2662f50c52a848f04  --login-server=https://headscale.computeportal.net:8080 --accept-routes

# Set tailscaled verbosity to 1 (snap hardcodes --verbose 10)
sudo mkdir -p /etc/systemd/system/snap.tailscale.tailscaled.service.d
cat <<'OVERRIDE' | sudo tee /etc/systemd/system/snap.tailscale.tailscaled.service.d/verbose.conf
[Service]
ExecStart=
ExecStart=/snap/tailscale/154/bin/tailscaled --socket /var/snap/tailscale/common/socket/tailscaled.sock --statedir /var/snap/tailscale/common --verbose 1
OVERRIDE
sudo systemctl daemon-reload
sudo systemctl restart snap.tailscale.tailscaled.service

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
sudo usermod -aG sudo worker

# Set up SSH key authentication (no password)
sudo mkdir -p /home/worker/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUUE9BNVpjQgwG1oNHikldvI5kLU/6cY3YzhkE92h1t vm@computeportal.io" | sudo tee /home/worker/.ssh/authorized_keys
sudo chown -R worker:worker /home/worker/.ssh
sudo chmod 700 /home/worker/.ssh
sudo chmod 600 /home/worker/.ssh/authorized_keys

# Disable password authentication for worker
sudo passwd -d worker
echo "User 'worker' created with SSH key authentication (no password)"

echo "Installation and network join complete!"
echo "Note: You may need to authorize this device in your network controller."
