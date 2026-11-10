<#
=====================================================================
 forward-gate.ps1 - medicao diaria do forward de 30 dias (G11)
=====================================================================
 O que mede, todos os dias, com numero e hora:
   1. MD5 do .ex5 em disco vs MD5 DECLARADO. Divergencia = janela a zero.
   2. Versoes a correr ([START]) - um build novo divide os 30 dias.
   3. Funil: visitas, sinais, AllowTrade (bloqueios), ExecFail, trades.
   4. Cobertura de IA: simbolos do universo com previsao real (available=true).
   5. P/L do dia, trades do dia, PerdaDia %, Amplitude (DD) % do [STATUS].
   6. Traces de execucao: [TRADE PIPELINE], [SCANNER] TRADE SUCCESS.

 Escreve:
   EQUIPE/FORWARD/medicao.jsonl   (uma linha por dia do servidor)
   EQUIPE/FORWARD/FORWARD.md      (tabela viva, legivel pelo DONO)

 Saida: 0 = tudo conforme | 2 = MD5 divergiu (janela perdida) | 1 = erro

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\forward-gate.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\forward-gate.ps1 -Detalhe
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$Root = '',
  [switch]$Detalhe
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path

$equipe  = Join-Path $Root 'Experts\XAU_AI_PRO\EQUIPE'
$fwdDir  = Join-Path $equipe 'FORWARD'
$ex5     = Join-Path $Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
$logDir  = Join-Path $Root 'Logs'
$appDir  = Join-Path $Root 'Files\XAU_AI_PRO'
$jsonl   = Join-Path $fwdDir 'medicao.jsonl'
$md      = Join-Path $fwdDir 'FORWARD.md'
$decl    = Join-Path $fwdDir 'DECLARADO.json'

# Desvio do servidor em relacao a hora local (medido: -03:00 => servidor = local + 3h)
$OffsetServidorHoras = 3

function Say($t) { if ($Detalhe) { Write-Host $t } }

function Ler-LogLocal([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return '' }
  try {
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode)
    $t = $sr.ReadToEnd(); $sr.Close(); return $t
  } catch { return '' }
}

# ---------------------------------------------------------------- declaracao
$md5Atual = ''
$ex5Info  = $null
if (Test-Path -LiteralPath $ex5) {
  $ex5Info = Get-Item -LiteralPath $ex5
  $md5Atual = (Get-FileHash -LiteralPath $ex5 -Algorithm MD5).Hash
}

$declarado = $null
if (Test-Path -LiteralPath $decl) {
  try { $declarado = Get-Content -LiteralPath $decl -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $declarado = $null }
}
$md5Declarado = if ($declarado) { [string]$declarado.md5 } else { '' }
$versaoDeclarada = if ($declarado) { [string]$declarado.versao } else { '' }
$divergente = ($md5Declarado -ne '' -and $md5Atual -ne $md5Declarado)

# ---------------------------------------------------------------- logs
$serverNow = (Get-Date).AddHours($OffsetServidorHoras)
$serverDate = $serverNow.ToString('yyyy-MM-dd')

$logFiles = @()
if (Test-Path -LiteralPath $logDir) {
  $logFiles = Get-ChildItem -LiteralPath $logDir -Filter '*.log' -ErrorAction SilentlyContinue |
              Where-Object { $_.LastWriteTime -ge (Get-Date).AddDays(-2) } | Sort-Object Name
}
$texto = ''
foreach ($lf in $logFiles) { $texto += (Ler-LogLocal $lf.FullName) + "`n" }
$linhas = $texto -split "`r?`n"

Say ("linhas lidas: " + $linhas.Count)

