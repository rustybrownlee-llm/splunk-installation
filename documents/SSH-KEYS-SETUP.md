# SSH Keys Setup Guide

Quick guide for setting up passwordless SSH authentication to Linux servers.

## Why Use SSH Keys?

- **No passwords needed**: Automatic authentication
- **More secure**: Keys are cryptographically stronger than passwords
- **Easier automation**: Scripts can connect without prompts
- **Convenient**: Works for VMs, production servers, cloud instances

## Quick Setup (5 Minutes)

### Step 1: Check for Existing Keys (On Your Computer)

```bash
ls -la ~/.ssh/id_*.pub
```

**If you see files listed** (like `id_ed25519.pub` or `id_rsa.pub`):
- ✅ You already have SSH keys, skip to Step 3

**If you see "No such file or directory"**:
- Continue to Step 2

### Step 2: Generate SSH Key Pair (One-Time Setup)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

**When prompted:**
1. `Enter file in which to save the key`: Press **Enter** (use default location)
2. `Enter passphrase`: Press **Enter** (no passphrase for convenience)*
3. `Enter same passphrase again`: Press **Enter**

*For added security, you can set a passphrase, but you'll need to enter it once per session

**You should see:**
```
Your identification has been saved in /Users/yourusername/.ssh/id_ed25519
Your public key has been saved in /Users/yourusername/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:... your_email@example.com
```

### Step 3: Copy Public Key to Linux Server

**For a specific server:**
```bash
ssh-copy-id username@server-ip-address
```

**Example:**
```bash
# For lab VM
ssh-copy-id splunkadmin@192.168.64.2

# For production server
ssh-copy-id splunkadmin@10.1.2.100
```

**When prompted:**
- `Are you sure you want to continue connecting?`: Type **yes** and press Enter
- `password:`: Enter the user's password **one time**

**You should see:**
```
Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'username@server'"
and check to make sure that only the key(s) you wanted were added.
```

### Step 4: Test Passwordless Login

```bash
ssh username@server-ip-address
```

**✅ Success:** You connect without entering a password!

## Using with Multiple Servers

You can use the same SSH key for multiple servers:

```bash
# Lab VM
ssh-copy-id splunkadmin@192.168.64.2

# Production Splunk server
ssh-copy-id splunkadmin@prod-splunk-01

# Another production server
ssh-copy-id splunkadmin@prod-splunk-02
```

After setup, all connections are passwordless!

## For SCP File Transfers

Once SSH keys are set up, SCP (file copy) also becomes passwordless:

```bash
# Copy file to server
scp myfile.txt splunkadmin@192.168.64.2:~/

# Copy directory to server
scp -r myfolder splunkadmin@192.168.64.2:~/

# Copy from server to local
scp splunkadmin@192.168.64.2:~/remotefile.txt ./
```

## Advanced: Different Keys for Different Servers

If you want separate keys for different environments:

```bash
# Generate key for production
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_production -C "production-servers"

# Generate key for lab
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_lab -C "lab-servers"

# Copy specific key to server
ssh-copy-id -i ~/.ssh/id_ed25519_production.pub splunkadmin@prod-server

# Use specific key to connect
ssh -i ~/.ssh/id_ed25519_production splunkadmin@prod-server
```

## SSH Config File (Optional but Recommended)

Create `~/.ssh/config` to simplify connections:

```bash
# Create or edit SSH config
nano ~/.ssh/config
```

**Add entries for your servers:**
```
# Lab VM
Host splunk-lab
    HostName 192.168.64.2
    User splunkadmin
    IdentityFile ~/.ssh/id_ed25519

# Production server
Host splunk-prod
    HostName 10.1.2.100
    User splunkadmin
    IdentityFile ~/.ssh/id_ed25519
```

**Now you can connect with shortcuts:**
```bash
# Instead of: ssh splunkadmin@192.168.64.2
ssh splunk-lab

# Instead of: ssh splunkadmin@10.1.2.100
ssh splunk-prod
```

## Troubleshooting

### "Permission denied (publickey)"

**Check permissions on server:**
```bash
# SSH into server (with password) and run:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### "Host key verification failed"

**If server was reinstalled:**
```bash
# Remove old host key
ssh-keygen -R server-ip-address

# Reconnect (will ask to verify new key)
ssh username@server-ip-address
```

### Keys not working on macOS

**macOS may need to add key to keychain:**
```bash
ssh-add ~/.ssh/id_ed25519
```

**Make it permanent (add to ~/.ssh/config):**
```
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
```

### Verify key was copied correctly

**On the server:**
```bash
cat ~/.ssh/authorized_keys
# Should show your public key
```

**On your computer:**
```bash
cat ~/.ssh/id_ed25519.pub
# Should match the key on the server
```

## Security Best Practices

✅ **Do:**
- Keep private key (`id_ed25519`) on your computer only
- Use different keys for different security levels (dev/prod)
- Set a passphrase for keys used on production servers
- Regularly rotate keys (generate new ones annually)

❌ **Don't:**
- Share your private key with anyone
- Copy private key to servers
- Email private keys
- Store private keys in cloud storage

## Key Files Explained

| File | Location | Description | Share? |
|------|----------|-------------|--------|
| `id_ed25519` | `~/.ssh/` on your computer | Private key | ❌ Never |
| `id_ed25519.pub` | `~/.ssh/` on your computer | Public key | ✅ Safe to share |
| `authorized_keys` | `~/.ssh/` on server | List of allowed public keys | ℹ️ Server only |

## Quick Reference Commands

```bash
# Generate new key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy key to server
ssh-copy-id username@server

# Test connection
ssh username@server

# View your public key
cat ~/.ssh/id_ed25519.pub

# List all keys
ls -la ~/.ssh/

# Remove server from known_hosts
ssh-keygen -R server-ip-address
```

## For Windows Users

Windows 10/11 includes OpenSSH. Open PowerShell and use the same commands:

```powershell
# Generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Keys stored in: C:\Users\YourUsername\.ssh\

# Copy to server (manual, no ssh-copy-id on Windows)
# 1. Display your public key:
type $env:USERPROFILE\.ssh\id_ed25519.pub

# 2. SSH to server and paste into ~/.ssh/authorized_keys
```

---

**Last Updated**: November 2025
