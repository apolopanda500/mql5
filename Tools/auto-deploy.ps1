<#
=====================================================================
 auto-deploy.ps1 - porta unica de "autoupdate" do XAU_AI_PRO
=====================================================================
 Ordem de execucao (para na PRIMEIRA falha):

   1. GATE HG-01 / HG-02 - confirma que a versao tripla esta coerente:
        header  // XAU_AI_PRO vX.Y.ZZZ
        #property version "A.BCD"     (BCD = Y*100+ZZZ)
        #define EA_VERSION_STRING "X.Y.ZZZ"
      Uma divergencia aqui ja custou dois ciclos (v1.2.141 vs "1.340") e
      nao e detectada pelo compilador, por isso e bloqueante.

   2. COMPILA XAU_AI_PRO.mq5 via metaeditor64.exe /compile /log /inc.

   3. Le o log (UTF-16) e exige 0 errors. Avisos sao listados.

   4. Confirma que o .ex5 foi REALMENTE publicado e e mais recente que o
      .mq5/.mqh mais recente. Justificacao: uma compilacao falhada do
      MetaEditor APAGA o .ex5 (ja aconteceu neste projecto), o que
      deixaria os 15 graficos sem binario no proximo reload.

   5. Imprime a sequencia MCP obrigatoria de reanexacao. O reattach NAO
      pode ser feito por script: profile_apply e uma accao do servidor
      MCP do terminal, nao existe equivalente em MQL5 nem em CLI.

 Uso:
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\auto-deploy.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\auto-deploy.ps1 -Commit -Message "chore(xau): ..."
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\auto-deploy.ps1 -SkipCompile

 O que este script NAO faz (deliberado):
   - nao altera risco, inputs, .set, contas nem ordens;
   - nao faz self-update do binario a partir de git/HTTP (opcao 3 do
     ciclo 103): continua proibido sem confirmacao explicita do dono;
   - nao faz reset, checkout destrutivo, force-push nem rebase.
=====================================================================
#>
[CmdletBinding()]
param(
   # Salta a compilacao (apenas gate de versao + verificacao do .ex5 actual)
   [switch]$SkipCompile,

   # Faz commit de tudo o que mudou e push para os dois remotes
   [switch]$Commit,
   [string]$Message = '',

   [string]$Remote1 = 'github',
   [string]$Remote2 = 'origin',
   [string]$Branch  = 'main',

   # Caminho do MetaEditor (detectado automaticamente se vazio)
   [string]$MetaEditor = ''
)

$ErrorActionPreference = 'Continue'

$script:Failures = 0
$script:Mql5Root = 'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5'
$script:EaDir    = Join-Path $script:Mql5Root 'Experts\XAU_AI_PRO'
$script:EaSource = Join-Path $script:EaDir 'XAU_AI_PRO.mq5'
$script:EaEx5    = Join-Path $script:EaDir 'XAU_AI_PRO.ex5'
$script:VmFile   = Join-Path $script:EaDir 'Enterprise\VersionManager.mqh'
$script:TempDir  = Join-Path $script:Mql5Root 'Files\Temp'

function Write-Section([string]$Text) {
   Write-Host ''
   Write-Host ('=== ' + $Text + ' ===') -ForegroundColor Cyan
}
function Write-Ok([string]$Text)   { Write-Host ('  [OK]   ' + $Text) -ForegroundColor Green }
function Write-Info([string]$Text) { Write-Host ('  [..]   ' + $Text) }
function Write-Warn2([string]$Text){ Write-Host ('  [WARN] ' + $Text) -ForegroundColor Yellow }
function Write-Fail([string]$Text) {
   Write-Host ('  [FAIL] ' + $Text) -ForegroundColor Red
   $script:Failures++
}
function Exit-Gate([string]$Reason) {
   Write-Host ''
   Write-Host ('ABORTADO: ' + $Reason) -ForegroundColor Red
   exit 1
}

function Resolve-MetaEditor {
   if ($MetaEditor -and (Test-Path -LiteralPath $MetaEditor)) { return $MetaEditor }
   $cands = @(
      'C:\Program Files\MetaTrader 5\metaeditor64.exe',
      'C:\Program Files (x86)\MetaTrader 5\metaeditor64.exe',
      'C:\Program Files\MetaTrader 5\metaeditor.exe'
   )
   foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { return $c } }
   return ''
}

# ---------------------------------------------------------------------
# 1. GATE HG-01 / HG-02 - versao tripla
# ---------------------------------------------------------------------
Write-Section '1. Gate de versao (HG-01 / HG-02)'

