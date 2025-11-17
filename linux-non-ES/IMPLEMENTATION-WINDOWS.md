# Splunk Universal Forwarder Windows Implementation Guide

## Manual Installation Instructions

This guide provides step-by-step PowerShell commands for manually installing Splunk Universal Forwarder on Windows systems **without internet access**.

---

## Prerequisites

- Windows 10/11 or Windows Server 2016+
- Administrator access
- Pre-downloaded Universal Forwarder installer (choose based on your Splunk Enterprise version):
  - `splunkforwarder-10.0.2-*-windows-x64.msi` (159MB) - For Enterprise 10.x
  - `splunkforwarder-9.4.6-*-windows-x64.msi` (171MB) - For Enterprise 9.4.6
  - `splunkforwarder-9.3.2-*-x64-release.msi` (130MB) - Universal compatibility
- Optional add-on files: `splunk-add-on-for-microsoft-windows_901.tgz` and `splunk-supporting-add-on-for-active-directory_311.tgz`

---

## Part 1: Install Universal Forwarder

### Step 1: Open PowerShell as Administrator

Right-click **PowerShell** → **Run as Administrator**

### Step 2: Navigate to Installation Package

```powershell
cd C:\Path\To\windows-forwarder-package

# Verify installer exists (use the version matching your Splunk Enterprise)
# For Enterprise 10.x:
Get-Item splunkforwarder-10.0.2-*-windows-x64.msi

# For Enterprise 9.4.6:
Get-Item splunkforwarder-9.4.6-*-windows-x64.msi

# For universal compatibility:
Get-Item splunkforwarder-9.3.2-*-x64-release.msi
```

### Step 3: Set Configuration Variables

**Important**: Replace these values with your actual Splunk server details

```powershell
$SplunkServerIP = "YOUR_SPLUNK_SERVER_IP"          # Example: "10.0.1.100"
$SplunkPassword = "YOUR_SPLUNK_ADMIN_PASSWORD"     # Secure password of your choice
$DeploymentPort = "8089"
$ReceivingPort = "9997"
```

### Step 4: Install Universal Forwarder (Silent Mode)

```powershell
# Choose the installer version matching your Splunk Enterprise version
# For Enterprise 10.x (recommended):
$InstallerPath = ".\splunkforwarder-10.0.2-*-windows-x64.msi"

# For Enterprise 9.4.6 (recommended):
# $InstallerPath = ".\splunkforwarder-9.4.6-*-windows-x64.msi"

# For universal compatibility:
# $InstallerPath = ".\splunkforwarder-9.3.2-*-x64-release.msi"

$InstallDir = "C:\Program Files\SplunkUniversalForwarder"

# Create installation command
$Arguments = @(
    "/i"
    "`"$InstallerPath`""
    "AGREETOLICENSE=yes"
    "DEPLOYMENT_SERVER=`"${SplunkServerIP}:${DeploymentPort}`""
    "RECEIVING_INDEXER=`"${SplunkServerIP}:${ReceivingPort}`""
    "SPLUNKUSERNAME=admin"
    "SPLUNKPASSWORD=`"$SplunkPassword`""
    "LAUNCHSPLUNK=1"
    "/quiet"
)

# Run installation
Start-Process msiexec.exe -ArgumentList $Arguments -Wait -NoNewWindow

Write-Host "Installation complete. Waiting for services to start..." -ForegroundColor Green
Start-Sleep -Seconds 30
```

### Step 5: Verify Installation

```powershell
# Check if service is running
Get-Service -Name "SplunkForwarder" | Select-Object Status, DisplayName

# Expected output: Status = Running
```

```powershell
# Verify installation directory
Test-Path "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe"

# Expected output: True
```

### Step 6: Configure Splunk Binary Path

```powershell
$SplunkBin = "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe"
```

---

## Part 2: Configure Windows Event Log Collection

### Step 1: Stop Splunk Service

```powershell
Stop-Service -Name "SplunkForwarder" -Force
Start-Sleep -Seconds 10
```

### Step 2: Create Inputs Configuration

