#!/usr/bin/env python3
"""Finds textures in the Roblox Creator Store (public decals) for the game's materials.

    python3 scripts/library_textures.py search "<keywords>" --sheet out.png [--limit 24]
    python3 scripts/library_textures.py resolve <decal id> [<decal id> ...]
    python3 scripts/library_textures.py check

search lists decals for the keywords with a contact sheet: each picture with its decal id, how
well its opposite edges match (lower tiles better: a seamless texture scores near 0) and how
coloured it is (lower is greyer; a part's colour tints a material's texture, so grey ones take
paint best). resolve finds the image a decal shows (a material needs the image's id, not the decal's): the
Creator Store's item details list it as the decal's textureId. It also says whether Roblox will show
that image: a decal can be in the store while its image is private or was taken down, and then the
image's own thumbnail is only a placeholder ("no picture"). Never use one of those: it would not
load in the game. check asks the same of every image id already in Data/TextureIds (colour, normal
and roughness maps) and fails if one has gone.

Picked textures go in src/shared/Data/TextureIds.luau (with their decal ids noted), then
python3 scripts/sync_materials.py puts them in the place.
"""
import argparse
import io
import json
import sys
import time
import urllib.parse
import urllib.request

import numpy as np
from PIL import Image, ImageDraw

UA = {"User-Agent": "texture-finder"}
SKIP = ("minecraft", "nintendo", "tomodachi", "mario", "zelda", "pokemon", "animal crossing", "fortnite", "sims",
        "roblox logo", "meme", "face", "logo")


def get(url, raw=False):
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
                return data if raw else json.loads(data)
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(2 + attempt * 3)
                continue
            raise
    raise RuntimeError("rate limited: " + url)


def search(keywords, limit):
    q = urllib.parse.quote(keywords)
    ids, cursor = [], ""
    while len(ids) < limit:
        url = f"https://apis.roblox.com/toolbox-service/v1/marketplace/13?keyword={q}&limit=30"
        if cursor:
            url += "&cursor=" + urllib.parse.quote(cursor)
        page = get(url)
        ids += [d["id"] for d in page.get("data", [])]
        cursor = page.get("nextPageCursor")
        if not cursor:
            break
    return ids[:limit]


def details(ids):
    out = {}
    for i in range(0, len(ids), 30):
        chunk = ",".join(str(x) for x in ids[i:i + 30])
        for d in get(f"https://apis.roblox.com/toolbox-service/v1/items/details?assetIds={chunk}").get("data", []):
            out[d["asset"]["id"]] = d
    return out


def thumbs(ids, kind="assets"):
    out = {}
    for i in range(0, len(ids), 50):
        chunk = ",".join(str(x) for x in ids[i:i + 50])
        for d in get(f"https://thumbnails.roblox.com/v1/{kind}?assetIds={chunk}&size=420x420&format=Png").get("data", []):
            if d.get("state") == "Completed":
                out[d["targetId"]] = d["imageUrl"]
    return out


def measure(im):
    a = np.asarray(im.convert("RGB").resize((128, 128), Image.BOX), float) / 255
    # seams: how different the opposite edges are, against how different neighbouring columns are
    edge = (np.abs(a[:, 0] - a[:, -1]).mean() + np.abs(a[0] - a[-1]).mean()) / 2
    inner = (np.abs(a[:, 1:] - a[:, :-1]).mean() + np.abs(a[1:] - a[:-1]).mean()) / 2
    seam = edge / max(inner, 1e-3)
    mean = a.reshape(-1, 3).mean(0)
    sat = float(a.max(2).mean() - a.min(2).mean())
    return seam, sat, mean


