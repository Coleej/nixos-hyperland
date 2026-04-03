#!/usr/bin/env bash
# Show keybindings in wofi

notify-send "Keybindings" "Loading..."

KEYBINDINGS=$(/run/current-system/sw/bin/hyprctl -j binds | /etc/profiles/per-user/cody/bin/jq -r '.[] | "\(.key) \(.modmask // "") \(.dispatcher) \(.arg)"' | sort)

echo "$KEYBINDINGS" | /run/current-system/sw/bin/wofi --dmenu --fork --prompt "Keybindings"
