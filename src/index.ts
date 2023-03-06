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
