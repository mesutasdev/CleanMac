#!/bin/bash
# Açık/koyu roket ikonlarından AppIcon, AppBrand ve menü çubuğu AppLogo üretir.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DARK_SRC="${1:-$ROOT/scripts/assets/brand-dark.png}"
LIGHT_SRC="${2:-$ROOT/scripts/assets/brand-light.png}"
ASSETS="$ROOT/CleanMac/Assets.xcassets"
VENV="$ROOT/.venv-assets"

if [[ ! -f "$DARK_SRC" ]]; then
  echo "Koyu ikon bulunamadı: $DARK_SRC" >&2
  exit 1
fi

if [[ ! -f "$LIGHT_SRC" ]]; then
  echo "Açık ikon bulunamadı: $LIGHT_SRC" >&2
  exit 1
fi

if [[ ! -d "$VENV" ]]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q pillow
fi

"$VENV/bin/python3" - "$DARK_SRC" "$LIGHT_SRC" "$ASSETS" <<'PY'
import json
import os
import sys
from PIL import Image

DARK_SRC, LIGHT_SRC, ROOT = sys.argv[1], sys.argv[2], sys.argv[3]

def ensure_rgba(img):
    return img.convert("RGBA") if img.mode != "RGBA" else img

def content_bbox(img, threshold=30):
    px = img.load()
    w, h = img.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 16 and (r + g + b) > threshold:
                found = True
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if not found:
        return (0, 0, w, h)
    pad = int(max(max_x - min_x, max_y - min_y) * 0.06)
    return (max(0, min_x - pad), max(0, min_y - pad), min(w, max_x + pad + 1), min(h, max_y + pad + 1))

def square_fit(img, size):
    w, h = img.size
    scale = min(size / w, size / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(resized, ((size - nw) // 2, (size - nh) // 2), resized)
    return canvas

def composite_on_bg(img, size, bg):
    src = square_fit(img, size)
    out = Image.new("RGBA", (size, size), bg)
    out.alpha_composite(src)
    return out

def to_template(img, size):
    src = square_fit(img, size)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sp, op = src.load(), out.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = sp[x, y]
            if a > 16:
                strength = min(255, int(((r + g + b) / 3 / 255) * a))
                op[x, y] = (0, 0, 0, strength)
    return out

dark = ensure_rgba(Image.open(DARK_SRC)).crop(content_bbox(ensure_rgba(Image.open(DARK_SRC))))
light = ensure_rgba(Image.open(LIGHT_SRC)).crop(content_bbox(ensure_rgba(Image.open(LIGHT_SRC))))

dark_bg = (0, 0, 0, 255)
light_bg = (248, 248, 250, 255)

brand_dir = os.path.join(ROOT, "AppBrand.imageset")
composite_on_bg(light, 512, light_bg).save(os.path.join(brand_dir, "app-brand-light.png"))
composite_on_bg(light, 1024, light_bg).save(os.path.join(brand_dir, "app-brand-light@2x.png"))
composite_on_bg(dark, 512, dark_bg).save(os.path.join(brand_dir, "app-brand-dark.png"))
composite_on_bg(dark, 1024, dark_bg).save(os.path.join(brand_dir, "app-brand-dark@2x.png"))

brand_contents = {
    "images": [
        {"filename": "app-brand-light.png", "idiom": "universal", "scale": "1x"},
        {"filename": "app-brand-light@2x.png", "idiom": "universal", "scale": "2x"},
        {
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "filename": "app-brand-dark.png",
            "idiom": "universal",
            "scale": "1x",
        },
        {
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "filename": "app-brand-dark@2x.png",
            "idiom": "universal",
            "scale": "2x",
        },
    ],
    "info": {"author": "xcode", "version": 1},
}
with open(os.path.join(brand_dir, "Contents.json"), "w", encoding="utf-8") as f:
    json.dump(brand_contents, f, indent=2)
    f.write("\n")

icon_dir = os.path.join(ROOT, "AppIcon.appiconset")
icon_sizes = {
    "icon_16.png": 16, "icon_16@2x.png": 32, "icon_32.png": 32, "icon_32@2x.png": 64,
    "icon_128.png": 128, "icon_128@2x.png": 256, "icon_256.png": 256, "icon_256@2x.png": 512,
    "icon_512.png": 512, "icon_512@2x.png": 1024,
}
for name, size in icon_sizes.items():
    composite_on_bg(light, size, light_bg).save(os.path.join(icon_dir, name))

for name, size in icon_sizes.items():
    dark_name = name.replace(".png", "-dark.png")
    composite_on_bg(dark, size, dark_bg).save(os.path.join(icon_dir, dark_name))

icon_images = []
for name, size in icon_sizes.items():
    dim = size // (2 if "@2x" in name else 1)
    dim = int(name.split("_")[1].split("@")[0]) if False else None
    # parse size from filename
    base = name.replace(".png", "").replace("@2x", "")
    px = int(base.split("_")[1])
    scale = "2x" if "@2x" in name else "1x"
    icon_images.append({
        "filename": name,
        "idiom": "mac",
        "scale": scale,
        "size": f"{px}x{px}",
    })
    icon_images.append({
        "appearances": [{"appearance": "luminosity", "value": "dark"}],
        "filename": name.replace(".png", "-dark.png"),
        "idiom": "mac",
        "scale": scale,
        "size": f"{px}x{px}",
    })

with open(os.path.join(icon_dir, "Contents.json"), "w", encoding="utf-8") as f:
    json.dump({"images": icon_images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
    f.write("\n")

logo_dir = os.path.join(ROOT, "AppLogo.imageset")
to_template(dark, 18).save(os.path.join(logo_dir, "app-logo.png"))
to_template(dark, 36).save(os.path.join(logo_dir, "app-logo@2x.png"))

print(f">> Logo asset'leri güncellendi: {ROOT}")
PY
