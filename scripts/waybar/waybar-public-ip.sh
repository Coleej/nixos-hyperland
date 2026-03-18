#!/usr/bin/env bash
set -euo pipefail

get_ip() {
  curl -fsS --max-time 2 https://api.ipify.org 2>/dev/null && return 0
  curl -fsS --max-time 2 https://ifconfig.me 2>/dev/null && return 0
  curl -fsS --max-time 2 https://icanhazip.com 2>/dev/null && return 0
  return 1
}

ip="$(get_ip 2>/dev/null || true)"
if [[ -z "${ip:-}" ]]; then
  echo '{"text":"IP: ?","tooltip":"Public IP unavailable"}'
else
  ip_trimmed="${ip//$'\n'/}"
  printf '{"text": "IP: %s", "tooltip": "Public IP: %s"}\n' "$ip_trimmed" "$ip_trimmed"
fi
