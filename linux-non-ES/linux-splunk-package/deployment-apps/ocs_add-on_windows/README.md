# OCS Add-on: Windows Event Log Collection

## Purpose
Collects Windows Event Logs from Universal Forwarders and sends them to the `wineventlog` index.

## What it does
- Collects Application Event Logs
- Collects Security Event Logs (includes authentication, auditing)
- Collects System Event Logs (includes system errors, hardware events)
- Sends all events in XML format for better parsing
- Routes all events to the `wineventlog` index

## Event Log Channels Collected

| Channel | Description | Common Use Cases |
|---------|-------------|------------------|
| Application | Application-specific events | Software errors, crashes, performance issues |
| Security | Security and audit events | Login attempts, privilege changes, object access |
| System | Windows system events | Service status, hardware issues, driver problems |

## Configuration

### Default Settings
All three event log channels are enabled by default and send to the `wineventlog` index.

### Disabling a Channel
To disable a specific channel on an individual forwarder, create `local/inputs.conf`:

```ini
[WinEventLog://Application]
disabled = true
```

### Adding Additional Channels
To collect additional Windows Event Log channels, create `local/inputs.conf`:

```ini
# PowerShell Operational Logs
[WinEventLog://Microsoft-Windows-PowerShell/Operational]
disabled = false
index = wineventlog
renderXml = true

# Sysmon Logs (requires Sysmon installed)
[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = false
index = wineventlog
renderXml = true
```

### Changing Target Index
To send logs to a different index, create `local/inputs.conf`:

```ini
[WinEventLog://Security]
index = security
```

## Prerequisites

### On the Indexer
The `wineventlog` index must be created on the indexer before deploying this app.

Run on the indexer:
```bash
sudo -u splunk /opt/splunk/bin/splunk add index wineventlog -auth admin:password
```

Or use the provided script: `scripts/create-indexes.sh`

### On the Forwarder
- Splunk Universal Forwarder must be installed
- Forwarder service must run with sufficient privileges to read event logs (default: Local System)

## Important Settings

### renderXml = true
This setting ensures event logs are collected in XML format, which provides:
- Better field extraction
- Complete event data
- CIM compliance when used with Splunk Add-on for Microsoft Windows

### start_from = oldest
First-time collection starts from the oldest available events. After initial collection, only new events are collected.

## Deployment
Deploy this app via the deployment server to all Windows forwarders.

## Data Volume Considerations
Windows Event Logs can generate significant data volume, especially Security logs on domain controllers or busy servers.

**Typical daily volumes:**
- Workstation: 50-200 MB/day
- Server: 200-500 MB/day
- Domain Controller: 1-5 GB/day

Monitor your license usage after deployment.

## Troubleshooting

### No events appearing in Splunk
1. Check forwarder is running: `Get-Service SplunkForwarder`
2. Verify inputs are enabled: Check `btool` output
3. Check forwarder logs: `$SPLUNK_HOME\var\log\splunk\splunkd.log`

### Permission errors
Ensure the SplunkForwarder service runs as Local System (default) or an account with:
- Read access to Event Logs
- Log on as a service right

### Testing
On the indexer, search for data:
```
index=wineventlog
| stats count by host, source
```

## Version
1.0.0

## Author
OCS Admin

## Related Apps
- **ocs_add-on_outputs**: Configures where to send collected data
- **ocs_add-on_deployment**: Connects forwarder to deployment server
- **Splunk Add-on for Microsoft Windows**: Provides CIM-compliant field extractions (install on indexer/search head)
