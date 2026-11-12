# Security shotgun source

Original Bunker 07 detachable-magazine industrial shotgun made with Blender 5.3.0. No external models, textures, recordings or asset license dependencies.

- Editable source: security_shotgun.blend.
- Reproducible Blender source: generate.py.
- Runtime export: godot/assets/weapons/security_shotgun.glb.
- Animation part names: Slide (ribbed fore-end), Magazine and MagazineBase.
- Blender +Y points down the barrel; GLB maps this to Godot -Z.
- Definition view_scale: 0.75; muzzle Vector3(0,0.038,-0.285) is already scaled for that model scale.
- Original PCM sound specification: godot/scripts/shotgun_sound.gd.

Regenerate from the repository root in PowerShell:
```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.3/blender.exe' --background --python assets/source/security-shotgun/generate.py
```

The GLB exports evaluated bevels and weighted normals. Source objects remain independently editable. Pump ribs are parented to Slide so they follow the shared presentation animation.

Asset-only visual preview: docs/godot/campaign-screenshots/shotgun-asset.png. Final gameplay framing, ammunition, accuracy accounting and pickup integration are owned by the operation integration code.
