// Development-only draft translation helper. Never included in either app target.
// Sends only the reviewed English interface catalog, never app/user data.
// Outputs JSON to stdout; the caller reviews and applies it with apply_patch.
import fs from 'node:fs';
const lang=process.argv[2];
if(!['de','ja','fr','nl','it','es','sv','zh-Hans','ms','ta','ga','mi'].includes(lang))throw Error('Unsupported draft language');
const english=JSON.parse(fs.readFileSync('LocalizationTools/en.json','utf8'));
const legacy=JSON.parse(fs.readFileSync('LocalizationTools/legacy-translations.json','utf8'));
const manual=JSON.parse(fs.readFileSync('LocalizationTools/manual-translations.json','utf8'));
const unchanged=new Set(['Pinch','PINCH','Pinch Plus','PINCH PLUS','MG','Na','PLUS','KCAL','28 g','1 oz','2 oz','4 oz','16 oz']);
const result={};
for(const key of Object.keys(english)) {
 if(unchanged.has(key))result[key]=key;
 else if(manual[lang]?.[key])result[key]=manual[lang][key];
 else if(legacy[lang]?.[key])result[key]=legacy[lang][key];
}
const keys=Object.keys(english).filter(k=>!(k in result));
const protect=s=>s.replace(/Pinch/g,'ZXQPINCHZXQ').replace(/FatSecret/g,'ZXQFATSECRETZXQ').replace(/\{(\d+)\}/g,'ZXQARG$1ZXQ').replaceAll('\n',' ZXQNEWLINEZXQ ');
const restore=s=>s.replace(/ZXQ\s*PINCH\s*ZXQ/gi,'Pinch').replace(/ZXQ\s*FATSECRET\s*ZXQ/gi,'FatSecret').replace(/ZXQ\s*ARG\s*(\d+)\s*ZXQ/gi,'{$1}').replace(/\s*ZXQNEWLINEZXQ\s*/gi,'\n');
async function translate(text) {
 const url=new URL('https://translate.googleapis.com/translate_a/single');
 for(const [k,v] of Object.entries({client:'gtx',sl:'en',tl:lang==='zh-Hans'?'zh-CN':lang,dt:'t',q:text}))url.searchParams.set(k,v);
 const response=await fetch(url,{signal:AbortSignal.timeout(25000)});
 if(!response.ok)throw Error('Translation HTTP '+response.status);
 const data=await response.json();
 return data[0].map(x=>x[0]??'').join('');
}
const batches=[];let batch=[],size=0;
for(const key of keys) {
 if(size+key.length>2100&&batch.length){batches.push(batch);batch=[];size=0;}
 batch.push(key);size+=key.length+35;
}if(batch.length)batches.push(batch);
for(let i=0;i<batches.length;i++) {
 const list=batches[i];
 const source=list.map((k,n)=>`[${String(n).padStart(4,'0')}] ${protect(k)}`).join('\n');
 const text=await translate(source);
 const matches=[...text.matchAll(/\[\s*(\d{4})\s*\]\s*([\s\S]*?)(?=\[\s*\d{4}\s*\]|$)/g)];
 if(matches.length!==list.length)throw Error(`Boundary mismatch ${lang} batch ${i}: ${matches.length}/${list.length}`);
 for(const match of matches) {
  const key=list[Number(match[1])]; if(!key)throw Error('Bad translation index');
  let value=restore(match[2].trim());
  const slots=s=>[...s.matchAll(/\{\d+\}/g)].map(x=>x[0]).sort().join(',');
  if(slots(key)!==slots(value)||/ZXQ/i.test(value)) {
   value=restore((await translate(protect(key))).trim());
   if(slots(key)!==slots(value)||/ZXQ/i.test(value))throw Error('Placeholder mismatch: '+key+' => '+value);
  }
  result[key]=value;
 }
 console.error(`${lang}: ${Math.min(keys.length,Object.keys(result).length)} strings; batch ${i+1}/${batches.length}`);
}
console.log(JSON.stringify(Object.fromEntries(Object.keys(english).map(k=>[k,result[k]])),null,2));
