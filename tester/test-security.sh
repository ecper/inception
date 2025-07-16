#!/bin/bash

# Security requirements test

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== SECURITY REQUIREMENTS TEST ===${NC}"
echo ""

SECURITY_TESTS=0
SECURITY_PASSED=0

# Test 1: No hardcoded passwords in Dockerfiles
echo "1. Dockerfile Security"
if ! grep -r -i "password\|pass" srcs/requirements/*/Dockerfile | grep -v "comment\|#" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ No hardcoded passwords in Dockerfiles${NC}"
    SECURITY_PASSED=$((SECURITY_PASSED + 1))
else
    echo -e "${RED}✗ Hardcoded passwords found in Dockerfiles${NC}"
    grep -r -i "password\|pass" srcs/requirements/*/Dockerfile | grep -v "comment\|#"
fi
SECURITY_TESTS=$((SECURITY_TESTS + 1))

# Test 2: Environment variables usage
echo ""
echo "2. Environment Variables"
if [ -f "srcs/.env" ]; then
    echo -e "${GREEN}✓ .env file exists${NC}"
    SECURITY_PASSED=$((SECURITY_PASSED + 1))
    
    # Check required environment variables
    source srcs/.env
    if [ -n "$MYSQL_ROOT_PASSWORD" ] && [ -n "$MYSQL_PASSWORD" ] && [ -n "$WORDPRESS_ADMIN_PASSWORD" ]; then
        echo -e "${GREEN}✓ All required passwords are set in environment${NC}"
        SECURITY_PASSED=$((SECURITY_PASSED + 1))
    else
        echo -e "${RED}✗ Some passwords missing in .env${NC}"
    fi
    SECURITY_TESTS=$((SECURITY_TESTS + 1))
else
    echo -e "${RED}✗ .env file not found${NC}"
fi
SECURITY_TESTS=$((SECURITY_TESTS + 1))

# Test 3: TLS Configuration
echo ""
echo "3. TLS/SSL Configuration"
if grep -q "ssl_protocols.*TLSv1\.[23]" srcs/requirements/nginx/conf/nginx.conf; then
    echo -e "${GREEN}✓ TLS 1.2/1.3 configured${NC}"
    SECURITY_PASSED=$((SECURITY_PASSED + 1))
else
    echo -e "${RED}✗ TLS not properly configured${NC}"
fi
SECURITY_TESTS=$((SECURITY_TESTS + 1))

if grep -q "listen 443 ssl" srcs/requirements/nginx/conf/nginx.conf; then
    echo -e "${GREEN}✓ HTTPS properly configured${NC}"
    SECURITY_PASSED=$((SECURITY_PASSED + 1))
else
    echo -e "${RED}✗ HTTPS not configured${NC}"
fi
SECURITY_TESTS=$((SECURITY_TESTS + 1))

# Test 4: No HTTP exposure
if ! grep -q "listen 80" srcs/requirements/nginx/conf/nginx.conf && ! grep -q "80:80" srcs/docker-compose.yml; then
    echo -e "${GREEN}✓ No HTTP (port 80) exposure${NC}"
    SECURITY_PASSED=$((SECURITY_PASSED + 1))
else
    echo -e "${RED}✗ HTTP port is exposed${NC}"
fi
SECURITY_TESTS=$((SECURITY_TESTS + 1))

# Test 5: Container security
echo ""
echo "4. Container Security"
if docker ps >/dev/null 2>&1; then
    # Check if containers run as non-root (where applicable)
    echo "Container process users:"
    for container in nginx wordpress mariadb; do
        if docker ps | grep -q $container; then
            USER_PROCESSES=$(docker exec $container ps -eo user,comm --no-headers 2>/dev/null | head -5)
            echo "  $container: $USER_PROCESSES"
        fi
    done
    
    # Check no privileged containers
    if ! docker ps --format "table {{.Names}}\t{{.Command}}" | grep -i "privileged"; then
        echo -e "${GREEN}✓ No privileged containers${NC}"
        SECURITY_PASSED=$((SECURITY_PASSED + 1))
    else
        echo -e "${RED}✗ Privileged containers detected${NC}"
    fi
    SECURITY_TESTS=$((SECURITY_TESTS + 1))
fi

# Test 6: Network security
echo ""
echo "5. Network Security"
if grep -q "networks:" srcs/docker-compose.yml && ! grep -q "network_mode.*host" srcs/docker-compose.yml; then
    echo -e "${GREEN}✓ Custom network used, host network avoided${NC}"
    SECURITY_PASSED=$((SECURITY_PASSED + 1))
else
    echo -e "${RED}✗ Network configuration not secure${NC}"
fi
SECURITY_TESTS=$((SECURITY_TESTS + 1))

# Test 7: File permissions
echo ""
echo "6. File Permissions"
if [ -f "srcs/.env" ]; then
    ENV_PERMS=$(stat -c "%a" srcs/.env)
    if [ "$ENV_PERMS" = "644" ] || [ "$ENV_PERMS" = "600" ]; then
        echo -e "${GREEN}✓ .env file has appropriate permissions ($ENV_PERMS)${NC}"
        SECURITY_PASSED=$((SECURITY_PASSED + 1))
    else
        echo -e "${YELLOW}Warning: .env file permissions are $ENV_PERMS${NC}"
    fi
    SECURITY_TESTS=$((SECURITY_TESTS + 1))
fi

# Test 8: SSL Certificate
echo ""
echo "7. SSL Certificate"
if docker ps | grep -q nginx; then
    if docker exec nginx test -f /etc/nginx/ssl/inception.crt && docker exec nginx test -f /etc/nginx/ssl/inception.key; then
        echo -e "${GREEN}✓ SSL certificate files exist${NC}"
        SECURITY_PASSED=$((SECURITY_PASSED + 1))
        
        # Check certificate validity
        CERT_INFO=$(docker exec nginx openssl x509 -in /etc/nginx/ssl/inception.crt -noout -subject -dates 2>/dev/null)
        echo "Certificate info: $CERT_INFO"
    else
        echo -e "${RED}✗ SSL certificate files missing${NC}"
    fi
    SECURITY_TESTS=$((SECURITY_TESTS + 1))
fi

# Test 9: Database security
echo ""
echo "8. Database Security"
if docker ps | grep -q mariadb; then
    # Check if root can only connect from localhost
    if docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT User, Host FROM mysql.user WHERE User='root';" 2>/dev/null | grep -q "localhost"; then
        echo -e "${GREEN}✓ Root user restricted to localhost${NC}"
        SECURITY_PASSED=$((SECURITY_PASSED + 1))
    else
        echo -e "${RED}✗ Root user not properly restricted${NC}"
    fi
    SECURITY_TESTS=$((SECURITY_TESTS + 1))
    
    # Check if test database is removed
    if ! docker exec mariadb mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;" 2>/dev/null | grep -q "test"; then
        echo -e "${GREEN}✓ Test database removed${NC}"
        SECURITY_PASSED=$((SECURITY_PASSED + 1))
    else
        echo -e "${RED}✗ Test database still exists${NC}"
    fi
    SECURITY_TESTS=$((SECURITY_TESTS + 1))
fi

# Summary
echo ""
echo -e "${BLUE}=== Security Test Summary ===${NC}"
echo "Passed: $SECURITY_PASSED/$SECURITY_TESTS tests"

if [ $SECURITY_PASSED -eq $SECURITY_TESTS ]; then
    echo -e "${GREEN}✓ All security requirements met${NC}"
    exit 0
else
    echo -e "${RED}✗ Some security requirements not met${NC}"
    exit 1
fi