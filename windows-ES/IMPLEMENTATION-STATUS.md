# HAP Windows ES Implementation - Status

## Architecture

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

## Custom Add-ons Created (hap_ prefix)

### ✅ Custom Add-ons Completed

1. **hap_add-on_es_indexes** - ES index definitions for Server 2
   - Location: `windows-ES/custom-addons/hap_add-on_es_indexes/`
   - Install on: Server 2 (Indexer)
   - Purpose: Define all ES indexes with frozen rollover to Server 1
   - Indexes: wineventlog, perfmon, network, firewall, dns, web, proxy, security, endpoint, application, database, email, cybervision

2. **hap_add-on_es_indexes_searchhead** - ES index definitions for Server 1
   - Location: `windows-ES/custom-addons/hap_add-on_es_indexes_searchhead/`
   - Install on: Server 1 (Search Head)
   - Purpose: Make indexes visible in Web UI without storage paths
   - Note: Critical for ES dashboard and search functionality

3. **hap_add-on_distributed_search** - Distributed search config for Server 1
   - Location: `windows-ES/custom-addons/hap_add-on_distributed_search/`
   - Install on: Server 1 (Search Head)
   - Purpose: Configure Server 1 to search Server 2
   - Note: CLI method (`splunk add search-server`) is preferred

### ✅ Server Configurations Completed

4. **frozen-archive-setup** - Frozen bucket receiver for Server 1
   - Location: `windows-ES/server-configs/frozen-archive-setup/`
   - Install on: Server 1
   - Purpose: SMB share and PowerShell scripts for frozen bucket storage
   - Includes: Monitoring scripts, retention management

5. **serverclass.conf** - Deployment server configuration
   - Location: `windows-ES/server-configs/serverclass.conf`
   - Install on: Server 1 (C:\Program Files\Splunk\etc\system\local\)
   - Purpose: Control which apps deploy to which forwarders
   - Server Classes: AllForwarders, WindowsForwarders

### ✅ Deployment Apps Completed

6. **hap_add-on_deployment** - Deployment client config
   - Location: `windows-ES/deployment-apps/hap_add-on_deployment/`
   - Deploy to: ALL forwarders (via deployment server)
   - Purpose: Point forwarders to Server 1 deployment server
   - Benefit: Centralized deployment server configuration

7. **hap_add-on_outputs** - Forwarder outputs
   - Location: `windows-ES/deployment-apps/hap_add-on_outputs/`
   - Deploy to: ALL forwarders (via deployment server)
   - Purpose: Send data to Server 2:9997
   - Features: Compression enabled, connection timeouts configured

8. **hap_add-on_windows_inputs** - Windows event log collection
   - Location: `windows-ES/deployment-apps/hap_add-on_windows_inputs/`
   - Deploy to: Windows forwarders only (OS-filtered)
   - Purpose: Collect Windows events, Sysmon, perfmon
   - Collects: Security, System, Application, PowerShell, Defender, Firewall, Sysmon, Perfmon

9. **hap_add-on_cybervision_inputs** - Cisco Cyber Vision index routing
   - Location: `windows-ES/deployment-apps/hap_add-on_cybervision_inputs/`
   - Deploy to: Forwarders with Cyber Vision sensors (CyberVisionForwarders serverclass)
   - Purpose: Override default index, route to cybervision index
   - Requires: TA-cisco_cybervision installed first on forwarder

## Splunkbase Add-ons Required

### Critical (Get from Splunkbase)

