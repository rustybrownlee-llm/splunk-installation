# CIM Add-on Local Configuration

## Purpose
This directory contains `local/datamodels.conf` to enable data model acceleration for the Splunk Common Information Model (CIM) add-on, required for InfoSec App dashboards.

## Installation

The `install-addons.sh` script automatically copies this file to the CIM add-on after extraction.

**Manual installation:**
```bash
# After CIM add-on is extracted to /opt/splunk/etc/apps/Splunk_SA_CIM/
sudo mkdir -p /opt/splunk/etc/apps/Splunk_SA_CIM/local
sudo cp cim-local-config/datamodels.conf /opt/splunk/etc/apps/Splunk_SA_CIM/local/
sudo chown splunk:splunk /opt/splunk/etc/apps/Splunk_SA_CIM/local/datamodels.conf
sudo -u splunk /opt/splunk/bin/splunk restart
```

## What Gets Accelerated

Based on InfoSec App dashboard analysis, these 8 data models are enabled for acceleration:

| Data Model | InfoSec App Usage |
|------------|-------------------|
| **Authentication** | Login analysis, access patterns, failed auth attempts |
| **Change_Analysis** | Account management, system changes |
| **Endpoint** | Processes, filesystem, registry, services, ports |
| **Intrusion_Detection** | IDS/IPS alerts, attack signatures |
| **Malware** | Antivirus events, malware detection |
| **Network_Sessions** | VPN connections, session analysis |
| **Network_Traffic** | Firewall logs, network flows |
| **Web** | Web proxy, URL filtering |

## Managing Acceleration via UI

After installation, you can manage acceleration using the CIM add-on UI:

1. **Settings → Data Models**
2. Click on a data model name
3. Click **Edit → Acceleration**
4. The checkboxes will show enabled/disabled based on `local/datamodels.conf`
5. Make changes via UI (they override the local config)

## Acceleration Settings

```ini
acceleration = true                    # Enable acceleration
acceleration.earliest_time = -1y      # Accelerate last 1 year of data
acceleration.max_time = 3600          # Max 1 hour per acceleration build
```

### Adjusting Time Range

Edit `datamodels.conf` and change `acceleration.earliest_time`:

- `-7d` = Last 7 days (minimal resources)
- `-30d` = Last 30 days (light usage)
- `-90d` = Last 90 days (moderate)
- `-1y` = Last 1 year (recommended for InfoSec App)
- `-2y` = Last 2 years (heavy resources)

## Checking Acceleration Status

### Via Splunk Web
**Settings → Data Models** → Click model → View "Acceleration Status"

### Via Search
```
| rest /services/admin/summarization by_tstats=1
| search title=DM_*
| eval size_mb=round(summary.size/1024/1024,2)
| table title, summary.complete, summary.latest_time, size_mb
| rename title as "Data Model", summary.complete as "Complete (%)", summary.latest_time as "Latest", size_mb as "Size (MB)"
```

### Monitor Build Progress
```
index=_internal sourcetype=scheduler savedsearch_name="DM_*"
| stats count by savedsearch_name, status
```

## Performance Considerations

### Resource Requirements

**Minimum (Lab):**
- 8GB RAM for Splunk
- 50GB disk for TSIDX files
- 4 CPU cores

**Recommended (Production):**
- 16GB+ RAM for Splunk
- 200GB+ disk for TSIDX files
- 8+ CPU cores
- SSD storage for TSIDX (optimal performance)

### Build Times

| Data Volume | Initial Build Time | Incremental Updates |
|-------------|-------------------|---------------------|
| 10GB/day | 1-2 hours | 5-10 minutes |
| 50GB/day | 4-8 hours | 15-30 minutes |
| 100GB/day | 8-16 hours | 30-60 minutes |

### Disk Usage

TSIDX files typically consume 10-20% of raw data size:
- 100GB raw data = 10-20GB TSIDX
- 1TB raw data = 100-200GB TSIDX

## Troubleshooting

### Acceleration Not Starting

**Check CIM add-on is enabled:**
```bash
sudo -u splunk /opt/splunk/bin/splunk display app Splunk_SA_CIM
```

**Check data is flowing:**
```
| datamodel Authentication search
| head 10
```

**Check scheduler logs:**
```
index=_internal sourcetype=scheduler savedsearch_name="DM_*"
| stats count by savedsearch_name, status, message
```

### Slow Build Performance

1. **Reduce time range:** Change from `-1y` to `-90d`
2. **Increase max_time:** Change from `3600` to `7200`
3. **Add more resources:** CPU, RAM, faster disks
4. **Stagger builds:** Edit search schedules in CIM UI

### High Disk Usage

**Check TSIDX size:**
```
| rest /services/admin/summarization by_tstats=1
| search title=DM_*
| eval size_gb=round(summary.size/1024/1024/1024,2)
| table title, size_gb
| sort -size_gb
```

**Reduce if needed:**
- Decrease `acceleration.earliest_time`
- Filter data using acceleration.source_guid (advanced)

### Incomplete Acceleration

**Symptoms:** Dashboards show "No results" or partial data

**Solutions:**
1. Wait for initial build to complete (check status)
2. Verify data exists in the time range
3. Check for acceleration errors in logs
4. Rebuild acceleration: Settings → Data Models → Rebuild

## Disabling Specific Models

If resources are limited, disable models not used by your dashboards:

1. Edit `local/datamodels.conf`
2. Set `acceleration = false` for unused models
3. Restart Splunk

Or via UI:
1. Settings → Data Models → [Model] → Edit → Acceleration
2. Uncheck "Accelerate"
3. Save

## Best Practices

1. **Start small:** Begin with `-30d`, expand to `-1y` after verifying performance
2. **Monitor builds:** Check completion daily during initial period
3. **Plan storage:** Ensure 20% raw data size available for TSIDX
4. **Staged rollout:** Enable 2-3 models at a time, verify, then enable more
5. **Use SSD:** Place `$SPLUNK_DB` on SSD for best acceleration performance
6. **Regular cleanup:** Old TSIDX files are auto-cleaned based on retention

## Related Documentation

- [Splunk Data Model Acceleration](https://docs.splunk.com/Documentation/Splunk/latest/Knowledge/Acceleratedatamodels)
- [CIM Documentation](https://docs.splunk.com/Documentation/CIM/latest/User/Overview)
- [tstats Command](https://docs.splunk.com/Documentation/Splunk/latest/SearchReference/tstats)
- [InfoSec App Requirements](https://splunkbase.splunk.com/app/4240/)

---

**Created for:** InfoSec App for Splunk
**Data Models:** 8 core models identified from dashboard analysis
**Last Updated:** November 2024
