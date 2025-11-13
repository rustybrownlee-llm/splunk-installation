#!/bin/bash

################################################################################
# Splunk Add-ons Installation Script
# Supports: Ubuntu/Debian and RHEL/CentOS
#
# This script installs all Splunk add-ons and apps in the correct order
# for CIM compliance and InfoSec App functionality
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOADS_DIR="$SCRIPT_DIR/downloads"

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

# Check if downloads directory exists
if [ ! -d "$DOWNLOADS_DIR" ]; then
    log_error "Downloads directory not found: $DOWNLOADS_DIR"
    exit 1
fi

log_info "Starting Splunk add-ons installation..."
log_info "Downloads directory: $DOWNLOADS_DIR"
log_info "Target directory: $SPLUNK_HOME/etc/apps/"
log_info ""

# Stop Splunk before installing apps
log_info "Stopping Splunk..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk stop

log_info ""
log_info "Installing OCS custom add-ons..."

# Install ocs_add-on_indexes (creates indexes on the Splunk server)
if [ -d "$SCRIPT_DIR/ocs_add-on_indexes" ]; then
    log_info "  Installing ocs_add-on_indexes (index definitions)..."
    cp -r "$SCRIPT_DIR/ocs_add-on_indexes" "$SPLUNK_HOME/etc/apps/"
else
    log_warn "  ocs_add-on_indexes not found, skipping"
fi

log_info ""
log_info "Extracting all add-ons to $SPLUNK_HOME/etc/apps/..."

# Count tarballs (both .tgz and .tar.gz)
TARBALL_COUNT=$(find "$DOWNLOADS_DIR" \( -name "*.tgz" -o -name "*.tar.gz" \) ! -name "*forwarder*" 2>/dev/null | wc -l)
log_info "Found $TARBALL_COUNT add-on packages to install"
log_info ""

# Extract all tarballs to Splunk apps directory
cd "$SPLUNK_HOME/etc/apps/"

# Process .tgz files
for tarball in "$DOWNLOADS_DIR"/*.tgz; do
    # Skip if glob didn't match any files
    [ -f "$tarball" ] || continue

    # Skip forwarder packages (those are for Windows clients, not server)
    if [[ "$tarball" == *"forwarder"* ]]; then
        continue
    fi

    filename=$(basename "$tarball")
    log_info "  Extracting: $filename"
    tar -xzf "$tarball" 2>&1 | grep -v "Ignoring unknown extended header keyword" >&2
done

# Process .tar.gz files
for tarball in "$DOWNLOADS_DIR"/*.tar.gz; do
    # Skip if glob didn't match any files
    [ -f "$tarball" ] || continue

    # Skip forwarder packages
    if [[ "$tarball" == *"forwarder"* ]]; then
        continue
    fi

    filename=$(basename "$tarball")
    log_info "  Extracting: $filename"
    tar -xzf "$tarball" 2>&1 | grep -v "Ignoring unknown extended header keyword" >&2
done

log_info ""
log_info "Configuring CIM add-on with data model acceleration..."

# Apply CIM local configuration for data model acceleration (for InfoSec App)
CIM_APP_DIR="$SPLUNK_HOME/etc/apps/Splunk_SA_CIM"
if [ -d "$CIM_APP_DIR" ] && [ -f "$SCRIPT_DIR/cim-local-config/datamodels.conf" ]; then
    log_info "  Enabling data model acceleration for InfoSec App..."
    mkdir -p "$CIM_APP_DIR/local"
    cp "$SCRIPT_DIR/cim-local-config/datamodels.conf" "$CIM_APP_DIR/local/"
    log_info "  ✓ Configured 8 data models for acceleration (Authentication, Endpoint, Network, etc.)"
else
    log_warn "  CIM add-on not found or config missing, skipping acceleration setup"
fi

log_info ""
log_info "Setting ownership to $SPLUNK_USER:$SPLUNK_USER..."
chown -R $SPLUNK_USER:$SPLUNK_USER "$SPLUNK_HOME/etc/apps/"

log_info ""
log_info "Starting Splunk to enable all apps..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk start

log_info ""
log_info "========================================================"
log_info "Add-ons Installation Complete!"
log_info "========================================================"
log_info ""
log_info "Installed Components:"
log_info "  ✓ OCS Index Definitions (wineventlog, os, network, web, security, application, database, email)"
log_info "  ✓ Splunk Common Information Model (CIM) with data model acceleration enabled"
log_info "  ✓ Network Security Add-ons (Cisco, Palo Alto)"
log_info "  ✓ Technology Add-ons (Windows, AD, Sysmon, Unix/Linux)"
log_info "  ✓ InfoSec App for Splunk"
log_info "  ✓ Visualization Apps"
log_info ""
log_info "Data Model Acceleration:"
log_info "  ✓ 8 CIM data models configured for acceleration (required by InfoSec App)"
log_info "  - Initial acceleration build will start automatically"
log_info "  - Build time depends on data volume (can take hours for large datasets)"
log_info "  - Check status: Settings → Data Models → [Model Name]"
log_info ""
log_info "Verify Installation:"
log_info "  1. Access Splunk Web: http://$(hostname -I | awk '{print $1}'):8000"
log_info "  2. Go to Apps → Manage Apps"
log_info "  3. Check that all apps are 'Enabled'"
log_info "  4. Go to Settings → Indexes to verify OCS indexes"
log_info ""
log_info "Next Steps:"
log_info "  1. Run: sudo ./configure-deployment-server.sh"
log_info "  2. Run: sudo ./setup-receiving.sh"
log_info ""
