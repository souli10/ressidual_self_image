"""Generate placeholder PNG assets for Residual Self Image.
Run once. Replace these with real art later — same filenames, same directories."""

from PIL import Image, ImageDraw, ImageFont
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(BASE, "assets")

GREEN = (0, 180, 0, 255)
DARK_GREEN = (0, 80, 0, 255)
BLACK = (10, 20, 10, 255)
RED = (180, 0, 0, 255)
AGENT_COLOR = (30, 30, 30, 255)
GRAY = (80, 100, 80, 255)
WHITE_SMOKE = (200, 210, 200, 180)


def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)


def save(img, rel_path):
    full = os.path.join(ASSETS, rel_path)
    ensure_dir(full)
    img.save(full)
    print(f"  [OK] {rel_path}")


def make_iso_tile(w, h, fill, outline=None):
    """Create a diamond-shaped isometric tile."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    diamond = [(w // 2, 0), (w, h // 2), (w // 2, h), (0, h // 2)]
    d.polygon(diamond, fill=fill, outline=outline or DARK_GREEN)
    return img


def make_rect(w, h, fill, outline=None, label=None):
    """Simple labeled rectangle sprite."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 1, w - 2, h - 2], fill=fill, outline=outline or GREEN)
    if label:
        # Simple text placement
        try:
            font = ImageFont.truetype("arial.ttf", 10)
        except:
            font = ImageFont.load_default()
        bbox = d.textbbox((0, 0), label, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text(((w - tw) // 2, (h - th) // 2), label, fill=GREEN, font=font)
    return img


def make_character_sheet(color, label, frames=4, directions=4):
    """Create a simple sprite sheet: 4 dirs x N frames, 32x48 per frame."""
    fw, fh = 32, 48
    img = Image.new("RGBA", (fw * frames, fh * directions), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    dir_labels = ["SE", "NE", "SW", "NW"]
    for dir_i in range(directions):
        for frame_i in range(frames):
            x = frame_i * fw
            y = dir_i * fh
            # Body
            d.rectangle([x + 8, y + 12, x + 24, y + 40], fill=color, outline=GREEN)
            # Head
            d.ellipse([x + 10, y + 2, x + 22, y + 14], fill=color, outline=GREEN)
            # Direction indicator arrow
            cx, cy = x + 16, y + 26
            if dir_i == 0:  # SE
                d.line([cx, cy, cx + 6, cy + 6], fill=GREEN, width=2)
            elif dir_i == 1:  # NE
                d.line([cx, cy, cx + 6, cy - 6], fill=GREEN, width=2)
            elif dir_i == 2:  # SW
                d.line([cx, cy, cx - 6, cy + 6], fill=GREEN, width=2)
            elif dir_i == 3:  # NW
                d.line([cx, cy, cx - 6, cy - 6], fill=GREEN, width=2)
            # Frame offset for walk animation
            if frame_i % 2 == 1:
                d.rectangle([x + 10, y + 40, x + 14, y + 47], fill=color)
                d.rectangle([x + 18, y + 38, x + 22, y + 45], fill=color)
    return img


print("=== Generating Placeholder Assets ===\n")

# --- TILESETS ---
print("[Tilesets]")
save(make_iso_tile(64, 32, (20, 30, 20, 255)), "tilesets/floor_office.png")
save(make_iso_tile(64, 32, (30, 40, 30, 255), DARK_GREEN), "tilesets/floor_street.png")
save(make_iso_tile(64, 32, (15, 25, 20, 255)), "tilesets/floor_subway.png")

# Wall tiles (taller for iso walls)
wall = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
wd = ImageDraw.Draw(wall)
# Wall face
wd.polygon([(32, 0), (64, 8), (64, 40), (32, 48), (0, 40), (0, 8)],
           fill=(40, 55, 40, 255), outline=DARK_GREEN)
save(wall, "tilesets/wall_office.png")
save(wall, "tilesets/wall_subway.png")

# --- CHARACTERS ---
print("\n[Characters]")
save(make_character_sheet(BLACK, "NEO"), "characters/neo_spritesheet.png")
save(make_character_sheet(AGENT_COLOR, "AGENT", frames=2), "characters/agent_spritesheet.png")
save(make_character_sheet(GRAY, "NPC", frames=2, directions=4), "characters/npc_spritesheet.png")

# --- OBJECTS ---
print("\n[Objects]")
# Door
door = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
dd = ImageDraw.Draw(door)
dd.rectangle([16, 0, 48, 44], fill=(50, 70, 50, 255), outline=GREEN)
dd.rectangle([36, 20, 40, 24], fill=RED)  # red lock indicator
save(door, "objects/door_locked.png")

# Door unlocked variant
door_open = door.copy()
dd2 = ImageDraw.Draw(door_open)
dd2.rectangle([36, 20, 40, 24], fill=GREEN)  # green = unlocked
save(door_open, "objects/door_unlocked.png")

# Debris
debris = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
dbd = ImageDraw.Draw(debris)
for i, (x, y, w, h) in enumerate([(5, 8, 18, 12), (25, 4, 14, 16), (42, 10, 16, 14)]):
    dbd.rectangle([x, y, x + w, y + h], fill=(60, 70, 55, 255), outline=DARK_GREEN)
save(debris, "objects/debris.png")

# Printer
printer = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
pd = ImageDraw.Draw(printer)
pd.rectangle([4, 16, 44, 44], fill=(50, 60, 50, 255), outline=GREEN)
pd.rectangle([8, 8, 40, 16], fill=(40, 50, 40, 255), outline=DARK_GREEN)
pd.rectangle([34, 20, 40, 24], fill=GREEN)  # status LED
save(printer, "objects/printer.png")

# Security camera
camera = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
cd = ImageDraw.Draw(camera)
cd.rectangle([8, 4, 24, 12], fill=GRAY, outline=GREEN)  # mount
cd.polygon([(8, 12), (24, 12), (28, 28), (4, 28)], fill=GRAY, outline=GREEN)  # cone
cd.ellipse([13, 6, 19, 10], fill=RED)  # light
save(camera, "objects/security_camera.png")

# Desk with monitor
desk = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
dkd = ImageDraw.Draw(desk)
dkd.rectangle([4, 20, 60, 44], fill=(45, 55, 45, 255), outline=DARK_GREEN)  # desk
dkd.rectangle([20, 4, 44, 22], fill=BLACK, outline=GREEN)  # monitor
dkd.rectangle([22, 6, 42, 20], fill=(5, 15, 5, 255))  # screen
save(desk, "objects/desk.png")

# Phone (hardline)
phone = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
phd = ImageDraw.Draw(phone)
phd.rectangle([8, 4, 24, 44], fill=GRAY, outline=GREEN)
phd.rectangle([6, 6, 12, 14], fill=(60, 80, 60, 255), outline=GREEN)  # handset top
phd.rectangle([6, 34, 12, 42], fill=(60, 80, 60, 255), outline=GREEN)  # handset bottom
save(phone, "objects/phone_hardline.png")

# Steam valve
valve = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
vd = ImageDraw.Draw(valve)
vd.rectangle([4, 12, 28, 28], fill=GRAY, outline=GREEN)
vd.ellipse([10, 4, 22, 16], fill=(70, 90, 70, 255), outline=GREEN)  # wheel
save(valve, "objects/steam_valve.png")

# Filing cabinet
cabinet = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
cbd = ImageDraw.Draw(cabinet)
cbd.rectangle([2, 2, 30, 46], fill=(45, 60, 45, 255), outline=DARK_GREEN)
for y in [10, 22, 34]:
    cbd.rectangle([6, y, 26, y + 8], fill=(35, 50, 35, 255), outline=DARK_GREEN)
    cbd.rectangle([14, y + 2, 18, y + 6], fill=GREEN)  # handle
save(cabinet, "objects/filing_cabinet.png")

# --- VFX ---
print("\n[VFX]")
# Steam particle
steam = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
sd = ImageDraw.Draw(steam)
sd.ellipse([2, 2, 14, 14], fill=WHITE_SMOKE)
save(steam, "vfx/steam_particle.png")

# Glitch overlay (tiling scanlines)
glitch = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
gd = ImageDraw.Draw(glitch)
for y in range(0, 128, 2):
    gd.line([0, y, 127, y], fill=(0, 20, 0, 30))
save(glitch, "vfx/glitch_overlay.png")

# --- UI ---
print("\n[UI]")
# Cursor
cursor = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
cud = ImageDraw.Draw(cursor)
cud.line([8, 0, 8, 15], fill=GREEN, width=1)
cud.line([0, 8, 15, 8], fill=GREEN, width=1)
save(cursor, "ui/cursor_crosshair.png")

# Terminal frame
tf = Image.new("RGBA", (400, 300), (0, 0, 0, 0))
tfd = ImageDraw.Draw(tf)
tfd.rectangle([0, 0, 399, 299], fill=(5, 12, 5, 240), outline=GREEN, width=2)
tfd.rectangle([0, 0, 399, 20], fill=(0, 40, 0, 255))
tfd.rectangle([4, 4, 12, 16], fill=RED)
tfd.rectangle([16, 4, 24, 16], fill=(180, 180, 0, 255))
tfd.rectangle([28, 4, 36, 16], fill=GREEN)
save(tf, "ui/terminal_frame.png")

print("\n=== Done! All placeholders generated. ===")
print(f"\nAssets directory: {ASSETS}")
print("\nWhen you have real assets, just replace the PNGs with the same filenames.")
