#!/bin/bash

# 42 Inception Project - Complete Requirements Test
# 全要件を検証するテストスイート

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print test results
print_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗${NC} $2"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Function to check if containers are running
check_containers_running() {
    local nginx_status=$(docker ps --format '{{.Names}}' | grep -c nginx || echo 0)
    local wordpress_status=$(docker ps --format '{{.Names}}' | grep -c wordpress || echo 0)
    local mariadb_status=$(docker ps --format '{{.Names}}' | grep -c mariadb || echo 0)
    
    [ $nginx_status -eq 1 ] && [ $wordpress_status -eq 1 ] && [ $mariadb_status -eq 1 ]
}

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  42 INCEPTION PROJECT TEST SUITE${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "Makefile" ] || [ ! -d "srcs" ]; then
    echo -e "${RED}Error: Please run this script from the inception project root directory${NC}"
    exit 1
fi

# Section 1: Project Structure
echo -e "${CYAN}1. PROJECT STRUCTURE${NC}"
[ -f "Makefile" ]; print_test $? "Makefile exists"
[ -d "srcs" ]; print_test $? "srcs directory exists"
[ -f "srcs/docker-compose.yml" ]; print_test $? "docker-compose.yml exists"
[ -f "srcs/.env" ]; print_test $? ".env file exists"
[ -d "srcs/requirements/nginx" ]; print_test $? "nginx directory exists"
[ -d "srcs/requirements/wordpress" ]; print_test $? "wordpress directory exists"
[ -d "srcs/requirements/mariadb" ]; print_test $? "mariadb directory exists"
echo ""

# Section 2: Dockerfile Validation
echo -e "${CYAN}2. DOCKERFILE VALIDATION${NC}"
[ -f "srcs/requirements/nginx/Dockerfile" ]; print_test $? "nginx Dockerfile exists"
[ -f "srcs/requirements/wordpress/Dockerfile" ]; print_test $? "wordpress Dockerfile exists"
[ -f "srcs/requirements/mariadb/Dockerfile" ]; print_test $? "mariadb Dockerfile exists"

# Check base images (only Alpine/Debian allowed)
grep -E "^FROM\s+(alpine|debian)" srcs/requirements/nginx/Dockerfile > /dev/null
print_test $? "nginx uses Alpine/Debian base image"
grep -E "^FROM\s+(alpine|debian)" srcs/requirements/wordpress/Dockerfile > /dev/null
print_test $? "wordpress uses Alpine/Debian base image"
grep -E "^FROM\s+(alpine|debian)" srcs/requirements/mariadb/Dockerfile > /dev/null
print_test $? "mariadb uses Alpine/Debian base image"

# Check forbidden pre-built images
! grep -E "^FROM\s+(nginx|wordpress|mariadb|mysql|php):" srcs/requirements/*/Dockerfile > /dev/null
print_test $? "No forbidden pre-built service images used"
echo ""

# Section 3: Security Requirements
echo -e "${CYAN}3. SECURITY REQUIREMENTS${NC}"
# Check no hardcoded passwords in Dockerfiles
! grep -iE "(password|pass).*=" srcs/requirements/*/Dockerfile > /dev/null
print_test $? "No hardcoded passwords in Dockerfiles"

# Check environment variables are used
grep -E "MYSQL_ROOT_PASSWORD|MYSQL_PASSWORD|WORDPRESS.*PASSWORD" srcs/.env > /dev/null
print_test $? "Passwords are stored in .env file"

# Check .env file is properly configured
source srcs/.env
[ -n "$MYSQL_ROOT_PASSWORD" ] && [ -n "$MYSQL_PASSWORD" ] && [ -n "$WORDPRESS_ADMIN_PASSWORD" ]
print_test $? "All required passwords are set in .env"
echo ""

# Section 4: WordPress User Requirements
echo -e "${CYAN}4. WORDPRESS USER REQUIREMENTS${NC}"
source srcs/.env

# Check admin username doesn't contain forbidden words
FORBIDDEN_NAMES=("admin" "Admin" "administrator" "Administrator")
IS_ADMIN_VALID=true
for forbidden in "${FORBIDDEN_NAMES[@]}"; do
    if [[ "$WORDPRESS_ADMIN_USER" == "$forbidden" ]]; then
        IS_ADMIN_VALID=false
        break
    fi
done
[ "$IS_ADMIN_VALID" = true ]; print_test $? "Admin username doesn't contain forbidden words"

# Check regular user is defined
[ -n "$WORDPRESS_USER" ] && [ -n "$WORDPRESS_USER_EMAIL" ] && [ -n "$WORDPRESS_USER_PASSWORD" ]
print_test $? "Regular user is properly defined in .env"
echo ""

# Section 5: Docker Compose Configuration
echo -e "${CYAN}5. DOCKER COMPOSE CONFIGURATION${NC}"
grep -E "build:.*requirements/nginx" srcs/docker-compose.yml > /dev/null
print_test $? "nginx service builds from Dockerfile"
grep -E "build:.*requirements/wordpress" srcs/docker-compose.yml > /dev/null
print_test $? "wordpress service builds from Dockerfile"
grep -E "build:.*requirements/mariadb" srcs/docker-compose.yml > /dev/null
print_test $? "mariadb service builds from Dockerfile"

# Check port configuration
grep "443:443" srcs/docker-compose.yml > /dev/null
print_test $? "Port 443 is exposed for nginx"
! grep -E "80:80|8080:8080" srcs/docker-compose.yml > /dev/null
print_test $? "No HTTP port (80) is exposed"

