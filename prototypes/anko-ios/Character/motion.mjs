const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export class Spring {
 constructor(value=0){this.value=value;this.velocity=0;}
 step(target,dt,stiffness=95,damping=18){this.velocity+=(stiffness*(target-this.value)-damping*this.velocity)*dt;this.value+=this.velocity*dt;return this.value;}
}
// Each pose is solved from continuous input, velocity and springs, not animation clips.
export class CompanionMotion {
 constructor(random=Math.random){this.random=random;this.time=0;this.x=new Spring();this.y=new Spring();this.yaw=new Spring();this.headX=new Spring();this.headY=new Spring();this.ears=new Spring();this.joy=new Spring();this.calm=new Spring();this.attention=new Spring();this.targetX=0;this.look={x:0,y:0};this.dragging=false;this.touching=false;this.mood='idle';this.phase=0;this.blinkAt=1+random()*3;this.blinkStart=-10;this.lookAt=2;this.lastInput=-10;this.energy=0;this.reduced=false;this.pose={};}
 setMood(mood){if(mood!==this.mood&&mood==='happy')this.pet(.65);this.mood=mood;}
 aim(x,y){this.look={x:clamp(x,-1,1),y:clamp(y,-1,1)};this.lastInput=this.time;}
 start(x,y){this.touching=true;this.aim(x,y);}
 drag(x,y){this.dragging=true;this.targetX=clamp(x*.9,-.7,.7);this.aim(x,y);this.energy=Math.min(1,this.energy+.04);}
 release(){this.touching=false;this.dragging=false;}
 pet(strength=1){this.energy=Math.min(1.4,this.energy+strength*.7);this.y.velocity=clamp(this.y.velocity+strength*1.5,-3,3);this.ears.velocity+=(this.random()-.5)*8;this.blinkStart=this.time;}
 step(dt){
 dt=clamp(dt,0,1/30);this.time+=dt;const t=this.time,r=this.reduced;
 if(t>this.lookAt&&!this.touching&&t-this.lastInput>2){this.look={x:(this.random()-.5)*.7,y:(this.random()-.5)*.35};this.lookAt=t+2.5+this.random()*4;}
 if(t>this.blinkAt){this.blinkStart=t;this.blinkAt=t+2+this.random()*4;}
 const blinking=Math.max(0,1-Math.abs((t-this.blinkStart)/.16-1));
 this.energy*=Math.exp(-dt*1.45);
 const joy=this.joy.step(this.mood==='happy'?.85:0,dt,32,10),calm=this.calm.step(this.mood==='sleepy'?1:0,dt,28,10),alert=this.attention.step(this.mood==='alert'?1:0,dt,36,11);
 const x=this.x.step(this.targetX,dt,35,10),speed=clamp(this.x.velocity,-2.3,2.3);
 this.phase+=Math.abs(speed)*dt*11;
 const moving=clamp(Math.abs(speed)*1.5,0,1),gait=Math.sin(this.phase),bounce=this.y.step(0,dt,100,13);
 const breath=r?0:Math.sin(t*2.1)*.014+Math.sin(t*.73)*.004;
 this.pose={time:t,x:r?this.targetX:x,y:r?0:clamp(bounce,-.03,.23)+Math.abs(gait)*moving*.04,bodyScale:1+breath,
 yaw:this.yaw.step(r?0:speed*.32+this.look.x*.14,dt,45,12),
 headX:this.headX.step(r?0:-this.look.y*.22+calm*.08,dt,62,14),headY:this.headY.step(r?0:this.look.x*.36,dt,62,14),
 tilt:r?0:-speed*.075+Math.sin(t*.8)*.018,ear:r?0:this.ears.step(0,dt,85,9)+breath*.8,
 eyes:r?1-calm*.85:Math.max(.07,(1-blinking)*(1-calm*.87)*(1-joy*.36)),pupilX:r?0:this.look.x*.035,pupilY:r?0:this.look.y*.025,
 joy,calm,alert,moving:r?0:moving,gait:r?0:gait,energy:r?0:this.energy,held:this.touching&&!r?1:0};if(r){this.pose.yaw=0;this.pose.headX=0;this.pose.headY=0;this.pose.joy=this.mood==='happy'?.85:0;this.pose.calm=this.mood==='sleepy'?1:0;this.pose.alert=this.mood==='alert'?1:0;this.pose.eyes=this.mood==='sleepy'?.13:1;}return this.pose;
 }
}
