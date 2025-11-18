# HAP Frozen Archive Setup - Server 1

Configuration for Server 1 to receive and store frozen buckets from Server 2.

## Purpose

Server 2 (indexer) automatically rolls aged data to "frozen" state and archives it to Server 1 for long-term compliance storage.

## Architecture

```
Server 2 (Indexer)                    Server 1 (Search Head)
┌───────────────────┐                 ┌────────────────────┐
│ Hot → Warm → Cold │──Frozen──────►  │ C:\splunk-frozen\  │
│                   │   Buckets       │   \wineventlog\    │
│ Retention: 90 days│   via SMB       │   \network\        │
│                   │                 │   \firewall\       │
└───────────────────┘                 │   ... (all indexes)│
                                      └────────────────────┘
```

## Setup Steps

### 1. Create Frozen Archive Directory on Server 1

```powershell
# Open PowerShell as Administrator on Server 1

# Create main frozen archive directory
New-Item -Path "C:\splunk-frozen" -ItemType Directory -Force

# Create subdirectories for each index (optional, auto-created)
$indexes = @('wineventlog','perfmon','network','firewall','dns','web','proxy','security','endpoint','application','database','email','cybervision')
foreach ($index in $indexes) {
    New-Item -Path "C:\splunk-frozen\$index\frozen" -ItemType Directory -Force
}
```

### 2. Create SMB Share

```powershell
# Share the frozen archive directory
New-SmbShare -Name "splunk-frozen" `
             -Path "C:\splunk-frozen" `
             -FullAccess "Everyone" `
             -Description "Splunk Frozen Bucket Archive"

# Verify share was created
Get-SmbShare -Name "splunk-frozen"
```

### 3. Set NTFS Permissions

```powershell
# Get the Splunk service account name
# Default: NT SERVICE\splunkd on Server 2
# Or use domain account if Splunk runs under domain service account

# Set permissions for local service account (if Server 2 uses local account)
$acl = Get-Acl "C:\splunk-frozen"
$permission = "NT AUTHORITY\NETWORK SERVICE","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\splunk-frozen" $acl

# OR if using domain service account (replace DOMAIN\splunkuser):
$acl = Get-Acl "C:\splunk-frozen"
$permission = "DOMAIN\splunkuser","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\splunk-frozen" $acl
```

### 4. Test SMB Access from Server 2

From Server 2, test the share:

```powershell
# Test network connectivity
Test-NetConnection -ComputerName SERVER1 -Port 445

# Test SMB share access
Test-Path "\\SERVER1\splunk-frozen"

# Try to create a test file
"test" | Out-File "\\SERVER1\splunk-frozen\test.txt"
Remove-Item "\\SERVER1\splunk-frozen\test.txt"
```

### 5. Configure Firewall on Server 1

```powershell
# Allow SMB traffic from Server 2
New-NetFirewallRule -DisplayName "SMB for Splunk Frozen Archive" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 445 `
                    -Action Allow `
                    -RemoteAddress SERVER2_IP

# Or allow from entire subnet
New-NetFirewallRule -DisplayName "SMB for Splunk Frozen Archive" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 445 `
                    -Action Allow `
                    -RemoteAddress 192.168.1.0/24
```

## Server 2 Configuration

The indexer (Server 2) is already configured via `hap_add-on_es_indexes` with:

```ini
[default]
coldToFrozenDir = \\SERVER1\splunk-frozen\$_index_name\frozen
```

**Important:** Update `SERVER1` with actual hostname or IP in the indexes.conf file.

## Verification

### Check Frozen Bucket Transfer

On Server 2, verify frozen rollover is configured:

```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk btool indexes list --debug | Select-String "coldToFrozenDir"
```

Should show:
```
coldToFrozenDir = \\SERVER1\splunk-frozen\$_index_name\frozen
```

### Monitor for Frozen Buckets

On Server 1, watch for incoming frozen buckets:

```powershell
# List frozen buckets by index
Get-ChildItem "C:\splunk-frozen" -Recurse -Directory |
    Where-Object { $_.Name -like "db_*" } |
    Group-Object { $_.Parent.Parent.Name } |
    Select-Object Name, Count
```

### Check Archive Size

```powershell
# Get total size of frozen archive
$size = (Get-ChildItem "C:\splunk-frozen" -Recurse -File |
         Measure-Object -Property Length -Sum).Sum
