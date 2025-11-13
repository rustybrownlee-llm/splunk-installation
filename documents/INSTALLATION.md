# Splunk Enterprise Installation Guide

Quick installation guide for Splunk Enterprise 10.0.1 on Linux servers.

## Requirements

- **OS**: Ubuntu/Debian or RHEL/CentOS/Rocky/AlmaLinux
- **Resources**: 8GB RAM minimum, 80GB disk space
- **Access**: Root/sudo privileges
- **Network**: Ports 8000, 8089, 9997 accessible

## Installation Steps

### 1. Prepare Installation Files

Ensure all required files are in the `downloads/` directory:
```bash
ls -lh downloads/splunk-10.0.1-c486717c322b-linux-amd64.tgz
ls -lh downloads/*.tgz  # Verify all add-ons are present
```

### 2. Run Installation Scripts

Execute scripts in order:

```bash
cd scripts

# Step 1: Install Splunk Enterprise
sudo ./install-splunk.sh

# Step 2: Configure Deployment Server
sudo ./configure-deployment-server.sh

# Step 3: Install Add-ons and Apps
sudo ./install-addons.sh

# Step 4: Enable Receiving from Forwarders
sudo ./setup-receiving.sh
```

### 3. Access Splunk Web

After installation completes:

1. Open browser: `http://<server-ip>:8000`
2. Login with:
   - Username: `admin`
   - Password: `5plunk#1!`
3. **Change password immediately** after first login

### 4. Verify Installation

```bash
# Check Splunk status
sudo -u splunk /opt/splunk/bin/splunk status

# Check listening ports
sudo netstat -tuln | grep -E '(8000|8089|9997)'

# View installed apps
sudo -u splunk /opt/splunk/bin/splunk display app
```

## Default Configuration

| Component | Value |
|-----------|-------|
| Splunk Home | `/opt/splunk` |
| Splunk User/Group | `splunk:splunk` |
| Admin Password | `5plunk#1!` (CHANGE THIS!) |
| Web Interface | Port 8000 |
| Management Port | Port 8089 |
| Receiving Port | Port 9997 |

## Firewall Ports

The installation scripts automatically configure firewall rules:

| Port | Purpose | Protocol |
|------|---------|----------|
| 8000 | Splunk Web | TCP |
| 8089 | Management/Deployment Server | TCP |
| 9997 | Forwarder Data Receiving | TCP |

## Script Details

### install-splunk.sh
- Detects OS (Ubuntu/RHEL)
- Installs system dependencies
- Creates splunk user/group
- Extracts and configures Splunk
- Sets default admin password
- Configures firewall
- Enables boot-start service

### configure-deployment-server.sh
- Enables deployment server functionality
- Creates `windows_forwarder_base` app
- Configures serverclass for Windows forwarders
- Sets up automatic app deployment

### install-addons.sh
- Installs all add-ons in correct order:
  1. CIM (Common Information Model)
  2. Lookup File Editor
  3. Network add-ons (Cisco, Palo Alto)
  4. Technology add-ons (Windows, AD, Sysmon, Unix/Linux)
  5. InfoSec App
  6. Visualization apps

### setup-receiving.sh
- Enables port 9997 for receiving data
- Creates indexes (main, wineventlog, perfmon)
- Configures firewall rules

## Post-Installation

### Change Default Password

Via Splunk Web:
1. Settings → Users → admin → Edit
2. Change password
3. Save

Via CLI:
```bash
sudo -u splunk /opt/splunk/bin/splunk edit user admin -password NEW_PASSWORD -auth admin:5plunk#1!
```

### Get Server IP for Forwarders

```bash
hostname -I | awk '{print $1}'
```

Use this IP in Windows forwarder `config.ps1` file.

### Check Deployment Server

```bash
# List connected deployment clients
sudo -u splunk /opt/splunk/bin/splunk list deploy-clients -auth admin:5plunk#1!

# Reload deployment server
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server -auth admin:5plunk#1!
```

## Common Issues

### Installation Fails
- Check log output for specific errors
- Verify downloads folder contains required files
- Ensure sufficient disk space: `df -h`
- Check sudo/root access: `id`

### Firewall Not Configured
- Scripts detect `ufw` (Ubuntu) and `firewalld` (RHEL)
- Manual configuration if neither detected:
  ```bash
  # Ubuntu/Debian
  sudo ufw allow 8000/tcp
  sudo ufw allow 8089/tcp
  sudo ufw allow 9997/tcp

  # RHEL/CentOS
  sudo firewall-cmd --permanent --add-port=8000/tcp
  sudo firewall-cmd --permanent --add-port=8089/tcp
  sudo firewall-cmd --permanent --add-port=9997/tcp
  sudo firewall-cmd --reload
  ```

### Splunk Won't Start
```bash
# Check service status
sudo systemctl status Splunkd

# View logs
sudo tail -f /opt/splunk/var/log/splunk/splunkd.log

# Start manually
sudo -u splunk /opt/splunk/bin/splunk start
```

### Can't Access Web Interface
- Verify Splunk is running: `sudo -u splunk /opt/splunk/bin/splunk status`
- Check firewall allows port 8000
- Verify correct IP address: `hostname -I`
- Check if port is listening: `sudo netstat -tuln | grep 8000`

## Next Steps

1. **Secure Installation**: Change default password
2. **Install Forwarders**: See [WINDOWS-FORWARDER-INSTALL.md](WINDOWS-FORWARDER-INSTALL.md)
3. **Configure Data**: Review [ADMINISTRATION.md](ADMINISTRATION.md)
4. **Monitor Health**: Settings → Monitoring Console

## Useful Commands

```bash
# Service Management
sudo systemctl start Splunkd
sudo systemctl stop Splunkd
sudo systemctl status Splunkd

# Direct Splunk Commands
sudo -u splunk /opt/splunk/bin/splunk start
sudo -u splunk /opt/splunk/bin/splunk stop
sudo -u splunk /opt/splunk/bin/splunk restart
sudo -u splunk /opt/splunk/bin/splunk status

# View Logs
sudo tail -f /opt/splunk/var/log/splunk/splunkd.log

# Check Inputs
sudo -u splunk /opt/splunk/bin/splunk list inputstatus -auth admin:PASSWORD

# List Apps
sudo -u splunk /opt/splunk/bin/splunk display app

# Restart Splunk
sudo -u splunk /opt/splunk/bin/splunk restart
```

## Support

For issues or questions:
- Check logs: `/opt/splunk/var/log/splunk/splunkd.log`
- Review [ADMINISTRATION.md](ADMINISTRATION.md) for troubleshooting
- Splunk documentation: https://docs.splunk.com/

---

**Installation Time**: Approximately 30-45 minutes (including add-ons)

**Last Updated**: November 2025