if (-not (Test-Path -LiteralPath $script:EaSource)) { Exit-Gate ('fonte ausente: ' + $script:EaSource) }
if (-not (Test-Path -LiteralPath $script:VmFile))   { Exit-Gate ('VersionManager ausente: ' + $script:VmFile) }

$hdrLine = (Get-Content -LiteralPath $script:EaSource -TotalCount 2)[1]
if ($hdrLine -notmatch 'v(\d+)\.(\d+)\.(\d+)') {
   Exit-Gate ('header sem versao reconhecivel na linha 2: "' + $hdrLine + '"')
}
$vMaj = [int]$Matches[1]
$vMin = [int]$Matches[2]
$vPat = [int]$Matches[3]
$hdrVer = "$vMaj.$vMin.$vPat"
$expectedProp = "$vMaj." + ($vMin * 100 + $vPat)

$propRaw = (Select-String -LiteralPath $script:EaSource -Pattern '^#property\s+version').Line
if (-not $propRaw -or $propRaw -notmatch '"(\d+)\.(\d+)"') {
   Exit-Gate '#property version ausente ou fora do formato xxx.yyy'
}
$propVer = $Matches[1] + '.' + $Matches[2]

$defRaw = (Select-String -LiteralPath $script:VmFile -Pattern '#define\s+EA_VERSION_STRING').Line
if (-not $defRaw -or $defRaw -notmatch '"(\d+\.\d+\.\d+)"') {
   Exit-Gate 'EA_VERSION_STRING ausente ou fora do formato X.Y.ZZZ'
}
$defVer = $Matches[1]

Write-Info ('header              = ' + $hdrVer)
Write-Info ('#property version   = "' + $propVer + '"   (esperado "' + $expectedProp + '")')
Write-Info ('EA_VERSION_STRING   = "' + $defVer + '"')

if ($propVer -ne $expectedProp) {
   Exit-Gate ('#property version "' + $propVer + '" nao corresponde a ' + $hdrVer + ' -> devia ser "' + $expectedProp + '"')
}
if ($defVer -ne $hdrVer) {
   Exit-Gate ('EA_VERSION_STRING "' + $defVer + '" nao corresponde ao header ' + $hdrVer)
}
Write-Ok ('versao tripla coerente: ' + $hdrVer)

# ---------------------------------------------------------------------
# 2 + 3. Compilacao
# ---------------------------------------------------------------------
if ($SkipCompile) {
   Write-Section '2. Compilacao (SALTADA por -SkipCompile)'
} else {
   Write-Section '2. Compilacao via metaeditor64'
   $me = Resolve-MetaEditor
   if (-not $me) { Exit-Gate 'metaeditor64.exe nao encontrado (informe -MetaEditor)' }
   Write-Info ('compilador = ' + $me)

   if (-not (Test-Path -LiteralPath $script:TempDir)) {
      New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
   }
   $logPath = Join-Path $script:TempDir ('autodeploy_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
   $ex5Before = $null
   if (Test-Path -LiteralPath $script:EaEx5) { $ex5Before = (Get-Item -LiteralPath $script:EaEx5).LastWriteTimeUtc }

   $argList = @(
      ('/compile:' + $script:EaSource),
      ('/log:' + $logPath),
      ('/inc:' + $script:Mql5Root)
   )
   Start-Process -FilePath $me -ArgumentList $argList -NoNewWindow -Wait | Out-Null

   # MetaEditor escreve o log em UTF-16 e pode ainda estar a fechar o ficheiro
   $txt = ''
   $deadline = (Get-Date).AddSeconds(90)
   while ((Get-Date) -lt $deadline) {
      if (Test-Path -LiteralPath $logPath) {
         try { $txt = [System.IO.File]::ReadAllText($logPath, [System.Text.Encoding]::Unicode) } catch { $txt = '' }
         if ($txt -match 'Result:') { break }
      }
      Start-Sleep -Milliseconds 500
   }
   if ($txt -notmatch 'Result:') {
      Exit-Gate ('log de compilacao sem linha "Result:" (' + $logPath + ')')
   }

   $lines = $txt -split "`r?`n"
   $resLine = ($lines | Where-Object { $_ -match 'Result:' } | Select-Object -Last 1)

   $errs = -1; $warns = -1
   if ($resLine -match '(\d+)\s+errors?,\s+(\d+)\s+warnings?') {
      $errs = [int]$Matches[1]
      $warns = [int]$Matches[2]
   } else {
      Exit-Gate ('nao consegui ler a contagem de erros: "' + $resLine.Trim() + '"')
   }

   Write-Info ($resLine.Trim())
   if ($errs -gt 0) {
      $lines | Where-Object { $_ -match ': error ' } | ForEach-Object { Write-Host ('    ' + $_.Trim()) -ForegroundColor Red }
      Write-Fail ($errs.ToString() + ' erro(s) de compilacao')
      Exit-Gate 'compilacao com erros'
   }
   if ($warns -gt 0) {
      $lines | Where-Object { $_ -match ': warning ' } | ForEach-Object { Write-Host ('    ' + $_.Trim()) -ForegroundColor Yellow }
      Write-Warn2 ($warns.ToString() + ' aviso(s) - a politica do projecto pede 0/0')
   }
   Write-Ok ('compilacao limpa: ' + $errs + ' errors, ' + $warns + ' warnings')
}

# ---------------------------------------------------------------------
# 4. O .ex5 publicado e verificavel?
# ---------------------------------------------------------------------
Write-Section '3. Verificacao do .ex5 publicado'

if (-not (Test-Path -LiteralPath $script:EaEx5)) {
   Exit-Gate ('o .ex5 NAO existe em ' + $script:EaEx5 + ' (compilacao falhada apaga o binario)')
}
$ex5 = Get-Item -LiteralPath $script:EaEx5
if ($ex5.Length -le 0) { Exit-Gate 'o .ex5 tem 0 bytes' }
Write-Info ('.ex5 = ' + $ex5.Length + ' B   ' + $ex5.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))

