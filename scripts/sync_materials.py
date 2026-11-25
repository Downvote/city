#!/usr/bin/env python3
"""Puts the textures that have uploaded ids into the place file: a MaterialVariant for each under
MaterialService in default.project.json, and MaterialService's <Material>Name properties
pointing each material at its variant. Roblox only lets plugins set a variant's maps, so they go
in at build time rather than from a script while the game runs.

A look (an entry of art/textures/textures.json with a "look", such as Concrete's Panel) gets its
MaterialVariant too, named CatalogTown<Look>, but no <Material>Name property: it takes no
material's place, and only the parts that name it wear it.

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
-- Roblox image ids for the materials' textures and for the looks (Data/Textures). They come from
-- the Creator Store (public decals, found with scripts/library_textures.py; `decal` is the decal
-- they came from, the comment its name and maker). Our own painted set in art/textures can take a
-- texture's place once uploaded (scripts/upload_textures.py, which starts the comment with
-- "painted"). Fields: `color` the image, `normal` an optional normal map (OpenGL style, the kind
-- Roblox reads) and `rough` an optional roughness map, both from the same set as the colour
-- where the picture has a pattern (bricks, cobbles, tiles), `studs` how many studs one copy
-- covers (else Data/Textures' own), `own` when the picture brings its own colour (the part's
-- paint then only tints it lightly), `light` how light the picture is on average (0 to 1) when
-- it is a good deal darker than the rest: the part's paint is then brightened to make up for
-- it, as far as the colour can go (Textures.shade).
-- After changing this, run python3 scripts/sync_materials.py to put it in the place.
-- A texture with no colour id here keeps Roblox's own material, and a look with none shows its
-- material. One texture a line: the scripts and the preview read this file line by line.

export type Ids = {
\tcolor: string?,
\tnormal: string?,
\trough: string?,
\tstuds: number?,
\town: boolean?,
\tlight: number?,
\tdecal: number?,
}

-- stylua: ignore
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
        for key in ("color", "normal", "rough"):
            v = re.search(r"\b" + key + r"\s*=\s*" + ID, body)
            if v:
                ids[key] = v.group(1)
        v = re.search(r"\bstuds\s*=\s*([\d.]+)", body)
        if v:
            ids["studs"] = float(v.group(1)) if "." in v.group(1) else int(v.group(1))
        v = re.search(r"\bdecal\s*=\s*(\d+)", body)
        if v:
            ids["decal"] = int(v.group(1))
        v = re.search(r"\blight\s*=\s*([\d.]+)", body)
        if v:
            ids["light"] = float(v.group(1))
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
        for k in ("color", "normal", "rough"):
            if k in got:
                fields.append(f'{k} = "{got[k]}"')
        if "studs" in got:
            fields.append(f"studs = {got['studs']}")
        if got.get("own"):
            fields.append("own = true")
        if "light" in got:
            fields.append(f"light = {got['light']:g}")
        if "decal" in got:
            fields.append(f"decal = {got['decal']}")
        note = f" -- {got['note']}" if got.get("note") else ""
        rows.append(f"\t{name} = {{ {', '.join(fields)} }},{note}\n")
    table = "{\n" + "".join(rows) + "}" if rows else "{}"
    text = HEADER + f"local TextureIds: {{ [string]: Ids }} = {table}\n\nreturn TextureIds\n"
    open(path, "w").write(text)


# Materials that keep Roblox's own face: the island's terrain is Grass, and the user liked Roblox's
# own grass texture there ("never mind, the previous grass texture was ok"); ours is a look.
KEEP_OWN = {"Grass"}


def variant_name(name, info=None):
    """The MaterialVariant a texture becomes: CatalogTownSand for sand, CatalogTown<Look> for a look."""
    if info and info.get("look"):
        return "CatalogTown" + info["look"]
    return "CatalogTown" + name[:1].upper() + name[1:]


def material_service(ids, index):
    node = {"$className": "MaterialService"}
    props = {}
    variants = {}
    for name, info in index.items():
        got = ids.get(name, {})
        if "color" not in got:
            continue
        v = variant_name(name, info)
        if v in variants:
            sys.exit(f"two textures would both be the MaterialVariant {v}: rename {name}")
        p = {"BaseMaterial": info["material"], "ColorMap": got["color"], "StudsPerTile": got.get("studs", info["studs"]),
             "MaterialPattern": "Regular"}
        if "normal" in got:
            p["NormalMap"] = got["normal"]
        # a texture without its own roughness map takes the flat grey one (`sheen`), so it shines a little
        rough = got.get("rough") or ids.get("sheen", {}).get("color")
        if rough:
            p["RoughnessMap"] = rough
        variants[v] = {"$className": "MaterialVariant", "$properties": p}
        if info["material"] in KEEP_OWN and not info.get("look"):
            sys.exit(f"{name} would take {info['material']}'s place, which the terrain needs as Roblox's own: "
                     "make it a look")
        if not info.get("look"):  # a look takes no material's place
            props[info["material"] + "Name"] = v
    if not variants:
        return None
    if props:
        node["$properties"] = props
    node.update(variants)
    return node


def counts(node):
    """How many MaterialVariants the node holds, and how many of them are looks (no override)."""
    if not node:
        return 0, 0
    variants = [k for k, v in node.items() if isinstance(v, dict) and v.get("$className") == "MaterialVariant"]
    overrides = set(node.get("$properties", {}).values())
    return len(variants), len([v for v in variants if v not in overrides])


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
    count, looks = counts(node)
    said = f"{count} textures in the place" + (f", {looks} of them looks" if looks else "")
    if args.check:
        if wanted != current:
            print("default.project.json is out of date with Data/TextureIds: run python3 scripts/sync_materials.py")
            sys.exit(1)
        print(f"materials in sync ({said})")
        return
    if wanted != current:
        open(PROJECT, "w").write(wanted)
    print(said)


if __name__ == "__main__":
    main()
