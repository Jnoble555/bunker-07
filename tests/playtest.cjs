const {chromium}=require('playwright');
const fs=require('fs'),http=require('http'),path=require('path');
const root=path.resolve(__dirname,'..');
const server=http.createServer((req,res)=>{
 let name=req.url.split('?')[0];
 if(name==='/before') {res.setHeader('Content-Type','text/html');res.end(fs.readFileSync(path.join(root,'tests/fixtures/before.html')));return;}
 if(name==='/')name='/index.html';
 const file=path.join(root,name);if(!file.startsWith(root)){res.writeHead(403).end();return;}
 try{res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':file.endsWith('.css')?'text/css':'text/plain');res.end(fs.readFileSync(file));}catch{res.writeHead(404).end();}
});
(async()=>{
 await new Promise(r=>server.listen(8765,'127.0.0.1',r));
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1100,height:850}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 fs.mkdirSync(path.join(root,'docs/screenshots'),{recursive:true});
 for(const version of ['before','after']) {
  await page.goto('http://127.0.0.1:8765/'+(version==='before'?'before':''));
  await page.evaluate(()=>{missionIndex=1;reset();mode='pause';$('overlay').hidden=true;$('hud').hidden=false;player.x=1.5;player.y=7.5;player.angle=0;render();});
  await page.locator('main').screenshot({path:path.join(root,`docs/screenshots/${version}-maintenance.png`)});
  await page.evaluate(()=>{player.x=2;player.y=5.5;player.angle=0;render();});
  await page.locator('main').screenshot({path:path.join(root,`docs/screenshots/${version}-guard.png`)});
 }
 const results=await page.evaluate(()=>{
  const checks=[];const check=(name,ok)=>{checks.push({name,ok:!!ok});};
  const init=()=>{missionIndex=1;reset();mode='play';};
  init();check('core gate closed',wall(8.5,4.5));
  player.x=3.5;player.y=7.5;chooseRoute();check('maintenance route',firstRoute==='maintenance');
  player.x=4.5;usePanel();check('panel prevents alarm',panelDisabled&&!alarmTriggered);
  player.x=8.5;player.y=5.5;update(.01);check('core collected opens gate',coreCollected&&!wall(8.5,4.5));
  player.x=exit.x;player.y=exit.y;update(.01);check('stealth extraction',mode==='finished'&&campaignStats[mission.id].clear!==null);
  init();player.x=2;player.y=5.5;chooseRoute();check('direct route',firstRoute==='direct');
  update(.5);player.x=2;player.y=7.5;update(.01);check('broken sight resets detection',alertProgress===0);
  player.x=2;player.y=5.5;for(let i=0;i<30;i++)update(.04);
  check('alarm reinforcement once',alarmTriggered&&enemies.length===2);triggerAlarm();check('no duplicate reinforcement',enemies.length===2);
  player.x=4.5;player.y=7.5;usePanel();check('silence preserves reinforcement',!alarmActive&&enemies.length===2);
  init();player.x=4.5;player.y=5.5;player.angle=0;enemies[0].x=6;const armorHP=enemies[0].hp;for(let i=0;i<armorHP;i++){cooldown=0;shoot();}check('armored bot takes three hits and is killed',armorHP===3&&enemies[0].hp===0&&hits===3);
  init();alarmTriggered=true;player.x=4;player.y=5.5;enemies[0].attack=0;update(.01);check('attack windup',enemies[0].attackWindup>0);update(.8);check('armored attack damage',player.hp===82);
  for(let i=0;i<3;i++){missionIndex=i;reset();render();check('mission renders '+mission.id,Number.isFinite(depth[240]));}
  // Traverse using the real collision/movement/update path, without teleporting between waypoints.
  const walkTo=(x,y)=>{
   for(let i=0;i<1200 && mode==='play';i++) {
    const dx=x-player.x,dy=y-player.y,d=Math.hypot(dx,dy);if(d<.04)return true;
    const step=Math.min(d,2.65*.02);move(player,dx/d*step,dy/d*step);update(.02);
   }
   return mode==='finished';
  };
  init();
  let walked=walkTo(1.5,7.5)&&walkTo(4.5,7.5);usePanel();
  walked=walked&&walkTo(8.5,7.5)&&walkTo(8.5,5.5)&&walkTo(8.5,4.5)&&walkTo(10.5,4.5)&&walkTo(10.5,1.5)&&walkTo(11.5,1.5);
  check('maintenance collision traversal and extraction',walked&&mode==='finished'&&coreCollected&&!alarmTriggered);
  init();walked=walkTo(1.5,5.5)&&walkTo(2,5.5);
  for(let i=0;i<60;i++)update(.02);
  player.angle=0;shoot();cooldown=0;shoot();
  walked=walked&&walkTo(8.5,5.5)&&walkTo(8.5,4.5)&&walkTo(10.5,4.5)&&walkTo(10.5,1.5)&&walkTo(11.5,1.5);
  check('direct collision traversal and alarm extraction',walked&&mode==='finished'&&coreCollected&&alarmTriggered);
  return checks;
 });
 await page.evaluate(()=>{missionIndex=1;reset();mode='play';$('overlay').hidden=true;});
 await page.keyboard.press('Space');await page.keyboard.press('KeyR');await page.waitForTimeout(1000);
 results.push({name:'keyboard reload completes',ok:await page.evaluate(()=>player.ammo===8&&reloadTimer===0)});
 await page.keyboard.press('KeyP');results.push({name:'pause UI',ok:await page.locator('#pause-screen').isVisible()});
 // Exercise campaign/menu handlers with pointer capture disabled for headless determinism.
 await page.goto('http://127.0.0.1:8765/');
 await page.evaluate(()=>{canvas.requestPointerLock=()=>Promise.resolve();localStorage.removeItem(TUTORIAL_KEY);});
 await page.locator('#start-campaign').click();
 results.push({name:'campaign briefing UI',ok:await page.locator('#briefing-screen').isVisible()});
 await page.locator('#begin-mission').click();
 await page.keyboard.press('KeyP');
 results.push({name:'pause hides tutorial',ok:await page.locator('#tutorial').isHidden()});
 await page.locator('#pause-settings').click();
 results.push({name:'pause settings UI',ok:await page.locator('#settings-screen').isVisible()});
 await page.locator('#settings-back').click();await page.locator('#resume').click();
 results.push({name:'resume restores HUD controls tutorial',ok:await page.evaluate(()=>!$('hud').hidden&&!$('play-controls').hidden&&!$('tutorial').hidden)});
 const more=await page.evaluate(()=>{
  const checks=[],check=(name,ok)=>checks.push({name,ok:!!ok});
  progressTutorial('move');progressTutorial('aim');shoot();
  const shotsBefore=shots;reloadTimer=RELOAD_DURATION;shoot();check('reload blocks firing',shots===shotsBefore);update(RELOAD_DURATION);progressTutorial('reload');
  check('tutorial completion persisted',readStoredValue(TUTORIAL_KEY)==='true'&&$('tutorial').hidden);
  finish(false);const failedRun=run;$('result-action').click();
  check('retry resets mission and counts attempt',missionIndex===0&&run===failedRun+1&&campaignStats.breach.retries===1&&player.hp===100&&player.ammo===8);
  finish(true);$('result-action').click();check('continue opens next briefing',missionIndex===1&&!$('briefing-screen').hidden);
  $('begin-mission').click();check('control room starts clean',mission.id==='control-room'&&!alarmTriggered&&!panelDisabled&&!coreCollected);
  finish(true);$('result-action').click();$('begin-mission').click();
  check('blackout exit locked before power',!powerRestored);player.x=exit.x;player.y=exit.y;update(.01);check('blackout cannot exit unpowered',mode==='play');
  player.x=panel.x;player.y=panel.y;usePanel();check('blackout power use',powerRestored&&panelDisabled);
  player.x=exit.x;player.y=exit.y;update(.01);check('campaign summary after final exit',mode==='finished'&&!$('campaign-summary').hidden&&campaignStats.blackout.clear!==null);
  const eventCount=events.length;$('result-action').click();check('new campaign preserves session events',events.length===eventCount&&missionIndex===0&&campaignStats.breach.clear===null&&campaignStats.breach.retries===0);
  missionIndex=1;reset();mode='play';alarmTriggered=true;player.x=4;player.y=5.5;enemies[0].attack=0;update(.01);player.x=2;update(1);
  check('escaping windup avoids damage',player.hp===100&&enemies[0].attackWindup===0);
  check('CSV quotes special fields',csvCell('a,"b"\nc')==='"a,""b""\nc"');
  showTitle();return checks;
 });results.push(...more);
 await page.locator('#open-settings').click();
 await page.locator('#volume').fill('0.25');await page.locator('#volume').dispatchEvent('input');
 await page.locator('#mute').check();
 await page.locator('#sensitivity').fill('0.005');await page.locator('#sensitivity').dispatchEvent('input');
 await page.reload();results.push({name:'settings survive reload',ok:await page.evaluate(()=>preferences.volume===.25&&preferences.muted&&preferences.sensitivity===.005&&window.Bunker07Audio.getMuted())});
 await page.locator('#open-settings').click();await page.locator('#reset-settings').click();
 results.push({name:'settings reset defaults',ok:await page.evaluate(()=>JSON.stringify(preferences)===JSON.stringify(DEFAULT_PREFERENCES))});
 await page.evaluate(()=>{canvas.requestPointerLock=()=>Promise.resolve();missionIndex=0;startMission();shoot();pause();});
 const downloadPromise=page.waitForEvent('download');await page.locator('#export').click();const download=await downloadPromise;
 const csv=fs.readFileSync(await download.path(),'utf8');results.push({name:'CSV download includes mission and combat',ok:csv.startsWith('run,elapsed_seconds,')&&csv.includes('mission_id')&&csv.includes('mission_start')&&csv.includes('shot')&&csv.includes('breach')});
 const fallback=await browser.newContext();await fallback.addInitScript(()=>{Object.defineProperty(window,'localStorage',{get(){throw new Error('storage unavailable');}});window.AudioContext=undefined;window.webkitAudioContext=undefined;});
 const fallbackPage=await fallback.newPage();fallbackPage.on('pageerror',e=>errors.push(e.message));await fallbackPage.goto('http://127.0.0.1:8765/');
 results.push({name:'storage and audio unavailable remain playable',ok:await fallbackPage.evaluate(()=>{canvas.requestPointerLock=()=>Promise.resolve();startMission();shoot();savePreferences();return mode==='play'&&shots===1&&preferences.volume===.65;})});await fallback.close();
 const capturePage=await browser.newPage();capturePage.on('pageerror',e=>errors.push(e.message));await capturePage.goto('http://127.0.0.1:8765/');
 await capturePage.evaluate(()=>{startMission();pause();});await capturePage.waitForTimeout(300);
 results.push({name:'late pointer capture released on menu',ok:await capturePage.evaluate(()=>mode==='pause'&&document.pointerLockElement!==canvas&&!$('pause-screen').hidden)});await capturePage.close();
 const perf=await page.evaluate(()=>{missionIndex=1;reset();const t=performance.now();for(let i=0;i<30;i++)render();return (performance.now()-t)/30;});
 const report={checks:results,errors,averageRenderMs:perf};
 fs.writeFileSync(path.join(root,'docs/playtest-results.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
 await browser.close();server.close();if(errors.length||results.some(r=>!r.ok))process.exitCode=1;
})().catch(e=>{console.error(e);server.close();process.exitCode=1;});
