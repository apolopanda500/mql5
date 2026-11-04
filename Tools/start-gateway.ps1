<#
.SYNOPSIS
   Sobe o gateway FastAPI em 9011 para testar a IA, com os gates de trade
   DESLIGADOS.

.DESCRIPTION
   `start_gateway.bat` liga XAU_ENABLE_REAL_ORDERS=1, XAU_ENABLE_MT5_EXECUTION=1,
   XAU_ENABLE_TRADE_COMMANDS=1 e XAU_MCP_TRADING=1 - serve para o produto, nao
   para medir a rota de IA. Este script forca esses gates a 0 antes de arrancar,
   para que uma sessao de diagnostico nunca consiga enviar uma ordem.

   O token vem do `.env` da raiz (XAU_GATEWAY_TOKEN, 64 caracteres) pelo proprio
   backend. Nada e impresso nem gravado.

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\start-gateway.ps1

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\start-gateway.ps1 -Port 9001
#>
[CmdletBinding()]
param(
   [int]$Port = 9011
)

$ErrorActionPreference = 'Stop'

$repo = Join-Path (Split-Path -Parent $PSScriptRoot) 'Files\XAU_AI_PRO'
$py   = Join-Path $repo '.venv\Scripts\python.exe'

if(-not (Test-Path $py)) {
   Write-Host "[FAIL] .venv ausente em $repo" -ForegroundColor Red
   Write-Host '        crie com: <python> -m virtualenv .venv ; .venv\Scripts\python -m pip install -r requirements.txt' -ForegroundColor Gray
   exit 1
}

# Gates de execucao: explicita e repetidamente DESLIGADOS.
$env:XAU_ENABLE_REAL_ORDERS        = '0'
$env:XAU_ENABLE_DEMO_ORDERS        = '0'
$env:XAU_ENABLE_MT5_EXECUTION      = '0'
$env:XAU_ENABLE_TRADE_COMMANDS     = '0'
$env:XAU_ENABLE_EMERGENCY_RESUME   = '0'
$env:XAU_MCP_TRADING               = '0'
$env:XAU_GATEWAY_PORT              = "$Port"

# O app instalado pode ter posto isto no ambiente do usuario; nao deixar herdar.
if($env:XAU_THIRD_PARTY_EA_READ_ONLY -eq $null) { $env:XAU_THIRD_PARTY_EA_READ_ONLY = '1' }

Write-Host ''
Write-Host "gateway de DIAGNOSTICO em http://127.0.0.1:$Port" -ForegroundColor Cyan
Write-Host 'gates: REAL_ORDERS=0 DEMO_ORDERS=0 MT5_EXECUTION=0 TRADE_COMMANDS=0 MCP_TRADING=0' -ForegroundColor Gray
Write-Host 'Ctrl+C para parar.' -ForegroundColor Gray
Write-Host ''

Set-Location $repo
& $py -m uvicorn backend.fastapi_gateway:app --port $Port --host 127.0.0.1
exit $LASTEXITCODE
