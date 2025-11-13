# Lab/VM Documentation

**For Internal Use Only - Testing and Development**

This folder contains documentation for setting up a Splunk test lab using UTM virtual machines on macOS.

## Contents

### VM Setup Guides

- **LINUX-VM-SETUP.md** - Ubuntu Server VM creation for Splunk Enterprise testing
- **WINDOWS-VM-SETUP.md** - Windows 11 VM creation for Universal Forwarder testing

### Removed/Consolidated

- ~~VM-SETUP-GUIDE.md~~ - Split into separate Linux and Windows guides for clarity

## Related Documentation

- **SSH Keys Setup**: See `../documents/SSH-KEYS-SETUP.md`
  - Useful for both VMs and production servers
  - Enables passwordless SSH access
  - Required for easy file deployment

## Purpose

These documents are for:
- Setting up the testing environment on your Mac
- Learning and testing Splunk configurations
- Developing and validating scripts before production deployment
- Testing Windows forwarder PowerShell scripts
- Validating deployment automation

## Lab Architecture

```
macOS Host (M4 Max MacBook Pro)
├── Ubuntu VM (splunk-server)
│   ├── IP: 192.168.64.2
│   ├── RAM: 8 GB
│   ├── Disk: 80 GB
│   └── Splunk Enterprise + Apps
│
└── Windows 11 VM (windows-client)
    ├── IP: 192.168.64.3
    ├── RAM: 4 GB
    ├── Disk: 60 GB
    └── Universal Forwarder
```

## Setup Order

1. **Install UTM**: `brew install utm`
2. **Download ISOs**: Ubuntu Server ARM64 + Windows 11 ARM64 Evaluation
3. **Create Linux VM**: Follow LINUX-VM-SETUP.md
4. **Set up SSH keys**: Follow ../documents/SSH-KEYS-SETUP.md
5. **Deploy Splunk files**: Use `scripts/deploy-to-vm.sh`
6. **Install Splunk**: Follow ../documents/INSTALLATION.md
7. **Create Windows VM**: Follow WINDOWS-VM-SETUP.md
8. **Install forwarder**: Follow ../documents/WINDOWS-FORWARDER-INSTALL.md

## Not for Customer Use

These VM-specific documents are **not** intended for customer deployments.

**For production installation:** See `/documents` folder

---

**Environment:** macOS with UTM virtualization
**Platform:** Apple Silicon (ARM64)
**Use Case:** Lab testing and script development
**Last Updated:** November 2025
