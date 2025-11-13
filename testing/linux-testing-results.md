# Linux Splunk Installation - Testing Results

## Testing Overview

**Objective**: Validate Splunk Enterprise installation package on both Ubuntu and RHEL platforms to ensure production readiness.

**Test Date Started**: 2024-11-13
**Tester**: Rusty Brownlee
**Package Version**: Splunk Enterprise 10.0.1

---

## Test Environment

### Instance 1: Ubuntu Server
- **Status**: ✅ Running
- **OS**: Ubuntu Server 22.04 LTS
- **Instance Type**: m7i-flex.large (2 vCPU, 8GB RAM)
- **Storage**: 80GB gp3
- **Instance ID**: i-0e743a52c524b3f74
- **Public IP**: 13.220.87.48
- **Private IP**: 172.31.20.15
- **Region**: us-east-1
- **AMI**: ami-00b13f11600160c10
- **Key**: splunk-test-key
- **Security Group**: sg-0538613876cccfe9d (splunk-test-sg)

### Instance 2: RHEL Server
- **Status**: ⏸️ Pending
- **OS**: Red Hat Enterprise Linux 9
- **Instance Type**: t3.xlarge (4 vCPU, 16GB RAM)
- **Storage**: 80GB gp3
- **Instance ID**: _pending_
- **Public IP**: _pending_
- **Region**: _pending_

---

## Test Plan

### Phase 1: Ubuntu Server Testing

#### 1.1 Initial Setup
- [x] Launch EC2 instance
- [x] Configure security groups (SSH 22, Splunk 8000, 8089, 9997)
- [x] SSH connectivity verified
- [ ] Upload linux-splunk-package to instance

#### 1.2 Core Installation (`install-splunk.sh`)
- [ ] Script executes without errors
- [ ] OS detection works (Ubuntu detected)
- [ ] Package manager detection (apt)
- [ ] Dependencies install successfully
- [ ] Splunk user/group created
- [ ] Splunk extracts to /opt/splunk
- [ ] Password prompt works
- [ ] Password confirmation works
- [ ] Splunk starts successfully
- [ ] Boot-start enabled
- [ ] Firewall configured (ufw)
- [ ] Ports accessible (8000, 8089, 9997)
- [ ] Splunk Web accessible (HTTP)

#### 1.3 Add-ons Installation (`install-addons.sh`)
- [ ] OCS index add-on installs
- [ ] All .tgz add-ons extract
- [ ] Splunk Security Essentials (.tar.gz) extracts
- [ ] CIM add-on found
- [ ] CIM acceleration configured
- [ ] All add-ons enabled in Splunk Web
- [ ] No extraction errors
- [ ] Ownership set correctly (splunk:splunk)
- [ ] Splunk restarts successfully
- [ ] All apps visible in Manage Apps

#### 1.4 Deployment Server Configuration (`configure-deployment-server.sh`)
- [ ] Script prompts for credentials
- [ ] Deployment server enabled
- [ ] OCS deployment apps installed
- [ ] ocs_add-on_deployment configured with server IP
- [ ] ocs_add-on_outputs configured with indexer IP
- [ ] ocs_add-on_windows present
- [ ] Server classes created
- [ ] Legacy windows_forwarder_base created
- [ ] Deployment server reloads successfully
- [ ] Deployment apps directory structure correct

#### 1.5 Receiving Configuration (`setup-receiving.sh`)
- [ ] Script prompts for credentials
- [ ] Port 9997 enabled for receiving
- [ ] Firewall rule added (ufw)
- [ ] Port listening verified (netstat/ss)
- [ ] Splunk shows receiving enabled

#### 1.6 Certificate Generation (`generate-certificates.sh`)
- [ ] Script runs as root
- [ ] Certificate type selection works
- [ ] Self-signed option works
- [ ] Local CA option works
- [ ] Prompts for certificate details
- [ ] Certificates generated successfully
- [ ] Files created in correct locations
- [ ] Permissions set correctly (600)
- [ ] Ownership correct (splunk:splunk)

#### 1.7 SSL Configuration (`configure-ssl.sh`)
- [ ] Certificate file detected
- [ ] HTTP/HTTPS option prompt works
- [ ] server.conf updated correctly
- [ ] web.conf created/updated
- [ ] Splunk restarts successfully
- [ ] HTTPS accessible on port 8000
- [ ] Certificate valid (browser shows connection)
- [ ] HTTP disabled if option selected

