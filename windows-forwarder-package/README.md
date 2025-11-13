# Windows Universal Forwarder Installation Package

Complete package for deploying Splunk Universal Forwarder on Windows systems.

## Contents

### Installer
- **splunkforwarder-9.3.2-d8bb32809498-x64-release.msi** (130 MB)
  - Splunk Universal Forwarder 9.3.2 for Windows x64

### Add-ons (Deployed via Deployment Server)
- **splunk-add-on-for-microsoft-windows_901.tgz**
  - Collects Windows Event Logs, Performance data, Registry, Services
- **splunk-supporting-add-on-for-active-directory_311.tgz**
  - Collects Active Directory logs (if applicable)

### OCS Custom Deployment Apps (in deployment-apps/)
- **ocs_add-on_deployment** - Connects forwarders to deployment server
- **ocs_add-on_outputs** - Configures data forwarding to indexers
- **ocs_add-on_windows** - Windows Event Log collection (System, Security, Application)
- These are automatically deployed from the Splunk server when forwarders connect

### PowerShell Scripts
- **config.ps1** - Configuration file (EDIT THIS FIRST)
- **Install-SplunkForwarder.ps1** - Automated installation script
- **Configure-SplunkForwarder.ps1** - Post-install configuration
- **Test-SplunkForwarder.ps1** - Verify forwarder connectivity

## Quick Installation

### 1. Edit Configuration

Open `config.ps1` and update:
```powershell
$Script:DeploymentServerAddress = "YOUR_SPLUNK_SERVER_IP"
$Script:IndexerAddress = "YOUR_SPLUNK_SERVER_IP"
```

### 2. Run Installation (As Administrator)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
.\Install-SplunkForwarder.ps1
```

### 3. Verify

```powershell
.\Test-SplunkForwarder.ps1
```

## What Gets Installed

- Universal Forwarder installed to `C:\Program Files\SplunkUniversalForwarder`
- Configured to connect to Deployment Server (receives apps/configs)
- Configured to forward to Indexer
- Runs as Windows Service (auto-start on boot)

**After connecting to Deployment Server, these OCS apps are auto-deployed:**
- **ocs_add-on_deployment** - Deployment client configuration
- **ocs_add-on_outputs** - Forwarding to indexer
- **ocs_add-on_windows** - Windows Event Log collection (System, Security, Application → wineventlog index)

## Add-ons Deployment

### OCS Custom Apps (Included)
The OCS deployment apps in `deployment-apps/` are ready for deployment server:
1. On Splunk server, run `configure-deployment-server.sh` (automatically installs OCS apps)
2. Forwarders connecting will automatically receive:
   - ocs_add-on_deployment (deployment client config)
   - ocs_add-on_outputs (forwarding config)
   - ocs_add-on_windows (Windows Event Log collection)

### Official Splunk Add-ons (Optional)
The `.tgz` add-on files (Microsoft Windows TA, Active Directory TA) should be:
1. Extracted on Splunk **indexer/search head** (not forwarders)
2. Used for field extraction and CIM normalization
3. Located at `/opt/splunk/etc/apps/` on the Splunk server

These TAs are for parsing, not collection. Collection is handled by OCS apps.

## System Requirements

- Windows Server 2012 R2 or later / Windows 8.1 or later
- 2 GB RAM minimum
- 2 GB disk space minimum
- Network access to Splunk server (ports 8089, 9997)
- PowerShell 5.1 or later
- Administrator privileges

## Default Credentials

- Username: `admin`
- Password: `5plunk#1!` (configured in config.ps1)

**Note:** Forwarders don't typically need login access (managed via Deployment Server).

## Firewall Requirements

**Outbound from Windows to Splunk Server:**
- TCP 8089 (Deployment Server)
- TCP 9997 (Indexer receiving)

No inbound ports required on Windows forwarder.

## Troubleshooting

**Check forwarder service:**
```powershell
Get-Service SplunkForwarder
```

**Check forwarder logs:**
```powershell
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 50
```

**Test connectivity to Splunk server:**
```powershell
Test-NetConnection -ComputerName YOUR_SPLUNK_IP -Port 8089
Test-NetConnection -ComputerName YOUR_SPLUNK_IP -Port 9997
```

**Restart forwarder:**
```powershell
Restart-Service SplunkForwarder
```

## For Production Deployment

1. **Test in lab first** - Use this package to test complete workflow
2. **Update config.ps1** - Set correct Splunk server IP
3. **Copy entire folder** to Windows systems (USB, network share, GPO)
4. **Run as Administrator** - Installation requires admin rights
5. **Verify in Splunk** - Check Settings → Forwarder Management

## Package This for Distribution

**Create ZIP for easy transfer:**
```powershell
Compress-Archive -Path . -DestinationPath windows-forwarder-package.zip
```

**Or use USB/Network Share:**
- Copy entire `windows-forwarder-package` folder
- Users run installation from that folder

---

**Version:** Splunk UF 9.3.2
**Last Updated:** 2025-11-03
**For:** Windows production deployments
