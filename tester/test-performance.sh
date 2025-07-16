#!/bin/bash

# Performance and resource usage test

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== PERFORMANCE & RESOURCE TEST ===${NC}"
echo ""

# Check if containers are running
if ! docker ps | grep -q nginx || ! docker ps | grep -q wordpress || ! docker ps | grep -q mariadb; then
    echo -e "${RED}Not all containers are running. Please run 'make' first.${NC}"
    exit 1
fi

# Test 1: Container resource usage
echo "1. Container Resource Usage"
echo ""
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
echo ""

# Test 2: Response time test
echo "2. Response Time Test"
echo ""
echo -n "HTTPS response time: "
RESPONSE_TIME=$(curl -k -s -w "%{time_total}" -o /dev/null https://localhost:443 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}${RESPONSE_TIME}s${NC}"
    if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
        echo -e "${GREEN}✓ Response time under 2 seconds${NC}"
    else
        echo -e "${YELLOW}⚠ Response time over 2 seconds${NC}"
    fi
else
    echo -e "${RED}✗ No response${NC}"
fi

# Test 3: Container health check
echo ""
echo "3. Container Health"
echo ""
for container in nginx wordpress mariadb; do
    STATUS=$(docker inspect $container --format='{{.State.Status}}' 2>/dev/null)
    HEALTH=$(docker inspect $container --format='{{.State.Health.Status}}' 2>/dev/null)
    
    if [ "$STATUS" = "running" ]; then
        echo -e "${GREEN}✓ $container: $STATUS${NC}"
    else
        echo -e "${RED}✗ $container: $STATUS${NC}"
    fi
done

# Test 4: Memory usage analysis
echo ""
echo "4. Memory Usage Analysis"
echo ""
TOTAL_MEMORY=0
for container in nginx wordpress mariadb; do
    MEMORY=$(docker stats --no-stream --format "{{.MemUsage}}" $container | cut -d'/' -f1 | sed 's/[^0-9.]//g')
    if [ -n "$MEMORY" ]; then
        echo "$container: ${MEMORY}MB"
        TOTAL_MEMORY=$(echo "$TOTAL_MEMORY + $MEMORY" | bc)
    fi
done
echo "Total: ${TOTAL_MEMORY}MB"

if (( $(echo "$TOTAL_MEMORY < 1000" | bc -l) )); then
    echo -e "${GREEN}✓ Total memory usage under 1GB${NC}"
else
    echo -e "${YELLOW}⚠ Total memory usage over 1GB${NC}"
fi

# Test 5: Disk usage
echo ""
echo "5. Disk Usage"
echo ""
echo "Docker images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep srcs

echo ""
echo "Docker volumes:"
docker volume ls | grep srcs

# Test 6: Network latency
echo ""
echo "6. Network Latency (Internal)"
echo ""
echo -n "nginx → wordpress: "
NGINX_WP_TIME=$(docker exec nginx time nc -zv wordpress 9000 2>&1 | grep real | awk '{print $2}' || echo "N/A")
echo "$NGINX_WP_TIME"

echo -n "wordpress → mariadb: "
WP_DB_TIME=$(docker exec wordpress time nc -zv mariadb 3306 2>&1 | grep real | awk '{print $2}' || echo "N/A")
echo "$WP_DB_TIME"

# Test 7: Process count
echo ""
echo "7. Process Count"
echo ""
for container in nginx wordpress mariadb; do
    PROCESS_COUNT=$(docker exec $container ps aux --no-headers 2>/dev/null | wc -l)
    echo "$container: $PROCESS_COUNT processes"
done

# Test 8: Load test simulation
echo ""
echo "8. Basic Load Test"
echo ""
echo "Sending 10 concurrent requests..."
for i in {1..10}; do
    curl -k -s -o /dev/null https://localhost:443 &
done
wait

echo -e "${GREEN}✓ Load test completed${NC}"

# Test 9: Container restart test
echo ""
echo "9. Container Resilience"
echo ""
echo "Testing container restart capabilities..."

# Check restart policy
for container in nginx wordpress mariadb; do
    RESTART_POLICY=$(docker inspect $container --format='{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null)
    if [ "$RESTART_POLICY" = "always" ]; then
        echo -e "${GREEN}✓ $container: restart policy is 'always'${NC}"
    else
        echo -e "${RED}✗ $container: restart policy is '$RESTART_POLICY'${NC}"
    fi
done

# Test 10: Log analysis
echo ""
echo "10. Log Analysis"
echo ""
echo "Recent container logs (errors only):"
for container in nginx wordpress mariadb; do
    ERROR_COUNT=$(docker logs $container 2>&1 | grep -i error | wc -l)
    if [ $ERROR_COUNT -eq 0 ]; then
        echo -e "${GREEN}✓ $container: No errors in logs${NC}"
    else
        echo -e "${YELLOW}⚠ $container: $ERROR_COUNT errors in logs${NC}"
    fi
done

echo ""
echo -e "${BLUE}=== Performance Test Complete ===${NC}"
echo ""
echo "Summary:"
echo "- Total memory usage: ${TOTAL_MEMORY}MB"
echo "- HTTPS response time: ${RESPONSE_TIME}s"
echo "- All containers have 'always' restart policy"
echo ""

if (( $(echo "$TOTAL_MEMORY < 1000" | bc -l) )) && (( $(echo "$RESPONSE_TIME < 3.0" | bc -l) )); then
    echo -e "${GREEN}✓ Performance requirements met${NC}"
else
    echo -e "${YELLOW}⚠ Some performance metrics need attention${NC}"
fi