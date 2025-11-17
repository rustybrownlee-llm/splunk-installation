# Linux Splunk Enterprise Installation Package

Complete package for deploying Splunk Enterprise 10.0.1 on Linux servers with all required add-ons and apps.

## Contents

### Splunk Enterprise
- **splunk-10.0.1-c486717c322b-linux-amd64.tgz** (1.6 GB)
  - Splunk Enterprise 10.0.1 for Linux x86_64/AMD64

### Installation Scripts
- **install-splunk.sh** - Main Splunk Enterprise installation
- **configure-deployment-server.sh** - Configure as deployment server
- **install-addons.sh** - Install all add-ons and apps
- **setup-receiving.sh** - Configure forwarder receiving

### OCS Custom Add-ons

**ocs_add-on_indexes** (for Splunk Server):
- Creates CIM-compliant indexes: wineventlog, os, network, web, security, application, database, email
- Automatically installed by install-addons.sh
- 30-60 day retention policies with configurable size limits

**Deployment Apps** (in deployment-apps/):
- **ocs_add-on_deployment** - Connects forwarders to deployment server
- **ocs_add-on_outputs** - Configures data forwarding to indexers
- **ocs_add-on_windows** - Windows Event Log collection (System, Security, Application)
- Automatically deployed by configure-deployment-server.sh

### Add-ons & Apps (in downloads/)
**Core:**
- Splunk Common Information Model (CIM)
- Lookup File Editor

**Network Security:**
- Cisco Network Data Add-on
- Cisco ASA Add-on
- Palo Alto Networks Add-on & Firewall App

**Technology Add-ons:**
- Microsoft Windows Add-on
- Active Directory Supporting Add-on
- Sysmon Add-on
- Unix and Linux Add-on

**Applications:**
- InfoSec App for Splunk
- Splunk AI Toolkit
- Force Directed Graph Visualization
- Alert Manager & Add-on
- Sankey Diagram Visualization
- Punchcard Custom Visualization

## Quick Installation

### 1. Copy Package to Linux Server

```bash
# From your workstation
scp -r linux-splunk-package user@server:~/
```

### 2. Run Installation Scripts (In Order)

```bash
ssh user@server
cd ~/linux-splunk-package

# 1. Install Splunk Enterprise
chmod +x *.sh
sudo ./install-splunk.sh

# 2. Configure as Deployment Server (for managing forwarders)
sudo ./configure-deployment-server.sh

# 3. Install all add-ons and apps
sudo ./install-addons.sh

# 4. Setup forwarder receiving
sudo ./setup-receiving.sh
```

### 3. Access Splunk Web

```
http://YOUR_SERVER_IP:8000
Username: admin
Password: 5plunk#1!
```

**IMPORTANT:** Change the default password immediately after first login!

## System Requirements

### Minimum (Testing)
- 4 GB RAM
- 2 CPU cores
- 50 GB disk space
- Ubuntu 22.04 LTS or RHEL 8+

### Recommended (Production)
- 12 GB RAM minimum (Splunk recommends 8GB+)
- 4+ CPU cores
- 200+ GB disk space
- Ubuntu 22.04 LTS or RHEL 8+

### Network Requirements
- Outbound internet access (for downloads during setup, if needed)
- Open ports:
  - 8000 (Splunk Web)
  - 8089 (Management/Deployment Server)
  - 9997 (Forwarder Receiving)

## What Gets Installed

1. **Splunk Enterprise** installed to `/opt/splunk`
2. **Splunk user/group** created for running services
3. **OCS add-on_indexes** creates CIM-compliant indexes (wineventlog, os, network, web, security, etc.)
4. **All add-ons** extracted to `/opt/splunk/etc/apps/` (CIM, Windows TA, network TAs, InfoSec apps)
5. **Deployment Server** configured for managing Windows/Linux forwarders
6. **OCS deployment apps** installed to `/opt/splunk/etc/deployment-apps/` (deployment, outputs, windows inputs)
7. **Server classes** configured to deploy OCS apps to appropriate forwarders
8. **Receiving** enabled on port 9997 for forwarder data
9. **Firewall rules** configured (auto-detects ufw or firewalld)
10. **Boot-start** enabled (Splunk starts on system boot)

## Default Credentials

- **Username:** `admin`
- **Password:** `5plunk#1!`

Change this immediately in production!

## Script Details

### install-splunk.sh
- Detects OS (Ubuntu/Debian vs RHEL/CentOS)
- Installs dependencies
- Creates splunk user/group
- Extracts Splunk to /opt/splunk
- Configures admin password
- Starts Splunk and enables boot-start
- Configures firewall (ufw or firewalld)

### configure-deployment-server.sh
- Enables deployment server functionality
- Creates deployment-apps directory structure
- Installs OCS deployment apps (ocs_add-on_deployment, ocs_add-on_outputs, ocs_add-on_windows)
- Automatically configures deployment server and indexer IPs in OCS apps
- Configures server classes for forwarder management:
  - AllForwarders: Gets deployment client and outputs configuration
  - WindowsForwarders: Gets Windows Event Log collection configuration
- Creates legacy windows_forwarder_base app for backward compatibility

### install-addons.sh
- Stops Splunk
- Installs ocs_add-on_indexes (creates CIM-compliant indexes)
- Extracts all add-on tarballs to /opt/splunk/etc/apps/
- Sets correct ownership
- Starts Splunk (auto-discovers new apps and creates indexes)

### setup-receiving.sh
- Enables receiving on port 9997
- Configures firewall for receiving port
- Verifies port is listening

## Supported Operating Systems

**Tested and Supported:**
- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 20.04 LTS (Focal)
- RHEL 8.x / Rocky Linux 8.x / AlmaLinux 8.x
- RHEL 9.x / Rocky Linux 9.x / AlmaLinux 9.x
- CentOS 8 Stream

