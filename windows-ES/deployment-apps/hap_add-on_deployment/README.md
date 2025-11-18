# HAP Deployment Client Configuration

This app configures Universal Forwarders to connect to the HAP deployment server (Server 1).

## Purpose

Centralizes deployment server configuration so:
- All forwarders connect to the same deployment server
- If deployment server moves, update this app and push to all forwarders
- No need to manually edit system/local on each forwarder
- Consistent configuration across all endpoints

## Deployment Strategy

### Option 1: Deploy via Deployment Server (Recommended)

1. Install this app to Server 1's deployment-apps directory:
   ```
   C:\Program Files\Splunk\etc\deployment-apps\hap_add-on_deployment\
   ```

2. Configure serverclass to deploy to all forwarders (see serverclass.conf)

3. Forwarders receive app and connect to deployment server

**Catch-22 Solution**: For initial deployment, forwarders need to know the deployment server to receive this app. See Option 2 for bootstrap.

### Option 2: Bootstrap Installation (First-Time Setup)

For NEW forwarders that don't know the deployment server yet:

**During MSI Installation:**
```
DEPLOYMENT_SERVER="SERVER1_HOSTNAME:8089"
```

**Or Post-Installation:**
Copy this app to the forwarder manually:
```powershell
# Copy app to forwarder
Copy-Item -Path "\\SERVER1\share\hap_add-on_deployment" `
          -Destination "C:\Program Files\SplunkUniversalForwarder\etc\apps\" `
          -Recurse

# Restart forwarder
Restart-Service SplunkForwarder
```

After bootstrap, the deployment server can push updates to this app.

### Option 3: GPO/SCCM Deployment

Package this app with your Universal Forwarder deployment:
- Include in MSI customization
- Deploy via Group Policy
- Push via SCCM/Intune

## Configuration Required

### Update Deployment Server Address

Edit `default/deploymentclient.conf` line 13:

```ini
targetUri = DEPLOYMENT_SERVER_HOSTNAME:8089
```

Replace `DEPLOYMENT_SERVER_HOSTNAME` with:
- **Hostname**: `SERVER1:8089` or `HAP-SPLUNK-01:8089`
- **FQDN**: `server1.domain.local:8089`
- **IP Address**: `192.168.1.10:8089` (less preferred, harder to move)

**Recommendation**: Use hostname or FQDN for flexibility.

### Example:
```ini
targetUri = HAP-SPLUNK-01:8089
```

## Phone Home Interval

Default: **60 seconds** (forwarder checks for updates every minute)

Adjust if needed:
- More frequent: `30` (heavier load on deployment server)
- Less frequent: `300` (5 minutes, lighter load)
- Production standard: `60` (recommended)

## Installation Locations

| Forwarder Type | Installation Path |
|----------------|-------------------|
| Windows | `C:\Program Files\SplunkUniversalForwarder\etc\apps\` |
| Linux | `/opt/splunkforwarder/etc/apps/` |
| macOS | `/Applications/SplunkForwarder/etc/apps/` |

## Verification

### Check Deployment Client Status

On a forwarder:
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk show deploy-poll -auth admin:changeme
```

Expected output:
```
Deployment Server URI: https://SERVER1:8089
Deployment Client is Enabled.
```

### Check Connection to Deployment Server

```powershell
.\splunk list deploy-server -auth admin:changeme
```

Should show Server 1 details.

### View Forwarder Status on Deployment Server

On Server 1:
```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk list deploy-clients -auth admin:password
```

Should list all connected forwarders with this app installed.

## Moving the Deployment Server

If you need to move the deployment server to a different machine:

### Step 1: Update This App

Edit `default/deploymentclient.conf`:
```ini
targetUri = NEW_SERVER:8089
```

### Step 2: Reload Deployment Server

On the **current** deployment server:
```powershell
.\splunk reload deploy-server -auth admin:password
```

### Step 3: Push Updated App

The updated app will automatically deploy to all forwarders on their next phone home.

### Step 4: Verify Forwarders Reconnect

Check forwarders are connecting to new deployment server:
```spl
index=_internal sourcetype=splunkd component=DeploymentClient
| stats count by hostname
```

## Troubleshooting

### Forwarder Can't Connect to Deployment Server

**Check network connectivity:**
```powershell
Test-NetConnection -ComputerName SERVER1 -Port 8089
```

**Check deploymentclient.conf:**
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk btool deploymentclient list
```

Verify `targetUri` is correct.

**Check firewall:**
Ensure TCP 8089 is open on Server 1 firewall.

### App Not Deploying to Forwarders

**Check serverclass.conf** on deployment server - ensure this app is assigned to correct server class.

**Reload deployment server:**
```powershell
.\splunk reload deploy-server -auth admin:password
```

### Forwarder Shows "Deployment Client is Disabled"

Enable deployment client:
```powershell
.\splunk enable deploy-client -auth admin:changeme
```

Or check if `disabled = true` in deploymentclient.conf.

### Multiple Deployment Servers?

If you have multiple deployment servers (e.g., prod vs. test):
- Create separate versions of this app
- `hap_add-on_deployment_prod`
- `hap_add-on_deployment_test`

Deploy appropriate version to each forwarder group.

## Security Considerations

1. **Authentication**: Deployment server uses Splunk auth (port 8089)
2. **Encryption**: Communication over HTTPS by default
3. **Certificate Validation**: Consider enabling SSL certificate validation
4. **Firewall**: Restrict 8089 access to known forwarder IPs/subnets

## Advanced Configuration

### Retry on Failure

Add to deploymentclient.conf:
```ini
[target-broker:deploymentServer]
targetUri = SERVER1:8089
phoneHomeIntervalInSecs = 60
handshakeRetryIntervalInSecs = 30
```

### Multiple Deployment Servers (Failover)

```ini
[target-broker:primary_ds]
targetUri = SERVER1:8089

[target-broker:secondary_ds]
targetUri = SERVER2:8089
```

Note: Splunk tries primary first, then secondary on failure.

## Related Apps

- **hap_add-on_outputs**: Configures where forwarders send data (Server 2)
- **hap_add-on_windows_inputs**: Windows-specific data collection
- **serverclass.conf**: Deployment server configuration (Server 1)

## Files in This App

```
hap_add-on_deployment/
├── default/
│   ├── app.conf               # App metadata
│   └── deploymentclient.conf  # Deployment client config
├── metadata/
│   └── default.meta           # Permissions
└── README.md                  # This file
```

## Example Deployment Flow

1. **Install Splunk Enterprise on Server 1**
2. **Configure Server 1 as deployment server**
3. **Update this app** with Server 1 hostname
4. **Copy to deployment-apps**:
   ```powershell
   Copy-Item -Path "hap_add-on_deployment" `
             -Destination "C:\Program Files\Splunk\etc\deployment-apps\" `
             -Recurse
   ```
5. **Configure serverclass.conf** to deploy to all forwarders
6. **Install Universal Forwarders** with bootstrap deployment server setting
7. **Forwarders check in**, receive this app, and maintain connection

---

**Last Updated:** 2024-11-17