# Check restart policy
RESTART_COUNT=$(grep -c "restart: always" srcs/docker-compose.yml)
[ $RESTART_COUNT -eq 3 ]; print_test $? "All containers have restart: always"

# Check no forbidden configurations
! grep -E "network_mode:\s*host" srcs/docker-compose.yml > /dev/null
print_test $? "network_mode: host is not used"
! grep -E "(links:|--link)" srcs/docker-compose.yml > /dev/null
print_test $? "links are not used"
echo ""

# Section 6: Network Configuration
echo -e "${CYAN}6. NETWORK CONFIGURATION${NC}"
grep -E "networks:" srcs/docker-compose.yml > /dev/null
print_test $? "Custom network is defined"
grep -E "driver:\s*bridge" srcs/docker-compose.yml > /dev/null
print_test $? "Bridge network driver is used"
echo ""

# Section 7: Volume Configuration
echo -e "${CYAN}7. VOLUME CONFIGURATION${NC}"
grep -E "wp-volume:" srcs/docker-compose.yml > /dev/null
print_test $? "WordPress volume is defined"
grep -E "db-volume:" srcs/docker-compose.yml > /dev/null
print_test $? "Database volume is defined"

# Check volume persistence
grep -E "device:.*data" srcs/docker-compose.yml > /dev/null
print_test $? "Volumes are mapped to host directories"
echo ""

# Section 8: TLS/SSL Configuration
echo -e "${CYAN}8. TLS/SSL CONFIGURATION${NC}"
grep -E "ssl_protocols.*TLSv1\.[23]" srcs/requirements/nginx/conf/nginx.conf > /dev/null
print_test $? "TLS 1.2/1.3 is configured"
grep "listen 443 ssl" srcs/requirements/nginx/conf/nginx.conf > /dev/null
print_test $? "HTTPS is properly configured"
! grep "listen 80" srcs/requirements/nginx/conf/nginx.conf > /dev/null
print_test $? "No HTTP (port 80) listener configured"
echo ""

# Section 9: Container Runtime Check (if containers are running)
echo -e "${CYAN}9. RUNTIME VALIDATION${NC}"
if check_containers_running; then
    echo "Containers are running, performing runtime checks..."
    
    # Check container status
    docker ps | grep "nginx.*Up" > /dev/null
    print_test $? "nginx container is running"
    docker ps | grep "wordpress.*Up" > /dev/null
    print_test $? "wordpress container is running"
    docker ps | grep "mariadb.*Up" > /dev/null
    print_test $? "mariadb container is running"
    
    # Check port mapping
    docker ps | grep "443->443" > /dev/null
    print_test $? "Port 443 is correctly mapped"
    
    # Check WordPress users (if WordPress is accessible)
    if docker exec wordpress wp user list --allow-root >/dev/null 2>&1; then
        # Check admin user
        ADMIN_COUNT=$(docker exec wordpress wp user list --role=administrator --field=user_login --allow-root 2>/dev/null | grep -v "^admin$\|^Admin$\|^administrator$\|^Administrator$" | wc -l)
        [ "$ADMIN_COUNT" -gt 0 ]; print_test $? "Valid admin user exists"
        
        # Check regular user
        REGULAR_COUNT=$(docker exec wordpress wp user list --allow-root 2>/dev/null | tail -n +2 | grep -v "administrator" | wc -l)
        [ "$REGULAR_COUNT" -gt 0 ]; print_test $? "Regular user exists"
    else
        echo -e "${YELLOW}WordPress not yet accessible, skipping user checks${NC}"
    fi
    
    # Check database connectivity
    docker exec mariadb mysql -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "SELECT 1;" $WORDPRESS_DB_NAME >/dev/null 2>&1
    print_test $? "Database connectivity works"
    
    # Check network connectivity
    docker exec nginx nc -zv wordpress 9000 >/dev/null 2>&1
    print_test $? "nginx can connect to wordpress"
    docker exec wordpress nc -zv mariadb 3306 >/dev/null 2>&1
    print_test $? "wordpress can connect to mariadb"
    
else
    echo -e "${YELLOW}Containers are not running. Start with 'make' to perform runtime checks.${NC}"
fi
echo ""

# Section 10: Makefile Targets
echo -e "${CYAN}10. MAKEFILE VALIDATION${NC}"
grep -E "^all:" Makefile > /dev/null
print_test $? "all target exists"
grep -E "^clean:" Makefile > /dev/null
print_test $? "clean target exists"
grep -E "^fclean:" Makefile > /dev/null
print_test $? "fclean target exists"
grep -E "^re:" Makefile > /dev/null
print_test $? "re target exists"
echo ""

# Section 11: Forbidden Practices Check
echo -e "${CYAN}11. FORBIDDEN PRACTICES CHECK${NC}"
! grep -r "sleep infinity\|tail -f\|while true" srcs/requirements/ > /dev/null 2>&1
print_test $? "No infinite loops in containers"

# Check if any ready-made images are pulled (exclude alpine and debian)
! grep -r "docker pull" srcs/requirements/ > /dev/null 2>&1 && \
! grep -r "^FROM" srcs/requirements/ | grep -v "FROM alpine\|FROM debian" > /dev/null 2>&1
print_test $? "No forbidden image pulls detected"
echo ""

# Final Results
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}           TEST RESULTS${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Total Tests: ${TOTAL_TESTS}"
echo -e "Passed: ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed: ${RED}${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Project meets 42 requirements!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix the issues above.${NC}"
    exit 1
fi