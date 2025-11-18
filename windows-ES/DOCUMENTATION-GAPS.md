# HAP Windows ES - Documentation Gaps

## Purpose

This document tracks remaining documentation needed for complete customer handoff. Priorities are based on customer operational needs and implementation timeline.

## Timeline Strategy

1. **Pre-Implementation Testing**: AWS environment setup guides
2. **During Implementation Testing**: Learn the actual process, take notes
3. **Post-Implementation**: Document proven procedures and create operational guides

## Pre-Implementation (Before AWS Testing)

### AWS Testing Environment Setup

**Status**: [TODO]

**Documents Needed**:
- `testing/AWS-ENVIRONMENT-SETUP.md` - EC2 instances, Security Groups, VPC configuration
- `testing/AD-MOCK-SETUP.md` - Domain Controller promotion, mock organization structure
- `testing/ES-TEST-PLAN.md` - What to test, validation procedures

**Why**: Need these to build AWS test environment tomorrow

**Owner**: Create before starting AWS work

---

## During Implementation (Build in AWS, Document What Works)

### Server Implementation Guides

**Status**: [TODO] - Marked in IMPLEMENTATION-STATUS.md but not created

**Documents Needed**:
1. `IMPLEMENTATION-SERVER1.md` - ES Search Head complete setup
2. `IMPLEMENTATION-SERVER2.md` - Indexer complete setup
3. `IMPLEMENTATION-FORWARDERS.md` - Universal Forwarder deployment

**Approach**:
- Build the environment in AWS step-by-step
- Document each successful step as we go
- Include screenshots where helpful
- Note any gotchas or issues encountered
- These become the proven playbook for customer deployment

**Why**: Cannot create accurate guides without hands-on implementation experience

**Owner**: Create during AWS testing based on actual process

---

## Post-Implementation (Customer Handoff Documents)

### 1. ES User Management & RBAC

**Priority**: HIGH

**Document**: `operations/ES-USER-MANAGEMENT.md`

**Contents**:

**User Authentication & Authorization**:
- ES roles explained (ess_admin, ess_analyst, ess_user)
- Splunk platform roles (admin, power, user)
- LDAP authentication strategy configuration
- AD group to Splunk/ES role mapping
- Role assignment procedures
- Creating custom roles if needed
- User onboarding workflow
- Access control best practices
- Least-privilege recommendations

**Identity and Asset Management**:
- Identity TTL (Time-to-Live) configuration
  - Default: 90 days, Recommended: 180-365 days
  - Retains deleted/disabled AD users for forensic investigations
  - ES 7.0+ feature - no manual identity merging required
- Identity merge process explanation
- Asset TTL configuration
- Monitoring identity staleness (saved search for approaching TTL)
- Manual identity management procedures
- Multiple identity sources (if applicable)

**Testing & Validation**:
- Test user login with each role
- Verify AD group membership grants correct access
- Test identity merge behavior (disable AD user, verify retention)
- Validate identity enrichment in notable events

**Why**: Customer needs to manage their own users after we leave. This is operational day-one requirement. Identity TTL configuration is critical for forensic investigations and compliance.

**When**: After ES is installed and we've tested user/role creation and LDAP authentication in AWS

**Critical Testing**: Verify identity merge behavior works correctly - disable test AD user, confirm identity remains in lookup with last_seen timestamp

---

### 2. Notable Event Management & Suppression

**Priority**: HIGH

**Document**: `operations/NOTABLE-EVENT-WORKFLOWS.md`

**Contents**:

**Notable Event Lifecycle**:
- Severity/urgency assignment
- Owner assignment procedures
- Status workflow (New → In Progress → Resolved → Closed)
- Disposition codes
- Comments and annotations

**Suppression Strategy**:
- When to suppress vs tune correlation search
- Creating suppression rules
- Time-based suppressions
- Suppression by field values
- Review and removal of outdated suppressions
- False positive documentation workflow

**Notification Configuration**:
- Email alert setup (SMTP configuration)
- Alert routing by severity
- Escalation procedures
- On-call integration (if applicable)
- Alert fatigue prevention

**Why**: Without this, analysts will drown in alerts or ignore the system. Critical for ES adoption and success.

**When**: After ES is running and we've generated test notable events

---

### 3. Correlation Search Tuning

**Priority**: MEDIUM-HIGH

**Document**: `operations/CORRELATION-SEARCH-TUNING.md`

**Contents**:

**Initial Configuration**:
- Which out-of-box searches to enable (ES ships with 100+)
- Recommended starter set for Windows environment
- Throttling configuration to prevent alert storms
- Scheduling best practices

**Tuning Procedures**:
- Identifying noisy searches
- Adjusting thresholds
- Refining search logic for environment
- Adding whitelists/blacklists
- Performance impact considerations

**Custom Search Development** (if needed):
- When to create custom correlation searches
- Best practices for search performance
- Testing before enabling in production
- Documentation requirements

**Maintenance**:
- Quarterly review process
- Metrics to track (alert volume, false positive rate)
- Continuous improvement workflow

