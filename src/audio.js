/* Original synthesized mechanical effects. Audio failure never blocks gameplay. */
(function () {
  'use strict';
  var context=null, master=null, unavailable=false, masterVolume=1, muted=false;
  var active=new Set();
  function clamp(value,min,max,fallback){return typeof value==='number'&&isFinite(value)?Math.max(min,Math.min(max,value)):fallback;}
  function syncMaster(){
    if(!context||!master)return;
    try {master.gain.setValueAtTime(muted?0:masterVolume,context.currentTime);} catch (_) {}
  }
  function getContext(){
    if(context||unavailable)return context;
    try {
      var AudioClass=window.AudioContext||window.webkitAudioContext;
      if(!AudioClass){unavailable=true;return null;}
      context=new AudioClass();master=context.createGain();master.connect(context.destination);syncMaster();
      return context;
    } catch (_) {unavailable=true;context=null;master=null;return null;}
  }
  function release(bus){
    if(bus.released)return;bus.released=true;active.delete(bus);
    for(var node of bus.nodes)try{node.disconnect();}catch(_){}
    try {bus.input.disconnect();if(bus.panner)bus.panner.disconnect();} catch (_) {}
  }
  function play(makeSound,pan,distance){
    if(muted||masterVolume===0)return;
    var bus;
    try {
      var audio=getContext();if(!audio)return;
      if(audio.state==='suspended'&&typeof audio.resume==='function'){
        var pending=audio.resume();if(pending&&typeof pending.catch==='function')pending.catch(function(){});
      }
      var gain=audio.createGain();
      gain.gain.setValueAtTime(1/(1+clamp(distance,0,100,0)*.3),audio.currentTime);
      bus={input:gain,panner:null,voices:0,released:false,oscillators:[],nodes:[]};
      if(typeof audio.createStereoPanner==='function'){
        bus.panner=audio.createStereoPanner();bus.panner.pan.setValueAtTime(clamp(pan,-1,1,0),audio.currentTime);
        gain.connect(bus.panner);bus.panner.connect(master);
      } else gain.connect(master);
      active.add(bus);makeSound(audio,bus);
      if(bus.voices===0)release(bus);
    } catch (_) {
      if(bus){for(var oscillator of bus.oscillators)try{oscillator.stop();}catch(__){}release(bus);}
    }
  }
  function tone(audio,bus,shape,startFrequency,endFrequency,duration,volume,delay){
    var oscillator=audio.createOscillator(),gain=audio.createGain();
    var start=audio.currentTime+(delay||0),end=start+duration;
    oscillator.type=shape;
    oscillator.frequency.setValueAtTime(startFrequency,start);
    oscillator.frequency.exponentialRampToValueAtTime(endFrequency,end);
    gain.gain.setValueAtTime(.0001,start);
    gain.gain.exponentialRampToValueAtTime(volume,start+.008);
    gain.gain.exponentialRampToValueAtTime(.0001,end);
    oscillator.connect(gain);gain.connect(bus.input);bus.voices++;bus.oscillators.push(oscillator);bus.nodes.push(oscillator,gain);
    oscillator.onended=function(){
      try {oscillator.disconnect();gain.disconnect();}catch(_){}
      bus.voices--;if(bus.voices===0)release(bus);
    };
    oscillator.start(start);oscillator.stop(end+.01);
  }
  var sounds={
    fire:function(a,b){tone(a,b,'sawtooth',720,155,.12,.16);tone(a,b,'triangle',130,42,.08,.16);},
    hit:function(a,b){tone(a,b,'triangle',190,48,.18,.28);},
    reload:function(a,b){tone(a,b,'square',880,520,.045,.08);tone(a,b,'square',620,310,.07,.07,.09);},
    detect:function(a,b){tone(a,b,'square',510,760,.08,.07);tone(a,b,'square',760,1030,.09,.06,.12);},
    attack:function(a,b){tone(a,b,'sawtooth',90,280,.22,.08);tone(a,b,'square',440,640,.07,.05,.18);},
    impact:function(a,b){tone(a,b,'triangle',1100,120,.06,.13);tone(a,b,'square',320,76,.045,.04,.015);},
    damage:function(a,b){tone(a,b,'triangle',150,32,.23,.24);tone(a,b,'sawtooth',80,38,.13,.1);},
    use:function(a,b){tone(a,b,'sine',620,900,.07,.12);tone(a,b,'sine',930,1230,.09,.09,.09);},
    alarm:function(a,b){tone(a,b,'square',330,610,.2,.07);tone(a,b,'square',610,330,.2,.07,.2);},
    step:function(a,b){tone(a,b,'triangle',85,45,.055,.06);},
    servo:function(a,b){tone(a,b,'sawtooth',140,190,.085,.035);}
  };
  var api={
    setMasterVolume:function(value){masterVolume=clamp(value,0,1,masterVolume);syncMaster();return masterVolume;},
    getMasterVolume:function(){return masterVolume;},
    setMuted:function(value){muted=Boolean(value);syncMaster();return muted;},
    getMuted:function(){return muted;},
    positional:function(kind,pan,distance){if(sounds[kind])play(sounds[kind],pan,distance);},
    stopAll:function(){
      for(var bus of Array.from(active)){
        for(var oscillator of bus.oscillators)try{oscillator.stop();}catch(_){}
        release(bus);
      }
    }
  };
  Object.keys(sounds).forEach(function(kind){api[kind]=function(pan,distance){play(sounds[kind],pan,distance);};});
  window.Bunker07Audio=api;
})();
