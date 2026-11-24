#!/usr/bin/env python3
"""Draws the primitives dumped by tools/preview/dump.luau into a PNG.

    python3 tools/preview/render.py in.json out.png [--yaw 35] [--pitch 30] [--size 900]

A small z-buffered rasteriser: boxes, wedges, cylinders and balls, flat shaded with light from
the top left, an orthographic camera fitted to the scene. Good enough to see whether a model
looks the way its recipe meant.

--textures paints each part with the texture the game gives its material (Data/TextureIds: the
Creator Store pictures, fetched once into out/library), tinted by the part's colour and tiled in
the part's own space along the face's main axis, the way Roblox lays a MaterialVariant on a part.
The part's colour is first changed as the game changes it (Textures.shade: lifted under a picture
with its own colour, brightened under a dark one).
--painted uses our own painted set in art/textures instead (scripts/gen_textures.py).

The picture is lit and graded as the game lights and grades it (tools/preview/look.py, from the
numbers in Tuning.Look): the sun's strength and colour, the violet shade, the tone map and the
colour correction for the hour (--hour, 13 by default). The light still comes from the top left
so a model reads well. --no-grade leaves the colour correction off, --plain draws the old flat
preview (no light model, no grade): neither is what a player sees.

A part whose material names a look ("Concrete:Panel", Data/Textures) wears the look's picture at
the look's studs per tile: with --textures its Creator Store picture, with --painted the one in
art/textures. A look with no id in Data/TextureIds shows its material's picture under --textures,
as the game would, or with --textures --painted together our painted one.
"""
import argparse
import json
import math

import os
import sys
import urllib.request

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import look as game_look  # noqa: E402  (the game's light and grade)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
TEX_DIR = os.path.join(ROOT, "art", "textures")
LIB_DIR = os.path.join(ROOT, "out", "library")
LIFT = 0.72  # Textures.Lift: how far a part's colour moves to white on a texture with its own colour
LEVEL = 0.8  # Textures.Level: how light a texture is taken to be; paint on a darker one is brightened


def shade_paint(color, own, light):
    """Textures.shade: the colour a part is given under a texture that brings its own colour, or
    under one that is darker than the rest."""
    color = np.array(color, float)
    if own:
        return color * (1 - LIFT) + LIFT
    if light and light < LEVEL:
        gain = min(LEVEL / light, 1 / max(color.max(), 1e-3))
        if gain > 1:
            return color * gain
    return color


def fetch_image(image_id):
    """An image asset's picture (its 420 px thumbnail), cached under out/library. None while Roblox
    is still making the thumbnail, and when it only has a placeholder to show: an image that is
    private or was taken down, which would not load in the game either."""
    path = os.path.join(LIB_DIR, f"{image_id}.png")
    if not os.path.exists(path):
        os.makedirs(LIB_DIR, exist_ok=True)
        ua = {"User-Agent": "preview"}
        url = f"https://thumbnails.roblox.com/v1/assets?assetIds={image_id}&size=420x420&format=Png"
        info = json.load(urllib.request.urlopen(urllib.request.Request(url, headers=ua), timeout=30))["data"][0]
        if info.get("state") != "Completed":
            print(f"image {image_id}: its thumbnail is not ready yet, run again")
            return None
        if "/Image/" not in info.get("imageUrl", ""):
            print(f"image {image_id}: Roblox shows no picture for it (private or taken down)")
            return None
        data = urllib.request.urlopen(urllib.request.Request(info["imageUrl"], headers=ua), timeout=30).read()
        open(path, "wb").write(data)
    return path


