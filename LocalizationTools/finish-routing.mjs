import fs from 'node:fs';
import path from 'node:path';
import {swiftFiles,patchFile} from './source-strings.mjs';
let patch='*** Begin Patch\n';
for(const file of swiftFiles(path.resolve('Sodium Tracker'))) {
 if(!file.includes('/Screens/')) continue;
 const old=fs.readFileSync(file,'utf8');let next=old;
 for(const [text,h,m] of [['8:00 AM',8,0],['12:30 PM',12,30],['6:30 PM',18,30]]) next=next.replaceAll(JSON.stringify(text),`PinchFormat.clock(hour: ${h}, minute: ${m})`);
 next=next.replaceAll('["S", "M", "T", "W", "T", "F", "S"]','PinchFormat.weekdaySymbols');
 next=next.replaceAll('String(describing: ui.plan == .yearly ? "annually" : "monthly")','PinchLocalization.resolve(ui.plan == .yearly ? "annually" : "monthly")');
 next=next.replaceAll('String(describing: value == .yearly ? "year" : "month")','PinchLocalization.resolve(value == .yearly ? "year" : "month")');
 next=next.replaceAll('String(describing: cadence)','PinchLocalization.resolve(cadence)');
 next=next.replaceAll('String(describing: product?.displayPrice ?? "Price unavailable")','product?.displayPrice ?? PinchLocalization.resolve("Price unavailable")');
 next=next.replaceAll('String(describing: fits ? "Fits in today’s remaining budget" : "Does not fit in today’s remaining budget")','PinchLocalization.resolve(fits ? "Fits in today’s remaining budget" : "Does not fit in today’s remaining budget")');
 patch+=patchFile(file,old,next);
}
console.log(patch+'*** End Patch');
