import {api,save,evidence} from './store-listing-update.mjs';
import {copy} from './listing-copy-1.1.mjs';
import {readFileSync,existsSync} from 'node:fs';
import {join} from 'node:path';
const version='1f016dcd-1be3-451c-b89a-9c08a242288f';
const info='9b0615c4-0585-4a1a-9129-26cd135f4604';
const locales=api('GET','/v1/appStoreVersions/'+version+'/appStoreVersionLocalizations?limit=200');
const infos=api('GET','/v1/appInfos/'+info+'/appInfoLocalizations?limit=200');
const results=[];
for(const [locale,c] of Object.entries(copy)){
 const l=locales.data.find(x=>x.attributes.locale===locale),i=infos.data.find(x=>x.attributes.locale===locale);
 if(!l||!i||i.attributes.name!==c.name||l.attributes.description!==c.description||l.attributes.keywords!==c.keywords||!l.attributes.supportUrl||!i.attributes.privacyPolicyUrl)throw Error('Text validation failed '+locale);
 const sets=api('GET','/v1/appStoreVersionLocalizations/'+l.id+'/appScreenshotSets?include=appScreenshots&limit=200');
 const set=sets.data.find(x=>x.attributes.screenshotDisplayType==='APP_IPHONE_67');
 const verificationFile=join(evidence,'verified-screenshots-'+locale+'.json');
 if(!set||!existsSync(verificationFile))throw Error('No completed screenshot evidence '+locale);
 const expected=JSON.parse(readFileSync(verificationFile));
 const shots=api('GET','/v1/appScreenshotSets/'+set.id+'/appScreenshots?limit=200');
 if(shots.data.length!==5||shots.data.some((x,n)=>x.id!==expected.data[n].id||x.attributes.sourceFileChecksum!==expected.data[n].attributes.sourceFileChecksum||x.attributes.assetDeliveryState?.state!=='COMPLETE'||x.attributes.imageAsset?.width!==1260||x.attributes.imageAsset?.height!==2736))throw Error('Screenshot validation failed '+locale);
 results.push({locale,name:i.attributes.name,subtitle:i.attributes.subtitle,keywords:l.attributes.keywords,screenshotCount:5,status:'verified',versionLocalizationId:l.id,screenshotSetId:set.id});
 console.log('Final read-back verified '+locale);
}
const old=JSON.parse(readFileSync(join(evidence,'before-version-localizations.json'))).data;
const live=api('GET','/v1/appStoreVersions/873e92f2-8358-4199-883b-411eaa98d09e/appStoreVersionLocalizations?limit=200').data;
if(old.length!==live.length||old.some(x=>JSON.stringify(x.attributes)!==JSON.stringify(live.find(y=>y.id===x.id)?.attributes)))throw Error('Live metadata changed');
for(const l of live){
 const before=JSON.parse(readFileSync(join(evidence,'before-screenshots-'+l.attributes.locale+'.json')));
 const after=api('GET','/v1/appStoreVersionLocalizations/'+l.id+'/appScreenshotSets?include=appScreenshots&limit=200');
 const ids=x=>x.data.map(s=>[s.id,(s.relationships.appScreenshots.data||[]).map(a=>a.id)]).sort((a,b)=>a[0].localeCompare(b[0]));
 if(JSON.stringify(ids(before))!==JSON.stringify(ids(after)))throw Error('Live screenshots changed '+l.attributes.locale);
}
const liveInfo=api('GET','/v1/appInfos/20fb3b08-c431-4f98-9230-993674a42ae4/appInfoLocalizations?limit=200');
const oldInfo=JSON.parse(readFileSync(join(evidence,'before-info-20fb3b08-c431-4f98-9230-993674a42ae4.json')));
if(oldInfo.data.length!==liveInfo.data.length||oldInfo.data.some(x=>JSON.stringify(x.attributes)!==JSON.stringify(liveInfo.data.find(y=>y.id===x.id)?.attributes)))throw Error('Live app info changed');
const state=api('GET','/v1/appStoreVersions/'+version).data.attributes;
if(state.appStoreState!=='PREPARE_FOR_SUBMISSION')throw Error('Draft state changed');
const final={appId:'6800595930',version:'1.1',versionId:version,state:state.appStoreState,verifiedAt:new Date().toISOString(),locales:results,localeCount:results.length,screenshotCount:results.length*5,liveVersionUnchanged:true,scope:'Localized iPhone listing screenshots, names, descriptions and keywords; new locale subtitles and required URLs. No price, build, review submission or release changes.',caveats:['13 languages across 17 locale records.','65 unique supplied images reused for regional English and French; 85 uploads total.','Screenshots retain English app UI and are not certified for release-build fidelity.','Irish, Māori and Romansh have no separate App Store listing locales.','Existing iPad screenshots preserved; no replacement iPad assets supplied.','Native-language keyword demand is not fully validated in all markets; no conversion claims.','The app binary translations and pricing/trial rollout remain separate release work.']};
save('final-verification',final);console.log(JSON.stringify(final,null,2));
