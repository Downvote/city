#!/usr/bin/env python3
"""Paints the game's own textures: one tileable picture per material, in a soft hand-painted style.

    python3 scripts/gen_textures.py [--only grass,brick] [--sheet out.png]

Writes art/textures/<name>.png (the colour map), <name>_n.png (a normal map) and textures.json
(each texture's material and studs per tile, which src/shared/Data/Textures.luau must match).

Roblox tints a material's colour map by the part's colour, and players paint anything any
colour, so every map here is nearly grey: light faces, darker cracks and edges, highlights on
the sides that face the light (from the top left), a little warmth. Each pattern repeats exactly
at the tile's edges: noise is made in frequency space, and shapes that cross an edge are drawn
again on the other side.
"""
import argparse
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

N = 512  # pixels per tile
S = 2  # supersampling for drawn strokes
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "art", "textures")
WARM = np.array([1.0, 0.985, 0.955])

YY, XX = np.mgrid[0:N, 0:N].astype(float)


# helpers ----------------------------------------------------------------------------------------------

def lowpass(rng, cx, cy=None):
    """Smooth noise that tiles: about cx blobs across, cy down. Zero mean, unit spread."""
    cy = cy or cx
    F = np.fft.fft2(rng.standard_normal((N, N)))
    fy = np.fft.fftfreq(N)[:, None] * N
    fx = np.fft.fftfreq(N)[None, :] * N
    F *= np.exp(-((fx / cx) ** 2 + (fy / cy) ** 2))
    r = np.real(np.fft.ifft2(F))
    return (r - r.mean()) / (r.std() + 1e-9)


def fbm(rng, base, octaves=4, gain=0.55):
    out = np.zeros((N, N))
    amp, total = 1.0, 0.0
    for i in range(octaves):
        out += lowpass(rng, base * 2 ** i) * amp
        total += amp
        amp *= gain
    return out / total


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def steps(x, n, soft=0.35):
    """Soft posterising: values gather into n bands with smooth edges, like strokes of paint."""
    y = x * n
    f = y - np.floor(y)
    return (np.floor(y) + smoothstep(0.5 - soft, 0.5 + soft, f)) / n


def grad(h):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) / 2
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) / 2
    return dx, dy


def lit(h, k):
    """Light from the top left: slopes rising away from it are lit, the others shaded."""
    dx, dy = grad(h)
    return np.clip((dx + dy) * k, -1.5, 1.5)


def normal_map(h, depth):
    dx, dy = grad(h)
    nx, ny, nz = -dx * depth, dy * depth, np.ones_like(h)  # OpenGL style: green points up
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.stack([nx / ln, ny / ln, nz / ln], -1)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


OFFSETS = [(ox, oy) for ox in (-N, 0, N) for oy in (-N, 0, N)]


def canvas(value=128):
    im = Image.new("L", (N * S, N * S), value)
    return im, ImageDraw.Draw(im)


def poly(d, pts, fill):
    """A filled polygon, drawn again across every edge so it tiles."""
    for ox, oy in OFFSETS:
        d.polygon([((x + ox) * S, (y + oy) * S) for x, y in pts], fill=int(fill))


def ellipse(d, x, y, rx, ry, fill):
    for ox, oy in OFFSETS:
        d.ellipse([(x - rx + ox) * S, (y - ry + oy) * S, (x + rx + ox) * S, (y + ry + oy) * S], fill=int(fill))


def line(d, pts, width, fill):
    for ox, oy in OFFSETS:
        d.line([((x + ox) * S, (y + oy) * S) for x, y in pts], fill=int(fill), width=max(1, int(width * S)))


def done(im):
    """The canvas back at tile size, as offsets from its base value in -1..1."""
    return np.asarray(im.resize((N, N), Image.BOX), float) / 128 - 1


