# Linux Non-ES Splunk Deployment

Complete offline installation package for Splunk Enterprise on Linux with Windows Universal Forwarders, designed for environments without Enterprise Security (non-ES).

## Overview

This deployment provides:
- **Splunk Enterprise 10.0.1 or 9.4.6** on Linux (Ubuntu/Debian or RHEL/CentOS)
- **Deployment Server** for centralized forwarder management
- **Data Receiving** from Universal Forwarders (port 9997)
- **18+ Pre-configured Add-ons** for CIM compliance and InfoSec App
- **Windows Event Log Collection** from Windows endpoints

## Architecture

```
┌─────────────────────────────────────────────┐
│         Linux Server (Ubuntu/RHEL)          │
│                                             │
│         Splunk Enterprise 10.0.1            │
│                                             │
│         - Indexer & Search Head             │
│         - Deployment Server                 │
│         - Data Receiver (Port 9997)         │
│         - 18+ Add-ons Installed             │
│         - CIM Data Models Accelerated       │
│                                             │
└──────────────────┬──────────────────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
      ▼            ▼            ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Windows  │ │ Windows  │ │ Windows  │
│ Client 1 │ │ Client 2 │ │ Client N │
│          │ │          │ │          │
│ Forwarder│ │ Forwarder│ │ Forwarder│
│ 9.3.2    │ │ 9.3.2    │ │ 9.3.2    │
└──────────┘ └──────────┘ └──────────┘
```

## Directory Contents

```
linux-non-ES/
├── README.md                           # This file
├── IMPLEMENTATION-LINUX.md             # Manual Linux installation guide
├── IMPLEMENTATION-WINDOWS.md           # Manual Windows forwarder guide
├── VERSION-SELECTION.md                # Version compatibility matrix
│
└── linux-splunk-package/               # Installation scripts and configs
    ├── install-splunk.sh               # Install Splunk Enterprise
    ├── install-addons.sh               # Install all add-ons
    ├── configure-deployment-server.sh  # Setup deployment server
    ├── setup-receiving.sh              # Enable data receiving
    │
    ├── ocs_add-on_indexes/             # Custom index definitions
    │   └── default/indexes.conf        # 9 custom indexes
    │
    ├── cim-local-config/               # CIM data model acceleration
    │   └── datamodels.conf             # 8 accelerated data models
    │
    └── deployment-apps/                # Apps for deployment server
        ├── ocs_add-on_deployment/      # Deployment client config
        ├── ocs_add-on_outputs/         # Output config to indexer
        └── ocs_add-on_windows/         # Windows Event Log inputs
```

## Installation Options

### Option 1: Automated Installation (Recommended if scripts can run)

**Prerequisites:**
- Root access (sudo)
- Installers downloaded to `../installers/`
- Add-ons downloaded to `../splunkbase/`

**Steps:**

```bash
cd linux-splunk-package

# Step 1: Install Splunk Enterprise
sudo ./install-splunk.sh
# Prompts for admin password, installs Splunk 10.0.1

# Step 2: Install all add-ons
sudo ./install-addons.sh
# Installs 18+ add-ons from ../splunkbase/ and configures CIM

# Step 3: Configure deployment server
sudo ./configure-deployment-server.sh
# Sets up deployment server for forwarder management

# Step 4: Enable data receiving
sudo ./setup-receiving.sh
# Opens port 9997 for forwarder data
```

### Option 2: Manual Installation (For restricted environments)

If script execution is restricted, follow the comprehensive step-by-step guides:

**Linux Server:**
- Follow `IMPLEMENTATION-LINUX.md` for complete manual CLI installation

**Windows Forwarders:**
- Follow `IMPLEMENTATION-WINDOWS.md` for manual PowerShell installation

These guides provide every command needed for manual execution without running scripts.

## Version Selection

This deployment supports two Splunk Enterprise versions:

| Version | Status | Use Case |
|---------|--------|----------|
| 10.0.1 | Latest (default) | New deployments, latest features |
| 9.4.6 | Stable 9.x | Conservative deployments, proven stability |

**Changing Versions:**
Edit `linux-splunk-package/install-splunk.sh`:
```bash
# For Splunk 9.4.6 instead of 10.0.1:
SPLUNK_VERSION="9.4.6"
SPLUNK_BUILD="60284236e579"
```

See `VERSION-SELECTION.md` for complete compatibility matrix.

## Installed Components

### Core Framework
- Splunk Common Information Model (CIM) 6.2.0 - **with data model acceleration enabled**
- Splunk Security Essentials 3.8.2

### Network Security
- Splunk Add-on for Cisco ASA 6.0.0
- Add-on for Cisco Network Data 2.7.9
- Palo Alto Networks Firewall 2.1.4
- Splunk Add-on for Palo Alto Networks 2.0.2

### Windows Monitoring
- Splunk Add-on for Microsoft Windows 9.0.1
- Splunk Supporting Add-on for Active Directory 3.1.1
- Splunk Add-on for Sysmon 5.0.0

### Unix/Linux Monitoring
- Splunk Add-on for Unix and Linux 10.2.0

### Security & Analysis
- **InfoSec App for Splunk 1.7.1** (requires CIM data model acceleration)
- Alert Manager 3.0.11
- Alert Manager Add-on 2.3.1

