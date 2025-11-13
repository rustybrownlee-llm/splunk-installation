# OCS Add-on: Deployment Client Configuration

## Purpose
Configures forwarders to connect to the deployment server for centralized configuration management.

## What it does
- Establishes connection between Universal Forwarders and the Deployment Server
- Enables automatic app deployment and updates from the deployment server
- Allows centralized management of forwarder configurations

## Configuration

### Deployment Server Setup
Edit `default/deploymentclient.conf` and replace `DEPLOYMENT_SERVER_IP` with your deployment server's IP address or hostname:

```ini
[target-broker:deploymentServer]
targetUri = 192.168.1.10:8089
```

### Per-Forwarder Overrides
If a specific forwarder needs to connect to a different deployment server:

1. On the forwarder, create: `$SPLUNK_HOME/etc/apps/ocs_add-on_deployment/local/deploymentclient.conf`
2. Add the override configuration:
```ini
[target-broker:deploymentServer]
targetUri = different-server:8089
```

## Deployment
This app should be deployed via:
- **Method 1**: Deployment server (for forwarders already connected)
- **Method 2**: Packaged with forwarder installer (for new installations)
- **Method 3**: Manual installation on standalone forwarders

## Version
1.0.0

## Author
OCS Admin
