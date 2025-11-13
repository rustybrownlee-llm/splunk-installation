#!/bin/bash

################################################################################
# Deploy Splunk Installation Files to VM
#
# This script copies necessary files from Mac to Ubuntu VM
# Excludes large/unnecessary files (vm/, iso/, .git/)
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Configuration - CHANGE THESE VALUES
VM_USER="splunkadmin"
VM_IP="192.168.64.2"
VM_TARGET_DIR="~/splunk-installation"

# Project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info "Splunk Installation VM Deployment Script"
log_info "=========================================="
log_info ""
log_info "Project Root: $PROJECT_ROOT"
log_info "Target VM:    $VM_USER@$VM_IP"
log_info "Target Dir:   $VM_TARGET_DIR"
log_info ""

# Verify we're in the right directory
if [ ! -f "$PROJECT_ROOT/INSTALLATION.md" ]; then
    log_error "Cannot find INSTALLATION.md - are you in the right directory?"
    exit 1
fi

# Check if VM is reachable
log_info "Testing connection to VM..."
if ! ping -c 1 -W 2 $VM_IP &> /dev/null; then
    log_warn "Cannot ping VM at $VM_IP - make sure VM is running"
    log_warn "Continuing anyway (ping might be blocked)..."
fi

# Test SSH connection
log_info "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $VM_USER@$VM_IP exit 2>/dev/null; then
    log_info "SSH key not set up - you'll need to enter password multiple times"
    log_info "To avoid this, set up SSH keys (see below)"
    log_info ""
fi

log_info "Creating target directory on VM..."
ssh $VM_USER@$VM_IP "mkdir -p $VM_TARGET_DIR"

cd "$PROJECT_ROOT"

log_info ""
log_info "Copying files to VM (this may take a few minutes)..."
log_info ""

# Copy scripts
log_info "1/5 Copying scripts..."
scp -r scripts $VM_USER@$VM_IP:$VM_TARGET_DIR/

# Copy downloads (largest, ~2GB)
log_info "2/5 Copying downloads (~2GB, will take 2-3 minutes)..."
scp -r downloads $VM_USER@$VM_IP:$VM_TARGET_DIR/

# Copy configs
log_info "3/5 Copying configs..."
scp -r configs $VM_USER@$VM_IP:$VM_TARGET_DIR/

# Copy windows-forwarders
log_info "4/5 Copying windows-forwarders..."
scp -r windows-forwarders $VM_USER@$VM_IP:$VM_TARGET_DIR/

# Copy documentation (production docs only, not VM setup guide)
log_info "5/5 Copying documentation..."
scp -r documents $VM_USER@$VM_IP:$VM_TARGET_DIR/
scp README.md $VM_USER@$VM_IP:$VM_TARGET_DIR/ 2>/dev/null || true

log_info ""
log_info "=========================================="
log_info "Deployment Complete!"
log_info "=========================================="
log_info ""
log_info "Files copied to: $VM_USER@$VM_IP:$VM_TARGET_DIR"
log_info ""
log_info "Next Steps:"
log_info "  1. SSH into VM:  ssh $VM_USER@$VM_IP"
log_info "  2. Navigate:     cd ~/splunk-installation/scripts"
log_info "  3. Make executable: chmod +x *.sh"
log_info "  4. Run install:  sudo ./install-splunk.sh"
log_info ""
log_info "To avoid entering password multiple times, set up SSH keys:"
log_info "  ssh-keygen -t ed25519 -C 'your_email@example.com'"
log_info "  ssh-copy-id $VM_USER@$VM_IP"
log_info ""
