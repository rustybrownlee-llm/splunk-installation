<#
.SYNOPSIS
    Installs Splunk Universal Forwarder on Windows systems

.DESCRIPTION
    This script installs the Splunk Universal Forwarder and configures it
    to connect to a deployment server using settings from config.ps1

.EXAMPLE
    .\Install-SplunkForwarder.ps1

.NOTES
    Author: Splunk Admin
    Requires: Administrator privileges
    Configuration: Edit config.ps1 before running this script
#>

[CmdletBinding()]
param()

# Requires Administrator
#Requires -RunAsAdministrator

# Load configuration
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptRoot "config.ps1"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Configuration file not found: $ConfigPath" -ForegroundColor Red
    Write-Host "Please create config.ps1 from the template" -ForegroundColor Yellow
    exit 1
}

Write-Host "[INFO] Loading configuration from config.ps1..." -ForegroundColor Green
. $ConfigPath

# Installer configuration
$SplunkVersion = "9.3.2"  # Using 9.3.2 as 10.0.1 is not available for Windows forwarder
$SplunkBuild = "d8bb32809498"
$InstallerFilename = "splunkforwarder-$SplunkVersion-$SplunkBuild-x64-release.msi"
$ProjectRoot = Split-Path -Parent $ScriptRoot
$ProjectInstallerPath = Join-Path $ProjectRoot "downloads\$InstallerFilename"
$InstallerPath = "$env:TEMP\splunkforwarder.msi"
$LogPath = "$env:TEMP\splunk_install.log"

# Use config values
$DeploymentServer = $Script:DeploymentServerAddress
$DeploymentPort = $Script:DeploymentServerPort
$InstallPath = $Script:InstallPath
$AdminPassword = ConvertTo-SecureString $Script:SplunkAdminPassword -AsPlainText -Force

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
    return Test-Path "$InstallPath\bin\splunk.exe"
}

function Get-SplunkService {
    return Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
}

