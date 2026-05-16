#!/usr/bin/env bash
set -euo pipefail

IMAGE_DIR="/home/vlahoff/Pictures/carPics"
INTERVAL=600

command -v hyprpaper >/dev/null 2>&1 || { echo "Error: hyprpaper not found"; exit 1; }
command -v hyprctl   >/dev/null 2>&1 || { echo "Error: hyprctl not found"; exit 1; }
command -v shuf      >/dev/null 2>&1 || { echo "Error: shuf not found (coreutils)"; exit 1; }
command -v find      >/dev/null 2>&1 || { echo "Error: find not found"; exit 1; }

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  echo "Error: HYPRLAND_INSTANCE_SIGNATURE is not set. Run this inside your Hyprland session (and not via sudo)."
  exit 1
fi

if [[ ! -d "$IMAGE_DIR" ]]; then
  echo "Error: directory '$IMAGE_DIR' does not exist."
  exit 1
fi

# Start hyprpaper if it isn't running
if ! pgrep -x hyprpaper >/dev/null 2>&1; then
  hyprpaper &
  sleep 1
fi

# Collect monitor names (non -j approach, avoids jq dependency)
mapfile -t MONITORS < <(hyprctl monitors | awk '/^Monitor /{print $2}')
if ((${#MONITORS[@]} == 0)); then
  echo "Error: couldn't detect monitors from 'hyprctl monitors'"
  exit 1
fi

while true; do
  mapfile -d '' shuffled < <(find "$IMAGE_DIR" -maxdepth 1 -type f -print0 | shuf -z)

  if ((${#shuffled[@]} == 0)); then
    echo "No images found in $IMAGE_DIR"
    sleep "$INTERVAL"
    continue
  fi

  for img in "${shuffled[@]}"; do
    # Optional preload (some setups prefer it)
    hyprctl hyprpaper preload "$img" >/dev/null 2>&1 || true

    for m in "${MONITORS[@]}"; do
      hyprctl hyprpaper wallpaper "${m},${img},cover"
    done

    sleep "$INTERVAL"
  done
done
