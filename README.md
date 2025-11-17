# Splunk Enterprise Deployment Package

Complete offline installation package for Splunk Enterprise with Universal Forwarders, designed for air-gapped environments without internet access.

## Project Overview

This project provides:
- **Splunk Enterprise 10.0.1** installation for Linux (Ubuntu/Debian and RHEL/CentOS)
- **Splunk Universal Forwarder 9.3.2** for Windows systems
- Complete deployment server configuration for managing forwarders
- Manual implementation guides for environments with script execution restrictions
- 18+ pre-configured add-ons for network security, Windows monitoring, and CIM compliance
- Automated installation scripts (optional)

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

## Directory Structure

```
splunk-installation/
├── README.md                                  # This file
├── IMPLEMENTATION-LINUX.md                    # Manual Linux installation guide
├── IMPLEMENTATION-WINDOWS.md                  # Manual Windows installation guide
│
├── installers/                                # Large installer files (gitignored)
│   ├── splunk-10.0.1-*-linux-amd64.tgz       # Splunk Enterprise 10.0.1 (1.6GB)
│   ├── splunk-9.4.6-*-linux-amd64.tgz        # Splunk Enterprise 9.4.6 (1.1GB)
│   ├── splunkforwarder-9.3.2-*-x64.msi       # Windows forwarder (130MB)
│   └── splunkforwarder-9.3.2-*-x86_64.tgz    # Linux forwarder (47MB)
│
├── linux-splunk-package/                      # Linux server installation
│   ├── install-splunk.sh                      # Main Splunk installation script
│   ├── install-addons.sh                      # Add-on installation script
│   ├── configure-deployment-server.sh         # Deployment server setup
│   ├── setup-receiving.sh                     # Data receiving configuration
│   ├── downloads/                             # 18+ add-on files (in git)
│   │   ├── splunk-common-information-model-cim_620.tgz
│   │   ├── splunk-add-on-for-microsoft-windows_901.tgz
│   │   ├── splunk-add-on-for-cisco-asa_600.tgz
│   │   ├── palo-alto-networks-firewall_214.tgz
│   │   ├── infosec-app-for-splunk_171.tgz
│   │   └── [13 more add-ons...]
│   ├── ocs_add-on_indexes/                    # Custom index definitions
│   ├── cim-local-config/                      # CIM acceleration config
│   └── deployment-apps/                       # Apps for deployment server
│       ├── ocs_add-on_deployment/
│       ├── ocs_add-on_outputs/
│       └── ocs_add-on_windows/
│
└── windows-forwarder-package/                 # Windows client installation
    ├── Install-SplunkForwarder.ps1            # Automated PowerShell installer
    ├── config/                                # Configuration templates
    └── installers/                            # Windows MSI (see installers/)
```

## Quick Start

### Option 1: Manual Installation (Recommended for Restricted Environments)

If customer facilities have execution policies preventing script execution:

**Linux Server:**
1. Follow step-by-step instructions in `IMPLEMENTATION-LINUX.md`
2. All commands are provided for manual CLI execution
3. No script execution required

**Windows Forwarders:**
1. Follow step-by-step instructions in `IMPLEMENTATION-WINDOWS.md`
2. All commands are provided for manual PowerShell execution
3. Works in environments with restricted execution policies

### Option 2: Automated Installation (If Scripts Can Run)

**Linux Server:**
```bash
cd linux-splunk-package

# Step 1: Install Splunk Enterprise
sudo ./install-splunk.sh
# Prompts for admin password, installs Splunk 10.0.1

# Step 2: Install all add-ons
sudo ./install-addons.sh
# Installs 18+ add-ons and configures CIM

# Step 3: Configure deployment server
sudo ./configure-deployment-server.sh
# Sets up deployment server for forwarder management

# Step 4: Enable data receiving
sudo ./setup-receiving.sh
# Opens port 9997 for forwarder data
```

**Windows Forwarders:**
```powershell
# Run PowerShell as Administrator
cd windows-forwarder-package

# Option 1: Use the automated installer
.\Install-SplunkForwarder.ps1 -SplunkServerIP "YOUR_SERVER_IP"

# Option 2: Follow manual steps in IMPLEMENTATION-WINDOWS.md
```

## Version Information

**Splunk Components:**
- Splunk Enterprise: **10.0.1** (latest version, 1.6GB)
- Splunk Enterprise: **9.4.6** (stable 9.x version, 1.1GB)
- Universal Forwarder: **9.3.2** (130MB for Windows, 47MB for Linux)

**Supported Operating Systems:**
- Linux: Ubuntu 22.04+, Debian 11+, RHEL 8+, CentOS 8+
- Windows: Windows 10/11, Windows Server 2016+
- Architectures: x86_64 (AMD64), ARM64

## Installed Add-ons and Apps

The package includes 18+ pre-configured add-ons:

**Core Framework:**
- Splunk Common Information Model (CIM) 6.2.0
- Splunk Security Essentials 3.8.2

**Network Security:**
- Splunk Add-on for Cisco ASA 6.0.0
- Add-on for Cisco Network Data 2.7.9
- Palo Alto Networks Firewall 2.1.4
- Splunk Add-on for Palo Alto Networks 2.0.2

