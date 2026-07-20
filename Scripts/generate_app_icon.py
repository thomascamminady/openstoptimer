# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pillow",
#     "fire",
# ]
# ///
"""Draws the OpenStopTimer app icon: a simple stopwatch glyph on a soft
diagonal gradient. iOS applies corner rounding itself, so this is a plain
filled square with no transparency and no pre-rounded corners.

Run via: uv run Scripts/generate_app_icon.py generate
"""

from __future__ import annotations

import math
from pathlib import Path

import fire
from PIL import Image, ImageDraw, ImageOps

SIZE = 1024
GRADIENT_TOP_LEFT = (47, 58, 209)  # deep indigo
GRADIENT_BOTTOM_RIGHT = (156, 74, 224)  # vivid violet
GLYPH = (255, 255, 255)


def _diagonal_gradient(size: int, top_left: tuple[int, int, int], bottom_right: tuple[int, int, int]) -> Image.Image:
    """A smooth top-left -> bottom-right gradient, built by rotating a
    vertical black-to-white gradient 45 degrees and colorizing it."""
    base = Image.linear_gradient("L").resize((size * 2, size * 2))
    rotated = base.rotate(45, resample=Image.BICUBIC)
    left = (rotated.width - size) // 2
    top = (rotated.height - size) // 2
    cropped = rotated.crop((left, top, left + size, top + size))
    return ImageOps.colorize(cropped, black=top_left, white=bottom_right).convert("RGB")


def _draw_simple_stopwatch(draw: ImageDraw.ImageDraw) -> None:
    """A deliberately minimal glyph — a ring, a crown, one hand — closer to
    a clean icon-font "timer" symbol than a literally detailed watch face."""
    center = SIZE / 2
    radius = SIZE * 0.29
    ring_width = SIZE * 0.065

    # Crown (top button).
    crown_width = SIZE * 0.14
    crown_height = SIZE * 0.085
    stem_top = center - radius - crown_height * 0.5
    draw.rounded_rectangle(
        [center - crown_width / 2, stem_top, center + crown_width / 2, stem_top + crown_height * 1.5],
        radius=crown_width * 0.4,
        fill=GLYPH,
    )

    # Face ring.
    draw.ellipse(
        [center - radius, center - radius, center + radius, center + radius],
        outline=GLYPH,
        width=int(ring_width),
    )

    # One bold hand, pointing to ~2 o'clock — "time is running."
    hand_angle = math.radians(60)
    hand_len = radius * 0.66
    draw.line(
        [(center, center), (center + hand_len * math.sin(hand_angle), center - hand_len * math.cos(hand_angle))],
        fill=GLYPH,
        width=int(SIZE * 0.055),
        joint="curve",
    )

    hub_radius = SIZE * 0.045
    draw.ellipse(
        [center - hub_radius, center - hub_radius, center + hub_radius, center + hub_radius],
        fill=GLYPH,
    )


class Commands:
    def generate(self, output_path: str = "OpenStopTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png") -> None:
        """Renders the 1024x1024 app icon PNG."""
        image = _diagonal_gradient(SIZE, GRADIENT_TOP_LEFT, GRADIENT_BOTTOM_RIGHT)
        draw = ImageDraw.Draw(image)
        _draw_simple_stopwatch(draw)

        destination = Path(output_path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination)
        print(f"wrote {destination}")


if __name__ == "__main__":
    fire.Fire(Commands)
