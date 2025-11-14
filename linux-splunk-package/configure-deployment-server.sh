#!/bin/bash

################################################################################
# Splunk Deployment Server Configuration Script
# Supports: Ubuntu/Debian and RHEL/CentOS
#
# This script configures Splunk as a deployment server for managing
# forwarder configurations
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
DEPLOYMENT_APPS_DIR="$SPLUNK_HOME/etc/deployment-apps"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DEPLOYMENT_APPS="$SCRIPT_DIR/deployment-apps"

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

log_info "Configuring Splunk Deployment Server..."
echo ""

# Prompt for admin credentials
log_info "Enter Splunk admin credentials"
read -p "Admin username [admin]: " SPLUNK_ADMIN_USER
SPLUNK_ADMIN_USER=${SPLUNK_ADMIN_USER:-admin}
read -sp "Admin password: " SPLUNK_ADMIN_PASSWORD
echo ""
echo ""

# Enable deployment server
log_info "Enabling deployment server..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk enable deploy-server -auth admin:$SPLUNK_ADMIN_PASSWORD

# Create deployment-apps directory structure
log_info "Creating deployment apps directory structure..."
mkdir -p $DEPLOYMENT_APPS_DIR

# Copy OCS deployment apps if they exist
if [ -d "$PACKAGE_DEPLOYMENT_APPS" ]; then
    log_info "Installing OCS deployment apps..."
    for app_dir in "$PACKAGE_DEPLOYMENT_APPS"/ocs_*; do
        if [ -d "$app_dir" ]; then
            app_name=$(basename "$app_dir")
            log_info "  Installing: $app_name"
            cp -r "$app_dir" "$DEPLOYMENT_APPS_DIR/"
        fi
    done

    # Configure OCS apps with server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')

    # Update ocs_add-on_deployment with deployment server IP
    if [ -f "$DEPLOYMENT_APPS_DIR/ocs_add-on_deployment/default/deploymentclient.conf" ]; then
        log_info "  Configuring ocs_add-on_deployment with deployment server IP: $SERVER_IP"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/DEPLOYMENT_SERVER_IP/$SERVER_IP/g" "$DEPLOYMENT_APPS_DIR/ocs_add-on_deployment/default/deploymentclient.conf"
        else
            sed -i "s/DEPLOYMENT_SERVER_IP/$SERVER_IP/g" "$DEPLOYMENT_APPS_DIR/ocs_add-on_deployment/default/deploymentclient.conf"
        fi
    fi

    # Update ocs_add-on_outputs with indexer IP
    if [ -f "$DEPLOYMENT_APPS_DIR/ocs_add-on_outputs/default/outputs.conf" ]; then
        log_info "  Configuring ocs_add-on_outputs with indexer IP: $SERVER_IP"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/INDEXER_IP/$SERVER_IP/g" "$DEPLOYMENT_APPS_DIR/ocs_add-on_outputs/default/outputs.conf"
        else
            sed -i "s/INDEXER_IP/$SERVER_IP/g" "$DEPLOYMENT_APPS_DIR/ocs_add-on_outputs/default/outputs.conf"
        fi
    fi
fi

# Create a base forwarder app for all Windows forwarders
log_info "Creating base Windows forwarder configuration app..."
WINDOWS_APP_DIR="$DEPLOYMENT_APPS_DIR/windows_forwarder_base"
mkdir -p $WINDOWS_APP_DIR/local
mkdir -p $WINDOWS_APP_DIR/metadata

# Create outputs.conf for forwarders
cat > $WINDOWS_APP_DIR/local/outputs.conf << 'EOF'
[tcpout]
defaultGroup = primary_indexers

[tcpout:primary_indexers]
server = SPLUNK_SERVER_IP:9997
compressed = true

