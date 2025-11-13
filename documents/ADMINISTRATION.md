# Splunk Administration Guide

Administration, troubleshooting, and best practices for Splunk Enterprise deployment.

## Table of Contents

- [Daily Operations](#daily-operations)
- [Security Best Practices](#security-best-practices)
- [Monitoring & Health](#monitoring--health)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Performance Tuning](#performance-tuning)
- [Backup & Recovery](#backup--recovery)

## Daily Operations

### Check System Health

```bash
# Splunk service status
sudo systemctl status Splunkd

# Check all components
sudo -u splunk /opt/splunk/bin/splunk status

# View recent errors
sudo tail -100 /opt/splunk/var/log/splunk/splunkd.log | grep -i error

# Check disk usage
df -h /opt/splunk
```

### Monitor Forwarders

Via Splunk Web:
1. Settings → Monitoring Console
2. Forwarders → Forwarder: Deployment
3. Check for disconnected forwarders

Via CLI:
```bash
# List all deployment clients
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:PASSWORD

# Check receiving connections
sudo netstat -an | grep 9997
```

### View Incoming Data

Search in Splunk Web:
```spl
# All data from last 15 minutes
index=* earliest=-15m

# Windows forwarder data
index=main sourcetype=WinEventLog:* earliest=-1h

# Check data volume by host
index=* earliest=-24h | stats count by host

# Deployment server activity
index=_internal sourcetype=splunkd component=DS*
```

## Security Best Practices

### Change Default Password

**Critical**: Change the default admin password immediately after installation.

Via CLI:
```bash
sudo -u splunk /opt/splunk/bin/splunk edit user admin \
  -password NewSecurePassword123! \
  -auth admin:5plunk#1!
```

Via Splunk Web:
1. Settings → Users → admin → Edit
2. Enter new password
3. Save

### Create Additional Admin Users

```bash
# Create new admin user
sudo -u splunk /opt/splunk/bin/splunk add user username \
  -password PASSWORD \
  -role admin \
  -auth admin:PASSWORD
```

### Enable SSL/TLS

For production deployments, enable SSL on Splunk Web:

1. Splunk Web: Settings → Server settings → General settings
2. Enable SSL: Yes
3. HTTPS port: 443 or 8443
4. Configure certificate paths

### Firewall Configuration

Restrict access to Splunk ports by source IP:

**Ubuntu/Debian (ufw):**
```bash
# Allow from specific network
sudo ufw allow from 192.168.1.0/24 to any port 8000
sudo ufw allow from 192.168.1.0/24 to any port 8089
sudo ufw allow from 192.168.1.0/24 to any port 9997
```

**RHEL/CentOS (firewalld):**
```bash
# Add rich rules for specific sources
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="8000" accept'

sudo firewall-cmd --reload
```

### Disable Unnecessary Services

```bash
# Disable distributed search if not needed
sudo -u splunk /opt/splunk/bin/splunk disable dist-search -auth admin:PASSWORD
```

## Monitoring & Health

### Monitoring Console

Access: Settings → Monitoring Console

Key areas to monitor:
- **Indexing Performance**: Settings → Indexing → Performance
- **Forwarder Status**: Settings → Forwarders → Deployment
- **Resource Usage**: Settings → Resource Usage → Instance
- **Search Performance**: Settings → Search → Activity

### Resource Monitoring

```bash
# CPU and memory usage
top -u splunk

# Disk I/O
iostat -x 5

# Network connections
sudo netstat -an | grep -E ':(8000|8089|9997)'

# Splunk process details
ps aux | grep splunk
```

### Index Health

Via Splunk Web:
1. Settings → Indexes
2. Check index sizes and bucket counts
3. Review frozen/thawed data

Via CLI:
```bash
# List all indexes with sizes
sudo -u splunk /opt/splunk/bin/splunk list index -auth admin:PASSWORD
```

### Log Monitoring

```bash
# Watch main log
sudo tail -f /opt/splunk/var/log/splunk/splunkd.log

# Search for errors
sudo grep -i error /opt/splunk/var/log/splunk/splunkd.log | tail -50

# Monitor metrics
sudo tail -f /opt/splunk/var/log/splunk/metrics.log
```

## Troubleshooting

### Splunk Won't Start

**Check license:**
```bash
# View license status
sudo -u splunk /opt/splunk/bin/splunk list licenses -auth admin:PASSWORD
```

**Check disk space:**
```bash
df -h /opt/splunk
# Need at least 5GB free
```

**Check permissions:**
```bash
ls -la /opt/splunk
# Should be owned by splunk:splunk

# Fix if needed
sudo chown -R splunk:splunk /opt/splunk
```

**View startup errors:**
```bash
sudo -u splunk /opt/splunk/bin/splunk start --answer-yes --no-prompt
# Watch for error messages
```

### Forwarders Not Connecting

**Check deployment server:**
```bash
# Verify deployment server is running
sudo -u splunk /opt/splunk/bin/splunk list deploy-server -auth admin:PASSWORD

# Check for client connections
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:PASSWORD
```

**Check receiving port:**
```bash
# Verify port 9997 is listening
sudo netstat -tuln | grep 9997

# Check firewall
sudo firewall-cmd --list-all  # RHEL
sudo ufw status               # Ubuntu
```

**Test connectivity from forwarder:**
```powershell
# Windows
Test-NetConnection -ComputerName <splunk-server> -Port 9997

# Linux
telnet <splunk-server> 9997
```

**Review logs:**
```bash
# Deployment server logs
sudo grep -i "deployment" /opt/splunk/var/log/splunk/splunkd.log | tail -50

# Receiving data logs
sudo grep -i "tcpin" /opt/splunk/var/log/splunk/metrics.log | tail -20
```

### No Data Appearing

**Check inputs:**
```bash
# List all inputs
sudo -u splunk /opt/splunk/bin/splunk list inputstatus -auth admin:PASSWORD
```

**Search internal logs:**
```spl
# In Splunk Web
index=_internal sourcetype=splunkd component=Metrics group=tcpin_connections
| stats count by hostname
```

**Verify index configuration:**
```bash
# Check if data is in different index
# In Splunk Web search:
| eventcount summarize=false index=* | table index count
```

### High CPU/Memory Usage

**Identify expensive searches:**
```spl
index=_audit action=search
| stats count avg(total_run_time) as avg_runtime by user search
| sort -avg_runtime
```

**Check for runaway processes:**
```bash
top -u splunk
# Look for high CPU splunkd processes

# Kill specific search
sudo -u splunk /opt/splunk/bin/splunk list search-server -auth admin:PASSWORD
```

**Reduce search head load:**
- Limit concurrent searches
- Use summary indexing for repeated searches
- Optimize search queries

### Disk Space Issues

**Check index sizes:**
```bash
du -sh /opt/splunk/var/lib/splunk/*/db
```

**Clean old data:**
```bash
# Check frozen data
du -sh /opt/splunk/var/lib/splunk/*/frozendb

# Manually delete if needed (BE CAREFUL)
# sudo rm -rf /opt/splunk/var/lib/splunk/*/frozendb/*
```

**Adjust index retention:**
1. Settings → Indexes → Edit index
2. Modify `frozenTimePeriodInSecs` or `maxTotalDataSizeMB`
3. Save

## Maintenance

### Restart Splunk

```bash
# Graceful restart (waits for searches to complete)
sudo -u splunk /opt/splunk/bin/splunk restart

# Force restart
sudo systemctl restart Splunkd
```

### Update/Install Apps

**Via Splunk Web:**
1. Apps → Manage Apps
2. Install app from file
3. Browse to .tgz file
4. Upload and restart if prompted

**Via CLI:**
```bash
sudo -u splunk /opt/splunk/bin/splunk install app /path/to/app.tgz \
  -auth admin:PASSWORD

sudo -u splunk /opt/splunk/bin/splunk restart
```

### Deployment Server Changes

After modifying deployment apps:
```bash
# Reload deployment server
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:PASSWORD

# Force forwarders to check in
# Forwarders check every 60 seconds by default
```

### Splunk Upgrades

**Before upgrading:**
1. Backup `/opt/splunk/etc/` directory
2. Review release notes
3. Test in non-production first
4. Plan maintenance window

**Upgrade process:**
```bash
# Stop Splunk
sudo -u splunk /opt/splunk/bin/splunk stop

# Extract new version over existing (preserves configs)
sudo tar xzf splunk-NEW-VERSION.tgz -C /opt

# Set ownership
sudo chown -R splunk:splunk /opt/splunk

# Start Splunk (will auto-migrate)
sudo -u splunk /opt/splunk/bin/splunk start --accept-license
```

## Performance Tuning

### Index Optimization

**Set appropriate retention:**
```ini
# In indexes.conf
[main]
frozenTimePeriodInSecs = 2592000  # 30 days
maxTotalDataSizeMB = 250000       # 250 GB
```

**Use separate indexes:**
- Different retention requirements
- Different access controls
- Performance isolation

### Search Optimization

**Best practices:**
- Use time ranges (earliest/latest)
- Filter early in search pipeline
- Use indexed fields when possible
- Avoid wildcards at start of search
- Use summary indexing for repeated searches

**Example of optimized search:**
```spl
# GOOD
index=main sourcetype=WinEventLog:Security EventCode=4624 earliest=-24h
| stats count by user

# BAD
index=* "*4624*"
| search sourcetype=WinEventLog:Security
| stats count by user
```

### Forwarder Tuning

**On forwarders, adjust queue sizes if needed:**
```ini
# In outputs.conf
[tcpout]
maxQueueSize = 10MB  # Increase if forwarder buffering

[tcpout:primary_indexers]
compressed = true     # Enable compression
useACK = true        # Enable indexer acknowledgment
```

## Backup & Recovery

### Configuration Backup

**Backup essential directories:**
```bash
# Create backup
sudo tar czf splunk-config-$(date +%Y%m%d).tar.gz \
  /opt/splunk/etc/system/local \
  /opt/splunk/etc/apps \
  /opt/splunk/etc/deployment-apps \
  /opt/splunk/etc/users

# Store off-server
scp splunk-config-*.tar.gz user@backup-server:/backups/
```

**Automate with cron:**
```bash
# Add to /etc/cron.weekly/splunk-backup
#!/bin/bash
tar czf /backup/splunk-config-$(date +%Y%m%d).tar.gz /opt/splunk/etc
find /backup -name "splunk-config-*.tar.gz" -mtime +30 -delete
```

### Index Backup

**For critical data:**
```bash
# Backup specific index
sudo tar czf /backup/main-index-$(date +%Y%m%d).tar.gz \
  /opt/splunk/var/lib/splunk/main/db

# Or use Splunk's built-in archiving
# Configure via indexes.conf:
# coldToFrozenDir = /archive/splunk/frozen
```

### Restore Configuration

```bash
# Stop Splunk
sudo -u splunk /opt/splunk/bin/splunk stop

# Restore configuration
sudo tar xzf splunk-config-YYYYMMDD.tar.gz -C /

# Fix permissions
sudo chown -R splunk:splunk /opt/splunk/etc

# Start Splunk
sudo -u splunk /opt/splunk/bin/splunk start
```

### Disaster Recovery

**Complete reinstall procedure:**
1. Run installation scripts
2. Restore configuration backup
3. Restore index data (if backed up)
4. Verify forwarder connections
5. Test searches and apps

## Common Tasks Reference

### User Management

```bash
# List users
sudo -u splunk /opt/splunk/bin/splunk list user -auth admin:PASSWORD

# Add user
sudo -u splunk /opt/splunk/bin/splunk add user username \
  -password PASSWORD -role user -auth admin:PASSWORD

# Delete user
sudo -u splunk /opt/splunk/bin/splunk remove user username \
  -auth admin:PASSWORD

# Change password
sudo -u splunk /opt/splunk/bin/splunk edit user username \
  -password NEWPASSWORD -auth admin:PASSWORD
```

### License Management

```bash
# View license
sudo -u splunk /opt/splunk/bin/splunk list licenses -auth admin:PASSWORD

# Add license
sudo -u splunk /opt/splunk/bin/splunk add licenses /path/to/license.lic \
  -auth admin:PASSWORD
```

### Index Management

```bash
# Create index
sudo -u splunk /opt/splunk/bin/splunk add index newindex \
  -auth admin:PASSWORD

# List indexes
sudo -u splunk /opt/splunk/bin/splunk list index -auth admin:PASSWORD

# Clean index
sudo -u splunk /opt/splunk/bin/splunk clean eventdata -index indexname \
  -auth admin:PASSWORD
```

## Support Resources

- **Splunk Documentation**: https://docs.splunk.com/
- **Splunk Answers**: https://community.splunk.com/
- **Splunk Education**: https://education.splunk.com/

## Emergency Contacts

Document your support contacts:
- Splunk Administrator: _____________________
- System Administrator: _____________________
- Network Team: _____________________
- Vendor Support: _____________________

---

**Last Updated**: November 2025
