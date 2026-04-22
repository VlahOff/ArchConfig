#!/usr/bin/env bash
#
# wallpaper-rotator.sh
# A simple script to rotate wallpapers via hyprpaper
# -----------------------------------------------------------------------------

# ─── USER CONFIG ───────────────────────────────────────────────────────────────
# Directory containing your wallpapers:
# IMAGE_DIR="$HOME/Pictures/carPics"
IMAGE_DIR="/home/vlahoff/Pictures/carPics"

# Time between changes, in seconds:
#INTERVAL=1800 # 30 min
INTERVAL=600 # 10 min
# ────────────────────────────────────────────────────────────────────────────────

# ─── PREREQUISITES CHECK ───────────────────────────────────────────────────────
command -v hyprpaper >/dev/null 2>&1 || { echo "Error: 'hyprpaper' not found in PATH."; exit 1; }
command -v hyprctl   >/dev/null 2>&1 || { echo "Error: 'hyprctl' not found in PATH.";   exit 1; }
command -v shuf      >/dev/null 2>&1 || { echo "Error: 'shuf' not found (coreutils).";   exit 1; }

if [[ ! -d "$IMAGE_DIR" ]]; then
  echo "Error: directory '$IMAGE_DIR' does not exist."
  exit 1
fi
# ────────────────────────────────────────────────────────────────────────────────

# ─── KILL EXISTING INSTANCES ───────────────────────────────────────────────────
# 1) Kill other running copies of this script:
ME="$(readlink -f "$0")"
for pid in $(pgrep -f "$ME"); do
  [[ "$pid" != $$ ]] && kill "$pid"
done

# 2) Kill any running hyprpaper daemon:
pkill hyprpaper
# ────────────────────────────────────────────────────────────────────────────────

# ─── (RE)START HYPRPAPER DAEMON ─────────────────────────────────────────────────
hyprpaper &    # spawn hyprpaper in background
sleep 1        # give it a moment to initialize its IPC socket
# ────────────────────────────────────────────────────────────────────────────────

# ─── MAIN LOOP: ROTATE WALLPAPERS (SHUFFLED, NO REPEATS) ───────────────────────
while true; do
  # Shuffle all files in the directory (null-delimited so spaces are safe)
  mapfile -d '' shuffled < <(find "$IMAGE_DIR" -maxdepth 1 -type f -print0 | shuf -z)

  if ((${#shuffled[@]} == 0)); then
    echo "No images found in $IMAGE_DIR"
    sleep "$INTERVAL"
    continue
  fi

  for img in "${shuffled[@]}"; do
    hyprctl hyprpaper wallpaper ",$img,cover"
    sleep "$INTERVAL"
  done
done
# ────────────────────────────────────────────────────────────────────────────────
