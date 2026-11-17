"""Original deterministic PBR surface recipes. Run with Python + numpy + Pillow."""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'godot/assets/control-room'
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 512
rng = np.random.default_rng(707)
y, x = np.mgrid[:SIZE, :SIZE] / SIZE

def noise(grid):
    small = Image.fromarray(rng.integers(0, 256, (grid, grid), dtype=np.uint8))
    return np.asarray(small.resize((SIZE, SIZE), Image.Resampling.BICUBIC)) / 255 - .5

def save(name, color, roughness, height):
    Image.fromarray(np.uint8(np.clip(color, 0, 255))).save(OUT / f'{name}_albedo.png')
    Image.fromarray(np.uint8(np.clip(roughness * 255, 0, 255))).save(OUT / f'{name}_roughness.png')
    # Periodic derivatives yield tangent normals; material disables height displacement.
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 8
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 8
    normals = np.stack([-dx, -dy, np.ones_like(height)], -1)
    normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
    Image.fromarray(np.uint8((normals * .5 + .5) * 255)).save(OUT / f'{name}_normal.png')

coarse, fine, grain = noise(12), noise(90), noise(512)
pores = (grain < -.47).astype(float)
tone = coarse * 13 + fine * 7 + grain * 3 - pores * 12
save('concrete', np.array([151, 156, 151]) + tone[..., None],
     .86 + fine * .08, fine * .10 + grain * .025 - pores * .05)

fine, grain = noise(70), noise(512)
scratches = ((np.sin(x * 700) > .995) & (grain > .2)).astype(float)
tone = fine * 6 + grain * 2 + scratches * 12
save('enamel', np.array([49, 68, 76]) + tone[..., None],
     .47 + fine * .12 + scratches * .15, fine * .025 + scratches * .025)

grain = noise(512)
edge = np.minimum.reduce([x, y, 1 - x, 1 - y])
joint = (edge < .012).astype(float)
bevel = np.clip((edge - .012) / .012, 0, 1)
screws = np.zeros_like(x)
for sx in [.06, .94]:
    for sy in [.06, .94]:
        screws += (((x-sx)**2 + (y-sy)**2) < .00013)
tread = ((np.sin((x+y)*np.pi*32) > .87) & (edge > .04)).astype(float)
tone = grain * 6 - joint * 26 - screws * 15 + tread * 5
save('floor', np.array([64, 72, 76]) + tone[..., None],
     .62 + grain * .07 + tread * .10, bevel * .09 - screws * .07 + tread * .018)
print('Generated nine original 512px PBR maps:', OUT)
