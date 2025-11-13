# AWS EC2 Splunk Test Server

Quick reference for connecting to the AWS EC2 instance for Splunk testing.

## Instance Details

| Property | Value |
|----------|-------|
| Instance ID | `i-03dcb8671c6d492e9` |
| Instance Type | `t3.micro` (1 GB RAM, 2 vCPU) |
| Public IP | `3.93.164.15` |
| Region | `us-east-1` |
| AMI | Ubuntu 22.04 LTS (amd64) |
| Storage | 160 GB gp3 |
| Security Group | `sg-0538613876cccfe9d` |
| Key Pair | `splunk-test-key` |

## SSH Connection

```bash
ssh -i ~/.ssh/aws-splunk-key.pem ubuntu@3.93.164.15
```

Add to `/etc/hosts` (optional):
```bash
echo "3.93.164.15 splunk-aws" | sudo tee -a /etc/hosts
ssh -i ~/.ssh/aws-splunk-key.pem ubuntu@splunk-aws
```

## Open Ports

- **22** - SSH
- **8000** - Splunk Web
- **8089** - Splunk Management/Deployment Server
- **9997** - Splunk Forwarder Receiving

## Splunk Web Access

After installation: **http://3.93.164.15:8000**

## Deploy Files to Instance

```bash
cd /Users/rustybrownlee/Development/splunk-installation/scripts
scp -i ~/.ssh/aws-splunk-key.pem -r ../scripts ../downloads ../configs ubuntu@3.93.164.15:~/
```

Or use the deployment script (modify for AWS):
```bash
./deploy-to-vm.sh  # Edit to use aws-splunk-key.pem and 3.93.164.15
```

## Install Splunk

```bash
ssh -i ~/.ssh/aws-splunk-key.pem ubuntu@3.93.164.15
cd ~/scripts
chmod +x *.sh
sudo ./install-splunk.sh
sudo ./configure-deployment-server.sh
sudo ./install-addons.sh
sudo ./setup-receiving.sh
```

## AWS CLI Management

**Start instance:**
```bash
aws ec2 start-instances --instance-ids i-03dcb8671c6d492e9
```

**Stop instance:**
```bash
aws ec2 stop-instances --instance-ids i-03dcb8671c6d492e9
```

**Get current IP (changes after stop/start):**
```bash
aws ec2 describe-instances --instance-ids i-03dcb8671c6d492e9 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

**Terminate instance (destroys VM):**
```bash
aws ec2 terminate-instances --instance-ids i-03dcb8671c6d492e9
```

**Instance status:**
```bash
aws ec2 describe-instances --instance-ids i-03dcb8671c6d492e9 \
  --query 'Reservations[0].Instances[0].State.Name' --output text
```

## Cost

- **t3.micro**: Free tier eligible (750 hours/month for 12 months)
- **Storage**: 160 GB gp3 @ ~$12.80/month (~$0.08/GB-month)
- **Stop instance when not in use** to save on compute (storage charges remain)

## Notes

- Public IP changes when instance is stopped/started (use Elastic IP if needed)
- Instance user is `ubuntu` (not `splunkadmin`)
- Free tier covers 750 hours/month of t3.micro runtime
- Remember to stop/terminate when done testing

---

**Created:** 2025-11-03
**Region:** us-east-1 (N. Virginia)
