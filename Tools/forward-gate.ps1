<#
=====================================================================
 forward-gate.ps1 - medicao diaria do forward de 30 dias (G11)
=====================================================================
 SEM DEPENDENCIA DE MODULOS: usa apenas cmdlets do modulo Management
 (Get-Item, Get-ChildItem, Test-Path, Get-Content) e .NET puro. O
 modulo Utility NAO carrega no Windows PowerShell 5.1 desta maquina
 (medido 10/11/2026: `Get-FileHash` nao e reconhecido), por isso o hash
 e calculado com `System.Security.Cryptography.MD5` e nenhuma selecao
 usa `Select-Object`/`Where-Object`/`Measure-Object`.

 O que mede, todos os dias, com numero e hora:
   1. MD5 do .ex5 em disco vs MD5 DECLARADO. Divergencia = janela a zero.
   2. Versoes a correr ([START]) - um build novo divide os 30 dias.
   3. Funil: visitas, sinais, AllowTrade (bloqueios), ExecFail, trades.
   4. Cobertura de IA: simbolos do universo com previsao real.
   5. P/L do dia, trades do dia, PerdaDia %, Amplitude (DD) % do [STATUS].
   6. Traces de execucao e `HTTP 1003`.

 Escreve:
   EQUIPE/FORWARD/medicao.jsonl   (uma linha por dia do servidor)
   EQUIPE/FORWARD/FORWARD.md      (tabela viva, legivel pelo DONO)

 Saida: 0 = conforme | 2 = MD5 divergiu (janela perdida) | 1 = erro

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\forward-gate.ps1
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

$equipe = Join-Path $Root 'Experts\XAU_AI_PRO\EQUIPE'
$fwdDir = Join-Path $equipe 'FORWARD'
$ex5    = Join-Path $Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
$logDir = Join-Path $Root 'Logs'
$appDir = Join-Path $Root 'Files\XAU_AI_PRO'
$jsonl  = Join-Path $fwdDir 'medicao.jsonl'
$md     = Join-Path $fwdDir 'FORWARD.md'
$decl   = Join-Path $fwdDir 'DECLARADO.json'

$OffsetServidorHoras = 3

function Say($t) { if ($Detalhe) { Write-Host $t } }

function Get-MD5([string]$Path) {
  $fs = [System.IO.File]::OpenRead($Path)
  try {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = $md5.ComputeHash($fs)
    return ([System.BitConverter]::ToString($bytes) -replace '-', '')
  } finally { $fs.Close() }
}

# IMPRESSAO DIGITAL DA GOVERNANCA DOS MODELOS.
#
# PORQUE EXISTE (medido 10/11/2026, D-162): o binario esta no MD5, mas o
# CONJUNTO DE MODELOS que o gateway serve NAO esta. O `publicable`, o
# `min_edge` e o `publish_reason` vivem em `Python\models\*.meta.json` - e o
# EA decide com eles. Um reinicio do gateway, ou uma publicacao nova de
# modelos, muda o comportamento do EA **com o mesmo binario**: os 30 dias
# mediam um alvo que se mexe. Por isso o `.ex5` E a governanca entram os dois
# na declaracao, e a mudanca da governanca e registada como evento.
function Get-Governanca([string]$ModelosDir) {
  if (-not (Test-Path -LiteralPath $ModelosDir)) { return @{ sha256 = ''; n = 0 } }
  $nomes = @()
  foreach ($f in @(Get-ChildItem -LiteralPath $ModelosDir -Filter '*.meta.json' -ErrorAction SilentlyContinue)) { $nomes += $f.Name }
  [Array]::Sort($nomes)
  $sb = New-Object System.Text.StringBuilder
  $n = 0
  foreach ($nome in $nomes) {
    $p = Join-Path $ModelosDir $nome
    $null = $sb.Append($nome + ':' + (Get-MD5 $p) + "`n")
    $n++
  }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))
  return @{ sha256 = ([System.BitConverter]::ToString($bytes) -replace '-', ''); n = $n }
}

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
$ex5Info = $null
if (Test-Path -LiteralPath $ex5) {
  $ex5Info = Get-Item -LiteralPath $ex5
  $md5Atual = Get-MD5 $ex5
}

