# Interaktiver Pagefile-Manager für Windows 10/11
# Autor: haku0x
# Lizenz: MIT

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║       🧠 Interaktiver Pagefile-Manager     ║" -ForegroundColor Magenta
    Write-Host "║             für Windows 10/11             ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

function Show-CurrentSettings {
    $pagefile = Get-WmiObject -Query "SELECT * FROM Win32_PageFileSetting"
    if ($pagefile) {
        Write-Host "`n📄 Aktuelle Pagefile-Konfiguration:" -ForegroundColor Green
        $pagefile | Format-Table Name, InitialSize, MaximumSize
    } else {
        Write-Host "⚠️ Kein Pagefile konfiguriert oder Zugriff verweigert." -ForegroundColor Yellow
    }
}

function Set-ManualPagefile {
    param (
        [int]$InitialSize,
        [int]$MaxSize
    )
    Write-Host "⚙️ Setze Pagefile manuell auf ${InitialSize}MB bis ${MaxSize}MB..." -ForegroundColor Cyan
    wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False | Out-Null
    wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=$InitialSize,MaximumSize=$MaxSize | Out-Null
    Write-Host "✅ Pagefile wurde angepasst." -ForegroundColor Green
}

function Enable-AutomaticPagefile {
    Write-Host "🔁 Setze Pagefile-Verwaltung zurück auf 'automatisch'..." -ForegroundColor Cyan
    wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True | Out-Null
    Write-Host "✅ Automatische Verwaltung aktiviert." -ForegroundColor Green
}

function Remove-Pagefile {
    Write-Host "🗑️ Entferne benutzerdefinierten Pagefile-Eintrag..." -ForegroundColor Cyan
    Enable-AutomaticPagefile
}

function Show-Menu {
    Show-Header
    Show-CurrentSettings
    Write-Host ""
    Write-Host "[1] ➕ Pagefile manuell konfigurieren" -ForegroundColor Yellow
    Write-Host "[2] 🔁 Automatische Verwaltung aktivieren" -ForegroundColor Yellow
    Write-Host "[3] ❌ Pagefile entfernen (nur benutzerdefiniert)" -ForegroundColor Yellow
    Write-Host "[4] 🚪 Beenden" -ForegroundColor Yellow
    Write-Host ""
    $choice = Read-Host "🔢 Auswahl [1-4]"
    switch ($choice) {
        "1" {
            $initial = Read-Host "📦 Minimale Größe in MB (z.B. 2048)"
            $max = Read-Host "📏 Maximale Größe in MB (z.B. 8192)"
            Set-ManualPagefile -InitialSize $initial -MaxSize $max
        }
        "2" { Enable-AutomaticPagefile }
        "3" { Remove-Pagefile }
        "4" {
            Write-Host "`n👋 Beende Skript..." -ForegroundColor Green
            exit
        }
        default {
            Write-Host "❗ Ungültige Eingabe." -ForegroundColor Red
        }
    }
    Pause
    Show-Menu
}

# Starte Menü
Show-Menu
