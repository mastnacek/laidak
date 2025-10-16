"""
Konverze SVG app ikony na PNG (1024x1024px)
Vyžaduje: pip install cairosvg pillow
"""

import sys
from pathlib import Path

# Fix encoding issues on Windows
sys.stdout.reconfigure(encoding='utf-8') if hasattr(sys.stdout, 'reconfigure') else None

try:
    import cairosvg
    from PIL import Image
    import io
except ImportError:
    print("X Chybi dependencies!")
    print("Nainstaluj: pip install cairosvg pillow")
    sys.exit(1)


def svg_to_png(svg_path: str, png_path: str, size: int = 1024):
    """
    Konvertuje SVG na PNG s danou velikostí

    Args:
        svg_path: Cesta k SVG souboru
        png_path: Cesta k výstupnímu PNG
        size: Velikost výstupu v pixelech (čtverec)
    """
    print(f"[*] Konvertuji {svg_path} -> {png_path}")

    # Konverze SVG -> PNG (do pameti)
    png_data = cairosvg.svg2png(
        url=svg_path,
        output_width=size,
        output_height=size,
    )

    # Ulozit PNG
    with open(png_path, 'wb') as f:
        f.write(png_data)

    print(f"[OK] PNG vytvoreno: {size}x{size}px")


def main():
    # Zjistit cestu ke složce
    script_dir = Path(__file__).parent
    svg_file = script_dir / "app_icon.svg"
    png_file = script_dir / "app_icon.png"

    if not svg_file.exists():
        print(f"[ERROR] SVG soubor nenalezen: {svg_file}")
        sys.exit(1)

    # Konvertovat
    svg_to_png(str(svg_file), str(png_file), size=1024)

    print(f"\n[OK] Ikona pripravena!")
    print(f"[PATH] Umisteni: {png_file}")


if __name__ == "__main__":
    main()
