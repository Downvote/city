#!/usr/bin/env python3
"""Uploads the painted textures in art/textures to Roblox through Open Cloud, writes their image ids
into src/shared/Data/TextureIds.luau and puts them in the place (scripts/sync_materials.py).

    ROBLOX_API_KEY=<key> python3 scripts/upload_textures.py --user <your user id> --looks
    ROBLOX_API_KEY=<key> python3 scripts/upload_textures.py --group <group id> --only panel,barrel
    python3 scripts/upload_textures.py --user <your user id> --looks --dry-run

    --looks        only the looks (Concrete's Panel, Metal's Shutter and the rest of Data/Textures' looks)
    --only a,b     only these textures, by their names in art/textures/textures.json
    --no-normals   colour maps only: no normal maps, no roughness maps
    --as TYPE      the asset type to upload as: image, decal or auto (the default: image, and decal
                   for the rest of the run if Roblox refuses image)
    --dry-run      send nothing and need no key: list every request that would be made

The key is read from the environment variable ROBLOX_API_KEY and is never printed. Make it at
create.roblox.com, Open Cloud, API Keys, with the Assets API permissions asset:read and
asset:write, for the user or the group the pictures should belong to.

Each picture is one request, POST https://apis.roblox.com/assets/v1/assets, a multipart form of
two fields: `request`, JSON with assetType, displayName, description and
creationContext.creator.userId (or groupId), and `fileContent`, the PNG. The answer is an
operation; the script asks GET https://apis.roblox.com/assets/v1/operations/<id> until it is
done and reads the new asset's id from it. A texture's colour map goes up first, then its normal
map (<name>_n.png) and its roughness map (<name>_r.png, where there is one).

Uploaded as an Image, the id that comes back is the image itself, which is what a material
needs. Uploaded as a Decal, it is the decal's id, and the image inside it has another id that
must be found: the script reads the decal through the Asset Delivery API, which needs the
permission legacy-asset:manage on the key as well. If that fails too it prints the decal's id
and stops there for that picture. Then find the image by hand: in Studio put the decal on a
part and read the Decal's Texture property, or once the decal is public run
python3 scripts/library_textures.py resolve <decal id>. Write the id on the texture's line in
Data/TextureIds as "rbxassetid://<image id>" and run python3 scripts/sync_materials.py.

A picture whose id is already in Data/TextureIds is skipped, so a run that failed part way can
be run again. To send a repainted picture, take its id off its line first. A texture whose
colour is a Creator Store picture is left alone whole: its other maps belong to that picture's
set, not to ours. New images go through Roblox's moderation and show once they're approved.
"""
import argparse
import json
import os
import re
import struct
import sys
import time
import urllib.error
import urllib.request
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sync_materials  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TEX = os.path.join(ROOT, "art", "textures")
API = "https://apis.roblox.com"
CREATE = API + "/assets/v1/assets"
KEY_VAR = "ROBLOX_API_KEY"
OURS = "painted"  # how the comment on a line of Data/TextureIds starts when the pictures are our own
MAPS = (("color", ""), ("normal", "_n"), ("rough", "_r"))
TYPES = {"image": "Image", "decal": "Decal"}


class Refused(Exception):
    """Roblox answered with an error. `code` is the HTTP status, `body` what it said."""

    def __init__(self, method, url, code, body):
        super().__init__(f"{method} {url}: {code} {body[:300]}")
        self.code, self.body = code, body


def request(method, url, key, body=None, content_type=None):
    headers = {"x-api-key": key}
    if content_type:
        headers["Content-Type"] = content_type
    for attempt in range(5):
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 4:  # too many requests: wait and ask again
                time.sleep(5 + attempt * 10)
                continue
            raise Refused(method, url, e.code, e.read().decode("utf-8", "replace")) from None
    raise RuntimeError("unreachable")


def meta(asset_type, display, creator):
    return {
        "assetType": asset_type,
        "displayName": display,
        "description": "Painted texture for Maplewick",
        "creationContext": {"creator": creator},
    }


def upload(path, asset_type, display, creator, key):
    """Sends one picture and waits for Roblox to finish with it. Returns the new asset's id."""
    boundary = uuid.uuid4().hex
    parts = [
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n".encode()
        + json.dumps(meta(asset_type, display, creator)).encode(),
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{os.path.basename(path)}\"\r\n"
        "Content-Type: image/png\r\n\r\n".encode() + open(path, "rb").read(),
    ]
    body = b"\r\n".join(parts) + f"\r\n--{boundary}--\r\n".encode()
    op = json.loads(request("POST", CREATE, key, body, f"multipart/form-data; boundary={boundary}"))
    for _ in range(90):
        if op.get("error"):
            raise RuntimeError(f"Roblox could not make the asset: {json.dumps(op['error'])[:300]}")
        if op.get("done"):
            answer = op.get("response") or {}
            if "assetId" not in answer:
                raise RuntimeError(f"no asset id in the finished operation: {json.dumps(op)[:300]}")
            state = (answer.get("moderationResult") or {}).get("moderationState")
            return str(answer["assetId"]), state
        op_id = op.get("operationId") or str(op.get("path", "")).rsplit("/", 1)[-1]
        if not op_id:
            raise RuntimeError(f"no operation to wait for: {json.dumps(op)[:300]}")
        time.sleep(2)
        op = json.loads(request("GET", f"{API}/assets/v1/operations/{op_id}", key))
    raise RuntimeError("upload still processing after three minutes: " + display)


def wrong_type(e):
    """Whether Roblox refused the request because of its asset type."""
    return isinstance(e, Refused) and e.code == 400 and re.search(r"asset\s*_?type", e.body, re.I) is not None


