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
  local rows=()
  local max_cat=0 max_key=0

  while IFS=$'\t' read -r modmask key dispatcher arg; do
    # Map XF86 key names to friendly equivalents
    case "$key" in
      XF86AudioRaiseVolume)  key="Volume Up"       ;;
      XF86AudioLowerVolume)  key="Volume Down"     ;;
      XF86AudioMute)         key="Mute"            ;;
      XF86AudioPlay)         key="Play/Pause"      ;;
      XF86AudioNext)         key="Next Track"      ;;
      XF86AudioPrev)         key="Prev Track"      ;;
      XF86MonBrightnessUp)   key="Brightness Up"  ;;
      XF86MonBrightnessDown) key="Brightness Down" ;;
    esac

    prefix=$(decode_mod "$modmask")
    category=$(categorize "$dispatcher" "$arg")
    cat_col="[${category}]"
    key_col="${prefix}${key}"

    # Build a friendly action label
    case "$dispatcher" in
      exec)                       action="$arg" ;;
      workspace)                  action="go to workspace $arg" ;;
      movetoworkspace)            action="move window → workspace $arg" ;;
      togglespecialworkspace)     action="toggle special: $arg" ;;
      movespecialworkspace)       action="move → special: $arg" ;;
      movefocus)                  action="focus $arg" ;;
      movewindow)                 action="move window $arg" ;;
      killactive)                 action="close window" ;;
      togglefloating)             action="toggle floating" ;;
      pseudo)                     action="toggle pseudo-tile" ;;
      layoutmsg)                  action="layout: $arg" ;;
      fullscreen)                 action="fullscreen" ;;
      exit)                       action="exit Hyprland" ;;
      *)                          action="$dispatcher${arg:+ $arg}" ;;
    esac

    # Track max column widths
    (( ${#cat_col} > max_cat )) && max_cat=${#cat_col}
    (( ${#key_col} > max_key )) && max_key=${#key_col}

    rows+=("${cat_col}	${key_col}	${action}")
  done < <(hyprctl -j binds 2>/dev/null | jq -r '
    .[] | select(
      .mouse     == false and
      .catch_all == false and
      .submap    == ""
    ) | [.modmask, .key, .dispatcher, .arg] | @tsv
  ')

  # Print with uniform column widths, sorted
  printf '%s\n' "${rows[@]}" \
    | sort \
    | while IFS=$'\t' read -r cat_col key_col action; do
        printf "%-*s  %-*s  →  %s\n" \
          "$max_cat" "$cat_col" \
          "$max_key" "$key_col" \
          "$action"
      done
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
