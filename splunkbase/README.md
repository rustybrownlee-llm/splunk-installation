# Splunkbase Apps and Add-ons

This directory contains all Splunk apps and add-ons downloaded from Splunkbase.

These files are shared across all sub-projects and should be referenced (not duplicated) by implementation scripts.

## Contents

Place the following add-on files here (18+ total):

### Core Framework
- `splunk-common-information-model-cim_*.tgz`
- `splunk-security-essentials_*.tar.gz`

### Network Security
- `splunk-add-on-for-cisco-asa_*.tgz`
- `add-on-for-cisco-network-data_*.tgz`
- `palo-alto-networks-firewall_*.tgz`
- `splunk-add-on-for-palo-alto-networks_*.tgz`

### Windows Monitoring
- `splunk-add-on-for-microsoft-windows_*.tgz`
- `splunk-supporting-add-on-for-active-directory_*.tgz`
- `splunk-add-on-for-sysmon_*.tgz`

### Unix/Linux Monitoring
- `splunk-add-on-for-unix-and-linux_*.tgz`

### Security & Analysis
- `infosec-app-for-splunk_*.tgz`
- `alert-manager_*.tgz`
- `alert-manager-add-on_*.tgz`

### Visualization
- `splunk-ai-toolkit_*.tgz`
- `force-directed-app-for-splunk_*.tgz`
- `punchcard-custom-visualization_*.tgz`
- `splunk-sankey-diagram-custom-visualization_*.tgz`
- `splunk-app-for-lookup-file-editing_*.tgz`

## Download Sources

All add-ons can be downloaded from: https://splunkbase.splunk.com/

## File Management

- These files are gitignored due to size
- Keep versions consistent across deployments
- Reference this directory from sub-project installation scripts
