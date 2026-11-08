# compile-ea.ps1 - compile do XAU_AI_PRO com COPIA DE SEGURANCA antes do compile
#
# REGRA ADOPTADA EM 07/11/2026 (D-091 / P1.2342):
#   O MetaEditor APAGA o .ex5 quando o compile falha. Medido: entre 19:28:35
#   (compile falhado) e 19:30:46 (compile bom) a frota de 15 graficos esteve
#   sem binario no disco. Por isso este script copia o .ex5 que esta em
#   producao para MQL5\Files\Backup antes de chamar o compilador: um compile
#   falhado deixa de poder apontar a frota para o vazio.
#
# Uso:
#   .\compile-ea.ps1              copia para Backup, compila, mede o resultado
#   .\compile-ea.ps1 -NoCompile   so faz a copia de seguranca (teste da regra)
#
# Nao toca em fontes, inputs, graficos nem na conta. Nao arma execucao.

param(
   [switch]$NoCompile
)

$ErrorActionPreference = 'Stop'

# MD5 por .NET: nao depende de Get-FileHash (ausente em alguns hosts/runspaces
# deste ambiente) e devolve sempre o mesmo formato de 32 hex maiusculos.
function Get-Md5Hex([string]$Path) {
   $md5 = [System.Security.Cryptography.MD5]::Create()
   try {
      $fs = [System.IO.File]::OpenRead($Path)
      try {
         return ([BitConverter]::ToString($md5.ComputeHash($fs)) -replace '-', '')
      }
      finally { $fs.Dispose() }
   }
   finally { $md5.Dispose() }
}

$Mql5    = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$EaDir   = Join-Path $Mql5 'Experts\XAU_AI_PRO'
$Source  = Join-Path $EaDir 'XAU_AI_PRO.mq5'
$Ex5     = Join-Path $EaDir 'XAU_AI_PRO.ex5'
$Backup  = Join-Path $Mql5 'Files\Backup'
$MetaEditor = 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'

if (-not (Test-Path -LiteralPath $Source)) {
   throw "fonte nao encontrada: $Source"
}

# Versao legivel: a fonte canonica e EA_VERSION_STRING.
$ver = 'desconhecida'
$vm = Join-Path $EaDir 'Enterprise\VersionManager.mqh'
if (Test-Path -LiteralPath $vm) {
   $m = [regex]::Match((Get-Content -LiteralPath $vm -Raw), '#define\s+EA_VERSION_STRING\s+"([^"]+)"')
   if ($m.Success) { $ver = $m.Groups[1].Value }
}

if (-not (Test-Path -LiteralPath $Backup)) {
   New-Item -ItemType Directory -Path $Backup -Force | Out-Null
}

# 1. Copia de seguranca do binario que esta em producao.
$backupPath = $null
if (Test-Path -LiteralPath $Ex5) {
   $stamp = (Get-Date -Format 'yyyyMMdd_HHmmss')
   $safeVer = $ver -replace '[^0-9A-Za-z]', ''
   $backupPath = Join-Path $Backup ("XAU_AI_PRO_v{0}_{1}.ex5" -f $safeVer, $stamp)
   Copy-Item -LiteralPath $Ex5 -Destination $backupPath -Force
   $h = Get-Md5Hex $backupPath
   Write-Output ("[BACKUP] {0} ({1} B) MD5 {2}" -f (Split-Path -Leaf $backupPath), (Get-Item -LiteralPath $backupPath).Length, $h)
}
else {
   Write-Output '[BACKUP] nao havia .ex5 para copiar (frota ja sem binario no disco)'
}

if ($NoCompile) {
   Write-Output '[DRY] -NoCompile: copia feita, compilador nao chamado.'
   exit 0
}

# 2. Compile.
$log = Join-Path $env:TEMP ('compile_xau_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
$p = Start-Process -FilePath $MetaEditor -ArgumentList "/compile:`"$Source`"", "/log:`"$log`"" -Wait -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 2

$result = 'sem linha Result no log'
if (Test-Path -LiteralPath $log) {
   $txt = Get-Content -LiteralPath $log -Encoding Unicode
   $line = $txt | Select-String -Pattern '^Result:' | Select-Object -Last 1
   if ($line) { $result = $line.Line.Trim() }
   $txt | Select-String -Pattern 'error|warning' | Where-Object { $_.Line -notmatch '^Result:' } | ForEach-Object { Write-Output ('  ' + $_.Line.Trim()) }
}

Write-Output ("[COMPILE] {0}" -f $result)

# 3. Estado do binario. Sem .ex5 nao ha sucesso, diga o que disser o log.
if (-not (Test-Path -LiteralPath $Ex5)) {
   Write-Output '[FALHA] .ex5 AUSENTE apos o compile. Restaurar do Backup (o mais recente em Files\Backup).'
   if ($backupPath) { Write-Output ("         candidato: {0}" -f $backupPath) }
   exit 1
}

$info = Get-Item -LiteralPath $Ex5
$md5  = Get-Md5Hex $Ex5
Write-Output ("[EX5] {0} B | {1} | MD5 {2}" -f $info.Length, $info.LastWriteTime.ToString('dd/MM HH:mm:ss'), $md5)

if ($result -match '0 errors') { exit 0 } else { exit 1 }
