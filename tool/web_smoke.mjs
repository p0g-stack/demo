// Smoke check of the plain web build in headless Chromium: Rust runs in the
// page and in a Squadron Web Worker, from a static server with no COOP/COEP.
//
//   node tool/web_smoke.mjs http://127.0.0.1:8000/
//
// Finds buttons through Flutter's semantics tree, switched on from outside
// the app with the engine's "Enable accessibility" placeholder.
import { chromium } from 'playwright';

const url = process.argv[2];
const expected = [
  /objective\.digest: digest: ran rust_sha2 in web_worker/,
  /ui\.rust: rust in inline on wasm32/,
  /ui\.rust: rust in worker on wasm32/,
];

const browser = await chromium.launch();
// An explicit locale: Flutter refuses an empty navigator.language.
const page = await browser.newPage({ locale: 'en-US', viewport: { width: 1000, height: 1400 } });
const lines = [];
page.on('console', (m) => lines.push(m.text()));
page.on('pageerror', (e) => lines.push(`pageerror: ${e}`));

const seen = (re) => lines.some((l) => re.test(l));
async function until(re, ms = 60000) {
  for (let t = 0; t < ms && !seen(re); t += 250) await page.waitForTimeout(250);
  return seen(re);
}
const button = (name) => page.getByRole('button', { name, exact: true });

let ok = false;
try {
  await page.goto(url);
  const a11y = page.locator('flt-semantics-placeholder');
  await a11y.waitFor({ state: 'attached', timeout: 60000 });
  await a11y.evaluate((e) => e.click());

  await button('SHA-256').click();
  await until(expected[0]);
  await button('Rust').click();
  await button('Run in every place').click();
  await until(expected[1]);
  await until(expected[2]);
  ok = expected.every(seen);
} finally {
  console.log(lines.filter((l) => !/FINEST|WebGL|GPU stall/.test(l)).join('\n'));
  for (const re of expected) console.log(`${seen(re) ? 'ok  ' : 'MISS'} ${re.source}`);
  await browser.close();
}
process.exit(ok ? 0 : 1);
