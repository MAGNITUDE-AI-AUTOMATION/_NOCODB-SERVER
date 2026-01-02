#!/bin/bash

# NocoDB Installation Script - Phase 2
# Server: 72.62.149.57 (Ubuntu 22.04)
# Domain: db.magnitude-ai.com

set -e  # Exit on error

echo "=================================="
echo "NocoDB Installation - Phase 2"
echo "=================================="
echo ""

# Step 1: Create directory structure
echo "Step 1: Creating directory structure..."
mkdir -p /opt/nocodb
cd /opt/nocodb

# Step 2: Generate secure passwords
echo "Step 2: Generating secure passwords..."
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
NC_AUTH_JWT_SECRET=$(openssl rand -base64 32)

# Step 3: Create .env file
echo "Step 3: Creating .env file..."
cat > .env << EOF
# Auto-generated on $(date)
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
NC_AUTH_JWT_SECRET=${NC_AUTH_JWT_SECRET}
EOF

echo "✅ Passwords generated and saved to /opt/nocodb/.env"
echo ""

# Step 4: Create docker-compose.yml
echo "Step 4: Creating docker-compose.yml..."
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
    driver: local
  nocodb_data:
    driver: local

networks:
  nocodb-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml created"
echo ""

# Step 5: Start Docker containers
echo "Step 5: Starting Docker containers..."
docker compose up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 10

# Check container status
docker compose ps

echo ""
echo "✅ NocoDB containers started!"
echo ""
echo "=================================="
echo "IMPORTANT INFORMATION"
echo "=================================="
echo ""
echo "📁 Installation directory: /opt/nocodb"
echo "🔐 Passwords saved in: /opt/nocodb/.env"
echo "🐘 PostgreSQL Password: ${POSTGRES_PASSWORD}"
echo ""
echo "⚠️  SAVE THESE CREDENTIALS SECURELY!"
echo ""
echo "Next steps:"
echo "1. Configure nginx reverse proxy"
echo "2. Set up SSL certificate with certbot"
echo "3. Access NocoDB at https://db.magnitude-ai.com"
echo ""
echo "=================================="
