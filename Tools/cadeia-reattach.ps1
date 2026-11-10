<#
=====================================================================
 cadeia-reattach.ps1 - constroi a cadeia de inputs a partir do PERFIL VIVO
=====================================================================
 Porque nao se copia uma cadeia feita a mao: a cadeia que estava em
 `Files\Temp\reattach_inputs_45.txt` foi derivada de um perfil que tem
 `Symbols=XAUUSD` (UM simbolo) e `AvoidHoursGMT=9` (UMA hora). O perfil
 vivo tem `Symbols` com os **15** simbolos e `AvoidHoursGMT=9,11,14,18,20,22`
 (seis horas). Aplicar aquela cadeia **colapsava o universo de 15 para 1** e
 desarmava cinco horas de bloqueio - e nenhum dos dois e erro visivel: o
 reattach aceita e o EA simplesmente deixa de operar nos outros 14.

 Aqui a cadeia e extraida do `.chr` VIVO, e a unica alteracao e a que o DONO
 mandou (D-174: `MinAIConfidence` 60.0 -> 45.0). Todo o resto - o universo,
 as horas de bloqueio, os filtros, o magic, o token - vai tal como esta.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\cadeia-reattach.ps1
   ... -Campo MinAIConfidence -Valor 45.0
   ... -Saida Files\Temp\reattach_inputs_45_v2.txt
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$ChartsDir = '',
  [string]$Fonte = 'chart01.chr',
  [string]$Campo = 'MinAIConfidence',
  [string]$Valor = '45.0',
  [string]$Saida = '',
  [string]$Root = ''
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
if ($ChartsDir -eq '') { $ChartsDir = Join-Path $Root 'Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071' }
if ($Saida -eq '') { $Saida = Join-Path $Root ("Files\Temp\reattach_inputs_" + $Campo + "_" + ($Valor -replace '\.', '') + "_v2.txt") }

$fonte = Join-Path $ChartsDir $Fonte
if (-not (Test-Path -LiteralPath $fonte)) { Write-Host "ERRO: fonte ausente: $fonte" -ForegroundColor Red; exit 1 }

$t = [System.IO.File]::ReadAllText($fonte, [System.Text.Encoding]::Unicode)
$m = [regex]::Match($t, '(?s)<inputs>(.*?)</inputs>')
if (-not $m.Success) { Write-Host "ERRO: sem bloco <inputs> em $fonte" -ForegroundColor Red; exit 1 }

$pares = @()
$antes = $null
$depois = $null
foreach ($l in ($m.Groups[1].Value -split "`r?`n")) {
  $l = $l.Trim()
  if ($l -eq '') { continue }
  if ($l -like '===*') { continue }              # cabecalho de grupo: nao e input
  if ($l -notmatch '=') { continue }
  $i = $l.IndexOf('=')
  $nome = $l.Substring(0, $i).Trim()
  $val = $l.Substring($i + 1).Trim()
  if ($nome -eq $Campo) { $antes = $val; $val = $Valor; $depois = $val }
  $pares += ($nome + '=' + $val)
}

if ($antes -eq $null) { Write-Host "ERRO: o campo '$Campo' nao existe no perfil" -ForegroundColor Red; exit 1 }

[System.IO.File]::WriteAllText($Saida, ($pares -join ','), (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("cadeia escrita : {0}" -f $Saida)
Write-Host ("pares          : {0}" -f $pares.Count)
Write-Host ("alteracao      : {0}: {1} -> {2}" -f $Campo, $antes, $depois)
$sym = ($pares | Where-Object { $_ -like 'Symbols=*' }) -replace '^Symbols=', ''
Write-Host ("universo       : {0} simbolo(s)" -f (@($sym -split ',').Count))
$av = ($pares | Where-Object { $_ -like 'AvoidHoursGMT=*' }) -replace '^AvoidHoursGMT=', ''
Write-Host ("horas de veto  : {0}" -f $av)
Write-Host ''
Write-Host 'VERIFICAR AGORA:  powershell -NoProfile -ExecutionPolicy Bypass -File Tools\verificar-cadeia.ps1 -Cadeia <este ficheiro>'
exit 0
