#!/usr/bin/env python3
"""Lays painted icons (tools/preview/art_dump.luau) out on a sheet to look at:
    python3 tools/preview/art_sheet.py <dir> <out.png> [--cols N]
Each icon is shown big (192), then as the game shows it: 48 and 28 across from the big painting,
24 and 16 across from the small one, on the dark card colour, in its own tint (or near white)."""
import json
import sys

from PIL import Image, ImageDraw, ImageFont

src, out = sys.argv[1], sys.argv[2]
cols = int(sys.argv[sys.argv.index("--cols") + 1]) if "--cols" in sys.argv else 4
items = json.load(open(src + "/list.json"))
CARD, INK = (37, 40, 54), (236, 238, 246)
W, H = 300, 262


def load(name, n):
    return Image.frombytes("RGBA", (n, n), open("%s/%s.%d.rgba" % (src, name, n), "rb").read())


def tinted(im, item):
    if item["coloured"]:
        return im
    t = item.get("tint") or [c / 255 for c in INK]
    r, g, b, a = im.split()
    return Image.merge("RGBA", (r.point(lambda v: int(v * t[0])), g.point(lambda v: int(v * t[1])), b.point(lambda v: int(v * t[2])), a))


rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGB", (W * cols, H * rows), CARD)
draw = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
except OSError:
    font = ImageFont.load_default()
for i, item in enumerate(items):
    x, y = (i % cols) * W, (i // cols) * H
    big = tinted(load(item["name"], 192), item)
    # the 24 grid behind the big one, faintly, with the 2 unit margin marked
    for k in range(0, 25, 2):
        c = (52, 56, 74) if k not in (2, 22) else (84, 90, 116)
        draw.line([x + 8 + k * 8, y + 8, x + 8 + k * 8, y + 200], fill=c)
        draw.line([x + 8, y + 8 + k * 8, x + 200, y + 8 + k * 8], fill=c)
    sheet.paste(big, (x + 8, y + 8), big)
    px = x + 212
    for size, level in ((48, 96), (28, 96), (24, 48), (16, 48)):
        im = tinted(load(item["name"], level), item).resize((size, size), Image.BOX if level % size == 0 else Image.BILINEAR)
        sheet.paste(im, (px, y + 8), im)
        y += size + 8
    y = (i // cols) * H
    draw.text((x + 8, y + 206), item["name"], fill=INK, font=font)
sheet.save(out)
print("wrote " + out)
