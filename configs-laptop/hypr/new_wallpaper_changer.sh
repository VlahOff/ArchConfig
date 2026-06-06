#!/usr/bin/env bash
set -euo pipefail

#IMAGE_DIR="/home/vlahoff/Pictures/wide"
#IMAGE_DIR="/home/vlahoff/Pictures/space"
IMAGE_DIR="/home/vlahoff/Pictures/carPics"
INTERVAL=600

command -v hyprpaper >/dev/null 2>&1 || {
  echo "Error: hyprpaper not found"
  exit 1
}
command -v hyprctl >/dev/null 2>&1 || {
  echo "Error: hyprctl not found"
  exit 1
}
command -v shuf >/dev/null 2>&1 || {
  echo "Error: shuf not found (coreutils)"
  exit 1
}
command -v find >/dev/null 2>&1 || {
  echo "Error: find not found"
  exit 1
}

# Kill any older instances of this same script before continuing.
# This uses both a pidfile and a /proc scan, so it works whether the old
# copy was started as ./script.sh, /full/path/script.sh, or bash script.sh.
SCRIPT_PATH="$(readlink -f -- "$0")"
SCRIPT_NAME="$(basename -- "$SCRIPT_PATH")"
APP_ID="hyprpaper_wallpaper_changer"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="$STATE_DIR/${APP_ID}.pid"

kill_old_pids() {
  local pids=("$@")
  ((${#pids[@]} == 0)) && return 0

  echo "Killing older instance(s): ${pids[*]}"
  kill "${pids[@]}" 2>/dev/null || true

  for _ in {1..20}; do
    local still_running=()
    for pid in "${pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        still_running+=("$pid")
      fi
    done

    ((${#still_running[@]} == 0)) && return 0
    pids=("${still_running[@]}")
    sleep 0.1
  done

  kill -9 "${pids[@]}" 2>/dev/null || true
}

find_same_script_pids() {
  local proc pid arg arg_base cwd candidate resolved resolved_base found

  for proc in /proc/[0-9]*; do
    pid="${proc#/proc/}"

    # Do not kill this script or the shell that launched it.
    [[ "$pid" == "$$" || "$pid" == "$PPID" ]] && continue
    [[ -r "$proc/cmdline" ]] || continue

    found=0
    while IFS= read -r -d '' arg; do
      [[ -z "$arg" ]] && continue

      if [[ "$arg" == "$SCRIPT_PATH" ]]; then
        found=1
        break
      fi

      arg_base="$(basename -- "$arg")"
      if [[ "$arg" == */"$SCRIPT_NAME" || "$arg" == "$SCRIPT_NAME" || "$arg_base" == new_wallpaper_changer*.sh ]]; then
        cwd="$(readlink -f -- "$proc/cwd" 2>/dev/null || true)"
        [[ -z "$cwd" ]] && continue

        if [[ "$arg" == /* ]]; then
          candidate="$arg"
        else
          candidate="$cwd/$arg"
        fi

        resolved="$(readlink -f -- "$candidate" 2>/dev/null || true)"
        resolved_base="$(basename -- "$resolved" 2>/dev/null || true)"
        if [[ "$resolved" == "$SCRIPT_PATH" || "$resolved_base" == new_wallpaper_changer*.sh ]]; then
          found=1
          break
        fi
      fi
    done <"$proc/cmdline"

    ((found)) && echo "$pid"
  done
}

# Kill the PID recorded by the previous run, if it is still alive.
if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ "$old_pid" =~ ^[0-9]+$ && "$old_pid" != "$$" ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill_old_pids "$old_pid"
  fi
fi

# Also kill matching instances that were started before this pidfile logic existed.
mapfile -t OLD_PIDS < <(find_same_script_pids | sort -n -u)
kill_old_pids "${OLD_PIDS[@]}"

printf '%s\n' "$$" >"$PID_FILE"
cleanup_pidfile() {
  if [[ -f "$PID_FILE" ]] && [[ "$(cat "$PID_FILE" 2>/dev/null || true)" == "$$" ]]; then
    rm -f "$PID_FILE"
  fi
}
trap cleanup_pidfile EXIT INT TERM

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
    hyprctl hyprpaper preload "$img" >/dev/null 2>&1 || true

    for m in "${MONITORS[@]}"; do
      hyprctl hyprpaper wallpaper "${m},${img}"
    done

    hyprctl hyprpaper unload unused >/dev/null 2>&1 || true

    sleep "$INTERVAL"
  done
done
