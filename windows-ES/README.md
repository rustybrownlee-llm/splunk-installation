# Windows Enterprise Security (ES) Deployment

Complete Splunk Enterprise Security deployment for Stratus ftServer environment with dedicated search head and indexer architecture.

## Architecture Overview

```
Server 1 (Stratus ftServer)           Server 2 (Stratus ftServer)
┌──────────────────────────┐          ┌──────────────────────────┐
│ ES Search Head           │          │ Dedicated Indexer        │
│ - Enterprise Security    │◄────────►│ - All data ingestion     │
│ - License Master         │ Dist.    │ - Data model accel.      │
│ - Deployment Server      │ Search   │ - Port 9997 receiving    │
│ - Frozen archive storage │          │ - Splunk_TA_ForIndexers  │
│                          │          │ - hap_add-on_es_indexes  │
└──────────────────────────┘          └──────────────────────────┘
              ▲                                  │
              │                                  │ Frozen buckets
              │                                  ▼
         Windows Endpoints           Frozen Archive Share on Server 1
```

### Design Rationale

**Server 1 - Dedicated ES Search Head:**
- Handles resource-intensive correlation searches and ES workload
- No indexing to preserve resources for ES processing
- Hosts deployment server for centralized forwarder management
- Provides frozen bucket storage for aged data compliance
- License master for environment

**Server 2 - Dedicated Indexer:**
- All data ingestion and storage (hot/warm/cold buckets)
- Data model acceleration for ES
- Receives data from forwarders on port 9997
- Rolls frozen buckets to Server 1 via SMB share

**Stratus Fault Tolerance:**
- Each server operates independently with built-in Stratus redundancy
- No Splunk clustering required (Stratus handles HA at hardware level)
- Simplified deployment and maintenance

## Directory Structure

```
windows-ES/
├── README.md                          # This file
├── IMPLEMENTATION-STATUS.md           # Detailed implementation tracking
│
├── custom-addons/                     # Install on Splunk servers
│   ├── hap_add-on_es_indexes/         # → Server 2 (Indexer)
│   ├── hap_add-on_es_indexes_searchhead/  # → Server 1 (Search Head)
│   ├── hap_add-on_distributed_search/ # → Server 1 (Search Head)
│   └── hap_add-on_frozen_archive/     # → Server 1 (Search Head)
│
├── deployment-apps/                   # Install on Server 1, deploy to forwarders
│   ├── hap_add-on_deployment/         # → ALL forwarders
│   ├── hap_add-on_outputs/            # → ALL forwarders
│   └── hap_add-on_windows_inputs/     # → Windows forwarders only
│
└── server-configs/                    # Server 1 configuration files
    ├── serverclass.conf               # Deployment server config
    ├── frozen-archive-setup/          # Frozen bucket storage setup
    └── README.md
```

## Custom Add-ons Created

All custom add-ons use the `hap_` prefix for easy identification.

### Server 2 (Indexer) Add-ons

**hap_add-on_es_indexes**
- Defines all 13 ES indexes with storage paths
- Configures frozen bucket rollover to Server 1
- Sets retention policies and size limits

### Server 1 (Search Head) Add-ons

**hap_add-on_es_indexes_searchhead**
- Index definitions WITHOUT storage paths
- Makes indexes visible in ES Web UI and search interface
- Critical for ES dashboard functionality

**hap_add-on_distributed_search**
- Configures distributed search to Server 2
- Alternative: Use CLI method (preferred)

**hap_add-on_frozen_archive**
- SMB share configuration for frozen bucket storage
- PowerShell monitoring and retention scripts

### Deployment Apps (For Forwarders)

**hap_add-on_deployment** → ALL forwarders
- Centralized deployment server configuration
- Allows moving deployment server without touching forwarders

**hap_add-on_outputs** → ALL forwarders
- Sends data to Server 2:9997
- Compression and connection timeout settings

**hap_add-on_windows_inputs** → Windows forwarders only
- Windows Event Log collection (Security, System, Application, etc.)
- Performance monitoring (CPU, Memory, Disk, Network)
- Sysmon operational logs
- DNS client logs

## ES Indexes Defined

| Index | Purpose | Estimated Daily Volume |
|-------|---------|------------------------|
| wineventlog | Windows event logs | 100-500 MB per endpoint |
| perfmon | Performance monitoring | 50-100 MB per endpoint |
| network | Network traffic, NetFlow | Varies by sources |
| firewall | Firewall logs | Varies by sources |
| dns | DNS query logs | 50-200 MB per endpoint |
| web | IIS, Apache logs | Varies by sources |
| proxy | Proxy server logs | Varies by sources |
| security | Security tools (EDR, IDS/IPS) | Varies by sources |
| endpoint | Sysmon, EDR telemetry | 500MB-2GB per endpoint |
| application | Application logs | Varies by sources |
| database | Database audit logs | Varies by sources |
| email | Email security logs | Varies by sources |
| cybervision | Cisco Cyber Vision ICS/OT | Varies by sources |

