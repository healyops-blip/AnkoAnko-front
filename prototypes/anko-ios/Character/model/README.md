# Anko refined character

Reference-led reconstruction from the supplied Anko visual. This is a new editable model, not the original brand production model. Unseen surfaces are inferred from the supplied images.

- `Anko-Refined.blend`: native authoring scene.
- `anko-refined.glb`: self-contained runtime model; embedded into HTML by the build.
- `sculpt.py`: reproducible mesh, materials, seven-bone skin, and face construction.

The hood and ears are merged into one smooth surface. The body, sleeves, mitten hands, legs and feet form one continuous skinned mesh. Heat-diffusion skin weights follow the connected surface and keep arm motion from affecting the feet. The face follows the hood curvature; eyes, eyelids, mouth and lightning are geometry rather than image swaps.

Rebuild with Blender 5.2 or later:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b -t 4 --python sculpt.py
```

Then run `npm test` and `npm run build` from `Character/`, and rebuild the iOS app. No network model service or external texture is needed at runtime. The `.blend` material previews and the application's lights may differ; final appearance is checked in the app.

The debug-only iOS environment `ANKO_MODEL_REVIEW=turn`, combined with an `ANKO_PREVIEW_THEME`, enables a repeatable turned/raised-arm inspection pose. Normal runs keep continuous interaction and do not use that pose.
