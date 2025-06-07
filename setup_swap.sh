#!/bin/bash
# 🚀 Interaktiver Swap-Manager für Debian 12
# Autor: haku0x  Lizenz: MIT

set -euo pipefail
trap 'handle_error' ERR

# === Farben und Stile ===
RED='\033[1;91m'; GREEN='\033[1;92m'; YELLOW='\033[1;93m'
CYAN='\033[1;96m'; MAGENTA='\033[1;95m'; BLUE='\033[1;94m'
BOLD='\033[1m'; NC='\033[0m'

# === Konstanten ===
SWAP_FILE="/swapfile"
MIN_SWAP_SIZE="256M"
MAX_SWAP_SIZE="64G"
DEFAULT_SWAPPINESS=10

# === Hilfsfunktionen ===
function handle_error() {
    local line_number=$1
    echo -e "\n${RED}❌ Ein Fehler ist in Zeile $line_number aufgetreten.${NC}"
    echo -e "${YELLOW}ℹ️  Bitte überprüfen Sie die Berechtigungen und Systemressourcen.${NC}"
    exit 1
}

function check_system_requirements() {
    if ! command -v fallocate &> /dev/null; then
        echo -e "${YELLOW}⚠️  fallocate nicht gefunden. Verwende dd als Alternative.${NC}"
    fi
    if ! command -v mkswap &> /dev/null; then
        echo -e "${RED}❌ mkswap nicht gefunden. Bitte installieren Sie util-linux.${NC}"
        exit 1
    fi
}

function validate_swap_size() {
    local size=$1
    if [[ ! $size =~ ^[0-9]+[MG]$ ]]; then
        echo -e "${RED}❌ Ungültiges Format. Verwenden Sie z.B. 1G oder 512M${NC}"
        return 1
    fi
    local num=${size%[MG]}
    local unit=${size: -1}
    if [[ $unit == "M" && $num -lt 256 ]]; then
        echo -e "${RED}❌ Minimale Swap-Größe ist 256M${NC}"
        return 1
    fi
    if [[ $unit == "G" && $num -gt 64 ]]; then
        echo -e "${RED}❌ Maximale Swap-Größe ist 64G${NC}"
        return 1
    fi
    return 0
}

function header() {
    clear
    echo -e "\n${MAGENTA}╔════════════════════════════════════════════════════╗"
    echo -e "║           🧠 Interaktiver Swap-Manager              ║"
    echo -e "║                für Debian 12                        ║"
    echo -e "╚════════════════════════════════════════════════════╝${NC}\n"
    
    # System-Informationen anzeigen
    echo -e "${BLUE}📊 System-Informationen:${NC}"
    echo -e "  • RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo -e "  • CPU: $(nproc) Kerne"
    echo -e "  • OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)\n"
    
    if swapon --noheadings --show | grep -q "$SWAP_FILE"; then
        echo -e "${GREEN}✅ Aktiver Swap:${NC}"
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
    echo -e "${BOLD}${CYAN}Hauptmenü:${NC}\n"
    echo -e "${YELLOW}[1]${NC} ➕ Swap erstellen"
    echo -e "${YELLOW}[2]${NC} ❌ Swap entfernen"
    echo -e "${YELLOW}[3]${NC} 🔁 Swap-Größe ändern"
    echo -e "${YELLOW}[4]${NC} 📊 Swap-Nutzung nach Prozessen"
    echo -e "${YELLOW}[5]${NC} 🔧 Swappiness-Wert anzeigen/ändern"
    echo -e "${YELLOW}[6]${NC} 📂 Aktive Swap-Geräte anzeigen"
    echo -e "${YELLOW}[7]${NC} 📴 Swap dauerhaft deaktivieren"
    echo -e "${YELLOW}[8]${NC} ℹ️  Hilfe anzeigen"
    echo -e "${YELLOW}[9]${NC} 🚪 Beenden"
    
    while true; do
        echo -ne "\n🔢 ${CYAN}Auswahl eingeben [1-9]: ${NC}"
        read -r CHOICE
        case $CHOICE in
            1) create_swap; break ;;
            2) remove_swap; break ;;
            3) resize_swap; break ;;
            4) show_swap_usage; break ;;
            5) configure_swappiness; break ;;
            6) list_all_swap; break ;;
            7) disable_swap_permanently; break ;;
            8) show_help; break ;;
            9) echo -e "\n👋 ${GREEN}Beende Skript...${NC}"; exit 0 ;;
            *) echo -e "\n${RED}❗ Ungültige Eingabe. Bitte erneut versuchen.${NC}" ;;
        esac
    done
    sleep 1
    show_menu
}

