#!/usr/bin/env python3
"""Generate every Play Store / App Store image from the raw captures.

Inputs
    assets/images/beres_logo.png             master app icon
    store_assets/screenshots/raw/*.png       device captures (see raw/README.md)

Outputs
    store_assets/app_icon_1024.png
    store_assets/play_store_icon_512.png
    store_assets/feature_graphic_1024x500.png
    store_assets/screenshots/android-phone/promo_*.png   1080x1920
    store_assets/screenshots/ios-6.9-inch/promo_*.png    1290x2796

Run from the project root:  python3 scripts/generate_store_assets.py
"""

import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICON = ROOT / "assets" / "images" / "beres_logo.png"
FONT_DIR = ROOT / "assets" / "font"
STORE = ROOT / "store_assets"
RAW = STORE / "screenshots" / "raw"

FONT_BOLD = FONT_DIR / "Inter_18pt-ExtraBold.ttf"
FONT_MED = FONT_DIR / "Inter_18pt-Medium.ttf"

NAVY = (0x0A, 0x0E, 0x21)
PURPLE_DEEP = (0x3B, 0x14, 0x7D)
PURPLE = (0x7C, 0x3A, 0xED)
LILAC = (0xC4, 0xB5, 0xFD)
WHITE = (0xFF, 0xFF, 0xFF)

SLIDES = [
    ("home", "Semua kebutuhan harian", "dalam satu aplikasi"),
    ("finance", "Lihat ke mana", "uangmu pergi"),
    ("budget", "Pasang limit per kategori", "sebelum jebol"),
    ("calendar", "Agenda, libur nasional", "dan tanggal gajian"),
    ("alarm", "Alarm yang tetap bunyi", "walau app ditutup"),
    ("password", "Password aman,", "tersimpan di perangkat"),
    ("converter", "Konversi satuan", "dan mata uang"),
]

TARGETS = {
    "android-phone": (1080, 1920),
    "ios-6.9-inch": (1290, 2796),
}


def font(path, size):
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def backdrop(size):
    """Calm vertical gradient, navy at the edges and purple through the middle."""
    w, h = size
    ramp = Image.new("RGB", (1, 256))
    d = ImageDraw.Draw(ramp)
    stops = [(0.0, NAVY), (0.42, PURPLE_DEEP), (0.78, PURPLE), (1.0, PURPLE_DEEP)]
    for y in range(256):
        t = y / 255
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                local = (t - t0) / (t1 - t0)
                d.point(
                    (0, y),
                    fill=tuple(
                        int(c0[j] + (c1[j] - c0[j]) * local) for j in range(3)
                    ),
                )
                break
    return ramp.resize((w, h), Image.BICUBIC).convert("RGBA")


def diagonal_backdrop(size):
    """Navy in the top-left, deepening to purple across the diagonal."""
    w, h = size
    span = max(w, h) * 2
    ramp = Image.new("RGB", (1, 256))
    d = ImageDraw.Draw(ramp)
    stops = [(0.0, NAVY), (0.55, PURPLE_DEEP), (1.0, PURPLE)]
    for y in range(256):
        t = y / 255
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                local = (t - t0) / (t1 - t0)
                d.point(
                    (0, y),
                    fill=tuple(int(c0[j] + (c1[j] - c0[j]) * local) for j in range(3)),
                )
                break
    grad = ramp.resize((span, span), Image.BICUBIC).rotate(
        -35, resample=Image.BICUBIC
    )
    left = (span - w) // 2
    top = (span - h) // 2
    return grad.crop((left, top, left + w, top + h)).convert("RGBA")


def glow_backdrop(size, center, radius):
    """Diagonal field with a soft purple glow behind the mark."""
    w, h = size
    canvas = diagonal_backdrop((w, h))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    steps = 60
    for i in range(steps, 0, -1):
        t = i / steps
        r = radius * t
        alpha = int(200 * (1 - t) ** 1.5)
        d.ellipse(
            [center[0] - r, center[1] - r, center[0] + r, center[1] + r],
            fill=PURPLE + (alpha,),
        )
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(radius * 0.12)))
    return canvas


