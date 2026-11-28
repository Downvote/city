#!/usr/bin/env python3
"""A plot as somebody standing on it would see it, after dark as well as by day: what
tools/preview/walk.py draws (a lens, the game's sun or moon for the hour with cast shadows, the
textures, the haze and the grade), plus the plot's own lamps lighting what is round them and a
glow round what shines, the way a player's lights are on at every hour (Sim/Lights).

    python3 tools/preview/plan_shot.py <scene.json> <out.png> --eye x,y,z --look x,y,z
        [--fov 60] [--size 1600x900] [--ss 2] [--hour 19.3] [--textures] [--far 900]

<scene.json> is what `lune run tools/preview/dump.luau plan:<plan.json>` writes; its lamps are
read from <scene.json>.lamps.json beside it (tools/preview/plan_shot.sh does both). --ss draws
the picture that many times bigger and shrinks it, which smooths its edges.

It is a sketch of what Roblox draws, by the same model as tools/preview/look.py and
tools/preview/stage.py: lamps light what faces them and fade to nothing at their range (a placed
light has no shadows in the game either, so it reaches through walls); Neon is drawn at its own
colour, a little over, with a soft glow round it for the Bloom; the haze takes the air's colour
for the hour (Tuning.Look.Air), dimmed after dark as the sky's light goes; the sky is a gradient
with the moon and stars at night. Nothing moves (a ride stands as it was drawn), no particles,
no reflections, no fog machine's fog.
The picture is shaded deferred: the nearest surface at every pixel first, then the light on all
of them at once, so many lamps cost little.
"""
import argparse
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render  # noqa: E402  (the shapes, the textures)
import walk  # noqa: E402  (clipping, filling triangles, the air)
import stage  # noqa: E402  (the night sky)
import look as game_look  # noqa: E402  (the game's light and grade)

LAMP = stage.LAMP  # how strongly a lamp lights what faces it, for its brightness
NIGHT_SKY = (np.array([0.07, 0.08, 0.2]), np.array([0.2, 0.17, 0.32]))  # overhead, at the horizon


def vec(text):
    return np.array([float(x) for x in text.split(",")])


