# puppeteer を使用したスクレイピングアプリケーションから Chromium を切り離す

## 前提

puppeteer を使うアプリケーションを k8s 上で走らせるとリソース使用量が跳ね上がる

おそらく、 Chrome (Chromium) がドカ食いしている

Chrome 専用のノードを分ければ管理しやすそう

## やってみる

### 元アプリケーション

適当なスクレイピングアプリケーションを作る
とりあえず puppeteer の document からサンプルコードをコピペ

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

とりあえず動かすと


### 分割

`puppeteer` を `puppeteer-core` に変更

browser の初期化を以下のようにする
```ts
await puppeteer.connect({ browserURL: process.env.BROWSER_ADDR });
```

```diff
-import * as puppeteer from 'puppeteer';
+import * as puppeteer from 'puppeteer-core';

-(async () => {
-    const browser = await puppeteer.launch();
+const getChromeDevPage = async (browser: puppeteer.Browser) => {

...

-})();
+};
+
+(async () => {
+    const browser = await puppeteer.connect({ browserURL: process.env.BROWSER_ADDR });
+    await getChromeDevPage(browser);
+})()
+    .then(() => {
+        console.log('finished');
+    })
+    .catch((e) => {
+        console.error(e);
+    });
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
BROWSER_ADDR="ws://localhost:3000" node dest
```

### Node.js 側もコンテナ化

適当に Dockerfile を作る

```Dockerfile
FROM nixos/nix:2.9.2

WORKDIR /workdir

RUN nix-env -iA nixpkgs.tini
RUN nix-env -iA nixpkgs.nodejs-16_x
RUN nix-env -iA nixpkgs.yarn


COPY . .

RUN \
  nix-build && \
  nix-collect-garbage -d

ENTRYPOINT ["/root/.nix-profile/bin/tini", "--"]

CMD ["node", "dest"]
```

趣味で nixos ベースになってる



15:00~15:45
