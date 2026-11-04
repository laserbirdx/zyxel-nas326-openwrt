param(
    [Parameter(Mandatory = $true)][string]$Command,
    [string]$Port = "COM48",
    [int]$WaitMs = 3000
)

$sp = New-Object System.IO.Ports.SerialPort $Port, 115200, "None", 8, "One"
$sp.ReadTimeout = 5000
$sp.NewLine = "`r`n"
$sp.Open()
Start-Sleep -Milliseconds 300
if ($sp.BytesToRead -gt 0) { $null = $sp.ReadExisting() }

$sp.WriteLine($Command)
Start-Sleep -Milliseconds $WaitMs

$output = ""
while ($sp.BytesToRead -gt 0) {
    $output += $sp.ReadExisting()
    Start-Sleep -Milliseconds 200
}
Write-Output $output
$sp.Close()
