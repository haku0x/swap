# 🧠 Interaktiver Swap-Manager für Debian 12

Ein einfach zu bedienendes Bash-Skript zur Verwaltung von Swap auf Debian 12-Systemen. Ideal für Server, VMs oder Desktops, die flexible Swap-Verwaltung benötigen.

---

## 🚀 Funktionen

- ➕ Swap-Datei erstellen (benutzerdefinierte Größe)
- 🔁 Swap-Größe ändern
- ✅ Swap entfernen
- 🛡️ Automatische Fehlerbehandlung
- 👀 Übersichtliche, moderne TUI (Text User Interface)
- 📦 Persistente Einbindung über `/etc/fstab`
- 🧠 Swappiness automatisch auf 10 gesetzt

---

## 🛠️ Anforderungen

- Debian 12
- Root-Zugriff (`sudo`)

---

## 🧪 Installation & Nutzung

### 🔽 Klonen

```bash
bash <(curl -s https://raw.githubusercontent.com/haku0x/swap/main/setup_swap.sh)
