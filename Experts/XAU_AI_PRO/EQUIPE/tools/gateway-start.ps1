# gateway-start.ps1 - manter o gateway de IA (9011) vivo, em MODO LEITURA
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\gateway-start.ps1
#
# Idempotente: se a porta 9011 ja estiver a ouvir, sai sem fazer nada.
# Serve para a tarefa agendada XAU_AI_PRO_GatewayKeepalive (cada 5 minutos):
# se o gateway morrer (reboot, crash, terminal fechado), volta sozinho.
#
# REGRA: 6 flags de execucao ficam a 0 e NAO sao parametrizaveis. O token e
# lido pelo proprio gateway do .env; este script nunca o imprime.
#
# Nao toca em graficos, inputs, conta, ordens nem parametros de risco.

$ErrorActionPreference = 'Stop'

$appRoot = 'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\XAU_AI_PRO'
$python  = Join-Path $appRoot '.venv\Scripts\python.exe'
$logDir  = Join-Path $appRoot 'logs'
$logOut  = Join-Path $logDir 'gateway_9011.out.log'
$logErr  = Join-Path $logDir 'gateway_9011.err.log'
$porta   = 9011

if (-not (Test-Path -LiteralPath $python)) {
   Write-Output "RECUSADO: python do .venv nao encontrado em $appRoot"
   exit 1
}

$ouvindo = Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue
if ($ouvindo) {
   Write-Output "OK: porta $porta ja esta a ouvir (pid $($ouvindo[0].OwningProcess)); nada a fazer."
   exit 0
}

if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$env:XAU_GATEWAY_PORT            = "$porta"
$env:XAU_GATEWAY_HOST            = '127.0.0.1'
$env:XAU_ENABLE_REAL_ORDERS      = '0'
$env:XAU_ENABLE_DEMO_ORDERS      = '0'
$env:XAU_ENABLE_MT5_EXECUTION    = '0'
$env:XAU_ENABLE_TRADE_COMMANDS   = '0'
$env:XAU_ENABLE_EMERGENCY_RESUME = '0'
$env:XAU_ENABLE_MCP_TRADING      = '0'

$p = Start-Process -FilePath $python `
   -ArgumentList '-m', 'uvicorn', 'backend.fastapi_gateway:app', '--port', "$porta", '--host', '127.0.0.1' `
   -WorkingDirectory $appRoot -RedirectStandardOutput $logOut -RedirectStandardError $logErr `
   -PassThru -WindowStyle Hidden

$limite = (Get-Date).AddSeconds(45)
while ((Get-Date) -lt $limite) {
   Start-Sleep -Milliseconds 700
   $vivo = $false
   if (Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue) { $vivo = $true }
   if (-not $vivo) {
      # 401 sem token tambem prova que o servico esta vivo a responder.
      try {
         $r = Invoke-WebRequest -Uri "http://127.0.0.1:$porta/api/health" -TimeoutSec 2 -UseBasicParsing -SkipHttpErrorCheck
         if ($r.StatusCode -eq 200 -or $r.StatusCode -eq 401) { $vivo = $true }
      }
      catch { $vivo = $false }
   }
   if ($vivo) {
      Write-Output "OK: gateway a responder na porta $porta (pid $($p.Id), modo LEITURA)."
      exit 0
   }
   if ($p.HasExited) {
      Write-Output "FALHA: o processo saiu com codigo $($p.ExitCode). Ver $logErr"
      exit 1
   }
}

Write-Output "FALHA: 45 s sem resposta na porta $porta. Processo pid $($p.Id) deixado a correr; ver $logErr"
exit 1
