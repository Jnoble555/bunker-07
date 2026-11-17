# Bunker service-panel kit and original materials

Original project work for the Deep Signal visual benchmark. The kit was initially named for Control Room and was made reusable when Deep Signal became the requested showcase. No external art, textures, fonts or recordings were downloaded; there are no new external asset-license dependencies.

- Editable source: `control_room_kit.blend`, Blender **5.3.0**.
- Geometry source: `generate.py`; exports `godot/assets/control-room/control_room_kit.glb`.
- Surface source: `generate_materials.py`, Python with **numpy 2.4.0 / Pillow 12.1.0** in the executed environment.
- Nine original 512×512 PNGs: albedo, tangent-space normal and roughness for concrete, enamel and anti-slip floor plating. Material code provides metallic values. No displacement or collision comes from these maps.
- Four module roots: WallPanel, VentPanel, CeilingTray and PracticalLamp. Geometry includes bevels, panel joints, kick plates, fasteners, louver blades, cable rails and protected light housings.

Regenerate from the repo root:

```powershell
python assets/source/control-room-kit/generate_materials.py
& 'C:/Program Files/Blender Foundation/Blender 5.3/blender.exe' --background --python assets/source/control-room-kit/generate.py
```

The `.blend` remains editable; GLB exports evaluated bevels/normals. Blender Z is up and -Y faces into a room, becoming Godot +Z. Module origins sit on the wall/floor reference. Wall details project at most approximately 8 cm at vents; they add no colliders and must remain shallow visual relief, rather than navigable cover.

Runtime `control_room_art.gd` batches repeated parts as MultiMeshes, applies world-space PBR materials and preserves existing physical geometry. This component supports the original grid-room contract and Deep Signal's authored solid-bounds contract; Iron Relay's separate level contract has not been integrated or tested here.