## Installation Quick Start

### Prerequisites

1. **Splunkbase Add-ons** (already downloaded to `../splunkbase/`):
   - ✓ Splunk Common Information Model (CIM) 6.2.0
   - ✓ Splunk Add-on for Microsoft Windows 9.0.1
   - ✓ Splunk Supporting Add-on for Active Directory 3.1.1 (ad-ldap_237.tgz)
   - ✓ Splunk Add-on for Sysmon 5.0.0
   - ✓ Splunk Add-on for Cisco ASA 6.0.0
   - ✓ Palo Alto Networks Add-ons

2. **Enterprise Security** (already downloaded to `../installers/`):
   - ✓ Splunk Enterprise Security 8.2.3 (splunk-enterprise-security_823.spl)
   - ✓ Splunk_TA_ForIndexers (included within the ES .spl file)

3. **Download from Splunkbase**:
   - Splunk Add-on for Microsoft DNS
   - Splunk Add-on for Microsoft DHCP
   - Splunk Add-on for Cisco Cyber Vision

### Server 2 (Indexer) Installation

```powershell
# 1. Install Splunk Enterprise 10.0.1 (MSI)
msiexec /i splunk-10.0.1-x64-release.msi

# 2. CRITICAL: Install Splunk_TA_ForIndexers FIRST (from ES package)
# Extract Splunk_TA_ForIndexers from splunk-enterprise-security_823.spl
# Method 1: Via Web UI (Settings → Apps → Install app from file)
# Method 2: Via CLI:
#   Rename .spl to .tar.gz, extract, find Splunk_TA_ForIndexers.spl inside
#   Install: .\splunk install app C:\path\to\Splunk_TA_ForIndexers.spl -auth admin:password

# 3. Install custom add-on
Copy-Item -Recurse "hap_add-on_es_indexes" "C:\Program Files\Splunk\etc\apps\"

# 4. Install Splunkbase add-ons
# - CIM
# - Windows TA
# - AD TA
# - Sysmon TA
# - Network TAs (Cisco, Palo Alto, DNS, DHCP)

# 5. Configure receiving port 9997
cd "C:\Program Files\Splunk\bin"
.\splunk enable listen 9997 -auth admin:password

# 6. Restart Splunk
.\splunk restart
```

### Server 1 (ES Search Head) Installation

```powershell
# 1. Install Splunk Enterprise 10.0.1 (MSI)
msiexec /i splunk-10.0.1-x64-release.msi

# 2. Install CIM add-on
# Via Web UI or extract to C:\Program Files\Splunk\etc\apps\

# 3. Install Enterprise Security 8.2.3
# Install splunk-enterprise-security_823.spl via Web UI or CLI:
# Web UI: Settings → Apps → Install app from file → Browse to .spl file
# CLI: .\splunk install app C:\path\to\splunk-enterprise-security_823.spl -auth admin:password
# Follow ES post-installation configuration wizard

# 4. Configure License Master
cd "C:\Program Files\Splunk\bin"
# Install license, configure as license master

# 5. Configure Deployment Server
Copy-Item "serverclass.conf" "C:\Program Files\Splunk\etc\system\local\"
.\splunk reload deploy-server -auth admin:password

# 6. Install custom add-ons
Copy-Item -Recurse "hap_add-on_es_indexes_searchhead" "C:\Program Files\Splunk\etc\apps\"
Copy-Item -Recurse "hap_add-on_frozen_archive" "C:\Program Files\Splunk\etc\apps\"

# 7. Install deployment apps
Copy-Item -Recurse "deployment-apps\hap_add-on_deployment" "C:\Program Files\Splunk\etc\deployment-apps\"
Copy-Item -Recurse "deployment-apps\hap_add-on_outputs" "C:\Program Files\Splunk\etc\deployment-apps\"
Copy-Item -Recurse "deployment-apps\hap_add-on_windows_inputs" "C:\Program Files\Splunk\etc\deployment-apps\"

# 8. Configure distributed search (CLI method preferred)
.\splunk add search-server SERVER2_HOSTNAME:8089 -auth admin:password -remoteUsername admin -remotePassword password

# 9. Restart Splunk
.\splunk restart

# 10. Complete ES setup wizard via Web UI
```

### Windows Forwarder Deployment

```powershell
# 1. Install Splunk Universal Forwarder (MSI)
msiexec /i splunkforwarder-10.0.1-x64-release.msi DEPLOYMENT_SERVER="SERVER1_HOSTNAME:8089"

# Apps auto-deploy from Server 1 deployment server:
# - hap_add-on_deployment (connects to deployment server)
# - hap_add-on_outputs (sends to Server 2:9997)
# - hap_add-on_windows_inputs (collects Windows logs and perfmon)

# 2. Optional: Install Sysmon for enhanced endpoint visibility
# Download from Microsoft Sysinternals
.\Sysmon64.exe -accepteula -i sysmonconfig.xml
```