```powershell
$InputsConf = @"
# Windows Event Logs
[WinEventLog://Application]
disabled = false
index = wineventlog
sourcetype = WinEventLog:Application

[WinEventLog://Security]
disabled = false
index = wineventlog
sourcetype = WinEventLog:Security

[WinEventLog://System]
disabled = false
index = wineventlog
sourcetype = WinEventLog:System

# Performance Monitoring
[perfmon://CPU]
object = Processor
counters = % Processor Time; % User Time; % Privileged Time
instances = _Total
interval = 30
disabled = false
index = perfmon

[perfmon://Memory]
object = Memory
counters = Available Bytes; Pages/sec; % Committed Bytes In Use
instances = *
interval = 30
disabled = false
index = perfmon

[perfmon://LogicalDisk]
object = LogicalDisk
counters = % Free Space; Free Megabytes; Current Disk Queue Length; % Disk Time; Avg. Disk Queue Length
instances = *
interval = 30
disabled = false
index = perfmon

[perfmon://Network]
object = Network Interface
counters = Bytes Total/sec; Packets/sec; Packets Received/sec; Packets Sent/sec
instances = *
interval = 30
disabled = false
index = perfmon
"@

# Write configuration file
$LocalDir = "C:\Program Files\SplunkUniversalForwarder\etc\system\local"
New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null
Set-Content -Path "$LocalDir\inputs.conf" -Value $InputsConf -Force
```

### Step 3: Configure Forwarding to Indexer

```powershell
$OutputsConf = @"
[tcpout]
defaultGroup = primary_indexers

[tcpout:primary_indexers]
server = ${SplunkServerIP}:${ReceivingPort}
compressed = true

[tcpout-server://${SplunkServerIP}:${ReceivingPort}]
"@

Set-Content -Path "$LocalDir\outputs.conf" -Value $OutputsConf -Force
```

### Step 4: Configure Deployment Client

```powershell
$DeploymentConf = @"
[deployment-client]

[target-broker:deploymentServer]
targetUri = ${SplunkServerIP}:${DeploymentPort}
"@

Set-Content -Path "$LocalDir\deploymentclient.conf" -Value $DeploymentConf -Force
```

### Step 5: Start Splunk Service

```powershell
Start-Service -Name "SplunkForwarder"
Start-Sleep -Seconds 20

# Verify service is running
Get-Service -Name "SplunkForwarder" | Select-Object Status
```

---

## Part 3: Install Windows Add-ons (Optional)

If you want to manually install the Windows and Active Directory add-ons instead of using deployment server:

### Step 1: Stop Splunk

```powershell
Stop-Service -Name "SplunkForwarder" -Force
Start-Sleep -Seconds 10
```

### Step 2: Extract Add-ons

```powershell
# Install 7-Zip or use built-in tar (Windows 10+)
$AppsDir = "C:\Program Files\SplunkUniversalForwarder\etc\apps"

# Extract Windows Add-on
cd C:\Path\To\windows-forwarder-package
tar -xzf splunk-add-on-for-microsoft-windows_901.tgz -C $AppsDir

# Extract Active Directory Add-on
tar -xzf splunk-supporting-add-on-for-active-directory_311.tgz -C $AppsDir

# Verify extraction
Get-ChildItem $AppsDir | Select-Object Name
```

### Step 3: Start Splunk

```powershell
Start-Service -Name "SplunkForwarder"
Start-Sleep -Seconds 20
```

---

## Part 4: Configure Windows Firewall (Optional)

If you need to allow outbound connections:

```powershell
# Allow outbound to Splunk server port 9997 (receiving)
New-NetFirewallRule -DisplayName "Splunk Forwarder - Outbound 9997" `
    -Direction Outbound `
    -Action Allow `
    -Protocol TCP `
    -RemotePort 9997 `
    -RemoteAddress $SplunkServerIP

# Allow outbound to Splunk server port 8089 (deployment)
New-NetFirewallRule -DisplayName "Splunk Deployment Client - Outbound 8089" `
    -Direction Outbound `
    -Action Allow `
    -Protocol TCP `
    -RemotePort 8089 `
    -RemoteAddress $SplunkServerIP

Write-Host "Firewall rules created successfully" -ForegroundColor Green
```

