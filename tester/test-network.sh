#!/bin/bash

# Network connectivity and communication test

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== NETWORK CONNECTIVITY TEST ===${NC}"
echo ""

# Check if containers are running
if ! docker ps | grep -q nginx || ! docker ps | grep -q wordpress || ! docker ps | grep -q mariadb; then
    echo -e "${RED}Not all containers are running. Please run 'make' first.${NC}"
    exit 1
fi

echo "Testing container network connectivity..."
echo ""

# Test 1: Nginx -> WordPress
echo -n "Nginx → WordPress (port 9000): "
if docker exec nginx nc -zv wordpress 9000 2>/dev/null; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Test 2: WordPress -> MariaDB
echo -n "WordPress → MariaDB (port 3306): "
if docker exec wordpress nc -zv mariadb 3306 2>/dev/null; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Test 3: Database authentication
echo -n "Database authentication: "
if docker exec wordpress mysql -h mariadb -u wp_user -pwppassword123 -e "SELECT 1;" wordpress_db >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Success${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Test 4: PHP-FPM connectivity
echo -n "PHP-FPM service: "
if docker exec nginx nc -zv wordpress 9000 2>/dev/null; then
    echo -e "${GREEN}✓ Active${NC}"
else
    echo -e "${RED}✗ Inactive${NC}"
fi

# Test 5: HTTPS endpoint
echo -n "HTTPS endpoint (443): "
if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:443 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

echo ""
echo "Network Information:"
echo "- Custom network: $(docker network ls | grep inception)"
echo "- Container IPs:"
docker inspect nginx wordpress mariadb --format '{{.Name}}: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'