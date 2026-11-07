# gateway-task.ps1 - gateway de IA da 9011 como tarefa do Windows.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File gateway-task.ps1 -Acao estado
#   powershell -NoProfile -ExecutionPolicy Bypass -File gateway-task.ps1 -Acao instalar   (precisa de Administrador)
#   powershell -NoProfile -ExecutionPolicy Bypass -File gateway-task.ps1 -Acao remover    (precisa de Administrador)
#
# Autor: DELTA (D-057 / Q-022). Criado em 06/11 15:56.
#
# REGRA QUE ESTE SCRIPT RESPEITA: o gateway sobe SEMPRE em modo leitura.
# As flags de execucao ficam a 0 e NAO sao parametrizaveis. Quem quiser
# execucao real tem de escrever outra coisa, de proposito e a mao - nao ha
# um "sim" escondido num valor por omissao.
#
# -Acao estado NUNCA altera nada: nao cria, nao remove, nao arranca.

param(
   [ValidateSet('estado','instalar','remover')]
   [string]$Acao = 'estado',
   [string]$NomeTarefa = 'XAU_AI_Gateway_9011'
)

$ErrorActionPreference = 'Stop'

$appRoot = 'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\XAU_AI_PRO'
$python  = Join-Path $appRoot '.venv\Scripts\python.exe'
$logOut  = Join-Path $appRoot 'logs\gateway_9011.out.log'
$logErr  = Join-Path $appRoot 'logs\gateway_9011.err.log'
$porta   = 9011

function Mostrar-Estado {
   Write-Output '--- TAREFA ---'
   $t = Get-ScheduledTask -TaskName $NomeTarefa -ErrorAction SilentlyContinue
   if ($t) {
      $i = Get-ScheduledTaskInfo -TaskName $NomeTarefa -ErrorAction SilentlyContinue
      Write-Output ('tarefa        :: EXISTE :: ' + $t.State)
      if ($i) {
         Write-Output ('ultima exec.  :: ' + $i.LastRunTime + ' | resultado 0x' + ('{0:X8}' -f $i.LastTaskResult))
         Write-Output ('proxima exec. :: ' + $i.NextRunTime)
      }
   } else {
      Write-Output 'tarefa        :: NAO EXISTE'
   }

   Write-Output '--- PROCESSO ---'
   $procs = @(Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
              Where-Object { $_.CommandLine -like '*fastapi_gateway*' })
   if ($procs.Count -eq 0) {
      Write-Output 'uvicorn       :: NAO ESTA A CORRER'
   } else {
      foreach ($p in $procs) { Write-Output ('uvicorn       :: PID ' + $p.ProcessId + ' (pai ' + $p.ParentProcessId + ')') }
   }

   Write-Output '--- PORTA ---'
   $sock = @(Get-NetTCPConnection -State Listen -LocalPort $porta -ErrorAction SilentlyContinue)
   if ($sock.Count -eq 0) {
      Write-Output ('porta ' + $porta + '  :: SEM LISTEN (leitura instavel nesta maquina - confirmar por HTTP)')
   } else {
      foreach ($s in $sock) { Write-Output ('porta ' + $porta + '  :: LISTEN dono=' + $s.OwningProcess) }
   }

   Write-Output '--- FICHEIROS ---'
   Write-Output ('python        :: ' + (Test-Path -LiteralPath $python))
   Write-Output ('backend       :: ' + (Test-Path -LiteralPath (Join-Path $appRoot 'backend\fastapi_gateway.py')))
   Write-Output ('logs\         :: ' + (Test-Path -LiteralPath (Split-Path -Parent $logOut)))
}

function Exigir-Admin {
   $id = [Security.Principal.WindowsIdentity]::GetCurrent()
   $pr = New-Object Security.Principal.WindowsPrincipal($id)
   if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
      Write-Output 'RECUSADO: -Acao instalar/remover exige sessao de Administrador.'
      Write-Output 'Alternativa sem admin: criar a tarefa na GUI (Agendador de Tarefas) ou manter o processo manual.'
      exit 1
   }
}

if ($Acao -eq 'estado') { Mostrar-Estado; exit 0 }

Exigir-Admin

if ($Acao -eq 'remover') {
   $t = Get-ScheduledTask -TaskName $NomeTarefa -ErrorAction SilentlyContinue
   if (-not $t) { Write-Output 'NADA A FAZER: a tarefa nao existe.'; exit 0 }
   Unregister-ScheduledTask -TaskName $NomeTarefa -Confirm:$false
   Write-Output ('REMOVIDO: tarefa ' + $NomeTarefa + '. O processo em curso NAO foi tocado - parar e decisao humana.')
   exit 0
}

# --- instalar ---
if (-not (Test-Path -LiteralPath $python)) {
   Write-Output ('RECUSADO: Python do .venv nao encontrado :: ' + $python)
   exit 1
}

$logDir = Split-Path -Parent $logOut
if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# Flags de execucao a 0 - fixas, nao parametrizaveis (ver cabecalho).
$envPrep = @(
   "`$env:XAU_GATEWAY_PORT='$porta'",
   "`$env:XAU_GATEWAY_HOST='127.0.0.1'",
   "`$env:XAU_ENABLE_REAL_ORDERS='0'",
   "`$env:XAU_ENABLE_DEMO_ORDERS='0'",
   "`$env:XAU_ENABLE_MT5_EXECUTION='0'",
   "`$env:XAU_ENABLE_TRADE_COMMANDS='0'",
   "`$env:XAU_ENABLE_EMERGENCY_RESUME='0'",
   "`$env:XAU_ENABLE_MCP_TRADING='0'"
) -join '; '

$comando = $envPrep + '; Set-Location -LiteralPath ''' + $appRoot + '''; ' +
           '& ''' + $python + ''' -m uvicorn backend.fastapi_gateway:app --port ' + $porta + ' --host 127.0.0.1' +
           ' *>> ''' + $logOut + ''' 2>> ''' + $logErr + ''''

$acaoTarefa = New-ScheduledTaskAction -Execute 'powershell.exe' `
   -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "' + $comando + '"') `
   -WorkingDirectory $appRoot

$gatilho = New-ScheduledTaskTrigger -AtLogOn
$definicoes = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
   -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 0) `
   -StartWhenAvailable

Register-ScheduledTask -TaskName $NomeTarefa -Action $acaoTarefa -Trigger $gatilho `
   -Settings $definicoes -Description 'Gateway de IA XAU_AI_PRO na porta 9011 (modo leitura, flags de execucao a 0)' `
   -Force | Out-Null

Write-Output ('INSTALADO: tarefa ' + $NomeTarefa + ' (gatilho: no logon; reinicio automatico a cada 1 min).')
Write-Output ('Porta: ' + $porta + ' | modo: LEITURA (6 flags de execucao a 0)')
Write-Output ('Log: ' + $logOut)
Write-Output 'NOTA: a tarefa arranca no proximo logon. Para testar ja: Start-ScheduledTask -TaskName ' + $NomeTarefa
Write-Output 'NOTA: se o gateway manual (PID actual) ainda estiver na 9011, o arranque falha com porta ocupada. Parar o manual primeiro.'
