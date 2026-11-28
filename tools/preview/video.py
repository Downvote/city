"""Turns the frames tools/preview/video.sh dumped into an mp4 with sound.

    python3 tools/preview/video.py <dir> <frames> <fps> <out.mp4> [--bg scene.png] [--workers 3]

Each <dir>/f_<k>.json is drawn by ui_render.py (a few at once). The sounds the interface asked for
(<dir>/f.sounds.json: when, which, at what rate, and when the game stopped it) are fetched from
Roblox's library through scripts/library_sounds.py, played from their start at their volume and rate
from src/shared/Data/Sounds.luau, cut where the game cut them, mixed, and laid under the frames.
The mix is raised as a whole to a comfortable level (the game plays effects softly under music)."""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
import library_sounds  # noqa: E402

RATE = 44100
CACHE = os.path.join(ROOT, "out", "sounds")


def effects():
    """Data/Sounds' lines that carry an id: key -> id, volume, rate, from, len."""
    out = {}
    for line in open(library_sounds.SOUNDS):
        m = re.match(r'\s*(\w+)\s*=\s*\{\s*id\s*=\s*(\d+)(.*)', line)
        if not m:
            continue
        rest = m.group(3)

        def num(name, default):
            mm = re.search(r'\b' + name + r'\s*=\s*([\d.]+)', rest)
            return float(mm.group(1)) if mm else default
        out.setdefault(m.group(1), dict(id=int(m.group(2)), volume=num("volume", 0.5), rate=num("rate", 1.0),
                                        start=num("from", 0.0), length=num("len", 3.0)))
    return out


def samples(asset_id):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{asset_id}.audio")
    if not os.path.exists(path):
        got = library_sounds.fetch(asset_id, CACHE)
        if got != path:
            os.replace(got, path)
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32)


def mix(sound_file, seconds):
    out = np.zeros(int(seconds * RATE) + 1, dtype=np.float32)
    if not os.path.exists(sound_file):
        return out
    table = effects()
    played = json.load(open(sound_file)).get("sounds") or []
    loaded = {}
    for e in played:
        entry = table.get(e["kind"])
        if not entry:
            print("  no sound for", e["kind"])
            continue
        if entry["id"] not in loaded:
            try:
                loaded[entry["id"]] = samples(entry["id"])
            except Exception as err:  # (a sound that won't come is left out, and said)
                print("  couldn't fetch", e["kind"], err)
                loaded[entry["id"]] = None
        src = loaded[entry["id"]]
        if src is None or len(src) == 0:
            continue
        rate = entry["rate"] * (e.get("rate") or 1)
        life = entry["length"] / max(0.1, rate) + 0.2  # (Controllers/Audio destroys it then)
        stop = e.get("stop")
        heard = min(life, (stop - e["t"]) if stop is not None else life, seconds - e["t"])
        if heard <= 0:
            continue
        n = int(heard * RATE)
        pos = entry["start"] * RATE + np.arange(n) * rate
        pos = pos[pos < len(src) - 1]
        piece = np.interp(pos, np.arange(len(src)), src).astype(np.float32) * entry["volume"]
        fade = min(len(piece), int(0.03 * RATE))
        if stop is not None and fade > 0:
            piece[-fade:] *= np.linspace(1, 0, fade, dtype=np.float32)
        at = int(e["t"] * RATE)
        end = min(len(out), at + len(piece))
        out[at:end] += piece[: end - at]
        print(f"  {e['t']:5.2f}s {e['kind']}" + (f" x{rate:.2f}" if rate != 1 else "") +
              (f" (stopped at {stop:.2f}s)" if stop is not None else ""))
    peak = float(np.abs(out).max()) if len(out) else 0
    if peak > 0:
        out *= 0.7 / peak
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("frames", type=int)
    ap.add_argument("fps", type=float)
    ap.add_argument("out")
    ap.add_argument("--bg", default=None)
    ap.add_argument("--workers", type=int, default=3)
    args = ap.parse_args()

    def draw(k):
        cmd = [sys.executable, os.path.join(HERE, "ui_render.py"), f"{args.dir}/f_{k}.json", f"{args.dir}/f_{k}.png"]
        if args.bg:
            cmd += ["--bg", args.bg]
        subprocess.run(cmd, check=True, capture_output=True)
        return k

    done = 0
    with ThreadPoolExecutor(args.workers) as pool:
        for _ in pool.map(draw, range(1, args.frames + 1)):
            done += 1
            if done % 20 == 0 or done == args.frames:
                print(f"  drawn {done} of {args.frames}")

    seconds = args.frames / args.fps
    audio = mix(f"{args.dir}/f.sounds.json", seconds)
    wav = os.path.join(args.dir, "sound.f32")
    audio.astype(np.float32).tofile(wav)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(args.fps), "-i", f"{args.dir}/f_%d.png",
                    "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", wav,
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", "-preset", "medium",
                    "-c:a", "aac", "-b:a", "160k", "-shortest", args.out], check=True)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
