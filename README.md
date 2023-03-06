# puppeteer を使用したスクレイピングアプリケーションから Chromium を切り離す

## 前提

puppeteer を使うアプリケーションを k8s 上で走らせるとリソース使用量が跳ね上がる

おそらく、 Chrome (Chromium) がドカ食いしている

Chrome 専用のノードを分ければ管理しやすそう

## やってみる

使用したコードはこちら
github の URL

### 元アプリケーション

puppeteer の document からサンプルコードを丸々コピペして適当なスクレイピングアプリケーションを作る。

```ts
import * as puppeteer from 'puppeteer';

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.goto('https://developer.chrome.com/');

  // Set screen size
  await page.setViewport({width: 1080, height: 1024});

  // Type into search box
  await page.type('.search-box__input', 'automate beyond recorder');

  // Wait and click on first result
  const searchResultSelector = '.search-box__link';
  await page.waitForSelector(searchResultSelector);
  await page.click(searchResultSelector);

  // Locate the full title with a unique string
  const textSelector = await page.waitForSelector(
    'text/Customize and automate'
  );
  const fullTitle = await textSelector.evaluate(el => el.textContent);

  // Print the full title
  console.log('The title of this blog post is "%s".', fullTitle);

  await browser.close();
})();
```

Google Developper のページから"Customize and automate~" というブログのタイトルを持ってくるというシンプルなもの。
実際に build して動かすと、こんな感じ。

```sh
=> node dest
The title of this blog post is "Customize and automate user flows beyond Chrome DevTools Recorder".
```

### 分割

`puppeteer` は `npm install puppeteer` をした際に Chromium をダウンロードしてきて、それを使ってスクレイピングを行う。

`puppeteer` を `puppeteer-core` に変更

browser の初期化を以下のようにする

```ts
const browserURL = process.env.BROWSER_ADDR;
await puppeteer.connect({ browserURL });
```

他にも 10秒毎にスクレイピングを実行するように変更したりして以下のようにした

```ts
import * as puppeteer from 'puppeteer-core';
import { setTimeout } from 'timers/promises';

const getChromeDevPage = async (browserURL: string) => {
    const browser = await puppeteer.connect({ browserURL });
    const page = await browser.newPage();

    await page.goto('https://developer.chrome.com/');

    // Set screen size
    await page.setViewport({ width: 1080, height: 1024 });

    // Type into search box
    await page.type('.search-box__input', 'automate beyond recorder');

    // Wait and click on first result
    const searchResultSelector = '.search-box__link';
    await page.waitForSelector(searchResultSelector);
    await page.click(searchResultSelector);

    // Locate the full title with a unique string
    const textSelector = await page.waitForSelector('text/Customize and automate');
    const fullTitle = await textSelector!.evaluate((el) => el.textContent);

    // Print the full title
    console.log('The title of this blog post is "%s".', fullTitle);

    await browser.close();
};

(async () => {
    const browserURL = process.env.BROWSER_ADDR;
    if (browserURL === undefined) {
        console.error('Environment variable `BROWSER_ADDR` is not set.');
        return;
    }
    while (true) {
        try {
            await getChromeDevPage(browserURL);
        } catch (e) {
            console.error('failue', { e });
            break;
        }
        await setTimeout(10 * 1000);
    }
})();
```

環境変数でブラウザの URL を渡せば動くようになる

ブラウザはとりあえず `browserless/chrome` の docker image を使用

```yaml
# docker-compose.yaml
version: '3.7'
services:
  chrome:
    image: browserless/chrome
    ports:
      - 3000:3000
```

```sh
BROWSER_ADDR="http://localhost:3000" node dest
```

で 10秒毎に `The title of this blog post is "Customize and automate user flows beyond Chrome DevTools Recorder".` が出る

### Node.js 側もコンテナ化

適当に Dockerfile を作る（Dockerfile の内容はリポジトリ見てね）

```yaml
# docker-compose.yaml

version: '3.7'
services:
  chrome:
    image: browserless/chrome
    ports:
      - 3000:3000

  app:
    build: .
    environment:
      - BROWSER_ADDR=http://chrome:3000
```

先に chrome を立ち上げてから app を立ち上げる

```sh
=> docker compose up chrome -d
[+] Running 1/1
 ⠿ Container puppeteer-separate-chrome-1  Started

=> docker compose up app
[+] Running 1/1
 ⠿ Container puppeteer-separate-app-1  Recreated
Attaching to puppeteer-separate-app-1
puppeteer-separate-app-1  | The title of this blog post is "Customize and automate user flows beyond Chrome DevTools Recorder".
puppeteer-separate-app-1  | The title of this blog post is "Customize and automate user flows beyond Chrome DevTools Recorder".
...
```

動く

### k8s で動かす

kubernetes 環境で動かしてみよう

とりあえず docker build する

```sh
=> docker build -t scraping:1.0.0 .
```

kind でローカル環境に k8s cluster を作成
`kind load` で手元でビルドした docker image を kind で動かせるようにしておく

```sh
=> kind create cluster
=> kind load docker-image scraping:1.0.0
```

Deployment を書く

chrome のみの deploy を作る

```yaml
# chrome.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: chrome-ns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: chrome-ns
  name: chrome
  labels:
    app: chrome
spec:
  selector:
    matchLabels:
      app: chrome
  replicas: 2
  template:
    metadata:
      labels:
        app: chrome
    spec:
      containers:
        - name: chrome
          image: browserless/chrome
          ports:
            - name: chrome
              containerPort: 3000
              protocol: TCP
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  namespace: chrome-ns
  name: chrome
spec:
  ports:
    - name: chrome
      targetPort: chrome
      port: 3000
  selector:
    app: chrome
```

scraping:1.0.0 の Deployment を作る

```yaml
```

動く

```sh
=> kubectl logs job/scraping  scraping
The title of this blog post is "Customize and automate user flows beyond Chrome DevTools Recorder".
```

### まとめ

puppeteer を使ったアプリを puppeteer-core + chrome の docker image に分割し、 k8s にデプロイしてみた

scrapingアプリの運用観点でも chrome を外部リソースとみなした方がやりやすそう

セッション管理とか気になる箇所もあるので要検証

ちょっと会社のアプリケーションで試してみたい
