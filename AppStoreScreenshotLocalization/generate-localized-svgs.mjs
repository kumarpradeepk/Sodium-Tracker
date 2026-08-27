import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const sourcePath = path.join(root, "Store Screenshots localized.dc.html");
const fontPath = path.join(root, "Baloo2-Variable.ttf");
const outputRoot = path.join(root, "svg-output");

const source = fs.readFileSync(sourcePath, "utf8");
const fontBase64 = fs.readFileSync(fontPath).toString("base64");
const componentScript = source.match(/<script type="text\/x-dc"[^>]*>([\s\S]*?)<\/script>/)?.[1];
const rowTemplate = source.match(/<sc-for[^>]*>([\s\S]*?)<\/sc-for>/)?.[1];

if (!componentScript || !rowTemplate) {
  throw new Error("Could not find the design component or screenshot template.");
}

class DCLogic {
  constructor() {
    this.props = {};
  }
}

const Component = new Function("DCLogic", `${componentScript}\nreturn Component;`)(DCLogic);
const component = new Component();
component.props = { showIOS: true, showAndroid: false };
const rows = component.renderVals().rows.filter((row) => row.isIos && ["nl", "fr", "it"].includes(row.cc));

function resolveTemplate(template, row) {
  let html = template;
  html = html.replace(/<sc-if value="{{ r\.([A-Za-z0-9_]+) }}"[^>]*>([\s\S]*?)<\/sc-if>/g, (_, key, body) => row[key] ? body : "");
  html = html.replace(/{{\s*r\.([A-Za-z0-9_]+)\s*}}/g, (_, key) => row[key] ?? "");
  return html;
}

function extractBalancedDiv(html, shotId) {
  const marker = `data-shot="${shotId}"`;
  const markerIndex = html.indexOf(marker);
  if (markerIndex < 0) throw new Error(`Missing ${marker}`);

  const start = html.lastIndexOf("<div", markerIndex);
  const tagPattern = /<div\b[^>]*>|<\/div>/g;
  tagPattern.lastIndex = start;
  let depth = 0;
  let match;

  while ((match = tagPattern.exec(html))) {
    if (match[0].startsWith("</")) depth -= 1;
    else depth += 1;
    if (depth === 0) return html.slice(start, tagPattern.lastIndex);
  }
  throw new Error(`Unbalanced div structure for ${shotId}`);
}

function toSvg(shotHtml) {
  const xhtml = shotHtml
    .replace(
      /font-family:\"Baloo 2\", -apple-system, \"Segoe UI\", sans-serif;/g,
      "font-family:'Baloo 2', -apple-system, 'Segoe UI', sans-serif;",
    )
    .replace(/&(?![A-Za-z0-9#]+;)/g, "&amp;")
    .replace(/<svg\b/g, '<svg xmlns="http://www.w3.org/2000/svg"');

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1290" height="2796" viewBox="0 0 430 932">
  <foreignObject x="0" y="0" width="430" height="932">
    <div xmlns="http://www.w3.org/1999/xhtml" style="margin:0;width:430px;height:932px;overflow:hidden;">
      <style>
        @font-face {
          font-family: "Baloo 2";
          src: url(data:font/ttf;base64,${fontBase64}) format("truetype");
          font-style: normal;
          font-weight: 400 900;
        }
        html, body { margin: 0; padding: 0; }
      </style>
      ${xhtml}
    </div>
  </foreignObject>
</svg>`;
}

for (const row of rows) {
  const rowHtml = resolveTemplate(rowTemplate, row);
  const localeDir = path.join(outputRoot, row.cc);
  fs.mkdirSync(localeDir, { recursive: true });

  for (let index = 1; index <= 5; index += 1) {
    const shotId = `${row.sp}-${index}`;
    const shot = extractBalancedDiv(rowHtml, shotId);
    fs.writeFileSync(path.join(localeDir, `${String(index).padStart(2, "0")}.svg`), toSvg(shot));
  }
}

console.log(`Generated ${rows.length * 5} localized SVG screenshots in ${outputRoot}`);
