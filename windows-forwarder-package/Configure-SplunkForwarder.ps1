<#
.SYNOPSIS
    Manual configuration for Splunk Universal Forwarder

.DESCRIPTION
    This script allows manual configuration of the Splunk Universal Forwarder.
    NOTE: Most configuration is automatically pushed by the deployment server.
    Only use this script if you need to manually override deployment server configs
    or troubleshoot connectivity issues.

.EXAMPLE
    .\Configure-SplunkForwarder.ps1

.NOTES
    Author: Splunk Admin
    Requires: Administrator privileges, Splunk Universal Forwarder installed
    Configuration: Uses settings from config.ps1
#>

[CmdletBinding()]
param()

#Requires -RunAsAdministrator

# Load configuration
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptRoot "config.ps1"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Configuration file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

. $ConfigPath

# Configuration
$SplunkHome = $Script:InstallPath
$SplunkBin = "$SplunkHome\bin\splunk.exe"
$LocalConfigPath = "$SplunkHome\etc\system\local"

# Functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "INFO"    { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor Green }
        "WARN"    { Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
        default   { Write-Host "[$timestamp] $Message" }
    }
}

function Test-SplunkInstalled {
    return Test-Path $SplunkBin
}

# Main
try {
    Write-ColorOutput "Splunk Universal Forwarder Manual Configuration" "INFO"
    Write-ColorOutput "" "INFO"

    # Check if Splunk is installed
    if (-not (Test-SplunkInstalled)) {
        Write-ColorOutput "Splunk Universal Forwarder not found at: $SplunkHome" "ERROR"
        Write-ColorOutput "Please run Install-SplunkForwarder.ps1 first" "ERROR"
        exit 1
    }

    Write-ColorOutput "============================================" "WARN"
    Write-ColorOutput "IMPORTANT NOTE" "WARN"
    Write-ColorOutput "============================================" "WARN"
    Write-ColorOutput "" "WARN"
    Write-ColorOutput "The deployment server automatically pushes configurations to forwarders." "WARN"
    Write-ColorOutput "This includes:" "WARN"
    Write-ColorOutput "  - Windows Event Log collection" "WARN"
    Write-ColorOutput "  - Performance Monitor collection" "WARN"
    Write-ColorOutput "  - Data forwarding settings" "WARN"
    Write-ColorOutput "" "WARN"
    Write-ColorOutput "This manual configuration script is only needed if:" "WARN"
    Write-ColorOutput "  1. The deployment server is not working" "WARN"
    Write-ColorOutput "  2. You need custom local configuration" "WARN"
    Write-ColorOutput "  3. You are troubleshooting connectivity" "WARN"
    Write-ColorOutput "" "WARN"
    Write-ColorOutput "Do you want to continue with manual configuration? (y/n)" "WARN"

    $response = Read-Host
    if ($response -ne 'y') {
        Write-ColorOutput "Configuration cancelled" "INFO"
        Write-ColorOutput "" "INFO"
        Write-ColorOutput "To verify deployment server configuration:" "INFO"
        Write-ColorOutput "  1. Check deployment client status in Splunk Web" "INFO"
        Write-ColorOutput "  2. Look for deployed apps in: $SplunkHome\etc\apps\" "INFO"
        Write-ColorOutput "  3. Run: .\Test-SplunkForwarder.ps1" "INFO"
        exit 0
    }

    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Creating manual configuration files..." "INFO"

    # Ensure local config directory exists
    if (-not (Test-Path $LocalConfigPath)) {
        New-Item -ItemType Directory -Path $LocalConfigPath -Force | Out-Null
    }

    # Create outputs.conf (where to send data)
    Write-ColorOutput "Configuring outputs (data forwarding)..." "INFO"
    $outputsConf = @"
[tcpout]
defaultGroup = primary_indexers

[tcpout:primary_indexers]
server = $($Script:IndexerAddress):$($Script:IndexerPort)
compressed = true

[tcpout-server://$($Script:IndexerAddress):$($Script:IndexerPort)]
"@

    $outputsConf | Out-File -FilePath "$LocalConfigPath\outputs.conf" -Encoding ASCII
    Write-ColorOutput "  Created: outputs.conf" "INFO"

    # Create deploymentclient.conf
    Write-ColorOutput "Configuring deployment client..." "INFO"
    $deploymentConf = @"
[deployment-client]

[target-broker:deploymentServer]
targetUri = $($Script:DeploymentServerAddress):$($Script:DeploymentServerPort)
"@

    $deploymentConf | Out-File -FilePath "$LocalConfigPath\deploymentclient.conf" -Encoding ASCII
    Write-ColorOutput "  Created: deploymentclient.conf" "INFO"

    # Create inputs.conf (what data to collect)
    if ($Script:EnableWindowsEventLogs -or $Script:EnablePerfmon) {
        Write-ColorOutput "Configuring inputs (data collection)..." "INFO"
        $inputsConf = ""

        if ($Script:EnableWindowsEventLogs) {
            Write-ColorOutput "  Adding Windows Event Logs" "INFO"
            foreach ($log in $Script:WindowsEventLogs) {
                $inputsConf += @"
[WinEventLog://$log]
disabled = false
index = main
sourcetype = WinEventLog:$log

"@
            }
        }

        if ($Script:EnablePerfmon) {
            Write-ColorOutput "  Adding Performance Monitor counters" "INFO"
            foreach ($key in $Script:PerfmonCounters.Keys) {
                $counter = $Script:PerfmonCounters[$key]
                $inputsConf += @"
[perfmon://$key]
object = $($counter.Object)
counters = $($counter.Counters)
instances = $($counter.Instances)
interval = $($counter.Interval)
disabled = false
index = main

"@
            }
        }

        $inputsConf | Out-File -FilePath "$LocalConfigPath\inputs.conf" -Encoding ASCII
        Write-ColorOutput "  Created: inputs.conf" "INFO"
    }

    # Restart Splunk service to apply changes
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Restarting Splunk service to apply configuration..." "INFO"
    Restart-Service -Name "SplunkForwarder"
    Start-Sleep -Seconds 5

    $service = Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-ColorOutput "Splunk service restarted successfully" "INFO"
    } else {
        Write-ColorOutput "Splunk service may not have restarted properly" "WARN"
    }

    # Display summary
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "============================================" "INFO"
    Write-ColorOutput "Manual Configuration Complete!" "INFO"
    Write-ColorOutput "============================================" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Configuration Details:" "INFO"
    Write-ColorOutput "  Indexer:            $($Script:IndexerAddress):$($Script:IndexerPort)" "INFO"
    Write-ColorOutput "  Deployment Server:  $($Script:DeploymentServerAddress):$($Script:DeploymentServerPort)" "INFO"
    Write-ColorOutput "  Config Location:    $LocalConfigPath" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Configuration Files Created:" "INFO"
    Write-ColorOutput "  - outputs.conf (data forwarding)" "INFO"
    Write-ColorOutput "  - deploymentclient.conf (deployment server connection)" "INFO"
    if ($Script:EnableWindowsEventLogs -or $Script:EnablePerfmon) {
        Write-ColorOutput "  - inputs.conf (data collection)" "INFO"
    }
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Next Steps:" "INFO"
    Write-ColorOutput "  1. Run: .\Test-SplunkForwarder.ps1" "INFO"
    Write-ColorOutput "  2. Check Splunk Web for incoming data" "INFO"
    Write-ColorOutput "  3. Verify deployment server connection" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "NOTE: Deployment server apps may override these settings!" "WARN"
    Write-ColorOutput "" "INFO"

}
catch {
    Write-ColorOutput "Configuration failed: $_" "ERROR"
    exit 1
}
