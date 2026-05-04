# Installation Guide
## Resilient Recursive DNS Architecture

### Prerequisites

- Raspberry Pi (3B+ or newer recommended) or compatible Linux device
- Debian-based Linux distribution (Debian 10+, Ubuntu 20.04+, Raspberry Pi OS)
- Root or sudo access
- Static IP address configured
- Internet connectivity
- Minimum 1GB RAM, 500MB free disk space

### Quick Start

#### Option 1: Automated Setup (Recommended)

```bash
# Clone this repository
git clone https://github.com/jeaniius/resilient-recursive-dns-architecture.git
cd resilient-recursive-dns-architecture

# Run setup script
sudo bash scripts/setup.sh

# Copy Unbound configuration
sudo cp config/unbound.conf /etc/unbound/unbound.conf.d/local.conf

# Initialize DNSSEC
sudo unbound-anchor

# Start Unbound
sudo systemctl restart unbound
sudo systemctl enable unbound
```

#### Option 2: Manual Installation

##### Step 1: Update System

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

##### Step 2: Install Unbound

```bash
sudo apt-get install -y unbound unbound-anchor wget
```

##### Step 3: Configure Unbound

```bash
# Copy provided configuration (or edit manually)
sudo cp config/unbound.conf /etc/unbound/unbound.conf.d/local.conf

# Create log directory
sudo mkdir -p /var/log/unbound
sudo chown unbound:unbound /var/log/unbound

# Download root hints
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
```

##### Step 4: Initialize DNSSEC

```bash
sudo unbound-anchor
```

##### Step 5: Start and Enable Unbound

```bash
sudo systemctl start unbound
sudo systemctl enable unbound

# Verify it's running
sudo systemctl status unbound
```

##### Step 6: Test Unbound

```bash
# Query test
dig @127.0.0.1 -p 5335 google.com

# Check status
unbound-control -c /etc/unbound/unbound.conf status
```

### AdGuard Home Installation

1. **Download AdGuard Home**
   ```bash
   cd /opt
   sudo wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v[VERSION]/AdGuardHome_linux_arm64.tar.gz
   sudo tar xvzf AdGuardHome_linux_arm64.tar.gz
   ```

2. **Run AdGuard Home**
   ```bash
   sudo ./AdGuardHome/AdGuardHome
   ```

3. **Configure AdGuard Home**
   - Access web interface: `http://[your-raspberry-pi-ip]:3000`
   - Set upstream DNS: `127.0.0.1:5335`
   - Set bootstrap DNS: `127.0.0.1:5335`
   - Enable all blocking settings

4. **Create systemd service** (optional but recommended)
   - Create `/etc/systemd/system/adguardhome.service`
   - Enable: `sudo systemctl enable adguardhome`
   - Start: `sudo systemctl start adguardhome`

### Automated Maintenance

#### Root Hints Updates

Add to crontab to automatically update root hints weekly:

```bash
sudo crontab -e

# Add this line:
0 0 * * 0 wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root && systemctl restart unbound
```

#### Security Updates

Install automatic security updates:

```bash
sudo apt-get install -y unattended-upgrades apt-listchanges

# Configure
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Verification

```bash
# Test DNS resolution
dig @127.0.0.1 -p 5335 +short google.com

# Should return IP address(es)

# Check DNSSEC validation
dig @127.0.0.1 -p 5335 dnssec-failed.org

# Should show SERVFAIL for invalid DNSSEC

# View logs
sudo tail -f /var/log/unbound/unbound.log
```

### Troubleshooting

**Unbound won't start:**
```bash
sudo unbound-checkconf /etc/unbound/unbound.conf
```

**Port 5335 in use:**
```bash
sudo lsof -i :5335
```

**DNS queries timing out:**
- Check firewall: `sudo ufw status`
- Verify interface: `ip addr show`
- Test connectivity: `ping 8.8.8.8`

### Performance Tuning

For optimal performance on Raspberry Pi:

1. Increase thread count in `unbound.conf` based on CPU cores
2. Adjust cache sizes based on available RAM
3. Monitor with: `unbound-control stats_noreset`

### Next Steps

- Configure other devices to use your DNS server
- Monitor performance with AdGuard Home dashboard
- Review logs regularly: `sudo tail /var/log/unbound/unbound.log`
- Keep system updated: `sudo apt-get update && sudo apt-get upgrade`