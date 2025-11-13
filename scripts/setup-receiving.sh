#!/bin/bash

################################################################################
# Splunk Receiving Port Configuration Script
# Supports: Ubuntu/Debian (ufw) and RHEL/CentOS (firewalld)
#
# This script configures Splunk to receive data from forwarders on port 9997
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
SPLUNK_HOME="/opt/splunk"
SPLUNK_USER="splunk"
SPLUNK_GROUP="splunk"
SPLUNK_ADMIN_PASSWORD="5plunk#1!"
RECEIVING_PORT="9997"

# Detect and configure firewall
configure_firewall() {
    log_info "Configuring firewall for port $RECEIVING_PORT..."

    # Check for firewalld (RHEL/CentOS)
    if command -v firewall-cmd &> /dev/null; then
        log_info "Detected firewalld"
        systemctl start firewalld 2>/dev/null || true
        systemctl enable firewalld 2>/dev/null || true

        firewall-cmd --permanent --add-port=$RECEIVING_PORT/tcp --zone=public
        firewall-cmd --reload

        log_info "Firewall rule added (firewalld)"

    # Check for ufw (Ubuntu/Debian)
    elif command -v ufw &> /dev/null; then
        log_info "Detected ufw"
        ufw allow $RECEIVING_PORT/tcp comment 'Splunk Forwarder Receiving'
        log_info "Firewall rule added (ufw)"
    else
        log_warn "No supported firewall detected"
        log_warn "Manually configure firewall for port: $RECEIVING_PORT"
    fi
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if Splunk is installed
if [ ! -d "$SPLUNK_HOME" ]; then
    log_error "Splunk not found at $SPLUNK_HOME"
    log_error "Please run install-splunk.sh first"
    exit 1
fi

log_info "Configuring Splunk to receive data from forwarders..."

# Enable receiving on port 9997
log_info "Enabling receiving port $RECEIVING_PORT..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk enable listen $RECEIVING_PORT -auth admin:$SPLUNK_ADMIN_PASSWORD

# Create inputs.conf for additional receiving configuration
log_info "Creating inputs configuration..."
mkdir -p $SPLUNK_HOME/etc/system/local

cat > $SPLUNK_HOME/etc/system/local/inputs.conf << 'EOF'
[splunktcp://9997]
disabled = false
connection_host = ip

[splunktcp]
route = has_key:_INDEX_AND_FORWARD_ROUTING:parsingQueue;parsingQueue
EOF

chown $SPLUNK_USER:$SPLUNK_GROUP $SPLUNK_HOME/etc/system/local/inputs.conf

# Configure index settings
log_info "Configuring indexes..."
cat > $SPLUNK_HOME/etc/system/local/indexes.conf << 'EOF'
[default]
# Increased default index sizes for production use
maxTotalDataSizeMB = 500000
frozenTimePeriodInSecs = 2592000

[main]
# Main index for general data
homePath = $SPLUNK_DB/main/db
coldPath = $SPLUNK_DB/main/colddb
thawedPath = $SPLUNK_DB/main/thaweddb
maxTotalDataSizeMB = 250000

[wineventlog]
# Windows Event Logs
homePath = $SPLUNK_DB/wineventlog/db
coldPath = $SPLUNK_DB/wineventlog/colddb
thawedPath = $SPLUNK_DB/wineventlog/thaweddb
maxTotalDataSizeMB = 100000

[perfmon]
# Windows Performance Monitor data
homePath = $SPLUNK_DB/perfmon/db
coldPath = $SPLUNK_DB/perfmon/colddb
thawedPath = $SPLUNK_DB/perfmon/thaweddb
maxTotalDataSizeMB = 50000
EOF

chown $SPLUNK_USER:$SPLUNK_GROUP $SPLUNK_HOME/etc/system/local/indexes.conf

# Configure firewall
configure_firewall

# Restart Splunk to apply changes
log_info "Restarting Splunk to apply receiving configuration..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk restart

# Verify receiving is enabled
log_info "Verifying receiving port status..."
sleep 5

SERVER_IP=$(hostname -I | awk '{print $1}')

# Check if port is listening
if netstat -tuln 2>/dev/null | grep -q $RECEIVING_PORT; then
    log_info "Port $RECEIVING_PORT is listening"
elif ss -tuln 2>/dev/null | grep -q $RECEIVING_PORT; then
    log_info "Port $RECEIVING_PORT is listening"
else
    log_warn "Port $RECEIVING_PORT may not be listening yet (check after Splunk fully starts)"
fi

log_info ""
log_info "========================================================"
log_info "Receiving Port Configuration Complete!"
log_info "========================================================"
log_info ""
log_info "Listening Address:"
log_info "  $SERVER_IP:$RECEIVING_PORT"
log_info ""
log_info "Configured Indexes:"
log_info "  - main         (General data, 250GB max)"
log_info "  - wineventlog  (Windows event logs, 100GB max)"
log_info "  - perfmon      (Performance data, 50GB max)"
log_info ""
log_info "Verification Commands:"
log_info "  Check receiving:   sudo -u splunk $SPLUNK_HOME/bin/splunk list inputstatus -auth admin:$SPLUNK_ADMIN_PASSWORD"
log_info "  Check forwarders:  sudo -u splunk $SPLUNK_HOME/bin/splunk list deploy-clients -auth admin:$SPLUNK_ADMIN_PASSWORD"
log_info ""
log_info "Splunk Web:"
log_info "  1. Go to: http://$SERVER_IP:8000"
log_info "  2. Settings → Forwarding and receiving"
log_info "  3. Click 'Configure receiving' to see port status"
log_info "  4. Settings → Monitoring Console → Forwarders to see connected clients"
log_info ""
log_info "Next Step:"
log_info "  Install Universal Forwarders on Windows/Linux clients"
log_info "  See: ../windows-forwarders/README.md"
log_info ""
