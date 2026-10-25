#!/usr/bin/env bash

set -euo pipefail

profile=$(powerprofilesctl get)

case "$profile" in
    performance)
        icon=""
        label="Performance"
        next_profile="balanced"
        next_label="Balanced"
        ;;
    balanced)
        icon=""
        label="Balanced"
        next_profile="power-saver"
        next_label="Power saver"
        ;;
    power-saver)
        icon=""
        label="Power saver"
        next_profile="performance"
        next_label="Performance"
        ;;
    *)
        printf 'Unknown power profile: %s\n' "$profile" >&2
        exit 1
        ;;
esac

if [[ "${1:-}" == "--cycle" ]]; then
    exec powerprofilesctl set "$next_profile"
fi

printf '{"text":"%s %s","tooltip":"Power profile: %s\\nClick for %s","class":"%s"}\n' \
    "$icon" "$label" "$label" "$next_label" "$profile"
