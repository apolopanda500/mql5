<#
=====================================================================
 limpar-windows.ps1 - limpeza de lixo REGENERAVEL do Windows
=====================================================================
 So apaga o que o Windows refaz sozinho. NUNCA toca em: Programs,
 Windows\Installer, ProgramData\Package Cache, pagefile.sys, swapfile.sys,
 registos, perfis de utilizador, .git, .venv, node_modules, bases de dados
 do MT5, modelos .pkl nem dados do projeto.

 Itens da whitelist:
   1. CrashDumps do utilizador e do Windows
   2. Logs CBS/DISM antigos
   3. Cache de download do Windows Update (com os servicos parados)
   4. Relatorios de erro do Windows (WER)
   5. $WINDOWS.~BT (restos de upgrade)
   6. Temporarios com mais de 2 dias (utilizador e Windows\Temp)
   7. Reciclagem
   8. DISM /StartComponentCleanup (WinSxS) - o maior ganho

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\limpar-windows.ps1
   ... -DryRun
   ... -SemDism     (pular a limpeza de componentes, que demora minutos)
=====================================================================
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$SemDism
)

$ErrorActionPreference = 'Continue'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$relatorio = @()
$total = 0

function Tam([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return 0 }
  $s = (Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  if ($s -eq $null) { return 0 }
  return [int64]$s
}

function Limpar([string]$rotulo, [string]$p, [int]$diasMin = 0, [scriptblock]$filtro = $null) {
  if (-not (Test-Path -LiteralPath $p)) { return }
  $antes = Tam $p
  if ($antes -eq 0) { return }
  $itens = @(Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue)
  if ($diasMin -gt 0) {
    $limite = (Get-Date).AddDays(-$diasMin)
    $itens = @($itens | Where-Object { $_.LastWriteTime -lt $limite })
  }
  if ($filtro) { $itens = @($itens | Where-Object { & $filtro $_ }) }
  if ($itens.Count -eq 0) { return }
  $bytes = [int64](($itens | Measure-Object Length -Sum).Sum)
  if ($DryRun) {
    $script:relatorio += ('[DRY] {0,-42} {1,7} MB em {2} ficheiro(s)' -f $rotulo, [math]::Round($bytes / 1MB, 1), $itens.Count)
    $script:total += $bytes
    return
  }
  foreach ($i in $itens) { Remove-Item -LiteralPath $i.FullName -Force -ErrorAction SilentlyContinue }
  $depois = Tam $p
  $libertado = $antes - $depois
  $script:relatorio += ('[OK]   {0,-42} {1,7} MB libertados' -f $rotulo, [math]::Round($libertado / 1MB, 1))
  $script:total += $libertado
}

function Vazio([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return }
  Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.PSIsContainer) { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    else { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
  }
}

Write-Host ("livre ANTES : {0} MB" -f [math]::Round((Get-PSDrive C).Free / 1MB, 0)) -ForegroundColor Cyan

# 1. crash dumps
Limpar 'CrashDumps (utilizador)' "$env:LOCALAPPDATA\CrashDumps"
Limpar 'CrashDumps (Windows)' 'C:\Windows\Minidump'
Limpar 'MEMORY.DMP' 'C:\Windows' 0 { param($f) $f.Name -eq 'MEMORY.DMP' }

# 2. logs de manutencao
Limpar 'Logs CBS' 'C:\Windows\Logs\CBS' 2
Limpar 'Logs DISM' 'C:\Windows\Logs\DISM' 2
Limpar 'Logs de servicing (panther)' 'C:\Windows\Logs\Panther' 2

# 3. cache do Windows Update (com os servicos parados)
if (-not $DryRun) {
  foreach ($svc in @('wuauserv', 'bits')) {
    try { Stop-Service -Name $svc -Force -ErrorAction Stop } catch { }
  }
}
Limpar 'Cache de download do Windows Update' 'C:\Windows\SoftwareDistribution\Download'
if (-not $DryRun) {
  foreach ($svc in @('wuauserv', 'bits')) {
    try { Start-Service -Name $svc -ErrorAction SilentlyContinue } catch { }
  }
}

# 4. relatorios de erro
Limpar 'Relatorios de erro (WER)' 'C:\ProgramData\Microsoft\Windows\WER' 2

# 5. restos de upgrade
Limpar 'Restos de upgrade ($WINDOWS.~BT)' 'C:\WINDOWS.~BT'

# 6. temporarios
Limpar 'Temporarios do Windows' 'C:\Windows\Temp' 2
Limpar 'Temporarios do utilizador' $env:TEMP 2
Limpar 'Temporarios locais' "$env:LOCALAPPDATA\Temp" 2

# 7. reciclagem
if (-not $DryRun) {
  try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch { }
}

# 8. componentes do Windows (WinSxS) - o maior ganho, demora
if (-not $SemDism) {
  Write-Host ''
  Write-Host 'DISM /StartComponentCleanup (pode demorar varios minutos)...' -ForegroundColor Cyan
  $antes = [int64](Get-PSDrive C).Free
  if ($DryRun) {
    $relatorio += '[DRY] DISM /StartComponentCleanup (WinSxS, 16 GB na pasta) - nao executado'
  } else {
    $out = & dism.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1
    $depois = [int64](Get-PSDrive C).Free
    $lib = $depois - $antes
    $relatorio += ('[OK]   {0,-42} {1,7} MB libertados' -f 'DISM StartComponentCleanup', [math]::Round($lib / 1MB, 1))
    $total += $lib
  }
}

Write-Host ''
$relatorio | ForEach-Object { Write-Host ("  " + $_) }
Write-Host ''
Write-Host ("TOTAL libertado : {0} MB" -f [math]::Round($total / 1MB, 0)) -ForegroundColor Green
Write-Host ("livre DEPOIS    : {0} MB" -f [math]::Round((Get-PSDrive C).Free / 1MB, 0)) -ForegroundColor Green
Write-Host ''
Write-Host 'NAO foi tocado: Windows\Installer, ProgramData\Package Cache, pagefile.sys, swapfile.sys, registos, perfis, .git, .venv, node_modules, bases de dados do MT5, modelos .pkl, dados do projeto.' -ForegroundColor DarkGray
exit 0
