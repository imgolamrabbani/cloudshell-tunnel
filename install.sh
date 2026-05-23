#!/usr/bin/env bash
set -e
echo "Downloading cloudshell-tunnel..."
curl -sL https://raw.githubusercontent.com/imgolamrabbani/cloudshell-tunnel/main/cloudshell-tunnel.sh -o /tmp/cloudshell-tunnel
echo "Installing to /usr/local/bin..."
sudo mv /tmp/cloudshell-tunnel /usr/local/bin/cloudshell-tunnel
sudo chmod +x /usr/local/bin/cloudshell-tunnel
echo "Installation complete! Run 'cloudshell-tunnel' to start."
