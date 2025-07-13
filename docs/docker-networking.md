# Docker ネットワーキング説明

## 概要
このプロジェクトでは、Dockerのカスタムブリッジネットワークを使用して、コンテナ間の安全な通信を実現しています。

## ネットワーク構成

### inception-network (Bridge Network)
- **タイプ**: ブリッジネットワーク
- **目的**: コンテナ間の内部通信
- **特徴**: 
  - 各コンテナは独自のIPアドレスを持つ
  - コンテナ名で相互にアクセス可能
  - 外部からは直接アクセス不可

## コンテナ間通信

### 1. Nginx → WordPress
- **プロトコル**: FastCGI (TCP)
- **ポート**: 9000
- **ホスト名**: wordpress
- **用途**: PHPリクエストの転送

```
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
}
```

### 2. WordPress → MariaDB
- **プロトコル**: MySQL Protocol (TCP)
- **ポート**: 3306
- **ホスト名**: mariadb
- **用途**: データベース接続

```
WORDPRESS_DB_HOST=mariadb:3306
```

## ポート公開

### 外部公開ポート
- **443 (HTTPS)**: Nginxのみ外部に公開
  - ホスト:443 → コンテナ:443

### 内部ポート
- **9000**: WordPress (PHP-FPM) - 内部のみ
- **3306**: MariaDB - 内部のみ

## セキュリティ

### ネットワーク分離
- カスタムネットワークにより、他のDockerコンテナから隔離
- 明示的に参加したコンテナのみ通信可能

### 最小権限の原則
- 必要最小限のポートのみ公開
- データベースは外部から直接アクセス不可

## Docker DNS
- Dockerの内部DNSがコンテナ名を解決
- `wordpress`、`mariadb`、`nginx`で相互にアクセス可能
- IPアドレスの代わりにサービス名を使用

## 通信フロー

```
[外部クライアント]
    ↓ HTTPS (443)
[Nginx Container]
    ↓ FastCGI (9000)
[WordPress Container]
    ↓ MySQL (3306)
[MariaDB Container]
```

## トラブルシューティング

### ネットワーク確認コマンド
```bash
# ネットワーク一覧
docker network ls

# ネットワーク詳細
docker network inspect srcs_inception-network

# コンテナのネットワーク設定確認
docker inspect nginx | grep -A 20 NetworkMode
```