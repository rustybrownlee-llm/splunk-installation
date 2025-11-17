# OCS Add-on: Outputs Configuration

## Purpose
Configures where Universal Forwarders send their collected data (indexer targets).

## What it does
- Defines the target indexer(s) for data forwarding
- Configures forwarding behavior (compression, SSL, timeouts)
- Sets up load balancing between multiple indexers (if configured)

## Configuration

### Basic Setup
Edit `default/outputs.conf` and replace `INDEXER_IP` with your indexer's IP address or hostname:

```ini
[tcpout:primary_indexers]
server = 192.168.1.10:9997
```

### Multiple Indexers (Load Balancing)
For multiple indexers, use comma-separated list:

```ini
[tcpout:primary_indexers]
server = 192.168.1.10:9997, 192.168.1.11:9997, 192.168.1.12:9997
autoLBFrequency = 30
```

### SSL/TLS Configuration
To enable encrypted forwarding, uncomment the SSL settings:

```ini
[tcpout:primary_indexers]
server = 192.168.1.10:9997
sslCertPath = $SPLUNK_HOME/etc/auth/server.pem
sslPassword = <encrypted_password>
sslVerifyServerCert = true
```

### Per-Forwarder Overrides
If a specific forwarder needs to send data to a different indexer:

1. On the forwarder, create: `$SPLUNK_HOME/etc/apps/ocs_add-on_outputs/local/outputs.conf`
2. Add the override configuration:
```ini
[tcpout:primary_indexers]
server = different-indexer:9997
```

## Important Notes
- Port 9997 is the default Splunk receiving port on indexers
- `indexAndForward = false` means forwarders only forward, they don't index locally
- `compressed = true` saves bandwidth during transmission
- Changes take effect after forwarder restart

## Deployment
Deploy via deployment server to all forwarders that need to send data to indexers.

## Version
1.0.0

## Author
OCS Admin
