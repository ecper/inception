# Inception - 42 Project

## 概要
DockerとDocker Composeを使用してLEMPスタック（Linux, Nginx, MariaDB, PHP）環境を構築するプロジェクトです。

## プロジェクト構成
- **Nginx**: Webサーバー（HTTPS対応）
- **WordPress**: PHP-FPMで動作するCMS
- **MariaDB**: データベースサーバー

## ドキュメント
- [技術選定の理由と根拠](docs/technical.md)
- [アーキテクチャ概要](docs/architecture.md)
- [Dockerネットワーキング詳細](docs/docker-networking.md)
- [セットアップガイド](docs/setup.md)

### 各コンテナの詳細
- [MariaDB](srcs/requirements/mariadb/mariadb-container.md)
- [WordPress](srcs/requirements/wordpress/wordpress-container.md)
- [Nginx](srcs/requirements/nginx/nginx-container.md)

## クイックスタート

### 1. 環境設定
```bash
cd srcs/
cp .env.example .env
# .envファイルを編集
```

### 2. ビルド&起動
```bash
make
```

### 3. アクセス
https://hauchida.42.fr

## コマンド一覧
- `make`: プロジェクトのビルドと起動
- `make down`: コンテナの停止
- `make re`: 再ビルドと再起動
- `make clean`: イメージとコンテナの削除
- `make fclean`: 完全クリーンアップ（データ含む）
- `make logs`: ログ表示

## 注意事項
- 既製のDockerイメージは使用禁止
- 全てAlpineまたはDebianベースで構築
- セキュリティを考慮した設計
