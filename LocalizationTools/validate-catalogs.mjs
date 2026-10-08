import fs from 'node:fs';
import assert from 'node:assert/strict';
import {sourceCatalog} from './catalog-source.mjs';
const languages=['en','de','ja','fr','nl','it','es','sv','zh-Hans','ms','ta','ga','mi','rm'];
const appFile='Sodium Tracker/Resources/PinchStrings.json';
const widgetFile='Sodium Tracker Widgets/PinchStrings.json';
assert.equal(fs.readFileSync(appFile,'utf8'),fs.readFileSync(widgetFile,'utf8'),'App/widget catalogs diverged');
const catalogs=JSON.parse(fs.readFileSync(appFile,'utf8'));
assert.deepEqual(Object.keys(catalogs).sort(),[...languages].sort(),'Unexpected or missing bundled language');
const expected=Object.keys(sourceCatalog()).sort();
assert.deepEqual(Object.keys(catalogs.en).sort(),expected,'Source inventory needs updating');
const slots=s=>[...s.matchAll(/\{\d+\}/g)].map(x=>x[0]).sort();
let failed=false;
for(const language of languages) {
 const dictionary=catalogs[language]??{};
 assert.deepEqual(Object.keys(dictionary).sort(),expected,`${language}: catalog keys differ from source`);
 const missing=expected.filter(k=>!dictionary[k]);
 const malformed=Object.entries(dictionary).filter(([k,v])=>typeof v!=='string'||!v.trim()||/ZXQ/i.test(v)||JSON.stringify(slots(k))!==JSON.stringify(slots(v)));
 console.log(`${language}: ${expected.length-missing.length}/${expected.length}; missing=${missing.length}; malformed=${malformed.length}`);
 if(missing.length||malformed.length){failed=true;console.log('  Examples: '+[...missing,...malformed.map(([k])=>k)].slice(0,3).join(' | '));}
}
if(failed)process.exitCode=1;
