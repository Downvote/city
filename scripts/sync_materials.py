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


HEADER = """--!strict
-- Roblox image ids for the materials' textures. Most come from the Creator Store (public decals,
-- found with scripts/library_textures.py; `decal` is the decal they came from, the comment its
-- name and maker); the rest can be our painted ones in art/textures once uploaded
-- (scripts/upload_textures.py). Fields: `color` the image, `normal` an optional normal map,
-- `studs` how many studs one copy covers (else Data/Textures' own), `own` when the picture
-- brings its own colour (the part's paint then only tints it lightly).
-- After changing this, run python3 scripts/sync_materials.py to put it in the place.
-- A texture with no colour id here keeps Roblox's own material.

export type Ids = { color: string?, normal: string?, studs: number?, own: boolean?, decal: number? }

"""


def read_ids(path=IDS):
    """name -> fields from the Luau table (entries look like
    `grass = { color = "rbxassetid://1", studs = 10, own = true, decal = 2 }, -- note`)."""
    text = open(path).read()
    out = {}
    for line in text.splitlines():
        code, _, note = line.partition("--")
        m = re.match(r"\s*(\w+)\s*=\s*\{([^{}]*)\}", code)
        if not m:
            continue
        name, body = m.groups()
        ids = {}
        for key in ("color", "normal"):
            v = re.search(r"\b" + key + r"\s*=\s*" + ID, body)
            if v:
                ids[key] = v.group(1)
        v = re.search(r"\bstuds\s*=\s*([\d.]+)", body)
        if v:
            ids["studs"] = float(v.group(1)) if "." in v.group(1) else int(v.group(1))
        v = re.search(r"\bdecal\s*=\s*(\d+)", body)
        if v:
            ids["decal"] = int(v.group(1))
        if re.search(r"\bown\s*=\s*true", body):
            ids["own"] = True
        if note.strip():
            ids["note"] = note.strip()
        if ids:
            out[name] = ids
    return out


def write_ids(ids, order, path=IDS):
    rows = []
    for name in order:
        got = ids.get(name)
        if not got or "color" not in got:
            continue
        fields = []
        for k in ("color", "normal"):
            if k in got:
                fields.append(f'{k} = "{got[k]}"')
        if "studs" in got:
            fields.append(f"studs = {got['studs']}")
        if got.get("own"):
            fields.append("own = true")
        if "decal" in got:
            fields.append(f"decal = {got['decal']}")
        note = f" -- {got['note']}" if got.get("note") else ""
        rows.append(f"\t{name} = {{ {', '.join(fields)} }},{note}\n")
    table = "{\n" + "".join(rows) + "}" if rows else "{}"
    text = HEADER + f"local TextureIds: {{ [string]: Ids }} = {table}\n\nreturn TextureIds\n"
    open(path, "w").write(text)


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
        p = {"BaseMaterial": info["material"], "ColorMap": got["color"], "StudsPerTile": got.get("studs", info["studs"]),
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
        print(f"materials in sync ({count} textures in the place)")
        return
    if wanted != current:
        open(PROJECT, "w").write(wanted)
    print(f"{count} textures in the place")


if __name__ == "__main__":
    main()
