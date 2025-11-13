# Windows 11 VM Setup Guide

Create a Windows 11 ARM64 VM using UTM on macOS for testing Splunk Universal Forwarder.

## Prerequisites

- ✅ UTM installed (via Homebrew: `brew install utm`)
- ⬇️ Windows 11 ARM64 Evaluation ISO (download instructions below)
- 💻 M4 Max MacBook Pro (or other Apple Silicon Mac)

## VM Specifications

| Resource | Value | Purpose |
|----------|-------|---------|
| RAM | 4 GB | Windows 11 + Universal Forwarder |
| CPU Cores | 2 | Adequate for forwarder testing |
| Disk | 60 GB | Windows + apps + logs |
| OS | Windows 11 Enterprise Evaluation ARM64 | Free 90-day trial |

## Step 1: Download Windows 11 ARM64 ISO

### Get Evaluation ISO

1. Visit Microsoft Evaluation Center:
   ```
   https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise
   ```

2. Click **"Download the ISO - ARM64"**

3. **Fill out registration form** (required):
   - Company email recommended
   - Company name
   - Country

4. **Select language** and click **"Download 64-bit edition"**

5. **Download starts** (file is ~5-6 GB, takes 10-30 minutes)

6. **Move ISO to project:**
   ```bash
   mv ~/Downloads/Windows11_*.iso \
     /Users/rustybrownlee/Development/splunk-installation/iso/windows11-arm64-eval.iso
   ```

### ISO Details

- **File size**: ~5-6 GB
- **Valid for**: 90 days (evaluation license)
- **Edition**: Windows 11 Enterprise Evaluation
- **Architecture**: ARM64 (for Apple Silicon)

## Step 2: Create VM in UTM

### Launch UTM
```bash
open -a UTM
```

### Create New Virtual Machine

1. Click **"Create a New Virtual Machine"**
2. Select **"Virtualize"** (for ARM64 native performance)

### Configure Operating System

3. Select **"Windows"**
4. Click **"Browse"** and navigate to:
   ```
   /Users/rustybrownlee/Development/splunk-installation/iso/windows11-arm64-eval.iso
   ```
5. ✅ Check **"Install Windows 10 or higher"** (yes, for Windows 11)
6. ✅ Check **"Install drivers and SPICE tools"** ← IMPORTANT for performance

### Hardware Configuration

7. **Memory**: Set to **4096 MB (4 GB)**
8. **CPU Cores**: Set to **2**

### Storage

9. **Storage Size**: Set to **60 GB**
10. Keep storage type as default

### Shared Directory (Optional)

11. Click **"Add"** under Shared Directory
12. Browse and select: `/Users/rustybrownlee/Development/splunk-installation/windows-forwarders`
13. Allows easy file transfer for PowerShell scripts

### Name and Save

14. **VM Name**: `windows-client`
15. Click **"Save"**

### Optional: Move VM to Project Folder

To keep everything self-contained:

16. Close UTM
17. Open Finder: `~/Library/Containers/com.utmapp.UTM/Data/Documents/`
18. Move `windows-client.utm` to: `/Users/rustybrownlee/Development/splunk-installation/vm/`
19. Reopen UTM → **"+"** → **"Open Existing VM"**
20. Select the moved VM

## Step 3: Install Windows 11

### Start Installation

1. Select VM in UTM
2. Click **▶️ Play**
3. Wait for Windows Setup to load (2-3 minutes)

### Windows Setup Wizard

**Language/Region:**
- Language: **English (or your preference)**
- Time/Currency: **Your country**
- Keyboard: **US (or your preference)**
- Click **"Next"**

**Install Now:**
- Click **"Install now"**

**Activate Windows:**
- Click **"I don't have a product key"** ← Evaluation doesn't need one
- Click **"Next"**

**Select Edition:**
- Select **"Windows 11 Enterprise Evaluation"**
- Click **"Next"**

