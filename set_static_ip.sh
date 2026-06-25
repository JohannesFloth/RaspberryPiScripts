#This script is used for setting a static ip in raspberry pi os bookworm and forward. Using network-manager-cli it requests the user to specify the number on the lab-set to ensure a unique ip-address.
#!/usr/bin/env bash
set -euo pipefail

LAN_IF="eth0"
WLAN_IF="wlan0"

LAN_NET="10.205.201"
WLAN_NET="10.222.222"

PREFIX="16"

LAN_GATEWAY="10.205.0.1"
WLAN_GATEWAY="10.222.0.1"

DNS_SERVER="10.0.0.11"

read -rp "Nummer des Laborsets eingeben (1-254): " X

if ! [[ "$X" =~ ^[0-9]+$ ]] || (( X < 1 || X > 254 )); then
  echo "Fehler: Bitte eine Zahl zwischen 1 und 254 eingeben."
  exit 1
fi

configure_interface() {
  local IFACE="$1"
  local IP_BASE="$2"
  local GATEWAY="$3"

  local IP="${IP_BASE}.${X}/${PREFIX}"

  local CON_ID
  CON_ID=$(nmcli -t -f NAME,DEVICE connection show | awk -F: -v dev="$IFACE" '$2 == dev {print $1; exit}')

  if [[ -z "${CON_ID:-}" ]]; then
    echo "Warnung: Keine Connection-ID für ${IFACE} gefunden. Überspringe ${IFACE}."
    return 0
  fi

  echo "Konfiguriere ${IFACE} über Connection-ID '${CON_ID}'"
  echo "IP:      ${IP}"
  echo "Gateway: ${GATEWAY}"
  echo "DNS:     ${DNS_SERVER}"

  sudo nmcli connection modify "$CON_ID" \
    ipv4.method manual \
    ipv4.addresses "$IP" \
    ipv4.gateway "$GATEWAY" \
    ipv4.dns "$DNS_SERVER" \
    ipv4.ignore-auto-dns yes

  sudo nmcli connection down "$CON_ID" || true
  sudo nmcli connection up "$CON_ID" || true

  echo "${IFACE} fertig."
  echo
}

configure_interface "$LAN_IF" "$LAN_NET" "$LAN_GATEWAY"
configure_interface "$WLAN_IF" "$WLAN_NET" "$WLAN_GATEWAY"

echo "Fertig."
