# Independent Godot milestone review

Scope: initial partial Control Room port only. The browser implementation remains the behavioral reference; this review does not certify campaign parity.

No code-review skill was available in the session's skill catalog. Review uses direct source inspection and an independently authored Godot physics integration harness in `godot/tests/milestone_test.gd`.

## Contract inspected

Reviewed `docs/godot/parity.md` before authoring tests, then the room and armored guard scripts against `src/game.js` and `src/bunker-systems.js`. Units (2m/tile), collision bit ownership, classic browser combat timings, range, armor health, and pause/reset interfaces were agreed before implementation ownership split.

## Confirmed findings resolved

- Camera FOV initially treated the browser's horizontal angle as Godot's vertical angle. The player camera now uses `KEEP_WIDTH` and `rad_to_deg(2 * atan(0.68))`. A projection-ray assertion confirms horizontal parity. [Godot Camera3D reference](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)
- The guard movement capsule was narrower than the reference's `.28`-tile shot tolerance. A separate `.56m` ray-target area now preserves the shooting tolerance while the physical movement radius remains `.36m`. Grazing hits and dead-target removal are tested.
- Actors intentionally do not block each other. Actual testing confirmed that shooting from inside the guard's hurtbox initially missed because native rays ignored their enclosing shape. `hit_from_inside` now handles this case, while the target-center positive-depth check prevents shooting an overlapping enemy behind the camera. Both cases are covered.
- Room label orientation and first-person weapon clipping were also corrected by their implementation owners after rendered inspection. The independent headless suite does not claim visual verification of those fixes.

One initial gate assertion incorrectly ended inside the permanent wall in map row 3. The test endpoint was corrected to the openable gate cell in row 4; that failure was a test-coordinate error, not a game defect.

## Executed validation

**46 native assertions passed**, zero failed, using actual Godot `4.7.2.stable.official.ed1daf0bf`. Results are saved in `godot/tests/milestone-results.json`. This is an executed native run, not a claim based on saved browser reports.

Run from the repository root:

```powershell
& 'C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --path godot --script res://tests/milestone_test.gd
```

The suite exercises real physics movement/wall collision and normalized diagonals, arrow aiming, physical P-key pause input routing, actual weapon hits and wall occlusion, armor/stagger/cooldown, reload pause/resume and fire gating, pending-shot cancellation, panel interaction range, attack pause/cancellation/damage, guard sight/detection/chase, core gate/extraction, and retry state reset. It also moves from the actual spawn through maintenance, uses the panel, collects the core, crosses the opened gate and reaches extraction without teleporting between route waypoints. That deterministic route disables guard processing to isolate traversal; combat and detection are tested separately with processing enabled.

The first sandboxed execution could not write Godot's normal user logs/read the Windows certificate store. Re-running with authorized escalation completed normally without those environment errors. No native script/runtime error appeared in the final run. A final `git diff --name-only -- src tests styles index.html` was empty, confirming browser runtime/test code remains unchanged.

No remaining blocking defect was found within the implemented M1 scope. This is not a guarantee of zero bugs or full campaign parity.

## Coverage limits

Headless deterministic physics checks cannot establish subjective presentation or mouse-capture usability. The integrating owner must separately inspect the rendered running game when available. Cameras, reinforcements, other devices/roles, optional objectives, campaign transitions/consequences, settings, onboarding, journal, ranks and CSV remain explicitly deferred unless the final parity checklist says otherwise.