**Windows Monitoring:**
- Splunk Add-on for Microsoft Windows 9.0.1
- Splunk Supporting Add-on for Active Directory 3.1.1
- Splunk Add-on for Sysmon 5.0.0

**Unix/Linux Monitoring:**
- Splunk Add-on for Unix and Linux 10.2.0

**Security & Analysis:**
- InfoSec App for Splunk 1.7.1
- Alert Manager 3.0.11
- Alert Manager Add-on 2.3.1

**Visualization:**
- Splunk AI Toolkit 5.6.3
- Force Directed App for Splunk 3.1.1
- Punchcard Custom Visualization 1.5.0
- Splunk Sankey Diagram Custom Visualization 1.6.0
- Splunk App for Lookup File Editing 4.0.6

## Custom OCS Components

**OCS Index Definitions:**
- `wineventlog` - Windows event logs (100GB limit)
- `perfmon` - Performance monitoring data (50GB limit)
- `os` - Operating system logs
- `network` - Network device logs
- `web` - Web server logs
- `security` - Security events
- `application` - Application logs
- `database` - Database logs
- `email` - Email system logs

**Deployment Apps:**
- `ocs_add-on_deployment` - Deployment client configuration (all forwarders)
- `ocs_add-on_outputs` - Output configuration to indexer (all forwarders)
- `ocs_add-on_windows` - Windows-specific inputs (Windows forwarders only)

## Network Requirements

**Required Ports:**
- **8000/tcp** - Splunk Web interface
- **8089/tcp** - Management port / Deployment server
- **9997/tcp** - Forwarder data receiving

**Firewall Configuration:**
- Forwarders → Server: 8089 (deployment server connection)
- Forwarders → Server: 9997 (data forwarding)
- Admin Workstation → Server: 8000 (web access)

## Installation Notes

### Linux Server Requirements
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 100GB minimum (depends on data volume)
- **CPU:** 4 cores minimum
- **OS:** Ubuntu 22.04+, RHEL 8+, or CentOS 8+

### Windows Forwarder Requirements
- **RAM:** 512MB minimum
- **Storage:** 2GB for installation
- **OS:** Windows 10/11, Windows Server 2016+

### Known Issues

1. **RHEL 9 OpenSSL Compatibility:** Splunk 10.0.1 may show OpenSSL warnings on RHEL 9 when enabling boot-start. The service runs fine but may not auto-start on reboot. Use manual start commands after reboots.

2. **Data Model Acceleration:** Initial CIM data model acceleration can take hours depending on data volume. This is normal and happens in the background.

## Security Considerations

⚠️ **Important Security Notes:**

1. **Change Default Password:** The installation guides use placeholder passwords. Always use strong, unique passwords in production.

2. **Secure Password Storage:** Do not store passwords in plain text. Use PowerShell SecureStrings on Windows.

3. **Network Segmentation:** Deploy Splunk in a secure network segment with appropriate firewall rules.

4. **TLS/SSL:** Consider enabling TLS encryption for forwarder-to-indexer communication in production.

5. **Access Control:** Configure role-based access control (RBAC) for users after installation.

## Troubleshooting

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
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:YOUR_PASSWORD

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
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:YOUR_PASSWORD

# List forwarders
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:YOUR_PASSWORD
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

## Documentation

- **IMPLEMENTATION-LINUX.md** - Complete manual installation guide for Linux servers
- **IMPLEMENTATION-WINDOWS.md** - Complete manual installation guide for Windows forwarders
- [Official Splunk Documentation](https://docs.splunk.com/)
- [Deployment Server Guide](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver)
- [Universal Forwarder Guide](https://docs.splunk.com/Documentation/Forwarder/)

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

## Support and Resources

- **Installation Issues:** See IMPLEMENTATION-LINUX.md or IMPLEMENTATION-WINDOWS.md troubleshooting sections
- **Splunk Community:** https://community.splunk.com/
- **Splunk Answers:** https://community.splunk.com/t5/Splunk-Answers/bd-p/splunk-answers

## License

Splunk software requires appropriate licensing for production use. This package is designed for enterprise deployment and assumes valid Splunk licenses.

## Package Preparation

### For Customer Delivery

1. Download Splunk installers to `installers/` directory:
   - Splunk Enterprise 10.0.1 or 9.4.6 (both included)
   - Splunk Universal Forwarder 9.3.2 (Windows and Linux)

2. Verify all add-ons are present in `linux-splunk-package/downloads/`

3. Package for transfer:
   ```bash
   # Create compressed archive
   tar czf splunk-installation-package.tar.gz \
       splunk-installation/ \
       --exclude=.git \
       --exclude=.DS_Store
   ```

4. Transfer to customer environment via approved method (USB, secure transfer, etc.)

## Changelog

### Version 2.0 (November 2024)
- Updated to Splunk Enterprise 10.0.1 (with 9.4.6 fallback option)
- Added manual implementation guides (IMPLEMENTATION-LINUX.md, IMPLEMENTATION-WINDOWS.md)
- Separated installers from add-ons in git repository
- Added 18+ pre-configured add-ons
- Improved offline installation support
- Added RHEL/CentOS support
- Fixed tar extraction hang issue in install-addons.sh
- Both Splunk 10.0.1 and 9.4.6 available for flexibility

---

**Last Updated:** November 2024
