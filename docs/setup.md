# Inception セットアップガイド

## 前提条件
- Docker と Docker Compose がインストールされていること
- sudo 権限があること
- ポート443が使用可能であること

## セットアップ手順

### 1. hostsファイルの設定
```bash
sudo echo "127.0.0.1 hauchida.42.fr" >> /etc/hosts
```

### 2. データディレクトリの作成
```bash
sudo mkdir -p /home/hauchida/data/wordpress
sudo mkdir -p /home/hauchida/data/mariadb
```

### 3. 環境変数の設定
```bash
cd srcs/
cp .env.example .env
# .envファイルを編集して適切な値を設定
```

### 4. プロジェクトのビルドと起動
```bash
cd /home/hauchida/Documents/fov-prog/42cursus/inception
make
```

### 5. 動作確認
- ブラウザで https://hauchida.42.fr にアクセス
- SSL証明書の警告を受け入れる（自己署名証明書のため）
- WordPressのログイン画面が表示されることを確認

## 管理コマンド

### コンテナの停止
```bash
make down
```

### コンテナの再起動
```bash
make re
```

### ログの確認
```bash
make logs
```

### 完全なクリーンアップ
```bash
make fclean
```

## トラブルシューティング

### ポート競合エラー
```bash
sudo lsof -i :443
# 使用中のプロセスを停止
```

### パーミッションエラー
```bash
sudo chown -R $USER:$USER /home/hauchida/data/
```

### コンテナが起動しない
```bash
docker compose -f srcs/docker-compose.yml logs [service_name]
```

### データベース接続エラー
- .envファイルの環境変数を確認
- MariaDBコンテナが正常に起動しているか確認
- ネットワーク接続を確認