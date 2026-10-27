#!/usr/bin/env bash

set -euo pipefail

service="org.freedesktop.UPower"
device="/org/freedesktop/UPower/devices/battery_BAT0"
interface="org.freedesktop.UPower.Device"

notify() {
    printf '%s\n' "$2" >&2
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Battery" -u "$1" "Battery charging" "$2" || true
    fi
}

fail() {
    notify critical "$1"
    exit 1
}

state=$(busctl --system get-property "$service" "$device" "$interface" ChargeThresholdEnabled) \
    || fail "Could not read battery charge preservation state."

case "$state" in
    "b true")
        enabled=false
        message="Battery preservation disabled — charging allowed to 100%."
        ;;
    "b false")
        enabled=true
        message="Battery preservation enabled — using configured charge limits."
        ;;
    *)
        fail "Unexpected battery charge preservation state."
        ;;
esac

busctl --system call "$service" "$device" "$interface" EnableChargeThreshold b "$enabled" \
    || fail "Could not change battery charge preservation."

state=$(busctl --system get-property "$service" "$device" "$interface" ChargeThresholdEnabled) \
    || fail "Could not verify battery charge preservation state."
[[ "$state" == "b $enabled" ]] \
    || fail "Battery charge preservation did not switch to the requested state."

notify normal "$message"
