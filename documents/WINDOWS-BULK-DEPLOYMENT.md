# Windows Universal Forwarder - Bulk Deployment Guide

## Overview

This guide provides multiple approaches for deploying Splunk Universal Forwarder to hundreds or thousands of Windows endpoints. These methods are designed for IT infrastructure teams to automate large-scale deployments.

## Prerequisites

- **Deployment Server** configured and accessible
- **Network Share** accessible to all target machines
- **Admin Credentials** with rights to install software on target machines
- **Splunk Package** with OCS add-ons copied to network share

##

 Deployment Methods

### Method 1: CSV-Based PowerShell Deployment (Recommended)
**Best for**: 10-1000+ endpoints, controlled rollout, mixed environments

### Method 2: Group Policy (GPO)
**Best for**: Domain-joined machines, scheduled deployments, automatic installation

### Method 3: SCCM/ConfigMgr
**Best for**: Enterprises using Microsoft Endpoint Manager, compliance tracking

### Method 4: Intune/MDM
**Best for**: Cloud-managed devices, modern management, remote workers

### Method 5: PDQ Deploy
**Best for**: Small-to-medium businesses, simple GUI-based deployment

---

## Method 1: CSV-Based PowerShell Deployment

### Overview
Use a CSV file listing target machines and deploy via PowerShell remoting.

### Step 1: Prepare Network Share

```powershell
# Create deployment share
New-Item -Path "\\fileserver\SplunkDeploy" -ItemType Directory
New-SmbShare -Name "SplunkDeploy" -Path "C:\SplunkDeploy" -FullAccess "Domain Admins"

# Copy forwarder package
Copy-Item "windows-forwarder-package\*" "\\fileserver\SplunkDeploy\" -Recurse
```

### Step 2: Create Target CSV

Create `targets.csv`:
```csv
ComputerName,Environment,Location
WORKSTATION001,Production,Office-NY
WORKSTATION002,Production,Office-NY
SERVER001,Production,Datacenter
SERVER002,Production,Datacenter
LAPTOP001,Production,Remote
```

### Step 3: Create Bulk Deployment Script

Save as `Deploy-SplunkBulk.ps1`:

```powershell
<#
.SYNOPSIS
    Bulk deployment script for Splunk Universal Forwarder
.DESCRIPTION
    Deploys Splunk UF to multiple machines from CSV input file
.PARAMETER CSVPath
    Path to CSV file containing target computer names
.PARAMETER DeploymentServer
    IP or hostname of Splunk Deployment Server
.PARAMETER NetworkShare
    UNC path to network share containing forwarder MSI
.PARAMETER Credential
    PSCredential object for remote authentication
.EXAMPLE
    .\Deploy-SplunkBulk.ps1 -CSVPath .\targets.csv -DeploymentServer "10.1.1.5" -NetworkShare "\\fileserver\SplunkDeploy"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CSVPath,

    [Parameter(Mandatory=$true)]
    [string]$DeploymentServer,

    [Parameter(Mandatory=$true)]
    [string]$NetworkShare,

    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential
)

# Import targets
$Targets = Import-Csv -Path $CSVPath

# Prompt for credentials if not provided
if (-not $Credential) {
    $Credential = Get-Credential -Message "Enter domain admin credentials for remote installation"
}

# Prompt for Splunk admin password (for forwarder configuration)
$SplunkAdminPassword = Read-Host -AsSecureString "Enter Splunk admin password"

# Results tracking
$Results = @()

# Process each target
foreach ($Target in $Targets) {
    $ComputerName = $Target.ComputerName

    Write-Host "`n[Processing] $ComputerName" -ForegroundColor Cyan

    $Result = [PSCustomObject]@{
        ComputerName = $ComputerName
        Status = ""
        Message = ""
        Timestamp = Get-Date
    }

    try {
        # Test connectivity
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            throw "Machine not reachable"
        }

        # Test WinRM
        if (-not (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
            throw "WinRM not available"
        }

        # Execute remote installation
        Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            param($NetworkShare, $DeploymentServer, $SplunkPassword)

            # Copy installer locally (faster than installing over network)
            $LocalPath = "C:\Temp\SplunkInstall"
            New-Item -Path $LocalPath -ItemType Directory -Force | Out-Null

            Copy-Item "$NetworkShare\*" -Destination $LocalPath -Recurse -Force

            # Run installation
            Set-Location $LocalPath

            # Install forwarder
            $InstallArgs = @(
                "/i"
                "splunkforwarder-9.3.2-d8bb32809498-x64-release.msi"
                "/quiet"
                "AGREETOLICENSE=Yes"
                "DEPLOYMENT_SERVER=$DeploymentServer:8089"
                "LAUNCHSPLUNK=1"
                "SERVICESTARTTYPE=auto"
            )

            Start-Process -FilePath "msiexec.exe" -ArgumentList $InstallArgs -Wait

            # Wait for service to start
            Start-Sleep -Seconds 10

            # Verify installation
            if (Get-Service "SplunkForwarder" -ErrorAction SilentlyContinue) {
                return "SUCCESS"
            } else {
                return "FAILED: Service not found"
            }

        } -ArgumentList $NetworkShare, $DeploymentServer, $SplunkAdminPassword

        $Result.Status = "SUCCESS"
        $Result.Message = "Forwarder installed and service running"
        Write-Host "[SUCCESS] $ComputerName" -ForegroundColor Green

    } catch {
        $Result.Status = "FAILED"
        $Result.Message = $_.Exception.Message
        Write-Host "[FAILED] $ComputerName - $($_.Exception.Message)" -ForegroundColor Red
    }

    $Results += $Result
}

