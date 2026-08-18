# XAU_AI_PRO v1.2.0 - Estado de Sincronização (18/08/2026)

## Build
- EA: XAU_AI_PRO.mq5 (v1.2.0) - compilado com 0 erros / 1 warning (formato de versão p/ Market)
- .ex5: MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5
- Todos os módulos (.mqh) padronizados para v1.2.0 (cabeçalhos, #property, comentários)

## Correções aplicadas (18/08 - v1.2.0)
1. **Bug corrigido - AutoTrade**: o input `AutoTrade` só era verificado em
   `CheckTradingConditions()`, que nunca era chamada no OnTick. Agora o OnTick
   respeita o input e bloqueia com "[TRADE BLOCK] AUTOTRADE OFF" quando desligado.
2. Padronização de versão v1.2.0 em 89 arquivos (Core, AI, Filters, Indicators,
   Management, Monitoring, Enterprise, Utils.mqh, XAU_AI_PRO.mq5).
3. VersionManager.mqh: versão corrente "1.0.0" -> "1.2.0".
4. FullAudit.mqh / ProductionChecklist.mqh: #property version "1.10" -> "1.2.0".
5. App desktop (C:\Users\Micro\Downloads\XAU_AI_PRO): app_version 2.0.0 -> 1.2.0
   (app/core.py, config_manager.py, config.json, main.py, sidebar.py,
   Python/pipeline.py APP_VERSION, Python/backend/api.py, specs PyInstaller,
   README, frontend/package.json, CHANGELOG).

## POR QUE O ROBÔ PAROU DE ABRIR OPERAÇÃO (diagnóstico 18/08)
- **AutoTrading do terminal está DESLIGADO** (`experts_trade_allowed=false`).
  O CircuitBreaker (CheckBrokerError) entra em SAFE MODE
  ("Broker connection or trading disabled") e bloqueia todo o OnTick.
- **Inputs nos gráficos (XAUUSD/EURUSD/AUDUSD H1) estão com AutoTrade=0**
  e todos os filtros desligados (configuração de testes).
- Conta: MetaQuotes-Demo 111194406 (US$ 200,00), 0 posições.
- Sinal: com filtros desligados o EA ainda gera sinal técnico (EMA+RSI),
  mas o bloqueio do CircuitBreaker + AutoTrade impede qualquer operação.

### Como reativar (passo a passo)
1. No MetaTrader 5, pressione **Ctrl+E** (ou botão "Algo Trading") para ligar
   o AutoTrading do terminal.
2. No gráfico, abra as propriedades do EA (F7) e coloque **AutoTrade=true**.
3. (Opcional) Reative os filtros desejados: EnableSpreadFilter, EnableTrendFilter,
   EnableAIFilter etc.
4. Acompanhe o journal: devem sumir os "[TRADE BLOCK] CIRCUIT BREAKER" e
   "[TRADE BLOCK] AUTOTRADE OFF".

## Pendências
- Rebuild do executável do app (dist\XAU_AI_PRO_v2.exe -> XAU_AI_PRO.exe) com o
  spec atualizado (build_app.spec / XAU_AI_PRO_v2.spec) para refletir v1.2.0.
- Forward-test em conta DEMO com AutoTrading ON.
- KCI: dados zerados no dataset (colunas KCI_* = 0).
- Reduzir verbosidade de logs (ValidationEngine imprime por tick).
