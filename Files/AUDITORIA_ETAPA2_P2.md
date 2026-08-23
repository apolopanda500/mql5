# AUDITORIA ETAPA 2 — PARTE 2: Caminho do Sinal (21/08/2026)

**Escopo:** SignalCore, DecisionEngine, ValidationEngine, Filters (Spread/Session/Trend/MTF/News).
**Método:** leitura integral + varredura cruzada de usos.

---

## 1. CADEIA COMPLETA DO SINAL (mapeada de ponta a ponta)

```
OnTick -> RunTradePipeline (por símbolo ativo)
  -> ProcessSymbol(symbol)              [MarketScanner.mqh:L56]
    -> GetDecision(symbol)              [DecisionEngine]
       -> GetSignal(symbol)             [SignalCore - sinal bruto]
          BUY : EMA50>EMA200 (vela fechada) && RSI[1]<45 && RSI virando p/ cima
          SELL: EMA50<EMA200 (vela fechada) && RSI[1]>55 && RSI virando p/ baixo
       -> AllowTrade(signal, symbol)
          -> ValidateTrade(symbol, signal)   [ValidationEngine - 7 gates]
             1. SPREAD inline vs GetMaxSpread (por símbolo)
             2. SESSION IsTradingSession (0-24h = sempre aberto hoje)
             3. TREND TrendBuy/TrendSell (preco vs EMA200 H1)
             4. ADX >= MinimumADX (18.0)
             5. AI AITradeAllowed (se EnableAIFilter)
             6. MTF MTFApproved (EMA20>EMA50 no M15)
             7. NEWS CanTradeNews (calendario economico nativo MQL5)
          -> CalculateMarketScore: 50 base
             +20 EMA alinhada | +RSI quality | +ADX quality | +AI confidence*0.5
             CORTE: score >= 60.0 senao DECISION BLOCKED
    -> (aprovado) execucao via ExecutionEngine/SmartExecution
```

## 2. ACHADOS POR MÓDULO

### SignalCore.mqh — ✅ BEM PROJETADO
- **Cache de handles por símbolo** (EMA fast/slow + RSI criados 1x, liberados no OnDeinit). Correção v1.2.0 documentada no cabeçalho.
- Sinal usa **vela fechada** (índice 1) — sem repaint.
- Menor: comentário cita "M15" mas usa PERIOD_CURRENT (H1 nos gráficos). Só documentação.

### DecisionEngine.mqh — ✅ funcional / ⚠️ performance
- Score heurístico transparente (50 base + bônus). Corte fixo 60.
- ⚠️ Cria e libera handles iMA (FastEMA/SlowEMA) **a cada chamada** — mesmo problema que o SignalCore já resolveu para o próprio GetSignal. Duplicação de handles EMA idênticos!

### ValidationEngine.mqh — ✅ funcional / ⚠️ duplicações
- 7 gates em cascata com logs claros `[VALIDATION] BLOCK/APPROVED`.
- ⚠️ Reimplementa inline o cálculo de spread em vez de chamar `GoodSpread()` do SpreadFilter (lógica duplicada, log duplicado).
- Prints `[VALIDATION]` sem throttle a cada chamada — contribui para o spam de log (A10).

### Filters — status individual
| Filtro | Estado | Observação |
|---|---|---|
| SessionFilter | ✅ OK | Trivial; hoje 0-24h = sempre aberto |
| TrendFilter | ✅ ok / ⚠️ perf | Handle _Symbol cacheado, mas multi-símbolo cria+libera handle POR consulta |
| MultiTimeframeFilter | ✅ ok / ⚠️ perf | Mesmo padrão: CreateMTFHandles + release por consulta (EMA20/50 no M15) |
| SpreadFilter | ⚠️ parcialmente morto | `GoodSpread` só usado por AdvancedAI (órfão); `GetCurrentSpread` usado pelo CircuitBreaker (vivo); ValidationEngine reimplementa inline |
| NewsFilter | 🌟 **JÁ É REAL** | Usa CalendarValueHistory nativo + TimeTradeServer + janelas before/after + impacto configurável |

## 3. DESCOBERTA IMPORTANTE — ETAPA 6 JÁ ESTÁ ~80% IMPLEMENTADA

O NewsFilter atual **não é modo seguro**: já consome o calendário econômico nativo do MT5
(`CalendarValueHistory`), usa horário do servidor (`TimeTradeServer`), janelas configuráveis
(`NewsMinutesBefore/After`) e threshold de impacto (`NewsImpactThreshold`).

