#!/usr/bin/env python3
"""Turns the low poly city pack the user sent into three things:

  out/citypack/kit/*.fbx      the kit: every different mesh once, in studs, for Studio's importer
                              (with the palette picture beside it and IMPORT.md, the steps)
  out/citypack/meshes.npz     the preview cache: the kit's triangles with a colour each
  src/shared/Data/CityPack.luau  the manifest: each kit key's pieces (size, centre) and every
                              placement in the pack (key, position, turn, stretch), in studs

    python3 -I scripts/citypack.py <LowPoly_City_01Ready.fbx or its glTF export> --textures <dir>
        [--out out/citypack] [--manifest src/shared/Data/CityPack.luau] [--no-kit]

The pack is someone else's work and the repository is public: the FBX, the textures and anything
made from their meshes (the kit, the cache, a Studio file holding the meshes) stay in out/, which
git ignores, or outside the repository. Only this script and the manifest (names, sizes and where
things stand) are committed.

An FBX is read through assimp (`apt install assimp-utils`): `assimp export` turns it into glTF
under out/citypack/scene/ once (it takes about six minutes) and later runs reuse that.

How the kit is made:
- Meshes with the same triangles are one key. The key is the pack's object name without its
  numbers (`tree`, `road_a`, `house`), with a two digit number when one name has several meshes.
- A key's mesh is stored as its first placement shows it in the city, minus its turn about the
  vertical and in studs (the pack is in centimetres; 28 to a stud). So every placement is a
  position, a turn and, for the trees the pack stretched, a stretch along the key's own axes.
- A placement that is the mirror image of its key uses the key turned or moved when the mesh is
  symmetric, else a mirrored copy `<key>_m` (Roblox can't mirror a part).
- Studio takes at most 20,000 triangles a mesh, so a bigger key is cut into pieces `<key>__1`,
  `<key>__2`... along its longest side. The pieces share the key's frame.
- Studio sets a MeshPart's position at the centre of its box, so the manifest lists each piece's
  centre in the key's frame: a piece goes at `placement * CFrame.new(centre * stretch)`.
"""
import argparse
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict

import numpy as np

UNIT = 28.0  # pack units (centimetres) to a stud: Roblox's 0.28 m
TRI_LIMIT = 19000  # Studio's importer refuses a mesh over 20,000 triangles; keep a margin
PALETTE = "color_1024x1024.jpg"

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

COMP = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}

# What each of the pack's names is. The kind decides the kit file a key goes in and, in the game,
# how it collides (Data/CityPack's Kinds).
KINDS = {
    "road": ["road_a", "road_b", "road_c", "parking_area", "bridge_a"],
    "ground": ["green_a", "land", "landscape", "sand_a", "water_a", "water_b", "wall", "basketballcourt"],
    "nature": ["tree", "plants", "park_a", "park_b", "park_c", "park_e", "park_f", "logs_a", "timber_a"],
    "vehicle": ["car_", "jeep_", "truck", "tractor_", "cart_", "lawn_mower_a", "airballoon_"],
    "prop": [
        "streetsign", "fence_", "gate_a", "bench_b", "barrel_", "cratebox_a", "mailbox_a", "props", "sport",
        "table_chair", "armchairs", "gamingchair", "milk", "vegetables", "fruitshop", "cheesemarket",
        "caffeeshop", "ice_cream", "farmstractures", "factorystructure",
    ],
}
FILES = {  # kit file per kind
    "building": "CityKit_Buildings",
    "road": "CityKit_Ground",
    "ground": "CityKit_Ground",
    "nature": "CityKit_Nature",
    "vehicle": "CityKit_Vehicles",
    "prop": "CityKit_Props",
}


def kind_of(base):
    for kind, names in KINDS.items():
        if any(base.startswith(n.rstrip("_")) for n in names):
            return kind
    return "building"


def base_name(name):
    k = name.lower()
    k = re.sub(r"_mesh.*$", "", k)
    k = re.sub(r"(\.\d+)+$", "", k)
    k = re.sub(r"\d+$", "", k)
    return re.sub(r"[^a-z0-9]+", "_", k).strip("_")


# ---------------------------------------------------------------------------------------------
# glTF


