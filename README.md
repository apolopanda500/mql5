# XAU_AI_PRO — Expert Advisor MQL5 (v1.2.214)

> **Plataforma Quantitativa Multi-Ativo para MetaTrader 5** — arquitetura modular de 115 ficheiros MQL5 com guarda dedicada para conta real, controle de custo efetivo em USD, concorrência serializada (Padrão F4) e integração *fail-closed* com o motor de IA.

[![Portal Oficial & Downloads](https://img.shields.io/badge/Portal-Official%20%26%20Downloads-blue)](https://apolopanda500.github.io/XAU_AI_PRO/)
[![App Desktop & Android](https://img.shields.io/badge/App-Desktop%20%26%20Android-green)](https://github.com/apolopanda500/XAU_AI_PRO)
[![MQL5 CodeBase](https://img.shields.io/badge/MQL5-CodeBase-orange)](https://www.mql5.com/en/users/apolopanda500)

Repositório MQL5 para MetaTrader 5 — espelho do [MQL5 Algo Forge](https://www.mql5.com/en/users/apolopanda500) | [Perfil GitHub](https://github.com/apolopanda500).

---

## Visão Geral da Engenharia

O **XAU_AI_PRO** segue o princípio *"sem medição é intenção, não prova"*. Opera integrado ao ecossistema [XAU AI PRO Trading Desk](https://github.com/apolopanda500/XAU_AI_PRO) (gateway FastAPI, núcleo Rust e interface para Windows/Android), mas mantém autonomia total de proteção dentro do MetaTrader 5.

> **Versão canônica:** `v1.2.214` — fonte única em `Enterprise/VersionManager.mqh` (`EA_VERSION_STRING "1.2.214"`). O `#property version "1.414"` do entry point segue a fórmula `minor*100+patch` exigida pelo compilador MQL5. *(Os banners `v1.2.9` que ainda aparecem no cabeçalho de alguns módulos são texto congelado de setembro, não a versão do produto.)*

### Pilares de Produção & Segurança

| Pilar | Módulo | Função |
|---|---|---|
| **Guarda de Conta Real** | `Core/RealAccountGuard.mqh` | Inerte em demo/backtest; ativa em `ACCOUNT_TRADE_MODE_REAL`. Bloqueia lote mínimo acima do teto de risco, impede stop zerado (`0R`) e limita posições sem proteção. |
| **Trava de Custo em USD** | `Filters/CostGate.mqh` | Converte spread + comissão para dólares e compara contra alvo e risco antes de enviar a ordem. |
| **Escada de Lucro em USD** | `Management/MoneyLadder.mqh` | Dona única de SL/TP: break-even e travas parciais/totais em USD, não em pontos ou R. |
| **Integridade & Concorrência (Padrão F4)** | `Monitoring/TradeLogger.mqh`, `Monitoring/EventEmitter.mqh` | Escrita serializada com lock exclusivo (`ABRIR → LOCK → SEEK → WRITE → FLUSH → FECHAR`), eliminando corrupção de `trade_history.csv` em operação multi-gráfico. |
| **Proteção Fail-Close** | `Core/StalenessGuard.mqh`, `Core/KillSwitch.mqh`, `Enterprise/CircuitBreaker.mqh` | Bloqueia entradas em cotação defasada, queda de conexão (com histerese) ou acionamento de emergência. |
| **Portão de Negociação** | `Core/TradeGate.mqh` | Fonte única de verdade sobre "pode operar?", com código `ETradeGate` explícito na telemetria. |

---

## Arquitetura Modular (115 módulos)

```text
Experts/XAU_AI_PRO/
├── XAU_AI_PRO.mq5            # Entry point (OnInit, OnTick, OnTimer, OnDeinit)
├── XAU_AI_PRO.mqproj         # Unidade de build oficial (MetaEditor64)
├── DiagGateSelfTest.mq5      # Autoteste de throttle e observabilidade de logs
│
├── Core/             (32)    # Config, TradePipeline, MarketScanner, DecisionEngine,
│                             #   RiskEngine, RealAccountGuard, TradeGate, StalenessGuard
├── Enterprise/       (24)    # CircuitBreaker (histerese), Retry, BackupManager, VersionManager
├── Monitoring/       (21)    # TradeLogger (F4), EventEmitter, DiagGate, HealthMonitor,
│                             #   SystemStatus, Auditoria
├── AI/               (10)    # AIEngine, AIConnector (HTTP/fallback), LearningHistory,
│                             #   AdaptiveWeights, ModelGovernance
├── Filters/          (10)    # CostGate (USD), GlobalScenario, MarketScenario,
│                             #   Session/Spread/News/MTF
├── Indicators/         (9)    # ATR, ADX, RSI, TrendStrength, HandleRegistry,
│                             #   SeriesIdentity, identidade de série
├── Management/         (5)    # MoneyLadder (escada em USD), posição aberta, break-even
├── Integration/        (2)    # EAHeartbeat + ExternalBridge — telemetria somente leitura
├── Scripts/                   # Sondas de diagnóstico (WebRequest, perm, series, tick value…)
└── Data/                      # Runtime local (CSV de aprendizado, sessão, auditoria — git-ignored)
```

---

## Cadeia de Decisão por Tick (`OnTick`)

1. **`CTradeGate::Evaluate()`** — valida os bits de permissão (terminal, algo trading, EA, conta e sessão).
2. **`CStalenessGuard::CotacaoVelha()`** — compara `MqlTick.time` com `TimeTradeServer()` (*fail-close*).
3. **`KillSwitch::Verificar()`** — precedência absoluta sobre qualquer sinal ou ordem.
4. **`MarketScanner::Scan()`** — varre o universo aplicando barreiras de barra atual, frescor de dados, *cooldown*, geração de sinal (`SignalCore` + `SignalCoreV2`), memória histórica (`LearningHistory`) e portões de validação.
5. **`TradePipeline`** → `ValidationEngine` → `ExecutionEngine` — funil único até o envio da ordem.

O EA publica seu retrato em `Files/Data/system_status.json` e o heartbeat somente-leitura em `%APPDATA%\MetaQuotes\Terminal\Common\Files\XAU_AI_PRO_heartbeat.json` (consumido pelo watchdog do gateway — nunca envia ordens nem altera risco).

---

## Ecossistema Completo (PC, Android & Downloads)

Para usar a interface gráfica, o motor de Machine Learning e o monitoramento remoto:

* **Portal Oficial & Downloads** (instaladores `.exe` PC e `.apk` Android): [apolopanda500.github.io/XAU_AI_PRO](https://apolopanda500.github.io/XAU_AI_PRO/)
* **Repositório Principal do App & Gateway**: [github.com/apolopanda500/XAU_AI_PRO](https://github.com/apolopanda500/XAU_AI_PRO)

---

## Qualidade & Validação

O CI público roda validação estática em cada push/PR: encoding UTF-8, balanceamento de chaves e integridade de `#include` (`validate_mql5.py`), sincronia de versão entre este README e `EA_VERSION_STRING`, CodeQL e varredura de segredos com Gitleaks. O `.ex5` de produção **nunca** é recompilado pelo CI.

---

## Aviso Legal e de Risco

Operações no mercado financeiro (XAU/USD, Forex, Índices e Cripto) envolvem alto risco de perda de capital. Nenhum código neste repositório constitui recomendação de investimento ou garantia de rentabilidade. Valide rigorosamente todos os parâmetros em conta demonstrativa (*Demo*) e *Forward Test* antes de qualquer ativação em conta real.

© 2026 APOLOPANDA500 — Todos os direitos reservados.
