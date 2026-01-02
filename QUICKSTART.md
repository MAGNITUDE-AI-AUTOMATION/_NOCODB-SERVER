# 🚀 Quick Start - NocoDB Installation

## Fastest Method (2 minutes)

```bash
ssh root@72.62.149.57
curl -sL https://raw.githubusercontent.com/MAGNITUDE-AI-AUTOMATION/_NOCODB-SERVER/main/scripts/complete-setup.sh | bash
```

Then open: **https://db.magnitude-ai.com**

---

## What Gets Installed

- ✅ NocoDB (latest version)
- ✅ PostgreSQL 15 database
- ✅ Nginx reverse proxy
- ✅ SSL certificate (Let's Encrypt)
- ✅ Auto-generated secure passwords
- ✅ Auto-restart on failure

---

## After Installation

### Access NocoDB
Open https://db.magnitude-ai.com and create your admin account

### View Credentials
```bash
cat /opt/nocodb/.env
```

### Manage Services
```bash
cd /opt/nocodb

# View logs
docker compose logs -f

# Restart
docker compose restart

# Stop
docker compose stop

# Start
docker compose start

# Status
docker compose ps
```

---

## Need Help?

See full documentation: [README.md](README.md)
