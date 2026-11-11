/* Original encounter systems. Devices are billboards; only the marked bulkhead affects grid collision. */
(() => {
  'use strict';
  function create(api) {
    const data = Object.freeze({
      camera:{x:7.3,y:5.5}, power:{x:6.5,y:7.5}, overload:{x:8.5,y:7.5},
      intel:{x:8.5,y:5.5}, doorSwitch:{x:7.5,y:7.5}, door:{x:8,y:6},
      cache:{x:7.5,y:8.5}, lamp:{x:3.5,y:5.8}
    });
    const campaign = {securityDisabled:false,alarmRaised:false,intel:false,secret:false};
    let current = {}, journal = [], campaignJournal = [], activeMission = '';
    const state=()=>api.state();
    const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
    const isControl=()=>activeMission==='control-room';
    function note(text) {
      if(!journal.includes(text)) journal.push(text);
      api.message?.(text);
    }
    function visible(from,to) {
      const d=distance(from,to);
      return d<.001 || api.ray(from.x,from.y,(to.x-from.x)/d,(to.y-from.y)/d).dist>=d-.02;
    }
    function assignRole(bot,role) {
      if(bot.role)return;
      bot.role=role;
      if(role==='armored') { bot.hp=Math.max(bot.hp,3);bot.speed=.58;bot.damage=18;bot.attackRange=1.15; }
      else if(role==='turret') {bot.speed=0;bot.damage=10;bot.attackRange=4.5;}
      else {bot.speed=1.25;bot.damage=8;bot.attackRange=.95;}
      bot.facing=Math.PI;
      bot.stagger=0;
    }
    function reset() {
      const s=state();
      activeMission=s.mission.id;
      current={powerRouted:false,overloaded:false,intel:false,secret:false,doorOpen:true,
        camera:{disabled:false,alert:0,angle:Math.PI},lamps:[{...data.lamp,broken:false}],
        investigation:null,patrolTarget:0,completed:false,noiseCount:0,rank:null};
      journal=campaignJournal.slice();
      for(const bot of s.enemies) assignRole(bot,isControl()?'armored':s.mission.id==='blackout'?'turret':'scout');
      if(isControl()) {
        note('CONTROL LOG: Evacuation cut short. Camera watches the direct hall. Maintenance power feeds the camera and service lights.');
      } else if(s.mission.id==='blackout') {
        if(campaign.securityDisabled) {
          for(const bot of s.enemies)if(bot.role==='turret')bot.hp=0;
          note('SECURITY LINK: Your Control Room shutdown has disabled the extraction turret.');
        } else if(campaign.alarmRaised) {
          const bot={id:'pursuit-armor',x:7.5,y:4.5,hp:3,attack:.8,attackWindup:0};
          assignRole(bot,'armored');s.enemies.push(bot);
          note('SECURITY LINK: Control Room alarm remains on record. An armored pursuit unit is deployed.');
        } else note('BLACKOUT LOG: Backup power is independent of the extraction turret. Watch the long corridor.');
        if(campaign.intel)note('RECOVERED INTEL: Backup switch is in the southwest service bay. Turrets cannot move; cross behind walls.');
      } else note('BREACH LOG: Scout units move quickly but have light armor. Keep space and use the corners.');
    }
    function newCampaign() {
      Object.assign(campaign,{securityDisabled:false,alarmRaised:false,intel:false,secret:false});
      journal=[];campaignJournal=[];
    }
    function noise(x,y) {
      if(!isControl())return;
      current.noiseCount++;
      const guard=state().enemies.find(bot=>bot.guard&&bot.hp>0);
      if(guard&&Math.hypot(guard.x-x,guard.y-y)<6&&!state().alarmTriggered) {
        current.investigation={x,y,left:5};
        guard.facing=Math.atan2(y-guard.y,x-guard.x);
        api.log('guard_investigating',guard.id,'gunshot');
      }
    }
    // Find the next tile along a short grid route to a last-heard location.
    function nextWaypoint(bot,target) {
      const s=state(),start={x:Math.floor(bot.x),y:Math.floor(bot.y)},end={x:Math.floor(target.x),y:Math.floor(target.y)};
      const key=p=>p.x+','+p.y,queue=[start],previous=new Map([[key(start),null]]);
      for(let i=0;i<queue.length&&i<180;i++) {
        const p=queue[i];if(p.x===end.x&&p.y===end.y)break;
        for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
          const n={x:p.x+dx,y:p.y+dy},k=key(n);
          if(previous.has(k)||(s.map[n.y]?.[n.x]??'#')==='#'||isWall(n.x,n.y))continue;
          previous.set(k,p);queue.push(n);
        }
      }
      if(!previous.has(key(end)))return null;
      let step=end,parent=previous.get(key(step));
      while(parent&&key(parent)!==key(start)){step=parent;parent=previous.get(key(step));}
      return step.x===start.x&&step.y===start.y?target:{x:step.x+.5,y:step.y+.5};
    }
    function update(dt) {
      const s=state();
      for(const bot of s.enemies)if(!bot.role)assignRole(bot,bot.guard?'armored':'scout');
      if(!isControl())return;
      const camera=current.camera;
      camera.angle=Math.PI+Math.sin(s.time*.65)*.42;
      const enabled=!camera.disabled&&!current.powerRouted&&!s.panelDisabled&&!s.alarmTriggered;
      const d=distance(data.camera,s.player),angle=Math.atan2(s.player.y-data.camera.y,s.player.x-data.camera.x);
      const inCone=Math.cos(angle-camera.angle)>.91;
      const wasTracking=camera.alert>0;
      camera.alert=!enabled?0:d<6&&inCone&&visible(data.camera,s.player)?Math.min(1.25,camera.alert+dt):Math.max(0,camera.alert-dt*2);
      if(!wasTracking&&camera.alert>0)api.sound?.('detect',data.camera.x,data.camera.y);
      if(camera.alert>=1.25) {api.log('camera_detected','camera_1');api.triggerAlarm();camera.alert=0;}
      const guard=s.enemies.find(bot=>bot.guard&&bot.hp>0);
      if(!guard||s.alarmTriggered||guard.stagger>0)return;
      let target;
      if(current.investigation) {
        current.investigation.left-=dt;
        if(current.investigation.left<=0||distance(guard,current.investigation)<.3)current.investigation=null;
      }
      if(current.investigation)target=nextWaypoint(guard,current.investigation);
      else {
        const patrol=[{x:3.5,y:5.5},{x:6.1,y:5.5}];
        target=patrol[current.patrolTarget];
        if(distance(guard,target)<.12){current.patrolTarget=1-current.patrolTarget;target=patrol[current.patrolTarget];}
      }
      if(target) {
        const x=target.x-guard.x,y=target.y-guard.y,d=Math.hypot(x,y);
        if(d>.04){const step=Math.min(d,.42*dt),ox=guard.x,oy=guard.y;api.move(guard,x/d*step,y/d*step);guard.moving=distance(guard,{x:ox,y:oy})>.0001;guard.facing=Math.atan2(y,x);}
      }
    }
    function devices() {
      if(!isControl())return [];
      return [
        {id:'power',...data.power,label:current.powerRouted?'SERVICE POWER OFF':'REROUTE POWER',detail:'Disable camera; darken service lights'},
        {id:'overload',...data.overload,label:current.overloaded?'OVERLOAD SPENT':'OVERLOAD GRID',detail:'One use: stagger nearby security units'},
        {id:'intel',...data.intel,label:current.intel?'INTEL RECOVERED':'RECOVER OPTIONAL INTEL',detail:'Triggers alarm unless security is disabled'},
        {id:'door',...data.doorSwitch,label:current.doorOpen?'CLOSE BULKHEAD':'OPEN BULKHEAD',detail:'Blocks the maintenance approach'},
        ...(!current.secret?[{id:'cache',...data.cache,label:'SEARCH HIDDEN CACHE',detail:'Optional supply locker and evacuation log'}]:[])
      ];
    }
    function nearby() {
      const s=state();
      return devices().filter(d=>distance(d,s.player)<=.8&&visible(s.player,d)).sort((a,b)=>distance(a,s.player)-distance(b,s.player))[0]||null;
    }
    function prompt() {
      if(!isControl())return '';
      const d=nearby();
      if(d)return `E · ${d.label}`;
      if(current.camera.alert>0)return `CAMERA TRACKING · ${Math.ceil(current.camera.alert/1.25*100)}%`;
      if(current.investigation)return 'GUARD INVESTIGATING · BREAK SIGHT';
      return current.intel?'OPTIONAL INTEL SECURED':current.powerRouted?'SERVICE LIGHTS OFF · CAMERA ISOLATED':'';
    }
    function interact() {
      if(state().mode!=='play')return false;
      const d=nearby();if(!d)return false;
      const s=state();
      if(d.id==='power') {
        current.powerRouted=!current.powerRouted;
        if(current.powerRouted)current.camera.alert=0;
        api.log('power_rerouted','service_grid',current.powerRouted?'isolated':'restored');
        note(current.powerRouted?'SERVICE GRID ISOLATED: Camera offline. Lights dimmed; emergency guidance remains active.':'SERVICE GRID RESTORED: Camera and service lights online.');
      } else if(d.id==='overload') {
        if(current.overloaded){api.message?.('OVERLOAD SPENT: The breaker is fused.');return true;}
        current.overloaded=true;
        let affected=0;
        for(const bot of s.enemies)if(bot.hp>0&&distance(bot,data.overload)<4&&visible(data.overload,bot)) {bot.stagger=3;bot.attackWindup=0;affected++;}
        api.log('grid_overloaded','overload_terminal',String(affected));
        note('GRID OVERLOAD: Nearby units staggered for three seconds. Breaker fused.');
      } else if(d.id==='intel') {
        if(current.intel){api.message?.('INTEL ALREADY RECOVERED. Extract to preserve it.');return true;}
        current.intel=true;
        api.log('intel_recovered','evacuation_manifest');
        if(!s.panelDisabled)api.triggerAlarm();
        note('MANIFEST RECOVERED: Personnel were evacuated through a southwest backup-power bay. Extract to preserve the intel.');
      } else if(d.id==='door') {
        if(current.doorOpen) {
          const occupied=[s.player,...s.enemies.filter(b=>b.hp>0)].some(b=>b.x+.2>8&&b.x-.2<9&&b.y+.2>6&&b.y-.2<7);
          if(occupied){api.log('bulkhead_obstructed','maintenance_bulkhead');api.message?.('BULKHEAD OBSTRUCTED: Move clear before closing.');return true;}
        }
        current.doorOpen=!current.doorOpen;
        api.log('bulkhead_toggled','maintenance_bulkhead',current.doorOpen?'open':'closed');
        api.message?.(current.doorOpen?'BULKHEAD OPEN.':'BULKHEAD CLOSED: Use switch here to reopen.');
      } else if(d.id==='cache') {
        current.secret=true;s.player.hp=Math.min(100,s.player.hp+25);
        api.log('secret_found','maintenance_cache');
        note('HIDDEN CACHE: Recovered medical supplies (+25 health, maximum 100). Log: "We left the line live so the exit signs would hold."');
      }
      return true;
    }
    function shoot(dx,dy,wallDist,nearestBotDepth=Infinity) {
      if(!isControl())return false;
      const p=state().player,targets=[];
      if(!current.camera.disabled)targets.push({...data.camera,type:'camera'});
      for(const lamp of current.lamps)if(!lamp.broken)targets.push({...lamp,type:'lamp',source:lamp});
      let hit=null,nearest=Math.min(wallDist,nearestBotDepth);
      for(const t of targets) {
        const x=t.x-p.x,y=t.y-p.y,z=x*dx+y*dy,offset=Math.abs(x*dy-y*dx);
        if(z>.12&&z<nearest&&offset<.18){hit=t;nearest=z;}
      }
      if(!hit)return false;
      api.impact?.(hit.x,hit.y,'spark');
      if(hit.type==='camera'){current.camera.disabled=true;current.camera.alert=0;api.log('camera_destroyed','camera_1');api.message?.('CAMERA DESTROYED: Gunfire can still draw the guard.');}
      else {hit.source.broken=true;api.log('light_destroyed','service_lamp');api.message?.('SERVICE LIGHT DESTROYED: Ambient emergency light remains.');}
      return true;
    }
    function isWall(x,y) {return isControl()&&!current.doorOpen&&Math.floor(x)===data.door.x&&Math.floor(y)===data.door.y;}
    function light(x,y) {
      if(!isControl())return 1;
      let multiplier=current.powerRouted?.5:1;
      if(current.lamps[0]?.broken&&Math.abs(y-5.5)<1.5&&x<5)multiplier*=.65;
      return multiplier;
    }
    function objects() {
      if(!isControl())return [];
      const s=state(),cameraOff=current.camera.disabled||current.powerRouted||s.panelDisabled;
      const result=[
        {...data.camera,kind:'prop',asset:cameraOff?'cameraOff':'camera',scale:.45},
        {...data.camera,kind:'sign',label:cameraOff?'CAMERA OFF':current.camera.alert>0?'CAMERA TRACKING':'SECURITY CAMERA',color:cameraOff?'#6c786e':'#e29a5a'},
        {...data.power,kind:'prop',asset:'console',scale:.6},
        {...data.power,kind:'sign',label:current.powerRouted?'POWER ISOLATED':'SERVICE POWER',color:'#65c8c1'},
        {...data.overload,kind:'prop',asset:'terminal',scale:.6},
        {...data.overload,kind:'sign',label:current.overloaded?'BREAKER FUSED':'OVERLOAD GRID',color:'#dcad60'},
        {...data.doorSwitch,kind:'sign',label:current.doorOpen?'BULKHEAD OPEN':'BULKHEAD CLOSED',color:'#b7bb8e'},
        {...data.intel,kind:'sign',label:current.intel?'INTEL SECURED':'OPTIONAL INTEL',color:'#75ccc2'},
        ...(!current.intel?[{...data.intel,kind:'prop',asset:'intel',scale:.36}]:[]),
        {...data.lamp,kind:'prop',asset:current.lamps[0].broken?'lampBroken':'lamp',scale:.8},
        {x:4.8,y:8.7,kind:'prop',asset:'damagedRack',scale:.85}
      ];
      if(!current.secret)result.push({...data.cache,kind:'prop',asset:'crate',scale:.55});
      return result;
    }
    function score(s) {
      const accuracy=(s.shots??0)>0?Math.round((s.hits??0)/(s.shots??1)*100):100;
      const stealth=s.mission.id==='control-room'?!s.alarmTriggered:s.player.hp===100;
      const points=(stealth?2:0)+(s.time<120?1:0)+(accuracy>=60?1:0)+(current.intel?1:0)+(current.secret?1:0);
      return {grade:points>=5?'S':points>=4?'A':points>=2?'B':'C',accuracy,stealth};
    }
    function finish(won) {
      if(current.completed)return;
      current.completed=true;
      current.rank=won?score(state()):null;
      if(won)campaignJournal=[...new Set([...campaignJournal,...journal])];
      if(won&&isControl()) {
        Object.assign(campaign,{securityDisabled:state().panelDisabled&&!state().alarmTriggered,alarmRaised:state().alarmTriggered,intel:current.intel,secret:current.secret});
      }
    }
    function summary(won) {
      if(!won)return 'Retry to recover optional intel and improve your rank.';
      const rank=current.rank||score(state());
      return `RANK ${rank.grade} · ${rank.stealth?'CLEAN RUN':'COMBAT RUN'} · ${Math.floor(state().time)}s · ACC ${(state().shots??0)>0?rank.accuracy+'%':'--'}`+(isControl()?` · INTEL ${current.intel?'YES':'NO'} · SECRET ${current.secret?'YES':'NO'}`:'');
    }
    return {data,campaign,get current(){return current;},reset,update,noise,interact,shoot,objects,light,isWall,prompt,summary,finish,newCampaign,entries:()=>journal.slice()};
  }
  window.Bunker07Systems={create};
})();
