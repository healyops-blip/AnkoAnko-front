"""Reproducible, editable reference-led Anko mesh. Blender 5.2+; Y is up."""
import bpy, math, os
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,roughness=.32,coat=.28):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;m.node_tree.nodes.clear();p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');output=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],output.inputs['Surface']);p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=roughness;p.inputs['Coat Weight'].default_value=coat;p.inputs['Coat Roughness'].default_value=.35;return m
blue=mat('Anko blue',(0.004,.085,.46),.46,.16);white=mat('Ice-blue face',(.68,.88,1),.4,.18);black=mat('Deep navy eyes',(.0015,.005,.014),.15,.75);iris=mat('Blue iris',(.002,.045,.25),.2,.6);glint=mat('Eye catchlight',(1,1,1),.16,.4);mouthmat=mat('Warm mouth',(.065,.009,.006),.55,0);tongueMat=mat('Tongue',(.8,.12,.075),.5,0)
def empty(name,parent=None,pos=(0,0,0)):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.parent=parent;o.location=pos;return o
rig=empty('AnkoRig');torso=empty('Torso',rig)
def sphere(name,pos,scale,material,parent=None,segments=48,rings=32):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=pos);o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material);o.parent=parent
 for f in o.data.polygons:f.use_smooth=True
 return o
def mesh(name,vs,fs,material,parent=None):
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.data.materials.append(material);o.parent=parent
 for p in me.polygons:p.use_smooth=True
 return o
def union(name,parts,voxel=.019):
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 mod=o.modifiers.new('Sculpt union','REMESH');mod.mode='VOXEL';mod.voxel_size=voxel;mod.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Surface relaxation','SMOOTH');mod.factor=1.2;mod.iterations=6;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Mobile topology','DECIMATE');mod.ratio=.65;bpy.ops.object.modifier_apply(modifier=mod.name)
 for p in o.data.polygons:p.use_smooth=True
 return o
parts=[sphere('Chest',(0,.83,0),(.47,.57,.365),blue)]
for side in [-1,1]:
 parts += [sphere('Leg',(side*.27,.33,0),(.22,.34,.235),blue),sphere('Foot',(side*.30,.13,.115),(.26,.18,.345),blue)]
 # A smooth continuous sleeve avoids the scallops of a chain of spheres.
 vs=[];fs=[];around=32;length=24
 axis=Vector((side*.35,-.65,.06)).normalized();u=Vector((0,0,1)).cross(axis).normalized();v=axis.cross(u).normalized()
 for j in range(length+1):
  t=j/length;centre=Vector((side*(.36+.36*t),1.13-.68*t,.025+.065*t));radius=.151+.018*math.sin(t*math.pi/2)
  for i in range(around):
   a=2*math.pi*i/around;point=centre+(u*math.cos(a)+v*math.sin(a))*radius;vs.append(tuple(point))
 for j in range(length):
  for i in range(around):a=j*around+i;b=j*around+(i+1)%around;fs.append((a,b,b+around,a+around))
 fs += [tuple(range(around-1,-1,-1)),tuple(length*around+i for i in range(around))]
 parts.append(mesh('Sleeve',vs,fs,blue))
 parts += [sphere('Mitten',(side*.72,.445,.095),(.178,.215,.165),blue),sphere('Thumb',(side*.61,.445,.195),(.092,.13,.085),blue)]
body=union('BodySurface',parts);body.parent=torso
# Sculpt feet into soft flat soles instead of detached ball-shaped shoes.
for v in body.data.vertices:
 if v.co.y<.035:v.co.y=.012+(v.co.y+.05)*.14
# Actual skinning allows elbows and hips to move without exposing separate primitives.
armdata=bpy.data.armatures.new('Anko skeleton');arm=bpy.data.objects.new('Skeleton',armdata);bpy.context.collection.objects.link(arm);arm.parent=torso;bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None):
 b=armdata.edit_bones.new(name);b.head=head;b.tail=tail
 if parent:b.parent=armdata.edit_bones[parent]
 return b
