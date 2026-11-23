#!/usr/bin/env python3
"""The city pack in the previews. tools/preview/dump.luau writes each pack object the map places as
a prim of shape "Pack" (its kit key, its frame and its stretch); `expand` turns those into
triangles with their own colours, read from the preview cache that scripts/citypack.py makes
(out/citypack/meshes.npz, never committed: the pack's meshes stay out of the repository).

Without the cache (a checkout without the pack) each pack object is drawn as the stand-in the game
uses when the kit isn't there: a box of its size in a plain colour by kind. A line says so.

    python3 tools/preview/citypack.py top <out.png> [--box x1,z1,x2,z2] [--px 2000] [--json scene.json]

draws a scene's pack objects (or, without --json, the whole pack where the pack puts it) from
straight above, quickly, with a grid every 100 studs: for laying out the map.
"""
import json
import math
import os
import re
import sys

import numpy as np

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
CACHE = os.path.join(ROOT, "out", "citypack", "meshes.npz")
MANIFEST = os.path.join(ROOT, "src", "shared", "Data", "CityPack.luau")

# the stand-ins' colours (Data/CityMap's StandIn colours, 0..1)
KIND_COLOURS = {
    "road": (0.42, 0.43, 0.46),
    "ground": (0.3, 0.51, 0.2),
    "building": (0.86, 0.84, 0.8),
    "nature": (0.36, 0.55, 0.3),
    "vehicle": (0.75, 0.42, 0.38),
    "prop": (0.7, 0.66, 0.6),
}

_cache = None
_said = False


def cache():
    """piece name -> (triangles n x 3 x 3 in the key's frame, colours n x 3 in 0..1), or None."""
    global _cache
    if _cache is None:
        if not os.path.exists(CACHE):
            _cache = {}
            return None
        z = np.load(CACHE)
        tri, col = z["tri"], z["col"]
        _cache = {}
        for name, s, n in zip(z["names"], z["starts"], z["counts"]):
            _cache[str(name)] = (tri[s:s + n].astype(np.float64), col[s:s + n].astype(np.float64) / 255)
    return _cache or None


def manifest():
    """The manifest as the converter wrote it: kit {key: (kind, [(piece, size, centre)])} and the
    placements [(key, x, y, z, yaw, rx, rz, sx, sy, sz)]."""
    src = open(MANIFEST).read()
    kit_block = src[src.index("CityPack.Kit = {"):src.index("CityPack.Placed = {")]
    placed_block = src[src.index("CityPack.Placed = {"):]
    flat = re.sub(r"\s+", " ", kit_block)
    kit = {}
    for m in re.finditer(r'(\w+) = \{ "(\w+)", ((?:\{ "\w+",[-\d., ]+\},? ?)+)\}', flat):
        pieces = []
        for name, nums in re.findall(r'\{ "(\w+)", ([-\d., ]+?),? \}', m.group(3)):
            v = [float(x) for x in nums.split(",")]
            pieces.append((name, np.array(v[0:3]), np.array(v[3:6])))
        kit[m.group(1)] = (m.group(2), pieces)
    placed = []
    for m in re.finditer(r'\{ "(\w+)", ([-\d., ]+?),? \}', re.sub(r"\s+", " ", placed_block)):
        v = [float(x) for x in m.group(2).split(",")]
        rx, rz = (v[4], v[5]) if len(v) >= 6 else (0.0, 0.0)
        sc = v[6:9] if len(v) >= 9 else [1.0, 1.0, 1.0]
        placed.append((m.group(1), v[0], v[1], v[2], v[3], rx, rz, *sc))
    return kit, placed


def ryxz(rx, ry, rz):
    """CFrame.fromEulerAnglesYXZ's rotation (radians)."""
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Ry @ Rx @ Rz


def box_tris(size, centre):
    """A box's twelve triangles round a centre (the stand-in)."""
    hx, hy, hz = np.asarray(size) / 2
    c = np.asarray(centre)
    v = np.array([[x, y, z] for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]) + c
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    out = []
    for a, b, cc, d in faces:
        out.append(v[[a, b, cc]])
        out.append(v[[a, cc, d]])
    return np.array(out)


