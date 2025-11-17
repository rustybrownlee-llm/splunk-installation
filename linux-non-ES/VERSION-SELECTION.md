# Splunk Version Selection Guide

This package includes **two versions** of Splunk Enterprise for maximum flexibility:

## Available Versions

### Splunk Enterprise 10.0.1 (Latest)
- **Size:** 1.6GB
- **Release Date:** September 2024
- **Status:** Latest major release

### Splunk Enterprise 9.4.6 (Stable)
- **Size:** 1.1GB
- **Release Date:** October 2024
- **Status:** Latest 9.x stable release

---

## Which Version Should You Use?

### Choose **Splunk 10.0.1** if:

✅ **You want the latest features** - Newest functionality and improvements
✅ **You're doing a new deployment** - Starting fresh with no legacy constraints
✅ **Testing/development environment** - Can tolerate potential issues
✅ **You have time for troubleshooting** - If issues arise during deployment

⚠️ **Considerations:**
- Some OpenSSL library warnings on RHEL 9 (doesn't affect functionality)
- May have newer bugs not yet discovered/patched
- Less community knowledge base (newer release)

---

### Choose **Splunk 9.4.6** if:

✅ **Production environment** - Need maximum stability
✅ **Conservative IT policies** - Avoid bleeding-edge versions
✅ **Compliance requirements** - Need well-tested, proven version
✅ **Limited troubleshooting time** - Must work reliably
✅ **Existing 9.x deployments** - Maintaining version consistency

⚠️ **Considerations:**
- Won't have the latest features from 10.0
- Eventually will need to upgrade to 10.x for long-term support

---

## Compatibility Matrix

| Component | Version 10.0.1 | Version 9.4.6 |
|-----------|---------------|---------------|
| **Universal Forwarder 10.0.2** | ✅ **Recommended** | ✅ Compatible (forward compatible) |
| **Universal Forwarder 9.4.6** | ✅ Compatible (backward compatible) | ✅ **Recommended** |
| **Universal Forwarder 9.3.2** | ✅ Compatible | ✅ Compatible |
| **All Add-ons (18+)** | ✅ Compatible | ✅ Compatible |
| **Ubuntu 22.04+** | ✅ Compatible | ✅ Compatible |
| **RHEL 8+** | ✅ Compatible | ✅ Compatible |
| **RHEL 9** | ⚠️ OpenSSL warnings | ✅ Full compatibility |
| **Deployment Server** | ✅ Compatible | ✅ Compatible |
| **CIM Data Models** | ✅ Compatible | ✅ Compatible |

### Universal Forwarder Version Recommendations

**Best Practice:** Match forwarder version to Enterprise version

- **Enterprise 10.0.1** → Use **Forwarder 10.0.2** (159MB Windows)
- **Enterprise 9.4.6** → Use **Forwarder 9.4.6** (171MB Windows)
- **Mixed Environment** → Use **Forwarder 9.3.2** (130MB Windows, 47MB Linux) for universal compatibility

**Note:** Splunk supports forward compatibility (newer forwarders → older indexers) and backward compatibility (older forwarders → newer indexers) within the same major version.

---

## Installation Instructions

Both versions use the **same installation scripts**. The scripts will automatically detect which version you've copied to the `downloads/` directory.

### To Use 10.0.1:
```bash
# Copy 10.0.1 installer to downloads
cp installers/splunk-10.0.1-c486717c322b-linux-amd64.tgz \
   linux-splunk-package/downloads/

# Run installation
cd linux-splunk-package
sudo ./install-splunk.sh
```

### To Use 9.4.6:
```bash
# Copy 9.4.6 installer to downloads
cp installers/splunk-9.4.6-60284236e579-linux-amd64.tgz \
   linux-splunk-package/downloads/

# Run installation
cd linux-splunk-package
sudo ./install-splunk.sh
```

### Manual Installation:
Follow **IMPLEMENTATION-LINUX.md** and adjust the version numbers in the commands:
- For 10.0.1: Use `splunk-10.0.1-c486717c322b-linux-amd64.tgz`
- For 9.4.6: Use `splunk-9.4.6-60284236e579-linux-amd64.tgz`

---

## Recommendation Summary

| Scenario | Recommended Version |
|----------|-------------------|
| **Production deployment** | 9.4.6 (Stable) |
| **Development/testing** | 10.0.1 (Latest) |
| **First-time Splunk users** | 9.4.6 (Stable) |
| **Experienced Splunk admins** | Either (10.0.1 for features, 9.4.6 for stability) |
| **Air-gapped environment with limited support** | 9.4.6 (Stable) |
| **Cloud/internet-connected with support** | 10.0.1 (Latest) |
| **Compliance-driven environment** | 9.4.6 (Stable) |
| **Innovation-focused environment** | 10.0.1 (Latest) |

---

## Upgrade Path

If you install 9.4.6 now, you can upgrade to 10.x later:

1. **Test 10.0.1 in non-production first**
2. **Back up your 9.4.6 configuration**
3. **Follow Splunk upgrade procedures**
4. **Verify all add-ons and apps still work**

---

## Known Issues

### Splunk 10.0.1:
- ⚠️ RHEL 9: OpenSSL library warnings with boot-start (doesn't affect Splunk operation)
- Being the newest release, may have undiscovered issues

### Splunk 9.4.6:
- ✅ No known critical issues
- Mature, well-tested release

---

## Still Unsure?

**When in doubt, choose 9.4.6** for:
- ✅ Proven stability
- ✅ Extensive community knowledge base
- ✅ Well-documented issues and solutions
- ✅ Lower risk deployment

You can always upgrade to 10.x later once it's been validated in your environment.

---

**Last Updated:** November 2024
