#!/usr/bin/env python3
"""Checks a dumped screen (tools/preview/ui_dump.luau's JSON) for the dark look: no surface is
left light, and no words are lost against what is behind them.

    python3 tools/preview/ui_audit.py <screen.json> [more.json ...]

The user: "Make every ui element dark mode, with a dark background". A surface is any frame,
button or box that is drawn (not see-through). It may be dark, or it may be a colour (a button,
a bar's fill, a tag), but it may not be white, cream or pale grey. Pieces of drawn icons, the
slider's knob and the dot that marks you on the map are let through. Words must stand out from
the nearest drawn thing behind them unless they carry an outline. A colour chip to pick from (a
paint colour, a finish, a favourite colour, a food's dot) is named "Swatch" and may be any colour.

Prints what it finds and exits 1 if there is anything.
"""
import json
import sys

SURFACES = {"Frame", "TextButton", "TextLabel", "TextBox", "CanvasGroup", "ScrollingFrame", "ImageLabel", "ImageButton"}
WORDS = {"TextLabel", "TextButton", "TextBox"}
# names that may be light on purpose
ALLOWED = {"Knob", "You", "Sheen", "Halo", "Swatch"}


def lum(c):
    return c[0] * 0.3 + c[1] * 0.59 + c[2] * 0.11


def colours(node):
    """The colours a node's background is drawn in (a wash is two), or None if it isn't drawn."""
    p = node["props"]
    if node["class"] not in SURFACES:
        return None
    if p.get("BackgroundTransparency", 0) >= 0.6:
        return None
    base = p.get("BackgroundColor3", [1, 1, 1])
    for c in node["children"]:
        if c["class"] == "UIGradient" and c["props"].get("Enabled", True) and "Color" in c["props"]:
            if c["name"] == "Stripes":
                continue
            keys = c["props"]["Color"]
            return [[k[1] * base[0], k[2] * base[1], k[3] * base[2]] for k in keys]
    return [base]


def pale(c):
    """White, cream or pale grey: bright and with hardly any colour in it."""
    return lum(c) > 0.8 and min(c) > 0.74


def in_icon(path):
    return any(n in ("IconArt", "Icon", "Swatch") or n.startswith("Fill") or n.startswith("Ink") for n in path)


def face_of(node):
    """A Kit button draws its colour on a child called Face (a blob's is Face/Shape/Core), and a
    row or a back button on one called Fill; the words sit beside it, so that is what is behind
    them."""
    for c in node["children"]:
        if c["name"] in ("Face", "Fill"):
            cols = colours(c)
            if cols:
                return cols
            for d in c["children"]:
                if d["name"] == "Shape":
                    for e in d["children"]:
                        if e["name"] == "Core" and colours(e):
                            return colours(e)
    return None


def small(node):
    s = node["props"].get("Size")
    return bool(s) and s[0] == 0 and s[2] == 0 and s[1] <= 28 and s[3] <= 28


def outlined(node):
    return any(c["class"] == "UIStroke" and c["name"] == "TextOutline" for c in node["children"])


def walk(node, path, behind, found):
    here = path + [node["name"]]
    cols = colours(node)
    if cols and not in_icon(here) and node["name"] not in ALLOWED:
        if any(pale(c) for c in cols) and not small(node):
            found.append("light surface: %s %s" % ("/".join(here[-6:]), [round(x * 255) for x in cols[0]]))
    if cols:
        behind = cols
    behind = face_of(node) or behind
    p = node["props"]
    if node["class"] in WORDS and p.get("Text") and p.get("TextTransparency", 0) < 0.6 and behind and not in_icon(here):
        tc = p.get("TextColor3")
        if tc and not outlined(node):
            worst = min(abs(lum(tc) - lum(b)) for b in behind)
            if worst < 0.28:
                found.append(
                    "hard to read: %s %r words %s on %s"
                    % ("/".join(here[-5:]), str(p["Text"])[:24], [round(x * 255) for x in tc], [round(x * 255) for x in behind[0]])
                )
    for c in node["children"]:
        walk(c, here, behind, found)


def main():
    bad = 0
    for path in sys.argv[1:]:
        data = json.load(open(path))
        found = []
        walk(data["root"], [], None, found)
        seen = []
        for f in found:
            if f not in seen:
                seen.append(f)
        for f in seen:
            print("%s: %s" % (path.split("/")[-1], f))
        bad += len(seen)
    if bad:
        print("%d things are not dark" % bad)
        sys.exit(1)
    print("dark look: nothing light left in %d screens" % len(sys.argv[1:]))


if __name__ == "__main__":
    main()
