Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === GUI Setup ===
$form = New-Object Windows.Forms.Form
$form.Text = "🧠 Interaktiver Pagefile-Manager"
$form.Size = New-Object Drawing.Size(420, 300)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.TopMost = $true

$font = New-Object Drawing.Font("Segoe UI", 9)

# === Labels & Inputs ===
$labelMin = New-Object Windows.Forms.Label
$labelMin.Text = "Minimale Größe (MB):"
$labelMin.Location = '20,30'
$labelMin.Size = '150,20'
$labelMin.Font = $font
$form.Controls.Add($labelMin)

$textMin = New-Object Windows.Forms.TextBox
$textMin.Location = '180,28'
$textMin.Size = '180,24'
$textMin.Font = $font
$form.Controls.Add($textMin)

$labelMax = New-Object Windows.Forms.Label
$labelMax.Text = "Maximale Größe (MB):"
$labelMax.Location = '20,70'
$labelMax.Size = '150,20'
$labelMax.Font = $font
$form.Controls.Add($labelMax)

$textMax = New-Object Windows.Forms.TextBox
$textMax.Location = '180,68'
$textMax.Size = '180,24'
$textMax.Font = $font
$form.Controls.Add($textMax)

# === Set Button ===
$btnSet = New-Object Windows.Forms.Button
$btnSet.Text = "📝 Pagefile setzen"
$btnSet.Location = '20,120'
$btnSet.Size = '160,30'
$btnSet.Font = $font
$btnSet.Add_Click({
    try {
        $min = [int]$textMin.Text
        $max = [int]$textMax.Text
        wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False | Out-Null
        wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=$min,MaximumSize=$max | Out-Null
        [Windows.Forms.MessageBox]::Show("✅ Pagefile wurde erfolgreich gesetzt.", "Erfolg")
    } catch {
        [Windows.Forms.MessageBox]::Show("❌ Fehler beim Setzen des Pagefiles.", "Fehler")
    }
})
$form.Controls.Add($btnSet)

# === Auto Button ===
$btnAuto = New-Object Windows.Forms.Button
$btnAuto.Text = "🔁 Automatische Verwaltung"
$btnAuto.Location = '200,120'
$btnAuto.Size = '160,30'
$btnAuto.Font = $font
$btnAuto.Add_Click({
    try {
        wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True | Out-Null
        [Windows.Forms.MessageBox]::Show("✅ Automatische Verwaltung aktiviert.", "Aktiviert")
    } catch {
        [Windows.Forms.MessageBox]::Show("❌ Fehler beim Aktivieren der Verwaltung.", "Fehler")
    }
})
$form.Controls.Add($btnAuto)

# === Info Label ===
$info = New-Object Windows.Forms.Label
$info.Text = "ℹ️ Änderungen erfordern ggf. einen Neustart."
$info.Location = '20,180'
$info.Size = '360,20'
$info.Font = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Italic)
$form.Controls.Add($info)

# === Run ===
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