def object_tris(key, rot, pos, scale, kit=None):
    """A placed pack object's triangles in the world and their colours."""
    c = cache()
    tris, cols = [], []
    pieces = None
    if c is not None:
        names = [n for n in c if n == key or n.startswith(key + "__")]
        if names:
            pieces = [c[n] for n in names]
    if pieces is None:
        if kit is None:
            kit = manifest()[0]
        kind, plist = kit.get(key, ("prop", []))
        col = np.array(KIND_COLOURS.get(kind, (0.7, 0.7, 0.7)))
        pieces = [(box_tris(size, centre), np.tile(col, (12, 1))) for _, size, centre in plist]
    for t, cc in pieces:
        w = (t * scale) @ rot.T + pos
        tris.append(w)
        cols.append(cc)
    if not tris:
        return np.zeros((0, 3, 3)), np.zeros((0, 3))
    return np.concatenate(tris), np.concatenate(cols)


def say_once():
    global _said
    if not _said and cache() is None:
        print("citypack: no preview cache (out/citypack/meshes.npz): the pack is drawn as stand-in boxes."
              " Run scripts/citypack.py on the pack to make it.")
    _said = True


def clip_tris(tris, cols, x1, z1, x2, z2):
    """The triangles cut to the rectangle x1..x2, z1..z2 (seen from above)."""
    xs, zs = tris[..., 0], tris[..., 2]
    inside = (xs.min(1) >= x1) & (xs.max(1) <= x2) & (zs.min(1) >= z1) & (zs.max(1) <= z2)
    outside = (xs.max(1) < x1) | (xs.min(1) > x2) | (zs.max(1) < z1) | (zs.min(1) > z2)
    out_t, out_c = [tris[inside]], [cols[inside]]
    for i in np.nonzero(~inside & ~outside)[0]:
        poly = list(tris[i])
        for axis, bound, keep_hi in ((0, x1, True), (0, x2, False), (2, z1, True), (2, z2, False)):
            res = []
            for j in range(len(poly)):
                a, b = poly[j], poly[(j + 1) % len(poly)]
                ina = a[axis] >= bound if keep_hi else a[axis] <= bound
                inb = b[axis] >= bound if keep_hi else b[axis] <= bound
                if ina:
                    res.append(a)
                if ina != inb:
                    t = (bound - a[axis]) / (b[axis] - a[axis])
                    res.append(a + (b - a) * t)
            poly = res
            if len(poly) < 3:
                break
        for j in range(1, len(poly) - 1):
            out_t.append(np.array([[poly[0], poly[j], poly[j + 1]]]))
            out_c.append(cols[i:i + 1])
    return np.concatenate(out_t), np.concatenate(out_c)


def expand(prims, size=None, eye=None, focal=None, far=None):
    """Turns the "Pack" prims of a dumped scene into "Tris" prims, one per object and colour, that
    tools/preview/render.py's prim_tris draws as they are. Triangles too small to see are left out:
    with `size` (the picture's width in pixels) by the scene's span, with `eye` and `focal` by
    their distance from the camera, and nothing past `far`."""
    pack = [p for p in prims if p.get("shape") == "Pack"]
    if not pack:
        return prims
    say_once()
    # a "Clip" prim (dump.luau's map:x1,z1,x2,z2) keeps only the triangles over that part of town
    clip = None
    for p in prims:
        if p.get("shape") == "Clip":
            c, sz = np.array(p["cf"][0:3]), np.array(p["size"])
            clip = (c - sz / 2, c + sz / 2)
    out = [p for p in prims if p.get("shape") not in ("Pack", "Clip")]
    px = None
    if size:
        pts = np.array([p["cf"][0:3] for p in prims])
        span = max(np.ptp(pts[:, 0]), np.ptp(pts[:, 2]), 1.0) * 1.15
        px = span / float(size)  # studs a pixel, about
    kit = manifest()[0]
    for p in pack:
        c = p["cf"]
        pos = np.array(c[0:3])
        if eye is not None and far is not None:
            if np.linalg.norm(pos - eye) - np.linalg.norm(p["size"]) / 2 > far:
                continue
        rot = np.array([[c[3], c[4], c[5]], [c[6], c[7], c[8]], [c[9], c[10], c[11]]])
        tris, cols = object_tris(p["key"], rot, pos, np.array(p.get("scale", [1, 1, 1])), kit)
        if len(tris) == 0:
            continue
        if clip is not None:
            tris, cols = clip_tris(tris, cols, clip[0][0], clip[0][2], clip[1][0], clip[1][2])
            if len(tris) == 0:
                continue
        edge = np.linalg.norm(tris[:, 1] - tris[:, 0], axis=1) + np.linalg.norm(tris[:, 2] - tris[:, 0], axis=1)
        keep = np.ones(len(tris), bool)
        if px is not None:
            keep &= edge > px * 0.5
        if eye is not None and focal is not None:
            dist = np.linalg.norm(tris.mean(1) - eye, axis=1)
            keep &= edge * focal / np.maximum(dist, 1.0) > 0.5
        tris, cols = tris[keep], cols[keep]
        if len(tris) == 0:
            continue
        q = np.round(cols * 64).astype(int)
        groups = {}
        for i, k in enumerate(map(tuple, q)):
            groups.setdefault(k, []).append(i)
        for ix in groups.values():
            t = tris[ix]
            lo, hi = t.reshape(-1, 3).min(0), t.reshape(-1, 3).max(0)
            out.append({
                "shape": "Tris",
                "tris": list(t),
                "cf": list((lo + hi) / 2) + [1, 0, 0, 0, 1, 0, 0, 0, 1],
                "size": list(hi - lo),
                "color": list(cols[ix[0]]),
                "transp": p.get("transp", 0),
                "mat": None,
                "pack": p["key"],
            })
    return out