def voronoi(rng, n, jitter=0.8):
    """Jittered points on an n x n grid; returns nearest distance, second distance, nearest id and
    the offset from the nearest point, all wrapping at the edges."""
    cell = N / n
    pts = []
    for j in range(n):
        for i in range(n):
            pts.append(((i + 0.5 + rng.uniform(-jitter, jitter) / 2) * cell,
                        (j + 0.5 + rng.uniform(-jitter, jitter) / 2) * cell))
    f1 = np.full((N, N), 1e9)
    f2 = np.full((N, N), 1e9)
    ids = np.zeros((N, N), int)
    rx = np.zeros((N, N))
    ry = np.zeros((N, N))
    for k, (px, py) in enumerate(pts):
        for ox, oy in OFFSETS:
            dx = XX - (px + ox)
            dy = YY - (py + oy)
            d = np.sqrt(dx * dx + dy * dy)
            nearer = d < f1
            f2 = np.where(nearer, f1, np.minimum(f2, d))
            f1 = np.where(nearer, d, f1)
            ids = np.where(nearer, k, ids)
            rx = np.where(nearer, dx, rx)
            ry = np.where(nearer, dy, ry)
    return f1, f2, ids, rx, ry, len(pts)


def runs(rng, lo, hi):
    """Cut points along one row: pieces between lo and hi pixels long that add up to the tile."""
    cuts, x = [], 0.0
    while x < N - lo:
        cuts.append(x)
        x += rng.uniform(lo, hi)
    scale = N / x if x > 0 else 1
    return [c * scale for c in cuts]


def row_pieces(rng, rows, lo, hi):
    """For a pattern of rows of pieces (planks, shingles): each pixel's piece id, its distances to
    the piece's left and right ends, and its position down the row."""
    rh = N / rows
    row = np.floor(YY / rh).astype(int)
    v = YY - row * rh
    pid = np.zeros((N, N), int)
    dl = np.zeros((N, N))
    dr = np.zeros((N, N))
    count = 0
    for r in range(rows):
        cuts = runs(rng, lo, hi)
        off = rng.uniform(0, N)
        mask = row == r
        x = (XX[mask] - off) % N
        edges = np.array(cuts + [N])
        k = np.searchsorted(edges, x, side="right") - 1
        pid[mask] = count + k
        dl[mask] = x - edges[k]
        dr[mask] = edges[k + 1] - x
        count += len(cuts)
    return pid, dl, dr, v, rh, count


# the textures -----------------------------------------------------------------------------------------

def grass(rng):
    lum = 0.80 + 0.025 * lowpass(rng, 3) + 0.02 * steps(lowpass(rng, 9) * 0.25 + 0.5, 4)
    h = 0.5 + 0.1 * lowpass(rng, 5)
    im, d = canvas()
    clumps = [(rng.uniform(0, N), rng.uniform(0, N)) for _ in range(150)]
    # dark blades low in each clump, then mid, then a few light tips on top
    for count, lo, hi, spread in ((3200, 40, 90, 13), (2600, 112, 150, 11), (1300, 178, 230, 8)):
        for _ in range(count):
            cx, cy = clumps[rng.integers(len(clumps))]
            x, y = cx + rng.normal(0, spread), cy + rng.normal(0, spread * 0.8)
            a = -math.pi / 2 + rng.normal(0, 0.42)
            length = rng.uniform(9, 18)
            w = rng.uniform(2.4, 3.8)
            bend = rng.normal(0, 0.3)
            px, py = math.cos(a + math.pi / 2), math.sin(a + math.pi / 2)
            mid = (x + math.cos(a + bend * 0.5) * length * 0.55, y + math.sin(a + bend * 0.5) * length * 0.55)
            tip = (x + math.cos(a + bend) * length, y + math.sin(a + bend) * length)
            pts = [(x + px * w / 2, y + py * w / 2), (mid[0] + px * w / 4, mid[1] + py * w / 4), tip,
                   (mid[0] - px * w / 4, mid[1] - py * w / 4), (x - px * w / 2, y - py * w / 2)]
            poly(d, pts, rng.uniform(lo, hi))
    blades = done(im)
    lum = lum + blades * 0.26
    h = h + blades * 0.4
    return lum, h, 3.0


def wood_grain(rng, bands=12):
    warp = 0.55 * lowpass(rng, 2, 5) + 0.18 * lowpass(rng, 4, 12)
    rings = np.sin(2 * math.pi * (YY / N * bands + warp))
    streak = lowpass(rng, 5, 90)
    return rings, streak


def wood(rng):
    rings, streak = wood_grain(rng)
    soft = steps(rings * 0.5 + 0.5, 3, 0.3) * 2 - 1
    lum = 0.82 + 0.045 * soft + 0.035 * streak + 0.015 * lowpass(rng, 24)
    lum -= 0.07 * smoothstep(0.86, 0.98, rings)  # the dark late-wood lines
    h = 0.5 + 0.08 * rings + 0.06 * streak
    return lum, h, 2.0


