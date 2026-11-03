const http = require('node:http');
const fs = require('node:fs/promises');
const fsSync = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require('C:/Users/Honorio/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');

const root = path.resolve(__dirname, '..');
const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.svg': 'image/svg+xml', '.png': 'image/png', '.webmanifest': 'application/manifest+json' };
const server = http.createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const target = path.resolve(root, pathname === '/' ? 'index.html' : `.${pathname}`);
    if (!target.startsWith(root + path.sep)) throw new Error('Caminho inválido');
    const content = await fs.readFile(target);
    response.writeHead(200, { 'Content-Type': types[path.extname(target)] || 'application/octet-stream' });
    response.end(content);
  } catch {
    response.writeHead(404).end('Não encontrado');
  }
});

(async () => {
  const externalUrl = process.env.RODA_TEST_URL;
  if (!externalUrl) await new Promise(resolve => server.listen(41731, '127.0.0.1', resolve));
  const baseUrl = externalUrl || 'http://127.0.0.1:41731/';
  const browserCandidates = [
    process.env.RODA_BROWSER_PATH,
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Users/Honorio/AppData/Local/Programs/Opera GX/opera.exe'
  ].filter(Boolean);
  const executablePath = browserCandidates.find(candidate => fsSync.existsSync(candidate));
  const browser = await chromium.launch({ headless: true, ...(executablePath ? { executablePath } : {}) });
  try {
    const widths = [360, 390, 768, 1280, 1920, 2560];
    for (const width of widths) {
      const page = await browser.newPage({ viewport: { width, height: 900 } });
      const errors = [];
      page.on('pageerror', error => errors.push(error.message));
      const target = new URL(baseUrl);
      target.searchParams.set('smoke', String(width));
      await page.goto(target.href, { waitUntil: 'domcontentloaded' });
      await page.waitForFunction(() => window.supabase && window.LivekitClient, null, { timeout: 15000 });
      assert.equal(await page.locator('#auth').isVisible(), true, `login invisível em ${width}px`);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth), true, `overflow em ${width}px`);
      await page.evaluate(() => document.documentElement.classList.add('theme-light'));
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth), true, `overflow claro em ${width}px`);
      assert.deepEqual(errors, [], `erros JavaScript em ${width}px`);
      await page.close();
    }
    console.log('PASS: login, scripts, temas e seis larguras sem erro ou rolagem horizontal');
  } finally {
    await browser.close();
    if (server.listening) server.close();
  }
})().catch(error => {
  console.error(error);
  if (server.listening) server.close();
  process.exitCode = 1;
});