## Configuration Customization

### Update Server Hostnames

**Before deployment**, update placeholders in these files:

1. **hap_add-on_es_indexes/default/indexes.conf**:
   ```ini
   coldToFrozenDir = \\SERVER1_HOSTNAME\splunk-frozen\$_index_name\frozen
   ```

2. **hap_add-on_deployment/default/deploymentclient.conf**:
   ```ini
   targetUri = SERVER1_HOSTNAME:8089
   ```

3. **hap_add-on_outputs/default/outputs.conf**:
   ```ini
   server = SERVER2_HOSTNAME:9997
   ```

### Tune for Environment

- **Index sizes**: Edit `maxTotalDataSizeMB` in indexes.conf
- **Retention**: Adjust `frozenTimePeriodInSecs` (default: 90 days)
- **Perfmon intervals**: Modify collection frequency in windows_inputs/inputs.conf
- **Event log filtering**: Add blacklists for noisy event IDs

## Verification Steps

### Verify Indexer (Server 2)

```powershell
# Check receiving is enabled
.\splunk list inputstatus -auth admin:password

# Verify indexes are created
.\splunk list index -auth admin:password

# Check for incoming data
# Via Web UI: Search → index=* earliest=-15m | stats count by index
```

### Verify Search Head (Server 1)

```powershell
# Check deployment server clients
.\splunk list deploy-clients -auth admin:password

# Verify distributed search peers
.\splunk list search-server -auth admin:password

# Check ES is installed
# Web UI → Apps → Enterprise Security should be available
```

### Verify Forwarders

```powershell
# On forwarder, check deployed apps
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk list app -auth admin:changeme

# Check outputs
.\splunk list forward-server -auth admin:changeme

# Verify inputs
.\splunk list inputstatus -auth admin:changeme
```

## Data Volume Planning

**Per Windows Endpoint (Daily):**
- Event Logs: 100-500 MB
- Perfmon: 50-100 MB
- Sysmon: 500MB-2GB (highly variable)
- **Total: ~1-3 GB per endpoint per day**

**For 100 endpoints**: 100-300 GB/day ingestion

**Storage Requirements:**
- **Server 2 (Hot/Warm/Cold)**: 30-90 days retention
  - 100 endpoints: 3-27 TB
- **Server 1 (Frozen)**: 90+ days compliance storage
  - 100 endpoints: 9+ TB

## Troubleshooting

### Forwarders Not Checking In

```powershell
# Check deployment client on forwarder
.\splunk list deploy-poll -auth admin:changeme

# Verify firewall allows 8089 to Server 1
Test-NetConnection -ComputerName SERVER1_HOSTNAME -Port 8089

# Check Server 1 deployment server status
.\splunk reload deploy-server -auth admin:password
```

### Data Not Flowing

```powershell
# Check forwarder outputs
.\splunk list forward-server -auth admin:changeme

# Verify Server 2 receiving
.\splunk list inputstatus -auth admin:password | Select-String "9997"

# Check forwarder queue
# Look for blocked queues in splunkd.log
```

### ES Dashboards Not Populating

- Verify data models are accelerating (Settings → Data models)
- Check index definitions on search head (Settings → Indexes)
- Verify distributed search is working (Settings → Distributed search)
- Confirm Splunk_TA_ForIndexers is installed on Server 2

## Related Documentation

- **IMPLEMENTATION-STATUS.md**: Detailed implementation tracking and status
- **custom-addons/**: README files for each add-on
- **deployment-apps/**: README files for forwarder apps
- **server-configs/**: Server configuration documentation
- **../splunkbase/**: Downloaded Splunkbase add-ons

## Support Resources

- **Splunk Enterprise Security Docs**: https://docs.splunk.com/Documentation/ES/latest
- **Distributed Deployment Guide**: https://docs.splunk.com/Documentation/Splunk/latest/Deploy
- **Deployment Server Docs**: https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver
- **Stratus ftServer Docs**: Contact Stratus Technologies for HA configuration

## Best Practices

1. **Install Splunk_TA_ForIndexers FIRST** on Server 2 before any other ES components
2. **Test on pilot group** before mass forwarder deployment
3. **Monitor forwarder queues** for data backlogs
4. **Deploy Sysmon** to critical servers and workstations for enhanced visibility
5. **Enable PowerShell logging** via Group Policy
6. **Tune Sysmon config** to balance visibility vs. volume
7. **Review ES correlation searches** and adjust to environment
8. **Schedule regular frozen bucket cleanup** on Server 1
9. **Monitor license usage** to stay within allocation
10. **Document custom correlation searches** and saved searches

---

**Created:** 2024-11-17
**Last Updated:** 2024-11-17
**Version:** 1.0
