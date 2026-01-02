# Phase 1 - Individual Diagnostic Commands

If you prefer to run commands individually instead of using the script, here are all the commands:

## 1. System Information

```bash
# OS version
cat /etc/os-release

# Disk space
df -h

# RAM
free -h

# CPU info
lscpu | grep -E "^CPU\(s\)|^Model name|^Architecture"

# System load
uptime
```

## 2. Docker Check

```bash
# Check if Docker is installed
docker --version

# Check Docker Compose
docker compose version

# List running containers
docker ps -a

# List Docker networks
docker network ls
```

## 3. Nginx Check

```bash
# Nginx status
systemctl status nginx

# Nginx version
nginx -v

# List site configs
ls -la /etc/nginx/sites-enabled/

# View site configurations
cat /etc/nginx/sites-enabled/*
```

## 4. Port Availability

```bash
# All listening ports
ss -tuln | grep LISTEN

# Check specific ports
ss -tuln | grep :8080  # NocoDB
ss -tuln | grep :5432  # PostgreSQL
ss -tuln | grep :80    # HTTP
ss -tuln | grep :443   # HTTPS

# Alternative port check
lsof -i :8080
lsof -i :5432
```

## 5. SSL & Certbot

```bash
# Check certbot
certbot --version

# List SSL certificates
ls -la /etc/letsencrypt/live/
```

## 6. Firewall

```bash
# UFW status
ufw status verbose

# iptables rules
iptables -L -n -v
```

---

**After running these commands, paste ALL the outputs back for analysis.**
