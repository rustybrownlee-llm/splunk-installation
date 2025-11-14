#!/bin/bash

################################################################################
# Splunk Enterprise Installation Script
# Supports: Ubuntu/Debian (ufw) and RHEL/CentOS (firewalld)
#
# This script installs Splunk Enterprise and performs initial configuration
################################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration variables
SPLUNK_VERSION="10.0.1"
SPLUNK_BUILD="c486717c322b"
SPLUNK_HOME="/opt/splunk"
SPLUNK_USER="splunk"
SPLUNK_GROUP="splunk"
SPLUNK_ADMIN_USER="admin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Detect architecture and set appropriate filename
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        SPLUNK_FILENAME="splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-linux-amd64.tgz"
        log_info "Detected architecture: x86_64 (AMD64)"
        ;;
    aarch64|arm64)
        SPLUNK_FILENAME="splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-aarch64.tgz"
        log_info "Detected architecture: aarch64 (ARM64)"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        log_error "Supported architectures: x86_64, aarch64"
        exit 1
        ;;
esac

# Detect OS and set package manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
        log_info "Detected OS: $NAME $VERSION_ID"
    else
        log_error "Cannot detect OS. /etc/os-release not found"
        exit 1
    fi
}

# Detect and configure firewall
configure_firewall() {
    log_info "Configuring firewall..."

    # Check for firewalld (RHEL/CentOS)
    if command -v firewall-cmd &> /dev/null; then
        log_info "Detected firewalld"
        systemctl start firewalld 2>/dev/null || true
        systemctl enable firewalld 2>/dev/null || true

        firewall-cmd --permanent --add-port=8000/tcp --zone=public
        firewall-cmd --permanent --add-port=8089/tcp --zone=public
        firewall-cmd --permanent --add-port=9997/tcp --zone=public
        firewall-cmd --reload

        log_info "Firewall rules added (firewalld)"

    # Check for ufw (Ubuntu/Debian)
    elif command -v ufw &> /dev/null; then
        log_info "Detected ufw"

        ufw allow 8000/tcp comment 'Splunk Web'
        ufw allow 8089/tcp comment 'Splunk Management Port'
        ufw allow 9997/tcp comment 'Splunk Forwarder Receiving'

        log_info "Firewall rules added (ufw)"
    else
        log_warn "No supported firewall detected (ufw or firewalld)"
        log_warn "Please manually configure firewall for ports: 8000, 8089, 9997"
    fi
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Detect OS
detect_os

log_info "Starting Splunk Enterprise installation..."
log_info "Version: ${SPLUNK_VERSION}"
log_info "Build: ${SPLUNK_BUILD}"
echo ""

# Prompt for admin password
log_info "Set Splunk admin password"
echo ""
while true; do
    read -sp "Enter new admin password: " SPLUNK_ADMIN_PASSWORD
    echo ""
    read -sp "Confirm admin password: " SPLUNK_ADMIN_PASSWORD_CONFIRM
    echo ""

    if [ "$SPLUNK_ADMIN_PASSWORD" == "$SPLUNK_ADMIN_PASSWORD_CONFIRM" ]; then
        if [ ${#SPLUNK_ADMIN_PASSWORD} -lt 8 ]; then
            log_error "Password must be at least 8 characters"
            echo ""
        else
            log_info "✓ Password set"
            break
        fi
    else
        log_error "Passwords do not match. Please try again."
        echo ""
    fi
done
echo ""

# Check for required dependencies (no internet required)
log_info "Checking for required dependencies..."

MISSING_DEPS=""
for cmd in tar gzip; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    log_error "Missing required dependencies:$MISSING_DEPS"
    log_error "Please install these packages before running this script"
    exit 1
fi

log_info "All required dependencies found"

# Create Splunk user and group
if getent group "$SPLUNK_GROUP" &>/dev/null; then
    log_warn "Group $SPLUNK_GROUP already exists"
else
    log_info "Creating Splunk group..."
    groupadd -r $SPLUNK_GROUP
fi

if id "$SPLUNK_USER" &>/dev/null; then
    log_warn "User $SPLUNK_USER already exists, skipping creation"
else
    log_info "Creating Splunk user..."
    useradd -r -m -d /home/$SPLUNK_USER -s /bin/bash -g $SPLUNK_GROUP $SPLUNK_USER
fi

# Download Splunk
log_info "Checking for Splunk Enterprise package..."
cd /tmp

# Check if package exists in project downloads folder
if [ -f "$PROJECT_ROOT/downloads/$SPLUNK_FILENAME" ]; then
    log_info "Found Splunk package in project downloads folder"
    cp "$PROJECT_ROOT/downloads/$SPLUNK_FILENAME" /tmp/
    log_info "Copied to /tmp for installation"
elif [ -f "$SPLUNK_FILENAME" ]; then
    log_warn "Splunk package already exists in /tmp"
else
    log_error "Splunk package not found!"
    log_info "Expected location: $PROJECT_ROOT/downloads/$SPLUNK_FILENAME"
    log_info "Please download: ${SPLUNK_FILENAME}"
    log_info "Direct download:"
    echo "wget -O $PROJECT_ROOT/downloads/$SPLUNK_FILENAME 'https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/linux/${SPLUNK_FILENAME}'"
    exit 1
fi

# Extract Splunk
log_info "Extracting Splunk to /opt..."
tar xzf $SPLUNK_FILENAME -C /opt

# Set ownership
log_info "Setting file ownership..."
chown -R $SPLUNK_USER:$SPLUNK_GROUP $SPLUNK_HOME

# Create user-seed.conf with default password
log_info "Configuring admin password (default: ${SPLUNK_ADMIN_PASSWORD})..."
mkdir -p $SPLUNK_HOME/etc/system/local
cat > $SPLUNK_HOME/etc/system/local/user-seed.conf << EOF
[user_info]
USERNAME = $SPLUNK_ADMIN_USER
PASSWORD = $SPLUNK_ADMIN_PASSWORD
EOF

chown $SPLUNK_USER:$SPLUNK_GROUP $SPLUNK_HOME/etc/system/local/user-seed.conf
chmod 600 $SPLUNK_HOME/etc/system/local/user-seed.conf

# Accept license and start Splunk
log_info "Starting Splunk for the first time..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk start --accept-license --answer-yes --no-prompt

# Enable boot-start
log_info "Enabling Splunk to start at boot..."
$SPLUNK_HOME/bin/splunk enable boot-start -user $SPLUNK_USER --accept-license --answer-yes

# Configure firewall
configure_firewall

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Display status
log_info ""
log_info "========================================================"
log_info "Splunk Enterprise Installation Complete!"
log_info "========================================================"
log_info ""
log_info "Installation Details:"
log_info "  Splunk Home:    $SPLUNK_HOME"
log_info "  Splunk User:    $SPLUNK_USER"
log_info "  Splunk Group:   $SPLUNK_GROUP"
log_info ""
log_info "Access Information:"
log_info "  Splunk Web:     http://${SERVER_IP}:8000"
log_info "  Username:       admin"
log_info "  Password:       ${SPLUNK_ADMIN_PASSWORD}"
log_info ""
log_info "IMPORTANT: Change the default password after first login!"
log_info ""
log_info "Open Ports:"
log_info "  8000 - Splunk Web Interface"
log_info "  8089 - Management/Deployment Server Port"
log_info "  9997 - Forwarder Receiving Port"
log_info ""
log_info "Next Steps:"
log_info "  1. Access Splunk Web and change admin password"
log_info "  2. Run: sudo ./configure-deployment-server.sh"
log_info "  3. Run: sudo ./install-addons.sh"
log_info "  4. Run: sudo ./setup-receiving.sh"
log_info ""
log_info "Common Commands:"
log_info "  Start:   sudo -u splunk $SPLUNK_HOME/bin/splunk start"
log_info "  Stop:    sudo -u splunk $SPLUNK_HOME/bin/splunk stop"
log_info "  Restart: sudo -u splunk $SPLUNK_HOME/bin/splunk restart"
log_info "  Status:  sudo -u splunk $SPLUNK_HOME/bin/splunk status"
log_info ""
