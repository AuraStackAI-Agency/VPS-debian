# Security Hardening Guide

This guide provides step-by-step instructions to harden your self-hosted AI infrastructure.

---

## 🎯 Security Principles

1. **Defense in Depth** - Multiple layers of security
2. **Least Privilege** - Minimal permissions by default
3. **Audit Everything** - Comprehensive logging
4. **Automated Updates** - Security patches applied automatically

---

## 🔒 Quick Hardening (Automated)

For immediate security improvements, run the automated script:

```bash
chmod +x scripts/harden_vps.sh
sudo ./scripts/harden_vps.sh
```

**What it does:**
- ✅ Installs UFW firewall
- ✅ Configures Fail2Ban
- ✅ Hardens SSH configuration
- ✅ Enables automatic security updates

**Duration:** ~3-5 minutes

---

## 🛡️ Manual Hardening Steps

### 1. SSH Hardening

#### Disable Root Login
Edit `/etc/ssh/sshd_config`:
```bash
PermitRootLogin no
```

#### Disable Password Authentication
```bash
PasswordAuthentication no
PubkeyAuthentication yes
```

#### Change Default Port (Optional)
```bash
Port 2222  # Choose a non-standard port
```

#### Restart SSH
```bash
sudo systemctl restart ssh
```

---

### 2. Firewall Configuration (UFW)

#### Install UFW
```bash
sudo apt-get install ufw -y
```

#### Configure Rules
```bash
# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (adjust port if changed)
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS for N8N webhooks
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

#### Verify
```bash
sudo ufw status verbose
```

---

### 3. Fail2Ban (Intrusion Prevention)

#### Install
```bash
sudo apt-get install fail2ban -y
```

#### Configure
Create `/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
```

#### Start Service
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### Check Banned IPs
```bash
sudo fail2ban-client status sshd
```

---

### 4. Automatic Security Updates

#### Install Unattended Upgrades
```bash
sudo apt-get install unattended-upgrades -y
```

#### Configure
Edit `/etc/apt/apt.conf.d/50unattended-upgrades`:
```bash
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::Automatic-Reboot "false";
```

#### Enable
```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 🐳 Docker Security

### 1. Run Containers as Non-Root

In your `docker-compose.yml`:
```yaml
services:
  n8n:
    user: "1000:1000"  # Non-root user
```

### 2. Limit Container Resources

```yaml
services:
  n8n:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
```

### 3. Use Read-Only Filesystems (Where Possible)

```yaml
services:
  redis:
    read_only: true
    tmpfs:
      - /tmp
```

### 4. Network Isolation

```yaml
networks:
  internal:
    driver: bridge
    internal: true  # No external access

services:
  postgres:
    networks:
      - internal  # Only accessible internally
```

---

## 🔐 Secrets Management

### Never Hardcode Secrets

❌ **Bad:**
```yaml
environment:
  - DB_PASSWORD=mysecretpassword
```

✅ **Good:**
```yaml
environment:
  - DB_PASSWORD=${DB_PASSWORD}
```

With `.env` file:
```bash
DB_PASSWORD=your_secure_password_here
```

### Rotate Secrets Regularly

```bash
# Generate strong passwords
openssl rand -base64 32
```

---

## 📊 Audit & Monitoring

### 1. Enable Audit Logs

```bash
sudo apt-get install auditd -y
sudo systemctl enable auditd
```

### 2. Monitor Failed Login Attempts

```bash
# View SSH failures
sudo grep "Failed password" /var/log/auth.log

# Count by IP
sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
```

### 3. Docker Container Logs

```bash
# View logs
docker logs --tail 100 -f CONTAINER_NAME

# Save logs for audit
docker logs CONTAINER_NAME > /var/log/docker/CONTAINER_NAME.log
```

---

## 🚨 Incident Response

### If You Detect a Breach

1. **Isolate the System**
   ```bash
   sudo ufw default deny incoming
   ```

2. **Check for Unauthorized Users**
   ```bash
   who
   last
   ```

3. **Check Running Processes**
   ```bash
   ps aux | grep -v "^root"
   ```

4. **Review Cron Jobs**
   ```bash
   crontab -l
   sudo cat /etc/crontab
   ```

5. **Backup Evidence**
   ```bash
   sudo cp /var/log/auth.log /backup/evidence/auth.log.$(date +%Y%m%d)
   ```

---

## ✅ Security Checklist

### Before Deployment
- [ ] SSH key-only authentication configured
- [ ] Default SSH port changed (optional but recommended)
- [ ] UFW firewall enabled with minimal open ports
- [ ] Fail2Ban installed and configured
- [ ] Automatic security updates enabled
- [ ] Docker containers run as non-root users
- [ ] Secrets stored in `.env` (not hardcoded)
- [ ] Backup strategy in place

### After Deployment
- [ ] Test SSH access with new configuration
- [ ] Verify UFW rules (`sudo ufw status`)
- [ ] Check Fail2Ban status (`sudo fail2ban-client status`)
- [ ] Monitor logs for suspicious activity
- [ ] Test disaster recovery procedure

### Monthly Maintenance
- [ ] Review Fail2Ban bans
- [ ] Check for available security updates
- [ ] Rotate database passwords
- [ ] Verify backups are running
- [ ] Review Docker container logs

---

## 🔗 Additional Resources

- [CIS Benchmark for Debian](https://www.cisecurity.org/benchmark/debian_linux)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Fail2Ban Manual](https://www.fail2ban.org/wiki/index.php/Main_Page)

---

## ⚠️ Important Notes

1. **Always test SSH changes** in a separate session before closing your current one.
2. **Backup your configuration** before making security changes.
3. **Document your security settings** for team members.
4. **Security is ongoing** - stay updated with security advisories.

---

**Need help?** Open an issue in the repository with the `security` label.