**Why**: Out-of-box correlation searches need environment-specific tuning. Prevents alert fatigue and improves SOC efficiency.

**When**: After ES is operational and we've worked with several correlation searches

---

### 4. Verification & Validation Checklist

**Priority**: MEDIUM

**Document**: `VERIFICATION-CHECKLIST.md`

**Contents**:
- Post-installation validation steps
- Data flow verification (forwarders → indexer → search head)
- ES components health check
- Data model acceleration status
- Asset/Identity framework population
- Notable event generation test
- User access verification
- Performance baseline establishment

**Why**: Ensures deployment is complete and functional before handoff

**When**: After implementation is complete, before customer handoff

---

### 5. Backup & Recovery Procedures

**Priority**: MEDIUM

**Document**: `operations/BACKUP-RECOVERY.md`

**Contents**:

**What to Backup**:
- ES KV Store (critical for ES operation)
- Asset/identity lookups
- Custom correlation searches and notable event rules
- Suppression configurations
- User-created content (dashboards, saved searches)
- Configuration files ($SPLUNK_HOME/etc/apps/)
- License files

**Backup Procedures**:
- Automated backup scripts
- Backup schedule recommendations
- Storage location and retention
- Testing restore procedures

**Recovery Scenarios**:
- Individual app/configuration restore
- KV Store restore
- Full system recovery
- Recovery Time Objective (RTO) expectations

**Why**: Customer needs disaster recovery plan. Stratus provides hardware HA but not configuration/data backup.

**When**: After implementation, can be documented from Splunk best practices

---

### 6. Security Hardening

**Priority**: MEDIUM

**Document**: `operations/SECURITY-HARDENING.md`

**Contents**:

**SSL/TLS Configuration**:
- Splunk Web HTTPS setup
- Management port (8089) encryption
- Forwarder-to-indexer encrypted communication
- Certificate management and renewal procedures

**Access Controls**:
- Network-level restrictions (Windows Firewall rules)
- Port lockdown recommendations
- Admin account security
- Service account security review

**Hardening Checklist**:
- Disable unnecessary services/inputs
- Default password changes
- Audit logging configuration
- Security event monitoring for Splunk itself

**Why**: Security best practices for production deployment. Customer may have compliance requirements.

**When**: After base implementation works, before production deployment

---

### 7. Operational Runbooks

**Priority**: LOW-MEDIUM

**Document**: `operations/TROUBLESHOOTING-RUNBOOKS.md`

**Contents**:

**Common Issues**:
- Forwarder not connecting to indexer
- Data not appearing in searches
- ES dashboards not loading
- Data model acceleration failures
- Disk space issues
- License warnings
- Performance degradation

**For Each Issue**:
- Symptoms
- Diagnosis steps
- Resolution procedures
- Escalation criteria

**Why**: Helps customer support team resolve common issues without vendor assistance

**When**: After we've encountered and solved issues during testing

---

### 8. Monitoring & Health Checks

**Priority**: LOW (Splunk 10 built-in)

**Document**: `operations/MONITORING-GUIDE.md` (lightweight)

**Contents**:
- Overview of Splunk 10 built-in health checks
- Monitoring Console access and navigation
- Key metrics to watch
- When to investigate issues
- Integration with customer monitoring systems (if needed)

**Why**: While Splunk 10 has this built-in, customer may need guidance on what to monitor

**When**: After implementation, low priority

---

## Lower Priority / Nice-to-Have

These can be addressed if time permits or on customer request:

- **Capacity Planning** - Document growth projections and storage planning
- **Change Management** - Formal change control procedures
- **Compliance Reporting** - If customer has specific compliance needs
- **Threat Intelligence Integration** - If customer wants threat feeds
- **Network Device Integration** - Detailed syslog receiver setup for firewalls/switches
- **Frozen Bucket Thawing** - Procedures to restore archived data

---

## Not Our Responsibility

These are handled elsewhere:

- **Licensing** - VAR manages license procurement and installation support
- **Sysmon Deployment** - Customer responsibility or separate SOW
- **Network Firewall Rules** - Customer network team implements based on our port requirements

---

## Summary: What We're Creating

### Immediate (This Week - AWS Testing):
1. AWS environment setup guides
2. Server implementation guides (during testing)

### Post-Testing (Next Week - Customer Handoff):
3. ES User Management & RBAC (HIGH)
4. Notable Event Management & Suppression (HIGH)
5. Correlation Search Tuning (MEDIUM-HIGH)
6. Verification Checklist (MEDIUM)
7. Backup & Recovery (MEDIUM)
8. Security Hardening (MEDIUM)
9. Troubleshooting Runbooks (LOW-MEDIUM)
10. Monitoring Guide (LOW)

---

## Next Steps

1. Create AWS testing environment guides (tonight or tomorrow morning)
2. Build and document implementation during AWS testing
3. Create operational handoff documents based on proven procedures
4. Review all documentation with customer during deployment
5. Adjust based on customer feedback and environment specifics

---

**Document Version**: 1.0
**Created**: 2024-11-17
**Last Updated**: 2024-11-17
**Status**: Active planning document
