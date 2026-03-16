#!/usr/bin/env python3
"""
Generate a high-quality macOS app icon for StockTracker.
Inspired by Apple News app icon style - clean, modern, with gradient.
"""

import os
from PIL import Image, ImageDraw, ImageFilter
import math

# Icon sizes needed for macOS
SIZES = [
    (16, 16),
    (16, 16),    # @2x
    (32, 32),
    (32, 32),    # @2x
    (128, 128),
    (128, 128),  # @2x
    (256, 256),
    (256, 256),  # @2x
    (512, 512),
    (512, 512),  # @2x
]

def create_icon(size):
    """Create a single icon at the given size."""

    # Create base image with rounded corners
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Icon margins (for rounded corners effect)
    margin = int(size * 0.05)

    # Gradient background - Apple News-inspired blue-green gradient
    # Create gradient colors
    top_color = (59, 130, 246)    # Blue-500
    bottom_color = (16, 185, 129)  # Emerald-500

    # Draw gradient background with rounded rectangle
    corner_radius = int(size * 0.22)

    # Create a rounded rectangle mask
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=corner_radius,
        fill=255
    )

    # Draw gradient
    for y in range(size):
        ratio = y / size
        r = int(top_color[0] * (1 - ratio) + bottom_color[0] * ratio)
        g = int(top_color[1] * (1 - ratio) + bottom_color[1] * ratio)
        b = int(top_color[2] * (1 - ratio) + bottom_color[2] * ratio)
        draw.line([(0, y), (size - 1, y)], fill=(r, g, b, 255))

    # Apply rounded corner mask
    img.putalpha(mask)

    # Draw stock chart elements
    chart_color = (255, 255, 255, 230)
    positive_color = (34, 197, 94)  # Green-500
    grid_color = (255, 255, 255, 80)

    # Chart area (centered, taking up ~70% of icon)
    chart_left = int(size * 0.15)
    chart_right = int(size * 0.85)
    chart_top = int(size * 0.15)
    chart_bottom = int(size * 0.85)
    chart_width = chart_right - chart_left
    chart_height = chart_bottom - chart_top

    # Draw subtle grid lines
    grid_draw = ImageDraw.Draw(img)
    for i in range(1, 4):
        y = chart_top + (chart_height * i // 4)
        grid_draw.line([(chart_left, y), (chart_right, y)], fill=grid_color, width=max(1, size // 64))

    # Draw stock line chart (upward trending)
    # Generate points for a nice upward trending chart
    num_points = 20
    points = []
    import random
    random.seed(42)  # Consistent chart pattern

    # Create upward trending data with some variation
    for i in range(num_points):
        x = chart_left + (chart_width * i // (num_points - 1))
        base_y = chart_bottom - (chart_height * (0.3 + 0.5 * i / (num_points - 1)))
        # Add some noise but keep overall upward trend
        noise = random.uniform(-chart_height * 0.1, chart_height * 0.1)
        y = max(chart_top + chart_height * 0.1, min(chart_bottom - chart_height * 0.1, base_y + noise))
        points.append((x, int(y)))

    # Draw the filled area under the line
    fill_points = [(chart_left, chart_bottom)] + points + [(chart_right, chart_bottom)]
    fill_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    fill_draw = ImageDraw.Draw(fill_img)
    fill_draw.polygon(fill_points, fill=(255, 255, 255, 60))

    # Apply mask to fill
    fill_img.putalpha(mask)
    img = Image.alpha_composite(img, fill_img)

    # Redraw the main line with glow effect
    draw = ImageDraw.Draw(img)

    # Draw thick line
    line_width = max(2, size // 20)
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=chart_color, width=line_width)

    # Draw glow/highlight on the line (slightly offset)
    glow_draw = ImageDraw.Draw(img)
    for i in range(len(points) - 1):
        glow_draw.line([points[i], points[i + 1]], fill=(255, 255, 255, 100), width=line_width + 2)

    # Draw dots at data points
    dot_radius = max(2, size // 32)
    for x, y in points[::3]:  # Every 3rd point
        draw.ellipse(
            [x - dot_radius, y - dot_radius, x + dot_radius, y + dot_radius],
            fill=chart_color
        )

    # Add a subtle inner shadow/highlight for depth
    highlight = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.rounded_rectangle(
        [(size//4, 0), (size - 1, size//2)],
        radius=corner_radius,
        fill=(255, 255, 255, 30)
    )
    img = Image.alpha_composite(img, highlight)

    # Add subtle shine effect at top
    shine = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine)
    # Elliptical shine at top
    shine_draw.ellipse(
        [size * 0.1, -size * 0.2, size * 0.9, size * 0.4],
        fill=(255, 255, 255, 25)
    )
    img = Image.alpha_composite(img, shine)

    return img


def main():
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(script_dir, "Sources/StockTracker/Assets.xcassets/AppIcon.appiconset")

    # Create icons
    icon_files = [
        "icon_16x16.png",
        "icon_16x16@2x.png",
        "icon_32x32.png",
        "icon_32x32@2x.png",
        "icon_128x128.png",
        "icon_128x128@2x.png",
        "icon_256x256.png",
        "icon_256x256@2x.png",
        "icon_512x512.png",
        "icon_512x512@2x.png",
    ]

    print("Generating high-quality app icons...")

    for i, (size, _) in enumerate(SIZES):
        icon = create_icon(size)
        icon_path = os.path.join(assets_dir, icon_files[i])
        icon.save(icon_path, "PNG")
        print(f"  Created {icon_files[i]} ({size}x{size})")

    print("\nApp icon generation complete!")
    print(f"Icons saved to: {assets_dir}")


if __name__ == "__main__":
    main()
