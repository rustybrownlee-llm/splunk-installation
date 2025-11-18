# HAP Distributed Search Configuration

This app configures Server 1 (ES Search Head) to search Server 2 (Indexer) using distributed search.

## Installation Location

**Server 1 (ES Search Head only)** - Install to `C:\Program Files\Splunk\etc\apps\`

## Purpose

Enables the ES Search Head to:
- Query data stored on Server 2 (dedicated indexer)
- Execute searches across the remote indexer
- Aggregate results for ES correlation searches

## Configuration Required

### 1. Update Server Hostnames

Edit `default/distsearch.conf`:

**Line 29** - Replace `SERVER1` with Search Head hostname:
```ini
[searchhead:HAP-SPLUNK-01]
```

**Line 34** - Replace `SERVER2` with Indexer hostname/IP:
```ini
servers = HAP-SPLUNK-02:8089
# or
servers = 192.168.1.20:8089
```

### 2. Add Search Peer via CLI (Preferred Method)

Instead of using this app, you can add the search peer manually via CLI:

On Server 1 (ES Search Head):
```powershell
# Open PowerShell as Administrator
cd "C:\Program Files\Splunk\bin"

# Add Server 2 as search peer
.\splunk add search-server https://SERVER2:8089 -auth admin:password -remoteUsername admin -remotePassword password

# List search peers to verify
.\splunk list search-server -auth admin:password

# Reload distributed search
.\splunk reload search-head -auth admin:password
```

### 3. Add Search Peer via Web UI (Alternative)

1. Log into Server 1 Splunk Web (http://SERVER1:8000)
2. Go to **Settings → Distributed search → Search peers**
3. Click **New search peer**
4. Enter:
   - **Peer URI**: https://SERVER2:8089
   - **Remote username**: admin
   - **Remote password**: [admin password]
5. Click **Save**

## Verification

### Check Search Peer Status

On Server 1:
```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk list search-server -auth admin:password
```

Expected output:
```
https://SERVER2:8089
    status           : Up
    replication_port : 8080
```

### Test Distributed Search

Run this search on Server 1:
```spl
| rest /services/search/distributed/peers
| table title status version
```

Should show Server 2 with status="Up"

### Test Data Access

```spl
index=* earliest=-1h
| stats count by splunk_server
```

Should show data from both servers (if Server 1 has any local indexes).

## Troubleshooting

### Search Peer Shows "Down"

Check network connectivity from Server 1 to Server 2:
```powershell
Test-NetConnection -ComputerName SERVER2 -Port 8089
```

### Authentication Errors

Verify credentials:
```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk edit search-server https://SERVER2:8089 -auth admin:password -remoteUsername admin -remotePassword password
```

### Firewall Issues

Ensure port 8089 is open on Server 2:
- Windows Firewall exception for TCP 8089
- Allow inbound from Server 1 IP

### Bundle Replication Errors

If bundle replication fails, check disk space on both servers and network connectivity.

## Alternative: Manual Configuration File

If using this app instead of CLI:
1. Edit `default/distsearch.conf` with correct hostnames
2. Copy to `C:\Program Files\Splunk\etc\apps\`
3. Restart Splunk on Server 1
4. Verify with `splunk list search-server`

## Related Configuration

- **Server 2**: Must have Splunk management port (8089) accessible
- **Server 2**: No additional configuration needed (acts as search peer automatically)
- **ES App**: Will automatically use distributed search for correlation searches

## Notes

- Server 1 should NOT index data (search head only)
- All data ingestion goes to Server 2
- ES correlation searches will query Server 2 automatically
- Data model acceleration happens on Server 2
- Search bundles are replicated to Server 2 as needed

## Important: CLI Method Recommended

The **CLI method** (`splunk add search-server`) is preferred over using this app because:
- Encrypts credentials properly
- Validates connection immediately
- Stores configuration in `distsearch.conf` automatically
- Easier to troubleshoot

**Use this app only if:**
- CLI access is restricted
- Standardizing configuration across multiple environments
- Need to pre-configure before first startup
