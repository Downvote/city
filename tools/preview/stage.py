#!/usr/bin/env python3
"""Draws a cutscene's set (Data/Stages) the way the game shows it: in a ViewportFrame, lit by the
set's own light (the ambient, plus the light's colour on whatever faces the way it comes from;
a viewport casts no shadows and has no fog), with the painted sky behind it (UI/Cutscene paints
the same bands, sun or moon and stars). Neon parts are drawn at their own colour.

    python3 tools/preview/stage.py <set.json> <out.png> [--shot wide | --all <dir>]
        [--eye x,y,z --look x,y,z --fov 40] [--size 1280x720] [--clear] [--no-cast] [--bars]

<set.json> is what `lune run tools/preview/dump.luau stage:<id>` writes; the light, the sky, the
shots and a stand-in on each mark are read from <set.json>.stage.json beside it, or from --side.
--all draws every shot into <dir> as <id>_<shot>.png. --clear leaves the sky out (see-through),
which is how tools/preview/ui_dump.luau lays the 3D picture over the screen it builds. --bars draws
the letterbox the cutscene puts over the top and the bottom. tools/preview/stage.sh runs the lot.
"""
import argparse
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render  # noqa: E402  (the shapes)
import walk  # noqa: E402  (clipping and filling triangles)

# the sky's bands, as UI/Cutscene paints them: the top colour from this far above the horizon
# (degrees), the middle colour at MID of the way down to it, the low colour this far below
SKY_SPAN = 34
MID = 0.6
BARS = 0.11  # the letterbox: this share of the screen's height, top and bottom


def vec(text):
    return np.array([float(x) for x in text.split(",")])


def basis(eye, look):
    fwd = look - eye
    fwd = fwd / np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    return fwd, right, up


def rand(seed):
    """The same little random UI/Cutscene uses for the stars."""
    s = seed % 2147483646 + 1

    def nxt():
        nonlocal s
        s = (s * 48271) % 2147483647
        return s / 2147483647

    return nxt


def lerp(a, b, t):
    return np.array(a) * (1 - t) + np.array(b) * t


def row_of(elev_deg, pitch, H, focal):
    """The screen row (from the top) where a point that many degrees over the horizon is drawn."""
    d = math.radians(elev_deg) - pitch
    d = max(-1.45, min(1.45, d))
    return H / 2 - focal * math.tan(d)


def sky_colour_at(sky, y, pitch, H, focal):
    top, hor, low = np.array(sky["top"]), np.array(sky["horizon"]), np.array(sky["low"])
    mid = np.array(sky["mid"]) if sky.get("mid") else None
    r_top = row_of(SKY_SPAN, pitch, H, focal)
    r_hor = row_of(0, pitch, H, focal)
    r_low = row_of(-SKY_SPAN, pitch, H, focal)
    if y <= r_top:
        return top
    if y <= r_hor:
        t = (y - r_top) / max(1e-6, r_hor - r_top)
        if mid is not None:
            return lerp(top, mid, t / MID) if t < MID else lerp(mid, hor, (t - MID) / (1 - MID))
        return lerp(top, hor, t)
    if y <= r_low:
        return lerp(hor, low, (y - r_hor) / max(1e-6, r_low - r_hor))
    return low


def project(d, fwd, right, up, W, H, focal):
    d = np.array(d, float)
    d /= np.linalg.norm(d)
    z = d @ fwd
    if z <= 0.05:
        return None
    return W / 2 + focal * (d @ right) / z, H / 2 - focal * (d @ up) / z


def paint_sky(sky, W, H, focal, fwd, right, up, scale):
    pitch = math.asin(max(-1, min(1, fwd[1])))
    img = np.zeros((H, W, 3))
    for y in range(H):
        img[y, :] = sky_colour_at(sky, y + 0.5, pitch, H, focal)
    im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    n = sky.get("stars") or 0
    if n:
        nxt = rand(11)
        for i in range(n):
            az = nxt() * 2 * math.pi
            el = math.radians(10 + nxt() * 70)
            size = (1.5 + nxt() * 2) * scale
            alpha = int(255 * (0.45 + 0.55 * nxt()))
            p = project([math.sin(az) * math.cos(el), math.sin(el), -math.cos(az) * math.cos(el)], fwd, right, up, W, H, focal)
            if p:
                d.ellipse([p[0] - size / 2, p[1] - size / 2, p[0] + size / 2, p[1] + size / 2], fill=(255, 250, 236, alpha))
    for key in ("sun", "moon"):
        disc = sky.get(key)
        if not disc:
            continue
        p = project(disc["dir"], fwd, right, up, W, H, focal)
        if not p:
            continue
        r = disc["size"] * scale / 2
        glow = disc.get("glow")
        if glow:
            g = tuple(int(c * 255) for c in glow)
            for k, a in ((2.6, 40), (1.8, 70), (1.3, 110)):
                d.ellipse([p[0] - r * k, p[1] - r * k, p[0] + r * k, p[1] + r * k], fill=g + (a,))
        col = tuple(int(c * 255) for c in disc["color"])
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col + (255,))
        phase = disc.get("phase") or 0
        if phase:
            # a crescent: a disc of the sky's own colour there over part of it
            bite = sky_colour_at(sky, p[1], pitch, H, focal)
            b = tuple(int(c * 255) for c in bite) + (255,)
            off = r * 2 * phase
            d.ellipse([p[0] - r + off, p[1] - r - r * 0.1, p[0] + r + off, p[1] + r - r * 0.1], fill=b)
    im.alpha_composite(layer)
    return im


