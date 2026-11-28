#!/usr/bin/env python3
"""Lays out and draws a GUI tree dumped by tools/preview/ui_dump.luau, close enough to Roblox to
judge a screen's look: sizes and anchors, list and grid layouts, padding, automatic sizes,
rounded corners, strokes, gradients, outlined text, emoji, clipping, rotation and the UIScale on
the ScreenGui.

    python3 tools/preview/ui_render.py ui.json out.png [--bg scene.png] [--ss 2]

Fonts: Fredoka One for FredokaOne, Inter for Builder Sans and Gotham. Run
tools/preview/fonts.sh once to fetch Fredoka One; it falls back to DejaVu without it.
"""
import argparse
import json
import math
import os
import re
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONT_DIRS = [os.path.expanduser("~/.local/share/fonts-preview"), "/usr/share/fonts/opentype/inter",
             "/usr/share/fonts/truetype/dejavu"]
EMOJI_FONT = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"

FONT_FILES = {
    "FredokaOne": "FredokaOne.ttf",
    "LuckiestGuy": "FredokaOne.ttf",
    "BuilderSansExtraBold": "Inter-ExtraBold.otf",
    "BuilderSansBold": "Inter-Bold.otf",
    "BuilderSansMedium": "Inter-Medium.otf",
    "BuilderSans": "Inter-Regular.otf",
    "GothamBlack": "Inter-Black.otf",
    "GothamBold": "Inter-Bold.otf",
    "GothamMedium": "Inter-Medium.otf",
    "Gotham": "Inter-Regular.otf",
    "SourceSansBold": "Inter-Bold.otf",
    "SourceSans": "Inter-Regular.otf",
}

_font_cache = {}


def font_path(name):
    f = FONT_FILES.get(name, "Inter-Bold.otf")
    for d in FONT_DIRS:
        p = os.path.join(d, f)
        if os.path.exists(p):
            return p
    return "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def get_font(name, size):
    size = max(1, int(round(size)))
    key = (name, size)
    if key not in _font_cache:
        _font_cache[key] = ImageFont.truetype(font_path(name), size)
    return _font_cache[key]


_emoji_cache = {}
EMOJI_RE = re.compile(
    "([\U0001F000-\U0001FAFF☀-➿⬀-⯿←-⇿⌀-⏿⤴⤵■-◿✀-➿]"
    "[️‍\U0001F3FB-\U0001F3FF]*(?:[\U0001F000-\U0001FAFF☀-➿][️]?)*)")
EMOJI_ONLY = set()


def emoji_image(ch, size):
    size = max(4, int(round(size)))
    key = (ch, size)
    if key in _emoji_cache:
        return _emoji_cache[key]
    try:
        f = ImageFont.truetype(EMOJI_FONT, 109)
        im = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.text((10, 10), ch, font=f, embedded_color=True)
        bbox = im.getbbox()
        if not bbox:
            raise ValueError
        im = im.crop(bbox)
        scale = size / max(im.width, im.height)
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    except Exception:
        im = None
    _emoji_cache[key] = im
    return im


def is_emoji_run(s):
    return bool(EMOJI_RE.fullmatch(s))


def split_runs(text):
    parts = []
    pos = 0
    for m in EMOJI_RE.finditer(text):
        if m.start() > pos:
            parts.append(text[pos:m.start()])
        parts.append(m.group(0))
        pos = m.end()
    if pos < len(text):
        parts.append(text[pos:])
    return parts


def text_width(text, font_name, size):
    w = 0
    f = get_font(font_name, size)
    for run in split_runs(text):
        if is_emoji_run(run):
            w += size * 1.05
        else:
            w += f.getlength(run)
    return w


def wrap_lines(text, font_name, size, width, wrap):
    out = []
    for para in text.split("\n"):
        if not wrap or width <= 0:
            out.append(para)
            continue
        words = para.split(" ")
        line = ""
        for wd in words:
            trial = wd if line == "" else line + " " + wd
            if text_width(trial, font_name, size) <= width + 0.5 or line == "":
                line = trial
            else:
                out.append(line)
                line = wd
        out.append(line)
    return out


# -------------------------------------------------------------------------------------------------
# helpers on the dumped tree

GUI_CLASSES = {"Frame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton", "ScrollingFrame",
               "ViewportFrame", "CanvasGroup", "VideoFrame"}
TEXT_CLASSES = {"TextLabel", "TextButton", "TextBox"}


def P(node, key, default=None):
    v = node["props"].get(key)
    return default if v is None else v


def mods(node):
    m = {}
    for c in node["children"]:
        if c["class"].startswith("UI"):
            m.setdefault(c["class"], c)
    return m


def gui_children(node):
    return [c for c in node["children"] if c["class"] in GUI_CLASSES]


def udim(u, size):
    return u[0] * size + u[1]


def padding(node, w, h):
    pad = mods(node).get("UIPadding")
    if not pad:
        return 0, 0, 0, 0
    return (udim(P(pad, "PaddingLeft", [0, 0]), w), udim(P(pad, "PaddingTop", [0, 0]), h),
            udim(P(pad, "PaddingRight", [0, 0]), w), udim(P(pad, "PaddingBottom", [0, 0]), h))


def auto_axes(node):
    a = P(node, "AutomaticSize", "None")
    return a in ("X", "XY"), a in ("Y", "XY")


def text_metrics(node, wrap_width):
    text = P(node, "Text", "") or ""
    if text == "":
        return 0, 0
    size = P(node, "TextSize", 14)
    font = P(node, "Font", "BuilderSansBold")
    lines = wrap_lines(text, font, size, wrap_width, P(node, "TextWrapped", False) and wrap_width > 0)
    w = max(text_width(l, font, size) for l in lines)
    return w, len(lines) * size * 1.0


# -------------------------------------------------------------------------------------------------
# layout


def base_size(node, pw, ph):
    s = P(node, "Size", [0, 100, 0, 100])
    return udim(s[:2], pw), udim(s[2:], ph)


