#!/usr/bin/env python3
"""Center a compact wlogout menu on the focused output, including scaled displays."""

import json
import math
import os
import subprocess
import sys


def monitor_size():
    try:
        result = subprocess.run(
            ["hyprctl", "-j", "monitors"],
            capture_output=True, text=True, check=True, timeout=2,
        )
        monitors = json.loads(result.stdout)
        monitor = next((item for item in monitors if item.get("focused")), monitors[0])
        width, height = float(monitor["width"]), float(monitor["height"])
        scale = float(monitor.get("scale", 1))
        if not all(math.isfinite(value) and value > 0 for value in (width, height, scale)):
            raise ValueError("Invalid monitor geometry")
        if int(monitor.get("transform", 0)) % 2:
            width, height = height, width
        return max(1, round(width / scale)), max(1, round(height / scale))
    except (OSError, subprocess.SubprocessError, ValueError, TypeError, KeyError, IndexError, AttributeError):
        return 1920, 1080


def main():
    width, height = monitor_size()
    panel_width = min(920, max(1, width - 48))
    panel_height = min(240, max(1, height - 48))
    horizontal = width - panel_width
    vertical = height - panel_height
    command = [
        "wlogout", "--buttons-per-row", "5", "--column-spacing", "14",
        "--margin-left", str(horizontal // 2),
        "--margin-right", str(horizontal - horizontal // 2),
        "--margin-top", str(vertical // 2),
        "--margin-bottom", str(vertical - vertical // 2),
        "--no-span",
        *sys.argv[1:],
    ]
    os.execvp(command[0], command)


if __name__ == "__main__":
    main()
