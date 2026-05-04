#!/bin/bash
# Setup script for Resilient Recursive DNS Architecture
# Run with: sudo bash setup.sh

set -e

echo "=== Resilient Recursive DNS Architecture Setup ==="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "[1/5] Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

echo "[2/5] Installing Unbound..."
sudo apt-get install -y unbound unbound-anchor wget

echo "[3/5] Installing AdGuard Home dependencies..."
sudo apt-get install -y curl

echo "[4/5] Creating directories and setting permissions..."
sudo mkdir -p /var/lib/unbound
sudo mkdir -p /var/log/unbound
sudo chown -R unbound:unbound /var/lib/unbound
sudo chown -R unbound:unbound /var/log/unbound

echo "[5/5] Downloading root hints..."
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
sudo chown unbound:unbound /var/lib/unbound/root.hints

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Copy config/unbound.conf to /etc/unbound/unbound.conf"
echo "2. Enable DNSSEC validation: sudo unbound-anchor"
echo "3. Test Unbound: unbound-control -c /etc/unbound/unbound.conf status"
echo "4. Start Unbound: sudo systemctl restart unbound"
echo "5. Install and configure AdGuard Home"
echo ""
echo "For automated root hints updates, add this cron job:"
echo "0 0 * * 0 wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root && systemctl restart unbound"
echo ""