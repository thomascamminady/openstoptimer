# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pillow",
#     "fire",
# ]
# ///
"""Draws the OpenStopTimer app icon: a bold stopwatch glyph on a solid
background. iOS applies corner rounding itself, so this is a plain filled
square with no transparency and no pre-rounded corners.

Run via: uv run Scripts/generate_app_icon.py generate
"""

from __future__ import annotations

import math
from pathlib import Path

import fire
from PIL import Image, ImageDraw

SIZE = 1024
BACKGROUND = (58, 54, 214)  # matches AccentColor
GLYPH = (255, 255, 255)


def _draw_stopwatch(draw: ImageDraw.ImageDraw) -> None:
    center = SIZE / 2
    body_radius = SIZE * 0.34
    ring_width = SIZE * 0.045

    # Crown (top button) and side stem connecting it to the case.
    crown_width = SIZE * 0.16
    crown_height = SIZE * 0.09
    stem_top = center - body_radius - crown_height * 0.55
    draw.rounded_rectangle(
        [center - crown_width / 2, stem_top, center + crown_width / 2, stem_top + crown_height * 1.6],
        radius=crown_width * 0.35,
        fill=GLYPH,
    )

    # Two side buttons (start/stop, reset) at upper-left and upper-right.
    button_length = SIZE * 0.13
    button_width = SIZE * 0.05
    for angle_deg in (-45, 45):
        angle = math.radians(angle_deg)
        inner = body_radius * 0.98
        outer = inner + button_length
        x0 = center + inner * math.sin(angle)
        y0 = center - inner * math.cos(angle)
        x1 = center + outer * math.sin(angle)
        y1 = center - outer * math.cos(angle)
        draw.line([(x0, y0), (x1, y1)], fill=GLYPH, width=int(button_width))
        draw.ellipse(
            [x1 - button_width / 2, y1 - button_width / 2, x1 + button_width / 2, y1 + button_width / 2],
            fill=GLYPH,
        )

    # Watch body ring.
    draw.ellipse(
        [center - body_radius, center - body_radius, center + body_radius, center + body_radius],
        outline=GLYPH,
        width=int(ring_width),
    )

    # Tick marks at each hour position.
    tick_outer = body_radius - ring_width * 0.6
    for hour in range(12):
        angle = math.radians(hour * 30)
        is_major = hour % 3 == 0
        tick_len = body_radius * (0.16 if is_major else 0.08)
        tick_inner = tick_outer - tick_len
        x0 = center + tick_outer * math.sin(angle)
        y0 = center - tick_outer * math.cos(angle)
        x1 = center + tick_inner * math.sin(angle)
        y1 = center - tick_inner * math.cos(angle)
        draw.line([(x0, y0), (x1, y1)], fill=GLYPH, width=int(SIZE * (0.02 if is_major else 0.012)))

    # Hands, pointing to ~2 minutes past 12 — a "timer is running" feel.
    minute_angle = math.radians(35)
    minute_len = body_radius * 0.62
    draw.line(
        [(center, center), (center + minute_len * math.sin(minute_angle), center - minute_len * math.cos(minute_angle))],
        fill=GLYPH,
        width=int(SIZE * 0.035),
    )
    second_angle = math.radians(100)
    second_len = body_radius * 0.78
    draw.line(
        [(center, center), (center + second_len * math.sin(second_angle), center - second_len * math.cos(second_angle))],
        fill=GLYPH,
        width=int(SIZE * 0.018),
    )

    hub_radius = SIZE * 0.025
    draw.ellipse(
        [center - hub_radius, center - hub_radius, center + hub_radius, center + hub_radius],
        fill=GLYPH,
    )


class Commands:
    def generate(self, output_path: str = "OpenStopTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png") -> None:
        """Renders the 1024x1024 app icon PNG."""
        image = Image.new("RGB", (SIZE, SIZE), BACKGROUND)
        draw = ImageDraw.Draw(image)
        _draw_stopwatch(draw)

        destination = Path(output_path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination)
        print(f"wrote {destination}")


if __name__ == "__main__":
    fire.Fire(Commands)
