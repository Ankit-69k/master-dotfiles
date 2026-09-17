#!/usr/bin/env bash

set -u

bold=$'\e[1m'
dim=$'\e[2m'
reset=$'\e[0m'

TAB_NAMES=("Output" "Input" "Special Keys")
tab_index=0

# ─────────────────────────────────────────────
# Core helpers (pactl works for PulseAudio and PipeWire-pulse)
# ─────────────────────────────────────────────

default_sink() { pactl get-default-sink 2>/dev/null; }
default_source() { pactl get-default-source 2>/dev/null; }

sink_volume() {
  pactl get-sink-volume "$1" 2>/dev/null | grep -oE '[0-9]+%' | head -n1
}

sink_muted() {
  pactl get-sink-mute "$1" 2>/dev/null | awk '{print $2}'
}

source_volume() {
  pactl get-source-volume "$1" 2>/dev/null | grep -oE '[0-9]+%' | head -n1
}

source_muted() {
  pactl get-source-mute "$1" 2>/dev/null | awk '{print $2}'
}

volume_up() {
  pactl set-sink-volume @DEFAULT_SINK@ +5% >/dev/null 2>&1
}

volume_down() {
  pactl set-sink-volume @DEFAULT_SINK@ -5% >/dev/null 2>&1
}

mute_output_toggle() {
  pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null 2>&1
}

mute_input_toggle() {
  pactl set-source-mute @DEFAULT_SOURCE@ toggle >/dev/null 2>&1
}

# ─────────────────────────────────────────────
# Output devices (sinks)
# ─────────────────────────────────────────────

get_sinks() {
  pactl list sinks 2>/dev/null | awk '
        /^[[:space:]]*Name: / { sub(/^[[:space:]]*Name: /, ""); name=$0 }
        /^[[:space:]]*Description: / { sub(/^[[:space:]]*Description: /, ""); print name "\t" $0 }
    '
}

output_display() {
  local default
  default="$(default_sink)"

  get_sinks | while IFS=$'\t' read -r name desc; do
    [[ -z "$name" ]] && continue

    local vol mute tag
    vol="$(sink_volume "$name")"
    mute="$(sink_muted "$name")"
    tag="$vol"
    [[ "$mute" == "yes" ]] && tag="$tag muted"

    if [[ "$name" == "$default" ]]; then
      printf "●  %-40s %-14s (%s)\n" "$desc" "$tag" "$name"
    else
      printf "   %-40s %-14s (%s)\n" "$desc" "$tag" "$name"
    fi
  done
}

# ─────────────────────────────────────────────
# Input devices (sources, excluding monitors)
# ─────────────────────────────────────────────

get_sources() {
  pactl list sources 2>/dev/null | awk '
        /^[[:space:]]*Name: / { sub(/^[[:space:]]*Name: /, ""); name=$0 }
        /^[[:space:]]*Description: / { sub(/^[[:space:]]*Description: /, ""); print name "\t" $0 }
    ' | grep -v $'\.monitor\t' | grep -vi '\.monitor'
}

input_display() {
  local default
  default="$(default_source)"

  get_sources | while IFS=$'\t' read -r name desc; do
    [[ -z "$name" ]] && continue
    [[ "$name" == *.monitor ]] && continue

    local vol mute tag
    vol="$(source_volume "$name")"
    mute="$(source_muted "$name")"
    tag="$vol"
    [[ "$mute" == "yes" ]] && tag="$tag muted"

    if [[ "$name" == "$default" ]]; then
      printf "●  %-40s %-14s (%s)\n" "$desc" "$tag" "$name"
    else
      printf "   %-40s %-14s (%s)\n" "$desc" "$tag" "$name"
    fi
  done
}

# ─────────────────────────────────────────────
# Selection parsing — technical name is the trailing (…) group
# ─────────────────────────────────────────────

name_from_selection() {
  sed -E 's/^.*\(([^)]+)\)[[:space:]]*$/\1/' <<<"$1"
}

# ─────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────

set_output() {
  local name="$1"
  [[ -z "$name" ]] && return

  if pactl set-default-sink "$name" >/dev/null 2>&1; then
    echo
    echo "${bold}✓ Output set${reset}"
    sleep 1
  else
    echo
    echo "${bold}✗ Failed to set output${reset}"
    sleep 1
  fi
}

set_input() {
  local name="$1"
  [[ -z "$name" ]] && return

  if pactl set-default-source "$name" >/dev/null 2>&1; then
    echo
    echo "${bold}✓ Input set${reset}"
    sleep 1
  else
    echo
    echo "${bold}✗ Failed to set input${reset}"
    sleep 1
  fi
}

