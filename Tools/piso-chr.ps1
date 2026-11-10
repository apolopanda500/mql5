<#
=====================================================================
 piso-chr.ps1 - mudar um input nos .chr VIVOS, de forma deterministica
=====================================================================
 PORQUE ESTA VIA E A CORRETA (medido em 10/11/2026 17:00)
 ------------------------------------------------------
 O `chart_add_expert` aceita `expert_parameters` como uma string
 `"Nome=Valor,Nome2=Valor2"` - **separada por virgulas**
 (`Experts\XAU_AI_PRO\Docs\GUIA_OPERACIONAL_MT5_ASSISTANT.md:231`).

 Mas ha inputs cujo VALOR contem virgulas:
   Symbols = XAUUSD,USDCLP,USDCOP,... (15 simbolos)
   AvoidHoursGMT = 9,11,14,18,20,22 (6 horas)
 Nesses, a virgula e o separador: o MT5 le `Symbols=XAUUSD` e o resto
 fica como lixo. **Uma cadeia com 323 pares truncaria o universo de 15
 para 1** e desarmaria 5 das 6 horas de veto - sem um unico erro.

 O `.chr` tem uma linha por input (`Nome=Valor`), **sem separador**:
 ai qualquer valor, com virgulas ou nao, sobrevive intacto. E o MT5 le o
 `.chr` ao abrir o grafico. Logo a via segura e:
   1. os 15 `.chr` gravos com o valor novo (uma linha cada);
   2. abrir/reanexar os graficos SEM `expert_parameters`.

 E seguro porque o ALFA acabou de alinhar os DEFAULTS COMPILADOS com o
 perfil vivo (D-175): reanexar sem `expert_parameters` passa a repor
 exatamente os valores certos.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\piso-chr.ps1 -Campo MinAIConfidence -Valor 45.0
   ... -DryRun     (so mostra o que ia mudar)
   ... -Reverter   (volta ao valor anterior, a partir do backup)
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$Campo = 'MinAIConfidence',
  [string]$Valor = '45.0',
  [string]$ChartsDir = '',
  [string]$Root = '',
  [switch]$DryRun,
  [switch]$Reverter
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
if ($ChartsDir -eq '') { $ChartsDir = Join-Path $Root 'Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071' }
$backupDir = Join-Path $Root 'Files\Backup\chr_piso'

if (-not (Test-Path -LiteralPath $ChartsDir)) { Write-Host "ERRO: sem $ChartsDir" -ForegroundColor Red; exit 1 }

$ficheiros = @(Get-ChildItem -LiteralPath $ChartsDir -Filter '*.chr' -ErrorAction SilentlyContinue | Sort-Object Name)
if ($ficheiros.Count -eq 0) { Write-Host 'ERRO: nenhum .chr encontrado' -ForegroundColor Red; exit 1 }

if ($Reverter) {
  $bks = @(Get-ChildItem -LiteralPath $backupDir -Filter '*.chr' -ErrorAction SilentlyContinue)
  if ($bks.Count -eq 0) { Write-Host "ERRO: sem backups em $backupDir" -ForegroundColor Red; exit 1 }
  foreach ($b in $bks) {
    $dest = Join-Path $ChartsDir $b.Name
    Copy-Item -LiteralPath $b.FullName -Destination $dest -Force
  }
  Write-Host ("REVERTIDO: {0} .chr restaurados do backup {1}" -f $bks.Count, $backupDir) -ForegroundColor Green
  exit 0
}

if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }

$mudou = 0; $iguais = 0; $erros = @()
foreach ($f in $ficheiros) {
  try {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $t = [System.Text.Encoding]::Unicode.GetString($bytes)
    $m = [regex]::Match($t, '(?m)^(' + [regex]::Escape($Campo) + ')=([^\r\n]*)')
    if (-not $m.Success) { $erros += ($f.Name + ': campo ausente'); continue }
    $antes = $m.Groups[2].Value.Trim()
    if ($antes -eq $Valor) { $iguais++; continue }
    if ($DryRun) {
      Write-Host ("{0,-14} {1}: {2} -> {3}  (DRY RUN)" -f $f.Name, $Campo, $antes, $Valor)
      $mudou++
      continue
    }
    # backup antes de tocar
    $bk = Join-Path $backupDir $f.Name
    if (-not (Test-Path -LiteralPath $bk)) { Copy-Item -LiteralPath $f.FullName -Destination $bk -Force }
    $nova = $t.Substring(0, $m.Index) + $Campo + '=' + $Valor + $t.Substring($m.Index + $m.Length)
    [System.IO.File]::WriteAllText($f.FullName, $nova, (New-Object System.Text.UTF8Encoding($false)))
    $mudou++
    Write-Host ("{0,-14} {1}: {2} -> {3}" -f $f.Name, $Campo, $antes, $Valor) -ForegroundColor DarkGray
  } catch {
    $erros += ($f.Name + ': ' + $_.Exception.Message)
  }
}

Write-Host ''
Write-Host ("{0}: {1} alterado(s), {2} ja no valor, {3} erro(s)" -f $Campo, $mudou, $iguais, $erros.Count)
if ($erros.Count -gt 0) { foreach ($e in $erros) { Write-Host ("  ERRO " + $e) -ForegroundColor Red } }
if (-not $DryRun) {
  Write-Host ("backup em: {0}" -f $backupDir) -ForegroundColor DarkGray
  Write-Host 'REVERTER:  powershell -NoProfile -ExecutionPolicy Bypass -File Tools\piso-chr.ps1 -Reverter' -ForegroundColor DarkGray
  Write-Host ''
  Write-Host 'ATENCAO: o terminal tem os graficos abertos e pode reescrever o .chr ao guardar.'
  Write-Host 'Fechar/reanexar os graficos DEPOIS desta edicao, sem expert_parameters.' -ForegroundColor Yellow
}
if ($erros.Count -gt 0) { exit 1 }
exit 0
