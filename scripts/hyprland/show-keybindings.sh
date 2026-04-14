#!/usr/bin/env bash
# Show Hyprland keybindings in a wofi dmenu popup

# ── Config ────────────────────────────────────────────────────────────────────
WOFI_LINES=25
WOFI_WIDTH=700
# ─────────────────────────────────────────────────────────────────────────────

# Decode a numeric modmask into a human-readable prefix (e.g. "SUPER + SHIFT + ")
decode_mod() {
  local mod=$1
  local out=""
  (( mod & 4  )) && out+="CTRL + "
  (( mod & 8  )) && out+="ALT + "
  (( mod & 64 )) && out+="SUPER + "
  (( mod & 1  )) && out+="SHIFT + "
  echo "$out"
}

# Assign a category label based on the dispatcher
categorize() {
  local disp=$1 arg=$2
  case "$disp" in
    exec)
      case "$arg" in
        *grim*|*slurp*|*screenshot*) echo "Screenshots" ;;
        *brightnessctl*)              echo "Brightness"  ;;
        *wpctl*|*playerctl*)          echo "Media"       ;;
        *hyprlock*|*dpms*)            echo "System"      ;;
        *)                            echo "Launch"      ;;
      esac ;;
    workspace|movetoworkspace|movetoworkspaceabsolute|\
    togglespecialworkspace|movespecialworkspace)
                                      echo "Workspaces"  ;;
    movefocus)                        echo "Focus"       ;;
    movewindow|swapwindow)            echo "Move Window" ;;
    killactive|close)                 echo "Windows"     ;;
    togglefloating|pseudo|layoutmsg|fullscreen|fakefullscreen)
                                      echo "Layout"      ;;
    exit)                             echo "System"      ;;
    *)                                echo "Other"       ;;
  esac
}

# Build the display list
build_list() {
  hyprctl -j binds 2>/dev/null | jq -r '
    .[] | select(
      .mouse       == false and
      .catch_all   == false and
      .submap      == ""
    ) | [.modmask, .key, .dispatcher, .arg] | @tsv
  ' | while IFS=$'\t' read -r modmask key dispatcher arg; do
      prefix=$(decode_mod "$modmask")
      category=$(categorize "$dispatcher" "$arg")

      # Build a friendly action label
      case "$dispatcher" in
        exec)              action="$arg" ;;
        workspace)         action="go to workspace $arg" ;;
        movetoworkspace)   action="move window → workspace $arg" ;;
        togglespecialworkspace) action="toggle special: $arg" ;;
        movespecialworkspace)   action="move → special: $arg" ;;
        movefocus)         action="focus $arg" ;;
        movewindow)        action="move window $arg" ;;
        killactive)        action="close window" ;;
        togglefloating)    action="toggle floating" ;;
        pseudo)            action="toggle pseudo-tile" ;;
        layoutmsg)         action="layout: $arg" ;;
        fullscreen)        action="fullscreen" ;;
        exit)              action="exit Hyprland" ;;
        *)                 action="$dispatcher${arg:+ $arg}" ;;
      esac

      printf "%-14s  %s%s  →  %s\n" "[$category]" "$prefix" "$key" "$action"
    done | sort
}

LIST=$(build_list)

if [[ -z "$LIST" ]]; then
  notify-send -u critical "show-keybindings" "Could not retrieve bindings from hyprctl"
  exit 1
fi

echo "$LIST" | wofi \
  --dmenu \
  --insensitive \
  --prompt "Keybindings" \
  --lines  "$WOFI_LINES" \
  --width  "$WOFI_WIDTH" \
  --hide-scroll \
  --no-actions
