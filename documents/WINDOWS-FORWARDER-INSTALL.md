# Windows Universal Forwarder Installation Guide

Quick installation guide for Splunk Universal Forwarder on Windows systems.

## Prerequisites

- **Windows OS**: Windows Server 2016+ or Windows 10/11
- **Administrator Access**: PowerShell as Administrator
- **Network Access**: Connectivity to Splunk server on ports 8089 and 9997
- **Files**: Universal Forwarder installer in `downloads/` directory
- **Splunk Server**: Must be installed and configured first (see [INSTALLATION.md](INSTALLATION.md))

## Quick Start

### 1. Get Splunk Server IP Address

On your Linux Splunk server:
```bash
hostname -I | awk '{print $1}'
```
Note this IP address - you'll need it for configuration.

### 2. Edit Configuration File

On Windows system:
1. Navigate to `windows-forwarders/` directory
2. Edit `config.ps1` in notepad or PowerShell ISE
3. Update these values:
   ```powershell
   # Line 13: Change to your Splunk server IP
   $Script:DeploymentServerAddress = "192.168.1.100"  # YOUR SPLUNK SERVER IP

   # Line 17: Usually same as deployment server
   $Script:IndexerAddress = "192.168.1.100"  # YOUR SPLUNK SERVER IP
   ```
4. Save the file

### 3. Run Installation

Open PowerShell as Administrator:

```powershell
# Set execution policy (first time only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Navigate to project directory
cd C:\path\to\splunk-installation\windows-forwarders

# Run installer
.\Install-SplunkForwarder.ps1
```

### 4. Verify Installation

The script will:
- ✓ Install Splunk Universal Forwarder
- ✓ Configure deployment server connection
- ✓ Start the SplunkForwarder service
- ✓ Configure Windows Firewall
- ✓ Display installation summary

Wait a few minutes, then check Splunk Web:
1. Go to http://\<splunk-server\>:8000
2. Settings → Forwarders → Forwarders
3. Look for your Windows hostname

## Installation Details

### What Gets Installed

| Component | Value |
|-----------|-------|
| Install Path | `C:\Program Files\SplunkUniversalForwarder` |
| Service Name | `SplunkForwarder` |
| Version | 9.3.2 (compatible with Splunk 10.0.1) |
| Default Password | `5plunk#1!` |

### Automatic Configuration

The deployment server automatically pushes:
- Windows Event Log collection (Application, Security, System)
- Performance Monitor counters (CPU, Memory, Disk, Network)
- Data forwarding configuration
- Index routing

**No manual configuration needed** if deployment server is working properly.

### Windows Firewall Rules

Automatically created:
- Port 8089 (TCP Inbound) - Splunk Management Port

### Hostname Requirement

For automatic app deployment, Windows hostname should contain:
- `-windows-` or `-win-`
- Examples: `SERVER-windows-01`, `DC-win-primary`

If not, deployment server won't automatically deploy Windows apps.

## Manual Configuration (Optional)

Only needed if deployment server isn't working or you need custom settings.

```powershell
.\Configure-SplunkForwarder.ps1
```

This script will warn you that deployment server handles configuration automatically.

## Verification & Testing

### Test Connectivity

```powershell
# Load config and test
cd windows-forwarders
. .\config.ps1
Test-SplunkConfig

# Manual connectivity test
Test-NetConnection -ComputerName 192.168.1.100 -Port 9997
Test-NetConnection -ComputerName 192.168.1.100 -Port 8089
```

### Check Service Status

```powershell
# Service status
Get-Service SplunkForwarder

# Should show:
# Status: Running
# StartType: Automatic

# Restart if needed
Restart-Service SplunkForwarder
```

### View Logs

```powershell
# View recent log entries
$logPath = "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log"
Get-Content $logPath -Tail 50

# Check for errors
Get-Content $logPath | Select-String -Pattern "ERROR" | Select-Object -Last 10

# Monitor deployment client
Get-Content $logPath | Select-String -Pattern "DeploymentClient"
```

### Verify Data in Splunk

In Splunk Web, search for:
```spl
# All data from this Windows host
index=main host="YOUR-HOSTNAME"

# Windows Event Logs
index=main sourcetype=WinEventLog:* host="YOUR-HOSTNAME"

# Performance data
index=main source="Perfmon:*" host="YOUR-HOSTNAME"

# Check last 15 minutes
index=main host="YOUR-HOSTNAME" earliest=-15m
```

## Troubleshooting

### Installation Fails

**Installer not found:**
- Ensure `splunkforwarder-9.3.2-d8bb32809498-x64-release.msi` is in `downloads/` directory
- Download from: https://www.splunk.com/en_us/download/universal-forwarder.html

**Permission denied:**
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → Run as administrator