[tcpout-server://SPLUNK_SERVER_IP:9997]
EOF

# Get the server IP and replace placeholder in outputs.conf
SERVER_IP=$(hostname -I | awk '{print $1}')

# Cross-platform sed (works on both Linux and macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/SPLUNK_SERVER_IP/$SERVER_IP/g" $WINDOWS_APP_DIR/local/outputs.conf
else
    sed -i "s/SPLUNK_SERVER_IP/$SERVER_IP/g" $WINDOWS_APP_DIR/local/outputs.conf
fi

log_info "Configured forwarders to send data to: $SERVER_IP:9997"

# Create inputs.conf for Windows forwarders
cat > $WINDOWS_APP_DIR/local/inputs.conf << 'EOF'
# Windows Event Logs
[WinEventLog://Application]
disabled = false
index = main
sourcetype = WinEventLog:Application

[WinEventLog://Security]
disabled = false
index = main
sourcetype = WinEventLog:Security

[WinEventLog://System]
disabled = false
index = main
sourcetype = WinEventLog:System

# Performance monitoring
[perfmon://CPU]
object = Processor
counters = % Processor Time; % User Time; % Privileged Time
instances = _Total
interval = 30
disabled = false
index = main

[perfmon://Memory]
object = Memory
counters = Available Bytes; Pages/sec; % Committed Bytes In Use
instances = *
interval = 30
disabled = false
index = main

[perfmon://LogicalDisk]
object = LogicalDisk
counters = % Free Space; Free Megabytes; Current Disk Queue Length; % Disk Time; Avg. Disk Queue Length
instances = *
interval = 30
disabled = false
index = main

[perfmon://Network]
object = Network Interface
counters = Bytes Total/sec; Packets/sec; Packets Received/sec; Packets Sent/sec
instances = *
interval = 30
disabled = false
index = main
EOF

# Create app.conf
cat > $WINDOWS_APP_DIR/local/app.conf << 'EOF'
[install]
state = enabled

[ui]
is_visible = false
is_manageable = false

[launcher]
author = Splunk Admin
description = Base configuration for Windows Universal Forwarders
version = 1.0
EOF

# Create default.meta
cat > $WINDOWS_APP_DIR/metadata/default.meta << 'EOF'
[]
access = read : [ * ], write : [ admin ]
export = system
EOF

# Create serverclass.conf for deployment server
log_info "Creating server class configuration..."
cat > $SPLUNK_HOME/etc/system/local/serverclass.conf << 'EOF'
[global]
whitelist.0 = *

# OCS Deployment Apps - All Forwarders
[serverClass:AllForwarders]
whitelist.0 = *

[serverClass:AllForwarders:app:ocs_add-on_deployment]
restartSplunkd = true
stateOnClient = enabled

[serverClass:AllForwarders:app:ocs_add-on_outputs]
restartSplunkd = true
stateOnClient = enabled

# OCS Windows Apps - Windows Forwarders (OS-based detection)
[serverClass:WindowsForwarders]
whitelist.0 = *
machineTypesFilter = windows-x64,windows-intel

[serverClass:WindowsForwarders:app:ocs_add-on_windows]
restartSplunkd = true
stateOnClient = enabled

# Legacy Windows Forwarder Base (if exists)
[serverClass:WindowsForwarders:app:windows_forwarder_base]
restartSplunkd = true
stateOnClient = enabled
EOF

# Set ownership
log_info "Setting file ownership..."
chown -R $SPLUNK_USER:$SPLUNK_GROUP $DEPLOYMENT_APPS_DIR
chown $SPLUNK_USER:$SPLUNK_GROUP $SPLUNK_HOME/etc/system/local/serverclass.conf

# Reload deployment server configuration
log_info "Reloading deployment server configuration..."
sudo -u $SPLUNK_USER $SPLUNK_HOME/bin/splunk reload deploy-server -auth admin:$SPLUNK_ADMIN_PASSWORD

log_info ""
log_info "========================================================"
log_info "Deployment Server Configuration Complete!"
log_info "========================================================"
log_info ""
log_info "Configuration Details:"
log_info "  Deployment Apps:  $DEPLOYMENT_APPS_DIR"
log_info "  Server Address:   $SERVER_IP"
log_info "  Indexer Port:     9997"
log_info ""
log_info "OCS Deployment Apps Installed:"
log_info "  ✓ ocs_add-on_deployment - Deployment client configuration"
log_info "  ✓ ocs_add-on_outputs - Forwarding configuration"
log_info "  ✓ ocs_add-on_windows - Windows Event Log collection"
log_info ""
log_info "Server Classes:"
log_info "  AllForwarders:"
log_info "    - Match: * (all forwarders)"
log_info "    - Apps: ocs_add-on_deployment, ocs_add-on_outputs"
log_info ""
log_info "  WindowsForwarders:"
log_info "    - Match: *-windows-*, *-win-*, WIN-*"
log_info "    - Apps: ocs_add-on_windows"
log_info ""
log_info "Windows Forwarder Configuration:"
log_info "  - Windows Event Logs (System, Security, Application)"
log_info "  - Sends to wineventlog index"
log_info "  - Auto-deployed to matching clients"
log_info ""
log_info "Useful Commands:"
log_info "  List clients:   sudo -u splunk $SPLUNK_HOME/bin/splunk list deploy-clients -auth admin:$SPLUNK_ADMIN_PASSWORD"
log_info "  Reload config:  sudo -u splunk $SPLUNK_HOME/bin/splunk reload deploy-server -auth admin:$SPLUNK_ADMIN_PASSWORD"
log_info ""
log_info "Next Steps:"
log_info "  1. Run: sudo ./install-addons.sh (if not already done)"
log_info "  2. Run: sudo ./setup-receiving.sh"
log_info "  3. Install forwarders on Windows clients"
log_info ""
