#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Inception 機能テスト ==="
echo ""

# 1. コンテナの状態確認
echo -e "${BLUE}1. コンテナ状態の確認${NC}"
echo "実行中のコンテナ:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(nginx|wordpress|mariadb|NAMES)"
echo ""

# 2. ネットワーク接続テスト
echo -e "${BLUE}2. コンテナ間のネットワーク接続テスト${NC}"

# Nginx -> WordPress
echo -n "Nginx → WordPress (9000): "
docker exec nginx nc -zv wordpress 9000 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 接続成功${NC}"
else
    echo -e "${RED}✗ 接続失敗${NC}"
fi

# WordPress -> MariaDB
echo -n "WordPress → MariaDB (3306): "
docker exec wordpress nc -zv mariadb 3306 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 接続成功${NC}"
else
    echo -e "${RED}✗ 接続失敗${NC}"
fi
echo ""

# 3. データベース接続テスト
echo -e "${BLUE}3. データベース接続テスト${NC}"
echo -n "MariaDBデータベース接続: "
docker exec mariadb mysql -u wp_user -pwppassword123 -e "SELECT 1;" wordpress_db > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 成功${NC}"
else
    echo -e "${RED}✗ 失敗${NC}"
fi

# データベースとテーブルの確認
echo ""
echo "データベース一覧:"
docker exec mariadb mysql -u root -prootpassword123 -e "SHOW DATABASES;" 2>/dev/null | grep -v "Warning"
echo ""

# 4. WordPressファイルの確認
echo -e "${BLUE}4. WordPressファイルの確認${NC}"
echo -n "wp-config.php: "
docker exec wordpress test -f /var/www/html/wp-config.php
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 存在${NC}"
else
    echo -e "${RED}✗ 不在${NC}"
fi

echo -n "index.php: "
docker exec wordpress test -f /var/www/html/index.php
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 存在${NC}"
else
    echo -e "${RED}✗ 不在${NC}"
fi
echo ""

# 5. HTTPS接続テスト
echo -e "${BLUE}5. HTTPS接続テスト${NC}"
DOMAIN=$(grep "DOMAIN_NAME" srcs/.env | cut -d'=' -f2)
echo "テスト対象: https://$DOMAIN"

# SSL証明書の確認
echo ""
echo "SSL証明書情報:"
docker exec nginx openssl x509 -in /etc/nginx/ssl/inception.crt -noout -subject -dates | head -3
echo ""

# HTTPSレスポンステスト
echo -n "HTTPSレスポンス: "
curl -k -s -o /dev/null -w "%{http_code}" https://localhost:443 > /tmp/http_status 2>/dev/null
HTTP_STATUS=$(cat /tmp/http_status)
if [[ "$HTTP_STATUS" =~ ^(200|301|302|404)$ ]]; then
    echo -e "${GREEN}✓ HTTP $HTTP_STATUS${NC}"
else
    echo -e "${RED}✗ HTTP $HTTP_STATUS${NC}"
fi
rm -f /tmp/http_status
echo ""

# 6. ボリュームの確認
echo -e "${BLUE}6. ボリュームの確認${NC}"
echo "Dockerボリューム:"
docker volume ls | grep -E "(wp-volume|db-volume|VOLUME)"
echo ""

echo "ホストディレクトリ:"
ls -la /home/hauchida/data/ 2>/dev/null || echo "データディレクトリが見つかりません"
echo ""

# 7. プロセスの確認
echo -e "${BLUE}7. 各コンテナのメインプロセス${NC}"
echo "Nginx:"
docker exec nginx ps aux | grep -E "(nginx|PID)" | head -2

echo ""
echo "WordPress (PHP-FPM):"
docker exec wordpress ps aux | grep -E "(php-fpm|PID)" | head -2

echo ""
echo "MariaDB:"
docker exec mariadb ps aux | grep -E "(mysqld|PID)" | head -2
echo ""

# 8. メモリとCPU使用率
echo -e "${BLUE}8. リソース使用状況${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(nginx|wordpress|mariadb|NAME)"
echo ""

# 9. ログの最新エントリ
echo -e "${BLUE}9. 各コンテナの最新ログ（最後の5行）${NC}"
echo -e "${YELLOW}Nginx:${NC}"
docker logs nginx --tail 5 2>&1 | sed 's/^/  /'

echo -e "${YELLOW}WordPress:${NC}"
docker logs wordpress --tail 5 2>&1 | sed 's/^/  /'

echo -e "${YELLOW}MariaDB:${NC}"
docker logs mariadb --tail 5 2>&1 | grep -v "Warning" | tail -5 | sed 's/^/  /'
echo ""

echo "=== テスト完了 ==="
echo -e "${YELLOW}注意: https://$DOMAIN にブラウザでアクセスして動作を確認してください${NC}"