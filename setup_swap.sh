#!/bin/bash
# 🌍 Cross-Plattform Swap-Manager
# Unterstützt: Linux (Debian-basiert) + Windows-Erkennung
# Autor: haku0x (angepasst)

set -euo pipefail
trap 'echo -e "\n\033[1;91m❌ Ein Fehler ist aufgetreten. Abbruch.\033[0m"; exit 1' ERR
SWAP_FILE="/swapfile"

# === System-Erkennung ===
OS=$(uname -s)

function is_windows() {
  [[ "$OS" == MINGW* || "$OS" == CYGWIN* || "$OS" == MSYS* ]]
}

function is_linux() {
  [[ "$OS" == "Linux" ]]
}

# === WINDOWS HANDLING ===
function run_windows() {
  echo -e "\n\033[1;93m⚠️  Windows erkannt – Swap-Verwaltung erfolgt hier manuell.\033[0m"
  echo -e "🔧 Bitte folge diesen Schritten:"
  echo -e "1. Systemsteuerung → System → Erweiterte Systemeinstellungen"
  echo -e "2. Reiter 'Erweitert' → Leistung → Einstellungen"
  echo -e "3. Reiter 'Erweitert' → Virtueller Speicher → Ändern"
  echo -e "4. Konfiguriere dort die Auslagerungsdatei (pagefile.sys)\n"
  exit 0
}

# === DEBIAN SWAP-MANAGER ===
function require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;91m❌ Dieses Skript muss als root oder mit sudo ausgeführt werden.\033[0m"
    exit 1
  fi
}

function header() {
  clear
  echo -e "\n\033[1;95m╔════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;95m║       🧠 Interaktiver Swap-Manager         ║\033[0m"
  echo -e "\033[1;95m║              für Debian 12                ║\033[0m"
  echo -e "\033[1;95m╚════════════════════════════════════════════╝\033[0m\n"
  if swapon --noheadings --show | grep -q "$SWAP_FILE"; then
    echo -e "\033[1;92m✅ Aktiver Swap erkannt:\033[0m"
    swapon --show | tail -n +2
    echo ""
  fi
}

function show_menu() {
  header
  echo -e "\033[1;93m[1]\033[0m ➕ Swap erstellen"
  echo -e "\033[1;93m[2]\033[0m ❌ Swap entfernen"
  echo -e "\033[1;93m[3]\033[0m 🔁 Swap-Größe ändern"
  echo -e "\033[1;93m[4]\033[0m 🚪 Beenden"
  echo -ne "\n🔢 \033[1mAuswahl eingeben [1-4]: \033[0m"
  read -r CHOICE
  case $CHOICE in
    1) create_swap;;
    2) remove_swap;;
    3) resize_swap;;
    4) echo -e "\n👋 \033[1;92mBeende Skript...\033[0m"; exit 0;;
    *) echo -e "\n❗ \033[1;91mUngültige Eingabe. Bitte erneut versuchen.\033[0m"; sleep 1; show_menu;;
  esac
}

function create_swap() {
  require_root
  if swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "\n✅ \033[1;92mSwap ist bereits aktiv unter $SWAP_FILE\033[0m"
    return
  fi
  echo -ne "📦 \033[1mGewünschte Swap-Größe (z. B. 1G, 2G, 4G): \033[0m"
  read -r SWAP_SIZE
  echo -e "📁 \033[1;96mErstelle Swap-Datei mit Größe $SWAP_SIZE...\033[0m"
  fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((${SWAP_SIZE::-1} * 1024)) status=progress
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" > /dev/null
  swapon "$SWAP_FILE"

  grep -q "$SWAP_FILE" /etc/fstab || echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
  sysctl -q -p /etc/sysctl.d/99-swappiness.conf

  echo -e "\n✅ \033[1;92mSwap wurde erfolgreich eingerichtet.\033[0m"
  swapon --show | tail -n +2
}

function remove_swap() {
  require_root
  if ! swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "⚠️ \033[1;93mKein aktiver Swap unter $SWAP_FILE gefunden.\033[0m"
  else
    echo -e "🧹 \033[1;96mDeaktiviere Swap...\033[0m"
    swapoff "$SWAP_FILE"
  fi
  echo -e "🗑️ \033[1;91mEntferne Swap-Datei...\033[0m"
  rm -f "$SWAP_FILE"
  sed -i '\|/swapfile|d' /etc/fstab
  rm -f /etc/sysctl.d/99-swappiness.conf
  sysctl -q -w vm.swappiness=60 || true
  echo -e "✅ \033[1;92mSwap wurde entfernt.\033[0m"
}

function resize_swap() {
  require_root
  if swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "♻️  \033[1;93mEntferne existierenden Swap zum Anpassen...\033[0m"
    swapoff "$SWAP_FILE"
  fi
  remove_swap
  echo -ne "📏 \033[1mNeue Swap-Größe (z. B. 2G, 8G): \033[0m"
  read -r NEW_SIZE
  echo -e "🔧 \033[1;96mErstelle neuen Swap mit $NEW_SIZE...\033[0m"
  fallocate -l "$NEW_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((${NEW_SIZE::-1} * 1024)) status=progress
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" > /dev/null
  swapon "$SWAP_FILE"
  grep -q "$SWAP_FILE" /etc/fstab || echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
  sysctl -q -p /etc/sysctl.d/99-swappiness.conf
  echo -e "✅ \033[1;92mSwap wurde auf $NEW_SIZE geändert.\033[0m"
  swapon --show | tail -n +2
}

# === AUSFÜHRUNG STARTEN ===
if is_windows; then
  run_windows
elif is_linux; then
  show_menu
else
  echo "❌ Nicht unterstütztes Betriebssystem: $OS"
  exit 1
fi
