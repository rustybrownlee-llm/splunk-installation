# Ubuntu Linux VM Setup Guide

Create an Ubuntu Server VM using UTM on macOS for Splunk Enterprise testing.

## Prerequisites

- ✅ UTM installed (via Homebrew: `brew install utm`)
- ✅ Ubuntu Server 22.04 ARM64 ISO in `iso/` folder
- 💻 M4 Max MacBook Pro (or other Apple Silicon Mac)

## VM Specifications

| Resource | Value | Purpose |
|----------|-------|---------|
| RAM | 8 GB | Splunk + indexes + apps |
| CPU Cores | 4 | Indexing and search performance |
| Disk | 80 GB | Splunk installation + data |
| OS | Ubuntu Server 22.04 ARM64 | Lightweight, production-like |

## Step 1: Create VM in UTM

### Launch UTM
```bash
open -a UTM
```
Or: Applications → UTM

### Create New Virtual Machine

1. Click **"Create a New Virtual Machine"**
2. Select **"Virtualize"** (for ARM64 native performance)

### Configure Operating System

3. Select **"Linux"**
4. Click **"Browse"** and navigate to:
   ```
   /Users/rustybrownlee/Development/splunk-installation/iso/ubuntu-22.04.5-live-server-arm64.iso
   ```

### Hardware Configuration

5. **Memory**: Set to **8192 MB (8 GB)**
6. **CPU Cores**: Set to **4**

### Storage

7. **Storage Size**: Set to **80 GB**
8. **Storage Type**: Keep default (qcow2)

### Shared Directory (Optional)

9. Click **"Add"** under Shared Directory
10. Browse and select: `/Users/rustybrownlee/Development/splunk-installation/scripts`
11. This allows easy file transfer between Mac and VM

### Name and Save

12. **VM Name**: `splunk-server`
13. ✅ Check **"Open VM Settings"**
14. Click **"Save"**

### VM Settings Adjustments

15. In settings window, go to **"QEMU"** section
16. Ensure **"UEFI Boot"** is enabled
17. Click **"Save"**

### Optional: Move VM to Project Folder

To keep everything self-contained:

18. Close UTM completely
19. Open Finder: `~/Library/Containers/com.utmapp.UTM/Data/Documents/`
20. Move `splunk-server.utm` to: `/Users/rustybrownlee/Development/splunk-installation/vm/`
21. Reopen UTM
22. Click **"+"** → **"Open Existing VM"**
23. Navigate to and select the moved VM

## Step 2: Install Ubuntu

### Start Installation

1. Select the VM in UTM
2. Click **▶️ Play** button
3. Wait for Ubuntu installer to load (1-2 minutes)

### Ubuntu Installation Prompts

**Language:**
- Select: **English** (or your preference)

**Keyboard:**
- Select your keyboard layout
- **Continue**

**Type of Install:**
- Select: **Ubuntu Server (minimized)** ← Use this for cleaner install
- **Continue**

**Network:**
- Accept default (DHCP automatic)
- Note the IP address shown (usually 192.168.64.x)
- **Continue**

**Proxy:**
- Leave blank unless needed
- **Continue**

**Mirror:**
- Accept default Ubuntu archive mirror
- **Continue**

**Storage:**
- Select: **Use entire disk**
- Accept default partition layout
- **Continue**
- Confirm: **Continue**

