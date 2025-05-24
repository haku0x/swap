Add-Type -AssemblyName System.Windows.Forms

# GUI-Fenster
$form = New-Object System.Windows.Forms.Form
$form.Text = "🧠 Pagefile-Manager"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Beschriftung
$label = New-Object System.Windows.Forms.Label
$label.Text = "Minimale Größe (MB):"
$label.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($label)

$minInput = New-Object System.Windows.Forms.TextBox
$minInput.Location = New-Object System.Drawing.Point(150, 20)
$form.Controls.Add($minInput)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Maximale Größe (MB):"
$label2.Location = New-Object System.Drawing.Point(20, 60)
$form.Controls.Add($label2)

$maxInput = New-Object System.Windows.Forms.TextBox
$maxInput.Location = New-Object System.Drawing.Point(150, 60)
$form.Controls.Add($maxInput)

# Button: Setzen
$setBtn = New-Object System.Windows.Forms.Button
$setBtn.Text = "Pagefile setzen"
$setBtn.Location = New-Object System.Drawing.Point(20, 100)
$setBtn.Add_Click({
    $min = [int]$minInput.Text
    $max = [int]$maxInput.Text
    wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False | Out-Null
    wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=$min,MaximumSize=$max | Out-Null
    [System.Windows.Forms.MessageBox]::Show("✅ Pagefile wurde gesetzt.")
})
$form.Controls.Add($setBtn)

# Button: Automatik
$autoBtn = New-Object System.Windows.Forms.Button
$autoBtn.Text = "Automatische Verwaltung"
$autoBtn.Location = New-Object System.Drawing.Point(150, 100)
$autoBtn.Add_Click({
    wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True | Out-Null
    [System.Windows.Forms.MessageBox]::Show("🔁 Automatische Verwaltung aktiviert.")
})
$form.Controls.Add($autoBtn)

# Fenster anzeigen
$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
