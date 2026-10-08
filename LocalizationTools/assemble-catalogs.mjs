import fs from 'node:fs';
import assert from 'node:assert/strict';
import {sourceCatalog} from './catalog-source.mjs';

// Deterministic, offline generation. Never publish a partial language catalog.
const languages=['en','de','ja','fr','nl','it','es','sv','zh-Hans','ms','ta','ga','mi','rm'];
const english=sourceCatalog();
const keys=Object.keys(english).sort();
const slots=value=>[...value.matchAll(/\{\d+\}/g)].map(x=>x[0]).sort();
const catalogs={en:english};
for(const language of languages.slice(1)) {
  const dictionary=JSON.parse(fs.readFileSync(`LocalizationTools/release-catalogs/${language}.json`,'utf8'));
  assert.deepEqual(Object.keys(dictionary).sort(),keys,`${language}: source keys differ`);
  for(const [key,value] of Object.entries(dictionary)) {
    assert.equal(typeof value,'string');
    assert.ok(value.trim(),`${language}: empty ${key}`);
    assert.deepEqual(slots(value),slots(key),`${language}: placeholders differ for ${key}`);
  }
  catalogs[language]=Object.fromEntries(Object.keys(english).map(key=>[key,dictionary[key]]));
}
const output=JSON.stringify(catalogs,null,2)+'\n';
for(const file of ['Sodium Tracker/Resources/PinchStrings.json','Sodium Tracker Widgets/PinchStrings.json']) fs.writeFileSync(file,output);
fs.writeFileSync('LocalizationTools/en.json',JSON.stringify(english,null,2)+'\n');
console.log(`Bundled ${languages.length} complete catalogs, ${keys.length} keys each; app/widget identical.`);
