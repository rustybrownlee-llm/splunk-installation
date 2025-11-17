# Splunk Enterprise Linux Implementation Guide

## Manual Installation Instructions

This guide provides step-by-step CLI commands for manually installing Splunk Enterprise on Ubuntu/Debian or RHEL/CentOS systems **without internet access**.

---

## Prerequisites

- Root or sudo access
- Pre-downloaded files in `linux-splunk-package/` directory:
  - `downloads/splunk-10.0.1-c486717c322b-linux-amd64.tgz` (or ARM64 version)
  - 18 add-on `.tgz` and `.tar.gz` files in `downloads/`
  - Configuration directories: `ocs_add-on_indexes/`, `cim-local-config/`, `deployment-apps/`

---

## Part 1: Install Splunk Enterprise

### Step 1: Verify Files

```bash
cd /path/to/linux-splunk-package
ls -lh downloads/splunk-10.0.1-*.tgz
ls -1 downloads/*.tgz downloads/*.tar.gz | wc -l
# Should show 19 files (1 installer + 18 add-ons)
```

### Step 2: Create Splunk User and Group

```bash
sudo groupadd -r splunk
sudo useradd -r -m -d /home/splunk -s /bin/bash -g splunk splunk
```

### Step 3: Extract Splunk

```bash
sudo cp downloads/splunk-10.0.1-c486717c322b-linux-amd64.tgz /tmp/
cd /tmp
sudo tar xzf splunk-10.0.1-c486717c322b-linux-amd64.tgz -C /opt
```

### Step 4: Set Ownership

```bash
sudo chown -R splunk:splunk /opt/splunk
```

### Step 5: Configure Admin Password

**Important**: Replace `YOUR_PASSWORD_HERE` with your desired admin password (minimum 8 characters)

```bash
sudo mkdir -p /opt/splunk/etc/system/local
sudo bash -c 'cat > /opt/splunk/etc/system/local/user-seed.conf << EOF
[user_info]
USERNAME = admin
PASSWORD = YOUR_PASSWORD_HERE
EOF'
sudo chown splunk:splunk /opt/splunk/etc/system/local/user-seed.conf
sudo chmod 600 /opt/splunk/etc/system/local/user-seed.conf
```

### Step 6: Start Splunk

```bash
sudo -u splunk /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
```

**Expected Output**: "The Splunk web interface is at http://[hostname]:8000"

### Step 7: Enable Boot Start (Optional)

```bash
sudo /opt/splunk/bin/splunk enable boot-start -user splunk --accept-license --answer-yes
```

**Note**: On RHEL 9, this may fail due to OpenSSL library incompatibility. Splunk will still run, but won't auto-start on reboot.

### Step 8: Configure Firewall

**For Ubuntu/Debian (ufw):**
```bash
sudo ufw allow 8000/tcp comment 'Splunk Web'
sudo ufw allow 8089/tcp comment 'Splunk Management Port'
sudo ufw allow 9997/tcp comment 'Splunk Forwarder Receiving'
```

**For RHEL/CentOS (firewalld):**
```bash
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-port=8000/tcp --zone=public
sudo firewall-cmd --permanent --add-port=8089/tcp --zone=public
sudo firewall-cmd --permanent --add-port=9997/tcp --zone=public
sudo firewall-cmd --reload
```

### Step 9: Verify Installation

```bash
sudo -u splunk /opt/splunk/bin/splunk status
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8000
```

**Expected**: "splunkd is running" and "HTTP 303"

---

## Part 2: Install Add-ons and Apps

### Step 1: Stop Splunk

```bash
sudo -u splunk /opt/splunk/bin/splunk stop
```

### Step 2: Install OCS Index Definitions

```bash
cd /path/to/linux-splunk-package
sudo cp -r ocs_add-on_indexes /opt/splunk/etc/apps/
```

### Step 3: Extract All Add-ons

```bash
cd /opt/splunk/etc/apps/

# Extract .tgz files (skip Splunk installer and forwarder packages)
for tarball in /path/to/linux-splunk-package/downloads/*.tgz; do
    filename=$(basename "$tarball")

    # Skip Splunk installer
    if [[ "$filename" =~ splunk-[0-9]+\.[0-9]+\.[0-9]+-.*-linux- ]]; then
        echo "Skipping installer: $filename"
        continue
    fi

    # Skip forwarder packages
    if [[ "$filename" == *"forwarder"* ]]; then
        echo "Skipping forwarder: $filename"
        continue
    fi

    echo "Extracting: $filename"
    sudo tar -xzf "$tarball" 2>/dev/null
done

# Extract .tar.gz files (Splunk Security Essentials)
for tarball in /path/to/linux-splunk-package/downloads/*.tar.gz; do
    filename=$(basename "$tarball")
    echo "Extracting: $filename"
    sudo tar -xzf "$tarball" 2>/dev/null
done
```

