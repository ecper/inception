# Alpine から Debian への移行ガイド

## 移行の理由

### なぜDebianを選択したか

1. **エンタープライズグレードの安定性**
   - 長い歴史と実績
   - 大規模プロダクション環境での豊富な採用実績
   - 予測可能なリリースサイクル

2. **互換性の向上**
   - glibc使用による広範なソフトウェア互換性
   - より多くのツールやライブラリが標準でサポート
   - デバッグツールの充実

3. **開発効率**
   - 豊富なドキュメントとコミュニティサポート
   - 一般的な問題の解決策が見つけやすい
   - チーム開発での知識共有が容易

## 主な変更点

### ベースイメージ

| サービス | Alpine | Debian |
|---------|--------|--------|
| NGINX | alpine:3.21 | debian:bullseye |
| MariaDB | alpine:3.21 | debian:bullseye |
| WordPress | alpine:3.21 | debian:bullseye |

### パッケージマネージャー

#### Alpine (APK)
```dockerfile
RUN apk update && apk add --no-cache nginx
```

#### Debian (APT)
```dockerfile
RUN apt-get update && apt-get install -y nginx \
    && rm -rf /var/lib/apt/lists/*
```

### パッケージ名の変更

| 機能 | Alpine | Debian |
|------|--------|--------|
| MariaDBサーバー | mariadb | mariadb-server |
| MariaDBクライアント | mariadb-client | mariadb-client |
| MySQLクライアント | mysql-client | mariadb-client |
| PHP | php83 | php7.4 |
| PHP-FPM | php83-fpm | php7.4-fpm |
| PHP MySQL拡張 | php83-mysqli | php7.4-mysql |

### ファイルパスの変更

#### PHP-FPM設定

**Alpine:**
```
/etc/php83/php-fpm.d/www.conf
```

**Debian:**
```
/etc/php/7.4/fpm/pool.d/www.conf
```

#### PHP-FPM実行ファイル

**Alpine:**
```
/usr/sbin/php-fpm83
```

**Debian:**
```
/usr/sbin/php-fpm7.4
```

### ユーザーとグループ

#### Alpine
- デフォルトユーザー: `nobody`
- Webサーバーユーザー: `nginx`

#### Debian
- デフォルトユーザー: `www-data`
- Webサーバーユーザー: `www-data`

### PHP-FPM設定の違い

#### リスニング設定

**Alpine:**
```ini
listen = 127.0.0.1:9000
```

**Debian (デフォルト):**
```ini
listen = /run/php/php7.4-fpm.sock
```

**変更後 (両方で9000ポート):**
```ini
listen = 9000
```

### 必要な追加設定

#### Debian特有の設定

1. **PHP実行ディレクトリの作成**
```dockerfile
RUN mkdir -p /run/php
```

2. **APTキャッシュのクリーンアップ**
```dockerfile
RUN rm -rf /var/lib/apt/lists/*
```

## イメージサイズの比較

| イメージ | Alpine | Debian |
|----------|--------|--------|
| ベースイメージ | ~5MB | ~120MB |
| NGINX | ~10MB | ~150MB |
| MariaDB | ~200MB | ~400MB |
| WordPress | ~100MB | ~300MB |

**注意:** Debianの方がイメージサイズは大きくなりますが、その分以下の利点があります：
- より多くの標準ツール
- デバッグが容易
- 互換性の問題が少ない

## セキュリティ考慮事項

### Debian 11 (Bullseye) のセキュリティ

1. **長期サポート (LTS)**
   - 2026年までのセキュリティアップデート
   - 定期的なセキュリティパッチ

2. **セキュリティ強化**
```dockerfile
# 不要なパッケージを削除
RUN apt-get autoremove -y && apt-get clean

# セキュリティアップデートの適用
RUN apt-get update && apt-get upgrade -y
```

## トラブルシューティング

### よくある問題と解決策

#### 1. パッケージが見つからない

**問題:**
```
E: Unable to locate package xxx
```

**解決:**
```dockerfile
# universeリポジトリを有効化（必要な場合）
RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository universe
```

#### 2. タイムゾーン設定

**Debianでの設定:**
```dockerfile
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```

#### 3. ロケール設定

**Debianでの設定:**
```dockerfile
RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
```

## パフォーマンス最適化

### Debianでの最適化Tips

1. **不要なドキュメントを除外**
```dockerfile
# /etc/dpkg/dpkg.cfg.d/01_nodoc
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-exclude /usr/share/info/*
```

2. **マルチステージビルドの活用**
```dockerfile
FROM debian:bullseye as builder
# ビルド処理

FROM debian:bullseye-slim
# 実行環境（より小さいイメージ）
```

## 移行チェックリスト

- [x] すべてのDockerfileをDebianベースに変更
- [x] パッケージ名を適切に変更
- [x] ファイルパスを更新
- [x] ユーザー/グループ権限を調整
- [x] PHP-FPM設定を更新
- [x] スクリプト内のユーザー名を更新（nobody → www-data）
- [x] ドキュメントを更新

## まとめ

AlpineからDebianへの移行により：

**メリット:**
- より安定した環境
- 豊富なパッケージとツール
- 広範な互換性
- 充実したドキュメント

**デメリット:**
- イメージサイズの増加
- 若干のメモリ使用量増加

プロダクション環境では、Debianの安定性と互換性のメリットが、サイズのデメリットを上回ることが多いです。