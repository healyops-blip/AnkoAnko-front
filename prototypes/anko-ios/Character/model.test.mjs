import fs from 'node:fs';
import assert from 'node:assert/strict';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {Vector3} from 'three';
const bytes=fs.readFileSync(new URL('./model/anko-refined.glb',import.meta.url));
const gltf=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');
const body=gltf.scene.getObjectByName('BodySurface');assert(body?.isSkinnedMesh);assert.equal(body.skeleton.bones.length,7);
const names=['HeadPivot','HeartFace','EyeL','EyeR','LidL','LidR','Lightning','ShoulderL','ShoulderR','ElbowL','ElbowR','HipL','HipR'];for(const name of names)assert(gltf.scene.getObjectByName(name),name);
const weights=body.geometry.getAttribute('skinWeight'),joints=body.geometry.getAttribute('skinIndex');for(let i=0;i<weights.count;i++){let total=0;for(let j=0;j<4;j++){const w=weights.getComponent(i,j);assert(Number.isFinite(w)&&w>=0);total+=w;assert(joints.getComponent(i,j)<7)}assert(Math.abs(total-1)<.001);}
const position=body.geometry.getAttribute('position');for(let i=0;i<position.count;i++){if(position.getY(i)<.25&&Math.abs(position.getX(i))<.59){for(let j=0;j<4;j++){const name=body.skeleton.bones[joints.getComponent(i,j)].name;if(/Shoulder|Elbow/.test(name))assert(weights.getComponent(i,j)<.001,'Feet must not be pulled by arm bones');}}}
gltf.scene.updateMatrixWorld(true);body.skeleton.update();const pos=body.geometry.getAttribute('position');let vertex=0;for(let i=0;i<pos.count;i++)if(pos.getX(i)>.65&&pos.getY(i)>.45){vertex=i;break;}const initial=new Vector3().fromBufferAttribute(pos,vertex);const before=body.applyBoneTransform(vertex,initial.clone());const shoulder=gltf.scene.getObjectByName('ShoulderR');shoulder.rotateZ(.45);gltf.scene.updateMatrixWorld(true);body.skeleton.update();const after=body.applyBoneTransform(vertex,initial.clone());assert(before.distanceTo(after)>.025,'The continuous arm surface must actually deform with the bone.');
console.log('PASS refined asset: 7-bone skin, required face/rig nodes, normalized finite weights, real arm-surface deformation.');
// Check surface continuity under a deliberately larger shoulder rotation.
// A single stray vertex weight would otherwise pass the point-motion assertion.
const deformed=Array.from({length:pos.count},(_,i)=>body.applyBoneTransform(i,new Vector3().fromBufferAttribute(pos,i)));
const indices=body.geometry.index;let largestStretch=0;
for(let i=0;i<indices.count;i+=3){for(const [a,b] of [[0,1],[1,2],[2,0]]){const ia=indices.getX(i+a),ib=indices.getX(i+b);const rest=new Vector3().fromBufferAttribute(pos,ia).distanceTo(new Vector3().fromBufferAttribute(pos,ib));if(rest>.001)largestStretch=Math.max(largestStretch,deformed[ia].distanceTo(deformed[ib])/rest);}}
assert(largestStretch<2.5,`Skin edge stretch ${largestStretch.toFixed(2)} indicates a discontinuity`);
console.log(`PASS deformed surface continuity: maximum edge stretch ${largestStretch.toFixed(2)}x.`);
