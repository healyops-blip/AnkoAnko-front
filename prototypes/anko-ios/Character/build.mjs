import {build} from 'esbuild';
import fs from 'node:fs';
const dir=new URL('.',import.meta.url);const result=await build({entryPoints:[new URL('character.js',dir).pathname],bundle:true,minify:true,format:'iife',target:['safari17'],write:false,legalComments:'inline'});
const page=new URL('../Anko/Resources/Web/index.html',dir);let html=fs.readFileSync(page,'utf8');html=html.replace(/<script id="anko-realtime-character">[\s\S]*?<\/script>/,'');html=html.replace('</body>',()=>`<script id="anko-realtime-character">${result.outputFiles[0].text.replaceAll('</script','<\\/script')}</script>\n</body>`);fs.writeFileSync(page,html);
fs.copyFileSync(new URL('node_modules/three/LICENSE',dir),new URL('THREE-LICENSE.txt',dir));
console.log('Bundled offline 3D character into shared HTML.');
