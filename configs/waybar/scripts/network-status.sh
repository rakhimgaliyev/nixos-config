#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_RUNTIME_DIR:-/tmp}"
cache_file="${cache_dir}/waybar-network-speed.cache"

get_iface() {
  ip route get 1.1.1.1 2>/dev/null | awk '
    {
      for (i = 1; i <= NF; i++) {
        if ($i == "dev") {
          print $(i + 1)
          exit
        }
      }
    }'
}

iface="$(get_iface)"
if [[ -z "${iface}" ]]; then
  iface="$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')"
fi

if command -v nmcli >/dev/null 2>&1; then
  connectivity="$(nmcli -t -f CONNECTIVITY g 2>/dev/null | head -n1 || true)"
  if [[ "${connectivity}" == "none" ]]; then
    printf '{"text":"󰖪","class":"offline","tooltip":"Network: offline"}\n'
    exit 0
  fi
fi

if [[ -z "${iface}" || ! -d "/sys/class/net/${iface}" ]]; then
  printf '{"text":"󰖪","class":"offline","tooltip":"Network: offline"}\n'
  exit 0
fi

state="$(cat "/sys/class/net/${iface}/operstate" 2>/dev/null || echo down)"
if [[ "${state}" != "up" ]]; then
  printf '{"text":"󰖪","class":"offline","tooltip":"%s: %s"}\n' "${iface}" "${state}"
  exit 0
fi

rx_now="$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)"
tx_now="$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)"
ts_now="$(date +%s)"

rx_prev="${rx_now}"
tx_prev="${tx_now}"
ts_prev="${ts_now}"

if [[ -f "${cache_file}" ]]; then
  read -r ts_prev rx_prev tx_prev < "${cache_file}" || true
fi

printf '%s %s %s\n' "${ts_now}" "${rx_now}" "${tx_now}" > "${cache_file}"

dt=$((ts_now - ts_prev))
if ((dt <= 0)); then
  dt=1
fi

down=$(((rx_now - rx_prev) / dt))
up=$(((tx_now - tx_prev) / dt))

if ((down < 0)); then
  down=0
fi
if ((up < 0)); then
  up=0
fi

down_h="$(numfmt --to=iec --suffix=B/s "${down}" 2>/dev/null || echo "${down}B/s")"
up_h="$(numfmt --to=iec --suffix=B/s "${up}" 2>/dev/null || echo "${up}B/s")"

if [[ -d "/sys/class/net/${iface}/wireless" ]]; then
  icon=""
else
  icon="󰈀"
fi

printf '{"text":"%s ↓ %s ↑ %s","class":"online","tooltip":"%s"}\n' "${icon}" "${down_h}" "${up_h}" "${iface}"
