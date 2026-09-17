#!/usr/bin/env bash

set -u

WIFI_DEVICE="$(nmcli -t -f DEVICE,TYPE device status |
  awk -F: '$2=="wifi"{print $1; exit}')"

if [[ -z "${WIFI_DEVICE:-}" ]]; then
  echo "No Wi-Fi device found."
  exit 1
fi

bold=$'\e[1m'
dim=$'\e[2m'
reset=$'\e[0m'

TAB_NAMES=("Available" "Saved" "Special Keys")
tab_index=0

current_connection() {
  nmcli -t -f NAME,TYPE connection show --active |
    awk -F: '$2=="802-11-wireless"{print $1; exit}'
}

# ─────────────────────────────────────────────
# Available networks (scan results)
# ─────────────────────────────────────────────

get_networks() {
  nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list |
    awk -F: '
    $2 != "" {
        ssid=$2
        signal=$3
        security=$4

        if (security == "")
            security="OPEN"

        if ($1 == "*")
            printf "●\t%s\t%s\t%s\n", ssid, signal, security
        else
            printf " \t%s\t%s\t%s\n", ssid, signal, security
    }' |
    awk -F'\t' '!seen[$2]++'
}

available_display() {
  get_networks | awk -F'\t' '
    {
        if ($1 == "●")
            printf "●  %-32s %3s%%  [%s]\n", $2, $3, $4
        else
            printf "   %-32s %3s%%  [%s]\n", $2, $3, $4
    }'
}

ssid_from_selection() {
  sed -E '
        s/^[● ]+[[:space:]]*//
        s/[[:space:]]+[0-9]+%[[:space:]]+\[[^]]+\]$//
    ' <<<"$1"
}

scan() {
  echo "Scanning..."

  nmcli radio wifi on >/dev/null 2>&1
  nmcli device wifi rescan >/dev/null 2>&1

  sleep 1
}

connect_network() {
  local ssid="$1"

  [[ -z "$ssid" ]] && return

  echo
  echo "${bold}Network:${reset} $ssid"
  echo

  # Check if NetworkManager already has a saved connection
  local saved

  saved="$(
    nmcli -t -f NAME,TYPE connection show |
      awk -F: -v ssid="$ssid" '
            $1 == ssid && $2 == "802-11-wireless" {
                print $1
                exit
            }
        '
  )"

  if [[ -n "$saved" ]]; then
    echo "Saved network found."
    echo "Connecting..."

    if nmcli connection up "$saved"; then
      echo
      echo "${bold}✓ Connected to $ssid${reset}"
      sleep 2
      return
    fi

    echo
    echo "Saved connection failed."
    echo "Trying again with password..."
    echo
  fi

  # Password entry directly in terminal
  local password

  read -rsp "Password for $ssid: " password
  echo

  if [[ -z "$password" ]]; then
    echo "Password cannot be empty."
    sleep 1
    return
  fi

  echo
  echo "Connecting..."

  if nmcli device wifi connect "$ssid" \
    password "$password" \
    ifname "$WIFI_DEVICE"; then

    echo
    echo "${bold}✓ Connected to $ssid${reset}"

  else

    echo
    echo "${bold}✗ Connection failed.${reset}"
    echo
    echo "NetworkManager reported:"
    nmcli device status

  fi

  echo
  read -rp "Press Enter to continue..."
}

# ─────────────────────────────────────────────
# Saved networks
# ─────────────────────────────────────────────

get_saved_networks() {
  local current
  current="$(current_connection)"

  nmcli -t -f NAME,TYPE,AUTOCONNECT connection show |
    awk -F: -v current="$current" '
      $2 == "802-11-wireless" {
          name  = $1
          auto  = ($3 == "yes") ? "auto-connect" : "manual"
          marker = (name == current) ? "●" : " "
          printf "%s\t%s\t%s\n", marker, name, auto
      }'
}

saved_display() {
  get_saved_networks | awk -F'\t' '{printf "%s  %-32s %s\n", $1, $2, $3}'
}

