# Splunk Installation Project

Complete setup for a Splunk Enterprise deployment server with Windows Universal Forwarders, designed to run on macOS using UTM virtual machines.

## Project Overview

This project provides automated scripts and configurations for:
- Splunk Enterprise installation on Ubuntu Server (ARM64)
- Deployment server configuration for managing forwarders
- Windows Universal Forwarder installation and configuration
- Complete testing environment using UTM VMs on macOS

## Architecture

```
┌─────────────────────────────────────────────┐
│         macOS (M4 Max MacBook Pro)          │
│                                             │
│  ┌────────────────┐    ┌─────────────────┐ │
│  │ Ubuntu VM      │    │ Windows 11 VM   │ │
│  │                │    │                 │ │
│  │ Splunk         │◄───┤ Universal       │ │
│  │ Enterprise     │    │ Forwarder       │ │
│  │                │    │                 │ │
│  │ - Indexer      │    │ - Event Logs    │ │
│  │ - Deployment   │    │ - Perfmon       │ │
│  │   Server       │    │                 │ │
│  └────────────────┘    └─────────────────┘ │
└─────────────────────────────────────────────┘
```

## Directory Structure

```
splunk-installation/
├── README.md                          # This file
│
├── documents/                         # Production installation docs (for customers)
│   ├── INSTALLATION.md                # Linux Splunk installation guide
│   ├── ADMINISTRATION.md              # Admin, troubleshooting, best practices
│   └── WINDOWS-FORWARDER-INSTALL.md   # Windows forwarder guide
│
├── documents-vm/                      # Lab/VM documentation (internal only)
│   └── VM-SETUP-GUIDE.md              # UTM VM creation for testing
│
├── scripts/                           # Bash scripts for Linux Splunk installation
│   ├── install-splunk.sh              # Main Splunk installation
│   ├── configure-deployment-server.sh # Setup deployment server
│   ├── install-addons.sh              # Install all add-ons in order
│   ├── setup-receiving.sh             # Configure data receiving
│   └── deploy-to-vm.sh                # Deploy files to VM (for testing)
│
├── windows-forwarders/                # PowerShell scripts for Windows
│   ├── config.ps1                     # Configuration file (edit with server IP)
│   ├── Install-SplunkForwarder.ps1    # Forwarder installation
│   ├── Configure-SplunkForwarder.ps1  # Manual configuration (optional)
│   └── Test-SplunkForwarder.ps1       # Diagnostics and testing
│
├── downloads/                         # Splunk installers and add-ons
│   ├── splunk-10.0.1-*.tgz            # Splunk Enterprise installer
│   ├── splunkforwarder-9.3.2-*.msi    # Windows Universal Forwarder
│   └── [various add-ons].tgz          # CIM, Windows TA, Network TAs, etc.
│
├── configs/                           # Configuration templates
│   └── deployment-apps/               # Apps for deployment server
│
├── iso/                               # ISO files for VM installation (lab only)
│   ├── ubuntu-22.04.5-live-server-arm64.iso
│   └── windows11-arm64-eval.iso
│
└── vm/                                # Virtual machine files (lab only)
    ├── splunk-server.utm
    └── windows-client.utm
```

## Quick Start

### For Lab/Testing (macOS with UTM VMs)

Follow the detailed guide in `documents-vm/VM-SETUP-GUIDE.md`:

### For Production Deployment

See `documents/INSTALLATION.md` for complete installation instructions.

### 1. Setup Virtual Machines (Lab Only)

1. Download Windows 11 ARM64 Evaluation ISO
2. Create Ubuntu Server VM in UTM
3. Create Windows 11 VM in UTM
4. Configure networking

**Estimated time:** 45-60 minutes

### 2. Install Splunk on Ubuntu VM

SSH into the Ubuntu VM or use UTM console:

```bash
# Copy scripts to the VM (if using shared folders or SCP)
# Then run:

sudo ./scripts/install-splunk.sh
# Follow prompts to download Splunk and set admin password

sudo ./scripts/configure-deployment-server.sh
# Sets up deployment server for managing forwarders

sudo ./scripts/setup-receiving.sh
# Enables receiving data from forwarders on port 9997
```

**Estimated time:** 30-45 minutes (including Splunk download)

### 3. Install Forwarder on Windows VM

On the Windows VM, run PowerShell as Administrator:

