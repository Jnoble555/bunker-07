# GitHub Pages: current Godot game

The hosted root is now built from `godot/project.godot`, including Deep Signal, the three-mission native campaign, tactical movement and weapon inventory. The earlier JavaScript game remains at `classic.html`. The repository's original `index.html`, source and classic tests remain the historical JavaScript implementation; the Pages artifact replaces the hosted root with the Godot export.

## Play

Open https://jnoble555.github.io/bunker-07/ and choose **Deep Signal / Tactical Operation → Deploy**. That option comes first; **Original campaign (3 missions)** is separate. WASD/mouse, Ctrl crouch, Shift sprint, Q/C lean, RMB zoom, E collect/use, 1/2/3 weapons, R reload, P/Esc pause. F5 retries while the game canvas has focus. CSV export downloads a browser file. The small Original browser edition link opens the classic JavaScript game.

Requires a desktop browser with WebGL 2. First load downloads the approximately 36 MB engine plus game data; later loads can use the browser cache. The export is single-threaded and needs no cross-origin isolation headers. No checkpoint save/resume has been added.

## Rebuild and publish

`.github/workflows/pages.yml` pins Godot 4.6.3, installs the official export template, exports the current project, stages the classic game and deploys a Pages artifact. A push to main triggers publishing; generated WASM is not committed to Git. `build-info.json` in the published site records the exact source commit and edition. Set Settings → Pages → Build and deployment → Source to **GitHub Actions** once. GitHub restricts changing that repository setting through the workflow token; the deployment job itself only publishes the built artifact.

Local build with Godot 4.6.3 and its web export template installed:

```
scripts/build_web.sh "$PWD/work/site"
python -m http.server 8765 --directory work/site
```

Open http://localhost:8765/. Opening the exported HTML as a local file is unsupported. `godot/export_presets.cfg` disables threading; `scripts/finish_web.py` adds edition identity, the classic link, the retry-key default override and the build marker. Neither engine files nor downloaded templates are part of source commits.

## Validation boundaries

The production export is tested in Chromium using WebGL 2 over plain HTTP without COOP/COEP headers. Native operation regression checks also pass 28/28 after the menu/CSV changes. Browser screenshots and actual hosted deployment verification are recorded in the delivery conversation. The classic file-URL regression cannot run in this managed Chromium because its administrator policy blocks file:// navigation; this is distinct from the HTTP classic edition. Full human combat balance, audible mix, mobile controls, other browsers and checkpoint saving remain outside this release.