**License Terms:**
- ✅ Check **"I accept the license terms"**
- Click **"Next"**

**Installation Type:**
- Select **"Custom: Install Windows only (advanced)"**

**Disk Selection:**
- Select **"Drive 0 Unallocated Space"**
- Click **"Next"**

**Installation Progress:**
- Wait 15-25 minutes
- VM will reboot automatically during installation
- **Don't interrupt!**

## Step 4: Windows 11 Initial Setup (OOBE)

After installation, Windows 11 setup (Out-of-Box Experience) begins:

### Region/Keyboard

- **Region**: Your country
- **Keyboard**: Your layout
- **Skip second keyboard** layout

### Network

- **For testing**, skip network setup:
  - Click **"I don't have internet"** (bottom left)
  - Click **"Continue with limited setup"**

### Account Setup

- **Account type**:
  - Click **"Sign-in options"** (bottom left)
  - Select **"Offline account"**
  - Click **"Limited experience"** (if asked)

- **Username**: `testuser` (or your preference)
- **Password**: [Choose a password]
- **Security questions**: Answer 3 questions

### Privacy Settings

- Review and toggle as desired
- Click **"Accept"** or **"Next"** through screens

### Let Windows Finish Setup

- Wait 5-10 minutes for Windows to complete setup
- Desktop should appear

## Step 5: Install SPICE Guest Tools

**CRITICAL for performance!**

### Auto-Install (Should Happen Automatically)

1. A window should pop up: **"SPICE Guest Tools"**
2. Click **"Run spice-guest-tools installer"**
3. Click **"Yes"** on User Account Control
4. Click **"Next"** → **"Install"** → **"Finish"**
5. **Reboot** when prompted

### Manual Install (If Auto-Install Didn't Work)

1. Open **File Explorer**
2. Click **"This PC"**
3. Double-click **"CD Drive (D:)" or similar**
4. Double-click **"spice-guest-tools-x.x.exe"**
5. Follow installer prompts
6. Reboot

### Verify Tools Installed

After reboot:
- Mouse should move smoothly
- Clipboard copy/paste should work between Mac and VM
- Display resolution should adjust automatically

## Step 6: Post-Install Configuration

### Enable PowerShell Script Execution

1. Click **Start** → Type **"PowerShell"**
2. **Right-click "Windows PowerShell"** → **"Run as administrator"**
3. Click **"Yes"** on User Account Control
4. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
   ```

### Get IP Address

```powershell
ipconfig
```

Look for **"IPv4 Address"** under Ethernet adapter
- Usually `192.168.64.x`
- **Write this down!** (needed for testing connectivity)

### Verify Network Connectivity

```powershell
# Ping your Mac
ping 192.168.64.1

# Ping Ubuntu VM (replace with actual IP)
ping 192.168.64.2
```

### Install Updates (Optional but Recommended)

1. **Settings** → **Windows Update**
2. Click **"Check for updates"**
3. Install all updates
4. Reboot if required

## Step 7: Prepare for Splunk Forwarder

### Copy PowerShell Scripts to VM

**Option A: Via Shared Folder** (if configured)
- Shared folders appear as network drives
- Copy `windows-forwarders` folder to `C:\splunk-installation\`

**Option B: Via RDP/File Copy** (simpler)
1. From Mac, compress windows-forwarders folder
2. Transfer via USB, cloud, or network share
3. Extract on Windows VM

**Option C: Clone Git Repo** (if you have Git)
```powershell
# Install Git for Windows first
winget install Git.Git