def image_id(decal_id, key):
    """The image a decal shows, read from the decal itself through the Asset Delivery API."""
    info = json.loads(request("GET", f"{API}/asset-delivery-api/v1/assetId/{decal_id}", key))
    with urllib.request.urlopen(info["location"], timeout=60) as r:
        data = r.read().decode("utf-8", "replace")
    m = re.search(r"(?:asset/\?id=|rbxassetid://)(\d+)", data)
    if not m:
        raise RuntimeError(f"no image id inside decal {decal_id}")
    return m.group(1)


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24]) if head[:8] == b"\x89PNG\r\n\x1a\n" else (0, 0)


def plan(names, index, ids, normals=True):
    """What a run would send, in order: (texture, field, file) for every picture that has no id
    yet. Also the textures left alone because their colour is a Creator Store picture."""
    jobs, left = [], []
    for name in names:
        got = ids.get(name, {})
        ours = index[name].get("look") or got.get("note", "").startswith(OURS)  # every look is our own
        if "color" in got and not ours:
            left.append(name)
            continue
        for field, suffix in MAPS:
            if field != "color" and not normals:
                continue
            file = name + suffix + ".png"
            if field not in got and os.path.exists(os.path.join(TEX, file)):
                jobs.append((name, field, file))
    return jobs, left


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    who = ap.add_mutually_exclusive_group(required=True)
    who.add_argument("--user", help="your Roblox user id")
    who.add_argument("--group", help="a group id to upload under instead")
    ap.add_argument("--only", help="comma separated texture names")
    ap.add_argument("--looks", action="store_true", help="only the looks")
    ap.add_argument("--no-normals", action="store_true", help="colour maps only")
    ap.add_argument("--as", dest="kind", choices=("auto", "image", "decal"), default="auto", help="the asset type")
    ap.add_argument("--dry-run", action="store_true", help="send nothing: list what would be sent")
    args = ap.parse_args()
    who_id = args.user or args.group
    if not who_id.isdigit():
        sys.exit("the user or group id is a number")
    key = os.environ.get(KEY_VAR, "")
    if not key and not args.dry_run:
        sys.exit(f"set {KEY_VAR} to an Open Cloud API key (see the top of this file)")
    creator = {"userId": who_id} if args.user else {"groupId": who_id}
    index = json.load(open(os.path.join(TEX, "textures.json")))
    order = list(index)
    names = args.only.split(",") if args.only else [n for n in order if index[n].get("look") or not args.looks]
    failed = 0
    for name in names:
        if name not in index:
            print(f"{name}: no such texture")
            failed += 1
    names = [n for n in names if n in index]
    ids = sync_materials.read_ids()
    jobs, left = plan(names, index, ids, not args.no_normals)
    if left:
        print("left alone (their colour is a Creator Store picture): " + ", ".join(left))
    asset_type = TYPES["decal" if args.kind == "decal" else "image"]

    if args.dry_run:
        total = 0
        for name, field, file in jobs:
            path = os.path.join(TEX, file)
            size = os.path.getsize(path)
            total += size
            w, h = png_size(path)
            display = f"Maplewick {name} {field}"
            print(f"POST {CREATE}")
            print(f"  request      {json.dumps(meta(asset_type, display, creator))}")
            print(f"  fileContent  art/textures/{file} (image/png, {w}x{h}, {size} bytes)")
            print(f"  then         TextureIds {name}.{field}")
        fallback = ", as Decal if Roblox refuses Image" if args.kind == "auto" else ""
        print(f"{len(jobs)} pictures, {total} bytes, as {asset_type}{fallback}. Nothing was sent.")
        sys.exit(1 if failed else 0)

    done = 0
    no_colour = set()  # textures whose colour map didn't go up: their other maps wait for the next run
    for name, field, file in jobs:
        display = f"Maplewick {name} {field}"
        path = os.path.join(TEX, file)
        if name in no_colour:
            failed += 1
            print(f"{file}: not sent, the colour map of {name} failed")
            continue
        try:
            try:
                asset, state = upload(path, asset_type, display, creator, key)
            except Refused as e:
                if not (args.kind == "auto" and asset_type == "Image" and wrong_type(e)):
                    raise
                print("Roblox refused the asset type Image: sending decals from here on")
                asset_type = "Decal"
                asset, state = upload(path, asset_type, display, creator, key)
            image = asset
            if asset_type == "Decal":
                try:
                    image = image_id(asset, key)
                except Exception as e:
                    raise RuntimeError(
                        f"uploaded as decal {asset}, but its image id could not be read ({e}). "
                        "Find it by hand (see the top of this file) and write it in Data/TextureIds."
                    ) from None
            got = ids.setdefault(name, {})
            got[field] = f"rbxassetid://{image}"
            got.setdefault("note", f"{OURS} (scripts/gen_textures.py)")
            done += 1
            where = f" (decal {asset})" if image != asset else ""
            print(f"{file}: image {image}{where}{', moderation: ' + state if state else ''}")
            sync_materials.write_ids(ids, order)  # after every picture, so a failure part way keeps the rest
        except Exception as e:  # keep going with the others
            failed += 1
            if field == "color":
                no_colour.add(name)
            print(f"{file}: {e}")
    sync_materials.write_ids(ids, order)
    sys.argv = ["sync_materials.py"]
    sync_materials.main()
    print(f"{done} of {len(jobs)} pictures uploaded")
    if failed:
        print(f"{failed} failed; run again to retry them (done ones are skipped)")
        sys.exit(1)


if __name__ == "__main__":
    main()
