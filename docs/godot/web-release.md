# GitHub Pages: Godot release procedure

## Public URL and verified stale-game cause

Public game: https://jnoble555.github.io/bunker-07/ . Hosting was verified on 2026-11-16 from GitHub Pages settings and HTTP response headers (`Server: GitHub.com`, `X-GitHub-Request-Id`). No custom domain is configured.

The audit found **Pages build_type=legacy, source=main, path=/**. That publishes the repository's classic JavaScript `index.html`, not the Godot artifact. HTTP returned 200 with `src/game.js` and the classic canvas; `build-info.json` returned 404. Both a branch-based `pages build and deployment` and `.github/workflows/pages.yml` had successful runs at `0b50af7dec29daf432bfa10432501e888069d48f`. They competed for the same site. Successful Actions deployment alone did not prove the public root contained Godot.

The latest successful custom run observed was https://github.com/Jnoble555/bunker-07/actions/runs/43804732867 ; the competing legacy run was https://github.com/Jnoble555/bunker-07/actions/runs/43804731646 . The API identifies their commit, but the currently served classic HTML has no embedded source marker, so its exact commit cannot be independently proven from public bytes. Phase 1 was additionally uncommitted/unpushed before this task, and therefore could not appear in either build.

The former workflow used Godot 4.6.3; project features, installed editor and Phase 1 regression tests use **4.7.2 stable, Compatibility**. This preparation aligns exports to that tested version without changing the renderer. The classic source root remains intentionally preserved; the build stages it as `classic.html` alongside its `src`/`styles` assets.

## Approval and hosting configuration

No merge, Pages settings mutation or new public deployment is authorized by the preparation prompt. Feature branch/PR publishing is authorized. After owner approval:

1. Open repository **Settings > Pages > Build and deployment > Source**, select **GitHub Actions** (not Deploy from a branch). This removes the competing legacy branch publisher. If settings access is unavailable, the owner must perform this exact step.
2. Review/approve and merge the prepared feature PR to `main`. Do not force-push or bypass branch protection. Main pushes run the tested export pipeline and then deployment. Configure a required reviewer on the existing `github-pages` environment if ongoing per-release approval is desired.
3. Alternatively, after the approved changes are already on `main`, run **Validate and publish Godot game** with branch `main` and `deploy=true`. Default manual runs only build/validate. Non-main refs and PRs cannot deploy.
4. Confirm the workflow's source SHA and URL, then fetch the live marker with a cache-busting query. Compare its **full SHA** to the approved `main` commit, not only the short footer ID.

The existing `.github/workflows/pages.yml` remains the sole intended publication workflow; no replacement hosting service or competing deploy system was introduced. A merge to main is a release action; obtain owner approval first.

## Repeatable build and validation

`scripts/godot-version.txt` is the tested engine pin (4.7.2). CI downloads the official Linux editor and standard export templates from `godotengine/godot-builds/releases/tag/4.7.2-stable`, verifies pinned SHA256 digests, and installs only the nonthreaded web debug/release ZIPs from the template archive. Future version changes must update the version pin and reviewed official archive hashes together.

Local template archive SHA256 verified during preparation:

`f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`

The matching template ZIPs were extracted into the isolated build profile at `$env:TEMP\bunker07-release\appdata\Godot\export_templates\4.7.2.stable`. They are build tooling, never source commits. Keep the matching profile selected when exporting locally:

```powershell
$godotBin = 'C:\Users\jnobe\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$releaseDir = Join-Path $env:TEMP 'bunker07-release'
$env:APPDATA = Join-Path $releaseDir 'appdata'
python -m unittest discover -s tests -p test_web_build.py -v
python scripts/run_godot_tests.py --godot $godotBin --logs (Join-Path $releaseDir 'gated-tests')
python scripts/build_web.py --godot $godotBin --output (Join-Path $releaseDir 'site') --commit (git rev-parse HEAD)
python scripts/validate_web.py (Join-Path $releaseDir 'site') --commit (git rev-parse HEAD) --engine 4.7.2
python -m http.server 8765 --bind 127.0.0.1 --directory (Join-Path $releaseDir 'site')
```

Open http://127.0.0.1:8765/ in a WebGL 2 capable desktop browser; `file://` is unsupported. On Linux/macOS with matching templates installed, `scripts/build_web.sh "$PWD/work/site"` invokes the same Python build implementation. Set `GODOT_BIN` to override the executable. Outputs under `work/` or `_site/` and Python caches are ignored.

Builds require a full Git HEAD SHA and clean source. Only four known engine/test-generated import/result files are excluded from the source-dirty check; restore them after tests for a clean final working tree. Export is rejected when the editor version differs from the pin. The build imports with `--quit`, exports preset `Web`, stages classic assets, injects identity and validates the complete artifact. Do not label an uncommitted working tree as a released commit.

CI runs all 14 Phase 0 programs plus the two director suites using isolated writable application data; it fails on nonzero exit, script/assertion errors, unexpected engine errors or timeout. The known host certificate-store warning is recorded but does not fail offline tests. Tests and log evidence upload precede the Pages artifact. PR artifacts identify the tested synthetic merge commit; approved main builds identify the actual deployed main commit.

## Build identification and artifact checks

`build-info.json` contains the full source commit, actual engine version, edition `deep-signal-godot`, `threads:false`, committed-source marker, and byte sizes/SHA256 for `index.html`, `index.js`, `index.wasm`, `index.pck` and `classic.html`. The existing HTML menu footer links to it and shows the first 12 commit characters. The footer hides when pointer lock is active; there is no gameplay HUD addition.

`validate_web.py` rejects missing/empty or hash-mismatched files, incorrect SHA/engine, a classic root, threading, and invalid WASM/PCK headers. The Compatibility export remains single-threaded, without COOP/COEP requirements or external runtime services. The artifact has the Godot engine JS, WASM, packed resources and HTML entry point; classic assets remain available under their original relative paths.

## Verification record and limits

The release-preparation audit reran all 16 Godot programs: **328 passing assertions plus orderly-close smoke**, zero assertion failures. Captured mouse was explicitly skipped headlessly. The root certificate-store read error remains an environment diagnostic. Packaging tool tests passed **10/10** (complete build, stale SHA, wrong engine, missing WASM, corrupted assets, classic root, threaded flag, invalid source marker and WASM header cases).

Matching official templates are installed in the isolated build profile and checksum-verified. Exact committed-source export verification is pending the release tooling commit; no new public/browser success is asserted at this checkpoint.

Browser access host was unavailable when actual browser verification was attempted. No new public deployment has occurred during preparation. Do not infer title rendering, Deep Signal input/combat, restart behavior or console cleanliness in a browser from native tests/export/HTTP validation. These remain release checks after approval:

- Full SHA in live `build-info.json` matches the approved release commit.
- HTML/JS/WASM/PCK all return 200 and hashes match the manifest; WASM MIME is appropriate.
- Title exposes both operations; Deep Signal deploys with guards, movement, shooting, objectives and retry functional.
- Browser console has no critical errors; F5 is handled by the focused canvas; menu build marker is current.
- Classic remains reachable at `/classic.html`; audio/controls are manually checked.

Phase 2 AI behavior is not part of this release preparation. The known immediate sharing and hidden-camera hit reaction remain documented Phase 1 risks.
