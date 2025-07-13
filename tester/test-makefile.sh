#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Makefile コマンドテスト ==="
echo ""

# 1. make all テスト
echo -e "${YELLOW}1. make all テスト${NC}"
make all
sleep 5
echo -n "コンテナの状態: "
RUNNING=$(docker ps --format '{{.Names}}' | grep -E "(nginx|wordpress|mariadb)" | wc -l)
if [ $RUNNING -eq 3 ]; then
    echo -e "${GREEN}✓ 3つのコンテナが実行中${NC}"
else
    echo -e "${RED}✗ コンテナが正しく起動していません（$RUNNING/3）${NC}"
fi
echo ""

# 2. make down テスト
echo -e "${YELLOW}2. make down テスト${NC}"
make down
sleep 2
echo -n "コンテナの状態: "
RUNNING=$(docker ps -a --format '{{.Names}}' | grep -E "(nginx|wordpress|mariadb)" | wc -l)
if [ $RUNNING -eq 0 ]; then
    echo -e "${GREEN}✓ 全てのコンテナが停止・削除されました${NC}"
else
    echo -e "${RED}✗ コンテナがまだ存在します（$RUNNING）${NC}"
fi
echo ""

# 3. make clean テスト
echo -e "${YELLOW}3. make clean テスト${NC}"
make all
sleep 5
make clean
echo -n "コンテナの状態: "
RUNNING=$(docker ps -a --format '{{.Names}}' | grep -E "(nginx|wordpress|mariadb)" | wc -l)
if [ $RUNNING -eq 0 ]; then
    echo -e "${GREEN}✓ コンテナがクリーンアップされました${NC}"
else
    echo -e "${RED}✗ コンテナがまだ存在します（$RUNNING）${NC}"
fi
echo -n "ボリュームの状態: "
VOLUMES=$(docker volume ls | grep -E "srcs_(wp|db)-volume" | wc -l)
if [ $VOLUMES -eq 2 ]; then
    echo -e "${GREEN}✓ ボリュームは保持されています${NC}"
else
    echo -e "${RED}✗ ボリュームの状態が異常です（$VOLUMES/2）${NC}"
fi
echo ""

# 4. make fclean テスト
echo -e "${YELLOW}4. make fclean テスト${NC}"
make all
sleep 5
echo "sudo権限が必要です（データディレクトリ削除のため）"
make fclean
echo -n "コンテナの状態: "
RUNNING=$(docker ps -a --format '{{.Names}}' | grep -E "(nginx|wordpress|mariadb)" | wc -l)
if [ $RUNNING -eq 0 ]; then
    echo -e "${GREEN}✓ コンテナが完全に削除されました${NC}"
else
    echo -e "${RED}✗ コンテナがまだ存在します（$RUNNING）${NC}"
fi
echo -n "ボリュームの状態: "
VOLUMES=$(docker volume ls | grep -E "srcs_(wp|db)-volume" | wc -l)
if [ $VOLUMES -eq 0 ]; then
    echo -e "${GREEN}✓ ボリュームが削除されました${NC}"
else
    echo -e "${RED}✗ ボリュームがまだ存在します（$VOLUMES）${NC}"
fi
echo -n "データディレクトリ: "
if [ ! -d "/home/uchida/data/wordpress" ] && [ ! -d "/home/uchida/data/mariadb" ]; then
    echo -e "${GREEN}✓ データディレクトリが削除されました${NC}"
else
    echo -e "${RED}✗ データディレクトリがまだ存在します${NC}"
fi
echo ""

echo "=== テスト完了 ==="