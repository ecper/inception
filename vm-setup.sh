#!/bin/bash

# Inception VM Setup Script
# このスクリプトをVM内で実行してください

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Inception VM セットアップスクリプト ===${NC}"
echo ""

# 1. システムアップデート
echo -e "${YELLOW}1. システムアップデート${NC}"
sudo apt update && sudo apt upgrade -y

# 2. 必要なパッケージのインストール
echo -e "${YELLOW}2. 必要なパッケージのインストール${NC}"
sudo apt install -y \
    curl \
    git \
    vim \
    make \
    build-essential \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw

# 3. Dockerのインストール
echo -e "${YELLOW}3. Dockerのインストール${NC}"
if ! command -v docker &> /dev/null; then
    # GPGキーの追加
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # リポジトリの追加
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Dockerのインストール
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # ユーザーをdockerグループに追加
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Dockerがインストールされました${NC}"
else
    echo -e "${GREEN}✓ Dockerは既にインストールされています${NC}"
fi

# 4. ファイアウォールの設定
echo -e "${YELLOW}4. ファイアウォールの設定${NC}"
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
echo -e "${GREEN}✓ ファイアウォールが設定されました${NC}"

# 5. プロジェクトディレクトリの作成
echo -e "${YELLOW}5. プロジェクトディレクトリの作成${NC}"
mkdir -p ~/42cursus/inception
echo -e "${GREEN}✓ プロジェクトディレクトリが作成されました${NC}"

# 6. データディレクトリの作成
echo -e "${YELLOW}6. データディレクトリの作成${NC}"
sudo mkdir -p /home/$USER/data/wordpress
sudo mkdir -p /home/$USER/data/mariadb
sudo chown -R $USER:$USER /home/$USER/data
echo -e "${GREEN}✓ データディレクトリが作成されました${NC}"

# 7. hostsファイルの設定
echo -e "${YELLOW}7. hostsファイルの設定${NC}"
DOMAIN="hauchida.42.fr"
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
    echo -e "${GREEN}✓ $DOMAIN がhostsファイルに追加されました${NC}"
else
    echo -e "${GREEN}✓ $DOMAIN は既にhostsファイルに存在します${NC}"
fi

# 8. スワップの設定（オプション）
echo -e "${YELLOW}8. スワップの設定${NC}"
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo -e "${GREEN}✓ 2GBのスワップが作成されました${NC}"
else
    echo -e "${GREEN}✓ スワップは既に設定されています${NC}"
fi

# 9. 環境情報の表示
echo ""
echo -e "${BLUE}=== セットアップ完了 ===${NC}"
echo ""
echo "システム情報:"
echo "- OS: $(lsb_release -d | cut -f2)"
echo "- Docker: $(docker --version 2>/dev/null || echo 'インストール後に再ログインが必要')"
echo "- Docker Compose: $(docker compose version 2>/dev/null || echo 'インストール後に再ログインが必要')"
echo "- IP: $(hostname -I | awk '{print $1}')"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "1. 再ログインしてDockerグループを有効化: 'exit' して再度ログイン"
echo "2. プロジェクトファイルを ~/42cursus/inception にコピー"
echo "3. cd ~/42cursus/inception && make でプロジェクトを起動"
echo ""
echo -e "${GREEN}セットアップが完了しました！${NC}"