bone('Root',(0,.1,0),(0,1.3,0))
for side,label in [(-1,'L'),(1,'R')]:
 bone('Shoulder'+label,(side*.37,1.11,0),(side*.56,.76,.05),'Root');bone('Elbow'+label,(side*.56,.76,.05),(side*.72,.40,.10),'Shoulder'+label);bone('Hip'+label,(side*.25,.5,0),(side*.27,.08,.1),'Root')
bpy.ops.object.mode_set(mode='OBJECT')
# Heat diffusion follows the connected surface instead of assigning nearby
# hands and feet to the same joint merely because they share a position.
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
# Keep the explicit scene hierarchy used by the shared runtime.
body.parent=torso
bpy.context.view_layer.objects.active=body
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL',limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL',lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')
headPivot=empty('HeadPivot',torso,(0,1.55,0));head=empty('Head',headPivot,(0,.55,0))
# Rounded hood with fuller lower cheeks: Lp silhouette, not a sphere.
vs=[];fs=[];nu=96;nv=64;power=2.2
for j in range(nv+1):
 lat=-math.pi/2+math.pi*j/nv
 for i in range(nu):
  a=2*math.pi*i/nu;d=Vector((math.cos(lat)*math.cos(a),math.sin(lat),math.cos(lat)*math.sin(a)));k=sum(abs(v)**power for v in d)**(-1/power);vs.append((d.x*k*1.015,d.y*k*.925,d.z*k*.79))
for j in range(nv):
 for i in range(nu):a=j*nu+i;b=j*nu+(i+1)%nu;fs.append((a,b,b+nu,a+nu))
hood=mesh('Hood',vs,fs,blue)
# Soft tapered ears are merged into the hood, including their roots.
earparts=[hood]
for side in [-1,1]:
 vs=[];fs=[];steps=20;around=32
 for j in range(steps+1):
  t=j/steps;radius=.22*(1-t)**.7+.015;cx=side*(.58+.09*t);cy=.68+.43*t;cz=-.075
  for i in range(around):a=2*math.pi*i/around;vs.append((cx+radius*math.cos(a),cy,cz+radius*.72*math.sin(a)))
 for j in range(steps):
  for i in range(around):a=j*around+i;b=j*around+(i+1)%around;fs.append((a,b,b+around,a+around))
 fs.append(tuple(range(around-1,-1,-1)));fs.append(tuple(steps*around+i for i in range(around)))
 earparts.append(mesh('Ear',vs,fs,blue))
hood=union('SculptedHood',earparts,.014);hood.parent=head
# Curved face, with the reference's distinctive deep centre dip and generous cheeks.
def zface(x,y):return .79*max(.015,1-abs(x/1.015)**power-abs(y/.925)**power)**(1/power)+.018
def bezier(a,b,c,d,n=24):
 return [tuple((1-t)**3*a[k]+3*(1-t)**2*t*b[k]+3*(1-t)*t*t*c[k]+t**3*d[k] for k in range(2)) for t in [j/n for j in range(n)]]
path=[]
curves=[((0,.37),(.19,.34),(.24,.64),(.48,.56)),((.48,.56),(.80,.47),(.89,.01),(.76,-.34)),((.76,-.34),(.54,-.77),(-.54,-.77),(-.76,-.34)),((-.76,-.34),(-.89,.01),(-.80,.47),(-.48,.56)),((-.48,.56),(-.24,.64),(-.19,.34),(0,.37))]
for c in curves:path+=bezier(*c)
vs=[];fs=[];N=len(path);rings=28
for j in range(rings+1):
 f=j/rings
 for x,y in path:x*=f*.92;y=((y+.07)*f-.07)*.94;vs.append((x,y,zface(x,y)))
for j in range(rings):
 for i in range(N):a=j*N+i;b=j*N+(i+1)%N;fs.append((a,b,b+N,a+N))