def planks(rng):
    rows = 4
    pid, dl, dr, v, rh, count = row_pieces(rng, rows, 200, 330)
    rings, streak = wood_grain(rng, 10)
    # each board takes its grain from a different place, and its own shade
    sy = rng.integers(0, N, count)
    sx = rng.integers(0, N, count)
    tone = rng.normal(0, 0.035, count)
    gy = (YY.astype(int) + sy[pid]) % N
    gx = (XX.astype(int) + sx[pid]) % N
    g = rings[gy, gx]
    s = streak[gy, gx]
    lum = 0.83 + tone[pid] + 0.04 * (steps(g * 0.5 + 0.5, 3, 0.3) * 2 - 1) + 0.03 * s
    lum -= 0.06 * smoothstep(0.86, 0.98, g)
    edge = np.minimum(np.minimum(dl, dr), np.minimum(v, rh - v))
    h = smoothstep(0, 4, edge) * 0.8 + 0.04 * g + 0.15
    lum += lit(h, 0.9)
    lum = np.where(edge < 1.2, 0.48, lum)  # the seams
    return lum, h, 6.0


def brick(rng):
    rows, per, gap = 16, 5, 5.0
    rh, bw = N / rows, N / per
    r = np.floor(YY / rh).astype(int)
    off = (r % 2) * bw / 2
    u = (XX + off) % bw
    v = YY - r * rh
    bid = r * per + (np.floor((XX + off) / bw).astype(int) % per)
    chip = 0.7 * lowpass(rng, 36)
    dist = np.minimum(np.minimum(u - gap / 2, bw - gap / 2 - u), np.minimum(v - gap / 2, rh - gap / 2 - v)) + chip
    tone = rng.normal(0, 0.05, rows * per)
    face = smoothstep(0, 4, dist)
    h = face * (0.75 + 0.06 * lowpass(rng, 14)) + 0.12
    brick_face = 0.79 + tone[bid] + 0.03 * lowpass(rng, 28) + 0.03 * (steps(lowpass(rng, 7) * 0.25 + 0.5, 3) - 0.5)
    mortar = 0.93 + 0.025 * lowpass(rng, 60)
    lum = np.where(dist > 0, brick_face, mortar) + lit(h, 0.9)
    return lum, h, 8.0


def cobble(rng):
    f1, f2, ids, _, _, n = voronoi(rng, 7)
    edge = (f2 - f1) / 2
    tone = rng.normal(0, 0.05, n)
    dome = smoothstep(2.0, 18.0, edge) ** 0.7
    h = dome * (0.8 + 0.08 * lowpass(rng, 30)) + 0.05 * lowpass(rng, 14)
    lum = 0.80 + tone[ids] + 0.025 * lowpass(rng, 40) + lit(h, 1.3)
    lum = steps(np.clip(lum, 0, 1.2), 14, 0.4)
    lum = np.where(edge < 2.5, 0.5 + 0.06 * lowpass(rng, 80), lum)
    return lum, h, 7.0


def slabs(rng, n, gap, bevel, base, var):
    size = N / n
    u, v = XX % size, YY % size
    sid = (np.floor(YY / size) * n + np.floor(XX / size)).astype(int)
    dist = np.minimum(np.minimum(u - gap / 2, size - gap / 2 - u), np.minimum(v - gap / 2, size - gap / 2 - v))
    dist += 0.6 * lowpass(rng, 90)
    tone = rng.normal(0, var, n * n)
    h = smoothstep(0, bevel, dist) * 0.8 + 0.1
    lum = base + tone[sid] + lit(h, 1.0)
    return lum, h, dist, u / size, v / size


def paving(rng):
    lum, h, dist, _, _ = slabs(rng, 4, 3.0, 4.0, 0.84, 0.03)
    lum += 0.03 * lowpass(rng, 12) + 0.02 * lowpass(rng, 60)
    speck = rng.random((N, N))
    lum -= (speck > 0.992) * 0.07
    # a few hairline cracks
    im, d = canvas(0)
    for _ in range(5):
        x, y = rng.uniform(0, N), rng.uniform(0, N)
        a = rng.uniform(0, 2 * math.pi)
        pts = [(x, y)]
        for _ in range(rng.integers(4, 9)):
            a += rng.normal(0, 0.6)
            x, y = x + math.cos(a) * 9, y + math.sin(a) * 9
            pts.append((x, y))
        line(d, pts, 1.2, 255)
    crack = np.asarray(im.resize((N, N), Image.BOX), float) / 255
    lum -= crack * 0.18
    lum = np.where(dist < 0.8, 0.55, lum)
    return lum, h - crack * 0.2, 8.0