function create_swap() {
    require_root
    check_system_requirements
    
    if swapon --show | grep -q "$SWAP_FILE"; then
        echo -e "\n${YELLOW}⚠️  Swap existiert bereits unter $SWAP_FILE${NC}"
        read -erp "Möchten Sie den bestehenden Swap überschreiben? [j/N]: " confirm
        [[ ! $confirm =~ ^[Jj]$ ]] && return
        remove_swap
    fi

    while true; do
        read -erp "📦 Gewünschte Swap-Größe (z.B. 1G, 2G): " SWAP_SIZE
        validate_swap_size "$SWAP_SIZE" && break
    done

    echo -e "${CYAN}📁 Erstelle Swap-Datei mit Größe $SWAP_SIZE...${NC}"
    if ! fallocate -l "$SWAP_SIZE" "$SWAP_FILE" 2>/dev/null; then
        echo -e "${YELLOW}ℹ️  Verwende dd als Alternative...${NC}"
        dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((${SWAP_SIZE::-1} * 1024)) status=progress
    fi

    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE" > /dev/null
    swapon "$SWAP_FILE"

    # Fstab-Eintrag nur hinzufügen, wenn nicht vorhanden
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    fi

    # Swappiness optimieren
    echo "vm.swappiness=$DEFAULT_SWAPPINESS" > /etc/sysctl.d/99-swappiness.conf
    sysctl -q -p /etc/sysctl.d/99-swappiness.conf

    echo -e "\n${GREEN}✅ Swap wurde erfolgreich eingerichtet:${NC}"
    swapon --show | tail -n +2
    echo -e "\n${YELLOW}ℹ️  Tipp: Überwachen Sie die Swap-Nutzung mit 'free -h'${NC}"
}

function remove_swap() {
    require_root
    echo -e "\n${CYAN}🔍 Überprüfe Swap-Status...${NC}"
    
    # Prüfe ob Swap aktiv ist
    if swapon --show | grep -q "$SWAP_FILE"; then
        echo -e "${YELLOW}⚠️  Deaktiviere aktiven Swap...${NC}"
        swapoff -v "$SWAP_FILE" || {
            echo -e "${RED}❌ Fehler beim Deaktivieren des Swaps.${NC}"
            echo -e "${YELLOW}ℹ️  Versuche erzwungenes Deaktivieren...${NC}"
            swapoff -a
        }
    else
        echo -e "${YELLOW}ℹ️  Kein aktiver Swap unter $SWAP_FILE gefunden.${NC}"
    fi

    # Entferne Swap-Datei
    if [[ -f "$SWAP_FILE" ]]; then
        echo -e "${CYAN}🗑️  Entferne Swap-Datei...${NC}"
        rm -f "$SWAP_FILE" || {
            echo -e "${RED}❌ Fehler beim Löschen der Swap-Datei.${NC}"
            echo -e "${YELLOW}ℹ️  Versuche mit erhöhten Rechten...${NC}"
            sudo rm -f "$SWAP_FILE"
        }
    fi

    # Entferne fstab-Eintrag
    if grep -q "$SWAP_FILE" /etc/fstab; then
        echo -e "${CYAN}📝 Entferne fstab-Eintrag...${NC}"
        sed -i "\|$SWAP_FILE|d" /etc/fstab
    fi

    # Entferne Swappiness-Konfiguration
    if [[ -f /etc/sysctl.d/99-swappiness.conf ]]; then
        echo -e "${CYAN}⚙️  Entferne Swappiness-Konfiguration...${NC}"
        rm -f /etc/sysctl.d/99-swappiness.conf
        sysctl -q -w vm.swappiness=60 || true
    fi

    # Überprüfe ob alles entfernt wurde
    if ! swapon --show | grep -q "$SWAP_FILE" && [[ ! -f "$SWAP_FILE" ]]; then
        echo -e "\n${GREEN}✅ Swap wurde erfolgreich entfernt.${NC}"
    else
        echo -e "\n${RED}⚠️  Swap konnte nicht vollständig entfernt werden.${NC}"
        echo -e "${YELLOW}ℹ️  Bitte überprüfen Sie manuell:${NC}"
        echo "1. swapon --show"
        echo "2. ls -l $SWAP_FILE"
        echo "3. cat /etc/fstab"
    fi
}

