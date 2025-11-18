# HAP ES Index Definitions - Search Head Version

This app defines index stanzas for the ES Search Head **without storage paths**.

## Installation Location

**Server 1 (ES Search Head ONLY)** - Install to `C:\Program Files\Splunk\etc\apps\`

## Purpose

Makes indexes visible in:
- Splunk Web UI dropdowns
- Search interface index picker
- ES dashboards and navigation
- Data model configurations

**Important:** This does NOT create storage - data is stored on Server 2 (indexer).

## Why Search Heads Need Index Definitions

Even though Server 1 doesn't store data, it needs to know about indexes for:

1. **Web UI Display**: Index dropdown menus in search bar
2. **Search Targeting**: `index=wineventlog` syntax validation
3. **ES Configuration**: Data model index assignments
4. **Dashboard Rendering**: Index-based dashboard filters
5. **Search-time Operations**: Field extractions, lookups based on index

## Difference from Indexer Version

| Aspect | Indexer Version | Search Head Version |
|--------|----------------|---------------------|
| Location | Server 2 | Server 1 |
| Storage paths | [X] Defined | ✗ Not defined |
| Frozen rollover | [X] Configured | ✗ Not applicable |
| Size limits | [X] Set | ✗ Not needed |
| Purpose | Store data | UI visibility |

## Configuration Required

**None** - This app works as-is. No hostname or path updates needed.

## Installation Order

Install AFTER:
- Splunk Enterprise
- Enterprise Security app
- Splunk_TA_ForIndexers (if installed on search head)

## Verification

After installation and restart, verify indexes are visible:

### Web UI Check:
1. Log into Splunk Web (http://SERVER1:8000)
2. Go to **Settings → Indexes**
3. Verify all custom indexes appear in list

### Search Check:
Run this search:
```spl
| rest /services/data/indexes
| search title=wineventlog OR title=network OR title=firewall OR title=dns
| table title disabled
```

All indexes should show `disabled=0`

### ES Integration Check:
1. Go to **Enterprise Security → Configure → Data Models**
2. Verify indexes appear in index constraints dropdowns
3. Check ES correlation searches reference correct indexes

## Index List

Indexes defined in this app:
- `wineventlog` - Windows events
- `perfmon` - Windows performance data
- `network` - Network traffic
- `firewall` - Firewall logs
- `dns` - DNS queries
- `web` - Web server logs
- `proxy` - Web proxy logs
- `security` - Security appliances
- `endpoint` - EDR/antivirus
- `application` - Application logs
- `database` - Database logs
- `email` - Email logs
- `cybervision` - Cisco Cyber Vision data

## ES Auto-Created Indexes

These are automatically created by ES (do not manually create):
- `notable` - ES notable events
- `risk` - ES risk scores
- `threat_activity` - Threat intelligence
- `summary` - Data model summaries

## Related Apps

- **hap_add-on_es_indexes**: Full version with storage paths for Server 2
- **hap_add-on_distributed_search**: Distributed search configuration
- **Enterprise Security**: Uses these index definitions

## Troubleshooting

### Indexes Don't Appear in UI

Check if app is enabled:
```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk display app hap_add-on_es_indexes_searchhead -auth admin:password
```

Should show `enabled = true`

### Search Returns "No results found" for valid index

1. Verify distributed search is configured correctly
2. Check Server 2 (indexer) has data in the index
3. Verify search peer is "Up" in Settings → Distributed search

### ES Can't Find Indexes

Restart Splunk after installing this app:
```powershell
Restart-Service SplunkForwarder
```

## Notes

- **Do NOT** install the indexer version (`hap_add-on_es_indexes`) on Server 1
- **Only** install this search head version on Server 1
- Server 1 should have NO local indexing (search head only)
- All data storage happens on Server 2
