<#
=====================================================================
 pulso-forward.ps1 - estado do forward a cada 15 minutos
=====================================================================
 Mede o mesmo que o `forward-gate.ps1` (binario, governanca, frota, funil,
 IA) mas escreve **uma linha compacta** em `_SYNC/pulso.jsonl`. E o
 registo continuo que mostra se o forward esta a andar: quantos graficos
 podem negociar, quantos sinais passam, quantos trades saem.

 E o que responde a "esta a correr?" sem abrir o terminal: um `tail` da
 ultima linha responde.

 Nao escreve nada no canal, nao altera nada, nao toca em ordens.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\pulso-forward.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\pulso-forward.ps1 -Verbo
=====================================================================
#>
[CmdletBinding()]
param([switch]$Verbo)

$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
$Root = (Resolve-Path -LiteralPath $Root).Path

$equipe = Join-Path $Root 'Experts\XAU_AI_PRO\EQUIPE'
$fwd    = Join-Path $equipe 'FORWARD'
$ex5    = Join-Path $Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
$saida  = Join-Path $equipe '_SYNC\pulso.jsonl'
$decl   = Join-Path $fwd 'DECLARADO.json'

function Get-MD5([string]$Path) {
  $fs = [System.IO.File]::OpenRead($Path)
  try {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    return ([System.BitConverter]::ToString($md5.ComputeHash($fs)) -replace '-', '')
  } finally { $fs.Close() }
}

$agora = Get-Date
$md5 = ''; $bytes = 0
if (Test-Path -LiteralPath $ex5) {
  $i = Get-Item -LiteralPath $ex5
  $md5 = Get-MD5 $ex5
  $bytes = $i.Length
}
$md5Dec = ''; $govDec = ''
if (Test-Path -LiteralPath $decl) {
  try {
    $d = Get-Content -LiteralPath $decl -Raw -Encoding UTF8 | ConvertFrom-Json
    $md5Dec = [string]$d.md5
    $govDec = [string]$d.governanca_sha256
  } catch { }
}

# frota: sonda 0 (o proprio EA escreve) - ausente = binario sem a sonda
$ligados = 0; $desligados = 0
$dataDir = Join-Path $Root 'Files\Data'
if (Test-Path -LiteralPath $dataDir) {
  foreach ($f in @(Get-ChildItem -LiteralPath $dataDir -Filter 'permission_state_*.csv' -ErrorAction SilentlyContinue)) {
    try {
      $fs = [System.IO.File]::Open($f.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
      $sr = New-Object System.IO.StreamReader($fs); $t = $sr.ReadToEnd(); $sr.Close()
      $ls = @($t -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
      if ($ls.Count -ge 2) {
        $c = $ls[$ls.Count - 1] -split ';'
        if ($c.Count -ge 11) { if ($c[4] -eq '1' -and $c[9] -eq '0') { $ligados++ } else { $desligados++ } }
      }
    } catch { }
  }
}

# funil: ultima linha [SCANNER] RESUMO do log de hoje
$log = Join-Path (Join-Path $Root 'Logs') ($agora.ToString('yyyyMMdd') + '.log')
$sin = -1; $trd = -1
try {
  $fs = [System.IO.File]::Open($log, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
  $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode)
  $txt = $sr.ReadToEnd(); $sr.Close()
  $ult = ''
  foreach ($l in ($txt -split "`r?`n")) { if ($l -match '\[SCANNER\] RESUMO') { $ult = $l } }
  if ($ult -match 'sinais=(\d+)') { $sin = [int]$Matches[1] }
  if ($ult -match 'trades=(\d+)') { $trd = [int]$Matches[1] }
} catch { }

$linha = ('{{"t":"{0}","md5_ok":{1},"md5":"{2}","bytes":{3},"gov_ok":{4},"frota_on":{5},"frota_off":{6},"sinais":{7},"trades":{8}}}' -f `
  $agora.ToString('yyyy-MM-dd HH:mm:ss'),
  $(if ($md5Dec -and $md5 -eq $md5Dec) { 'true' } else { 'false' }),
  $md5, $bytes,
  $(if ($govDec -and $govDec -ne '') { 'true' } else { 'false' }),
  $ligados, $desligados, $sin, $trd)

if (-not (Test-Path -LiteralPath (Split-Path $saida -Parent))) {
  New-Item -ItemType Directory -Path (Split-Path $saida -Parent) -Force | Out-Null
}
[System.IO.File]::AppendAllText($saida, $linha + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
if ($Verbo) { Write-Host $linha }
exit 0
