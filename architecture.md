# Inception プロジェクト アーキテクチャ

## 概要
InceptionプロジェクトはDockerを使用してLEMPスタック（Linux, Nginx, MariaDB, PHP）を構築します。
全てのDockerイメージは既製品を使用せず、AlpineまたはDebianベースで自作する必要があります。

## プロジェクト構造
```
inception/
├── Makefile
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   └── conf/
        │       └── wp-config-docker.sh
        └── mariadb/
            ├── Dockerfile
            └── conf/
                └── create_db.sh
```

## コンテナアーキテクチャ

### 1. Nginx コンテナ
- **ベースイメージ**: Alpine Linux
- **役割**: リバースプロキシ、SSL/TLS終端
- **ポート**: 443 (HTTPS only)
- **機能**:
  - TLS v1.2/v1.3 のみサポート
  - WordPressへのリクエストをプロキシ
  - 静的ファイルの配信

### 2. WordPress コンテナ  
- **ベースイメージ**: Alpine Linux
- **役割**: PHPアプリケーションサーバー
- **ポート**: 9000 (PHP-FPM)
- **機能**:
  - PHP-FPMによるPHP実行環境
  - WordPressコアファイルの管理
  - MariaDBとの接続

### 3. MariaDB コンテナ
- **ベースイメージ**: Alpine Linux
- **役割**: データベースサーバー
- **ポート**: 3306
- **機能**:
  - WordPressデータの永続化
  - ユーザー管理とアクセス制御

## ネットワーク構成
- カスタムDockerネットワークを使用
- コンテナ間通信は内部ネットワーク経由
- 外部からのアクセスはNginxの443ポートのみ

## ボリューム構成
- **db-volume**: MariaDBデータ永続化
- **wp-volume**: WordPressファイル共有（Nginx-WordPress間）

## セキュリティ考慮事項
- 環境変数による認証情報管理
- SSL/TLS必須
- 最小権限の原則に基づいたコンテナ設計