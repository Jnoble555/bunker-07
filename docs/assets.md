# Asset provenance and API

All textures, decorative props, robot animation frames, and the weapon in `src/bunker-art.js` are original procedural Canvas 2D drawings created for this project. No downloaded images, fonts, models, texture packs, or third-party artwork are used. There are no external asset license obligations. These drawings are delivered as original project source and can be modified with the project.

The direction is a late-industrial civil-defense bunker: pitted gray-olive concrete, charcoal steel, worn ochre safety bands, warm service lamps, and restrained green-cyan CRTs. Robot and weapon metal share that palette. Readable rectangular silhouettes and hard pixel edges suit the existing low-resolution renderer.

Load `src/bunker-art.js` before the main game script. It publishes `window.Bunker07Art`:

- `textures.concrete`, `steel`, `panel`, `floor`, `ceiling`: opaque 64×64 repeatable texture canvases.
- `props.console`, `rack`, `barrel`, `lamp`: transparent 64×64 billboard canvases; bottom edge is the floor anchor.
- `bots.idle`, `bots.walk`, `bots.attack`: arrays of two transparent 64×64 frames. Feet sit at the bottom edge. Select animation from actual movement or windup state; idle is a small mechanical head shift, walking alternates leg extension, and attack raises arms and flashes the weapon.
- `weapon`: transparent 160×110 first-person weapon and gloved-arm artwork. Draw at integer scale with smoothing disabled; retain the game's recoil/reload transforms.

The seeded texture generator gives reproducible pixels on every load. All assets are built once, then cached as canvases. Transparent billboards require the renderer's per-column depth test. These are flat sprites, with no implied dynamic geometry or real shadows.
