# HAP Forwarder Outputs Configuration

This app configures Universal Forwarders to send data to the HAP indexer (Server 2).

## Purpose

- Points all forwarders to Server 2:9997 for data ingestion
- Centralizes output configuration
- Easy to update if indexer address changes
- Applies to ALL forwarders (Windows, Linux, etc.)

## Installation Location

**Server 1 Deployment Server:**
```
C:\Program Files\Splunk\etc\deployment-apps\hap_add-on_outputs\
```

Deployed automatically to all forwarders via deployment server.

## Configuration Required

### Update Indexer Address

Edit `default/outputs.conf` lines 15 and 38:

```ini
server = INDEXER_HOSTNAME:9997
```

and

```ini
[tcpout-server://INDEXER_HOSTNAME:9997]
```

Replace `INDEXER_HOSTNAME` with:
- **Hostname**: `SERVER2` or `HAP-SPLUNK-02`
- **FQDN**: `server2.domain.local`
- **IP Address**: `192.168.1.20` (less flexible)

**Recommendation**: Use hostname or FQDN for easier moves.

### Example:
```ini
server = HAP-SPLUNK-02:9997
```

```ini
[tcpout-server://HAP-SPLUNK-02:9997]
```

## Key Settings

| Setting | Value | Description |
|---------|-------|-------------|
| defaultGroup | hap_indexers | Output group name |
| indexAndForward | false | Don't index locally, forward only |
| compressed | true | Compress data to save bandwidth |
| server | SERVER2:9997 | Indexer address and receiving port |

## Deployment Strategy

### Via Deployment Server (Recommended)

1. Update `outputs.conf` with Server 2 hostname
2. Copy to `C:\Program Files\Splunk\etc\deployment-apps\`
3. Configure in serverclass.conf:
   ```ini
   [serverClass:AllForwarders:app:hap_add-on_outputs]
   restartSplunkd = true
   stateOnClient = enabled
   ```
4. Reload deployment server
5. Forwarders receive app and start sending data to Server 2

### Manual Installation (Bootstrap)

For initial forwarder setup before deployment server is configured:

```powershell
# Copy to forwarder
Copy-Item -Path "hap_add-on_outputs" `
          -Destination "C:\Program Files\SplunkUniversalForwarder\etc\apps\" `
          -Recurse

# Restart forwarder
Restart-Service SplunkForwarder
```

## Verification

### On Forwarder - Check Output Configuration

```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk list forward-server -auth admin:changeme
```

Expected output:
```
Active forwards:
        SERVER2:9997
```

### On Forwarder - Test Connection to Indexer

```powershell
Test-NetConnection -ComputerName SERVER2 -Port 9997
```

Should show `TcpTestSucceeded : True`

### On Server 2 (Indexer) - Check Incoming Connections

```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk list inputstatus -auth admin:password
```

or via search:
```spl
index=_internal sourcetype=splunkd component=Metrics group=tcpin_connections
| stats values(hostname) by sourceIp
```

### On Server 1 (Search Head) - Verify Data Flow

```spl
index=* earliest=-5m
| stats count by host, index
| sort - count
```

Should show data from forwarders appearing in indexes.

## Load Balancing (Future)

If you add more indexers later, update outputs.conf:

```ini
[tcpout:hap_indexers]
server = SERVER2:9997, SERVER3:9997, SERVER4:9997
autoLBFrequency = 30
```

Forwarders will automatically load balance across all indexers.

## SSL/TLS Encryption

To enable encrypted forwarding:

### 1. Generate Certificates

On Server 2 (indexer):
```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk createssl server-cert -d "C:\Program Files\Splunk\etc\auth"
```

### 2. Configure Indexer to Require SSL

On Server 2, edit `inputs.conf`:
```ini
[splunktcp-ssl:9997]
disabled = false
```

### 3. Update This App

Uncomment SSL settings in `outputs.conf`:
```ini
sslCertPath = $SPLUNK_HOME/etc/auth/server.pem
sslRootCAPath = $SPLUNK_HOME/etc/auth/ca.pem
sslVerifyServerCert = false
```

### 4. Push Updated App

Deployment server pushes SSL config to all forwarders.

## Moving the Indexer

If you move data ingestion to a different server:

1. Update `outputs.conf` with new indexer address
2. Reload deployment server:
   ```powershell
   .\splunk reload deploy-server -auth admin:password
   ```
3. Forwarders receive update on next check-in
4. Data flows to new indexer

## Troubleshooting

### Forwarder Can't Connect to Indexer

**Check network:**
```powershell
Test-NetConnection -ComputerName SERVER2 -Port 9997
```

**Check firewall on Server 2:**
```powershell
Get-NetFirewallRule | Where-Object {$_.LocalPort -eq 9997}
```

**Check outputs configuration:**
```powershell
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk btool outputs list
```

Verify `server` setting is correct.

### Data Not Appearing on Indexer

**Check forwarder internal logs:**
```spl
index=_internal host=FORWARDER_NAME sourcetype=splunkd component=TcpOutputProc
| head 20
```

Look for connection errors or blocks.

**Verify forwarder queue:**
```powershell
.\splunk list forwarding-info -auth admin:changeme
```

### Connection Timeouts

Increase timeout values in outputs.conf:
```ini
connectionTimeout = 60
readTimeout = 600
writeTimeout = 600
```

### High Network Usage

Data is already compressed (`compressed = true`), but you can:
- Adjust thruput limits per forwarder
- Filter data before forwarding (inputs.conf blacklists)
- Reduce logging volume at source

## Advanced Configuration

### Per-Index Routing

Send different indexes to different indexers:

```ini
[tcpout:production_indexers]
server = SERVER2:9997
indexAndForward = false

[tcpout:security_indexers]
server = SERVER3:9998
indexAndForward = false

# Route wineventlog and security to security indexers
[tcpout-index:wineventlog]
target_group = security_indexers

[tcpout-index:security]
target_group = security_indexers

# Everything else to production indexers
[tcpout:default_indexers]
defaultGroup = production_indexers
```

### Thruput Limiting

Limit forwarder bandwidth:
```ini
[tcpout]
maxKBps = 256  # 256 KB/s max throughput
```

## Related Apps

- **hap_add-on_deployment**: Connects forwarders to deployment server
- **hap_add-on_windows_inputs**: Windows event collection (Windows forwarders only)
- **hap_add-on_es_indexes**: Index definitions on Server 2

## Files in This App

```
hap_add-on_outputs/
├── default/
│   ├── app.conf        # App metadata
│   └── outputs.conf    # Forwarder output configuration
├── metadata/
│   └── default.meta    # Permissions
└── README.md           # This file
```

## Security Best Practices

1. **Use SSL/TLS** for encrypted forwarding in production
2. **Restrict port 9997** on Server 2 firewall to known forwarder IPs/subnets
3. **Monitor connection failures** via internal logs
4. **Validate certificate** if using SSL (sslVerifyServerCert = true)
5. **Rotate certificates** annually

---

**Last Updated:** 2024-11-17
