@echo off
REM Wrapper da tarefa agendada "XAU_AI_PRO Forward Gate".
REM Mede o forward de 30 dias uma vez por dia e deixa o resultado em:
REM   Experts\XAU_AI_PRO\EQUIPE\FORWARD\medicao.jsonl
REM   Experts\XAU_AI_PRO\EQUIPE\FORWARD\FORWARD.md
REM Sai com codigo 2 se o MD5 divergir (janela perdida).
setlocal
set "ROOT=C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\Tools\forward-gate.ps1" > "%ROOT%\Experts\XAU_AI_PRO\EQUIPE\FORWARD\ultima_medicao.log" 2>&1
set "RC=%ERRORLEVEL%"
echo exit=%RC% >> "%ROOT%\Experts\XAU_AI_PRO\EQUIPE\FORWARD\ultima_medicao.log"
exit /b %RC%
