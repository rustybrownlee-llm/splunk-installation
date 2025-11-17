# Download Required Files

This package does **not** include Splunk installers or add-ons due to size constraints. Download them separately.

## Required Downloads

### 1. Splunk Enterprise (Required)
**Download:** https://www.splunk.com/en_us/download/splunk-enterprise.html

- **File:** `splunk-10.0.1-c486717c322b-linux-amd64.tgz` (1.7GB)
- **Place in:** `downloads/splunk-10.0.1-c486717c322b-linux-amd64.tgz`

### 2. Splunk Add-ons (Required for full functionality)

Download from Splunkbase: https://splunkbase.splunk.com/

Place all `.tgz` files in the `downloads/` directory.

#### Core Add-ons
1. **Splunk Common Information Model (CIM)**
   - https://splunkbase.splunk.com/app/1621/
   - File: `splunk-common-information-model-cim_*.tgz`

2. **Splunk Add-on for Microsoft Windows**
   - https://splunkbase.splunk.com/app/742/
   - File: `splunk-add-on-for-microsoft-windows_*.tgz`

#### Network Security
3. **Splunk Add-on for Cisco ASA**
   - https://splunkbase.splunk.com/app/1620/

4. **Splunk Add-on for Palo Alto Networks**
   - https://splunkbase.splunk.com/app/2757/

5. **Add-on for Cisco Network Data**
   - https://splunkbase.splunk.com/app/1467/

#### Applications
6. **InfoSec App for Splunk**
   - https://splunkbase.splunk.com/app/4240/
   - File: `infosec-app-for-splunk_*.tgz`

7. **Splunk Security Essentials**
   - https://splunkbase.splunk.com/app/3435/
   - File: `splunk-security-essentials_*.tar.gz`

8. **Splunk Lookup File Editor**
   - https://splunkbase.splunk.com/app/1724/

#### Supporting Add-ons
9. **Splunk Supporting Add-on for Active Directory**
   - https://splunkbase.splunk.com/app/4955/

10. **Splunk Add-on for Sysmon**
    - https://splunkbase.splunk.com/app/5709/

11. **Splunk Add-on for Unix and Linux**
    - https://splunkbase.splunk.com/app/833/

#### Visualizations (Optional)
12. **Force Directed App for Splunk**
13. **Sankey Diagram**
14. **Punchcard Custom Visualization**

## Directory Structure After Downloads

```
linux-splunk-package/
├── downloads/
│   ├── splunk-10.0.1-c486717c322b-linux-amd64.tgz          (1.7GB)
│   ├── splunk-common-information-model-cim_*.tgz
│   ├── splunk-add-on-for-microsoft-windows_*.tgz
│   ├── splunk-security-essentials_*.tar.gz
│   ├── infosec-app-for-splunk_*.tgz
│   └── [other add-ons].tgz
├── install-splunk.sh
├── install-addons.sh
└── ...
```

## Quick Download Script

```bash
# Create downloads directory
mkdir -p downloads
cd downloads

# Download Splunk Enterprise (requires Splunk account)
# Manual download from https://www.splunk.com/en_us/download/splunk-enterprise.html

# Or use wget/curl if you have direct download links
# wget -O splunk-10.0.1-c486717c322b-linux-amd64.tgz "YOUR_DOWNLOAD_URL"
```

## Verification

After downloading, verify you have:
```bash
ls -lh downloads/ | grep -E "\.(tgz|tar\.gz)$" | wc -l
# Should show 15+ files
```

## Installation

Once all files are downloaded:
```bash
sudo ./install-splunk.sh
```

---

**Note**: Splunk Enterprise requires a valid license. Free license is available for up to 500MB/day ingestion.
