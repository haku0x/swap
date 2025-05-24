# 🧠 Interaktiver Swap- & Pagefile-Manager für Debian 12 & Windows 10/11

Ein benutzerfreundliches, interaktives Tool zur Verwaltung von **Swap (Linux)** und **Pagefile (Windows)**.
Perfekt geeignet für Server, virtuelle Maschinen oder Desktops, die eine flexible Speicherverwaltung benötigen.

---

## 🚀 Funktionen

### 🐧 Für Debian 12

* ➕ Swap-Datei erstellen (benutzerdefinierte Größe)
* 🔁 Bestehende Swap-Größe anpassen
* ✅ Swap-Datei sicher entfernen
* 🛡️ Eingebaute Fehlerbehandlung
* 📆 Automatische Einbindung über `/etc/fstab`
* 🧠 Swappiness automatisch auf `10` gesetzt

### 🪟 Für Windows 10/11

* ➕ Pagefile manuell festlegen (Initial-/Maximalgröße)
* 🔁 Automatische Speicherverwaltung aktivieren oder deaktivieren
* ✅ Benutzerdefinierten Pagefile-Eintrag entfernen
* 💬 Interaktive PowerShell-Benutzeroberfläche

---

## 🛠️ Anforderungen

| Betriebssystem | Voraussetzungen                            |
| -------------- | ------------------------------------------ |
| Debian         | Debian 12, Root-Rechte (`sudo`)            |
| Windows        | Windows 10/11, PowerShell mit Adminrechten |

---

## ▶️ Schnellstart

### 🪟 Windows (Ausführung per PowerShell)  
⚠️ *Hinweis: Die PowerShell-Version ist derzeit nicht funktionsfähig und wird überarbeitet.*

```powershell
irm https://raw.githubusercontent.com/haku0x/swap/main/pagefile_manager.ps1 | iex
```

### 🐧 Debian (per Bash ausführen)

```powershell
bash <(curl -s https://raw.githubusercontent.com/haku0x/swap/main/setup_swap.sh)
```

## ⚠️ Hinweise

* Unter Windows muss PowerShell **als Administrator** gestartet werden.
* Unter Debian muss das Skript mit `sudo` ausgeführt werden, wenn du kein Root bist.
* Pagefile-Änderungen unter Windows können einen Neustart erfordern.

---

## 🧑‍💻 Lizenz

MIT License – freie Nutzung, Veränderung und Weitergabe erlaubt.
Autor: [haku0x](https://github.com/haku0x)

