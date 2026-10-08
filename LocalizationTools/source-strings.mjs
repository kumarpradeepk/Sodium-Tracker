// Read-only Swift string inventory. Handles nested interpolation and comments.
import fs from 'node:fs';
import path from 'node:path';
export function literals(source) {
  const found = [];
  function stringAt(start) {
    let i = start + 1, value = '', args = [];
    while (i < source.length) {
      if (source[i] === '"') return {start, end: i + 1, value, args};
      if (source[i] === '\\' && source[i + 1] === '(') {
        const begin = i + 2; i = begin; let depth = 1;
        while (depth && i < source.length) {
          if (source[i] === '"') { i = stringAt(i).end; continue; }
          if (source[i] === '(') depth++;
          if (source[i] === ')') depth--;
          i++;
        }
        value += `{${args.length}}`; args.push(source.slice(begin, i - 1)); continue;
      }
      if (source[i] === '\\') {
        const escaped = source[++i];
        value += ({n:'\n',t:'\t',r:'\r','"':'"','\\':'\\'}[escaped] ?? escaped); i++; continue;
      }
      value += source[i++];
    }
    throw new Error('Unterminated string at ' + start);
  }
  for (let i = 0; i < source.length;) {
    if (source.slice(i,i+2) === '//') { const end = source.indexOf('\n', i); i = end < 0 ? source.length : end; }
    else if (source.slice(i,i+2) === '/*') { const end = source.indexOf('*/',i+2); i = end < 0 ? source.length : end+2; }
    else if (source[i] === '"') { const item = stringAt(i); found.push(item); i=item.end; }
    else i++;
  }
  return found;
}
export function swiftFiles(dir) {
  return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e => e.isDirectory() ? swiftFiles(path.join(dir,e.name)) : e.name.endsWith('.swift') ? [path.join(dir,e.name)] : []);
}
export function patchFile(file, old, next) {
  file = path.resolve(file);
  if (old === next) return '';
  const a=old.trimEnd().split('\n'), b=next.trimEnd().split('\n');
  if(a.length === b.length) {
    let result=`*** Update File: ${file}\n`;
    for(let i=0;i<a.length;i++) if(a[i]!==b[i]) {
      result+='@@\n'; if(i>0) result+=' '+a[i-1]+'\n';
      while(i<a.length && a[i]!==b[i]) {result+='-'+a[i]+'\n'+'+'+b[i]+'\n';i++;}
    }
    return result;
  }
  let start=0,endA=a.length,endB=b.length;
  while(start<Math.min(a.length,b.length)&&a[start]===b[start])start++;
  while(endA>start&&endB>start&&a[endA-1]===b[endB-1]){endA--;endB--;}
  return `*** Update File: ${file}\n@@\n`+(start?' '+a[start-1]+'\n':'')+a.slice(start,endA).map(x=>'-'+x).join('\n')+'\n'+b.slice(start,endB).map(x=>'+'+x).join('\n')+'\n'+(endA<a.length?' '+a[endA]+'\n':'');
}
export function addFile(file, contents) {
  return `*** Add File: ${file}\n` + contents.trimEnd().split('\n').map(x=>'+'+x).join('\n') + '\n';
}
if (process.argv[2] === 'inventory') {
  const base = path.resolve('Sodium Tracker');
  const entries = new Map();
  for (const file of swiftFiles(base)) {
    if (/PinchLocalization.swift|SVGPath.swift|PinchMascot.swift|PinchFigure.swift/.test(file)) continue;
    const source=fs.readFileSync(file,'utf8');
    for (const item of literals(source)) {
      const v=item.value;
      if (!/[A-Za-z]/.test(v) || /^https?:|^M[\d .-]+[A-Z]|^pinch[.:]|^com\.|^adhoc:|^fs:|^\$/.test(v)) continue;
      if (!/\s/.test(v) && !/^[A-Z][a-z]+$/.test(v)) continue;
      const refs=entries.get(v) ?? []; refs.push(path.relative(base,file)+':'+(source.slice(0,item.start).split('\n').length)); entries.set(v,refs);
    }
  }
  console.log(JSON.stringify(Object.fromEntries([...entries].sort()),null,2));
}
