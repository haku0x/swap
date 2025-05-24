set -e

SWAP_FILE="/swapfile"

function show_menu() {
  echo "\n🚀 Swap-Installer für Debian 12"
  echo "=============================="
  echo "1) Swap erstellen"
  echo "2) Swap entfernen"
  echo "3) Beenden"
  echo -n "\nBitte Auswahl eingeben [1-3]: "
  read CHOICE
  case $CHOICE in
    1) create_swap;;
    2) remove_swap;;
    3) echo "Beende..."; exit 0;;
    *) echo "Ungültige Eingabe."; show_menu;;
  esac
}

function create_swap() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Bitte als root oder mit sudo starten!"
    exit 1
  fi

  if swapon --show | grep -q "$SWAP_FILE"; then
    echo "✅ Swap ist bereits aktiv unter $SWAP_FILE"
    exit 0
  fi

  echo -n "📦 Gib die gewünschte Swap-Größe ein (z. B. 1G, 2G, 4G): "
  read SWAP_SIZE

  echo "📁 Erstelle Swap-Datei ($SWAP_SIZE)..."
  sudo fallocate -l $SWAP_SIZE $SWAP_FILE || sudo dd if=/dev/zero of=$SWAP_FILE bs=1M count=$((${SWAP_SIZE::-1} * 1024)) status=progress

  echo "🔐 Setze Berechtigungen..."
  sudo chmod 600 $SWAP_FILE

  echo "🔄 Initialisiere Swap..."
  sudo mkswap $SWAP_FILE

  echo "✅ Aktiviere Swap..."
  sudo swapon $SWAP_FILE

  if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
  fi

  echo "⚙️ Setze Swappiness auf 10..."
  echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
  sudo sysctl -p /etc/sysctl.d/99-swappiness.conf

  free -h
  swapon --show

  echo -e "\n✅ Swap erfolgreich eingerichtet!"
}

function remove_swap() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Bitte als root oder mit sudo starten!"
    exit 1
  fi

  if ! swapon --show | grep -q "$SWAP_FILE"; then
    echo "⚠️ Kein aktives Swap unter $SWAP_FILE gefunden."
  else
    echo "🧹 Deaktiviere Swap..."
    sudo swapoff $SWAP_FILE
  fi

  echo "🗑️ Entferne Swap-Datei..."
  sudo rm -f $SWAP_FILE

  echo "🧼 Entferne Eintrag aus /etc/fstab..."
  sudo sed -i '\|/swapfile|d' /etc/fstab

  echo "⚙️ Entferne Swappiness-Konfiguration..."
  sudo rm -f /etc/sysctl.d/99-swappiness.conf
  sudo sysctl -w vm.swappiness=60 >/dev/null

  echo "✅ Swap wurde vollständig entfernt."
}

show_menu
