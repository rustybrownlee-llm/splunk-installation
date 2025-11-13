<#
.SYNOPSIS
    Tests and verifies Splunk Universal Forwarder configuration

.DESCRIPTION
    This script performs comprehensive tests on the Splunk Universal Forwarder
    installation, configuration, and connectivity to the deployment server and indexer.

.PARAMETER SplunkIndexer
    The hostname or IP address of the Splunk indexer to test connectivity

.PARAMETER DeploymentServer
    The hostname or IP address of the deployment server to test connectivity

.EXAMPLE
    .\Test-SplunkForwarder.ps1 -SplunkIndexer "192.168.64.5" -DeploymentServer "192.168.64.5"

.NOTES
    Author: Splunk Admin
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SplunkIndexer,

    [Parameter(Mandatory=$false)]
    [string]$DeploymentServer
)

$SplunkHome = "C:\Program Files\SplunkUniversalForwarder"
$SplunkBin = "$SplunkHome\bin\splunk.exe"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )

    switch ($Type) {
        "INFO"    { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN"    { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[PASS] $Message" -ForegroundColor Cyan }
        "FAIL"    { Write-Host "[FAIL] $Message" -ForegroundColor Red }
        default   { Write-Host "$Message" }
    }
}

function Test-SplunkFile {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-ColorOutput "Found: $Path" "SUCCESS"
        return $true
    } else {
        Write-ColorOutput "Missing: $Path" "FAIL"
        return $false
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Splunk Universal Forwarder Diagnostic Test" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    Passed = 0
    Failed = 0
}

# Test 1: Installation
Write-ColorOutput "TEST 1: Checking Splunk Installation" "INFO"
if (Test-Path $SplunkHome) {
    Write-ColorOutput "Splunk Home exists: $SplunkHome" "SUCCESS"
    $testResults.Passed++
} else {
    Write-ColorOutput "Splunk Home not found: $SplunkHome" "FAIL"
    $testResults.Failed++
}

if (Test-Path $SplunkBin) {
    Write-ColorOutput "Splunk executable found: $SplunkBin" "SUCCESS"
    $testResults.Passed++
} else {
    Write-ColorOutput "Splunk executable not found: $SplunkBin" "FAIL"
    $testResults.Failed++
}
Write-Host ""

# Test 2: Service Status
Write-ColorOutput "TEST 2: Checking Splunk Service" "INFO"
$service = Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
if ($service) {
    Write-ColorOutput "Service found: SplunkForwarder" "SUCCESS"
    Write-ColorOutput "Service Status: $($service.Status)" "INFO"
    Write-ColorOutput "Startup Type: $($service.StartType)" "INFO"

    if ($service.Status -eq 'Running') {
        Write-ColorOutput "Service is running" "SUCCESS"
        $testResults.Passed++
    } else {
        Write-ColorOutput "Service is not running" "FAIL"
        $testResults.Failed++
    }
} else {
    Write-ColorOutput "SplunkForwarder service not found" "FAIL"
    $testResults.Failed++
}
Write-Host ""

# Test 3: Configuration Files
Write-ColorOutput "TEST 3: Checking Configuration Files" "INFO"
$configFiles = @(
    "$SplunkHome\etc\system\local\outputs.conf",
    "$SplunkHome\etc\system\local\inputs.conf",
    "$SplunkHome\etc\system\local\deploymentclient.conf",
    "$SplunkHome\etc\system\local\server.conf"
)

$configPassed = 0
foreach ($file in $configFiles) {
    if (Test-SplunkFile $file) {
        $configPassed++
    }
}
$testResults.Passed += $configPassed
$testResults.Failed += ($configFiles.Count - $configPassed)
Write-Host ""

# Test 4: Read Configuration
Write-ColorOutput "TEST 4: Reading Configuration Details" "INFO"

if (Test-Path "$SplunkHome\etc\system\local\outputs.conf") {
    $outputsContent = Get-Content "$SplunkHome\etc\system\local\outputs.conf" -Raw
    if ($outputsContent -match 'server\s*=\s*([^:]+):(\d+)') {
        Write-ColorOutput "Forwarding configured to: $($matches[1]):$($matches[2])" "INFO"
        if (-not $SplunkIndexer) {
            $SplunkIndexer = $matches[1]
        }
    }
}

if (Test-Path "$SplunkHome\etc\system\local\deploymentclient.conf") {
    $deployContent = Get-Content "$SplunkHome\etc\system\local\deploymentclient.conf" -Raw
    if ($deployContent -match 'targetUri\s*=\s*([^:]+):(\d+)') {
        Write-ColorOutput "Deployment server: $($matches[1]):$($matches[2])" "INFO"
        if (-not $DeploymentServer) {
            $DeploymentServer = $matches[1]
        }
    }
}
Write-Host ""