def measure(node, pw, ph):
    """The node's size given its parent's content size, with AutomaticSize applied."""
    w, h = base_size(node, pw, ph)
    ax, ay = auto_axes(node)
    if not (ax or ay):
        node["_size"] = (w, h)
        return w, h
    pl, pt, pr, pb = padding(node, w, h)
    cw, ch = content_size(node, max(0, w - pl - pr), max(0, h - pt - pb), ax, ay)
    # a UISizeConstraint's MaxSize caps a box that sizes itself across, and words wrap at it
    cap = mods(node).get("UISizeConstraint")
    maxw = (P(cap, "MaxSize", None) or [None])[0] if cap else None
    if maxw is not None and maxw >= 1e6:
        maxw = None
    if node["class"] in TEXT_CLASSES:
        if ax and maxw is not None:
            tw, th = text_metrics(node, max(0, maxw - pl - pr))
        else:
            tw, th = text_metrics(node, 0 if ax else max(0, w - pl - pr))
        cw, ch = max(cw, tw), max(ch, th)
    if ax:
        w = max(w, cw + pl + pr)
        if maxw is not None:
            w = min(w, maxw)
    if ay:
        h = max(h, ch + pt + pb)
    node["_size"] = (w, h)
    return w, h


def content_size(node, w, h, ax, ay):
    kids = [c for c in gui_children(node) if P(c, "Visible", True)]
    m = mods(node)
    lst = m.get("UIListLayout")
    grid = m.get("UIGridLayout")
    if grid:
        cell = P(grid, "CellSize", [0, 100, 0, 100])
        pad = P(grid, "CellPadding", [0, 5, 0, 5])
        cw, chh = udim(cell[:2], w), udim(cell[2:], h)
        px, py = udim(pad[:2], w), udim(pad[2:], h)
        per = max(1, int((w + px) // (cw + px))) if w > 0 else len(kids)
        rows = math.ceil(len(kids) / per) if kids else 0
        return per * (cw + px) - px, rows * (chh + py) - py
    sizes = [measure(c, w, h) for c in kids]
    if lst:
        horiz = P(lst, "FillDirection", "Vertical") == "Horizontal"
        gap = udim(P(lst, "Padding", [0, 0]), w if horiz else h)
        if not sizes:
            return 0, 0
        if horiz:
            if P(lst, "Wraps", False) and not ax and w > 0:
                rows, x, rowh, total = 0, 0, 0, 0
                for sw, sh in sizes:
                    if x > 0 and x + sw > w:
                        total += rowh + gap
                        x, rowh = 0, 0
                    x += sw + gap
                    rowh = max(rowh, sh)
                return w, total + rowh
            return sum(s[0] for s in sizes) + gap * (len(sizes) - 1), max(s[1] for s in sizes)
        return max(s[0] for s in sizes), sum(s[1] for s in sizes) + gap * (len(sizes) - 1)
    mw, mh = 0, 0
    for c, (sw, sh) in zip(kids, sizes):
        pos = P(c, "Position", [0, 0, 0, 0])
        anc = P(c, "AnchorPoint", [0, 0])
        x = udim(pos[:2], w) - anc[0] * sw
        y = udim(pos[2:], h) - anc[1] * sh
        mw, mh = max(mw, x + sw), max(mh, y + sh)
    return mw, mh


def place(node, x, y, w, h):
    node["_rect"] = (x, y, w, h)
    pl, pt, pr, pb = padding(node, w, h)
    cx, cy, cw, ch = x + pl, y + pt, max(0, w - pl - pr), max(0, h - pt - pb)
    kids = [c for c in gui_children(node) if P(c, "Visible", True)]
    m = mods(node)
    lst = m.get("UIListLayout")
    grid = m.get("UIGridLayout")
    if node["class"] == "ScrollingFrame":
        # the canvas grows with its content on its scrolling axis
        acs = P(node, "AutomaticCanvasSize", "None")
        if acs in ("X", "XY"):
            cw = max(cw, content_size(node, cw, ch, True, False)[0])
        if acs in ("Y", "XY"):
            ch = max(ch, content_size(node, cw, ch, False, True)[1])
    if grid:
        cell = P(grid, "CellSize", [0, 100, 0, 100])
        pad = P(grid, "CellPadding", [0, 5, 0, 5])
        gw, gh = udim(cell[:2], cw), udim(cell[2:], ch)
        px, py = udim(pad[:2], cw), udim(pad[2:], ch)
        per = max(1, int((cw + px) // (gw + px)))
        kids.sort(key=lambda c: P(c, "LayoutOrder", 0))
        total_w = min(len(kids), per) * (gw + px) - px
        off = 0
        ha = P(grid, "HorizontalAlignment", "Left")
        if ha == "Center":
            off = (cw - total_w) / 2
        elif ha == "Right":
            off = cw - total_w
        for i, c in enumerate(kids):
            r, col = divmod(i, per)
            place(c, cx + off + col * (gw + px), cy + r * (gh + py), gw, gh)
        return
    sizes = {id(c): measure(c, cw, ch) for c in kids}
    if lst:
        horiz = P(lst, "FillDirection", "Vertical") == "Horizontal"
        gap = udim(P(lst, "Padding", [0, 0]), cw if horiz else ch)
        kids.sort(key=lambda c: P(c, "LayoutOrder", 0))
        ha = P(lst, "HorizontalAlignment", "Left")
        va = P(lst, "VerticalAlignment", "Top")
        if horiz:
            rows = [[]]
            xx = 0
            for c in kids:
                sw, sh = sizes[id(c)]
                if P(lst, "Wraps", False) and rows[-1] and xx + sw > cw:
                    rows.append([])
                    xx = 0
                rows[-1].append(c)
                xx += sw + gap
            yy = cy
            for row in rows:
                tw = sum(sizes[id(c)][0] for c in row) + gap * (len(row) - 1)
                rh = max([sizes[id(c)][1] for c in row] or [0])
                sx = cx + (cw - tw) / 2 if ha == "Center" else (cx + cw - tw if ha == "Right" else cx)
                for c in row:
                    sw, sh = sizes[id(c)]
                    if len(rows) == 1:
                        sy = cy + (ch - sh) / 2 if va == "Center" else (cy + ch - sh if va == "Bottom" else cy)
                    else:
                        sy = yy
                    place(c, sx, sy, sw, sh)
                    sx += sw + gap
                yy += rh + gap
        else:
            th = sum(sizes[id(c)][1] for c in kids) + gap * (len(kids) - 1) if kids else 0
            sy = cy + (ch - th) / 2 if va == "Center" else (cy + ch - th if va == "Bottom" else cy)
            for c in kids:
                sw, sh = sizes[id(c)]
                sx = cx + (cw - sw) / 2 if ha == "Center" else (cx + cw - sw if ha == "Right" else cx)
                place(c, sx, sy, sw, sh)
                sy += sh + gap
        return
    for c in kids:
        sw, sh = sizes[id(c)]
        pos = P(c, "Position", [0, 0, 0, 0])
        anc = P(c, "AnchorPoint", [0, 0])
        place(c, cx + udim(pos[:2], cw) - anc[0] * sw, cy + udim(pos[2:], ch) - anc[1] * sh, sw, sh)


# -------------------------------------------------------------------------------------------------
# drawing


def rgb(c, a=1.0):
    return (int(round(c[0] * 255)), int(round(c[1] * 255)), int(round(c[2] * 255)), int(round(a * 255)))


def corner_radius(node, w, h):
    c = mods(node).get("UICorner")
    if not c:
        return 0
    r = udim(P(c, "CornerRadius", [0, 8]), min(w, h))
    return max(0, min(r, min(w, h) / 2))


def seq_at(seq, t, n):
    if not seq:
        return [1.0] * n
    t = min(1, max(0, t))
    for i in range(len(seq) - 1):
        a, b = seq[i], seq[i + 1]
        if a[0] <= t <= b[0]:
            k = 0 if b[0] == a[0] else (t - a[0]) / (b[0] - a[0])
            return [a[j + 1] + (b[j + 1] - a[j + 1]) * k for j in range(n)]
    return list(seq[-1][1:n + 1])


def gradient_layer(w, h, color, alpha, grad, region=None):
    """An RGBA image w x h: colour times the gradient's colours, alpha times its transparency.
    `region` (x, y, w, h in pixels) makes only that part of it (a backdrop far bigger than the
    screen would not fit in memory whole)."""
    w, h = max(1, int(w)), max(1, int(h))
    rx, ry, rw, rh = region if region else (0, 0, w, h)
    if not grad or not P(grad, "Enabled", True):
        im = Image.new("RGBA", (rw, rh), rgb(color, alpha))
        return im
    rot = math.radians(P(grad, "Rotation", 0))
    cos, sin = math.cos(rot), math.sin(rot)
    ys, xs = np.mgrid[ry:ry + rh, rx:rx + rw]
    ext = abs(w * cos) + abs(h * sin)
    off = P(grad, "Offset", [0, 0]) or [0, 0]
    kind = str(P(grad, "Type", "Linear"))
    scale = P(grad, "Scale", 1) or 1
    if kind == "Radial":
        # centred on the frame, its radius a quarter of width plus height
        dx, dy = xs + 0.5 - w / 2 - off[0] * w, ys + 0.5 - h / 2 - off[1] * h
        t = np.sqrt(dx * dx + dy * dy) / max(1e-6, (w + h) / 4) / scale
    elif kind == "Elliptical":
        dx, dy = (xs + 0.5 - w / 2 - off[0] * w) / (w / 2), (ys + 0.5 - h / 2 - off[1] * h) / (h / 2)
        t = np.sqrt(dx * dx + dy * dy) / scale
    elif kind == "Conical":
        # sweeps clockwise from the direction Rotation gives (0 points right)
        dx, dy = xs + 0.5 - w / 2 - off[0] * w, ys + 0.5 - h / 2 - off[1] * h
        ang = (np.arctan2(dy, dx) - rot) % (2 * math.pi)
        t = ang / (2 * math.pi) / scale
    else:
        t = ((xs - w / 2) * cos + (ys - h / 2) * sin) / max(1e-6, ext) / scale + 0.5 - (off[0] * cos + off[1] * sin)
    cseq = P(grad, "Color", [[0, 1, 1, 1], [1, 1, 1, 1]])
    tseq = P(grad, "Transparency", [[0, 0], [1, 0]])
    times = np.linspace(0, 1, 256)
    ctab = np.array([seq_at(cseq, tt, 3) for tt in times])
    ttab = np.array([seq_at(tseq, tt, 1)[0] for tt in times])
    idx = np.clip((t * 255).astype(int), 0, 255)
    r = np.clip(ctab[idx, 0] * color[0], 0, 1)
    g = np.clip(ctab[idx, 1] * color[1], 0, 1)
    b = np.clip(ctab[idx, 2] * color[2], 0, 1)
    a = np.clip((1 - ttab[idx]) * alpha, 0, 1)
    arr = np.stack([r, g, b, a], axis=-1)
    return Image.fromarray((arr * 255).astype(np.uint8), "RGBA")


class Canvas:
    def __init__(self, w, h, ss, scale):
        self.im = Image.new("RGBA", (int(w * ss), int(h * ss)), (0, 0, 0, 0))
        self.ss = ss
        self.k = ss * scale  # layout units to pixels
        self.oy = 0

    def px(self, v):
        return v * self.k

    def paste(self, layer, x, y, clip):
        """Composites an RGBA layer at pixel (x, y), cropped to the clip rect (pixels)."""
        x, y = int(round(x)), int(round(y))
        if clip:
            cx1, cy1, cx2, cy2 = [int(round(v)) for v in clip]
            lx1, ly1 = max(x, cx1), max(y, cy1)
            lx2, ly2 = min(x + layer.width, cx2), min(y + layer.height, cy2)
            if lx1 >= lx2 or ly1 >= ly2:
                return
            layer = layer.crop((lx1 - x, ly1 - y, lx2 - x, ly2 - y))
            x, y = lx1, ly1
        if x >= self.im.width or y >= self.im.height or x + layer.width <= 0 or y + layer.height <= 0:
            return
        self.im.alpha_composite(layer, (max(0, x), max(0, y)),
                                (max(0, -x), max(0, -y)))


def rounded_mask(w, h, r):
    m = Image.new("L", (max(1, int(w)), max(1, int(h))), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, m.width - 1, m.height - 1], radius=int(r), fill=255)
    return m


def draw_shadows(cv, node, rect, clip):
    """The node's UIShadows (shape mode): the frame's rounded shape, spread, blurred and offset,
    lower ZIndex first. The blur's reach is one and a half times the blur radius, three standard
    deviations, as Roblox's write-up of them says."""
    shadows = [c for c in node["children"] if c["class"] == "UIShadow" and P(c, "Enabled", True)
               and str(P(c, "Mode", "Shape")) != "Text"]
    if not shadows:
        return
    x, y, w, h = [cv.px(v) for v in rect]
    if w < 1 or h < 1:
        return
    r = corner_radius(node, w / cv.k, h / cv.k) * cv.k
    for sh in sorted(shadows, key=lambda c: P(c, "ZIndex", -1)):
        alpha = 1 - P(sh, "Transparency", 0.5)
        if alpha <= 0:
            continue
        blur_u = P(sh, "BlurRadius", [0, 8])
        blur = (blur_u[0] * min(w, h) / cv.k + blur_u[1]) * cv.k
        sp = P(sh, "Spread", [0, 0, 0, 0]) or [0, 0, 0, 0]
        of = P(sh, "Offset", [0, 0, 0, 0]) or [0, 0, 0, 0]
        sx, sy = sp[0] * w + sp[1] * cv.k, sp[2] * h + sp[3] * cv.k
        ox, oy = of[0] * w + of[1] * cv.k, of[2] * h + of[3] * cv.k
        pad = int(blur * 1.5) + 2
        sw, shh = max(1, int(w + 2 * sx)), max(1, int(h + 2 * sy))
        mask = Image.new("L", (sw + 2 * pad, shh + 2 * pad), 0)
        mask.paste(rounded_mask(sw, shh, max(0, r + min(sx, sy))), (pad, pad))
        if blur > 0.5:
            mask = mask.filter(ImageFilter.GaussianBlur(blur / 2))
        px0, py0 = x - sx + ox - pad, y - sy + oy - pad
        if not P(sh, "ShowBehindParent", True):
            # not under the frame itself (it may be see-through)
            hole = Image.new("L", mask.size, 255)
            hole.paste(Image.eval(rounded_mask(w, h, r), lambda v: 255 - v), (int(round(x - px0)), int(round(y - py0))))
            mask = Image.fromarray((np.array(mask, dtype=np.uint16) * np.array(hole) // 255).astype(np.uint8))
        col = P(sh, "Color", [0, 0, 0])
        layer = Image.new("RGBA", mask.size, rgb(col, 1))
        layer.putalpha(Image.fromarray((np.array(mask, dtype=np.float32) * alpha).astype(np.uint8)))
        cv.paste(layer, px0, py0, clip)


def draw_box(cv, node, rect, clip):
    draw_shadows(cv, node, rect, clip)
    x, y, w, h = [cv.px(v) for v in rect]
    if w < 1 or h < 1:
        return
    m = mods(node)
    r = corner_radius(node, w / cv.k, h / cv.k) * cv.k
    bgt = P(node, "BackgroundTransparency", 0)
    stroke = m.get("UIStroke")
    is_text = node["class"] in TEXT_CLASSES
    border_stroke = stroke and P(stroke, "Enabled", True) and (
        P(stroke, "ApplyStrokeMode", "Contextual") == "Border" or not is_text)
    if border_stroke:
        t = P(stroke, "Thickness", 1) * cv.k
        st = P(stroke, "Transparency", 0)
        if t > 0 and st < 1:
            ow, oh = w + 2 * t, h + 2 * t
            outer = rounded_mask(ow, oh, r + t if r > 0 else 0)
            inner = Image.new("L", outer.size, 0)
            inner.paste(rounded_mask(w, h, r), (int(round(t)), int(round(t))))
            ring = Image.fromarray(np.clip(np.array(outer, dtype=np.int16) - np.array(inner, dtype=np.int16), 0, 255).astype(np.uint8))
            grad = None
            for c in stroke["children"]:
                if c["class"] == "UIGradient":
                    grad = c
            col = gradient_layer(ow, oh, P(stroke, "Color", [0, 0, 0]), 1 - st, grad)
            col.putalpha(Image.fromarray((np.array(col.getchannel("A"), dtype=np.uint16) * np.array(ring) // 255).astype(np.uint8)))
            cv.paste(col, x - t, y - t, clip)
    if bgt < 1:
        # only the part of the box that can be seen
        vx1, vy1, vx2, vy2 = 0, 0, cv.im.width, cv.im.height
        if clip:
            vx1, vy1, vx2, vy2 = max(vx1, clip[0]), max(vy1, clip[1]), min(vx2, clip[2]), min(vy2, clip[3])
        ix, iy = int(round(x)), int(round(y))
        rx1, ry1 = int(max(0, math.floor(vx1 - ix))), int(max(0, math.floor(vy1 - iy)))
        rx2, ry2 = int(min(int(w), math.ceil(vx2 - ix))), int(min(int(h), math.ceil(vy2 - iy)))
        if rx2 <= rx1 or ry2 <= ry1:
            return
        region = (rx1, ry1, rx2 - rx1, ry2 - ry1)
        layer = gradient_layer(w, h, P(node, "BackgroundColor3", [1, 1, 1]), 1 - bgt, m.get("UIGradient"), region)
        if r > 0:
            mask = rounded_mask(w, h, r).crop((rx1, ry1, rx2, ry2))
            a = np.array(layer.getchannel("A"), dtype=np.uint16) * np.array(mask) // 255
            layer.putalpha(Image.fromarray(a.astype(np.uint8)))
        cv.paste(layer, ix + rx1, iy + ry1, clip)


RICH_TAG = re.compile(r'<font\s+color="#([0-9a-fA-F]{6})">|</font>|<b>|</b>|<i>|</i>')


def parse_rich(text):
    """Roblox rich text, the part the game uses: <font color="#rrggbb"> spans (bold and italic
    tags are dropped). Returns the plain text and a colour (or None) for every character."""
    out, cols, stack, pos = [], [], [], 0
    for m in RICH_TAG.finditer(text):
        chunk = text[pos:m.start()]
        out.append(chunk)
        cols += [stack[-1] if stack else None] * len(chunk)
        tag = m.group(0)
        if tag.startswith("<font"):
            h = m.group(1)
            stack.append([int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255])
        elif tag == "</font>" and stack:
            stack.pop()
        pos = m.end()
    chunk = text[pos:]
    out.append(chunk)
    cols += [stack[-1] if stack else None] * len(chunk)
    plain = "".join(out).replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
    return plain, cols[:len(plain)] + [None] * max(0, len(plain) - len(cols))


def draw_text(cv, node, rect, clip):
    text = P(node, "Text", "") or ""
    if text == "" or P(node, "TextTransparency", 0) >= 1:
        return
    rich_cols = None
    if P(node, "RichText", False):
        text, rich_cols = parse_rich(text)
    mvg = P(node, "MaxVisibleGraphemes", -1)
    if mvg is not None and mvg >= 0:
        text = text[:mvg]
    x, y, w, h = rect
    pl, pt, pr, pb = padding(node, w, h)
    x, y, w, h = x + pl, y + pt, w - pl - pr, h - pt - pb
    font = P(node, "Font", "BuilderSansBold")
    size = P(node, "TextSize", 14)
    wrap = P(node, "TextWrapped", False)
    m = mods(node)
    if P(node, "TextScaled", False):
        size = 100
        tsc = m.get("UITextSizeConstraint")
        if tsc:
            size = min(size, P(tsc, "MaxTextSize", 100))
        while size > 4:
            lines = wrap_lines(text, font, size, w, wrap)
            tw = max(text_width(l, font, size) for l in lines)
            if tw <= w and len(lines) * size <= h:
                break
            size -= 1
    lines = wrap_lines(text, font, size, w, wrap)
    if P(node, "TextTruncate", "None") == "AtEnd":
        nl = []
        for l in lines:
            if text_width(l, font, size) > w:
                while l and text_width(l + "...", font, size) > w:
                    l = l[:-1]
                l = l + "..."
            nl.append(l)
        lines = nl
    lh = size
    total = len(lines) * lh
    ya = P(node, "TextYAlignment", "Center")
    ty = y + (h - total) / 2 if ya == "Center" else (y if ya == "Top" else y + h - total)
    color = P(node, "TextColor3", [0, 0, 0])
    alpha = 1 - P(node, "TextTransparency", 0)
    stroke = m.get("UIStroke")
    sw, scol = 0, None
    if stroke and P(stroke, "Enabled", True) and P(stroke, "ApplyStrokeMode", "Contextual") == "Contextual":
        sw = P(stroke, "Thickness", 1)
        scol = rgb(P(stroke, "Color", [0, 0, 0]), (1 - P(stroke, "Transparency", 0)) * alpha)
    elif P(node, "TextStrokeTransparency", 1) < 1:
        sw = 1
        scol = rgb(P(node, "TextStrokeColor3", [0, 0, 0]), (1 - P(node, "TextStrokeTransparency", 1)) * alpha)
    k = cv.k
    f = get_font(font, size * k)
    xa = P(node, "TextXAlignment", "Center")
    margin = int(sw * k + 4)
    # where each line starts in the text, so rich text colours follow the wrapping
    starts, cursor = [], 0
    for line in lines:
        while cursor < len(text) and text[cursor] in " \n" and not text.startswith(line, cursor):
            cursor += 1
        starts.append(cursor)
        cursor += len(line)
    for i, line in enumerate(lines):
        lw = text_width(line, font, size)
        lx = x + (w - lw) / 2 if xa == "Center" else (x if xa == "Left" else x + w - lw)
        ly = ty + i * lh
        # each line on its own small layer
        LW, LH = int(lw * k + margin * 2 + 4), int(lh * k + margin * 2 + 4)
        layer = Image.new("RGBA", (max(1, LW), max(1, LH)), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        cx = margin
        asc = f.getmetrics()[0]
        base_y = margin + (lh * k - (asc + f.getmetrics()[1])) / 2
        for run in split_runs(line):
            if is_emoji_run(run):
                em = emoji_image(run, size * k * 0.95)
                if em:
                    layer.alpha_composite(em, (int(cx + (size * k * 1.05 - em.width) / 2), int(margin + (lh * k - em.height) / 2)))
                cx += size * k * 1.05
            else:
                kw = {}
                if sw > 0:
                    kw = {"stroke_width": max(1, int(round(sw * k))), "stroke_fill": scol}
                if rich_cols is None:
                    d.text((cx, base_y), run, font=f, fill=rgb(color, alpha), **kw)
                    cx += f.getlength(run)
                else:
                    # draw it in pieces of one colour each
                    at = starts[i] + line.find(run)
                    j = 0
                    while j < len(run):
                        c = rich_cols[at + j] if at + j < len(rich_cols) else None
                        e = j
                        while e < len(run) and (rich_cols[at + e] if at + e < len(rich_cols) else None) == c:
                            e += 1
                        piece = run[j:e]
                        d.text((cx, base_y), piece, font=f, fill=rgb(c or color, alpha), **kw)
                        cx += f.getlength(piece)
                        j = e
        cv.paste(layer, lx * k - margin, ly * k - margin, clip)


_thumb_cache = {}


def item_thumb(item_id, size):
    """A picture of a catalog item from the 3D preview renderer, cached under out/ui_thumbs."""
    cache_dir = os.path.join(HERE, "..", "..", "out", "ui_thumbs")
    os.makedirs(cache_dir, exist_ok=True)
    # a ready-made building comes as "preset:<id>"; anything else is a catalog item
    # and "top:<id>" is a flat mark, seen from above as its card shows it (BuildUI's itemTile)
    view = []
    if item_id.startswith("top:"):
        scene, view = "item:" + item_id[4:], ["--yaw", "0", "--pitch", "76"]
    else:
        scene = item_id if item_id.startswith("preset:") else "item:" + item_id
    path = os.path.join(cache_dir, item_id.replace(":", "_") + ".png")
    if not os.path.exists(path):
        try:
            subprocess.run(["sh", os.path.join(HERE, "render.sh"), scene, path, "--size", "220",
                            "--transparent"] + view, check=True, capture_output=True, cwd=os.path.join(HERE, "..", ".."))
        except Exception:
            return None
    key = (item_id, size)
    if key not in _thumb_cache:
        im = Image.open(path).convert("RGBA")
        bbox = im.getbbox()
        if bbox:
            im = im.crop(bbox)
        s = size / max(im.width, im.height)
        _thumb_cache[key] = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
    return _thumb_cache[key]


PICTURES = {}


def load_pictures(data):
    """Pictures the game made itself (the drawn icons' sheets), written as raw pixels by the dump."""
    for p in data.get("pictures") or []:
        if os.path.exists(p["file"]):
            raw = open(p["file"], "rb").read()
            PICTURES[p["id"]] = Image.frombytes("RGBA", (p["w"], p["h"]), raw)


def fit_picture(img, tw, th):
    """A picture brought to tw by th the way a screen does it: plain averaging when it shrinks."""
    tw, th = max(1, int(round(tw))), max(1, int(round(th)))
    if img.width == tw and img.height == th:
        return img
    if tw >= img.width and th >= img.height:
        return img.resize((tw, th), Image.BILINEAR, reducing_gap=None)
    return img.resize((tw, th), Image.BOX)


def draw_picture(cv, node, rect, clip):
    """An ImageLabel showing part of one of those pictures, tinted by ImageColor3: stretched,
    nine sliced (SliceCenter, SliceScale) or tiled (TileSize), under its own UIGradient and cut
    to its own UICorner."""
    sheet = PICTURES.get(P(node, "Picture"))
    if sheet is None:
        return
    x, y, w, h = [cv.px(v) for v in rect]
    off = P(node, "ImageRectOffset", [0, 0])
    size = P(node, "ImageRectSize", [0, 0])
    if size[0] > 0 and size[1] > 0:
        sheet = sheet.crop((int(off[0]), int(off[1]), int(off[0] + size[0]), int(off[1] + size[1])))
    tw, th = max(1, int(round(w))), max(1, int(round(h)))
    kind = str(P(node, "ScaleType", "Stretch"))
    region = None
    if kind == "Slice":
        cl, ct, cr, cb = P(node, "SliceCenter", [0, 0, sheet.width, sheet.height])
        k = (P(node, "SliceScale", 1) or 1) * cv.k
        # the edges keep their size (times SliceScale); the middle takes what is left
        xs_src = [0, int(cl), int(cr), sheet.width]
        ys_src = [0, int(ct), int(cb), sheet.height]
        left, right = int(round(cl * k)), int(round((sheet.width - cr) * k))
        top, bottom = int(round(ct * k)), int(round((sheet.height - cb) * k))
        if left + right > tw:
            left = tw * left // max(1, left + right)
            right = tw - left
        if top + bottom > th:
            top = th * top // max(1, top + bottom)
            bottom = th - top
        xs_dst = [0, left, tw - right, tw]
        ys_dst = [0, top, th - bottom, th]
        part = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        for iy in range(3):
            for ix in range(3):
                sw, sh = xs_src[ix + 1] - xs_src[ix], ys_src[iy + 1] - ys_src[iy]
                dw, dh = xs_dst[ix + 1] - xs_dst[ix], ys_dst[iy + 1] - ys_dst[iy]
                if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0:
                    continue
                piece = sheet.crop((xs_src[ix], ys_src[iy], xs_src[ix + 1], ys_src[iy + 1]))
                part.paste(fit_picture(piece, dw, dh), (xs_dst[ix], ys_dst[iy]))
    elif kind == "Tile":
        ts = P(node, "TileSize", [1, 0, 1, 0])
        uw, uh = ts[0] * w + ts[1] * cv.k, ts[2] * h + ts[3] * cv.k
        tile = fit_picture(sheet, max(1, uw), max(1, uh))
        # only the part that can be seen (a tone over a whole backdrop is far bigger than the screen)
        vx1, vy1, vx2, vy2 = 0, 0, cv.im.width, cv.im.height
        if clip:
            vx1, vy1, vx2, vy2 = max(vx1, clip[0]), max(vy1, clip[1]), min(vx2, clip[2]), min(vy2, clip[3])
        ix, iy = int(round(x)), int(round(y))
        rx1, ry1 = int(max(0, math.floor(vx1 - ix))), int(max(0, math.floor(vy1 - iy)))
        rx2, ry2 = int(min(tw, math.ceil(vx2 - ix))), int(min(th, math.ceil(vy2 - iy)))
        if rx2 <= rx1 or ry2 <= ry1:
            return
        part = Image.new("RGBA", (rx2 - rx1, ry2 - ry1), (0, 0, 0, 0))
        for ty in range((ry1 // tile.height) * tile.height, ry2, tile.height):
            for tx in range((rx1 // tile.width) * tile.width, rx2, tile.width):
                part.paste(tile, (tx - rx1, ty - ry1))
        region = (rx1, ry1, rx2 - rx1, ry2 - ry1)
    else:
        part = fit_picture(sheet, tw, th)
    tint = P(node, "ImageColor3", [1, 1, 1])
    a = np.array(part, dtype=np.float32)
    a[..., 0] *= tint[0]
    a[..., 1] *= tint[1]
    a[..., 2] *= tint[2]
    a[..., 3] *= 1 - (P(node, "ImageTransparency", 0) or 0)
    grad = mods(node).get("UIGradient")
    if grad and P(grad, "Enabled", True):
        g = np.array(gradient_layer(tw, th, [1, 1, 1], 1, grad, region), dtype=np.float32) / 255
        a *= g
    r = corner_radius(node, w / cv.k, h / cv.k) * cv.k
    if r > 0:
        mask = rounded_mask(tw, th, r)
        if region:
            mask = mask.crop((region[0], region[1], region[0] + region[2], region[1] + region[3]))
        a[..., 3] *= np.array(mask, dtype=np.float32) / 255
    ox, oy = (region[0], region[1]) if region else (0, 0)
    cv.paste(Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA"), int(round(x)) + ox, int(round(y)) + oy, clip)


def draw_wedge(cv, node, rect, clip):
    """A right angled triangle (UI/Kit's wedge: a box with a gradient cut across its diagonal).
    Its name says which half of the box it keeps."""
    x, y, w, h = [cv.px(v) for v in rect]
    keep = node["name"][6:]
    pts = {
        "br": [(w, 0), (w, h), (0, h)],
        "tl": [(0, 0), (w, 0), (0, h)],
        "tr": [(0, 0), (w, 0), (w, h)],
        "bl": [(0, 0), (w, h), (0, h)],
    }.get(keep)
    if not pts or w < 0.5 or h < 0.5:
        return
    k = 3
    im = Image.new("RGBA", (max(1, int(round(w)) * k), max(1, int(round(h)) * k)), (0, 0, 0, 0))
    sx, sy = im.width / w, im.height / h
    alpha = 1 - (P(node, "BackgroundTransparency", 0) or 0)
    ImageDraw.Draw(im).polygon([(px * sx, py * sy) for px, py in pts], fill=rgb(P(node, "BackgroundColor3", [1, 1, 1]), alpha))
    im = im.resize((im.width // k, im.height // k), Image.LANCZOS)
    cv.paste(im, x, y, clip)


def draw_figure(cv, rect, clip, shadow=None, tint=None, fade=0):
    """A stand-in for a villager (the real one is a 3D model in a ViewportFrame): a plain figure
    the height of the frame, so a screen's layout can be judged. With `shadow` (0..1, how
    see-through) it is their shadow instead: the same figure all in black. `tint` (the frame's
    ImageColor3) multiplies its colours, as Roblox does to a ViewportFrame's picture, and `fade`
    (its ImageTransparency) lets what is behind show through: a villager who isn't the one
    talking is dimmed that way."""
    x, y, w, h = [cv.px(v) for v in rect]
    u = h / 100.0
    im = Image.new("RGBA", (max(1, int(w)), max(1, int(h))), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = w / 2
    skin, shirt, legs, hair = (244, 200, 164, 255), (112, 170, 226, 255), (74, 84, 120, 255), (96, 70, 60, 255)
    if shadow is not None:
        skin = shirt = legs = hair = (0, 0, 0, int(255 * (1 - shadow)))

    def box(x1, y1, x2, y2, col, r):
        d.rounded_rectangle([cx + x1 * u, y1 * u, cx + x2 * u, y2 * u], radius=r * u, fill=col)

    box(-11, 66, -1.5, 96, legs, 3)
    box(1.5, 66, 11, 96, legs, 3)
    box(-13, 33, 13, 68, shirt, 4)
    box(-21, 34, -14.5, 62, shirt, 3)
    box(14.5, 34, 21, 62, shirt, 3)
    box(-21, 56, -14.5, 64, skin, 3)
    box(14.5, 56, 21, 64, skin, 3)
    box(-10, 10, 10, 31, skin, 7)
    box(-11, 7, 11, 17, hair, 6)
    if shadow is None and (tint is not None or fade):
        a = np.array(im, dtype=np.float32)
        if tint is not None:
            a[..., 0] *= tint[0]
            a[..., 1] *= tint[1]
            a[..., 2] *= tint[2]
        a[..., 3] *= 1 - min(1, max(0, fade or 0))
        im = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")
    cv.paste(im, x, y, clip)


def draw_node(cv, node, clip, item_hint=None):
    if not P(node, "Visible", True):
        return
    if node.get("itemId"):
        item_hint = node["itemId"]
    rect = node.get("_rect")
    rot = P(node, "Rotation", 0) or 0
    target = cv
    outer_clip = clip
    # a CanvasGroup with round corners cuts its children to the rounded shape
    group = (rect and not rot and node["class"] == "CanvasGroup" and P(node, "ClipsDescendants", False)
             and mods(node).get("UICorner"))
    if group:
        draw_shadows(cv, node, rect, clip)
        x, y, w, h = [cv.px(v) for v in rect]
        r = corner_radius(node, w / cv.k, h / cv.k) * cv.k
        inner = Canvas(cv.im.width / cv.ss, cv.im.height / cv.ss, cv.ss, cv.k / cv.ss)
        inner.im = Image.new("RGBA", cv.im.size, (0, 0, 0, 0))
        plain = dict(node)
        plain["children"] = [c for c in node["children"] if c["class"] != "UIShadow"]
        draw_box(inner, plain, rect, None)
        kids = sorted(enumerate(gui_children(node)), key=lambda e: (P(e[1], "ZIndex", 1), e[0]))
        for _, c in kids:
            draw_node(inner, c, (x, y, x + w, y + h), item_hint)
        cut = Image.new("L", cv.im.size, 0)
        cut.paste(rounded_mask(w, h, r), (int(round(x)), int(round(y))))
        a_ = np.array(inner.im.getchannel("A"), dtype=np.uint16) * np.array(cut) // 255
        inner.im.putalpha(Image.fromarray(a_.astype(np.uint8)))
        cv.paste(inner.im, 0, 0, outer_clip)
        return
    if rot and rect:
        # a turned object is drawn upright on its own layer, turned, and only then clipped
        target = Canvas(cv.im.width / cv.ss, cv.im.height / cv.ss, cv.ss, cv.k / cv.ss)
        target.im = Image.new("RGBA", cv.im.size, (0, 0, 0, 0))
        clip = None
    if rect and node["name"].startswith("Wedge_"):
        draw_wedge(target, node, rect, clip)
    elif rect:
        draw_box(target, node, rect, clip)
        if node["class"] in TEXT_CLASSES:
            draw_text(target, node, rect, clip)
        if node["name"] == "Avatar" and not node.get("_in_avatar"):
            # (a holder named Avatar with the real viewport, also Avatar, inside it is one figure)
            draw_figure(target, rect, clip, None, P(node, "ImageColor3", None), P(node, "ImageTransparency", 0) or 0)
        elif node["name"] == "AvatarShadow":
            draw_figure(target, rect, clip, P(node, "ImageTransparency", 0.66))
        if node["class"] in ("ImageLabel", "ImageButton") and P(node, "Picture"):
            draw_picture(target, node, rect, clip)
        if node["class"] in ("ImageLabel", "ImageButton") and str(P(node, "Image", "")).startswith("rbxthumb"):
            # a catalog thumbnail: Roblox draws the item; here, a soft placeholder
            x, y, w, h = [target.px(v) for v in rect]
            ph = Image.new("RGBA", (max(1, int(w * 0.6)), max(1, int(h * 0.6))), (0, 0, 0, 0))
            ImageDraw.Draw(ph).rounded_rectangle([0, 0, ph.width - 1, ph.height - 1], radius=int(ph.width * 0.3), fill=(176, 186, 204, 255))
            target.paste(ph, x + w * 0.2, y + h * 0.2, clip)
        if node["class"] == "ViewportFrame" and item_hint:
            x, y, w, h = [target.px(v) for v in rect]
            th = item_thumb(item_hint, int(min(w, h) * 0.86))
            if th:
                target.paste(th, x + (w - th.width) / 2, y + (h - th.height) / 2, clip)
    child_clip = clip
    if rect and (P(node, "ClipsDescendants", False) or node["class"] == "ScrollingFrame") and not rot:
        x, y, w, h = [target.px(v) for v in rect]
        c = (x, y, x + w, y + h)
        child_clip = c if not clip else (max(c[0], clip[0]), max(c[1], clip[1]), min(c[2], clip[2]), min(c[3], clip[3]))
    kids = [c for c in gui_children(node)]
    kids = sorted(enumerate(kids), key=lambda e: (P(e[1], "ZIndex", 1), e[0]))
    for _, c in kids:
        if node["name"] == "Avatar" or node.get("_in_avatar"):
            c["_in_avatar"] = True
        draw_node(target, c, child_clip, item_hint)
    if target is not cv:
        x, y, w, h = [cv.px(v) for v in rect]
        rotated = target.im.rotate(-rot, resample=Image.BICUBIC, center=(x + w / 2, y + h / 2))
        cv.paste(rotated, 0, 0, outer_clip)


def tutorial_hole(root):
    """UI/Tutorial's darkened screen: four dark pieces round a hole over the thing to press, and a
    prompt beside it. The game cuts them from where the engine laid that thing out
    (AbsolutePosition), which the simulation can't know, so they are cut again here from this
    layout, the way Tutorial.cut and Tutorial.promptAt do it."""
    target, dims = None, []

    def walk(n):
        nonlocal target
        a = n.get("attrs") or {}
        if a.get("TutorialTarget") and n.get("_rect"):
            target = n
        if a.get("HolePad") is not None and n.get("_rect"):
            dims.append(n)
        for c in n["children"]:
            walk(c)

    walk(root)
    if not target:
        return
    tx, ty, tw, th = target["_rect"]
    for d in dims:
        dx, dy, sw, sh = d["_rect"]
        pad = d["attrs"]["HolePad"]
        x, y, w, h = tx - dx - pad, ty - dy - pad, tw + pad * 2, th + pad * 2
        x0 = min(max(math.floor(x), 0), sw)
        y0 = min(max(math.floor(y), 0), sh)
        x1 = min(max(math.ceil(x + w), x0), sw)
        y1 = min(max(math.ceil(y + h), y0), sh)
        pieces = {
            "Top": (0, 0, sw, y0),
            "Bottom": (0, y1, sw, sh - y1),
            "Left": (0, y0, x0, y1 - y0),
            "Right": (x1, y0, sw - x1, y1 - y0),
        }
        for c in d["children"]:
            a = c.get("attrs") or {}
            if a.get("Hole") in pieces:
                px, py, pw, ph = pieces[a["Hole"]]
                place(c, dx + px, dy + py, pw, ph)
            elif a.get("HoleArrow") and c.get("_rect"):
                _, _, aw, ah = c["_rect"]
                ax = (max(x, 0) + min(x + w, sw)) / 2 - aw / 2
                place(c, dx + math.floor(ax), dy + math.floor(y + pad - 2 - ah), aw, ah)
            elif a.get("HoleNear") and c.get("_rect"):
                _, _, cw, ch = c["_rect"]
                gap = a.get("HoleGap", 12)
                cx = min(max(math.floor(x + w / 2 - cw / 2), 16), max(16, sw - 16 - cw))
                if y + h / 2 > sh / 2:
                    cy = max(8, math.floor(y - gap - ch))
                else:
                    cy = min(sh - 8 - ch, math.floor(y + h + gap))
                place(c, dx + cx, dy + cy, cw, ch)


def backdrop(w, h, path):
    if path and os.path.exists(path):
        im = Image.open(path).convert("RGBA")
        s = max(w / im.width, h / im.height)
        im = im.resize((int(im.width * s) + 1, int(im.height * s) + 1), Image.LANCZOS)
        left, top = (im.width - w) // 2, (im.height - h) // 2
        return im.crop((left, top, left + w, top + h))
    ys = np.linspace(0, 1, h)[:, None]
    sky = np.array([150, 200, 240]) * (1 - ys) + np.array([215, 235, 250]) * ys
    img = np.repeat(sky[:, None, :], w, axis=1).reshape(h, w, 3)
    g = int(h * 0.62)
    img[g:] = np.array([110, 175, 90])
    return Image.fromarray(img.astype(np.uint8), "RGB").convert("RGBA")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--bg", default=None)
    ap.add_argument("--ss", type=int, default=2, help="supersampling")
    ap.add_argument("--keep", action="store_true", help="keep the supersampled size")
    args = ap.parse_args()
    data = json.load(open(args.inp))
    load_pictures(data)
    vw, vh = data["viewport"]
    inset = data.get("inset", 36)
    root = data["root"]
    m = mods(root)
    scale = P(m["UIScale"], "Scale", 1) if "UIScale" in m else 1
    ignore = P(root, "IgnoreGuiInset", False)
    top = 0 if ignore else inset
    gw, gh = vw / scale, (vh - top) / scale
    # The interface is laid out under the strip Roblox keeps at the top, but that strip is
    # see-through in the game and an object placed above y = 0 shows in it. So the picture is the
    # whole screen, the layout moved down by the strip. (It used to be painted black, which hid a
    # clock slab that ran up through it: "the weather tab is stretched".)
    off = top / scale
    for c in gui_children(root):
        if P(c, "Visible", True):
            sw, sh = measure(c, gw, gh)
            pos = P(c, "Position", [0, 0, 0, 0])
            anc = P(c, "AnchorPoint", [0, 0])
            place(c, udim(pos[:2], gw) - anc[0] * sw, off + udim(pos[2:], gh) - anc[1] * sh, sw, sh)
    tutorial_hole(root)
    ss = args.ss
    cv = Canvas(vw, vh, ss, scale)
    kids = sorted(enumerate(gui_children(root)), key=lambda e: (P(e[1], "ZIndex", 1), e[0]))
    for _, c in kids:
        draw_node(cv, c, None)
    bg = backdrop(vw * ss, vh * ss, args.bg)
    bg.alpha_composite(cv.im, (0, 0))
    # Roblox's own two buttons at the left of its top strip
    if top > 0:
        chrome = Image.new("RGBA", bg.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(chrome)
        for cx in [16, 60]:
            d.rounded_rectangle([cx * ss, 4 * ss, (cx + 36) * ss, 32 * ss], radius=10 * ss, fill=(20, 20, 24, 150))
        bg.alpha_composite(chrome)
    out = bg if args.keep else bg.resize((vw, vh), Image.LANCZOS)
    out.convert("RGB").save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