def concrete(rng):
    lum = 0.86 + 0.035 * fbm(rng, 4) + 0.02 * (steps(lowpass(rng, 6) * 0.25 + 0.5, 3) - 0.5)
    speck = rng.random((N, N))
    lum -= (speck > 0.985) * 0.06
    lum += (speck < 0.008) * 0.05
    h = 0.5 + 0.1 * fbm(rng, 8) + (speck < 0.01) * 0.1
    return lum, h, 1.5


def asphalt(rng):
    lum = 0.78 + 0.03 * fbm(rng, 5)
    im, d = canvas()
    for _ in range(5200):
        x, y = rng.uniform(0, N), rng.uniform(0, N)
        r = rng.uniform(0.7, 1.9)
        ellipse(d, x, y, r, r * rng.uniform(0.7, 1.0), rng.choice([60, 80, 170, 190, 215]))
    stones = done(im)
    lum = lum + stones * 0.12
    h = 0.5 + stones * 0.4
    return lum, h, 2.5


def plaster(rng):
    lum = 0.88 + 0.025 * lowpass(rng, 3) + 0.025 * (steps(lowpass(rng, 9) * 0.25 + 0.5, 4) - 0.5)
    im, d = canvas()
    # broad trowel sweeps
    for _ in range(140):
        x, y = rng.uniform(0, N), rng.uniform(0, N)
        a = rng.uniform(0, math.pi)
        length, w = rng.uniform(40, 110), rng.uniform(10, 24)
        ca, sa = math.cos(a), math.sin(a)
        pts = []
        for i in range(12):
            t = i / 11 * 2 * math.pi
            px, py = math.cos(t) * length / 2, math.sin(t) * w / 2
            pts.append((x + px * ca - py * sa, y + px * sa + py * ca))
        poly(d, pts, 128 + rng.uniform(-14, 14))
    sweeps = done(im)
    lum = lum + sweeps * 0.25
    h = 0.5 + sweeps * 0.6 + 0.05 * lowpass(rng, 40)
    return lum, h, 2.0


def clay(rng):
    rows, cols = 8, 8
    rh, cw = N / rows, N / cols
    r = np.floor(YY / rh).astype(int)
    off = (r % 2) * cw / 2
    u = ((XX + off) % cw) / cw
    v = (YY - r * rh) / rh
    tid = r * cols + (np.floor((XX + off) / cw).astype(int) % cols)
    barrel = np.sin(math.pi * u)
    # the lower end of each tile is rounded; past it you see the row underneath, in its shadow
    end = 1 - 0.16 * (1 - barrel)
    under = v > end
    tone = rng.normal(0, 0.045, rows * cols)
    h = barrel ** 0.6 * 0.6 + v * 0.35
    h = np.where(under, (v - end) * 0.3, h)
    lum = 0.80 + tone[tid] + 0.2 * (barrel ** 0.5 - 0.7) + 0.07 * np.exp(-((u - 0.36) / 0.08) ** 2)
    lum += 0.02 * lowpass(rng, 40)
    lum = np.where(under, 0.52, lum)
    shadow = smoothstep(0.0, 0.13, v) * 0.15
    lum -= 0.15 - shadow  # the row above throws a little shade on each tile's top
    return lum, h, 5.0


def shingle_rows(rng, rows, lo, hi, base, var, chip=0.0):
    pid, dl, dr, v, rh, count = row_pieces(rng, rows, lo, hi)
    tone = rng.normal(0, var, count)
    end = np.minimum(dl, dr)
    lum = base + tone[pid] + 0.03 * lowpass(rng, 70, 6) + 0.02 * lowpass(rng, 20)
    # shade under the row above, a lit lower edge, then the dark line where the next row starts
    lum -= 0.12 * (1 - smoothstep(0, rh * 0.22, v))
    lum += 0.05 * smoothstep(rh * 0.7, rh * 0.92, v)
    h = 0.2 + 0.6 * v / rh
    if chip:
        corner = np.minimum(dl, dr) + (rh - v)
        cut = corner < chip
        lum = np.where(cut, 0.5, lum)
    lum = np.where((end < 1.3) | (rh - v < 2.2), 0.46, lum)
    return lum, h