face=mesh('HeartFace',vs,fs,white,head)
solid=face.modifiers.new('Soft face rim','SOLIDIFY');solid.thickness=.012;bpy.context.view_layer.objects.active=face;bpy.ops.object.modifier_apply(modifier=solid.name)
for side,label in [(-1,'L'),(1,'R')]:
 eye=empty('Eye'+label,head,(side*.345,.045,zface(side*.345,.045)+.022));eye.rotation_euler.y=side*.18
 sphere('EyeLens'+label,(0,0,0),(.145,.173,.077),black,eye)
 sphere('Iris'+label,(0,-.045,.063),(.113,.116,.018),iris,eye)
 sphere('Pupil'+label,(0,.018,.074),(.105,.126,.018),black,eye)
 sphere('Catchlight'+label,(-.041,.066,.092),(.039,.044,.012),glint,eye,32,20)
 sphere('CatchlightSmall'+label,(.044,-.023,.091),(.015,.019,.008),glint,eye,24,16)
 # Closed eyelid curve is separate geometry, visible only during a full blink.
 cu=bpy.data.curves.new('Lid curve','CURVE');cu.dimensions='3D';cu.bevel_depth=.019;cu.bevel_resolution=4;sp=cu.splines.new('BEZIER');sp.bezier_points.add(2)
 for pt,co in zip(sp.bezier_points,[(-.14,.005,0),(0,-.042,.015),(.14,.005,0)]):pt.co=co;pt.handle_left_type='AUTO';pt.handle_right_type='AUTO'
 bpy.ops.object.select_all(action='DESELECT');lid=bpy.data.objects.new('Lid'+label,cu);bpy.context.collection.objects.link(lid);lid.parent=head;lid.location=eye.location+Vector((0,0,.068));lid.data.materials.append(black);bpy.context.view_layer.objects.active=lid;lid.select_set(True);bpy.ops.object.convert(target='MESH');lid=bpy.context.object;lid.name='Lid'+label;lid.hide_render=True
nose=sphere('Nose',(0,-.155,zface(0,-.155)+.026),(.093,.057,.052),black,head)
# Smiling mouth is concave geometry, with a lip rim and tongue below the corners.
mouth=empty('Mouth',head,(0,-.285,zface(0,-.285)+.025))
outline=[]
for c in [((-.19,.055),(-.09,.0),(.09,.0),(.19,.055)),((.19,.055),(.17,-.10),(.09,-.18),(0,-.17)),((0,-.17),(-.09,-.18),(-.17,-.10),(-.19,.055))]:outline+=bezier(*c,20)
vs=[(0,-.05,-.013)]+[(x,y,0) for x,y in outline];fs=[(0,i+1,(i+1)%len(outline)+1) for i in range(len(outline))];mesh('SmileInterior',vs,fs,mouthmat,mouth)
sphere('Tongue',(0,-.12,.008),(.105,.048,.012),tongueMat,mouth)
# Flush lightning emblem follows the curvature of the torso instead of floating on it.
outline=[(.07,.26),(-.17,-.01),(-.025,-.012),(-.085,-.255),(.185,.065),(.04,.065)]
vs=[];fs=[]
for ids in [(0,1,2),(0,2,5),(2,3,4),(2,4,5)]:
 a,b,c=[Vector(outline[i]) for i in ids];grid={};N=10
 for i in range(N+1):
  for k in range(N+1-i):
   point=a+(b-a)*(i/N)+(c-a)*(k/N);x,y=point.x,point.y+.85;z=.365*math.sqrt(max(.1,1-(x/.47)**2-((y-.83)/.57)**2))+.035;grid[i,k]=len(vs);vs.append((x,y,z))
 for i in range(N):
  for k in range(N-i):
   fs.append((grid[i,k],grid[i+1,k],grid[i,k+1]))
   if k<N-i-1:fs.append((grid[i+1,k],grid[i+1,k+1],grid[i,k+1]))
mesh('Lightning',vs,fs,glint,torso)
# Export only character objects; keep an editable native authoring file as well.
bpy.ops.object.select_all(action='DESELECT')
for o in list(bpy.context.scene.objects):
 if o.type in {'MESH','ARMATURE','EMPTY'}:o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Anko-Refined.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'anko-refined.glb'),export_format='GLB',use_selection=True,export_yup=False,export_animations=False,export_skins=True,export_materials='EXPORT',export_extras=True)
print('ANKO_MESH_STATS',sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH'))
