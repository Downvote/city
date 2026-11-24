#!/usr/bin/env python3
"""Paints the game's own textures: one tileable picture per material, in a soft hand-painted style,
and the looks (named variants of a material that only the parts asking for them wear: precast
panels, roller shutters, barrel roof tiles and so on).

    python3 scripts/gen_textures.py [--only lawn,brick] [--looks] [--sheet out.png] [--tiles 3] [--cell 384]

Writes art/textures/<name>.png (the colour map), <name>_n.png (a normal map), for the looks
<name>_r.png (a roughness map: white is matt, dark is glossy) and textures.json (each texture's
material and studs per tile, and a look's name, which src/shared/Data/Textures.luau must match).
--looks paints only the looks; --out writes somewhere else than art/textures.

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
    rough = 0.9 - blades * 0.08  # (a look needs a roughness map; the blades' tips a touch less dull)
    return lum, h, 3.0, rough


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


# the looks --------------------------------------------------------------------------------------------
# Drawn rather than photographed: flat faces, clear joints, a thin light on the edges that face the
# top left and a thin shade on the others, hardly any noise. Each returns a roughness map too.

def mix(a, b, t):
    return a + (b - a) * t


def brushed(rng, along, across, angle):
    """Tiling noise drawn out in one direction (an angle in radians), like the marks of a trowel:
    about `along` changes across the tile the long way and `across` the short way."""
    F = np.fft.fft2(rng.standard_normal((N, N)))
    fy = np.fft.fftfreq(N)[:, None] * N
    fx = np.fft.fftfreq(N)[None, :] * N
    ca, sa = math.cos(angle), math.sin(angle)
    F *= np.exp(-(((fx * ca + fy * sa) / along) ** 2 + ((fy * ca - fx * sa) / across) ** 2))
    r = np.real(np.fft.ifft2(F))
    return (r - r.mean()) / (r.std() + 1e-9)


def cells(nx, ny, stagger=0.0):
    """A grid of nx by ny cells, every other row moved along by `stagger` of a cell: each pixel's
    cell id, how far it is from the cell's left and top in pixels, and the cell's size."""
    cw, ch = N / nx, N / ny
    row = np.floor(YY / ch).astype(int)
    x = (XX + (row % 2) * cw * stagger) % N
    col = np.floor(x / cw).astype(int) % nx
    return row * nx + col, x - col * cw, YY - row * ch, cw, ch


def corner(a, b, r):
    """How far inside a corner a pixel is, its two edges a and b away, the corner rounded to r."""
    return np.where((a < r) & (b < r), r - np.hypot(r - a, r - b), np.minimum(a, b))


def inside(u, v, cw, ch, gap, r=0.0):
    """How far a pixel is inside its cell's face, the joint between faces being `gap` wide."""
    a = np.minimum(u, cw - u) - gap / 2
    b = np.minimum(v, ch - v) - gap / 2
    return corner(a, b, r) if r else np.minimum(a, b)


def panel(rng):
    # precast panels, two across and three down: a groove between them, four bolt holes a panel
    nx, ny = 2, 3
    cid, u, v, cw, ch = cells(nx, ny)
    d = inside(u, v, cw, ch, 5.0)
    face = smoothstep(0, 1.6, d)
    tone = rng.normal(0, 0.011, nx * ny)
    # marks the rain leaves, running down from each panel's top edge and fading
    runs_down = lowpass(rng, 34, 1.3)
    lum = 0.885 + tone[cid] + 0.013 * runs_down * (1 - 0.6 * v / ch) + 0.008 * lowpass(rng, 3)
    bx = np.minimum(u, cw - u) - cw * 0.13
    by = np.minimum(v, ch - v) - ch * 0.2
    r = np.hypot(bx, by)
    hole = 1 - smoothstep(4.6, 6.0, r)
    h = smoothstep(0, 2.5, d) * 0.5 - hole * 0.45 + 0.3
    lum = lum + lit(h, 0.42)
    lum = mix(0.60, lum, face)
    lum = mix(lum, 0.63, (1 - smoothstep(3.4, 4.8, r)) * 0.9)
    rough = mix(0.96, 0.84, face)
    return lum, h, 3.0, rough


