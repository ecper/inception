#!/bin/bash

# WordPress specific requirements test

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== WORDPRESS REQUIREMENTS TEST ===${NC}"
echo ""

# Check if containers are running
if ! docker ps | grep -q wordpress; then
    echo -e "${RED}WordPress container is not running. Please run 'make' first.${NC}"
    exit 1
fi

# Load environment variables
if [ -f "srcs/.env" ]; then
    source srcs/.env
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

echo "Testing WordPress user requirements..."
echo ""

# Test 1: Admin username validation
echo "1. Admin Username Validation"
FORBIDDEN_NAMES=("admin" "Admin" "administrator" "Administrator")
IS_ADMIN_VALID=true

for forbidden in "${FORBIDDEN_NAMES[@]}"; do
    if [[ "$WORDPRESS_ADMIN_USER" == "$forbidden" ]]; then
        echo -e "${RED}✗ Admin username '$WORDPRESS_ADMIN_USER' contains forbidden word '$forbidden'${NC}"
        IS_ADMIN_VALID=false
        break
    fi
done

if [ "$IS_ADMIN_VALID" = true ]; then
    echo -e "${GREEN}✓ Admin username '$WORDPRESS_ADMIN_USER' is valid${NC}"
fi

# Test 2: Regular user configuration
echo ""
echo "2. Regular User Configuration"
if [ -n "$WORDPRESS_USER" ] && [ -n "$WORDPRESS_USER_EMAIL" ] && [ -n "$WORDPRESS_USER_PASSWORD" ]; then
    echo -e "${GREEN}✓ Regular user '$WORDPRESS_USER' is configured${NC}"
else
    echo -e "${RED}✗ Regular user configuration incomplete${NC}"
fi

# Test 3: WordPress installation check
echo ""
echo "3. WordPress Installation Check"
if docker exec wordpress test -f /var/www/html/wp-config.php; then
    echo -e "${GREEN}✓ WordPress is installed${NC}"
else
    echo -e "${RED}✗ WordPress installation not found${NC}"
    exit 1
fi

# Test 4: Database connectivity
echo ""
echo "4. Database Connectivity"
if docker exec wordpress wp db check --allow-root >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
fi

# Test 5: User existence in WordPress
echo ""
echo "5. WordPress User Verification"

# Check if WP-CLI is working
if ! docker exec wordpress wp --info --allow-root >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: WP-CLI not accessible, skipping user checks${NC}"
else
    # Check admin user
    if docker exec wordpress wp user get "$WORDPRESS_ADMIN_USER" --allow-root >/dev/null 2>&1; then
        ADMIN_ROLE=$(docker exec wordpress wp user get "$WORDPRESS_ADMIN_USER" --field=roles --allow-root 2>/dev/null)
        if [[ "$ADMIN_ROLE" == *"administrator"* ]]; then
            echo -e "${GREEN}✓ Admin user '$WORDPRESS_ADMIN_USER' exists with administrator role${NC}"
        else
            echo -e "${RED}✗ Admin user exists but doesn't have administrator role${NC}"
        fi
    else
        echo -e "${RED}✗ Admin user '$WORDPRESS_ADMIN_USER' not found${NC}"
    fi
    
    # Check regular user
    if docker exec wordpress wp user get "$WORDPRESS_USER" --allow-root >/dev/null 2>&1; then
        REGULAR_ROLE=$(docker exec wordpress wp user get "$WORDPRESS_USER" --field=roles --allow-root 2>/dev/null)
        echo -e "${GREEN}✓ Regular user '$WORDPRESS_USER' exists with role: $REGULAR_ROLE${NC}"
    else
        echo -e "${RED}✗ Regular user '$WORDPRESS_USER' not found${NC}"
    fi
fi

# Test 6: WordPress configuration
echo ""
echo "6. WordPress Configuration"
CONFIG_TESTS=0
CONFIG_PASSED=0

# Check database configuration
if docker exec wordpress grep -q "$WORDPRESS_DB_NAME" /var/www/html/wp-config.php; then
    echo -e "${GREEN}✓ Database name configured correctly${NC}"
    CONFIG_PASSED=$((CONFIG_PASSED + 1))
else
    echo -e "${RED}✗ Database name not configured${NC}"
fi
CONFIG_TESTS=$((CONFIG_TESTS + 1))

if docker exec wordpress grep -q "$WORDPRESS_DB_USER" /var/www/html/wp-config.php; then
    echo -e "${GREEN}✓ Database user configured correctly${NC}"
    CONFIG_PASSED=$((CONFIG_PASSED + 1))
else
    echo -e "${RED}✗ Database user not configured${NC}"
fi
CONFIG_TESTS=$((CONFIG_TESTS + 1))

if docker exec wordpress grep -q "$WORDPRESS_DB_HOST" /var/www/html/wp-config.php; then
    echo -e "${GREEN}✓ Database host configured correctly${NC}"
    CONFIG_PASSED=$((CONFIG_PASSED + 1))
else
    echo -e "${RED}✗ Database host not configured${NC}"
fi
CONFIG_TESTS=$((CONFIG_TESTS + 1))

# Test 7: File permissions
echo ""
echo "7. File Permissions"
OWNER=$(docker exec wordpress stat -c "%U" /var/www/html/index.php 2>/dev/null)
if [ "$OWNER" = "nobody" ] || [ "$OWNER" = "www-data" ]; then
    echo -e "${GREEN}✓ WordPress files have correct ownership${NC}"
else
    echo -e "${YELLOW}Warning: WordPress files owned by '$OWNER'${NC}"
fi

# Test 8: WordPress functionality
echo ""
echo "8. WordPress Functionality"
if docker exec wordpress wp option get siteurl --allow-root 2>/dev/null | grep -q "https://"; then
    SITE_URL=$(docker exec wordpress wp option get siteurl --allow-root 2>/dev/null)
    echo -e "${GREEN}✓ WordPress site URL: $SITE_URL${NC}"
else
    echo -e "${RED}✗ WordPress site URL not properly configured${NC}"
fi

echo ""
echo "=== WordPress Test Summary ==="
echo "Admin user: $WORDPRESS_ADMIN_USER"
echo "Regular user: $WORDPRESS_USER"
echo "Database: $WORDPRESS_DB_NAME"
echo "Host: $WORDPRESS_DB_HOST"

if [ "$IS_ADMIN_VALID" = true ] && [ -n "$WORDPRESS_USER" ]; then
    echo -e "${GREEN}✓ All WordPress requirements satisfied${NC}"
else
    echo -e "${RED}✗ Some WordPress requirements not met${NC}"
fi