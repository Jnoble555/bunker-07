// Verify paths after source extraction: local files and GitHub Pages' project subdirectory.
const {chromium}=require('playwright');
const fs=require('fs'),path=require('path'),http=require('http');
const {pathToFileURL}=require('url');
const root=path.resolve(__dirname,'..');
const server=http.createServer((req,res)=>{
 const pathname=new URL(req.url,'http://localhost').pathname;
 if(!pathname.startsWith('/bunker-07/')){res.writeHead(404).end();return;}
 const file=path.resolve(root,pathname.slice('/bunker-07/'.length)||'index.html');
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 try{res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html');res.end(fs.readFileSync(file));}
 catch{res.writeHead(404).end();}
});
let browser;
(async()=>{
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 browser=await chromium.launch({executablePath:process.env.CHROME_PATH||'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const cases=[
  ['local game',pathToFileURL(path.join(root,'index.html')).href,true],
  ['GitHub Pages subdirectory','http://127.0.0.1:'+server.address().port+'/bunker-07/',true],
  ['local comparison fixture',pathToFileURL(path.join(root,'tests/fixtures/before.html')).href,false]
 ];
 for(const [name,url,current] of cases){
  const page=await browser.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('requestfailed',r=>errors.push(r.url()+': '+r.failure()?.errorText));
  page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
  await page.goto(url);
  const ok=await page.evaluate(current=>{
   const ready=mode==='ready'&&Number.isFinite(depth[240])&&window.Bunker07Missions.breach&&window.Bunker07Audio;
   if(!current)return !!ready;
   const styled=getComputedStyle(document.body).backgroundColor==='rgb(16, 19, 17)';
   canvas.requestPointerLock=()=>Promise.resolve();$('start-campaign').click();$('begin-mission').click();render();
   return !!(ready&&styled&&mode==='play'&&!$('hud').hidden&&window.Bunker07Art&&systems);
  },current);
  await page.close();
  if(!ok||errors.length)throw new Error(name+' failed: '+JSON.stringify(errors));
  console.log('PASS '+name);
 }
})().catch(e=>{console.error(e);process.exitCode=1;}).finally(async()=>{if(browser)await browser.close();server.close();});
