# OCS Custom Add-ons Documentation

## Overview

OCS (Operational Control System) custom add-ons are purpose-built Splunk apps for standardized deployment and configuration management across your Splunk infrastructure.

### Philosophy: Default vs Local
All OCS add-ons use the **default directory pattern** for baseline configurations:
- **default/** - Contains baseline configurations deployed to all forwarders
- **local/** - Empty by default, allows per-forwarder customization without modifying the app
- This approach enables centralized management while allowing exceptions when needed

## OCS Add-ons

### 1. ocs_add-on_deployment
**Purpose**: Configures forwarders to connect to the deployment server

**Location**: `configs/deployment-apps/ocs_add-on_deployment/`

**What it does**:
- Establishes deployment client connection
- Enables centralized configuration management
- Allows automatic app deployment from deployment server

**Configuration Required**:
Edit `default/deploymentclient.conf` and set your deployment server IP:
```ini
[target-broker:deploymentServer]
targetUri = 192.168.1.10:8089
```

**Deployment Target**: All forwarders (Universal Forwarders and Heavy Forwarders)

---

### 2. ocs_add-on_outputs
**Purpose**: Configures where forwarders send collected data

**Location**: `configs/deployment-apps/ocs_add-on_outputs/`

**What it does**:
- Defines target indexer(s) for data forwarding
- Configures TCP output settings
- Enables compression and connection management

**Configuration Required**:
Edit `default/outputs.conf` and set your indexer IP:
```ini
[tcpout:primary_indexers]
server = 192.168.1.10:9997
```

**For Multiple Indexers** (load balancing):
```ini
[tcpout:primary_indexers]
server = 192.168.1.10:9997, 192.168.1.11:9997, 192.168.1.12:9997
autoLBFrequency = 30
```

**Deployment Target**: All forwarders

---

### 3. ocs_add-on_windows
**Purpose**: Collects Windows Event Logs (System, Security, Application)

**Location**: `configs/deployment-apps/ocs_add-on_windows/`

**What it does**:
- Collects Application Event Logs
- Collects Security Event Logs (authentication, auditing)
- Collects System Event Logs (hardware, services)
- Routes all events to `wineventlog` index

**Configuration Required**:
None - works out of the box after `wineventlog` index is created

**Prerequisites**:
- `wineventlog` index must exist on indexer (see Index Creation section)
- Splunk Add-on for Microsoft Windows installed on indexer/search head for CIM compliance

**Deployment Target**: Windows forwarders only

**Data Volume Expectations**:
- Workstation: 50-200 MB/day
- Server: 200-500 MB/day
- Domain Controller: 1-5 GB/day

---

## Installation Workflow

### Step 1: Prepare the Indexer

1. **Create required indexes** on your Splunk indexer:
```bash
sudo ./scripts/create-indexes.sh
```

This creates:
- `wineventlog` index (500GB max, 30-day retention)

2. **Install Splunk Add-on for Microsoft Windows** on indexer/search head:
   - Download from Splunkbase: `splunk-add-on-for-microsoft-windows_*.tgz`
   - Extract to `$SPLUNK_HOME/etc/apps/`
   - Restart Splunk

### Step 2: Configure OCS Add-ons

1. **Edit ocs_add-on_deployment**:
   - Navigate to `configs/deployment-apps/ocs_add-on_deployment/default/`
   - Edit `deploymentclient.conf`
   - Replace `DEPLOYMENT_SERVER_IP` with your deployment server's IP

2. **Edit ocs_add-on_outputs**:
   - Navigate to `configs/deployment-apps/ocs_add-on_outputs/default/`
   - Edit `outputs.conf`
   - Replace `INDEXER_IP` with your indexer's IP

3. **Verify ocs_add-on_windows**:
   - No changes needed if using `wineventlog` index
   - Review `configs/deployment-apps/ocs_add-on_windows/default/inputs.conf`

### Step 3: Deploy to Deployment Server

Copy OCS add-ons to your deployment server:

```bash
# If using SCP to remote deployment server
scp -r configs/deployment-apps/ocs_* user@deployment-server:/opt/splunk/etc/deployment-apps/

# If deployment server is local
sudo cp -r configs/deployment-apps/ocs_* /opt/splunk/etc/deployment-apps/
sudo chown -R splunk:splunk /opt/splunk/etc/deployment-apps/ocs_*
```

### Step 4: Configure Server Classes

On the deployment server, edit `/opt/splunk/etc/system/local/serverclass.conf`:

```ini
# All Windows forwarders
[serverClass:windows_forwarders]
whitelist.0 = *

[serverClass:windows_forwarders:app:ocs_add-on_deployment]
restartSplunkd = true

[serverClass:windows_forwarders:app:ocs_add-on_outputs]
restartSplunkd = true

[serverClass:windows_forwarders:app:ocs_add-on_windows]
restartSplunkd = true
```

**For more granular control** (separate server classes):
```ini
# Deployment configuration - applies to ALL forwarders
[serverClass:all_forwarders]
whitelist.0 = *

[serverClass:all_forwarders:app:ocs_add-on_deployment]
restartSplunkd = true

[serverClass:all_forwarders:app:ocs_add-on_outputs]
restartSplunkd = true

# Windows-specific inputs - applies to Windows only
[serverClass:windows_only]
whitelist.0 = WIN-*
whitelist.1 = *-WINDOWS-*

[serverClass:windows_only:app:ocs_add-on_windows]
restartSplunkd = true
```

### Step 5: Reload Deployment Server

```bash
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:password
```

### Step 6: Verify Deployment

1. **Check deployment server**:
```bash
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:password
```

2. **On forwarder, check deployed apps**:
```powershell
# Windows
Get-ChildItem "C:\Program Files\SplunkUniversalForwarder\etc\apps" | Where-Object {$_.Name -like "ocs_*"}
```

3. **Search for data in Splunk Web**:
```
index=wineventlog
| stats count by host, source
```

---

## Per-Forwarder Customization

### Override Deployment Server (local/deploymentclient.conf)

On a specific forwarder that needs a different deployment server:

1. Create: `$SPLUNK_HOME/etc/apps/ocs_add-on_deployment/local/deploymentclient.conf`
2. Add:
```ini
[target-broker:deploymentServer]
targetUri = different-deployment-server:8089
```

### Override Indexer Target (local/outputs.conf)

On a specific forwarder that needs to send to a different indexer:

1. Create: `$SPLUNK_HOME/etc/apps/ocs_add-on_outputs/local/outputs.conf`
2. Add:
```ini
[tcpout:primary_indexers]
server = different-indexer:9997
```

### Disable Specific Event Logs (local/inputs.conf)

To disable Security logs on a specific forwarder:

1. Create: `$SPLUNK_HOME/etc/apps/ocs_add-on_windows/local/inputs.conf`
2. Add:
```ini
[WinEventLog://Security]
disabled = true
```

### Add Additional Event Logs (local/inputs.conf)

To collect PowerShell logs on specific forwarders:

1. Create: `$SPLUNK_HOME/etc/apps/ocs_add-on_windows/local/inputs.conf`
2. Add:
```ini
[WinEventLog://Microsoft-Windows-PowerShell/Operational]
disabled = false
index = wineventlog
renderXml = true

[WinEventLog://Windows PowerShell]
disabled = false
index = wineventlog
renderXml = true
```

---

## Troubleshooting

### Apps Not Deploying to Forwarders

**Check deployment server status**:
```bash
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients
```

**Check forwarder connection**:
On forwarder:
```powershell
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" list deploy-poll
```

**Common issues**:
- Forwarder can't reach deployment server (check firewall, port 8089)
- Server class doesn't match forwarder name
- Deployment server not reloaded after config changes

### No Data Appearing in wineventlog Index

**Verify index exists**:
```bash
sudo -u splunk /opt/splunk/bin/splunk list index wineventlog -auth admin:password
```

**Check forwarder inputs**:
On forwarder:
```powershell
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" list inputstatus
```

**Check forwarding**:
```powershell
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" list forward-server
```

**Check logs**:
```powershell
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" -Tail 50
```

### Permission Errors on Event Logs

**Symptom**: Event logs not collecting, permission denied errors

**Solution**: Ensure SplunkForwarder service runs as Local System:
```powershell
Get-Service SplunkForwarder | Select-Object Name, StartType, Status, StartName
# StartName should be "LocalSystem"
```

If not:
```powershell
Stop-Service SplunkForwarder
sc.exe config SplunkForwarder obj= LocalSystem
Start-Service SplunkForwarder
```

---

## Best Practices

### 1. Version Control
- Keep OCS add-ons in version control (Git)
- Increment version numbers in `app.conf` when making changes
- Document changes in app README files

### 2. Testing Before Wide Deployment
- Create a test server class with one forwarder
- Deploy changes to test forwarder first
- Verify data collection and functionality
- Then deploy to production server classes

### 3. Monitoring License Usage
Windows Event Logs can consume significant license:
```
index=_internal source=*license_usage.log type=Usage
| eval MB=b/1024/1024
| stats sum(MB) as MB by idx
| sort -MB
```

### 4. Index Sizing and Retention
Monitor index sizes and adjust as needed:
```bash
sudo -u splunk /opt/splunk/bin/splunk list index -auth admin:password
```

Adjust retention:
```bash
sudo -u splunk /opt/splunk/bin/splunk edit index wineventlog \
  -frozenTimePeriodInSecs 5184000 \
  -auth admin:password
# 5184000 seconds = 60 days
```

### 5. Regular Maintenance
- Review deployed apps: Settings → Forwarder Management → Apps
- Check forwarder health: Settings → Forwarder Management → Clients
- Monitor deployment server: `index=_internal sourcetype=splunkd component=DC:DeploymentClient`

---

## Extending OCS Add-ons

### Adding More Event Log Channels

Edit `ocs_add-on_windows/default/inputs.conf` and add:

```ini
[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = false
index = wineventlog
renderXml = true

[WinEventLog://Microsoft-Windows-TaskScheduler/Operational]
disabled = false
index = wineventlog
renderXml = true
```

Redeploy:
```bash
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server
```

### Creating ocs_add-on_linux

For Linux forwarders, create similar structure:

```bash
mkdir -p configs/deployment-apps/ocs_add-on_linux/{default,metadata}
```

Add to `default/inputs.conf`:
```ini
[monitor:///var/log/syslog]
disabled = false
index = linux
sourcetype = syslog

[monitor:///var/log/auth.log]
disabled = false
index = linux
sourcetype = linux_secure
```

---

## File Structure Reference

```
configs/deployment-apps/
├── ocs_add-on_deployment/
│   ├── default/
│   │   ├── app.conf              # App metadata
│   │   └── deploymentclient.conf # Deployment server connection
│   ├── metadata/
│   │   └── default.meta          # Permissions
│   └── README.md                 # App documentation
│
├── ocs_add-on_outputs/
│   ├── default/
│   │   ├── app.conf              # App metadata
│   │   └── outputs.conf          # Indexer forwarding config
│   ├── metadata/
│   │   └── default.meta          # Permissions
│   └── README.md                 # App documentation
│
└── ocs_add-on_windows/
    ├── default/
    │   ├── app.conf              # App metadata
    │   └── inputs.conf           # Windows Event Log collection
    ├── metadata/
    │   └── default.meta          # Permissions
    └── README.md                 # App documentation
```

---

## Related Scripts

- **scripts/create-indexes.sh** - Creates required indexes on indexer
- **scripts/configure-deployment-server.sh** - Initial deployment server setup
- **windows-forwarders/Install-SplunkForwarder.ps1** - Automated forwarder installation

---

## Additional Resources

- [Splunk Deployment Server Documentation](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver)
- [Creating Splunk Apps](https://dev.splunk.com/enterprise/docs/developapps/)
- [Windows Event Log Monitoring](https://docs.splunk.com/Documentation/Splunk/latest/Data/MonitorWindowseventlogdata)
- [Splunk Add-on for Microsoft Windows](https://splunkbase.splunk.com/app/742/)

---

**Last Updated**: November 2024
**Version**: 1.0.0
**Author**: OCS Admin
