#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to print test results
print_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

echo "=== Inception プロジェクト要件チェック ==="
echo ""

# 1. ディレクトリ構造チェック
echo "1. ディレクトリ構造のチェック"
[ -f "Makefile" ]; print_test $? "Makefileが存在する"
[ -d "srcs" ]; print_test $? "srcsディレクトリが存在する"
[ -f "srcs/docker-compose.yml" ]; print_test $? "docker-compose.ymlが存在する"
[ -f "srcs/.env" ]; print_test $? ".envファイルが存在する"
[ -d "srcs/requirements/nginx" ]; print_test $? "nginxディレクトリが存在する"
[ -d "srcs/requirements/wordpress" ]; print_test $? "wordpressディレクトリが存在する"
[ -d "srcs/requirements/mariadb" ]; print_test $? "mariadbディレクトリが存在する"
echo ""

# 2. Dockerfileの存在チェック
echo "2. Dockerfileの存在チェック"
[ -f "srcs/requirements/nginx/Dockerfile" ]; print_test $? "nginx Dockerfileが存在する"
[ -f "srcs/requirements/wordpress/Dockerfile" ]; print_test $? "wordpress Dockerfileが存在する"
[ -f "srcs/requirements/mariadb/Dockerfile" ]; print_test $? "mariadb Dockerfileが存在する"
echo ""

# 3. ベースイメージのチェック
echo "3. ベースイメージのチェック（Alpine/Debianのみ許可）"
grep -E "^FROM\s+(alpine|debian)" srcs/requirements/nginx/Dockerfile > /dev/null
print_test $? "nginxがAlpine/Debianベース"
grep -E "^FROM\s+(alpine|debian)" srcs/requirements/wordpress/Dockerfile > /dev/null
print_test $? "wordpressがAlpine/Debianベース"
grep -E "^FROM\s+(alpine|debian)" srcs/requirements/mariadb/Dockerfile > /dev/null
print_test $? "mariadbがAlpine/Debianベース"
echo ""

# 4. 禁止されたイメージのチェック
echo "4. 禁止されたイメージの使用チェック"
! grep -E "^FROM\s+(nginx|wordpress|mariadb|mysql|php)" srcs/requirements/*/Dockerfile > /dev/null
print_test $? "既製のサービスイメージを使用していない"
echo ""

# 5. 環境変数のチェック
echo "5. 環境変数のセキュリティチェック"
! grep -E "(PASSWORD|password).*=" srcs/requirements/*/Dockerfile > /dev/null
print_test $? "Dockerfileにパスワードがハードコードされていない"
grep -E "MYSQL_ROOT_PASSWORD|MYSQL_PASSWORD|WORDPRESS_.*_PASSWORD" srcs/.env > /dev/null
print_test $? ".envファイルにパスワード設定がある"
echo ""

# 6. Docker Composeの設定チェック
echo "6. Docker Compose設定チェック"
grep -E "build:.*requirements/nginx" srcs/docker-compose.yml > /dev/null
print_test $? "nginxがビルドされる設定"
grep -E "build:.*requirements/wordpress" srcs/docker-compose.yml > /dev/null
print_test $? "wordpressがビルドされる設定"
grep -E "build:.*requirements/mariadb" srcs/docker-compose.yml > /dev/null
print_test $? "mariadbがビルドされる設定"
grep "443:443" srcs/docker-compose.yml > /dev/null
print_test $? "ポート443が公開されている"
! grep -E "80:80|8080:8080" srcs/docker-compose.yml > /dev/null
print_test $? "HTTPポート(80)が公開されていない"
echo ""

# 7. ネットワーク設定チェック
echo "7. ネットワーク設定チェック"
grep -E "networks:" srcs/docker-compose.yml > /dev/null
print_test $? "カスタムネットワークが定義されている"
! grep -E "network_mode:\s*host" srcs/docker-compose.yml > /dev/null
print_test $? "network: hostを使用していない"
! grep -E "(links:|--link)" srcs/docker-compose.yml > /dev/null
print_test $? "linksを使用していない"
echo ""

# 8. ボリューム設定チェック
echo "8. ボリューム設定チェック"
grep -E "wp-volume:" srcs/docker-compose.yml > /dev/null
print_test $? "WordPressボリュームが定義されている"
grep -E "db-volume:" srcs/docker-compose.yml > /dev/null
print_test $? "データベースボリュームが定義されている"
echo ""

# 9. TLS設定チェック
echo "9. TLS/SSL設定チェック"
grep -E "ssl_protocols.*TLSv1\.[23]" srcs/requirements/nginx/conf/nginx.conf > /dev/null
print_test $? "TLS 1.2/1.3が設定されている"
grep "listen 443 ssl" srcs/requirements/nginx/conf/nginx.conf > /dev/null
print_test $? "HTTPSが有効になっている"
echo ""

# 10. コンテナ再起動設定チェック
echo "10. コンテナ再起動設定チェック"
COUNT=$(grep -c "restart: always" srcs/docker-compose.yml)
[ $COUNT -eq 3 ]; print_test $? "全てのコンテナにrestart: alwaysが設定されている"
echo ""

# 11. PID 1デーモンチェック
echo "11. 適切なプロセス管理チェック"
! grep -E "(tail -f|sleep infinity|while true)" srcs/requirements/*/Dockerfile srcs/requirements/*/conf/* > /dev/null 2>&1
print_test $? "無限ループを使用していない"
echo ""

# 12. 実行中のコンテナチェック（オプション）
echo "12. 実行中のコンテナチェック"
if command -v docker &> /dev/null; then
    RUNNING=$(docker ps --format '{{.Names}}' | grep -E "(nginx|wordpress|mariadb)" | wc -l)
    [ $RUNNING -eq 3 ]; print_test $? "3つのコンテナが実行中"
    
    # ポートチェック
    docker ps | grep "443->443" > /dev/null
    print_test $? "ポート443が正しくマッピングされている"
else
    echo -e "${YELLOW}⚠${NC}  Dockerが見つかりません。スキップします。"
fi
echo ""

# 13. Makefile targets チェック
echo "13. Makefile ターゲットチェック"
grep -E "^all:" Makefile > /dev/null
print_test $? "allターゲットが存在する"
grep -E "^clean:|^fclean:" Makefile > /dev/null
print_test $? "clean/fcleanターゲットが存在する"
grep -E "^re:" Makefile > /dev/null
print_test $? "reターゲットが存在する"
echo ""

# 結果表示
echo "======================================="
echo "テスト結果: ${PASSED_TESTS}/${TOTAL_TESTS} 合格"
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}✓ 全ての要件をクリアしています！${NC}"
else
    echo -e "${RED}✗ 一部の要件を満たしていません。${NC}"
fi
echo "======================================="