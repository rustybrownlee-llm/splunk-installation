#!/bin/bash

################################################################################
# Splunk Certificate Generation Script
# Supports: Self-signed certificates OR Local CA approach
#
# Use Case 1: Self-signed (Quick, for lab/testing)
# Use Case 2: Local CA (Professional, for production without domain CA)
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
CERT_DIR="$SPLUNK_HOME/etc/auth/mycerts"
CA_DIR="$SPLUNK_HOME/etc/auth/ca"
VALIDITY_DAYS=3650  # 10 years

# Detect server information
SERVER_HOSTNAME=$(hostname -f 2>/dev/null || hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')

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

log_section "Splunk Certificate Generation"
echo ""
log_info "Detected server information:"
log_info "  Hostname: $SERVER_HOSTNAME"
log_info "  IP Address: $SERVER_IP"
echo ""

# Ask for certificate approach
echo "Certificate Generation Options:"
echo ""
echo "1) Self-Signed Certificate"
echo "   - Quick and simple"
echo "   - Browser will show security warnings"
echo "   - Good for: Lab environments, quick testing"
echo ""
echo "2) Local Certificate Authority (Recommended)"
echo "   - Create your own CA, sign server certificates"
echo "   - Distribute CA cert to clients for trust"
echo "   - Good for: Production without domain CA, PS deliveries"
echo ""
read -p "Select option (1 or 2): " CERT_TYPE

case $CERT_TYPE in
    1)
        CERT_APPROACH="selfsigned"
        log_info "Selected: Self-Signed Certificate"
        ;;
    2)
        CERT_APPROACH="localca"
        log_info "Selected: Local Certificate Authority"
        ;;
    *)
        log_error "Invalid selection"
        exit 1
        ;;
esac

echo ""
log_section "Certificate Details"
echo ""

# Prompt for certificate details with defaults
read -p "Organization Name [Splunk Deployment]: " ORG_NAME
ORG_NAME=${ORG_NAME:-"Splunk Deployment"}

read -p "Organizational Unit [IT Security]: " ORG_UNIT
ORG_UNIT=${ORG_UNIT:-"IT Security"}

read -p "City [New York]: " CITY
CITY=${CITY:-"New York"}

read -p "State [NY]: " STATE
STATE=${STATE:-"NY"}

read -p "Country Code (2 letters) [US]: " COUNTRY
COUNTRY=${COUNTRY:-"US"}

read -p "Server DNS name [$SERVER_HOSTNAME]: " CERT_HOSTNAME
CERT_HOSTNAME=${CERT_HOSTNAME:-$SERVER_HOSTNAME}

read -p "Server IP address [$SERVER_IP]: " CERT_IP
CERT_IP=${CERT_IP:-$SERVER_IP}

echo ""
log_info "Certificate will include:"
log_info "  Common Name (CN): $CERT_HOSTNAME"
log_info "  Subject Alternative Names:"
log_info "    - DNS: $CERT_HOSTNAME"
log_info "    - IP: $CERT_IP"
echo ""

# Create certificate directories
mkdir -p "$CERT_DIR"
mkdir -p "$CA_DIR"

################################################################################
# Function: Generate Local CA
################################################################################
generate_local_ca() {
    log_section "Generating Local Certificate Authority"

    CA_KEY="$CA_DIR/ca-key.pem"
    CA_CERT="$CA_DIR/ca-cert.pem"

    if [ -f "$CA_CERT" ]; then
        log_warn "CA certificate already exists at $CA_CERT"
        read -p "Overwrite existing CA? This will invalidate all previously signed certificates! (yes/no): " OVERWRITE
        if [ "$OVERWRITE" != "yes" ]; then
            log_info "Using existing CA certificate"
            return 0
        fi
    fi

    log_info "Creating CA private key..."
    openssl genrsa -out "$CA_KEY" 4096

    log_info "Creating CA certificate..."
    openssl req -new -x509 -days $VALIDITY_DAYS -key "$CA_KEY" -out "$CA_CERT" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG_NAME/OU=$ORG_UNIT/CN=Splunk Local CA"

    log_info "✓ CA certificate created: $CA_CERT"
    log_info "✓ CA private key: $CA_KEY"
    echo ""
    log_warn "IMPORTANT: Distribute $CA_CERT to all clients that need to trust this Splunk server"
    echo ""
}