def top(out_png, box=None, px=2000, scene=None):
    """A quick drawing from straight above (painter's order), with a grid every 100 studs."""
    from PIL import Image, ImageDraw

    kit, placed = manifest()
    objs = []
    if scene:
        for p in json.load(open(scene)):
            if p.get("shape") == "Pack":
                c = p["cf"]
                rot = np.array([[c[3], c[4], c[5]], [c[6], c[7], c[8]], [c[9], c[10], c[11]]])
                objs.append((p["key"], rot, np.array(c[0:3]), np.array(p.get("scale", [1, 1, 1]))))
    else:
        for key, x, y, z, yaw, rx, rz, sx, sy, sz in placed:
            rot = ryxz(math.radians(rx), math.radians(yaw), math.radians(rz))
            objs.append((key, rot, np.array([x, y, z]), np.array([sx, sy, sz])))
    L = np.array([-0.45, 0.85, 0.3]); L /= np.linalg.norm(L)
    T, C = [], []
    for key, rot, pos, sc in objs:
        t, c = object_tris(key, rot, pos, sc, kit)
        T.append(t); C.append(c)
    T = np.concatenate(T); C = np.concatenate(C)
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    C = C * (0.55 + 0.45 * np.clip(np.abs(n @ L), 0, 1))[:, None]
    if box:
        x1, z1, x2, z2 = box
    else:
        x1, z1 = T[..., 0].min(), T[..., 2].min()
        x2, z2 = T[..., 0].max(), T[..., 2].max()
    keep = (T[..., 0].max(1) >= x1) & (T[..., 0].min(1) <= x2) & (T[..., 2].max(1) >= z1) & (T[..., 2].min(1) <= z2)
    T, C = T[keep], C[keep]
    s = px / max(x2 - x1, z2 - z1)
    img = Image.new("RGB", (int((x2 - x1) * s) + 1, int((z2 - z1) * s) + 1), (60, 104, 140))
    dr = ImageDraw.Draw(img)
    X = (T[..., 0] - x1) * s
    Y = (T[..., 2] - z1) * s
    col = (np.clip(C, 0, 1) * 255).astype(np.uint8)
    for i in np.argsort(T[..., 1].mean(1)):
        dr.polygon([(X[i, 0], Y[i, 0]), (X[i, 1], Y[i, 1]), (X[i, 2], Y[i, 2])], fill=tuple(col[i]))
    step = 100
    for gx in range(int(math.ceil(x1 / step)) * step, int(x2) + 1, step):
        dr.line([((gx - x1) * s, 0), ((gx - x1) * s, img.size[1])], fill=(255, 255, 255) if gx else (255, 60, 60))
        dr.text(((gx - x1) * s + 2, 2), str(gx), fill=(255, 255, 255))
    for gz in range(int(math.ceil(z1 / step)) * step, int(z2) + 1, step):
        dr.line([(0, (gz - z1) * s), (img.size[0], (gz - z1) * s)], fill=(255, 255, 255) if gz else (255, 60, 60))
        dr.text((2, (gz - z1) * s + 2), str(gz), fill=(255, 255, 255))
    img.save(out_png)
    print("wrote", out_png, img.size, f"{1 / s:.2f} studs a pixel")


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["top"])
    ap.add_argument("out")
    ap.add_argument("--box", default=None)
    ap.add_argument("--px", type=int, default=2000)
    ap.add_argument("--json", default=None, help="a dumped scene; without it, the pack where the pack puts it")
    a = ap.parse_args()
    top(a.out, [float(v) for v in a.box.split(",")] if a.box else None, a.px, a.json)
    sys.exit(0)
