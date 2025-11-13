#!/bin/bash

################################################################################
# Splunk SSL Configuration Script
# Configures HTTPS for Splunk Web using generated certificates
################################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
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

log_section() {
    echo -e "${BLUE}[====] $1 [====]${NC}"
}

# Configuration
SPLUNK_HOME="/opt/splunk"
SPLUNK_USER="splunk"
CERT_FILE="$SPLUNK_HOME/etc/auth/mycerts/server-combined.pem"
SERVER_CONF="$SPLUNK_HOME/etc/system/local/server.conf"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if Splunk is installed
if [ ! -d "$SPLUNK_HOME" ]; then
    log_error "Splunk not found at $SPLUNK_HOME"
    exit 1
fi

# Check if certificate exists
if [ ! -f "$CERT_FILE" ]; then
    log_error "Certificate not found at $CERT_FILE"
    log_error "Please run generate-certificates.sh first"
    exit 1
fi

log_section "Splunk Web SSL Configuration"
echo ""

# Get server IP for display
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_HOSTNAME=$(hostname -f 2>/dev/null || hostname)

log_info "Server information:"
log_info "  Hostname: $SERVER_HOSTNAME"
log_info "  IP: $SERVER_IP"
log_info "  Certificate: $CERT_FILE"
echo ""

# Ask for HTTP behavior
echo "HTTP Port Configuration:"
echo ""
echo "1) Enable HTTPS (port 8000) and disable HTTP"
echo "   - Most secure"
echo "   - Recommended for production"
echo ""
echo "2) Enable HTTPS (port 8000) and keep HTTP enabled"
echo "   - Both HTTP and HTTPS available"
echo "   - Good for transition period"
echo ""
read -p "Select option (1 or 2) [1]: " HTTP_OPTION
HTTP_OPTION=${HTTP_OPTION:-1}

if [ "$HTTP_OPTION" == "1" ]; then
    ENABLE_SSL_ONLY="true"
    log_info "Selected: HTTPS only (HTTP disabled)"
else
    ENABLE_SSL_ONLY="false"
    log_info "Selected: Both HTTP and HTTPS enabled"
fi

echo ""
log_section "Configuring Splunk Web"

# Backup existing server.conf
if [ -f "$SERVER_CONF" ]; then
    log_info "Backing up existing server.conf..."
    cp "$SERVER_CONF" "$SERVER_CONF.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Stop Splunk
log_info "Stopping Splunk..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk stop

# Configure SSL in server.conf
log_info "Updating server.conf with SSL configuration..."

# Remove existing [sslConfig] and [settings] sections to avoid duplicates
if [ -f "$SERVER_CONF" ]; then
    # Create temp file without SSL sections
    grep -v "^\[sslConfig\]" "$SERVER_CONF" | grep -v "^serverCert" | grep -v "^sslVersions" | grep -v "^cipherSuite" | grep -v "^ecdhCurves" > "$SERVER_CONF.tmp" || true
    mv "$SERVER_CONF.tmp" "$SERVER_CONF"
fi

# Add SSL configuration
cat >> "$SERVER_CONF" << EOF

# SSL Configuration for Splunk Web
[sslConfig]
serverCert = $CERT_FILE
sslVersions = tls1.2, tls1.3
# Modern cipher suite (supports TLS 1.2 and 1.3)
cipherSuite = ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
ecdhCurves = prime256v1, secp384r1, secp521r1

[settings]
enableSplunkdSSL = true
EOF

if [ "$ENABLE_SSL_ONLY" == "true" ]; then
    echo "startwebserver = 0" >> "$SERVER_CONF"
    log_info "✓ HTTP disabled, HTTPS only"
else
    log_info "✓ Both HTTP and HTTPS enabled"
fi

# Ensure proper [webSettings] configuration for HTTPS
WEB_CONF="$SPLUNK_HOME/etc/system/local/web.conf"

if [ ! -f "$WEB_CONF" ]; then
    cat > "$WEB_CONF" << EOF
[settings]
enableSplunkWebSSL = true
privKeyPath = $CERT_FILE
serverCert = $CERT_FILE
EOF
    log_info "✓ Created web.conf with SSL settings"
else
    # Update existing web.conf
    if ! grep -q "enableSplunkWebSSL" "$WEB_CONF"; then
        cat >> "$WEB_CONF" << EOF

[settings]
enableSplunkWebSSL = true
privKeyPath = $CERT_FILE
serverCert = $CERT_FILE
EOF
        log_info "✓ Updated web.conf with SSL settings"
    fi
fi

# Set ownership
chown splunk:splunk "$SERVER_CONF"
chown splunk:splunk "$WEB_CONF"

# Start Splunk
log_info "Starting Splunk..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk start

echo ""
log_section "SSL Configuration Complete!"
echo ""

if [ "$ENABLE_SSL_ONLY" == "true" ]; then
    log_info "Splunk Web is now available at:"
    log_info "  https://$SERVER_IP:8000"
    log_info "  https://$SERVER_HOSTNAME:8000"
    echo ""
    log_warn "HTTP access (port 8000) has been disabled"
else
    log_info "Splunk Web is now available at:"
    log_info "  HTTP:  http://$SERVER_IP:8000"
    log_info "  HTTPS: https://$SERVER_IP:8000"
    echo ""
    log_warn "Both HTTP and HTTPS are enabled"
    log_warn "Consider disabling HTTP after testing HTTPS"
fi

echo ""
log_info "Testing HTTPS connection..."
sleep 5

if curl -k -s "https://$SERVER_IP:8000/en-US/account/login" > /dev/null 2>&1; then
    log_info "✓ HTTPS is responding correctly"
else
    log_warn "Could not verify HTTPS connection"
    log_warn "This may be normal if firewall is blocking external connections"
fi

echo ""
log_section "Certificate Information"
echo ""
log_info "View certificate details:"
log_info "  openssl s_client -connect $SERVER_IP:8000 -showcerts < /dev/null 2>/dev/null | openssl x509 -text -noout | head -20"
echo ""

# If using local CA, remind about distribution
if [ -f "$SPLUNK_HOME/etc/auth/ca/ca-cert.pem" ]; then
    log_section "Next Steps: CA Certificate Distribution"
    echo ""
    log_warn "You are using a local CA. To avoid browser warnings:"
    echo ""
    log_info "1. Distribute CA certificate to all users:"
    log_info "   Location: $SPLUNK_HOME/etc/auth/ca/ca-cert.pem"
    echo ""
    log_info "2. Windows: Import ca-cert.pem to 'Trusted Root Certification Authorities'"
    log_info "   - Double-click ca-cert.pem"
    log_info "   - Install Certificate → Local Machine"
    log_info "   - Place in: Trusted Root Certification Authorities"
    echo ""
    log_info "3. macOS: Add ca-cert.pem to System Keychain and set to 'Always Trust'"
    echo ""
    log_info "4. Linux: Copy to /usr/local/share/ca-certificates/ and run update-ca-certificates"
    echo ""
fi

log_info "SSL configuration complete!"
echo ""
