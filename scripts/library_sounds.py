#!/usr/bin/env python3
"""Finds sounds and music in the Roblox Creator Store for the game, and checks the ones it uses.

    python3 scripts/library_sounds.py search "<keywords>" [--by roblox|pse|apm|distrokid|any] [--limit 30]
                                         [--most <seconds>] [--measure] [--sheet out.png]
    python3 scripts/library_sounds.py info <audio id> [<audio id> ...] [--sheet out.png] [--syllables]
    python3 scripts/library_sounds.py check

The toolbox's audio category is 3 (decals, which scripts/library_textures.py looks through, are 13).
Only audio any game may play is used (the user: "use roblox library for these, dont make your
own"): Roblox's own uploads and the libraries Roblox licensed for every game (Pro Sound Effects'
sound effects, APM's and DistroKid's music), all public. --by keeps a search to one of them
(roblox by default; `any` searches everyone's uploads, which are only usable when public).

--measure (and info) fetch each sound through Roblox's asset delivery, which only hands over audio
a game may play, and measure it with ffmpeg: how long it really sounds (from its first to its last
moment above a quiet floor), how loud its loudest tenth of a second is (dB, a full scale sine is
-3), its strongest pitch, and how noisy it is (0 a pure tone, 1 hiss). --sheet draws each one's
waveform and spectrogram on a contact sheet, to look at.

check reads every id in src/shared/Data/Sounds.luau and fails if one has gone: the Creator Store no
longer lists it, it isn't public, it isn't from one of the libraries above, asset delivery won't
hand it over, or it decodes to silence.
"""
import argparse
import gzip
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request

UA = {"User-Agent": "sound-finder"}
AUDIO = 3
# The libraries any game may use: Roblox's own account and the partners it licensed for everyone.
LIBRARIES = {
    "roblox": 1,
    "pse": 7462895450,  # ProSoundEffects
    "apm": 7462718749,  # APMOfficial
    "distrokid": 7135127272,  # DistrokidOfficial
}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOUNDS = os.path.join(ROOT, "src/shared/Data/Sounds.luau")
RATE = 22050


def get(url, raw=False):
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=40) as r:
                data = r.read()
                return data if raw else json.loads(data)
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(2 + attempt * 3)
                continue
            raise
    raise RuntimeError("rate limited: " + url)


def search(keywords, by, limit):
    q = urllib.parse.quote(keywords)
    ids, cursor = [], ""
    while len(ids) < limit:
        url = f"https://apis.roblox.com/toolbox-service/v1/marketplace/{AUDIO}?keyword={q}&limit=30"
        if by in LIBRARIES:
            url += f"&creatorTargetId={LIBRARIES[by]}"
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
    ids = [int(i) for i in ids]
    for i in range(0, len(ids), 30):
        chunk = ",".join(str(x) for x in ids[i:i + 30])
        for d in get(f"https://apis.roblox.com/toolbox-service/v1/items/details?assetIds={chunk}").get("data", []):
            out[d["asset"]["id"]] = d
    return out


def fetch(asset_id, folder):
    """Downloads the audio through asset delivery (only audio a game may play comes back) into
    `folder`; returns the file's path, or raises."""
    loc = get(f"https://assetdelivery.roblox.com/v2/asset/?id={asset_id}")
    places = loc.get("locations") or []
    if not places:
        raise RuntimeError(f"asset delivery has no file for {asset_id}: {loc.get('errors')}")
    data = get(places[0]["location"], raw=True)
    if data[:2] == b"\x1f\x8b":
        data = gzip.decompress(data)
    path = os.path.join(folder, f"{asset_id}.audio")
    with open(path, "wb") as f:
        f.write(data)
    return path


def decode(path):
    """The sound as mono samples at RATE (numpy), through ffmpeg."""
    import numpy as np
    out = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(out, dtype=np.float32)


