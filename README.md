# MQL5 - Algo Forge / APOLOPANDA500

Repositório de código MQL5 para MetaTrader 5 — [APOLOPANDA500 no MQL5 CodeBase](https://www.mql5.com/en/users/apolopanda500) | [Perfil GitHub](https://github.com/apolopanda500)

---

## 🚀 XAU_AI_PRO v1.2.0

**XAU_AI_PRO** é um Expert Advisor avançado de trading algorítmico para XAU/USD (ouro) e múltiplos símbolos, com integração de IA, gestão de risco, e arquitetura modular enterprise.

### Principais Recursos

| Categoria | Recursos |
|-----------|----------|
| **IA / Machine Learning** | AI Engine, Adaptive Weights, Learning Memory, Dataset logging, Pipeline Python |
| **Risk Management** | Lot size, risk %, max daily loss, drawdown limits, free margin check |
| **Execution** | Order retry (exponencial backoff), slippage control, circuit breaker, recovery |
| **Filters** | Spread filter, session filter, trend filter, MTF filter, news filter |
| **Indicators** | ATR, ADX, RSI, Trend Strength, Volatility Filter, KCI |
| **Monitoring** | Dashboard, trade logger, performance analyzer, statistics, health check |
| **Enterprise** | Safety Manager, Smart Execution, Telemetry, Scheduler, Auto-Calibration, Simulation Engine, Version Manager |
| **Multi-Symbol** | Suporte a XAUUSD, EURUSD, GBPUSD, USDJPY, AUDUSD, USDCAD, NZDUSD, USDCHF, XAGUSD, US30, US500, USTEC |

### Estrutura do Projeto

```
Experts/XAU_AI_PRO/
├── XAU_AI_PRO.mq5          # Expert Advisor principal (entry point)
├── XAU_AI_PRO.mqproj       # Projeto MQL5 (MetaEditor)
├── Utils.mqh               # Funções utilitárias
├── Core/                   # Módulos centrais
│   ├── Config.mqh          # Parâmetros de entrada (inputs)
│   ├── SystemManager.mqh   # Gerenciador do sistema
│   ├── DecisionEngine.mqh  # Motor de decisão
│   ├── RiskEngine.mqh      # Gestão de risco
│   ├── ExecutionEngine.mqh # Execução de ordens
│   └── ...
├── AI/                     # Módulos de inteligência artificial
│   ├── AIEngine.mqh
│   ├── AIClient.mqh
│   ├── AIConnector.mqh
│   ├── Dataset.mqh
│   └── AdaptiveWeights.mqh
├── Indicators/             # Indicadores técnicos
├── Filters/                # Filtros de entrada
├── Management/             # Gerenciamento de posições
├── Monitoring/             # Monitoramento e logs
├── Enterprise/             # Recursos enterprise
└── Data/                   # Arquivos de dados (ignorado pelo git)
```

### Configuração

Parametros principais configuráveis via MetaTrader:

- **MagicNumber**: 2026001
- **RiskPercent**: 1.0% do equity por operação
- **MaxDailyLossPercent**: 5.0%
- **MaxDrawdownPercent**: 15.0%
- **MaxSpread**: 50 pontos (configurável por símbolo)
- **Symbols**: XAUUSD, EURUSD, GBPUSD, USDJPY, AUDUSD, USDCAD, NZDUSD, USDCHF, XAGUSD, US30, US500, USTEC

### Sincronização

Este repositório possui dois remotes configurados:

| Remote | URL | Descrição |
|--------|-----|-----------|
| `origin` | `https://forge.mql5.io/APOLOPANDA500/mql5.git` | MQL5 CodeBase (MetaQuotes) |
| `github` | `https://github.com/apolopanda500/mql5.git` | Backup e desenvolvimento no GitHub |

Para sincronizar ambos:
```bash
git push origin main
git push github main
```

### Licença

Copyright 2026, APOLOPANDA500. Todos os direitos reservados.