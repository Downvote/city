#!/usr/bin/env python3
"""A sketch of the mist that placed fog machines and mist bowls give off, laid over a picture
tools/preview/walk.py drew (with --depth, so the mist sits behind what stands in front of it).
The previews draw no particles; this is Data/Effects' fog (puffs out of a fog machine's nozzle
that grow, slow and sink), fogbank (a low flat bank round its feet) and mist (a mist bowl's slow
puffs), as soft blobs of the sizes and reach those lines give, a sketch and not what Roblox draws.

    python3 tools/preview/mist.py <picture.png> <depth.npy> <mist.json> <out.png>
        --eye x,y,z --look x,y,z [--fov 60] [--seed 3]

<mist.json> lists the pieces: [{"kind": "fog" | "mist", "at": [x, y, z], "r": turn}], in the
same space as the scene (tools/preview/temple_town.luau writes one beside its plan).
"""
import argparse
import json
import math

import numpy as np
from PIL import Image


def vec(text):
    return np.array([float(v) for v in text.split(",")])


def puffs_of(e, rng):
    """Where one piece's puffs are a moment into its run: (centre, radius, strength, flatness)."""
    at = np.array(e["at"], float)
    a = math.radians(e.get("r", 0))
    ahead = np.array([math.sin(a), 0.0, math.cos(a)])
    side = np.array([ahead[2], 0.0, -ahead[0]])
    out = []
    if e["kind"] == "fog":
        # out of the nozzle at 5 to 7 a second, slowed hard by the air and sinking, growing from
        # 1 to 7 across over five to seven seconds; a low bank 4 to 9 across round the machine
        for _ in range(34):
            t = rng.random()
            reach = 1.5 + 9.0 * (1 - (1 - t) ** 2) + rng.normal(0, 1.2)
            c = at + ahead * reach + side * rng.normal(0, 0.9 + 2.2 * t)
            c[1] = 0.6 + 1.4 * (1 - t) + rng.random() * 1.6
            out.append((c, 0.6 + 3.2 * t, 0.26 * (1 - 0.55 * t), 0.75))
        for _ in range(14):
            c = at + ahead * rng.normal(1.5, 2.0) + side * rng.normal(0, 2.4)
            c[1] = 0.4 + rng.random() * 0.8
            out.append((c, 2.2 + rng.random() * 2.4, 0.2, 0.45))
    else:
        # a mist bowl: a few slow puffs over the water, 1 to 4 across, drifting down
        for _ in range(10):
            c = at + side * rng.normal(0, 0.8) + ahead * rng.normal(0, 0.8)
            c[1] = at[1] + 1.0 + rng.random() * 0.8
            out.append((c, 0.6 + rng.random() * 1.4, 0.2, 0.7))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("picture")
    ap.add_argument("depth")
    ap.add_argument("mist")
    ap.add_argument("out")
    ap.add_argument("--eye", required=True)
    ap.add_argument("--look", required=True)
    ap.add_argument("--fov", type=float, default=60)
    ap.add_argument("--seed", type=int, default=3)
    args = ap.parse_args()
    img = np.asarray(Image.open(args.picture).convert("RGB"), float) / 255
    zbuf = np.load(args.depth)
    H, W = zbuf.shape
    eye, look = vec(args.eye), vec(args.look)
    fwd = look - eye
    fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    focal = (H / 2) / math.tan(math.radians(args.fov) / 2)
    rng = np.random.default_rng(args.seed)
    color = np.array([0.93, 0.95, 0.96])
    cover = np.zeros((H, W))
    for e in json.load(open(args.mist)):
        for c, rad, strength, flat in puffs_of(e, rng):
            d = c - eye
            z = d @ fwd
            if z < 1:
                continue
            px = W / 2 + focal * (d @ right) / z
            py = H / 2 - focal * (d @ up) / z
            rx = focal * rad / z
            ry = rx * flat
            x0, x1 = int(max(0, px - 2 * rx)), int(min(W, px + 2 * rx + 1))
            y0, y1 = int(max(0, py - 2 * ry)), int(min(H, py + 2 * ry + 1))
            if x1 <= x0 or y1 <= y0:
                continue
            xs, ys = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
            q = ((xs - px) / max(rx, 1e-3)) ** 2 + ((ys - py) / max(ry, 1e-3)) ** 2
            a = strength * np.exp(-2.2 * q)
            # behind what stands in front of it, softly where it meets a surface
            seen = np.clip((zbuf[y0:y1, x0:x1] - (z - rad)) / (2 * rad), 0, 1)
            a = a * seen
            region = cover[y0:y1, x0:x1]
            cover[y0:y1, x0:x1] = 1 - (1 - region) * (1 - a)
    out = img * (1 - cover[..., None]) + color[None, None, :] * cover[..., None]
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