# Test 5: Network Connectivity
Write-ColorOutput "TEST 5: Testing Network Connectivity" "INFO"

if ($SplunkIndexer) {
    $indexerTest = Test-NetConnection -ComputerName $SplunkIndexer -Port 9997 -WarningAction SilentlyContinue
    if ($indexerTest.TcpTestSucceeded) {
        Write-ColorOutput "Connection to indexer $SplunkIndexer:9997 successful" "SUCCESS"
        $testResults.Passed++
    } else {
        Write-ColorOutput "Cannot connect to indexer $SplunkIndexer:9997" "FAIL"
        $testResults.Failed++
    }
} else {
    Write-ColorOutput "Indexer address not specified, skipping connectivity test" "WARN"
}

if ($DeploymentServer) {
    $deployTest = Test-NetConnection -ComputerName $DeploymentServer -Port 8089 -WarningAction SilentlyContinue
    if ($deployTest.TcpTestSucceeded) {
        Write-ColorOutput "Connection to deployment server $DeploymentServer:8089 successful" "SUCCESS"
        $testResults.Passed++
    } else {
        Write-ColorOutput "Cannot connect to deployment server $DeploymentServer:8089" "FAIL"
        $testResults.Failed++
    }
} else {
    Write-ColorOutput "Deployment server address not specified, skipping connectivity test" "WARN"
}
Write-Host ""

# Test 6: Log Files
Write-ColorOutput "TEST 6: Checking Log Files" "INFO"
$logFiles = @(
    "$SplunkHome\var\log\splunk\splunkd.log",
    "$SplunkHome\var\log\splunk\metrics.log"
)

$logsPassed = 0
foreach ($log in $logFiles) {
    if (Test-Path $log) {
        $logInfo = Get-Item $log
        Write-ColorOutput "Found: $($logInfo.Name) (Size: $([math]::Round($logInfo.Length/1KB, 2)) KB, Modified: $($logInfo.LastWriteTime))" "SUCCESS"
        $logsPassed++
    } else {
        Write-ColorOutput "Missing: $log" "FAIL"
    }
}
$testResults.Passed += $logsPassed
$testResults.Failed += ($logFiles.Count - $logsPassed)
Write-Host ""

# Test 7: Recent Errors in Logs
Write-ColorOutput "TEST 7: Checking for Recent Errors" "INFO"
if (Test-Path "$SplunkHome\var\log\splunk\splunkd.log") {
    $recentErrors = Select-String -Path "$SplunkHome\var\log\splunk\splunkd.log" -Pattern "ERROR" -SimpleMatch | Select-Object -Last 5

    if ($recentErrors) {
        Write-ColorOutput "Found $($recentErrors.Count) recent ERROR entries (showing last 5):" "WARN"
        $recentErrors | ForEach-Object {
            Write-Host "  $($_.Line)" -ForegroundColor Yellow
        }
    } else {
        Write-ColorOutput "No recent errors found in logs" "SUCCESS"
        $testResults.Passed++
    }
} else {
    Write-ColorOutput "Cannot check errors - log file not found" "WARN"
}
Write-Host ""

# Test 8: Firewall Rules
Write-ColorOutput "TEST 8: Checking Firewall Configuration" "INFO"
$firewallRules = Get-NetFirewallRule -DisplayName "*Splunk*" -ErrorAction SilentlyContinue

if ($firewallRules) {
    Write-ColorOutput "Found $($firewallRules.Count) Splunk firewall rule(s)" "SUCCESS"
    $firewallRules | ForEach-Object {
        Write-ColorOutput "  - $($_.DisplayName): $($_.Enabled)" "INFO"
    }
    $testResults.Passed++
} else {
    Write-ColorOutput "No Splunk firewall rules found" "WARN"
}
Write-Host ""

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-ColorOutput "Tests Passed: $($testResults.Passed)" "SUCCESS"
if ($testResults.Failed -gt 0) {
    Write-ColorOutput "Tests Failed: $($testResults.Failed)" "FAIL"
} else {
    Write-ColorOutput "Tests Failed: $($testResults.Failed)" "SUCCESS"
}
Write-Host ""

if ($testResults.Failed -eq 0) {
    Write-ColorOutput "All tests passed! Splunk Universal Forwarder appears to be configured correctly." "SUCCESS"
} else {
    Write-ColorOutput "Some tests failed. Please review the output above and address any issues." "WARN"
}

Write-Host ""
Write-Host "Additional diagnostic commands:" -ForegroundColor Cyan
Write-Host "  Get-Service SplunkForwarder | Select-Object *" -ForegroundColor Gray
Write-Host "  Get-Content '$SplunkHome\var\log\splunk\splunkd.log' -Tail 50" -ForegroundColor Gray
Write-Host "  Test-NetConnection -ComputerName <server> -Port 9997" -ForegroundColor Gray
Write-Host ""
