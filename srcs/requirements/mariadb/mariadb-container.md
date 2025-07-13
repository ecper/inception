# MariaDB コンテナ

## 概要
MariaDBコンテナはWordPressのデータを管理するデータベースサーバーです。

## Dockerfile の仕組み
1. **ベースイメージ**: Alpine Linux (軽量で高速)
2. **MariaDBインストール**: apkパッケージマネージャーを使用
3. **初期設定スクリプト**: データベースとユーザーの作成
4. **セキュリティ設定**: rootパスワード設定、リモートroot接続無効化

## 起動プロセス
1. MariaDBサービスの初期化
2. システムデータベースの作成
3. カスタムデータベースとユーザーの作成
4. セキュリティ設定の適用
5. ポート3306でリッスン開始

## 環境変数
- `MYSQL_ROOT_PASSWORD`: rootユーザーのパスワード
- `MYSQL_DATABASE`: WordPressデータベース名
- `MYSQL_USER`: WordPressユーザー名
- `MYSQL_PASSWORD`: WordPressユーザーパスワード

## データ永続化
- `/var/lib/mysql`: データベースファイルの保存場所
- Dockerボリュームにマウントして永続化