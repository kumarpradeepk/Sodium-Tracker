import fs from 'node:fs';
import path from 'node:path';
import {literals,swiftFiles} from './source-strings.mjs';
export function sourceCatalog() {
 const result={};
 const skip=/PinchLocalization\.swift|PinchFonts\.swift|PinchFormat\.swift|CSVExporter\.swift|SVGPath\.swift|PinchMascot\.swift|PinchFigure\.swift|SaltyRingCanvas\.swift|SaltyParticleLayer\.swift/;
 for(const root of ['Sodium Tracker','Sodium Tracker Widgets']) for(const file of swiftFiles(root)) {
  if(skip.test(file))continue;
  const source=fs.readFileSync(file,'utf8');
  for(const item of literals(source)) {
   const v=item.value, before=source.slice(Math.max(0,item.start-90),item.start);
   if(item.args.length || !/[A-Za-z]/.test(v))continue;
   if(/^https?:|^M[\d .-]+[A-Z]|^pinch[.:]|^com\.|^group\.|^adhoc:|^fs:|^\$|^Bearer|^[→←⚠✅✗🔎🧂]/u.test(v))continue;
   if(/systemName:\s*$|icon:\s*$|id:\s*$|forKey:\s*$|accessibilityIdentifier\(\s*$|key:\s*$|case\s+\w+\s*=\s*$/.test(before))continue;
   if(!/\s/.test(v)&&!/^\/?[A-Za-z]+(?:…|[!?])?$/.test(v))continue;
   if(/^[a-z]+$/.test(v)&& !/PinchText\(|format\(|resolve\(|serving:\s*$|name:\s*$|\?|:/.test(before))continue;
   if(file.endsWith('FatSecret.swift')&&!['Food','1 serving'].includes(v))continue;
   if(file.endsWith('PinchPalette.swift')&&!['Ocean','Salty','Sage','Iris'].includes(v))continue;
   if(/^(Info|Accept|Authorization|CFBundle|Content-Type|GET|POST|SELECT|PRAGMA|DELETE|INSERT|PINCH_FORCE|NudgeEngine|PinchWidget)/.test(v))continue;
   if(/^\s*$|^[A-Z]\d/.test(v))continue;
   if(['bp','checkmark','circle','customGoal','dark','de','doctor','EEE','EEEEE','en','goalChoice','hasOnboarded','hasSeeded','ja','light','lookupCount','mealRemBreakfast','mealRemDinner','mealRemLunch','now','nudgeState','obDiet','obWhy','plus','seedStartDay','sleuthEarnedAt','system','todayStage','userID'].includes(v))continue;
   if(['cool','leaf','seal'].includes(v))continue; // Internal badge IDs / SF Symbols.
   result[v]=v;
  }
 }
 for(const v of ['Today','Yesterday','Breakfast','Lunch','Dinner','Snacks','annually','monthly','year','month','App language','Follow device language','Check-ins','of {0} mg','{0}-day streak','{0} mg left','{0} mg over','Pinch keeps your sodium count close.','Unlock widgets','Sodium Tracker'])result[v]=v;
 return Object.fromEntries(Object.entries(result).sort(([a],[b])=>a.localeCompare(b)));
}
if(process.argv[2]==='print') console.log(JSON.stringify(sourceCatalog(),null,2));
