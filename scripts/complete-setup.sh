#!/bin/bash

# Complete NocoDB Setup - All-in-One Script
# Combines Docker installation, Nginx setup, and SSL configuration

set -e

echo "========================================="
echo "NocoDB Complete Installation"
echo "Server: 72.62.149.57"
echo "Domain: db.magnitude-ai.com"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

echo "📋 Pre-flight checks passed"
echo ""

# PART 1: Install NocoDB with Docker
echo "========================================="
echo "PART 1: Installing NocoDB"
echo "========================================="
echo ""

# Create directory
echo "Creating /opt/nocodb directory..."
mkdir -p /opt/nocodb
cd /opt/nocodb

# Generate passwords
echo "Generating secure credentials..."
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
NC_AUTH_JWT_SECRET=$(openssl rand -base64 32)

# Create .env file
cat > .env << EOF
# Auto-generated on $(date)
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
NC_AUTH_JWT_SECRET=${NC_AUTH_JWT_SECRET}
EOF

chmod 600 .env
echo "✅ Credentials saved to /opt/nocodb/.env"
echo ""

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'DOCKEREOF'
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
    driver: local
  nocodb_data:
    driver: local

networks:
  nocodb-network:
    driver: bridge
DOCKEREOF

echo "✅ docker-compose.yml created"
echo ""

# Start containers
echo "Starting Docker containers..."
docker compose up -d

echo ""
echo "⏳ Waiting for containers to be healthy (30 seconds)..."
sleep 30

# Check status
echo ""
echo "Container status:"
docker compose ps
echo ""

# PART 2: Configure Nginx
echo "========================================="
echo "PART 2: Configuring Nginx"
echo "========================================="
echo ""

cat > /etc/nginx/sites-available/nocodb << 'NGINXEOF'
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
NGINXEOF

echo "✅ Nginx config created"
echo ""

# Enable site
ln -sf /etc/nginx/sites-available/nocodb /etc/nginx/sites-enabled/
echo "✅ Site enabled"
echo ""

# Test nginx
echo "Testing nginx configuration..."
nginx -t
echo ""

# Reload nginx
systemctl reload nginx
echo "✅ Nginx reloaded"
echo ""

# PART 3: Setup SSL
echo "========================================="
echo "PART 3: Setting up SSL with Certbot"
echo "========================================="
echo ""

echo "Requesting SSL certificate for db.magnitude-ai.com..."
certbot --nginx -d db.magnitude-ai.com --non-interactive --agree-tos --register-unsafely-without-email

echo ""
echo "✅ SSL certificate installed"
echo ""

# Final verification
echo "========================================="
echo "VERIFICATION"
echo "========================================="
echo ""

echo "Docker containers:"
docker compose ps
echo ""

echo "Nginx status:"
systemctl status nginx --no-pager | head -10
echo ""

echo "NocoDB health check:"
curl -s http://127.0.0.1:8080/api/v1/health || echo "Service starting..."
echo ""

# Display credentials
echo "========================================="
echo "✅ INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "🌐 Access NocoDB at: https://db.magnitude-ai.com"
echo ""
echo "🔐 IMPORTANT - Save these credentials:"
echo "   PostgreSQL Password: ${POSTGRES_PASSWORD}"
echo "   Credentials file: /opt/nocodb/.env"
echo ""
echo "📁 Installation directory: /opt/nocodb"
echo ""
echo "🔧 Useful commands:"
echo "   View logs:     cd /opt/nocodb && docker compose logs -f"
echo "   Stop:          cd /opt/nocodb && docker compose stop"
echo "   Start:         cd /opt/nocodb && docker compose start"
echo "   Restart:       cd /opt/nocodb && docker compose restart"
echo "   Status:        cd /opt/nocodb && docker compose ps"
echo ""
echo "🎉 Open https://db.magnitude-ai.com to create your admin account!"
echo ""
echo "========================================="
