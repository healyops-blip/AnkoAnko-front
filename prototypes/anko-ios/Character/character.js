import * as THREE from 'three';
import {CompanionMotion} from './motion.mjs';
const root=document.querySelector('#anko-v9');
let renderer;
try{if(!window.WebGLRenderingContext)throw new Error('WebGL not supported');renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,powerPreference:'low-power',preserveDrawingBuffer:false});}
catch(error){root.dataset.character='unavailable';console.warn('Anko 3D unavailable',error);const hint=document.createElement('p');hint.className='character-unavailable';hint.textContent='当前设备未能启动 3D 互动，请重新打开应用。';root.querySelector('.petstage')?.append(hint);}
window.addEventListener('error',event=>{root.dataset.characterError=event.message;});
if(renderer){try{start();}catch(error){root.dataset.characterError=error.message;const hint=document.createElement('p');hint.className='character-unavailable';hint.textContent='3D 互动暂时未能启动，请重新打开应用。';root.querySelector('.petstage')?.append(hint);console.error(error);}}
function start(){
 renderer.setSize(600,600,false);renderer.setPixelRatio(1);renderer.setClearColor(0x000000,0);renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.0;
 const scene=new THREE.Scene();const camera=new THREE.PerspectiveCamera(32,1,.1,50);camera.position.set(0,1.48,6.8);camera.lookAt(0,1.3,0);
 scene.add(new THREE.HemisphereLight(0xe7f5ff,0x45628a,1.8));
 const key=new THREE.DirectionalLight(0xffffff,3);key.position.set(-3,5,5);scene.add(key);
 const rim=new THREE.DirectionalLight(0x83caff,2);rim.position.set(3,3,-2);scene.add(rim);
 const fill=new THREE.DirectionalLight(0xffffff,1.1);fill.position.set(2,1,4);scene.add(fill);
 const blue=new THREE.MeshPhysicalMaterial({color:0x087bdf,roughness:.4,metalness:.02,clearcoat:.4,clearcoatRoughness:.22});
 const blueLight=new THREE.MeshPhysicalMaterial({color:0x309cf0,roughness:.35,clearcoat:.45});
 const white=new THREE.MeshPhysicalMaterial({color:0xe4f7ff,roughness:.43,clearcoat:.35});
 const black=new THREE.MeshPhysicalMaterial({color:0x061b35,roughness:.17,clearcoat:1});
 const highlight=new THREE.MeshBasicMaterial({color:0xffffff});
 const mouthMat=new THREE.MeshStandardMaterial({color:0x192941,roughness:.65});
 const pink=new THREE.MeshStandardMaterial({color:0xf68d9c,roughness:.6});
 const sphere=new THREE.SphereGeometry(1,40,28);
 const rig=new THREE.Group();scene.add(rig);const torso=new THREE.Group();rig.add(torso);
 function ellipsoid(parent,mat,x,y,z,sx,sy,sz){const mesh=new THREE.Mesh(sphere,mat);mesh.position.set(x,y,z);mesh.scale.set(sx,sy,sz);parent.add(mesh);return mesh;}
 ellipsoid(torso,blue,0,.75,0,.44,.55,.32);
 const headPivot=new THREE.Group();headPivot.position.set(0,1.38,0);torso.add(headPivot);
 const head=new THREE.Group();head.position.y=.43;headPivot.add(head);
 ellipsoid(head,blue,0,0,0,.91,.81,.67);
 const ears=[];
 for(const side of [-1,1]){
  const ear=new THREE.Group();ear.position.set(side*.55,.59,-.02);ear.rotation.z=-side*.22;head.add(ear);ear.scale.set(.9,.7,1);
  const shape=new THREE.Shape();shape.moveTo(-.23,-.13);shape.quadraticCurveTo(-.22,.08,-.055,.41);shape.quadraticCurveTo(.01,.49,.08,.39);shape.quadraticCurveTo(.28,.02,.25,-.14);shape.closePath();
  const mesh=new THREE.Mesh(new THREE.ExtrudeGeometry(shape,{depth:.18,bevelEnabled:true,bevelThickness:.065,bevelSize:.055,bevelSegments:5,steps:1,curveSegments:16}),blueLight);mesh.position.z=-.13;ear.add(mesh);ears.push(ear);
 }
 // A curved face patch follows the head ellipsoid; it is real geometry, not a face image.
 const faceShape=new THREE.Shape();faceShape.moveTo(0,.32);faceShape.bezierCurveTo(.16,.31,.22,.59,.46,.49);faceShape.bezierCurveTo(.78,.39,.86,-.03,.72,-.31);faceShape.bezierCurveTo(.52,-.67,-.52,-.67,-.72,-.31);faceShape.bezierCurveTo(-.86,-.03,-.78,.39,-.46,.49);faceShape.bezierCurveTo(-.22,.59,-.16,.31,0,.32);
 const contour=faceShape.getPoints(28),verts=[],indices=[],rings=14,N=contour.length;
 const faceZ=(x,y)=>.67*Math.sqrt(Math.max(.04,1-x*x/(.91*.91)-y*y/(.81*.81)))+.018;
 for(let j=0;j<=rings;j++){const f=j/rings;for(const point of contour){const x=point.x*f,y=(point.y+.08)*f-.08;verts.push(x,y,faceZ(x,y));}}
 for(let j=0;j<rings;j++)for(let i=0;i<N-1;i++){const a=j*N+i,b=a+N;indices.push(a,a+1,b,b,a+1,b+1);}
 const faceGeo=new THREE.BufferGeometry();faceGeo.setAttribute('position',new THREE.Float32BufferAttribute(verts,3));faceGeo.setIndex(indices);faceGeo.computeVertexNormals();white.side=THREE.DoubleSide;head.add(new THREE.Mesh(faceGeo,white));
 const eyes=[];
 for(const side of [-1,1]){const eye=new THREE.Group();const x=side*.30,y=.075;eye.position.set(x,y,faceZ(x,y)+.016);eye.rotation.y=side*.24;head.add(eye);ellipsoid(eye,black,0,0,0,.112,.142,.064);ellipsoid(eye,highlight,-.028,.05,.054,.032,.035,.015);ellipsoid(eye,highlight,.035,-.028,.06,.013,.014,.008);eyes.push(eye);}
 ellipsoid(head,black,0,-.13,faceZ(0,-.13)+.026,.09,.055,.044);
 const mouth=new THREE.Group();mouth.position.set(0,-.28,faceZ(0,-.28)+.014);head.add(mouth);
 const smile=new THREE.Shape();smile.moveTo(-.16,.045);smile.quadraticCurveTo(0,-.025,.16,.045);smile.quadraticCurveTo(.13,-.135,0,-.14);smile.quadraticCurveTo(-.13,-.135,-.16,.045);const smileMesh=new THREE.Mesh(new THREE.ExtrudeGeometry(smile,{depth:.012,bevelEnabled:true,bevelSize:.007,bevelThickness:.007,bevelSegments:3}),mouthMat);mouth.add(smileMesh);const tongue=ellipsoid(mouth,pink,0,-.107,.023,.075,.024,.008);
 const cheeks=[];for(const side of [-1,1])cheeks.push(ellipsoid(head,new THREE.MeshStandardMaterial({color:0x9ddcff,transparent:true,opacity:.28,roughness:1}),side*.48,-.17,faceZ(side*.48,-.17)+.009,.11,.05,.016));
 const bolt=new THREE.Shape();bolt.moveTo(.065,.25);bolt.lineTo(-.16,-.02);bolt.lineTo(-.02,-.02);bolt.lineTo(-.08,-.23);bolt.lineTo(.18,.055);bolt.lineTo(.04,.055);bolt.closePath();
 const lightning=new THREE.Mesh(new THREE.ExtrudeGeometry(bolt,{depth:.018,bevelEnabled:true,bevelSize:.008,bevelThickness:.008,bevelSegments:2}),white);lightning.position.set(0,.77,.32);torso.add(lightning);
 const arms=[],legs=[];
 for(const side of [-1,1]){
  const shoulder=new THREE.Group();shoulder.position.set(side*.37,1.05,0);torso.add(shoulder);shoulder.rotation.z=side*.28;
  ellipsoid(shoulder,blue,side*.07,-.19,0,.14,.28,.15);const elbow=new THREE.Group();elbow.position.set(side*.12,-.35,.015);shoulder.add(elbow);ellipsoid(elbow,blue,0,-.065,.025,.155,.19,.15);arms.push({shoulder,elbow,side});
  const hip=new THREE.Group();hip.position.set(side*.23,.39,0);rig.add(hip);ellipsoid(hip,blue,0,-.10,0,.18,.25,.19);ellipsoid(hip,blue,side*.025,-.26,.11,.23,.16,.30);legs.push({hip,side});
 }
 // Contact shadow is drawn from vector gradients, independent of character artwork.
 const shadowCanvas=document.createElement('canvas');shadowCanvas.width=128;shadowCanvas.height=128;const sc=shadowCanvas.getContext('2d');const g=sc.createRadialGradient(64,64,5,64,64,62);g.addColorStop(0,'rgba(29,73,116,.26)');g.addColorStop(1,'rgba(29,73,116,0)');sc.fillStyle=g;sc.fillRect(0,0,128,128);
 const shadow=new THREE.Mesh(new THREE.PlaneGeometry(1.9,1.2),new THREE.MeshBasicMaterial({map:new THREE.CanvasTexture(shadowCanvas),transparent:true,depthWrite:false}));shadow.rotation.x=-Math.PI/2;shadow.position.y=-.035;scene.add(shadow);
 const mainFrame=document.createElement('canvas');mainFrame.width=600;mainFrame.height=600;const mainContext=mainFrame.getContext('2d');
 const motion=new CompanionMotion();let canvases=[],last=0,drawAt=0,drag=null,ignoreClickUntil=0,frames=0;const reducedQuery=window.matchMedia('(prefers-reduced-motion: reduce)');
 const refresh=()=>{if(drag&&!drag.canvas.isConnected){drag=null;motion.release();}root.querySelectorAll('.sprite:not(:has(canvas))').forEach(span=>{const c=document.createElement('canvas');c.className='anko-avatar';span.append(c);});canvases=[...root.querySelectorAll('canvas.anko-avatar')];};
 new MutationObserver(refresh).observe(root,{childList:true,subtree:true});refresh();root.dataset.character='3d';
 function coords(event,canvas){const r=canvas.getBoundingClientRect();return {x:Math.max(-1,Math.min(1,(event.clientX-r.left)/r.width*2-1)),y:Math.max(-1,Math.min(1,1-(event.clientY-r.top)/r.height*2))};}
 root.addEventListener('pointerdown',event=>{const canvas=event.target.closest('canvas.anko-avatar');if(!canvas||!canvas.closest('.pet-touch,.hero-pet'))return;const p=coords(event,canvas);drag={id:event.pointerId,canvas,startX:event.clientX,startY:event.clientY,moved:false};canvas.setPointerCapture(event.pointerId);motion.start(p.x,p.y);});
 root.addEventListener('pointermove',event=>{const canvas=drag?.canvas||event.target.closest('canvas.anko-avatar');if(!canvas)return;const p=coords(event,canvas);motion.aim(p.x,p.y);if(drag){if(Math.hypot(event.clientX-drag.startX,event.clientY-drag.startY)>7)drag.moved=true;if(drag.moved)motion.drag(p.x,p.y);}});
 function release(event){if(!drag||event.pointerId!==drag.id)return;if(drag.moved)ignoreClickUntil=performance.now()+450;drag=null;motion.release();}
 root.addEventListener('pointerup',release);root.addEventListener('pointercancel',release);root.addEventListener('lostpointercapture',release);
 root.addEventListener('click',event=>{if(performance.now()<ignoreClickUntil&&event.target.closest('.pet-touch,.hero-pet')){event.preventDefault();event.stopImmediatePropagation();}},true);
 root.addEventListener('keydown',event=>{if(event.target.closest('.pet-touch,.hero-pet')&&['ArrowLeft','ArrowRight'].includes(event.key)){event.preventDefault();motion.targetX=Math.max(-.7,Math.min(.7,motion.targetX+(event.key==='ArrowRight'?.25:-.25)));motion.aim(event.key==='ArrowRight'?1:-1,0);}});
 root.addEventListener('anko:pet',()=>motion.pet(.65+Math.random()*.65));
 function apply(p){
  rig.position.set(p.x,p.y,0);rig.rotation.y=p.yaw;torso.rotation.z=p.tilt;torso.scale.y=p.bodyScale;headPivot.rotation.set(p.headX,p.headY,-p.tilt*.5);head.scale.set(1+p.held*.01,1-p.held*.025,1);
  ears.forEach((ear,i)=>{const side=i?1:-1;ear.rotation.z=-side*(.22+p.ear+p.calm*.08);});
  eyes.forEach(eye=>{eye.scale.y=p.eyes;eye.children.forEach((child,i)=>{if(i){child.position.x+=(p.pupilX-child.position.x+(i===1?-.028:.035))*.1;}});});
  mouth.scale.y=.38+p.joy*.75+p.alert*.75;mouth.scale.x=1-p.alert*.45; tongue.visible=p.alert<.4;
  arms.forEach(({shoulder,elbow,side})=>{shoulder.rotation.z=side*(.22+p.joy*.65+p.energy*.35+p.held*.4)+p.gait*p.moving*.18;shoulder.rotation.x=side*p.gait*p.moving*.62+p.calm*.15+(motion.reduced?0:Math.sin(p.time*1.6+side)*.025);elbow.rotation.x=-p.energy*.28;elbow.rotation.z=side*(p.joy*.2+Math.sin(p.time*3.3+side)*p.energy*.18);});
  legs.forEach(({hip,side})=>{hip.rotation.x=side*p.gait*p.moving*.65;hip.position.y=.39+Math.max(0,side*p.gait)*p.moving*.055;});shadow.position.x=p.x;shadow.scale.setScalar(1-p.y*.35);shadow.material.opacity=1-p.y*.6;
 }
 function frame(ms){
  if(document.hidden){last=ms;return;}if(ms-drawAt<32)return;drawAt=ms;const dt=last?Math.min((ms-last)/1000,1/30):1/30;last=ms;
  motion.reduced=root.classList.contains('quiet')||reducedQuery.matches;motion.setMood(root.dataset.mood||'idle');const p=motion.step(dt);apply(p);
  const visible=canvases.filter(canvas=>{const r=canvas.getBoundingClientRect();return r.width&&r.height&&r.bottom>0&&r.top<innerHeight&&!canvas.closest('[hidden]');});if(!visible.length)return;
  renderer.render(scene,camera);mainContext.clearRect(0,0,600,600);mainContext.drawImage(renderer.domElement,0,0);
  for(const canvas of visible){const walker=canvas.closest('.walker');if(walker){const walking=!motion.reduced&&!walker.closest('.with-companion,.urgent');walker.style.transform=walking?`translate(${Math.sin(p.time*.32)*26}px,${Math.sin(p.time*.64)*9}px)`:'none';apply({...p,x:0,y:walking?Math.abs(Math.sin(p.time*4))*.035:0,yaw:walking?Math.cos(p.time*.32)*.4:p.yaw,moving:walking?1:0,gait:Math.sin(p.time*4)});renderer.render(scene,camera);}if(canvas.width!==600){canvas.width=600;canvas.height=600;}const ctx=canvas.getContext('2d');ctx.clearRect(0,0,600,600);ctx.drawImage(walker?renderer.domElement:mainFrame,0,0);}
  frames++;root.dataset.characterFrames=String(frames);
 }
 renderer.setAnimationLoop(frame);
 document.addEventListener('visibilitychange',()=>{if(document.hidden){motion.release();drag=null;}last=0;});
 renderer.domElement.addEventListener('webglcontextlost',event=>{event.preventDefault();root.dataset.character='recovering';});renderer.domElement.addEventListener('webglcontextrestored',()=>{root.dataset.character='3d';});
 window.ankoCharacter={inspect:()=>({renderer:'WebGL',meshes:(()=>{let n=0;scene.traverse(o=>{if(o.isMesh)n++});return n;})(),frames,mood:motion.mood,pose:{...motion.pose},dragging:motion.dragging}),dispose:()=>{renderer.setAnimationLoop(null);renderer.dispose();}};
}