```powershell
# Set execution policy (if not already done)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Install the forwarder
# Replace 192.168.64.5 with your Ubuntu VM's IP address
$password = Read-Host -AsSecureString "Enter Splunk admin password"
.\windows-forwarders\Install-SplunkForwarder.ps1 `
    -DeploymentServer "192.168.64.5" `
    -AdminPassword $password

# Configure the forwarder
.\windows-forwarders\Configure-SplunkForwarder.ps1 `
    -SplunkIndexer "192.168.64.5" `
    -DeploymentServer "192.168.64.5" `
    -EnableWindowsEventLogs `
    -EnablePerfmon

# Test the installation
.\windows-forwarders\Test-SplunkForwarder.ps1 `
    -SplunkIndexer "192.168.64.5" `
    -DeploymentServer "192.168.64.5"
```

**Estimated time:** 15-20 minutes

### 4. Verify the Deployment

1. Access Splunk Web: `http://<ubuntu-vm-ip>:8000`
2. Login with admin credentials
3. Check forwarder connections:
   - Settings → Forwarding and receiving → Receive data
   - Should show connected forwarder
4. Search for data: `index=main` or `index=_internal`

## Component Details

### Ubuntu VM (Splunk Server)

**Specifications:**
- OS: Ubuntu Server 22.04 LTS ARM64
- RAM: 8 GB
- Storage: 80 GB
- CPU: 4 cores

**Installed Components:**
- Splunk Enterprise 9.3.2
- Deployment Server
- Indexer
- Search Head

**Ports:**
- 8000: Splunk Web interface
- 8089: Management port / Deployment server
- 9997: Forwarder receiving port

### Windows VM (Test Client)

**Specifications:**
- OS: Windows 11 Enterprise Evaluation ARM64
- RAM: 4 GB
- Storage: 60 GB
- CPU: 2 cores

**Installed Components:**
- Splunk Universal Forwarder 9.3.2
- Configured deployment client
- Windows Event Log monitoring
- Performance Monitor collection

## Scripts Documentation

### Bash Scripts (scripts/)

#### install-splunk.sh
Installs Splunk Enterprise on Ubuntu Server.

Features:
- System package updates
- User creation
- Splunk download assistance
- Initial configuration
- Firewall setup
- Boot-start enablement

Usage:
```bash
sudo ./scripts/install-splunk.sh
```

#### configure-deployment-server.sh
Configures Splunk as a deployment server.

Features:
- Enables deployment server
- Creates deployment apps structure
- Configures server classes
- Sets up Windows forwarder base app

Usage:
```bash
sudo ./scripts/configure-deployment-server.sh
```

#### setup-receiving.sh
Configures Splunk to receive data from forwarders.

Features:
- Enables port 9997 for receiving
- Configures indexes
- Sets up firewall rules

Usage:
```bash
sudo ./scripts/setup-receiving.sh
```

### PowerShell Scripts (windows-forwarders/)

#### Install-SplunkForwarder.ps1
Downloads and installs Splunk Universal Forwarder.

Parameters:
- `-DeploymentServer`: Deployment server IP/hostname (required)
- `-AdminPassword`: Admin password as SecureString (required)
- `-DeploymentPort`: Deployment server port (default: 8089)
- `-InstallPath`: Installation path (default: C:\Program Files\SplunkUniversalForwarder)

Example:
```powershell
$pwd = Read-Host -AsSecureString
.\Install-SplunkForwarder.ps1 -DeploymentServer "192.168.64.5" -AdminPassword $pwd
```

#### Configure-SplunkForwarder.ps1
Configures forwarder inputs and outputs.

Parameters:
- `-SplunkIndexer`: Indexer IP/hostname (required)
- `-DeploymentServer`: Deployment server IP/hostname (required)
- `-IndexerPort`: Receiving port (default: 9997)
- `-EnableWindowsEventLogs`: Enable Event Log collection (default: true)
- `-EnablePerfmon`: Enable Performance Monitor (default: true)

Example:
```powershell
.\Configure-SplunkForwarder.ps1 -SplunkIndexer "192.168.64.5" -DeploymentServer "192.168.64.5"
```

#### Test-SplunkForwarder.ps1
Runs diagnostics on forwarder installation.

Tests:
- Installation verification
- Service status
- Configuration files
- Network connectivity
- Log file analysis
- Firewall rules

Example:
```powershell
.\Test-SplunkForwarder.ps1 -SplunkIndexer "192.168.64.5" -DeploymentServer "192.168.64.5"
```

## Configuration Templates

### deploymentclient.conf
Template for configuring forwarders to connect to deployment server.

Location on forwarder: `$SPLUNK_HOME/etc/system/local/deploymentclient.conf`

### outputs.conf
Template for configuring where forwarders send data.

Location on forwarder: `$SPLUNK_HOME/etc/system/local/outputs.conf`

## Troubleshooting

### Ubuntu VM Issues

**Cannot connect to Splunk Web:**
```bash
# Check if Splunk is running
sudo -u splunk /opt/splunk/bin/splunk status

# Check firewall
sudo ufw status

# View logs
tail -f /opt/splunk/var/log/splunk/splunkd.log
```

