const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const DESIGN_DIR = path.join(__dirname, '..');
const OUTPUT_DIR = __dirname;

const SCREENSHOTS = [
  {
    name: 'sportx-screenshot-1-home.jpg',
    htmlFile: 'home-dashboard.html',
    viewport: { width: 390, height: 844 }
  },
  {
    name: 'sportx-screenshot-2-trials.jpg',
    htmlFile: 'trial-listings.html',
    viewport: { width: 390, height: 844 }
  },
  {
    name: 'sportx-screenshot-3-coaches.jpg',
    htmlFile: 'coach-directory.html',
    viewport: { width: 390, height: 844 }
  },
  {
    name: 'sportx-screenshot-4-academies.jpg',
    htmlFile: 'academy-directory.html',
    viewport: { width: 390, height: 844 }
  },
  {
    name: 'sportx-feature-graphic.jpg',
    isFeature: true,
    viewport: { width: 1024, height: 500 }
  }
];

async function generateScreenshots() {
  console.log('🚀 Starting screenshot generation...\n');

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  for (const shot of SCREENSHOTS) {
    try {
      console.log(`📸 Generating: ${shot.name}`);

      const page = await browser.newPage();
      await page.setViewport({
        width: shot.viewport.width,
        height: shot.viewport.height,
        deviceScaleFactor: 2
      });

      let htmlPath;
      if (shot.isFeature) {
        htmlPath = path.join(__dirname, 'feature-graphic.html');
      } else {
        htmlPath = path.join(DESIGN_DIR, shot.htmlFile);
      }

      const fileUrl = `file://${htmlPath}`;
      await page.goto(fileUrl, { waitUntil: 'networkidle0', timeout: 30000 });

      await page.evaluate(() => {
        return new Promise(resolve => {
          if (document.readyState === 'complete') {
            resolve();
          } else {
            window.addEventListener('load', resolve);
          }
        });
      });

      await new Promise(r => setTimeout(r, 1500));

      const screenshotPath = path.join(OUTPUT_DIR, shot.name);

      if (shot.isFeature) {
        const featureEl = await page.$('#feature-graphic');
        if (featureEl) {
          await featureEl.screenshot({
            path: screenshotPath,
            type: 'jpeg',
            quality: 95
          });
        } else {
          await page.screenshot({
            path: screenshotPath,
            type: 'jpeg',
            quality: 95,
            clip: { x: 0, y: 0, width: 1024, height: 500 }
          });
        }
      } else {
        await page.screenshot({
          path: screenshotPath,
          type: 'jpeg',
          quality: 95
        });
      }

      console.log(`   ✅ Saved: ${shot.name}`);
      await page.close();

    } catch (error) {
      console.log(`   ❌ Error: ${error.message}`);
    }
  }

  await browser.close();
  console.log('\n✨ Done! Screenshots saved to:', OUTPUT_DIR);
}

generateScreenshots().catch(console.error);