# Export results
$Results | Export-Csv -Path "deployment-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Targets: $($Results.Count)"
Write-Host "Successful: $(($Results | Where-Object {$_.Status -eq 'SUCCESS'}).Count)" -ForegroundColor Green
Write-Host "Failed: $(($Results | Where-Object {$_.Status -eq 'FAILED'}).Count)" -ForegroundColor Red
```

### Step 4: Execute Deployment

```powershell
# Run deployment
.\Deploy-SplunkBulk.ps1 `
    -CSVPath ".\targets.csv" `
    -DeploymentServer "10.1.1.5" `
    -NetworkShare "\\fileserver\SplunkDeploy"

# Review results
Import-Csv "deployment-results-*.csv" | Format-Table -AutoSize
```

### Step 5: Verify Deployment

On Splunk server:
```bash
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:password
```

Or in Splunk Web: **Settings → Forwarder Management → Clients**

---

## Method 2: Group Policy (GPO) Deployment

### Overview
Use Active Directory Group Policy to deploy and maintain forwarders automatically.

### Step 1: Prepare MSI Package

1. Copy `splunkforwarder-9.3.2-*.msi` to `\\domain.local\NETLOGON\SplunkForwarder\`
2. Create configuration file `\\domain.local\NETLOGON\SplunkForwarder\install-config.txt`:

```
DEPLOYMENT_SERVER=10.1.1.5:8089
AGREETOLICENSE=Yes
LAUNCHSPLUNK=1
SERVICESTARTTYPE=auto
```

### Step 2: Create GPO

1. Open **Group Policy Management**
2. Create new GPO: `Deploy Splunk Universal Forwarder`
3. Link to target OU (e.g., `OU=Workstations,DC=domain,DC=local`)

### Step 3: Configure Software Installation

1. Edit GPO → **Computer Configuration** → **Policies** → **Software Settings** → **Software Installation**
2. Right-click → **New** → **Package**
3. Browse to `\\domain.local\NETLOGON\SplunkForwarder\splunkforwarder-9.3.2-*.msi`
4. Select **Assigned**
5. **Properties** → **Deployment** → Select:
   - ☑ Install this application at logon
   - ☑ Install this application on computer startup (recommended)

### Step 4: Add Transform (for MSI properties)

Since GPO doesn't natively pass MSI properties, use a startup script:

1. GPO → **Computer Configuration** → **Policies** → **Windows Settings** → **Scripts** → **Startup**
2. Add PowerShell script:

```powershell
# Configure-SplunkForwarder-GPO.ps1
$SplunkHome = "C:\Program Files\SplunkUniversalForwarder"