**Verify Extraction:**
```bash
ls -1 /opt/splunk/etc/apps/ | grep -E 'cisco|palo|infosec|Splunk_SA_CIM|TA-'
# Should show multiple add-ons
```

### Step 4: Configure CIM Data Model Acceleration

```bash
sudo mkdir -p /opt/splunk/etc/apps/Splunk_SA_CIM/local
sudo cp /path/to/linux-splunk-package/cim-local-config/datamodels.conf \
    /opt/splunk/etc/apps/Splunk_SA_CIM/local/
```

### Step 5: Set Ownership

```bash
sudo chown -R splunk:splunk /opt/splunk/etc/apps/
```

### Step 6: Start Splunk

```bash
sudo -u splunk /opt/splunk/bin/splunk start
```

**Wait 30-60 seconds for all apps to initialize**

### Step 7: Verify Add-ons

```bash
sudo -u splunk /opt/splunk/bin/splunk display app -auth admin:YOUR_PASSWORD_HERE | head -30
```

Access Splunk Web at `http://[server-ip]:8000` and verify:
1. Apps → Manage Apps shows all installed apps as "Enabled"
2. Settings → Indexes shows: wineventlog, os, network, web, security, application, database, email

---

## Part 3: Configure Deployment Server

### Step 1: Enable Deployment Server

**Replace `YOUR_PASSWORD_HERE` with your admin password**

```bash
sudo -u splunk /opt/splunk/bin/splunk enable deploy-server -auth admin:YOUR_PASSWORD_HERE
```

### Step 2: Create Deployment Apps Directory

```bash
sudo mkdir -p /opt/splunk/etc/deployment-apps
```

### Step 3: Install OCS Deployment Apps

```bash
cd /path/to/linux-splunk-package
sudo cp -r deployment-apps/ocs_add-on_deployment /opt/splunk/etc/deployment-apps/
sudo cp -r deployment-apps/ocs_add-on_outputs /opt/splunk/etc/deployment-apps/
sudo cp -r deployment-apps/ocs_add-on_windows /opt/splunk/etc/deployment-apps/
```

### Step 4: Configure Server IP in Deployment Apps

**Get your server IP:**
```bash
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $SERVER_IP"
```

**Update ocs_add-on_deployment:**
```bash
sudo sed -i "s/DEPLOYMENT_SERVER_IP/$SERVER_IP/g" \
    /opt/splunk/etc/deployment-apps/ocs_add-on_deployment/default/deploymentclient.conf

# For macOS, use:
# sudo sed -i '' "s/DEPLOYMENT_SERVER_IP/$SERVER_IP/g" \
#     /opt/splunk/etc/deployment-apps/ocs_add-on_deployment/default/deploymentclient.conf
```

**Update ocs_add-on_outputs:**
```bash
sudo sed -i "s/INDEXER_IP/$SERVER_IP/g" \
    /opt/splunk/etc/deployment-apps/ocs_add-on_outputs/default/outputs.conf

# For macOS, use:
# sudo sed -i '' "s/INDEXER_IP/$SERVER_IP/g" \
#     /opt/splunk/etc/deployment-apps/ocs_add-on_outputs/default/outputs.conf
```

### Step 5: Create Server Class Configuration

```bash
sudo bash -c 'cat > /opt/splunk/etc/system/local/serverclass.conf << "EOF"
[global]
whitelist.0 = *

# OCS Deployment Apps - All Forwarders
[serverClass:AllForwarders]
whitelist.0 = *

[serverClass:AllForwarders:app:ocs_add-on_deployment]
restartSplunkd = true
stateOnClient = enabled

[serverClass:AllForwarders:app:ocs_add-on_outputs]
restartSplunkd = true
stateOnClient = enabled

# OCS Windows Apps - Windows Forwarders (OS-based detection)
[serverClass:WindowsForwarders]
whitelist.0 = *
machineTypesFilter = windows-x64,windows-intel
restartSplunkd = true

[serverClass:WindowsForwarders:app:ocs_add-on_windows]
restartSplunkd = true
stateOnClient = enabled
EOF'
```

### Step 6: Set Ownership

```bash
sudo chown -R splunk:splunk /opt/splunk/etc/deployment-apps
sudo chown splunk:splunk /opt/splunk/etc/system/local/serverclass.conf
```

### Step 7: Reload Deployment Server

```bash
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:YOUR_PASSWORD_HERE
```

### Step 8: Verify Deployment Server

```bash
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:YOUR_PASSWORD_HERE
```

**Expected**: "No deployment clients found" (until forwarders connect)

---

## Part 4: Configure Data Receiving

### Step 1: Enable Receiving Port

```bash
sudo -u splunk /opt/splunk/bin/splunk enable listen 9997 -auth admin:YOUR_PASSWORD_HERE
```

