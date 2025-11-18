# Active Directory Service Account Setup for Splunk Enterprise Security

## Purpose

This document provides step-by-step instructions for creating and configuring a dedicated Active Directory service account that Splunk Enterprise Security will use to query AD for asset and identity information. This data feeds the ES Asset and Identity framework, enabling correlation of security events with user and asset context.

## Overview

Splunk ES will use the **Splunk Supporting Add-on for Active Directory** (SA-LDAP) to:
- Query Active Directory for user identity information (nightly)
- Query Active Directory for computer/device asset information (nightly)
- Populate ES asset and identity correlation lookups
- Enable user and asset context in security investigations

## Service Account Requirements

### Account Specifications

**Account Name**: `svc_splunk_ldap` (recommended)
- **Type**: Domain service account
- **Password**: Strong, complex password (minimum 20 characters)
- **Password Expiration**: Set to "Password never expires" OR coordinate password rotation with Splunk team
- **Account Restrictions**: Restrict logon to specific servers (Server 1 - ES Search Head)
- **Description**: "Splunk Enterprise Security LDAP Query Service Account"

### Security Considerations

- **Least Privilege**: Account only needs READ access to AD objects
- **No Interactive Logon**: Account should be denied interactive logon rights
- **Service Account OU**: Place in dedicated service accounts OU with appropriate Group Policy
- **Audit**: Enable logon auditing for this account
- **Documentation**: Document account ownership and purpose in AD description field

## Required Active Directory Permissions

### Minimum Required Permissions

The service account needs **READ** permissions on the following AD objects:

#### For Identity Collection (Users)
- **Container**: `CN=Users,DC=domain,DC=com` (and all OUs containing user accounts)
- **Object Types**: User objects
- **Permissions**:
  - Read all properties
  - List contents
  - Read permissions

#### For Asset Collection (Computers)
- **Container**: `CN=Computers,DC=domain,DC=com` (and all OUs containing computer accounts)
- **Object Types**: Computer objects
- **Permissions**:
  - Read all properties
  - List contents
  - Read permissions

### Step-by-Step Permission Assignment

#### Option 1: Use Built-in Domain Users Group (Simplest)
By default, Domain Users group has read access to most AD objects. If the service account is a member of Domain Users, it likely has sufficient permissions.

**Verification**:
1. Open **Active Directory Users and Computers**
2. Right-click the domain root → **Properties**
3. Go to **Security** tab
4. Verify **Authenticated Users** or **Domain Users** has **Read** permission

#### Option 2: Create Dedicated Security Group (Recommended)
For better security and auditability, create a dedicated group with explicit permissions.

**Steps**:

1. **Create Security Group**:
   ```
   Group Name: SG_Splunk_LDAP_Readers
   Group Type: Security - Global
   Description: Splunk LDAP read-only access for asset/identity collection
   ```

2. **Add Service Account to Group**:
   - Add `svc_splunk_ldap` to `SG_Splunk_LDAP_Readers` group

3. **Delegate Read Permissions on Domain Root**:
   - Open **Active Directory Users and Computers**
   - Right-click domain root (e.g., `domain.com`) → **Delegate Control**
   - Click **Next**
   - Click **Add** → Select `SG_Splunk_LDAP_Readers` → **OK**
   - Click **Next**
   - Select **Create a custom task to delegate** → **Next**
   - Select **This folder, existing objects in this folder, and creation of new objects in this folder**
   - Check:
     - User objects
     - Computer objects
     - Group objects (optional, for group membership info)
   - Click **Next**
   - Under Permissions, check:
     - Read All Properties
     - List Contents
   - Click **Next** → **Finish**

4. **Verify Permissions**:
   ```powershell
   # Test from a domain controller
   dsacls "DC=domain,DC=com" | Select-String "SG_Splunk_LDAP_Readers"
   ```

## Service Account Creation Steps

### Step 1: Create the Service Account