**Profile Setup:**
- Your name: **splunkadmin** (or your preference)
- Server name: **splunk-server**
- Username: **splunkadmin**
- Password: [Choose a secure password - you'll use this often]
- **Continue**

**SSH Setup:**
- ✅ **Check "Install OpenSSH server"** ← IMPORTANT!
- **Continue**

**Featured Server Snaps:**
- Skip all (press **Done** without selecting anything)

**Installation:**
- Wait 5-10 minutes for installation to complete
- You'll see packages being installed

## Step 3: CRITICAL - Remove ISO Before Rebooting

When you see **"Installation complete!"** screen:

### ⚠️ DO NOT Click "Reboot Now" Yet!

1. **Switch to UTM window** (keep installer screen visible)
2. Click **"Stop"** button (⏹️) to force stop the VM
3. Click **"OK"** on the "lose unsaved data" dialog (installation is already saved)
4. Click **VM settings** (⚙️ icon)
5. Scroll to bottom → **"CD/DVD"** dropdown
6. Click dropdown → Select **"Clear"**
7. Click **"Save"**
8. Click **▶️ Start** to boot the VM

### First Boot

9. VM should boot to Ubuntu login prompt in 1-2 minutes
10. **If it returns to installer**: ISO wasn't removed, repeat steps above
11. **If it hangs >3 minutes**: See Troubleshooting section below

## Step 4: Post-Install Configuration

### Login

```
splunk-server login: splunkadmin
Password: [your password]
```

### Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Install Useful Tools

```bash
sudo apt install -y curl wget net-tools vim
```

### Get IP Address

```bash
ip addr show
```

Look for IP under `enp0s1` or similar interface (usually `192.168.64.x`)

**Write this down!** You'll need it for:
- SSH connections
- Windows forwarder config.ps1
- Accessing Splunk Web

### Set Up SSH Keys (Recommended)

For passwordless SSH access from your Mac, see: **`../documents/SSH-KEYS-SETUP.md`**

Quick version from your **Mac terminal**:
```bash
ssh-copy-id splunkadmin@192.168.64.2
```

Replace `192.168.64.2` with your VM's IP address.

## Step 5: Deploy Splunk Files to VM

From your **Mac terminal**:

### Option A: Use Deployment Script (Recommended)

```bash
cd /Users/rustybrownlee/Development/splunk-installation/scripts
./deploy-to-vm.sh
```

The script automatically copies all needed files.

### Option B: Manual SCP

```bash
# Create directory on VM
ssh splunkadmin@192.168.64.2 'mkdir -p ~/splunk-installation'

# Copy project files
cd /Users/rustybrownlee/Development/splunk-installation
scp -r scripts downloads configs documents splunkadmin@192.168.64.2:~/splunk-installation/
```

## Step 6: Take Snapshot (Important!)

Before installing Splunk, create a snapshot:

1. In UTM, **right-click** the VM
2. Select **"Manage Snapshots"**
3. Click **"Create Snapshot"**
4. Name: **"pre-splunk-install"**
5. Click **"Save"**

**Why?** You can revert to this clean state if anything goes wrong during Splunk installation.

## Next Steps

You're now ready to install Splunk! See `documents/INSTALLATION.md`

Quick start:
```bash
ssh splunkadmin@192.168.64.2
cd ~/splunk-installation/scripts
chmod +x *.sh
sudo ./install-splunk.sh
```

## VM Management

### Using UTM GUI

- **Start**: Select VM → Click ▶️
- **Stop**: Select VM → Click ⏹️
- **Force Stop**: Stop button → Hold Option key
- **Snapshots**: Right-click VM → Manage Snapshots

### Using utmctl (Terminal)

```bash
# List VMs
utmctl list

# Start VM
utmctl start "splunk-server"

# Stop VM
utmctl stop "splunk-server"

# Check status
utmctl status "splunk-server"

# Get IP (requires guest tools)
utmctl ip-address "splunk-server"
```

## Troubleshooting

### VM Boots Back to Installer

**Problem**: After installation, VM shows Ubuntu installer again instead of login prompt.

**Cause**: ISO still mounted in CD/DVD drive.

**Solution**:
1. Force stop VM
2. VM Settings → CD/DVD dropdown → "Clear"
3. Start VM

**Prevention**: Always remove ISO before rebooting after installation.

### VM Hangs on Boot

**Problem**: Black screen or "A start job is running for..." message for >3 minutes.

**Solutions**:

**1. Network Wait Timeout (Most Common)**
```bash
# Let it timeout (2-3 minutes), then after login:
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
```

**2. Boot in Verbose Mode to See Error**
- When GRUB menu appears, press **'e'**
- Find line starting with `linux`
- Remove words `quiet` and `splash`
- Press **Ctrl+X** to boot
- Watch for errors

**3. ISO Still Mounted**
- See "VM Boots Back to Installer" above

### Can't SSH to VM

**Check VM is running:**
```bash
utmctl status "splunk-server"
```

**Check IP address:**
- In VM console: `ip addr show`
- From Mac: `ping 192.168.64.2`

**Check SSH service:**
```bash
# In VM console
sudo systemctl status sshd
```

**If not installed:**
```bash
sudo apt install openssh-server
```

### Network Not Working in VM

**Check interface:**
```bash
ip addr show
ip link show
```

**Restart networking:**
```bash
sudo systemctl restart systemd-networkd
```

**Check UTM network settings:**
- VM Settings → Network → Should be "Shared Network"

### VM is Slow

**Increase resources:**
- Stop VM
- VM Settings → Memory: increase to 16 GB if you have RAM
- VM Settings → CPU: increase to 6-8 cores

**Check Mac resources:**
```bash
# On Mac
top
# Ensure you're not running too many apps
```

### Shared Folders Not Working

**Requires SPICE guest tools:**
```bash
# Ubuntu ARM64 may not have SPICE tools
# Use SCP/SSH instead for file transfer
```

**Alternative - Use SCP:**
```bash
# From Mac to VM
scp file.txt splunkadmin@192.168.64.2:~/

# From VM to Mac
scp splunkadmin@192.168.64.2:~/file.txt ./
```

## Tips & Best Practices

✅ **Do:**
- Take snapshots before major changes
- Use SSH keys for passwordless access
- Note the VM's IP address
- Keep VM updated: `sudo apt update && sudo apt upgrade`
- Shut down gracefully: `sudo shutdown -h now`

❌ **Don't:**
- Force stop without reason (can corrupt disk)
- Run out of disk space (monitor with `df -h`)
- Forget to remove ISO after installation
- Skip the OpenSSH server installation

## Quick Reference

| Task | Command |
|------|---------|
| VM IP address | `ip addr show` |
| Update system | `sudo apt update && sudo apt upgrade -y` |
| Shutdown | `sudo shutdown -h now` |
| Reboot | `sudo reboot` |
| Disk space | `df -h` |
| Memory usage | `free -h` |
| SSH from Mac | `ssh splunkadmin@192.168.64.2` |
| Copy to VM | `scp file.txt splunkadmin@192.168.64.2:~/` |

---

**Last Updated**: November 2025
**Platform**: macOS with UTM virtualization
**For**: Lab testing and development