if (Test-Path $SplunkHome) {
    # Configure deployment client
    & "$SplunkHome\bin\splunk.exe" set deploy-poll "10.1.1.5:8089" -auth admin:changeme

    # Restart service
    Restart-Service SplunkForwarder
}
```

### Step 5: Apply and Test

1. Force GPO update on test machine: `gpupdate /force`
2. Reboot test machine
3. Verify: `Get-Service SplunkForwarder`
4. Roll out to production OUs

### GPO Deployment Notes

- **Timing**: Installation happens at computer startup or user logon
- **Uninstall**: Edit GPO → Package Properties → **Deployment** → **Uninstall this application when it falls out of the scope of management**
- **Targeting**: Use WMI filters or security group filtering for selective deployment

---

## Method 3: SCCM/Configuration Manager

### Overview
Deploy via Microsoft Endpoint Configuration Manager (SCCM).

### Step 1: Create Application

1. **Software Library** → **Application Management** → **Applications**
2. **Create Application** → Select **Manually specify the application information**
3. Name: `Splunk Universal Forwarder 9.3.2`

### Step 2: Add Deployment Type

1. **Deployment Types** → **Add**
2. Type: **Windows Installer (*.msi file)**
3. Content location: `\\sccm\sources$\Splunk\splunkforwarder-9.3.2-*.msi`
4. Installation command:
```
msiexec /i splunkforwarder-9.3.2-d8bb32809498-x64-release.msi /quiet AGREETOLICENSE=Yes DEPLOYMENT_SERVER=10.1.1.5:8089 LAUNCHSPLUNK=1 SERVICESTARTTYPE=auto
```
5. Uninstall command:
```
msiexec /x {PRODUCT-CODE-GUID} /quiet
```

### Step 3: Configure Detection Method

1. **Detection Methods** → **Add Clause**
2. Setting Type: **File System**
3. File/folder: `C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe`
4. The file or folder must exist

Or use service detection:
1. Setting Type: **Windows Installer**
2. Product code: `{Use MSI product GUID}`

### Step 4: Configure Requirements

1. **Requirements** → **Add**
2. Condition: **Operating System**
3. Select: Windows 10/11, Windows Server 2016/2019/2022

### Step 5: Deploy Application

1. Right-click application → **Deploy**
2. Collection: Select target collection (e.g., `All Workstations`)
3. Purpose: **Required**
4. Schedule: Immediately or specific maintenance window
5. User Experience: **Install for system**, **Hide in Software Center**

### Step 6: Monitor Deployment

1. **Monitoring** → **Deployments**
2. Find your Splunk deployment
3. View compliance status

### SCCM Deployment Notes

- **Staged Rollout**: Use multiple collections (Pilot → Production)
- **Maintenance Windows**: Schedule for off-hours
- **Dependency**: Can create dependency on .NET Framework if needed
- **Supersedence**: Configure to automatically upgrade older versions

---

## Method 4: Microsoft Intune/MDM

### Overview
Deploy to cloud-managed or hybrid Azure AD-joined devices.

### Step 1: Prepare Win32 App Package

1. Download **Microsoft Win32 Content Prep Tool**
2. Convert MSI to `.intunewin`:

```powershell
.\IntuneWinAppUtil.exe -c "C:\Source" -s "splunkforwarder-9.3.2-d8bb32809498-x64-release.msi" -o "C:\Output"
```

### Step 2: Create Intune App

1. **Microsoft Endpoint Manager admin center** → **Apps** → **Windows**
2. **Add** → **Windows app (Win32)**
3. Upload `.intunewin` package

### Step 3: Configure App Information

- **Name**: Splunk Universal Forwarder 9.3.2
- **Description**: Collects and forwards Windows logs to Splunk
- **Publisher**: Splunk Inc.
- **Install command**:
```
msiexec /i splunkforwarder-9.3.2-d8bb32809498-x64-release.msi /quiet AGREETOLICENSE=Yes DEPLOYMENT_SERVER=10.1.1.5:8089 LAUNCHSPLUNK=1 SERVICESTARTTYPE=auto
```
- **Uninstall command**:
```
msiexec /x {PRODUCT-GUID} /quiet
```

### Step 4: Configure Requirements

- **Operating system architecture**: 64-bit
- **Minimum operating system**: Windows 10 1607

### Step 5: Configure Detection Rules

**Detection rule type**: File
- **Path**: `C:\Program Files\SplunkUniversalForwarder\bin`
- **File or folder**: `splunk.exe`
- **Detection method**: File or folder exists

### Step 6: Assign to Groups

1. **Assignments** → **Required**
2. Select Azure AD group (e.g., `SG-Splunk-Forwarders`)
3. Save

### Step 7: Monitor

**Apps** → **Monitor** → **App install status**

### Intune Deployment Notes

- **Device Targeting**: Assign to device groups, not user groups
- **Win32 App Requirements**: Requires Intune Management Extension
- **Cloud-Only**: Works for Azure AD-joined and Hybrid AD-joined devices
- **Retry Logic**: Intune automatically retries failed installations

---

## Method 5: PDQ Deploy (Third-Party)

### Overview
Simple GUI-based deployment tool popular in SMB environments.

### Step 1: Create Package

1. **PDQ Deploy** → **New Package**
2. Name: `Splunk Universal Forwarder 9.3.2`
3. **New Step** → **Install**
4. File: Browse to `splunkforwarder-9.3.2-*.msi`
5. Parameters:
```
/quiet AGREETOLICENSE=Yes DEPLOYMENT_SERVER=10.1.1.5:8089 LAUNCHSPLUNK=1 SERVICESTARTTYPE=auto
```

### Step 2: Configure Success Codes

- Success Codes: `0, 3010`
- Error Handling: Stop deployment on error

### Step 3: Deploy to Targets

1. Select package → **Deploy Once**
2. Choose Targets:
   - Active Directory (select OU)
   - PDQ Inventory (select collection)
   - Manual list
3. **Deploy Now**

### Step 4: Monitor

View real-time deployment status in PDQ Deploy console.

---

## Deployment Best Practices

### Pre-Deployment Testing

1. **Pilot Group**: Test on 5-10 machines first
2. **Verification**:
   - Service running: `Get-Service SplunkForwarder`
   - Deployment client connected: Check Splunk server
   - Data flowing: Search for `index=_internal host=TESTMACHINE`

### Staged Rollout

1. **Phase 1**: Pilot group (1% of fleet)
2. **Phase 2**: Development/test systems (10%)
3. **Phase 3**: Non-critical production (40%)
4. **Phase 4**: Critical production (49%)

### Monitoring Deployment Health

Create Splunk dashboard to monitor forwarder deployment:

```spl
index=_internal source=*metrics.log group=tcpin_connections
| stats dc(hostname) as forwarder_count by _time span=1h
| timechart span=1h sum(forwarder_count) as "Connected Forwarders"
```

### Troubleshooting Failed Installations

Common issues:

1. **WinRM not enabled**: Enable with `Enable-PSRemoting -Force`
2. **Firewall blocking**: Allow ports 8089 and 9997
3. **Permissions**: Ensure installer runs as SYSTEM or admin
4. **Disk space**: Requires 2GB minimum
5. **Previous installation**: Uninstall old version first

### Cleanup Script for Failed Installations

```powershell
# Remove-SplunkForwarder.ps1
Get-Service "SplunkForwarder" -ErrorAction SilentlyContinue | Stop-Service -Force
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Splunk*"} | ForEach-Object {$_.Uninstall()}
Remove-Item "C:\Program Files\SplunkUniversalForwarder" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## Security Considerations

