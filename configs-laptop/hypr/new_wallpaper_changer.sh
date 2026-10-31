#!/usr/bin/env bash
set -euo pipefail

# These can be overridden for one run, for example:
# INTERVAL=300 IMAGE_DIR="$HOME/Pictures/wide" ./new_wallpaper_changer.sh
IMAGE_DIR="${IMAGE_DIR:-/home/vlahoff/Pictures/superUltraWide}"
INTERVAL="${INTERVAL:-600}"
DPMS_POLL_INTERVAL="${DPMS_POLL_INTERVAL:-5}"

for required_command in hyprpaper hyprctl shuf find awk flock; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Error: $required_command not found"
    exit 1
  fi
done

if [[ ! "$INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: INTERVAL must be a positive whole number of seconds."
  exit 1
fi

if [[ ! "$DPMS_POLL_INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: DPMS_POLL_INTERVAL must be a positive whole number of seconds."
  exit 1
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  echo "Error: HYPRLAND_INSTANCE_SIGNATURE is not set. Run this inside your Hyprland session (and not via sudo)."
  exit 1
fi

if [[ ! -d "$IMAGE_DIR" ]]; then
  echo "Error: directory '$IMAGE_DIR' does not exist."
  exit 1
fi

# Keep one slideshow per Hyprland session; config reloads reuse the running one.
# Never remove this file: another process could otherwise lock a different inode.
APP_ID="hyprpaper_wallpaper_changer"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK_FILE="$STATE_DIR/${APP_ID}.${UID}.${HYPRLAND_INSTANCE_SIGNATURE}.lock"
exec 9>>"$LOCK_FILE"
if ! flock --nonblock 9; then
  echo "Wallpaper changer is already running for this Hyprland session."
  exit 0
fi
trap 'exit 0' INT TERM

# Querying the IPC is more reliable than pgrep when the same user has more than
# one Hyprland session.
if ! hyprctl hyprpaper listactive >/dev/null 2>&1; then
  # The daemon must not keep the slideshow lock after this script exits.
  hyprpaper 9>&- &
  hyprpaper_ready=0
  for _ in {1..20}; do
    if hyprctl hyprpaper listactive >/dev/null 2>&1; then
      hyprpaper_ready=1
      break
    fi
    sleep 0.25
  done

  if ((hyprpaper_ready == 0)); then
    echo "Error: hyprpaper did not become ready."
    exit 1
  fi
fi

# Return success only when Hyprland reports at least one monitor and every
# reported monitor has DPMS off. Unknown/missing state deliberately fails open
# so an older Hyprland version cannot pause the changer forever.
all_displays_asleep() {
  local monitor_output

  monitor_output="$(hyprctl monitors 2>/dev/null)" || return 1
  awk '
    /^[[:space:]]*dpmsStatus:[[:space:]]*/ {
      found = 1
      state = tolower($2)
      if (state == "1" || state == "true" || state == "yes" || state == "on") {
        awake = 1
      }
    }
    END { exit !(found && !awake) }
  ' <<<"$monitor_output"
}

wait_until_displays_awake() {
  local announced=0

  while all_displays_asleep; do
    if ((announced == 0)); then
      echo "All displays are asleep; pausing wallpaper changes."
      announced=1
    fi
    sleep "$DPMS_POLL_INTERVAL"
  done

  if ((announced)); then
    echo "A display is awake; resuming wallpaper changes."
  fi
}

# Sleep for INTERVAL seconds of awake-display time. Time spent with every
# display in DPMS-off state does not consume the wallpaper interval.
sleep_active_interval() {
  local remaining="$INTERVAL"
  local nap

  while ((remaining > 0)); do
    wait_until_displays_awake

    nap="$DPMS_POLL_INTERVAL"
    if ((nap > remaining)); then
      nap="$remaining"
    fi

    sleep "$nap"

    # Be conservative when DPMS changed during the nap: do not count this
    # chunk if all displays are asleep by the end of it.
    if ! all_displays_asleep; then
      remaining=$((remaining - nap))
    fi
  done
}

# Require an active output before changing images; Hyprpaper handles matching.
refresh_monitors() {
  local monitor_output

  monitor_output="$(hyprctl monitors 2>/dev/null)" || return 1
  mapfile -t MONITORS < <(awk '/^Monitor / { print $2 }' <<<"$monitor_output")
  ((${#MONITORS[@]} > 0))
}

wait_for_monitors() {
  local announced=0

  until refresh_monitors; do
    if ((announced == 0)); then
      echo "No active monitors detected; waiting."
      announced=1
    fi
    sleep "$DPMS_POLL_INTERVAL"
  done
}

while true; do
  mapfile -d '' shuffled < <(find "$IMAGE_DIR" -maxdepth 1 -type f -print0 | shuf -z)

  if ((${#shuffled[@]} == 0)); then
    echo "No images found in $IMAGE_DIR"
    sleep_active_interval
    continue
  fi

  for img in "${shuffled[@]}"; do
    wait_until_displays_awake
    wait_for_monitors

    # New and reconnected outputs inherit this image without waiting for rotation.
    if hyprctl hyprpaper wallpaper ", ${img}, cover" >/dev/null 2>&1; then
      sleep_active_interval
    else
      echo "Warning: could not set '$img' as the fallback wallpaper." >&2
      sleep "$DPMS_POLL_INTERVAL"
    fi
  done
done
