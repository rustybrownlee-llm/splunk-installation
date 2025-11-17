# Splunk Enterprise Deployment Package

Multi-deployment package for Splunk Enterprise with Universal Forwarders, designed for various environments including air-gapped deployments.

## Project Overview

This project provides a complete Splunk deployment framework supporting:
- Multiple deployment scenarios (Linux non-ES, Windows ES, and more)
- Splunk Enterprise installation for various platforms
- Universal Forwarder deployment strategies
- Complete deployment server configuration for managing forwarders
- Shared repository of apps, add-ons, and installers
- Both automated and manual installation options

## Directory Structure

```
splunk-installation/
├── README.md                                  # This file - project overview
│
├── installers/                                # Shared installer files (gitignored)
│   ├── splunk-10.0.1-*-linux-amd64.tgz       # Splunk Enterprise 10.0.1 (1.6GB)
│   ├── splunk-9.4.6-*-linux-amd64.tgz        # Splunk Enterprise 9.4.6 (1.1GB)
│   ├── splunkforwarder-10.0.2-*-windows-x64.msi  # Windows forwarder for 10.x
│   ├── splunkforwarder-9.4.6-*-windows-x64.msi   # Windows forwarder for 9.4.6
│   ├── splunkforwarder-9.3.2-*-x64-release.msi   # Windows forwarder legacy
│   └── splunkforwarder-9.3.2-*-Linux-x86_64.tgz  # Linux forwarder
│
├── splunkbase/                                # Shared apps/add-ons repository
│   ├── README.md                              # List of 18+ add-ons
│   └── [18+ add-on .tgz files]               # Downloaded from Splunkbase (gitignored)
│
├── universal-forwarders/                      # Forwarder deployment strategies
│   ├── README.md                              # Deployment patterns & best practices
│   └── windows-forwarder-package/            # Windows forwarder automation
│
├── linux-non-ES/                              # Linux Enterprise + Windows Forwarders
│   ├── README.md                              # Linux deployment documentation
│   ├── IMPLEMENTATION-LINUX.md                # Manual Linux installation guide
│   ├── IMPLEMENTATION-WINDOWS.md              # Manual Windows forwarder guide
│   ├── VERSION-SELECTION.md                   # Version compatibility matrix
│   └── linux-splunk-package/                  # Installation scripts
│       ├── install-splunk.sh
│       ├── install-addons.sh
│       ├── configure-deployment-server.sh
│       ├── setup-receiving.sh
│       ├── ocs_add-on_indexes/                # Custom index definitions
│       ├── cim-local-config/                  # CIM acceleration config
│       └── deployment-apps/                   # Apps for deployment server
│
└── windows-ES/                                # Windows Enterprise Security (future)
    └── README.md                              # Staged for future implementation
```

## Sub-Projects

### linux-non-ES/
**Linux Splunk Enterprise Server + Windows Universal Forwarders**

Complete deployment package for a Linux-based Splunk Enterprise server receiving data from Windows endpoints.

- **Platform:** Ubuntu/Debian or RHEL/CentOS
- **Version:** Splunk Enterprise 10.0.1 or 9.4.6
- **Features:**
  - Indexer & Search Head
  - Deployment Server for forwarder management
  - 18+ pre-configured add-ons (CIM, InfoSec, network security)
  - Windows Event Log collection from forwarders

📚 **Documentation:** See `linux-non-ES/README.md` for complete deployment guide

### windows-ES/
**Windows Enterprise Security Deployment (Staged)**

Reserved for future Windows-based Splunk Enterprise deployment with Enterprise Security.

📚 **Documentation:** See `windows-ES/README.md` for status

## Shared Resources

### installers/
Splunk Enterprise and Universal Forwarder installers for all platforms. These files are gitignored due to size and must be downloaded separately.

**Download sources:**
- Splunk Enterprise: https://www.splunk.com/en_us/download/splunk-enterprise.html
- Universal Forwarders: https://www.splunk.com/en_us/download/universal-forwarder.html

### splunkbase/
Centralized repository for Splunk apps and add-ons downloaded from Splunkbase. Shared across all sub-projects.

**Contents:** 18+ add-ons including:
- Splunk Common Information Model (CIM)
- InfoSec App for Splunk
- Network Security Add-ons (Cisco, Palo Alto)
- Technology Add-ons (Windows, Active Directory, Sysmon, Unix/Linux)
- Visualization apps

📚 **Documentation:** See `splunkbase/README.md` for complete list

### universal-forwarders/
Universal Forwarder deployment strategies and configurations applicable to all sub-projects.

**Deployment Strategy:** Centralized management via Deployment Server
- Automatic configuration distribution
- OS-specific targeting (Windows vs Linux)
- Version compatibility guidance

📚 **Documentation:** See `universal-forwarders/README.md` for deployment patterns

## Version Information

**Splunk Components:**
- Splunk Enterprise: **10.0.1** (latest, 1.6GB) or **9.4.6** (stable 9.x, 1.1GB)
- Universal Forwarder: **10.0.2**, **9.4.6**, or **9.3.2** (universal compatibility)

**Supported Operating Systems:**
- Linux: Ubuntu 22.04+, Debian 11+, RHEL 8+, CentOS 8+
- Windows: Windows 10/11, Windows Server 2016+
- Architectures: x86_64 (AMD64), ARM64

