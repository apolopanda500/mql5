# AUDITORIA XAU AI PRO — v1.2.0 (18/08/2026)

**Auditor completo:** MetaTrader Assistant — Data: 18/08/2026 17:39 (GMT-3)
**Escopo:** EA MQL5 (Experts\XAU_AI_PRO) + Aplicativo desktop (C:\Users\Micro\Downloads\XAU_AI_PRO)
**Resultado geral:** CONSISTENTE — todos os módulos unificados na versão v1.2.0

## 1. DIAGNÓSTICO: por que o robô parou de abrir operações
1. **AutoTrading do terminal DESLIGADO** (`experts_trade_allowed=false`) → CircuitBreaker em SAFE MODE.
2. **Input AutoTrade=0 nos 3 gráficos** (XAUUSD, EURUSD, AUDUSD H1).
3. **Bug MQL5**: input AutoTrade ignorado no OnTick (`CheckTradingConditions()` nunca era chamada) — CORRIGIDO.

## 2. EA MQL5 — versões
- XAU_AI_PRO.mq5: v1.20 → **v1.2.0** (#property version "1.2.0")
- 39 módulos com cabeçalho atualizado (v1.0/v1.1/v1.10/v1.20/v2.0 → v1.2.0)
- 50 módulos com cabeçalho v1.2.0 adicionado
- VersionManager.mqh: "1.0.0" → "1.2.0"
- FullAudit/ProductionChecklist: #property version "1.10" → "1.2.0"
- Compilação: **0 erros, 1 warning** (formato Market, inofensivo)

## 3. Aplicativo (Downloads\XAU_AI_PRO) — versões
- app/core.py, config_manager.py, data/config.json, main.py, sidebar.py: v2.0/2.0.0 → **v1.2.0**
- Python/pipeline.py (APP_VERSION), Python/backend/api.py: 2.0.0 → **1.2.0**
- build_app.spec / XAU_AI_PRO_v2.spec: name XAU_AI_PRO_v2 → **XAU_AI_PRO**
- README.md: "Crypto Trader Pro" → **"XAU AI PRO v1.2.0"**
- frontend/package.json: xau-ai-pro / XAU AI PRO
- CHANGELOG.md: entrada [1.2.0] adicionada

## 4. Correção de código (v1.2.0)
OnTick agora respeita o input AutoTrade (bloqueia com "[TRADE BLOCK] AUTOTRADE OFF" quando desligado).

## 5. Backups
- MQL5: MQL5\Files\Backup\XAU_AI_PRO_backup_v120\
- App: C:\Users\Micro\Downloads\XAU_AI_PRO\Backup_v120\

## 6. Pendências
1. Ligar AutoTrading no terminal (Ctrl+E) e AutoTrade=true no EA (F7).
2. Rebuild do exe: `pyinstaller build_app.spec` (gera dist\XAU_AI_PRO.exe v1.2.0).
3. Forward-test em DEMO (MetaQuotes-Demo 111194406).
4. KCI zerado no dataset; 5. verbosidade de logs.

Relatório completo: C:\Users\Micro\Downloads\XAU_AI_PRO\Docs\AUDITORIA_V1.2.0.md
