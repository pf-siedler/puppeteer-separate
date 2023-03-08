# puppeteer-separate

Puppeteer を使ったアプリケーションから Chrome を切り離す実験

## Requirement

- nix
- nix fake
- docker
- docker compose

以下は `nix develop` コマンドで使えるようになるが一応

- Node.js
- yarn
- kind
- kubectl
- make

お好みであると便利なもの

- direnv

## ディレクトリの説明

- `src/`: TypeScript のソースコード
- `k8s/`: kubernetes の manifest
- 

## 準備

direnv を使う場合

```sh
$ echo "use flake" > .envrc
$ direnv allow
```

direnv を使わない場合

```sh
$ nix develop
```

## Usage

```sh
# Chrome の Docker image を立ち上げる
$ docker compose up chrome -d
# ビルド
$ yarn build
# 実行
$ BROWSER_ADDR=http://localhost:3000 yarn start

# ctrl + c で終了
```

### docker compose で動かす場合

```sh
$ docker compose up chrome -d
$ docker compose up app

# ctrl + c で終了
```
