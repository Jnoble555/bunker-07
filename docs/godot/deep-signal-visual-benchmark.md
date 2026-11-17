# Deep Signal desktop visual benchmark

Branch: `feature/deep-signal-visual-benchmark`, based on GitHub main `c9d00c6`. The user's preferred Deep Signal mission is the showcase. This is the first environment/material/lighting benchmark toward a more modern presentation; character and first-person animation production remain separate milestones.

## View and play

The benchmark is an **opt-in scene**. Ordinary project F5 and the hosted game still use the existing main scene. The benchmark starts Deep Signal immediately with its eight actors, current security director, objectives, pickups, ammunition and retry rules.

From the repository root in PowerShell:

```powershell
$godotBin = 'C:/Users/jnobe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
& $godotBin --path .\godot --rendering-method forward_plus --rendering-driver d3d12 res://scenes/deep_signal_visual_benchmark.tscn
```

For the Compatibility preview, replace the renderer/driver arguments with `--rendering-method gl_compatibility`. To see the original visual baseline in the same playable scene, append `-- --benchmark-baseline` at the end of either command. `scripts/run_visual_benchmark.ps1` provides the same profiles through `-Renderer Desktop` or `-Renderer Compatibility` and optional `-Baseline`; direct commands also work on machines that restrict local PowerShell scripts.

In the Godot editor, open `scenes/deep_signal_visual_benchmark.tscn` and press **F6** for the project's default Compatibility preview. Use the command above for desktop Forward+. WASD/mouse, Ctrl crouch, Shift sprint, Q/C lean, RMB zoom, E interaction/pickups, 1/2/3 weapons, R reload, P/Esc pause and F5 retry remain available.

## Art direction and implementation

Grounded near-future military infrastructure: pale mineral concrete, blue-grey painted service panels, dark rubber, worn metal hardware and restrained amber identifiers. Cool operational lighting contrasts with warmer entry/security lighting. Surfaces and geometry establish scale; emissive screens retain their color and lose the overexposed appearance.

| Surface | Direction |
| --- | --- |
| Concrete | Pale grey, fine pores, restrained tonal variation; 2 m texture period |
| Painted equipment | Blue-grey enamel; roughness variation and subtle wear |
| Floor | Grey anti-slip panels with seams/fasteners and restrained normal detail; 1 m period |
| Hardware | Exposed metal with bevels and roughness 0.38 |
| Guidance | Existing cyan route markers, amber objectives and contextual E guidance |

Original Blender modules add panel joints, kick plates, captive fasteners, vent louvers, ceiling cable trays and protected practical-light housings. Repeated parts use MultiMesh batches. The visual layer adds **no physics bodies**, changes no existing collision transforms and does not modify authored navigation or cover.

Desktop uses Forward+ / D3D12, SSAO and 2× MSAA on world and weapon viewports. Compatibility disables SSAO and retains the same original textures and modules. Both use filmic tone mapping, selective room shadows and neutral sky-based specular fill. Runtime reflection probes emitted a seven-texture cleanup warning on this D3D12/GPU combination; the final reflection-sky fallback exits without that warning. Its fill is an approximation, not room-accurate reflections or baked indirect lighting.

