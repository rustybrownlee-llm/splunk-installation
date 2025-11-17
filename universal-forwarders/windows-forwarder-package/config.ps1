# Splunk Windows Forwarder Configuration
# Edit this file with your Splunk server details before running installation scripts

################################################################################
# SPLUNK SERVER CONFIGURATION
################################################################################

# Splunk Deployment Server IP or Hostname
# This is the Splunk Enterprise server that manages forwarder configurations
$Script:DeploymentServerAddress = "192.168.1.100"  # CHANGE THIS TO YOUR SPLUNK SERVER IP

# Splunk Indexer IP or Hostname
# This is where the forwarder sends data (usually the same as deployment server)
$Script:IndexerAddress = "192.168.1.100"  # CHANGE THIS TO YOUR SPLUNK SERVER IP

################################################################################
# PORT CONFIGURATION (Default values - usually no need to change)
################################################################################

# Deployment Server Port (default: 8089)
$Script:DeploymentServerPort = 8089

# Indexer Receiving Port (default: 9997)
$Script:IndexerPort = 9997

################################################################################
# AUTHENTICATION (Default password - should match Linux installation)
################################################################################

# Splunk Admin Password
# IMPORTANT: This is the default password set during installation
# Change this in Splunk Web after first login!
$Script:SplunkAdminPassword = "5plunk#1!"

################################################################################
# INSTALLATION PATHS (Default values - usually no need to change)
################################################################################

# Splunk Universal Forwarder Installation Path
$Script:InstallPath = "C:\Program Files\SplunkUniversalForwarder"

################################################################################
# DATA COLLECTION SETTINGS
################################################################################

# Enable Windows Event Log collection
$Script:EnableWindowsEventLogs = $true

# Enable Performance Monitor collection
$Script:EnablePerfmon = $true

# Windows Event Logs to collect (if enabled)
$Script:WindowsEventLogs = @(
    "Application",
    "Security",
    "System"
)

# Performance Monitor counters to collect (if enabled)
$Script:PerfmonCounters = @{
    "CPU" = @{
        Object = "Processor"
        Counters = "% Processor Time; % User Time; % Privileged Time"
        Instances = "_Total"
        Interval = 30
    }
    "Memory" = @{
        Object = "Memory"
        Counters = "Available Bytes; Pages/sec; % Committed Bytes In Use"
        Instances = "*"
        Interval = 30
    }
    "Disk" = @{
        Object = "LogicalDisk"
        Counters = "% Free Space; Free Megabytes; Current Disk Queue Length"
        Instances = "*"
        Interval = 30
    }
    "Network" = @{
        Object = "Network Interface"
        Counters = "Bytes Total/sec; Packets/sec"
        Instances = "*"
        Interval = 30
    }
}

################################################################################
# VERIFICATION
################################################################################

# Function to verify configuration
function Test-SplunkConfig {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Splunk Configuration Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Deployment Server: ${DeploymentServerAddress}:${DeploymentServerPort}" -ForegroundColor Yellow
    Write-Host "Indexer:           ${IndexerAddress}:${IndexerPort}" -ForegroundColor Yellow
    Write-Host "Install Path:      $InstallPath" -ForegroundColor Yellow
    Write-Host "Event Logs:        $(if($EnableWindowsEventLogs){'Enabled'}else{'Disabled'})" -ForegroundColor Yellow
    Write-Host "Perfmon:           $(if($EnablePerfmon){'Enabled'}else{'Disabled'})" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Test network connectivity
    Write-Host "Testing connectivity..." -ForegroundColor Green

    $deploymentTest = Test-NetConnection -ComputerName $DeploymentServerAddress -Port $DeploymentServerPort -WarningAction SilentlyContinue
    if ($deploymentTest.TcpTestSucceeded) {
        Write-Host "[OK] Can reach deployment server: ${DeploymentServerAddress}:${DeploymentServerPort}" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Cannot reach deployment server: ${DeploymentServerAddress}:${DeploymentServerPort}" -ForegroundColor Red
        Write-Host "       Check firewall and network connectivity" -ForegroundColor Yellow
    }

    $indexerTest = Test-NetConnection -ComputerName $IndexerAddress -Port $IndexerPort -WarningAction SilentlyContinue
    if ($indexerTest.TcpTestSucceeded) {
        Write-Host "[OK] Can reach indexer: ${IndexerAddress}:${IndexerPort}" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Cannot reach indexer: ${IndexerAddress}:${IndexerPort}" -ForegroundColor Red
        Write-Host "       Ensure Splunk receiving port is configured and firewall allows connection" -ForegroundColor Yellow
    }
    Write-Host ""
}

################################################################################
# DO NOT EDIT BELOW THIS LINE
################################################################################

# Configuration variables are automatically available when this script is dot-sourced
# Example: . .\config.ps1
