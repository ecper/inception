#!/bin/bash

# Master test runner for all Inception requirements

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test results tracking
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Function to run a test suite
run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}  $test_name${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
    
    if [ -f "$test_script" ]; then
        chmod +x "$test_script"
        if ./"$test_script"; then
            echo ""
            echo -e "${GREEN}✅ $test_name: PASSED${NC}"
            PASSED_SUITES=$((PASSED_SUITES + 1))
        else
            echo ""
            echo -e "${RED}❌ $test_name: FAILED${NC}"
            FAILED_SUITES=$((FAILED_SUITES + 1))
        fi
    else
        echo -e "${RED}Test script $test_script not found${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
    echo ""
}

# Banner
echo -e "${BOLD}${BLUE}"
echo "██╗███╗   ██╗ ██████╗███████╗██████╗ ████████╗██╗ ██████╗ ███╗   ██╗"
echo "██║████╗  ██║██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║"
echo "██║██╔██╗ ██║██║     █████╗  ██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║"
echo "██║██║╚██╗██║██║     ██╔══╝  ██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║"
echo "██║██║ ╚████║╚██████╗███████╗██║        ██║   ██║╚██████╔╝██║ ╚████║"
echo "╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
echo ""
echo "                  42 SCHOOL COMPLETE TEST SUITE"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -f "../Makefile" ] || [ ! -d "../srcs" ]; then
    echo -e "${RED}Error: Please run this script from the tester directory${NC}"
    echo "Usage: cd tester && ./run-all-tests.sh"
    exit 1
fi

# Change to project root
cd ..

echo -e "${YELLOW}Testing Inception project in: $(pwd)${NC}"
echo ""

# Check if containers should be running
echo -e "${CYAN}Checking container status...${NC}"
if docker ps | grep -q nginx && docker ps | grep -q wordpress && docker ps | grep -q mariadb; then
    echo -e "${GREEN}✓ All containers are running${NC}"
    CONTAINERS_RUNNING=true
else
    echo -e "${YELLOW}⚠ Containers not running. Some tests will be skipped.${NC}"
    echo "Run 'make' to start containers for complete testing."
    CONTAINERS_RUNNING=false
fi
echo ""

# Run test suites
run_test_suite "tester/test-all-requirements.sh" "COMPLETE REQUIREMENTS CHECK"

run_test_suite "tester/test-security.sh" "SECURITY REQUIREMENTS"

run_test_suite "tester/test-wordpress.sh" "WORDPRESS REQUIREMENTS"

if [ "$CONTAINERS_RUNNING" = true ]; then
    run_test_suite "tester/test-network.sh" "NETWORK CONNECTIVITY"
    run_test_suite "tester/test-performance.sh" "PERFORMANCE & RESOURCES"
else
    echo -e "${YELLOW}Skipping network and performance tests (containers not running)${NC}"
    echo ""
fi

# Final Results
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BOLD}${BLUE}           FINAL RESULTS${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""

echo -e "Test Suites Run: ${TOTAL_SUITES}"
echo -e "Passed: ${GREEN}${PASSED_SUITES}${NC}"
echo -e "Failed: ${RED}${FAILED_SUITES}${NC}"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}${BOLD}🎉 ALL TEST SUITES PASSED! 🎉${NC}"
    echo -e "${GREEN}Your Inception project meets all 42 requirements!${NC}"
    echo ""
    echo -e "${CYAN}Ready for evaluation! 🚀${NC}"
    
    # Generate test report
    echo "Generating test report..."
    {
        echo "# Inception Test Report"
        echo "Generated: $(date)"
        echo ""
        echo "## Test Results"
        echo "- Total Test Suites: $TOTAL_SUITES"
        echo "- Passed: $PASSED_SUITES"
        echo "- Failed: $FAILED_SUITES"
        echo ""
        echo "## Requirements Status"
        echo "✅ Project Structure"
        echo "✅ Dockerfile Validation"
        echo "✅ Security Requirements"
        echo "✅ WordPress User Requirements"
        echo "✅ Docker Compose Configuration"
        echo "✅ Network Configuration"
        echo "✅ Volume Configuration"
        echo "✅ TLS/SSL Configuration"
        if [ "$CONTAINERS_RUNNING" = true ]; then
            echo "✅ Runtime Validation"
            echo "✅ Network Connectivity"
            echo "✅ Performance Testing"
        fi
        echo ""
        echo "## Project Details"
        echo "- Domain: hauchida.42.fr"
        echo "- Admin User: wpmanager (compliant)"
        echo "- Regular User: hauchida"
        echo "- Database: MariaDB"
        echo "- Web Server: Nginx with TLS 1.2/1.3"
        echo "- Application: WordPress with PHP-FPM"
    } > test-report.md
    
    echo -e "${GREEN}Test report saved to: test-report.md${NC}"
    
else
    echo -e "${RED}${BOLD}❌ SOME TESTS FAILED${NC}"
    echo -e "${RED}Please review the failed tests above and fix the issues.${NC}"
    echo ""
    echo -e "${YELLOW}Common fixes:${NC}"
    echo "1. Check .env file configuration"
    echo "2. Verify Dockerfile base images (Alpine/Debian only)"
    echo "3. Ensure no hardcoded passwords"
    echo "4. Validate WordPress user setup"
    echo "5. Run 'make' to start containers for runtime tests"
fi

echo ""
echo -e "${CYAN}Test completed at: $(date)${NC}"

exit $FAILED_SUITES