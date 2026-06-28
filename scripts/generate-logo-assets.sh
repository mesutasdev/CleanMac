#!/bin/bash
# Yeni marka logosundan AppIcon, AppBrand ve menü çubuğu AppLogo üretir.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/scripts/assets/brand-source.png}"
ASSETS="$ROOT/CleanMac/Assets.xcassets"
VENV="$ROOT/.venv-assets"

if [[ ! -f "$SRC" ]]; then
  echo "Kaynak logo bulunamadı: $SRC" >&2
  exit 1
fi

if [[ ! -d "$VENV" ]]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q pillow
fi

"$VENV/bin/python3" - "$SRC" "$ASSETS" <<'PY'
import sys
from PIL import Image
import os

SRC, ROOT = sys.argv[1], sys.argv[2]

def ensure_rgba(img):
    return img.convert("RGBA") if img.mode != "RGBA" else img

def content_bbox(img, threshold=45):
    px = img.load()
    w, h = img.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            lum = (r + g + b) / 3
            if a > 16 and lum > threshold:
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

def white_on_black_to_brand(img, size):
    src = square_fit(img, size)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    sp, op = src.load(), out.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = sp[x, y]
            lum = (r + g + b) / 3
            if a > 16 and lum > 40:
                strength = min(255, int((lum / 255) * a))
                op[x, y] = (strength, strength, strength, 255)
    return out

def white_on_black_to_template(img, size):
    src = square_fit(img, size)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sp, op = src.load(), out.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = sp[x, y]
            lum = (r + g + b) / 3
            if a > 16 and lum > 45:
                strength = min(255, int((lum / 255) * a))
                op[x, y] = (0, 0, 0, strength)
    return out

source = ensure_rgba(Image.open(SRC)).crop(content_bbox(ensure_rgba(Image.open(SRC))))

brand_dir = os.path.join(ROOT, "AppBrand.imageset")
white_on_black_to_brand(source, 512).save(os.path.join(brand_dir, "app-brand.png"))
white_on_black_to_brand(source, 1024).save(os.path.join(brand_dir, "app-brand@2x.png"))

icon_dir = os.path.join(ROOT, "AppIcon.appiconset")
for name, size in {
    "icon_16.png": 16, "icon_16@2x.png": 32, "icon_32.png": 32, "icon_32@2x.png": 64,
    "icon_128.png": 128, "icon_128@2x.png": 256, "icon_256.png": 256, "icon_256@2x.png": 512,
    "icon_512.png": 512, "icon_512@2x.png": 1024,
}.items():
    white_on_black_to_brand(source, size).save(os.path.join(icon_dir, name))

logo_dir = os.path.join(ROOT, "AppLogo.imageset")
white_on_black_to_template(source, 18).save(os.path.join(logo_dir, "app-logo.png"))
white_on_black_to_template(source, 36).save(os.path.join(logo_dir, "app-logo@2x.png"))

print(f">> Logo asset'leri güncellendi: {ROOT}")
PY