# Verify admin rights
[Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544'
# Should return True
```

**Execution policy error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Service Won't Start

```powershell
# Check service
Get-Service SplunkForwarder | Select-Object *

# View event log
Get-EventLog -LogName Application -Source "Splunk*" -Newest 20

# Check installation log
Get-Content "$env:TEMP\splunk_install.log" -Tail 50

# Try manual start
Start-Service SplunkForwarder
```

### Can't Connect to Deployment Server

**Check network connectivity:**
```powershell
# Test deployment server port
Test-NetConnection -ComputerName 192.168.1.100 -Port 8089

# If fails, check:
# 1. Splunk server firewall
# 2. Windows firewall on client
# 3. Network routing
```

**Check deployment client config:**
```powershell
$deployConfig = "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"
Get-Content $deployConfig

# Should show:
# [target-broker:deploymentServer]
# targetUri = <server-ip>:8089
```

**Force deployment client check-in:**
```powershell
# Restart service to force check-in
Restart-Service SplunkForwarder

# Check logs for deployment activity
$logPath = "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log"
Get-Content $logPath | Select-String -Pattern "DeploymentClient" | Select-Object -Last 20
```

### No Data Appearing in Splunk

**Check outputs configuration:**
```powershell
# Via deployed app
$outputsConf = "C:\Program Files\SplunkUniversalForwarder\etc\apps\windows_forwarder_base\local\outputs.conf"
if (Test-Path $outputsConf) {
    Get-Content $outputsConf
} else {
    Write-Host "Deployment app not received yet"
}

# Check connectivity to indexer
Test-NetConnection -ComputerName 192.168.1.100 -Port 9997
```

**Verify inputs are enabled:**
```powershell
# Check deployed app inputs
$inputsConf = "C:\Program Files\SplunkUniversalForwarder\etc\apps\windows_forwarder_base\local\inputs.conf"
if (Test-Path $inputsConf) {
    Get-Content $inputsConf
} else {
    Write-Host "Deployment app not received yet - check deployment server"
}
```

**Check forwarder queue:**
```powershell
# Look for queue full errors
$logPath = "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log"
Get-Content $logPath | Select-String -Pattern "queue" | Select-Object -Last 10
```

### Firewall Blocking

**Windows Firewall:**
```powershell
# Check existing rules
Get-NetFirewallRule -DisplayName "*Splunk*"

# If missing, create manually
New-NetFirewallRule -DisplayName "Splunk Management Port" `
  -Direction Inbound -Protocol TCP -LocalPort 8089 -Action Allow

# Disable Windows Firewall (testing only!)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

**Check outbound connectivity:**
```powershell
# Allow outbound if blocked
New-NetFirewallRule -DisplayName "Splunk Outbound to Indexer" `
  -Direction Outbound -Protocol TCP -RemotePort 9997 -Action Allow
```

## Advanced Configuration

### Custom Data Inputs

If you need to collect additional data beyond what deployment server provides:

1. Create `inputs.conf` in `C:\Program Files\SplunkUniversalForwarder\etc\system\local\`
2. Add custom inputs:
   ```ini
   [monitor://C:\logs\app.log]
   disabled = false
   index = main
   sourcetype = app:log

   [WinEventLog://Microsoft-Windows-Sysmon/Operational]
   disabled = false
   index = main
   renderXml = true
   ```
3. Restart service: `Restart-Service SplunkForwarder`

### Change Forwarder Password

```powershell
# Using splunk.exe
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk.exe edit user admin -password NewPassword -auth admin:5plunk#1!
```

### Uninstall Forwarder

```powershell
# Stop service
Stop-Service SplunkForwarder

# Uninstall via Programs and Features
# OR via command line:
msiexec /x splunkforwarder-9.3.2-d8bb32809498-x64-release.msi /quiet

# Remove installation directory (if needed)
Remove-Item -Recurse -Force "C:\Program Files\SplunkUniversalForwarder"
```

## Deployment at Scale

### Deploy to Multiple Systems

**Using Group Policy:**
1. Place installer in network share
2. Create GPO for software installation
3. Configure startup script with installation command

**Using PowerShell Remoting:**
```powershell
# From admin workstation
$computers = Get-Content "computers.txt"
$credential = Get-Credential

Invoke-Command -ComputerName $computers -Credential $credential -FilePath .\Install-SplunkForwarder.ps1
```

**Using SCCM/Intune:**
- Package installer MSI
- Deploy with appropriate parameters
- Monitor deployment status

### Silent Installation

For automated deployments:
```powershell
# Silent install with MSI directly
msiexec /i splunkforwarder-9.3.2-d8bb32809498-x64-release.msi `
  AGREETOLICENSE=Yes `
  SPLUNKPASSWORD="5plunk#1!" `
  DEPLOYMENT_SERVER="192.168.1.100:8089" `
  LAUNCHSPLUNK=1 `
  SERVICESTARTTYPE=auto `
  /quiet /norestart
```

## Common Commands Reference

```powershell
# Service Management
Get-Service SplunkForwarder
Start-Service SplunkForwarder
Stop-Service SplunkForwarder
Restart-Service SplunkForwarder

# View Logs
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 50

# Check Configuration
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf"

# Test Connectivity
Test-NetConnection -ComputerName <server-ip> -Port 9997
Test-NetConnection -ComputerName <server-ip> -Port 8089

# Force Check-in
Restart-Service SplunkForwarder

# Installed Apps
Get-ChildItem "C:\Program Files\SplunkUniversalForwarder\etc\apps"
```

## Best Practices

1. **Hostname Convention**: Include `-windows-` or `-win-` in hostname
2. **Monitor Disk Space**: Forwarder queues data locally if indexer unavailable
3. **Regular Updates**: Keep forwarder version current
4. **Test Before Prod**: Test deployment on single machine first
5. **Document Configuration**: Keep config.ps1 in version control

## Support

- **Logs**: `C:\Program Files\SplunkUniversalForwarder\var\log\splunk\`
- **Installation Log**: `%TEMP%\splunk_install.log`
- **Splunk Docs**: https://docs.splunk.com/Documentation/Forwarder/
- **See Also**: [ADMINISTRATION.md](ADMINISTRATION.md)

---

**Last Updated**: November 2025