---

## Verification

### Check Splunk Service Status

```powershell
Get-Service -Name "SplunkForwarder" | Format-List *
```

**Expected**: Status = Running, StartType = Automatic

### Check Splunk Version

```powershell
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" version
```

**Expected**: Shows version 10.0.2, 9.4.6, or 9.3.2 (depending on which installer you used)

### View Configuration Files

```powershell
# View inputs configuration
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"

# View outputs configuration
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf"

# View deployment client configuration
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"
```

### Check Splunk Logs

```powershell
# View most recent log entries
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 50

# Check for errors
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" | Select-String -Pattern "ERROR"
```

### Test Connection to Deployment Server

```powershell
Test-NetConnection -ComputerName $SplunkServerIP -Port 8089
```

**Expected**: TcpTestSucceeded = True

### Test Connection to Receiving Port

```powershell
Test-NetConnection -ComputerName $SplunkServerIP -Port 9997
```

**Expected**: TcpTestSucceeded = True

---

## Verify on Splunk Server

After installation, verify on the Splunk server that the forwarder appears:

1. **Via Splunk Web**:
   - Go to `http://[splunk-server]:8000`
   - Settings → Distributed environment → Forwarder management
   - Should show the Windows machine hostname

2. **Via CLI** (on Linux server):
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:password
   ```

3. **Check for Data**:
   - In Splunk Web, go to **Search & Reporting**
   - Run search: `index=wineventlog`
   - Should see Windows event log data (may take 5-10 minutes to appear)

---

## Common PowerShell Commands

### Service Management

```powershell
# Start service
Start-Service -Name "SplunkForwarder"

# Stop service
Stop-Service -Name "SplunkForwarder"

# Restart service
Restart-Service -Name "SplunkForwarder"

# Check status
Get-Service -Name "SplunkForwarder"

# Set service to auto-start
Set-Service -Name "SplunkForwarder" -StartupType Automatic
```

### Splunk CLI Commands

```powershell
$SplunkBin = "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe"

# Check status
& $SplunkBin status

# List inputs
& $SplunkBin list inputstatus -auth admin:$SplunkPassword

# List forward servers
& $SplunkBin list forward-server -auth admin:$SplunkPassword

# Show deployment client info
& $SplunkBin show deploy-poll -auth admin:$SplunkPassword

# Reload deployment client
& $SplunkBin reload deploy-client -auth admin:$SplunkPassword
```

---

## Troubleshooting

### Service Won't Start

```powershell
# Check event logs
Get-EventLog -LogName Application -Source "Splunk*" -Newest 20 | Format-List

# Check splunkd.log
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 100 | Select-String -Pattern "ERROR|WARN"

# Verify installation
Test-Path "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe"
```

### Can't Connect to Deployment Server

```powershell
# Test network connectivity
Test-NetConnection -ComputerName $SplunkServerIP -Port 8089 -InformationLevel Detailed

# Check firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Splunk*"}

# Check deploymentclient.conf
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"
```

### No Data Appearing in Splunk

```powershell
# Verify inputs are configured
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"

# Check if forwarder is sending data
$SplunkBin = "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe"
& $SplunkBin list inputstatus -auth admin:$SplunkPassword

# Check metrics log
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\metrics.log" -Tail 50

# Restart service and wait
Restart-Service -Name "SplunkForwarder"
Start-Sleep -Seconds 60
```

### Permission Errors

The SplunkForwarder service runs as **Local System** by default. If you need to change this:

```powershell
# Change service account (if needed for Active Directory monitoring)
$serviceName = "SplunkForwarder"
$credential = Get-Credential -Message "Enter domain admin credentials"

$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
$service.Change($null,$null,$null,$null,$null,$null,$credential.UserName,$credential.GetNetworkCredential().Password)

Restart-Service -Name $serviceName
```

---

## Uninstallation (If Needed)

### Method 1: Using MSI

```powershell
# Find product code
$productCode = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Splunk*"} | Select-Object -ExpandProperty IdentifyingNumber

