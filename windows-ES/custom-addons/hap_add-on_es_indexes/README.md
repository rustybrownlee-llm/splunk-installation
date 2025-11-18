# HAP Enterprise Security Index Definitions

This app defines custom indexes for the HAP Enterprise Security deployment.

## Installation Location

**Server 2 (Indexer)** - Install to `C:\Program Files\Splunk\etc\apps\`

## Purpose

Creates index definitions for:
- Windows Event Logs (wineventlog, perfmon)
- Network data (network, firewall, dns)
- Web traffic (web, proxy)
- Security data (security, endpoint)
- Applications (application, database, email)
- Industrial/IoT (cybervision)

## Configuration Required

### 1. Update Server 1 Hostname for Frozen Archive

Edit `default/indexes.conf` line 11:
```ini
coldToFrozenDir = \\SERVER1_HOSTNAME\splunk-frozen\$_index_name\frozen
```

Replace `SERVER1_HOSTNAME` with:
- Actual hostname of Server 1, OR
- IP address of Server 1

Example:
```ini
coldToFrozenDir = \\HAP-SPLUNK-01\splunk-frozen\$_index_name\frozen
# or
coldToFrozenDir = \\192.168.1.10\splunk-frozen\$_index_name\frozen
```

### 2. Create Frozen Archive Share on Server 1

On Server 1 (ES Search Head):
1. Create directory: `C:\splunk-frozen\`
2. Share as `splunk-frozen` with write permissions for Splunk service account
3. Grant NTFS permissions to Splunk service account

PowerShell example:
```powershell
# Create directory
New-Item -Path "C:\splunk-frozen" -ItemType Directory

# Share directory
New-SmbShare -Name "splunk-frozen" -Path "C:\splunk-frozen" -FullAccess "Everyone"

# Set NTFS permissions (replace DOMAIN\splunkuser with actual service account)
$acl = Get-Acl "C:\splunk-frozen"
$permission = "DOMAIN\splunkuser","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\splunk-frozen" $acl
```

## ES Auto-Created Indexes

Enterprise Security automatically creates these indexes (do not manually define):
- `notable` - Notable events from correlation searches
- `risk` - Risk scoring data
- `threat_activity` - Threat intelligence data
- `summary` - Accelerated data model summaries

## Retention Policy

Default retention: **90 days** (7776000 seconds)

Adjust `frozenTimePeriodInSecs` in `default/indexes.conf` for different retention:
- 30 days: 2592000
- 60 days: 5184000
- 90 days: 7776000
- 180 days: 15552000
- 1 year: 31536000

## Storage Sizing

Total allocated: ~1.1TB across all indexes

Adjust `maxTotalDataSizeMB` values based on:
- Data ingestion rates
- Available storage on Server 2
- Retention requirements

## Verification

After installation and Splunk restart:

```spl
| rest /services/data/indexes
| table title totalEventCount currentDBSizeMB maxTotalDataSizeMB
| where title!="_*" AND title!="history" AND title!="main"
```

## Related Apps

- **Splunk_TA_ForIndexers**: Install this BEFORE installing this app (comes with ES)
- **hap_add-on_frozen_archive**: Install on Server 1 to receive frozen buckets

## Notes

- Install AFTER Splunk_TA_ForIndexers
- Restart Splunk after installation
- Monitor frozen archive share connectivity
- Adjust sizes based on actual data volume after 30 days
