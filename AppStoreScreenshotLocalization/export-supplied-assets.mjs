import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import sharp from '/Users/pradeep.kumar1/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp/dist/index.mjs';

// Format-only export of the user-supplied artwork. Never overwrite originals.
const sourceRoot = '/Users/pradeep.kumar1/Downloads/pinch-screenshots-localized';
const outputRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), 'supplied-assets-1260x2736');
const referenceOnly = new Set(['ga-IE', 'mi-NZ', 'rm-CH']);
const names = ['01_today.png', '02_fits.png', '03_reminders.png', '04_favorites.png', '05_streaks.png'];
const hash = data => crypto.createHash('sha256').update(data).digest('hex');
const results = [];

if (fs.existsSync(outputRoot)) throw new Error('Output already exists; inspect it before producing another export.');
const locales = fs.readdirSync(sourceRoot, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name).sort();
for (const locale of locales) {
  const actual = fs.readdirSync(path.join(sourceRoot, locale)).filter(f => f.endsWith('.png')).sort();
  if (JSON.stringify(actual) !== JSON.stringify([...names].sort())) throw new Error(`Unexpected screenshot set: ${locale}`);
}

for (const locale of locales) {
  const group = referenceOnly.has(locale) ? 'reference-only' : 'store-candidates';
  const targetDir = path.join(outputRoot, group, locale);
  fs.mkdirSync(targetDir, { recursive: true });
  for (const filename of names) {
    const source = path.join(sourceRoot, locale, filename);
    const output = path.join(targetDir, filename);
    const original = fs.readFileSync(source);
    const sourceHash = hash(original);
    const before = await sharp(original).metadata();
    // Source and target ratios differ by under 0.3%; preserve all artwork with
    // a tiny aspect-ratio adjustment rather than cropping words or phone UI.
    const ratioDifference = Math.abs((before.width / before.height) / (1260 / 2736) - 1);
    if (ratioDifference > 0.003) throw new Error(`Unexpected aspect ratio: ${source}`);
    await sharp(original)
      .resize({ width: 1260, height: 2736, fit: 'fill', kernel: sharp.kernel.lanczos3 })
      .flatten({ background: '#ffffff' })
      .removeAlpha()
      .toColourspace('srgb')
      .png({ compressionLevel: 9 })
      .toFile(output);
    const after = await sharp(output).metadata();
    if (after.width !== 1260 || after.height !== 2736 || after.hasAlpha || after.format !== 'png') {
      throw new Error(`Invalid output: ${output}`);
    }
    if (hash(fs.readFileSync(source)) !== sourceHash) throw new Error(`Original changed: ${source}`);
    results.push({ locale, group, filename, source, output, sourceSHA256: sourceHash,
      outputSHA256: hash(fs.readFileSync(output)), sourceSize: [before.width, before.height],
      outputSize: [after.width, after.height], hasAlpha: after.hasAlpha, space: after.space,
      aspectRatioAdjustmentPercent: +(ratioDifference * 100).toFixed(4) });
  }
}
console.log(JSON.stringify({ outputRoot, total: results.length,
  storeCandidates: results.filter(r => r.group === 'store-candidates').length,
  referenceOnly: results.filter(r => r.group === 'reference-only').length,
  scope: 'Dimensions/opaque PNG export only; text and artwork unchanged. Upscaling does not add source detail. API locale IDs and live metadata remain unverified.',
  results }, null, 2));
