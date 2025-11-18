# HAP Cisco Cyber Vision Inputs Configuration

This app overrides the default index configuration for Cisco Cyber Vision data collection, routing all OT/ICS data to the dedicated `cybervision` index.

## Purpose

Centralizes index routing configuration for Cisco Cyber Vision deployments:
- Overrides TA-cisco_cybervision default index (default → cybervision)
- Routes all 6 Cyber Vision data types to the correct ES index
- Deployed via deployment server for centralized management
- Supports ICS/OT security monitoring in Enterprise Security

## Deployment Strategy

**Deployed via Deployment Server to CyberVisionForwarders serverclass**

Server class configuration targets forwarders with Cyber Vision sensors:
```ini
[serverClass:CyberVisionForwarders]
# Target forwarders with Cyber Vision sensors
whitelist.0 = CYBERVISION-*
# Or use naming convention for ICS/OT systems
whitelist.1 = ICS-*
whitelist.2 = OT-*

[serverClass:CyberVisionForwarders:app:hap_add-on_cybervision_inputs]
restartSplunkd = true
stateOnClient = enabled
```

## Installation Location

**Server 1 Deployment Server:**
```
C:\Program Files\Splunk\etc\deployment-apps\hap_add-on_cybervision_inputs\
```

**Forwarders (auto-deployed):**
```
C:\Program Files\SplunkUniversalForwarder\etc\apps\hap_add-on_cybervision_inputs\
```

## Data Types Routed to cybervision Index

| Input Type | Sourcetype | Description |
|------------|------------|-------------|
| cybervision_events | cisco:cybervision:events | Security events from OT environment |
| cybervision_devices | cisco:cybervision:devices | Asset inventory (PLCs, RTUs, HMIs, etc.) |
| cybervision_components | cisco:cybervision:components | Component-level device details |
| cybervision_flows | cisco:cybervision:flows | OT network flow data (protocols) |
| cybervision_activities | cisco:cybervision:activities | System activity and change logs |
| cybervision_vulnerabilities | cisco:cybervision:vulnerabilities | ICS/OT CVEs and vulnerabilities |

## Prerequisites

### 1. Cisco Cyber Vision Sensor Deployment
- Cisco Cyber Vision sensor must be deployed in the OT environment
- Sensor must be configured and operational
- API access must be enabled

### 2. TA-cisco_cybervision Installation on Forwarder
```powershell
# Install the Cisco Cyber Vision TA from Splunkbase
# Location: splunkbase/cisco-cyber-vision-splunk-add-on_210.tgz
# Install on the forwarder that will connect to Cyber Vision sensors

cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk install app C:\path\to\cisco-cyber-vision-splunk-add-on_210.tgz -auth admin:changeme
```

### 3. Configure Cyber Vision Connection
After installing TA-cisco_cybervision, configure sensor connection:
1. Web UI: http://forwarder:8089 → TA-cisco_cybervision → Configuration
2. Add Cyber Vision sensor connection details:
   - Sensor IP/hostname
   - API credentials
   - Collection interval (default: 60 seconds)

### 4. cybervision Index on Indexers
The cybervision index must exist on Server 2:
- Already defined in `hap_add-on_es_indexes`
- Install `hap_add-on_es_indexes` on Server 2 before deploying this app

## Configuration Details

### Index Overrides
This app overrides all 6 input stanzas from TA-cisco_cybervision:
```ini
[cybervision_events]
index = cybervision  # Overrides: index = default

[cybervision_devices]
index = cybervision  # Overrides: index = default

[cybervision_components]
index = cybervision  # Overrides: index = default

[cybervision_flows]
index = cybervision  # Overrides: index = default

[cybervision_activities]
index = cybervision  # Overrides: index = default

[cybervision_vulnerabilities]
index = cybervision  # Overrides: index = default
```

### Collection Intervals
Default collection settings from TA-cisco_cybervision:
- **Interval**: 60 seconds
- **Page Size**: 100 events per API call
- **Python Version**: Python 3

These settings are configured in TA-cisco_cybervision and not overridden by this app.

## Verification

### On Forwarder

Check that both apps are deployed:
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk list app -auth admin:changeme
# Should show:
# - TA-cisco_cybervision
# - hap_add-on_cybervision_inputs
```

Check input configuration:
```powershell
.\splunk btool inputs list cybervision --debug
# Should show index = cybervision for all inputs
```

Check inputs are running:
```powershell
.\splunk list inputstatus -auth admin:changeme | Select-String "cybervision"
```

### On ES Search Head (Server 1)

Verify data is flowing to cybervision index:
```spl
index=cybervision earliest=-15m
| stats count by sourcetype, source
| sort - count
```

Check for all 6 data types:
```spl
index=cybervision earliest=-1h
| stats count by sourcetype
| sort sourcetype
```

Expected sourcetypes:
- cisco:cybervision:activities
- cisco:cybervision:components
- cisco:cybervision:devices
- cisco:cybervision:events
- cisco:cybervision:flows
- cisco:cybervision:vulnerabilities

View recent OT assets discovered:
```spl
index=cybervision sourcetype="cisco:cybervision:devices" earliest=-1h
| stats values(ip) as ip_addresses values(deviceType) as device_type by label
| sort label
```

### Check Data Model Population

After 24 hours, verify ES data models are populating:
```spl
| datamodel Network_Traffic search
| search sourcetype="cisco:cybervision:flows"
| head 100
```

```spl
| datamodel Vulnerabilities search
| search sourcetype="cisco:cybervision:vulnerabilities"
| head 100
```

## Troubleshooting

### No Data Appearing in cybervision Index

**Check TA-cisco_cybervision is installed:**
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk list app -auth admin:changeme | Select-String "TA-cisco_cybervision"
```

