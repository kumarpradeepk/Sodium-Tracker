import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, dirname } from 'node:path';
import { randomUUID } from 'node:crypto';

const root = dirname(fileURLToPath(import.meta.url));
export const evidence = join(root, 'appstore-update-2026-09-06');
mkdirSync(evidence, {recursive:true});
const cli = '/Users/pradeep.kumar1/.codex/plugins/cache/personal/store-metadata-agent/0.1.0+codex.20260827083035/scripts/store_api.mjs';
export function save(name, data) {
  // Upload URLs/asset tokens are transient transport credentials, not audit evidence.
  writeFileSync(join(evidence, `${name}.json`), JSON.stringify(data,(key,value)=>['uploadOperations','assetToken'].includes(key)?undefined:value,2));
}
export function api(method,path,body) {
  const args=[cli,'apple','request','--method',method,'--path',path];
  if(body){ const file=join(evidence,'request-'+randomUUID()+'.json');writeFileSync(file,JSON.stringify(body));args.push('--input',file); }
  const result=execFileSync(process.execPath,args,{encoding:'utf8',maxBuffer:20*1024*1024,timeout:120000});
  return result.trim()?JSON.parse(result):null;
}
export function upload(setId,file,locale) {
  const bytes=readFileSync(file);
  const reserve=join(evidence,`reserve-${locale}.json`),commit=join(evidence,`commit-${locale}.json`);
  writeFileSync(reserve,JSON.stringify({data:{type:'appScreenshots',attributes:{fileName:file.split('/').at(-1),fileSize:bytes.length},relationships:{appScreenshotSet:{data:{type:'appScreenshotSets',id:setId}}}}}));
  writeFileSync(commit,JSON.stringify({data:{type:'appScreenshots',id:'$ASSET_ID',attributes:{uploaded:true}}}));
  const result=execFileSync(process.execPath,[cli,'apple','upload-asset','--reserve-path','/v1/appScreenshots','--reserve-input',reserve,'--commit-path','/v1/appScreenshots/$ASSET_ID','--commit-input',commit,'--file',file],{encoding:'utf8',maxBuffer:5*1024*1024,timeout:180000});
  return JSON.parse(result);
}

if(process.argv[2]==='inspect') {
  const infos=api('GET','/v1/apps/6800595930/appInfos');save('before-appInfos',infos);
  const locals=api('GET','/v1/appStoreVersions/873e92f2-8358-4199-883b-411eaa98d09e/appStoreVersionLocalizations?limit=200');save('before-version-localizations',locals);
  for(const info of infos.data){const l=api('GET',`/v1/appInfos/${info.id}/appInfoLocalizations?limit=200`);save(`before-info-${info.id}`,l);console.log(JSON.stringify({info:info.id,localizations:l.data.map(x=>({id:x.id,...x.attributes}))}));}
  for(const l of locals.data){const s=api('GET',`/v1/appStoreVersionLocalizations/${l.id}/appScreenshotSets?include=appScreenshots&limit=200`);save(`before-screenshots-${l.attributes.locale}`,s);console.log(JSON.stringify({locale:l.attributes.locale,sets:s.data.map(x=>({id:x.id,...x.attributes,count:x.relationships.appScreenshots.data?.length})),screenshots:(s.included||[]).map(x=>({id:x.id,fileName:x.attributes.fileName}))}));}
}
if(process.argv[2]==='create-version'){
 const versions=api('GET','/v1/apps/6800595930/appStoreVersions?filter[platform]=IOS&limit=20');
 if(versions.data.some(x=>x.attributes.versionString==='1.1'))throw Error('1.1 exists; inspect instead');
 const v=api('POST','/v1/appStoreVersions',{data:{type:'appStoreVersions',attributes:{platform:'IOS',versionString:'1.1'},relationships:{app:{data:{type:'apps',id:'6800595930'}}}}});
 save('created-version',v);console.log(JSON.stringify(v));
}