$sizeGB = [math]::Round($size / 1GB, 2)
Write-Host "Frozen archive size: $sizeGB GB"

# Size by index
Get-ChildItem "C:\splunk-frozen" -Directory | ForEach-Object {
    $indexSize = (Get-ChildItem $_.FullName -Recurse -File |
                  Measure-Object -Property Length -Sum).Sum / 1GB
    [PSCustomObject]@{
        Index = $_.Name
        SizeGB = [math]::Round($indexSize, 2)
    }
} | Sort-Object SizeGB -Descending
```

## Automated Monitoring Script

Create `C:\Scripts\Monitor-FrozenArchive.ps1`:

```powershell
# Monitor Frozen Archive Growth
$archivePath = "C:\splunk-frozen"
$logPath = "C:\Logs\frozen-archive.log"

$size = (Get-ChildItem $archivePath -Recurse -File |
         Measure-Object -Property Length -Sum).Sum / 1GB
$count = (Get-ChildItem $archivePath -Recurse -Directory |
          Where-Object { $_.Name -like "db_*" }).Count

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "$timestamp - Size: $([math]::Round($size, 2)) GB - Buckets: $count"

Add-Content -Path $logPath -Value $logEntry

# Alert if > 500GB
if ($size -gt 500) {
    Write-Warning "Frozen archive exceeds 500GB!"
    # Add email alert here if needed
}
```

Schedule this script to run daily via Task Scheduler.

## Retention Management

Frozen buckets are stored indefinitely by default. To manage retention:

### Option 1: Manual Cleanup

Periodically delete old frozen buckets:

```powershell
# Delete frozen buckets older than 2 years
$cutoffDate = (Get-Date).AddYears(-2)
Get-ChildItem "C:\splunk-frozen" -Recurse -Directory |
    Where-Object { $_.Name -like "db_*" -and $_.CreationTime -lt $cutoffDate } |
    Remove-Item -Recurse -Force
```

### Option 2: Scheduled Task

Create a scheduled task to auto-delete frozen buckets after X years.

## Disaster Recovery

Frozen archive serves as offline backup:

1. **Backup the archive**: Use Windows Backup or enterprise backup solution
2. **Restore if needed**: Frozen buckets can be "thawed" back into Splunk

### To Thaw Frozen Buckets:

```powershell
# Move frozen bucket to thaweddb directory on indexer
# Then run rebuild command
cd "C:\Program Files\Splunk\bin"
.\splunk rebuild C:\Program Files\Splunk\var\lib\splunk\wineventlog\thaweddb\[bucket_name]
```

## Troubleshooting

### Server 2 Can't Write to Share

**Check permissions**:
```powershell
# On Server 1
Get-SmbShareAccess -Name "splunk-frozen"
Get-Acl "C:\splunk-frozen" | Format-List
```

**Check service account**:
```powershell
# On Server 2 - verify what account Splunk runs as
Get-Service splunkd | Select-Object Name, StartType, Status, StartName
```

### Disk Space Issues

**Monitor disk usage**:
```powershell
Get-Volume | Where-Object { $_.DriveLetter -eq 'C' }
```

**Set quota alert** at 80% full.

### Network Path Not Found

**Test SMB**:
```powershell
# From Server 2
Test-Path "\\SERVER1\splunk-frozen"
Get-SmbConnection
```

**Check firewall**:
```powershell
# On Server 1
Get-NetFirewallRule | Where-Object { $_.LocalPort -eq 445 }
```

## Security Considerations

1. **Use dedicated service account** for Splunk (not NETWORK SERVICE)
2. **Restrict SMB share access** to only Server 2 IP
3. **Enable SMB signing** for integrity
4. **Encrypt frozen buckets** if storing sensitive data long-term
5. **Audit access** to frozen archive regularly

## Storage Sizing

Estimate frozen archive growth:

```
Daily ingestion: X GB/day
Retention before frozen: 90 days
Data in hot/warm/cold: X GB/day * 90 = Y GB

After 90 days, frozen bucket generation = X GB/day
Annual frozen growth = X GB/day * 365 = Z GB/year
```

Plan storage capacity accordingly.

## Related Documentation

- `hap_add-on_es_indexes/README.md` - Index definitions with frozen paths
- Splunk Docs: [Archive indexed data](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Configurefreezepaths)

---

**Last Updated:** 2024-11-17
