<#
=====================================================================
 journal-ao-vivo.ps1 - ler o journal do EA em direto
=====================================================================
 O terminal do MT5 mantem o ficheiro de log ABERTO EM ESCRITA EXCLUSIVA.
 Ler com `Get-Content` falha com "ficheiro em uso". A leitura correta e
 abrir o ficheiro com `FileShare.ReadWrite -bor FileShare.Delete` e ir
 lendo a partir de um offset de bytes, sem nunca trancar o terminal.

 O que resolve:
   - a mudanca de dia (o log passa a YYYYMMDD.log) sem perder nada
   - filtro por tag ([SCANNER], [AI], [TRADE BLOCK], ...), por simbolo e
     por texto
   - modo "catch-up": mostra as ultimas N linhas e DEPOIS segue em direto
   - modo "silencioso": so escreve em ficheiro (para correr em background)

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\journal-ao-vivo.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\journal-ao-vivo.ps1 -Tag 'AI|TRADE' -Segundos 30
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\journal-ao-vivo.ps1 -CatchUp 40 -Simbolo XAUUSD
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\journal-ao-vivo.ps1 -Saida Logs\ao-vivo.txt -Silencioso

 SAIDA: 0 = terminou por tempo | 1 = erro
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$LogDir = '',
  [string]$Tag = '',
  [string]$Simbolo = '',
  [string]$Texto = '',
  [int]$CatchUp = 20,
  [int]$Segundos = 0,
  [string]$Saida = '',
  [switch]$Silencioso
)

$ErrorActionPreference = 'Continue'
if ($LogDir -eq '') {
  $root = Split-Path -Parent $PSScriptRoot
  $LogDir = Join-Path $root 'Logs'
}
if (-not (Test-Path -LiteralPath $LogDir)) { Write-Host "ERRO: sem pasta de logs: $LogDir"; exit 1 }

$rxTag = ''
if ($Tag -ne '') { $rxTag = $Tag }
$rxSimb = if ($Simbolo -ne '') { [regex]::Escape($Simbolo) } else { '' }
$rxTxt = if ($Texto -ne '') { [regex]::Escape($Texto) } else { '' }

function Casa([string]$l) {
  if ($rxTag -ne '' -and $l -notmatch $rxTag) { return $false }
  if ($rxSimb -ne '' -and $l -notmatch $rxSimb) { return $false }
  if ($rxTxt -ne '' -and $l -notmatch $rxTxt) { return $false }
  return $true
}

function Escrever([string]$s) {
  if ($Silencioso) {
    if ($Saida -ne '') { [System.IO.File]::AppendAllText($Saida, $s, (New-Object System.Text.UTF8Encoding($false))) }
  } else {
    Write-Host $s
  }
}

function Ficheiro-Do-Dia() {
  $n = (Get-Date).ToString('yyyyMMdd')
  $p = Join-Path $LogDir ($n + '.log')
  if (Test-Path -LiteralPath $p) { return $p }
  return $null
}

function Ler-Desde([string]$Path, [long]$Offset) {
  # devolve @{ texto = <novo>; offset = <novo offset> }
  $res = @{ texto = ''; offset = $Offset }
  try {
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
    try {
      $len = $fs.Length
      if ($Offset -gt $len) { $Offset = 0 }      # o ficheiro foi truncado/rodado
      $fs.Seek($Offset, [System.IO.SeekOrigin]::Begin) | Out-Null
      $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode, $true, 4096, $true)
      $txt = $sr.ReadToEnd()
      # o offset novo e o fim do que foi lido, alinhado a 2 bytes (UTF-16)
      $pos = $fs.Position
      $res.texto = $txt
      $res.offset = $pos
    } finally { $fs.Close() }
  } catch { }
  return $res
}

# ---------------------------------------------------------------- catch-up
$ficheiro = Ficheiro-Do-Dia
if ($ficheiro -eq $null) { Write-Host "ERRO: nao ha log de hoje em $LogDir"; exit 1 }

$offset = 0
if ($CatchUp -gt 0) {
  # le o ficheiro todo, fica com as ultimas N linhas que casam, e posiciona
  # o offset no fim para seguir em direto
  $r = Ler-Desde $ficheiro 0
  $todas = @($r.texto -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
  $sel = @($todas | Where-Object { Casa $_ })
  $ini = [Math]::Max(0, $sel.Count - $CatchUp)
  for ($i = $ini; $i -lt $sel.Count; $i++) { Escrever $sel[$i] }
  $offset = $r.offset
} else {
  $offset = 0
}

if ($Segundos -le 0) { $Segundos = 3600 }
$fim = (Get-Date).AddSeconds($Segundos)
Escrever ("--- a seguir em direto: " + $ficheiro + " | ate " + $fim.ToString('HH:mm:ss') + " ---")

while ((Get-Date) -lt $fim) {
  $f = Ficheiro-Do-Dia
  if ($f -eq $null) { Start-Sleep -Milliseconds 700; continue }
  if ($f -ne $ficheiro) {
    # rotacao de dia: acaba o ficheiro antigo e recomeca no novo
    $r = Ler-Desde $f 0
    foreach ($l in @($r.texto -split "`r?`n" | Where-Object { $_.Trim() -ne '' })) { if (Casa $l) { Escrever $l } }
    $offset = $r.offset
    $ficheiro = $f
    Escrever ("--- passou para " + $f + " ---")
    continue
  }
  $r = Ler-Desde $f $offset
  if ($r.texto -ne '') {
    foreach ($l in @($r.texto -split "`r?`n" | Where-Object { $_.Trim() -ne '' })) { if (Casa $l) { Escrever $l } }
    $offset = $r.offset
  }
  Start-Sleep -Milliseconds 600
}

Escrever "--- fim do acompanhamento ---"
exit 0
