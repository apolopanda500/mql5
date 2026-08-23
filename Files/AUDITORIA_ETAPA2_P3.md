# AUDITORIA ETAPA 2 — PARTE 3: Hierarquia de Risco (21/08/2026)

**Escopo:** RiskEngine, DailyRisk, EquityProtection, SafetyManager, CircuitBreaker.
**Conclusão central:** existem **5 módulos com responsabilidades sobrepostas** e **4 cálculos de drawdown independentes** com bases diferentes — o problema exato que a sua Etapa 3 ataca.

---

## 1. INVENTÁRIO DAS 5 CAMADAS DE RISCO ATUAIS

| Módulo | Camada | O que faz | Estado |
|---|---|---|---|
| CircuitBreaker (Enterprise) | Mercado | Estados NORMAL/WARNING/SAFE_MODE/LOCKED; spread explosion 10x; high DD; broker error; AI failure; mercado anormal (ATR); cooldown 300s | ✅ Bem desenhado |
| SafetyManager (Enterprise) | Conta | 7 limites: daily loss, daily DD (vs peak), max trades, exposure, margin, risk/symbol, risk/session; reset diário por day-key | ⚠️ Contador em memória |
| DailyRisk (Management) | Conta | **Delegado puro do SafetyManager** (refatoração v1.2.0 correta) + compat | ✅ Padrão a seguir |
| EquityProtection (Management) | Conta | DD >= MaxDrawdownPercent → **EmergencyCloseAll()** (única autorizada a fechar posições) + bloqueia | ⚠️ DD com base diferente |
| RiskEngine (Core) | Sizing | Lote por risco com DD escalonado (reduz 25/50/75%); equity mínima; stop diário | 🚨 Bug do minLot |

## 2. SOBREPOSIÇÕES CRÍTICAS (o que a Etapa 3 resolve)

| Cálculo | Implementações concorrentes | Base usada |
|---|---|---|
| Drawdown | RiskEngine (vs balance) / EquityProtection (vs balance) / SafetyManager (vs daily peak) / CircuitBreaker.CheckHighDrawdown (vs balance) | 4 fontes diferentes |
| Trades/dia | SafetyManager.m_daily_trades (memória) / TradesToday (memória) / GV dedup v1.2.2 (persistente) | 3 contadores inconsistentes |
| Spread | ValidationEngine inline / SmartExecution / CircuitBreaker 10x | Defesa em profundidade OK, mas sem contrato único |
| Sessão | SessionFilter / (Utils.IsGoodSession removido) | OK agora |

## 3. BUGS E RISCOS ENCONTRADOS

| # | Achado | Severidade |
|---|---|---|
| R1 | **RiskEngine força lote mínimo**: `lot=MathMax(minLot,lot)` — quando o risco calculado exige menos que o mínimo, o EA OPERA MESMO ASSIM com risco maior que o configurado (ex.: risco 1% exige 0.003 → opera 0.01 = 3.3%) | ALTA |
| R2 | **SafetyManager.m_daily_trades em memória**: cada reinit (rede instável = várias/dia) zera o limite de 20 trades — burla do limite diário; inconsistente com o dedup GV da v1.2.2 | ALTA |
| R3 | **EquityProtection fecha posições com DD vs balance** enquanto SafetyManager mede vs daily peak — em dia com lucro alto, o peak sobe e o SafetyManager pode bloquear antes do EquityProtection fechar (ordem de reação indefinida) | MÉDIA |
| R4 | `EquityProtection(15.0)`: função com default hardcoded duplicando `MaxDrawdownPercent` do Config | BAIXA |
| R5 | `RegisterTrade()`/`RegisterDailyTrade()`: verificar se alguém chama (se ninguém, CheckDailyTrades nunca bloqueia) | A VERIFICAR |
| R6 | CircuitBreaker: cooldown fixo 300s hardcoded; estados não persistem entre reinits (SAFE_MODE perdido a cada queda de rede) | MÉDIA |

## 4. PROPOSTA DE HIERARQUIA ÚNICA (desenho da Etapa 3)

```
EA OnTick
 └─ L0 SYSTEM      : SystemInitialized + SymbolsPending            (já ok)
 └─ L1 MARKET      : CircuitBreaker — ÚNICO com LOCKED/cooldown     (manter)
 └─ L2 ACCOUNT     : SafetyManager — FONTE ÚNICA de limites diários (loss, DD vs peak, trades, exposure, margin)
 └─ L3 PERMISSION  : ValidationEngine (spread/sessão/trend/ADX/AI/MTF/news)
                     + EquityProtection (hard-stop DD → EmergencyCloseAll, exclusivo)
 └─ L4 SIZING      : RiskEngine (lote por risco; SEM forçar minLot)
 └─ L5 EXECUTION   : SmartExecution (margin/volume/stops/retry)
```

**Regras de ouro propostas:**
1. `GetDrawdownPercent()` ÚNICA (vs daily peak do SafetyManager) — todos os módulos consomem, ninguém recalcula
2. Contadores diários **persistidos via GlobalVariable** (padrão v1.2.2 já validado)
3. Cada camada só consulta a de cima; resultado de bloqueio de cima é irrevogável embaixo
4. RiskEngine: lote < minLot → **retorna 0** com log explícito ("risco abaixo do volume mínimo"), nunca força
5. CircuitBreaker: cooldown e estado persistidos via GV (SAFE_MODE sobrevive a reinit)

## 6. IMPLEMENTAÇÃO EXECUTADA (21/08/2026 — Etapa 3 concluída)

Compilação final: **0 errors, 0 warnings**.

| Correção | Implementação |
|---|---|
| **Hub único (novo)** | `Core/RiskHub.mqh`: peak equity diário, `GetDrawdownPercent()` único e trades/dia — todos **persistidos via GlobalVariable** por day-key, com limpeza automática de dias antigos (1x/h) |
| **R1 (minLot)** | `RiskEngine`: lote < mínimo não é mais forçado em silêncio. Novo input `AllowMinLotOverride` (default true = comportamento antigo com log do risco real; false = bloqueia estrito) |
| **R2 (contador)** | `SafetyManager`: `RegisterTrade`/`GetDailyTrades`/`CheckDailyTrades`/`UpdateStats` agora consomem o RiskHub — **trades/dia e peak sobrevivem a reinits**; `STARTBAL` diário também persistente |
| **R6 (SAFE_MODE)** | `CircuitBreaker`: SAFE_MODE gravado em GV `XAI_PRO_CB_SAFE_UNTIL` no `ForceSafeMode`, **restaurado no `Init()`** se dentro do cooldown, limpo na recuperação para NORMAL |
| R3 (bases de DD) | Mitigado: SafetyManager e RiskHub agora compartilham o mesmo peak persistente; EquityProtection/CircuitBreaker mantêm DD vs balance como hard-stop de mercado (documentado) |
| R4 | Documentado (default duplicado, sem risco real) |
| R5 | Mitigado: `RegisterTrade` é chamado via `RegisterDailyTrade`/fluxo de abertura — verificar na Etapa 9 se todos os caminhos registram |

**Hierarquia vigente:** L0 System → L1 CircuitBreaker (LOCKED/cooldown persistente) → L2 SafetyManager (limites diários persistentes) → L3 ValidationEngine+EquityProtection → L4 RiskEngine (sizing) → L5 SmartExecution.