**Forwarders not connecting:**
```bash
# Check receiving port
sudo netstat -tuln | grep 9997

# Check deployment server
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart
```

### Windows VM Issues

**Forwarder won't install:**
```powershell
# Check installation log
Get-Content $env:TEMP\splunk_install.log -Tail 50

# Verify connectivity
Test-NetConnection -ComputerName <ubuntu-ip> -Port 9997
```

**Service won't start:**
```powershell
# Check service
Get-Service SplunkForwarder | Select-Object *

# View logs
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 50

# Restart service
Restart-Service SplunkForwarder
```

**No data appearing in Splunk:**
```powershell
# Verify configuration
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf"

# Test connectivity
Test-NetConnection -ComputerName <ubuntu-ip> -Port 9997

# Check for errors
.\Test-SplunkForwarder.ps1 -SplunkIndexer <ubuntu-ip> -DeploymentServer <ubuntu-ip>
```

## Network Requirements

Both VMs must be on the same network (UTM shared network by default).

**Required Ports:**
- Ubuntu → Any: 80, 443 (outbound for downloads)
- Windows → Ubuntu: 8089 (deployment server)
- Windows → Ubuntu: 9997 (data forwarding)
- Your Mac → Ubuntu: 8000 (Splunk Web access)

**Firewall Configuration:**

Ubuntu (configured by scripts):
```bash
sudo ufw allow 8000/tcp
sudo ufw allow 8089/tcp
sudo ufw allow 9997/tcp
```

Windows (configured by install script):
```powershell
New-NetFirewallRule -DisplayName "Splunk Management Port" -Direction Inbound -Protocol TCP -LocalPort 8089 -Action Allow
```

## Maintenance

### Backup Configuration

**Ubuntu:**
```bash
# Backup Splunk configuration
sudo tar czf splunk-config-backup-$(date +%Y%m%d).tar.gz /opt/splunk/etc

# Backup scripts
tar czf scripts-backup-$(date +%Y%m%d).tar.gz scripts/
```

**Windows:**
```powershell
# Backup forwarder configuration
Compress-Archive -Path "C:\Program Files\SplunkUniversalForwarder\etc" -DestinationPath "splunk-forwarder-backup-$(Get-Date -Format 'yyyyMMdd').zip"
```

### Updates

**Splunk Enterprise:**
```bash
# Download new version
# Stop Splunk
sudo -u splunk /opt/splunk/bin/splunk stop

# Extract new version over existing
sudo tar xzf splunk-new-version.tgz -C /opt

# Start Splunk
sudo -u splunk /opt/splunk/bin/splunk start
```

**Universal Forwarder:**
```powershell
# Download new MSI
# Run upgrade
msiexec /i splunkforwarder-new-version.msi /quiet AGREETOLICENSE=Yes
```

## VM Management

### Using utmctl (from macOS)

```bash
# List VMs
utmctl list

# Start VMs
utmctl start "splunk-server"
utmctl start "windows-client"

# Stop VMs
utmctl stop "splunk-server"
utmctl stop "windows-client"

# Get VM status
utmctl status "splunk-server"

# Get IP address (requires guest tools)
utmctl ip-address "splunk-server"
```

### Snapshots

Create snapshots before major changes:

1. Right-click VM in UTM
2. Select "Manage Snapshots"
3. Click "Create Snapshot"
4. Name it descriptively (e.g., "pre-upgrade", "working-config")

## Useful Splunk Searches

After deployment, try these searches in Splunk Web:

```
# View all Windows Event Logs
index=main sourcetype=WinEventLog:*

# View Security logs
index=main sourcetype=WinEventLog:Security

# CPU Performance
index=main source="Perfmon:CPU"

# Memory Usage
index=main source="Perfmon:Memory"

# Check forwarder connections
index=_internal sourcetype=splunkd component=Metrics group=tcpin_connections
```

## Additional Resources

- [Splunk Documentation](https://docs.splunk.com/)
- [UTM Documentation](https://docs.getutm.app/)
- [Splunk Universal Forwarder](https://docs.splunk.com/Documentation/Forwarder/)
- [Deployment Server](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver)

## Version Information

- Splunk Enterprise: 9.3.2
- Universal Forwarder: 9.3.2
- Ubuntu Server: 22.04.5 LTS ARM64
- Windows 11: ARM64 Enterprise Evaluation
- UTM: Latest (installed via Homebrew)

## License

This project is for educational and testing purposes. Splunk software requires appropriate licensing for production use.

## Author

Created as part of a Splunk deployment automation project.

---

**Last Updated:** November 2025