def stucco(rng):
    # painted render: broad sweeps of the trowel, each patch worked in its own direction
    lum = 0.905 + 0.008 * lowpass(rng, 2)
    marks = np.zeros((N, N))
    for angle in (0.5, 1.9, 2.8):
        patch = smoothstep(-0.2, 0.9, lowpass(rng, 2))
        marks += brushed(rng, 5, 22, angle) * patch
    marks /= 1.6
    soft = steps(np.clip(marks * 0.22 + 0.5, 0, 1), 5, 0.42) - 0.5
    lum += 0.034 * soft
    h = 0.5 + 0.16 * soft
    rough = np.full((N, N), 0.92) + 0.03 * soft
    return lum, h, 2.2, rough


def maple(rng):
    # brick in running bond: no two bricks quite the same length or the same shade
    rows, per = 12, 4
    rh, bw = N / rows, N / per
    row = np.floor(YY / rh).astype(int)
    v = YY - row * rh
    bid = np.zeros((N, N), int)
    dl = np.zeros((N, N))
    dr = np.zeros((N, N))
    for r in range(rows):
        edges = (np.arange(per) + 0.5 * (r % 2)) * bw + rng.uniform(-5, 5, per)
        m = row == r
        x = (XX[m] - edges[0]) % N
        rel = np.append(edges - edges[0], N)
        k = np.searchsorted(rel, x, side="right") - 1
        bid[m] = r * per + k
        dl[m] = x - rel[k]
        dr[m] = rel[k + 1] - x
    count = rows * per
    side = rng.uniform(1.8, 3.4, count)
    bed = rng.uniform(1.8, 3.0, count)
    d = corner(np.minimum(dl, dr) - side[bid], np.minimum(v, rh - v) - bed[bid], 4.0)
    face = smoothstep(0, 1.5, d)
    tone = rng.normal(0, 0.022, count)
    pick = rng.random(count)
    tone = np.where(pick < 0.12, tone - 0.075, np.where(pick > 0.9, tone + 0.04, tone))
    lum = 0.855 + tone[bid] + 0.014 * (0.5 - v / rh) + 0.008 * lowpass(rng, 9, 22)
    h = smoothstep(0, 3.0, d) * 0.6 + 0.2
    lum = lum + lit(h, 0.45)
    lum = mix(0.58 + 0.01 * lowpass(rng, 40), lum, face)
    rough = mix(0.97, 0.82, face)
    return lum, h, 3.5, rough


def mosaic(rng):
    # small glazed facade tiles, eight by eight, here and there a darker one
    n = 8
    cid, u, v, cw, ch = cells(n, n)
    d = inside(u, v, cw, ch, 3.4, 4.0)
    face = smoothstep(0, 1.4, d)
    tone = rng.normal(0, 0.014, n * n)
    pick = rng.random(n * n)
    tone = np.where(pick < 0.11, tone - 0.10, np.where(pick > 0.93, tone + 0.035, tone))
    shine = 0.04 * np.exp(-(((u + v) / cw - 0.62) / 0.2) ** 2)
    h = smoothstep(0, 4.5, d) * 0.55 + 0.2
    lum = 0.875 + tone[cid] + shine + lit(h, 0.5)
    lum = mix(0.61, lum, face)
    rough = mix(0.9, 0.32, face)
    return lum, h, 3.0, rough


