#!/usr/bin/env python3
"""Uploads the painted textures in art/textures to Roblox through Open Cloud, writes their image ids
into src/shared/Data/TextureIds.luau and puts them in the place (scripts/sync_materials.py).

    ROBLOX_API_KEY=<key> python3 scripts/upload_textures.py --user <your user id>
    ROBLOX_API_KEY=<key> python3 scripts/upload_textures.py --group <group id> --only grass,brick
    options: --no-normals (colour maps only), --dry-run (say what would go up)

Make the key at create.roblox.com, Open Cloud, API Keys, with these permissions: Assets API
(asset:read, asset:write) and Legacy Asset (legacy-asset:manage). The first uploads the
pictures; the second reads each uploaded decal back to find its image id, which is the id a
material needs. Textures already in TextureIds are skipped. New images go through Roblox's
moderation and show once they're approved.
"""
import argparse
import json
import os
import re
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

HEADER = """--!strict
-- Roblox image ids for the painted textures in art/textures, once they're uploaded. One entry per
-- texture name from Data/Textures: `color` for <name>.png, `normal` for <name>_n.png (optional).
-- scripts/upload_textures.py fills this in; after a Studio bulk import, paste the ids by hand:
--   grass = { color = "rbxassetid://123", normal = "rbxassetid://456" },
-- then run python3 scripts/sync_materials.py to put them in the place.
-- A texture with no colour id here keeps Roblox's own material.

export type Ids = { color: string?, normal: string? }

"""


def request(method, url, key, body=None, content_type=None):
    headers = {"x-api-key": key}
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{method} {url}: {e.code} {e.read()[:300]!r}") from None


def upload(path, display, creator, key):
    boundary = uuid.uuid4().hex
    meta = {
        "assetType": "Decal",
        "displayName": display,
        "description": "Painted texture for Maplewick",
        "creationContext": {"creator": creator},
    }
    parts = [
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"request\"\r\n\r\n".encode() + json.dumps(meta).encode(),
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"{os.path.basename(path)}\"\r\n"
        "Content-Type: image/png\r\n\r\n".encode() + open(path, "rb").read(),
    ]
    body = b"\r\n".join(parts) + f"\r\n--{boundary}--\r\n".encode()
    op = json.loads(request("POST", API + "/assets/v1/assets", key, body, f"multipart/form-data; boundary={boundary}"))
    for _ in range(60):
        if op.get("done"):
            return op["response"]["assetId"]
        time.sleep(2)
        op = json.loads(request("GET", API + "/assets/v1/" + op["path"], key))
    raise RuntimeError("upload still processing after two minutes: " + display)


def image_id(decal_id, key):
    """The image a decal shows, read from the decal itself through the Asset Delivery API."""
    info = json.loads(request("GET", f"{API}/asset-delivery-api/v1/assetId/{decal_id}", key))
    with urllib.request.urlopen(info["location"], timeout=60) as r:
        data = r.read().decode("utf-8", "replace")
    m = re.search(r"(?:asset/\?id=|rbxassetid://)(\d+)", data)
    if not m:
        raise RuntimeError(f"no image id inside decal {decal_id}")
    return m.group(1)


def write_ids(ids, order):
    rows = []
    for name in order:
        got = ids.get(name)
        if got:
            fields = ", ".join(f'{k} = "{got[k]}"' for k in ("color", "normal") if k in got)
            rows.append(f"\t{name} = {{ {fields} }},\n")
    table = "{\n" + "".join(rows) + "}" if rows else "{}"
    text = HEADER + f"local TextureIds: {{ [string]: Ids }} = {table}\n\nreturn TextureIds\n"
    open(sync_materials.IDS, "w").write(text)


def main():
    ap = argparse.ArgumentParser()
    who = ap.add_mutually_exclusive_group(required=True)
    who.add_argument("--user", help="your Roblox user id")
    who.add_argument("--group", help="a group id to upload under instead")
    ap.add_argument("--only", help="comma separated texture names")
    ap.add_argument("--no-normals", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    key = os.environ.get("ROBLOX_API_KEY", "")
    if not key and not args.dry_run:
        sys.exit("set ROBLOX_API_KEY to an Open Cloud API key (see the top of this file)")
    creator = {"userId": args.user} if args.user else {"groupId": args.group}
    index = json.load(open(os.path.join(TEX, "textures.json")))
    order = list(index)
    names = args.only.split(",") if args.only else order
    ids = sync_materials.read_ids()
    failed = 0
    for name in names:
        if name not in index:
            print(f"{name}: no such texture")
            failed += 1
            continue
        got = ids.setdefault(name, {})
        jobs = [("color", name + ".png")]
        if not args.no_normals:
            jobs.append(("normal", name + "_n.png"))
        for field, file in jobs:
            if field in got:
                continue
            if args.dry_run:
                print(f"would upload {file}")
                continue
            try:
                decal = upload(os.path.join(TEX, file), f"Maplewick {name} {field}", creator, key)
                image = image_id(decal, key)
                got[field] = f"rbxassetid://{image}"
                print(f"{file}: image {image} (decal {decal})")
                write_ids(ids, order)  # after every picture, so a failure part way keeps the rest
            except Exception as e:  # keep going with the others
                failed += 1
                print(f"{file}: {e}")
    if not args.dry_run:
        write_ids(ids, order)
        sys.argv = ["sync_materials.py"]
        sync_materials.main()
    if failed:
        print(f"{failed} failed; run again to retry them (done ones are skipped)")
        sys.exit(1)


if __name__ == "__main__":
    main()