# [START] por versao
$starts = @($linhas | Where-Object { $_ -match '\[START\] XAU_AI_PRO' })
$versoes = @{}
foreach ($s in $starts) {
  if ($s -match 'XAU_AI_PRO\s+(v[0-9.]+)') {
    $v = $Matches[1]
    if (-not $versoes.ContainsKey($v)) { $versoes[$v] = 0 }
    $versoes[$v]++
  }
}
$versaoCorrer = if ($versoes.Count -gt 0) { ($versoes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key } else { '' }

# funil: ultimo [SCANNER] RESUMO
$resumo = ''
foreach ($l in $linhas) { if ($l -match '\[SCANNER\] RESUMO') { $resumo = $l } }
$funil = @{}
if ($resumo) {
  if ($resumo -match 'visitas=(\d+)') { $funil['visitas'] = [int]$Matches[1] }
  if ($resumo -match 'sinais=(\d+)')  { $funil['sinais'] = [int]$Matches[1] }
  if ($resumo -match 'trades=(\d+)')  { $funil['trades'] = [int]$Matches[1] }
  if ($resumo -match 'bloqueios=(\d+)') { $funil['bloqueios'] = [int]$Matches[1] }
  if ($resumo -match 'AllowTrade=(\d+)') { $funil['allow_trade_bloqueios'] = [int]$Matches[1] }
  if ($resumo -match 'ExecFail=(\d+)') { $funil['exec_fail'] = [int]$Matches[1] }
  if ($resumo -match 'Stale=(\d+)') { $funil['stale'] = [int]$Matches[1] }
  if ($resumo -match 'NoSignal=(\d+)') { $funil['no_signal'] = [int]$Matches[1] }
}

# [STATUS] HEALTHY: estado da conta e do dia
$status = ''
foreach ($l in $linhas) { if ($l -match '\[STATUS\] HEALTHY') { $status = $l } }
$conta = @{}
if ($status) {
  if ($status -match 'P/Ldia\(realizado\):\s*(-?[0-9.]+)') { $conta['pl_dia'] = [double]$Matches[1] }
  if ($status -match 'Trades:\s*(\d+)/(\d+)') { $conta['trades_dia'] = [int]$Matches[1]; $conta['trades_max'] = [int]$Matches[2] }
  if ($status -match 'PerdaDia:\s*([0-9.]+)%/([0-9.]+)%') { $conta['perda_dia_pct'] = [double]$Matches[1]; $conta['perda_dia_teto_pct'] = [double]$Matches[2] }
  if ($status -match 'Amplitude:\s*([0-9.]+)%') { $conta['amplitude_pct'] = [double]$Matches[1] }
  if ($status -match 'Orders=(\d+)') { $conta['orders'] = [int]$Matches[1] }
  if ($status -match 'Exec=(\d+)') { $conta['exec'] = [int]$Matches[1] }
  if ($status -match 'Reject=(\d+)') { $conta['reject'] = [int]$Matches[1] }
  if ($status -match 'Requotes=(\d+)') { $conta['requotes'] = [int]$Matches[1] }
  if ($status -match 'Positions:\s*(\d+)\s*total EA') { $conta['posicoes_ea'] = [int]$Matches[1] }
  if ($status -match 'Equity=([0-9.]+)') { $conta['equity'] = [double]$Matches[1] }
}

# IA: simbolos com previsao real hoje (do log do gateway)
$iaSimbolos = @{}
foreach ($l in $linhas) {
  if ($l -match '\[AI\] PYTHON \| (\w+) \|') { $iaSimbolos[$Matches[1]] = $true }
}
# gateway: available=true por simbolo do universo
$universo = @()
$token = ''
$envFile = Join-Path $appDir '.env'
if (Test-Path -LiteralPath $envFile) {
  $t = (Get-Content -LiteralPath $envFile -Encoding UTF8 | Where-Object { $_ -match 'XAU_GATEWAY_TOKEN' } | Select-Object -First 1)
  if ($t) { $token = ($t -split '=')[1].Trim() }
}
$gwDisponiveis = @()
if ($token -ne '') {
  $h = @{ Authorization = "Bearer $token" }
  foreach ($s in @('XAUUSD','EURUSD','GBPUSD','USDJPY','AUDUSD','USDCAD','NZDUSD','USDCHF','USDBRL','USDSEK','USDCNH','USDCZK','USDRUB','USDSGD','USDCLP','USDCOP')) {
    try {
      $r = Invoke-WebRequest -Uri "http://127.0.0.1:9011/api/ai/predict?symbol=$s&timeframe=H1" -Headers $h -UseBasicParsing -TimeoutSec 12
      $j = $r.Content | ConvertFrom-Json
      if ($j.available -eq $true) { $gwDisponiveis += $s }
    } catch { }
  }
}

$traces = @($linhas | Where-Object { $_ -match '\[TRADE PIPELINE\]' }).Count
$sucesso = @($linhas | Where-Object { $_ -match '\[SCANNER\] TRADE SUCCESS' }).Count
$timeouts = @($linhas | Where-Object { $_ -match 'HTTP 1003' }).Count

# ---------------------------------------------------------------- registo
if (-not (Test-Path -LiteralPath $fwdDir)) { New-Item -ItemType Directory -Path $fwdDir -Force | Out-Null }

$registo = [ordered]@{
  server_date        = $serverDate
  medido_local       = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss')
  md5_ex5            = $md5Atual
  md5_declarado      = $md5Declarado
  md5_divergente     = $divergente
  ex5_bytes          = if ($ex5Info) { $ex5Info.Length } else { 0 }
  ex5_mtime          = if ($ex5Info) { $ex5Info.LastWriteTime.ToString('dd/MM HH:mm:ss') } else { '' }
  versao_declarada   = $versaoDeclarada
  versao_em_memoria  = $versaoCorrer
  starts_total       = $starts.Count
  funil              = $funil
  conta              = $conta
  ia_simbolos_log    = @($iaSimbolos.Keys | Sort-Object)
  ia_available_gw    = $gwDisponiveis
  ia_disponiveis_n   = $gwDisponiveis.Count
  trade_pipeline     = $traces
  trade_success      = $sucesso
  webrequest_1003    = $timeouts
}

$linha = ($registo | ConvertTo-Json -Compress -Depth 6)
[System.IO.File]::AppendAllText($jsonl, $linha + "`r`n", (New-Object System.Text.UTF8Encoding($false)))

# tabela md
$mdLines = @()
if (Test-Path -LiteralPath $jsonl) {
  $mdLines = Get-Content -LiteralPath $jsonl -Encoding UTF8 | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_ | ConvertFrom-Json }
}
$tabela = @()
$tabela += '# FORWARD 30 DIAS - G11 (medicao diaria automatica)'
$tabela += ''
$tabela += ("Gerado por ``Tools\forward-gate.ps1``. Dia do servidor = local + $OffsetServidorHoras h.")
$tabela += ''
$tabela += '| Dia servidor | MD5 ok | Ver. memoria | Sinais | AllowTrade(bloq) | ExecFail | Trades | P/L dia | DD % | IA disp. | 1003 |'
$tabela += '|---|---|---|---|---|---|---|---|---|---|---|'
foreach ($r in $mdLines) {
  $f = $r.funil; $c = $r.conta
  $ok = if ($r.md5_divergente) { 'NAO' } else { 'sim' }
  $tabela += ('| ' + $r.server_date + ' | ' + $ok + ' | ' + $r.versao_em_memoria +
              ' | ' + $(if ($f) { $f.sinais } else { '-' }) +
              ' | ' + $(if ($f) { $f.allow_trade_bloqueios } else { '-' }) +
              ' | ' + $(if ($f) { $f.exec_fail } else { '-' }) +
              ' | ' + $(if ($f) { $f.trades } else { '-' }) +
              ' | ' + $(if ($c) { $c.pl_dia } else { '-' }) +
              ' | ' + $(if ($c) { $c.amplitude_pct } else { '-' }) +
              ' | ' + $r.ia_disponiveis_n +
              ' | ' + $r.webrequest_1003 + ' |')
}
$tabela += ''
$tabela += ('**Declarado:** ' + $(if ($declarado) { $declarado.versao + ' MD5 ' + $declarado.md5 + ' (' + $declarado.ex5_bytes + ' B)' } else { 'NADA - ainda nao declarado' }))
if ($divergente) {
  $tabela += ''
  $tabela += '> **VERMELHO: MD5 DIVERGENTE.** O binario em disco NAO e o declarado. Pela regra D-139/D-141 os 30 dias voltam a zero.'
}
[System.IO.File]::WriteAllLines($md, $tabela, (New-Object System.Text.UTF8Encoding($false)))

Say ("-> " + $jsonl)
Say ("-> " + $md)

if ($divergente) {
  Write-Host "VERMELHO: MD5 divergente. Em disco=$md5Atual declarado=$md5Declarado. Os 30 dias vao a zero ate novo deploy declarado." -ForegroundColor Red
  exit 2
}
Write-Host ("OK forward: " + $serverDate + " | sinais=" + $(if ($funil) { $funil.sinais } else { '?' }) +
            " | trades=" + $(if ($funil) { $funil.trades } else { '?' }) +
            " | IA=" + $gwDisponiveis.Count + " simbolos | 1003=" + $timeouts) -ForegroundColor Green
exit 0