class Gltf:
    def __init__(self, path):
        self.path = path
        self.gl = json.load(open(path))
        base = os.path.dirname(path)
        self.bin = np.memmap(os.path.join(base, self.gl["buffers"][0]["uri"]), dtype=np.uint8, mode="r")

    def accessor(self, i):
        a = self.gl["accessors"][i]
        bv = self.gl["bufferViews"][a["bufferView"]]
        dt = COMP[a["componentType"]]
        n = NCOMP[a["type"]]
        off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        stride = bv.get("byteStride", 0)
        count = a["count"]
        size = np.dtype(dt).itemsize * n
        if stride and stride != size:
            raw = np.lib.stride_tricks.as_strided(
                np.frombuffer(self.bin, dtype=np.uint8, count=stride * count, offset=off),
                shape=(count, size), strides=(stride, 1)).copy()
            return raw.view(dt).reshape(count, n)
        return np.frombuffer(self.bin, dtype=dt, count=count * n, offset=off).reshape(count, n).copy()

    def mesh(self, mi):
        """A mesh as flat triangle lists: positions (n,3,3), normals (n,3,3), uvs (n,3,2)."""
        P, N, U = [], [], []
        for prim in self.gl["meshes"][mi]["primitives"]:
            if prim.get("mode", 4) != 4:
                continue
            at = prim["attributes"]
            pos = self.accessor(at["POSITION"]).astype(np.float64)
            idx = self.accessor(prim["indices"]).reshape(-1, 3).astype(np.int64) if "indices" in prim \
                else np.arange(len(pos)).reshape(-1, 3)
            nor = self.accessor(at["NORMAL"]).astype(np.float64) if "NORMAL" in at else None
            uv = self.accessor(at["TEXCOORD_0"]).astype(np.float64) if "TEXCOORD_0" in at else np.zeros((len(pos), 2))
            tri = pos[idx]
            if nor is None:
                fn = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
                fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-12
                n3 = np.repeat(fn[:, None, :], 3, axis=1)
            else:
                n3 = nor[idx]
            P.append(tri)
            N.append(n3)
            U.append(uv[idx])
        if not P:
            return np.zeros((0, 3, 3)), np.zeros((0, 3, 3)), np.zeros((0, 3, 2))
        return np.concatenate(P), np.concatenate(N), np.concatenate(U)

    def placements(self):
        nodes = self.gl["nodes"]
        out = []

        def mat(n):
            if "matrix" in n:
                return np.array(n["matrix"], dtype=float).reshape(4, 4).T
            T = np.eye(4)
            t = n.get("translation", [0, 0, 0])
            x, y, z, w = n.get("rotation", [0, 0, 0, 1])
            s = n.get("scale", [1, 1, 1])
            R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                          [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                          [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
            T[:3, :3] = R @ np.diag(s)
            T[:3, 3] = t
            return T

        def walk(i, parent):
            n = nodes[i]
            M = parent @ mat(n)
            if "mesh" in n:
                out.append((n.get("name", ""), n["mesh"], M))
            for c in n.get("children", []):
                walk(c, M)

        for r in self.gl["scenes"][self.gl.get("scene", 0)]["nodes"]:
            walk(r, np.eye(4))
        return out


def scene_from(src, out_dir):
    """The pack as glTF: the file itself, or assimp's export of the FBX, cached under out_dir."""
    if src.lower().endswith((".gltf", ".glb")):
        return src
    stamp = f"{os.path.getsize(src)}:{int(os.path.getmtime(src))}"
    scene = os.path.join(out_dir, "scene", "city.gltf")
    stamp_file = os.path.join(out_dir, "scene", "stamp.txt")
    if os.path.exists(scene) and os.path.exists(stamp_file) and open(stamp_file).read() == stamp:
        return scene
    os.makedirs(os.path.dirname(scene), exist_ok=True)
    print("assimp: turning the FBX into glTF (about six minutes)...")
    subprocess.run(["assimp", "export", src, scene, "-fgltf2"], check=True, stdout=subprocess.DEVNULL)
    open(stamp_file, "w").write(stamp)
    return scene


# ---------------------------------------------------------------------------------------------
# The rotations Roblox uses (CFrame.Angles / fromEulerAnglesYXZ): right handed, Y up.


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def euler_yxz(R):
    """(rx, ry, rz) in radians with R = Ry(ry) @ Rx(rx) @ Rz(rz), as CFrame.fromEulerAnglesYXZ."""
    rx = math.asin(max(-1.0, min(1.0, -R[1, 2])))
    if abs(R[1, 2]) < 0.99999:
        ry = math.atan2(R[0, 2], R[2, 2])
        rz = math.atan2(R[1, 0], R[1, 1])
    else:
        ry = math.atan2(-R[2, 0], R[0, 0])
        rz = 0.0
    return rx, ry, rz


def ryxz(rx, ry, rz):
    cx, sx = math.cos(rx), math.sin(rx)
    cz, sz = math.cos(rz), math.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return rot_y(ry) @ Rx @ Rz


def polar(A):
    """A = R @ P with R a rotation and P symmetric positive."""
    U, S, Vt = np.linalg.svd(A)
    R = U @ Vt
    if np.linalg.det(R) < 0:
        U[:, -1] *= -1
        S[-1] *= -1
        R = U @ Vt
    P = Vt.T @ np.diag(S) @ Vt
    return R, P


def canonical_yaw(L):
    """The turn about the vertical to take off a placement so its mesh lines up with the axes: the
    world direction of the first of the mesh's own axes that lies flat, as a yaw."""
    for j in range(3):
        w = L[:, j]
        flat = math.hypot(w[0], w[2])
        if flat > 0.9 * np.linalg.norm(w):
            return math.atan2(-w[2], w[0])
    return 0.0


# ---------------------------------------------------------------------------------------------


class Key:
    def __init__(self, name, kind, tri, nor, uv):
        self.name, self.kind = name, kind
        self.tri, self.nor, self.uv = tri, nor, uv
        self.pieces = []  # (name, slice of triangles)

    def split(self):
        n = len(self.tri)
        if n <= TRI_LIMIT:
            self.pieces = [(self.name, np.arange(n))]
            return
        cen = self.tri.mean(1)
        out = []

        def cut(ix):
            if len(ix) <= TRI_LIMIT:
                out.append(ix)
                return
            c = cen[ix]
            ax = int(np.argmax(c.max(0) - c.min(0)))
            order = ix[np.argsort(c[:, ax], kind="stable")]
            parts = math.ceil(len(ix) / TRI_LIMIT)
            half = len(order) * (parts // 2) // parts
            cut(order[:half])
            cut(order[half:])

        cut(np.arange(n))
        out.sort(key=lambda ix: tuple(np.round(cen[ix].mean(0), 1)))
        self.pieces = [(f"{self.name}__{i + 1}", ix) for i, ix in enumerate(out)]

    def piece_box(self, ix):
        p = self.tri[ix].reshape(-1, 3)
        lo, hi = p.min(0), p.max(0)
        return (lo + hi) / 2, hi - lo


def mirrored(tri, nor, uv, axis=0):
    F = np.ones(3)
    F[axis] = -1
    return (tri * F)[:, ::-1], (nor * F)[:, ::-1], uv[:, ::-1]


def same_surface(a, ca, b, cb, tol=0.02):
    """Whether two meshes are the same surface: the same corners with the same colours, in any
    order. Corners, not triangles, since a mirrored square is split along its other diagonal."""
    def corners(t, c):
        p = t.reshape(-1, 3)
        col = np.repeat(c, 3, axis=0)
        key = np.concatenate([np.round(p / tol), np.round(col * 20)], axis=1)
        return np.unique(key, axis=0)
    ka, kb = corners(a, ca), corners(b, cb)
    if len(ka) != len(kb):
        return False
    return bool((ka == kb).all())


def symmetric(tri, col):
    """How a key's mirror image can be had without a copy: ('x', c) when the mesh is its own mirror
    across the plane x = c, ('z', c) across z = c, else None."""
    if len(tri) > 8000:
        return None
    lo = tri.reshape(-1, 3).min(0)
    hi = tri.reshape(-1, 3).max(0)
    c = (lo + hi) / 2
    for axis, name in ((0, "x"), (2, "z")):
        m = tri.copy()
        m[..., axis] = 2 * c[axis] - m[..., axis]
        if same_surface(m, col, tri, col):
            return name, c[axis]
    return None


def build(gl, palette):
    """Groups the pack's placements by mesh, makes the keys and lists the placements."""
    placed = gl.placements()
    groups = {}
    order = []
    mesh_group = {}
    for mi in range(len(gl.gl["meshes"])):
        tri, nor, uv = gl.mesh(mi)
        h = hashlib.sha1(np.round(tri, 3).tobytes() + np.round(uv, 4).tobytes()).hexdigest()
        if h not in groups:
            groups[h] = {"mesh": mi, "placements": []}
            order.append(h)
        mesh_group[mi] = h
    for name, mi, M in placed:
        groups[mesh_group[mi]]["placements"].append((name, M))
    order = [h for h in order if groups[h]["placements"]]

    by_base = defaultdict(list)
    for h in order:
        by_base[base_name(groups[h]["placements"][0][0])].append(h)

    keys = {}
    placements = []
    shear = []
    for base in sorted(by_base):
        hs = by_base[base]
        width = max(2, len(str(len(hs))))
        for n, h in enumerate(hs):
            g = groups[h]
            kname = base if len(hs) == 1 else f"{base}_{n + 1:0{width}d}"
            tri, nor, uv = gl.mesh(g["mesh"])
            pl = g["placements"]
            # the key's own frame: its first placement the right way round, minus its yaw
            first = next((M for _, M in pl if np.linalg.det(M[:3, :3]) > 0), pl[0][1])
            L0 = first[:3, :3]
            yaw0 = canonical_yaw(L0)
            B = rot_y(-yaw0) @ L0 / UNIT
            # snap B's tiny noise away so the kit lines up with the axes exactly
            B[np.abs(B) < 1e-9 * np.abs(B).max()] = 0.0
            Binv = np.linalg.inv(B)
            ktri = tri @ B.T
            knor = nor @ Binv
            knor /= np.linalg.norm(knor, axis=2, keepdims=True) + 1e-12
            kuv = uv
            if np.linalg.det(B) < 0:
                ktri, knor, kuv = ktri[:, ::-1], knor[:, ::-1], kuv[:, ::-1]
            kind = kind_of(base)
            if kind == "building" and np.ptp(ktri[..., 1]) < 2:
                kind = "ground"  # the flat lots under the pack's houses
            key = Key(kname, kind, ktri, knor, kuv)
            keys[kname] = key
            sym = "unknown"
            for pname, M in pl:
                A = (M[:3, :3] / UNIT) @ Binv  # kit studs to world studs
                t = M[:3, 3] / UNIT
                use = kname
                if np.linalg.det(A) < 0:
                    if sym == "unknown":
                        sym = symmetric(ktri, sample_colours(kuv, palette))
                    if sym is None:
                        use = kname + "_m"
                        if use not in keys:
                            mt, mn, mu = mirrored(ktri, knor, kuv, 0)
                            keys[use] = Key(use, key.kind, mt, mn, mu)
                        A = A @ np.diag([-1.0, 1.0, 1.0])
                    elif sym[0] == "x":
                        t = t + A @ np.array([2 * sym[1], 0, 0])
                        A = A @ np.diag([-1.0, 1.0, 1.0])
                    else:
                        t = t + A @ np.array([0, 0, 2 * sym[1]])
                        A = A @ np.diag([1.0, 1.0, -1.0])
                R, P = polar(A)
                scale = np.diag(P).copy()
                off = P - np.diag(scale)
                if np.abs(off).max() > 1e-3 * np.abs(scale).max():
                    shear.append(pname)
                placements.append({"key": use, "name": pname, "pos": t, "rot": R, "scale": scale})
    for k in keys.values():
        k.split()
    return keys, placements, shear


# ---------------------------------------------------------------------------------------------
# The kit: glTF per file, turned into FBX by assimp


def write_gltf(path, keys, image):
    """One glTF with every key in `keys`, laid out apart on a grid so they can be told apart in
    Studio. Each piece is its own node and mesh, named by the piece."""
    nodes, meshes, accessors, views = [], [], [], []
    blob = bytearray()

    def add(arr, target, kind, minmax=False):
        arr = np.ascontiguousarray(arr)
        while len(blob) % 4:
            blob.append(0)
        off = len(blob)
        blob.extend(arr.tobytes())
        views.append({"buffer": 0, "byteOffset": off, "byteLength": arr.nbytes, "target": target})
        a = {"bufferView": len(views) - 1, "componentType": 5126 if arr.dtype == np.float32 else 5125,
             "count": len(arr), "type": kind}
        if minmax:
            a["min"] = arr.min(0).tolist()
            a["max"] = arr.max(0).tolist()
        accessors.append(a)
        return len(accessors) - 1

    cols = max(1, int(math.ceil(math.sqrt(len(keys)))))
    sizes = [k.tri.reshape(-1, 3).max(0) - k.tri.reshape(-1, 3).min(0) for k in keys]
    cell = max(20.0, float(np.max([max(s[0], s[2]) for s in sizes])) * 0.5)
    x = z = 0.0
    row_depth = 0.0
    for i, k in enumerate(keys):
        lo = k.tri.reshape(-1, 3).min(0)
        hi = k.tri.reshape(-1, 3).max(0)
        if i % cols == 0 and i:
            x = 0.0
            z += row_depth + 10
            row_depth = 0.0
        at = np.array([x - lo[0], 0.0, z - lo[2]])
        x += (hi[0] - lo[0]) + 10
        row_depth = max(row_depth, hi[2] - lo[2])
        for pname, ix in k.pieces:
            flat = np.concatenate([k.tri[ix].reshape(-1, 3), k.nor[ix].reshape(-1, 3), k.uv[ix].reshape(-1, 2)],
                                  axis=1).astype(np.float32)
            uniq, idx = np.unique(flat, axis=0, return_inverse=True)  # corners shared by triangles once
            pos, nor, uv = uniq[:, :3].copy(), uniq[:, 3:6].copy(), uniq[:, 6:8].copy()
            idx = idx.reshape(-1).astype(np.uint32)
            prim = {"attributes": {"POSITION": add(pos, 34962, "VEC3", True), "NORMAL": add(nor, 34962, "VEC3"),
                                   "TEXCOORD_0": add(uv, 34962, "VEC2")},
                    "indices": add(idx, 34963, "SCALAR"), "material": 0, "mode": 4}
            meshes.append({"name": pname, "primitives": [prim]})
            nodes.append({"name": pname, "mesh": len(meshes) - 1, "translation": at.tolist()})
    gl = {
        "asset": {"version": "2.0", "generator": "Maplewick scripts/citypack.py"},
        "scene": 0,
        "scenes": [{"nodes": list(range(len(nodes)))}],
        "nodes": nodes,
        "meshes": meshes,
        "materials": [{"name": "Palette", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0},
                                                                   "metallicFactor": 0.0, "roughnessFactor": 1.0}}],
        "textures": [{"source": 0, "sampler": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}],
        "images": [{"uri": image}],
        "buffers": [{"uri": os.path.basename(path).replace(".gltf", ".bin"), "byteLength": len(blob)}],
        "bufferViews": views,
        "accessors": accessors,
    }
    open(path.replace(".gltf", ".bin"), "wb").write(blob)
    json.dump(gl, open(path, "w"))


def fbx_compress(path):
    """Packs a binary FBX's big arrays with zlib, as Blender and Autodesk's own exporters do (assimp
    leaves them raw, which makes the files five times bigger). Everything else is kept as it is."""
    import struct
    import zlib

    d = open(path, "rb").read()
    version = struct.unpack("<I", d[23:27])[0]
    wide = version >= 7500
    head = struct.Struct("<QQQB" if wide else "<IIIB")
    null = b"\0" * head.size
    sizes = {"Y": 2, "C": 1, "I": 4, "F": 4, "D": 8, "L": 8}
    asize = {"f": 4, "d": 8, "l": 8, "i": 4, "b": 1}

    def read(off):
        end, nprops, plen, nl = head.unpack_from(d, off)
        if end == 0:
            return None, off + head.size
        name = d[off + head.size:off + head.size + nl]
        p = off + head.size + nl
        props = []
        for _ in range(nprops):
            t = chr(d[p])
            p += 1
            if t in sizes:
                props.append(d[p - 1:p + sizes[t]])
                p += sizes[t]
            elif t in asize:
                n, enc, clen = struct.unpack_from("<III", d, p)
                raw = d[p + 12:p + 12 + clen]
                if enc == 0 and n * asize[t] > 128:
                    packed = zlib.compress(raw, 9)
                    props.append(t.encode() + struct.pack("<III", n, 1, len(packed)) + packed)
                else:
                    props.append(d[p - 1:p + 12 + clen])
                p += 12 + clen
            elif t in "SR":
                n = struct.unpack_from("<I", d, p)[0]
                props.append(d[p - 1:p + 4 + n])
                p += 4 + n
            else:
                raise ValueError(f"unknown FBX property type {t!r}")
        children = []
        sentinel = False
        while p < end:
            child, p2 = read(p)
            if child is None:
                sentinel = True
                p = p2
                break
            children.append(child)
            p = p2
        return (name, props, children, sentinel), end

    def write(node, out, at):
        name, props, children, sentinel = node
        body = b"".join(props)
        at += head.size + len(name) + len(body)
        parts = []
        for c in children:
            blob = write(c, [], at)
            parts.append(blob)
            at += len(blob)
        if sentinel:
            parts.append(null)
            at += len(null)
        return head.pack(at, len(props), len(body), len(name)) + name + body + b"".join(parts)

    nodes = []
    off = 27
    while True:
        node, off = read(off)
        if node is None:
            break
        nodes.append(node)
    out = bytearray(d[:27])
    for n in nodes:
        out += write(n, [], len(out))
    out += null
    out += bytes.fromhex("fabcab09d0c8d466b176fb831cf7267e") + b"\0\0\0\0"
    pad = ((len(out) + 15) & ~15) - len(out)
    out += b"\0" * (pad or 16)
    out += struct.pack("<I", version) + b"\0" * 120 + bytes.fromhex("f85a8c6adef5d97eece90ce3758f290b")
    open(path, "wb").write(bytes(out))


def sample_colours(uv, tex):
    h, w, _ = tex.shape
    c = uv.mean(1)
    u = np.clip((c[:, 0] % 1.0) * w, 0, w - 1).astype(int)
    v = np.clip((c[:, 1] % 1.0) * h, 0, h - 1).astype(int)
    return tex[v, u]


def read_back(fbx, work):
    """The FBX read again through assimp: piece name -> (triangles, uvs)."""
    back = os.path.join(work, os.path.basename(fbx).replace(".fbx", "_back.gltf"))
    subprocess.run(["assimp", "export", fbx, back, "-fgltf2"], check=True, stdout=subprocess.DEVNULL)
    g = Gltf(back)
    out = {}
    for name, mi, M in g.placements():
        tri, _, uv = g.mesh(mi)
        out[name] = (tri @ M[:3, :3].T + M[:3, 3], uv)
    return out


def write_kit(keys, out_dir, palette_src, tex):
    kit = os.path.join(out_dir, "kit")
    work = os.path.join(out_dir, "work")
    for d in (kit, work):
        os.makedirs(d, exist_ok=True)
    shutil.copy(palette_src, os.path.join(kit, PALETTE))
    shutil.copy(palette_src, os.path.join(work, PALETTE))
    files = defaultdict(list)
    for k in sorted(keys.values(), key=lambda k: k.name):
        files[FILES[k.kind]].append(k)
    report = []
    problems = []
    for fname, ks in sorted(files.items()):
        gpath = os.path.join(work, fname + ".gltf")
        write_gltf(gpath, ks, PALETTE)
        fbx = os.path.join(kit, fname + ".fbx")
        subprocess.run(["assimp", "export", gpath, fbx, "-ffbx"], check=True, stdout=subprocess.DEVNULL)
        fbx_compress(fbx)
        back = read_back(fbx, work)
        want = {pname: (k, ix) for k in ks for pname, ix in k.pieces}
        missing = sorted(set(want) - set(back))
        extra = sorted(set(back) - set(want))
        if missing or extra:
            problems.append(f"{fname}: names lost {missing[:5]} or added {extra[:5]}")
        tris = 0
        biggest = 0
        for pname, (k, ix) in want.items():
            if pname not in back:
                continue
            btri, buv = back[pname]
            n = len(ix)
            tris += n
            biggest = max(biggest, n)
            if len(btri) != n:
                problems.append(f"{pname}: {len(btri)} triangles came back, {n} went in")
                continue
            # sizes match (the grid moved it; the box's size must not change, nor turn)
            s_in = np.ptp(k.tri[ix].reshape(-1, 3), 0)
            s_back = np.ptp(btri.reshape(-1, 3), 0)
            if np.abs(s_in - s_back).max() > 0.01 + 1e-4 * s_in.max():
                problems.append(f"{pname}: size {np.round(s_in, 2)} came back as {np.round(s_back, 2)}")
            # winding (a mirror flips it) and colours (the uvs) survive
            a = k.tri[ix]
            n_in = np.cross(a[:, 1] - a[:, 0], a[:, 2] - a[:, 0])
            n_back = np.cross(btri[:, 1] - btri[:, 0], btri[:, 2] - btri[:, 0])
            agree = (np.sign((n_in * n_back).sum(1)) >= 0).mean()
            if agree < 0.99:
                problems.append(f"{pname}: triangles face the other way ({agree:.2f} agree)")
            c_in = sample_colours(k.uv[ix], tex)
            c_back = sample_colours(buv, tex)
            same = (np.abs(np.sort(c_in, 0) - np.sort(c_back, 0)).max(1) < 0.02).mean()
            if same < 0.98:
                problems.append(f"{pname}: colours changed ({same:.2f} the same)")
        report.append((fname, len(ks), len(want), tris, biggest, os.path.getsize(fbx)))
    return report, problems


# ---------------------------------------------------------------------------------------------
# The manifest


def fmt(x, nd=2):
    s = f"{x:.{nd}f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def write_manifest(path, keys, placements, source):
    lines = []
    w = lines.append
    w("--!nocheck")
    w("-- (Generated data with names and numbers in one list, which the type checker can't follow.)")
    w("-- The city pack's kit and where the pack puts each piece. Written by scripts/citypack.py from the")
    w("-- user's low poly city pack; never edit it by hand. It holds names, sizes and positions only: the")
    w("-- pack's meshes are imported in Studio (out/citypack/kit/IMPORT.md) and never kept in the repository.")
    w("--")
    w("-- Kit[key] = { kind, { piece, size x, y, z, centre x, y, z, triangles }, ... }: a key's pieces, each a")
    w("-- MeshPart named by the piece (the key itself when it has one), with the size Studio gives it, the")
    w("-- centre of its box in the key's own frame (studs) and how many triangles it has.")
    w("-- Placed = { key, x, y, z, yaw [, rx, rz] [, sx, sy, sz] }: where the pack puts a key, in the pack's")
    w("-- own frame and in studs, turned yaw degrees about the vertical (and rx, rz degrees as")
    w("-- CFrame.fromEulerAnglesYXZ takes them, for the few that lean) and stretched along its own axes.")
    w("-- Data/CityMap turns and moves the pack into the game's town.")
    w("")
    w("local CityPack = {}")
    w("")
    w(f"CityPack.Source = {json.dumps(source)}")
    w(f"CityPack.Unit = {fmt(UNIT)} -- pack units (centimetres) to a stud")
    w("")
    w("CityPack.Kit = {")
    for name in sorted(keys):
        k = keys[name]
        parts = []
        for pname, ix in k.pieces:
            c, s = k.piece_box(ix)
            parts.append("{ " + ", ".join([json.dumps(pname)] + [fmt(v, 3) for v in s] + [fmt(v, 3) for v in c]
                                          + [str(len(ix))]) + " }")
        w(f"\t{name} = {{ {json.dumps(k.kind)}, " + ", ".join(parts) + " },")
    w("} :: { [string]: { any } }")
    w("")
    w("CityPack.Placed = {")
    for p in placements:
        R = p["rot"]
        rx, ry, rz = euler_yxz(R)
        vals = [json.dumps(p["key"])] + [fmt(v) for v in p["pos"]] + [fmt(math.degrees(ry))]
        lean = abs(rx) > 1e-4 or abs(rz) > 1e-4
        sc = p["scale"]
        stretch = np.abs(sc - 1).max() > 5e-4
        if lean or stretch:
            vals += [fmt(math.degrees(rx)), fmt(math.degrees(rz))]
        if stretch:
            vals += [fmt(v, 3) for v in sc]
        w("\t{ " + ", ".join(vals) + " },")
    w("} :: { { any } }")
    w("")
    w("return CityPack")
    open(path, "w").write("\n".join(lines) + "\n")
    # in the repository's own format (scripts/check.sh checks it), when stylua is about
    stylua = shutil.which("stylua") or os.path.expanduser("~/.local/rbx-tools/bin/stylua")
    if os.path.exists(stylua):
        subprocess.run([stylua, path], cwd=ROOT, check=False)


def write_cache(path, keys, tex):
    """The preview cache: per piece its triangles (studs, the key's frame) and their colours."""
    names, starts, counts, tris, cols = [], [], [], [], []
    at = 0
    for name in sorted(keys):
        k = keys[name]
        for pname, ix in k.pieces:
            names.append(pname)
            starts.append(at)
            counts.append(len(ix))
            tris.append(k.tri[ix].astype(np.float32))
            cols.append((np.clip(sample_colours(k.uv[ix], tex), 0, 1) * 255).astype(np.uint8))
            at += len(ix)
    np.savez_compressed(path, names=np.array(names), starts=np.array(starts), counts=np.array(counts),
                        tri=np.concatenate(tris), col=np.concatenate(cols))


IMPORT_STEPS = """# Bringing the city into Studio

These files hold every model in the city pack you sent, each one once:

{files}
- `{palette}`: the colour palette every model takes its colours from

Keep them all in one folder: the importer finds the picture next to the FBX files.

1. Open the game's place in Studio, the one you publish. Importing there gives the game
   permission to use the models.
2. **File > Import** (in older Studio, **File > Import 3D**). Select all {count} `.fbx` files at
   once. They go into the import queue.
3. Click the first file's name to open its settings and set:
   - File General: **Upload to Roblox** on, **Add to Workspace** on, **Anchored** on,
     **Import Only As Model** on, **Import as Package** off. **Creator**: whoever owns the game
     (you, or the group if the game belongs to a group).
   - File Transform: **World Forward** Front, **World Up** Top (the defaults).
   - File Geometry: **Scale Unit** Studs, **Merge Meshes** off, **Invert Negative Faces** off.
   - Leave the settings of the single objects as they come.

   Then right-click that file in the queue and pick **Apply settings to all**.
4. Before importing, look at the queue: no red errors, and each preview shows the models in
   colour. A plain grey preview means the picture wasn't found: put `{palette}` in the same folder
   as the FBX files and add them again.
   One model is bigger than Roblox lets a part be: `water_a_06` in `CityKit_Ground`, the sea north
   of town, 3,500 studs across. If Studio warns about it or shrinks it, that's fine: the game
   doesn't use it and draws that sea itself. If it stops the import, untick that one model.
5. Click **Import**. It uploads about {meshes} meshes and can take a few minutes. A model per file
   appears in the Workspace.
6. One check: in `CityKit_Buildings`, find the bank (two pieces, `bank__1` and `bank__2`, one
   over the other). Look at its front: the sign over the door reads BANK, left to right. If it
   reads backwards, tell us before anything else.
7. Send us the {count} asset ids: in the import queue, right-click each file and pick
   **Copy asset ID**. That's all we need; the game loads the models by those ids.

Rather send one id? Select the {count} imported models in the Explorer, group them (Ctrl+G), name
the group `CityKit`, then right-click it, **Save to Roblox**, and send us the id it shows.

Rather send a file? Right-click that `CityKit` group, **Save to File**, and send us the `.rbxm`.
We keep it out of the game's public repository, like these files.

Don't rename, move or resize the parts inside: the game finds each one by its name, and places
and sizes it itself. You can delete the models from the Workspace once you have the ids.
"""


def write_steps(kit_dir, report):
    files = "\n".join(f"- `{f}.fbx`: {n} models, {m} meshes, {s / 1e6:.1f} MB" for f, n, m, _, _, s in report)
    text = IMPORT_STEPS.format(files=files, palette=PALETTE, count=len(report),
                               meshes=sum(r[2] for r in report))
    open(os.path.join(kit_dir, "IMPORT.md"), "w").write(text)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("src", help="the pack's FBX, or assimp's glTF export of it")
    ap.add_argument("--textures", required=True, help=f"the pack's textures folder (with {PALETTE})")
    ap.add_argument("--out", default=os.path.join(ROOT, "out", "citypack"))
    ap.add_argument("--manifest", default=os.path.join(ROOT, "src", "shared", "Data", "CityPack.luau"))
    ap.add_argument("--no-kit", action="store_true", help="skip the FBX files (manifest and cache only)")
    ap.add_argument("--pack-name", default="LowPoly_City_01Ready.fbx", help="the pack's file, for the manifest")
    a = ap.parse_args()
    from PIL import Image

    palette = os.path.join(a.textures, PALETTE)
    tex = np.asarray(Image.open(palette).convert("RGB")).astype(np.float32) / 255.0
    os.makedirs(a.out, exist_ok=True)
    gl = Gltf(scene_from(a.src, a.out))
    keys, placements, shear = build(gl, tex)
    print(f"keys {len(keys)}, pieces {sum(len(k.pieces) for k in keys.values())}, placements {len(placements)}")
    print(f"triangles in the kit {sum(len(k.tri) for k in keys.values())}")
    if shear:
        print(f"warning: {len(shear)} placements stretched askew (kept as a stretch along the axes): {shear[:6]}")
    write_manifest(a.manifest, keys, placements, a.pack_name)
    write_cache(os.path.join(a.out, "meshes.npz"), keys, tex)
    print("wrote", a.manifest, "and", os.path.join(a.out, "meshes.npz"))
    if a.no_kit:
        return
    report, problems = write_kit(keys, a.out, palette, tex)
    for fname, nkeys, npieces, tris, biggest, size in report:
        print(f"{fname}.fbx: {nkeys} keys, {npieces} meshes, {tris} triangles (biggest {biggest}), "
              f"{size / 1e6:.1f} MB")
    if problems:
        print("PROBLEMS:")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    write_steps(os.path.join(a.out, "kit"), report)
    print("every kit file read back: names, triangle counts, sizes, facing and colours as written")
    print("steps for Studio:", os.path.join(a.out, "kit", "IMPORT.md"))


if __name__ == "__main__":
    main()
