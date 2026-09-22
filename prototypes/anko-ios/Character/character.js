import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {RoomEnvironment} from 'three/addons/environments/RoomEnvironment.js';
import modelData from './model/anko-refined.glb';
import {CompanionMotion} from './motion.mjs';
const root=document.querySelector('#anko-v9');
let renderer;
try{if(!window.WebGLRenderingContext)throw new Error('WebGL not supported');renderer=new THREE.WebGLRenderer({alpha:true,antialias:true,powerPreference:'low-power',preserveDrawingBuffer:false});}
catch(error){root.dataset.character='unavailable';console.warn('Anko 3D unavailable',error);const hint=document.createElement('p');hint.className='character-unavailable';hint.textContent='当前设备未能启动 3D 互动，请重新打开应用。';root.querySelector('.petstage')?.append(hint);}
window.addEventListener('error',event=>{root.dataset.characterError=event.message;});
if(renderer){start().catch(error=>{root.dataset.characterError=error.message;const hint=document.createElement('p');hint.className='character-unavailable';hint.textContent='3D 互动暂时未能启动，请重新打开应用。';root.querySelector('.petstage')?.append(hint);console.error(error);});}
async function start(){
 renderer.setSize(600,600,false);renderer.setPixelRatio(1);renderer.setClearColor(0x000000,0);renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.0;
 const scene=new THREE.Scene();const camera=new THREE.PerspectiveCamera(32,1,.1,50);camera.position.set(0,1.63,7);camera.lookAt(0,1.5,0);
 scene.add(new THREE.HemisphereLight(0xe7f5ff,0x45628a,.65));
 const key=new THREE.DirectionalLight(0xffffff,2.2);key.position.set(-3,5,5);scene.add(key);
 const rim=new THREE.DirectionalLight(0x83caff,1.8);rim.position.set(3,3,-2);scene.add(rim);
 const fill=new THREE.DirectionalLight(0xffffff,.65);fill.position.set(2,1,4);scene.add(fill);
 const pmrem=new THREE.PMREMGenerator(renderer);const room=new RoomEnvironment();const environment=pmrem.fromScene(room,.04);scene.environment=environment.texture;room.dispose();pmrem.dispose();
 const model=await new GLTFLoader().parseAsync(modelData.buffer,'');scene.add(model.scene);
 const find=name=>{const object=model.scene.getObjectByName(name);if(!object)throw new Error('Missing rig node: '+name);return object;};
 const rig=find('AnkoRig'),torso=find('Torso'),headPivot=find('HeadPivot'),head=find('Head'),mouth=find('Mouth'),tongue=find('Tongue');
 const eyes=['L','R'].map(label=>({eye:find('Eye'+label),lid:find('Lid'+label)}));
 const arms=['L','R'].map((label,i)=>{const shoulder=find('Shoulder'+label),elbow=find('Elbow'+label);return {shoulder,elbow,side:i?1:-1,shoulderRest:shoulder.quaternion.clone(),elbowRest:elbow.quaternion.clone()};});
 const legs=['L','R'].map((label,i)=>{const hip=find('Hip'+label);return {hip,side:i?1:-1,rest:hip.quaternion.clone()};});
 model.scene.traverse(o=>{if(o.isMesh){o.frustumCulled=false;if(o.material){o.material.envMapIntensity=.12;if(o.material.name==='Anko blue'){o.material.specularIntensity=.3;o.material.clearcoat=.08;o.material.roughness=.5;}if(['Deep navy eyes','Blue iris'].includes(o.material.name)){o.material.envMapIntensity=0;o.material.specularIntensity=.25;o.material.clearcoat=.1;}}}});
 const deltaRotation=new THREE.Quaternion();const deltaEuler=new THREE.Euler();
 function rotateJoint(joint,rest,x,y,z){deltaRotation.setFromEuler(deltaEuler.set(x,y,z));joint.quaternion.copy(rest).multiply(deltaRotation);}
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
  rig.position.set(p.x,p.y,0);rig.rotation.y=p.yaw;torso.rotation.z=p.tilt;torso.scale.y=p.bodyScale;headPivot.rotation.set(p.headX,p.headY,-.055-p.tilt*.5);head.scale.set(1+p.held*.01,1-p.held*.025,1);
  eyes.forEach(({eye,lid})=>{const open=Math.max(0,Math.min(1,(p.eyes-.07)/.93));eye.scale.y=Math.max(.06,open);eye.visible=open>.13;lid.visible=open<=.13;});
  mouth.scale.y=.85+p.joy*.24-p.calm*.63;mouth.scale.x=1-p.alert*.3;tongue.visible=p.alert<.4;
  arms.forEach(({shoulder,elbow,side,shoulderRest,elbowRest})=>{
   rotateJoint(shoulder,shoulderRest,side*p.gait*p.moving*.48,0,side*(p.joy*.62+p.energy*.22+p.held*.24));
   rotateJoint(elbow,elbowRest,-p.energy*.22,0,side*(p.joy*.14+Math.sin(p.time*3.3+side)*p.energy*.12));
  });
  legs.forEach(({hip,side,rest})=>rotateJoint(hip,rest,side*p.gait*p.moving*.48,0,0));
  shadow.position.x=p.x;shadow.scale.setScalar(1-p.y*.35);shadow.material.opacity=1-p.y*.6;
 }
 function frame(ms){
  if(document.hidden){last=ms;return;}if(ms-drawAt<32)return;drawAt=ms;const dt=last?Math.min((ms-last)/1000,1/30):1/30;last=ms;
  motion.reduced=root.classList.contains('quiet')||reducedQuery.matches;motion.setMood(root.dataset.mood||'idle');const p=motion.step(dt);if(window.ankoModelReview==='turn'){Object.assign(p,{yaw:.55,headY:-.12,headX:0,joy:.8,eyes:.95,energy:0,gait:.4,moving:.4});}apply(p);
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
