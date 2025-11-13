# Splunk Enterprise Installation Package

Complete automation package for deploying Splunk Enterprise with Windows Universal Forwarders, designed for Professional Services engagements.

## 🚀 Quick Start

### For Linux Splunk Server

```bash
# Download package
wget https://github.com/YOUR_USERNAME/splunk-installation/archive/main.tar.gz
tar -xzf main.tar.gz
cd splunk-installation-main/linux-splunk-package

# Download Splunk installers (see DOWNLOAD-INSTRUCTIONS.md)
# Then run installation
sudo ./install-splunk.sh
sudo ./install-addons.sh
sudo ./configure-deployment-server.sh
sudo ./setup-receiving.sh
```

### For Windows Forwarders

See `windows-forwarder-package/README.md`

## 📦 What's Included

### Linux Splunk Package
- **Automated Scripts**: Complete installation automation
- **OCS Custom Add-ons**: Production-ready deployment apps
- **SSL/TLS Support**: Certificate generation and configuration
- **CIM Integration**: Pre-configured data model acceleration
- **8 CIM-Compliant Indexes**: wineventlog, os, network, web, security, application, database, email

### Windows Forwarder Package
- **PowerShell Scripts**: Automated forwarder installation
- **Bulk Deployment Guide**: 5 methods for enterprise-scale deployment
- **OCS Deployment Apps**: Centralized configuration management

### Documentation
- **Installation Guides**: Step-by-step for all platforms
- **Administration Guide**: Day-2 operations
- **Bulk Deployment Guide**: Scale to thousands of endpoints
- **Testing Documentation**: QA procedures and results

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│         Splunk Enterprise (Linux)           │
│                                             │
│  - Indexer                                  │
│  - Deployment Server                        │
│  - Search Head                              │
│  - 8 CIM-Compliant Indexes                  │
│  - InfoSec App + Security Essentials        │
└─────────────────┬───────────────────────────┘
                  │
       ┌──────────┴──────────┐
       │                     │
┌──────▼─────┐      ┌───────▼──────┐
│  Windows   │      │   Windows    │
│  Forwarder │      │   Forwarder  │
│            │      │              │
│ - Event    │      │ - Event      │
│   Logs     │      │   Logs       │
│ - OCS Apps │      │ - OCS Apps   │
└────────────┘      └──────────────┘
```

## 📋 Prerequisites

### Linux Server
- Ubuntu 22.04 LTS or RHEL 9
- 8GB+ RAM (16GB recommended)
- 80GB+ disk space
- 4+ CPU cores
- Ports: 8000, 8089, 9997

### Windows Clients
- Windows Server 2012 R2+ or Windows 8.1+
- 2GB RAM minimum
- Network access to Splunk server
- Administrator privileges

## 🔐 Security Features

- ✅ **No Hardcoded Passwords**: All scripts prompt for credentials
- ✅ **SSL/TLS Support**: Self-signed or local CA certificates
- ✅ **Secure Defaults**: Proper file permissions and ownership
- ✅ **Role-Based Access**: OCS add-ons use default/local pattern

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [INSTALLATION.md](documents/INSTALLATION.md) | Linux Splunk installation guide |
| [ADMINISTRATION.md](documents/ADMINISTRATION.md) | Day-2 operations and maintenance |
| [WINDOWS-FORWARDER-INSTALL.md](documents/WINDOWS-FORWARDER-INSTALL.md) | Windows forwarder deployment |
| [WINDOWS-BULK-DEPLOYMENT.md](documents/WINDOWS-BULK-DEPLOYMENT.md) | Enterprise-scale deployment (5 methods) |
| [OCS-ADDONS.md](documents/OCS-ADDONS.md) | Custom OCS add-ons documentation |

## 🎯 Use Cases

- **Security Operations**: InfoSec App, Security Essentials, CIM compliance
- **Compliance**: PCI, HIPAA, SOX data collection and monitoring
- **IT Operations**: Centralized logging, performance monitoring
- **Incident Response**: Real-time alerting, correlation searches

## 🏢 Professional Services Ready

This package is designed for Professional Services engagements:
- Complete automation for consistent deployments
- Bulk deployment guidance for infrastructure teams
- Comprehensive documentation for handoff
- Testing procedures included
- Production-ready configurations

## 📖 Testing

See `testing/linux-testing-results.md` for QA procedures and validation results.

## 🤝 Support

This is a professional services package. For Splunk product support, visit https://www.splunk.com/support

## 📄 License

Splunk Enterprise requires a valid license. Free license available for up to 500MB/day ingestion.

## ⚠️ Important Notes

1. **Download Splunk Installers Separately**: This repo excludes Splunk binaries due to size. See `linux-splunk-package/DOWNLOAD-INSTRUCTIONS.md`
2. **Test First**: Always test in lab environment before production deployment
3. **Change Default Passwords**: Scripts prompt for passwords - never use defaults in production
4. **Review Firewall Rules**: Ensure proper network segmentation and access controls

## 🔄 Version

- **Splunk Enterprise**: 10.0.1
- **Universal Forwarder**: 9.3.2
- **Package Version**: 1.0.0
- **Last Updated**: November 2024

---

**Created for**: Professional Services deployments
**Supports**: Ubuntu 22.04 LTS, RHEL 9, Windows Server 2012 R2+
