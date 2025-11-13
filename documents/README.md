# Production Installation Documentation

**For Customer Deployments**

This folder contains all documentation for deploying Splunk Enterprise in production environments.

## Contents

- **INSTALLATION.md** - Complete Splunk Enterprise installation guide for Linux servers
- **ADMINISTRATION.md** - Administration, troubleshooting, and best practices guide
- **WINDOWS-FORWARDER-INSTALL.md** - Windows Universal Forwarder installation and configuration guide
- **SSH-KEYS-SETUP.md** - SSH key authentication setup for passwordless Linux server access

## Usage

These documents are designed for:
- Production Linux server deployments (Ubuntu/Debian or RHEL/CentOS)
- Customer-facing installations
- Field deployment by technicians
- Post-installation administration and support

## Key Features

- **OS Detection**: Scripts automatically detect Ubuntu/RHEL and configure appropriately
- **Modular Installation**: Test each phase independently
- **Simplified Configuration**: Single config file for Windows forwarders
- **Production Ready**: Includes security best practices and troubleshooting

## Installation Overview

### Linux Server (Splunk Enterprise)
1. Copy `scripts/` and `downloads/` to server
2. Run scripts in order:
   - `install-splunk.sh`
   - `configure-deployment-server.sh`
   - `install-addons.sh`
   - `setup-receiving.sh`
3. Access Splunk Web and change default password

### Windows Clients (Universal Forwarder)
1. Copy `windows-forwarders/` folder to Windows system
2. Edit `config.ps1` with Splunk server IP
3. Run `Install-SplunkForwarder.ps1` as Administrator
4. Verify in Splunk Web

## Support

- Default password: `5plunk#1!` (change immediately after installation)
- All scripts include detailed logging and error messages
- See ADMINISTRATION.md for troubleshooting

---

**Environment:** Production Linux servers (Ubuntu/Debian/RHEL/CentOS)
**Use Case:** Customer deployments and production installations