def measure(samples):
    """How it sounds: { secs (heard), start (s before it starts), loud (dB of the loudest 0.1 s),
    peak (dB), pitch (Hz, the strongest), noise (0 tone to 1 hiss), length (s, the whole file) }."""
    import numpy as np
    a = samples.astype(np.float64)
    n = len(a)
    if n == 0:
        return {"length": 0, "secs": 0, "start": 0, "loud": -120, "peak": -120, "pitch": 0, "noise": 1}
    win = max(1, RATE // 100)  # 10 ms frames
    frames = n // win
    rms = np.sqrt(np.mean(a[:frames * win].reshape(frames, win) ** 2, axis=1) + 1e-12) if frames else np.array([1e-6])
    db = 20 * np.log10(rms)
    top = db.max()
    heard = np.where(db > max(top - 40, -70))[0]
    start, end = (heard[0], heard[-1] + 1) if len(heard) else (0, 0)
    # the loudest tenth of a second
    k = 10
    loud = max(10 * np.log10(np.mean(rms[i:i + k] ** 2)) for i in range(max(1, frames - k + 1))) if frames else -120
    peak = 20 * np.log10(np.abs(a).max() + 1e-12)
    # pitch and noise from the loudest 0.1 s
    best = int(np.argmax([np.mean(rms[i:i + k] ** 2) for i in range(max(1, frames - k + 1))])) if frames else 0
    seg = a[best * win: best * win + 4096]
    if len(seg) < 512:
        seg = np.pad(seg, (0, 512 - len(seg)))
    spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg)))) + 1e-12
    freqs = np.fft.rfftfreq(len(seg), 1 / RATE)
    band = (freqs > 60) & (freqs < 8000)
    pitch = float(freqs[band][np.argmax(spec[band])])
    noise = float(np.exp(np.mean(np.log(spec[band]))) / np.mean(spec[band]))
    return {"length": round(n / RATE, 2), "secs": round((end - start) * win / RATE, 2), "start": round(start * win / RATE, 3),
            "loud": round(float(loud), 1), "peak": round(float(peak), 1), "pitch": round(pitch), "noise": round(noise, 2)}


def syllables(samples):
    """The separate sounds in a recording (a babble's syllables): [(start s, length s, pitch Hz)],
    each from where the sound rises out of a dip to where it drops back, 0.04 to 0.3 s long."""
    import numpy as np
    a = samples.astype(np.float64)
    win = RATE // 100
    frames = len(a) // win
    if frames < 3:
        return []
    rms = np.sqrt(np.mean(a[:frames * win].reshape(frames, win) ** 2, axis=1) + 1e-12)
    db = 20 * np.log10(rms)
    floor = db.max() - 22
    out, start, quiet = [], None, 0
    for i in range(frames + 1):
        loud = i < frames and db[i] > floor
        if loud and start is None:
            start, quiet = i, 0
        elif start is not None and not loud:
            quiet += 1
            if quiet >= 2 or i == frames:
                end = i - quiet + 1
                length = (end - start) * win / RATE
                if 0.04 <= length <= 0.3:
                    seg = a[start * win: end * win]
                    spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), n=8192))
                    freqs = np.fft.rfftfreq(8192, 1 / RATE)
                    band = (freqs > 80) & (freqs < 4000)
                    out.append((round(start * win / RATE, 3), round(length, 3), round(float(freqs[band][np.argmax(spec[band])]))))
                start = None
        elif loud:
            quiet = 0
    return out


