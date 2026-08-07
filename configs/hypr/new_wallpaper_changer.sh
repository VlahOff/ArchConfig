#!/usr/bin/env bash
set -euo pipefail

# These can be overridden for one run, for example:
# INTERVAL=300 IMAGE_DIR="$HOME/Pictures/wide" ./new_wallpaper_changer.sh
IMAGE_DIR="${IMAGE_DIR:-/home/vlahoff/Pictures/carPics}"
INTERVAL="${INTERVAL:-600}"
DPMS_POLL_INTERVAL="${DPMS_POLL_INTERVAL:-5}"

for required_command in hyprpaper hyprctl shuf find awk readlink; do
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

# Kill any older instances of this same script before continuing.
# This uses both a pidfile and a /proc scan, so it works whether the old
# copy was started as ./script.sh, /full/path/script.sh, or bash script.sh.
SCRIPT_PATH="$(readlink -f -- "$0")"
APP_ID="hyprpaper_wallpaper_changer"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="$STATE_DIR/${APP_ID}.${UID}.pid"

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

process_runs_this_script() {
  local pid="$1"
  local proc="/proc/$pid"
  local arg cwd candidate resolved

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ -r "$proc/cmdline" ]] || return 1

  cwd="$(readlink -f -- "$proc/cwd" 2>/dev/null || true)"
  [[ -n "$cwd" ]] || return 1

  while IFS= read -r -d '' arg; do
    [[ -z "$arg" ]] && continue

    if [[ "$arg" == /* ]]; then
      candidate="$arg"
    else
      candidate="$cwd/$arg"
    fi

    resolved="$(readlink -f -- "$candidate" 2>/dev/null || true)"
    [[ "$resolved" == "$SCRIPT_PATH" ]] && return 0
  done <"$proc/cmdline"

  return 1
}

find_same_script_pids() {
  local proc pid

  for proc in /proc/[0-9]*; do
    pid="${proc#/proc/}"

    # Do not kill this script or the shell that launched it.
    [[ "$pid" == "$$" || "$pid" == "$PPID" ]] && continue
    process_runs_this_script "$pid" && echo "$pid"
  done
}

# Kill the PID recorded by the previous run only if it still belongs to this
# script. This avoids killing an unrelated process after PID reuse.
if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ "$old_pid" != "$$" ]] && process_runs_this_script "$old_pid"; then
    kill_old_pids "$old_pid"
  fi
fi

# Also kill matching instances that were started before this pidfile logic existed.
mapfile -t OLD_PIDS < <(find_same_script_pids)
kill_old_pids "${OLD_PIDS[@]}"

printf '%s\n' "$$" >"$PID_FILE"
cleanup_pidfile() {
  if [[ -f "$PID_FILE" ]] && [[ "$(cat "$PID_FILE" 2>/dev/null || true)" == "$$" ]]; then
    rm -f "$PID_FILE"
  fi
}
terminate() {
  exit 0
}
trap cleanup_pidfile EXIT
trap terminate INT TERM

# Querying the IPC is more reliable than pgrep when the same user has more than
# one Hyprland session.
if ! hyprctl hyprpaper listloaded >/dev/null 2>&1; then
  hyprpaper &
  hyprpaper_ready=0
  for _ in {1..20}; do
    if hyprctl hyprpaper listloaded >/dev/null 2>&1; then
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

# Refresh this list before each change so hot-plugged and removed monitors do
# not leave stale names behind.
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

    if ! hyprctl hyprpaper preload "$img" >/dev/null 2>&1; then
      echo "Warning: could not preload '$img'; skipping it." >&2
      sleep "$DPMS_POLL_INTERVAL"
      continue
    fi

    wallpaper_was_set=0
    for m in "${MONITORS[@]}"; do
      if hyprctl hyprpaper wallpaper "${m},${img}" >/dev/null 2>&1; then
        wallpaper_was_set=1
      else
        echo "Warning: could not set '$img' on monitor '$m'." >&2
      fi
    done

    hyprctl hyprpaper unload unused >/dev/null 2>&1 || true

    if ((wallpaper_was_set)); then
      sleep_active_interval
    else
      sleep "$DPMS_POLL_INTERVAL"
    fi
  done
done