def scatter_cards(img, specs):
    """Faint stacked-card motifs echoing the app icon."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x, y, w, alpha in specs:
        h = int(w * 0.75)
        step = int(w * 0.13)
        for depth, mult in ((2, 0.40), (1, 0.65), (0, 1.0)):
            cx = x - step * depth * 0.55
            cy = y - step * depth
            d.rounded_rectangle(
                [cx, cy, cx + w, cy + h],
                radius=int(w * 0.14),
                fill=(255, 255, 255, int(alpha * mult)),
            )
    img.alpha_composite(layer)


def strip_navbar(shot):
    """Drop the light system navigation bar from the bottom of a capture."""
    px = shot.load()
    limit = int(shot.height * 0.08)
    cut = 0
    for offset in range(1, limit):
        y = shot.height - offset
        row = sum(sum(px[x, y]) for x in range(0, shot.width, 40))
        samples = len(range(0, shot.width, 40)) * 3
        if row / samples < 150:
            break
        cut = offset
    return shot.crop((0, 0, shot.width, shot.height - cut)) if cut else shot


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.width - 1, img.height - 1], radius=radius, fill=255
    )
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def drop_shadow(canvas, box, radius, blur, alpha, offset):
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [
            box[0] + offset[0],
            box[1] + offset[1],
            box[2] + offset[0],
            box[3] + offset[1],
        ],
        radius=radius,
        fill=(0, 0, 0, alpha),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))


def centered(draw, y, text, fnt, fill, width):
    box = draw.textbbox((0, 0), text, font=fnt)
    x = (width - (box[2] - box[0])) // 2 - box[0]
    draw.text((x, y), text, font=fnt, fill=fill)
    return box[3] - box[1]


def make_icons():
    master = Image.open(ICON).convert("RGBA")
    flat = Image.new("RGB", master.size, NAVY)
    flat.paste(master, (0, 0), master)
    flat.resize((1024, 1024), Image.LANCZOS).save(STORE / "app_icon_1024.png")
    flat.resize((512, 512), Image.LANCZOS).save(STORE / "play_store_icon_512.png")
    print("  app_icon_1024.png, play_store_icon_512.png")


def make_feature_graphic():
    w, h = 1024, 500
    canvas = glow_backdrop((w, h), (222, 250), 470)
    scatter_cards(
        canvas,
        [
            (870, 86, 118, 26),
            (930, 348, 92, 20),
        ],
    )

    size = 250
    icon = rounded(
        Image.open(ICON).convert("RGB").resize((size, size), Image.LANCZOS),
        int(size * 0.235),
    )
    ix, iy = 96, (h - size) // 2
    drop_shadow(
        canvas, (ix, iy, ix + size, iy + size), int(size * 0.235), 20, 150, (0, 16)
    )
    canvas.alpha_composite(icon, (ix, iy))

    d = ImageDraw.Draw(canvas)
    tx = ix + size + 66
    d.text((tx, 168), "BERES", font=font(FONT_BOLD, 104), fill=WHITE)
    d.text(
        (tx + 4, 296),
        "Urusan harian, semua beres.",
        font=font(FONT_MED, 34),
        fill=LILAC,
    )

    canvas.convert("RGB").save(STORE / "feature_graphic_1024x500.png")
    print("  feature_graphic_1024x500.png  (RGB, no alpha)")


def make_promo(raw_name, line1, line2, target, out_path):
    w, h = target
    unit = w / 1080
    canvas = backdrop((w, h))
    scatter_cards(
        canvas,
        [
            (int(-40 * unit), int(h * 0.63), int(210 * unit), 26),
            (int(w - 120 * unit), int(h * 0.30), int(230 * unit), 22),
            (int(w - 60 * unit), int(h * 0.86), int(170 * unit), 18),
        ],
    )

    d = ImageDraw.Draw(canvas)
    f1 = font(FONT_BOLD, int(58 * unit))
    f2 = font(FONT_MED, int(48 * unit))
    y = int(104 * unit)
    y += centered(d, y, line1, f1, WHITE, w) + int(38 * unit)
    centered(d, y, line2, f2, LILAC, w)

    shot = strip_navbar(Image.open(RAW / f"{raw_name}.png").convert("RGB"))
    top = int(310 * unit)
    avail_h = h - top - int(96 * unit)
    avail_w = int(w * 0.78)
    scale = min(avail_w / shot.width, avail_h / shot.height)
    shot = shot.resize(
        (int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS
    )
    radius = int(48 * unit)
    sx = (w - shot.width) // 2
    sy = top

    drop_shadow(
        canvas,
        (sx, sy, sx + shot.width, sy + shot.height),
        radius,
        int(36 * unit),
        175,
        (0, int(24 * unit)),
    )
    canvas.alpha_composite(rounded(shot, radius), (sx, sy))

    border = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle(
        [sx, sy, sx + shot.width - 1, sy + shot.height - 1],
        radius=radius,
        outline=(255, 255, 255, 60),
        width=max(2, int(3 * unit)),
    )
    canvas.alpha_composite(border)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path)


def main():
    missing = [n for n, _, _ in SLIDES if not (RAW / f"{n}.png").exists()]
    if missing:
        print(f"Missing raw captures: {', '.join(missing)}", file=sys.stderr)
        print(f"Put them in {RAW.relative_to(ROOT)}/ first.", file=sys.stderr)
        return 1

    STORE.mkdir(parents=True, exist_ok=True)
    print("Icons:")
    make_icons()
    print("Feature graphic:")
    make_feature_graphic()

    print("Screenshots:")
    for folder, target in TARGETS.items():
        for i, (raw_name, line1, line2) in enumerate(SLIDES, start=1):
            out = STORE / "screenshots" / folder / f"promo_{i}_{raw_name}.png"
            make_promo(raw_name, line1, line2, target, out)
        print(f"  {folder}: {len(SLIDES)} slides at {target[0]}x{target[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
