# Troubleshooting Guide
## Resilient Recursive DNS Architecture

### Common Issues

#### 1. Unbound Service Won't Start

**Problem:** `systemctl restart unbound` fails or service stops immediately

**Solutions:**

```bash
# Check configuration syntax
sudo unbound-checkconf

# View service logs
sudo journalctl -u unbound -xe

# Check for port conflicts
sudo netstat -tlnp | grep 5335

# Verify permissions
sudo ls -la /var/lib/unbound/
sudo ls -la /var/log/unbound/
```

#### 2. DNS Queries Not Resolving

**Problem:** `dig @127.0.0.1 -p 5335 google.com` returns no results

**Solutions:**

```bash
# Test connectivity
ping 8.8.8.8

# Check if Unbound is listening
sudo netstat -tlnp | grep unbound

# Query with verbose output
dig @127.0.0.1 -p 5335 +trace google.com

# Check firewall
sudo ufw status
sudo ufw allow 5335

# Check interface binding
grep "interface:" /etc/unbound/unbound.conf
```

#### 3. DNSSEC Validation Fails

**Problem:** DNSSEC queries return SERVFAIL

**Solutions:**

```bash
# Reinitialize DNSSEC trust anchors
sudo unbound-anchor -r /var/lib/unbound/root.key

# Verify DNSSEC configuration
grep "dnssec" /etc/unbound/unbound.conf

# Test DNSSEC
dig @127.0.0.1 -p 5335 +dnssec www.dnssec-failed.org
```

#### 4. High CPU Usage

**Problem:** Unbound consuming excessive CPU

**Solutions:**

```bash
# Check query load
unbound-control -c /etc/unbound/unbound.conf stats

# Monitor performance
watch -n 1 'unbound-control -c /etc/unbound/unbound.conf stats_noreset'

# Reduce thread count in unbound.conf if on low-power hardware:
num-threads: 2  # Instead of 4

# Check for DNS amplification attacks
grep "dropped queries" /var/log/unbound/unbound.log
```

#### 5. Memory Issues

**Problem:** Out of memory errors

**Solutions:**

```bash
# Check memory usage
free -h

# Reduce cache sizes in unbound.conf:
msg-cache-size: 50m  # From 100m
rrset-cache-size: 100m  # From 200m

# Restart service after changes
sudo systemctl restart unbound
```

#### 6. Slow DNS Resolution

**Problem:** DNS queries are slow

**Solutions:**

```bash
# Check query timing
dig @127.0.0.1 -p 5335 +stats google.com

# Verify root hints are up-to-date
ls -la /var/lib/unbound/root.hints

# Update root hints manually
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
sudo systemctl restart unbound

# Check for internet connectivity issues
mtr 8.8.8.8
```

#### 7. AdGuard Home Can't Connect to Unbound

**Problem:** "Connection refused" or "Timeout" errors

**Solutions:**

```bash
# Verify Unbound is running
sudo systemctl status unbound

# Check listening ports
sudo netstat -tlnp | grep 5335

# Test connection from localhost
dig @127.0.0.1 -p 5335 google.com

# Verify AdGuard Home settings:
# - Upstream DNS: 127.0.0.1:5335
# - Bootstrap DNS: 127.0.0.1:5335

# Check firewall
sudo ufw allow 5335/udp
sudo ufw allow 5335/tcp
```

### Diagnostic Commands

```bash
# General status
sudo systemctl status unbound

# Configuration validation
sudo unbound-checkconf

# Query statistics
unbound-control -c /etc/unbound/unbound.conf stats

# View recent queries
sudo tail -50 /var/log/unbound/unbound.log

# Monitor in real-time
sudo tail -f /var/log/unbound/unbound.log

# Test DNS query
dig @127.0.0.1 -p 5335 +trace example.com

# Check service dependencies
ldd /usr/sbin/unbound
```

### Log Locations

- **Unbound logs**: `/var/log/unbound/unbound.log`
- **Systemd logs**: `journalctl -u unbound -n 50`
- **System logs**: `/var/log/syslog`

### Performance Monitoring

```bash
# Real-time stats
watch -n 2 'unbound-control -c /etc/unbound/unbound.conf stats_noreset'

# Query volume
grep "queries received" /var/log/unbound/unbound.log

# Cache hit rate
unbound-control -c /etc/unbound/unbound.conf stats | grep -i cache
```

### Reset to Defaults

If configuration becomes corrupted:

```bash
# Backup current config
sudo cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.backup

# Restore default
sudo apt-get install --reinstall unbound

# Reapply custom configuration
sudo cp config/unbound.conf /etc/unbound/unbound.conf.d/local.conf

# Restart service
sudo systemctl restart unbound
```

### Getting Help

- Check Unbound documentation: `man unbound`
- View configuration options: `man unbound.conf`
- Unbound GitHub: https://github.com/NLnetLabs/unbound
- Community support: https://unbound.nlnetlabs.nl/

### Before Filing an Issue

1. Collect diagnostic information:
   ```bash
   echo "=== System Info ===" > diagnostics.txt
   uname -a >> diagnostics.txt
   echo "=== Unbound Version ===" >> diagnostics.txt
   unbound -v >> diagnostics.txt
   echo "=== Configuration ===" >> diagnostics.txt
   unbound-checkconf -p >> diagnostics.txt
   echo "=== Recent Errors ===" >> diagnostics.txt
   sudo tail -100 /var/log/unbound/unbound.log >> diagnostics.txt
   ```

2. Share relevant logs with issue report