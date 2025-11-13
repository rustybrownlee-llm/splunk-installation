# Splunk Installation Downloads

This directory contains all Splunk software packages and add-ons for local installation.

## Core Splunk Software

### Splunk Enterprise
- **File**: `splunk-10.0.1-c486717c322b-linux-amd64.tgz` (1.6 GB)
- **Version**: 10.0.1
- **Build**: c486717c322b
- **Platform**: Linux AMD64
- **Purpose**: Main Splunk installation for Ubuntu VM

### Universal Forwarders
- **File**: `splunkforwarder-9.3.2-d8bb32809498-x64-release.msi` (130 MB)
  - **Version**: 9.3.2
  - **Platform**: Windows x64
  - **Purpose**: Windows forwarder installation

- **File**: `splunkforwarder-9.3.2-d8bb32809498-Linux-x86_64.tgz` (47 MB)
  - **Version**: 9.3.2
  - **Platform**: Linux x86_64
  - **Purpose**: Linux forwarder installation (if needed)

## Splunk Add-ons & Apps

### Core Add-ons
- **splunk-common-information-model-cim_620.tgz** (2.1 MB)
  - Essential data model for Splunk Enterprise Security and other apps

- **splunk-add-on-for-microsoft-windows_901.tgz** (210 KB)
  - Windows data collection and parsing

- **splunk-supporting-add-on-for-active-directory_311.tgz** (1.3 MB)
  - Active Directory support and integration

- **splunk-add-on-for-sysmon_500.tgz** (40 KB)
  - Sysmon event parsing for Windows

- **splunk-add-on-for-unix-and-linux_1020.tgz** (955 KB)
  - Unix/Linux data collection

### Network Security Add-ons
- **add-on-for-cisco-network-data_279.tgz** (63 KB)
  - Cisco IOS/IOS XE/IOS XR/NX-OS device support
  - Version 2.7.9
  - CIM-compliant network traffic data model

- **splunk-add-on-for-cisco-asa_600.tgz** (69 KB)
  - Cisco ASA firewall support
  - Version 6.0.0
  - CIM-compliant network traffic data model

- **splunk-add-on-for-palo-alto-networks_202.tgz** (4.8 MB)
  - Palo Alto Networks firewall support
  - Version 2.0.2
  - CIM-compliant network traffic data model

- **palo-alto-networks-firewall_214.tgz** (26 KB)
  - Older Palo Alto add-on (use v2.0.2 above instead)

### Apps & Tools
- **splunk-ai-toolkit_563.tgz** (20 MB)
  - Machine learning toolkit for Splunk

- **splunk-app-for-lookup-file-editing_406.tgz** (6.8 MB)
  - Edit CSV lookup files directly in Splunk Web

- **alert-manager_3011.tgz** (637 KB)
  - Advanced alert management and workflow

- **alert-manager-add-on_231.tgz** (10 KB)
  - Supporting add-on for Alert Manager

### Visualizations & Apps
- **infosec-app-for-splunk_171.tgz** (227 KB)
  - Information Security application

- **force-directed-app-for-splunk_311.tgz** (251 KB)
  - Force-directed graph visualizations

- **punchcard-custom-visualization_150.tgz** (222 KB)
  - Punchcard visualization

- **splunk-sankey-diagram-custom-visualization_160.tgz** (155 KB)
  - Sankey diagram visualization

## Installation Notes

### Splunk Enterprise
The installation script (`../scripts/install-splunk.sh`) automatically looks in this directory for:
```
splunk-10.0.1-c486717c322b-linux-amd64.tgz
```

### Windows Universal Forwarder
The PowerShell script (`../windows-forwarders/Install-SplunkForwarder.ps1`) automatically looks for:
```
splunkforwarder-10.0.1-c486717c322b-x64-release.msi
```
Note: Currently using version 9.3.2 as 10.0.1 was not publicly available.

### Installing Add-ons

**Important: Installation Order**
For proper CIM compliance and InfoSec App functionality, install in this order:
1. **Splunk Common Information Model (CIM)** - Install first
   - `splunk-common-information-model-cim_620.tgz`
2. **Splunk App for Lookup File Editing** - Required for InfoSec App
   - `splunk-app-for-lookup-file-editing_406.tgz`
3. **Network Add-ons** - Install before InfoSec App
   - `add-on-for-cisco-network-data_279.tgz`
   - `splunk-add-on-for-cisco-asa_600.tgz`
   - `splunk-add-on-for-palo-alto-networks_202.tgz`
4. **Technology Add-ons** - Windows and Unix monitoring
   - `splunk-add-on-for-microsoft-windows_901.tgz`
   - `splunk-supporting-add-on-for-active-directory_311.tgz`
   - `splunk-add-on-for-sysmon_500.tgz`
   - `splunk-add-on-for-unix-and-linux_1020.tgz`
5. **InfoSec App for Splunk** - Install after all dependencies
   - `infosec-app-for-splunk_171.tgz`
6. **Visualization Apps** - Optional enhancements
   - `splunk-ai-toolkit_563.tgz`
   - `force-directed-app-for-splunk_311.tgz`
   - `alert-manager_3011.tgz` (install add-on first: `alert-manager-add-on_231.tgz`)
   - Note: Sankey and Punchcard visualizations are deprecated on Splunk 10.0+

**Via Splunk Web:**
1. Go to Apps → Manage Apps
2. Click "Install app from file"
3. Browse to this directory and select the .tgz file
4. Follow the installation prompts
5. Restart Splunk when prompted

**Via Command Line:**
```bash
sudo -u splunk /opt/splunk/bin/splunk install app /path/to/addon.tgz -auth admin:password
sudo -u splunk /opt/splunk/bin/splunk restart
```

**All Required Files Present:**
All necessary add-ons and apps have been downloaded and are ready for installation.

## Download Sources

All files were downloaded from official Splunk sources:
- **Splunk Enterprise & Forwarders**: https://www.splunk.com/en_us/download.html
- **Apps & Add-ons**: https://splunkbase.splunk.com/

## Version Compatibility

- **Splunk Enterprise**: 10.0.1
- **Universal Forwarders**: 9.3.2 (compatible with Splunk Enterprise 10.0.1)
- **Add-ons**: Latest available versions as of November 2025

**Note**: Universal Forwarders from different versions can connect to Splunk Enterprise. Version 9.3.2 forwarders are fully compatible with 10.0.1 Enterprise.

## File Integrity

To verify file integrity, you can check MD5/SHA256 checksums against Splunk's official checksums:
```bash
sha256sum filename.tgz
```

Compare with checksums from Splunk's download page.

## Storage Requirements

Total space used: ~2.0 GB

Ensure you have sufficient disk space before installation:
- Ubuntu VM: 80 GB recommended
- Windows VM: 60 GB recommended
