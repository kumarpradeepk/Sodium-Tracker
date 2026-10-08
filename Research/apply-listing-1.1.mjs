import {copy} from './listing-copy-1.1.mjs';
import {api,save,evidence,upload} from './store-listing-update.mjs';
import {readFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {join} from 'node:path';
const version='1f016dcd-1be3-451c-b89a-9c08a242288f';
const info='9b0615c4-0585-4a1a-9129-26cd135f4604';
const assetRoot=join(evidence,'../../AppStoreScreenshotLocalization/supplied-assets-1260x2736');
const selected=process.argv.slice(3);
const entries=Object.entries(copy).filter(([l])=>!selected.length||selected.includes(l));
const current=api('GET','/v1/appStoreVersions/'+version).data;
if(current.attributes.appStoreState!=='PREPARE_FOR_SUBMISSION')throw Error('Draft no longer editable');
if(process.argv[2]==='text'){
 const iv=api('GET','/v1/appInfos/'+info+'/appInfoLocalizations?limit=200');
 const vv=api('GET','/v1/appStoreVersions/'+version+'/appStoreVersionLocalizations?limit=200');
 if(!existsSync(join(evidence,'pre-text-info.json')))save('pre-text-info',iv);
 if(!existsSync(join(evidence,'pre-text-version.json')))save('pre-text-version',vv);
 for(const [locale,c] of entries){
  let i=iv.data.find(x=>x.attributes.locale===locale);
  if(!i)i=api('POST','/v1/appInfoLocalizations',{data:{type:'appInfoLocalizations',attributes:{locale,name:c.name,subtitle:c.subtitle,privacyPolicyUrl:'https://tinkersmithstudio.com/pinch/privacy.html'},relationships:{appInfo:{data:{type:'appInfos',id:info}}}}}).data;
  else if(i.attributes.name!==c.name)i=api('PATCH','/v1/appInfoLocalizations/'+i.id,{data:{type:'appInfoLocalizations',id:i.id,attributes:{name:c.name}}}).data;
  // Adding an app-info locale can also create its version-localization record.
  let v=api('GET','/v1/appStoreVersions/'+version+'/appStoreVersionLocalizations?limit=200').data.find(x=>x.attributes.locale===locale);
  if(!v)v=api('POST','/v1/appStoreVersionLocalizations',{data:{type:'appStoreVersionLocalizations',attributes:{locale,description:c.description,keywords:c.keywords,supportUrl:'https://tinkersmithstudio.com/pinch/'},relationships:{appStoreVersion:{data:{type:'appStoreVersions',id:version}}}}}).data;
  else v=api('PATCH','/v1/appStoreVersionLocalizations/'+v.id,{data:{type:'appStoreVersionLocalizations',id:v.id,attributes:{description:c.description,keywords:c.keywords,...(!v.attributes.supportUrl?{supportUrl:'https://tinkersmithstudio.com/pinch/'}:{})}}}).data;
  const ci=api('GET','/v1/appInfoLocalizations/'+i.id).data,cv=api('GET','/v1/appStoreVersionLocalizations/'+v.id).data;
  if(ci.attributes.name!==c.name||cv.attributes.description!==c.description||cv.attributes.keywords!==c.keywords)throw Error('Read-back mismatch: '+locale);
  save('verified-text-'+locale,{appInfo:ci,versionLocalization:cv});console.log('Verified text: '+locale);
 }
}
if(process.argv[2]==='screenshots'){
 const manifest=JSON.parse(readFileSync(join(assetRoot,'manifest.json')));
 const locals=api('GET','/v1/appStoreVersions/'+version+'/appStoreVersionLocalizations?limit=200').data;
 for(const [locale,c] of entries){
  const l=locals.find(x=>x.attributes.locale===locale);if(!l)throw Error('Missing locale '+locale);
  const files=manifest.results.filter(x=>x.locale===c.folder&&x.group==='store-candidates').sort((a,b)=>a.filename.localeCompare(b.filename));
  if(files.length!==5)throw Error('Expected five screenshots for '+locale);
  for(const f of files)if(createHash('sha256').update(readFileSync(f.output)).digest('hex')!==f.outputSHA256)throw Error('Asset changed: '+f.output);
  const sets=api('GET','/v1/appStoreVersionLocalizations/'+l.id+'/appScreenshotSets?include=appScreenshots&limit=200');
  if(!existsSync(join(evidence,'pre-upload-'+locale+'.json')))save('pre-upload-'+locale,sets);
  let set=sets.data.find(x=>x.attributes.screenshotDisplayType==='APP_IPHONE_67');
  if(!set)set=api('POST','/v1/appScreenshotSets',{data:{type:'appScreenshotSets',attributes:{screenshotDisplayType:'APP_IPHONE_67'},relationships:{appStoreVersionLocalization:{data:{type:'appStoreVersionLocalizations',id:l.id}}}}}).data;
  const existing=api('GET','/v1/appScreenshotSets/'+set.id+'/appScreenshots?limit=200').data;
  const uploaded=[];
  for(const f of files){
   const md5=createHash('md5').update(readFileSync(f.output)).digest('hex');
   let a=existing.find(x=>x.attributes.fileName===f.filename&&x.attributes.sourceFileChecksum===md5);
   if(!a){a=upload(set.id,f.output,locale).data;save('uploaded-'+locale+'-'+f.filename,{data:a});}
   uploaded.push({id:a.id,md5,fileName:f.filename});
   console.log('Uploaded '+locale+' '+f.filename);
  }
  // Never remove old images until every replacement has finished processing.
  let ready=false;
  for(let attempt=0;attempt<12;attempt++){
   const all=api('GET','/v1/appScreenshotSets/'+set.id+'/appScreenshots?limit=200').data;
   const target=uploaded.map(u=>all.find(x=>x.id===u.id));
   if(target.some(x=>x?.attributes.assetDeliveryState?.state==='FAILED'))throw Error('Apple rejected an image in '+locale);
   if(target.every((x,n)=>x?.attributes.assetDeliveryState?.state==='COMPLETE'&&x.attributes.sourceFileChecksum===uploaded[n].md5)){ready=true;break;}
   await new Promise(r=>setTimeout(r,5000));
  }
  if(!ready)throw Error('Images still processing; old images retained for '+locale);
  for(const old of existing.filter(x=>!uploaded.some(u=>u.id===x.id))){
   api('DELETE','/v1/appScreenshots/'+old.id);
   console.log('Replaced old draft screenshot '+locale+' '+old.attributes.fileName);
  }
  api('PATCH','/v1/appScreenshotSets/'+set.id+'/relationships/appScreenshots',{data:uploaded.map(x=>({type:'appScreenshots',id:x.id}))});
  const final=api('GET','/v1/appScreenshotSets/'+set.id+'/appScreenshots?limit=200');
  if(final.data.length!==5||final.data.some((x,n)=>x.id!==uploaded[n].id||x.attributes.assetDeliveryState?.state!=='COMPLETE'))throw Error('Final screenshot verification failed '+locale);
  save('verified-screenshots-'+locale,{setId:set.id,locale,...final});console.log('Verified five ordered screenshots: '+locale);
 }
}
