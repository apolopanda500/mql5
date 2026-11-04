# XAU_AI_PRO — Plano de Melhorias: MCP, MT5 Build 6060 e IA

> **Projeto:** XAU_AI_PRO v1.2.111  
> **Plataforma:** MetaTrader 5 Build 6060+ (julho/2026)  
> **Idioma:** Português (Brasil)  
> **Data:** 03/11/2026

---

## 1. RESUMO EXECUTIVO

Este documento apresenta novas melhorias para o assistente MT5 **XAU_AI_PRO**, baseado em:

- Leitura completa de todos os arquivos do projeto (Core, AI, Enterprise, Filters, Management, Monitoring, Indicators)
- Leitura do `PROGRESS.md` (ciclos 1–79, até v1.2.93 / 02/11/2026)
- Leitura de `RELATORIO_FINAL_ETAPAS1_13.md`, `VersionManager.mqh`, `RiskHub.mqh`, `TradeGate.mqh`, `AIConnector.mqh`, `AIEngine.mqh`, `Config.mqh`, `XAU_AI_PRO.mq5`
- Pesquisa na documentação oficial do **MT5 Build 6060** (MCP nativo, AI Assistant, OpenBLAS/LAPACK, WebRequest corrigido, CHARTEVENT_CHART_CHANGE, SocketCreate)
- Pesquisa no artigo MQL5 **#23708** (MCP_Accessibility_Assistant.mq5)
- Scan de superfícies da API MT5 (Ciclo 37 — 360 identificadores, 15 famílias)

---

## 2. ESTADO ATUAL DO PROJETO

### 2.1 Arquitetura

| Camada | Diretório | Principais arquivos |
|--------|-----------|---------------------|
| Core | `Core/` | Config, TradeGate, RiskHub, RiskEngine, ExecutionEngine, OrderManager, PositionManager, StateMachine, SymbolManager, SymbolValidator, TradePipeline, MarketScanner |
| AI | `AI/` | AIConnector, AIEngine, AIClient, AdaptiveWeights, AILearningMemory, AIMetrics, DataLogger, Dataset, ModelGovernance |
| Enterprise | `Enterprise/` | SafetyManager, CircuitBreaker, RecoveryManager, SmartExecution, TradeMonitor, Scheduler, DatabaseManager, Telemetry, BackupManager, BenchmarkEngine, NotificationCenter, ConfigManager, VersionManager, FailureMode, ConnectionGuard, MarginChecker, ExecutionQuality, ExecutionStats, VolumeValidator, PositionSynchronizer |
| Filters | `Filters/` | SpreadFilter, SessionFilter, TrendFilter, MultiTimeframeFilter, NewsFilter, MarketRegime |
| Management | `Management/` | BreakEven, DailyRisk, EquityProtection, PortfolioManager |
| Monitoring | `Monitoring/` | Logger, Dashboard, Diagnostics, HealthMonitor, EventEmitter, EventLock, TradeLogger, AuditLog, Statistics, PerformanceAnalyzer, SystemStatus, ForwardTestRunner, ReplayEngine, BacktestAnalyzer, QuantValidator, ValidationChecklist, ProductionChecklist, OperatorBrief |
| Indicators | `Indicators/` | ATR, ADX, RSI, TrendStrength, VolatilityFilter |

### 2.2 Funcionalidades já implementadas

- ✅ Risk Hub com persistência via `GlobalVariable` (sobrevive a reinicializações)
- ✅ TradeGate — fonte única de verdade para permissão de negociação
- ✅ DiagGate — controle de volume de journal (redução ~30%)
- ✅ HealthMonitor + WatchDog (liveness vs progress)
- ✅ CircuitBreaker, RecoveryManager, SafetyManager
- ✅ NotificationCenter (Telegram, push, cooldown, dedup)
- ✅ BackupManager, DatabaseManager
- ✅ VersionManager, ConfigManager (perfis persistidos)
- ✅ ProductionChecklist, ValidationChecklist (ETAPA 10)
- ✅ EventEmitter, ForwardTestRunner, ReplayEngine (ETAPA 15.6)
- ✅ QuantValidator (ETAPA 14 — 11 métricas quantitativas)
- ✅ ModelGovernance (ETAPA 15.3 — metadados de modelo)
- ✅ TradeLogger com 13 colunas (Ticket/Magic/Origin)
- ✅ SymbolValidator (P1.51 — validação de símbolo antes de enviar ordem)
- ✅ TradeLog fallback counter (P1.52 — rastreia quando posId está ausente)

### 2.3 Versão

- `EA_VERSION_STRING` = "1.2.111" (VersionManager.mqh)
- `#property version` = "1.311" (formato MetaEditor)

