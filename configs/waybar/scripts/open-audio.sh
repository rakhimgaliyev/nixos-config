#!/usr/bin/env bash
set -euo pipefail

if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl clients | grep -Eiq 'class: (org\.pulseaudio\.pavucontrol|pavucontrol)|title: Volume Control'; then
    hyprctl dispatch movetoworkspacesilent current,'class:^(org\.pulseaudio\.pavucontrol|pavucontrol)$' >/dev/null 2>&1 || true
    hyprctl dispatch focuswindow 'class:^(org\.pulseaudio\.pavucontrol|pavucontrol)$' >/dev/null 2>&1 \
      || hyprctl dispatch focuswindow 'title:^(Volume Control)$' >/dev/null 2>&1 \
      || true
    exit 0
  fi
fi

exec pavucontrol
