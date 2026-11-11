/* Original procedural pixel art for Bunker 07. No downloaded assets. */
(() => {
  'use strict';
  function surface(draw,w=64,h=64) {
    const c=document.createElement('canvas'); c.width=w; c.height=h;
    const g=c.getContext('2d'); g.imageSmoothingEnabled=false; draw(g); return c;
  }
  let seed=703;
  function random(){ seed=(Math.imul(seed,1664525)+1013904223)>>>0; return seed/4294967296; }
  function rect(g,color,x,y,w,h){g.fillStyle=color;g.fillRect(x,y,w,h);}
  function bolts(g){for(const x of [4,59])for(const y of [5,58]){rect(g,'#182020',x,y,3,3);rect(g,'#8b9181',x,y,2,1);}}
  const textures={};
  textures.concrete=surface(g=>{
    rect(g,'#62665a',0,0,64,64);
    for(let i=0;i<1600;i++){const v=Math.floor(66+random()*55);rect(g,`rgba(${v},${v+3},${v-6},.28)`,random()*64|0,random()*64|0,1+random()*3|0,1);}
    rect(g,'#353e37',0,0,64,2);rect(g,'#808173',0,2,64,1);rect(g,'#374039',0,0,2,64);
    rect(g,'#353d34',0,46,64,2);rect(g,'#9a8749',0,48,64,5);rect(g,'#222d29',0,53,64,11);
    for(let x=0;x<64;x+=16){rect(g,'#444d42',x,55,11,2);}
    for(const x of [8,44]){rect(g,'#444b40',x,6,1,19);rect(g,'#4a5044',x+1,24,1,6);}
    bolts(g);
  });
  textures.steel=surface(g=>{
    rect(g,'#374540',0,0,64,64);
    for(let y=0;y<64;y+=8){rect(g,'#46524a',2,y,60,1);rect(g,'#27352f',2,y+1,60,1);}
    rect(g,'#182822',0,0,3,64);rect(g,'#667063',3,0,1,64);rect(g,'#1a2924',61,0,3,64);
    rect(g,'#a48b4c',0,45,64,9);
    for(let x=-8;x<64;x+=16){g.fillStyle='#30382b';g.beginPath();g.moveTo(x,54);g.lineTo(x+9,45);g.lineTo(x+15,45);g.lineTo(x+6,54);g.fill();}
    bolts(g);
  });
  textures.panel=surface(g=>{
    rect(g,'#414b40',0,0,64,64);rect(g,'#202d28',4,5,56,40);rect(g,'#172622',6,7,52,36);
    for(let i=0;i<4;i++){rect(g,'#84917c',10,11+i*7,35,2);rect(g,i%2?'#6dbaa5':'#b1a05a',49,10+i*7,4,3);}
    rect(g,'#94947b',8,51,31,5);rect(g,'#252e26',10,53,18,1);bolts(g);
  });
  textures.floor=surface(g=>{
    rect(g,'#44473c',0,0,64,64);
    for(let i=0;i<900;i++)rect(g,random()>.5?'#4b4d41':'#3c4137',random()*64|0,random()*64|0,2,1);
    rect(g,'#222b26',0,0,64,2);rect(g,'#222b26',0,0,2,64);rect(g,'#656354',2,2,62,1);
    for(let y=8;y<60;y+=12)for(let x=7;x<60;x+=12){rect(g,'#55594c',x,y,5,1);rect(g,'#272f29',x+1,y+1,5,1);}
  });
  textures.ceiling=surface(g=>{
    rect(g,'#303b34',0,0,64,64);rect(g,'#192820',0,0,64,5);rect(g,'#192820',0,0,5,64);
    for(let y=12;y<60;y+=5){rect(g,'#1e2c25',11,y,43,2);rect(g,'#485045',11,y+2,43,1);}
    bolts(g);
  });
  const props={};
  props.console=surface(g=>{
    rect(g,'#15231e',4,59,56,5);rect(g,'#424c3e',7,32,50,28);rect(g,'#626a53',7,32,50,3);
    rect(g,'#26392e',12,8,40,27);rect(g,'#78806a',12,8,40,2);rect(g,'#0b2422',15,11,34,20);
    for(let i=0;i<5;i++){rect(g,'#66be9e',18,14+i*3,8+(i*7)%21,1);}
    rect(g,'#6cb19b',38,14,7,10);rect(g,'#203f32',40,16,3,6);
    for(let y=39;y<48;y+=4)for(let x=13;x<43;x+=5)rect(g,'#adb09a',x,y,3,2);
    rect(g,'#d5a854',47,39,4,4);rect(g,'#111f19',12,51,39,6);rect(g,'#777c64',12,51,39,1);
  });
  props.rack=surface(g=>{
    rect(g,'#15221b',9,2,46,62);rect(g,'#61694f',10,2,43,2);rect(g,'#48513f',10,4,3,57);rect(g,'#303d2e',51,4,3,57);
    for(let y=7;y<59;y+=10){rect(g,'#414d3b',15,y,34,8);rect(g,'#839079',17,y+1,17,1);for(let x=18;x<37;x+=3)rect(g,'#17281c',x,y+4,1,3);rect(g,'#86c69d',43,y+2,2,2);}
  });
  props.barrel=surface(g=>{
    rect(g,'#17261d',14,59,36,5);rect(g,'#58604a',14,18,36,43);rect(g,'#7b7b59',16,18,6,41);rect(g,'#313f2d',45,20,5,39);
    for(const y of [19,34,54]){rect(g,'#202e22',13,y,38,4);rect(g,'#7f8063',14,y,35,1);}
    rect(g,'#979060',24,39,15,10);rect(g,'#343c26',29,42,5,5);rect(g,'#273724',17,14,30,5);rect(g,'#737858',19,14,25,2);
  });
  props.lamp=surface(g=>{
    rect(g,'#243429',27,20,10,44);rect(g,'#72775b',28,20,2,44);rect(g,'#29392c',18,8,28,16);
    rect(g,'#a68b4b',20,10,24,12);rect(g,'#f3cf79',23,12,18,8);rect(g,'#fff0b6',25,13,14,3);
    rect(g,'#1c2b20',19,7,26,3);rect(g,'#1c2b20',19,22,26,3);
  });
  // All additions are original pixel drawings, using the same 64px floor anchor.
  props.lampBroken=surface(g=>{
    rect(g,'#243429',27,20,10,44);rect(g,'#72775b',28,20,2,44);
    rect(g,'#1c2b20',18,8,28,17);rect(g,'#514b36',21,11,21,10);
    rect(g,'#0c1713',24,11,5,9);rect(g,'#111b16',30,15,12,6);
    rect(g,'#8b7445',37,23,4,3);rect(g,'#716f54',22,59,8,2);
  });
  function camera(active){return surface(g=>{
    rect(g,'#263b2c',29,3,6,61);rect(g,'#78836b',30,3,2,61);
    rect(g,'#1d2e25',10,10,44,18);rect(g,'#7e8770',12,10,40,3);
    rect(g,'#4d6250',12,13,37,12);rect(g,'#162b25',17,17,18,7);
    rect(g,active?'#cf754b':'#3b4b40',20,18,10,4);rect(g,'#10271f',22,18,6,4);
    rect(g,active?'#edb667':'#64735b',43,16,3,3);
    rect(g,'#172c21',23,28,17,5);rect(g,'#596c50',24,28,3,4);
    if(!active){rect(g,'#0d1b17',12,22,12,4);rect(g,'#927344',25,25,7,2);}
  });}
  props.camera=camera(true);props.cameraOff=camera(false);
  props.terminal=surface(g=>{
    rect(g,'#17281f',14,61,36,3);rect(g,'#394c38',22,32,20,30);rect(g,'#7b8569',22,32,3,30);
    rect(g,'#6b775d',9,7,46,29);rect(g,'#122c28',12,10,40,21);rect(g,'#4a6751',12,31,40,3);
    for(let y=14;y<28;y+=4)rect(g,'#74c6aa',17,y,y%3?24:16,1);
    rect(g,'#a4ab83',16,38,32,9);for(let x=19;x<45;x+=5)rect(g,'#233d2b',x,40,3,2);
    rect(g,'#d4a752',43,50,4,4);
  });
  props.intel=surface(g=>{
    rect(g,'#20392d',20,53,25,11);rect(g,'#a3aa80',21,47,23,13);
    rect(g,'#e3d5a0',24,40,16,17);rect(g,'#455d44',27,44,10,2);
    for(let y=49;y<55;y+=3)rect(g,'#728165',27,y,8,1);
    rect(g,'#77d5bc',22,59,21,2);rect(g,'#f0d68a',34,41,5,3);
  });
  props.crate=surface(g=>{
    rect(g,'#15271e',9,59,47,5);rect(g,'#526046',10,30,44,31);rect(g,'#879073',10,30,44,3);
    rect(g,'#2b4130',10,35,44,3);rect(g,'#2b4130',10,52,44,4);rect(g,'#96a07a',14,34,4,26);
    rect(g,'#243e2b',43,34,5,26);rect(g,'#b7ab70',23,40,15,8);rect(g,'#38472c',27,43,7,2);
    rect(g,'#6d7859',14,24,36,6);rect(g,'#162b1e',16,24,32,2);
  });
  props.damagedRack=surface(g=>{
    g.drawImage(props.rack,0,0);rect(g,'#13241c',15,19,34,13);rect(g,'#99835a',17,31,16,2);
    rect(g,'#9d5d34',43,24,3,9);rect(g,'#e5aa55',45,29,2,2);rect(g,'#172b20',18,33,3,24);
    rect(g,'#696b4d',19,54,7,2);rect(g,'#223523',42,47,8,12);
  });
  props.door=surface(g=>{
    rect(g,'#1a2c22',4,0,56,64);rect(g,'#7b8469',6,0,4,64);rect(g,'#374b38',10,0,44,64);
    rect(g,'#15281f',29,0,4,64);rect(g,'#728266',33,0,2,64);
    for(let y=5;y<61;y+=9)rect(g,'#4c6048',11,y,17,2);
    rect(g,'#c3a35c',9,40,46,7);for(let x=11;x<54;x+=10)rect(g,'#273a25',x,42,4,4);
    rect(g,'#173e31',46,26,6,9);rect(g,'#8dd1a6',48,28,2,4);
  });
  props.brokenLamp=props.lampBroken;
  props.cache=props.crate;
  function bot(frame,state){return surface(g=>{
    const stride=state==='walk'?(frame%2?3:-3):0, lift=state==='stagger'?3:state==='idle'?frame%2:0;
    rect(g,'#14211c',9,61,46,3);
    rect(g,'#384b3b',17,43,11,17+stride);rect(g,'#384b3b',36,43,11,17-stride);
    rect(g,'#192c23',14,58+Math.min(0,stride),15,5);rect(g,'#192c23',35,58-Math.max(0,stride),16,5);
    rect(g,'#25382b',13,22+lift,38,24);rect(g,'#75816a',16,23+lift,32,3);rect(g,'#536a4b',18,27+lift,27,15);
    rect(g,'#8b9375',23,29+lift,17,3);rect(g,'#293e2e',24,35+lift,15,5);
    rect(g,'#233b2a',21,6+lift,23,17);rect(g,'#8a9476',23,6+lift,19,3);rect(g,'#102d29',23,12+lift,19,7);
    rect(g,state==='attack'?'#ff7049':state==='stagger'?'#efcf84':'#89d6ba',25,14+lift,15,2);
    const arm=state==='attack'?7:27+lift;
    rect(g,'#4d6046',8,arm,8,21);rect(g,'#4d6046',48,arm,8,21);rect(g,'#a0a084',9,arm+17,7,5);rect(g,'#a0a084',48,arm+17,7,5);
    rect(g,'#152c23',48,arm+9,10,5);rect(g,'#a8955b',51,arm+9,6,1);
    if(state==='attack'&&frame===1){rect(g,'#f5d077',52,arm+3,9,6);rect(g,'#fff0ae',55,arm+1,3,9);}
  });}
  const bots={idle:[bot(0,'idle'),bot(1,'idle')],walk:[bot(0,'walk'),bot(1,'walk')],attack:[bot(0,'attack'),bot(1,'attack')]};
  bots.stagger=[bot(0,'stagger'),bot(1,'stagger')];
  function roleBot(role,frame,state){return surface(g=>{
    const attack=state==='attack',stagger=state==='stagger',step=state==='walk'?(frame%2?3:-3):0;
    const bob=stagger?3:state==='idle'?frame%2:0;
    if(role==='armored'){
      rect(g,'#14231c',5,60,54,4);rect(g,'#2a3d30',11,41,17,20+step);rect(g,'#2a3d30',36,41,17,20-step);
      rect(g,'#728168',10,46,17,6);rect(g,'#728168',37,46,17,6);
      rect(g,'#1e3227',5,20+bob,54,25);rect(g,'#7d876d',8,21+bob,48,4);rect(g,'#4c6249',11,26+bob,42,15);
      rect(g,'#a99b62',14,28+bob,35,4);rect(g,'#283e2c',14,34+bob,35,5);
      rect(g,'#2e4834',22,5+bob,22,17);rect(g,'#a1aa83',24,5+bob,18,4);
      rect(g,'#11281f',24,12+bob,18,6);rect(g,attack?'#ff8c51':stagger?'#f4d383':'#d9a36b',26,14+bob,14,2);
      const arm=attack?10:25+bob;rect(g,'#465e45',2,arm,10,25);rect(g,'#465e45',52,arm,10,25);
      rect(g,'#98a184',3,arm+19,8,5);rect(g,'#98a184',53,arm+19,8,5);
      rect(g,'#142b20',51,arm+9,12,8);rect(g,'#beac6a',52,arm+10,10,2);
      if(attack&&frame)rect(g,'#ffe39a',55,arm+2,6,8);
    }else if(role==='scout'){
      rect(g,'#102c25',15,62,37,2);rect(g,'#3c6152',24,42,6,18+step);rect(g,'#3c6152',37,42,6,18-step);
      rect(g,'#97b4a0',22,58+Math.min(step,0),9,4);rect(g,'#97b4a0',37,58-Math.max(step,0),9,4);
      rect(g,'#1c3c32',19,23+bob,28,22);rect(g,'#86a08b',20,24+bob,26,3);rect(g,'#4c7964',25,29+bob,17,11);
      rect(g,'#76d2b2',28,32+bob,11,2);rect(g,'#1c3d33',24,8+bob,18,15);rect(g,'#7b9e87',25,8+bob,16,3);
      rect(g,attack?'#ff8b58':stagger?'#f2da96':'#99f2d5',27,15+bob,13,3);rect(g,'#416851',30,2+bob,2,6);
      const arm=attack?13:28+bob;rect(g,'#375c48',14,arm,6,18);rect(g,'#375c48',47,arm,6,18);
      rect(g,'#9fb199',15,arm+14,5,4);rect(g,'#9fb199',47,arm+14,5,4);
      if(attack&&frame)rect(g,'#fff0b8',47,arm-3,5,8);
    }else{
      rect(g,'#12291e',8,59,49,5);rect(g,'#4d6346',15,51,35,10);rect(g,'#88936c',18,51,29,3);
      rect(g,'#233c29',26,34,14,19);rect(g,'#617955',28,34,3,17);
      rect(g,'#253c2d',9,17+bob,47,21);rect(g,'#8a9371',11,18+bob,42,4);rect(g,'#596e50',11,23+bob,42,13);
      rect(g,'#162e24',21,25+bob,21,9);rect(g,'#899b7a',23,25+bob,17,2);rect(g,'#0a2119',27,28+bob,10,7);
      rect(g,attack?'#f59a5e':stagger?'#f2ce7f':'#d99455',13,25+bob,4,4);
      rect(g,'#aaa278',45,25+bob,6,6);if(attack&&frame){rect(g,'#ffd980',25,13+bob,14,10);rect(g,'#fff1b7',29,9+bob,6,14);}
    }
    if(stagger){rect(g,'#ffdc8b',8+frame*39,15,4,2);rect(g,'#ffe8b5',13+frame*29,10,2,5);}
  });}
  const roles={standard:bots};
  for(const role of ['armored','scout','turret']){
    roles[role]={};for(const state of ['idle','walk','attack','stagger'])roles[role][state]=[roleBot(role,0,state),roleBot(role,1,state)];
  }
  const effects={
    spark:surface(g=>{for(const [x,y,w,h,c] of [[30,18,4,27,'#fff1b0'],[18,30,29,4,'#ffd47b'],[23,22,4,4,'#f4a74f'],[40,40,4,4,'#f4a74f'],[39,21,3,5,'#efbf6a'],[20,40,3,4,'#efbf6a']])rect(g,c,x,y,w,h);}),
    smoke:surface(g=>{for(const [x,y,w,h] of [[21,20,20,18],[14,31,33,15],[25,13,10,11],[19,43,27,8]])rect(g,'#7c816b88',x,y,w,h);})
  };
  const weapon=surface(g=>{
    rect(g,'#202c26',12,91,45,19);rect(g,'#59634a',14,87,28,23);rect(g,'#8b8b68',21,88,8,22);
    rect(g,'#202c26',103,91,45,19);rect(g,'#59634a',118,87,28,23);rect(g,'#8b8b68',131,88,8,22);
    rect(g,'#1a2821',55,49,50,61);rect(g,'#5d6b55',60,38,40,72);rect(g,'#87917a',63,39,4,65);rect(g,'#303f31',93,39,7,71);
    rect(g,'#1b2d23',68,16,24,48);rect(g,'#7b876d',70,18,20,37);rect(g,'#a4aa8a',72,18,3,35);
    rect(g,'#17291e',74,19,12,7);rect(g,'#111f19',76,21,8,4);rect(g,'#d0b875',76,12,8,7);rect(g,'#13271e',78,12,4,5);
    rect(g,'#253c2d',69,65,22,22);for(let y=69;y<87;y+=4)rect(g,'#111f17',71,y,18,2);
    rect(g,'#b4a05c',95,65,3,13);rect(g,'#bad9ad',96,67,1,5);rect(g,'#788367',63,95,30,2);
  },160,110);
  window.Bunker07Art={textures,props,bots,roles,effects,weapon};
})();