def shingles(rng):
    lum, h = shingle_rows(rng, 9, 46, 80, 0.82, 0.045)
    return lum, h, 4.0


def slate(rng):
    lum, h = shingle_rows(rng, 8, 50, 110, 0.78, 0.07, chip=9)
    flakes = steps(lowpass(rng, 26, 10) * 0.25 + 0.5, 4) - 0.5
    lum += flakes * 0.05
    h = h + flakes * 0.2
    return lum, h, 4.0


def tiles(rng):
    lum, h, dist, u, v = slabs(rng, 4, 4.0, 3.0, 0.94, 0.015)
    lum += 0.05 * np.exp(-(((u + v) - 0.7) / 0.18) ** 2)  # a soft shine across each tile
    lum += 0.01 * lowpass(rng, 30)
    lum = np.where(dist < 0, 0.76 + 0.02 * lowpass(rng, 90), lum)
    return lum, h, 2.5


def carpet(rng):
    lum = 0.84 + 0.035 * lowpass(rng, 110) + 0.025 * lowpass(rng, 8) + 0.02 * (rng.random((N, N)) - 0.5)
    h = 0.5 + 0.2 * lowpass(rng, 110)
    return lum, h, 1.5


def fabric(rng):
    k = 48
    u, v = XX * k / N, YY * k / N
    warp = ((np.floor(u) + np.floor(v)) % 2) == 0
    prof = np.where(warp, np.sin(math.pi * (u % 1)), np.sin(math.pi * (v % 1)))
    lum = 0.79 + 0.11 * prof ** 0.7 + 0.025 * lowpass(rng, 40, 5) + 0.025 * lowpass(rng, 5, 40)
    h = prof * 0.6
    return lum, h, 1.2


def marble(rng):
    turb = fbm(rng, 2, 3)
    lum = 0.93 + 0.02 * fbm(rng, 3) + 0.025 * (steps(lowpass(rng, 4) * 0.25 + 0.5, 3) - 0.5)
    # soft clouded veins with a thin darker core, and a fainter second set across them
    s = np.sin(2 * math.pi * (XX / N * 1 + YY / N * 2) + 1.7 * turb)
    lum -= 0.07 * np.exp(-(s / 0.3) ** 2) + 0.1 * np.exp(-(s / 0.05) ** 2)
    s2 = np.sin(2 * math.pi * (XX / N * 3 - YY / N * 1) + 1.4 * fbm(rng, 3, 3))
    lum -= 0.03 * np.exp(-(s2 / 0.25) ** 2) + 0.04 * np.exp(-(s2 / 0.04) ** 2)
    h = 0.5 + 0.02 * turb
    return lum, h, 0.5


def sand(rng):
    ripple = np.sin(2 * math.pi * (YY / N * 7 + 0.45 * lowpass(rng, 2, 3)))
    grain = rng.random((N, N)) - 0.5
    lum = 0.86 + 0.025 * fbm(rng, 5) + 0.03 * steps(ripple * 0.5 + 0.5, 3) + 0.05 * grain
    h = 0.5 + 0.12 * ripple + 0.1 * grain
    return lum, h, 1.5


def rock(rng):
    f1, f2, ids, rx, ry, n = voronoi(rng, 4, 0.9)
    a = rng.normal(0, 0.012, n)
    b = rng.normal(0, 0.012, n)
    h = a[ids] * rx + b[ids] * ry + 0.25 * fbm(rng, 6) + smoothstep(0, 10, (f2 - f1) / 2) * 0.4
    tone = rng.normal(0, 0.05, n)
    shade = lit(h, 9.0)
    lum = 0.78 + tone[ids] + steps(np.clip(shade * 0.5 + 0.5, 0, 1), 4, 0.25) * 0.24 - 0.12
    lum += 0.03 * lowpass(rng, 30)
    lum = np.where((f2 - f1) / 2 < 2.2, 0.5, lum)
    return lum, h, 8.0


def metal(rng):
    lum = 0.86 + 0.028 * lowpass(rng, 3, 220) + 0.015 * lowpass(rng, 3) + 0.01 * lowpass(rng, 2, 60)
    h = 0.5 + 0.05 * lowpass(rng, 3, 220)
    return lum, h, 0.6