$srcs = @(Get-Item -LiteralPath $script:EaSource)
$srcs += @(Get-ChildItem -LiteralPath $script:EaDir -Filter '*.mqh' -Recurse -File -ErrorAction SilentlyContinue)
$newest = ($srcs | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1)
Write-Info ('fonte mais recente = ' + $newest.Name + '   ' + $newest.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))

if ($newest.LastWriteTimeUtc -gt $ex5.LastWriteTimeUtc) {
   Exit-Gate ('o .ex5 (' + $ex5.LastWriteTime.ToString('HH:mm:ss') + ') e MAIS ANTIGO que ' + $newest.Name + ' (' + $newest.LastWriteTime.ToString('HH:mm:ss') + ') - compilar antes de reanexar')
}
Write-Ok '.ex5 publicado e mais recente que todas as fontes'

# ---------------------------------------------------------------------
# 5. Reattach - passo MCP obrigatorio
# ---------------------------------------------------------------------
Write-Section '4. Reattach obrigatorio (passo MCP, nao automatizavel)'
Write-Host '  O EA ficou compilado, mas os 15 graficos continuam a correr a build'
Write-Host '  ANTERIOR em memoria. Compilar nao reanexa. Executar, por esta ordem:'
Write-Host ''
Write-Host '    1) metatrader5__profile_apply  profile_name=Default'
Write-Host '    2) metatrader5__profile_apply  profile_name=XAI_P216_LIVE'
Write-Host '    3) metatrader5__get_expert_journal  filter=[START]'
Write-Host ('       esperado: [START] XAU_AI_PRO v' + $hdrVer + ' | conta=... | saldo=...') -ForegroundColor Gray
Write-Host '    4) metatrader5__get_expert_journal  filter=PRICE=0.00000   (tem de dar 0 registos)'
Write-Host ''

# ---------------------------------------------------------------------
# 6. Commit / push opcionais
# ---------------------------------------------------------------------
if ($Commit) {
   Write-Section '5. Commit e push'
   if ([string]::IsNullOrWhiteSpace($Message)) { Exit-Gate 'Commit pedido sem -Message' }

   Push-Location $script:Mql5Root
   try {
      git add -A 2>&1 | Out-Null
      git commit -m $Message 2>&1 | ForEach-Object { Write-Host ('    ' + $_) -ForegroundColor DarkGray }
      if ($LASTEXITCODE -ne 0) { Write-Warn2 'git commit devolveu codigo != 0 (nada para commitar?)' }

      foreach ($rem in @($Remote1, $Remote2)) {
         if ([string]::IsNullOrWhiteSpace($rem)) { continue }
         git push $rem $Branch 2>&1 | ForEach-Object { Write-Host ('    ' + $_) -ForegroundColor DarkGray }
         if ($LASTEXITCODE -eq 0) { Write-Ok ('push ' + $rem + '/' + $Branch) }
         else { Write-Fail ('push ' + $rem + '/' + $Branch + ' falhou') }
      }
   } finally {
      Pop-Location
   }
}

Write-Section 'RESUMO'
if ($script:Failures -eq 0) {
   Write-Host ('  PRONTO: XAU_AI_PRO v' + $hdrVer + ' compilado e verificado. Falta o reattach MCP.') -ForegroundColor Green
   exit 0
}
Write-Host ('  ' + $script:Failures + ' falha(s) - ver acima.') -ForegroundColor Red
exit 1
