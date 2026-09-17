#!/usr/bin/env bash

set -u

bold=$'\e[1m'
dim=$'\e[2m'
reset=$'\e[0m'

TAB_NAMES=("Available" "Paired" "Special Keys")
tab_index=0

# ─────────────────────────────────────────────
# Core helpers
# ─────────────────────────────────────────────

bluetooth_on() {
  bluetoothctl power on >/dev/null 2>&1
}

bluetooth_off() {
  bluetoothctl power off >/dev/null 2>&1
}

scan() {
  echo "Scanning..."
  bluetoothctl power on >/dev/null 2>&1
  bluetoothctl scan on >/dev/null 2>&1 &
  local pid=$!
  sleep 4
  bluetoothctl scan off >/dev/null 2>&1
  kill "$pid" >/dev/null 2>&1 || true
}

get_devices() {
  bluetoothctl devices 2>/dev/null
}

get_paired_macs() {
  {
    bluetoothctl paired-devices 2>/dev/null
    bluetoothctl devices Paired 2>/dev/null
  } |
    awk '{print $2}' | sort -u
}

get_connected() {
  bluetoothctl devices Connected 2>/dev/null
}

is_connected() {
  local mac="$1"
  bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"
}

# ─────────────────────────────────────────────
# Available (unpaired, discovered) devices
# ─────────────────────────────────────────────

available_display() {
  local paired
  paired="$(get_paired_macs)"

  get_devices | while read -r _ mac name; do
    [[ -z "$mac" ]] && continue
    grep -qx "$mac" <<<"$paired" && continue

    if is_connected "$mac"; then
      printf "●  %-32s %s\n" "$name" "$mac"
    else
      printf "   %-32s %s\n" "$name" "$mac"
    fi
  done
}

# ─────────────────────────────────────────────
# Paired devices
# ─────────────────────────────────────────────

paired_display() {
  {
    bluetoothctl paired-devices 2>/dev/null
    bluetoothctl devices Paired 2>/dev/null
  } |
    awk '!seen[$2]++' |
    while read -r _ mac name; do
      [[ -z "$mac" ]] && continue

      if is_connected "$mac"; then
        printf "●  %-32s %s\n" "$name" "$mac"
      else
        printf "   %-32s %s\n" "$name" "$mac"
      fi
    done
}

# ─────────────────────────────────────────────
# Selection parsing
# ─────────────────────────────────────────────

mac_from_selection() {
  grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' <<<"$1"
}

name_from_selection() {
  local selected="$1" mac="$2" name

  name="$(sed -E 's/^[● ]+[[:space:]]*//' <<<"$selected")"
  name="${name%%"$mac"*}"
  sed -E 's/[[:space:]]+$//' <<<"$name"
}

# ─────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────

connect_device() {
  local mac="$1"
  local name="$2"

  echo
  echo "${bold}Device:${reset} $name"
  echo "${dim}Address:${reset} $mac"
  echo
  echo "Connecting..."

  if bluetoothctl connect "$mac"; then
    echo
    echo "${bold}✓ Connected to $name${reset}"
  else
    echo
    echo "${bold}✗ Connection failed${reset}"
  fi

  echo
  read -rp "Press Enter to continue..."
}

disconnect_device() {
  local connected
  connected="$(get_connected)"

  if [[ -z "$connected" ]]; then
    echo
    echo "No Bluetooth device is connected."
    sleep 1
    return
  fi

  local mac name
  mac="$(echo "$connected" | awk 'NR==1{print $2}')"
  name="$(echo "$connected" | head -n1 | cut -d' ' -f3-)"

  echo
  echo "Disconnecting from ${name:-Unknown Device}..."

  if bluetoothctl disconnect "$mac"; then
    echo
    echo "${bold}✓ Disconnected${reset}"
  else
    echo
    echo "${bold}✗ Disconnect failed${reset}"
  fi

  sleep 1
}

remove_paired() {
  local mac="$1"
  local name="$2"

  [[ -z "$mac" ]] && return

  echo
  echo "Removing paired device: ${name:-$mac}"

  if bluetoothctl remove "$mac" >/dev/null 2>&1; then
    echo "${bold}✓ Removed ${name:-$mac}${reset}"
  else
    echo "✗ Failed to remove ${name:-$mac}"
  fi

  sleep 1
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
  echo "${bold}Bluetooth${reset}"
  echo

  if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo "${dim}Bluetooth:${reset} ${bold}On${reset}"
  else
    echo "${dim}Bluetooth:${reset} ${dim}Off${reset}"
  fi

  local connected
  connected="$(get_connected)"

  if [[ -n "$connected" ]]; then
    local mac name
    mac="$(echo "$connected" | awk 'NR==1{print $2}')"
    name="$(echo "$connected" | head -n1 | cut -d' ' -f3-)"

    echo "${dim}Connected:${reset} ${bold}${name:-Unknown Device}${reset}"
    echo "${dim}Address:${reset} $mac"
  else
    echo "${dim}Connected:${reset} ${dim}None${reset}"
  fi

  echo
  draw_tab_bar
  echo "${dim}────────────────────────────────────────────────────────${reset}"
  echo
}

# ─────────────────────────────────────────────
# Startup checks
# ─────────────────────────────────────────────

if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo "bluetoothctl is not installed."
  echo "Install with: sudo pacman -S bluez bluez-utils"
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is not installed."
  echo "Install with: sudo pacman -S fzf"
  exit 1
fi

if [[ -z "$(bluetoothctl list 2>/dev/null)" ]]; then
  echo "No Bluetooth controller found."
  exit 1
fi

bluetooth_on
scan

# ─────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────

while true; do

  draw_header

  case $tab_index in
  0)
    display="$(available_display)"
    extra_keys="r"
    footer="  ${bold}Enter${reset}  Connect      ${bold}r${reset}  Rescan"
    ;;
  1)
    display="$(paired_display)"
    extra_keys="x"
    footer="  ${bold}Enter${reset}  Connect      ${bold}x${reset}  Remove paired device"
    ;;
  2)
    display=$'Rescan devices\nBluetooth On\nBluetooth Off\nDisconnect\nQuit'
    extra_keys=""
    footer="  ${bold}Enter${reset}  Run selected action"
    ;;
  esac

  if [[ -z "$display" ]]; then
    echo "${dim}No devices found.${reset}"
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
        --prompt="  Bluetooth > " \
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
  r)
    scan
    continue
    ;;
  x)
    if [[ $tab_index -eq 1 && -n "$selected" ]]; then
      mac="$(mac_from_selection "$selected")"
      name="$(name_from_selection "$selected" "$mac")"
      remove_paired "$mac" "$name"
    fi
    continue
    ;;
  esac

  [[ -z "$selected" ]] && continue

  case $tab_index in
  0 | 1)
    mac="$(mac_from_selection "$selected")"
    name="$(name_from_selection "$selected" "$mac")"
    connect_device "$mac" "$name"
    ;;
  2)
    case "$selected" in
    "Rescan devices") scan ;;
    "Bluetooth On")
      bluetooth_on
      sleep 1
      ;;
    "Bluetooth Off")
      bluetooth_off
      sleep 1
      ;;
    "Disconnect") disconnect_device ;;
    "Quit") exit 0 ;;
    esac
    ;;
  esac

done
