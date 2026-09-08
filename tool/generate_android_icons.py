"""Generate transparent Boba launcher icons. Requires Pillow."""
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
source = Image.open(ROOT / 'assets/boba/chara1.png').convert('RGBA')
source = source.crop(source.getchannel('A').getbbox())

def icon(size, content_size):
    canvas = Image.new('RGBA', (size, size))
    artwork = ImageOps.contain(source, (content_size, content_size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(artwork, ((size-artwork.width)//2, (size-artwork.height)//2))
    return canvas

for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    folder = RES / f'mipmap-{density}'
    icon(round(48*scale), round(46*scale)).save(folder / 'ic_launcher.png')
    # Adaptive layers are 108dp; the launcher displays the central 72dp.
    # Boba fills 68dp vertically; the face/body stay well within the mask.
    icon(round(108*scale), round(68*scale)).save(folder / 'ic_launcher_foreground.png')

folder = RES / 'mipmap-anydpi-v26'
folder.mkdir(exist_ok=True)
(folder / 'ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/transparent" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
print('Generated transparent legacy and adaptive Android icons.')
