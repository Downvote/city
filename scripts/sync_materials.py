#!/usr/bin/env python3
"""Puts the painted textures that have uploaded ids into the place file: a MaterialVariant for each
under MaterialService in default.project.json, and MaterialService's <Material>Name properties
pointing each material at its variant. Roblox only lets plugins set a variant's maps, so they go
in at build time rather than from a script while the game runs.

    python3 scripts/sync_materials.py          rewrite default.project.json from Data/TextureIds
    python3 scripts/sync_materials.py --check  exit 1 if default.project.json is out of date
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PROJECT = os.path.join(ROOT, "default.project.json")
IDS = os.path.join(ROOT, "src", "shared", "Data", "TextureIds.luau")
INDEX = os.path.join(ROOT, "art", "textures", "textures.json")
ID = r'"(rbxassetid://\d+)"'


def read_ids(path=IDS):
    """name -> {"color": id, "normal": id} from the Luau table (entries look like
    `grass = { color = "rbxassetid://1", normal = "rbxassetid://2" },`)."""
    text = open(path).read()
    text = re.sub(r"--[^\n]*", "", text)  # comments hold an example entry
    out = {}
    for name, body in re.findall(r"\b(\w+)\s*=\s*\{([^{}]*)\}", text):
        ids = {}
        for key in ("color", "normal"):
            m = re.search(r"\b" + key + r"\s*=\s*" + ID, body)
            if m:
                ids[key] = m.group(1)
        if ids:
            out[name] = ids
    return out


def variant_name(name):
    return "Maplewick" + name[:1].upper() + name[1:]


def material_service(ids, index):
    node = {"$className": "MaterialService"}
    props = {}
    variants = {}
    for name, info in index.items():
        got = ids.get(name, {})
        if "color" not in got:
            continue
        v = variant_name(name)
        p = {"BaseMaterial": info["material"], "ColorMap": got["color"], "StudsPerTile": info["studs"],
             "MaterialPattern": "Regular"}
        if "normal" in got:
            p["NormalMap"] = got["normal"]
        variants[v] = {"$className": "MaterialVariant", "$properties": p}
        props[info["material"] + "Name"] = v
    if not variants:
        return None
    node["$properties"] = props
    node.update(variants)
    return node


def render(project):
    return json.dumps(project, indent=2) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    current = open(PROJECT).read()
    project = json.loads(current)
    node = material_service(read_ids(), json.load(open(INDEX)))
    if node:
        project["tree"]["MaterialService"] = node
    else:
        project["tree"].pop("MaterialService", None)
    wanted = render(project)
    count = 0 if not node else len(node) - 2
    if args.check:
        if wanted != current:
            print("default.project.json is out of date with Data/TextureIds: run python3 scripts/sync_materials.py")
            sys.exit(1)
        print(f"materials in sync ({count} painted textures in the place)")
        return
    if wanted != current:
        open(PROJECT, "w").write(wanted)
    print(f"{count} painted textures in the place")


if __name__ == "__main__":
    main()
