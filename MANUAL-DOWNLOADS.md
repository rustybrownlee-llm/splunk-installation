# Network Add-ons Installation Guide

All required network add-ons have been downloaded and are ready for installation.

## Downloaded Network Add-ons for Traffic Data Model

### 1. Cisco Network Data Add-on ✓
- **Filename**: `add-on-for-cisco-network-data_279.tgz`
- **Version**: 2.7.9
- **Size**: 63 KB
- **App ID**: 1467
- **Description**:
  - Supports Cisco IOS, IOS XE, IOS XR, and NX-OS devices
  - CIM-compliant for network traffic data model
  - Provides field extractions and lookups for Cisco network data

### 2. Cisco ASA Add-on ✓
- **Filename**: `splunk-add-on-for-cisco-asa_600.tgz`
- **Version**: 6.0.0
- **Size**: 69 KB
- **Description**:
  - Specifically for Cisco ASA firewalls
  - CIM-compliant for network traffic data model

### 3. Palo Alto Networks Add-on ✓
- **Filename**: `splunk-add-on-for-palo-alto-networks_202.tgz`
- **Version**: 2.0.2
- **Size**: 4.8 MB
- **App ID**: 7523
- **Description**:
  - Supports Palo Alto Networks firewalls
  - CIM-compliant for network traffic data model
  - Compatible with Splunk 10.0+

## Verify Downloads

All files are present in the downloads/ directory:

```bash
ls -lh downloads/add-on-for-cisco-network-data_279.tgz
ls -lh downloads/splunk-add-on-for-cisco-asa_600.tgz
ls -lh downloads/splunk-add-on-for-palo-alto-networks_202.tgz
```

## Installation Order

After downloading, install the add-ons in this specific order:

1. **Splunk Common Information Model (CIM)** ✓ Already downloaded
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-common-information-model-cim_620.tgz -auth admin:password
   ```

2. **Splunk App for Lookup File Editing** ✓ Already downloaded
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-app-for-lookup-file-editing_406.tgz -auth admin:password
   ```

3. **Network Add-ons** ✓ Already downloaded
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/add-on-for-cisco-network-data_279.tgz -auth admin:password
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-add-on-for-cisco-asa_600.tgz -auth admin:password
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-add-on-for-palo-alto-networks_202.tgz -auth admin:password
   ```

4. **Technology Add-ons** ✓ Already downloaded
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-add-on-for-microsoft-windows_901.tgz -auth admin:password
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-supporting-add-on-for-active-directory_311.tgz -auth admin:password
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-add-on-for-sysmon_500.tgz -auth admin:password
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/splunk-add-on-for-unix-and-linux_1020.tgz -auth admin:password
   ```

5. **InfoSec App for Splunk** ✓ Already downloaded
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk install app downloads/infosec-app-for-splunk_171.tgz -auth admin:password
   ```

6. **Restart Splunk**
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk restart
   ```

## Verification

After installation, verify the add-ons are installed:

1. **Via Splunk Web**:
   - Navigate to `http://<splunk-server>:8000`
   - Go to Apps → Manage Apps
   - Look for "Splunk Add-on for Cisco Networks" and "Splunk Add-on for Palo Alto Networks"
   - Both should show as "Enabled"

2. **Via Command Line**:
   ```bash
   sudo -u splunk /opt/splunk/bin/splunk display app | grep -i "cisco\|palo"
   ```

3. **Check CIM Data Models**:
   - In Splunk Web, go to Settings → Data Models
   - Look for "Network Traffic" data model
   - The model should be populated by the network add-ons

## Troubleshooting

**Problem**: Add-on won't install
```bash
# Check if add-on package is valid
tar -tzf downloads/splunk-add-on-for-cisco-networks_273.tgz | head

# Check Splunk logs
tail -f /opt/splunk/var/log/splunk/splunkd.log
```

**Problem**: Add-on installed but not showing data
- Ensure you have actual Cisco/Palo Alto data being ingested
- These are TAs (Technology Add-ons) - they parse data but don't collect it
- You'll need to configure data inputs or forwarders to send network device logs

**Problem**: CIM data model not accelerating
- Go to Settings → Data Models
- Click on "Network Traffic" data model
- Enable acceleration if needed
- Note: Acceleration requires data to be present

## Additional Resources

- [Splunk Add-on for Cisco Networks Documentation](https://docs.splunk.com/Documentation/AddOns/released/CiscoNetworks/About)
- [Splunk Add-on for Palo Alto Networks Documentation](https://docs.splunk.com/Documentation/AddOns/released/PAN/About)
- [Splunk CIM Documentation](https://docs.splunk.com/Documentation/CIM/latest/User/Overview)
- [InfoSec App Documentation](https://splunkbase.splunk.com/app/4240/)

---

**Last Updated**: November 2025
