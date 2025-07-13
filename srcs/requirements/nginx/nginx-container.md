# Nginx コンテナ

## 概要
NginxコンテナはWebサーバーとリバースプロキシとして動作し、HTTPS接続を処理します。

## Dockerfile の仕組み
1. **ベースイメージ**: Alpine Linux
2. **Nginx**: 最新安定版
3. **OpenSSL**: 自己署名証明書の生成
4. **設定ファイル**: カスタムnginx.conf

## 起動プロセス
1. SSL証明書の生成（自己署名）
2. Nginx設定ファイルの読み込み
3. PHP-FPMへのプロキシ設定
4. ポート443でHTTPSリッスン開始

## SSL/TLS設定
- TLS v1.2 と v1.3 のみサポート
- 自己署名証明書を使用（本番環境では正式な証明書を使用）
- 強力な暗号スイートのみ許可

## プロキシ設定
- PHPファイルはWordPress（PHP-FPM）へ転送
- 静的ファイルは直接配信
- FastCGIプロトコルでPHP-FPMと通信

## ボリューム
- `/var/www/html`: WordPressファイル（WordPressコンテナと共有）