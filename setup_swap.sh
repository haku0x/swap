#!/bin/bash
# 🚀 Interaktiver Swap-Manager für Debian 12
# Autor: haku0x | Lizenz: MIT (erweitert von ChatGPT)

set -euo pipefail
trap 'echo -e "\n${RED}❌ Ein unerwarteter Fehler ist aufgetreten. Breche ab.${NC}"; exit 1' ERR

# === Farben ===
RED='\033[1;91m'; GREEN='\033[1;92m'; YELLOW='\033[1;93m'; CYAN='\033[1;96m'; MAGENTA='\033[1;95m'; NC='\033[0m'

SWAP_FILE="/swapfile"

function header() {
  clear
  echo -e "\n${MAGENTA}╔════════════════════════════════════════════╗"
  echo -e "║       🧠 Interaktiver Swap-Manager         ║"
  echo -e "║            für Debian 12                   ║"
  echo -e "╚════════════════════════════════════════════╝${NC}\n"
  if swapon --noheadings --show | grep -q "$SWAP_FILE"; then
    echo -e "${GREEN}✅ Aktiver Swap erkannt:${NC}"
    swapon --show | tail -n +2
    echo ""
  fi
}

function require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Dieses Skript muss als root oder mit sudo ausgeführt werden.${NC}"
    exit 1
  fi
}

function show_menu() {
  header
  echo -e "${YELLOW}[1]${NC} ➕ Swap erstellen"
  echo -e "${YELLOW}[2]${NC} ❌ Swap entfernen"
  echo -e "${YELLOW}[3]${NC} 🔁 Swap-Größe ändern"
  echo -e "${YELLOW}[4]${NC} 🚪 Beenden"
  echo -e "${YELLOW}[5]${NC} 📊 Swap-Nutzung anzeigen"
  echo -ne "\n🔢 ${CYAN}Auswahl eingeben [1-5]: ${NC}"
  read -r CHOICE
  case $CHOICE in
    1) create_swap ;;
    2) remove_swap ;;
    3) resize_swap ;;
    4) echo -e "\n👋 ${GREEN}Beende Skript...${NC}"; exit 0 ;;
    5) show_swap_usage ;;
    *) echo -e "\n${RED}❗ Ungültige Eingabe. Bitte erneut versuchen.${NC}"; sleep 1; show_menu ;;
  esac
}

function create_swap() {
  require_root
  if swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "\n${GREEN}✅ Swap ist bereits aktiv unter $SWAP_FILE${NC}"
    return
  fi

  read -erp "📦 Gewünschte Swap-Größe (z. B. 1G, 2G): " SWAP_SIZE
  [[ -z "$SWAP_SIZE" ]] && echo -e "${RED}❌ Keine Größe eingegeben.${NC}" && return

  echo -e "${CYAN}📁 Erstelle Swap-Datei mit Größe $SWAP_SIZE...${NC}"
  fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((${SWAP_SIZE::-1} * 1024)) status=progress
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" > /dev/null
  swapon "$SWAP_FILE"

  grep -q "$SWAP_FILE" /etc/fstab || echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
  sysctl -q -p /etc/sysctl.d/99-swappiness.conf

  echo -e "\n${GREEN}✅ Swap wurde erfolgreich eingerichtet.${NC}"
  swapon --show | tail -n +2
}

function remove_swap() {
  require_root
  if swapon --show | grep -q "$SWAP_FILE"; then
    echo -e "${CYAN}🧹 Deaktiviere Swap...${NC}"
    swapoff "$SWAP_FILE"
  else
    echo -e "${YELLOW}⚠️ Kein aktiver Swap unter $SWAP_FILE gefunden.${NC}"
  fi
  echo -e "${RED}🗑️ Entferne Swap-Datei...${NC}"
  rm -f "$SWAP_FILE"
  sed -i "\|$SWAP_FILE|d" /etc/fstab
  rm -f /etc/sysctl.d/99-swappiness.conf
  sysctl -q -w vm.swappiness=60 || true
  echo -e "${GREEN}✅ Swap wurde entfernt.${NC}"
}

function resize_swap() {
  require_root
  remove_swap
  read -erp "📏 Neue Swap-Größe (z. B. 2G, 8G): " NEW_SIZE
  [[ -z "$NEW_SIZE" ]] && echo -e "${RED}❌ Keine Größe eingegeben.${NC}" && return
  echo -e "${CYAN}🔧 Erstelle neuen Swap mit $NEW_SIZE...${NC}"
  fallocate -l "$NEW_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((${NEW_SIZE::-1} * 1024)) status=progress
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" > /dev/null
  swapon "$SWAP_FILE"
  grep -q "$SWAP_FILE" /etc/fstab || echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
  sysctl -q -p /etc/sysctl.d/99-swappiness.conf
  echo -e "${GREEN}✅ Swap wurde auf $NEW_SIZE geändert.${NC}"
  swapon --show | tail -n +2
}

function show_swap_usage() {
  echo -e "\n${MAGENTA}📊 Swap-Nutzung nach Prozess:${NC}\n"
  for pid in $(ls /proc | grep '^[0-9]'); do
    if [[ -r /proc/$pid/status ]]; then
      swap_kb=$(awk '/VmSwap/ {print $2}' /proc/$pid/status)
      [[ -n "$swap_kb" && "$swap_kb" -gt 0 ]] && \
        cmd=$(ps -p $pid -o comm=) && \
        echo -e "${YELLOW}${pid}${NC}: ${swap_kb} KB → ${CYAN}${cmd}${NC}"
    fi
  done | sort -k2 -n -r | head -n 15
  echo ""
  read -erp "🔁 ${CYAN}Zurück zum Menü? [Enter]${NC}"
  show_menu
}

show_menu