def sheet(rows, path):
    """Each sound's waveform (top) and spectrogram (under it), with its id and name."""
    import numpy as np
    from PIL import Image, ImageDraw
    cw, wave_h, spec_h, cols = 300, 60, 90, 4
    cell_h = wave_h + spec_h + 30
    n = len(rows)
    img = Image.new("RGB", (cols * cw, ((n + cols - 1) // cols) * cell_h), (24, 24, 30))
    d = ImageDraw.Draw(img)
    for k, r in enumerate(rows):
        x0, y0 = (k % cols) * cw, (k // cols) * cell_h
        m = r["m"]
        # from where it starts to where it ends (at most 4 s), so a short one fills its cell
        first = int(m["start"] * RATE)
        a = r["samples"][first: first + int(min(4, max(0.25, m["secs"] + 0.05)) * RATE)]
        if len(a):
            step = max(1, len(a) // (cw - 8))
            for i in range(cw - 8):
                chunk = a[i * step:(i + 1) * step]
                if len(chunk) == 0:
                    break
                h = float(np.abs(chunk).max()) * (wave_h / 2 - 2)
                d.line([(x0 + 4 + i, y0 + wave_h / 2 - h), (x0 + 4 + i, y0 + wave_h / 2 + h)], fill=(120, 200, 160))
            nfft = 512
            hops = max(1, (len(a) - nfft) // (cw - 8))
            a = np.pad(a, (0, nfft))
            cols_ = []
            for i in range(cw - 8):
                seg = a[i * hops: i * hops + nfft]
                if len(seg) < nfft:
                    break
                cols_.append(np.abs(np.fft.rfft(seg * np.hanning(nfft)))[: nfft // 4])
            if cols_:
                s = 20 * np.log10(np.array(cols_).T + 1e-9)
                s = np.clip((s - s.max() + 60) / 60, 0, 1)[::-1]
                im = Image.fromarray((s * 255).astype("uint8")).resize((len(cols_), spec_h))
                img.paste(Image.merge("RGB", (im, im.point(lambda v: v * 0.8), im.point(lambda v: v * 0.5))),
                          (x0 + 4, y0 + wave_h))
        d.text((x0 + 4, y0 + wave_h + spec_h + 2), f'{r["id"]} {m["secs"]}s {m["loud"]}dB {m["pitch"]}Hz n{m["noise"]}',
               fill=(230, 230, 230))
        d.text((x0 + 4, y0 + wave_h + spec_h + 15), r["name"][:44], fill=(160, 160, 170))
    img.save(path)
    print("sheet", path)


def show(ids, info, do_measure, sheet_path=None, most=None, sylls=False):
    rows = []
    folder = tempfile.mkdtemp(prefix="sounds-") if do_measure else None
    try:
        for i in ids:
            d = info.get(int(i))
            if not d:
                print(f"{i:>16}  not in the Creator Store")
                continue
            a = d["asset"]
            ad = a.get("audioDetails") or {}
            if most is not None and (a.get("duration") or 0) > most:
                continue
            line = (f'{a["id"]:>16} {a.get("duration", 0):>4}s {ad.get("audioType", "?")[:5]:5} '
                    f'{d["creator"]["name"][:16]:16} {a["name"][:58]}')
            if ad.get("artist") and ad.get("audioType") == "Music":
                line += f' | {ad.get("artist")[:24]}'
            if do_measure:
                try:
                    samples = decode(fetch(a["id"], folder))
                    m = measure(samples)
                    line += f'  heard {m["secs"]}s from {m["start"]}s, loud {m["loud"]} dB, peak {m["peak"]}, {m["pitch"]} Hz, noise {m["noise"]}'
                    rows.append({"id": a["id"], "name": a["name"], "samples": samples, "m": m})
                    if sylls:
                        line += "\n" + "\n".join(f"        syllable at {st}s for {ln}s, {hz} Hz" for st, ln, hz in syllables(samples))
                except Exception as e:  # noqa: BLE001
                    line += f"  (couldn't fetch: {e})"
            print(line)
        if sheet_path and rows:
            sheet(rows, sheet_path)
    finally:
        if folder:
            shutil.rmtree(folder, ignore_errors=True)


def cmd_search(args):
    ids = search(args.keywords, args.by, args.limit)
    show(ids, details(ids), args.measure or bool(args.sheet), args.sheet, args.most)


def cmd_info(args):
    ids = [int(i) for i in args.ids]
    show(ids, details(ids), True, args.sheet, sylls=args.syllables)


def read_sounds(path=SOUNDS):
    """key -> asset id, from the lines of Data/Sounds that look like `key = { id = 123, ... }`."""
    out = {}
    for line in open(path):
        m = re.match(r'\s*\[?"?(\w+)"?\]?\s*=\s*\{\s*id\s*=\s*(\d+)', line)
        if m:
            out[m.group(1)] = int(m.group(2))
    return out


def cmd_check(args):
    want = read_sounds()
    if not want:
        print("no sounds found in Data/Sounds")
        sys.exit(1)
    info = details(list(set(want.values())))
    allowed = set(LIBRARIES.values())
    have_ffmpeg = shutil.which("ffmpeg") is not None
    folder = tempfile.mkdtemp(prefix="sounds-")
    gone = []
    try:
        for key, i in sorted(want.items()):
            d = info.get(i)
            if not d:
                gone.append(f"{key}: {i}: not in the Creator Store")
                continue
            a = d["asset"]
            if a.get("typeId") != AUDIO:
                gone.append(f"{key}: {i}: not audio")
                continue
            if a.get("visibilityStatus", 0) != 0:
                gone.append(f"{key}: {i}: not public")
                continue
            if d["creator"]["id"] not in allowed:
                gone.append(f"{key}: {i}: by {d['creator']['name']}, not one of the libraries every game may use")
                continue
            try:
                path = fetch(i, folder)
                if have_ffmpeg:
                    m = measure(decode(path))
                    if m["loud"] < -60:
                        gone.append(f"{key}: {i}: silent")
            except Exception as e:  # noqa: BLE001
                gone.append(f"{key}: {i}: won't play: {e}")
    finally:
        shutil.rmtree(folder, ignore_errors=True)
    for line in gone:
        print(line)
    print(f"{len(want)} sounds in Data/Sounds, {len(gone)} gone or not usable")
    if gone:
        sys.exit(1)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("search")
    s.add_argument("keywords")
    s.add_argument("--by", default="roblox", choices=list(LIBRARIES) + ["any"])
    s.add_argument("--limit", type=int, default=30)
    s.add_argument("--most", type=float, help="only sounds this many seconds long or less")
    s.add_argument("--measure", action="store_true")
    s.add_argument("--sheet")
    i = sub.add_parser("info")
    i.add_argument("ids", nargs="+")
    i.add_argument("--sheet")
    i.add_argument("--syllables", action="store_true", help="list the separate sounds in each (a babble's syllables)")
    sub.add_parser("check")
    args = ap.parse_args()
    {"search": cmd_search, "info": cmd_info, "check": cmd_check}[args.cmd](args)


if __name__ == "__main__":
    main()
