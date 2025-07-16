#!/bin/bash

# WordPress要件チェックスクリプト

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== WordPress ユーザー要件チェック ==="
echo ""

# 1. 環境変数のチェック
echo "1. 環境変数の確認"
source srcs/.env

# 管理者ユーザー名の確認
FORBIDDEN_NAMES=("admin" "Admin" "administrator" "Administrator")
IS_VALID=true

for forbidden in "${FORBIDDEN_NAMES[@]}"; do
    if [[ "$WORDPRESS_ADMIN_USER" == "$forbidden" ]]; then
        echo -e "${RED}✗ 管理者ユーザー名 '$WORDPRESS_ADMIN_USER' は禁止されています${NC}"
        IS_VALID=false
        break
    fi
done

if $IS_VALID; then
    echo -e "${GREEN}✓ 管理者ユーザー名 '$WORDPRESS_ADMIN_USER' は有効です${NC}"
fi

# 通常ユーザーの確認
if [ -n "$WORDPRESS_USER" ] && [ -n "$WORDPRESS_USER_EMAIL" ] && [ -n "$WORDPRESS_USER_PASSWORD" ]; then
    echo -e "${GREEN}✓ 通常ユーザー '$WORDPRESS_USER' が設定されています${NC}"
else
    echo -e "${RED}✗ 通常ユーザーの設定が不完全です${NC}"
fi

echo ""

# 2. 実際のWordPressユーザーを確認（Dockerが起動している場合）
echo "2. WordPress内のユーザー確認"
if docker ps | grep -q wordpress; then
    echo "WordPressコンテナで確認中..."
    
    # 管理者ユーザーの確認
    ADMIN_EXISTS=$(docker exec wordpress wp user list --role=administrator --field=user_login --allow-root 2>/dev/null | grep -v "^admin$\|^Admin$\|^administrator$\|^Administrator$" | wc -l)
    if [ "$ADMIN_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}✓ 有効な管理者ユーザーが存在します:${NC}"
        docker exec wordpress wp user list --role=administrator --allow-root 2>/dev/null
    else
        echo -e "${RED}✗ 有効な管理者ユーザーが見つかりません${NC}"
    fi
    
    # 通常ユーザーの確認
    REGULAR_USERS=$(docker exec wordpress wp user list --role=author,editor,contributor,subscriber --allow-root 2>/dev/null | wc -l)
    if [ "$REGULAR_USERS" -gt 1 ]; then  # ヘッダー行を除く
        echo -e "${GREEN}✓ 通常ユーザーが存在します:${NC}"
        docker exec wordpress wp user list --role=author,editor,contributor,subscriber --allow-root 2>/dev/null
    else
        echo -e "${RED}✗ 通常ユーザーが見つかりません${NC}"
    fi
else
    echo -e "${YELLOW}WordPressコンテナが起動していません。'make'を実行してください。${NC}"
fi

echo ""

# 3. 設定ファイルの確認
echo "3. 設定ファイルの確認"
if grep -q "wp user create" srcs/requirements/wordpress/conf/wp-config-docker.sh; then
    echo -e "${GREEN}✓ ユーザー作成処理が実装されています${NC}"
else
    echo -e "${RED}✗ ユーザー作成処理が見つかりません${NC}"
fi

echo ""
echo "=== 要件サマリー ==="
echo "必須要件:"
echo "1. 管理者ユーザー名に禁止語を含まない: $([ "$IS_VALID" = true ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}")"
echo "2. 通常ユーザーアカウントの作成: $([ -n "$WORDPRESS_USER" ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}")"
echo ""

if $IS_VALID && [ -n "$WORDPRESS_USER" ]; then
    echo -e "${GREEN}全ての要件を満たしています！${NC}"
else
    echo -e "${RED}要件を満たしていません。修正が必要です。${NC}"
fi