def sky_colours(light, hour):
    """The sky overhead and at the horizon: walk.py's by day, sinking to night's as the sun goes
    under (a guess at Roblox's sky; it is darker than walk.py's dusk once the sun is down)."""
    zen, hor = walk.sky_at(hour)
    under = float(np.clip((-light.sun[1] - 0.02) / 0.3, 0, 1))
    return zen * (1 - under) + NIGHT_SKY[0] * under, hor * (1 - under * 0.85) + NIGHT_SKY[1] * under * 0.85


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--eye", required=True)
    ap.add_argument("--look", required=True)
    ap.add_argument("--fov", type=float, default=60, help="the lens, degrees top to bottom")
    ap.add_argument("--size", default="1600x900")
    ap.add_argument("--ss", type=int, default=2, help="drawn this many times bigger, then shrunk")
    ap.add_argument("--hour", type=float, default=19.3)
    ap.add_argument("--textures", action="store_true")
    ap.add_argument("--far", type=float, default=900)
    ap.add_argument("--reach", type=float, default=220, help="shadows are worked out this far from the camera")
    ap.add_argument("--no-grade", action="store_true")
    ap.add_argument("--lamps", default=None, help="the lamps (default <inp>.lamps.json)")
    args = ap.parse_args()

    W0, H0 = [int(v) for v in args.size.split("x")]
    W, H = W0 * args.ss, H0 * args.ss
    eye, target = vec(args.eye), vec(args.look)
    fwd = target - eye
    fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    focal = (H / 2) / math.tan(math.radians(args.fov) / 2)

    look_json = game_look.load()
    light = game_look.Light(look_json, args.hour)
    sky_dir = light.dir
    haze, fog_reach = walk.air_at(look_json, args.hour)
    dark = float(np.clip((-light.sun[1] + 0.05) / 0.25, 0, 1))
    haze = haze * (1 - 0.68 * dark)  # the air is lit by the sky: dim after dark

    prims = json.load(open(args.inp))
    lamps = json.load(open(args.lamps or args.inp + ".lamps.json"))
    textures = render.Textures(library=True) if args.textures else None
    render.USE_KIT = True

    tris, owners = [], []
    for pi, p in enumerate(prims):
        if p.get("transp", 0) >= 0.99:
            continue
        pos = np.array(p["cf"][0:3])
        if np.linalg.norm(pos - eye) - np.linalg.norm(p["size"]) / 2 > args.far:
            continue
        for t in render.prim_tris(p):
            tris.append(t)
            owners.append(pi)
    T = np.array(tris)
    owners = np.array(owners)
    alphas = np.array([1 - prims[o].get("transp", 0) for o in owners])
    print(f"{len(T)} triangles, {len(lamps)} lamps")

    # the sun's or the moon's shadow map, over what is near the camera
    shadow = None
    if sky_dir[1] > 0.02:
        lr = np.cross(sky_dir, [0, 1, 0])
        lr /= np.linalg.norm(lr)
        lu = np.cross(lr, sky_dir)
        flat = T.reshape(-1, 3)
        u, v, d = flat @ lr, flat @ lu, flat @ -sky_dir
        near = np.linalg.norm(T.mean(axis=1) - eye, axis=1) < args.reach
        S = 4096
        nu, nv = u.reshape(-1, 3)[near], v.reshape(-1, 3)[near]
        u0, v0 = nu.min(), nv.min()
        k = (S - 4) / max(nu.max() - u0, nv.max() - v0, 1e-6)
        depth = np.full((S, S), np.inf)
        U = ((u - u0) * k + 2).reshape(-1, 3)
        V = ((v - v0) * k + 2).reshape(-1, 3)
        D = d.reshape(-1, 3)
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

    def sunlit(world, n):
        """How much of the sun or the moon reaches these points (0 to 1)."""
        lit = np.ones(len(world), dtype=np.float32)
        if shadow is None:
            return lit
        depth, lr, lu, u0, v0, k, S = shadow
        facing = np.clip(n @ sky_dir, 0, 1)
        fu = (world @ lr - u0) * k + 2
        fv = (world @ lu - v0) * k + 2
        there = world @ -sky_dir - (0.25 + 0.6 * (1 - facing))
        acc = np.zeros(len(world), dtype=np.float32)
        for du in (-1, 0, 1):
            for dv in (-1, 0, 1):
                su = np.clip((fu + du).astype(int), 0, S - 1)
                sv = np.clip((fv + dv).astype(int), 0, S - 1)
                acc += depth[sv, su] >= there
        lit = acc / 9
        off = (fu < 1) | (fv < 1) | (fu > S - 2) | (fv > S - 2)
        lit[off] = 1
        return lit

    lamp_at = np.array([l["at"] for l in lamps], dtype=np.float32).reshape(-1, 3)
    lamp_col = np.array([game_look.to_lin(np.array(l["color"])) for l in lamps], dtype=np.float32).reshape(-1, 3)

    def shade(world, n, albedo):
        """Display colours of surfaces at `world` facing `n` painted `albedo` (display colours)."""
        irr = light.irradiance(n, sunlit(world, n)).astype(np.float32)
        for li, l in enumerate(lamps):
            rng = l["range"]
            dv = lamp_at[li][None, :] - world
            dist = np.sqrt((dv * dv).sum(axis=1))
            near = dist < rng
            if not near.any():
                continue
            idx = np.nonzero(near)[0]
            dd = np.maximum(dist[idx], 1e-4)
            cosv = np.clip((dv[idx] * n[idx]).sum(axis=1) / dd, 0, 1)
            fall = np.clip(1 - dd / rng, 0, 1) ** 2
            irr[idx] += lamp_col[li][None, :] * (l["brightness"] * LAMP * cosv * fall)[:, None]
        out = light.shade(albedo, irr)
        dist = np.linalg.norm(world - eye, axis=1)
        fog = (1 - np.exp(-dist / fog_reach))[:, None]
        return out * (1 - fog) + haze * fog

    # the sky behind everything
    zen, hor = sky_colours(light, args.hour)
    side = {"light": {"hour": args.hour}}
    saved = walk.sky_at
    walk.sky_at = lambda hour: (zen, hor)
    try:
        img = stage.paint_sky(side, W, H, focal, fwd, right, up, H / 720, sky_dir, args.hour).astype(np.float32)
    finally:
        walk.sky_at = saved

    # first pass: the nearest solid surface at every pixel, its place, its facing and its paint
    zbuf = np.full((H, W), np.inf, dtype=np.float32)
    gpos = np.zeros((H, W, 3), dtype=np.float32)
    gnrm = np.zeros((H, W, 3), dtype=np.float32)
    galb = np.zeros((H, W, 3), dtype=np.float32)
    gglow = np.zeros((H, W), dtype=bool)
    cam = np.stack([(T - eye) @ right, (T - eye) @ up, (T - eye) @ fwd], axis=-1)
    ahead = (cam[:, :, 2] >= walk.NEAR).any(axis=1)
    clear = []

    def surface(i, c, wts):
        """The pixels triangle i covers through the lens and what it shows at each: (slices,
        mask of the pixels nearer than what is there, their depths, world points, normal, paint)."""
        t = T[i]
        n = np.cross(t[1] - t[0], t[2] - t[0])
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            return None
        n /= ln
        if n @ (t[0] - eye) > 0:
            n = -n
        px = W / 2 + focal * c[:, 0] / c[:, 2]
        py = H / 2 - focal * c[:, 1] / c[:, 2]
        if px.max() < 0 or px.min() > W or py.max() < 0 or py.min() > H:
            return None
        got = walk.raster(px, py, W, H)
        if got is None:
            return None
        sl, w1, w2, w3, inside = got
        iz = w1 / c[0, 2] + w2 / c[1, 2] + w3 / c[2, 2]
        z = 1 / np.maximum(iz, 1e-9)
        closer = inside & (z < zbuf[sl] - 1e-4)
        if not closer.any():
            return None
        corners = wts @ t
        b1 = (w1 / c[0, 2] * z)[closer]
        b2 = (w2 / c[1, 2] * z)[closer]
        b3 = (w3 / c[2, 2] * z)[closer]
        world = b1[:, None] * corners[0] + b2[:, None] * corners[1] + b3[:, None] * corners[2]
        p = prims[owners[i]]
        base = np.array(p["color"])
        col = np.tile(base, (len(world), 1))
        if textures is not None and p.get("mat") != "Neon":
            key = textures.key(p.get("mat"))
            if key is not None:
                cf = p["cf"]
                ppos = np.array(cf[0:3])
                rot = np.array([[cf[3], cf[4], cf[5]], [cf[6], cf[7], cf[8]], [cf[9], cf[10], cf[11]]])
                lp = (world - ppos) @ rot + np.array(p["size"]) / 2
                nl = n @ rot
                axis = int(np.argmax(np.abs(nl)))
                if axis == 0:
                    tu, tv = (-lp[:, 2] if nl[0] > 0 else lp[:, 2]), -lp[:, 1]
                elif axis == 1:
                    tu, tv = lp[:, 0], lp[:, 2]
                else:
                    tu, tv = (lp[:, 0] if nl[2] > 0 else -lp[:, 0]), -lp[:, 1]
                tex = textures.sample(key, tu, tv, focal / float(z[closer].mean()))
                if tex is not None:
                    _, _, own, bright = textures.by_mat[key]
                    col = render.shade_paint(base, own, bright)[None, :] * tex
        return sl, closer, z, world, n, col

    for i in np.nonzero(ahead)[0]:
        if alphas[i] < 1:
            clear.append(i)
            continue
        glow = prims[owners[i]].get("mat") == "Neon"
        for c, wts in walk.clip_near(cam[i]):
            got = surface(i, c, wts)
            if got is None:
                continue
            sl, closer, z, world, n, col = got
            zbuf[sl][closer] = z[closer]
            gpos[sl][closer] = world
            gnrm[sl][closer] = n
            galb[sl][closer] = col
            gglow[sl][closer] = glow

    # the light on every surface at once
    hit = np.isfinite(zbuf)
    lit_px = hit & ~gglow
    if lit_px.any():
        img[lit_px] = shade(gpos[lit_px], gnrm[lit_px], galb[lit_px])
    if gglow.any():
        gl = np.clip(galb[gglow] * 1.12, 0, 1)
        dist = np.linalg.norm(gpos[gglow] - eye, axis=1)
        fog = (1 - np.exp(-dist / fog_reach))[:, None]
        img[gglow] = gl * (1 - fog) + haze * fog

    # second pass: glass and other see-through parts over it, far ones first
    clear.sort(key=lambda i: -float(np.linalg.norm(T[i].mean(axis=0) - eye)))
    for i in clear:
        a = alphas[i]
        for c, wts in walk.clip_near(cam[i]):
            got = surface(i, c, wts)
            if got is None:
                continue
            sl, closer, z, world, n, col = got
            sub = img[sl]
            sub[closer] = sub[closer] * (1 - a) + shade(world, np.tile(n, (len(world), 1)), col) * a

    if not args.no_grade:
        img = game_look.grade(img, light)
    # the glow round what shines (Tuning.Look.Bloom): a tight halo and a wide soft one
    if gglow.any():
        mask = np.zeros((H, W, 3), dtype=np.float32)
        mask[gglow] = np.clip(galb[gglow], 0, 1)
        g = Image.fromarray((mask * 255).astype(np.uint8), "RGB")
        tight = np.asarray(g.filter(ImageFilter.GaussianBlur(radius=max(2, H / 160))), np.float32) / 255
        wide = np.asarray(g.filter(ImageFilter.GaussianBlur(radius=max(4, H / 45))), np.float32) / 255
        bloom = look_json["Bloom"]["Intensity"]
        img = np.clip(img + tight * 0.55 * bloom + wide * 0.75 * bloom, 0, 1)
    pic = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB")
    if args.ss != 1:
        pic = pic.resize((W0, H0), Image.LANCZOS)
    pic.save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
