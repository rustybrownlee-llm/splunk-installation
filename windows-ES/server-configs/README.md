# HAP Server Configuration Files

This directory contains configuration files for Server 1 (ES Search Head / Deployment Server).

## Files

### serverclass.conf
**Purpose:** Controls which apps are deployed to which forwarders

**Install Location:** `C:\Program Files\Splunk\etc\system\local\serverclass.conf`

**After Installation:**
```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk reload deploy-server -auth admin:password
```

**Verify:**
```powershell
.\splunk list deploy-clients -auth admin:password
```

## Server Classes Defined

### AllForwarders
- **Matches:** All forwarders (Windows, Linux, etc.)
- **Apps Deployed:**
  - `hap_add-on_deployment` - Deployment server connection
  - `hap_add-on_outputs` - Send data to Server 2:9997

### WindowsForwarders
- **Matches:** Windows forwarders only (via OS filter)
- **Apps Deployed:**
  - `hap_add-on_windows_inputs` - Windows Event Logs + Perfmon

## Customization

Edit `serverclass.conf` to:
- Add environment-specific server classes (Prod/Test)
- Target specific hosts or naming patterns
- Deploy role-specific apps (DC, IIS, SQL Server)
- Use blacklists to exclude hosts

## Related Documentation

- **Deployment Apps:** `../deployment-apps/` directory
- **Splunk Docs:** [About deployment server](https://docs.splunk.com/Documentation/Splunk/latest/Updating/Aboutdeploymentserver)