class Textures:
    """Textures by Roblox material, and the looks by "<material>:<look>", each as a small mip
    pyramid (float RGB), its studs per tile, whether it brings its own colour and how light it is
    said to be (Data/TextureIds' `light`)."""

    def __init__(self, painted=False, library=True):
        self.by_mat = {}
        index_path = os.path.join(TEX_DIR, "textures.json")
        if not os.path.exists(index_path):
            return
        index = json.load(open(index_path))
        ids = {}
        if library:
            sys.path.insert(0, os.path.join(ROOT, "scripts"))
            import sync_materials
            ids = sync_materials.read_ids()
        for name, info in index.items():
            look = info.get("look")
            studs, own, light, path = info["studs"], False, None, None
            got = ids.get(name)
            if got and "color" in got:
                try:
                    path = fetch_image(got["color"].split("//")[1])
                except Exception as e:
                    print("no picture for", name, e)
                studs, own, light = got.get("studs", studs), got.get("own", False), got.get("light")
            elif painted and (look or not library):
                path = os.path.join(TEX_DIR, name + ".png")
            if not path or not os.path.exists(path):
                continue
            im = Image.open(path).convert("RGB")
            levels = []
            while min(im.width, im.height) >= 4:
                levels.append(np.asarray(im, float) / 255)
                im = im.resize((im.width // 2, im.height // 2), Image.BOX)
            self.by_mat[info["material"] + ":" + look if look else info["material"]] = (levels, studs, own, light)

    def key(self, mat):
        """What a part of this material is painted with: its look's picture, else its material's
        (a look with no picture shows the material), else None."""
        if not mat:
            return None
        if mat in self.by_mat:
            return mat
        base = mat.split(":")[0]
        return base if base in self.by_mat else None

    def sample(self, mat, u, v, px_per_stud):
        """Colours at stud coordinates u, v (arrays), picking the mip level for the zoom."""
        entry = self.by_mat.get(mat)
        if entry is None:
            return None
        levels, studs = entry[0], entry[1]
        texels_per_px = levels[0].shape[0] / studs / max(1e-6, px_per_stud)
        lv = int(np.clip(math.floor(math.log2(max(1.0, texels_per_px))), 0, len(levels) - 1))
        tex = levels[lv]
        ny, nx = tex.shape[0], tex.shape[1]  # a picture that isn't square is stretched over the tile
        x = (np.floor(u / studs * nx).astype(int)) % nx
        y = (np.floor(v / studs * ny).astype(int)) % ny
        return tex[y, x]


def box_tris():
    # unit box corners -0.5..0.5
    c = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    idx = lambda x, y, z: (x > 0) * 4 + (y > 0) * 2 + (z > 0)
    faces = [
        [(-1, -1, -1), (-1, 1, -1), (-1, 1, 1), (-1, -1, 1)],
        [(1, -1, -1), (1, -1, 1), (1, 1, 1), (1, 1, -1)],
        [(-1, -1, -1), (-1, -1, 1), (1, -1, 1), (1, -1, -1)],
        [(-1, 1, -1), (1, 1, -1), (1, 1, 1), (-1, 1, 1)],
        [(-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1)],
        [(-1, -1, 1), (-1, 1, 1), (1, 1, 1), (1, -1, 1)],
    ]
    tris = []
    for f in faces:
        p = [np.array(v) * 0.5 for v in f]
        tris.append((p[0], p[1], p[2]))
        tris.append((p[0], p[2], p[3]))
    return [np.array(t, dtype=float) for t in tris]


def wedge_tris():
    # Roblox wedge: full height at +Z, sloping to the bottom front edge at -Z
    A = np.array([-0.5, -0.5, -0.5])
    B = np.array([0.5, -0.5, -0.5])
    Cc = np.array([0.5, -0.5, 0.5])
    D = np.array([-0.5, -0.5, 0.5])
    E = np.array([-0.5, 0.5, 0.5])
    F = np.array([0.5, 0.5, 0.5])
    tris = [
        (A, B, Cc), (A, Cc, D),  # bottom
        (D, Cc, F), (D, F, E),  # back
        (A, E, F), (A, F, B),  # slope
        (A, D, E),  # left side
        (B, F, Cc),  # right side
    ]
    return [np.array(t, dtype=float) for t in tris]


def cylinder_tris(n=16):
    # along X, radius 0.5, length 1
    tris = []
    for i in range(n):
        a1 = 2 * math.pi * i / n
        a2 = 2 * math.pi * (i + 1) / n
        p1 = (math.cos(a1) * 0.5, math.sin(a1) * 0.5)
        p2 = (math.cos(a2) * 0.5, math.sin(a2) * 0.5)
        l = np.array([-0.5, p1[0], p1[1]]); l2 = np.array([-0.5, p2[0], p2[1]])
        r = np.array([0.5, p1[0], p1[1]]); r2 = np.array([0.5, p2[0], p2[1]])
        tris.append(np.array([l, r, r2])); tris.append(np.array([l, r2, l2]))
        tris.append(np.array([[-0.5, 0, 0], l2, l])); tris.append(np.array([[0.5, 0, 0], r, r2]))
    return tris


def ball_tris(n=10, m=8):
    tris = []
    def pt(i, j):
        th = math.pi * j / m
        ph = 2 * math.pi * i / n
        return np.array([math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)]) * 0.5
    for i in range(n):
        for j in range(m):
            a, b, c, d = pt(i, j), pt(i + 1, j), pt(i + 1, j + 1), pt(i, j + 1)
            tris.append(np.array([a, b, c])); tris.append(np.array([a, c, d]))
    return tris


def polytope_tris(planes):
    """Triangles of the convex shape { p : n.p <= d for every (n, d) }: the low poly kit's shapes
    (Build/LowPoly) are all cut this way, so the preview draws exactly what the game does."""
    planes = [(np.array(n, float) / np.linalg.norm(n), d / np.linalg.norm(n)) for n, d in planes]
    verts = []
    m = len(planes)
    for i in range(m):
        for j in range(i + 1, m):
            for k in range(j + 1, m):
                A = np.array([planes[i][0], planes[j][0], planes[k][0]])
                if abs(np.linalg.det(A)) < 1e-9:
                    continue
                v = np.linalg.solve(A, np.array([planes[i][1], planes[j][1], planes[k][1]]))
                if all(n @ v <= d + 1e-7 for n, d in planes):
                    if not any(np.linalg.norm(v - w) < 1e-6 for w in verts):
                        verts.append(v)
    tris = []
    for n, d in planes:
        face = [v for v in verts if abs(n @ v - d) < 1e-6]
        if len(face) < 3:
            continue
        c = np.mean(face, axis=0)
        u = face[0] - c
        u /= np.linalg.norm(u)
        w = np.cross(n, u)
        face.sort(key=lambda v: math.atan2((v - c) @ w, (v - c) @ u))
        for i in range(1, len(face) - 1):
            tris.append(np.array([face[0], face[i], face[i + 1]]))
    return tris


def gem_tris():
    planes = []
    for a in range(3):
        for sgn in (-1, 1):
            n = [0, 0, 0]; n[a] = sgn
            planes.append((n, 0.5))
    for a, b in ((0, 1), (0, 2), (1, 2)):
        for s1 in (-1, 1):
            for s2 in (-1, 1):
                n = [0, 0, 0]; n[a] = s1; n[b] = s2
                planes.append((n, 0.5 * math.sqrt(2)))
    return polytope_tris(planes)


def prism_tris(sides):
    planes = [((1, 0, 0), 0.5), ((-1, 0, 0), 0.5)]
    for i in range(sides):
        a = 2 * math.pi * i / sides
        planes.append(((0, math.cos(a), math.sin(a)), 0.5))
    return polytope_tris(planes)


def cone_tris(sides=8):
    planes = [((0, -1, 0), 0.5)]
    for i in range(sides):
        a = 2 * math.pi * i / sides
        # y <= 0.5 - 2 (u.p): the slope from the base's edge to the tip
        planes.append(((2 * math.cos(a), 1, 2 * math.sin(a)), 0.5))
    return polytope_tris(planes)


# Balls, cylinders and cones are drawn with the low poly kit's shapes, as the game draws them
# (pass --smooth to see Roblox's own, which the game falls back to without the kit).
SHAPES = {"Block": box_tris(), "Wedge": wedge_tris(), "Cylinder": cylinder_tris(), "Ball": ball_tris()}
KIT = {"Gem": gem_tris(), "Prism": prism_tris(8), "Disc": prism_tris(16), "Cone": cone_tris()}
USE_KIT = True
DISC_FROM = 9


def gem_turn(pos):
    """The turn Build/LowPoly gives a gem at `pos` (CFrame.Angles(a, b, c) = Rx(a) Ry(b) Rz(c))."""
    h = abs(pos[0] * 12.9898 + pos[1] * 78.233 + pos[2] * 37.719)
    a, b, c = (h % 1) * 2 * math.pi, ((h * 1.618) % 1) * 2 * math.pi, ((h * 2.414) % 1) * 2 * math.pi
    rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    ry = np.array([[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]])
    rz = np.array([[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]])
    return rx @ ry @ rz


def prim_tris(p):
    c = p["cf"]
    pos = np.array(c[0:3])
    rot = np.array([[c[3], c[4], c[5]], [c[6], c[7], c[8]], [c[9], c[10], c[11]]])
    size = np.array(p["size"])
    base = SHAPES.get(p["shape"], SHAPES["Block"])
    if USE_KIT:
        if p["shape"] == "Ball":
            base = KIT["Gem"]
            if size[0] == size[1] == size[2]:
                rot = rot @ gem_turn(p.get("local", pos))
        elif p["shape"] == "Cylinder":
            base = KIT["Disc"] if max(size[1], size[2]) >= DISC_FROM else KIT["Prism"]
        elif p["shape"] == "Cone":
            base = KIT["Cone"]
    elif p["shape"] == "Cone":
        base = SHAPES["Cylinder"]
        rot = rot @ np.array([[0, -1, 0], [1, 0, 0], [0, 0, 1]])
        size = np.array([size[1], size[0], size[2]])
    out = []
    for t in base:
        v = (t * size) @ rot.T + pos
        out.append(v)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--yaw", type=float, default=35)
    ap.add_argument("--pitch", type=float, default=32)
    ap.add_argument("--size", type=int, default=900)
    ap.add_argument("--hide-clear", action="store_true", help="skip invisible parts (default)")
    ap.add_argument("--transparent", action="store_true", help="no background (for thumbnails)")
    ap.add_argument("--smooth", action="store_true", help="Roblox's own balls and cylinders, not the low poly kit")
    ap.add_argument("--textures", action="store_true", help="paint parts with the game's textures")
    ap.add_argument("--painted", action="store_true", help="paint parts with our painted art/textures "
                    "(with --textures: only the looks that have no id yet)")
    ap.add_argument("--hour", type=float, default=13, help="the game's hour whose light and grade to show")
    ap.add_argument("--no-grade", action="store_true", help="leave off the game's colour correction")
    ap.add_argument("--plain", action="store_true", help="the old flat shading, no light model and no grade")
    args = ap.parse_args()
    global USE_KIT
    USE_KIT = not args.smooth

    prims = json.load(open(args.inp))
    yaw = math.radians(args.yaw)
    pitch = math.radians(args.pitch)
    # camera looks from +x+z, down at the pitch
    forward = np.array([-math.sin(yaw) * math.cos(pitch), -math.sin(pitch), -math.cos(yaw) * math.cos(pitch)])
    right = np.cross(forward, [0, 1, 0]); right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    light = np.array([-0.45, 0.85, 0.3]); light /= np.linalg.norm(light)
    game = None if args.plain else game_look.Light(game_look.load(), args.hour)

    textures = Textures(painted=args.painted, library=args.textures) if (args.textures or args.painted) else None
    tris, cols, alphas, owners = [], [], [], []
    for pi, p in enumerate(prims):
        if p.get("transp", 0) >= 0.99:
            continue
        for t in prim_tris(p):
            tris.append(t)
            cols.append(p["color"])
            alphas.append(1 - p.get("transp", 0))
            owners.append(pi)
    if not tris:
        print("nothing to draw")
        return
    T = np.array(tris)  # n x 3 x 3
    flat = T.reshape(-1, 3)
    sx = flat @ right
    sy = flat @ up
    pad = 0.06
    minx, maxx, miny, maxy = sx.min(), sx.max(), sy.min(), sy.max()
    span = max(maxx - minx, maxy - miny) * (1 + 2 * pad)
    W = H = args.size
    scale = W / span
    cx, cy = (minx + maxx) / 2, (miny + maxy) / 2

    img = np.zeros((H, W, 3)); img[:] = (0.86, 0.9, 0.95)
    zbuf = np.full((H, W), np.inf)
    # opaque first, then glass on top blended
    order = sorted(range(len(T)), key=lambda i: alphas[i] < 1)
    for i in order:
        t = T[i]
        n = np.cross(t[1] - t[0], t[2] - t[0])
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            continue
        n /= ln
        if n @ forward > 0:
            n = -n
        if game is None:
            shade = 0.55 + 0.45 * max(0, n @ light)
            col = np.array(cols[i]) * shade
        else:
            irr = game.irradiance(n, 1.0, toward=light)
            col = game.shade(np.array(cols[i])[None, :], irr)[0]
        px = (t @ right - cx) * scale + W / 2
        py = H / 2 - (t @ up - cy) * scale
        pz = t @ forward
        x0, x1 = int(max(0, math.floor(px.min()))), int(min(W - 1, math.ceil(px.max())))
        y0, y1 = int(max(0, math.floor(py.min()))), int(min(H - 1, math.ceil(py.max())))
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (qx, qy) = zip(px, py)
        den = (by - qy) * (ax - qx) + (qx - bx) * (ay - qy)
        if abs(den) < 1e-9:
            continue
        w1 = ((by - qy) * (xs - qx) + (qx - bx) * (ys - qy)) / den
        w2 = ((qy - ay) * (xs - qx) + (ax - qx) * (ys - qy)) / den
        w3 = 1 - w1 - w2
        inside = (w1 >= -1e-6) & (w2 >= -1e-6) & (w3 >= -1e-6)
        if not inside.any():
            continue
        z = w1 * pz[0] + w2 * pz[1] + w3 * pz[2]
        region = zbuf[y0:y1 + 1, x0:x1 + 1]
        closer = inside & (z < region - 1e-4)
        if textures is not None and closer.any():
            p = prims[owners[i]]
            key = textures.key(p.get("mat"))
            if key is not None:
                # the pixel's place in the part's own space, from the corner, in studs
                c = p["cf"]
                ppos = np.array(c[0:3])
                rot = np.array([[c[3], c[4], c[5]], [c[6], c[7], c[8]], [c[9], c[10], c[11]]])
                half = np.array(p["size"]) / 2
                local = (t - ppos) @ rot + half  # the triangle's corners
                a1, a2, a3 = w1[closer], w2[closer], w3[closer]
                lp = a1[:, None] * local[0] + a2[:, None] * local[1] + a3[:, None] * local[2]
                nl = n @ rot  # the face's normal in the part's own space
                axis = int(np.argmax(np.abs(nl)))
                # a side face reads left to right for whoever stands in front of it, so the light
                # painted into a picture stays at its top left on every wall
                if axis == 0:
                    u, v = (-lp[:, 2] if nl[0] > 0 else lp[:, 2]), -lp[:, 1]
                elif axis == 1:
                    u, v = lp[:, 0], lp[:, 2]
                else:
                    u, v = (lp[:, 0] if nl[2] > 0 else -lp[:, 0]), -lp[:, 1]
                tex = textures.sample(key, u, v, scale)
                if tex is not None:
                    # as the game colours the part: lifted under a picture with its own colour,
                    # brightened under a dark one
                    tcol = shade_paint(cols[i], textures.by_mat[key][2], textures.by_mat[key][3])
                    if game is None:
                        texel = tcol * shade * tex
                    else:
                        texel = game.shade(tcol[None, :] * tex, irr)
                    if alphas[i] >= 1:
                        region[closer] = z[closer]
                        img[y0:y1 + 1, x0:x1 + 1][closer] = texel
                    continue
        if alphas[i] >= 1:
            region[closer] = z[closer]
            img[y0:y1 + 1, x0:x1 + 1][closer] = col
        else:
            a = alphas[i]
            sub = img[y0:y1 + 1, x0:x1 + 1]
            sub[closer] = sub[closer] * (1 - a) + col * a
    if game is not None and not args.no_grade:
        img = game_look.grade(img, game)
    rgb8 = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    if args.transparent:
        alpha = np.where(np.isfinite(zbuf), 255, 0).astype(np.uint8)
        Image.fromarray(np.dstack([rgb8, alpha]), "RGBA").save(args.out)
    else:
        Image.fromarray(rgb8).save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
