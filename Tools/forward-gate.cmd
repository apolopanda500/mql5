@echo off
REM Wrapper da tarefa agendada "XAU_AI_PRO Forward Gate".
REM Mede o forward de 30 dias uma vez por dia e deixa o resultado em:
REM   Experts\XAU_AI_PRO\EQUIPE\FORWARD\medicao.jsonl   (estado do canal)
REM   Experts\XAU_AI_PRO\EQUIPE\FORWARD\trades.jsonl     (trades/PF/DD reais)
REM   Experts\XAU_AI_PRO\EQUIPE\FORWARD\FORWARD.md       (tabela viva)
REM Sai com codigo 2 se o MD5 divergir (janela perdida).
setlocal
set "ROOT=C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
set "PY=%ROOT%\Files\XAU_AI_PRO\.venv\Scripts\python.exe"
set "JANELA=2026-11-11"
set "SAIDA=%ROOT%\Experts\XAU_AI_PRO\EQUIPE\FORWARD\ultima_medicao.log"

REM 1) METRICAS DO G11 a partir do stream de trades do proprio EA (PF, DD, trades).
REM    Sao os numeros que o GATE_REAL exige: PF >= 1.2, DD <= 8%%, >= 30 trades.
echo [%date% %time%] --- metricas G11 --- > "%SAIDA%"
"%PY%" "%ROOT%\Tools\g11-metrics.py" --janela %JANELA% --saldo 12593.83 >> "%SAIDA%" 2>&1

REM 2) ESTADO DO CANAL: MD5 do binario, versao em memoria, funil, cobertura de IA.
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Tools\forward-gate.ps1" >> "%SAIDA%" 2>&1
set "RC=%ERRORLEVEL%"
echo exit=%RC% >> "%SAIDA%"
exit /b %RC%
