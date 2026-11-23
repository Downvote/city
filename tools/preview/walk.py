#!/usr/bin/env python3
"""A view of a preview scene as somebody standing in it would see it: a camera with a lens, at
eye height or wherever you put it, the sun where the game has it at that hour, shadows cast
across the ground and the walls, a sky, and a little haze with distance.

    python3 tools/preview/walk.py <scene.json> <out.png> --eye x,y,z --look x,y,z
        [--fov 60] [--size 1280x720] [--hour 16] [--far 700] [--textures] [--painted]
        [--no-shadows] [--smooth]

tools/preview/render.py draws the same scenes from above with no lens, which is right for judging
a model or a layout. This one is for judging a place: does a street read as a street, how long
are the shadows, what do you see from the pavement. It is still only a sketch of what Roblox
draws (no bloom, no reflections, one hard shadow test a pixel), but the sun's height follows the
game's (Lighting.GeographicLatitude 54) and its colour the hour, as Services/World grades it.
tools/preview/walk.sh dumps a scene and runs this on it.
"""
import argparse
import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render  # noqa: E402  (the shapes, the textures)

LATITUDE = 54.0
NEAR = 0.4


def sun_at(hour):
    """Which way the sun is (a unit vector toward it), how strong and what colour, and the
    colour of the light that isn't the sun's, at an hour of the game's day."""
    h = min(max(hour, 6.2), 17.8)
    a = math.pi * (h - 6) / 12
    lat = math.radians(LATITUDE)
    s = np.array([math.cos(a), math.sin(a) * math.cos(lat), -math.sin(a) * math.sin(lat)])
    s /= np.linalg.norm(s)
    if 10 <= hour <= 14.5:
        sun, ambient = np.array([1.0, 0.97, 0.9]) * 0.62, np.array([0.52, 0.51, 0.62])
        sky, haze = np.array([0.42, 0.62, 0.9]), np.array([0.82, 0.87, 0.95])
    elif 7.5 <= hour <= 16.5:
        sun, ambient = np.array([1.0, 0.88, 0.7]) * 0.7, np.array([0.5, 0.47, 0.6])
        sky, haze = np.array([0.46, 0.62, 0.86]), np.array([0.95, 0.86, 0.74])
    else:
        sun, ambient = np.array([1.0, 0.72, 0.5]) * 0.74, np.array([0.46, 0.42, 0.58])
        sky, haze = np.array([0.5, 0.56, 0.8]), np.array([0.98, 0.76, 0.6])
    return s, sun, ambient, sky, haze


def vec(text):
    return np.array([float(x) for x in text.split(",")])


def clip_near(cam):
    """A triangle in camera space (3 x 3: x right, y up, z ahead) cut at the near plane. Returns
    a list of triangles (none, one or two), each with the weights of the original corners for
    every new corner, so anything known at the corners can be carried over."""
    ins = cam[:, 2] >= NEAR
    eye3 = np.eye(3)
    if ins.all():
        return [(cam, eye3)]
    if not ins.any():
        return []
    pts, wts = [], []
    for i in range(3):
        j = (i + 1) % 3
        if ins[i]:
            pts.append(cam[i]); wts.append(eye3[i])
        if ins[i] != ins[j]:
            t = (NEAR - cam[i, 2]) / (cam[j, 2] - cam[i, 2])
            pts.append(cam[i] + (cam[j] - cam[i]) * t)
            wts.append(eye3[i] + (eye3[j] - eye3[i]) * t)
    out = []
    for k in range(1, len(pts) - 1):
        out.append((np.array([pts[0], pts[k], pts[k + 1]]), np.array([wts[0], wts[k], wts[k + 1]])))
    return out


