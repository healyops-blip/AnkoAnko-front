import assert from 'node:assert/strict';
import {CompanionMotion} from './motion.mjs';
const m=new CompanionMotion(()=>.5);const step=(n=90)=>{for(let i=0;i<n;i++)m.step(1/30);return m.pose;};
step();m.start(.8,.3);m.drag(.8,.3);step(8);assert(m.pose.x>0&&m.pose.x<.7);assert(m.pose.moving>0);const oldVelocity=m.x.velocity;m.drag(-.8,-.3);m.step(1/30);assert(Math.abs(m.x.velocity-oldVelocity)<2,'direction changes continuously');step(100);assert(m.pose.x<-.6);m.release();step(100);assert(Math.abs(m.x.velocity)<.001);
m.pet();step(2);assert(m.pose.y>0);for(let i=0;i<50;i++)m.pet();step(3);assert(m.pose.y<=.23);m.setMood('sleepy');step(100);assert(m.pose.calm>.99&&m.pose.eyes<.2);
m.setMood('alert');step(100);assert(m.pose.alert>.99);m.reduced=true;step(3);assert.equal(m.pose.y,0);assert.equal(m.pose.moving,0);assert.equal(m.pose.energy,0);assert.equal(m.pose.tilt,0);
for(let i=0;i<1000;i++){if(i%53===0)m.pet();if(i%101===0)m.drag(Math.sin(i),Math.cos(i));const p=m.step(i%5===0?1:.01);for(const v of Object.values(p))assert(Number.isFinite(v));}
console.log('PASS real-time rig: smooth following/reversal, settling, impulse bounds, expression blending, reduced motion, long-run finite poses.');
