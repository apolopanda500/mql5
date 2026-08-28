@echo off
REM ============================================================
REM XAU_AI_PRO - Heartbeat Watchdog (ETAPA 20.14 Endurance)
REM Inicia o daemon de monitoramento (nao altera o EA).
REM
REM Configure abaixo (opcional) o webhook do Slack para receber
REM alertas quando o pipeline parar de atualizar.
REM ============================================================
setlocal

REM --- Alerta Slack (opcional; preencha com seu Incoming Webhook) ---
REM set "SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXXX/YYYY/ZZZZ"

REM --- Limites ---
set "MAX_IDLE_SEC=900"
set "AUDIT_MAX_IDLE_SEC=86400"
set "ALERT_THROTTLE_SEC=3600"

REM --- Caminho do watchdog ---
set "WD_DIR=%~dp0"
cd /d "%WD_DIR%"

echo [XAU_AI_PRO] Iniciando watchdog (intervalo 300s)...
echo [XAU_AI_PRO] Ctrl+C para parar.
python heartbeat_watchdog.py --daemon --interval 300

endlocal