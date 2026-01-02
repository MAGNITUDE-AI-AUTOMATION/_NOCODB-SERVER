# NocoDB Server Setup

**Server:** 72.62.149.57  
**OS:** Ubuntu 22.04.5 LTS  
**Domain:** db.magnitude-ai.com  
**Docker:** 29.1.3 ✅  
**Status:** Ready for installation

---

## 📊 Phase 1 Analysis - COMPLETE ✅

### Server Status
- ✅ **OS**: Ubuntu 22.04.5 LTS (Jammy Jellyfish)
- ✅ **Docker**: 29.1.3 installed and ready
- ✅ **Disk**: 46GB available (7% used)
- ✅ **RAM**: 3.8GB total, 3.2GB available
- ✅ **Nginx**: Running with SSL for chat.magnitude-ai.com
- ✅ **Certbot**: 1.21.0 installed
- ✅ **Port 8080**: FREE ✓
- ✅ **Port 5432**: FREE ✓
- ✅ **Firewall**: Inactive (no restrictions)

### Analysis Results
- ✅ No conflicts detected
- ✅ Sufficient resources for NocoDB + PostgreSQL
- ✅ Existing nginx configuration compatible
- ✅ Ready for immediate deployment

---

## 🚀 Phase 2 - Installation (THREE OPTIONS)

### Option 1: One-Command Installation (RECOMMENDED)

SSH into your server and run:

```bash
ssh root@72.62.149.57

# Download and run the complete setup script
curl -sL https://raw.githubusercontent.com/MAGNITUDE-AI-AUTOMATION/_NOCODB-SERVER/main/scripts/complete-setup.sh | bash
```

This will:
1. ✅ Install NocoDB + PostgreSQL in Docker
2. ✅ Configure nginx reverse proxy
3. ✅ Set up SSL certificate
4. ✅ Generate secure passwords
5. ✅ Start all services

**Installation time:** ~2-3 minutes

---

### Option 2: Manual Step-by-Step Installation

If you prefer to run each step manually:

#### Step 1: Install NocoDB
```bash
ssh root@72.62.149.57
curl -o install-nocodb.sh https://raw.githubusercontent.com/MAGNITUDE-AI-AUTOMATION/_NOCODB-SERVER/main/scripts/install-nocodb.sh
chmod +x install-nocodb.sh
./install-nocodb.sh
```

#### Step 2: Setup Nginx & SSL
```bash
curl -o setup-nginx-ssl.sh https://raw.githubusercontent.com/MAGNITUDE-AI-AUTOMATION/_NOCODB-SERVER/main/scripts/setup-nginx-ssl.sh
chmod +x setup-nginx-ssl.sh
./setup-nginx-ssl.sh
```

---

### Option 3: Copy/Paste Commands

<details>
<summary>Click to expand full command sequence</summary>

```bash
# 1. Create directory
mkdir -p /opt/nocodb && cd /opt/nocodb

# 2. Generate passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
NC_AUTH_JWT_SECRET=$(openssl rand -base64 32)

# 3. Create .env file
cat > .env << EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
NC_AUTH_JWT_SECRET=${NC_AUTH_JWT_SECRET}
EOF

# 4. Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: nocodb-postgres
    restart: always
    environment:
      POSTGRES_DB: nocodb
      POSTGRES_USER: nocodb
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - nocodb-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nocodb"]
      interval: 10s
      timeout: 5s
      retries: 5

  nocodb:
    image: nocodb/nocodb:latest
    container_name: nocodb
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NC_DB: "pg://postgres:5432?u=nocodb&p=${POSTGRES_PASSWORD}&d=nocodb"
      NC_AUTH_JWT_SECRET: ${NC_AUTH_JWT_SECRET}
      NC_PUBLIC_URL: https://db.magnitude-ai.com
      NC_DISABLE_TELE: false
      NC_REDIS_URL: ""
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - nocodb_data:/usr/app/data
    networks:
      - nocodb-network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  nocodb_data:

networks:
  nocodb-network:
EOF

# 5. Start Docker containers
docker compose up -d

# 6. Wait for startup
sleep 30

# 7. Create nginx config
cat > /etc/nginx/sites-available/nocodb << 'EOF'
server {
    server_name db.magnitude-ai.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        proxy_buffering off;
        proxy_request_buffering off;
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    listen 80;
}
EOF

# 8. Enable site
ln -sf /etc/nginx/sites-available/nocodb /etc/nginx/sites-enabled/

# 9. Test and reload nginx
nginx -t && systemctl reload nginx

# 10. Setup SSL
certbot --nginx -d db.magnitude-ai.com --non-interactive --agree-tos --register-unsafely-without-email

# 11. Display credentials
echo "Installation complete!"
echo "PostgreSQL Password: ${POSTGRES_PASSWORD}"
echo "Access at: https://db.magnitude-ai.com"
```

</details>

---

## 🎯 After Installation

### Access NocoDB
1. Open browser: **https://db.magnitude-ai.com**
2. Create your admin account
3. Start building your database!

### Important Files & Credentials
- **Installation directory**: `/opt/nocodb`
- **Credentials file**: `/opt/nocodb/.env`
- **Docker compose**: `/opt/nocodb/docker-compose.yml`
- **Nginx config**: `/etc/nginx/sites-available/nocodb`

### Useful Commands
```bash
# View logs
cd /opt/nocodb && docker compose logs -f

# Stop services
docker compose stop

# Start services
docker compose start

# Restart services
docker compose restart

# Check status
docker compose ps

# View credentials
cat /opt/nocodb/.env
```

---

## 🏗️ Architecture

```
Internet (HTTPS/443)
         ↓
    Nginx Reverse Proxy
         ↓
   NocoDB (localhost:8080)
         ↓
   PostgreSQL 15 (internal)
```

- **Frontend**: db.magnitude-ai.com (HTTPS with Let's Encrypt)
- **NocoDB**: Docker container on 127.0.0.1:8080
- **Database**: PostgreSQL 15 in Docker
- **Data**: Persistent volumes (survives restarts)
- **Auto-restart**: Enabled on failure

---

## 📁 Repository Structure

```
_NOCODB-SERVER/
├── README.md                     # This file
├── docker-compose.yml            # Docker setup template
├── .env.example                  # Environment variables template
├── nginx/
│   └── db.magnitude-ai.com.conf  # Nginx configuration
├── scripts/
│   ├── complete-setup.sh         # All-in-one installer
│   ├── install-nocodb.sh         # Docker setup only
│   └── setup-nginx-ssl.sh        # Nginx & SSL only
└── phase1-diagnostics.sh         # Server analysis script
```

---

## ✅ Status Checklist

- [x] Phase 1 diagnostic complete
- [x] Server analysis passed
- [x] Installation scripts ready
- [ ] Installation executed
- [ ] NocoDB accessible
- [ ] Admin account created

---

## 🆘 Troubleshooting

### Check if services are running
```bash
docker compose ps
systemctl status nginx
```

### View NocoDB logs
```bash
cd /opt/nocodb
docker compose logs -f nocodb
```

### View PostgreSQL logs
```bash
docker compose logs -f postgres
```

### Test local connection
```bash
curl http://127.0.0.1:8080/api/v1/health
```

### Restart everything
```bash
cd /opt/nocodb
docker compose restart
systemctl restart nginx
```

---

## 🔒 Security Notes

- PostgreSQL only accessible internally
- NocoDB only accessible via nginx
- Strong auto-generated passwords
- SSL certificate with auto-renewal
- Security headers configured
- All data in persistent volumes

---

**Ready to install? Choose Option 1 for the fastest setup!**
