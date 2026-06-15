"""Generates launcher icons + Play Store art for Smash Breaker.

Outputs:
  SmashBreaker/icons/icon_192.png            (legacy launcher)
  SmashBreaker/icons/adaptive_fg_432.png     (adaptive foreground, transparent)
  SmashBreaker/icons/adaptive_bg_432.png     (adaptive background)
  store_assets/play_icon_512.png             (Play Store icon)
  store_assets/feature_graphic_1024x500.png  (Play feature graphic)
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = os.path.dirname(__file__)
ICONS = os.path.join(BASE, "SmashBreaker", "icons")
STORE = os.path.join(BASE, "store_assets")
os.makedirs(ICONS, exist_ok=True)
os.makedirs(STORE, exist_ok=True)

random.seed(7)

DEEP = (4, 9, 20)
NAVY = (10, 18, 36)
CYAN = (74, 208, 255)
CYAN_BRIGHT = (126, 230, 255)
MAGENTA = (255, 74, 208)
GOLD = (255, 184, 74)
WHITE = (240, 248, 255)

ORBITRON = os.path.join(BASE, "SmashBreaker", "fonts", "Orbitron.ttf")


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    w, h = size
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    return img


def add_stars(img, count, max_r=2):
    d = ImageDraw.Draw(img)
    w, h = img.size
    for _ in range(count):
        x, y = random.randint(0, w), random.randint(0, h)
        r = random.uniform(0.4, max_r)
        b = random.randint(120, 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(b, b, min(255, b + 20)))
    return img


def glow_ellipse(img, box, color, blur, alpha=255):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse(box, fill=color + (alpha,))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    img.paste(layer, (0, 0), layer)
    return img


def rounded(d, box, radius, fill):
    d.rounded_rectangle(box, radius=radius, fill=fill)


def draw_scene(img, scale=1.0, ball_pos=None):
    """Neon paddle + ball + brick rows composition."""
    w, h = img.size
    s = scale
    d = ImageDraw.Draw(img, "RGBA")
    cx = w / 2

    # Brick rows (top)
    brick_w, brick_h, gap = 56 * s, 26 * s, 8 * s
    colors = [CYAN, GOLD, CYAN, MAGENTA, CYAN]
    top = h * 0.16
    for row in range(2):
        ncols = 5 if row == 0 else 4
        row_w = ncols * brick_w + (ncols - 1) * gap
        x0 = cx - row_w / 2
        y0 = top + row * (brick_h + gap)
        for i in range(ncols):
            c = colors[(i + row) % len(colors)]
            bx = x0 + i * (brick_w + gap)
            glow_ellipse(img, [bx - 6 * s, y0 - 6 * s, bx + brick_w + 6 * s, y0 + brick_h + 6 * s],
                         c, 8 * s, 90)
            rounded(d, [bx, y0, bx + brick_w, y0 + brick_h], 5 * s, c + (255,))

    # Ball with glow + short trail
    if ball_pos is None:
        ball_pos = (cx + 60 * s, h * 0.52)
    bx, by = ball_pos
    br = 17 * s
    for i in range(4):   # trail
        t = (i + 1) / 4
        tr = br * (1.0 - t * 0.65)
        tx = bx + 50 * s * t
        ty = by + 36 * s * t
        glow_ellipse(img, [tx - tr, ty - tr, tx + tr, ty + tr], WHITE, 5 * s, int(110 * (1 - t)))
    glow_ellipse(img, [bx - br * 2.2, by - br * 2.2, bx + br * 2.2, by + br * 2.2], CYAN_BRIGHT, 14 * s, 130)
    d.ellipse([bx - br, by - br, bx + br, by + br], fill=WHITE + (255,))

    # Paddle (bottom) — capsule with glow
    pw, ph = 190 * s, 38 * s
    py = h * 0.78
    glow_ellipse(img, [cx - pw / 2 - 10 * s, py - 10 * s, cx + pw / 2 + 10 * s, py + ph + 10 * s],
                 CYAN, 16 * s, 150)
    rounded(d, [cx - pw / 2, py, cx + pw / 2, py + ph], ph / 2, CYAN + (255,))
    rounded(d, [cx - pw / 2 + 8 * s, py + 6 * s, cx + pw / 2 - 8 * s, py + 12 * s], 4 * s,
            CYAN_BRIGHT + (220,))
    return img


# --- 1) Legacy launcher 192 ------------------------------------------------------
icon = vertical_gradient((192, 192), NAVY, DEEP).convert("RGBA")
add_stars(icon, 26, 1.4)
draw_scene(icon, scale=0.62, ball_pos=(124, 96))
icon.save(os.path.join(ICONS, "icon_192.png"))
print("icon_192.png")

# --- 2) Adaptive foreground 432 (transparent, content in centre 66%) -------------
fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
draw_scene(fg, scale=0.95, ball_pos=(275, 220))
fg.save(os.path.join(ICONS, "adaptive_fg_432.png"))
print("adaptive_fg_432.png")

# --- 3) Adaptive background 432 ---------------------------------------------------
bg = vertical_gradient((432, 432), NAVY, DEEP).convert("RGBA")
add_stars(bg, 60, 1.8)
glow_ellipse(bg, [-80, 300, 250, 600], (20, 60, 110), 60, 160)
glow_ellipse(bg, [280, -60, 560, 200], (70, 20, 80), 70, 130)
bg.save(os.path.join(ICONS, "adaptive_bg_432.png"))
print("adaptive_bg_432.png")

# --- 4) Play Store icon 512 (no transparency allowed) ------------------------------
store_icon = vertical_gradient((512, 512), NAVY, DEEP).convert("RGBA")
add_stars(store_icon, 70, 2.0)
glow_ellipse(store_icon, [-100, 360, 320, 760], (20, 60, 110), 80, 150)
draw_scene(store_icon, scale=1.65, ball_pos=(330, 260))
store_icon.convert("RGB").save(os.path.join(STORE, "play_icon_512.png"))
print("play_icon_512.png")

# --- 5) Feature graphic 1024×500 ----------------------------------------------------
fgx = vertical_gradient((1024, 500), (8, 14, 30), DEEP).convert("RGBA")
add_stars(fgx, 130, 1.8)
# Nebula blobs
glow_ellipse(fgx, [-150, 250, 400, 700], (16, 60, 105), 90, 150)
glow_ellipse(fgx, [700, -120, 1200, 260], (75, 18, 80), 90, 140)
# Scene on the right
draw_scene(fgx, scale=1.15, ball_pos=(760, 235))
# Title text on the left
d = ImageDraw.Draw(fgx)
try:
    f_big = ImageFont.truetype(ORBITRON, 86)
    f_small = ImageFont.truetype(ORBITRON, 30)
except OSError:
    f_big = ImageFont.load_default()
    f_small = f_big
# Soft glow behind the title
glow_ellipse(fgx, [30, 150, 560, 330], (20, 80, 130), 70, 120)
d.text((60, 168), "SMASH", font=f_big, fill=CYAN_BRIGHT)
d.text((60, 262), "BREAKER", font=f_big, fill=WHITE)
d.text((63, 372), "CONQUER THE GALAXIES", font=f_small, fill=(150, 175, 210))
fgx.convert("RGB").save(os.path.join(STORE, "feature_graphic_1024x500.png"))
print("feature_graphic_1024x500.png")

print("Done.")
