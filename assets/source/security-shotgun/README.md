# Original breach shotgun

Original project geometry and materials, generated with Blender 4.3.2. No downloaded assets.

From the repository root:

```
blender -b --python assets/source/security-shotgun/generate.py
```

This saves `security_shotgun.blend` beside the generator and exports `godot/assets/weapons/security_shotgun.glb`. The receiver, extended barrel, tubular magazine, fore-end, stock and amber sight distinguish it from the SMG. Named Slide/Magazine/MagazineBase nodes use the existing timing-driven weapon wrapper. The reload is a stylized magazine/tube motion, not a realistic per-shell reload; all ammunition transfers only when the 2.2-second reload completes.