### Visualization
- Splunk AI Toolkit 5.6.3
- Force Directed App for Splunk 3.1.1
- Punchcard Custom Visualization 1.5.0
- Splunk Sankey Diagram Custom Visualization 1.6.0
- Splunk App for Lookup File Editing 4.0.6

## Custom OCS Components

### OCS Index Definitions
The `ocs_add-on_indexes` app creates 9 custom indexes:

- `wineventlog` - Windows event logs (100GB limit)
- `perfmon` - Performance monitoring data (50GB limit)
- `os` - Operating system logs
- `network` - Network device logs
- `web` - Web server logs
- `security` - Security events
- `application` - Application logs
- `database` - Database logs
- `email` - Email system logs

### OCS Deployment Apps
Deployed automatically to forwarders via Deployment Server:

- `ocs_add-on_deployment` - Deployment client configuration (all forwarders)
- `ocs_add-on_outputs` - Output configuration to indexer (all forwarders)
- `ocs_add-on_windows` - Windows Event Log collection (Windows forwarders only)

## Network Requirements

**Required Ports:**
- **8000/tcp** - Splunk Web interface
- **8089/tcp** - Management port / Deployment server
- **9997/tcp** - Forwarder data receiving

**Firewall Rules:**
Scripts automatically configure firewall (ufw or firewalld) for these ports.

## System Requirements

### Linux Server
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 100GB minimum (depends on data volume)
- **CPU:** 4 cores minimum
- **OS:** Ubuntu 22.04+, RHEL 8+, or CentOS 8+

### Windows Forwarders
- **RAM:** 512MB minimum
- **Storage:** 2GB for installation
- **OS:** Windows 10/11, Windows Server 2016+

## Post-Installation

### Access Splunk Web
```
http://YOUR_SERVER_IP:8000
Username: admin
Password: [password set during installation]
```

### Verify Installation
1. Go to **Apps → Manage Apps** - check all apps are enabled
2. Go to **Settings → Indexes** - verify OCS indexes exist
3. Go to **Settings → Data Models** - check CIM data models show "Accelerated"
4. Go to **Settings → Forwarding and receiving** - verify port 9997 is configured

### Deploy Windows Forwarders
After server configuration:
1. See `../universal-forwarders/windows-forwarder-package/` for Windows installation
2. See `IMPLEMENTATION-WINDOWS.md` for manual forwarder setup
3. Forwarders will automatically check in with Deployment Server
4. Server will push configurations based on server class rules

## Troubleshooting

### Splunk Won't Start
```bash
# Check logs
sudo tail -50 /opt/splunk/var/log/splunk/splunkd.log

# Verify ownership
ls -la /opt/splunk | head -10

# Manual start
sudo -u splunk /opt/splunk/bin/splunk start
```

### Add-ons Not Installing
```bash
# Verify add-ons exist
ls -lh ../splunkbase/

# Check permissions
sudo chown -R splunk:splunk /opt/splunk/etc/apps/
```

### Forwarders Not Connecting
```bash
# Check receiving port
sudo netstat -tulnp | grep 9997

# List connected forwarders
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:PASSWORD

# Reload deployment server
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:PASSWORD
```

### Data Model Acceleration Slow
CIM data model acceleration can take hours for large datasets. This is normal.

Check status:
- **Splunk Web:** Settings → Data Models → [Model Name] → Acceleration Status

## Useful Commands

```bash
# Service management
sudo -u splunk /opt/splunk/bin/splunk start
sudo -u splunk /opt/splunk/bin/splunk stop
sudo -u splunk /opt/splunk/bin/splunk restart
sudo -u splunk /opt/splunk/bin/splunk status

# Deployment server
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:PASSWORD
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:PASSWORD

# Check receiving
sudo -u splunk /opt/splunk/bin/splunk list inputstatus -auth admin:PASSWORD
```

## Useful Splunk Searches

```spl
# View all Windows Event Logs
index=wineventlog

# Security events only
index=wineventlog sourcetype=WinEventLog:Security

# View forwarder connections
index=_internal sourcetype=splunkd component=Metrics group=tcpin_connections

# Check data volume by host
index=* | stats count by host

# Performance monitoring
index=perfmon source="Perfmon:CPU"
```

## Known Issues

### RHEL 9 OpenSSL Compatibility
Splunk 10.0.1 may show OpenSSL warnings on RHEL 9 when enabling boot-start. The service runs fine but may not auto-start on reboot. Use manual start commands after reboots.

**Workaround:**
```bash
# Create systemd service manually
# Or use cron @reboot entry
```

### Data Model Acceleration Performance
Initial CIM data model acceleration can take several hours depending on data volume. This is expected behavior and happens in the background.

## Security Considerations

⚠️ **Important:**
1. Change default passwords after installation
2. Use strong, unique passwords (minimum 8 characters)
3. Configure firewall rules appropriately
4. Consider TLS/SSL for production forwarder traffic
5. Implement RBAC after installation

## Support

- **Manual Installation:** See `IMPLEMENTATION-LINUX.md` and `IMPLEMENTATION-WINDOWS.md`
- **Version Questions:** See `VERSION-SELECTION.md`
- **Splunk Documentation:** https://docs.splunk.com/
- **Community:** https://community.splunk.com/

## Related Documentation

- `../README.md` - Main project overview
- `../splunkbase/README.md` - Complete add-on list
- `../universal-forwarders/README.md` - Forwarder deployment strategies
- `../installers/` - Required installer files

---

**Last Updated:** November 2024
