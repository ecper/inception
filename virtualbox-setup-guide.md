# Inception VirtualBox セットアップガイド

## 目次
1. [必要なもの](#必要なもの)
2. [VirtualBoxのインストール](#virtualboxのインストール)
3. [仮想マシンの作成](#仮想マシンの作成)
4. [OSのインストール](#osのインストール)
5. [基本環境設定](#基本環境設定)
6. [Dockerのインストール](#dockerのインストール)
7. [プロジェクトのセットアップ](#プロジェクトのセットアップ)
8. [トラブルシューティング](#トラブルシューティング)

## 必要なもの
- VirtualBox 6.1以上
- Ubuntu Server 22.04 LTS ISOイメージ（推奨）またはDebian 11
- 最低8GB RAM（仮想マシンに4GB割り当て）
- 最低20GB ディスク容量
- インターネット接続

## VirtualBoxのインストール

### Windows/Mac/Linux
1. [VirtualBox公式サイト](https://www.virtualbox.org/wiki/Downloads)からダウンロード
2. ホストOSに応じたインストーラーを実行
3. VirtualBox Extension Pack もダウンロード・インストール（推奨）

## 仮想マシンの作成

### 1. 新規仮想マシン作成
```
名前: inception-vm
タイプ: Linux
バージョン: Ubuntu (64-bit) または Debian (64-bit)
```

### 2. メモリサイズ
```
推奨: 4096 MB (4GB)
最小: 2048 MB (2GB)
```

### 3. ハードディスク
```
- 仮想ハードディスクを作成する
- VDI (VirtualBox Disk Image)
- 動的にサイズ変更
- サイズ: 20GB以上
```

### 4. 仮想マシンの設定

#### システム設定
- **マザーボード**:
  - ブートメニューを有効化
  - チップセット: ICH9
  - ポインティングデバイス: PS/2マウス
- **プロセッサー**:
  - CPU数: 2以上（ホストCPUの半分まで）
  - PAE/NX を有効化

#### ディスプレイ設定
- ビデオメモリ: 128MB
- グラフィックスコントローラー: VMSVGA

#### ネットワーク設定
- **アダプター1**: NATまたはブリッジアダプター
  - NATの場合: ポートフォワーディング設定が必要
  - ブリッジの場合: 直接アクセス可能

##### NATポートフォワーディング設定
```
名前: SSH
プロトコル: TCP
ホストIP: 127.0.0.1
ホストポート: 2222
ゲストIP: 10.0.2.15
ゲストポート: 22

名前: HTTPS
プロトコル: TCP
ホストIP: 127.0.0.1
ホストポート: 443
ゲストIP: 10.0.2.15
ゲストポート: 443
```

## OSのインストール

### 1. Ubuntu Server 22.04 LTSのインストール
1. ISOイメージをマウント
2. 仮想マシンを起動
3. 言語選択: English
4. キーボード設定: 適切なレイアウトを選択
5. ネットワーク設定: DHCPを使用
6. プロキシ設定: 空白（必要に応じて設定）
7. ミラー設定: デフォルト
8. ストレージ設定: 
   - Use an entire disk
   - LVMを使用
9. ユーザー設定:
   ```
   Your name: hauchida
   Your server's name: inception-vm
   Pick a username: hauchida
   Password: [安全なパスワード]
   ```
10. OpenSSH serverをインストール
11. 追加パッケージは選択しない

### 2. 初回起動後の設定
```bash
# システムアップデート
sudo apt update && sudo apt upgrade -y

# 必要なパッケージのインストール
sudo apt install -y \
    curl \
    git \
    vim \
    make \
    build-essential \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release
```

## 基本環境設定

### 1. sudo権限の設定
```bash
# sudoグループにユーザーを追加（既に追加されている場合はスキップ）
sudo usermod -aG sudo hauchida
```

### 2. SSH設定（オプション）
```bash
# SSHサービスの有効化
sudo systemctl enable ssh
sudo systemctl start ssh

# ホストからSSH接続（NATの場合）
ssh -p 2222 hauchida@localhost
```

### 3. ファイアウォール設定
```bash
# UFWの設定
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Dockerのインストール

### 1. Docker公式リポジトリの追加
```bash
# GPGキーの追加
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# リポジトリの追加
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 2. Dockerのインストール
```bash
# パッケージリストの更新
sudo apt update

# Dockerのインストール
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# ユーザーをdockerグループに追加
sudo usermod -aG docker hauchida

# 再ログインまたは
newgrp docker
```

### 3. Docker動作確認
```bash
# Dockerバージョン確認
docker --version
docker compose version

# テスト実行
docker run hello-world
```

## プロジェクトのセットアップ

### 1. プロジェクトのクローン
```bash
# プロジェクトディレクトリの作成
mkdir -p ~/42cursus
cd ~/42cursus

# Gitからクローン（または手動でコピー）
git clone [your-repository-url] inception
cd inception
```

### 2. プロジェクト構造の確認
```bash
# 必要なディレクトリ構造
inception/
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements/
│       ├── nginx/
│       ├── wordpress/
│       └── mariadb/
```

### 3. 環境変数の設定
```bash
# .envファイルの作成
cd srcs/
cp .env.example .env
vim .env

# 以下を編集
DOMAIN_NAME=hauchida.42.fr
# その他のパスワードなど
```

### 4. hostsファイルの設定
```bash
# VMのhostsファイル
sudo vim /etc/hosts

# 以下を追加
127.0.0.1 hauchida.42.fr
```

### 5. データディレクトリの作成
```bash
# 手動で作成
sudo mkdir -p /home/hauchida/data/wordpress
sudo mkdir -p /home/hauchida/data/mariadb
sudo chown -R hauchida:hauchida /home/hauchida/data
```

### 6. プロジェクトの起動
```bash
# プロジェクトルートで実行
make

# ログの確認
make logs

# ブラウザでアクセス
# https://hauchida.42.fr (VM内から)
# https://localhost:443 (ホストから、NATの場合)
```

## トラブルシューティング

### 1. メモリ不足エラー
```bash
# スワップの追加
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 2. ディスク容量不足
```bash
# Dockerのクリーンアップ
docker system prune -a -f --volumes

# ログのクリア
sudo journalctl --vacuum-time=3d
```

### 3. ネットワーク接続問題
```bash
# DNS設定の確認
cat /etc/resolv.conf

# 必要に応じて追加
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
```

### 4. 権限エラー
```bash
# Dockerソケットの権限確認
ls -la /var/run/docker.sock

# グループの再読み込み
su - hauchida
```

## セキュリティ推奨事項

1. **定期的なアップデート**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **ファイアウォールの適切な設定**
   ```bash
   sudo ufw status
   ```

3. **強力なパスワードの使用**

4. **不要なサービスの無効化**
   ```bash
   sudo systemctl list-unit-files | grep enabled
   ```

## VM スナップショット

重要な変更前にスナップショットを作成：
1. VirtualBoxマネージャーでVMを選択
2. 「スナップショット」タブ
3. 「作成」をクリック
4. 名前と説明を入力

## 最終チェックリスト

- [ ] VirtualBoxがインストールされている
- [ ] 仮想マシンが作成されている（4GB RAM、20GB ディスク）
- [ ] Ubuntu/Debianがインストールされている
- [ ] Dockerがインストールされ、動作している
- [ ] プロジェクトファイルが配置されている
- [ ] hostsファイルが設定されている
- [ ] `make`コマンドでプロジェクトが起動する
- [ ] https://hauchida.42.fr にアクセスできる