function resize_swap() {
    require_root
    echo -e "\n${CYAN}🔄 Swap-Größe ändern${NC}"
    
    # Prüfe ob Swap existiert
    if ! swapon --show | grep -q "$SWAP_FILE" && [[ ! -f "$SWAP_FILE" ]]; then
        echo -e "${YELLOW}ℹ️  Kein Swap gefunden. Erstelle neuen Swap...${NC}"
        create_swap
        return
    fi

    # Sichere aktuelle Swap-Größe
    CURRENT_SIZE=$(swapon --show | grep "$SWAP_FILE" | awk '{print $3}')
    echo -e "${CYAN}📊 Aktuelle Swap-Größe: ${YELLOW}$CURRENT_SIZE${NC}"

    # Frage nach neuer Größe
    while true; do
        read -erp "📦 Neue Swap-Größe eingeben (z.B. 1G, 2G): " NEW_SIZE
        validate_swap_size "$NEW_SIZE" && break
    done

    # Bestätigung
    echo -e "\n${YELLOW}⚠️  Achtung: Swap wird neu erstellt mit Größe $NEW_SIZE${NC}"
    read -erp "Möchten Sie fortfahren? [j/N]: " confirm
    [[ ! $confirm =~ ^[Jj]$ ]] && return

    # Entferne alten Swap
    echo -e "\n${CYAN}🧹 Entferne alten Swap...${NC}"
    remove_swap

    # Erstelle neuen Swap
    echo -e "\n${CYAN}📁 Erstelle neuen Swap mit Größe $NEW_SIZE...${NC}"
    if ! fallocate -l "$NEW_SIZE" "$SWAP_FILE" 2>/dev/null; then
        echo -e "${YELLOW}ℹ️  Verwende dd als Alternative...${NC}"
        dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((${NEW_SIZE::-1} * 1024)) status=progress
    fi

    # Setze Berechtigungen und aktiviere Swap
    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE" > /dev/null
    swapon "$SWAP_FILE"

    # Füge fstab-Eintrag hinzu
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    fi

    # Setze Swappiness
    echo "vm.swappiness=$DEFAULT_SWAPPINESS" > /etc/sysctl.d/99-swappiness.conf
    sysctl -q -p /etc/sysctl.d/99-swappiness.conf

    # Überprüfe Ergebnis
    if swapon --show | grep -q "$SWAP_FILE"; then
        echo -e "\n${GREEN}✅ Swap wurde erfolgreich auf $NEW_SIZE geändert:${NC}"
        swapon --show | tail -n +2
    else
        echo -e "\n${RED}❌ Fehler beim Ändern der Swap-Größe.${NC}"
        echo -e "${YELLOW}ℹ️  Bitte überprüfen Sie die Systemprotokolle.${NC}"
    fi
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

function configure_swappiness() {
  CURRENT=$(cat /proc/sys/vm/swappiness)
  echo -e "\n${CYAN}📉 Aktueller Swappiness-Wert: ${YELLOW}${CURRENT}${NC}"
  read -erp "✏️ Neuer Wert eingeben (0–100) oder [Enter] zum Beenden: " NEW
  if [[ "$NEW" =~ ^[0-9]+$ ]] && ((NEW >= 0 && NEW <= 100)); then
    echo "vm.swappiness=$NEW" > /etc/sysctl.d/99-swappiness.conf
    sysctl -q -p /etc/sysctl.d/99-swappiness.conf
    echo -e "${GREEN}✅ Neuer Wert gesetzt: $NEW${NC}"
  else
    echo -e "${YELLOW}ℹ️ Kein neuer Wert gesetzt.${NC}"
  fi
  read -erp "🔁 ${CYAN}Zurück zum Menü? [Enter]${NC}"
  show_menu
}

function list_all_swap() {
  echo -e "\n${MAGENTA}📂 Alle aktiven Swap-Geräte:${NC}"
  swapon --show --output=NAME,TYPE,SIZE,USED,PRIO
  echo ""
  read -erp "🔁 ${CYAN}Zurück zum Menü? [Enter]${NC}"
  show_menu
}

function disable_swap_permanently() {
  require_root
  echo -e "${RED}⚠️ Swap wird dauerhaft deaktiviert...${NC}"
  swapoff -a
  sed -i '/swap/d' /etc/fstab
  rm -f /etc/sysctl.d/99-swappiness.conf
  sysctl -q -w vm.swappiness=60 || true
  echo -e "${GREEN}✅ Swap deaktiviert & aus Autostart entfernt.${NC}"
  read -erp "🔁 ${CYAN}Zurück zum Menü? [Enter]${NC}"
  show_menu
}

function show_help() {
    clear
    echo -e "\n${MAGENTA}📚 Hilfe und Informationen:${NC}\n"
    echo -e "${BOLD}Was ist Swap?${NC}"
    echo "Swap ist ein Bereich auf der Festplatte, der als virtueller RAM verwendet wird."
    echo "Er wird aktiviert, wenn der physische RAM voll ist."
    echo -e "\n${BOLD}Empfehlungen:${NC}"
    echo "• Swap-Größe: 1-2x RAM für Desktop, 0.5-1x RAM für Server"
    echo "• Swappiness: 10-60 (niedriger = weniger Swap-Nutzung)"
    echo -e "\n${BOLD}Tipps:${NC}"
    echo "• Überwachen Sie die Swap-Nutzung regelmäßig"
    echo "• Bei SSD: Erwägen Sie eine niedrigere Swappiness"
    echo "• Bei HDD: Höhere Swappiness kann sinnvoll sein"
    
    read -erp "\n🔁 ${CYAN}Zurück zum Menü? [Enter]${NC}"
    show_menu
}

# Start des Skripts
check_system_requirements
show_menu
