#!/usr/bin/env python3
"""Uploads the city kit (out/citypack/kit, made by scripts/citypack.py) to Roblox through Open Cloud.

    python3 -I scripts/upload_citykit.py --user <userId>     (or --group <groupId>)

The palette picture goes up as an Image and each of the five FBX files as a Model (Roblox turns an FBX into
a Model of MeshParts, like Studio's importer). Each upload is an operation; the script waits for each to
finish and prints the asset ids for Tuning.City.KitAssetIds and Tuning.City.KitTextureId. It also writes
them to out/citypack/kit/uploaded.json.

The API key is never in this script or on the command line: the session's network proxy adds it to every
request to apis.roblox.com. Elsewhere, set ROBLOX_API_KEY and it is sent as the x-api-key header.
The kit stays out of the repository (it is the user's pack); only the ids go in Tuning.
"""

import argparse
import json
import os
import subprocess
import sys
import time

API = "https://apis.roblox.com/assets/v1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, "out", "citypack", "kit")
FILES = ["Buildings", "Ground", "Nature", "Props", "Vehicles"]


def key_header():
    return ["-H", "x-api-key: " + os.environ.get("ROBLOX_API_KEY", "proxy-injected")]


def curl(args):
    out = subprocess.run(
        ["curl", "-sS", "--max-time", "600", "-w", "\n%{http_code}"] + key_header() + args,
        capture_output=True,
        text=True,
    )
    if out.returncode != 0:
        raise RuntimeError("curl failed: " + out.stderr.strip())
    body, _, code = out.stdout.rpartition("\n")
    return int(code), body


def creator(a):
    return {"userId": str(a.user)} if a.user else {"groupId": str(a.group)}


def upload(a, path, asset_type, content_type, name, description):
    request = {
        "assetType": asset_type,
        "displayName": name,
        "description": description,
        "creationContext": {"creator": creator(a)},
    }
    code, body = curl(
        [
            "-X",
            "POST",
            API + "/assets",
            "--form-string",
            "request=" + json.dumps(request),
            "-F",
            "fileContent=@" + path + ";type=" + content_type,
        ]
    )
    if code >= 300:
        raise RuntimeError(f"{name}: upload refused ({code}): {body[:400]}")
    op = json.loads(body)
    return op.get("path") or ("operations/" + op["operationId"])


def wait(op_path, name):
    for attempt in range(120):
        code, body = curl([API + "/" + op_path])
        if code >= 300:
            raise RuntimeError(f"{name}: checking the upload failed ({code}): {body[:400]}")
        op = json.loads(body)
        if op.get("done"):
            if "error" in op or "status" in op and not op.get("response"):
                raise RuntimeError(f"{name}: Roblox refused it: {json.dumps(op)[:600]}")
            return op["response"]
        time.sleep(min(2 + attempt, 10))
    raise RuntimeError(f"{name}: still not done after waiting")


def main():
    ap = argparse.ArgumentParser()
    who = ap.add_mutually_exclusive_group(required=True)
    who.add_argument("--user", type=int, help="the Roblox user id that owns the game")
    who.add_argument("--group", type=int, help="the group id, when a group owns the game")
    ap.add_argument("--only", choices=["palette"] + FILES, action="append", help="upload just these")
    a = ap.parse_args()

    todo = a.only or (["palette"] + FILES)
    done = {}
    record = os.path.join(KIT, "uploaded.json")
    if os.path.exists(record):
        done = json.load(open(record))
    for item in todo:
        if item == "palette":
            path = os.path.join(KIT, "color_1024x1024.jpg")
            op = upload(a, path, "Image", "image/jpeg", "CityKit palette", "Colour palette for the city kit")
        else:
            path = os.path.join(KIT, f"CityKit_{item}.fbx")
            size = os.path.getsize(path)
            if size > 20 * 1024 * 1024:
                raise RuntimeError(f"{path} is {size} bytes, over Open Cloud's 20 MB")
            op = upload(a, path, "Model", "model/fbx", f"CityKit_{item}", f"City kit: {item.lower()}")
        print(f"{item}: uploaded, waiting for Roblox ({op})", flush=True)
        response = wait(op, item)
        done[item] = int(response["assetId"])
        print(f"{item}: asset {done[item]}", flush=True)
        json.dump(done, open(record, "w"), indent=2)
    print(json.dumps(done, indent=2))


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        print("error:", e, file=sys.stderr)
        sys.exit(1)
