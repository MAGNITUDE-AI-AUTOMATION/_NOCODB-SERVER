#!/bin/bash

# Setup Nginx and SSL for NocoDB
# Server: 72.62.149.57
# Domain: db.magnitude-ai.com

set -e

echo "=================================="
echo "Nginx & SSL Setup for NocoDB"
echo "=================================="
echo ""

# Step 1: Create nginx config
echo "Step 1: Creating nginx configuration..."
cat > /etc/nginx/sites-available/nocodb << 'EOF'
server {
    server_name db.magnitude-ai.com;

    # Proxy to NocoDB container
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Standard proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeouts for long operations
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    listen 80;
}
EOF

echo "✅ Nginx config created at /etc/nginx/sites-available/nocodb"
echo ""

# Step 2: Enable the site
echo "Step 2: Enabling nginx site..."
ln -sf /etc/nginx/sites-available/nocodb /etc/nginx/sites-enabled/

# Step 3: Test nginx config
echo "Step 3: Testing nginx configuration..."
nginx -t

# Step 4: Reload nginx
echo "Step 4: Reloading nginx..."
systemctl reload nginx

echo "✅ Nginx configured and reloaded"
echo ""

# Step 5: Setup SSL with certbot
echo "Step 5: Setting up SSL certificate..."
echo "This will:"
echo "  - Request a certificate for db.magnitude-ai.com"
echo "  - Automatically configure nginx for HTTPS"
echo "  - Set up auto-renewal"
echo ""

certbot --nginx -d db.magnitude-ai.com --non-interactive --agree-tos --register-unsafely-without-email

echo ""
echo "✅ SSL certificate installed!"
echo ""

# Step 6: Verify
echo "Step 6: Verifying setup..."
systemctl status nginx --no-pager
echo ""

echo "=================================="
echo "SETUP COMPLETE!"
echo "=================================="
echo ""
echo "🎉 NocoDB is now accessible at:"
echo "   https://db.magnitude-ai.com"
echo ""
echo "📝 Next steps:"
echo "   1. Open https://db.magnitude-ai.com in your browser"
echo "   2. Create your admin account"
echo "   3. Start building your database!"
echo ""
echo "🔒 SSL certificate will auto-renew via certbot"
echo ""
echo "=================================="