---

## 4. MELHORIAS SUGERIDAS (POR PRIORIDADE)

### 4.1 Prioridade Alta — Integração MCP

**Problema:** O XAU_AI_PRO não menciona MCP em nenhum arquivo. O MT5 Build 6060 adicionou suporte nativo, permitindo que agentes de IA acessem dados de mercado, analisem gráficos, trabalhem com EAs e usem o Strategy Tester via linguagem natural.

**Solução:** Criar um servidor MCP dentro do EA que exponha:

| Operação MCP | Descrição | Sensibilidade |
|-------------|-----------|---------------|
| `get_risk_status()` | Drawdown diário, trades do dia, peak equity, saldo | Leitura |
| `get_ai_signal(symbol)` | Sinal e confiança da IA para um símbolo | Leitura |
| `get_health_status()` | Estado dos módulos, heartbeat, safe mode | Leitura |
| `get_account_info()` | Login, balance, equity, margin, profit | Leitura |
| `get_open_positions()` | Lista de posições abertas com SL/TP | Leitura |
| `get_checklist_status()` | Status das checklists de produção/validação | Leitura |
| `validate_trade(symbol, type, lots, sl, tp)` | Valida se uma ordem pode ser executada | Execução (pré-checked) |
| `get_trade_gate_verdict()` | Veredito atual do TradeGate | Leitura |

**Arquivo criado:** `Core/MCPServer.mqh` — implementação completa da classe `CMCPServer`.

**Segurança MCP:**
- Token de autenticação obrigatório (sem token = MCP desabilitado)
- Operações de leitura sempre permitidas se token válido
- Operações de execução requerem confirmação explícita
- Todas as ações via MCP gravadas no AuditLog

---

### 4.2 Prioridade Alta — SQLite para Logs Estruturados

**Problema:** O scan de superfícies MT5 (Ciclo 37) identificou que **SQLite é a única lacuna com evidência medida (0/25)**. O TradeLogger e AuditLog usam CSV em modo texto, que apresenta:
- Vírgula extra desloca colunas
- Ano `22026` (erro de colagem de linhas)
- 108 linhas malformadas em 100k linhas medidas

**Solução:** Substituir CSV por SQLite nativo do MQL5 (`DatabaseBind`, `DatabaseReadBind`, `PRIMARY KEY` no ticket).

**Arquivo criado:** `Monitoring/TradeLoggerSQLite.mqh` — classe `CTradeLoggerSQLite` com:
- Tabela `trades` com 13 colunas (ticket PRIMARY KEY)
- Índices por símbolo e tempo
- `INSERT OR REPLACE` para evitar duplicatas
- Bind de parâmetros (evita SQL injection)
- Funções de conveniência: `TradeLoggerSQLiteInit`, `TradeLoggerSQLiteLog`, `TradeLoggerSQLiteShutdown`

---

### 4.3 Prioridade Média — Comunicação MT5 ↔ Python via Socket

**Problema:** O gateway de IA usa HTTP (`http://127.0.0.1:9001/api/ai/predict`) com timeout de 15s. O scan de superfícies confirmou que `SocketCreate` funciona em EAs (até 128 sockets, com TLS).

**Solução:** Adicionar comunicação via socket como alternativa ao HTTP para:
- Menor latência
- Comunicação bidirecional
- Heartbeat mais frequente sem overhead HTTP

---


---

## 5. ARQUIVOS CRIADOS NESTA SESSÃO

| Arquivo | Caminho | Descrição |
|---------|---------|-----------|
| `MCPServer.mqh` | `Core/MCPServer.mqh` | Servidor MCP com 8 operações (leitura e validação de trade) |
| `TradeLoggerSQLite.mqh` | `Monitoring/TradeLoggerSQLite.mqh` | TradeLogger com SQLite nativo (substitui CSV) |
| `PLANO_MELHORIAS_MCP_MT5.md` | `PLANO_MELHORIAS_MCP_MT5.md` | Este documento |

---

## 6. PRÓXIMOS PASSOS RECOMENDADOS

### Fase 1 (Imediato)
1. [ ] Compilar `MCPServer.mqh` e `TradeLoggerSQLite.mqh` para verificar 0 erros / 0 warnings
2. [ ] Incluir `#include "Core/MCPServer.mqh"` em `XAU_AI_PRO.mq5`
3. [ ] Adicionar input `EnableMCPServer = false` e `MCPServerToken` em `Config.mqh`
4. [ ] Chamar `MCPServer.Init(MCPServerToken)` no `OnInit()`

