#!/usr/bin/env python3
"""Render assets/icon.png (256x256): the hero swinging on the cable over a swamp.

Draws from app/Sprites.js with a fixed Tokyo Night palette (the icon can't
follow the live theme), writes a PPM, and lets ImageMagick scale and round it:
    python3 tools/make-icon.py

Also writes the desktop icon set under assets/icons/hicolor: the same pixels
as an SVG (one rect per run of a colour, so it stays crisp at any size) and
PNGs from 16 to 512 px scaled from icon.png with nearest-neighbour, so the
pixel art never blurs.
"""
import os
import re
import shutil
import subprocess
import tempfile

here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, "..", "app", "Sprites.js")).read()


def sprite(name):
    m = re.search(name + r': \[\s*((?:"[^"]*",?\s*)+)\]', src)
    return re.findall(r'"([^"]*)"', m.group(1))


PAL = {"h": "5e3d26", "H": "94653f", "s": "e8b896", "b": "4a3020", "e": "101014", "u": "17171c",
       "v": "7aa2f7", "j": "4d6d9a", "J": "34507a", "w": "ececec", "P": "d6dde0", "Q": "e0af68"}
S = 64
img = [["16161e"] * S for _ in range(S)]


def fill(x0, y0, w, h, c):
    for y in range(max(0, y0), min(S, y0 + h)):
        for x in range(max(0, x0), min(S, x0 + w)):
            img[y][x] = c


# sky, canopy, swamp
for y in range(S):
    fill(0, y, S, 1, "1f2a2a" if y < 30 else "182222")
for x in range(-4, S + 4, 9):
    r = 7 + (x * 7) % 4
    for dy in range(-r, r + 1):
        w = int((r * r - dy * dy) ** 0.5)
        fill(x - w, 8 + dy, 2 * w + 1, 1, "4f7a3a" if dy > 2 else "9ece6a")
fill(0, 50, S, 14, "7aa2f7")
fill(4, 52, 22, 1, "b4c9ff")
fill(36, 56, 18, 1, "b4c9ff")
# the cable, from the top to the hero's hands
x0, y0, x1, y1 = 22, 0, 34, 24
for i in range(40):
    fill(round(x0 + (x1 - x0) * i / 39), round(y0 + (y1 - y0) * i / 39), 1, 1, "7aa2f7")
# the hero
for y, row in enumerate(sprite("hang")):
    for x, c in enumerate(row):
        if c in PAL:
            fill(29 + x, 23 + y, 1, 1, PAL[c])

with tempfile.TemporaryDirectory() as tmp:
    ppm = os.path.join(tmp, "icon.ppm")
    with open(ppm, "wb") as f:
        f.write(b"P6 %d %d 255\n" % (S, S))
        f.write(bytes(int(c[i:i + 2], 16) for row in img for c in row for i in (0, 2, 4)))
    out = os.path.join(here, "..", "assets", "icon.png")
    subprocess.run(["magick", ppm, "-filter", "point", "-resize", "240x240",
                    "-bordercolor", "none", "-border", "8",
                    "(", "+clone", "-alpha", "extract", "-fill", "black", "-colorize", "100",
                    "-fill", "white", "-draw", "roundrectangle 8,8 247,247 44,44", ")",
                    "-alpha", "off", "-compose", "CopyOpacity", "-composite", out], check=True)
    print("wrote", os.path.relpath(out))

# The scalable icon: the 64x64 grid drawn into the same 240px square, 8px
# border and 44px corner radius as icon.png.
icons = os.path.join(here, "..", "assets", "icons", "hicolor")
cell = 240 / S
rects = []
for y, row in enumerate(img):
    x = 0
    while x < S:
        end = x
        while end + 1 < S and row[end + 1] == row[x]:
            end += 1
        rects.append('<rect x="%g" y="%g" width="%g" height="%g" fill="#%s"/>'
                     % (8 + x * cell, 8 + y * cell, (end - x + 1) * cell, cell, row[x]))
        x = end + 1
svg = os.path.join(icons, "scalable", "apps", "hyprfall.svg")
os.makedirs(os.path.dirname(svg), exist_ok=True)
with open(svg, "w") as f:
    f.write('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256" shape-rendering="crispEdges">\n'
            '<clipPath id="r"><rect x="8" y="8" width="240" height="240" rx="44"/></clipPath>\n'
            '<g clip-path="url(#r)">\n' + "\n".join(rects) + '\n</g>\n</svg>\n')
print("wrote", os.path.relpath(svg))

for size in (16, 24, 32, 48, 64, 128, 256, 512):
    png = os.path.join(icons, "%dx%d" % (size, size), "apps", "hyprfall.png")
    os.makedirs(os.path.dirname(png), exist_ok=True)
    if size == 256:
        shutil.copyfile(out, png)
    else:
        subprocess.run(["magick", out, "-filter", "point", "-resize", "%dx%d" % (size, size), png], check=True)
    print("wrote", os.path.relpath(png))