### Credential Management

- **Never hardcode passwords** in scripts
- Use **Credential Manager** or **Azure Key Vault**
- Rotate service account passwords regularly

### Network Security

- **Deployment Server**: Restrict access to port 8089
- **TLS/SSL**: Configure encrypted forwarding (see SSL guide)
- **Firewall rules**: Only allow necessary traffic

### Audit Logging

Enable deployment auditing:

```powershell
# Log all deployments
$DeploymentLog = "\\fileserver\logs\splunk-deployments.csv"
$LogEntry = [PSCustomObject]@{
    Timestamp = Get-Date
    ComputerName = $env:COMPUTERNAME
    User = $env:USERNAME
    Status = "SUCCESS"
}
$LogEntry | Export-Csv -Path $DeploymentLog -Append -NoTypeInformation
```

---

## Post-Deployment Tasks

### 1. Verify Forwarder Health

On Splunk server:
```bash
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:password | grep -c "serverName"
```

### 2. Check Data Flow

```spl
index=wineventlog
| stats count by host
| where count > 0
```

### 3. Review License Usage

**Settings → Licensing** → Check daily ingestion

### 4. Create Health Dashboard

Use **Splunk DMC** (Distributed Management Console) or create custom dashboard to monitor:
- Forwarder connection status
- Data ingestion rate per forwarder
- Forwarders not reporting
- Failed forwarding queues

---

## Scaling Considerations

### Large Deployments (10,000+ endpoints)

1. **Multiple Deployment Servers**: Distribute load
2. **Batch Deployment**: Deploy 100-500 machines per batch
3. **Bandwidth Management**: Schedule deployments during off-hours
4. **Distributed Execution**: Use multiple jump servers for PSRemoting

### Performance Tuning

- **Parallel Execution**: Run 10-50 concurrent installations
- **Local Caching**: Copy MSI locally before installing
- **Pre-staging**: Push files ahead of time, install on schedule

---

## Support and Maintenance

### Automated Health Checks

Create scheduled task to run health check script:

```powershell
# Check-SplunkForwarderHealth.ps1
$Service = Get-Service "SplunkForwarder" -ErrorAction SilentlyContinue

if ($Service.Status -ne "Running") {
    Start-Service SplunkForwarder
    # Send alert to monitoring system
}
```

### Upgrade Strategy

When new forwarder version is released:
1. Update deployment server with new apps
2. Let forwarders auto-update via deployment server
3. Or: Redeploy using same method with new MSI

---

## Quick Reference

| Deployment Method | Setup Time | Best For | Machines | Automation |
|-------------------|------------|----------|----------|------------|
| CSV + PowerShell | 30 min | Immediate deployment | 10-1000+ | High |
| GPO | 1-2 hours | Domain environment | 100-10000+ | High |
| SCCM | 2-4 hours | Enterprise, compliance | 1000-100000+ | Very High |
| Intune | 1-2 hours | Cloud/hybrid/remote | 100-10000+ | High |
| PDQ Deploy | 30 min | SMB, GUI preference | 10-5000 | Medium |

---

**Created for**: Large-scale Windows Universal Forwarder deployments
**Last Updated**: November 2024
