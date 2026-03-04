#!/usr/bin/env bash
set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
  printf '{"text":"󰂲","class":"off","tooltip":"Bluetooth tools not found"}\n'
  exit 0
fi

show_out="$(bluetoothctl show 2>/dev/null || true)"
if [[ -z "${show_out}" ]]; then
  printf '{"text":"󰂲","class":"off","tooltip":"Bluetooth controller unavailable"}\n'
  exit 0
fi

powered="$(printf '%s\n' "${show_out}" | awk -F': ' '/Powered:/ {print tolower($2); exit}')"
if [[ "${powered}" != "yes" ]]; then
  printf '{"text":"󰂲","class":"off","tooltip":"Bluetooth: off"}\n'
  exit 0
fi

connected="$(bluetoothctl devices Connected 2>/dev/null || true)"
count="$(printf '%s\n' "${connected}" | sed '/^$/d' | wc -l | tr -d ' ')"

if [[ -n "${count}" ]] && ((count > 0)); then
  printf '{"text":"󰂱","class":"connected","tooltip":"Bluetooth: %s connected"}\n' "${count}"
else
  printf '{"text":"","class":"on","tooltip":"Bluetooth: on"}\n'
fi
