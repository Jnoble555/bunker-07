# Industrial security sidearm
Original Bunker 07 geometry and materials, created in Blender 5.3.0 using generate.py. No downloaded art or external asset licenses. Editable source: security_sidearm.blend. Runtime export: godot/assets/weapons/security_sidearm.glb.
Regenerate from repo root:
"C:/Program Files/Blender Foundation/Blender 5.3/blender.exe" --background --python assets/source/security-sidearm/generate.py
Godot 4.7.2 imports the GLB. Open godot/project.godot, press F5, Start Campaign, Deploy. The reusable wrapper is godot/scenes/security_sidearm.tscn.
Presentation reads the existing flash and reload_remaining timers; no combat-controller edits. Slide and magazine parts remain separate editable mesh objects. Reset explicitly restores idle. Weapon surfaces disable world shadow casting and use the existing viewmodel overlay convention.
Executed: Godot import/parser validation; existing milestone combat suite 46/46; graphical campaign smoke; weapon_visual.gd captured idle, movement, firing, reload stages, empty ammo and retry and asserted pause preserves magazine pose and retry restores ammo. Captures are docs/godot/campaign-screenshots/weapon-*.png.
Remaining: human mouse-driven feel, full magazine visibility during the lowered reload pose, subjective materials across additional lighting conditions, and a full campaign playthrough. The bright/dark campaign captures precede the final raised weapon placement; weapon-idle and animation frames use that placement.
