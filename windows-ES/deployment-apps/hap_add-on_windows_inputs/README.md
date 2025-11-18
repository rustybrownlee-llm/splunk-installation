# HAP Windows Inputs Configuration

This app configures Windows Universal Forwarders to collect Windows Event Logs, Performance Monitoring data, and Sysmon telemetry.

## Purpose

Standardizes data collection across all Windows endpoints:
- Windows Event Logs (Security, System, Application, PowerShell, Firewall, Defender)
- Performance Monitoring (CPU, Memory, Disk, Network)
- Sysmon operational logs (if Sysmon is installed)
- DNS Client logs
- Optional: Active Directory, IIS logs

## Deployment Strategy

**Deployed via Deployment Server to Windows forwarders ONLY**

Server class configuration filters by OS:
```ini
[serverClass:WindowsForwarders]
whitelist.0 = *
machineTypesFilter = windows-x64, windows-intel

[serverClass:WindowsForwarders:app:hap_add-on_windows_inputs]
restartSplunkd = true
stateOnClient = enabled
```

## Installation Location

**Server 1 Deployment Server:**
```
C:\Program Files\Splunk\etc\deployment-apps\hap_add-on_windows_inputs\
```

**Windows Forwarders (auto-deployed):**
```
C:\Program Files\SplunkUniversalForwarder\etc\apps\hap_add-on_windows_inputs\
```

## Data Sources Collected

### Windows Event Logs → wineventlog index

| Event Log | Sourcetype | Description |
|-----------|------------|-------------|
| Security | WinEventLog:Security | Authentication, account changes, privilege use |
| System | WinEventLog:System | System events, services, drivers |
| Application | WinEventLog:Application | Application errors and warnings |
| PowerShell/Operational | WinEventLog:PowerShell | PowerShell script execution |
| Windows PowerShell | WinEventLog:WindowsPowerShell | Legacy PowerShell logging |
| Firewall | WinEventLog:Firewall | Windows Firewall events |
| Defender | WinEventLog:Defender | Windows Defender detections |
| TaskScheduler | WinEventLog:TaskScheduler | Scheduled task execution |
| Setup | WinEventLog:Setup | Windows Update events |

### Endpoint Security → endpoint index

| Event Log | Sourcetype | Description |
|-----------|------------|-------------|
| Sysmon | XmlWinEventLog:Microsoft-Windows-Sysmon/Operational | Process creation, network connections, file changes |
| Defender | WinEventLog:Defender | Antivirus detections |

### Performance Monitoring → perfmon index

| Counter Object | Metrics Collected | Interval |
|----------------|-------------------|----------|
| Processor | CPU usage, user time, privileged time | 60 sec |
| Memory | Available bytes, page faults, committed memory | 60 sec |
| LogicalDisk | Free space, disk queue, disk time | 60 sec |
| PhysicalDisk | Read/write latency, queue lengths | 60 sec |
| Network Interface | Bytes/packets sent/received, bandwidth | 60 sec |
| System | Processor queue, context switches | 60 sec |
| Process | Top CPU consumers, memory usage | 300 sec (5 min) |

### DNS Logs → dns index

| Event Log | Sourcetype | Description |
|-----------|------------|-------------|
| DNS-Client/Operational | WinEventLog:DNS-Client | DNS query logs |

## Prerequisites

### Enable PowerShell Logging (via Group Policy)

**Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell:**
- Enable "Turn on Module Logging"
- Enable "Turn on PowerShell Script Block Logging"
- Enable "Turn on PowerShell Transcription"

### Install Sysmon (Recommended for ES)

1. Download Sysmon: https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon

2. Install with SwiftOnSecurity config:
   ```powershell
   # Download config
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "C:\sysmonconfig.xml"

   # Install Sysmon
   .\Sysmon64.exe -accepteula -i C:\sysmonconfig.xml
   ```

3. Verify installation:
   ```powershell
   Get-Service Sysmon64
   Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10
   ```

### Enable DNS Client Logging

DNS client logging is enabled by default in Windows 10+. Verify:
```powershell
Get-WinEvent -LogName "Microsoft-Windows-DNS-Client/Operational" -MaxEvents 10
```

## Configuration Tuning

### Reduce Perfmon Collection Frequency

If performance counters create too much data, adjust intervals in `inputs.conf`:

```ini
# Reduce to 5-minute intervals
[perfmon://CPU]
interval = 300

[perfmon://Memory]
interval = 300
```

### Filter Noisy Event Logs

To exclude specific event IDs, add to `inputs.conf`:

```ini
[WinEventLog://Security]
blacklist = 4624,4625  # Exclude logon events (very chatty)
```

### Disable Sysmon if Not Installed

If Sysmon isn't deployed:

```ini
[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = true
```

Or remove the stanza entirely.

