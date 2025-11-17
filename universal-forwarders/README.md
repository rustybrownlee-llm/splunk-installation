# Universal Forwarders

This directory contains deployment strategies and configurations for Splunk Universal Forwarders across all platforms.

## Purpose

Universal Forwarders are lightweight Splunk agents that collect and forward data to Splunk Enterprise indexers. They can be deployed on:

- Windows servers and workstations
- Linux servers
- macOS systems
- Cloud instances
- Container environments

## Deployment Strategy

Forwarders connect to a Splunk Deployment Server which:
- Distributes configurations automatically
- Manages apps and inputs
- Provides centralized control
- Supports OS-specific targeting

## Contents

### windows-forwarder-package/
PowerShell scripts and configurations for Windows Universal Forwarder deployment.

**Key Files:**
- `Install-SplunkForwarder.ps1` - Automated installer
- `config/` - Configuration templates
- `README.md` - Windows-specific documentation

### Version Compatibility

Universal Forwarders should match the major version of your Splunk Enterprise deployment:

| Enterprise Version | Recommended Forwarder |
|-------------------|----------------------|
| 10.0.x | 10.0.2 |
| 9.4.6 | 9.4.6 |
| Universal | 9.3.2 |

Forwarder installers are located in `../installers/` directory.

## Deployment Server Integration

All forwarder deployments in this project use the Deployment Server pattern:

1. Install forwarder with deployment server configured
2. Forwarder checks in with deployment server
3. Server class rules determine which apps/configs to deploy
4. Forwarder receives and applies configurations automatically

This approach ensures:
- ✅ Consistent configurations across endpoints
- ✅ Easy updates and changes
- ✅ Centralized management
- ✅ OS-specific targeting (Windows vs Linux)

## Best Practices

1. **Version Matching**: Keep forwarders on the same major version as indexers
2. **Testing**: Test deployments on a subset before mass rollout
3. **Monitoring**: Use the deployment server UI to track forwarder health
4. **Credentials**: Use deployment server to distribute credentials securely
5. **Updates**: Stage updates through deployment server for gradual rollout

## Related Documentation

- `../linux-non-ES/IMPLEMENTATION-WINDOWS.md` - Manual Windows forwarder installation
- `../installers/` - Forwarder installer binaries
- Sub-project specific deployment guides
