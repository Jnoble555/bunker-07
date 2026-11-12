# Security SMG source

Original project meshes and materials generated in Blender 5.3.0; no external assets or license dependencies. The separate parts include receiver/slide, barrel, stock, grips and removable magazine.

Editable source: security_smg.blend.
Reproducible source: generate.py.
Runtime export: godot/assets/weapons/security_smg.glb.
The existing Godot security_sidearm.tscn wrapper caches both models and drives their parts using the selected weapon's definition. The pistol source/export are unchanged.

From the repository root in PowerShell:
```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.3/blender.exe' --background --python assets/source/security-smg/generate.py
```

SMG firing audio is original finite synthesized PCM in native_audio.gd, with a separate sound specification from the pistol.
