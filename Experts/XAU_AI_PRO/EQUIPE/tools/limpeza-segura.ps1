# limpeza-segura.ps1 - limpeza do Windows sem tocar em projetos, backups ou dados
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\limpeza-segura.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\limpeza-segura.ps1 -Executar
#
# Sem -Executar: mede e lista o que faria. Com -Executar: limpa.
#
# Limpa apenas:
#   - ficheiros em %TEMP% com mais de 7 dias;
#   - cache do npm;
#   - caches de browser (Edge/Chrome) SE os processos estiverem fechados;
#   - logs do MetaTrader com mais de 60 dias (mantem os recentes).
#
# NUNCA toca em: projetos, git, backups, Downloads, Documentos, lixeira,
# historico de conta, modelos, dados.
#
# BASE: D-097 (limpeza com backup) / D-099 (ambiente).

param(
   [switch]$Executar
)

$ErrorActionPreference = 'Continue'

function Get-SizeMB([string]$Path) {
   if (-not (Test-Path -LiteralPath $Path)) { return 0 }
   $s = (Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
   if (-not $s) { return 0 }
   return [math]::Round($s / 1MB, 1)
}

function Get-FreeGB {
   return [math]::Round((Get-PSDrive C).Free / 1GB, 2)
}

$antes = Get-FreeGB
Write-Output ''
Write-Output '===== LIMPEZA SEGURA ====='
Write-Output ("modo            : {0}" -f $(if ($Executar) { 'EXECUTAR' } else { 'simulacao (use -Executar)' }))
Write-Output ("disco C: livre  : {0} GB" -f $antes)
Write-Output ''

$alvos = @()

$temp = $env:TEMP
$velhos = @(Get-ChildItem -LiteralPath $temp -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) })
$alvos += [pscustomobject]@{ Nome = 'TEMP > 7 dias'; Caminho = $temp; Itens = $velhos.Count; MB = (($velhos | ForEach-Object { Get-SizeMB $_.FullName } | Measure-Object -Sum).Sum) }

$npm = Join-Path $env:LOCALAPPDATA 'npm-cache'
$alvos += [pscustomobject]@{ Nome = 'cache npm'; Caminho = $npm; Itens = 0; MB = (Get-SizeMB $npm) }

foreach ($b in @(
   @{ Nome = 'cache Edge'; Caminho = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data\Default\Cache'); Proc = 'msedge' },
   @{ Nome = 'cache Chrome'; Caminho = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default\Cache'); Proc = 'chrome' }
)) {
   $corre = @(Get-Process -Name $b.Proc -ErrorAction SilentlyContinue).Count -gt 0
   $alvos += [pscustomobject]@{ Nome = $(if ($corre) { $b.Nome + ' (browser aberto - ignorado)' } else { $b.Nome }); Caminho = $b.Caminho; Itens = 0; MB = (Get-SizeMB $b.Caminho) }
}

$mt5Logs = 'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Logs'
$logsVelhos = @(Get-ChildItem -LiteralPath $mt5Logs -Filter '*.log' -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-60) })
$alvos += [pscustomobject]@{ Nome = 'logs MT5 > 60 dias'; Caminho = $mt5Logs; Itens = $logsVelhos.Count; MB = (($logsVelhos | Measure-Object Length -Sum).Sum / 1MB) }

foreach ($a in $alvos) {
   Write-Output ("  {0,-32} {1,8:N1} MB  {2}" -f $a.Nome, [math]::Round($a.MB, 1), $a.Caminho)
}

if (-not $Executar) {
   Write-Output ''
   Write-Output 'Nada foi alterado. Para limpar: repita com -Executar.'
   Write-Output '=========================='
   exit 0
}

# --- executar ---
foreach ($f in $velhos) { Remove-Item -LiteralPath $f.FullName -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path -LiteralPath $npm) { & cmd /c "npm cache clean --force" *> $null }

foreach ($b in @(
   @{ Caminho = (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data\Default\Cache'); Proc = 'msedge' },
   @{ Caminho = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default\Cache'); Proc = 'chrome' }
)) {
   if (@(Get-Process -Name $b.Proc -ErrorAction SilentlyContinue).Count -gt 0) { continue }
   if (Test-Path -LiteralPath $b.Caminho) { Get-ChildItem -LiteralPath $b.Caminho -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
}

foreach ($f in $logsVelhos) { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }

$depois = Get-FreeGB
Write-Output ''
Write-Output ("disco C: livre  : {0} GB -> {1} GB (ganho {2:N2} GB)" -f $antes, $depois, ($depois - $antes))
Write-Output 'Projetos, git, backups, Downloads e lixeira NAO foram tocados.'
Write-Output '=========================='