### Step 2: Create Receiving Configuration

```bash
sudo bash -c 'cat > /opt/splunk/etc/system/local/inputs.conf << "EOF"
[splunktcp://9997]
disabled = false
compressed = true

[default]
host = $decideOnStartup
EOF'
```

### Step 3: Configure Index Settings

```bash
sudo bash -c 'cat > /opt/splunk/etc/system/local/indexes.conf << "EOF"
[default]
maxTotalDataSizeMB = 250000
frozenTimePeriodInSecs = 15552000

[main]
maxTotalDataSizeMB = 250000

[wineventlog]
maxTotalDataSizeMB = 100000

[perfmon]
maxTotalDataSizeMB = 50000
EOF'
```

### Step 4: Set Ownership

```bash
sudo chown splunk:splunk /opt/splunk/etc/system/local/inputs.conf
sudo chown splunk:splunk /opt/splunk/etc/system/local/indexes.conf
```

### Step 5: Restart Splunk

```bash
sudo -u splunk /opt/splunk/bin/splunk restart
```

**Wait 30-60 seconds for restart**

### Step 6: Verify Receiving Port

```bash
sudo netstat -tulnp | grep 9997
# Or on newer systems:
sudo ss -tulnp | grep 9997
```

**Expected**: Shows splunkd listening on port 9997

---

## Verification Checklist

### Access Splunk Web

1. Open browser: `http://[server-ip]:8000`
2. Login: `admin` / `YOUR_PASSWORD_HERE`

### Verify Components

- [ ] **Apps → Manage Apps**: All apps show as "Enabled"
- [ ] **Settings → Indexes**: Shows wineventlog, os, network, web, security, application, database, email, perfmon
- [ ] **Settings → Forwarding and receiving**: Shows "Configure receiving" with port 9997
- [ ] **Settings → Distributed environment → Deployment server**: Shows server classes configured
- [ ] **Settings → Data models**: Shows CIM data models with acceleration enabled

### Test Commands

```bash
# Check Splunk status
sudo -u splunk /opt/splunk/bin/splunk status

# List all apps
sudo -u splunk /opt/splunk/bin/splunk display app -auth admin:YOUR_PASSWORD_HERE

# Check receiving status
sudo -u splunk /opt/splunk/bin/splunk list inputstatus -auth admin:YOUR_PASSWORD_HERE

# List deployment clients (should be empty until forwarders connect)
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:YOUR_PASSWORD_HERE
```

---

## Common Splunk Commands

```bash
# Start Splunk
sudo -u splunk /opt/splunk/bin/splunk start

# Stop Splunk
sudo -u splunk /opt/splunk/bin/splunk stop

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart

# Check status
sudo -u splunk /opt/splunk/bin/splunk status

# Reload deployment server
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:YOUR_PASSWORD_HERE

# View logs
sudo tail -f /opt/splunk/var/log/splunk/splunkd.log
```

---

## Troubleshooting

### Splunk Won't Start

```bash
# Check for errors
sudo tail -50 /opt/splunk/var/log/splunk/splunkd.log

# Check if port 8000 is already in use
sudo netstat -tulnp | grep 8000

# Verify ownership
ls -la /opt/splunk | head -10
# Should show splunk:splunk
```

### Port 9997 Not Listening

```bash
# Check inputs.conf
cat /opt/splunk/etc/system/local/inputs.conf

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart

# Wait and check again
sleep 30
sudo ss -tulnp | grep 9997
```

### Add-ons Not Appearing

```bash
# Check apps directory
ls -1 /opt/splunk/etc/apps/ | wc -l
# Should show 30+ directories

# Check ownership
ls -la /opt/splunk/etc/apps/ | head -20
# Should all show splunk:splunk

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart
```

---

## Important Notes

1. **OpenSSL Issue on RHEL 9**: The boot-start command may fail with "libcrypto.so.3: version OPENSSL_3.4.0 not found". This is a known compatibility issue. Splunk runs fine, but won't auto-start on reboot. Manually start after reboots if needed.

2. **Firewall**: If firewall commands fail, manually configure firewall rules for ports 8000, 8089, and 9997.

3. **Password Security**: Change the default admin password immediately after first login via Splunk Web.

4. **Data Model Acceleration**: Initial build will start automatically but can take hours depending on data volume. Check status at Settings → Data Models.

5. **No Internet Required**: All commands above work without internet access, assuming files are pre-downloaded.

---

## Next Steps

After completing this installation:

1. Install Universal Forwarders on Windows/Linux clients (see IMPLEMENTATION-WINDOWS.md)
2. Configure data inputs specific to your environment
3. Set up user accounts and roles
4. Configure alerting and monitoring

---

**Installation Complete!**

Your Splunk Enterprise server is now ready to receive data from forwarders.
