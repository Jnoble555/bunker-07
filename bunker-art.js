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
  function bot(frame,state){return surface(g=>{
    const stride=state==='walk'?(frame%2?3:-3):0, lift=state==='idle'?frame%2:0;
    rect(g,'#14211c',9,61,46,3);
    rect(g,'#384b3b',17,43,11,17+stride);rect(g,'#384b3b',36,43,11,17-stride);
    rect(g,'#192c23',14,58+Math.min(0,stride),15,5);rect(g,'#192c23',35,58-Math.max(0,stride),16,5);
    rect(g,'#25382b',13,22+lift,38,24);rect(g,'#75816a',16,23+lift,32,3);rect(g,'#536a4b',18,27+lift,27,15);
    rect(g,'#8b9375',23,29+lift,17,3);rect(g,'#293e2e',24,35+lift,15,5);
    rect(g,'#233b2a',21,6+lift,23,17);rect(g,'#8a9476',23,6+lift,19,3);rect(g,'#102d29',23,12+lift,19,7);
    rect(g,state==='attack'?'#ff7049':'#89d6ba',25,14+lift,15,2);
    const arm=state==='attack'?7:27+lift;
    rect(g,'#4d6046',8,arm,8,21);rect(g,'#4d6046',48,arm,8,21);rect(g,'#a0a084',9,arm+17,7,5);rect(g,'#a0a084',48,arm+17,7,5);
    rect(g,'#152c23',48,arm+9,10,5);rect(g,'#a8955b',51,arm+9,6,1);
    if(state==='attack'&&frame===1){rect(g,'#f5d077',52,arm+3,9,6);rect(g,'#fff0ae',55,arm+1,3,9);}
  });}
  const bots={idle:[bot(0,'idle'),bot(1,'idle')],walk:[bot(0,'walk'),bot(1,'walk')],attack:[bot(0,'attack'),bot(1,'attack')]};
  const weapon=surface(g=>{
    rect(g,'#202c26',12,91,45,19);rect(g,'#59634a',14,87,28,23);rect(g,'#8b8b68',21,88,8,22);
    rect(g,'#202c26',103,91,45,19);rect(g,'#59634a',118,87,28,23);rect(g,'#8b8b68',131,88,8,22);
    rect(g,'#1a2821',55,49,50,61);rect(g,'#5d6b55',60,38,40,72);rect(g,'#87917a',63,39,4,65);rect(g,'#303f31',93,39,7,71);
    rect(g,'#1b2d23',68,16,24,48);rect(g,'#7b876d',70,18,20,37);rect(g,'#a4aa8a',72,18,3,35);
    rect(g,'#17291e',74,19,12,7);rect(g,'#111f19',76,21,8,4);rect(g,'#d0b875',76,12,8,7);rect(g,'#13271e',78,12,4,5);
    rect(g,'#253c2d',69,65,22,22);for(let y=69;y<87;y+=4)rect(g,'#111f17',71,y,18,2);
    rect(g,'#b4a05c',95,65,3,13);rect(g,'#bad9ad',96,67,1,5);rect(g,'#788367',63,95,30,2);
  },160,110);
  window.Bunker07Art={textures,props,bots,weapon};
})();