#### 1.8 Functional Testing
- [ ] Login to Splunk Web works
- [ ] All apps appear in Apps menu
- [ ] InfoSec App loads
- [ ] CIM data models visible (Settings → Data Models)
- [ ] CIM acceleration enabled (check each model)
- [ ] Indexes created (Settings → Indexes)
- [ ] wineventlog index exists
- [ ] os, network, web, security indexes exist
- [ ] Deployment server shows no clients (expected)
- [ ] Receiving port shows listening

#### 1.9 Integration Testing
- [ ] Can create test data
- [ ] Search works across indexes
- [ ] InfoSec App dashboards load
- [ ] Data model searches work
- [ ] No errors in splunkd.log
- [ ] No errors in web UI

---

### Phase 2: RHEL Server Testing

#### 2.1 Initial Setup
- [ ] Launch EC2 instance
- [ ] Configure security groups
- [ ] SSH connectivity verified
- [ ] Upload linux-splunk-package to instance

#### 2.2 Core Installation (`install-splunk.sh`)
- [ ] Script executes without errors
- [ ] OS detection works (RHEL detected)
- [ ] Package manager detection (yum/dnf)
- [ ] Dependencies install successfully
- [ ] Splunk user/group created
- [ ] Splunk extracts to /opt/splunk
- [ ] Password prompt works
- [ ] Password confirmation works
- [ ] Splunk starts successfully
- [ ] Boot-start enabled
- [ ] Firewall configured (firewalld)
- [ ] Ports accessible (8000, 8089, 9997)
- [ ] Splunk Web accessible (HTTP)

#### 2.3 Add-ons Installation (`install-addons.sh`)
- [ ] OCS index add-on installs
- [ ] All .tgz add-ons extract
- [ ] Splunk Security Essentials (.tar.gz) extracts
- [ ] CIM add-on found
- [ ] CIM acceleration configured
- [ ] All add-ons enabled in Splunk Web
- [ ] No extraction errors
- [ ] Ownership set correctly
- [ ] Splunk restarts successfully

#### 2.4 Deployment Server Configuration
- [ ] All checks from Ubuntu Phase 1.4

#### 2.5 Receiving Configuration
- [ ] All checks from Ubuntu Phase 1.5
- [ ] Firewall rule added (firewalld)

#### 2.6 Certificate Generation
- [ ] All checks from Ubuntu Phase 1.6

#### 2.7 SSL Configuration
- [ ] All checks from Ubuntu Phase 1.7

#### 2.8 Functional Testing
- [ ] All checks from Ubuntu Phase 1.8

#### 2.9 Integration Testing
- [ ] All checks from Ubuntu Phase 1.9

---

## Issues Discovered

### Critical Issues
_None yet_

### Major Issues
_None yet_

### Minor Issues
_None yet_

### Documentation Updates Needed
_None yet_

---

## Test Results Summary

### Ubuntu Server
- **Overall Status**: ⏳ In Progress
- **Installation**: Ready to begin
- **Add-ons**: Not Started
- **Deployment Server**: Not Started
- **Receiving**: Not Started
- **Certificates**: Not Started
- **SSL**: Not Started
- **Functional Tests**: Not Started
- **Pass Rate**: 0/0 (0%)

### RHEL Server
- **Overall Status**: ⏸️ Not Started
- **Installation**: Not Started
- **Add-ons**: Not Started
- **Deployment Server**: Not Started
- **Receiving**: Not Started
- **Certificates**: Not Started
- **SSL**: Not Started
- **Functional Tests**: Not Started
- **Pass Rate**: 0/0 (0%)

---

## Notes and Observations

### Session 1: 2024-11-13
- Testing document created
- Test plan defined
- Ubuntu instance launched successfully (i-0e743a52c524b3f74)
- Instance type: m7i-flex.large (2 vCPU, 8GB RAM) - free tier eligible
- Note: Account limited to free-tier instances only

---

## Sign-off

### Ubuntu Testing
- [ ] All tests passed
- [ ] Issues documented
- [ ] Ready for production

### RHEL Testing
- [ ] All tests passed
- [ ] Issues documented
- [ ] Ready for production

---

**Last Updated**: 2024-11-13
**Next Steps**: Launch Ubuntu EC2 instance and begin Phase 1 testing