# Main installation process
try {
    Write-ColorOutput "Starting Splunk Universal Forwarder installation..." "INFO"
    Write-ColorOutput "Version: $SplunkVersion Build: $SplunkBuild" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Configuration:" "INFO"
    Write-ColorOutput "  Deployment Server: ${DeploymentServer}:${DeploymentPort}" "INFO"
    Write-ColorOutput "  Install Path:      $InstallPath" "INFO"

    # Check if already installed
    if (Test-SplunkInstalled) {
        Write-ColorOutput "Splunk Universal Forwarder is already installed at: $InstallPath" "WARN"
        $response = Read-Host "Do you want to reinstall? (y/n)"
        if ($response -ne 'y') {
            Write-ColorOutput "Installation cancelled" "INFO"
            exit 0
        }
    }

    # Check for installer in project downloads folder first
    if (Test-Path $ProjectInstallerPath) {
        Write-ColorOutput "Found installer in project downloads folder" "INFO"
        Write-ColorOutput "Source: $ProjectInstallerPath" "INFO"
        Copy-Item -Path $ProjectInstallerPath -Destination $InstallerPath -Force
        Write-ColorOutput "Copied to: $InstallerPath" "INFO"
    }
    else {
        Write-ColorOutput "Installer not found in downloads folder" "ERROR"
        Write-ColorOutput "Expected location: $ProjectInstallerPath" "ERROR"
        Write-ColorOutput "" "INFO"
        Write-ColorOutput "Please download the installer manually:" "WARN"
        Write-ColorOutput "  1. Go to: https://www.splunk.com/en_us/download/universal-forwarder.html" "INFO"
        Write-ColorOutput "  2. Download: $InstallerFilename" "INFO"
        Write-ColorOutput "  3. Save to: $ProjectInstallerPath" "INFO"
        throw "Installer not found"
    }

    # Verify installer exists
    if (-not (Test-Path $InstallerPath)) {
        throw "Installer file not found: $InstallerPath"
    }

    # Convert SecureString password to plain text for installation
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Prepare installation arguments
    $msiArgs = @(
        "/i"
        "`"$InstallerPath`""
        "AGREETOLICENSE=Yes"
        "SPLUNKPASSWORD=`"$PlainPassword`""
        "DEPLOYMENT_SERVER=`"${DeploymentServer}:${DeploymentPort}`""
        "LAUNCHSPLUNK=1"
        "SERVICESTARTTYPE=auto"
        "/quiet"
        "/norestart"
        "/L*V"
        "`"$LogPath`""
    )

    # Install Splunk
    Write-ColorOutput "Installing Splunk Universal Forwarder..." "INFO"
    Write-ColorOutput "This may take several minutes..." "INFO"

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

    # Clear password from memory
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    Remove-Variable PlainPassword

    # Check installation result
    if ($process.ExitCode -eq 0) {
        Write-ColorOutput "Installation completed successfully" "INFO"
    }
    elseif ($process.ExitCode -eq 3010) {
        Write-ColorOutput "Installation completed (reboot required)" "WARN"
    }
    else {
        throw "Installation failed with exit code: $($process.ExitCode). Check log: $LogPath"
    }

    # Wait for service to be available
    Write-ColorOutput "Waiting for Splunk service to initialize..." "INFO"
    Start-Sleep -Seconds 10

    # Verify service
    $service = Get-SplunkService
    if ($service) {
        Write-ColorOutput "Splunk service status: $($service.Status)" "INFO"

        if ($service.Status -ne 'Running') {
            Write-ColorOutput "Starting Splunk service..." "INFO"
            Start-Service -Name "SplunkForwarder"
            Start-Sleep -Seconds 5
        }
    }
    else {
        Write-ColorOutput "Splunk service not found" "WARN"
    }

    # Configure Windows Firewall
    Write-ColorOutput "Configuring Windows Firewall..." "INFO"

    $firewallRules = @(
        @{Name="Splunk Management Port"; Port=8089}
    )

    foreach ($rule in $firewallRules) {
        $existingRule = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
        if ($existingRule) {
            Write-ColorOutput "Firewall rule '$($rule.Name)' already exists" "INFO"
        }
        else {
            New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol TCP -LocalPort $rule.Port -Action Allow | Out-Null
            Write-ColorOutput "Created firewall rule: $($rule.Name) (Port $($rule.Port))" "INFO"
        }
    }

    # Set hostname recommendation
    Write-ColorOutput "Checking hostname for deployment server recognition..." "INFO"
    $currentHostname = $env:COMPUTERNAME

    if ($currentHostname -notmatch '(windows|win)') {
        Write-ColorOutput "Note: For automatic app deployment, consider renaming computer to include '-windows-' or '-win-'" "WARN"
        Write-ColorOutput "      Example: SERVER-windows-01 or DC-win-primary" "INFO"
    }
    else {
        Write-ColorOutput "Hostname contains 'windows' or 'win' - deployment server will recognize this client" "INFO"
    }

    # Clean up installer
    Write-ColorOutput "Cleaning up installer file..." "INFO"
    Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue

    # Display summary
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "============================================" "INFO"
    Write-ColorOutput "Installation Complete!" "INFO"
    Write-ColorOutput "============================================" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Installation Details:" "INFO"
    Write-ColorOutput "  Path:              $InstallPath" "INFO"
    Write-ColorOutput "  Deployment Server: ${DeploymentServer}:${DeploymentPort}" "INFO"
    Write-ColorOutput "  Service Status:    $((Get-SplunkService).Status)" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Installation log: $LogPath" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Next Steps:" "INFO"
    Write-ColorOutput "  1. Verify deployment server connection in Splunk Web" "INFO"
    Write-ColorOutput "  2. Run: .\Configure-SplunkForwarder.ps1 (if needed)" "INFO"
    Write-ColorOutput "  3. Check forwarder appears in deployment server clients list" "INFO"
    Write-ColorOutput "" "INFO"
    Write-ColorOutput "Useful Commands:" "INFO"
    Write-ColorOutput "  Check service: Get-Service SplunkForwarder" "INFO"
    Write-ColorOutput "  View logs:     Get-Content '$InstallPath\var\log\splunk\splunkd.log' -Tail 50" "INFO"
    Write-ColorOutput "  Restart:       Restart-Service SplunkForwarder" "INFO"
    Write-ColorOutput "" "INFO"

}
catch {
    Write-ColorOutput "Installation failed: $_" "ERROR"
    Write-ColorOutput "Check the installation log at: $LogPath" "ERROR"
    exit 1
}
