# OCS Add-on: Index Definitions

## Purpose
Defines CIM-compliant indexes for standardized data collection across the Splunk deployment.

## Installation Location
**Splunk Enterprise Server** (Indexer/Search Head) - NOT deployed to forwarders

## Indexes Created

| Index | Purpose | Max Size | Retention | Typical Sources |
|-------|---------|----------|-----------|-----------------|
| **wineventlog** | Windows Event Logs | 512GB | 30 days | Windows System, Security, Application logs |
| **os** | Operating System Data | 256GB | 30 days | Syslog, auth.log, secure, messages |
| **network** | Network Device Data | 256GB | 30 days | Firewalls, switches, routers, IDS/IPS |
| **web** | Web Access Logs | 256GB | 30 days | Apache, IIS, nginx, proxy logs |
| **security** | Security Events | 512GB | 60 days | IDS/IPS, antivirus, authentication, DLP |
| **application** | Application Logs | 256GB | 30 days | Custom apps, middleware, app servers |
| **database** | Database Logs | 128GB | 30 days | Oracle, MySQL, PostgreSQL, SQL Server |
| **email** | Email Logs | 128GB | 60 days | Exchange, Postfix, sendmail, gateways |

## CIM Data Model Mapping

These indexes align with Splunk Common Information Model (CIM) data models:

- **Authentication** → security, os, wineventlog
- **Network Traffic** → network
- **Web** → web
- **Email** → email
- **Endpoint** → os, wineventlog
- **Malware** → security
- **Intrusion Detection** → security, network

## Installation

### Method 1: Automated (Recommended)
Use the installation script:
```bash
sudo ./install-addons.sh
```

This extracts all add-ons including ocs_add-on_indexes to `/opt/splunk/etc/apps/`

### Method 2: Manual Installation
```bash
# Copy to Splunk apps directory
sudo cp -r ocs_add-on_indexes /opt/splunk/etc/apps/

# Set ownership
sudo chown -R splunk:splunk /opt/splunk/etc/apps/ocs_add-on_indexes

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart
```

## Verification

Check that indexes were created:
```bash
sudo -u splunk /opt/splunk/bin/splunk list index -auth admin:password
```

Or in Splunk Web:
1. Settings → Indexes
2. Verify all OCS indexes are listed

## Customization

### Adjusting Retention
To change retention period for an index:
```bash
sudo -u splunk /opt/splunk/bin/splunk edit index wineventlog \
  -frozenTimePeriodInSecs 5184000 \
  -auth admin:password
# 5184000 seconds = 60 days
```

### Adjusting Size Limits
Edit `default/indexes.conf` before installation, or modify after:
```bash
sudo -u splunk /opt/splunk/bin/splunk edit index wineventlog \
  -maxTotalDataSizeMB 1000000 \
  -auth admin:password
# 1000000 MB = ~1TB
```

### Override in Local
For custom adjustments, create `local/indexes.conf`:
```ini
[wineventlog]
maxTotalDataSizeMB = 1000000
frozenTimePeriodInSecs = 7776000
# 1TB max, 90-day retention
```

## Index Usage Guidelines

### wineventlog
- All Windows Event Logs (System, Security, Application)
- Windows operational logs (PowerShell, Sysmon, etc.)
- Windows performance data

### os
- Linux/Unix syslog
- Authentication logs (auth.log, secure)
- System messages
- Can also include Windows OS-level events if preferred

### network
- Firewall logs (Cisco ASA, Palo Alto, etc.)
- Switch/router logs
- IDS/IPS (Snort, Suricata)
- Network flow data (NetFlow, sFlow)

### web
- Web server access logs
- Web server error logs
- Proxy logs (Squid, Blue Coat)
- Load balancer logs

### security
- Centralized security events
- Antivirus/EDR logs
- DLP alerts
- Authentication failures
- Privilege escalation events

### application
- Custom application logs
- Middleware (Tomcat, JBoss)
- Message queues
- Microservices

### database
- Database audit logs
- Query logs
- Slow query logs
- Database errors

### email
- SMTP logs
- Exchange logs
- Email gateway logs
- Spam filter logs

## Monitoring Index Health

### Check Index Sizes
```
| rest /services/data/indexes
| search title=wineventlog OR title=os OR title=network OR title=web OR title=security OR title=application OR title=database OR title=email
| table title currentDBSizeMB maxTotalDataSizeMB
| eval percentUsed=round((currentDBSizeMB/maxTotalDataSizeMB)*100,2)
| sort -percentUsed
```

### Check Data Ingestion by Index
```
index=* earliest=-24h
| eval indexname=index
| stats count as events sum(len(_raw)) as bytes by indexname
| eval GB=round(bytes/1024/1024/1024,3)
| fields - bytes
| sort -GB
```

### Monitor License Usage by Index
```
index=_internal source=*license_usage.log type=Usage
| eval GB=b/1024/1024/1024
| stats sum(GB) as GB by idx
| sort -GB
```

## Important Notes

1. **Install on Indexer/Search Head Only** - Do NOT deploy to forwarders
2. **Create Before Sending Data** - Indexes must exist before forwarders send data
3. **Monitor License Usage** - Adjust retention/size based on license constraints
4. **Adjust for Your Environment** - Default sizes are starting points, tune based on actual usage
5. **Consider Compliance** - Security/email indexes have longer retention for compliance

## Related Documentation
- [Splunk Indexes Documentation](https://docs.splunk.com/Documentation/Splunk/latest/Indexer/Aboutindexesandindexers)
- [CIM Documentation](https://docs.splunk.com/Documentation/CIM/latest/User/Overview)

## Version
1.0.0

## Author
OCS Admin
