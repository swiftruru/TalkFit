from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).parent


def normalized(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGB", size, "white")
    copy = image.convert("RGB")
    copy.thumbnail(size, Image.Resampling.LANCZOS)
    origin = ((size[0] - copy.width) // 2, (size[1] - copy.height) // 2)
    canvas.paste(copy, origin)
    return canvas


def crop_near_white(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    white = Image.new("RGB", rgb.size, "white")
    difference = ImageChops.difference(rgb, white).convert("L")
    mask = difference.point(lambda value: 255 if value > 12 else 0)
    bounds = mask.getbbox()
    return rgb.crop(bounds) if bounds else rgb


def compose(name: str) -> None:
    source = Image.open(ROOT / f"{name}-target.png")
    implementation = Image.open(ROOT / f"{name}-implementation.png")
    viewport = implementation.size
    left = normalized(crop_near_white(source), viewport)
    right = normalized(implementation, viewport)
    gutter = 24
    comparison = Image.new(
        "RGB",
        (viewport[0] * 2 + gutter, viewport[1]),
        (232, 228, 216),
    )
    comparison.paste(left, (0, 0))
    comparison.paste(right, (viewport[0] + gutter, 0))
    comparison.save(ROOT / f"{name}-qa-comparison.png", optimize=True)


compose("short-practice")
compose("script-practice")