toggle_sink_mute() {
  local name="$1"
  [[ -z "$name" ]] && return
  pactl set-sink-mute "$name" toggle >/dev/null 2>&1
}

toggle_source_mute() {
  local name="$1"
  [[ -z "$name" ]] && return
  pactl set-source-mute "$name" toggle >/dev/null 2>&1
}

# ─────────────────────────────────────────────
# Header / tab bar
# ─────────────────────────────────────────────

draw_tab_bar() {
  local i line=""

  for i in "${!TAB_NAMES[@]}"; do
    if [[ $i -eq $tab_index ]]; then
      line+="${bold}[ ${TAB_NAMES[$i]} ]${reset}   "
    else
      line+="${dim}${TAB_NAMES[$i]}${reset}   "
    fi
  done

  echo "$line"
}

draw_header() {
  clear

  echo
  echo "${bold}Sound${reset}"
  echo

  local sink source svol smute ivol imute
  sink="$(default_sink)"
  source="$(default_source)"
  svol="$(sink_volume "$sink")"
  smute="$(sink_muted "$sink")"
  ivol="$(source_volume "$source")"
  imute="$(source_muted "$source")"

  echo "${dim}Output:${reset} ${bold}${sink:-None}${reset}  ${dim}(${svol:-?}$([[ "$smute" == "yes" ]] && echo ", muted"))${reset}"
  echo "${dim}Input:${reset}  ${bold}${source:-None}${reset}  ${dim}(${ivol:-?}$([[ "$imute" == "yes" ]] && echo ", muted"))${reset}"

  echo
  draw_tab_bar
  echo "${dim}────────────────────────────────────────────────────────${reset}"
  echo
}

# ─────────────────────────────────────────────
# Startup checks
# ─────────────────────────────────────────────

if ! command -v pactl >/dev/null 2>&1; then
  echo "pactl is not installed."
  echo "Install with: sudo pacman -S libpulse pipewire-pulse"
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is not installed."
  echo "Install with: sudo pacman -S fzf"
  exit 1
fi

# ─────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────

while true; do

  draw_header

  case $tab_index in
  0)
    display="$(output_display)"
    extra_keys="m"
    footer="  ${bold}Enter${reset}  Set as default    ${bold}m${reset}  Mute/unmute selected"
    ;;
  1)
    display="$(input_display)"
    extra_keys="m"
    footer="  ${bold}Enter${reset}  Set as default    ${bold}m${reset}  Mute/unmute selected"
    ;;
  2)
    display=$'Volume Up (+5%)\nVolume Down (-5%)\nMute/Unmute Output\nMute/Unmute Input\nQuit'
    extra_keys=""
    footer="  ${bold}Enter${reset}  Run selected action"
    ;;
  esac

  if [[ -z "$display" ]]; then
    echo "${dim}Nothing found.${reset}"
  fi

  printf '%s\n' "$display"

  echo
  echo "${dim}────────────────────────────────────────────────────────${reset}"
  echo
  echo "$footer"
  echo "  ${bold}Tab${reset}    Switch view      ${bold}q${reset}  Quit"
  echo

  expect_keys="tab,q"
  [[ -n "$extra_keys" ]] && expect_keys="$expect_keys,$extra_keys"

  mapfile -t fzf_result < <(
    printf '%s\n' "$display" |
      fzf \
        --height=45% \
        --layout=reverse \
        --border \
        --prompt="  Sound > " \
        --pointer="▶" \
        --marker="●" \
        --no-multi \
        --expect="$expect_keys"
  )

  if [[ ${#fzf_result[@]} -eq 0 ]]; then
    exit 0
  fi

  key="${fzf_result[0]-}"
  selected="${fzf_result[1]-}"

  case "$key" in
  q)
    exit 0
    ;;
  tab)
    tab_index=$(((tab_index + 1) % ${#TAB_NAMES[@]}))
    continue
    ;;
  m)
    if [[ -n "$selected" ]]; then
      name="$(name_from_selection "$selected")"
      if [[ $tab_index -eq 0 ]]; then
        toggle_sink_mute "$name"
      elif [[ $tab_index -eq 1 ]]; then
        toggle_source_mute "$name"
      fi
    fi
    continue
    ;;
  esac

  [[ -z "$selected" ]] && continue

  case $tab_index in
  0)
    name="$(name_from_selection "$selected")"
    set_output "$name"
    ;;
  1)
    name="$(name_from_selection "$selected")"
    set_input "$name"
    ;;
  2)
    case "$selected" in
    "Volume Up (+5%)") volume_up ;;
    "Volume Down (-5%)") volume_down ;;
    "Mute/Unmute Output") mute_output_toggle ;;
    "Mute/Unmute Input") mute_input_toggle ;;
    "Quit") exit 0 ;;
    esac
    ;;
  esac

done
