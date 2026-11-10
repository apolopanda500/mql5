<#
=====================================================================
 verificar-cadeia.ps1 - pre-flight do reattach: a cadeia bate com o perfil?
=====================================================================
 Compara, par a par, a cadeia de inputs (`Files\Temp\reattach_inputs_45.txt`)
 com o bloco <inputs> do `.chr` vivo, e diz EXACTAMENTE o que muda.

 Porque existe: um reattach com lista parcial repõe os restantes inputs nos
 DEFAULTS COMPILADOS - e os defaults compilados sao o oposto do perfil vivo
 em 13 campos (EnableStoplessEntry=true, AllowTradeWithoutAI=true,
 MaxDrawdownPercent=50.0, RiskPercent=1.0, 4 filtros=false, ...). Um
 reattach mal feito nao da erro nenhum: e um reattach que desliga quatro
 filtros de risco e volta a permitir entradas sem stop.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\verificar-cadeia.ps1
   ... -Cadeia Files\Temp\reattach_inputs_45.txt
   ... -ChartsDir <pasta dos .chr>
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$Cadeia = '',
  [string]$ChartsDir = '',
  [string[]]$EsperadoAlterado = @('MinAIConfidence')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ($Cadeia -eq '') { $Cadeia = Join-Path $root 'Files\Temp\reattach_inputs_45.txt' }
if ($ChartsDir -eq '') { $ChartsDir = Join-Path $root 'Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071' }

# --- a cadeia (separada por virgulas) ---
$txt = [System.IO.File]::ReadAllText($Cadeia, [System.Text.Encoding]::UTF8)
$mapa = @{}
foreach ($p in ($txt -split ',')) {
  $p = $p.Trim()
  if ($p -eq '' -or $p -notmatch '=') { continue }
  $i = $p.IndexOf('=')
  $mapa[$p.Substring(0, $i).Trim()] = $p.Substring($i + 1).Trim()
}

# --- o perfil vivo (uma linha por par) ---
$perfil = @{}
$divergentes = @()
foreach ($f in @(Get-ChildItem -LiteralPath $ChartsDir -Filter '*.chr' -ErrorAction SilentlyContinue | Sort-Object Name)) {
  $t = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::Unicode)
  $m = [regex]::Match($t, '(?s)<inputs>(.*?)</inputs>')
  if (-not $m.Success) { continue }
  $bloco = @{}
  foreach ($l in ($m.Groups[1].Value -split "`r?`n")) {
    $l = $l.Trim()
    if ($l -eq '' -or $l -like '===*' -or $l -notmatch '=') { continue }
    $i = $l.IndexOf('=')
    $bloco[$l.Substring(0, $i).Trim()] = $l.Substring($i + 1).Trim()
  }
  $dif = @()
  foreach ($k in $bloco.Keys) {
    if (-not $mapa.ContainsKey($k)) { $dif += ('FALTA ' + $k); continue }
    if ($mapa[$k] -ne $bloco[$k]) {
      # O `expert_parameters` e separado por VIRGULAS: um valor com virgulas
      # (Symbols com 15 simbolos, AvoidHoursGMT com 6 horas) TRUNCA chega
      # inteiro ao MT5. A cadeia foi feita a partir de um split por virgulas,
      # por isso a diferenca aparece exatamente nesses campos.
      $marca = ''
      if ($bloco[$k] -match ',' -or $mapa[$k] -match ',') { $marca = '  <== TRUNCADO PELO FORMATO A VIRGULA' }
      $dif += ('MUDA ' + $k + ': ' + $bloco[$k] + ' -> ' + $mapa[$k] + $marca)
    }
  }
  foreach ($k in $mapa.Keys) { if (-not $bloco.ContainsKey($k)) { $dif += ('EXTRA ' + $k + '=' + $mapa[$k]) } }
  $status = if ($dif.Count -eq 0) { 'IDENTICO' } else { ($dif -join ' | ') }
  if ($dif.Count -gt 0) { $divergentes += $f.Name }
  Write-Host ("{0,-14} {1}" -f $f.Name, $status)
}

Write-Host ''
Write-Host ("cadeia   : {0} pares" -f $mapa.Count)
Write-Host ("esperado mudar: {0}" -f ($EsperadoAlterado -join ', '))
if ($divergentes.Count -eq 0) {
  Write-Host "RESULTADO: a cadeia bate com TODOS os perfis vivos." -ForegroundColor Green
  exit 0
}
Write-Host ("RESULTADO: {0} perfis divergem da cadeia. NAO reattachar sem resolver." -f $divergentes.Count) -ForegroundColor Red
exit 1
