# M1 verification and pause checkpoint

**Partial Control Room port; campaign parity is not achieved.** Branch: `migration/godot-control-room`, based on completed browser commit `252e9a4`. Work paused at the user's request after validation, then resumed only to finalize this checkpoint. The first staging attempt was not executed because automatic approval review could not complete after usage expired; no commit was made during that attempt. The milestone commit is now the latest commit on this branch. No merge or publication has been performed.

## Actually executed

- Repository/status/README/source/test/docs inspection; no initial local edits or applicable AGENTS.md were found. Shared contracts and parity checklist were written before independent implementation.
- Installed Godot console executable `C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --version`: `4.7.2.stable.official.ed1daf0bf`.
- Fresh browser `npm test`: 94 gameplay checks and 3 path checks passed. Evidence from this run is separately preserved in [browser-baseline.json](browser-baseline.json). Historical browser reports were restored to their original contents. Browser source/tests were not changed.
- Final Godot `--headless --path godot --editor --import --quit`: clean import, exit 0, no script/import errors. An initial sandboxed attempt could not write Godot's AppData caches; the normal-permission rerun succeeded.
- Final `--headless --path godot --script res://tests/milestone_test.gd`: **46 passed, zero failed**, exit 0. [Native results](../../godot/tests/milestone-results.json).
- Non-headless Compatibility/OpenGL run using `--script res://tests/visual_smoke.gd`: exit 0, real Space-key event dispatched, title/maintenance/guard/pause screenshots captured. Screenshots were visually inspected. Renderer reported Microsoft D3D12 / Qualcomm Adreno via Mesa OpenGL 4.6. This was scripted runtime testing, not a full human playthrough.

## Native checks cover

Movement collision/diagonal normalization, yaw and horizontal FOV, weapon hits/nearest walls/cooldown/three-hit health/stagger, grazing and overlapping hit volumes, dead-target removal, reload/fire gating, pause freezing reload/attack/active clock and dropping pending fire, native P pause/resume input, panel range/idempotence, guard detection/LOS/chase, attack damage and cancellation, core gating/extraction, retry reset, and collision-driven maintenance traversal through the opened gate to extraction. The route test isolates enemy AI; combat is tested separately.

## Findings resolved

Corrected camera KEEP_WIDTH projection to match the browser horizontal FOV; readable depth-tested world labels; viewmodel depth clipping near walls; separate .56m hit tolerance from .36m movement radius; inside-hurtbox hitscan and behind-camera rejection. Target-center wall-depth precedence remains as in the reference. One initially failing gate assertion aimed into a permanent wall beyond the gate; its endpoint was corrected, rather than changing correct map collision.

Independent agents owned room geometry and guard implementation in disjoint files. Root integrated shared gameplay. An independent reviewer authored native tests and inspected the combined implementation; no code-review skill was available in the skill catalog. See [review notes](review.md).

## Resume here

Launch by importing `godot/project.godot` and pressing F5, then Deploy. Detailed commands/controls are in [godot/README.md](../../godot/README.md). All remaining work is explicit in [parity.md](parity.md): cameras, investigation, reinforcements, other roles/devices, optional intel/cache, journal/ranks, campaign transitions and success-only consequence commits, settings/onboarding/summaries, sound and CSV analytics. No campaign state is committed by this milestone.

No export, merge to main, branch publication, full manual mouse-driven campaign, cross-platform validation or performance certification has been performed. Browser hosting and reference remain intact. Resume from this checkpoint; do not restart or infer full port completion.

## Engine references read directly

- [Godot ray casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html): physics-space queries, masks, inside-hit behavior.
- [Pausing and process modes](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html): pause the scene physics while menu input remains active.
- [CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html): native collision-aware movement.
