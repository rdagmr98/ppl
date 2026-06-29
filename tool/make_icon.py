"""Genera l'icona dell'app Quiz PPL(A): aereo top-down su anello di prua.
Tema scuro (#0E1116 -> navy) + blu, con arco verde (richiamo 'risposta corretta').
Render a 2x con anti-alias, poi downscale. Produce:
  assets/icon/icon.png            (1024, full-bleed, per web/legacy/maskable)
  assets/icon/icon_foreground.png (1024, trasparente, per adaptive Android)
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
os.makedirs(OUT, exist_ok=True)
S = 2048               # supersampling
C = S // 2
WHITE = (244, 249, 255, 255)
BLUE = (30, 136, 229, 255)
GREEN = (38, 196, 120, 255)

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))

def vgradient(top, bot):
    img = Image.new('RGB', (S, S))
    px = img.load()
    for y in range(S):
        t = y / (S - 1)
        col = lerp(top, bot, t)
        for x in range(S):
            px[x, y] = col
    return img

# aereo top-down (naso in alto). Offsemi-destra (dx>=0) attorno al centro; poi specchiati.
# coordinate in frazioni di S/2 (~ raggio); scalate da R.
R = S * 0.46
half = [
    (0.00, -0.64),  # naso
    (0.05, -0.55),
    (0.075, -0.30),
    (0.085, -0.16),  # radice ala anteriore
    (0.62, 0.06),    # tip ala (freccia)
    (0.62, 0.13),
    (0.10, 0.02),    # radice ala posteriore
    (0.065, 0.40),   # fusoliera poppa
    (0.26, 0.52),    # tip stabilizzatore
    (0.26, 0.575),
    (0.055, 0.49),
    (0.045, 0.64),   # coda
    (0.0, 0.64),
]
def plane_polygon(cx, cy, scale):
    pts = []
    for dx, dy in half:
        pts.append((cx + dx * R * scale, cy + dy * R * scale))
    for dx, dy in reversed(half[1:-1]):
        pts.append((cx - dx * R * scale, cy + dy * R * scale))
    return pts

def draw_scene(draw, cx, cy, scale, with_ring=True):
    if with_ring:
        rr = R * 0.92 * scale
        # anello di prua blu
        draw.ellipse([cx-rr, cy-rr, cx+rr, cy+rr], outline=BLUE, width=int(20*scale))
        # tacche N/E/S/W
        for ang in range(0, 360, 90):
            a = math.radians(ang - 90)
            x1 = cx + math.cos(a) * rr; y1 = cy + math.sin(a) * rr
            x2 = cx + math.cos(a) * (rr - 60*scale); y2 = cy + math.sin(a) * (rr - 60*scale)
            draw.line([x1, y1, x2, y2], fill=BLUE, width=int(20*scale))
        # arco verde "rotta corretta" (in alto-destra)
        bb = [cx-rr, cy-rr, cx+rr, cy+rr]
        draw.arc(bb, -70, -10, fill=GREEN, width=int(26*scale))
    # ombra aereo
    sh = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.polygon(plane_polygon(cx+8*scale, cy+14*scale, scale), fill=(0, 0, 0, 160))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    base.paste(sh, (0, 0), sh)
    draw2 = ImageDraw.Draw(base)
    draw2.polygon(plane_polygon(cx, cy, scale), fill=WHITE)
    # cupola/abitacolo: piccolo cerchio blu
    cp = R * 0.075 * scale
    draw2.ellipse([cx-cp, cy-R*0.22*scale-cp, cx+cp, cy-R*0.22*scale+cp], fill=BLUE)

# ---- icona full-bleed (web/legacy/maskable) ----
base = vgradient((14, 17, 22), (16, 42, 67)).convert('RGBA')
d = ImageDraw.Draw(base)
draw_scene(d, C, C, 1.0, with_ring=True)
icon = base.resize((1024, 1024), Image.LANCZOS)
icon.convert('RGB').save(os.path.join(OUT, 'icon.png'))

# ---- foreground trasparente (adaptive Android): contenuto entro la safe zone ----
base = Image.new('RGBA', (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(base)
draw_scene(d, C, C, 0.66, with_ring=True)
fg = base.resize((1024, 1024), Image.LANCZOS)
fg.save(os.path.join(OUT, 'icon_foreground.png'))

print('OK ->', os.path.abspath(OUT))
