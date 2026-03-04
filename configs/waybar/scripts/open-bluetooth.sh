#!/usr/bin/env bash
set -euo pipefail

if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl clients | grep -Eiq 'class: (\.?blueman-manager(-wrapped)?|org\.blueman\.Manager)|title: Bluetooth Devices'; then
    hyprctl dispatch movetoworkspacesilent current,'class:^(\.?blueman-manager(-wrapped)?|org\.blueman\.Manager)$' >/dev/null 2>&1 || true
    hyprctl dispatch focuswindow 'class:^(\.?blueman-manager(-wrapped)?|org\.blueman\.Manager)$' >/dev/null 2>&1 \
      || hyprctl dispatch focuswindow 'title:^(Bluetooth Devices)$' >/dev/null 2>&1 \
      || true
    exit 0
  fi
fi

exec blueman-manager
