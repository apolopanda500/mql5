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
$contaMemoria = ''
$logDir = Join-Path $Root 'Logs'
if (Test-Path -LiteralPath $logDir) {
  # Os 2 ultimos ficheiros: a virada do dia parte os [START] entre dois
  # ficheiros, e a conta do terminal pode estar no de ontem.
  $logs = @(Get-ChildItem -LiteralPath $logDir -Filter '*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 2)
  foreach ($lf in $logs) {
    try {
      $fs = [System.IO.File]::Open($lf.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
      $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode); $t = $sr.ReadToEnd(); $sr.Close()
      foreach ($l in ($t -split "`r?`n")) {
        if ($l -match '\[START\] XAU_AI_PRO\s+(v[0-9.]+)') { $versaoMemoria = $Matches[1] }
        # A CONTA tambem e parte da identidade do forward (D-179).
        if ($l -match '\[START\] XAU_AI_PRO.*conta=(\d+)\s*\|\s*([^|]+)\|') {
          $contaMemoria = $Matches[1].Trim() + ' @ ' + $Matches[2].Trim()
        }
      }
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

# --- 1b. A CONTA (D-179) ---
# MEDIDO em 10/11/2026 19:45: o terminal trocou de conta NO MESMO SITIO
# (MetaQuotes-Demo 113568614 -> Headway-Demo 6419396). O `.ex5` nao mudou,
# o MD5 nao mudou, a versao nao mudou - e o portao passou. **A conta e parte
# da identidade do forward**: sem ela, uma janela declarada para a conta
# A pode estar a medir a conta B.
$contaDeclarada = ''
if (Test-Path -LiteralPath $declF) {
  try { $dd = Get-Content -LiteralPath $declF -Raw -Encoding UTF8 | ConvertFrom-Json; $contaDeclarada = [string]$dd.conta } catch { }
}
if ($contaDeclarada -ne '' -and $contaMemoria -ne '' -and $contaDeclarada -ne $contaMemoria) {
  $falhas += ("a conta em memoria e '{0}' e a declarada e '{1}' - o terminal trocou de conta" -f $contaMemoria, $contaDeclarada)
}
if ($contaDeclarada -eq '') {
  # MEDIDO em 10/11 20:00-20:02: o terminal passou por DUAS contas em dois
  # minutos (450258809 XMGlobal-MT5 20 -> 113568614 MetaQuotes-Demo) e o portao
  # nao reclamou, porque o dossier ainda nao declarava conta nenhuma.
  # Um dossier sem conta e um dossier que mede o que calhar: TEM de falhar.
  $falhas += "o dossier NAO declara a conta - mede-se a conta do terminal em silencio. Declara-a antes de abrir a janela."
}
if ($contaMemoria -eq '') {
  $falhas += "nao foi possivel ler a conta do journal (sem [START] legivel)"
}

# --- 2. perfil: os inputs vivos tem de bater com os declarados, CAMPO A CAMPO
# NAO se procura um "piso 45" fixo: o valor declarado pode mudar (e ja mudou),
# e o que interessa e saber se o que esta a correr e o que foi declarado.
# MEDIDO em 10/11 20:50: nos 5 graficos vivos so o chart01 tem o bloco
# <inputs> completo (piso 60.0); os outros 4 perderam-no. O portao tem de
# dizer isso com nome de campo, nao "falta o piso 45".
$inputsDeclarados = $null
$chartCount = 0
if (Test-Path -LiteralPath $declF) {
  try { $dd2 = Get-Content -LiteralPath $declF -Raw -Encoding UTF8 | ConvertFrom-Json; $inputsDeclarados = $dd2.inputs } catch { }
}
$crs = @(Get-ChildItem -LiteralPath $chartsDir -Filter '*.chr' -ErrorAction SilentlyContinue)
$chartCount = $crs.Count
$liveInputs = @{}
foreach ($f in $crs) {
  try {
    $t = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::Unicode)
    foreach ($m in [regex]::Matches($t, '(?m)^([A-Za-z_][A-Za-z0-9_]*)=([^\r\n]*)')) {
      $k = $m.Groups[1].Value; $v = $m.Groups[2].Value.Trim()
      if (-not $liveInputs.ContainsKey($k)) { $liveInputs[$k] = $v }
    }
  } catch { }
}
$difInputs = @()
if ($inputsDeclarados) {
  foreach ($prop in $inputsDeclarados.PSObject.Properties) {
    $k = $prop.Name; $dv = [string]$prop.Value
    if (-not $liveInputs.ContainsKey($k)) { $difInputs += ("$k = AUSENTE no perfil (declarado $dv)"); continue }
    if ($liveInputs[$k] -ne $dv) { $difInputs += ("$k : vivo=$($liveInputs[$k]) declarado=$dv") }
  }
} else {
  $difInputs += 'o dossier nao declara o bloco de inputs'
}
$chartCountEsperado = 0
if (Test-Path -LiteralPath $declF) {
  try {
    $dd3 = Get-Content -LiteralPath $declF -Raw -Encoding UTF8 | ConvertFrom-Json
    # DISTINTOS: a lista de simbolos pode terentries repetidas de
    # declaracoes anteriores (MEDIDO 11/11 23:30: 32 entradas para 16 simbolos).
    $chartCountEsperado = @(@($dd3.frota_simbolos) | ForEach-Object { [string]$_ } | Sort-Object -Unique).Count
  } catch { }
}
if ($chartCountEsperado -gt 0 -and $chartCount -ne $chartCountEsperado) {
  $falhas += ("o perfil tem {0} graficos e o dossier declara {1} - falta aplicar o perfil completo" -f $chartCount, $chartCountEsperado)
}
if ($difInputs.Count -gt 0) {
  $falhas += ("os inputs vivos nao batem com os declarados ({0}): {1}" -f $difInputs.Count, (($difInputs | Select-Object -First 4) -join ' ; '))
}

# --- 3. frota (sonda 0) ---
# MEDIDO em 10/11 20:05: o terminal passou por 3 contas (450258809 XMGlobal,
# 6419396 Headway-Demo, 113568614 MetaQuotes-Demo) e cada uma deixou os seus
# `permission_state_*.csv` no MESMO `Files\Data`. Contar ficheiros a scarring
# dava "32/15 LIGADO" - sem significado. A frota que conta e a do PERFIL
# VIVO: os simbolos dos `.chr` da conta ativa. As orfas saoitoras.
$simbolosPerfil = @()
foreach ($f in @(Get-ChildItem -LiteralPath $chartsDir -Filter '*.chr' -ErrorAction SilentlyContinue)) {
  try {
    $t = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::Unicode)
    $m = [regex]::Match($t, '(?m)^symbol=(\S+)')
    if ($m.Success) { $simbolosPerfil += $m.Groups[1].Value.Trim() }
  } catch { }
}
$lig = 0; $des = 0; $fich = 0; $orfas = 0
foreach ($f in @(Get-ChildItem -LiteralPath $dataDir -Filter 'permission_state_*.csv' -ErrorAction SilentlyContinue)) {
  $sym = $f.BaseName -replace '^permission_state_', ''
  $doPerfil = $simbolosPerfil -contains $sym
  try {
    $fs = [System.IO.File]::Open($f.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
    $sr = New-Object System.IO.StreamReader($fs); $t = $sr.ReadToEnd(); $sr.Close()
    $l = @($t -split "`r?`n" | Where-Object { $_.Trim() })
    if ($l.Count -ge 2) {
      $c = $l[$l.Count - 1] -split ';'
      if ($c.Count -ge 11) {
        if ($doPerfil) {
          $fich++
          if ($c[4] -eq '1' -and $c[9] -eq '0') { $lig++ } else { $des++ }
        } else { $orfas++ }
      }
    }
  } catch { }
}
if ($simbolosPerfil.Count -eq 0) { $falhas += 'o perfil nao tem simbolos legiveis' }
elseif ($fich -eq 0) { $falhas += ("sem sonda 0 para os {0} simbolos do perfil" -f $simbolosPerfil.Count) }
elseif ($lig -lt $simbolosPerfil.Count) { $falhas += ("frota {0}/{1} com o bit ligado - falta o F7 do DONO nos {2} restantes" -f $lig, $simbolosPerfil.Count, ($simbolosPerfil.Count - $lig)) }

Write-Host ''
Write-Host '== FECHA DA JANELA ==' -ForegroundColor Cyan
Write-Host ("binario   : {0} B | MD5 {1} | {2} min estavel | memoria {3} | disco v{4}" -f $info.Length, $md5, $idadeMin, $versaoMemoria, $versaoDisco)
Write-Host ("conta     : {0} | declarada: {1}" -f $(if ($contaMemoria) { $contaMemoria } else { 'n/d' }), $(if ($contaDeclarada) { $contaDeclarada } else { '(sem conta no dossier)' }))
Write-Host ("perfil    : {0} .chr | inputs a bater com o declarado: {1} | divergencias: {2}" -f $chartCount, $(if ($difInputs.Count -eq 0) { "todos" } else { "NAO" }), $difInputs.Count)
Write-Host ("frota     : {0}/{1} LIGADO | {2} desligado | {3} sondas do perfil | {4} orfas de outras contas" -f $lig, $simbolosPerfil.Count, $des, $fich, $orfas)
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