$declarado = $null
if (Test-Path -LiteralPath $decl) {
  try { $declarado = Get-Content -LiteralPath $decl -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $declarado = $null }
}
$md5Declarado = ''; $versaoDeclarada = ''
if ($declarado) {
  $md5Declarado = [string]$declarado.md5
  $versaoDeclarada = [string]$declarado.versao
}
$divergente = ($md5Declarado -ne '' -and $md5Atual -ne $md5Declarado)

# governanca dos modelos (ver Get-Governanca): o binario esta no MD5, os
# modelos NAO - e o EA decide com os dois.
$gov = Get-Governanca (Join-Path $appDir 'Python\models')
$govDeclarada = ''
if ($declarado -and $declarado.PSObject.Properties.Name -contains 'governanca_sha256') { $govDeclarada = [string]$declarado.governanca_sha256 }
$govMudou = ($govDeclarada -ne '' -and $gov.sha256 -ne $govDeclarada)

# ---------------------------------------------------------------- logs
$serverNow = (Get-Date).AddHours($OffsetServidorHoras)
$serverDate = $serverNow.ToString('yyyy-MM-dd')

$logFiles = @()
if (Test-Path -LiteralPath $logDir) {
  $todos = @(Get-ChildItem -LiteralPath $logDir -Filter '*.log' -ErrorAction SilentlyContinue)
  foreach ($lf in $todos) {
    if ($lf.LastWriteTime -ge (Get-Date).AddDays(-2)) { $logFiles += $lf }
  }
}
$texto = ''
foreach ($lf in $logFiles) { $texto += (Ler-LogLocal $lf.FullName) + "`n" }
$linhas = @($texto -split "`r?`n")
Say ("linhas lidas: " + $linhas.Count)

# [START] por versao
$versoes = @{}
$nStarts = 0
foreach ($l in $linhas) {
  if ($l -match '\[START\] XAU_AI_PRO\s+(v[0-9.]+)') {
    $v = $Matches[1]; $nStarts++
    if (-not $versoes.ContainsKey($v)) { $versoes[$v] = 0 }
    $versoes[$v] = $versoes[$v] + 1
  }
}
$versaoCorrer = ''
$melhor = -1
foreach ($k in $versoes.Keys) { if ($versoes[$k] -gt $melhor) { $melhor = $versoes[$k]; $versaoCorrer = $k } }

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

# [STATUS] HEALTHY
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

# IA: simbolos com previsao real no log
$iaSimbolos = @{}
$n1003 = 0
$nPipeline = 0
$nSucesso = 0
foreach ($l in $linhas) {
  if ($l -match '\[AI\] PYTHON \| (\w+) \|') { $iaSimbolos[$Matches[1]] = $true }
  if ($l -match 'HTTP 1003') { $n1003++ }
  if ($l -match '\[TRADE PIPELINE\]') { $nPipeline++ }
  if ($l -match '\[SCANNER\] TRADE SUCCESS') { $nSucesso++ }
}

