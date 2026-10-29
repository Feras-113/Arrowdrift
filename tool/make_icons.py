#!/usr/bin/env python3
"""Renders the Arrowdrift logo to launcher icons + Play Store graphics.

Geometry mirrors lib/ui/widgets/logo.dart (unit square coordinates).
Outputs:
  tool/android_res/...   -> copied into android/app/src/main/res by tool/setup.sh
  store/play_icon_512.png, store/feature_graphic_1024x500.png
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 4  # supersampling

MINT = (0x2E, 0xF2, 0xC9)
CORAL = (0xFF, 0x6B, 0x8A)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size, c1, c2):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            px[x, y] = lerp(c1, c2, (x + y) / (2 * size - 2))
    return img


def thick_polyline(d, pts, width, fill):
    r = width / 2
    for a, b in zip(pts, pts[1:]):
        d.line([a, b], fill=fill, width=int(width))
    for p in pts:
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=fill)


def snake(layer, s, pts_unit, tip_y, color, ox, oy, k):
    """Draw one snake (head pointing up) in a transparent RGBA layer."""
    def P(x, y):
        return (ox + x * s * k, oy + y * s * k)
    pts = [P(*p) for p in pts_unit]
    w = s * k * 0.10
    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = s * k * 0.012
    thick_polyline(sd, [(x, y + off) for x, y in pts], w, (0, 0, 0, 76))
    layer.alpha_composite(shadow)
    d = ImageDraw.Draw(layer)
    thick_polyline(d, pts, w, color + (255,))
    hl = tuple(int(c + (255 - c) * 0.55) for c in color) + (255,)
    thick_polyline(d, pts, w * 0.3, hl)
    ex, ey = pts[-1]
    tip = (ex, oy + tip_y * s * k)
    d.polygon([tip, (ex + s * k * 0.12, ey), (ex - s * k * 0.12, ey)], fill=color + (255,))


def draw_logo(size, badge=True, k=1.0):
    """k scales the arrows about the centre (for adaptive-icon safe zone)."""
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    if badge:
        g = gradient(s, (0x0B, 0x10, 0x30), (0x26, 0x37, 0x9A)).convert("RGBA")
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=255)
        img.paste(g, (0, 0), mask)
        ImageDraw.Draw(img).rounded_rectangle(
            [s * 0.012, s * 0.012, s - s * 0.012, s - s * 0.012],
            radius=int(s * 0.21), outline=(255, 255, 255, 31), width=max(1, int(s * 0.012)))
    off = s * (1 - k) / 2
    snake(img, s, [(0.42, 0.80), (0.78, 0.80), (0.78, 0.60)], 0.44, CORAL, off, off, k)
    snake(img, s, [(0.24, 0.76), (0.24, 0.46), (0.58, 0.46), (0.58, 0.34)], 0.18, MINT, off, off, k)
    return img.resize((size, size), Image.LANCZOS)


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


def main():
    res = os.path.join(ROOT, "tool", "android_res")
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for d, px in legacy.items():
        save(draw_logo(px, True), f"{res}/mipmap-{d}/ic_launcher.png")
        # round launcher: same badge clipped to a circle
        sq = draw_logo(px, True)
        m = Image.new("L", (px * SS, px * SS), 0)
        ImageDraw.Draw(m).ellipse([0, 0, px * SS - 1, px * SS - 1], fill=255)
        m = m.resize((px, px), Image.LANCZOS)
        rnd = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        bg = gradient(px, (0x0B, 0x10, 0x30), (0x26, 0x37, 0x9A)).convert("RGBA")
        rnd.paste(bg, (0, 0), m)
        fg = draw_logo(px, False, 0.86)
        rnd.alpha_composite(fg)
        out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        out.paste(rnd, (0, 0), m)
        save(out, f"{res}/mipmap-{d}/ic_launcher_round.png")
    for d, px in adaptive.items():
        # keep arrows inside the 66/108 safe zone
        save(draw_logo(px, False, 0.62), f"{res}/mipmap-{d}/ic_launcher_foreground.png")

    os.makedirs(f"{res}/mipmap-anydpi-v26", exist_ok=True)
    for name in ("ic_launcher", "ic_launcher_round"):
        with open(f"{res}/mipmap-anydpi-v26/{name}.xml", "w") as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                    '    <background android:drawable="@color/ic_launcher_background"/>\n'
                    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                    '</adaptive-icon>\n')
    os.makedirs(f"{res}/values", exist_ok=True)
    with open(f"{res}/values/ic_launcher_background.xml", "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                '    <color name="ic_launcher_background">#12195A</color>\n</resources>\n')

    # Play Store assets
    store = os.path.join(ROOT, "store")
    save(draw_logo(512, True), f"{store}/play_icon_512.png")

    W, H = 1024, 500
    bg = Image.new("RGB", (W, H))
    px = bg.load()
    c1, c2 = (0x0B, 0x10, 0x30), (0x26, 0x37, 0x9A)
    for y in range(H):
        for x in range(W):
            px[x, y] = lerp(c1, c2, (x / W * 0.7 + y / H * 0.3))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([60, 40, 460, 440], fill=MINT + (70,))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    bg = Image.alpha_composite(bg.convert("RGBA"), glow)
    logo = draw_logo(340, True)
    bg.alpha_composite(logo, (90, 80))
    d = ImageDraw.Draw(bg)

    def font(sz):
        for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                  "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"):
            if os.path.exists(p):
                return ImageFont.truetype(p, sz)
        return ImageFont.load_default()
    d.text((470, 178), "ARROWDRIFT", font=font(62), fill=(244, 247, 255, 255))
    d.text((474, 262), "Slide every arrow out.", font=font(34), fill=MINT + (255,))
    d.text((474, 318), "5,100 levels  •  Free", font=font(28), fill=(154, 167, 217, 255))
    save(bg.convert("RGB"), f"{store}/feature_graphic_1024x500.png")
    print("icons + store graphics written")


if __name__ == "__main__":
    main()
