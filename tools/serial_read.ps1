param(
    [string]$Port = "COM48",
    [int]$WaitMs = 10000
)

$sp = New-Object System.IO.Ports.SerialPort $Port, 115200, "None", 8, "One"
$sp.ReadTimeout = 5000
$sp.Open()
Start-Sleep -Milliseconds $WaitMs

$output = ""
while ($sp.BytesToRead -gt 0) {
    $output += $sp.ReadExisting()
    Start-Sleep -Milliseconds 200
}
if ($output.Length -eq 0) {
    $sp.Write("`r`n")
    Start-Sleep -Milliseconds 2000
    while ($sp.BytesToRead -gt 0) {
        $output += $sp.ReadExisting()
        Start-Sleep -Milliseconds 200
    }
}
Write-Output $output
$sp.Close()
