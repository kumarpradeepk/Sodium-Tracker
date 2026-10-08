import fs from 'node:fs';
import path from 'node:path';
import {literals,swiftFiles,patchFile} from './source-strings.mjs';
const root=path.resolve('Sodium Tracker');
let patch='*** Begin Patch\n';
const quote=s=>JSON.stringify(s).replaceAll('\\/', '/');
for(const file of swiftFiles(root)) {
  if(!/\/(Screens|Components|Models)\//.test(file) || /PinchMascot|PinchFigure/.test(file)) continue;
  const old=fs.readFileSync(file,'utf8'); let next=old;
  // Interpolate AFTER translating the template; never parse user data as copy.
  const edits=literals(old).filter(x=>x.args.length && /[A-Za-z]/.test(x.value)
    && !/^M[\d .-]|^https?:|^pinch[.:]|^adhoc:|^fs:/.test(x.value)
    && /\s|\/year|\/mo|streak/.test(x.value));
  for(const x of edits.reverse()) {
    const expr='PinchLocalization.format('+quote(x.value)+', ['+x.args.map(a=>'String(describing: '+a+')').join(', ')+'])';
    next=next.slice(0,x.start)+expr+next.slice(x.end);
  }
  if(file.endsWith('/PaywallSheet.swift')) {
    next=next.replace(/\bText\(/g,'PinchText(');
    next=next.replace('Label(benefit,','Label(PinchLocalization.resolve(benefit),');
    next=next.replace('.accessibilityLabel(title)', '.accessibilityLabel(PinchLocalization.resolve(title))');
  }
  // String-taking native controls otherwise bypass our shared catalog.
  for(const method of ['accessibilityLabel','accessibilityHint','accessibilityValue','navigationTitle','displayName','description']) {
    const rx=new RegExp('\\.'+method+'\\(("(?:[^"\\\\]|\\\\.)*"(?:\\s*\\?[^\\n]*)?)\\)','g');
    next=next.replace(rx,(all,arg)=>'.'+method+'(PinchLocalization.resolve('+arg+'))');
  }
  next=next.replace(/(Button|Label|Link|Toggle)\(("(?:[^"\\\\]|\\\\.)*")([,)])/g, '$1(PinchLocalization.resolve($2)$3');
  for(const key of ['isFavorite ? "Remove from favorites" : "Pin to favorites"','leading ? "Previous day" : "Next day"']) {
    next=next.replace('.accessibilityLabel('+key+')','.accessibilityLabel(PinchLocalization.resolve('+key+'))');
  }
  patch+=patchFile(file,old,next);
}
console.log(patch+'*** End Patch');
