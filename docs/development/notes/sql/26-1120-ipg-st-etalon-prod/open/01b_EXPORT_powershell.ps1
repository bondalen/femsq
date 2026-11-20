# C2 / D1.1 — выгрузка эталона структуры ИПГ (только чтение).
# Альтернатива BCP: PowerShell + SqlClient, Windows auth, без админ-прав.
# lastUpdated: 2026-11-20
# Запуск:
#   powershell -ExecutionPolicy Bypass -File 01b_EXPORT_powershell.ps1

$Server   = 'SPB-05-NV-SQL1'
$Database = 'FishEye'
$OutDir   = Join-Path $env:TEMP 'femsq_ipg_st_etalon_20261120'

$tables = @(
    'stType', 'st', 'stIpg', 'stIpgNm',
    'stCost', 'stCostNm', 'stRel', 'stNet', 'stNetPn',
    'ipg', 'ipgCh', 'ipgPn', 'ipgStPn', 'ipgSh',
    'stIpgOutLimPn_2606'
)

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "=== Export etalon to $OutDir ==="

$cs = "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True"
$conn = New-Object System.Data.SqlClient.SqlConnection $cs
$conn.Open()

foreach ($t in $tables) {
    $outFile = Join-Path $OutDir "$t.tsv"
    Write-Host "--- $t ---"
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT * FROM ags.[$t]"
        $cmd.CommandTimeout = 0
        $rdr = $cmd.ExecuteReader()
        $sw = New-Object System.IO.StreamWriter($outFile, $false, [System.Text.Encoding]::UTF8)
        $fieldCount = $rdr.FieldCount
        while ($rdr.Read()) {
            $vals = for ($i = 0; $i -lt $fieldCount; $i++) {
                if ($rdr.IsDBNull($i)) { '' }
                else {
                    $v = $rdr.GetValue($i)
                    if ($v -is [datetime]) { $v.ToString('yyyy-MM-dd HH:mm:ss.fff') }
                    else { [string]$v }
                }
            }
            $sw.WriteLine(($vals -join "`t"))
        }
        $sw.Close()
        $rdr.Close()
        Write-Host "OK $t -> $outFile"
    }
    catch {
        Write-Host "WARN $t : $($_.Exception.Message)"
        "WARN: $t not exported: $($_.Exception.Message)" | Set-Content -Path (Join-Path $OutDir "$t.WARN.txt") -Encoding UTF8
    }
}

$conn.Close()
Write-Host "=== DONE ==="
Get-ChildItem $OutDir | Select-Object Name, Length