# Clone repository
cd C:\
git clone <your-repo-url> splunk-installation
cd splunk-installation\windows-forwarders
```

### Edit config.ps1

1. Open `config.ps1` in Notepad
2. Update **Line 13**:
   ```powershell
   $Script:DeploymentServerAddress = "192.168.64.2"  # Your Ubuntu VM IP
   ```
3. Update **Line 17**:
   ```powershell
   $Script:IndexerAddress = "192.168.64.2"  # Your Ubuntu VM IP
   ```
4. **Save** the file

## Step 8: Take Snapshot

Before installing Splunk forwarder:

1. In UTM, **right-click** the Windows VM
2. Select **"Manage Snapshots"**
3. Click **"Create Snapshot"**
4. Name: **"pre-forwarder-install"**
5. Click **"Save"**

## Next Steps

You're ready to install Splunk Universal Forwarder!

See `documents/WINDOWS-FORWARDER-INSTALL.md` for complete installation guide.

Quick start:
```powershell
# In PowerShell as Administrator
cd C:\splunk-installation\windows-forwarders
.\Install-SplunkForwarder.ps1
```

## VM Management

### Using UTM GUI

- **Start**: Select VM → Click ▶️
- **Stop**: Select VM → Click ⏹️
- **Full Screen**: Click the expand icon
- **Snapshots**: Right-click VM → Manage Snapshots

### Graceful Shutdown

**From Windows:**
- Start → Power → Shut down

**From UTM:**
- Select VM → Click ⏹️ (sends ACPI shutdown)

### Force Stop (Only if Frozen)

- Hold **Option** key while clicking ⏹️ button

## Troubleshooting

### Windows Won't Activate

**This is normal for evaluation!**

Evaluation license is activated automatically. Ignore activation prompts for 90 days.

### VM is Slow

**Install SPICE Guest Tools** (see Step 5)

**Increase RAM if available:**
- Stop VM
- VM Settings → Memory → Increase to 8 GB
- Start VM

**Disable Visual Effects:**
1. System → About → Advanced system settings
2. Performance Settings
3. Select "Adjust for best performance"
4. Apply

### Can't Ping Ubuntu VM

**Check IPs:**
```powershell
# Windows
ipconfig

# Ubuntu (in VM console)
ip addr show
```

**Check Windows Firewall:**
```powershell
# Temporarily disable for testing
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Re-enable after testing
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

### Shared Folders Not Working

**Requires SPICE Guest Tools** installed

**Check mounted drives:**
- File Explorer → This PC
- Look for network drives

**Alternative - Use SCP:**

Install OpenSSH on Windows (built-in on Windows 10/11):
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

Then from Mac:
```bash
scp file.txt testuser@192.168.64.3:C:\
```

### Display Issues

**Resolution not adjusting:**
- Install SPICE Guest Tools
- Restart VM

**Multiple monitors:**
- UTM supports multiple displays in VM settings

### Clipboard Not Working

**Requires SPICE Guest Tools**

After installing:
- Copy on Mac → Paste in Windows VM
- Copy in Windows VM → Paste on Mac

## Tips & Best Practices

✅ **Do:**
- Install SPICE Guest Tools immediately
- Take snapshots before major changes
- Keep Windows updated
- Use PowerShell as Administrator for installations
- Test network connectivity before installing forwarder

❌ **Don't:**
- Skip SPICE Guest Tools (performance will be poor)
- Force stop unless VM is frozen
- Install heavy software (this is for testing forwarders)
- Ignore Windows Firewall (needed for Splunk ports)

## Quick Reference

| Task | Command |
|------|---------|
| Get IP | `ipconfig` |
| Ping Ubuntu VM | `ping 192.168.64.2` |
| PowerShell as Admin | Right-click → Run as administrator |
| Windows Firewall | `Get-NetFirewallProfile` |
| Shutdown | `shutdown /s /t 0` |
| Reboot | `shutdown /r /t 0` |
| Check disk space | `Get-PSDrive C` |

## Windows 11 Evaluation License

- **Duration**: 90 days from first boot
- **Activation**: Automatic for evaluation
- **Renewal**: Create new VM after expiration
- **Features**: Full Enterprise features

**To check remaining days:**
```powershell
slmgr /xpr
```

---

**Last Updated**: November 2025
**Platform**: macOS with UTM virtualization
**For**: Lab testing of Windows Universal Forwarder