# Uninstall
Start-Process msiexec.exe -ArgumentList "/x $productCode /quiet" -Wait
```

### Method 2: Manual Cleanup

```powershell
# Stop service
Stop-Service -Name "SplunkForwarder" -Force

# Remove service
sc.exe delete SplunkForwarder

# Remove installation directory
Remove-Item -Path "C:\Program Files\SplunkUniversalForwarder" -Recurse -Force

# Remove firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Splunk*"} | Remove-NetFirewallRule
```

---

## Bulk Deployment Script

For deploying to multiple Windows machines, save this as `Deploy-SplunkForwarder.ps1`:

```powershell
# Deploy-SplunkForwarder.ps1
# Run as Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$SplunkServerIP,

    [Parameter(Mandatory=$true)]
    [string]$SplunkPassword,

    [string]$InstallerPath = ".\splunkforwarder-10.0.2-*-windows-x64.msi"  # Or use 9.4.6 or 9.3.2
)

# Installation
Write-Host "Installing Splunk Universal Forwarder..." -ForegroundColor Cyan
$Arguments = @(
    "/i", "`"$InstallerPath`"",
    "AGREETOLICENSE=yes",
    "DEPLOYMENT_SERVER=`"${SplunkServerIP}:8089`"",
    "RECEIVING_INDEXER=`"${SplunkServerIP}:9997`"",
    "SPLUNKUSERNAME=admin",
    "SPLUNKPASSWORD=`"$SplunkPassword`"",
    "LAUNCHSPLUNK=1",
    "/quiet"
)
Start-Process msiexec.exe -ArgumentList $Arguments -Wait -NoNewWindow

Start-Sleep -Seconds 30

# Verify
$service = Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
if ($service.Status -eq "Running") {
    Write-Host "SUCCESS: Splunk Universal Forwarder installed and running" -ForegroundColor Green
} else {
    Write-Host "ERROR: Installation may have failed" -ForegroundColor Red
}

# Test connectivity
Write-Host "Testing connection to Splunk server..." -ForegroundColor Cyan
$testDeployment = Test-NetConnection -ComputerName $SplunkServerIP -Port 8089 -WarningAction SilentlyContinue
$testReceiving = Test-NetConnection -ComputerName $SplunkServerIP -Port 9997 -WarningAction SilentlyContinue

if ($testDeployment.TcpTestSucceeded -and $testReceiving.TcpTestSucceeded) {
    Write-Host "SUCCESS: Can reach Splunk server on ports 8089 and 9997" -ForegroundColor Green
} else {
    Write-Host "WARNING: Cannot reach Splunk server. Check network/firewall." -ForegroundColor Yellow
}
```

**Usage**:
```powershell
.\Deploy-SplunkForwarder.ps1 -SplunkServerIP "YOUR_SPLUNK_SERVER_IP" -SplunkPassword "YOUR_PASSWORD"
```

---

## Important Notes

1. **Security**: Store the Splunk admin password securely. Consider using PowerShell secure strings in production.

2. **Deployment Server**: The forwarder will automatically receive configuration from the deployment server based on its hostname pattern (e.g., machines with "WIN-" in hostname).

3. **Data Delay**: Allow 5-10 minutes after installation for data to start appearing in Splunk.

4. **Hostname**: The forwarder uses the Windows hostname. Ensure it's descriptive (e.g., "WIN-DC01" for domain controller).

5. **Indexes**: Make sure the `wineventlog` and `perfmon` indexes exist on the Splunk server before data arrives.

6. **Active Directory**: For AD monitoring, the service account must have appropriate permissions. Consider running as a domain admin account.

---

## Next Steps

After installation:

1. Verify forwarder appears in Splunk Web (Settings → Forwarder management)
2. Confirm data is flowing (run search: `index=wineventlog | stats count by host`)
3. Configure additional inputs if needed
4. Set up alerts for critical Windows events
5. Review and customize deployment server apps

---

**Installation Complete!**

Your Windows Universal Forwarder is now sending data to the Splunk Enterprise server.
