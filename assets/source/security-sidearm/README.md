# Industrial security sidearm

Original Bunker 07 geometry/materials made with Blender 5.3.0. No external art or license dependencies.
Editable source: security_sidearm.blend; reproducible generator: generate.py; runtime: godot/assets/weapons/security_sidearm.glb. The generator exports evaluated bevels/normals and darker steel/polymer materials.

Regenerate from the repository root:
```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.3/blender.exe' --background --python assets/source/security-sidearm/generate.py
```

Launch: import godot/project.godot in Godot 4.7.2, press F5, Start Campaign, Deploy. Reusable wrapper: godot/scenes/security_sidearm.tscn.

The player renders the weapon in a transparent 1280x720 SubViewport under the HUD, with its own depth buffer and neutral lighting. Normal depth testing preserves overlap between weapon parts; isolation keeps world walls from clipping the weapon. Shadows are disabled. The reduced, angled pose exposes the grip and barrel. Reload raises and tilts the weapon while moving the magazine out and back during the unchanged 0.8-second controller timer. Recoil/slide still follow the existing 0.10-second flash state. Pause and reset retain their original controller behavior.

Verification executed for this polish:
- Godot import/parser validation with regenerated GLB: clean.
- Existing milestone/combat suite: 46/46, zero failures.
- Updated weapon_visual.gd rendered idle, movement, firing, magazine out/in, empty, retry, bright Breach, dark Blackout, interaction range and near-wall views. It asserted magazine pose stays frozen during pause and slide/magazine return home after retry.
- All current weapon-*.png captures except the explicitly historical before images use the final GLB and placement. The firing capture holds the controller-triggered pose paused for GPU inspection; reload frames are at about 0.4 and 0.7 seconds.
- Matching Control Room idle comparison: [before](../../../docs/godot/campaign-screenshots/weapon-polish-before-idle.png), [after](../../../docs/godot/campaign-screenshots/weapon-idle.png).
- [Magazine out](../../../docs/godot/campaign-screenshots/weapon-reload-out.png), [magazine in](../../../docs/godot/campaign-screenshots/weapon-reload-in.png), [bright](../../../docs/godot/campaign-screenshots/weapon-bright.png), [dark](../../../docs/godot/campaign-screenshots/weapon-dark.png).

Limits: fixed neutral viewmodel lighting intentionally does not reflect colored world lights. Human mouse-driven feel, other window aspect ratios/drivers and the added viewport's performance on other hardware remain manual checks.