def draw(prims, light, eye, look, fov, W, H, sky=None, scale=1.0):
    fwd, right, up = basis(eye, look)
    focal = (H / 2) / math.tan(math.radians(fov) / 2)
    ambient = np.array(light["ambient"])
    lcol = np.array(light["color"])
    ldir = np.array(light["dir"], float)
    ldir /= np.linalg.norm(ldir)
    tris, owners = [], []
    for pi, p in enumerate(prims):
        if p.get("transp", 0) >= 0.99:
            continue
        for t in render.prim_tris(p):
            tris.append(t)
            owners.append(pi)
    img = np.zeros((H, W, 3))
    alpha = np.zeros((H, W))
    zbuf = np.full((H, W), np.inf)
    if not tris:
        return img, alpha
    T = np.array(tris)
    cam = np.stack([(T - eye) @ right, (T - eye) @ up, (T - eye) @ fwd], axis=-1)
    ahead = (cam[:, :, 2] >= walk.NEAR).any(axis=1)
    alphas = np.array([1 - prims[o].get("transp", 0) for o in owners])
    order = sorted(np.nonzero(ahead)[0], key=lambda i: alphas[i] < 1)
    for i in order:
        t = T[i]
        n = np.cross(t[1] - t[0], t[2] - t[0])
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            continue
        n /= ln
        if n @ (t[0] - eye) > 0:
            n = -n
        p = prims[owners[i]]
        base = np.array(p["color"])
        if p.get("mat") == "Neon":
            col = base
        else:
            col = base * np.clip(ambient + lcol * max(0.0, float(n @ -ldir)), 0, 1.2)
        col = np.clip(col, 0, 1)
        a = alphas[i]
        for c, _ in walk.clip_near(cam[i]):
            px = W / 2 + focal * c[:, 0] / c[:, 2]
            py = H / 2 - focal * c[:, 1] / c[:, 2]
            if px.max() < 0 or px.min() > W or py.max() < 0 or py.min() > H:
                continue
            got = walk.raster(px, py, W, H)
            if got is None:
                continue
            sl, w1, w2, w3, inside = got
            iz = w1 / c[0, 2] + w2 / c[1, 2] + w3 / c[2, 2]
            z = 1 / np.maximum(iz, 1e-9)
            region = zbuf[sl]
            closer = inside & (z < region - 1e-4)
            if not closer.any():
                continue
            sub = img[sl]
            al = alpha[sl]
            if a >= 1:
                region[closer] = z[closer]
                sub[closer] = col
                al[closer] = 1
            else:
                sub[closer] = sub[closer] * (1 - a) + col * a
                al[closer] = np.maximum(al[closer], a)
    return img, alpha


def shot_picture(prims, side, eye, look, fov, W, H, clear=False, bars=False, ss=2):
    w, h = W * ss, H * ss
    img, alpha = draw(prims, side["light"], eye, look, fov, w, h)
    fwd, right, up = basis(eye, look)
    focal = (h / 2) / math.tan(math.radians(fov) / 2)
    rgba = np.dstack([np.clip(img, 0, 1) * 255, alpha * 255]).astype(np.uint8)
    pic = Image.fromarray(rgba, "RGBA")
    if not clear:
        back = paint_sky(side["sky"], w, h, focal, fwd, right, up, h / 720)
        back.alpha_composite(pic)
        pic = back
    if bars:
        d = ImageDraw.Draw(pic)
        b = int(h * BARS)
        d.rectangle([0, 0, w, b], fill=(0, 0, 0, 255))
        d.rectangle([0, h - b, w, h], fill=(0, 0, 0, 255))
    return pic.resize((W, H), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out", help="a PNG, or with --all the folder to write into")
    ap.add_argument("--side", default=None, help="the light, sky and shots (default: <inp>.stage.json)")
    ap.add_argument("--shot", default="wide")
    ap.add_argument("--all", action="store_true", help="every shot, into the folder `out`")
    ap.add_argument("--eye", default=None)
    ap.add_argument("--look", default=None)
    ap.add_argument("--fov", type=float, default=None)
    ap.add_argument("--size", default="1280x720")
    ap.add_argument("--clear", action="store_true", help="no sky: see-through where nothing is drawn")
    ap.add_argument("--no-cast", action="store_true", help="leave the stand-ins off the marks")
    ap.add_argument("--bars", action="store_true", help="the letterbox over the top and the bottom")
    ap.add_argument("--ss", type=int, default=2)
    args = ap.parse_args()
    render.USE_KIT = True
    W, H = [int(v) for v in args.size.split("x")]
    prims = json.load(open(args.inp))
    side = json.load(open(args.side or args.inp + ".stage.json"))
    if not args.no_cast:
        prims = prims + side.get("figures", [])
    if args.all:
        os.makedirs(args.out, exist_ok=True)
        for name, sh in sorted(side["shots"].items()):
            pic = shot_picture(prims, side, np.array(sh["eye"]), np.array(sh["look"]), sh["fov"], W, H,
                               args.clear, args.bars, args.ss)
            path = os.path.join(args.out, "%s_%s.png" % (side.get("id", "stage"), name.replace(":", "-")))
            pic.convert("RGB").save(path)
            print("wrote", path)
        return
    if args.eye:
        eye, look, fov = vec(args.eye), vec(args.look), args.fov or 40
    else:
        sh = side["shots"][args.shot]
        eye, look, fov = np.array(sh["eye"]), np.array(sh["look"]), args.fov or sh["fov"]
    pic = shot_picture(prims, side, eye, look, fov, W, H, args.clear, args.bars, args.ss)
    (pic if args.clear else pic.convert("RGB")).save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