# gateway: available=true por simbolo
$token = ''
$envFile = Join-Path $appDir '.env'
if (Test-Path -LiteralPath $envFile) {
  foreach ($l in @(Get-Content -LiteralPath $envFile -Encoding UTF8)) {
    if ($l -match 'XAU_GATEWAY_TOKEN') { $token = ($l -split '=')[1].Trim(); break }
  }
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

# ---------------------------------------------------------------- registo
if (-not (Test-Path -LiteralPath $fwdDir)) { New-Item -ItemType Directory -Path $fwdDir -Force | Out-Null }

$iaLista = @()
foreach ($k in $iaSimbolos.Keys) { $iaLista += $k }
[Array]::Sort($iaLista)

$registo = [ordered]@{
  server_date       = $serverDate
  medido_local      = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss')
  md5_ex5           = $md5Atual
  md5_declarado     = $md5Declarado
  md5_divergente    = $divergente
  governanca_sha256 = $gov.sha256
  governanca_declarada = $govDeclarada
  governanca_mudou   = $govMudou
  governanca_modelos = $gov.n
  ex5_bytes         = if ($ex5Info) { $ex5Info.Length } else { 0 }
  ex5_mtime         = if ($ex5Info) { $ex5Info.LastWriteTime.ToString('dd/MM HH:mm:ss') } else { '' }
  versao_declarada  = $versaoDeclarada
  versao_em_memoria = $versaoCorrer
  starts_total      = $nStarts
  funil             = $funil
  conta             = $conta
  ia_simbolos_log   = $iaLista
  ia_available_gw   = $gwDisponiveis
  ia_disponiveis_n  = $gwDisponiveis.Count
  trade_pipeline    = $nPipeline
  trade_success     = $nSucesso
  webrequest_1003   = $n1003
}

[System.IO.File]::AppendAllText($jsonl, (($registo | ConvertTo-Json -Compress -Depth 6) + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))

# tabela md
$mdLines = @()
if (Test-Path -LiteralPath $jsonl) {
  foreach ($l in @(Get-Content -LiteralPath $jsonl -Encoding UTF8)) {
    if ($l.Trim() -ne '') { $mdLines += ($l | ConvertFrom-Json) }
  }
}
$tabela = @()
$tabela += '# FORWARD 30 DIAS - G11 (medicao diaria automatica)'
$tabela += ''
$tabela += ("Gerado por ``Tools\forward-gate.ps1``. Dia do servidor = local + $OffsetServidorHoras h.")
$tabela += ''
$tabela += '| Dia servidor | MD5 ok | Gov. ok | Ver. memoria | Sinais | AllowTrade(bloq) | ExecFail | Trades | P/L dia | DD % | IA disp. | 1003 |'
$tabela += '|---|---|---|---|---|---|---|---|---|---|---|---|'
foreach ($r in $mdLines) {
  $f = $r.funil; $c = $r.conta
  $ok = if ($r.md5_divergente) { 'NAO' } else { 'sim' }
  $gok = if ($r.governanca_mudou) { 'MUDOU' } else { 'sim' }
  $sin = '-'; $alt = '-'; $exf = '-'; $trd = '-'
  if ($f) { $sin = $f.sinais; $alt = $f.allow_trade_bloqueios; $exf = $f.exec_fail; $trd = $f.trades }
  $pl = '-'; $dd = '-'
  if ($c) { $pl = $c.pl_dia; $dd = $c.amplitude_pct }
  $tabela += ('| ' + $r.server_date + ' | ' + $ok + ' | ' + $gok + ' | ' + $r.versao_em_memoria + ' | ' + $sin +
              ' | ' + $alt + ' | ' + $exf + ' | ' + $trd + ' | ' + $pl + ' | ' + $dd +
              ' | ' + $r.ia_disponiveis_n + ' | ' + $r.webrequest_1003 + ' |')
}
$tabela += ''
$tabela += ('**Declarado:** ' + $(if ($declarado) { $declarado.versao + ' MD5 ' + $declarado.md5 + ' (' + $declarado.ex5_bytes + ' B)' } else { 'NADA - ainda nao declarado' }))
$tabela += ''
$tabela += ('**Governanca dos modelos:** ' + $gov.sha256 + ' (' + $gov.n + ' meta.json) - o binario esta no MD5, os modelos NAO: esta impressao e o que impede os 30 dias de medirem um alvo que se mexe.')
if ($divergente) {
  $tabela += ''
  $tabela += '> **VERMELHO: MD5 DIVERGENTE.** O binario em disco NAO e o declarado. Pela regra D-139/D-141 os 30 dias voltam a zero.'
}
if ($govMudou) {
  $tabela += ''
  $tabela += '> **AMARELO: GOVERNANCA MUDOU.** O conjunto de .meta.json em vigor ja nao e o declarado. O EA pode estar a decidir com outros modelos COM O MESMO BINARIO. Registar o porquê.'
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
            " | IA=" + $gwDisponiveis.Count + " simbolos | 1003=" + $n1003) -ForegroundColor Green
exit 0
