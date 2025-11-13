# AWS Windows Server EC2 Instance

Quick reference for connecting to the Windows Server 2022 EC2 instance for testing Splunk Universal Forwarder.

## Instance Details

| Property | Value |
|----------|-------|
| Instance ID | `i-08c1400fbc1fcfcc0` |
| Instance Type | `t3.micro` (1 GB RAM, 2 vCPU) |
| Public IP | `54.161.64.115` |
| Region | `us-east-1` |
| OS | Windows Server 2022 Datacenter |
| Storage | 60 GB gp3 |
| Security Group | `sg-04231f5548f7b36d6` |
| Key Pair | `splunk-test-key` |

## RDP Connection

### Credentials

- **Host**: `54.161.64.115`
- **Username**: `Administrator`
- **Password**: `2%*Vc3zsW2rMHcUy7wtdq2sVm!sPWetD`

### Connect from Mac

**Option 1: Microsoft Remote Desktop (Recommended)**

1. Install from App Store: **Microsoft Remote Desktop**
2. Click **"+ Add"** → **"PC"**
3. **PC name**: `54.161.64.115`
4. **User account**: Click **"Add User Account"**
   - **Username**: `Administrator`
   - **Password**: `2%*Vc3zsW2rMHcUy7wtdq2sVm!sPWetD`
5. Click **"Add"**
6. Double-click the connection to connect

**Option 2: Command Line**

```bash
# Using Microsoft Remote Desktop (if already configured)
open rdp://Administrator@54.161.64.115
```

## Open Ports

- **3389** - RDP (Remote Desktop Protocol)

## Splunk Configuration

### Linux Splunk Server Details

Point the Windows forwarder to:
- **Deployment Server**: `3.93.164.15:8089`
- **Indexer**: `3.93.164.15:9997`

### Transfer PowerShell Scripts

**Option A: Copy/Paste via RDP**

1. Connect via RDP
2. Copy text from Mac → Paste in Windows

**Option B: Download from GitHub/Cloud**

If you have your scripts in a repo or cloud storage

**Option C: SCP (requires OpenSSH on Windows)**

```powershell
# On Windows Server (in PowerShell as Administrator)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

Then from Mac:
```bash
scp -r windows-forwarders Administrator@54.161.64.115:C:\\
```

### Install Splunk Forwarder

1. **Copy** `windows-forwarders` folder to Windows instance
2. **Edit** `config.ps1`:
   ```powershell
   $Script:DeploymentServerAddress = "3.93.164.15"
   $Script:IndexerAddress = "3.93.164.15"
   ```
3. **Run** as Administrator:
   ```powershell
   cd C:\windows-forwarders
   .\Install-SplunkForwarder.ps1
   ```

## AWS CLI Management

**Start instance:**
```bash
aws ec2 start-instances --instance-ids i-08c1400fbc1fcfcc0
```

**Stop instance:**
```bash
aws ec2 stop-instances --instance-ids i-08c1400fbc1fcfcc0
```

**Get current IP (changes after stop/start):**
```bash
aws ec2 describe-instances --instance-ids i-08c1400fbc1fcfcc0 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

**Get Administrator password:**
```bash
aws ec2 get-password-data --instance-id i-08c1400fbc1fcfcc0 \
  --priv-launch-key ~/.ssh/aws-splunk-key.pem --query 'PasswordData' --output text
```

**Terminate instance (destroys VM):**
```bash
aws ec2 terminate-instances --instance-ids i-08c1400fbc1fcfcc0
```

**Instance status:**
```bash
aws ec2 describe-instances --instance-ids i-08c1400fbc1fcfcc0 \
  --query 'Reservations[0].Instances[0].State.Name' --output text
```

## Cost

- **t3.micro**: Free tier eligible (750 hours/month for 12 months)
- **Storage**: 60 GB gp3 @ ~$4.80/month (~$0.08/GB-month)
- **Stop instance when not in use** to save on compute (storage charges remain)

## Networking

Both instances are in the same VPC and can communicate:
- **Linux Splunk Server**: `3.93.164.15` (internal and external)
- **Windows Forwarder**: `54.161.64.115` (internal and external)

Windows forwarder can reach Linux server on all required ports.

## Notes

- Public IP changes when instance is stopped/started (use Elastic IP if needed)
- Administrator password is generated at instance launch (stored above)
- Windows takes 5-10 minutes to boot completely after launch
- RDP may take a minute to become available even after instance shows "running"
- Free tier covers 750 hours/month of t3.micro runtime
- Remember to stop/terminate when done testing

## Troubleshooting

**Can't connect via RDP:**
- Wait 10 minutes after launch for Windows to fully boot
- Check security group allows port 3389
- Verify public IP hasn't changed (if you stopped/started)

**Forwarder can't reach Splunk server:**
- Verify Linux Splunk server is running
- Check Linux security group allows ports 8089 and 9997
- Test connectivity: `Test-NetConnection -ComputerName 3.93.164.15 -Port 8089`

---

**Created:** 2025-11-03
**Region:** us-east-1 (N. Virginia)
