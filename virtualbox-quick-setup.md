# VirtualBox クイックセットアップガイド

## 最速セットアップ手順（10分で完了）

### 1. VirtualBoxで新規VM作成（2分）
```
名前: inception-vm
タイプ: Linux
バージョン: Ubuntu (64-bit)
メモリ: 4096MB
ディスク: 20GB (VDI, 動的)
```

### 2. VM設定変更（1分）
- **システム → プロセッサー**: CPU 2個
- **ネットワーク → アダプター1**: 
  - ブリッジアダプター（推奨）または
  - NAT + ポートフォワーディング:
    - SSH: ホスト2222 → ゲスト22
    - HTTPS: ホスト443 → ゲスト443

### 3. Ubuntu Server インストール（5分）
1. [Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server) ISOをダウンロード
2. VMにISOをマウントして起動
3. 最小インストール:
   - 言語: English
   - OpenSSH server: ✓
   - ユーザー名: hauchida

### 4. VM内で自動セットアップ（2分）
```bash
# VMにログイン後、以下を実行
wget https://raw.githubusercontent.com/[your-repo]/inception/main/vm-setup.sh
chmod +x vm-setup.sh
./vm-setup.sh

# または手動で:
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### 5. プロジェクト配置
```bash
# ホストから（プロジェクトディレクトリで）
scp -P 2222 -r . hauchida@localhost:~/42cursus/inception/

# またはVM内でgit clone
git clone [your-repository] ~/42cursus/inception
```

### 6. 起動
```bash
cd ~/42cursus/inception
make
```

## トラブルシューティング

### ホストからVMにアクセスできない
```bash
# VM内で確認
ip addr show
sudo ufw status

# ブリッジモードの場合: 表示されたIPを使用
# NATモードの場合: localhost:2222 (SSH), localhost:443 (HTTPS)
```

### Dockerコマンドが使えない
```bash
# 再ログインまたは
newgrp docker
```

### メモリ不足
```bash
# VMのメモリを6GB以上に増やすか、スワップを追加
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 評価者向け情報

### アクセス方法
1. **VM内から**: https://hauchida.42.fr
2. **ホストから（ブリッジ）**: https://[VM-IP]
3. **ホストから（NAT）**: https://localhost:443

### 確認コマンド
```bash
# プロジェクト構造
ls -la ~/42cursus/inception/

# 実行中のコンテナ
docker ps

# ログ確認
cd ~/42cursus/inception && make logs

# クリーンアップ
make fclean
```