### Fase 2 (Curto prazo)
1. [ ] Integrar `TradeLoggerSQLite` ao `OnTradeTransaction()` para gravar deals em SQLite
2. [ ] Criar endpoint MCP para receber comandos de IA (via WebRequest ou Socket)
3. [ ] Adicionar auditoria de ações MCP no `AuditLog`

### Fase 3 (Médio prazo)
1. [ ] Migrar `AuditLog` para SQLite
2. [ ] Usar OpenBLAS para cálculos de `AdaptiveWeights.mqh`
3. [ ] Implementar comunicação via socket com backend Python
4. [ ] Atualizar `PROGRESS.md` com ciclos 80+

---

## 7. RECURSOS DE REFERÊNCIA

- [MT5 Help — MCP and AI](https://www.metatrader5.com/en/terminal/help/mcp_and_ai)
- [MT5 Build 6060 Release Notes](https://www.metatrader5.com/en/releasenotes/terminal/2447)
- [MQL5 Article #23708 — MCP Accessibility Assistant](https://www.mql5.com/en/articles/23708)
- [MQL5 Documentation — Database Functions](https://www.mql5.com/en/docs/database)
- [MQL5 Documentation — Socket Functions](https://www.mql5.com/docs/constants/errorswarnings/errorcodes)

---

*Este plano foi elaborado com base na leitura completa do código-fonte do XAU_AI_PRO e pesquisa nas documentações oficiais da MetaQuotes/MQL5. Todas as sugestões são compatíveis com a arquitetura modular existente e não alteram regras de trading, risco ou execução.*
### 4.4 Prioridade Média — OpenBLAS para Cálculos de IA/ML

**Problema:** Os cálculos de IA (AdaptiveWeights, AIMetrics, PerformanceAnalyzer) usam aritmética básica MQL5.

**Solução:** Usar as novas funções LAPACK/OpenBLAS do Build 6060 para:
- Fatoração QR de matrizes de features
- Cálculo de Sharpe, Sortino, etc.
- Otimização de pesos adaptativos

**Exemplo:** `MQL_LAST_OPENBLAS_ERROR` para capturar erros de computação matricial.

---

### 4.5 Prioridade Média — Dashboard Reativo (CHARTEVENT_CHART_CHANGE)

**Problema:** O Dashboard não reage automaticamente a mudanças de escala de preço (`CHART_PRICE_MIN`/`CHART_PRICE_MAX`).

**Solução:** Usar o novo evento `CHARTEVENT_CHART_CHANGE` (Build 6060) para atualizar o Dashboard quando a escala do gráfico mudar.

---

### 4.6 Prioridade Média — Documentação e Versionamento

**Problema:** O `PROGRESS.md` documenta até v1.2.93 (ciclo 79), mas a versão atual é v1.2.111. Há divergência entre `EA_VERSION_STRING`, `#property version` e qualquer arquivo `VERSION` na raiz.

**Solução:**
1. Atualizar `PROGRESS.md` com ciclos 80+ (v1.2.94 → v1.2.111)
2. Criar `README.md` com índice da documentação
3. Sincronizar versões em todos os 3 locais (define, property, arquivo VERSION)
4. Documentar a arquitetura MCP em `Docs/MCP_ARCHITECTURE.md`
- PROGRESS.md documenta até v1.2.93 (ciclo 79, 02/11/2026)

---

## 3. NOVIDADES DO MT5 BUILD 6060 (APLICÁVEIS)

| Recurso | Descrição | Relevância para XAU_AI_PRO |
|---------|-----------|---------------------------|
| **MCP nativo** | Model Context Protocol integrado ao terminal e MetaEditor | Expor funcionalidades do EA para IA externa (Claude Code, Codex, etc.) |
| **AI Assistant** | Assistente integrado com MQL5 Lite gratuito | Desenvolvimento, debug, otimização via linguagem natural |
| **Provedores externos** | OpenAI, Anthropic, Gemini, DeepSeek, Ollama | Substituir ou complementar gateway HTTP local |
| **OpenBLAS/LAPACK** | Funções matemáticas avançadas (matrix factorization, BLAS L3) | Cálculos de IA/ML dentro do MQL5 (pesos adaptativos, Sharpe, etc.) |
| **CHARTEVENT_CHART_CHANGE** | Evento para mudanças de CHART_PRICE_MIN/MAX | Dashboard reativo a mudanças de escala de preço |
| **WebRequest timeout corrigido** | Timeout de requisição HTTP mais confiável | Gateway de IA mais estável |
| **SocketCreate** | MQL5 pode abrir sockets (até 128, TLS) | Comunicação mais rápida MT5 ↔ Python backend |
| **UTF-8 sem BOM** | .mq5/.mqh salvos sem BOM | Consistência com padrões atuais do MQL5 |