# WordPress コンテナ

## 概要
WordPressコンテナはPHP-FPMを使用してWordPressアプリケーションを実行します。

## Dockerfile の仕組み
1. **ベースイメージ**: Alpine Linux
2. **PHP-FPM**: PHP 8.1 とWordPress必要モジュール
3. **WP-CLI**: WordPressコマンドラインツール
4. **自動セットアップ**: 初回起動時にWordPressを自動設定

## 起動プロセス
1. PHP-FPMの設定読み込み
2. WordPressファイルの確認・ダウンロード
3. wp-config.phpの生成
4. データベース接続の確立
5. WordPressのインストール（初回のみ）
6. PHP-FPMサービスの起動（ポート9000）

## 環境変数
- `WORDPRESS_DB_HOST`: MariaDBホスト名
- `WORDPRESS_DB_USER`: データベースユーザー
- `WORDPRESS_DB_PASSWORD`: データベースパスワード
- `WORDPRESS_DB_NAME`: データベース名
- `DOMAIN_NAME`: サイトドメイン
- `WORDPRESS_TITLE`: サイトタイトル
- `WORDPRESS_ADMIN_USER`: 管理者ユーザー名
- `WORDPRESS_ADMIN_PASSWORD`: 管理者パスワード
- `WORDPRESS_ADMIN_EMAIL`: 管理者メールアドレス

## ボリューム
- `/var/www/html`: WordPressファイル（Nginxと共有）