def checker(rng):
    # floor tiles laid light and mid grey by turns, so one colour paints both
    n = 4
    cid, u, v, cw, ch = cells(n, n)
    mid = ((cid % n) + (cid // n)) % 2 == 1
    d = inside(u, v, cw, ch, 3.6)
    face = smoothstep(0, 1.4, d)
    tone = rng.normal(0, 0.008, n * n)
    shine = 0.028 * np.exp(-(((u + v) / cw - 0.7) / 0.24) ** 2)
    h = smoothstep(0, 3.0, d) * 0.45 + 0.25
    lum = np.where(mid, 0.60, 0.95) + tone[cid] + shine + lit(h, 0.3)
    lum = mix(0.44, lum, face)
    rough = mix(0.88, 0.26, face)
    return lum, h, 2.2, rough


def corrugated(rng):
    # corrugated sheet, the ridges upright; one lap where two sheets meet, with its screws
    k = 16
    ph = 2 * math.pi * k * XX / N
    crest = np.cos(ph)  # 1 along a ridge's top, -1 down in the furrow
    toward = -np.sin(ph)  # 1 on the side of a ridge that faces the light
    lum = 0.76 + 0.18 * steps(toward * 0.5 + 0.5, 4, 0.3) - 0.04 * smoothstep(0.2, 1.0, -crest)
    lum += 0.01 * lowpass(rng, 40, 1.4)
    h = 0.5 + 0.4 * crest
    lap = 0.62 * N
    below = YY - lap
    lum -= 0.11 * smoothstep(-1.2, 0.0, below) * (1 - smoothstep(0.0, 7.0, below))  # the upper sheet's shade
    lum = mix(lum, 0.5, smoothstep(-1.4, -0.4, below) * (1 - smoothstep(0.4, 1.4, below)))
    h = h + 0.12 * (1 - smoothstep(-1.0, 1.0, below))
    pitch = N / k
    sx = (XX + pitch) % (2 * pitch) - pitch  # a screw on every other ridge
    r = np.hypot(sx, YY - (lap - 13))
    head = 1 - smoothstep(2.6, 3.8, r)
    lum = mix(lum, 0.9 - 0.2 * smoothstep(-2.0, 3.0, sx + (YY - (lap - 13))), head)
    lum = mix(lum, 0.52, smoothstep(3.0, 3.8, r) * (1 - smoothstep(4.4, 5.2, r)) * 0.8)
    h = h + 0.25 * head
    rough = np.full((N, N), 0.46) + 0.05 * smoothstep(0.2, 1.0, -crest)
    return lum, h, 7.0, rough


def shutter(rng):
    # a roller shutter: slats running across, each one curved, lit above and shaded at its lip
    k = 10
    v = (YY * k / N) % 1
    lum = 0.85 + 0.05 * np.exp(-((v - 0.2) / 0.1) ** 2) - 0.10 * smoothstep(0.5, 0.9, v)
    lum += 0.007 * lowpass(rng, 1.5, 70)
    lip = smoothstep(0.895, 0.93, v)
    lum = mix(lum, 0.5, lip)
    lum -= 0.06 * (1 - smoothstep(0.0, 0.07, v))  # the lip above throws a little shade
    h = np.sin(math.pi * np.clip(v / 0.92, 0, 1)) ** 0.7 * 0.6 + 0.1
    rough = mix(np.full((N, N), 0.5), 0.9, lip)
    return lum, h, 4.0, rough


def slats(rng):
    # upright timber slats with a gap between each and the next
    k = 8
    pw = N / k
    col = np.floor(XX / pw).astype(int)
    u = XX - col * pw
    d = np.minimum(u, pw - u) - 6.5
    face = smoothstep(0, 1.5, d)
    grain = lowpass(rng, 46, 1.6)
    late = lowpass(rng, 90, 2.4)
    shift = rng.integers(0, N, k)
    gy = (YY.astype(int) + shift[col]) % N
    gx = XX.astype(int)
    tone = rng.normal(0, 0.024, k)
    lum = 0.87 + tone[col] + 0.022 * (steps(grain[gy, gx] * 0.25 + 0.5, 3, 0.3) - 0.5)
    lum -= 0.03 * smoothstep(1.3, 2.1, late[gy, gx])  # a few darker lines of grain
    h = smoothstep(0, 3.5, d) * 0.7 + 0.1
    lum = lum + lit(h, 0.4)
    # the gap is in shade, deepest beside the slat that stands between it and the light
    gap = 0.3 + 0.1 * smoothstep(0.0, 13.0, (u + 6.5) % pw)
    lum = mix(gap, lum, face)
    rough = mix(1.0, 0.72, face)
    return lum, h, 5.0, rough


def barrel(rng):
    # barrel roof tiles: rounded covers running down the roof over the channels between them,
    # each row's lower end lapping the row below
    cols, rows = 6, 4
    cid, u, v, cw, ch = cells(cols, rows)
    t = v / ch
    half = 0.33 + 0.045 * t  # a cover is a little wider at its lower end
    x = (u / cw - 0.5) / half
    edge = (1 - np.abs(x)) * half * cw  # pixels in from the cover's side
    on = smoothstep(-0.7, 0.7, edge)
    up = np.sqrt(np.clip(1 - x * x, 0, 1))
    tone = rng.normal(0, 0.03, cols * rows)
    cover = 0.66 + tone[cid] + 0.27 * steps(np.clip(0.8 * up - 0.5 * x, 0, 1), 4, 0.32)
    cover -= 0.13 * (1 - smoothstep(0.0, 0.14, t))  # the shade of the row above
    cover += 0.03 * smoothstep(0.72, 0.93, t)
    px = ((u / cw + 0.5) % 1 - 0.5) / (0.5 - half)  # across the channel, -1..1
    pan = 0.54 + 0.15 * smoothstep(-0.6, 0.9, px) - 0.08 * (1 - smoothstep(0.0, 0.14, t))
    lum = mix(pan, cover, on)
    lum = mix(lum, 0.42, (1 - smoothstep(0.5, 1.6, np.abs(edge))) * 0.7)
    lum = mix(lum, 0.42, smoothstep(ch - 3.4, ch - 2.2, v) * mix(0.5, 1.0, on))
    # heights in pixels here, so the normal map bends the light round each cover as a real one would
    h = mix(1.5 * px * px, 3.0 + 7.0 * up, on) + 2.5 * t
    rough = mix(np.full((N, N), 0.8), 0.6, on)
    return lum, h, 1.0, rough


def flags(rng):
    # big paving slabs, each row laid half a slab along from the last
    cols, rows = 2, 4
    cid, u, v, cw, ch = cells(cols, rows, 0.5)
    d = inside(u, v, cw, ch, 5.0, 4.0) + 0.45 * lowpass(rng, 40)
    face = smoothstep(0, 1.6, d)
    tone = rng.normal(0, 0.02, cols * rows)
    lum = 0.88 + tone[cid] + 0.014 * (steps(lowpass(rng, 3) * 0.25 + 0.5, 3, 0.4) - 0.5)
    h = smoothstep(0, 3.5, d) * 0.55 + 0.2
    lum = lum + lit(h, 0.45)
    lum = mix(0.57, lum, face)
    rough = mix(0.97, 0.86, face)
    return lum, h, 3.0, rough


def street(rng):
    # street asphalt: fine stones, one mended patch and one hairline crack
    lum = 0.80 + 0.008 * fbm(rng, 3, 3)
    im, d = canvas()
    for _ in range(6500):
        x, y = rng.uniform(0, N), rng.uniform(0, N)
        r = rng.uniform(0.5, 1.15)
        ellipse(d, x, y, r, r * rng.uniform(0.75, 1.0), rng.choice([84, 100, 158, 172, 190]))
    stones = done(im)
    lum = lum + stones * 0.085
    h = 0.5 + stones * 0.3
    # the patch: an oblong a shade darker with a sealed edge, wholly inside the tile
    qx = np.abs(XX - 300) - 92
    qy = np.abs(YY - 170) - 54
    sd = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - 10
    sd = sd + 2.2 * lowpass(rng, 14)
    patch = 1 - smoothstep(-1.0, 1.0, sd)
    lum -= 0.018 * patch
    lum -= 0.035 * (1 - smoothstep(0.6, 1.8, np.abs(sd)))
    im, d = canvas(0)
    x, y, a = 40.0, 330.0, 0.35
    pts = [(x, y)]
    for _ in range(26):
        a = 0.35 + rng.normal(0, 0.55)
        x, y = x + math.cos(a) * 10, y + math.sin(a) * 10
        pts.append((x, y))
    line(d, pts, 1.1, 255)
    crack = np.asarray(im.resize((N, N), Image.BOX), float) / 255
    lum -= crack * 0.12
    h = h - crack * 0.25 - 0.04 * patch
    rough = np.full((N, N), 0.93) - 0.06 * patch
    return lum, h, 1.6, rough


def meadow(rng):
    # the grass under foot, terrain and grass parts alike: no pattern and fully matt. The user:
    # "make the floor grass texture smoother" (Roblox's own grass is speckled)
    lum = np.full((N, N), 0.98)
    return lum, np.zeros((N, N)), 0.0, np.ones((N, N))


def blade(rng):
    # the long grass's blades (client World/Grass): no pattern at all and fully matt, so the
    # blades are smooth and don't shine (the user: "too shiny", then "make their textures smoother")
    lum = np.full((N, N), 0.98)
    return lum, np.zeros((N, N)), 0.0, np.ones((N, N))


def canvas_weave(rng):
    # awning canvas: a plain weave of thick threads, some a little heavier than the rest
    k = 40
    u, v = XX * k / N, YY * k / N
    iu, iv = np.floor(u).astype(int), np.floor(v).astype(int)
    over = ((iu + iv) % 2) == 0
    warp = rng.normal(0, 0.009, k)
    weft = rng.normal(0, 0.009, k)
    prof = np.where(over, np.sin(math.pi * (u % 1)), np.sin(math.pi * (v % 1)))
    lum = 0.845 + 0.075 * prof ** 0.8 + np.where(over, warp[iu % k], weft[iv % k])
    lum += 0.007 * lowpass(rng, 3, 30) + 0.007 * lowpass(rng, 30, 3)
    h = prof * 0.5
    rough = np.full((N, N), 0.95)
    return lum, h, 1.2, rough


def cliff(rng):
    # beds of rock lying one on another, thick and thin, each its own shade and broken here and
    # there by an upright crack: a lit ledge along the top of every bed, shade under the one above
    wy = (YY + 6 * lowpass(rng, 1.5, 1.2) + 1.6 * lowpass(rng, 5, 2)) % N
    wx = XX + 6 * lowpass(rng, 1.5, 3)
    beds = [0.0]
    while beds[-1] < N - 30:
        beds.append(beds[-1] + (rng.uniform(20, 34) if len(beds) % 3 == 0 else rng.uniform(52, 96)))
    beds = np.array(beds) * N / beds[-1]
    nb = len(beds) - 1
    b = np.clip(np.searchsorted(beds, wy, side="right") - 1, 0, nb - 1)
    top = wy - beds[b]
    bot = beds[b + 1] - wy
    bid = np.zeros((N, N), int)
    dl = np.zeros((N, N))
    dr = np.zeros((N, N))
    count = 0
    for i in range(nb):
        thick = beds[i + 1] - beds[i]
        cuts = np.array(runs(rng, 90, 260) if thick > 40 else runs(rng, 170, 420))
        cuts = np.append(cuts, N)
        m = b == i
        x = (wx[m] - rng.uniform(0, N)) % N
        k = np.clip(np.searchsorted(cuts, x, side="right") - 1, 0, len(cuts) - 2)
        bid[m] = count + k
        dl[m] = x - cuts[k]
        dr[m] = cuts[k + 1] - x
        count += len(cuts) - 1
    rx, ry = (dl - dr) / 2, (top - bot) / 2
    bed_tone = rng.normal(0, 0.04, nb)
    tone = rng.normal(0, 0.018, count)
    # a second face cut across each block at its own angle, a shade apart from the first
    ang = rng.uniform(0.25, math.pi - 0.25, count)
    off = rng.normal(0, 20, count)
    turn = rng.choice([-0.045, -0.03, 0.03, 0.045], count)
    cut = smoothstep(-1.0, 1.0, rx * np.cos(ang[bid]) + ry * np.sin(ang[bid]) - off[bid])
    lum = 0.80 + bed_tone[b] + tone[bid] + turn[bid] * cut
    lum += 0.08 * (1 - smoothstep(1.5, 6.5, top))
    lum -= 0.13 * (1 - smoothstep(0.0, 13.0, bot))
    lum -= 0.045 * (1 - smoothstep(0.0, 7.0, dr))
    lum += 0.03 * (1 - smoothstep(1.5, 5.0, dl))
    lum = mix(0.5, lum, smoothstep(0.5, 1.7, np.minimum(dl, dr)))  # the cracks are finer than the beds' lines
    lum = mix(0.43, lum, smoothstep(0.9, 2.2, np.minimum(top, bot)))
    edge = np.minimum(np.minimum(dl, dr), np.minimum(top, bot))
    deep = rng.uniform(0, 0.3, nb)
    h = smoothstep(0, 6.0, edge) * 0.5 + deep[b] + 0.1 * cut * np.sign(turn[bid])
    rough = np.full((N, N), 0.92)
    return lum, h, 5.0, rough


# name -> (painter, Roblox material, studs per tile)
TEXTURES = {
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
    "meadow": (meadow, "Grass", 32),
}

# name -> (painter, Roblox material, studs per tile, the look's name): a part whose material is
# "Concrete:Panel" wears the look Panel of Concrete; nothing else does
LOOKS = {
    "panel": (panel, "Concrete", 12, "Panel"),
    "stucco": (stucco, "Concrete", 10, "Stucco"),
    "maple": (maple, "Brick", 6, "Maple"),
    "mosaic": (mosaic, "CeramicTiles", 4, "Mosaic"),
    "checker": (checker, "CeramicTiles", 4, "Checker"),
    "corrugated": (corrugated, "Metal", 6, "Corrugated"),
    "shutter": (shutter, "Metal", 4, "Shutter"),
    "slats": (slats, "WoodPlanks", 4, "Slats"),
    "barrel": (barrel, "ClayRoofTiles", 6, "Barrel"),
    "slabs": (flags, "Pavement", 8, "Slabs"),
    "street": (street, "Asphalt", 16, "Street"),
    "canvas": (canvas_weave, "Fabric", 3, "Canvas"),
    "cliff": (cliff, "Rock", 16, "Cliff"),
    # our painted grass is a look a part has to ask for (Grass itself wears the plain meadow)
    "lawn": (grass, "Grass", 8, "Lawn"),
    "blade": (blade, "SmoothPlastic", 16, "Blade"),
}

# seeds kept from before a texture moved between the two lists
SEEDS = {"lawn": 1000}

# a colour for each in the contact sheet, close to how the town uses it
SAMPLE = {
    "lawn": (0.42, 0.72, 0.30), "wood": (0.66, 0.45, 0.28), "planks": (0.78, 0.58, 0.38),
    "brick": (0.74, 0.36, 0.28), "cobble": (0.72, 0.68, 0.62), "paving": (0.86, 0.80, 0.70),
    "concrete": (0.80, 0.80, 0.78), "asphalt": (0.30, 0.30, 0.34), "plaster": (0.96, 0.90, 0.80),
    "clay": (0.80, 0.40, 0.26), "shingles": (0.36, 0.42, 0.58), "slate": (0.42, 0.44, 0.50),
    "tiles": (0.86, 0.92, 0.95), "carpet": (0.72, 0.40, 0.44), "fabric": (0.40, 0.56, 0.70),
    "marble": (0.95, 0.94, 0.92), "sand": (0.92, 0.84, 0.64), "rock": (0.58, 0.56, 0.54),
    "metal": (0.70, 0.72, 0.76), "meadow": (0.53, 0.67, 0.34),
    "panel": (0.80, 0.79, 0.76), "stucco": (0.96, 0.87, 0.72), "maple": (0.78, 0.40, 0.30),
    "mosaic": (0.92, 0.58, 0.30), "checker": (0.86, 0.34, 0.30), "corrugated": (0.50, 0.66, 0.74),
    "shutter": (0.74, 0.76, 0.78), "slats": (0.74, 0.54, 0.36), "barrel": (0.34, 0.47, 0.58),
    "slabs": (0.84, 0.80, 0.73), "street": (0.36, 0.36, 0.40), "canvas": (0.82, 0.26, 0.22),
    "cliff": (0.66, 0.58, 0.50), "blade": (0.44, 0.62, 0.30),
}


def entries():
    """Every texture in order: name, painter, material, studs per tile, look (None for a
    material's own texture) and the seed it is painted from."""
    # (the seeds stay what they were when grass was the first material's texture: wood is still
    # 1001 and the lawn still paints from grass's 1000)
    out = [(name, fn, material, studs, None, 1000 + i)
           for i, (name, (fn, material, studs)) in enumerate(TEXTURES.items(), 1)]
    out += [(name, fn, material, studs, look, SEEDS.get(name, 2000 + i))
            for i, (name, (fn, material, studs, look)) in enumerate(LOOKS.items())]
    return out


def paint(fn, seed):
    """A painter's colour map, normal map and roughness map (None when it paints none)."""
    rng = np.random.default_rng(seed)
    got = fn(rng)
    lum, h, depth = got[:3]
    lum = np.clip(lum, 0, 1)
    rgb = np.clip(lum[..., None] * WARM, 0, 1)
    rough = None
    if len(got) > 3:
        r = (np.clip(got[3], 0, 1) * 255 + 0.5).astype(np.uint8)
        rough = np.stack([r, r, r], -1)
    return (rgb * 255 + 0.5).astype(np.uint8), normal_map(h, depth), rough


def seam(color):
    """How a picture's opposite edges meet, against the sharpest step between two neighbouring rows
    or columns inside it: 1 or less for a picture that tiles."""
    c = color.astype(float).mean(-1)
    rows = np.abs(c - np.roll(c, 1, 0)).mean(1)
    cols = np.abs(c - np.roll(c, 1, 1)).mean(0)
    return max(rows[0] / (rows[1:].max() + 1e-9), cols[0] / (cols[1:].max() + 1e-9))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="comma separated names")
    ap.add_argument("--looks", action="store_true", help="only the looks")
    ap.add_argument("--sheet", help="also write a contact sheet PNG here (tinted, each tiled)")
    ap.add_argument("--tiles", type=int, default=2, help="copies each way in a cell of the sheet")
    ap.add_argument("--cell", type=int, default=256, help="pixels a cell of the sheet")
    ap.add_argument("--plain", action="store_true", help="the sheet untinted, as painted")
    ap.add_argument("--out", default=OUT, help="where to write (default art/textures)")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    every = entries()
    known = [e[0] for e in every]
    names = args.only.split(",") if args.only else [e[0] for e in every if e[4] or not args.looks]
    for name in names:
        if name not in known:
            raise SystemExit(f"no texture called {name}")
    index_path = os.path.join(args.out, "textures.json")
    index = json.load(open(index_path)) if os.path.exists(index_path) else {}
    shown = []
    for name, fn, material, studs, look, seed in every:
        if name not in names:
            continue
        color, normal, rough = paint(fn, seed)
        Image.fromarray(color, "RGB").save(os.path.join(args.out, name + ".png"), optimize=True)
        Image.fromarray(normal, "RGB").save(os.path.join(args.out, name + "_n.png"), optimize=True)
        if rough is not None:
            Image.fromarray(rough, "RGB").save(os.path.join(args.out, name + "_r.png"), optimize=True)
        index[name] = {"material": material, "studs": studs}
        if look:
            index[name]["look"] = look
        print(f"{name:10s} {material + (':' + look if look else ''):24s} mean {color.mean() / 255:.2f}  seam {seam(color):.2f}")
        shown.append((name, color))
    index = {k: index[k] for k in known if k in index}
    with open(index_path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")
    if args.sheet and shown:
        cell = args.cell
        cols = min(5, len(shown))
        rows = math.ceil(len(shown) / cols)
        sheet = Image.new("RGB", (cols * cell, rows * (cell + 20)), (250, 246, 236))
        draw = ImageDraw.Draw(sheet)
        for k, (name, color) in enumerate(shown):
            tint = np.ones(3) if args.plain else np.array(SAMPLE.get(name, (0.8, 0.8, 0.8)))
            tiled = np.tile(color, (args.tiles, args.tiles, 1)).astype(float) * tint
            im = Image.fromarray(np.clip(tiled, 0, 255).astype(np.uint8)).resize((cell - 8, cell - 8), Image.LANCZOS)
            x, y = (k % cols) * cell, (k // cols) * (cell + 20)
            sheet.paste(im, (x + 4, y + 4))
            draw.text((x + 8, y + cell - 2), name, fill=(70, 48, 40))
        sheet.save(args.sheet)
        print("sheet", args.sheet)


if __name__ == "__main__":
    main()
