# NGINX サービス詳細解説

## 目次
1. [Dockerfile解説](#dockerfile解説)
2. [nginx.conf設定ファイル解説](#nginxconf設定ファイル解説)
3. [SSL/TLS設定の詳細](#ssltls設定の詳細)
4. [FastCGI設定の詳細](#fastcgi設定の詳細)

## Dockerfile解説

```dockerfile
FROM alpine:3.21
```
**解説：**
- Alpine Linux 3.21をベースイメージとして使用
- Penultimate stable version（最新から2番目の安定版）
- イメージサイズ: 約5MB（最小限のフットプリント）

```dockerfile
RUN apk update && apk add --no-cache nginx openssl
```
**解説：**
- `apk update`: パッケージインデックスを更新
- `apk add --no-cache`: キャッシュを残さずパッケージをインストール
  - **nginx**: Webサーバー本体
  - **openssl**: SSL証明書生成に必要
- `--no-cache`オプションの利点:
  - イメージサイズの削減（キャッシュファイルを残さない）
  - セキュリティ向上（不要なファイルを排除）

```dockerfile
RUN mkdir -p /etc/nginx/ssl
```
**解説：**
- SSL証明書を格納するディレクトリを作成
- `-p`オプション: 親ディレクトリも必要に応じて作成

```dockerfile
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt \
    -keyout /etc/nginx/ssl/inception.key \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=hauchida.42.fr/UID=hauchida"
```
**解説：各オプションの意味**
- `req`: 証明書要求の処理
- `-x509`: 自己署名証明書を生成
- `-nodes`: 秘密鍵を暗号化しない（自動起動に必要）
- `-out`: 証明書の出力先
- `-keyout`: 秘密鍵の出力先
- `-subj`: 証明書のサブジェクト情報
  - `C=FR`: 国コード（フランス）
  - `ST=IDF`: 州/地域（イル・ド・フランス）
  - `L=Paris`: 都市
  - `O=42`: 組織名
  - `OU=42`: 組織単位
  - `CN=hauchida.42.fr`: コモンネーム（ドメイン名）
  - `UID=hauchida`: ユーザーID

```dockerfile
RUN mkdir -p /var/run/nginx
```
**解説：**
- NGINXのPIDファイル格納ディレクトリを作成
- プロセス管理に必要

```dockerfile
COPY conf/nginx.conf /etc/nginx/nginx.conf
```
**解説：**
- カスタム設定ファイルをコンテナにコピー
- デフォルト設定を上書き

```dockerfile
EXPOSE 443
```
**解説：**
- コンテナがリッスンするポートを宣言
- HTTPSポート（443）のみを公開
- HTTPポート（80）は意図的に公開しない（セキュリティ要件）

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```
**解説：**
- コンテナ起動時のコマンド
- `-g "daemon off;"`: フォアグラウンドで実行
  - Dockerではプロセスがフォアグラウンドで実行される必要がある
  - PID 1として正しく動作するため

## nginx.conf設定ファイル解説

### グローバル設定

```nginx
user nginx;
```
**解説：**
- NGINXワーカープロセスの実行ユーザー
- セキュリティのため非rootユーザーで実行

```nginx
worker_processes auto;
```
**解説：**
- ワーカープロセス数を自動設定
- CPUコア数に応じて最適化
- 手動設定例: `worker_processes 4;`

```nginx
error_log /var/log/nginx/error.log notice;
```
**解説：**
- エラーログの出力先とレベル
- `notice`: 通常の情報も記録（debug < info < notice < warn < error < crit）

```nginx
pid /var/run/nginx/nginx.pid;
```
**解説：**
- PIDファイルの保存場所
- プロセス管理に使用

### イベント処理設定

```nginx
events {
    worker_connections 1024;
}
```
**解説：**
- 各ワーカープロセスが処理できる最大同時接続数
- 1024は一般的なWebサイトには十分
- 計算式: 最大接続数 = worker_processes × worker_connections

### HTTP設定

```nginx
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
```
**解説：**
- `mime.types`: ファイル拡張子とMIMEタイプのマッピング
- `default_type`: MIMEタイプが不明な場合のデフォルト

```nginx
    sendfile on;
```
**解説：**
- カーネルレベルでのファイル転送を有効化
- ディスクI/Oとネットワークソケット間の効率的なデータ転送
- パフォーマンス向上に寄与

```nginx
    keepalive_timeout 65;
```
**解説：**
- HTTP Keep-Aliveのタイムアウト時間（秒）
- 同一クライアントとの接続を65秒間維持
- 複数のリクエストで接続を再利用

### サーバー設定

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
```
**解説：**
- `listen 443 ssl`: IPv4でポート443をリッスン
- `listen [::]:443 ssl`: IPv6でポート443をリッスン
- `ssl`: SSL/TLSを有効化

```nginx
    server_name hauchida.42.fr;
```
**解説：**
- このサーバーブロックが処理するドメイン名
- リクエストのHostヘッダーと照合

## SSL/TLS設定の詳細

```nginx
ssl_certificate /etc/nginx/ssl/inception.crt;
ssl_certificate_key /etc/nginx/ssl/inception.key;
```
**解説：**
- SSL証明書と秘密鍵のパス
- Dockerfileで生成した自己署名証明書を使用

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```
**解説：**
- 使用するTLSプロトコルバージョン
- TLSv1.0, TLSv1.1は脆弱性のため無効化
- 最新の安全なプロトコルのみ許可

```nginx
ssl_ciphers HIGH:!aNULL:!MD5;
```
**解説：**
- `HIGH`: 高強度の暗号スイートを使用
- `!aNULL`: 認証なしの暗号スイートを除外
- `!MD5`: MD5ベースの暗号スイートを除外（脆弱）

```nginx
ssl_prefer_server_ciphers on;
```
**解説：**
- サーバー側の暗号スイート優先順位を使用
- クライアントではなくサーバーが暗号スイートを選択

### ドキュメントルート設定

```nginx
root /var/www/html;
index index.php index.html index.htm;
```
**解説：**
- `root`: Webコンテンツのルートディレクトリ
- `index`: デフォルトファイルの優先順位
  1. index.php（WordPress用）
  2. index.html
  3. index.htm

## FastCGI設定の詳細

### 一般的なルーティング

```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```
**解説：**
- すべてのリクエストの処理ルール
- 処理順序:
  1. `$uri`: 要求されたファイルを探す
  2. `$uri/`: ディレクトリとして探す
  3. `/index.php?$args`: WordPressのフロントコントローラーに転送
- これによりWordPressのパーマリンクが機能する

### PHP処理設定

```nginx
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass wordpress:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
}
```

**各行の詳細解説：**

1. `location ~ \.php$`
   - 正規表現でPHPファイルにマッチ
   - `.php`で終わるすべてのリクエストを処理

2. `try_files $uri =404`
   - PHPファイルが存在しない場合は404エラー
   - セキュリティ対策（存在しないPHPファイルの実行を防ぐ）

3. `fastcgi_split_path_info ^(.+\.php)(/.+)$`
   - パス情報を分割
   - 例: `/index.php/some/path` → スクリプト名とパス情報に分離

4. `fastcgi_pass wordpress:9000`
   - PHP-FPMサービスに転送
   - `wordpress`: Docker内部DNSでサービス名を解決
   - `9000`: PHP-FPMのリスニングポート

5. `fastcgi_index index.php`
   - ディレクトリアクセス時のデフォルトファイル

6. `include fastcgi_params`
   - FastCGI用の標準パラメータをインクルード

7. `fastcgi_param SCRIPT_FILENAME`
   - 実行するPHPスクリプトの絶対パス
   - `$document_root`: /var/www/html
   - `$fastcgi_script_name`: リクエストされたスクリプト名

8. `fastcgi_param PATH_INFO`
   - URLのパス情報をPHPに渡す
   - WordPressのルーティングに使用

### セキュリティ設定

```nginx
location ~ /\.ht {
    deny all;
}
```
**解説：**
- `.ht`で始まるファイル（.htaccess等）へのアクセスを拒否
- Apacheの設定ファイルが誤って公開されることを防ぐ
- `deny all`: すべてのアクセスを拒否

## パフォーマンス最適化のポイント

1. **sendfile**: カーネルレベルでのファイル転送
2. **tcp_nopush**: パケットの効率的な送信（追加可能）
3. **gzip**: 圧縮転送（追加可能）

```nginx
# 追加可能な最適化設定例
sendfile on;
tcp_nopush on;
tcp_nodelay on;
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript;
```

## セキュリティ強化のポイント

1. **HTTPSのみ**: ポート443のみを公開
2. **最新TLSプロトコル**: TLSv1.2とTLSv1.3のみ
3. **強力な暗号スイート**: 弱い暗号化を除外
4. **ファイルアクセス制限**: .htaccessなどを拒否

## トラブルシューティング

### よくある問題と解決方法

1. **502 Bad Gateway**
   - 原因: PHP-FPMサービスが起動していない
   - 解決: `docker-compose logs wordpress`でログ確認

2. **証明書エラー**
   - 原因: 自己署名証明書を使用
   - 解決: ブラウザで例外として追加

3. **Permission Denied**
   - 原因: ファイル権限の問題
   - 解決: `chown -R nobody:nobody /var/www/html`

## まとめ

NGINXコンテナは以下の役割を担います：
- **リバースプロキシ**: PHP-FPMへのリクエスト転送
- **SSL/TLS終端**: HTTPS通信の処理
- **静的ファイル配信**: CSS、JS、画像などの高速配信
- **セキュリティゲートウェイ**: 唯一の外部公開ポイント