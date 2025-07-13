# Inception プロジェクト要件（日本語版）

## プロジェクト概要
このプロジェクトでは、Dockerを使用してシステム管理の知識を広げることを目的としています。複数のDockerイメージを仮想化し、個人の仮想マシン内で作成します。

## 必須要件（Mandatory Part）

### 一般的なガイドライン
- このプロジェクトは仮想マシン上で実行する必要があります
- 必要なファイルはすべて`srcs`フォルダに配置する必要があります
- `Makefile`が必要で、`srcs/docker-compose.yml`でアプリケーション全体をセットアップする必要があります
- Makefileは評価中にプロジェクト全体をビルドする必要があります

### 必須構成

#### 構築する必要があるコンテナ
1. **NGINX コンテナ**（TLSv1.2またはTLSv1.3のみ）
2. **WordPress + php-fpm コンテナ**（nginxなし）
3. **MariaDB コンテナ**（nginxなし）

#### ボリューム設定
- WordPressデータベースを含むボリューム
- WordPressウェブサイトファイルを含むボリューム

#### ネットワーク設定
- Dockerネットワークを確立してコンテナ間の接続を行う

### 技術要件

#### Dockerfile要件
- 各サービス用に1つのDockerfileを作成する
- DockerfileはMakefileによって`docker-compose.yml`内で呼び出される
- コンテナのDockerイメージは独自に構築する必要がある（Docker Hubからプルすることは禁止、Alpine/Debianを除く）
- 最新の安定版のAlpineまたはDebianを使用することを推奨

#### セキュリティ要件
- パスワードをDockerfileに保存することは禁止
- 環境変数を使用する必要がある
- `.env`ファイルを使用してdocker-compose.yml内の環境変数を保存
- `.env`ファイルはsrcsディレクトリのルートに配置

#### コンテナ要件
- コンテナはクラッシュした場合に再起動する必要がある
- 無限ループを回避するために適切な設定を行う
- PID 1でデーモンを実行することは禁止
- 各コンテナは適切に動作するように設定される

### 具体的な実装内容

#### WordPress設定
- 管理者ユーザーの作成
- 管理者ユーザー名に「admin」「Admin」「administrator」「Administrator」を含めることは禁止
- 通常のユーザーアカウントの作成も必要

#### ドメイン設定
- ドメイン名は`login.42.fr`形式にする（loginは自分の42ログイン名）
- ローカルIPアドレスを`login.42.fr`にリダイレクトする設定

#### 接続設定
- NGINX経由でのみアクセス可能（ポート443のみ）
- HTTPSプロトコルを使用

### ディレクトリ構造例
```
inception/
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   └── conf/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   └── conf/
│       └── wordpress/
│           ├── Dockerfile
│           ├── .dockerignore
│           └── conf/
```

### 禁止事項
- `network: host`、`--link`、`links:`の使用は禁止
- 無限ループでコンテナを起動することは禁止（`sleep infinity`、`tail -f`など）
- 既製のDockerイメージの使用（nginx、wordpress、mariadbなど）
- DockerHub上のサービスイメージの使用（Alpine/Debian以外）

### 評価基準
- Dockerの基本的な使い方の理解
- Docker-composeによるマルチコンテナアプリケーションの構築
- Dockerfileの作成とベストプラクティスの適用
- セキュリティを考慮した実装
- 適切なネットワーキングとボリューム管理

## ボーナスパート（今回は実装しない）
- Redis cache
- FTPサーバー
- 静的ウェブサイト（PHP以外の言語）
- Adminer
- 任意の有用なサービス（ただし説明が必要）

注：ボーナスパートは必須パートが完璧な場合のみ評価される