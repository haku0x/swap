# 🧠 Interaktiver Swap- & Pagefile-Manager für Debian 12 & Windows 10/11

Ein einfach zu bedienendes, interaktives Tool zur Verwaltung von **Swap (Linux)** und **Pagefile (Windows)**.  
Ideal für Server, virtuelle Maschinen oder Desktops, die flexible Speicherverwaltung benötigen.

---

## 🚀 Funktionen

### 🐧 Debian 12
- ➕ Swap-Datei erstellen (benutzerdefinierte Größe)
- 🔁 Swap-Größe ändern
- ✅ Swap entfernen
- 🛡️ Automatische Fehlerbehandlung
- 📦 Persistente Einbindung über `/etc/fstab`
- 🧠 Swappiness auf `10` gesetzt

### 🪟 Windows 10/11
- ➕ Pagefile manuell konfigurieren
- 🔁 Automatische Verwaltung aktivieren/deaktivieren
- ✅ Benutzerdefinierten Pagefile-Eintrag entfernen
- 💬 Interaktive PowerShell-Benutzeroberfläche

---

## 🛠️ Anforderungen

| System   | Anforderungen                              |
|----------|--------------------------------------------|
| Debian   | Debian 12, Root-Rechte (`sudo`)            |
| Windows  | Windows 10/11, PowerShell als Administrator|

---

## ▶️ Schnellstart

🪟 Windows (per PowerShell ausführen)
```powershell
irm https://raw.githubusercontent.com/haku0x/swap/main/pagefile_manager.ps1 | iex

### 🐧 Debian (per Bash ausführen)

```bash
bash <(curl -s https://raw.githubusercontent.com/haku0x/swap/main/setup_swap.sh)


