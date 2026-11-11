# Reactive bunker art and audio

All added visuals in `src/bunker-art.js` and synthesized effects in `src/audio.js` are original project source. No external images, recordings, models, fonts or asset packs were imported; no external asset license is required.

## API

- Existing `Bunker07Art.bots`, textures, weapon and props remain available. Bots additionally have `stagger` frames.
- `Bunker07Art.roles.standard`, `.armored`, `.scout`, `.turret` each expose two-frame `idle`, `walk`, `attack`, `stagger` arrays. All are transparent 64×64 canvases with floor anchors.
- Added props: `camera`, `cameraOff`, `terminal`, `lampBroken`, `intel`, `crate`, `damagedRack`, `door`. Compatibility aliases: `brokenLamp` and `cache`.
- `Bunker07Art.effects.spark` and `.smoke` are transparent 64×64 canvases.
- Existing audio `fire`, `hit`, `reload` remain available. Added effect names: `detect`, `attack`, `impact`, `damage`, `use`, `alarm`, `step`, `servo`.
- `Bunker07Audio.positional(kind, pan, distance)` plays one effect, or call a named effect with `(pan, distance)`. Pan clamps to −1…1; world distance attenuates gain. Browsers without stereo panners use centered audio. `stopAll()` stops and disconnects active voices. Mute/master-volume changes affect already-playing tails immediately.

## Focused checks

- `node --check` passed for both files.
- Real headless Chrome loaded the art and verified all 32 role-state frames contain nontransparent pixels; all eight added named props resolve.
- A deterministic Web Audio graph mock verified two-tone detection playback, spatial pan clamping, live mute/master-volume changes, voice completion cleanup and immediate `stopAll()` disconnection. An initial cleanup check led to explicitly disconnecting oscillator/gain nodes immediately on stop, rather than waiting for their asynchronous ended callbacks.
- The integrated game loaded directly from disk in Chrome, rendered all 12 armored/scout/turret state combinations without page errors, and exercised impact/damage rendering plus a source-right pan value of +1. Device-hit feedback was independently reviewed; camera/lamp hits now invoke the shared impact hook.

These are focused component checks; browser gameplay integration is covered separately by the encounter harness. Spatial audio here is left/right panning with distance attenuation, not physical room acoustics or wall transmission simulation.
