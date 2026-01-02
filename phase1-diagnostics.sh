#!/bin/bash

# NocoDB Server - Phase 1 Diagnostic Script
# Run this on your Ubuntu VPS (72.62.149.57) and paste back the output

echo "=================================="
echo "NOCODB PRE-INSTALLATION DIAGNOSTICS"
echo "Server: 72.62.149.57"
echo "Date: $(date)"
echo "=================================="
echo ""

echo "--- 1. OS VERSION ---"
cat /etc/os-release
echo ""

echo "--- 2. DISK SPACE ---"
df -h
echo ""

echo "--- 3. RAM USAGE ---"
free -h
echo ""

echo "--- 4. CPU INFO ---"
lscpu | grep -E "^CPU\(s\)|^Model name|^Architecture"
echo ""

echo "--- 5. CPU USAGE ---"
top -bn1 | head -n 5
echo ""

echo "--- 6. DOCKER VERSION CHECK ---"
if command -v docker &> /dev/null; then
    echo "Docker is installed:"
    docker --version
    docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo "Docker Compose not found"
else
    echo "Docker is NOT installed"
fi
echo ""

echo "--- 7. RUNNING DOCKER CONTAINERS ---"
if command -v docker &> /dev/null; then
    docker ps -a
else
    echo "Docker not installed - no containers to list"
fi
echo ""

echo "--- 8. DOCKER NETWORKS ---"
if command -v docker &> /dev/null; then
    docker network ls
else
    echo "Docker not installed - no networks to list"
fi
echo ""

echo "--- 9. NGINX STATUS ---"
systemctl status nginx --no-pager
echo ""

echo "--- 10. NGINX VERSION ---"
nginx -v
echo ""

echo "--- 11. NGINX SITES-ENABLED ---"
ls -la /etc/nginx/sites-enabled/
echo ""

echo "--- 12. NGINX SITE CONFIGURATIONS ---"
for file in /etc/nginx/sites-enabled/*; do
    if [ -f "$file" ]; then
        echo "=== Content of $file ==="
        cat "$file"
        echo ""
    fi
done
echo ""

echo "--- 13. PORTS IN USE ---"
echo "All listening ports:"
ss -tuln | grep LISTEN
echo ""

echo "--- 14. SPECIFIC PORT CHECK (8080, 5432, 80, 443) ---"
echo "Port 8080:"
ss -tuln | grep :8080 || echo "Port 8080 is FREE"
echo "Port 5432:"
ss -tuln | grep :5432 || echo "Port 5432 is FREE"
echo "Port 80:"
ss -tuln | grep :80
echo "Port 443:"
ss -tuln | grep :443
echo ""

echo "--- 15. CERTBOT STATUS ---"
if command -v certbot &> /dev/null; then
    echo "Certbot is installed:"
    certbot --version
else
    echo "Certbot is NOT installed"
fi
echo ""

echo "--- 16. SSL CERTIFICATES ---"
if [ -d "/etc/letsencrypt/live" ]; then
    echo "Existing SSL certificates:"
    ls -la /etc/letsencrypt/live/
else
    echo "No /etc/letsencrypt/live directory found"
fi
echo ""

echo "--- 17. FIREWALL STATUS (UFW) ---"
if command -v ufw &> /dev/null; then
    echo "UFW Status:"
    ufw status verbose
else
    echo "UFW not installed"
fi
echo ""

echo "--- 18. FIREWALL STATUS (IPTABLES) ---"
echo "Current iptables rules:"
iptables -L -n -v
echo ""

echo "--- 19. RUNNING SERVICES ON STANDARD PORTS ---"
lsof -i :80 2>/dev/null || echo "Nothing on port 80"
lsof -i :443 2>/dev/null || echo "Nothing on port 443"
lsof -i :8080 2>/dev/null || echo "Nothing on port 8080"
lsof -i :5432 2>/dev/null || echo "Nothing on port 5432"
echo ""

echo "--- 20. SYSTEM LOAD ---"
uptime
echo ""

echo "=================================="
echo "DIAGNOSTIC COMPLETE"
echo "=================================="
echo ""
echo "Please copy ALL the output above and paste it back for analysis."
