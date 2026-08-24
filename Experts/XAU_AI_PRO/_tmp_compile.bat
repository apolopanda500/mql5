@echo off
REM ETAPA 13 - validacion de compilacion sincronica
REM Metodologia: usar cmd /c (PowerShell & e async non son fiables neste env)
"C:\Program Files\MetaTrader 5\MetaEditor64.exe" /compile "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mqproj" /log
exit /b %ERRORLEVEL%