**Script auto-detects:**
- Package manager (apt vs yum/dnf)
- Firewall (ufw vs firewalld)
- Architecture (x86_64 only)

## Deployment Workflow

### For Single Server

1. Run all 4 scripts in order
2. Access Splunk Web
3. Deploy Windows forwarders using `windows-forwarder-package`

### For Multiple Servers

**Option A: Manual deployment to each server**
- Copy package to each server
- Run installation scripts

**Option B: Automation (Ansible/Puppet/Chef)**
- Use scripts as basis for automation
- Customize for your environment

## Post-Installation

### Verify Installation

```bash
# Check Splunk is running
sudo -u splunk /opt/splunk/bin/splunk status

# Check which ports are listening
sudo netstat -tlnp | grep splunk
# or
sudo ss -tlnp | grep splunk

# View logs
tail -f /opt/splunk/var/log/splunk/splunkd.log
```

### Access Splunk Web

1. Open browser: `http://YOUR_SERVER_IP:8000`
2. Login: `admin` / `5plunk#1!`
3. Change password when prompted
4. Go to **Apps** → **Manage Apps** to verify all apps installed

### Configure Data Inputs

1. **Settings** → **Data Inputs**
2. Configure inputs for:
   - Monitor local Linux logs
   - Receive forwarder data (already configured on port 9997)
   - Network inputs (syslog, etc.)

### Deploy to Forwarders

1. Copy forwarder apps to `/opt/splunk/etc/deployment-apps/`
2. Configure server classes in **Settings** → **Forwarder Management**
3. Install Windows/Linux forwarders pointing to this server

## Troubleshooting

### Splunk Won't Start

```bash
# Check if port 8000 is already in use
sudo netstat -tlnp | grep 8000

# Check Splunk logs
tail -100 /opt/splunk/var/log/splunk/splunkd.log

# Check disk space
df -h

# Check permissions
ls -la /opt/splunk
```

### Can't Access Web Interface

```bash
# Check firewall
sudo ufw status  # Ubuntu/Debian
sudo firewall-cmd --list-all  # RHEL/CentOS

# Manually add rules if needed
sudo ufw allow 8000/tcp
# or
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

### Apps Not Showing Up

```bash
# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart

# Check app directory
ls -la /opt/splunk/etc/apps/

# Check app ownership
ls -la /opt/splunk/etc/apps/ | head -20
# Should show: splunk splunk
```

### Forwarders Can't Connect

```bash
# Verify port 9997 is listening
sudo netstat -tlnp | grep 9997

# Check firewall allows 9997
sudo ufw status | grep 9997
# or
sudo firewall-cmd --list-ports | grep 9997

# Check deployment server
sudo -u splunk /opt/splunk/bin/splunk show deploy-poll
```

## Maintenance Commands

```bash
# Start Splunk
sudo -u splunk /opt/splunk/bin/splunk start

# Stop Splunk
sudo -u splunk /opt/splunk/bin/splunk stop

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart

# Check status
sudo -u splunk /opt/splunk/bin/splunk status

# Enable boot-start (if not already enabled)
sudo /opt/splunk/bin/splunk enable boot-start -user splunk

# View Splunk version
sudo -u splunk /opt/splunk/bin/splunk version
```

## Security Best Practices

### After Installation:

1. **Change default password** immediately
2. **Configure SSL/TLS** for Splunk Web (Settings → Server Settings → General Settings)
3. **Restrict firewall** to only allow access from trusted IPs
4. **Create role-based users** instead of using admin for everything
5. **Enable auditing** (Settings → System Settings → Audit Logs)
6. **Configure authentication** (LDAP/SAML if available)
7. **Keep Splunk updated** (check for security updates)

### Firewall Hardening:

```bash
# Ubuntu/Debian - Restrict to specific IP
sudo ufw delete allow 8000/tcp
sudo ufw allow from YOUR_IP to any port 8000 proto tcp

# RHEL/CentOS - Restrict to specific IP
sudo firewall-cmd --permanent --remove-port=8000/tcp
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="YOUR_IP" port port="8000" protocol="tcp" accept'
sudo firewall-cmd --reload
```

## Package This for Distribution

**Create tarball for easy transfer:**

```bash
cd /path/to/parent/directory
tar -czf linux-splunk-package.tar.gz linux-splunk-package/

# Transfer to server
scp linux-splunk-package.tar.gz user@server:~/

# Extract on server
tar -xzf linux-splunk-package.tar.gz
cd linux-splunk-package
```

## Production Deployment Checklist

- [ ] Server meets minimum requirements (12GB RAM recommended)
- [ ] Firewall configured with proper rules
- [ ] DNS/hostname properly configured
- [ ] Time synchronization (NTP) configured
- [ ] Backup strategy planned
- [ ] Default password changed
- [ ] SSL/TLS enabled for Splunk Web
- [ ] User roles and authentication configured
- [ ] Data retention policies configured
- [ ] Monitoring/alerting configured
- [ ] Forwarder deployment planned
- [ ] Documentation updated with server details

## Support & Documentation

**Official Splunk Documentation:**
- Installation: https://docs.splunk.com/Documentation/Splunk/latest/Installation
- Deployment Server: https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver
- Add-ons: https://splunkbase.splunk.com/

**Package Support:**
- Default admin password: `5plunk#1!` (change after installation)
- Scripts log to console with color-coded output
- All scripts support both Ubuntu/Debian and RHEL/CentOS

---

**Version:** Splunk Enterprise 10.0.1
**Build:** c486717c322b
**Last Updated:** 2025-11-03
**Architecture:** Linux x86_64/AMD64
**For:** Production and lab deployments