The existing rooms are generated at runtime. This pass does not claim lightmap baking or global illumination; an editor-authored/bakeable environment is a later step. Renderer capability references: [Godot renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [PBR material documentation](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).

The benchmark HUD moves health/ammo to the lower edge and keeps objective/E guidance above. Existing alerts and gameplay remain connected to the campaign controller. Deep Signal guards now use an original procedural security-operator mesh: layered armor, helmet/visor, pouches, knee protection, radio pack and service rifle. Vertex colors batch each animated body section into one surface; simple limb gait, firing recoil, reload pose and alert lamp continue to follow the existing actor state. The model is a stylized low-detail first pass, not a rigged production character.

No external character or weapon asset was used. The runtime mesh and muted industrial material palette are generated in `scripts/deep_signal_enemy_visual.gd`; gameplay collision and AI remain in `scripts/deep_signal_enemy.gd`.

## Matching captures

All comparisons use identical 1280×720 camera positions and the final assets. Scripted capture freezes enemy physics and visits entry, Security, Maintenance and Operations; Operations is a visual inspection viewpoint, not evidence of completing its objective sequence.

| View | Original desktop | Final desktop |
| --- | --- | --- |
| Entry | [before](visual-benchmark/before-forward_plus-entry.png) | [after](visual-benchmark/after-forward_plus-entry.png) |
| Security | [before](visual-benchmark/before-forward_plus-security.png) | [after](visual-benchmark/after-forward_plus-security.png) |
| Maintenance | [before](visual-benchmark/before-forward_plus-maintenance.png) | [after](visual-benchmark/after-forward_plus-maintenance.png) |
| Operations | [before](visual-benchmark/before-forward_plus-operations.png) | [after](visual-benchmark/after-forward_plus-operations.png) |

Guard close-up: [final model in the running Deep Signal scene](visual-benchmark/after-forward_plus-guard-detail.png). For this inspection capture the AI was frozen and the selected guard was turned toward the camera; it is a staged asset view, not a combat screenshot.

Compatibility uses matching `before-gl_compatibility-*` / `after-gl_compatibility-*` captures in the same folder. `*-access-used.png` records the actual successful access-terminal interaction.

## Actual verification and performance

Executed on the installed **Godot 4.7.2.stable.official.ed1daf0bf**, Windows, **Qualcomm Adreno X1-85**. Desktop driver reports D3D12 12_0; Compatibility reports Mesa OpenGL over D3D12. Blender **5.3.0** generated and exported the source asset successfully.

| Profile | Mean FPS | Mean frame time | p95 frame time | Reported draws |
| --- | ---: | ---: | ---: | ---: |
| Original / Forward+ | 172.9 | 5.78 ms | 6.79 ms | 158 |
| Final / Forward+, 2× MSAA | 97.3 | 10.28 ms | 11.85 ms | 186 |
| Original / Compatibility | 187.9 | 5.32 ms | 6.28 ms | 545 |
| Final / Compatibility | 47.8 | 20.92 ms | 22.32 ms | 348 |

Each final report measures 180 wall-clock process-frame intervals after a 90-physics-frame warmup at the fixed Security view, vsync disabled, AI frozen, one benchmark process at a time. JSON files in `visual-benchmark/` preserve the measurements. These short static-view samples do not establish sustained combat frame rate, browser FPS, thermal behavior or performance on another GPU. The original baseline has no added MSAA; the final desktop result includes its cost.

- Editor import/script check: exit 0, final output inspected without script/import errors.
- `visual_benchmark_test.gd`: **14/14** in both graphical profiles, and **14/14** in each original-baseline profile. Final output has no script errors or texture-cleanup warnings.
- Same test headlessly: **9/9**, skipping captures and graphical measurements. Added to the existing native regression runner for future CI.
- Checks compare original vs decorated collision shapes/transforms, cover points and navigation route; retain all eight actors; verify instancing, blocked/unblocked objective interaction, actual reload/clock pause and retry rebuild/reset.
- Existing `tactical_operation_test.gd`: **28/28** headless, including physical direct/alternate routes, elevated data/extraction, shotgun, switching, death/retry and original campaign entry.
- Final running captures inspected for scale, panel/vent visibility, materials, lighting and HUD/E guidance. This is scripted graphical validation, not a full human combat playthrough.
- After the guard visual iteration, the graphical benchmark passed **15/15** on Forward+ and the existing `deep_signal_enemy_test.gd` passed **16/16** headlessly. Collision, cover and navigation comparisons remain unchanged. The latest static capture sample with the new guard model reported **51.0 FPS** and **1,052 draw calls** on the same Adreno X1-85 setup; this sample is variable and indicates the character presentation still needs performance profiling before it should be considered a shipped visual default.

Reproduce: `& $godotBin --headless --path .\godot --editor --import --quit`, then `& $godotBin --headless --path .\godot --script res://tests/visual_benchmark_test.gd`. For captures/performance use the test script with the renderer flags from the launch command; append `-- --benchmark-baseline` for comparison.

## Next visual milestones

1. Human review of this direction during live combat, including screen readability and long-session performance. Compatibility requires further optimization before adopting this art profile as the hosted default; native Compatibility measurements do not verify a web export.
2. Replace this procedural guard with a rigged original or clearly licensed character and coordinated locomotion/aim/reload/hit animation.
3. Refine first-person weapon geometry/materials, add animated hands and improve environmental lighting response while retaining the isolated weapon depth buffer.
4. Develop hero terminals/cover and bakeable room modules, then validate indirect lighting/reflections. The current repeated architecture remains a first-pass kit.

Asset source and reproducibility: [control-room-kit README](../../assets/source/control-room-kit/README.md). No external art was acquired. Main, browser defaults and existing gameplay source remain unchanged by this feature.