################################################################################
# Function: Generate Server Certificate (CA-signed)
################################################################################
generate_ca_signed_cert() {
    log_section "Generating CA-Signed Server Certificate"

    SERVER_KEY="$CERT_DIR/server-key.pem"
    SERVER_CSR="$CERT_DIR/server-csr.pem"
    SERVER_CERT="$CERT_DIR/server-cert.pem"

    CA_KEY="$CA_DIR/ca-key.pem"
    CA_CERT="$CA_DIR/ca-cert.pem"

    log_info "Creating server private key..."
    openssl genrsa -out "$SERVER_KEY" 2048

    log_info "Creating certificate signing request (CSR)..."
    openssl req -new -key "$SERVER_KEY" -out "$SERVER_CSR" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG_NAME/OU=$ORG_UNIT/CN=$CERT_HOSTNAME"

    # Create extensions file for SAN
    cat > "$CERT_DIR/server-ext.cnf" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CERT_HOSTNAME
IP.1 = $CERT_IP
EOF

    log_info "Signing server certificate with CA..."
    openssl x509 -req -in "$SERVER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
        -CAcreateserial -out "$SERVER_CERT" -days $VALIDITY_DAYS \
        -extfile "$CERT_DIR/server-ext.cnf"

    # Create combined PEM (Splunk format)
    cat "$SERVER_CERT" "$SERVER_KEY" "$CA_CERT" > "$CERT_DIR/server-combined.pem"

    log_info "✓ Server certificate: $SERVER_CERT"
    log_info "✓ Server private key: $SERVER_KEY"
    log_info "✓ Combined PEM (for Splunk): $CERT_DIR/server-combined.pem"
}

################################################################################
# Function: Generate Self-Signed Certificate
################################################################################
generate_selfsigned_cert() {
    log_section "Generating Self-Signed Certificate"

    SERVER_KEY="$CERT_DIR/server-key.pem"
    SERVER_CERT="$CERT_DIR/server-cert.pem"

    log_info "Creating self-signed certificate..."

    # Create extensions file for SAN
    cat > "$CERT_DIR/server-ext.cnf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C=$COUNTRY
ST=$STATE
L=$CITY
O=$ORG_NAME
OU=$ORG_UNIT
CN=$CERT_HOSTNAME

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CERT_HOSTNAME
IP.1 = $CERT_IP
EOF

    openssl req -x509 -nodes -days $VALIDITY_DAYS \
        -newkey rsa:2048 -keyout "$SERVER_KEY" -out "$SERVER_CERT" \
        -config "$CERT_DIR/server-ext.cnf"

    # Create combined PEM (Splunk format)
    cat "$SERVER_CERT" "$SERVER_KEY" > "$CERT_DIR/server-combined.pem"

    log_info "✓ Self-signed certificate: $SERVER_CERT"
    log_info "✓ Server private key: $SERVER_KEY"
    log_info "✓ Combined PEM (for Splunk): $CERT_DIR/server-combined.pem"
}

################################################################################
# Main execution
################################################################################

if [ "$CERT_APPROACH" == "localca" ]; then
    generate_local_ca
    generate_ca_signed_cert

    echo ""
    log_section "Certificate Authority Summary"
    echo ""
    log_info "CA Certificate (distribute to clients):"
    log_info "  Location: $CA_DIR/ca-cert.pem"
    echo ""
    log_info "  View certificate:"
    log_info "    openssl x509 -in $CA_DIR/ca-cert.pem -text -noout"
    echo ""
    log_warn "Next Steps:"
    log_warn "  1. Distribute ca-cert.pem to Windows clients for browser trust"
    log_warn "  2. Install ca-cert.pem in browser/OS trust store"
    log_warn "  3. Run configure-ssl.sh to enable HTTPS on Splunk Web"

else
    generate_selfsigned_cert

    echo ""
    log_section "Self-Signed Certificate Summary"
    echo ""
    log_warn "Note: Browsers will show security warnings with self-signed certificates"
    log_warn "Users must manually accept the certificate or add an exception"
    echo ""
    log_info "Next Steps:"
    log_info "  1. Run configure-ssl.sh to enable HTTPS on Splunk Web"
fi

echo ""
log_section "Server Certificate Summary"
echo ""
log_info "Certificate for Splunk Web (HTTPS):"
log_info "  Location: $CERT_DIR/server-combined.pem"
echo ""
log_info "View certificate details:"
log_info "  openssl x509 -in $CERT_DIR/server-cert.pem -text -noout | head -20"
echo ""

# Set ownership
chown -R splunk:splunk "$SPLUNK_HOME/etc/auth"
chmod 600 "$CERT_DIR"/*.pem
chmod 600 "$CA_DIR"/*.pem 2>/dev/null || true

log_info "✓ Certificate permissions set correctly"
echo ""
log_info "Certificate generation complete!"
echo ""
