#!/usr/bin/env python3
"""Draws a cutscene's set (Data/Stages) the way the game shows it now: built in the world and lit
by the game's own light at the set's hour (tools/preview/look.py: the sun or the moon, the shade
lit by the sky, the tone map and the grade), with shadows cast from the sun or the moon, the
set's lamps lighting what is round them (no shadows from those here), Neon glowing, the haze
fading what is far off, and a sky with the sun or the moon in it (and stars after dark).
It is a sketch of what Roblox draws, good for judging a set and its shots, not a screenshot.

    python3 tools/preview/stage.py <set.json> <out.png> [--shot wide | --all <dir>] [--shots a,b]
        [--eye x,y,z --look x,y,z --fov 40] [--size 1280x720] [--ss 1] [--clear] [--bars]

<set.json> is what `lune run tools/preview/dump.luau stage:<id>` writes; the light, the shots, the
lamps and a stand-in on each mark are read from <set.json>.stage.json beside it, or from --side.
--all draws every shot into <dir> as <id>_<shot>.png (--shots only those). --clear leaves the sky
out (see-through), which is how tools/preview/ui_dump.luau lays the picture under the screen it
builds. --bars draws the letterbox. tools/preview/stage.sh runs the lot.
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
import walk  # noqa: E402  (clipping and filling triangles, the sky's colours)
import look as game_look  # noqa: E402  (the game's light and grade)

BARS = 0.11  # the letterbox: this share of the screen's height, top and bottom
LAMP = 1.1  # how strongly a lamp lights what faces it, for its brightness
INDOOR_SKY = 0.22  # how much of the sky's light reaches into a room


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
    s = seed % 2147483646 + 1

    def nxt():
        nonlocal s
        s = (s * 48271) % 2147483647
        return s / 2147483647

    return nxt


def tris_of(p):
    """A primitive's triangles: balls and cylinders round (the sets are built smooth), cones from
    the low poly kit as the game draws them."""
    render.USE_KIT = p["shape"] == "Cone"
    return render.prim_tris(p)


def paint_sky(side, W, H, focal, fwd, right, up, scale, sky_dir, hour):
    zenith, horizon = walk.sky_at(hour)
    air = side["light"].get("air") or {}
    if air.get("color"):
        horizon = np.array(air["color"]) * 0.85 + horizon * 0.15
        zenith = (np.array(air.get("decay") or air["color"]) * 0.6 + zenith * 0.4)
    rows = (np.arange(H) + 0.5 - H / 2) / focal
    pitch = math.asin(max(-1, min(1, fwd[1])))
    elev = pitch - np.arctan(rows)
    blend = np.clip(elev / math.radians(38), 0, 1) ** 0.7
    img = np.zeros((H, W, 3))
    img[:] = (horizon[None, :] * (1 - blend[:, None]) + zenith[None, :] * blend[:, None])[:, None, :]
    im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def project(v):
        v = np.array(v, float)
        v /= np.linalg.norm(v)
        z = v @ fwd
        if z <= 0.05:
            return None
        return W / 2 + focal * (v @ right) / z, H / 2 - focal * (v @ up) / z

    night = sky_dir[1] < 0 or game_look.sun_dir(hour, -20)[1] < -0.05
    if night:
        nxt = rand(11)
        for _ in range(160):
            az = nxt() * 2 * math.pi
            el = math.radians(8 + nxt() * 80)
            size = (1.2 + nxt() * 1.8) * scale
            alpha = int(255 * (0.35 + 0.6 * nxt()))
            p = project([math.sin(az) * math.cos(el), math.sin(el), -math.cos(az) * math.cos(el)])
            if p:
                d.ellipse([p[0] - size / 2, p[1] - size / 2, p[0] + size / 2, p[1] + size / 2],
                          fill=(255, 250, 236, alpha))
    p = project(sky_dir)
    if p and sky_dir[1] > -0.1:
        r = (26 if night else 40) * scale
        col = (236, 236, 220) if night else (255, 246, 214)
        glow = (170, 186, 236) if night else (255, 214, 150)
        for k, a in ((3.0, 30), (2.0, 60), (1.4, 110)):
            d.ellipse([p[0] - r * k, p[1] - r * k, p[0] + r * k, p[1] + r * k], fill=glow + (a,))
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col + (255,))
    im.alpha_composite(layer)
    return np.asarray(im.convert("RGB"), float) / 255


def draw(prims, side, eye, look, fov, W, H, clear=False):
    light_info = side["light"]
    hour = light_info["hour"]
    sky_dir = np.array(side["sky_dir"], float)
    sky_dir /= np.linalg.norm(sky_dir)
    look_json = side["look"]
    light = game_look.Light(look_json, hour)
    if light_info.get("indoor"):
        light.sky = light.sky * INDOOR_SKY
        L = look_json["Light"]
        amb = (L["Night"]["Ambient"] if light.grade is look_json["Grade"]["Night"] else L["Ambient"])
        light.ambient = game_look.to_lin(game_look.rgb(amb))
    grade_over = light_info.get("grade") or {}
    if grade_over:
        g = dict(light.grade)
        if grade_over.get("tint"):
            g["Tint"] = [c * 255 for c in grade_over["tint"]]
        if grade_over.get("saturation") is not None:
            g["Saturation"] = grade_over["saturation"]
        light.grade = g
    air = light_info.get("air") or {}
    haze, reach = walk.air_at(look_json, hour)
    if air.get("color"):
        haze = np.array(air["color"], float)
    if air.get("density"):
        reach = 360.0 / air["density"]
    lamps = side.get("lamps") or []

    fwd, right, up = basis(eye, look)
    focal = (H / 2) / math.tan(math.radians(fov) / 2)
    tris, owners = [], []
    for pi, p in enumerate(prims):
        if p.get("transp", 0) >= 0.99:
            continue
        for t in tris_of(p):
            tris.append(t)
            owners.append(pi)
    if clear:
        img = np.zeros((H, W, 3))
    else:
        img = paint_sky(side, W, H, focal, fwd, right, up, H / 720, sky_dir, hour)
    alpha = np.zeros((H, W))
    glowmask = np.zeros((H, W, 3))
    if not tris:
        return img, alpha
    T = np.array(tris)
    owners = np.array(owners)
    alphas = np.array([1 - prims[o].get("transp", 0) for o in owners])

    # the shadow map, from the sun (or the moon), over what is near the camera
    toward = sky_dir
    shadow = None
    if toward[1] > 0.02:
        lr = np.cross(toward, [0, 1, 0])
        lr /= np.linalg.norm(lr)
        lu = np.cross(lr, toward)
        flat = T.reshape(-1, 3)
        u, v, dd = flat @ lr, flat @ lu, flat @ -toward
        near = np.linalg.norm(T.mean(axis=1) - eye, axis=1) < 90
        S = 3072
        nu, nv = u.reshape(-1, 3)[near], v.reshape(-1, 3)[near]
        if len(nu):
            u0, v0 = nu.min(), nv.min()
            k = (S - 4) / max(nu.max() - u0, nv.max() - v0, 1e-6)
            depth = np.full((S, S), np.inf)
            U = ((u - u0) * k + 2).reshape(-1, 3)
            V = ((v - v0) * k + 2).reshape(-1, 3)
            D = dd.reshape(-1, 3)
            solid = (alphas > 0.7) & near & np.array([prims[o].get("mat") != "Neon" for o in owners])
            for i in np.nonzero(solid)[0]:
                got = walk.raster(U[i], V[i], S, S)
                if got is None:
                    continue
                sl, w1, w2, w3, inside = got
                z = w1 * D[i, 0] + w2 * D[i, 1] + w3 * D[i, 2]
                region = depth[sl]
                closer = inside & (z < region)
                region[closer] = z[closer]
            shadow = (depth, lr, lu, u0, v0, k, S)

    cam = np.stack([(T - eye) @ right, (T - eye) @ up, (T - eye) @ fwd], axis=-1)
    ahead = (cam[:, :, 2] >= walk.NEAR).any(axis=1)
    order = sorted(np.nonzero(ahead)[0], key=lambda i: alphas[i] < 1)
    zbuf = np.full((H, W), np.inf)
    lamp_pos = np.array([l["at"] for l in lamps]) if lamps else None
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
        glow = p.get("mat") == "Neon"
        facing = max(0.0, float(n @ toward))
        a = alphas[i]
        for c, wts in walk.clip_near(cam[i]):
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
            corners = wts @ t
            b1 = (w1 / c[0, 2] * z)[closer]
            b2 = (w2 / c[1, 2] * z)[closer]
            b3 = (w3 / c[2, 2] * z)[closer]
            world = b1[:, None] * corners[0] + b2[:, None] * corners[1] + b3[:, None] * corners[2]
            if glow:
                shaded = np.tile(np.clip(base * 1.12, 0, 1), (len(world), 1))
            else:
                lit = np.ones(len(world))
                if shadow is not None and facing > 0:
                    depth, lr, lu, u0, v0, k, S = shadow
                    fu = (world @ lr - u0) * k + 2
                    fv = (world @ lu - v0) * k + 2
                    there = world @ -toward - (0.2 + 0.5 * (1 - facing))
                    lit = np.zeros(len(world))
                    for du in (-1, 0, 1):
                        for dv in (-1, 0, 1):
                            su = np.clip((fu + du).astype(int), 0, S - 1)
                            sv = np.clip((fv + dv).astype(int), 0, S - 1)
                            lit += depth[sv, su] >= there
                    lit /= 9
                    off = (fu < 1) | (fv < 1) | (fu > S - 2) | (fv > S - 2)
                    lit[off] = 1
                irr = light.irradiance(n, lit, toward=toward)
                if lamp_pos is not None:
                    for li, l in enumerate(lamps):
                        dv = lamp_pos[li][None, :] - world
                        dist = np.linalg.norm(dv, axis=1)
                        near_l = dist < l["range"]
                        if not near_l.any():
                            continue
                        cosv = np.clip((dv @ n) / np.maximum(dist, 1e-6), 0, 1)
                        fall = np.clip(1 - dist / l["range"], 0, 1) ** 2
                        irr = irr + (game_look.to_lin(np.array(l["color"]))[None, :]
                                     * (l["brightness"] * LAMP * cosv * fall)[:, None])
                shaded = light.shade(np.tile(base, (len(world), 1)), irr)
            dist = np.linalg.norm(world - eye, axis=1)
            fog = (1 - np.exp(-dist / reach))[:, None]
            shaded = shaded * (1 - fog) + haze * fog
            sub = img[sl]
            al = alpha[sl]
            gm = glowmask[sl]
            if a >= 1:
                region[closer] = z[closer]
                sub[closer] = shaded
                al[closer] = 1
                gm[closer] = shaded if glow else 0
            else:
                sub[closer] = sub[closer] * (1 - a) + shaded * a
                al[closer] = np.maximum(al[closer], a)
    img = game_look.grade(img, light)
    # a soft glow round what shines (the game's bloom)
    if glowmask.any():
        g = Image.fromarray((np.clip(glowmask, 0, 1) * 255).astype(np.uint8), "RGB")
        g = g.filter(ImageFilter.GaussianBlur(radius=max(2, H / 90)))
        img = np.clip(img + np.asarray(g, float) / 255 * 0.55, 0, 1)
    return img, alpha


def shot_picture(prims, side, eye, look, fov, W, H, clear=False, bars=False, ss=1):
    w, h = W * ss, H * ss
    img, alpha = draw(prims, side, eye, look, fov, w, h, clear)
    if clear:
        rgba = np.dstack([np.clip(img, 0, 1) * 255, alpha * 255]).astype(np.uint8)
        pic = Image.fromarray(rgba, "RGBA")
    else:
        pic = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    if bars:
        d = ImageDraw.Draw(pic)
        b = int(h * BARS)
        d.rectangle([0, 0, w, b], fill=(0, 0, 0, 255))
        d.rectangle([0, h - b, w, h], fill=(0, 0, 0, 255))
    return pic.resize((W, H), Image.LANCZOS) if ss != 1 else pic


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out", help="a PNG, or with --all the folder to write into")
    ap.add_argument("--side", default=None, help="the light, shots and lamps (default: <inp>.stage.json)")
    ap.add_argument("--shot", default="wide")
    ap.add_argument("--all", action="store_true", help="every shot, into the folder `out`")
    ap.add_argument("--shots", default=None, help="with --all: only these shots (a,b,c)")
    ap.add_argument("--eye", default=None)
    ap.add_argument("--look", default=None)
    ap.add_argument("--fov", type=float, default=None)
    ap.add_argument("--size", default="1280x720")
    ap.add_argument("--clear", action="store_true", help="no sky: see-through where nothing is drawn")
    ap.add_argument("--no-cast", action="store_true", help="leave the stand-ins off the marks")
    ap.add_argument("--bars", action="store_true", help="the letterbox over the top and the bottom")
    ap.add_argument("--ss", type=int, default=1)
    args = ap.parse_args()
    W, H = [int(v) for v in args.size.split("x")]
    prims = json.load(open(args.inp))
    side = json.load(open(args.side or args.inp + ".stage.json"))
    if "look" not in side:
        side["look"] = game_look.load()
    if not args.no_cast:
        prims = prims + side.get("figures", [])
    if args.all:
        os.makedirs(args.out, exist_ok=True)
        want = set(args.shots.split(",")) if args.shots else None
        for name, sh in sorted(side["shots"].items()):
            if want and name not in want:
                continue
            pic = shot_picture(prims, side, np.array(sh["eye"]), np.array(sh["look"]), sh["fov"], W, H,
                               args.clear, args.bars, args.ss)
            path = os.path.join(args.out, "%s_%s.png" % (side.get("id", "stage"), name.replace(":", "-")))
            pic.convert("RGB").save(path)
            print("wrote", path)
        return
    if args.eye:
        eye, lk, fov = vec(args.eye), vec(args.look), args.fov or 40
    else:
        sh = side["shots"][args.shot]
        eye, lk, fov = np.array(sh["eye"]), np.array(sh["look"]), args.fov or sh["fov"]
    pic = shot_picture(prims, side, eye, lk, fov, W, H, args.clear, args.bars, args.ss)
    (pic if args.clear else pic.convert("RGB")).save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
