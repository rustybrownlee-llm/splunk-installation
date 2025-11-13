# Deployment Apps Directory

This directory contains apps that will be deployed to forwarders via the deployment server.

## Structure

Each subdirectory represents an app that can be deployed to forwarders:

```
deployment-apps/
├── windows_forwarder_base/
│   ├── local/
│   │   ├── inputs.conf      # Data inputs configuration
│   │   ├── outputs.conf     # Forwarding configuration
│   │   └── app.conf         # App metadata
│   └── metadata/
│       └── default.meta     # Permissions
```

## Creating a New Deployment App

1. Create a new directory: `mkdir deployment-apps/my_new_app`
2. Create the structure:
   ```bash
   mkdir -p deployment-apps/my_new_app/{local,metadata}
   ```
3. Add configuration files in `local/`
4. Create `metadata/default.meta` for permissions
5. Create `local/app.conf` with app metadata

## Example App Configuration

### app.conf
```ini
[install]
state = enabled

[ui]
is_visible = false
is_manageable = false

[launcher]
author = Splunk Admin
description = Description of what this app does
version = 1.0
```

### default.meta
```ini
[]
access = read : [ * ], write : [ admin ]
export = system
```

## Deploying Apps

Apps are deployed based on server class configuration in:
`$SPLUNK_HOME/etc/system/local/serverclass.conf`

After adding or modifying apps:
```bash
sudo -u splunk /opt/splunk/bin/splunk reload deploy-server
```

## Common Deployment Apps

- **windows_forwarder_base**: Base configuration for all Windows forwarders
  - Windows Event Logs collection
  - Performance Monitor data
  - Outputs configuration

- **linux_forwarder_base**: Base configuration for Linux forwarders (create as needed)
  - Syslog collection
  - File monitoring
  - Script execution

## Best Practices

1. Keep apps focused on specific functionality
2. Use server classes to target specific groups of forwarders
3. Test new apps on a single forwarder before deploying widely
4. Version your apps (increment version in app.conf when making changes)
5. Document changes in app descriptions