- ✓ **Splunk Common Information Model (CIM)** 6.2.0 - Already in ../splunkbase/
- ✓ **Splunk Add-on for Microsoft Windows** 9.0.1 - Already in ../splunkbase/
- ✓ **Splunk Supporting Add-on for Active Directory** 3.1.1 - Already in ../splunkbase/ (ad-ldap_237.tgz)
- ✓ **Splunk Add-on for Sysmon** 5.0.0 - Already in ../splunkbase/
- ✓ **Splunk Enterprise Security (ES)** 8.2.3 - Already in ../installers/ (splunk-enterprise-security_823.spl)
- ✓ **Splunk_TA_ForIndexers** - Included with ES .spl file, install FIRST on Server 2
- ✓ **Splunk Add-on for Cisco Cyber Vision** 2.1.0 - Already in ../splunkbase/ (cisco-cyber-vision-splunk-add-on_210.tgz)
- ⏳ **Splunk Add-on for Microsoft DNS** - Download from Splunkbase
- ⏳ **Splunk Add-on for Microsoft DHCP** - Download from Splunkbase
- ⏳ **Splunk_SA_ExtremeSearch** - Optional, download from Splunkbase

### Network (Some already downloaded)

- ✓ **Splunk Add-on for Cisco ASA** 6.0.0 - Already in ../splunkbase/
- ✓ **Palo Alto Networks Add-ons** - Already in ../splunkbase/

### Optional Enhancements

- **ES Content Update (ESCU)** - Pre-built detection content
- **Threat intelligence feeds** - Anomali, MISP, etc.

## Installation Order - Server 2 (Indexer)

1. Install Splunk Enterprise 10.0.1 (MSI installer)
2. **Install Splunk_TA_ForIndexers** (extract from splunk-enterprise-security_823.spl) - CRITICAL FIRST STEP
3. Install hap_add-on_es_indexes
4. Install CIM add-on (splunk-common-information-model_620.tgz)
5. Install Windows TAs (Microsoft Windows, AD LDAP ad-ldap_237.tgz, Sysmon)
6. Install network TAs (Cisco ASA, Palo Alto)
7. Install Cisco Cyber Vision TA (cisco-cyber-vision-splunk-add-on_210.tgz)
8. Install DNS/DHCP TAs (if available)
9. Configure receiving (port 9997)
10. Restart Splunk

## Installation Order - Server 1 (ES Search Head)

1. Install Splunk Enterprise 10.0.1 (MSI installer)
2. Install CIM add-on (splunk-common-information-model_620.tgz)
3. **Install Enterprise Security 8.2.3** (splunk-enterprise-security_823.spl) - Manual process via Web UI or CLI
4. Configure License Master
5. Configure Deployment Server
6. Install hap_add-on_es_indexes_searchhead
7. Install hap_add-on_frozen_archive (if using frozen bucket storage)
8. Install hap_add-on_distributed_search (or use CLI to add search peer - preferred)
9. Configure distributed search to Server 2
10. Restart Splunk
11. Complete ES setup wizard

## Implementation Guides Needed

- ⏳ **IMPLEMENTATION-SERVER1.md** - ES Search Head setup guide
- ⏳ **IMPLEMENTATION-SERVER2.md** - Indexer setup guide
- ⏳ **IMPLEMENTATION-FORWARDERS.md** - Windows forwarder deployment
- ⏳ **ES-INSTALLATION-GUIDE.md** - Enterprise Security specific steps
- ⏳ **VERIFICATION-CHECKLIST.md** - Post-install validation

## Configuration Templates Needed

- ⏳ Deployment server serverclass.conf
- ⏳ License configuration
- ⏳ ES asset/identity framework templates
- ⏳ Data model acceleration tuning

## Next Steps

1. ✅ ~~Complete remaining custom add-ons~~ - DONE
2. ⏳ Create implementation guides for both servers
3. ⏳ Document ES installation process
4. ⏳ Create verification checklists
5. ⏳ Download remaining Splunkbase add-ons

## Notes

- All custom add-ons use `hap_` prefix
- Server 2 must have Splunk_TA_ForIndexers installed BEFORE any other ES components
- ES installation is manual process (no scripting)
- Distributed search can be configured via CLI (preferred) or app
- Frozen archive requires SMB share on Server 1

---

**Created:** 2024-11-17
**Last Updated:** 2024-11-17
