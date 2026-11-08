# ambiente-check.ps1 - a maquina esta' pronta para trabalhar?
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ambiente-check.ps1
#
# Verifica: disco, ferramentas, Python/uv, MCP, tarefas e projecto. Nao altera
# nada. Sai com 1 se houver falha bloqueante.
#
# BASE: D-099 / AMBIENTE.md

$ErrorActionPreference = 'Continue'

$ok = 0; $aviso = 0; $falha = 0

function Item([string]$Nome, [string]$Estado, [string]$Detalhe) {
   $marca = switch ($Estado) { 'OK' { '[OK]   '; $script:ok++ } 'AVISO' { '[AVISO]'; $script:aviso++ } default { '[FALHA]'; $script:falha++ } }
   Write-Output ("  {0} {1,-26} {2}" -f $marca, $Nome, $Detalhe)
}

Write-Output ''
Write-Output '===== AMBIENTE ====='

$free = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
if ($free -ge 10) { Item 'disco C:' 'OK' "$free GB livres" }
elseif ($free -ge 5) { Item 'disco C:' 'AVISO' "$free GB livres (pouco; limpar com limpeza-segura.ps1)" }
else { Item 'disco C:' 'FALHA' "$free GB livres (critico)" }

foreach ($t in @(
   @{ N = 'git'; C = 'git' }, @{ N = 'node'; C = 'node' }, @{ N = 'npm'; C = 'npm' },
   @{ N = 'gh'; C = 'gh' }, @{ N = 'python'; C = 'python' }, @{ N = 'uv'; C = 'uv' },
   @{ N = 'rg'; C = 'rg' }, @{ N = 'jq'; C = 'jq' }, @{ N = '7zr'; C = '7zr' },
   @{ N = 'opencode'; C = 'opencode' }
)) {
   $cmd = Get-Command $t.C -ErrorAction SilentlyContinue
   if ($cmd) { Item $t.N 'OK' $cmd.Source }
   else {
      $local = Join-Path 'C:\AI\tools' ($t.C + '.exe')
      if (Test-Path -LiteralPath $local) {
         if ($env:Path -match [regex]::Escape('C:\AI\tools')) { Item $t.N 'OK' $local }
         else { Item $t.N 'AVISO' ($local + ' (instalado; abrir terminal novo)') }
      }
      else { Item $t.N 'AVISO' 'ausente' }
   }
}

try {
   $v = (& python --version 2>&1) -join ''
   if ($v -match '3\.1[0-9]') { Item 'python versao' 'OK' $v } else { Item 'python versao' 'AVISO' $v }
}
catch { Item 'python versao' 'AVISO' 'nao executou' }

$cfg = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
if (Test-Path -LiteralPath $cfg) {
   try {
      $j = Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
      $n = @($j.mcp.PSObject.Properties | Where-Object { $_.Value.enabled -ne $false }).Count
      if ($n -ge 8) { Item 'MCP activos' 'OK' "$n servidores" } else { Item 'MCP activos' 'AVISO' "$n servidores" }
   }
   catch { Item 'MCP activos' 'FALHA' 'opencode.json invalido' }
}
else { Item 'MCP activos' 'AVISO' 'opencode.json nao encontrado' }

$tarefas = @(Get-ScheduledTask -TaskName 'XAU_AI_PRO_*' -ErrorAction SilentlyContinue)
if ($tarefas.Count -ge 4) { Item 'tarefas Windows' 'OK' ($tarefas.Count.ToString() + ' activas') }
else { Item 'tarefas Windows' 'AVISO' ($tarefas.Count.ToString() + ' activas') }

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
if (Test-Path -LiteralPath (Join-Path $root 'Experts\XAU_AI_PRO\XAU_AI_PRO.mq5')) { Item 'projecto MQL5' 'OK' $root }
else { Item 'projecto MQL5' 'FALHA' 'nao encontrado' }

Write-Output ''
Write-Output ("RESULTADO: {0} OK, {1} aviso(s), {2} falha(s)" -f $ok, $aviso, $falha)
if ($falha -gt 0) { Write-Output 'Reparar as falhas antes de trabalho critico (autoridade D-097).'; exit 1 }
Write-Output 'Ambiente pronto para trabalhar.'
Write-Output '===================='
exit 0
