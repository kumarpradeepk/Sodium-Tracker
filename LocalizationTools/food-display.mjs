import fs from 'node:fs';
import {swiftFiles,patchFile} from './source-strings.mjs';
let patch='*** Begin Patch\n';
for(const file of [...swiftFiles('Sodium Tracker/Screens'), 'Sodium Tracker/Components/SharedComponents.swift']) {
 const old=fs.readFileSync(file,'utf8');let next=old;
 for(const variable of ['food','option','resolved'])for(const [field,display] of [['name','displayName'],['serving','displayServing']]) {
  next=next.replaceAll(`PinchText(${variable}.${field})`,`Text(verbatim: ${variable}.${display})`);
  next=next.replaceAll(`String(describing: ${variable}.${field})`,`${variable}.${display}`);
  next=next.replaceAll(`String(describing: PinchLocalization.resolve(${variable}.${field}))`,`${variable}.${display}`);
 }
 for(const raw of ['isOn ? "On" : "Off"','selected ? "Selected" : "Not selected"','favorites.contains(where: { $0.foodID == option.id }) ? "Favorite" : "Recommended"','favorites.contains(where: { $0.foodID == food.id }) ? "Favorite" : "Recommended"']) {
  next=next.replaceAll('.accessibilityValue('+raw+')','.accessibilityValue(PinchLocalization.resolve('+raw+'))');
 }
 patch+=patchFile(file,old,next);
}
console.log(patch+'*** End Patch');
