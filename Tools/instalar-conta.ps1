<#
=====================================================================
 instalar-conta.ps1 - instalar o EA numa SEGUNDA conta (ex.: Headway)
=====================================================================
 O MT5 e UMA instalacao com VARIAS contas, cada uma na sua pasta de
 terminal. Para operar noutra conta (hw.site = Headway, com missoes) o
 EA tem de existir na pasta dessa conta.

 DUAS REGRAS QUE ESTE SCRIPT IMPOE (e que nao podem ser negociadas):

 1. **NUNCA tocar na pasta do forward.** A conta do forward de 30 dias
    (MetaQuotes-Demo 113568614) vive em
    `Terminal\D0E8209F77C8CF37AD8BF550E51FF075`. Se a pasta alvo for
    essa, o script RECUSA. Mexer nela reinicia a janela de 30 dias e
    contamina a medicao do G11.

 2. **MagicNumber DIFERENTE por conta.** O forward usa 2026001. A conta
    nova usa outra (por omissao 2026002). O `CheckDailyLoss`/`CheckDaily-
    Drawdown` somam por magic, e o `full_audit.csv`/
    `forward_test_events.csv` (de onde sai o PF do G11) sao por magic:
    sem isto, as duas contas entram na mesma medicao.

 Passos:
   1. copia as fontes do EA para `MQL5\Experts\XAU_AI_PRO` da conta nova;
   2. copia o `.env` (o token do gateway) para `MQL5\Files\XAU_AI_PRO\`;
      o EA le o token de la, e nao do input - a fonte continua a ser uma;
   3. gera o template com a cadeia de 323 pares e o MagicNumber novo;
   4. diz os passos de GUI ao DONO (nao ha como os fazer por script).

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\instalar-conta.ps1 -TerminalHash <hash>
   ... -Magic 2026002
   ... -DryRun
=====================================================================
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$TerminalHash,
  [int]$Magic = 2026002,
  [string]$Raiz = '',
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if ($Raiz -eq '') { $Raiz = Split-Path -Parent $PSScriptRoot }
$Raiz = (Resolve-Path -LiteralPath $Raiz).Path

$HASH_FORWARD = 'D0E8209F77C8CF37AD8BF550E51FF075'
if ($TerminalHash -eq $HASH_FORWARD) {
  Write-Host "RECUSADO: essa e a pasta do FORWARD de 30 dias (MetaQuotes-Demo)." -ForegroundColor Red
  Write-Host "Instalar aqui reinicia a janela de 30 dias e contamina o G11." -ForegroundColor Red
  exit 4
}

$termBase = Join-Path $env:APPDATA ("MetaQuotes\Terminal\" + $TerminalHash)
if (-not (Test-Path -LiteralPath $termBase)) {
  Write-Host "ERRO: pasta de terminal inexistente: $termBase" -ForegroundColor Red
  Write-Host "Faca login na conta nova no MT5 (o terminal cria a pasta) e volte a correr." -ForegroundColor Yellow
  exit 1
}

$origem = Join-Path $Raiz 'Experts\XAU_AI_PRO'
$destEA  = Join-Path $termBase 'MQL5\Experts\XAU_AI_PRO'
$destEnv = Join-Path $termBase 'MQL5\Files\XAU_AI_PRO'
$destTpl = Join-Path $termBase 'MQL5\Profiles\Templates'

Write-Host ("terminal alvo : {0}" -f $termBase)
Write-Host ("origem do EA  : {0}" -f $origem)
Write-Host ("magic         : {0} (o forward usa 2026001)" -f $Magic)

# ---- 1. fontes do EA -------------------------------------------------------
$ficheiros = @(Get-ChildItem -LiteralPath $origem -Recurse -File -Include *.mq5,*.mqh,*.mqproj -ErrorAction SilentlyContinue)
Write-Host ("fontes do EA  : {0} ficheiro(s)" -f $ficheiros.Count)

# ---- 2. template com a cadeia de 323 pares e o magic novo ------------------
$tplOrigem = Join-Path $Raiz 'Files\XAU_AI_PRO\MQL5\Profiles\Templates\PROBE_chart01.tpl'
if (-not (Test-Path -LiteralPath $tplOrigem)) {
  $cands = @(Get-ChildItem -LiteralPath (Join-Path $env:APPDATA 'MetaQuotes\Terminal') -Recurse -Filter 'PROBE_chart01.tpl' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  if ($cands.Count -gt 0) { $tplOrigem = $cands[0].FullName }
}
if (-not (Test-Path -LiteralPath $tplOrigem)) { Write-Host "ERRO: template PROBE_chart01.tpl nao encontrado" -ForegroundColor Red; exit 1 }

$tpl = [System.IO.File]::ReadAllText($tplOrigem, [System.Text.Encoding]::Unicode)
$antesMagic = ([regex]::Match($tpl, 'MagicNumber=([0-9]+)')).Groups[1].Value
$tplNova = [regex]::Replace($tpl, 'MagicNumber=[0-9]+', ('MagicNumber=' + $Magic))
# o comentario de conta deve dizer que conta e, para nao se confundir
$tplNova = [regex]::Replace($tplNova, '(?m)^(<description>).*?(</description>)', '${1}HEADWAY magic ' + $Magic + '${2}')
$nPares = ([regex]::Matches($tplNova, '(?m)^\s*[A-Za-z_][A-Za-z0-9_]*=')).Count
Write-Host ("template     : {0}" -f (Split-Path $tplOrigem -Leaf))
Write-Host ("pares       : {0} | MagicNumber {1} -> {2}" -f $nPares, $antesMagic, $Magic)

# ---- 3. .env (o token do gateway) ----------------------------------------
$envOrigem = Join-Path $Raiz 'Files\XAU_AI_PRO\.env'
$envDest = Join-Path $destEnv '.env'
$envOk = (Test-Path -LiteralPath $envOrigem)

if ($DryRun) {
  Write-Host ''
  Write-Host 'DRY RUN - nada foi escrito:' -ForegroundColor Yellow
  Write-Host ("  copiar {0} ficheiros para {1}" -f $ficheiros.Count, $destEA)
  Write-Host ("  escrever template em {0}\HEADWAY_{1}.tpl" -f $destTpl, $Magic)
  if ($envOk) { Write-Host ("  copiar .env para {0}" -f $envDest) }
  exit 0
}

# fontes
if (-not (Test-Path -LiteralPath $destEA)) { New-Item -ItemType Directory -Path $destEA -Force | Out-Null }
$n = 0
foreach ($f in $ficheiros) {
  $rel = $f.FullName.Substring($origem.Length).TrimStart('\')
  $d = Join-Path $destEA $rel
  $dir = Split-Path $d -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Copy-Item -LiteralPath $f.FullName -Destination $d -Force
  $n++
}
Write-Host ("OK fontes    : {0} copiados para {1}" -f $n, $destEA) -ForegroundColor Green

# .env
if ($envOk) {
  if (-not (Test-Path -LiteralPath $destEnv)) { New-Item -ItemType Directory -Path $destEnv -Force | Out-Null }
  Copy-Item -LiteralPath $envOrigem -Destination $envDest -Force
  Write-Host ("OK .env      : {0} (o EA le o token do gateway de ca)" -f $envDest) -ForegroundColor Green
} else {
  Write-Host 'AVISO: .env de origem nao encontrado - o EA nao tera token do gateway.' -ForegroundColor Yellow
}

# template
if (-not (Test-Path -LiteralPath $destTpl)) { New-Item -ItemType Directory -Path $destTpl -Force | Out-Null }
$tplDest = Join-Path $destTpl ('HEADWAY_' + $Magic + '.tpl')
[System.IO.File]::WriteAllText($tplDest, $tplNova, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("OK template : {0}" -f $tplDest) -ForegroundColor Green

# verificacao por hash
$exemplos = @()
foreach ($f in @($ficheiros | Where-Object { $_.Name -match 'XAU_AI_PRO\.mq5$|Config\.mqh$|VersionManager\.mqh$' })) {
  $rel = $f.FullName.Substring($origem.Length).TrimStart('\')
  $d = Join-Path $destEA $rel
  if (Test-Path -LiteralPath $d) {
    $h1 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $h2 = (Get-FileHash -LiteralPath $d -Algorithm SHA256).Hash
    $exemplos += ("  {0,-22} {1}" -f $rel, $(if ($h1 -eq $h2) { 'OK' } else { 'DIVERGE' }))
  }
}
if ($exemplos.Count -gt 0) { Write-Host 'verificacao:'; $exemplos | ForEach-Object { Write-Host $_ } }

Write-Host ''
Write-Host 'PASSOS DE GUI (so o DONO os pode fazer):' -ForegroundColor Cyan
Write-Host ("  1. MT5 > Ficheiro > Login to Trade Account: login e servidor da conta Headway")
Write-Host ("  2. Abrir um grafico (ex.: EURUSD M15) e aplicar o template: {0}" -f (Split-Path $tplDest -Leaf))
Write-Host ("  3. F7 > Comum > 'Permitir negociacao algoritmica'  (o bit e por grafico)")
Write-Host ("  4. Repetir o template nos restantes simbolos")
Write-Host ("  5. VERIFICAR: [START] XAU_AI_PRO v1.2.203 | simbolo=<s> | conta=<login da conta nova>")
Write-Host ''
Write-Host ("ATENCAO: o forward de 30 dias (MetaQuotes-Demo) fica intacto - MagicNumber {0} vs {1}." -f $Magic, 2026001) -ForegroundColor DarkGray
exit 0