def raster(px, py, W, H):
    """The pixels a screen triangle covers: the box's slices, the three weights and the mask."""
    x0, x1 = int(max(0, math.floor(px.min()))), int(min(W - 1, math.ceil(px.max())))
    y0, y1 = int(max(0, math.floor(py.min()))), int(min(H - 1, math.ceil(py.max())))
    if x1 < x0 or y1 < y0:
        return None
    (ax, bx, qx), (ay, by, qy) = px, py
    den = (by - qy) * (ax - qx) + (qx - bx) * (ay - qy)
    if abs(den) < 1e-12:
        return None
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    w1 = ((by - qy) * (xs - qx) + (qx - bx) * (ys - qy)) / den
    w2 = ((qy - ay) * (xs - qx) + (ax - qx) * (ys - qy)) / den
    w3 = 1 - w1 - w2
    inside = (w1 >= -1e-6) & (w2 >= -1e-6) & (w3 >= -1e-6)
    if not inside.any():
        return None
    return (slice(y0, y1 + 1), slice(x0, x1 + 1)), w1, w2, w3, inside


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--eye", required=True, help="where the camera is: x,y,z in studs")
    ap.add_argument("--look", required=True, help="what it looks at: x,y,z")
    ap.add_argument("--fov", type=float, default=60, help="the lens, degrees top to bottom")
    ap.add_argument("--size", default="1280x720")
    ap.add_argument("--hour", type=float, default=16, help="the game's hour, 6 to 18")
    ap.add_argument("--far", type=float, default=700, help="nothing further off than this is drawn")
    ap.add_argument("--textures", action="store_true")
    ap.add_argument("--painted", action="store_true")
    ap.add_argument("--no-shadows", action="store_true")
    ap.add_argument("--reach", type=float, default=320, help="shadows are worked out this far from the camera")
    ap.add_argument("--smooth", action="store_true")
    args = ap.parse_args()
    render.USE_KIT = not args.smooth
    W, H = [int(v) for v in args.size.split("x")]
    eye, look = vec(args.eye), vec(args.look)
    forward = look - eye
    forward /= np.linalg.norm(forward)
    right = np.cross(forward, [0, 1, 0]); right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    focal = (H / 2) / math.tan(math.radians(args.fov) / 2)
    sun_dir, sun_col, ambient, sky, haze = sun_at(args.hour)

    prims = json.load(open(args.inp))
    textures = render.Textures(painted=args.painted, library=args.textures) if (args.textures or args.painted) else None
    tris, owners = [], []
    for pi, p in enumerate(prims):
        if p.get("transp", 0) >= 0.99:
            continue
        pos = np.array(p["cf"][0:3])
        reach = np.linalg.norm(p["size"]) / 2
        if np.linalg.norm(pos - eye) - reach > args.far:
            continue
        for t in render.prim_tris(p):
            tris.append(t)
            owners.append(pi)
    if not tris:
        print("nothing to draw")
        return
    T = np.array(tris)
    owners = np.array(owners)

    # the shadow map: the scene's depth seen from the sun, with no lens
    shadow = None
    if not args.no_shadows:
        lr = np.cross(sun_dir, [0, 1, 0]); lr /= np.linalg.norm(lr)
        lu = np.cross(lr, sun_dir)
        flat = T.reshape(-1, 3)
        u, v, d = flat @ lr, flat @ lu, flat @ -sun_dir  # d grows away from the sun
        # only what is near the camera casts and takes shadows: the map's dots stay small
        near = (np.linalg.norm(T.mean(axis=1) - eye, axis=1) < args.reach * 1.35)
        S = 4096
        nu, nv = u.reshape(-1, 3)[near], v.reshape(-1, 3)[near]
        u0, v0 = nu.min(), nv.min()
        k = (S - 4) / max(nu.max() - u0, nv.max() - v0, 1e-6)
        depth = np.full((S, S), np.inf)
        U = ((u - u0) * k + 2).reshape(-1, 3)
        V = ((v - v0) * k + 2).reshape(-1, 3)
        D = d.reshape(-1, 3)
        solid = np.array([prims[o].get("transp", 0) < 0.3 for o in owners]) & near
        for i in np.nonzero(solid)[0]:
            got = raster(U[i], V[i], S, S)
            if got is None:
                continue
            sl, w1, w2, w3, inside = got
            z = w1 * D[i, 0] + w2 * D[i, 1] + w3 * D[i, 2]
            region = depth[sl]
            closer = inside & (z < region)
            region[closer] = z[closer]
        shadow = (depth, lr, lu, u0, v0, k, S)

    # the sky: clear above, the haze's colour at the horizon
    img = np.zeros((H, W, 3))
    rows = (np.arange(H) + 0.5 - H / 2) / focal  # tan of the angle below the lens's middle
    pitch = math.asin(forward[1])
    elev = pitch - np.arctan(rows)
    blend = np.clip(elev / math.radians(38), 0, 1) ** 0.7
    img[:] = (haze[None, :] * (1 - blend[:, None]) + sky[None, :] * blend[:, None])[:, None, :]
    zbuf = np.full((H, W), np.inf)

    cam = np.stack([(T - eye) @ right, (T - eye) @ up, (T - eye) @ forward], axis=-1)  # n x 3 x 3
    ahead = (cam[:, :, 2] >= NEAR).any(axis=1)
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
        glow = p.get("mat") == "Neon"
        facing = max(0.0, float(n @ sun_dir))
        for c, wts in clip_near(cam[i]):
            px = W / 2 + focal * c[:, 0] / c[:, 2]
            py = H / 2 - focal * c[:, 1] / c[:, 2]
            if px.max() < 0 or px.min() > W or py.max() < 0 or py.min() > H:
                continue
            got = raster(px, py, W, H)
            if got is None:
                continue
            sl, w1, w2, w3, inside = got
            # depth and place, right for a lens: what is known at the corners is carried over
            # divided by their depth
            iz = w1 / c[0, 2] + w2 / c[1, 2] + w3 / c[2, 2]
            z = 1 / np.maximum(iz, 1e-9)
            region = zbuf[sl]
            closer = inside & (z < region - 1e-4)
            if not closer.any():
                continue
            corners = wts @ t  # the cut triangle's corners in the world
            b1 = (w1 / c[0, 2] * z)[closer]
            b2 = (w2 / c[1, 2] * z)[closer]
            b3 = (w3 / c[2, 2] * z)[closer]
            world = b1[:, None] * corners[0] + b2[:, None] * corners[1] + b3[:, None] * corners[2]
            lit = np.ones(len(world))
            if shadow is not None and facing > 0 and not glow:
                depth, lr, lu, u0, v0, k, S = shadow
                fu = (world @ lr - u0) * k + 2
                fv = (world @ lu - v0) * k + 2
                there = world @ -sun_dir - (0.25 + 0.6 * (1 - facing))
                # nine taps round the spot, so a shadow's edge is a soft step and not a saw
                lit = np.zeros(len(world))
                for du in (-1, 0, 1):
                    for dv in (-1, 0, 1):
                        su = np.clip((fu + du).astype(int), 0, S - 1)
                        sv = np.clip((fv + dv).astype(int), 0, S - 1)
                        lit += depth[sv, su] >= there
                lit /= 9
                # past the map's edge everything is in the sun
                off = (fu < 1) | (fv < 1) | (fu > S - 2) | (fv > S - 2)
                lit[off] = 1
            col = np.tile(base, (len(world), 1))
            if textures is not None:
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
                        if textures.by_mat[key][2]:
                            col = col * (1 - render.LIFT) + render.LIFT
                        col = col * tex
            if glow:
                shaded = col * 1.15
            else:
                skylight = 0.86 + 0.14 * n[1]
                shaded = col * (ambient * skylight + sun_col[None, :] * (facing * lit)[:, None])
            dist = np.linalg.norm(world - eye, axis=1)
            fog = (1 - np.exp(-dist / 1500.0))[:, None]
            shaded = shaded * (1 - fog) + haze * fog
            a = alphas[i]
            sub = img[sl]
            if a >= 1:
                region[closer] = z[closer]
                sub[closer] = shaded
            else:
                sub[closer] = sub[closer] * (1 - a) + shaded * a
    rgb8 = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(rgb8).save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
