"""The game's light and colour grade for the preview tools, from the same numbers the game uses
(Tuning.Look, written out by tools/preview/look.luau).

Roblox does not publish how it turns Lighting's numbers into a pixel, so this is a model, kept
simple and written down here so it can be argued with:

- Colours are taken to linear light (power 2.2), lit, then tone mapped and taken back.
- The sun lights a face by Brightness x the sun's tint (ColorShift_Top) x the cosine of its angle
  to the sun, and nothing where something stands between it and the sun. It fades and warms as
  it nears the horizon (what the Atmosphere does to it in the game; a guess at how much).
- Shade outdoors is lit by OutdoorAmbient, the same from every side, plus light off the sky
  (EnvironmentDiffuseScale x a pale blue sky, more on what faces up than on what faces down).
- ExposureCompensation scales the light (1 is twice as bright) before the tone map, as Roblox's
  reference says. The tone map is a filmic curve (Narkowicz's fit of ACES): Roblox's own curve is
  not published, but it is filmic and rolls bright colours off toward white the same way.
- The grade is the ColorCorrectionEffect: contrast about mid grey, then brightness added, then
  saturation about the colour's own grey (reaching grey at -1, as Roblox's reference says), then
  the tint multiplied in (the reference calls the tint multiplicative). The order and the
  contrast's pivot are assumed.
- The sun's direction is Roblox's own (the formula Lighting:GetSunDirection follows, from the
  engine's sky code: a circle tilted by the latitude less the earth's tilt), so at latitude 54
  the sun rises in the east (+X), stands about 59 degrees up at noon and always a little to the
  south (+Z), and sets in the west (-X).
"""
import json
import math
import os
import subprocess
import tempfile

import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
EARTH_TILT = 23.5
SKY = np.array([0.25, 0.32, 0.45])  # light off a clear sky at midday, linear, before the scale
DUSK = np.array([1.0, 0.72, 0.5])  # what the air does to the sun's colour at the horizon
MOON = np.array([0.55, 0.62, 1.0])  # moonlight's colour


def load():
    """Tuning.Look as a dict."""
    fd, path = tempfile.mkstemp(suffix=".json")
    os.close(fd)
    try:
        env = dict(os.environ)
        env["PATH"] = os.path.expanduser("~/.local/rbx-tools/bin") + os.pathsep + env.get("PATH", "")
        subprocess.run(["lune", "run", "tools/preview/look.luau", path], cwd=ROOT, env=env, check=True,
                       stdout=subprocess.DEVNULL)
        return json.load(open(path))
    finally:
        os.remove(path)


def to_lin(c):
    return np.power(np.clip(c, 0, None), 2.2)


def to_display(c):
    return np.power(np.clip(c, 0, 1), 1 / 2.2)


def tonemap(x):
    x = np.clip(x, 0, None)
    return np.clip((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0, 1)


def rgb(c):
    return np.array(c, float) / 255


def sun_dir(hour, latitude):
    """A unit vector toward the sun at an hour, as Roblox has it."""
    a = 2 * math.pi * (hour % 24) / 24
    t = math.radians(EARTH_TILT - latitude)
    return np.array([math.sin(a) * math.cos(t), -math.cos(a) * math.cos(t), -math.sin(t)])


def grade_for(look, hour):
    """The grade's entry for an hour: the first whose hours hold it, else the night's."""
    for g in look["Grade"]["Hours"]:
        if g["From"] <= hour <= g["To"]:
            return g
    return look["Grade"]["Night"]


class Light:
    """The game's light at one hour."""

    def __init__(self, look, hour):
        L = look["Light"]
        self.hour = hour
        self.sun = sun_dir(hour, L["Latitude"])
        up = self.sun[1]
        day = float(np.clip(up / 0.15, 0, 1))  # the sun fades out at the horizon
        warm = float(np.clip(1 - (up - 0.05) / 0.45, 0, 1))
        tint = to_lin(rgb(L["SunTint"])) * (1 - warm + warm * DUSK)
        night = L.get("Night") or {}
        if up > -0.05:
            self.dir = self.sun
            self.direct = L["Brightness"] * tint * day
            outdoor = L["OutdoorAmbient"]
        else:  # the moon, opposite the sun, faint and blue
            self.dir = -self.sun
            self.direct = L["Brightness"] * 0.06 * to_lin(MOON) * float(np.clip(self.dir[1] / 0.15, 0, 1))
            outdoor = night.get("OutdoorAmbient", L["OutdoorAmbient"])
        self.ambient = to_lin(rgb(outdoor))
        self.sky = L["SkyDiffuse"] * SKY * float(np.clip(up / 0.3, 0.05, 1))
        self.exposure = 2 ** L["Exposure"]
        self.grade = grade_for(look, hour)
        self.grade_brightness = look["Grade"]["Brightness"]

    def irradiance(self, normal, lit=1.0, toward=None):
        """The light falling on faces with these normals (n x 3, or one), sunlit by `lit` (0 to 1).
        `toward` puts the sun somewhere else (render.py's fixed light), keeping its strength."""
        n = np.atleast_2d(normal)
        d = self.dir if toward is None else toward
        facing = np.clip(n @ d, 0, None)
        lit = np.asarray(lit, float).reshape(-1)
        return (self.ambient[None, :] + self.sky[None, :] * (0.5 + 0.5 * n[:, 1:2])
                + self.direct[None, :] * (facing * lit)[:, None])

    def shade(self, color, irradiance):
        """Display colours (0 to 1) of surfaces painted `color` (display, n x 3) under `irradiance`."""
        return to_display(tonemap(to_lin(color) * irradiance * self.exposure))


def grade(img, light):
    """The colour correction over a whole picture (h x w x 3 or n x 3, display, 0 to 1)."""
    g = light.grade
    c = (img - 0.5) * (1 + g["Contrast"]) + 0.5 + light.grade_brightness
    lum = (c @ np.array([0.299, 0.587, 0.114]))[..., None]
    c = lum + (c - lum) * (1 + g["Saturation"])
    return np.clip(c * rgb(g["Tint"]), 0, 1)