### Domain Controller-Specific Logs

For domain controllers, uncomment in `inputs.conf`:

```ini
[WinEventLog://Directory Service]
disabled = false
index = wineventlog
sourcetype = WinEventLog:DirectoryService
renderXml = true
```

### IIS Web Server Logs

For IIS servers, uncomment and update path:

```ini
[monitor://C:\inetpub\logs\LogFiles]
disabled = false
index = web
sourcetype = iis
recursive = true
followTail = 1
```

## Verification

### On Windows Forwarder

Check inputs are enabled:
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk list inputstatus -auth admin:changeme
```

Should show multiple `WinEventLog` and `perfmon` inputs.

### On ES Search Head (Server 1)

Verify data is flowing:

```spl
index=wineventlog earliest=-15m
| stats count by host, sourcetype
| sort - count
```

```spl
index=perfmon earliest=-15m
| stats count by host, object
```

```spl
index=endpoint sourcetype="XmlWinEventLog:Microsoft-Windows-Sysmon/Operational" earliest=-15m
| stats count by host, EventCode
```

### Check Data Model Acceleration

After 24 hours, verify ES data models are populating:

```spl
| datamodel Authentication search
| head 100
```

## Performance Impact

### Forwarder Resource Usage

Expected CPU/Memory impact per forwarder:
- **Minimal**: 2-5% CPU, 50-100MB RAM
- **With Sysmon**: 5-10% CPU, 100-200MB RAM
- **Network**: 1-5 Mbps depending on event volume

### Data Volume Estimates

Daily data volume per Windows endpoint:
- **Event Logs**: 100-500 MB/day
- **Perfmon**: 50-100 MB/day
- **Sysmon**: 500MB-2GB/day (varies widely)
- **Total**: ~1-3 GB/day per endpoint

**For 100 endpoints**: 100-300 GB/day ingestion

## Troubleshooting

### Event Logs Not Collecting

**Check Windows Event Log service:**
```powershell
Get-Service EventLog
```

**Check forwarder can access logs:**
```powershell
Get-WinEvent -LogName Security -MaxEvents 1
```

**Verify forwarder has permissions:**
Splunk forwarder service account needs "Read" access to event logs (granted by default for LocalSystem).

### Perfmon Counters Failing

**Check counter names:**
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk btool inputs list perfmon
```

**Verify counters exist:**
```powershell
Get-Counter -Counter "\Processor(_Total)\% Processor Time"
```

### Sysmon Events Not Appearing

**Verify Sysmon is running:**
```powershell
Get-Service Sysmon64
```

**Check Sysmon event log exists:**
```powershell
Get-WinEvent -ListLog "Microsoft-Windows-Sysmon/Operational"
```

**Test Sysmon logging:**
```powershell
# Create a test event
notepad.exe
# Should see EventCode 1 (Process Create) in Sysmon log
```

### High Forwarder CPU Usage

**Reduce Sysmon events:**
Tune Sysmon config to exclude noisy events (network connections to localhost, etc.)

**Reduce perfmon frequency:**
Increase intervals from 60 to 300 seconds

**Filter event logs:**
Add blacklists for chatty event IDs

## ES Integration

This app feeds data to ES data models:

| ES Data Model | Data Source | Sourcetype |
|---------------|-------------|------------|
| Authentication | Windows Security logs | WinEventLog:Security |
| Endpoint.Processes | Sysmon | XmlWinEventLog:Sysmon |
| Endpoint.Filesystem | Sysmon | XmlWinEventLog:Sysmon |
| Endpoint.Registry | Sysmon | XmlWinEventLog:Sysmon |
| Network_Traffic | Sysmon (EventCode 3) | XmlWinEventLog:Sysmon |
| Change | Windows System/Security | WinEventLog:System, WinEventLog:Security |

## Related Apps

- **Splunk Add-on for Microsoft Windows** (from Splunkbase) - Install on search head for field extractions
- **Splunk Add-on for Sysmon** (from Splunkbase) - Install on search head for Sysmon parsing
- **hap_add-on_outputs**: Where this data gets sent (Server 2:9997)
- **hap_add-on_deployment**: Deployment server connection

## Files in This App

```
hap_add-on_windows_inputs/
├── default/
│   ├── app.conf      # App metadata
│   └── inputs.conf   # Windows input definitions
├── metadata/
│   └── default.meta  # Permissions
└── README.md         # This file
```

## Best Practices

1. **Deploy Sysmon** to all critical servers and workstations
2. **Enable PowerShell logging** via Group Policy
3. **Monitor forwarder queues** for data backlogs
4. **Tune Sysmon config** to balance visibility vs. volume
5. **Filter noisy events** to reduce storage costs
6. **Test on pilot group** before mass deployment

---

**Last Updated:** 2024-11-17