## Network Requirements

**Required Ports:**
- **8000/tcp** - Splunk Web interface
- **8089/tcp** - Management port / Deployment server
- **9997/tcp** - Forwarder data receiving

**Firewall Configuration:**
- Forwarders → Server: 8089 (deployment server connection)
- Forwarders → Server: 9997 (data forwarding)
- Admin Workstation → Server: 8000 (web access)

## Quick Start

### 1. Prepare the Package

Download required installers and add-ons:

```bash
# Download Splunk Enterprise installers to installers/
# Download Splunkbase add-ons to splunkbase/
# See respective README files for download links
```

### 2. Choose Your Deployment

Navigate to the appropriate sub-project and follow its documentation:

**For Linux Enterprise + Windows Forwarders:**
```bash
cd linux-non-ES
# Follow README.md or IMPLEMENTATION-LINUX.md
```

**For Windows Enterprise Security:**
```bash
cd windows-ES
# Follow README.md (currently staged for future implementation)
```

### 3. Deploy Universal Forwarders

Once your Splunk server is configured, deploy forwarders:

```bash
# See universal-forwarders/README.md for deployment strategies
# Use deployment server for centralized management
```

## Common Troubleshooting

### Splunk Won't Start

```bash
# Check logs
sudo tail -50 /opt/splunk/var/log/splunk/splunkd.log

# Verify ownership
ls -la /opt/splunk | head -10

# Check if port is in use
sudo netstat -tulnp | grep 8000
```

### Forwarders Not Connecting

```bash
# Check receiving port
sudo netstat -tulnp | grep 9997

# List connected forwarders
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:PASSWORD

# Check deployment server configuration
cat /opt/splunk/etc/system/local/serverclass.conf
```

### Windows Forwarder Issues

```powershell
# Check service status
Get-Service -Name "SplunkForwarder"

# View logs
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 50

# Test connectivity
Test-NetConnection -ComputerName YOUR_SERVER_IP -Port 9997
```

## Maintenance Commands

**Linux Server:**
```bash
# Start/Stop/Restart
sudo -u splunk /opt/splunk/bin/splunk start
sudo -u splunk /opt/splunk/bin/splunk stop
sudo -u splunk /opt/splunk/bin/splunk restart

# Check status
sudo -u splunk /opt/splunk/bin/splunk status

# Reload deployment server
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:PASSWORD

# List forwarders
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:PASSWORD
```

**Windows Forwarder:**
```powershell
# Service management
Start-Service -Name "SplunkForwarder"
Stop-Service -Name "SplunkForwarder"
Restart-Service -Name "SplunkForwarder"
Get-Service -Name "SplunkForwarder"

# Check forwarder status
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" status
```

## Useful Splunk Searches

After deployment, try these searches:

```spl
# View all Windows Event Logs
index=wineventlog

# Security events only
index=wineventlog sourcetype=WinEventLog:Security

# View all forwarder connections
index=_internal sourcetype=splunkd component=Metrics group=tcpin_connections

# Check data volume by host
index=* | stats count by host

# Performance monitoring
index=perfmon source="Perfmon:CPU"
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Change Default Passwords:** Always use strong, unique passwords in production
2. **Secure Password Storage:** Do not store passwords in plain text
3. **Network Segmentation:** Deploy Splunk in a secure network segment with appropriate firewall rules
4. **TLS/SSL:** Consider enabling TLS encryption for forwarder-to-indexer communication in production
5. **Access Control:** Configure role-based access control (RBAC) for users after installation

## Package Preparation for Transfer

### For Air-Gapped Deployment

1. Download all installers to `installers/` directory
2. Download all add-ons to `splunkbase/` directory
3. Package for transfer:

```bash
# Create compressed archive
tar czf splunk-installation-package.tar.gz \
    splunk-installation/ \
    --exclude=.git \
    --exclude=.DS_Store
```

4. Transfer to target environment via approved method (USB, secure transfer, etc.)

## Documentation

- **Sub-Project READMEs:** See each sub-project directory for specific deployment guides
- **Manual Installation Guides:** Available in sub-project directories (IMPLEMENTATION-*.md)
- [Official Splunk Documentation](https://docs.splunk.com/)
- [Deployment Server Guide](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver)
- [Universal Forwarder Guide](https://docs.splunk.com/Documentation/Forwarder/)

## Support and Resources

- **Installation Issues:** See sub-project IMPLEMENTATION guides for troubleshooting
- **Splunk Community:** https://community.splunk.com/
- **Splunk Answers:** https://community.splunk.com/t5/Splunk-Answers/bd-p/splunk-answers

## License

Splunk software requires appropriate licensing for production use. This package is designed for enterprise deployment and assumes valid Splunk licenses.

## Changelog

### Version 2.1 (November 2024)
- Restructured project into multi-deployment framework
- Created sub-projects: linux-non-ES, windows-ES (staged)
- Centralized shared resources: installers/, splunkbase/, universal-forwarders/
- Updated all scripts to reference new directory structure
- Added comprehensive documentation for each sub-project

### Version 2.0 (November 2024)
- Updated to Splunk Enterprise 10.0.1 (with 9.4.6 fallback option)
- Added manual implementation guides
- Added 18+ pre-configured add-ons
- Improved offline installation support
- Added RHEL/CentOS support

---

**Last Updated:** November 2024