saved_name_from_selection() {
  sed -E '
        s/^[● ]+[[:space:]]*//
        s/[[:space:]]+(auto-connect|manual)[[:space:]]*$//
        s/[[:space:]]+$//
    ' <<<"$1"
}

connect_saved() {
  local name="$1"

  [[ -z "$name" ]] && return

  echo
  echo "${bold}Network:${reset} $name"
  echo
  echo "Connecting..."

  if nmcli connection up "$name"; then
    echo
    echo "${bold}✓ Connected to $name${reset}"
    sleep 2
  else
    echo
    echo "${bold}✗ Connection failed.${reset}"
    echo
    nmcli device status
    echo
    read -rp "Press Enter to continue..."
  fi
}

remove_saved() {
  local name="$1"

  [[ -z "$name" ]] && return

  echo
  echo "Removing saved network: $name"

  if nmcli connection delete "$name" >/dev/null 2>&1; then
    echo "${bold}✓ Removed $name${reset}"
  else
    echo "✗ Failed to remove $name"
  fi

  sleep 1
}

# ─────────────────────────────────────────────
# Radio / connection actions
# ─────────────────────────────────────────────

disconnect_wifi() {
  local current
  current="$(current_connection)"

  if [[ -z "$current" ]]; then
    echo
    echo "No Wi-Fi connection is active."
    sleep 1
    return
  fi

  echo
  echo "Disconnecting from $current..."

  if nmcli device disconnect "$WIFI_DEVICE"; then
    echo
    echo "${bold}✓ Disconnected from $current${reset}"
  else
    echo
    echo "✗ Failed to disconnect."
  fi

  sleep 1
}

wifi_on() {
  nmcli radio wifi on

  echo
  echo "${bold}✓ Wi-Fi enabled${reset}"

  sleep 1
}

wifi_off() {
  nmcli radio wifi off

  echo
  echo "${bold}✓ Wi-Fi disabled${reset}"

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

  local current
  current="$(current_connection)"

  echo
  echo "${bold}                         Wi-Fi${reset}"
  echo

  echo "${dim}Device:${reset} $WIFI_DEVICE"

  if [[ -n "$current" ]]; then
    echo "${dim}Connected:${reset} ${bold}$current${reset}"
  else
    echo "${dim}Connected:${reset} ${dim}None${reset}"
  fi

  echo
  draw_tab_bar
  echo "${dim}────────────────────────────────────────────────────────${reset}"
  echo
}

# ─────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────

scan

while true; do

  draw_header

  case $tab_index in
  0)
    display="$(available_display)"
    extra_keys="r"
    footer="  ${bold}Enter${reset}  Connect      ${bold}r${reset}  Rescan"
    ;;
  1)
    display="$(saved_display)"
    extra_keys="x"
    footer="  ${bold}Enter${reset}  Connect      ${bold}x${reset}  Remove saved network"
    ;;
  2)
    display=$'Rescan networks\nWi-Fi On\nWi-Fi Off\nDisconnect\nQuit'
    extra_keys=""
    footer="  ${bold}Enter${reset}  Run selected action"
    ;;
  esac

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
        --prompt="  Wi-Fi > " \
        --pointer="▶" \
        --marker="●" \
        --no-multi \
        --expect="$expect_keys"
  )

  # ESC / Ctrl-C: nothing captured at all -> quit
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
      name="$(saved_name_from_selection "$selected")"
      remove_saved "$name"
    fi
    continue
    ;;
  esac

  # No action key pressed -> Enter was used on the highlighted row.
  [[ -z "$selected" ]] && continue

  case $tab_index in
  0)
    ssid="$(ssid_from_selection "$selected")"
    connect_network "$ssid"
    ;;
  1)
    name="$(saved_name_from_selection "$selected")"
    connect_saved "$name"
    ;;
  2)
    case "$selected" in
    "Rescan networks") scan ;;
    "Wi-Fi On") wifi_on ;;
    "Wi-Fi Off") wifi_off ;;
    "Disconnect") disconnect_wifi ;;
    "Quit") exit 0 ;;
    esac
    ;;
  esac

done