# name -> (painter, Roblox material, studs per tile)
TEXTURES = {
    "grass": (grass, "Grass", 8),
    "wood": (wood, "Wood", 4),
    "planks": (planks, "WoodPlanks", 8),
    "brick": (brick, "Brick", 8),
    "cobble": (cobble, "Cobblestone", 8),
    "paving": (paving, "Pavement", 8),
    "concrete": (concrete, "Concrete", 12),
    "asphalt": (asphalt, "Asphalt", 10),
    "plaster": (plaster, "Plaster", 10),
    "clay": (clay, "ClayRoofTiles", 6),
    "shingles": (shingles, "RoofShingles", 6),
    "slate": (slate, "Slate", 6),
    "tiles": (tiles, "CeramicTiles", 4),
    "carpet": (carpet, "Carpet", 4),
    "fabric": (fabric, "Fabric", 3),
    "marble": (marble, "Marble", 12),
    "sand": (sand, "Sand", 10),
    "rock": (rock, "Rock", 10),
    "metal": (metal, "Metal", 6),
}

# a colour for each in the contact sheet, close to how the town uses it
SAMPLE = {
    "grass": (0.42, 0.72, 0.30), "wood": (0.66, 0.45, 0.28), "planks": (0.78, 0.58, 0.38),
    "brick": (0.74, 0.36, 0.28), "cobble": (0.72, 0.68, 0.62), "paving": (0.86, 0.80, 0.70),
    "concrete": (0.80, 0.80, 0.78), "asphalt": (0.30, 0.30, 0.34), "plaster": (0.96, 0.90, 0.80),
    "clay": (0.80, 0.40, 0.26), "shingles": (0.36, 0.42, 0.58), "slate": (0.42, 0.44, 0.50),
    "tiles": (0.86, 0.92, 0.95), "carpet": (0.72, 0.40, 0.44), "fabric": (0.40, 0.56, 0.70),
    "marble": (0.95, 0.94, 0.92), "sand": (0.92, 0.84, 0.64), "rock": (0.58, 0.56, 0.54),
    "metal": (0.70, 0.72, 0.76),
}


def paint(name, seed):
    fn, material, studs = TEXTURES[name]
    rng = np.random.default_rng(seed)
    lum, h, depth = fn(rng)
    lum = np.clip(lum, 0, 1)
    rgb = np.clip(lum[..., None] * WARM, 0, 1)
    return (rgb * 255 + 0.5).astype(np.uint8), normal_map(h, depth), material, studs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="comma separated names")
    ap.add_argument("--sheet", help="also write a contact sheet PNG here (tinted, 2x2 tiles each)")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    names = args.only.split(",") if args.only else list(TEXTURES)
    index_path = os.path.join(OUT, "textures.json")
    index = json.load(open(index_path)) if os.path.exists(index_path) else {}
    cells = []
    for i, name in enumerate(TEXTURES):
        if name not in names:
            continue
        color, normal, material, studs = paint(name, 1000 + i)
        Image.fromarray(color, "RGB").save(os.path.join(OUT, name + ".png"), optimize=True)
        Image.fromarray(normal, "RGB").save(os.path.join(OUT, name + "_n.png"), optimize=True)
        index[name] = {"material": material, "studs": studs}
        print(f"{name:9s} {material:14s} mean {color.mean() / 255:.2f}")
        cells.append((name, color))
    index = {k: index[k] for k in TEXTURES if k in index}
    with open(index_path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")
    if args.sheet and cells:
        cell = 256
        cols = 5
        rows = math.ceil(len(cells) / cols)
        sheet = Image.new("RGB", (cols * cell, rows * (cell + 20)), (250, 246, 236))
        draw = ImageDraw.Draw(sheet)
        for k, (name, color) in enumerate(cells):
            tint = np.array(SAMPLE.get(name, (0.8, 0.8, 0.8)))
            tiled = np.tile(color, (2, 2, 1)).astype(float) * tint
            im = Image.fromarray(np.clip(tiled, 0, 255).astype(np.uint8)).resize((cell - 8, cell - 8), Image.LANCZOS)
            x, y = (k % cols) * cell, (k // cols) * (cell + 20)
            sheet.paste(im, (x + 4, y + 4))
            draw.text((x + 8, y + cell - 2), name, fill=(70, 48, 40))
        sheet.save(args.sheet)
        print("sheet", args.sheet)


if __name__ == "__main__":
    main()
