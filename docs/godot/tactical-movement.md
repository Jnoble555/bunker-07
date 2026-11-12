# Tactical movement milestone

Branch: feature/tactical-movement, based on completed main 54bb961. One-agent implementation; browser and weapon assets are unchanged.

Controls: mouse full look (existing sensitivity, +/-80 degree pitch); WASD horizontal motion; hold Ctrl crouch, Shift sprint, Q/C lean, RMB aim. E remains interaction. Crouch uses a 1.05 m capsule and 0.85 m eye height; standing uses 1.8 m / 1.4 m and checks clearance. Gravity, floor snap, ramps up to 48 degrees and steps up to 0.26 m are supported. Sprint is 1.5x; crouch 0.45x; aiming multiplies speed by 0.65 and narrows horizontal FOV to 58 degrees. Lean sweeps a 0.12 m camera sphere through up to 0.32 m of lateral travel.

The player body yaw determines horizontal travel; camera pitch/lean determines the existing hitscan ray. Enemy/camera detection uses the actual player eye. Device interaction rays use the actual eye and may terminate on that device's own solid housing, but stop on intervening obstacles. The overload ignores only its own housing when checking outgoing visibility.

Equipment racks, alarm console, service/overload terminal housings and the supply box use world collision layer 1, shared by player movement, enemy movement, sight and shots. The console and cache sit toward the south side of their aisles to preserve actor clearance. Existing route checks now walk the north clearance lane instead of walking through prop centers; bulkhead LOS assertions start outside the newly solid overload terminal. Their assertions retain the original success conditions.

Reset restores standing, pitch, lean, aim and velocity. Menu opening, pause and application focus loss release held action state; release/repress keys after returning to a menu if necessary. Pause freezes camera and weapon animation.

Launch:
- Campaign: open godot/project.godot, F5, Start Campaign, Deploy.
- Lab: open godot/scenes/movement_lab.tscn, F6.
- CLI from repo root: Godot --path godot res://scenes/movement_lab.tscn.
- Installed executable: C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe.

Actual verification on Godot 4.7.2 / Windows Compatibility:
- Editor import/script parsing.
- Existing milestone mechanic checks: 46/46.
- Existing campaign checks: 51/51, all three campaign routes.
- tactical_movement_test.gd: 17/17, including short capsule, headroom, standing recovery, pitch-independent travel, sprint/aim/crouch speed, pitch clamp, lean wall sweep, stair/ramp ascent, elevated target shot, vertical occlusion, interaction/enemy occlusion, pause freeze/input release and retry reset.
- The tactical suite also ran graphically. Captured and inspected the [lab](campaign-screenshots/movement-lab.png) and [headroom bay](campaign-screenshots/movement-headroom.png).
- Existing saved JSON reports remain historical; new executed results above are distinguished from them.

Remaining manual checks: prolonged mouse-driven campaign feel, unusual staircase corners/steep transitions, camera roll comfort, other frame rates/drivers and non-default window aspect ratios. No inventory or enemy-expansion work is included.

Inventory milestone follow-up: the pitch test now calls the shared clamping math directly in headless mode and explicitly skips captured-mouse handler coverage there. A separate graphical check dispatches a synthetic mouse event only when mouse capture is available. See [current inventory verification](weapon-inventory.md) for the separately recorded results.
