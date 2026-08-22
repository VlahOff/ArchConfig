#!/usr/bin/env bash

shopt -s nullglob

batteries=(/sys/class/power_supply/ps-controller-battery-*)

# Controller disconnected
if (( ${#batteries[@]} == 0 )); then
    exit 0
fi

battery="${batteries[0]}"

capacity=$(<"$battery/capacity")
status=$(<"$battery/status")

if (( capacity <= 15 )); then
    class="critical"
elif (( capacity <= 30 )); then
    class="warning"
elif [[ "$status" == "Charging" ]]; then
    class="charging"
else
    class="normal"
fi

printf '{"text":"󰊴  %s%%","tooltip":"DualSense: %s%% — %s","class":"%s","percentage":%s}\n' \
    "$capacity" "$capacity" "$status" "$class" "$capacity"