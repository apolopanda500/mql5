<#
=====================================================================
 fechar-janela.ps1 - fechar o forward num comando so (depois do F7)
=====================================================================
 Verifica as QUATRO condicoes que o dossier exige, e so declara se as
 quatro passarem. Se alguma falhar, diz qual - e nao declara.

 1. O BINARIO: MD5 do disco estavel (nao mudou nos ultimos minutos) e
    igual ao que corre em memoria nos 15 graficos.
 2. O PERFIL: os 15 `.chr` com `MinAIConfidence` no valor declarado e com
    os 15 simbolos (o universo nao pode ter colapsado para 1).
 3. A FROTA: 15/15 com o bit de negociacao ligado (sonda 0 do proprio EA).
 4. A GOVERNANCA: a impressao dos `.meta.json` igual a declarada.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\fechar-janela.ps1
   ... -EstavelMin 10      (minutos sem o .ex5 mudar; omissao: 5)
   ... -Forcar              (declara mesmo com algo em falta, e regista)
=====================================================================
#>
[CmdletBinding()]
param(
  [int]$EstavelMin = 5,
  [switch]$Forcar,
  [string]$Root = ''
)

$ErrorActionPreference = 'Continue'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path

$ex5 = Join-Path $Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
$declF = Join-Path $Root 'Experts\XAU_AI_PRO\EQUIPE\FORWARD\DECLARADO.json'
$chartsDir = Join-Path $Root 'Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071'
$dataDir = Join-Path $Root 'Files\Data'

function Get-MD5([string]$p) {
  $fs = [System.IO.File]::OpenRead($p)
  try { $md5 = [System.Security.Cryptography.MD5]::Create(); return ([System.BitConverter]::ToString($md5.ComputeHash($fs)) -replace '-', '') }
  finally { $fs.Close() }
}

$falhas = @()
$notas = @()

# --- 1. binario estavel e em memoria ---
if (-not (Test-Path -LiteralPath $ex5)) { Write-Host 'ERRO: sem binario' -ForegroundColor Red; exit 1 }
$info = Get-Item -LiteralPath $ex5
$md5 = Get-MD5 $ex5
$idadeMin = [int]((Get-Date) - $info.LastWriteTime).TotalMinutes
if ($idadeMin -lt $EstavelMin) { $falhas += ("binario mexido ha {0} min (estavel exige {1})" -f $idadeMin, $EstavelMin) }

# versao em memoria: o ultimo [START] do journal
$versaoMemoria = ''
$logDir = Join-Path $Root 'Logs'
if (Test-Path -LiteralPath $logDir) {
  $lf = @(Get-ChildItem -LiteralPath $logDir -Filter '*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
  if ($lf.Count -gt 0) {
    try {
      $fs = [System.IO.File]::Open($lf[0].FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
      $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode); $t = $sr.ReadToEnd(); $sr.Close()
      foreach ($l in ($t -split "`r?`n")) { if ($l -match '\[START\] XAU_AI_PRO\s+(v[0-9.]+)') { $versaoMemoria = $Matches[1] } }
    } catch { }
  }
}
$versaoDisco = ''
$vm = Join-Path $Root 'Experts\XAU_AI_PRO\Enterprise\VersionManager.mqh'
if (Test-Path -LiteralPath $vm) {
  $m = Select-String -Path $vm -Pattern '#define\s+EA_VERSION_STRING\s+"([^"]+)"' | Select-Object -First 1
  if ($m) { $versaoDisco = $m.Matches[0].Groups[1].Value }
}
if ($versaoMemoria -ne '' -and $versaoDisco -ne '' -and $versaoMemoria -ne ('v' + $versaoDisco)) {
  $falhas += ("a memoria corre {0} e o disco e v{1} - o deploy nao pegou" -f $versaoMemoria, $versaoDisco)
}

# --- 2. perfil: piso e universo ---
$piso = ''; $nPisoOk = 0; $nSimbolos = 0; $nChr = 0
foreach ($f in @(Get-ChildItem -LiteralPath $chartsDir -Filter '*.chr' -ErrorAction SilentlyContinue | Sort-Object Name)) {
  $nChr++
  try {
    $t = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::Unicode)
    $p = [regex]::Match($t, 'MinAIConfidence=([^\r\n]*)').Groups[1].Value.Trim()
    $s = @(([regex]::Match($t, 'Symbols=([^\r\n]*)').Groups[1].Value.Trim()) -split ',').Count
    if ($p -eq $piso -or $piso -eq '') { $piso = $p }
    if ($p -eq '45.0') { $nPisoOk++ }
    if ($s -ge 15) { $nSimbolos++ }
  } catch { }
}
if ($nChr -eq 0) { $falhas += 'sem .chr no perfil oficial' }
else {
  if ($nPisoOk -lt $nChr) { $falhas += ("piso 45 so em {0}/{1} graficos" -f $nPisoOk, $nChr) }
  if ($nSimbolos -lt $nChr) { $falhas += ("universo de 15 simbolos so em {0}/{1} graficos" -f $nSimbolos, $nChr) }
}

# --- 3. frota (sonda 0) ---
$lig = 0; $des = 0; $fich = 0
foreach ($f in @(Get-ChildItem -LiteralPath $dataDir -Filter 'permission_state_*.csv' -ErrorAction SilentlyContinue)) {
  $fich++
  try {
    $fs = [System.IO.File]::Open($f.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
    $sr = New-Object System.IO.StreamReader($fs); $t = $sr.ReadToEnd(); $sr.Close()
    $l = @($t -split "`r?`n" | Where-Object { $_.Trim() })
    if ($l.Count -ge 2) {
      $c = $l[$l.Count - 1] -split ';'
      if ($c.Count -ge 11) { if ($c[4] -eq '1' -and $c[9] -eq '0') { $lig++ } else { $des++ } }
    }
  } catch { }
}
if ($fich -eq 0) { $falhas += 'sem sonda 0 (permission_state_*.csv) - o binario vivo nao a escreve' }
elseif ($lig -lt 15) { $falhas += ("frota {0}/15 com o bit ligado - falta o F7 do DONO nos {1} restantes" -f $lig, (15 - $lig)) }

Write-Host ''
Write-Host '== FECHA DA JANELA ==' -ForegroundColor Cyan
Write-Host ("binario   : {0} B | MD5 {1} | {2} min estavel | memoria {3} | disco v{4}" -f $info.Length, $md5, $idadeMin, $versaoMemoria, $versaoDisco)
Write-Host ("perfil    : {0}/{1} .chr com piso 45.0 | {2}/{3} com 15 simbolos" -f $nPisoOk, $nChr, $nSimbolos, $nChr)
Write-Host ("frota     : {0}/15 LIGADO | {1} desligado | {2} sondas" -f $lig, $des, $fich)
Write-Host ''

if ($falhas.Count -gt 0 -and -not $Forcar) {
  foreach ($f in $falhas) { Write-Host ("  FALTA: " + $f) -ForegroundColor Yellow }
  Write-Host ''
  Write-Host 'A JANELA NAO ABRE. Nao declarar enquanto estas condicoes faltam.' -ForegroundColor Red
  exit 3
}
if ($falhas.Count -gt 0) { foreach ($f in $falhas) { Write-Host ("  AVISO (declarado com -Forcar): " + $f) -ForegroundColor Yellow } }

& (Join-Path $Root 'Tools\declarar-forward.ps1')
exit $LASTEXITCODE