def cmd_search(args):
    ids = search(args.keywords, args.limit)
    info = details(ids)
    urls = thumbs(ids)
    rows = []
    for i in ids:
        d = info.get(i)
        if not d or i not in urls:
            continue
        name = d["asset"]["name"]
        if any(s in name.lower() for s in SKIP):
            continue
        im = Image.open(io.BytesIO(get(urls[i], raw=True))).convert("RGB")
        seam, sat, mean = measure(im)
        votes = d.get("voting", {})
        rows.append({"id": i, "name": name, "creator": d["creator"]["name"], "seam": round(seam, 2),
                     "sat": round(sat, 2), "light": round(float(mean.mean()), 2),
                     "up": votes.get("upVotes", 0), "down": votes.get("downVotes", 0), "im": im})
    rows.sort(key=lambda r: r["seam"])
    for r in rows:
        print(f'{r["id"]:>12}  seam {r["seam"]:5.2f}  sat {r["sat"]:.2f}  light {r["light"]:.2f}  '
              f'+{r["up"]}/-{r["down"]}  {r["name"][:40]}  ({r["creator"]})')
    if args.sheet and rows:
        cell, cols = 200, 6
        n = min(len(rows), args.show)
        sheet = Image.new("RGB", (cols * cell, ((n + cols - 1) // cols) * (cell + 28)), (250, 246, 236))
        draw = ImageDraw.Draw(sheet)
        for k, r in enumerate(rows[:n]):
            x, y = (k % cols) * cell, (k // cols) * (cell + 28)
            # two by two, so a seam shows as a cross
            im = r["im"].resize((cell // 2 - 2, cell // 2 - 2), Image.LANCZOS)
            for ox in (0, 1):
                for oy in (0, 1):
                    sheet.paste(im, (x + 2 + ox * (cell // 2 - 2), y + 2 + oy * (cell // 2 - 2)))
            draw.text((x + 4, y + cell), f'{r["id"]} s{r["seam"]} c{r["sat"]}', fill=(60, 40, 30))
            draw.text((x + 4, y + cell + 12), r["name"][:30], fill=(110, 90, 80))
        sheet.save(args.sheet)
        print("sheet", args.sheet)


def economy(asset_id):
    return get(f"https://economy.roblox.com/v2/assets/{asset_id}/details")


def resolve(decal_id):
    """The image a decal shows: the Creator Store's item details carry it as textureId."""
    d = get(f"https://apis.roblox.com/toolbox-service/v1/items/details?assetIds={decal_id}").get("data", [])
    if not d or d[0]["asset"].get("typeId") != 13:
        raise RuntimeError(f"{decal_id} is not a decal in the Creator Store")
    image = d[0]["asset"].get("textureId")
    if not image:
        raise RuntimeError(f"no image listed for decal {decal_id}")
    return image


def shown(image_ids):
    """image id -> whether Roblox shows the image itself: its thumbnail is the picture ("ok"), is
    still being made ("pending") or is the placeholder for an image nobody may see ("no picture")."""
    out = {}
    ids = [int(i) for i in image_ids]
    for i in range(0, len(ids), 50):
        chunk = ",".join(str(x) for x in ids[i:i + 50])
        for d in get(f"https://thumbnails.roblox.com/v1/assets?assetIds={chunk}&size=420x420&format=Png").get("data", []):
            if d.get("state") == "Pending":
                out[d["targetId"]] = "pending"
            elif d.get("state") == "Completed" and "/Image/" in (d.get("imageUrl") or ""):
                out[d["targetId"]] = "ok"
            else:
                out[d["targetId"]] = "no picture"
    return out


def cmd_resolve(args):
    failed = 0
    found = {}
    for decal in args.ids:
        try:
            found[decal] = resolve(int(decal))
        except Exception as e:
            print(decal, "failed:", e)
            failed += 1
    state = shown(found.values()) if found else {}
    for decal, image in found.items():
        how = state.get(int(image), "no picture")
        print(decal, image, how)
        if how == "no picture":
            failed += 1
    if failed:
        sys.exit(1)


def cmd_check(args):
    import os
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import sync_materials
    want = {}
    for name, got in sync_materials.read_ids().items():
        for field in ("color", "normal", "rough"):
            if field in got:
                want[int(got[field].split("//")[1])] = f"{name}.{field}"
    state = shown(want)
    for attempt in range(3):  # a thumbnail nobody has asked for yet takes a moment to be made
        waiting = [i for i in want if state.get(i) == "pending"]
        if not waiting:
            break
        time.sleep(6)
        state.update(shown(waiting))
    gone = [(label, i, state.get(i, "no picture")) for i, label in want.items() if state.get(i) != "ok"]
    for label, i, how in gone:
        print(f"{label}: image {i}: {how}")
    print(f"{len(want)} images in Data/TextureIds, {len(gone)} that Roblox shows no picture for")
    if gone:
        sys.exit(1)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("search")
    s.add_argument("keywords")
    s.add_argument("--limit", type=int, default=30)
    s.add_argument("--show", type=int, default=18)
    s.add_argument("--sheet")
    r = sub.add_parser("resolve")
    r.add_argument("ids", nargs="+")
    sub.add_parser("check")
    args = ap.parse_args()
    {"search": cmd_search, "resolve": cmd_resolve, "check": cmd_check}[args.cmd](args)


if __name__ == "__main__":
    main()
