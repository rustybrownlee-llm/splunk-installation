#!/bin/bash

################################################################################
# Splunk Index Creation Script
# Supports: Ubuntu/Debian and RHEL/CentOS
#
# This script creates custom indexes for OCS add-ons and other use cases
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

# Check if Splunk is running
if ! sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk status | grep -q "splunkd is running"; then
    log_error "Splunk is not running. Please start Splunk first:"
    log_error "  sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk start"
    exit 1
fi

log_info "Creating custom indexes..."
log_info ""

# Prompt for admin credentials
read -p "Enter Splunk admin username [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -sp "Enter Splunk admin password: " ADMIN_PASSWORD
echo ""
echo ""

# Create wineventlog index
log_info "Creating 'wineventlog' index for Windows Event Logs..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk add index wineventlog \
    -auth $ADMIN_USER:$ADMIN_PASSWORD \
    -datatype event \
    2>/dev/null || log_warn "Index 'wineventlog' may already exist"

# Set retention and size for wineventlog (optional - adjust as needed)
log_info "Configuring wineventlog index settings..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk edit index wineventlog \
    -auth $ADMIN_USER:$ADMIN_PASSWORD \
    -maxTotalDataSizeMB 500000 \
    -frozenTimePeriodInSecs 2592000 \
    2>/dev/null || log_warn "Could not modify index settings (may already be configured)"

# You can add more indexes here as needed
# Example:
# log_info "Creating 'security' index..."
# sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk add index security \
#     -auth $ADMIN_USER:$ADMIN_PASSWORD \
#     -datatype event \
#     2>/dev/null || log_warn "Index 'security' may already exist"

log_info ""
log_info "========================================================"
log_info "Index Creation Complete!"
log_info "========================================================"
log_info ""
log_info "Created Indexes:"
log_info "  ✓ wineventlog - Windows Event Logs (500GB max, 30-day retention)"
log_info ""

# List all indexes
log_info "All configured indexes:"
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk list index -auth $ADMIN_USER:$ADMIN_PASSWORD 2>/dev/null | grep -E "^[[:space:]]*[a-zA-Z]" || true

log_info ""
log_info "Index Settings:"
log_info "  - Max Size: 500GB (500000 MB)"
log_info "  - Retention: 30 days (2592000 seconds)"
log_info "  - Type: Event data"
log_info ""
log_info "To view index details:"
log_info "  sudo -u splunk /opt/splunk/bin/splunk list index wineventlog -auth admin:password"
log_info ""
log_info "To search the index in Splunk Web:"
log_info "  index=wineventlog"
log_info ""
