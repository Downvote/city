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
from PIL import Image, ImageDraw, ImageFont

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
    if node["class"] in TEXT_CLASSES:
        tw, th = text_metrics(node, 0 if ax else max(0, w - pl - pr))
        cw, ch = max(cw, tw), max(ch, th)
    if ax:
        w = max(w, cw + pl + pr)
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


def gradient_layer(w, h, color, alpha, grad):
    """An RGBA image w x h: colour times the gradient's colours, alpha times its transparency."""
    w, h = max(1, int(w)), max(1, int(h))
    if not grad or not P(grad, "Enabled", True):
        im = Image.new("RGBA", (w, h), rgb(color, alpha))
        return im
    rot = math.radians(P(grad, "Rotation", 0))
    cos, sin = math.cos(rot), math.sin(rot)
    ys, xs = np.mgrid[0:h, 0:w]
    ext = abs(w * cos) + abs(h * sin)
    off = P(grad, "Offset", [0, 0]) or [0, 0]
    t = ((xs - w / 2) * cos + (ys - h / 2) * sin) / max(1e-6, ext) + 0.5 - (off[0] * cos + off[1] * sin)
    cseq = P(grad, "Color", [[0, 1, 1, 1], [1, 1, 1, 1]])
    tseq = P(grad, "Transparency", [[0, 0], [1, 0]])
    times = np.linspace(0, 1, 64)
    ctab = np.array([seq_at(cseq, tt, 3) for tt in times])
    ttab = np.array([seq_at(tseq, tt, 1)[0] for tt in times])
    idx = np.clip((t * 63).astype(int), 0, 63)
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


def draw_box(cv, node, rect, clip):
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
        layer = gradient_layer(w, h, P(node, "BackgroundColor3", [1, 1, 1]), 1 - bgt, m.get("UIGradient"))
        mask = rounded_mask(w, h, r)
        a = np.array(layer.getchannel("A"), dtype=np.uint16) * np.array(mask) // 255
        layer.putalpha(Image.fromarray(a.astype(np.uint8)))
        cv.paste(layer, x, y, clip)


def draw_text(cv, node, rect, clip):
    text = P(node, "Text", "") or ""
    if text == "" or P(node, "TextTransparency", 0) >= 1:
        return
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
                d.text((cx, base_y), run, font=f, fill=rgb(color, alpha), **kw)
                cx += f.getlength(run)
        cv.paste(layer, lx * k - margin, ly * k - margin, clip)


_thumb_cache = {}


def item_thumb(item_id, size):
    """A picture of a catalog item from the 3D preview renderer, cached under out/ui_thumbs."""
    cache_dir = os.path.join(HERE, "..", "..", "out", "ui_thumbs")
    os.makedirs(cache_dir, exist_ok=True)
    path = os.path.join(cache_dir, item_id + ".png")
    if not os.path.exists(path):
        try:
            subprocess.run(["sh", os.path.join(HERE, "render.sh"), "item:" + item_id, path, "--size", "220",
                            "--transparent"], check=True, capture_output=True, cwd=os.path.join(HERE, "..", ".."))
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


def draw_node(cv, node, clip, item_hint=None):
    if not P(node, "Visible", True):
        return
    if node.get("itemId"):
        item_hint = node["itemId"]
    rect = node.get("_rect")
    rot = P(node, "Rotation", 0) or 0
    target = cv
    outer_clip = clip
    if rot and rect:
        # a turned object is drawn upright on its own layer, turned, and only then clipped
        target = Canvas(cv.im.width / cv.ss, cv.im.height / cv.ss, cv.ss, cv.k / cv.ss)
        target.im = Image.new("RGBA", cv.im.size, (0, 0, 0, 0))
        clip = None
    if rect:
        draw_box(target, node, rect, clip)
        if node["class"] in TEXT_CLASSES:
            draw_text(target, node, rect, clip)
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
        draw_node(target, c, child_clip, item_hint)
    if target is not cv:
        x, y, w, h = [cv.px(v) for v in rect]
        rotated = target.im.rotate(-rot, resample=Image.BICUBIC, center=(x + w / 2, y + h / 2))
        cv.paste(rotated, 0, 0, outer_clip)


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
    vw, vh = data["viewport"]
    inset = data.get("inset", 36)
    root = data["root"]
    m = mods(root)
    scale = P(m["UIScale"], "Scale", 1) if "UIScale" in m else 1
    ignore = P(root, "IgnoreGuiInset", False)
    top = 0 if ignore else inset
    gw, gh = vw / scale, (vh - top) / scale
    for c in gui_children(root):
        if P(c, "Visible", True):
            sw, sh = measure(c, gw, gh)
            pos = P(c, "Position", [0, 0, 0, 0])
            anc = P(c, "AnchorPoint", [0, 0])
            place(c, udim(pos[:2], gw) - anc[0] * sw, udim(pos[2:], gh) - anc[1] * sh, sw, sh)
    ss = args.ss
    cv = Canvas(vw, vh - top, ss, scale)
    kids = sorted(enumerate(gui_children(root)), key=lambda e: (P(e[1], "ZIndex", 1), e[0]))
    for _, c in kids:
        draw_node(cv, c, None)
    bg = backdrop(vw * ss, vh * ss, args.bg)
    # the Roblox top bar
    d = ImageDraw.Draw(bg)
    d.rectangle([0, 0, vw * ss, top * ss], fill=(0, 0, 0, 0))
    for i, cx in enumerate([16, 60]):
        d.rounded_rectangle([cx * ss, 4 * ss, (cx + 36) * ss, 32 * ss], radius=10 * ss, fill=(20, 20, 24, 150))
    bg.alpha_composite(cv.im, (0, top * ss))
    out = bg if args.keep else bg.resize((vw, vh), Image.LANCZOS)
    out.convert("RGB").save(args.out)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
