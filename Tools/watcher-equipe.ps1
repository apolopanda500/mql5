# watcher-equipe.ps1 - monitor continuo do canal + repos + espelho.
# Roda ate ser parado (Ctrl+C / kill). Imprime so quando algo muda.
param(
  [int]$IntervaloSeg = 45,
  [int]$HeartbeatMin = 5
)

$root = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
$equipe = Join-Path $root "Experts\XAU_AI_PRO\EQUIPE"
$audit = Join-Path $root "Tools\equipe-audit.ps1"
$sync = Join-Path $equipe "tools\sync-agent.ps1"

$ultimoEstado = ""
$ultimoHeartbeat = Get-Date
$iter = 0

while ($true) {
  $iter++
  $agora = Get-Date -Format 'HH:mm:ss'
  try {
    Push-Location $root
    $pai = (git status --porcelain 2>$null | Measure-Object -Line).Lines
    $paiLog = (git log -1 --format='%h %s' 2>$null)
    Pop-Location
  } catch { $pai = -1; $paiLog = '?' }

  $app = Join-Path $root "Files\XAU_AI_PRO"
  try {
    Push-Location $app
    $aninhado = (git status --porcelain 2>$null | Measure-Object -Line).Lines
    $aninhadoLog = (git log -1 --format='%h %s' 2>$null)
    Pop-Location
  } catch { $aninhado = -1; $aninhadoLog = '?' }

  $auditOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $audit verify 2>&1 | Out-String
  $auditRes = if ($auditOut -match 'RESULTADO: ok') { 'OK' } elseif ($auditOut -match 'RESULTADO: (\d+)') { "$($Matches[1]) prob" } else { '?' }

  $checkOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $sync check 2>&1 | Out-String
  $checkRes = if ($checkOut -match 'OK - sem problemas') { '0' } elseif ($checkOut -match '(\d+) problema') { "$($Matches[1])" } else { '?' }

  $estado = "$pai|$paiLog|$aninhado|$aninhadoLog|$auditRes|$checkRes"
  if ($estado -ne $ultimoEstado) {
    Write-Host "[$agora] MUDOU | pai=$pai ($paiLog) | app=$aninhado ($aninhadoLog) | audit=$auditRes | canal=$checkRes prob" -ForegroundColor Cyan
    # mostrar ultima linha de cada inbox (resumo)
    foreach ($f in @('INBOX_AGENTE_1.md','INBOX_AGENTE_2.md','INBOX_AGENTE_3.md')) {
      $p = Join-Path $equipe $f
      if (Test-Path $p) {
        $ult = (Get-Content $p -Encoding UTF8 -Tail 3 | Where-Object { $_.Trim() -ne '' } | Select-Object -Last 1)
        if ($ult) { Write-Host "   $f :: $($ult.Trim().Substring(0,[Math]::Min(120,$ult.Trim().Length)))" -ForegroundColor DarkGray }
      }
    }
    $ultimoEstado = $estado
  } elseif ((Get-Date) - $ultimoHeartbeat -gt [TimeSpan]::FromMinutes($HeartbeatMin)) {
    Write-Host "[$agora] heartbeat | pai=$pai app=$aninhado audit=$auditRes canal=$checkRes prob | sem mudancas" -ForegroundColor DarkGray
    $ultimoHeartbeat = Get-Date
  }

  Start-Sleep -Seconds $IntervaloSeg
}