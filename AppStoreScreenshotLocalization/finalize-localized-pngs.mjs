import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "/Users/pradeep.kumar1/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp/dist/index.mjs";

const root = path.dirname(fileURLToPath(import.meta.url));
const outputRoot = path.join(root, "png-output");

const locales = [
  ["en-us", "en-US"],
  ["en-gb", "en-AU"],
  ["en-gb", "en-CA"],
  ["en-gb", "en-GB"],
  ["nl", "nl-NL"],
  ["fr", "fr-FR"],
  ["de", "de-DE"],
  ["it", "it-IT"],
  ["ja", "ja-JP"],
];
const requestedTarget = process.argv[2];
const localesToFinalize = requestedTarget
  ? locales.filter(([, targetLocale]) => targetLocale === requestedTarget)
  : locales;

if (requestedTarget && localesToFinalize.length === 0) {
  throw new Error(`Unknown target locale: ${requestedTarget}`);
}

const names = [
  "01-your-everyday-sodium-tracker.png",
  "02-know-before-you-bite.png",
  "03-log-meals-in-seconds.png",
  "04-reminders-not-nagging.png",
  "05-streaks-that-stick.png",
];

for (const [sourceLocale, targetLocale] of localesToFinalize) {
  const targetDir = path.join(outputRoot, targetLocale);
  fs.mkdirSync(targetDir, { recursive: true });

  for (let index = 1; index <= 5; index += 1) {
    const source = `/private/tmp/pinch-render-${sourceLocale}/${String(index).padStart(2, "0")}.svg.png`;
    const target = path.join(targetDir, names[index - 1]);

    await sharp(source)
      .trim({ background: "#ffffff", threshold: 2 })
      .resize({ width: 1290, height: 2796, fit: "fill" })
      .flatten({ background: "#ffffff" })
      .removeAlpha()
      .png({ compressionLevel: 9, adaptiveFiltering: true })
      .toFile(target);
  }

  const contactSheetDir = path.join(root, "qa-contact-sheets");
  fs.mkdirSync(contactSheetDir, { recursive: true });
  const previews = await Promise.all(
    names.map((name) =>
      sharp(path.join(targetDir, name))
        .resize({ width: 258, height: 559, fit: "fill" })
        .png()
        .toBuffer(),
    ),
  );

  await sharp({
    create: { width: 1290, height: 559, channels: 3, background: "#ffffff" },
  })
    .composite(previews.map((input, index) => ({ input, left: index * 258, top: 0 })))
    .png()
    .toFile(path.join(contactSheetDir, `${targetLocale}.png`));
}

console.log(`Finalized ${localesToFinalize.length * names.length} App Store PNG screenshots in ${outputRoot}`);