**Check Cyber Vision sensor connection:**
```powershell
# Check TA-cisco_cybervision logs
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\ta_cisco_cybervision*.log" -Tail 50
```

**Verify index override is applied:**
```powershell
.\splunk btool inputs list cybervision_events --debug
# Should show: index = cybervision
# And the source should be from hap_add-on_cybervision_inputs
```

**Check for errors in splunkd.log:**
```powershell
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" | Select-String "cybervision" -Context 2
```

### Data Going to Wrong Index

If data appears in `index=default` instead of `index=cybervision`:

1. Verify this app is deployed and enabled
2. Check app precedence (this app must load after TA-cisco_cybervision)
3. Restart splunkd:
   ```powershell
   cd "C:\Program Files\SplunkUniversalForwarder\bin"
   .\splunk restart
   ```

### Cyber Vision API Connection Failures

**Check sensor connectivity:**
```powershell
# Test connection to Cyber Vision sensor
Test-NetConnection -ComputerName SENSOR_IP -Port 443
```

**Verify API credentials:**
- Check TA-cisco_cybervision configuration
- Ensure API user has read permissions
- Verify API token is not expired

**Check TA-cisco_cybervision logs:**
```powershell
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\ta_cisco_cybervision_cybervision_*.log" -Tail 100
```

## Data Volume Estimates

Typical daily data volume per Cyber Vision sensor:

| Data Type | Estimated Volume |
|-----------|------------------|
| Events | 100-500 MB/day |
| Devices | 10-50 MB/day |
| Components | 10-50 MB/day |
| Flows | 500MB-2GB/day |
| Activities | 50-200 MB/day |
| Vulnerabilities | 10-50 MB/day |
| **Total** | **~1-3 GB/day per sensor** |

**For multiple sensors**: Multiply by number of sensors

**Storage Requirements:**
- 90-day retention: ~90-270 GB per sensor
- Frozen storage: Additional space on Server 1 for compliance

## ES Integration

This app supports Enterprise Security OT Security use cases:

### ES Data Models Populated
- **Network Traffic**: OT protocol flows
- **Vulnerabilities**: ICS/OT CVEs
- **Change**: Asset configuration changes
- **Authentication**: OT system authentication (if available)

### ES Notable Events
Cyber Vision data feeds into:
- Asset and Identity correlation
- Vulnerability tracking
- OT network baseline
- Threat detection (OT-specific)

### Asset and Identity Framework
Update ES asset/identity lists with OT assets:
```spl
index=cybervision sourcetype="cisco:cybervision:devices"
| table ip, mac, label, deviceType, vendor, model
| outputlookup cybervision_assets.csv
```

## Related Apps

- **TA-cisco_cybervision** (from Splunkbase) - Core Cyber Vision integration
  - Must be installed FIRST on forwarders
  - Contains actual input modules and field extractions
  - This app only overrides index routing

- **hap_add-on_outputs**: Sends data to Server 2:9997
- **hap_add-on_deployment**: Deployment server connection
- **hap_add-on_es_indexes**: cybervision index definition

## Files in This App

```
hap_add-on_cybervision_inputs/
├── default/
│   ├── app.conf        # App metadata
│   └── inputs.conf     # Index overrides for all 6 Cyber Vision inputs
├── metadata/
│   └── default.meta    # Permissions
└── README.md           # This file
```

## Best Practices

1. **Install TA-cisco_cybervision first** before deploying this app
2. **Test with one sensor** before scaling to multiple sensors
3. **Monitor API rate limits** on Cyber Vision sensors
4. **Tune collection intervals** if data volume is too high
5. **Create OT asset lookups** for ES correlation
6. **Document sensor-to-forwarder mappings** for troubleshooting
7. **Set up alerts** for Cyber Vision API connection failures

## Security Considerations

- **API Credentials**: Store Cyber Vision API credentials securely
- **Network Segmentation**: Forwarders in OT zone may need firewall rules
- **Data Classification**: OT data may be more sensitive than IT data
- **Access Control**: Limit access to cybervision index to authorized users

## Support and Documentation

- **Cisco Cyber Vision Docs**: https://www.cisco.com/c/en/us/support/security/cyber-vision/tsd-products-support-series-home.html
- **TA-cisco_cybervision Docs**: See app README in Splunkbase package
- **ES OT Security**: https://docs.splunk.com/Documentation/ES/latest/User/OTsecurity

---

**Created:** 2024-11-17
**Last Updated:** 2024-11-17
**Version:** 1.0.0