Falta para fechar a sua Etapa 6:
1. **Filtro por moeda** (hoje considera eventos de TODAS as moedas; ideal: USD/BRL-relevante ao símbolo via CalendarCountry)
2. **Throttle da consulta** (variável `lastNewsCheck` existe mas nunca é usada — CalendarValueHistory roda a cada validação)
3. Estados explícitos NEWS_CLEAR/WARNING/BLOCK (hoje só bool newsBlocked)
4. Verificar inputs reais no Config (EnableNewsFilter está ON ou OFF?)

## 4. NOVAS ANOMALIAS (continuação A11+)

| # | Anomalia | Impacto | Recomendação |
|---|---|---|---|
| A11 | Handles de indicador criados/liberados por chamada: DecisionEngine (EMA), TrendFilter (multi-symbol), MTFFilter | CPU/memória desperdiçados; lentidão no scanner 9 símbolos x ticks | Replicar o padrão de cache do SignalCore (já existe modelo pronto no projeto) |
| A12 | Spread validado 2x no fluxo (ValidationEngine inline + SmartExecution::ValidateExecution) | Redundância + log duplo | Aceitável como defesa em profundidade; padronizar via SpreadFilter único na Etapa 3 |
| A13 | NewsFilter: sem throttle (lastNewsCheck morto) e sem filtro por moeda | Chamadas de calendário excessivas; bloqueios por notícia irrelevante à moeda | Fechar na Etapa 6 |
| A14 | Statics de log 1x/min compartilhados entre os 9 símbolos (GetSignal/AllowTrade/GetDecision/CalculateMarketScore) | Log de diagnóstico cobre só o primeiro símbolo processado por minuto | Trocar static simples por mapa por símbolo (Etapa 9) |

## 6. RESOLUÇÕES APLICADAS (21/08/2026 — Etapa 6 + NO_MARGIN)

### Etapa 6 — NewsFilter profissional (NewsFilter.mqh reescrito, 332 linhas)
- ✅ **Estados explícitos**: `ENUM_NEWS_STATE { NEWS_CLEAR, NEWS_WARNING, NEWS_BLOCK, NEWS_ACTIVE }`
- ✅ **Throttle real**: `lastNewsCheck` agora funciona — calendário consultado no máx. 1x/60s (`NEWS_REFRESH_SEC`)
- ✅ **Filtro por moeda**: input `NewsCurrencies` (era órfão desde v1.2.0!) implementado; vazio = auto-derivação pelo símbolo (XAUUSD→USD, EURUSD→EUR+USD) com lista de 24 moedas FX
- ✅ **Bug do cast corrigido**: código antigo tratava `value.impact_type` (POSITIVE/NEGATIVE) como importance — com threshold 2 bloqueava só notícias de impacto *negativo*. Agora usa `event.importance` real via `CalendarEventById`
- ✅ Janela WARNING = 2x janela de bloqueio (`NEWS_WARNING_FACTOR`)
- ✅ Fail-open em erro de calendário; compat total (`CanTradeNews/IsNewsTime/IsNewsBlocked/PrintNewsStatus`)
- ⚙️ `EnableNewsFilterReal` removido do Config (input órfão); **`EnableNewsFilter=false` permanece OFF — ativação é decisão operacional**

### NO_MARGIN resolvido (2 correções)
- **Causa raiz dupla**: (1) IA multiplicava lote (0.01×1.25=0.0125) e o `CheckMargin` rodava com volume NÃO normalizado → margem inflada $198 > limite 90%×$189; (2) fórmula manual `(vol×contract×price)/lev` multiplica pelo preço mesmo quando USD já é a moeda base (USDJPY: $10 real → $159 calculados)
- **Fix 1**: `SmartExecution::ValidateExecution` normaliza volume antes do CheckMargin
- **Fix 2**: `MarginChecker::CalculateRequiredMargin` usa `OrderCalcMargin()` nativo (conversão de moeda exausta) com fallback manual
- Compilado: **0 errors, 0 warnings**

### Incidente operacional (documentação)
17:29: usuário removeu os EAs dos gráficos (Reason=2) após spam NO_MARGIN; compilação falha das 18:12 deletou o .ex5 durante o boot do terminal → EAs não recarregaram sozinhos. `.ex5` restaurado 18:19/18:38. **Recarga manual nos 3 gráficos pendente do usuário.**


## 7. POR QUE ENTRA / NAO ENTRA (mapeamento pre-correcoes)

Com o mapeamento acima, todo bloqueio hoje produz log rastreável:
- `[VALIDATION] BLOCK | SPREAD/SESSION/TREND/ADX/AI/MTF/NEWS`
- `DECISION BLOCKED | Score=X`
- `[TRADE BLOCK] SAFETY/CIRCUIT/EQUITY` (camadas Enterprise, OnTick)

**Gap para a sua Etapa 4 (máquina de estados):** os logs existem mas não há um registro estruturado único por tentativa (trade_id, score, gate que bloqueou). O esqueleto para isso entra na Etapa 4/9.