**Using Active Directory Users and Computers GUI**:

1. Open **Active Directory Users and Computers**
2. Navigate to the Service Accounts OU (or create one if it doesn't exist):
   - Right-click domain → **New** → **Organizational Unit**
   - Name: `Service Accounts`
3. Right-click **Service Accounts** OU → **New** → **User**
4. Enter details:
   - **First name**: `Splunk LDAP`
   - **Last name**: `Service Account`
   - **User logon name**: `svc_splunk_ldap`
   - Click **Next**
5. Set password:
   - **Password**: [Generate strong 20+ character password]
   - Check: User cannot change password
   - Check: Password never expires
   - Uncheck: User must change password at next logon
   - Click **Next** → **Finish**

**Using PowerShell** (optional):

```powershell
# Create service account
Import-Module ActiveDirectory

$Password = Read-Host -AsSecureString "Enter password for svc_splunk_ldap"

New-ADUser -Name "svc_splunk_ldap" `
    -SamAccountName "svc_splunk_ldap" `
    -UserPrincipalName "svc_splunk_ldap@domain.com" `
    -DisplayName "Splunk LDAP Service Account" `
    -Description "Splunk Enterprise Security LDAP Query Service Account - Created $(Get-Date -Format 'yyyy-MM-dd')" `
    -Path "OU=Service Accounts,DC=domain,DC=com" `
    -AccountPassword $Password `
    -Enabled $true `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true

# Add to Splunk LDAP Readers group (if using Option 2)
Add-ADGroupMember -Identity "SG_Splunk_LDAP_Readers" -Members "svc_splunk_ldap"
```

### Step 2: Configure Account Restrictions

**Restrict Logon Hours** (optional but recommended):

1. Open account properties
2. Go to **Account** tab
3. Click **Logon Hours**
4. Allow logon 24/7 (Splunk queries run on schedule)

**Restrict Logon To Specific Computers** (recommended):

1. Open account properties
2. Go to **Account** tab
3. Click **Log On To**
4. Select **The following computers**
5. Add: `SERVER1` (ES Search Head hostname)
6. Click **OK**

**Deny Interactive Logon**:

Apply via Group Policy to Service Accounts OU:
- Computer Configuration → Windows Settings → Security Settings → Local Policies → User Rights Assignment
- **Deny log on locally**: Add `svc_splunk_ldap`
- **Deny log on through Remote Desktop Services**: Add `svc_splunk_ldap`

### Step 3: Document the Account

**Required Information for Splunk Team**:

Provide the following information to the Splunk administrator:

```
Service Account Details
=======================
Username: svc_splunk_ldap
Domain: DOMAIN
Full UPN: svc_splunk_ldap@domain.com
Full DN: CN=svc_splunk_ldap,OU=Service Accounts,DC=domain,DC=com
Password: [Provided securely via password vault or secure channel]

Domain Controller Information
==============================
Primary DC: dc01.domain.com
Secondary DC: dc02.domain.com
LDAP Port: 636 (LDAPS - SSL) OR 389 (LDAP - non-SSL)
Global Catalog Port: 3269 (GC-SSL) OR 3268 (GC - non-SSL)

Base DNs for Queries
====================
User Base DN: DC=domain,DC=com
Computer Base DN: DC=domain,DC=com

Search Scope: subtree (searches all OUs beneath base DN)
```

**Security Notes**:
- DO NOT send passwords via email
- Use secure password vault (e.g., KeePass, 1Password, CyberArk)
- OR deliver password in person or via secure encrypted channel

## Testing the Service Account

### Test 1: LDAP Bind Test

Test from Server 1 (ES Search Head) or any domain-joined Windows server:

**Using PowerShell**:

```powershell
# Test LDAP bind
$username = "svc_splunk_ldap@domain.com"
$password = Read-Host -AsSecureString "Enter password"
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Test connection
$domain = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DC=domain,DC=com", $credential.UserName, $credential.GetNetworkCredential().Password)

if ($domain.Name -ne $null) {
    Write-Host "SUCCESS: LDAP bind successful" -ForegroundColor Green
    Write-Host "Domain Name: $($domain.Name)"
} else {
    Write-Host "FAILED: LDAP bind failed" -ForegroundColor Red
}
```

### Test 2: Query User Objects

```powershell
# Test user query
$searcher = New-Object System.DirectoryServices.DirectorySearcher($domain)
$searcher.Filter = "(objectClass=user)"
$searcher.PageSize = 1000
$searcher.PropertiesToLoad.Add("sAMAccountName") | Out-Null
$searcher.PropertiesToLoad.Add("displayName") | Out-Null
$searcher.PropertiesToLoad.Add("mail") | Out-Null

try {
    $results = $searcher.FindAll()
    Write-Host "SUCCESS: Found $($results.Count) user objects" -ForegroundColor Green

    # Show first 5 users
    $results | Select-Object -First 5 | ForEach-Object {
        Write-Host "  User: $($_.Properties['samaccountname']) - $($_.Properties['displayname'])"
    }
} catch {
    Write-Host "FAILED: User query failed - $($_.Exception.Message)" -ForegroundColor Red
}
```

### Test 3: Query Computer Objects

```powershell
# Test computer query
$searcher.Filter = "(objectClass=computer)"
$searcher.PropertiesToLoad.Clear()
$searcher.PropertiesToLoad.Add("name") | Out-Null
$searcher.PropertiesToLoad.Add("operatingSystem") | Out-Null
$searcher.PropertiesToLoad.Add("dNSHostName") | Out-Null

try {
    $results = $searcher.FindAll()
    Write-Host "SUCCESS: Found $($results.Count) computer objects" -ForegroundColor Green

    # Show first 5 computers
    $results | Select-Object -First 5 | ForEach-Object {
        Write-Host "  Computer: $($_.Properties['name']) - $($_.Properties['operatingsystem'])"
    }
} catch {
    Write-Host "FAILED: Computer query failed - $($_.Exception.Message)" -ForegroundColor Red
}
```

### Test 4: LDAPS (SSL) Connection Test

If using LDAPS (port 636), verify SSL certificate is trusted:

```powershell
# Test LDAPS connection
$ldapsUri = "LDAPS://dc01.domain.com:636"
$domain = New-Object System.DirectoryServices.DirectoryEntry($ldapsUri, $credential.UserName, $credential.GetNetworkCredential().Password)

if ($domain.Name -ne $null) {
    Write-Host "SUCCESS: LDAPS (SSL) connection successful" -ForegroundColor Green
} else {
    Write-Host "FAILED: LDAPS connection failed - Check SSL certificate" -ForegroundColor Red
}
```

## Firewall and Network Requirements

Ensure the following ports are open between **Server 1 (ES Search Head)** and **Domain Controllers**:

### Required Ports

| Protocol | Port | Description | Required |
|----------|------|-------------|----------|
| LDAP | 389 | LDAP (non-SSL) | Yes (if not using LDAPS) |
| LDAPS | 636 | LDAP over SSL | Yes (recommended) |
| Global Catalog | 3268 | GC (non-SSL) | Optional |
| GC-SSL | 3269 | GC over SSL | Optional |
| DNS | 53 | DNS lookups | Yes |
| Kerberos | 88 | Kerberos authentication | Yes (if domain-joined) |

### Network Test

From Server 1, test connectivity to domain controller:

```powershell
# Test LDAP port
Test-NetConnection -ComputerName dc01.domain.com -Port 389

# Test LDAPS port (recommended)
Test-NetConnection -ComputerName dc01.domain.com -Port 636

# Test DNS
Resolve-DnsName domain.com
```

## Splunk SA-LDAP Configuration

Once the service account is created and tested, configure Splunk SA-LDAP add-on on Server 1.

### Installation Steps (performed by Splunk team)

1. **Install SA-LDAP add-on**:
   ```powershell
   cd "C:\Program Files\Splunk\bin"
   .\splunk install app C:\path\to\ad-ldap_237.tgz -auth admin:password
   .\splunk restart
   ```

2. **Configure LDAP Connection**:
   - Navigate to Splunk Web UI → **SA-LDAP** app
   - Go to **Configuration** → **LDAP Connections**
   - Click **New LDAP Connection**

3. **LDAP Connection Settings**:
   ```
   Name: Corporate_AD
   LDAP Server: dc01.domain.com
   Port: 636 (LDAPS recommended)
   SSL Enabled: Yes
   Base DN: DC=domain,DC=com
   Bind DN: CN=svc_splunk_ldap,OU=Service Accounts,DC=domain,DC=com
   Bind DN Password: [password provided by customer]
   ```

4. **Configure Identity Search**:
   - **Search Filter**: `(objectClass=user)`
   - **Attributes to Retrieve**:
     - sAMAccountName
     - userPrincipalName
     - displayName
     - mail
     - telephoneNumber
     - title
     - department
     - manager
     - memberOf
     - whenCreated
     - lastLogon

5. **Configure Asset Search**:
   - **Search Filter**: `(objectClass=computer)`
   - **Attributes to Retrieve**:
     - name
     - dNSHostName
     - operatingSystem
     - operatingSystemVersion
     - description
     - location
     - managedBy
     - whenCreated
     - lastLogon

### Schedule Configuration

Configure nightly collection schedule:

**For Identity Collection**:
- **Schedule**: Daily at 2:00 AM
- **Cron**: `0 2 * * *`
- **Interval**: 86400 seconds (24 hours)

**For Asset Collection**:
- **Schedule**: Daily at 3:00 AM
- **Cron**: `0 3 * * *`
- **Interval**: 86400 seconds (24 hours)

**Lookup Output**:
- **Identity Lookup**: `identity_lookup_expanded.csv`
- **Asset Lookup**: `asset_lookup_by_str.csv`

## Expected Data Volume

### Typical AD Query Results

| Object Type | Estimated Count | Data Size per Record | Total Size |
|-------------|----------------|---------------------|------------|
| Users | 1,000 - 10,000 | 2 KB | 2 MB - 20 MB |
| Computers | 1,000 - 10,000 | 1.5 KB | 1.5 MB - 15 MB |

**Total Daily Data**: ~5-35 MB (negligible impact on indexing volume)

**Lookups Storage**: Lookup files stored in `$SPLUNK_HOME/etc/apps/SA-IdentityManagement/lookups/`

## Verification and Validation

### Verify LDAP Queries Are Running

**Check SA-LDAP logs**:
```spl
index=_internal source=*sa-ldap* earliest=-24h
| stats count by log_level, message
| sort - count
```

**Check for LDAP search successes**:
```spl
index=_internal source=*sa-ldap* "LDAP search" earliest=-24h
| stats count by status
```

### Verify Identity Data

**Check identity lookup population**:
```spl
| inputlookup identity_lookup_expanded
| stats count by identity
| sort - count
| head 10
```

**Sample identity data**:
```spl
| inputlookup identity_lookup_expanded
| head 20
| table identity, email, displayName, department, title
```

### Verify Asset Data

**Check asset lookup population**:
```spl
| inputlookup asset_lookup_by_str
| stats count by asset
| sort - count
| head 10
```

**Sample asset data**:
```spl
| inputlookup asset_lookup_by_str
| head 20
| table asset, ip, dns, os, location
```

### ES Asset and Identity Framework Validation

**Verify ES sees the data**:
1. Navigate to **Enterprise Security** → **Configure** → **Data Enrichment** → **Asset and Identity Management**
2. Verify:
   - Identity data source shows "SA-LDAP"
   - Asset data source shows "SA-LDAP"
   - Last update timestamp is recent
   - Record counts match expectations

**Test correlation in Notable Event**:
```spl
index=notable earliest=-24h
| head 1
| fields + user, src, dest
| lookup identity_lookup_expanded identity as user OUTPUT email, department
| lookup asset_lookup_by_str asset as src OUTPUT ip, os
| table _time, user, email, department, src, ip, os
```

## Troubleshooting

### Issue: LDAP Bind Failures

**Symptoms**: SA-LDAP logs show "LDAP bind failed" or "Invalid credentials"

**Checks**:
1. Verify password is correct
2. Check account is not locked: `Get-ADUser svc_splunk_ldap | Select-Object LockedOut`
3. Check account is enabled: `Get-ADUser svc_splunk_ldap | Select-Object Enabled`
4. Verify UPN format: `svc_splunk_ldap@domain.com` or `DOMAIN\svc_splunk_ldap`

**Resolution**:
```powershell
# Unlock account if locked
Unlock-ADAccount -Identity svc_splunk_ldap

# Reset password if needed
Set-ADAccountPassword -Identity svc_splunk_ldap -Reset
```

### Issue: LDAPS Certificate Errors

**Symptoms**: SSL/TLS errors when connecting on port 636

**Checks**:
1. Verify DC has valid SSL certificate
2. Check certificate is trusted by Server 1
3. Verify certificate CN matches DC hostname

**Resolution**:
- Export DC certificate and import to Server 1 Trusted Root CA store
- OR use non-SSL LDAP on port 389 (less secure)

### Issue: Insufficient Permissions

**Symptoms**: LDAP queries return no results or partial results

**Checks**:
```powershell
# Check effective permissions
dsacls "DC=domain,DC=com" | Select-String "svc_splunk_ldap"

# Check group membership
Get-ADUser svc_splunk_ldap -Properties MemberOf | Select-Object -ExpandProperty MemberOf
```

**Resolution**:
- Verify service account is member of appropriate security group
- Re-delegate permissions using steps in "Required Active Directory Permissions" section

### Issue: Queries Timeout or Return Partial Results

**Symptoms**: LDAP searches timeout or return incomplete data

**Checks**:
- Check for large number of AD objects (>50,000)
- Verify network connectivity and latency
- Check DC performance and load

**Resolution**:
- Increase page size in SA-LDAP configuration (default: 1000)
- Configure multiple LDAP servers for load balancing
- Schedule queries during off-peak hours

### Issue: Stale Data in Lookups

**Symptoms**: Identity/asset lookups contain old or deleted objects

**Checks**:
```spl
| inputlookup identity_lookup_expanded
| search identity="deleted_user"
```

**Resolution**:
- Verify scheduled searches are running successfully
- Check for errors in SA-LDAP logs
- Manually run LDAP search to force refresh
- Consider adding filters to exclude disabled accounts:
  - User filter: `(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))`
  - Computer filter: `(&(objectClass=computer)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))`

## Security Best Practices

### Password Management

- **Rotation**: Coordinate password changes with Splunk team
- **Complexity**: Minimum 20 characters, mixed case, numbers, symbols
- **Storage**: Store password in secure vault (KeePass, 1Password, CyberArk)
- **Access**: Limit password access to authorized personnel only

### Access Control

- **RBAC**: Use dedicated security group for permissions
- **Audit**: Enable auditing for service account logon events
- **Monitoring**: Alert on:
  - Failed LDAP binds
  - Account lockouts
  - Password changes
  - Unauthorized group membership changes

### Compliance

- **Documentation**: Maintain record of service account purpose and owner
- **Review**: Quarterly review of service account permissions
- **Attestation**: Annual attestation of service account necessity

## Maintenance and Operations

### Quarterly Review

**Tasks**:
- [ ] Verify service account is still in use
- [ ] Review group membership
- [ ] Check for any security alerts related to account
- [ ] Validate LDAP queries are still successful
- [ ] Review data volume and lookup sizes

### Password Rotation (if required)

**Notification**: Splunk team must be notified 2 weeks in advance

**Steps**:
1. Customer resets password in AD
2. Customer provides new password to Splunk team (secure channel)
3. Splunk team updates SA-LDAP configuration
4. Splunk team tests LDAP connection
5. Verify scheduled searches continue successfully

### Monitoring

**Recommended Alerts**:

**LDAP Bind Failures**:
```spl
index=_internal source=*sa-ldap* "bind failed" earliest=-1h
| stats count
| where count > 0
| eval severity="high"
```

**Stale Lookups**:
```spl
| rest /services/data/lookup-table-files
| search title="identity_lookup_expanded.csv" OR title="asset_lookup_by_str.csv"
| eval age_hours=round((now() - updated) / 3600, 1)
| where age_hours > 30
| table title, age_hours
```

## Appendix A: Sample PowerShell Test Script

```powershell
# AD Service Account Test Script for Splunk ES
# Save as: Test-SplunkLDAPAccount.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [string]$DomainController = "",

    [int]$Port = 636,

    [switch]$UseSSL = $true
)

# Prompt for password securely
$SecurePassword = Read-Host -AsSecureString "Enter password for $Username"
$Credential = New-Object System.Management.Automation.PSCredential("$Username@$Domain", $SecurePassword)

Write-Host "`n=== Splunk LDAP Service Account Test ===" -ForegroundColor Cyan
Write-Host "Username: $Username@$Domain"
Write-Host "Domain Controller: $DomainController"
Write-Host "Port: $Port"
Write-Host "SSL: $UseSSL`n"

# Test 1: LDAP Bind
Write-Host "[Test 1] LDAP Bind Test..." -ForegroundColor Yellow

$ldapPath = if ($DomainController) {
    if ($UseSSL) { "LDAPS://${DomainController}:${Port}/DC=$($Domain.Replace('.',',DC='))" }
    else { "LDAP://${DomainController}:${Port}/DC=$($Domain.Replace('.',',DC='))" }
} else {
    "LDAP://DC=$($Domain.Replace('.',',DC='))"
}

try {
    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
        $ldapPath,
        $Credential.UserName,
        $Credential.GetNetworkCredential().Password
    )

    if ($DirectoryEntry.Name -ne $null) {
        Write-Host "[PASS] LDAP bind successful" -ForegroundColor Green
        Write-Host "       Domain: $($DirectoryEntry.Name)`n"
    } else {
        Write-Host "[FAIL] LDAP bind failed - Check credentials" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[FAIL] LDAP bind failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: User Query
Write-Host "[Test 2] User Object Query..." -ForegroundColor Yellow

$Searcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry)
$Searcher.Filter = "(objectClass=user)"
$Searcher.PageSize = 1000
$Searcher.PropertiesToLoad.Add("sAMAccountName") | Out-Null
$Searcher.PropertiesToLoad.Add("displayName") | Out-Null
$Searcher.PropertiesToLoad.Add("mail") | Out-Null

try {
    $UserResults = $Searcher.FindAll()
    Write-Host "[PASS] Found $($UserResults.Count) user objects" -ForegroundColor Green

    Write-Host "       Sample users:"
    $UserResults | Select-Object -First 5 | ForEach-Object {
        $sam = $_.Properties['samaccountname']
        $dn = $_.Properties['displayname']
        Write-Host "       - $sam ($dn)"
    }
    Write-Host ""
} catch {
    Write-Host "[FAIL] User query failed - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Computer Query
Write-Host "[Test 3] Computer Object Query..." -ForegroundColor Yellow

$Searcher.Filter = "(objectClass=computer)"
$Searcher.PropertiesToLoad.Clear()
$Searcher.PropertiesToLoad.Add("name") | Out-Null
$Searcher.PropertiesToLoad.Add("operatingSystem") | Out-Null

try {
    $ComputerResults = $Searcher.FindAll()
    Write-Host "[PASS] Found $($ComputerResults.Count) computer objects" -ForegroundColor Green

    Write-Host "       Sample computers:"
    $ComputerResults | Select-Object -First 5 | ForEach-Object {
        $name = $_.Properties['name']
        $os = $_.Properties['operatingsystem']
        Write-Host "       - $name ($os)"
    }
    Write-Host ""
} catch {
    Write-Host "[FAIL] Computer query failed - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Performance Test
Write-Host "[Test 4] Query Performance Test..." -ForegroundColor Yellow

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$Searcher.Filter = "(objectClass=user)"
$TestResults = $Searcher.FindAll()
$Stopwatch.Stop()

$ElapsedSeconds = $Stopwatch.Elapsed.TotalSeconds
Write-Host "[INFO] Query time: $([math]::Round($ElapsedSeconds, 2)) seconds for $($TestResults.Count) users" -ForegroundColor Cyan

if ($ElapsedSeconds -lt 10) {
    Write-Host "[PASS] Performance acceptable (< 10 seconds)" -ForegroundColor Green
} elseif ($ElapsedSeconds -lt 30) {
    Write-Host "[WARN] Performance acceptable but slow (< 30 seconds)" -ForegroundColor Yellow
} else {
    Write-Host "[WARN] Performance slow (> 30 seconds) - Consider optimization" -ForegroundColor Yellow
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "All tests passed. Service account is ready for Splunk ES configuration.`n" -ForegroundColor Green
```

**Usage**:
```powershell
.\Test-SplunkLDAPAccount.ps1 -Username "svc_splunk_ldap" -Domain "domain.com" -DomainController "dc01.domain.com"
```

## Appendix B: LDAP Filter Examples

### Exclude Disabled Accounts

**Users (exclude disabled)**:
```ldap
(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

**Computers (exclude disabled)**:
```ldap
(&(objectClass=computer)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

### Filter by OU

**Users in specific OU**:
```ldap
(&(objectClass=user)(memberOf=OU=Corporate Users,DC=domain,DC=com))
```

### Exclude Service Accounts

**Exclude accounts with "svc_" prefix**:
```ldap
(&(objectClass=user)(!(sAMAccountName=svc_*)))
```

### Recent Logon Filter

**Users who logged on in last 90 days**:
```ldap
(&(objectClass=user)(lastLogon>=[90 days ago in FileTime format]))
```

## Appendix C: Delivery Checklist

Provide this completed checklist to the Splunk team:

- [ ] Service account `svc_splunk_ldap` created
- [ ] Password set and documented in secure vault
- [ ] Account set to "Password never expires" OR rotation schedule documented
- [ ] Account added to appropriate security group (if using dedicated group)
- [ ] AD permissions delegated (read access to users and computers)
- [ ] Account restrictions configured (logon hours, logon to servers)
- [ ] Interactive logon denied via Group Policy
- [ ] Service account tested using PowerShell test script
- [ ] Network connectivity verified (ports 636/389 open to DCs)
- [ ] LDAPS certificate installed on Server 1 (if using SSL)
- [ ] Account information documented and provided to Splunk team:
  - [ ] Username and UPN
  - [ ] Password (via secure channel)
  - [ ] Domain controller hostnames
  - [ ] Base DNs for user and computer searches
  - [ ] LDAP/LDAPS port preferences
- [ ] Firewall rules configured between Server 1 and DCs
- [ ] Monitoring/auditing enabled for service account
- [ ] Documentation stored in secure location

---

**Document Version**: 1.0
**Created**: 2024-11-17
**For**: HAP Windows Enterprise Security Deployment
**Contact**: [Splunk Administrator Contact Information]
