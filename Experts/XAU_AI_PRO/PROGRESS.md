# XAU_AI_PRO — Registro de Progresso

> Plataforma XAUUSD: modular, auditável, testável e preparada para operação.
> Última atualização: 2026-11-04 (v1.2.135) — índice geral em `README.md`
> Lista viva de pendencias (com dono e criterio de fechamento): `PENDENCIAS.md`.

---

## Ciclo 2026-09-07 — testes ADX (SHORT/LONG) + C5 + health

### TEST_ADX (filtro ADX MinimumADX=18, fail-open SKIP + sentinela)

| Métrica | SHORT (02–03/09) | LONG (01/08–05/09) |
|---|---|---|
| Barras | 264 | 6.600 |
| Ticks | 447.571 | 10.839.724 |
| Deals / Trades | 40 / 20 | 1.611 / 1.165 |
| Long / Short | 4 / 16 | 814 / 351 |
| P/L | −155,10 | −454,56 |
| Profit Factor | 0,49 | 0,80 |
| DD balance | 2,98% | 9,56% |
| Expected payoff | — | −0,39 |
| Sharpe | — | −3,51 |
| ADX unavailable / valid / block | 1 / 17.134 / 4.531 | 1 / 5.930.462 / 498.965 |

**Reading:** `GetADX()<0 → fail-open`, `ADX<18 → BLOCK` funcional (block crece con la ventana; PASS real en USDJPY 34,08 / USDBRL 37,61). La estrategia base NO es rentable en ventana larga (PF 0,80, E=−0,39, DD 9,9%). **No producción.**

### Reconciliação C5 (window ≥ 2026.09.02 00:33:40 servidor)
- missing_audit_entry=0 · dup_exec=0 · unknown_event_tickets=[] (el falso positivo 10090527226 = caché API, confirmado)
- missing_event_entry=2: tickets 10067813690, 10068219749 (build antiguo 04/09, pre-fix ADX)
- Broker: 201 deals, net +9,96, 1 posición EURUSD abierta
- **C5 = 3/4 limpias; cerrado para el build actual** (2 pendientes son de build anterior). No se implementa Opción A (re-emisión al arranque) → evita rebuild+reload = nuevo T0.

### HEALTH ERROR en producción — causa raíz (falso positivo)
- Heartbeats ATR/ADX/RSI/AI = inicio de OnTick; CSV/JSON/PYTHON = final (tras `UpdateDataset` = tras todos los early-return).
- Trades: 20/20 (SAFETY MAX_TRADES_PER_DAY) → OnTick retorna en `CSafetyManager::CheckAll()` ANTES del heartbeat dataset/python → 3 módulos sin batir → 3× warning + HEALTH FAILURE por check.
- Backoff exponencial confirmado (60→120→…→1920 s; techo 32 min).
- **No es fallo de engine/dataset/python/AI.** Auto-recupera al resetear el contador diario. Fix cosmético recomendado (beat pre-bloqueo).

### Endurance técnico del build nuevo
- `XAU_AI_PRO.ex5` (07/09 03:27Z, fix ADX): run LONG = 10,84 M ticks / 6.600 barras SIN crash → evidencia de estabilidad (C2/C3 técnico con build nuevo).
- Disco: 10,79 GB libres tras rotación de logs.

### Fix definitivo — LIVENESS vs PROGRESS (auditado + refeito, 07/09)
- `HealthMonitor.mqh`: novo canal `g_wdLastProgress[]`/`g_wdProgressFails[]` + funcoes `HealthMonitorProgress()` e `HealthIsPipeline()`.
- `HealthMonitorCheckHeartbeatModule()`: modulos pipeline (PYTHON/CSV/JSON) usan `g_wdLastProgress` (so avanza con `UpdateDataset` real -> detecta parada real); indicadores/AI usan `g_wdLastTime` (liveness por tick).
- `XAU_AI_PRO.mq5`: **removidos** os 3 heartbeats do topo do OnTick (mascaravam parada); o bloco pos-UpdateDataset agora chama `HealthMonitorProgress("CSV"/"JSON"/"PYTHON")`. OnInit mantiene heartbeats iniciais (liveness base).
- Build validado: **0 erros, 0 warnings** (07/09 17:33). `.ex5` regenarado (410.498 B). Aplicacion exige reload dos 7 charts = novo T0.
- **Nota de proceso:** durante a edicion um helper corrompiu temporalmente o `.mq5` (delete en offset errado); restaurado via `git checkout -- XAU_AI_PRO.mq5` e re-aplicado o fix cirurxicamente. Estado final: LF consistente, 0/0.

## Resumo de status (Etapas do roadmap)

| Etapa | Status | Observação |
|---|---|---|
| 1 — SignalCore (entrada + A/B) | ✅ | Baseline aprovado; estratégia B (EMA+ADX+Breakout) experimental |
| 2 — DecisionEngine | ✅ | Auditado; TF da EMA do score alinhado à estratégia; anti-repaint (vela fechada) |
| 3 — ValidationEngine | ✅ | Auditado (9 filtros); código de rejeição estruturado adicionado |
| 4 — RiskEngine | ✅ | Cadeia equity→%→SL→tick→lote completa; drawdown via RiskHub |
| 5 — ExecutionEngine | ✅ | Auditado; não-grava sinais; inclui simulação e blindagem a duplicidade |
| 6 — PositionManager | ✅ | BE, trailing ATR, parcial, controle de posições; padrões registrados |
| 7 — IA/ML (infra) | ✅ | Veto/direção/score/lote/feedback + **AIMetrics** (accuracy/precision/recall) |
| 8 — Backtest protocol | 🔄 | A/B rodados; E (OOS) inconclusivo; F (recente) rodando |
| 9 — Robustez | ⏳ | — |
| 10 — Broker/Environment | ✅ | Detecção automática (símbolo/digits/point/spread/volume/stops/freeze); `ProbeSymbolProfile()` |
| 11 — Data + Telemetry | ✅ (parcial) | código de rejeição integrado; "porquê não entrou" disponível |
| 12 — Dashboard | ✅ | Ampliado: Trend, Regime, IA Dir/Conf, DD RiskHub e mais (build OK) |
| 13 — PLATFORM/BACKEND | ✅ | DatabaseManager (SQLite): analytics reais — `GetTotalProfit/Trades/WinRate/ProfitFactor` implementados |
| 14 — Segurança operacional | ✅ | CircuitBreaker robusto: kill-switch, DD, spread(10x), IA fallback, broker, mercado anormal, persistência, auto-recovery, FailSafe API |
| 15 — Forward test | ⏳ | — |

---

## Resultado A/B (Etapa 1/8) — XAUUSD M5 (14–24/08, ticks reais)

| Métrica | A (baseline RSI) | B (EMA+ADX+Breakout) |
|---|---|---|
| Lucro | **-14,45** | -66,17 |
| Profit Factor | **0,8855** | 0,2033 |
| Trades | 49 | 15 |
| Win rate | 59% | 40% |

**Decisão:** baseline A aprovado como entrada corrente. B mantido experimental (não segue para produção até atingir consistência).

**Requisito de engenharia:** cada backtest every-tick XAU M5 leva ~1h50–2h real. Perfil `TESTE_F_OTIMIZADO.ini` (logs off, Model=2) acelera janelas longas.

## IA — snapshot vs. walk-forward
`prediction_XAUUSD.json` é um snapshot único e estático. Rodar o Teste C/D com ele num período longo é inválido (mesma predição "BUY 87.86" em todas as barras). Só é válido após predição intraperioodal / walk-forward (pipeline Python externo).

## Mudanças v1.3.1 (recentes)
- `ValidationEngine.mqh`: `enum ValidationRejectCode` + `GetLastReject()` + `RejectCodeToString()` — observabilidade sem mudar decisão.
- `DecisionEngine.mqh`: EMA do `MarketScore` alinhada ao TF da estratégia; usa vela fechada `[1]`.
- `SignalCore.mqh`: seletor `XAU_UseNewStrategy` permite A/B em runtime; interfaces `GetSignal()/GetSignal(symbol)` preservadas.
- `SymbolValidator.mqh`: `ProbeSymbolProfile()` consolida detecção broker (digits/point/tick/volume/stops/freeze/spread).
- `Dashboard.mqh`: ampliado com Trend, Regime, IA Dir/Conf, DD (RiskHub).
- Perfis de teste otimizados (`.ini` com logs off) p/ janelas longas.
- Build validado: 0 erros, 0 warnings em todo o projeto.

## Notas de risco
- `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent` não alterados (capital real).
## Ciclo 2026-10-29 — EA desbloqueado para operar sozinho (conta 113568614)

Diagnóstico feito no journal ao vivo, não por suposição: 13 gráficos com
`AutoTrade=true`, zero posições. Dois bloqueios independentes barravam tudo:

1. **Gate de IA obrigatório sem gateway.** Com `EnableAIFilter=true`,
   `AllowTradeWithoutAI=false` e o gateway Python (127.0.0.1:9001) fora do ar:
   `ValidateTrade -> AITradeAllowed()` comparava confiança de fallback 40
   (teto `AIUnavailableConfidenceCap`) com `MinAIConfidence=50` e devolvia
   `false`; e `AllowTrade -> FinalAIAllow()` devolvia `false` em
   "IA indisponível". Journal: `[VALIDATION] BLOCK | AI | NZDUSD`.
2. **SAFE_MODE global disparado por um símbolo exótico.** `CheckAbnormalMarket`
   via `[CIRCUIT] ABNORMAL MARKET | USDBRL | Ratio=3.64` e chamava
   `ForceSafeMode`, que é persistido em `GlobalVariable` e parava os 13
   gráficos (`[TRADE BLOCK] CIRCUIT BREAKER | State=SAFE_MODE`).

### Correções

- `Core/Config.mqh`: novo input `EnableAutonomousMode=true` (IA consultiva:
  continua pontuando/logando, não veta e não exige gateway) e `MinMarketScore`
  (piso de score antes fixo em 60.0 no código).
- `AI/AIEngine.mqh`: `AIGateRequired()` como autoridade única do gate de IA,
  consultada por `AITradeAllowed()`, `GetAIConfidence()` e `FinalAIAllow()`.
- `Enterprise/CircuitBreaker.mqh`: `CircuitAbnormalMarketBlocksAll=false`
  (anomalia de ATR restrita ao símbolo via `CanTrade(symbol)`) e
  `CircuitAbnormalATRRatio` parametrizado.
- `Core/RiskEngine.mqh` + `Core/ExecutionEngine.mqh`: **lote e stop na mesma
  unidade.** Medido: US$ 2,00 de risco com 0,41 lote davam stop de 5 PONTOS
  (0,5 pip, dentro do spread) — 3 posições fecharam em stop loss imediato.
  Agora `CalculateLotByRiskUSD`/`CalculateLotByRiskAuto` dimensionam o lote
  para que `StopLossPoints` valha `RiskPerTradeUsd`.

### Validação

- Compilação: 0 erros, 0 warnings (`XAU_AI_PRO.mq5`, build 6292 x64).
- Operações reais após recarga: `RISK CALC USD | Risco=2.00 USD | Stop=300 pts`
  e posições abertas com SL/TP de 300 pontos (ex.: NZDUSD 0.56264 /
  SL 0.56565 / TP 0.55965; USDCNH 6.65671 / 6.65971 / 6.65371).
- `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent` não alterados.

## Ciclo 2026-10-29 (2) - EA aprende com o historico real (manual + EA)

Objetivo: a AILearningMemory era volatil (zerava a cada recarga) e nunca era
alimentada. Agora existe aprendizado persistente baseado no historico real da
conta, incluindo as operacoes MANUAIS do usuario.

### Arquivos

- `AI/LearningHistory.mqh` (novo): diario append-only + ingestao via HistorySelect.
- `AI/AILearningMemory.mqh`: flag `g_AILearnQuiet` para silenciar o log durante
  importacao em lote (o resumo e impresso uma vez).
- `Core/DecisionEngine.mqh`: aplica `LearningAdjustedScore()` ao MarketScore.
- `XAU_AI_PRO.mq5`: include do modulo, `AILearningInit()` em InitializeModules,
  `AILearningImportHistory()` no OnTimer (throttle 1h/conta) e
  `AILearningRecordDeal()` no fechamento em OnTradeTransaction.

### Persistencia

- Arquivo: `MQL5\Files\Data\XAU_AI_PRO_learning.csv` (append-only, uma linha por
  evento: `simbolo;ticket;direcao;confianca;resultado;hora`).
- Na inicializacao o arquivo e reproduzido (`LearningReplayJournal`) e a memoria
  e reconstruida identica - sobrevive a recarga, troca de grafico e reinicio.
- Cursor por simbolo (`ultimo ticket`) impede contar o mesmo trade duas vezes.
- Ingestao completa roda 1x por hora por conta (GlobalVariable
  `XAI_PRO_LEARN_IMPORT_<login>`), evitando custo em 13 graficos.

### Criterio de ingestao

- Somente deals de saida (`DEAL_ENTRY_OUT` / `DEAL_ENTRY_OUT_BY`) de BUY/SELL.
- Operacao manual: `DEAL_MAGIC == 0` (input `LearningImportManualTrades`).
- Operacao do EA: `DEAL_MAGIC == MagicNumber` (input `LearningImportExpertTrades`).
- Resultado liquido = PROFIT + SWAP + COMMISSION; empates nao contam.

### Uso no score

- `LearningAdjustedScore()` aplica `MemoryBoost(simbolo)` ao MarketScore.
- `LearningPenaltyEnabled=false` (padrao): o aprendizado so INCENTIVA (boost>=1).
  Memoria negativa NAO reduz o score - evita reintroduzir bloqueios globais no
  EA autonomo. Ligue o input para permitir penalidade.
- Inputs novos: EnableLearningFromHistory, LearningImportManualTrades,
  LearningImportExpertTrades, LearningHistoryDays(180), EnableLearningBoost,
  LearningPenaltyEnabled(false).

### Validacao (conta 113568614, 29/10/2026 16:0x)

```
[LEARN] historico importado | janela=180d | deals=81 | manuais=21 | doEA=60 | empates=0
[LEARN] memoria restaurada do disco | linhas=81 | aplicadas=81 | simbolos=10
[LEARN] XAUUSD | T=24 W=20 L=4 WR=83.3% MEM=16.00 BOOST=1.18
[LEARN] USDCNH | T=27 W=21 L=6 WR=77.8% MEM=15.00 BOOST=1.18
[LEARN] AUDUSD | T=7 W=7 L=0 WR=100.0% MEM=7.00 BOOST=1.06
[LEARN] USDSEK | T=6 W=0 L=6 WR=0.0% MEM=-6.00 BOOST=1.00 (penalidade off)
```

Compilacao: 0 errors, 0 warnings. Posicoes abertas preservadas (USDCNH 0.04,
NZDUSD 0.01) - o aprendizado nao intercepta execucao nem gestao.

### Nota

Aprendizado e observacional: nao garante melhora de resultado. Validar no
Strategy Tester antes de qualquer conta real.


## Ciclo 2026-10-29 (3) - 8 melhorias aprovadas (v1.2.10)
Mapa feito antes de codar: a maior parte dos 8 itens ja existia em Core/Config.mqh e nao foi duplicada.
### Ja existia (auditado)
- Risco por % tem prioridade sobre RiskPerTradeUsd: RiscoPorTradeUsd() usa RiskPerTradePercent quando > 0.
- Envelope de risco total (MaxTotalRiskPercent) com RiscoAbertoUSD() contando posicoes stopless por StopLossPoints.
- Entrada sem SL (EnableStoplessEntry + StoplessArm/Lock/ATRMult) e alvos adaptativos (DynTPFactor*).
- Lote dinamico por confianca/ADX (EnableDynamicLot, DynLotFactor*, DynConf*, DynADX*) com MaxRiskPerTradePercentCap=3.0.
- Pipeline unico entre graficos: PipelineIsMaster() (GlobalVariable XAI_PRO_PIPE_MASTER_<login> + heartbeat 180s, takeover automatico).
- Meta de lucro diario (EnableDailyProfitTarget / DailyProfitStopTrading / DailyProfitProtectPositions) e spread por simbolo (GetMaxSpreadPct).
### Adicionado neste ciclo
1. Risco efetivo observavel - Core/ExecutionEngine.mqh: log [RISK] risco EFETIVO acima do pedido com pedido/efetivo/fator/lot/stop. Input EffectiveRiskWarnFactor=1.5.
2. RR minimo - input MinRewardRatio=0.0 (desligado). Quando > 0 eleva o TP ate o piso em vez de recusar a entrada, e loga [RISK] RR da entrada (TP/SL/RR reais).
3. Trava por TEMPO por simbolo - Core/MarketScanner.mqh: MinSecondsBetweenTradesPerSymbol=300 via GlobalVariable XAI_PRO_LASTTRADE_<simbolo>_<login>, sobrevive a recarga. Antes a trava usava PERIOD_CURRENT do grafico mestre, entao um grafico M1 liberava o simbolo a cada minuto.
4. Bloqueio opcional de direcao ruim - EnableDirectionBlacklist=false, DirectionBlacklistMinTrades=5, DirectionBlacklistMaxWR=30.0. LearningDirectionBlocked() em ProcessSymbol antes de STATE_SIGNAL_GENERATED. Fica opt-in porque o boost nunca bloqueia (LearningPenaltyEnabled=false piso 1.0).
5. Aprendizado por hora/sessao - AI/LearningHistory.mqh: AILearningHour + HourStore/HourWinRate/HourBoost/HourSummary. HourBoost aplicado dentro de LearningAdjustedScore. Hora extraida do campo 6 do diario, sem migrar as linhas antigas. Log [LEARN] com MELHOR_HORA/PIOR_HORA.
6. Estado de sessao persistente - novo Core/SessionState.mqh gravando Data/XAU_AI_PRO_session.csv (login/dia/trades/W/L/pico/saved). Por conta E por dia do servidor, dia diferente descarta tudo. Restaurado no OnInit, gravado a cada 300s no OnTimer e forcado no OnDeinit.
7. Guarda de exposicao manual - EnableManualExposureGuard=true / ManualGuardAllowSameDirection=false. ForeignPositionDirection/ManualGuardState dentro de CanOpenPosition + log [POSITION GUARD] a cada 60s.
8. WR no SystemStatus - Monitoring/SystemStatus.mqh: SSLearningSection() no JSON com enabled/trades/wins/winrate/boost/dir_buy_wr/dir_buy_n/dir_sell_wr/dir_sell_n/hour/hour_wr/hour_n/dir_block_enabled/summary.
### Bugs encontrados na validacao (corrigidos)
- SystemStatus.mqh estava truncado em 270 linhas (perdia FileWriteString/FileClose/fechamento do bloco/#endif): erro mismatched #ifdef e unbalanced parentheses. Cauda reanexada.
- LearningHistory.mqh aplicava StoreExperience() DUAS vezes por linha no replay, dobrando a memoria a cada recarga (XAUUSD T=24 -> 48, USDCNH 31 -> 62). Agora 1 aplicacao por linha.
- SessionStateRestore() estava definido mas nunca chamado no OnInit (a edicao anterior nao entrou), por isso so aparecia [SESSION] estado salvo. Agora e chamado logo apos PeakEquity.
### Validacao
- Compilacao: 0 errors, 0 warnings (13529 ms, X64 Regular).
- MQL5/Files/Data/system_status.json ja contem o objeto learning com enabled=true, boost e os campos por direcao/hora.
- Journal: [LEARN] com MELHOR_HORA/PIOR_HORA confirmado e [SESSION] estado salvo com dia=2026.10.30 e pico=12332.19.
- Pendente de verificacao ao vivo: a linha [SESSION] estado restaurado so aparece no proximo OnInit/reload do EA.
### Nota operacional
- Bloqueio real de novas entradas hoje: AI INVALID JSON SYMBOL (gateway Python 127.0.0.1:9001 offline) com AllowTradeWithoutAI=false.
- RiskPerTradeUsd=2.0 com StopLossPoints=300 faz quase todo par cair no lote minimo 0.01 (risco real US$0.30-3).


## Ciclo 2026-10-29 (4) - destravado o conflito IA x tecnico

### Diagnostico (medido, nao suposto)
- 3h de journal sem UMA linha DECISION: o funil morria antes do AllowTrade.
- O unico bloqueio visivel era [SCANNER] BLOCK | No Signal, e o log era
  limitado por UM static compartilhado: so 1 simbolo logava por minuto.
- Causa raiz: GetCombinedSignal devolvia 0 sempre que tecnico e IA apontavam
  lados opostos (return 0 seco). Com previsao fraca/desatualizada isso
  zerava TODA entrada, sem log e sem chance de AllowTrade.

### Mudancas
- AI/AIEngine.mqh: nova AIConflictBlocks(). A IA so cancela a entrada quando
  esta fresca (AI_IsStale=false) E confiavel (AI_Score >= AIConflictMinScore).
  Fora disso o tecnico prevalece e o evento vira log [AI CONFLICT] (1/min).
- Core/Config.mqh: inputs EnableAIConflictResolve=true e AIConflictMinScore=80.0.
  EnableAIConflictResolve=false restaura o comportamento antigo (empate = parar).
- Core/MarketScanner.mqh: throttle de log POR SIMBOLO (arrays static). Antes
  apenas um simbolo por minuto aparecia no journal, mascarando os outros 10.

### Validacao
- Compilacao: 0 errors, 0 warnings (14456 ms, X64 Regular).
- Strategy Tester XAUUSD M15 20-29/10/2026, 1 min OHLC, 10000 USD, 1:100:
  303 trades, 335 deals, PF 0.8961, lucro -30.95, DD max 1.68%.
  Conclusao: a maquinaria de sinal/execucao funciona; o problema nao era
  codigo morto. O resultado da janela e break-even negativo - nao e prova
  de lucratividade e pede otimizacao antes de conta real.
- Backtest 1 (sem .set) mostrou AutoTrade=false bloqueando tudo: o tester
  herdou inputs antigos. Backtest 2 com AutoTrade=true liberou as 303 entradas.
- Ao vivo: posicao aberta pelo EA as 19:35 (servidor 00:35) - USDCNH sell
  1.36, magic 2026001, comment XAU_AI_PRO.

### Portoes ainda ativos (vistos no journal)
- [TRADE BLOCK] CIRCUIT BREAKER | Abnormal market: USDBRL (SAFE_MODE).
- [TRADE BLOCK] CIRCUIT BREAKER | Broker connection or trading disabled.
- [SCANNER] BLOCK | intervalo minimo do simbolo (MinSecondsBetweenTradesPerSymbol=300).

### Atencao
- Lote 1.36 em USDCNH e muito acima do 0.04 anterior: conferir
  RiskPerTradePercent=0.5 + EnableDynamicLot (DynLotFactor* ate 4.0).
- Janela de mercado: sem ticks o pipeline nao roda e o EA fica mudo no journal.

## Ciclo 2026-10-29 (5) - correcao guiada pelo historico real (ai_feedback.csv)

### Diagnostico (402 resultados fechados, 2026.08.24 a 2026.10.29)
- WR real 68.9%, soma -10.51. Media ganho +0.555 x media perda -1.313
  (payoff 0.476). Com WR 68.9% o RR de equilibrio e 0.319 - a borda
  existe, mas e fina e e consumida por duas caudas:
- Score IA == 0: 67 entradas, WR 34.3%, liquido -56.77.
  Score > 0: 335 entradas, WR 75.8%, liquido +46.26.
- Horas 0h e 20h: 58 entradas, -59.75 (20h com WR 21.1%).
  Restante: +79.15 com WR 78.2%.
- Filtro testado (score>0 E hora fora de {0,20}): 303 entradas,
  liquido +79.15; descartadas 99 entradas com -89.66.

### Mudancas
- AI/AIEngine.mqh: veto de score zero dentro de FinalAIAllow.
  AIGateRequired() e false com EnableAutonomousMode=true (padrao) e com
  AllowTradeWithoutAI=true, e nesse caminho a funcao devolvia TRUE sem
  olhar o score. Era assim que 67 entradas sem leitura passavam.
  Log: [ADV AI] BLOQUEADO | score=.. (sem leitura).
- Core/Config.mqh: input bool BlockZeroAIScore = true.
- Core/Config.mqh: input string AvoidHoursList = 0,20.
- Filters/SessionFilter.mqh: IsAvoidHourListed() + IsAvoidedHour().
  Aceita " / off / none para desligar; ignora valores fora de 0..23.
- Core/ValidationEngine.mqh: veto PROPRIO de hora proibida em ValidateTrade,
 independente de EnableSessionFilter (que e false por padrao e por isso
 nunca bloqueava nada). Log: [VALIDATION] BLOCK | AVOID HOUR | simbolo.
- Core/Config.mqh: RewardRatio 0.50 -> 0.65.
- Core/ExecutionEngine.mqh: MinRewardRatio 0.00 -> 0.55. Piso de RR que
 ELEVA o TP (nunca rejeita a entrada). Log: [RISK] alvo elevado ...

### Observacao importante sobre o TP
- Com EnableAdaptiveTargets=true (padrao) o TP NAO vem de RewardRatio:
 vem de TargetFactorForGrade(conviccao) -> DynTPFactorMin/Base/Clear/
 Strong/Elite (0.35/0.50/0.80/1.20/2.00). RewardRatio so governa o
 caminho nao-adaptativo e as projecoes do OrderManager.
 Para mexer no TP de verdade: DynTPFactor* ou EnableAdaptiveTargets=false.

### Validacao
- Compilacao: 0 errors, 0 warnings (13829 ms, X64 Regular, build 6292).
- Backtest 20-29/10/2026: pendente nesta entrada (o Strategy Tester estava
 executando um job anterior de 3 meses com ticks reais). Config e .set
 prontos: Profiles/Tester/xai_v1300_c5.ini e xai_v1300_c5.set
 (AutoTrade=true, RewardRatio=0.65, MinRewardRatio=0.55,
 AvoidHoursList=0,20, BlockZeroAIScore=true).

### Pendente / risco aberto
- Confirmar resultado do backtest na janela 20-29/10 e comparar com o
 baseline de 303 trades / PF 0.8961 / -30.95 / DD 1.68%.
- Lote 1.36 em USDCNH (posicao 11166638047) continua merecendo revisao.
- Aprendizado do historico MANUAL do dono ainda nao existe: AILearningMemory
 e so memoria de processo e nao le HistorySelect. Precisa de persistencia
 em Data/ + ingestao no OnInit para sobreviver a recarga.
## Ciclo 2026-10-29 (6) - fim do spam de log que inviabilizava o backtest

### Diagnostico medido
- O Strategy Tester ficou preso em um job antigo (12 simbolos, ticks reais,
  2026.07.29->2026.10.29) iniciado as 20:51. Em ~25 minutos o arquivo
  Tester\logs\20261029.log chegou a 1,16 GB e continuava crescendo
  (~0,75 MB/s), com o tempo simulado ainda em 2026.07.30 13:10 - ou seja,
  ~2 dias simulados por 25 min reais. Nao era lentidao do modelo: era I/O
  de log.
- Amostra do final do log mostrava o padrao dominante repetido a cada tick:
  "[TRADE PIPELINE] INICIANDO" + "[VALIDATION] USDBRL | Spread=16.00 |
  Max=308.75" + "[VALIDATION] BLOCK | TREND BUY | USDBRL". Causa:
  ValidateTrade() roda no OnTick e os 20 Print de validacao eram
  incondicionais.
- O hotfix v1.2.15 (anti-spam do [LEARN]) tratou outra fonte, nao esta.

### Mudanca (Core/ValidationEngine.mqh) - v1.2.16
- Novo ValidationLogAllowed(symbol, reason): tabela de 64 slots
  (simbolo+motivo -> ultimo timestamp), janela de 300 s de tempo do servidor
  (no tester = tempo simulado) e despejo FIFO quando a tabela enche.
- Os 20 Print de ValidateTrade passaram a ser guardados: EMPTY SYMBOL,
  SIGNAL 0, INVALID PRICE, SPREAD INFO, SPREAD, AVOID HOUR, SESSION,
  TREND BUY, TREND SELL, ADX INFO, ADX SKIP, ADX BLOCK, VOLATILITY,
  REGIME OK, AI, AI OK, MTF, NEWS, NEWS OK, APPROVED.
- Nenhuma decisao mudou: os guards cercam apenas o Print; todos os
  return false/true originais foram preservados.
- Efeito esperado no tester: de 2 a 4 linhas por tick para no maximo 1 linha
  por simbolo+motivo a cada 5 min simulados. Em live (13 graficos) o
  diagnostico continua visivel, na mesma ordem de grandeza do
  AllowBlockPrint (60 s).

### Validacao
- Compilacao: 0 errors, 0 warnings (14864 ms, X64 Regular, build 6292).
- ex5: 554648 bytes (era 550896), recompilado as 21:17.
- Backup do arquivo antes da edicao:
  Files/Backup/ValidationEngine.mqh.bak_v1215 (8037 bytes).
- Backtest 20-29/10: AINDA bloqueado. O job antigo continua rodando e
  tester_stop recusa qualquer run_id ("requested run_id does not match the
  active tester job"); tester_list_result_windows segue vazio. Precisa de
  Stop manual na aba Testador de Estrategia.

### Pendente / proximo
- Depois do Stop manual: apagar/rotacionar Tester\logs\20261029.log (1,16 GB),
  rodar xai_v1300_c5.ini + xai_v1300_c5.set e comparar com o baseline
  303 trades / PF 0.8961 / -30.95 / DD 1.68%.
- Reattach/recompilar nos 13 graficos para v1.2.15 + v1.2.16 valerem em live.
- Investigar "[LEARN] historico verificado | saidas=99 | deste_EA=0 |
  manuais=0".

## Ciclo 2026-10-29 (7) - "alvo curto": causa medida e corrigida

### Instrumento novo: MQL5\Scripts\XAI_TargetProbe.mq5
Sonda de diagnostico (NAO negocia). Para cada posicao do magic, reconstroi
R = distancia do stop ORIGINAL (maior SL visto nas ordens da posicao, porque
BreakEven so aperta o stop) e simula, vela M1 a vela M1, o resultado de
alvos em 0,50/0,60/0,80/1,00/1,25/1,50/2,00 R. Saida:
Files\Data\XAI_targets_probe.csv (uma linha por posicao com mfe_R e mae_R).

### O que a sonda mostrou (30 posicoes reais do EA, 12 h a frente)
- O TP NAO era curto: em todas as linhas o TP estava a ~1,0 R da entrada.
- O preco andava a favor 0,5 a 1,2 R (mfe_R: 0,547 / 0,890 / 1,214 / 1,168 /
  1,063 / 0,570 ...) com mae_R quase sempre abaixo de 0,3 R.
- Mesmo assim o resultado realizado ficava entre 0,03 e 0,37 R
  (realizado_R: 0,099 / 0,368 / 0,154 / 0,245 / 0,036 / 0,014).
- Causa: em Management\BreakEven.mqh o gatilho era max(BreakEvenTrigger,
  1 ATR) mas a trava era `entrada + BreakEvenOffset (10 PONTOS)`. Ou seja:
  o trade andava ~0,6 R, o stop ia para +0,1 R e o primeiro respiro fechava
  tudo em ~0,1 R. Era isso que aparecia como avgWin +0,555 x avgLoss -1,313
  (payoff 0,476) no ai_feedback.csv - nao o tamanho do alvo.

### Mudanca (v1.2.16)
- Core\Config.mqh: novos inputs BreakEvenInR=true, BreakEvenTriggerR=0,60,
  BreakEvenLockR=0,30.
- Management\BreakEven.mqh: rDist = |TP - entrada| (a sonda mostrou TP ~ 1 R,
  entao serve de escala do trade) com fallback para ATR. O gatilho passa a ser
  max(atual, 0,60 R) e a trava max(offset, 0,30 R).
- Efeito: a trava deixa de ser um numero fixo de pontos e passa a ser fracao
  do risco da propria operacao. Quem sai no break even sai com ~0,30 R em vez
  de ~0,10 R, sem mudar a taxa de acerto (continua saindo no positivo).
- Nada mais foi alterado: TP, parcial em 1 ATR, trailing 1,2 ATR e risco
  seguem iguais. BreakEvenInR=false reproduz o comportamento antigo.

### Validacao
- Compilacao: 0 errors, 0 warnings (14805 ms, X64 Regular, build 6292).
- XAI_TargetProbe.mq5: 0 errors, 0 warnings (1049 ms).
- BreakEven.mqh e Config.mqh normalizados em CRLF (loneLF=0, sem BOM).
- Backtest: ainda bloqueado pelo job antigo no Strategy Tester (ver ciclo 6).

### Pendente / proximo
- Repetir a sonda depois de algumas horas de operacao com v1.2.16 e comparar
  realizado_R com mfe_R: a distancia entre os dois deve encolher.
- Reavaliar o TP (>1 R) SO com backtest limpo, porque a sonda tem amostra
  pequena e assume stop antes do alvo dentro da mesma vela.
- Corrigir a contaminacao da sonda: posicoes cujo unico SL registrado e o de
  break even aparecem com R minusculo (5 de 30 linhas) e devem ser filtradas
  por R/preco < 0,02%.

## Ciclo 2026-10-29 (8) - sonda v2 e A/B da politica de saida

### Sonda v2 (MQL5\Scripts\XAI_TargetProbe.mq5)
- Filtro de contaminacao: posicao cujo unico SL registrado e o de break even
  aparece com R minusculo. Descartado agora R/preco < 0,02% (InpMinRelR).
  Nesta amostra: 4 sem stop, 5 contaminadas, 25 validas.
- Grid de alvos fixos ampliado para 0,30/0,40/0,50/0,60/0,80/1,00/1,25/1,50/2,00.
- Novo bloco A/B: simula a POLITICA DE SAIDA (trava em LockR depois de
  TriggerR, alvo em TpR) sobre as mesmas operacoes e compara com o realizado.

### Resultado do A/B (25 operacoes reais, horizonte de 12 h)
| politica | total R | media R |
|---|---|---|
| ANTIGA (realizado) | -0,80 | -0,032 |
| NOVA (trava 0,30 R apos 0,60 R, alvo 1,00 R) | +2,28 | +0,091 |

Desfecho da NOVA: 4 alvos, 3 stops, 1 trava, 17 ainda abertas no fim do
horizonte (marcadas a mercado). Ganho de +3,08 R na mesma amostra
(+0,123 R por operacao). Direcao da correcao do ciclo 7 confirmada; a
magnitude e modesta porque a maioria nao resolveu no horizonte.

### Grid de alvos fixos (referencia, mesma amostra)
| K (R) | SL | TP | aberto | total R |
|---|---|---|---|---|
| 0,30 | 3 | 15 | 7 | -0,08 |
| 0,60 | 3 | 7 | 15 | +1,79 |
| 1,00 | 3 | 5 | 17 | +2,98 |
| 1,50 | 3 | 2 | 20 | +3,67 |
| 2,00 | 3 | 2 | 20 | +4,67 |

### Leitura honesta (o que NAO da para concluir)
- O grid sugere alvo mais largo que 1,0 R, mas 17 de 25 posicoes nao
  resolveram no horizonte e entram no total pelo preco da ultima vela. O
  total cresce com K por causa desse MTM, nao por alvos realmente atingidos.
  3 stops em 25 operacoes contam uma historia que o ai_feedback (402
  resultados, avgLoss -1,31) nao confirma.
- Amostra pequena e MTM-dependente: NAO justifica mexer no TP ainda.
  Ampliar alvo continua dependendo do backtest limpo.
- A mudanca do ciclo 7 (BreakEvenInR) e a que tem base solida: o realizado
  real estava entre 0,03 e 0,37 R com MFE de 0,5 a 1,2 R.

### Validacao
- XAI_TargetProbe.mq5: 0 errors, 0 warnings (1074 ms, X64 Regular).
- CSV: Files\Data\XAI_targets_probe.csv (25 linhas + 3 blocos de resumo).
- Backtest: ainda bloqueado (job antigo no Strategy Tester, log em 1,23 GB).

### Pendente / proximo
- Repetir a sonda depois de horas com v1.2.16 e comparar realizado_R x mfe_R.
- Decidir o TP (>1 R) so com backtest limpo.
- Investigar "[LEARN] historico verificado | saidas=99 | deste_EA=0 |
  manuais=0": o modulo de aprendizado nao esta atribuindo nenhuma saida ao
  EA nem as operacoes manuais, ou seja, aprende so com o que registra em
  tempo real.
---

## v1.2.19 - Resumo para o operador (`[RESUMO]`) - 29/10/2026

### Pedido
"Quero entender o que o EA esta fazendo" sem abrir mao de "tudo automatico".

### O que mudou
- `Monitoring/OperatorBrief.mqh` (novo): modulo SOMENTE LEITURA. Nao decide,
  nao envia ordem, nao altera SL/TP. A cada `OperatorBriefSeconds` imprime:
  - 1 linha de estado: master/standby, posicoes do EA (com flutuante) e
    manuais, dia FECHADO contra a meta efetiva, flutuante da conta, trades,
    IA e configuracao da escada;
  - 1 linha por posicao do EA: degrau da escada (SEM STOP / STOP na entrada /
    TRAVADO), stop atual e alvo convertido em USD.
- `Core/Config.mqh`: novos inputs `EnableOperatorBrief = true` e
  `OperatorBriefSeconds = 300`.
- `XAU_AI_PRO.mq5`: `#include "Monitoring/OperatorBrief.mqh"` e chamada
  `OperatorBriefTick(TradesToday)` no `OnTick`, dentro de `if(PipelineIsMaster())`,
  logo apos `ManagePositions()` - so a instancia mestre resume, uma vez por
  intervalo.
- A meta do dia no resumo vem de `DailyTargetEffectiveUsd()`, a MESMA fonte que
  o `ExecutionEngine` (freio de entradas) e o `PositionManager` (trava das
  posicoes) consomem. Nao existe segunda formula.
- O "dia" do resumo usa `LucroRealizadoHojeUSD()` (deals FECHADOS), nao
  `ACCOUNT_PROFIT`: e o numero que a meta realmente consome.

### Verificado ao vivo (21:42:29)
`[RESUMO] master=SIM | posicoes: 0 EA (+0.00 USD) + 0 manual | dia fechado: +0.00 de 100.00 USD (0%) | flutuante conta: +0.00 | trades=0 | IA=SEM PRECO | escada=ON arma 10.00 / trava 5.00 em 15.00 / alvo 20.00 USD`

### Achado (decisao pendente do dono)
A meta efetiva hoje e **100 USD**, nao 20: `EnableDailyTargetBalancePct=true`
com 10% de uma banca de ~12.346 USD da ~1.234 USD, cortado pelo teto
`DailyProfitTargetMaxUsd=100`. Para a meta de 20 USD valer de fato:
`DailyProfitTargetBalancePct=0` (desliga o piso por percentual) ou
`DailyProfitTargetMaxUsd=20`.

### Nota tecnica
A global `DailyProfit` do `XAU_AI_PRO.mq5` e alimentada por
`AccountInfoDouble(ACCOUNT_PROFIT)`, que e lucro FLUTUANTE da conta (zera
quando a posicao fecha). Ela serve ao dashboard e ao relatorio diario, nao a
meta. A meta sempre le `LucroRealizadoHojeUSD()`. Renomear/ajustar essa global
fica para o proximo ciclo.

### Compilacao
0 erros, 0 warnings (build 6292, x64). Os 16 graficos recarregaram o `.ex5`
automaticamente e ja exibem `EnableOperatorBrief=true`.
## v1.2.20 - Log que diz a verdade (diagnostico) - 29/10/2026

Duas correcoes de DIAGNOSTICO. Nenhuma regra de entrada, lote, stop ou alvo
mudou: o EA continua operando exatamente como antes. O que muda e que o
journal passou a explicar o que esta acontecendo.

### 1. `[LEARN]` parou de mentir sobre o historico

Antes:

    [LEARN] historico verificado | janela=180d | saidas=102 | deste_EA=0 | novos=0 | manuais=0 | doEA=0 | empates=0

Agora:

    [LEARN] historico verificado | janela=180d | saidas=102 | deste_EA=78 | manuais=24 | outros_EA=0 | ja_aprendidos=102 | novos=0 | novos_EA=0 | novos_manual=0 | empates=0

Leitura correta: **78 saidas do EA + 24 saidas manuais = 102**, e
**ja_aprendidos=102**, isto e, o aprendizado ja tinha absorvido TODO o
historico. O "0" anterior nao era falha de aprendizado: o contador `deste_EA`
media apenas o que passava do cursor `LearningLastDeal` (somente deals NOVOS),
entao um historico ja aprendido sempre reportava zero.

Correcao em `AI/LearningHistory.mqh` (`AILearningImportHistory`): a
classificacao (manual / deste EA / outro EA) passou a ser feita ANTES do
cursor, e `ja_aprendidos` conta o que o cursor pulou. O resumo agora separa
"existe no historico" de "entrou novo neste ciclo" (`novos`, `novos_EA`,
`novos_manual`).

### 2. `[SCANNER] BLOCK | AllowTrade` passou a dizer QUAL gate barrou

Antes:

    [SCANNER] BLOCK | AllowTrade (Validation/Score/IA) | EURUSD | Signal=-1

Agora:

    [SCANNER] BLOCK | AllowTrade | EURUSD | Signal=-1 | Motivo=VALIDATION: TREND SELL

Implementacao:
- `Core/DecisionEngine.mqh`: nova `AllowTradeEx(signal, symbol, &reason)`.
  A `AllowTrade()` original continua existindo como wrapper (nada quebrou) e o
  motivo fica em `g_allowBlockReason`.
- `Core/ValidationEngine.mqh`: `g_validationLastBlock`, alimentado dentro de
  `ValidationLogAllowed()` com o motivo exato de cada veto. Motivos
  informativos ("SPREAD INFO", "AI OK", "REGIME OK", "APPROVED", "ADX SKIP")
  nao sobrescrevem o motivo real do bloqueio.
- `Core/MarketScanner.mqh`: chama `AllowTradeEx` e imprime `Motivo=`.

### 3. Primeiro diagnostico real medido (21:55, apos reload dos 16 graficos)

    [SCANNER] BLOCK | AllowTrade | EURUSD | Signal=-1 | Motivo=VALIDATION: TREND SELL
    [SCANNER] BLOCK | AllowTrade | USDCHF | Signal=1  | Motivo=VALIDATION: TREND BUY

Quem barra as duas unicas entradas que aparecem e o **TrendFilter** (sinal
contra a tendencia), nao o score minimo nem o veto da IA. Os demais simbolos
continuam em `No Signal`. Isso responde a pergunta antiga "por que o EA nao
abre nada": nao era um bloqueio global misterioso, sao sinais contra a
tendencia em EURUSD/USDCHF e ausencia de sinal no resto.

### Validacao
- Compilacao: 0 errors, 0 warnings (MetaEditor build 6292 x64).
- 16 graficos recarregaram o .ex5 as 21:55:02-04 e imprimiram o novo formato
  imediatamente, sem reanexar nada e sem perder as configuracoes por grafico.

## v1.2.21 - Cenario global: adaptar em vez de vetar - 29/10/2026

### 1. O diagnostico que abriu esta versao

O journal das 21:55 (v1.2.20) respondeu "por que o EA nao abre nada": as duas
unicas entradas do dia foram mortas pelo `TrendFilter` -

```
[SCANNER] BLOCK | AllowTrade | EURUSD | Signal=-1 | Motivo=VALIDATION: TREND SELL
[SCANNER] BLOCK | AllowTrade | USDCHF | Signal=1  | Motivo=VALIDATION: TREND BUY
```

Ou seja: o unico criterio que decidia entrada era BINARIO (preco acima ou
abaixo da EMA200 H1). Num mercado sem tendencia isso veta os dois lados.

### 2. `Filters/MarketScenario.mqh` (novo)

Classifica o cenario com duas medidas que ja existiam e que sao COMPARAVEIS
entre classes de ativo:

- **ADX** = forca da tendencia;
- **ATR em % do preco** = volatilidade. Nunca pontos crus: 50 pontos valem
  $5,00 no BTCUSD e $0,0005 no EURUSD (o mesmo erro que ja custou o filtro de
  spread em 08/10/2026).

```
SCENARIO_TREND_STRONG  ADX >= ScenarioADXStrong (25)
SCENARIO_TREND_WEAK    ADX >= ScenarioADXWeak   (18)
SCENARIO_RANGING       ADX <  ScenarioADXWeak
SCENARIO_VOLATILE      ATR% >= ScenarioVolPctMax (2.00)
SCENARIO_UNKNOWN       sem leitura
```

A camada adapta tres coisas em vez de vetar:

| Item | Como o cenario age |
|---|---|
| Gate de tendencia | contramao em LATERAL passa, com lote menor; contramao com tendencia formada continua vetada |
| Lote | TENDENCIA_FORTE x1.00, FRACA x0.90, LATERAL x0.75, VOLATIL x0.60 |
| Alvo | VOLATIL x1.15 (disparada percorre mais), LATERAL x0.90 (preco volta) |

`ScenarioTrendGate()` substitui o veto binario em `ValidationEngine.mqh` e
sempre escreve o motivo. Contramao liberada gera
`[VALIDATION] TREND CONTRA OK`.

### 3. Correcao medida no proprio journal (ADX = 0)

As 22:14 o simbolo do grafico mestre saiu como `LATERAL | ADX=0.0`. O handle
do ADX ainda estava aquecendo e a leitura anterior (`adx < 0.0`) tratava 0.0
como LATERAL - "sem dado" virava permissao de contra-tendencia. Trocado para
`adx <= 0.0` -> `SCENARIO_UNKNOWN`. MEDIDO as 22:15: `USDJPY | SEM_LEITURA`.

### 4. Regra de ouro da camada

Nenhum fator de cenario passa de 1.0. A escala para cima continua sendo
exclusividade do lote dinamico por conviccao: duas fontes somando para cima
multiplicariam risco sem medir.

### Validacao

- Compilacao: 0 errors, 0 warnings (MetaEditor build 6292 x64).
- Journal ao vivo: `XAUUSD TENDENCIA_FORTE ADX=29.4 ATR%=0.36 lote x1.00`;
  `USDCHF TENDENCIA_FORTE ADX=50.6`; `USDCAD LATERAL ADX=16.1 lote x0.75`.

## v1.2.22 - Cenario global multi-ativo: correlacao, classe e sessao GMT - 29/10/2026

A v1.2.21 respondeu "que TIPO de mercado e este". Faltavam as duas perguntas
que so existem quando o EA roda em MUITOS ativos ao mesmo tempo - 16 graficos.

### 1. Falha medida: correlacao nao existia no projeto

Dos 16 graficos, quase todos sao pares contra o dolar. `MaxOpenPositions=50`
e teto de CONTAGEM, nao de risco:

- `EnableManualExposureGuard` protege apenas o MESMO simbolo com posicao MANUAL;
- `CPortfolioManager` mede exposicao TOTAL, nao exposicao POR MOEDA;
- nada impedia comprar dolar em USDJPY, USDCHF, USDCAD, USDCNH e USDSEK ao
  mesmo tempo.

Isso nao sao 5 operacoes: e UMA aposta no dolar com 5x o tamanho. Quando o
dolar vira, as cinco perdem juntas e o limite de perda diaria e atingido por
um unico movimento.

### 2. `Filters/GlobalScenario.mqh` (novo)

**Classe de ativo** - `AssetClassOf()` le `SYMBOL_CURRENCY_BASE` e
`SYMBOL_CURRENCY_PROFIT` da ficha (nunca o nome, que tem sufixo de broker):
METAL, MAJOR, MINOR, EXOTICO, INDICE, CRIPTO.

**Sessao em GMT** - `SessionBucketNow()` usa `TimeGMT()`, nao a hora do
servidor. `TradeStartHour..TradeEndHour` e `AvoidHoursList="0,20"` foram
calibrados em 402 trades de XAUUSD e mudam de significado com o horario de
verao do broker. Buckets: ASIA 00-07, LONDRES 07-12, NOVA_IORQUE 12-21,
POS_NY 21-24.

**Lote por sessao** (nunca acima de 1.0, piso `SessionLotFloor`):

| Sessao | Fator |
|---|---|
| LONDRES | 1.00 |
| NOVA_IORQUE | 1.00 |
| ASIA | 0.85 |
| POS_NY | 0.70 |
| FECHADO | 0.50 |
| exotico/minor em Asia ou pos-NY | x0.75 adicional |

**Guarda de correlacao** - `CurrencyExposureGuard()` testa as DUAS pernas do
simbolo proposto e veta quando a entrada aumentaria a exposicao numa moeda ja
carregada no mesmo sentido. Dois tetos, porque sao dois erros:

- `MaxCorrelatedTrades = 3` (contagem: 5 pares iguais);
- `MaxCorrelatedRiskPercent = 3.0%` (dinheiro: balance x 3% = 370 USD hoje).

O vetor e de CORRELACAO, nao de direcao: comprar EURUSD e comprar GBPUSD somam
em USD CURTO; comprar USDJPY e o oposto e nao soma. Posicao sem stop continua
ocupando o envelope e e medida pelo risco nominal - sem isso toda entrada
stopless somaria zero e o teto nunca encheria.

### 3. Correcao medida as 22:23 (rotulo de classe)

A primeira versao classificou USDSEK, USDCNH e USDBRL como MAJOR so porque a
perna base era `usd`. Sao EXOTICOS: a liquidez quem define e a OUTRA moeda. O
rotulo errado desligava a reducao de lote fora das sessoes liquidas.

```
antes:  [GLOBAL] USDBRL | classe=MAJOR   | sessao=ASIA | lote x0.85
depois: [GLOBAL] USDBRL | classe=EXOTICO | sessao=ASIA | lote x0.64
```

### 4. Journal deixou de repetir (v1.2.22 no `ScenarioLog`)

MEDIDO: a mesma linha de XAUUSD saiu identica as 22:14, 22:15 e 22:16. O
throttle era so de tempo (60s), entao cenario que nao mudou ocupava o journal
de minuto em minuto. Agora a linha sai quando a assinatura MUDA (cenario +
regime + fatores, exatamente o que decide lote e alvo) e ha heartbeat de 15
min com a marca `heartbeat`.

### 5. Onde cada gate entra

```
AllowTradeEx (DecisionEngine)
  1. ValidateTrade         -> TrendFilter/ScenarioTrendGate, spread, sessao, noticia
  2. NewsTradeAllow
  3. CurrencyExposureGuard  <- NOVO v1.2.22 (gate de carteira, antes do score)
  4. CalculateMarketScore
  5. FinalAIAllow
```

Antes do score porque e gate de CARTEIRA: nao adianta nota alta se a entrada
seria a quinta aposta no mesmo lado do dolar.

### Validacao

- Compilacao: 0 errors, 0 warnings (MetaEditor build 6292 x64), 2 builds.
- Journal ao vivo as 22:21-22:23 (11 simbolos): classe, sessao, lote e
  exposicao por moeda corretos; `exp` = 0.00 porque nao havia posicao aberta.
- Nenhuma ordem foi enviada, modificada ou cancelada.

## v1.2.23 - Horas proibidas em GMT (nao em hora de servidor) - 29/10/2026

### 1. O defeito medido

`AvoidHoursList = "0,20"` era lida com `TimeToStruct(TimeCurrent(), tm)` em
`Filters/SessionFilter.mqh`. `TimeCurrent()` e hora do SERVIDOR. Medido neste
terminal no dia 29/10: `TimeGMT()` = 01:23 com servidor = 03:23, ou seja o
servidor esta em **GMT+2**.

Consequencia: a lista que "queria" banir 00h e 20h bania de fato **GMT 22h**
(fecho de Nova Iorque - correto) e **GMT 18h** (MEIO da sessao de Nova
Iorque - errado para majors). Pior: quando o broker entra em horario de verao
(GMT+3), a MESMA lista passa a banir GMT 21h e GMT 17h. A regra derivava
sozinha duas vezes por ano, sem ninguem tocar em nada.

### 2. O que mudou

`Filters/GlobalScenario.mqh` ganhou cinco funcoes:

- `GmtHourNow()` - hora em GMT, independente do fuso do servidor;
- `HourInCsvList(hour, list)` - parser de "18,22";
- `HourInClassListGmt(classe, hour)` - parser de "METAL:22,23;EXOTICO:21,22,23";
- `IsAvoidedHourGlobal(symbol)` - decisao final;
- `AvoidedHourDetail(symbol)` - texto do log ("GMT=18h | lista=18,22").

`Core/Config.mqh` ganhou, logo apos `AvoidHoursList`:

```
input bool   EnableAvoidHoursGMT = true;
input string AvoidHoursGMT       = "18,22";
input string AvoidHoursByClass   = "";      // "METAL:22,23;EXOTICO:21,22,23"
```

`Core/ValidationEngine.mqh` trocou `IsAvoidedHour()` por
`IsAvoidedHourGlobal(symbol)` e o log passou a mostrar `AvoidedHourDetail`.

### 3. Decisoes de projeto

- O padrao `"18,22"` e o **equivalente congelado** do que a lista antiga fazia
  hoje com GMT+2. Nada muda no dia da atualizacao; o ganho e ela parar de
  derivar em marco e outubro.
- `AvoidHoursByClass` padrao **vazio** de proposito: nenhuma regra nova e
  inventada sem evidencia. O formato existe porque a pergunta certa e "que
  horas sao ruins PARA ESTE TIPO DE ATIVO", nao uma hora universal.
- `EnableAvoidHoursGMT = false` volta ao comportamento antigo (hora de
  servidor) sem apagar nada - o dono reverte em um clique.
- `SessionFilter.mqh` continua intacto como caminho legado.

### 4. Validacao

Journal entre 22:30 e 00:10: **zero** registros `AVOID HOUR`, correto (GMT era
01h, fora de 18/22). Compilacao 0 errors / 0 warnings.

---

## v1.2.24 - SAFE MODE por broker com histerese - 29/10/2026

### 1. O defeito medido

Journal do grafico USDJPY, 22:29:27.376:

```
[CIRCUIT] SAFE MODE activated: Broker connection or trading disabled | Trigger #1
```

e, imediatamente depois, no MESMO journal:

```
Status: HEALTHY | Uptime (s): 195 | Checks: 3 | Broker errors: 0
```

O robo se declarou doente e saudavel no mesmo segundo. A causa esta em
`Enterprise/CircuitBreaker.mqh`:

```cpp
bool CCircuitBreaker::CheckBrokerError()
{
   bool connected    = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
   bool tradeAllowed = (AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) != 0);
   if(!connected || !tradeAllowed) return true;   // UMA leitura = gatilho
   return false;
}
```

**Uma unica leitura** ruim bastava. No start (recarga do `.ex5`, reconexao do
servidor, warm-up do simbolo) `TERMINAL_CONNECTED` pode estar em 0 por um ou
dois tiques. E `ForceSafeMode` nao e local: ele parava o EA **inteiro**,
gravava `XAI_PRO_CB_SAFE_UNTIL` em `GlobalVariable` por 300 s e esse bloqueio
**sobrevivia a reinicios**. Um piscar de conexao custava 5 minutos de cegueira
em 16 graficos.

### 2. O que mudou

Tres inputs novos em `Enterprise/CircuitBreaker.mqh`:

```
input int CircuitBrokerFailMinCheck   = 3;    // leituras seguidas com falha
input int CircuitBrokerFailMinSeconds = 15;   // persistencia minima (s)
input int CircuitWarmupSeconds        = 30;   // carencia apos OnInit (s)
```

A falha so e aceita como real quando **persiste por N leituras E por S
segundos**, e nunca durante a carencia de start. Enquanto nao confirma, loga
`[CIRCUIT] BROKER INSTAVEL | leituras=.. | ..s | histerese | aguardando
confirmacao (nao bloqueia)` e **segue operando**.

Quando reconecta antes do gatilho, loga
`[CIRCUIT] BROKER OK | falha transitoria descartada: N leituras / Ss` e zera o
contador - o episodio nao deixa rastro bloqueante.

Quando confirma, loga `[CIRCUIT] BROKER CONFIRMADO INDISPONIVEL | leituras=..
| ..s | conectado=.. | trade_allowed=..` antes de entrar em SAFE_MODE.

### 3. A persistencia deixou de ser armadilha

`ForceSafeMode` agora grava tambem `XAI_PRO_CB_SAFE_BROKER = 1` quando o
motivo contem "broker". No `Init`, se o `SAFE_UNTIL` persistido for de broker
**e** o broker estiver conectado e liberado no momento do start, o bloqueio e
descartado:

```
[CIRCUIT] SAFE_MODE de broker descartado no start (broker conectado e liberado)
```

O bloqueio persistido continua valendo para drawdown, anomalia de mercado e
acionamento manual - esses nao desaparecem sozinhos.

### 4. Reversao

`CircuitBrokerFailMinCheck = 0` **e** `CircuitBrokerFailMinSeconds = 0`
restauram o gatilho imediato antigo. A carencia continua valendo (zerar
`CircuitWarmupSeconds` tambem a remove).

### 5. O que NAO foi mexido

O limite de drawdown, o limite de spread (10x o `MaxSpreadPct`), o escopo por
simbolo da anomalia de mercado (`CircuitAbnormalMarketBlocksAll = false`) e o
cooldown de 300 s continuam exatamente como estavam. A mudanca e somente sobre
a VELOCIDADE de aceitar a falha de broker.

### 6. Validacao

Compilacao `XAU_AI_PRO.mq5`: **0 errors, 0 warnings** (100568 ms, MetaEditor
build 6292 x64). Arquivo normalizado: CRLF puro, BOM preservado, 36515 bytes.
Os graficos continuam rodando o `.ex5` anterior ate serem reanexados - a
correcao vale a partir do proximo anexo do EA.

## v1.2.25 - Trava de custo: spread + comissao medidos contra o ALVO - 29/10/2026

### 1. A pesquisa (indice publico MQL5, artigos em portugues, 29/10/2026)

Consultas feitas na API publica de busca do MQL5 (`search.mql5.com/api/query`,
`hl=pt`, modulos `articles`/`codebase`/`forum`). Metodo: palavra-chave curta
(consultas longas em portugues retornaram 0 resultados - o indice casa termo a
termo).

Fontes encontradas e o que cada uma ensinou:

- **"Gerenciador de riscos para trading algoritmico"** - artigo 14634
  (Aleksandr Seredin). https://www.mql5.com/pt/articles/14634
  Conteudo: normalizacao de risco, interface para stop curto, **controle de
  slippage em ordens abertas** e **controle de spread na abertura de
  posicoes**. E a referencia que fechou o diagnostico desta versao: o custo de
  entrada deve ser medido CONTRA o resultado esperado, nao apenas contra um
  teto absoluto.
- **"Algoritmos avancados de execucao de ordens em MQL5: TWAP, VWAP e ordens
  Iceberg"** - artigo 17934. https://www.mql5.com/pt/articles/17934
  Relevante para volume grande; o projeto opera lote pequeno multiativo, entao
  fatiamento de ordem nao se aplica agora.
- **"Swaps (Parte I)"** - artigo 9198. https://www.mql5.com/pt/articles/9198
  Confirma que swap e custo de POSICAO, nao de entrada - fora do escopo deste
  gate.
- **"Desenvolvendo uma Estrategia de Pullback: Validacao"** - artigo 23508.
  https://www.mql5.com/pt/articles/23508
  Metodologia de robustez (o que sobrevive fora da amostra). Reforca a regra de
  ouro do projeto: nada de numero novo sem medicao.
- **"Superando as limitacoes do aprendizado de maquina (Parte 1)"** - artigo
  17906. https://www.mql5.com/pt/articles/17906
  Alerta sobre confiar em metricas isoladas. Reforca: backtest unico nao prova
  nada.

Codigo de terceiros NAO foi copiado. MQL5 CodeBase e Market tem licencas
distintas (parte e gratuita, parte e produto pago); copiar arquivo alheio para
dentro do `XAU_AI_PRO` misturaria licencas e estilo. O que foi aproveitado e a
IDEIA, reescrita no padrao do projeto (funcoes pequenas, variaveis locais, log
`[COST]` throttle, matematica por tick size/tick value).

### 2. O buraco medido no projeto

`Core/Config.mqh` ja tinha `MaxSpreadPct = 0.6` - spread limitado como
PORCENTAGEM DO PRECO. Isso barra spread absurdo e mais nada. A pergunta
economica ficava sem resposta: **quanto do alvo o custo vai comer?**

Nenhuma linha do projeto comparava custo com alvo. Grep por
`ACCOUNT_COMMISSION`, `swap` e `tick_value` mostrou que comissao so aparece em
historico (`LearningHistory`, `Config` ao somar lucro realizado) - nunca na
decisao de entrada.

O caso concreto: alvo tipico desta conta e `LadderTpUsd = 20` USD. Num exotico
com spread de 300 pontos e lote 1.0, o custo de ida e volta chega a varios
dolares - mais de 20% do alvo. A operacao precisa acertar mais que o normal so
para empatar, e `MaxSpreadPct` aprovava esse caso sem reclamar.

### 3. `Filters/CostGate.mqh` (novo)

Funcoes:

- `CostSpreadPoints(symbol)` - (ask-bid)/point, devolve 0 quando nao ha leitura;
- `CostPointsToUsd(symbol, volume, points)` - pontos -> dolares, passando por
  preco antes do tick (`point` != `tick_size` em varios brokers);
- `CostUsdToPoints(...)` - inverso, para dizer o alvo minimo;
- `CostUsdOfTrade(symbol, volume)` - spread em dolares + comissao por lote;
- `CostMinViableTargetPoints(symbol, volume)` - alvo a partir do qual o custo
  ja cabe no limite;
- `CostGateCheck(symbol, volume, targetPoints, riskPoints, reason)` - decisao;
- `CostGateSummary(...)` - texto curto para diagnostico;
- `CostLogAllowed(...)` - throttle do `[COST]`.

Inputs novos em `Core/Config.mqh`:

```
input bool   EnableCostGate      = true;
input double MaxCostPctOfTarget  = 20.0;   // custo maximo como % do alvo
input double MaxCostPctOfRisk    = 40.0;   // custo maximo como % do risco
input double CommissionPerLotUsd = 0.0;    // comissao ida e volta por lote
input int    CostGateLogSec      = 300;    // throttle do log
```

### 4. Onde ele entra

`Core/ExecutionEngine.mqh`, dentro de `ExecuteTrade`, DEPOIS de lote, alvo e
risco de referencia estarem definidos e ANTES de qualquer envio:

```cpp
   if(!CostGateCheck(symbol, lot, tpPontos,
                     (slRefPontos > 0.0 ? slRefPontos : slPontos), motivoCusto))
   {
      Print("EXECUTION: CUSTO BLOQUEADO | ", symbol, " | ", motivoCusto);
      EventTradeRejected(symbol, motivoCusto, "COST_TOO_HIGH");
      return false;
   }
```

Posicao escolhida de proposito: `AllowTradeEx` (DecisionEngine) nao conhece
lote nem alvo - o custo so pode ser julgado quando os dois existem.

### 5. Decisoes de projeto

- **Sem leitura de spread nao bloqueia.** "Sem tick" e ausencia de dado, nao
  evidencia de custo alto; a ordem ja e barrada adiante por preco invalido.
  Diferente do caso do risco (`RISK_DISTANCE_UNKNOWN`), onde bloquear e
  necessario porque sem distancia nao ha como dimensionar risco real.
- **Dois limites, nao um.** `MaxCostPctOfTarget` e a regra economica
  principal; `MaxCostPctOfRisk` existe porque um alvo otimo com risco minusculo
  deixaria passar custo grande em relacao ao que se arrisca. Qualquer um zerado
  desliga aquela checagem.
- **Swap fora.** Swap e custo de carregar a posicao, nao de abrir; a escada em
  dolares fecha no mesmo dia na maioria dos casos.
- **Comissao = 0 por padrao.** Melhor um zero honesto do que uma estimativa
  inventada. Conta com comissao: preencher `CommissionPerLotUsd`.
- **Nao mexe em lote nem em alvo.** So aprova ou recusa, com o numero medido.
  Elevar alvo automaticamente mudaria a estrategia - isso so com backtest.

### 6. O que foi avaliado e NAO entrou

- TWAP/VWAP/Iceberg (artigo 17934): o projeto opera lote pequeno em 16 simbolos;
  fatiar ordem aumentaria comissao e complexidade sem ganho medido.
- Martingale/grid ("Sideways Martingale" apareceu na busca): risco nao linear,
  incompativel com `MaxDailyLossPercent` e com a escada em dolares.
- Redes neurais / ONNX: o projeto ja tem pipeline de IA e memoria de
  aprendizado; trocar o motor sem medicao seria mudar o produto, nao melhora-lo.

### 7. Validacao

Compilacao `XAU_AI_PRO.mq5`: **0 errors, 0 warnings** (103593 ms, MetaEditor
build 6292 x64). `CostGate.mqh` 11946 bytes, `Config.mqh` 64135 bytes,
`ExecutionEngine.mqh` 34399 bytes - todos CRLF puro, `loneLF=0`, UTF-8 sem BOM
(padrao dos modulos recentes do projeto).

Vale a partir do proximo anexo do EA. Novos logs a observar:
`[COST] OK | ... | custo=X US$ = Y% do alvo`,
`[COST] BLOQUEADO | ... | alvo minimo para pagar o custo: N pts`,
`EXECUTION: CUSTO BLOQUEADO | ...`.

Aviso: um gate novo sempre pode reduzir o numero de entradas. O efeito so deve
ser julgado em backtest comparado (mesmo periodo, mesmo .set), nunca por
impressao.
## Ciclo 2026-10-29 (9) - estudo, indice de documentacao e versao que nao mentia

Pedido do dono: "estudar bastante, aprender, melhorar o EA, salvar conversas,
documentar tudo, atualizar tudo, executar e deixar rodar".

Este ciclo e de **documentacao e rastreabilidade**. Nenhuma regra de entrada,
lote, stop, alvo ou risco foi alterada.

### 1. O que foi estudado (e o que foi descartado)

Continuacao da pesquisa iniciada na v1.2.25 pelo indice publico MQL5
(`hl=pt`, modulos `articles`/`codebase`). O material lido ja esta citado na
secao v1.2.25; a leitura nova nao mudou nenhuma decisao de codigo.

O que a leitura consolidou como **regra do projeto**:

- copiar arquivo de CodeBase/Market e proibido por licenca e por estilo: o
  projeto reescreve a IDEIA no proprio padrao;
- nenhum numero novo (alvo, lote, percentual) entra sem medicao previa;
- backtest unico nao prova lucratividade - serve para comparar duas versoes
  com a mesma janela e o mesmo modelo de ticks.

O que foi avaliado e continua **fora**:

- TWAP/VWAP/Iceberg (lote pequeno em 16 simbolos; fatiar aumenta comissao);
- Martingale/grid/averaging (risco nao linear, incompativel com
  `MaxDailyLossPercent` e com a escada em dolares);
- troca do motor de IA por ONNX/rede neural (mudaria o produto sem medicao).

### 2. Defeito de rastreabilidade medido

`Enterprise/VersionManager.mqh` tinha:

```mql5
#define EA_VERSION_STRING "1.2.23"
```

Enquanto o codigo em execucao ja era o de v1.2.24 + v1.2.25. Consequencia
concreta: o banner de `OnInit` (`XAU_AI_PRO.mq5` linha 847) imprime
`XAU_AI_PRO v<EA_VERSION_STRING>` no journal, e o `[VERSION]` do
`CVersionManager` usa a mesma macro. Ou seja, **o journal dizia uma versao
que nao era a que estava rodando** - exatamente o tipo de mentira de log que
os ciclos 6 e 7 deste mesmo dia foram corrigir.

Corrigido: `EA_VERSION_STRING "1.2.25"`.

Observacao: `#property version "1.290"` nao acompanha e nao deve acompanhar -
MQL5 aceita somente dois numeros na propriedade. Ela e o espelho "1.290" da
serie 1.2.x e ja esta documentada no cabecalho do `.mq5`.

### 3. `README.md` (novo) - o indice que faltava

Existiam 15 documentos `.md` na raiz do EA e **nenhum indice**. Quem abria a
pasta nao tinha como saber que `PROGRESS.md` e a fonte da verdade e que os
demais sao registros de etapa. Criado `README.md` (12525 bytes, CRLF puro,
sem BOM) com:

1. **Onde ler o que** - tabela de todos os 16 documentos e para que serve cada
   um, com a regra "decisao de risco so vale se estiver em `PROGRESS.md` com o
   numero medido";
2. **Mapa de modulos** - o que cada pasta faz e o papel de cada arquivo, nos
   grupos AI / Core / Filters / Management / Enterprise / Monitoring;
3. **Ordem real dos portoes** - a sequencia exata que explica "por que nao
   abriu" (Pipeline -> Scanner -> Decision -> Validation -> Execution) e onde
   cada motivo aparece no journal;
4. **Estado ao vivo medido** - conta, magic, 16 graficos, posicoes, resultado
   do dia, saude;
5. **Parametros que mexem em dinheiro** - tabela dos inputs de risco com a
   regra de que mudanca exige numero antes e depois;
6. **Como compilar e validar** - MetaEditor + `validate_mql5.py` + as
   convencoes que quebram o build (UTF-8, CRLF, `#include` case-sensitive);
7. **Pendencias abertas em ordem de valor** - WebRequest/token, meta efetiva
   do dia, backtest, `StoplessEmergencyPoints`, lote do USDCNH, sonda de
   alvos, candidatos v1.2.26;
8. **Aviso** - o EA executa ordens reais; backtest nao e promessa.

### 4. Cabecalho do `PROGRESS.md` atualizado

Estava `> Ultima atualizacao: 2026-09-07 (v1.2.0)` - tres meses e 25 versoes
atras. Agora aponta para 2026-10-29 (v1.2.25) e para o `README.md`.

### 5. Estado ao vivo confirmado as 22:57 (conta 113568614)

| Item | Medido |
|---|---|
| Graficos com o EA | 16, todos com o `.ex5` de v1.2.24/v1.2.25 (inputs novos visiveis) |
| Posicoes abertas | 0 |
| Resultado do dia | +16,38 USD realizados |
| Trades do dia | 3 de 100 |
| Recuperacao / saude | `RECOVERY_OK` / `HEALTHY`, uptime 150 s, 0 falhas em todos os canais |
| `[CIRCUIT]` | Somente `initialized` nos 16 graficos: **nenhuma** falha de broker desde a recarga |
| `[GLOBAL]` | Ativo e correto: `USDBRL classe=EXOTICO ... lote x0.64`, `XAUUSD classe=METAL ... x0.85` |
| `[COST]` | **0 linhas** - o EA nao tentou entrada desde a recarga |
| `[SCANNER]` | `BLOCK | No Signal` em todos os simbolos |

Leitura honesta: o robo esta ativo, saudavel e sem sinal. `[COST]` vazio e
consequencia de nao haver tentativa de entrada, **nao** e falha do gate novo.
A confirmacao do `CostGate` em producao depende da proxima tentativa real.

### 6. Validacao

- Compilacao: **0 erros, 0 avisos** (build 6292 x64, `no_optimization`).
- `README.md`: 12525 bytes, CRLF puro (`loneLF=0`), sem BOM.
- `VersionManager.mqh`: alteracao de 1 linha, sem efeito em comportamento.
- Nenhuma ordem foi enviada, modificada ou cancelada neste ciclo.

### 7. Pendente

- Ver no journal o banner `XAU_AI_PRO v1.2.25` apos o reload para fechar a
  rastreabilidade (antes imprimia v1.2.23).
- Primeira linha `[COST] OK` ou `[COST] BLOQUEADO` real, quando houver setup.
- Os itens 1 a 7 do `README.md` secao 7 continuam abertos - o primeiro
  (WebRequest + `AIGatewayToken`) e o unico que depende do dono para a IA
  deixar de rodar em fallback.
### 8. Fechamento medido (23:01) - fonte e binario voltaram a concordar

Trocar a constante so vale depois de recompilar E recarregar. Medido no journal:

| Momento | Versao que o binario em memoria reportava |
|---|---|
| 21:31 (reload anterior) | `[VERSION] v1.2.15` |
| 23:01:26 (ultimo log do binario antigo) | `[VERSION] v1.2.21` |
| 23:01:27 (apos o rebuild deste ciclo) | `[VERSION] v1.2.25` nos 16 graficos |

**Achado que justifica a correcao:** o `.ex5` estava **defasado da fonte**. As
21:31 o binario dizia `1.2.15` enquanto o codigo em disco ja era o de v1.2.23;
as 23:01 o binario antigo dizia `1.2.21`. Em ambos os casos o journal
reportava uma versao que nao correspondia ao codigo que estava sendo lido -
o mesmo tipo de "log que mente" dos ciclos 6 e 7.

Depois do rebuild, cada um dos 16 graficos imprime:

```
[VERSION] v1.2.25 | build 2026.10.30
        XAU_AI_PRO v1.2.25
[VERSION] v1.2.25 | Build=2026.10.30 | Stable=Yes | AutoUpdate=OFF | Modulos=15
```

Binario gerado: `XAU_AI_PRO.ex5`, 856.472 bytes, 29/10/2026 23:01.

**Regra que fica para o projeto:** antes de acreditar em qualquer numero do
journal, conferir a linha `[VERSION]`. Se a versao do journal nao for a que
esta no fonte, o binario carregado nao e o codigo que se esta lendo - e
qualquer conclusao tirada do log naquele intervalo e invalida.

Nenhuma ordem foi enviada, modificada ou cancelada neste fechamento. Os 16
graficos recarregaram com `AutoTrade=true`, `MagicNumber=2026001` e os inputs
de v1.2.24/v1.2.25 preservados.

---

# Ciclo 2026-10-30 (10) - registrar a madrugada e guardar as conversas

## 1. Pedido do dono

"salvar tudo conversas" - transformar em arquivo o que foi pedido, medido e
decidido em cada sessao, e deixar o estado ao vivo do `README.md` coerente com
o que o journal realmente mediu. Nada de codigo novo neste ciclo: so registro,
indice e correcao de documento.

## 2. A madrugada provou tres coisas (sem o agente tocar em ordem nenhuma)

Nenhuma ordem foi enviada, modificada ou cancelada por mim neste ciclo. As
ordens abaixo partiram do proprio EA, nos 16 graficos com `v1.2.25`.

### 2.1 `[COST]` saiu do papel

```
2026.10.30 03:47:09.741  XAU_AI_PRO (USDJPY,H1)
[COST] OK | EURUSD | custo=0.06 US$ = 0.6% do alvo | spread=2.0 pts | comissao=0.00 US$ | alvo=312 pts
```

Ate a recarga anterior este gate tinha **zero** linhas no journal - nunca
havia sido exercitado. Agora foi: aprovou (0,6% do alvo, teto 20%) e a ordem
foi enviada. Pendencia da sessao anterior: fechada.

### 2.2 Tres fechamentos, todos positivos

| Ticket | Simbolo | Lado | Lote | Aberto (server) | Fechado (server) | Resultado |
|---|---|---|---|---|---|---|
| 11166638047 | USDCNH | sell | 1,36 | 00:35:21 | 02:10:45 | +10,42 |
| 11166734584 | NZDUSD | sell | 0,20 | 00:51:10 | 02:29:47 | +4,20 |
| 11167109885 | AUDUSD | buy | 0,16 | 02:00:04 | 02:29:48 | +1,76 |
| - | - | - | - | - | **Total** | **+16,38 USD** |

`open_reason=Expert` e `close_reason=Client` em todos: abriu o robo, fechou a
escada em dolares (`MoneyLadder`), nao foi intervencao manual. O `+16,38` e
resultado, **nao** e estatistica nem prova de lucro. Tres trades nao dizem
nada sobre expectativa de 300+.

### 2.3 O falso `SAFE MODE` nao voltou

`[CIRCUIT]`: 48 linhas `CircuitBreaker initialized` (16 graficos x recargas) e
**zero** ocorrencias de `SAFE MODE` entre 21:30 e 05:25. A histerese da
`v1.2.24` (`CircuitBrokerFailMinCheck=3` leituras **e**
`CircuitBrokerFailMinSeconds=15` segundos, com carencia de 30 s no start)
resolveu o defeito que parava os 16 graficos por um piscar de conexao.

## 3. Estado medido as 05:25 (local) / 10:25 (server)

| Item | Valor |
|---|---|
| Balance / Equity | 12.348,57 / 12.342,60 USD |
| Flutuante | -5,97 USD |
| Margem / livre | 33,54 / 12.309,06 USD |
| Posicoes abertas | 1 - EURUSD `sell` 0,03 @ 1,11794 (ticket `11171034182`), TP 1,11127 |
| Conexao | `synchronized`, ping 214 ms, ultima perda 2026-10-30T01:29:14Z |
| Fuso | local = UTC+0, server = local+2 (GMT+2, inverno) |
| Graficos | 16, todos com `[VERSION] v1.2.25` |

## 4. `CONVERSAS.md` (novo) - o que o dono pediu, sessao por sessao

Criado na raiz do EA. Registro **append-only**, com tabela indice
(`# / quando / pedido / resultado`), uma secao por sessao e um aviso
permanente no fim (nenhuma promessa de lucro; numero no journal so vale se a
linha `[VERSION]` bater com o fonte).

Separacao de responsabilidade que fica valendo no projeto:

| Arquivo | Guarda |
|---|---|
| `CONVERSAS.md` | o **pedido** do dono e o desfecho de cada sessao |
| `PROGRESS.md` | o detalhe **tecnico** com numero medido (este arquivo) |
| `README.md` | o **indice** e o estado atual, para leitura rapida |

## 5. Defeito de encoding encontrado no `README.md` (corrigido)

O patch PowerShell que atualizou a secao 4 escreveu duas travessoes (em-dash)
duplo-codificadas: o UTF-8 `E2 80 94` foi lido como CP1252 (`a`, `EUR`, `"`),
virou tres caracteres e depois foi regravado em UTF-8 - mojibake visivel
(`a-EUR-"`). Linhas afetadas: "Posicoes abertas" e o paragrafo "Leitura
honesta".

Correcao aplicada por script ASCII-only (caracteres alvo via `\uXXXX`, sem
literal acentuado no `.ps1`, porque o PowerShell 5.1 le script sem BOM como
ANSI e transforma o proprio literal em lixo):

- 2 ocorrencias de mojibake trocadas por hifen simples (padrao do resto do doc);
- linha do `[COST]` trocada, porque ainda dizia "0 linhas - o EA ainda **nao
  tentou** entrada desde a recarga" quando o journal ja tinha um `[COST] OK`
  real;
- regravado em UTF-8 **sem BOM** e CRLF.

**Regra que fica para o projeto:** editar `.md` com acento via PowerShell exige
script ASCII-only com `\uXXXX` ou `replace_text_in_file` do MCP. Travessao
digitado direto no `.ps1` corrompe o arquivo.

## 6. Validacao

`README.md` final: 12.698 bytes, `loneLF=0`, `BOM=False`, `mojibake_restante=0`,
secao 4 relida linha a linha (144-166). `PROGRESS.md` e `CONVERSAS.md` no mesmo
padrao (UTF-8 sem BOM, CRLF puro). Nenhum `.mq5`/`.mqh` foi tocado neste ciclo,
portanto nao houve recompilacao: o binario em producao continua
`XAU_AI_PRO.ex5` de 29/10 23:01, 856.472 bytes, `v1.2.25`.

## 7. Pendente (ordem de valor)

1. WebRequest ainda desligado no terminal (erro 4014) e `AIGatewayToken` vazio
   nos 16 graficos - o portao de IA esta em modo degradado por configuracao.
2. Meta efetiva hoje e **100 USD** (`EnableDailyTargetBalancePct=true`,
   `DailyProfitTargetMaxUsd=100`), nao os 20 USD do `LadderTpUsd`: decidir com
   o dono.
3. Lote 1,36 em USDCNH fechou +10,42, mas o risco era desproporcional
   (`RiskPerTradePercent=0,5` x `DynLotFactorElite=4,0` x `ScenarioLotFactor` x
   `SessionLotFactor`). Ganhar com risco errado nao valida o risco.
4. Backtest 20-29/10 (o usuario precisa clicar Stop no Testador) para medir
   `CostGate`, gate adaptativo e `MaxCorrelatedTrades`.
5. `StoplessEmergencyPoints=0` - decidir um colchao com o dono.

Nenhuma promessa de lucro. O robo esta ligado e saudavel; o que sustenta
decisao e medicao, nao a sorte de uma madrugada.

---

# Ciclo 2026-10-30 (11) - P0.1 medido: backtest de 3 meses da v1.2.26

## 1. O que foi feito
Retomada a partir de PENDENCIAS_20261030.md. Item P0.1 corrido: XAUUSD M15
2026.07.29 a 2026.10.29, deposito 200 USD, 1:100, Model=1 (m1 ohlc), binario
XAU_AI_PRO.ex5 de 30/10 02:06 ([VERSION] v1.2.26).

Config: Profiles\Tester\XAI_V1226_3M_M1OHLC.ini, copiado do .ini de 00:44 e
corrigido para paridade com producao (MaxRiskPerTradeUsd=8.0 e
ForwardHeartbeatSec=300 nao existiam no original).

## 2. Resultado medido (log do agente, 15:43 UTC)

| Metrica | Valor |
|---|---|
| Final balance | 164,72 USD (deposito 200) |
| Lucro | -35,28 USD (-17,6%) |
| Profit Factor | 0,81 |
| Trades | 296 (297 execucoes, 0 rejeicoes) |
| Wins / Losses | 9 / 66 |
| Win Rate | 3,04% (analyzer) / 12,00% (quant matrix) |
| Max DD | 83,30 USD (171,33% no calculo interno - ver nota) |
| Sharpe | -0,55 |
| Recovery / Expectancy | -0,42 / -0,12 USD por trade |
| Tempo de teste | 41 min 03 s |

## 3. Leitura honesta
v1.2.26 perdeu US$ 35,28 em 92 dias nesta janela. O criterio do P0.1 era
comparar com a v1.2.23 (+14,76 / PF 2,17), mas a comparacao direta NAO e
valida: 92 dias x 9 dias, e 11 simbolos no pipeline x XAUUSD M15. O que se
pode afirmar: com esta configuracao e nesta janela o resultado e negativo.
O P0.2 manda bloquear a conta real se o resultado for negativo. Fica bloqueada.

Nota sobre o DD: 171,33% e artefato do calculo interno (equity inicial
minusculo com posicoes simultaneas de varios simbolos). O numero a usar e o
valor em USD: 83,30.

## 4. Achados colaterais medidos no journal (2,67 GB)
1. LOT CAP REAL (teto de 8 USD da v1.2.26) nunca apareceu em 297 execucoes.
   Motivo medido: MaxRiskPerTradePercentCap=3,0 com 200 USD ja limita a 6 USD
   por trade, logo o teto em USD nunca e o binding. Fecha P0.3 por calculo.
   Em producao (banca 12 348) o percentual da 370 USD e o cap em USD passa a
   ser o binding - a prova em producao continua pendente.
2. EXECUTION WARNING | FORCA LOTE MINIMO apareceu 6 vezes e a ordem foi
   enviada nos 6 casos: P1.4 confirmado como defeito (avisa e abre).
3. AI GATEWAY | WebRequest falhou | erro 4014 = 18 486 linhas e ainda assim
   297 execucoes: P0.5 respondido. O caminho ativo e EnableAutonomousMode=true
   (IA consultiva) + BlockZeroAIScore=true (veto de score 0); com o gateway
   fora o score vem do fallback Data\prediction_<SYM>.json.
4. [CONFIG] Perfil: Conservative no fim do teste vem do default do objeto
   (Enterprise/ConfigManager.mqh:66, m_current_profile = PROFILE_CONSERVATIVE)
   e NAO dos inputs ativos (StopLossPoints=300). Log enganoso, sem efeito em
   dinheiro, mas deve ser rotulado como default do objeto.
5. Volume de log: Tester\logs\20261030.log chegou a 2,67 GB em 41 min e o
   disco livre caiu de 6,5 GB para 0,72 GB. Prova material do P0.4/P1.3.

## 5. Nao executado e por que
P0.2 (ticks reais) nao foi corrido: com 0,72 GB livres e sem permissao de
escrita/limpeza na pasta Tester, a corrida encheria o disco. Config pronto com
verbosidade reduzida: Profiles\Tester\XAI_V1226_3M_REALTICKS_QUIET.ini
(Model=4, EnableVerboseDebug=false, DebugTradeDecision=false,
EnableForwardLog=false). Antes de rodar: liberar espaco e apagar
Tester\logs\20261030.log.

Nenhuma ordem foi enviada, modificada ou cancelada nesta sessao. Nenhum
.mq5/.mqh foi alterado, logo nao houve recompilacao: o binario em producao
continua o de 30/10 02:06 (v1.2.26), recarregado nos 16 graficos as 14:59:56 UTC.


---

# Ciclo 2026-10-30 (12) - P0.4/P1.3 medido em producao: throttle nao resolveu

Medicao feita no experts log ao vivo (`MQL5\Logs\20261030.log`, 131,8 MB, 908 420
linhas no dia), contando linhas por janela de 30 min nos 16 graficos:

| Janela | Versao | Linhas/30 min | Linhas/hora |
|---|---|---|---|
| 15:30-16:00 | v1.2.26 | 61 532 | ~123 064 |
| 16:15-16:45 | v1.2.28 | 40 203 | ~80 406 |

Reducao de ~35%. O criterio de aceitacao do P1.3 era **menos de ~200
linhas/hora**: continuamos ~400x acima do alvo.

Emissor dominante na janela v1.2.28 (agrupado por mensagem): bloco
`=== HEALTH MONITOR ===` com **959 ocorrencias em 30 min** nos 16 graficos
(~1 bloco por grafico a cada 30 s) e ~25 linhas por bloco => ~24 000 das
40 203 linhas, ~60% do total.

Conclusao: o throttle introduzido na v1.2.27/v1.2.28 cortou SCANNER/PIPELINE/
DATA LOGGER, mas o HEALTH MONITOR continua a sair em cadencia de 30 s e
passa pelo caminho de log que nao respeita o throttle. Proximo passo
cirurgico: LogHealth com janela de 1 hora ou somente em falha, medindo de
novo a mesma janela de 30 min.

Custo colateral medido no mesmo dia: `MQL5\Logs\20261030.log` 131,8 MB,
`Tester\logs\20261030.log` 2 810 MB e `Tester\logs\20261029.log` 1 988 MB.
Disco livre as 16:44: **0,36 GB** - por isso o P0.2 (ticks reais) segue
bloqueado: o Tester nao esta nos write_roots, a limpeza e accao do dono.

---

# Ciclo 2026-10-30 (13) - P1.3/P0.4: journal de 80 406 para 7 020 linhas/hora (-91%)

Medicao no journal vivo (MQL5\Logs\20261030.log), 16 graficos, conta 113568614,
EnableVerboseDebug=true em todos. Cada janela e de estado estavel (as janelas
logo apos recompilar ficaram de fora porque contem o init/reload dos 16 graficos).

| Versao  | Janela                | Linhas | Por hora  |
|---------|-----------------------|--------|-----------|
| v1.2.26 | 15:30:00-16:00:00     | 61 532 | ~123 064  |
| v1.2.28 | 16:15:00-16:45:00     | 40 203 | ~80 406   |
| v1.2.29 | 17:05:00-17:08:30     |  1 426 | ~24 446   |
| v1.2.30 | 17:17:30-17:22:30     |  1 274 | ~15 288   |
| v1.2.31 | 17:30:00-17:35:00     |    585 | ~7 020    |

## O que mudou

- **v1.2.29 - bloco HEALTH MONITOR.** Era so 959 blocos em 30 min (~24 000 linhas,
  60% do journal) porque so havia o gate de EnableVerboseDebug no OnTimer. Passou a
  imprimir o bloco completo apenas com estado nao saudavel ou mudanca de estado
  (max 1x/5 min) e UMA linha por hora quando saudavel. HealthMonitorCheck() continua
  a rodar em todo ciclo: mudou a impressao, nao a vigilancia.
- **v1.2.30 - bloco SYSTEM STATUS (pai de RECOVERY STATUS, EXECUTION SUMMARY e
  SAFETY).** 1x/min por grafico. Medido em 17:05-17:08:30: 66 blocos RECOVERY (37%
  das linhas) + 50 SYSTEM STATUS + 50 EXECUTION SUMMARY (28%). Passou a 1x/4 h com
  tudo OK. No mesmo patch: backoff de transporte no gateway (P-01) e aviso 1x/30 min
  em erro de configuracao.
- **v1.2.31 - a causa, nao so o sintoma.** USDCOP aparecia como `Status: FAILURE`
  com `Segundos sem tick: 661`, `Total ticks: 0` e heartbeats ATR/ADX/RSI/AI em
  falha: HealthMonitorCheckTickTimeout(15) reprovava a saude de um simbolo que
  simplesmente nao tem sessao aberta naquele horario. Em 16 graficos multi-ativo a
  maioria fica nesse estado, entao o alerta nunca desligava. Agora o timeout de tick
  so reprova quando `SymbolInfoSessionQuote` diz que ha sessao aberta agora (helper
  `HealthSymbolSessionOpen()`, sessao desconhecida = criterio antigo). Com isso o
  estado volta a HEALTHY, o bloco de 25 linhas para de sair a cada 300 s e o resumo
  RECOVERY passou de 300 s para 4 h; SYSTEM STATUS ficou em tres niveis (circuito
  aberto 60 s, saude degradada 15 min, OK 4 h).

## Efeito colateral bom

O estado de saude deixou de marcar FAILURE por ausencia de tick. Isso importa mais
do que o journal: `CRecoveryManager`, `CNotificationCenter::SendHealthAlert` e o
`AuditLog` reagem a esse estado. Um FAILURE permanente por simbolo inativo podia
disparar recovery/notificacao sem causa, e ao mesmo tempo escondia a falha real
entre 3 500 linhas/hora de rotina.

## Proximo alvo medido (ainda dentro de P1.3)

Na janela 17:30-17:35 sobraram 585 linhas, dominadas por:

| Emissor | Linhas/5 min | Linhas/hora | Observacao |
|---------|--------------|-------------|------------|
| `[LOGGER OFFLINE]` (HealthMonitor) | 95 | ~1 140 | LoggerInit() nunca e chamado: todo LogInfo/LogError cai no journal |
| `AI LOAD` / `AI FILE NOT FOUND` / `AI INVALID JSON` | 60 | ~720 | throttle de 60 s por grafico em LoadAIPrediction |
| `[SCANNER] BLOCK` + `[PIPELINE] PROCESSANDO` | 160 | ~1 920 | grafico master (USDJPY) varre os 16 simbolos 1x/min |
| `[SESSION] estado salvo` | 16 | ~192 | 1x/hora por grafico, aceitavel |

## Licao de ferramenta (vale para as proximas sessoes)

O helper PowerShell de patch deste projeto tem uma armadilha: `Patch $path @( @($a,$b,$tag) )`
com UM UNICO par e achatado pelo PowerShell, e cada elemento do par chega como string
separada. Com `$pr[0]` virando o PRIMEIRO CARACTERE do texto, `.Replace()` troca aquele
caractere no arquivo inteiro. Foi o que aconteceu hoje: `Monitoring\Logger.mqh` perdeu
todos os `L` (viraram `o`) e `Enterprise\RecoveryManager.mqh` perdeu todos os `R`
(viraram `e`). Os dois foram restaurados de `MQL5\Files\Backup\*.v1229/v1230.bak` e o
patch reaplicado como `Patch $path (, @($a,$b,$tag))`. Regra: **um par sempre entre
virgula/array externo**, e conferir o tamanho e um identificador do arquivo depois.

## Continuacao do ciclo 13 - v1.2.32 e o numero final

Patch v1.2.32 aplicado as 17:36 (fallback `[LOGGER OFFLINE]` para 1x/10 min com
contador). Recarga confirmada no journal do terminal: 16 graficos com
`expert XAU_AI_PRO ... removed` + `loaded successfully` as 17:36:50.

| Versao  | Janela                | Linhas | Por hora  | Reducao vs 80 406 |
|---------|-----------------------|--------|-----------|-------------------|
| v1.2.28 | 16:15:00-16:45:00     | 40 203 | ~80 406   | referencia        |
| v1.2.29 | 17:05:00-17:08:30     |  1 426 | ~24 446   | -70%              |
| v1.2.30 | 17:17:30-17:22:30     |  1 274 | ~15 288   | -81%              |
| v1.2.31 | 17:30:00-17:35:00     |    585 | ~7 020    | -91%              |
| v1.2.32 | 17:42:00-17:46:00     |    418 | ~6 270    | -92%              |

Compilacao das tres versoes: 0 erros e 0 avisos (MetaEditor build 6294).

### O que sobrou e qual e o proximo passo

| Emissor | ~linhas/hora | Onde | Proposta |
|---------|--------------|------|----------|
| `[SCANNER] BLOCK` + `[PIPELINE] PROCESSANDO` | ~1 900 | grafico master (USDJPY) varre os 16 simbolos 1x/min | imprimir so na mudanca de sinal, ou 1x/15 min por simbolo |
| `AI LOAD` / `AI FILE NOT FOUND` / `AI INVALID JSON` | ~700 | `LoadAIPrediction`, throttle de 60 s | 1x/30 min |
| `[SESSION] estado salvo` | ~190 | 1x/hora por grafico | aceitavel, nao mexer |

Depois desses dois o journal entra na faixa de ~3 600/h dominada por evento real
(scanner, execucao, sessao). Chegar a <200/hora com 16 graficos exige decidir o
que fazer com o proprio `[SCANNER]` por simbolo - ou seja, e uma decisao de
produto, nao um throttle a mais.

## Ciclo 13 - v1.2.33 compilada; medicao de regime estacionario bloqueada pelo fechamento

- v1.2.33 (AIConnector 1x/30 min, "[SCANNER] BLOCK | No Signal" 1x/h por simbolo,
  "[PIPELINE] PROCESSANDO" 1x/h por ciclo) compilada as 18:54:21: 0 erros, 0 avisos,
  19 003 ms, .ex5 = 625 266 B, recarga dos 16 graficos entre 18:54:04 e 18:55.
- O processo concorrente subiu `EA_VERSION_STRING` para 1.2.34 as 18:53:32 (P1.1:
  `MaxTotalRiskOpenUsd = 60.0`, envelope de risco aberto em USD). O build em producao
  e o "1.2.34", que CONTEM as tres mudancas da v1.2.33 mais a da v1.2.34. Confirmado
  por leitura: AIConnector.mqh:720 `>= 1800`, MarketScanner.mqh:260 `logInfo`,
  TradePipeline.mqh:102-106 `pipelineInfoTime`.
- Nao existe janela estavel para medir hoje: o mercado fechou as 22:00 UTC (19:00
  local) e o `MQL5\Logs\20261030.log` parou de receber linhas as 18:59:53. A ultima
  linha escrita foi "[SESSION] estado salvo". A medicao tem de ser refeita na
  reabertura (domingo 22:00 UTC).
- Evidencia parcial, janela 18:54:04-19:00:00 (5,93 min, 12 297 linhas, dominada pelo
  init dos 16 graficos - nao e regime estacionario):

| padrao | na janela | esperado antes (1x/min x 16 graficos) |
| --- | --- | --- |
| `[SCANNER] BLOCK | No Signal` | 0 | ~95 |
| `[PIPELINE] PROCESSANDO` | 0 | ~95 |
| `AI LOAD` + `AI FILE NOT FOUND` + `AI INVALID JSON` | 32 | ~285 |
| `=== HEALTH MONITOR ===` | 64 (init) | 16 blocos de 25 linhas por ciclo |
| `========== SYSTEM STATUS ==========` + RECOVERY | 48 + 64 (init) | 16 por minuto |
| `[LOGGER OFFLINE]` | 47 | ~285 |
| `[SESSION] estado salvo` | 48 | 16/hora |

- Achado de produto: com o mercado fechado o journal cai praticamente a zero, ou seja,
  100% do volume remanescente e dirigido por tick/barra. A meta de <200 linhas/hora com
  16 graficos nao e alcancavel apenas com throttle: exige desligar diagnosticos por
  simbolo (decisao do dono, registrada na secao 13 de PENDENCIAS_20261030.md).
- Strategy Tester tentado as 19:06 para medir a emissao por instancia com ticks
  (XAI_V1234_VERBOSE_1D.ini/.set, XAUUSD M15, 28/10, m1-ohlc, verbose on). O run nao
  devolveu janela de resultado e o `Tester\logs\20261030.log` chegou a 3 184 MB, com o
  disco livre caindo de 4,47 GB para 2,93 GB. Experimento abortado: nao repetir
  backtest com `EnableVerboseDebug=true`, o journal do tester cresce em GB.

---

## Ciclo 14 - v1.2.36: teto de perda diaria em USD, fail-closed no lote minimo e verbose OFF no tester

Fechado o pacote 1 + 2 + 4 aprovado (P1.2b, P1.4, P0.2-verbose) numa unica compilacao.

- `Core/Config.mqh`: novo `input double MaxDailyLossUsd = 60.0` (linha 87);
  `OrcamentoDiarioPerda()` devolve o MENOR entre o teto de % do saldo e o de USD
  (mesmo padrao ja validado em `MaxTotalRiskOpenUsd`, v1.2.34);
  `BlockWhenMinLotExceedsRiskCap` passou a `true`; comentario do
  `EnableVerboseDebug` marcado como "ignorado no Strategy Tester".
- `Enterprise/SafetyManager.mqh`: `m_limits.max_daily_loss = OrcamentoDiarioPerda()`
  em vez de recalcular a percentagem.
- `XAU_AI_PRO.mq5`: `VerboseMode` e os tres guards de verbose passaram a exigir
  `!MQLInfoInteger(MQL_TESTER)`.
- `Core/SymbolManager.mqh:277`, `AI/DataLogger.mqh:549`: idem.
- `AI/ModelGovernance.mqh:64`: condicao invertida para continuar a imprimir
  `[MODEL] Governado` com o verbose forcado a OFF no tester.
- `Enterprise/VersionManager.mqh`: `EA_VERSION_STRING "1.2.36"` + paragrafo de changes.

Build: 0 errors / 0 warnings, 18 457 ms, `.ex5` = 623 468 B as 21:13:14.
Os 16 graficos continuam em v1.2.32: o binario esta compilado mas **nao** em producao
(o mercado esta fechado e nao ha recarga). Re-anexar e accao do dono.

Correccao ao relatorio anterior: o journal `MQL5\Logs\20261030.log` foi reiniciado e
tem agora 0,81 MB, pelo que as contagens antigas (15 348 linhas `[SCANNER]`) vivem no
ficheiro rodado, nao neste.

Strategy Tester: as 21:09:22 arrancou uma corrida de 3 meses com ticks reais, mas com
`[VERSION] v1.2.35` - nao e a v1.2.36. O perfil `XAI_V1236_3M_REALTICKS.ini` + `.set`
ficou pronto e validado (308 linhas, `MaxDailyLossUsd=60.0`,
`BlockWhenMinLotExceedsRiskCap=true`) para entrar no slot seguinte.
Custo medido: 15h simuladas em ~6 min de relogio (ETA ~14-15h), log do tester a 5 MB
e disco estavel em 8,05 GB - o verbose OFF resolveu o crescimento em GB.

### Correcao - a versao efetiva do binario e 1.2.37

Entre 21:17:26 e 21:17:48 o processo concorrente subiu a versao para 1.2.37
(`EA_VERSION_STRING "1.2.37"`, cabecalho `// XAU_AI_PRO v1.2.37`,
`#property version "1.237"`) e acrescentou **P1.10 - RealAccountGuard**
(`Core/RealAccountGuard.mqh`). O `.ex5` foi reescrito as 21:18:25 com 632 260 B.

O pacote desta sessao (P1.2b / P1.4 / P0.2-verbose) mantem-se verificado no binario por
`Select-String`: `MaxDailyLossUsd` (Config:87 e :916), `BlockWhenMinLotExceedsRiskCap = true`
(Config:1251), `m_limits.max_daily_loss = OrcamentoDiarioPerda()` (SafetyManager:146-147) e
`MQL_TESTER` em 4 ficheiros. Sem bytes NUL e com todas as fontes anteriores ao `.ex5`.

---

## Ciclo 15 - v1.2.38: scanner agregado (P1.3 rodada 6)

O `[SCANNER]` era o maior emissor do journal e o unico cujo piso nao dependia de
throttle: cada gate que barrava um simbolo reimprimia a mesma linha 1x/minuto. Medido
em 30/10 na v1.2.32: **15 348 linhas** de `[SCANNER]` no dia, **15 108 num unico
grafico** (o mestre que varre os 11 simbolos de `Symbols`).

Alteracao em `Core/MarketScanner.mqh`:

- novo `enum ENUM_SCAN_BUCKET` (7 motivos) + `ScanBlock()` + `ScanFlush()`;
- `ProcessSymbol()` abre/fecha a janela de 60 s e emite
  `[SCANNER] RESUMO | simbolos=N | sinais=N | trades=N | bloqueios=N | <motivo>=N ...`;
- detalhe por simbolo so com `EnableVerboseDebug` e fora do tester;
- resumo silencioso no maximo 1x/15 min; `TRADE SUCCESS` continua sempre.

Resultado esperado: de ~660 linhas/hora (so `No Signal`) + gates para ~60/hora por
instancia. Falta medir na reabertura (domingo 22:00 UTC) contra a referencia de
6 270 linhas/hora da v1.2.32.

Build: 0 errors / 0 warnings, 18 339 ms, `.ex5` = 634 590 B as 21:47:00, versao 1.2.38
(a mesma que o processo concorrente abriu para o P1.11 + P1.10).
Sem bump proprio: o paragrafo `v1.2.39` que eu tinha escrito no changelog foi revertido
para nao deixar `changes` e `EA_VERSION_STRING` a divergir.

## Ciclo 16 - leitura do lado A (v1.2.35, ticks reais) e orcamento de journal

Objectivo: decidir a sequencia do P0.2 com dados, nao com estimativa.

O que foi feito:
- Slot do Strategy Tester reavaliado: a corrida do processo concorrente (v1.2.35,
  `XAI_V1226_3M_REALTICKS_LEAN.ini`, 21:09:22) continua activa; `tester_run_backtest`
  responde `tester still started`. Nao posso parar o job: `tester_stop` exige `run_id` e o
  job nao foi arrancado por estas ferramentas.
- Extraccao em streaming do Tester log (o ficheiro esta aberto em modo exclusivo; foi
  preciso `FileShare.ReadWrite`) para obter a curva de saldo por dia simulado.
- Contagem literal de marcadores para medir o orcamento real de journal.

Resultado do lado A (200 USD, 2026.07.29 -> 2026.08.05 simulado, 14 trades):
`188,64 -> 184,11 -> 177,87 -> 175,98 -> 172,55 -> 172,31` = **-13,8% em 6 dias**, sangria
monotona de ~2,4 USD/dia.

Orcamento de journal (495 472 linhas / 6 dias simulados):
- `[STATE]` 25,6%; `RISK CALC USD` 8,4%; `[COST] BLOQUEADO` 8,4%; `CUSTO BLOQUEADO` 8,4%
  (o mesmo evento duas vezes); `SEM STOP NA ENTRADA` 8,4%; `[SCANNER]` 2,6%.
- 41 602 tentativas de risco para 14 trades.

Conclusao: o P1.3 (scanner agregado) resolve 2,6% do volume. O alvo <200 linhas/hora passa
por desligar `EnableVerboseDebug` em producao e por travar o registo por tentativa
(candidato P1.13). BÃ³nus: o mesmo travao acelera o testador, porque 34% das linhas estao no
caminho critico de uma tentativa bloqueada no custo.

Custo de recursos: log a 177 MB/hora, disco livre 7,69 GB, ETA do lado A ~11-12 h com ~2 GB
de log adicional. O dono deve vigiar o disco.

Coordenacao: fontes em 1.2.39 (`XAU_AI_PRO.mq5` 22:05:46, `EA_VERSION_STRING` 1.2.39,
`#property version "1.239"`), P1.12 fechado pelo processo concorrente, que adoptou o meu P1.3
como v1.2.39. O binario local e 1.2.38 e esta desactualizado; nao recompilei de proposito.
## Ciclo 17 - o lado A prova que a cadeia de saida nunca ganha

Metodo: leitura integral do Tester log do lado A (v1.2.35, ticks reais) em streaming, com
extracao de todas as linhas `TRADE CLOSED | SYMBOL | PROFIT=` e histograma de marcadores.

Numeros (17 dias simulados de 92, saldo 200 -> 156,43):
- 110 trades fechados: **0 com lucro**, 64 com perda, 46 exactamente `0.00`.
- soma dos PROFIT -43,78 USD; 200 - 43,78 = 156,22 contra saldo real 156,43 (swap 0,21). O log
  reconcilia - nao e artefacto de registo.
- `TAKE PROFIT` = 0 ocorrencias, `PARCIAL` = 0. O alvo nunca e atingido e o fecho parcial
  nunca dispara; `VIGIA FECHOU` = 47 e `BREAKEVEN` = 6 explicam os fechos.
- pior trade -7,79 USD (USDSEK); perda media -0,68 USD.

Leitura: o trade que anda a favor e fechado a 0,00 e o que anda contra fecha em perda. A trava
de break even (`BreakEvenLockR` 0,30 x distancia ao TP) devia deixar +0,3 R; o que se observa e
empate tecnico exacto. Ou a trava resolve para o preco de entrada, ou outra via (ladder `SO
ALVO`, vigia) fecha primeiro. E o defeito mais caro do EA e passa a ser a prioridade acima do
teto de perda diaria - que nesta corrida nunca teria disparado (perda diaria de 2-4 USD contra
um teto de 60 USD).

Journal: `[STATE]` 24,3%, `[RISK]` 8,0%, `[COST]` 7,8%, `[VIA RAPIDA]` 5,8%, `[LEARN]` 5,5%,
`[SCANNER]` 2,7%, `[LADDER]` 1,3%. `[LADDER]` e o pior em densidade: 98,9 linhas por trade, por
tick, sem throttle - candidato directo a trava de 60 s por ticket.

Recursos: log 251 MB a 174 MB/h, 8,90 GB livres (o dono libertou espaco), ETA ~9 h.

## Ciclo 18 - v1.2.37 a v1.2.40: conta real, disco e spam de journal (30/10 noite)

Registo pedido pelo dono ("salvar conversas anotar") para a cadeia de trabalho que
correu entre as 20:00 e as 23:35 de 30/10, mais a leitura do historico que veio a
seguir. Nenhuma linha de codigo foi escrita nesta gravacao.

### Versoes fechadas

| Versao / item | Ficheiros | Efeito |
|---|---|---|
| v1.2.37 / P1.10 | `Core/RealAccountGuard.mqh` (novo), `Core/ExecutionEngine.mqh`, `Core/PositionManager.mqh`, `XAU_AI_PRO.mq5` | Guarda que so aperta em conta REAL: lote minimo acima do tecto bloqueia, `StoplessEmergencyDistance()` nunca aceita multiplicador 0, maximo de 1 posicao sem stop por simbolo, banner `[REAL GUARD]`. Inerte no testador e em demo. |
| v1.2.38 / P1.11 | `Enterprise/BackupManager.mqh` | Snapshot deixou de correr em pares sobrepostos e passou a detectar a corrida entre instancias; copia de ficheiro inexistente deixou de ser fatal. |
| v1.2.39 / P1.12 | `XAU_AI_PRO.mq5`, `Enterprise/BackupManager.mqh`, `Enterprise/VersionManager.mqh` | Bloco `HEALTH MONITOR` de 25 linhas: 1x/hora (era a cada 5 min, e com o mercado fechado o estado ficava nao-saudavel para sempre). Falha de copia do backup: 1x/hora com contador de abafadas. |
| v1.2.39 / P1.3 | `Core/MarketScanner.mqh` (processo paralelo) | Scanner emite UM resumo por minuto por instancia em vez de uma linha por simbolo; detalhe so com `EnableVerboseDebug` e nunca no tester. |
| v1.2.40 / P1.13 | `Monitoring/AuditLog.mqh`, `Core/Config.mqh`, `Enterprise/VersionManager.mqh` | Rotacao por tamanho do `audit_log.csv`: `AuditRotateDecisionLogIfNeeded()` corre no inicio de `AuditOpenDecisionLog()` e move para `audit_log_prev.csv` acima de `AuditLogMaxSizeMb = 8` (limite efectivo 16 MB, nada apagado). Aviso `[AUDIT] rotacao ...` 1x/hora. |

Compilacao final: **0 erros, 0 avisos**, 23 150 ms, `X64 Regular`, MetaEditor build 6294,
`XAU_AI_PRO.ex5` 639 638 B as 22:31:15. `LF_solto = 0` nos quatro ficheiros tocados.

### Numeros que justificaram cada decisao

- **Journal:** v1.2.32 media 6 270 linhas/hora. Numa janela com o mercado fechado
  (16:02 -> 21:44) o bloco `HEALTH MONITOR` saiu 2 064 vezes e a falha de copia do
  backup 2 574 vezes. Alvo: **< 200 linhas/hora**.
- **Disco:** `Common\Files\XAU_AI_PRO\Backups` com 10 snapshots x 109 ficheiros =
  1 100 ficheiros, **787,2 MB**, **78,7-78,8 MB por snapshot**. A retencao estava certa
  (`BackupMaxKeep = 10`); o que nao tinha limite era o conteudo: `audit_log.csv` com
  **69 979 KB (68 MB)** as 22:28, copiado inteiro em cada snapshot. Foi esta a via que
  deixou 0,37 GB livres e abortou um backtest.
- **Efeito esperado da P1.13:** snapshots a descer de 78,8 MB para ~11 MB (8 de audit +
  7,3 de `trade_history` + 3,3 de dataset + predictionss).

### P0.5 - porque entram operacoes sem IA (fechada por leitura de codigo)

Cadeia exacta: `AIGateRequired()` devolve `false` quando `EnableAutonomousMode = true`
(`Core/Config.mqh:998`, valor por defeito) -> `AITradeAllowed()` devolve `true` sem olhar
score (`AI/AIEngine.mqh:58-64`) -> `FinalAIAllow()` so entra no ramo de bloqueio
`if(AIGateRequired())` (`AI/AIEngine.mqh:486-500`). O unico veto que resta e o de score
zero, `BlockZeroAIScore = true` (`Core/Config.mqh:1017`), que vale nos dois modos.
**Nao havia contradicao:** a IA e consultiva por desenho, documentado em
`Core/Config.mqh:986-998`. Politica activa: operar sempre; silencio total da IA (score 0)
e motivo de recusa.

### Efeito colateral do P0.5 (aberto, precisa de decisao)

`CalculateDynamicLot` (`Core/ExecutionEngine.mqh:86`) usa `GetAIConfidence()` como
"confianca" que decide o lote, via `ConvictionGrade()` -> `LotFactorForGrade()`. Sem IA, o
fallback tecnico chega a 85 (50 base + 15 tendencia + 10 RSI + 10 ADX,
`AI/AIEngine.mqh:141-160`): 85 >= `DynConfStrong` (82) com ADX >= 35 da nota 3 = **3x
lote**; e o `MemoryBoost` aprendido (`AI/AILearningMemory.mqh:154+`, ate 1,25x) empurra o
score para 100 -> `DynConfElite` (90) -> nota 4 = **4x lote**. Ou seja: **lote 4x sem
nenhum modelo ter respondido**. Nao viola a regra do dono (lote pela clareza da tendencia),
mas o numero mente no nome.

### Analise do historico (`trade_history.csv`)

Amostra: **99 560 registos validos** (o ficheiro e uma concatenacao de muitas corridas: 687
dias distintos, 369 reinicios de ordem temporal, logo os totais absolutos nao valem como
resultado de uma serie).

- **Integridade:** 371 linhas partidas de 99 943; `AI > 0` em 17 de 99 649. Causa:
  `Monitoring/TradeLogger.mqh` guarda handle persistente por instancia e faz
  `FileSeek(SEEK_END)` + `FileWrite` **sem `EventLock`** - com 16 graficos a escrever, as
  linhas intercalam-se. E o ficheiro de onde o EA aprende o historico (regra 7 do dono).
- **ADX (XAUUSD, 80 065 registos):** `>= 35` **+36 152** (WR 82,6%, PF 1,295);
  `25-35` **-31 033** (PF 0,592, media -2,84/trade); `20-25` -17 952 (PF 0,526); `< 20`
  -14 102 (PF 0,872). Todo o lucro vem de ADX >= 35.
- **Horas (UTC = servidor - 5):** piores servidor 16 / UTC 11 **-11 123**, servidor 19 /
  UTC 14 **-7 576**, servidor 14 / UTC 9 **-6 443** (soma **-25 141**). Melhores: servidor
  20 / UTC 15 +3 417, servidor 15 / UTC 10 +3 384, servidor 18 / UTC 13 +2 963. O
  `AvoidHoursGMT` proposto ("18,20,22") aponta para servidor 23, 1 e 3 - e o servidor 23
  tem 42 trades. **A lista nao cobre as horas que custam dinheiro.**
- **Global:** net -30 768,95, WR 67,8%, **PF 0,918**, media -0,31/trade. Coerente com o
  lado A do backtest (PF 0,81): muitos acertos pequenos, poucas perdas grandes.

### Propostas registadas (sem alterar nada - decisao do dono)

- **P1.14:** `DynADXClear` 25 -> **35** (nao escalar acima de 1x sem ADX >= 35).
- **P1.15:** `AvoidHoursGMT = "9,11,14,18,20,22"` (acrescenta as tres horas medidas como
  piores, mantem as antigas).
- **P1.16:** `Monitoring/TradeLogger.mqh` passar a abrir -> `SEEK(END)` -> escrever ->
  `FileFlush` -> fechar dentro do `EventLock` (padrao F4 do audit), para acabar com as
  linhas partidas.

### Nao validado

1. Nenhuma P1.13/P1.12/P1.3 medida em producao: o binario v1.2.40 **nao esta carregado nos
   graficos** (o re-anexar dos 16 exige autorizacao do dono).
2. Lado B do backtest (`run_id 7702617382101217572`) continuava a correr as 23:35
   (progresso 01:27 / 10:37), contra o lado A ja fechado (-34,68 / PF 0,81 / 296 trades /
   MaxDD 83,30).
3. As propostas P1.14/P1.15 precisam de confirmacao no backtest de 3 meses com ticks reais:
   esta amostra tem vies de concatenacao e nao distingue EA de operacao manual.

### Licoes de ferramenta desta ronda

- `search_text` do MCP **nao varre subpastas**: deu 0 resultados para `AllowTradeWithoutAI`
  em `.mqh` quando o input existe em `Core/Config.mqh:520`. Para `.mqh` usar
  `Get-ChildItem -Recurse | Select-String` (dentro do read root `MQL5`).
- Em PowerShell, `` '`n' `` em aspas simples e backtick literal, nao newline: uma contagem
  de LF solto reportou 2 num ficheiro limpo. Medir com `[char]10`/`[char]13`.
- Duas edicoes ao MESMO ficheiro no mesmo bloco correm em paralelo e perdem uma delas
  (aconteceu com `#property version`, que ficou `1.239` com o cabecalho em v1.2.40).
## Ciclo 19 - v1.2.41: o ficheiro de onde o EA aprende deixou de ser corrompido (P1.16)

Execucao do primeiro item da lista de propostas medidas em 30/10. Escolhido por ser o
**unico de risco nulo**: so muda I/O de ficheiro, nao toca em lote, horario, sinal, saida
nem risco. A razao de ser o primeiro e de ordem logica: P1.14 e P1.15 foram medidas sobre
um ficheiro com 371 linhas partidas e 369 reinicios temporais - apertar risco sobre essa
amostra seria afinar o radio com o mostrador torto.

### Base medida

| metrica do `trade_history.csv` | valor |
|---|---|
| registos validos | 99 560 |
| linhas partidas | **371** |
| reinicios de ordem temporal | **369** |
| registos com `AI > 0` | 17 de 99 649 (0,017%) |
| tamanho / congelado em | 7 498 313 B / 31/10 06:23 |

Mecanismo do defeito (dois, independentes, no mesmo modulo): **interleave** de dois
`FileWrite` concorrentes e **posicao obsoleta** - o handle persistente guarda o EOF de
quando fez o seek, logo grava por cima do que outra instancia escreveu entretanto (o modo
`FILE_SHARE_READ|WRITE` nao e append atomico). O `Monitoring/EventEmitter.mqh` ja tinha
resolvido exactamente isto e o comentario dele explica o mesmo padrao; o TradeLogger nunca
o adoptou.

### Mudanca (v1.2.41)

| ficheiro | mudanca | tamanho |
|---|---|---|
| `Monitoring/TradeLogger.mqh` | reescrito no padrao F4 (sem handle persistente) | 3 250 -> **7 153 B** |
| `XAU_AI_PRO.mq5` | guard `if(TradeLoggerReady())`, cabecalho v1.2.41, `#property "1.241"` | **73 825 B** |
| `Enterprise/VersionManager.mqh` | `EA_VERSION_STRING "1.2.41"` + changelog P1.16 | **15 597 B** |

`ABRIR -> LOCK -> SEEK(END) -> WRITE -> FLUSH -> FECHAR`, tudo dentro do `EventLock`
(GlobalVariable CAS + TTL de 2 s, o mesmo do EventEmitter e do BackupManager). Header
criado sob lock. Preferencia declarada: **nunca bloquear a execucao** - se o lock nao vier,
o trade e um DROP contado e impresso, nao uma linha partida no ficheiro. `TradeLoggerReady()`
e `TradeLoggerSummary()` (`Written`/`Dropped`/`EventLockStats()`) dao o estado sem handle.

### Validacao

- Compilacao: **0 erros, 0 avisos**, 16 461 ms, `X64 Regular`, MetaEditor build 6294,
  `XAU_AI_PRO.ex5` **640 754 B** as 15:50 (antes 640 948 B).
- `grep` nas fontes vivas: nenhum `tradeLoggerHandle` restante; guard novo em
  `XAU_AI_PRO.mq5:1639`; fontes todas mais antigas que o binario.

### Estado medido depois do build (o que o dono precisa de saber)

- **15 graficos** com o EA (nao 16), todos ainda com os inputs antigos: `DynADXClear 25.0`,
  `AvoidHoursGMT "18,20,22"`, `MinimumADX 18.0` -> **P1.14 e P1.15 sem efeito**.
- **chart04 / USDJPY** divergente dos outros 14: `AvoidHoursGMT "18,22"`,
  `BlockWhenMinLotExceedsRiskCap false`, `DailyProfitTargetMaxUsd 100.0`. Com o guard de
  mestre activo, uma instancia joga por regras de risco diferentes.
- **Sabado, mercado fechado**: `trade_history.csv` parado as 06:23. A escrita F4 nao tem
  nada para gravar hoje - a prova chega no primeiro trade de segunda.
- **Disco**: 6,99 GB livres; `Tester\logs` com 1,19 GB (347,6 MB de 30/10 + 842,3 MB de
  31/10, este ultimo o log da corrida que morreu sem relatorio).

### Nota de coordenacao (processo concorrente)

As 15:49:07 outro processo criou `Monitoring/DiagGate.mqh` (5 738 B: `DiagGateAllow()`,
`DiagGateSummary()`, `g_diagGateSuppressed`) e inseriu o `#include` em `XAU_AI_PRO.mq5:38`.
O build desta ronda inclui-o e compila limpo, mas **ele nao tem changelog**: o binario
640 754 B tem P1.16 documentada e DiagGate nao documentada. Nota para a proxima sessao, nao
para reverter agora.

### Licoes de ferramenta desta ronda

- `metaeditor64.exe` com o caminho entre aspas soltas rebenta em `'C:\Program' nao e
  reconhecido` e o cmd ainda devolve `EXITCODE=0` - **falso sucesso**. Usar sempre
  `cd /d "C:\Program Files\MetaTrader 5" & metaeditor64.exe /compile:...` e ler a linha
  `Result:` do log, nunca o exit code.
- `search_text` do MCP nao varre subpastas: deu 0 resultados para `EventLock` em `.mqh`
  quando o ficheiro existe. Para varrer arvore, `findstr /S` por shell dentro do read root.
- `list_open_charts` devolve os inputs completos de cada grafico - e a forma mais barata de
  provar se uma proposta de configuracao esta ou nao aplicada. Nesta ronda provou que nao.
- Duas edicoes ao mesmo ficheiro no mesmo bloco continuam a perder uma delas: o bump de
  versao foi feito em edicoes separadas.


## Ciclo 20 - v1.2.43: 1 286 MB limpos, a cadeia de saida medida e tres correcoes justificadas

### Objetivo

Executar a instrucao permanente do dono - limpar o que e regeneravel sem interromper o
trabalho, e aplicar as melhorias que a medicao sustentar - sem tocar em parametros de risco
por palpite.

### Parte A - limpeza (ronda 2)

Ronda 1 ja tinha libertado 1 317 MB. Nesta ronda atacaram-se os 5,3 GB de
`MQL5\Files\XAU_AI_PRO` e os duplicados de `MQL5\Files`, com provas antes de apagar:

- `MQL5\Files\Common\Data` (522,0 MB): 43 de 52 ficheiros SHA256-identicos a
  `MQL5\Files\Data`, os 9 restantes sao `prediction_*.json` de 1 KB de agosto (preservados
  em `Backup\Common_Data_unicos_20261031`). Zero referencias a `Common\Data` nos fontes. As
  referencias a `FILE_COMMON` no EA apontam para `Terminal\Common\Files`, nao para aqui.
- `core\Temp\cargo-target` (602,5 MB, 1 708 ficheiros): cache de build Rust parado desde
  22/10 23:20, sem `cargo`/`rustc` em execucao.
- `MQL5\logs\20261030.log` (160,3 MB), caches `.pyc`/`.tmp`/`.orig`, 23 logs de compilacao.

Ficaram deliberadamente de fora `dist` (1 022 MB, PyInstaller), `.venv` (1 331 MB),
`node_modules` (211 MB) e `Tester\logs` (1 135 MB) - os tres primeiros por exigirem rede e
tempo para reconstruir, o ultimo por estar fora dos `write_roots`.

**Disco: 6 776 -> 9 314 MB livres (2 583 MB nesta sessao).**

### Parte B - a medicao que decidiu o codigo

`Tester\logs\20261031.log`: 2 970 941 linhas, 269 tickets com `[LADDER]`.

- `ALVO EM DINHEIRO` (20 USD): **0 ocorrencias**.
- `STOP TRAVADO` (15 USD): **2**. `STOP NA ENTRADA` (10 USD): 157 tickets distintos.
- MFE por ticket: **214 de 269 tickets nunca passaram de 5 USD**; apenas 2 chegaram a
  >= 10 USD; **nenhum** chegou a 20 USD.
- `min(MFE, alvo)` somado: 153 / 160 / 164 / 168 / 170 / 171 / 171 USD para alvos
  8 / 10 / 12 / 14 / 15 / 18 / 20. **Mexer no alvo nao pagaria nada.**
- 54 093 linhas `[LADDER]` para 269 tickets, mas por ticket o SL so assumiu 2-3 valores e
  houve **zero** `[LADDER] Falha` -> reenvios redundantes de `PositionModify`.

### Parte C - o que mudou

| item | ficheiro | mudanca | prova |
|---|---|---|---|
| P1.18 | `Management\MoneyLadder.mqh` | nao reenvia `PositionModify` quando SL e TP ja sao os da posicao; removido o `if(noiseUsd > armUsd)` que era codigo morto | 54 093 linhas para 269 tickets, SL com 2-3 valores distintos, 0 falhas |
| P1.14 | `Core\Config.mqh` (1244) | `DynADXClear` 25,0 -> 35,0 | ADX 25-35: n=10 936, -31 033 USD, PF 0,592; ADX >= 35: +36 153, PF 1,295 |
| P1.15 | `Core\Config.mqh` (684) | `AvoidHoursGMT` "18,20,22" -> "9,11,14,18,20,22" | GMT 9/11/14 = 16 622 trades, -25 141 USD |
| versao | `Enterprise\VersionManager.mqh`, `XAU_AI_PRO.mq5` | 1.2.43 / `#property "1.243"` | `get_expert_advisor_parameters` |

### Validacao

    Result: 0 errors, 0 warnings, 15638 ms elapsed, cpu='X64 Regular'
    XAU_AI_PRO.ex5   646 910 B   31/10/2026 16:20   (versao 1.243)

### O que quase correu mal

A primeira compilacao da v1.2.43 deu 100 erros e o processo devolveu `EXITCODE=0`. O
`Config.mqh` tinha sido corrompido pela ferramenta de substituicao em quatro camadas
sucessivas: 23 LF soltos num ficheiro CRLF, 2 665 caracteres nao-ASCII em comentarios,
44 bytes NUL a partir do offset 73 247 (a causa real - o compilador trata um `.mqh` com NUL
como binario) e, por fim, o `#endif` final comido pela propria limpeza. Recuperado para
73 275 B / 1 529 linhas / 247 inputs / 0 NUL / 0 nao-ASCII.

### Licoes de ferramenta desta ronda

- **`EXITCODE=0` nao e sucesso.** So a linha `Result:` do log conta. Esta ronda teve 6
  compilacoes das quais 4 falharam com exit code 0.
- **Ordem de diagnostico de um `.mqh` que "rebenta sem motivo":** NUL -> EOL -> non-ASCII ->
  codigo. A causa real era a terceira da lista em tamanho e a primeira em importancia.
- **`replace_text_in_file` e o `edit` do MCP nao servem para edicoes multi-linha com CRLF**
  neste ficheiro (devolveram `replacements: 0` e "No match found"). O que funcionou foi
  sondar as linhas com um script, confirmar CRLF, e substituir por script com contagem de
  ocorrencias antes de escrever.
- **Duplicados de 500 MB devem ser provados, nao presumidos**: SHA256 ficheiro a ficheiro,
  mais pesquisa de referencias no codigo. Foi isso que autorizou apagar 522 MB com
  tranquilidade.

## Ciclo 21 - v1.2.43 a correr nos 16 graficos e a descoberta de que `Symbols` nao governa nada

### Parte A - o re-ataque dos 16 graficos

Objectivo: pôr a producao a correr com o binario v1.2.43 **e** com os dois inputs que a medicao justificou
(`DynADXClear` 35.0 e `AvoidHoursGMT` "9,11,14,18,20,22"), normalizando de caminho o chart04/USDJPY.

Caminho seguido, e a parte que quase estragou tudo:

1. `profile_add XAI_V1243_20261031` (16:31:11) a partir do estado vivo.
2. `patch_charts_1243.ps1` -> 16/16 substituicoes verificadas.
3. `profile_apply` do novo perfil -> **no-op**, porque ja era o selecionado.
4. Apliquei o perfil antigo para libertar a selecao. Ao trocar, o terminal **reescreveu** os 16 `.chr`
   do perfil novo a partir do estado vivo (16:32:12) e desfez o patch: tudo de volta a 25.0.
5. Re-patch (16/16) e `profile_apply` **imediatamente a seguir** (16:32:15, ok:true).

Estado final verificado em duas fontes independentes:
- disco: 16 `.chr` as 16:32:29 com ADX 35.0 / horas novas / blkMin true / dptMax 40.0;
- `list_open_charts`: as 16 instancias vivas com os mesmos valores, EA ligado, `AutoTrade=true`.

### Parte B - a medicao que decidiu (e a que abriu uma pergunta nova)

Ao rever o journal das 16 instancias reparei que **todas** imprimem `Total active symbols: 11`,
incluindo as que correm `USDCLP`, `USDCOP`, `USDCZK`, `USDRUB` e `USDSGD` - simbolos que **nao** estao
na lista `Symbols`. Isso levantou a pergunta certa: se a lista nao os inclui, porque operam?

Resposta, por leitura de codigo: `Core\SymbolManager.mqh` enche `ActiveSymbols[]` a partir de `Symbols`,
mas **`ActiveSymbols` nao e lido em mais nenhum ficheiro do EA**. Quem manda e `_Symbol` do grafico.
`EnableMultiSymbol`/`Symbols` produzem log e nada mais.

### Parte C - o que muda no codigo

Aplicado no fim desta ronda como v1.2.44 / P1.19 - ver a adenda no fim do ciclo. Razao: a medicao mostra um desalinhamento **sem efeito de trading** e mexer no
`SymbolManager` com 16 instancias a operar em DEMO e exactamente o tipo de alteracao que nao se faz por
palpite. Fica registado como **P1.19** com a correcao barata identificada (aviso quando `_Symbol` nao
consta de `Symbols`), para entrar junto com a proxima janela de codigo.

O que fica documentado e vale mais do que o codigo: **`Symbols` nao limita o universo negociado**.
O universo e o conjunto de graficos com o EA ligado. Os 16 graficos partilham `MagicNumber=2026001`
sem colisao apenas porque os 16 simbolos sao distintos - se dois graficos passarem a ter o mesmo simbolo,
passam a existir duas instancias a gerir a mesma posicao com o mesmo magic.

### Validacao

- 16/16 graficos com v1.2.43, `DynADXClear=35.0`, `AvoidHoursGMT=9,11,14,18,20,22`,
  `BlockWhenMinLotExceedsRiskCap=true`, `DailyProfitTargetMaxUsd=40.0`, `LadderTpUsd=20.0`.
- Compilacao: nao executada nesta ronda - nenhuma fonte foi alterada. O `.ex5` (646 910 B, 16:20:43)
  continua mais recente do que todas as fontes.
- Rollback: `XAI_V1232_ROLLBACK_20261030` intacto; backups `.bak` dos `.chr` originais preservados.

### O que quase correu mal

- Confiar no `profile_apply` depois de um patch **sem** garantir que o perfil nao estava selecionado.
  Custou um patch inteiro desfeito em 3 segundos. A regra ficou escrita: patch a frio, apply a seguir.
- `'Select-String' nao reconhecido` quando se canaliza um script dentro de `powershell -NoProfile -Command`.
  A solucao e correr o script sem pipe e devolver so o relatorio.

### Licoes de ferramenta desta ronda

- `search_regex`/`search_text` do MCP **nao sao recursivos** com glob `*.mq*` na raiz do EA: devolveram
  `total_files: 3` (so os 3 ficheiros da raiz) e zero resultados para um input que existe no `Core\Config.mqh`.
  Para varrer o EA inteiro: `Get-ChildItem -Recurse -Include *.mq5,*.mqh | Select-String`.
- O journal do expert e a fonte mais rapida para saber **o que o EA pensa** (ex.: numero de simbolos ativos),
  antes de ir ler o codigo. Medir primeiro, ler depois.

### Pendente

`Tester\logs` 1 135 MB (fora dos write_roots), decisao sobre `dist`/`.venv`/`node_modules`,
backtest de 3 meses (9 282 MB livres), janela limpa de 2-3 dias a partir de segunda, P1.19.


### Adenda 16:40 - P1.19 aplicado e v1.2.44 em producao (o codigo mudou, afinal)

Escrevi acima que nada mudava no codigo. Mudei de ideias pelos numeros: o mercado esta fechado (sabado),
a correcao tem 10 linhas e nao toca em risco nem em execucao. Era a janela certa e nao valia a pena
deixar a incoerencia escondida ate segunda.

O que mudou:

- `Core\SymbolManager.mqh`: em `InitSymbolManager()`, depois de `ActiveSymbols[]` estar construido, o
  `_Symbol` do grafico e resolvido pelo mesmo `ResolveBrokerSymbol()`; se nao constar da lista, imprime-se
  `SYMBOL MANAGER | AVISO P1.19: ...`. Unico efeito no comportamento: uma linha de journal. Nada de risco,
  execucao, filtros ou regras de entrada.
- `Enterprise\VersionManager.mqh`: `EA_VERSION_STRING` 1.2.43 -> 1.2.44 e entrada de changelog.
- `XAU_AI_PRO.mq5`: cabecalho v1.2.44.
- Compilacao: `Result: 0 errors, 0 warnings` (15 240 ms). `.ex5` 648 734 B as 16:38:06.
- Backup do original: `Files\Backup\SymbolManager_20261031_before_p119.mqh`.

**Prova de que o aviso distingue mesmo os dois casos** (journal do expert, 16:38:18 e 16:38:24): disparou
exactamente em 5 instancias - `USDCLP`, `USDCOP`, `USDCZK`, `USDRUB`, `USDSGD` - e em nenhuma das 11 que
constam de `Symbols`. Se a comparacao estivesse mal feita (sufixo de broker, sensibilidade a maiusculas,
resolucao de nome), teria disparado nas 16 ou em nenhuma. Disparou nas 5 previstas pela auditoria.

**Prova de que o binario novo chegou aos 16 graficos:** 16 registos `XAU_AI_PRO v1.2.44` as 16:38:23, um
por simbolo, todos distintos (`USDSGD, EURUSD, USDCOP, XAUUSD, NZDUSD, USDBRL, USDCNH, GBPUSD, AUDUSD,
USDRUB, USDCAD, USDCHF, USDSEK, USDJPY, USDCLP, USDCZK`).

**Licao operacional nova:** o terminal NAO recarrega os EAs quando o `.ex5` e compilado por processo
externo - o `metaeditor64 /compile` nao avisa o terminal, ao contrario da compilacao pelo IDE. Para o
binario entrar em producao foi preciso o ciclo `profile_apply Default` -> `profile_apply XAI_V1243_20261031`,
que recarrega os EAs a partir dos `.chr`. Sem isso o EA antigo continuaria em memoria e a versao impressa no
journal continuaria a ser a antiga - exactamente o tipo de "ja apliquei" que e falso.

**Os inputs sobreviveram ao ciclo:** os 16 `.chr` foram reescritos as 16:38:14 e continuam com
`DynADXClear=35.0` e `AvoidHoursGMT=9,11,14,18,20,22` (16/16 verificados por leitura direta do disco).
A troca de perfis propaga o estado vivo para o perfil que sai, e o estado vivo ja estava correcto.

## Ciclo 22 - o backtest de 3 meses passou a correr a configuracao de producao (e nao uma fotografia de 1.2.36)

### O que estava errado antes de arrancar
Dois problemas, ambos silenciosos:

1. **A versao numerica do binario estava atras.** `EA_VERSION_STRING` = 1.2.44 desde as 16:37, mas `#property version` continuava `"1.243"`. O `VersionManager` documenta que os tres sitios tem de concordar. Corrigido para `"1.244"` e recompilado: `0 errors, 0 warnings`, `.ex5` de 648 936 B as 16:58:59. Sem tocar em logica — o binario do tester e o dos 16 graficos diferem apenas nesta string.
2. **O `.set` era de outra versao.** `XAI_V1236_3M_REALTICKS.set` foi gravado em 1.2.36 e trazia `DynADXClear=25.0` e `AvoidHoursGMT=18,20,22` — os dois valores que a medicao de hoje derrubou. Remendar dois campos deixaria os outros ~300 presos em 1.2.36, incluindo os quatro `RealGuard*` que nasceram em 1.2.37.

### A decisao: o `.set` passa a ser extraido do grafico
Em vez de editar um ficheiro antigo, o `build_set_1244.ps1` le o bloco `<inputs>` do `chart01.chr` (XAUUSD) do perfil `XAI_V1243_20261031` e escreve um `.set` novo.

| medicao | valor |
|---|---|
| inputs no `<inputs>` do grafico | 308 |
| inputs declarados pelo `.ex5` | 308 |
| `.set` gerado | 7 786 B |

Os 308/308 sao a prova de que o grafico guarda o conjunto completo — o backtest nao herda defaults do codigo onde a producao tem valores escolhidos. Foi esta a diferenca que fez valer o trabalho: a partir de agora qualquer alteracao de input em producao entra no proximo backtest por construcao, nao por memoria de quem o prepara.

### O que foi conscientemente desligado
14 interruptores de escrita/telemetria (`EnableVerboseDebug`, `DebugTradeDecision`, `EnableDiagnostics`, `EnableDataset`, `SaveDatasetCSV`, `EnableScenarioLog`, `EnableGlobalScenarioLog`, `EnableAuditLog`, `EnableTelemetry`, `EnableDashboard`, `EnableBackupManager`, `EnableForwardLog`, `EnableNotifications`, mais `AutoTrade=true`). O motivo e medido, nao estetico: o log do tester cresceu ~800 MB em 6 h de simulacao e o disco tem 11,9 GB. Nenhum destes campos entra na decisao de abrir, no lote, no risco ou na escada de saida. Se o resultado divergir, o teste e repor `true` um a um.

### A corrida
`run_id 7702924108834513378`, XAUUSD M15, **ticks reais**, 2026.07.29 -> 2026.10.29, deposito 200 USD, alavancagem 1:100, arranque 17:00:15 no agente `Core 1` (build 6294), 9 556 MB atribuidos, 119 blocos de geracao de ticks. Progresso apos 90 s: `00:01:28 / 24:26:40`.

### Validacao
- Compilacao: `Result: 0 errors, 0 warnings, 14116 ms elapsed, cpu='X64 Regular'`.
- Coerencia versao: `EA_VERSION_STRING` 1.2.44, cabecalho `// XAU_AI_PRO v1.2.44`, `#property version "1.244"`.
- Inputs: 308 do grafico = 308 do binario.
- Journal do tester: `expert file added: Experts\XAU_AI_PRO\XAU_AI_PRO.ex5. 648973 bytes loaded`, `generating based on real ticks`, `initial deposit 200.00 USD, leverage 1:100`.
- Disco no arranque: 11 985 MB livres.

### O que este ciclo NAO prova
Nada sobre rentabilidade. Duas tentativas anteriores de 3 meses deram PF 0,81 e -34,68 no lado de M1-OHLC; esta corre com outro binario, outros inputs e ticks reais, logo e uma medida nova, nao uma continuacao. E um backtest unico, com um so simbolo, num so intervalo.

## Ciclo 23 - P1.20: o backtest estava a contaminar o ficheiro de onde o EA aprende

### Como apareceu
O plano era simples: arrancar o backtest de 3 meses, vigiar o disco, esperar. A meio da vigia, uma verificacao de rotina ao `Common\Files\trade_history.csv` mostrou o `mtime` a acompanhar o relogio do teste e tres linhas novas com data `2026.07.29` e `ATR/ADX/RSI/AI` a `0.00`.

O Strategy Tester estava a escrever no ficheiro de **producao**. `FILE_COMMON` resolve para a pasta comum verdadeira tambem dentro do tester, por isso nunca houve isolamento — e todos os backtests anteriores fizeram o mesmo.

### Porque e que isto e grave
`trade_history.csv` e a fonte de tres coisas que ja decidiram codigo:

- as bandas de ADX que fixaram `DynADXClear=35.0` (80 065 registos);
- as horas que fixaram `AvoidHoursGMT=9,11,14,18,20,22` (99 560 registos);
- o historico de aprendizagem (`EnableLearningFromHistory`).

Cada trade de backtest acrescenta linhas a essa base. Nao e um log: e a mataria de uma medicao.

### A correcao (v1.2.45)
`TradeLoggerFileName()` escolhe o destino: `trade_history_backtest.csv` sob `MQL_TESTER`/`MQL_VISUAL_MODE`, `trade_history.csv` no resto. `TradeLoggerOpen()` deixa de usar o literal. Lock F4, header, colunas e politica de DROP ficam iguais. Compilado: `0 errors, 0 warnings`.

Prova:
```
trade_history.csv           7498596 B  17:02:12   (parado)
trade_history_backtest.csv       51 B  17:10:02   (novo, header)
```

### A limpeza que nao se fez, e porque nao
Escrevi `purge_backtest_rows_p120.ps1` para cortar o bloco final (data <= 2026.10.29), com backup integral e abertura exclusiva. O script **abortou**, e fez bem:

```
linhas totais: 100239
ABORTADO: nenhuma linha com data >= 2026.10.30; nada removido
```

O ficheiro tem **689 dias distintos**, de `2024.01.02` a `2026.10.29`, e **zero** linhas de 30 ou 31/10/2026. Nao existe bloco simulado "no fim": o ficheiro inteiro e resultado de backtests antigos. Sem fronteira demonstravel, nao se corta. O backup ficou em `Files\Backup\trade_history_20261031_before_p120.csv`.

Este e o tipo de coisa em que a ferramenta certa e o abortar: um script que corta 679 linhas "com jeito" teria apagado a base de treino do EA em silencio.

### O agente pendurado
`tester_stop` devolveu `ok`, mas o `metatester64` do primeiro run ficou vivo com 4 920 MB e as duas relancagens seguidas morreram em 20-50 ms (`Core 1 disconnected`). Terminado o processo (PID 13196), o run seguinte arrancou de imediato. Fica como regra: depois de um `tester_stop`, verificar os processos `metatester64` antes de relancar.

### O que o log do tester revelou sobre o universo
Dentro de um teste **XAUUSD** o log imprime `[VIA RAPIDA] USDJPY`, `USDCAD`, `USDCNH` e `[RESUMO] master=SIM`. O backtest varre os 11 simbolos de `Symbols` e assume-se master; a producao tem 16 graficos, cada um no seu simbolo. **O backtest nao reproduz a topologia de producao.** Sempre que se citar o resultado, isto tem de ir junto.

### Validacao
- `Result: 0 errors, 0 warnings, 14329 ms elapsed, cpu='X64 Regular'` (v1.2.45).
- `EA_VERSION_STRING` 1.2.45, cabecalho `// XAU_AI_PRO v1.2.45`, `#property version "1.245"`.
- Isolamento confirmado por `mtime` de dois ficheiros diferentes.
- Run final `7702926785952690594` a simular `2026.07.29 03:55` as 17:11.
- Nenhum trade, risco ou filtro tocado: P1.20 e escrita de ficheiro, mais nada.

## Ciclo 24 - P1.21: a Regra 7 fechada, o trade_history passou a dizer quem abriu a operacao

### O que estava em aberto
A Regra 7 dizia uma coisa simples e nunca cumprida: uma linha do `trade_history.csv` tem de se poder atribuir a quem a abriu. O ficheiro tinha 10 colunas - `Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI` - e nenhuma delas responde a "foi este EA, foi a mao, foi outro robo?".

A consequencia nao era teorica. Toda a medicao que fixou `DynADXClear=35.0`, `DynADXStrong=35.0` e `AvoidHoursGMT=9,11,14,18,20,22` saiu desse ficheiro **sem poder separar o que era deste EA do que era de outra origem**. E o Ciclo 23 provou que o proprio Strategy Tester tinha estado a escrever ali. Duas fontes de contaminacao, nenhuma delas visivel na linha.

### A medicao que justificou a alteracao
Antes de tocar em codigo, contei o que existia:

| medida | valor |
|---|---|
| linhas no `trade_history.csv` de producao | 100 239 |
| dias distintos | 689 |
| primeiro dia | 2024.01.02 (36 linhas) |
| ultimo dia | 2026.10.29 (27 linhas) |
| linhas de 30-31/10/2026 | 0 |
| colunas de origem | 0 |

Zero colunas de origem em 100 239 linhas e em 689 dias. Nao e uma melhoria de estilo: e um campo causal em falta na base que decide inputs de risco.

O campo causal existe e e unico: `DEAL_MAGIC`. `2026001` e este EA por construcao (`MagicNumber`), `0` e ordem manual, qualquer outro valor e outro programa. `DEAL_POSITION_ID` da a ligacao ao historico do broker. Nao foi preciso inventar heuristica nenhuma.

### A alteracao (v1.2.46)
`TradeLogger.mqh`:

- o schema passou de 10 para **13 colunas** - `Ticket`, `Magic`, `Origin` acrescentadas no fim;
- `TradeLoggerOrigin(long dealMagic)` traduz o magic em `EA` / `MANUAL` / `OTHER`;
- `LogTradeCSV(...)` ganhou `ulong positionId` e `long dealMagic`;
- `XAU_AI_PRO.mq5` passou a enviar `DEAL_POSITION_ID` e `DEAL_MAGIC` do deal que fechou a posicao.

Acrescentar colunas no fim foi uma decisao verificada, nao uma esperanca: **nada dentro do EA le este ficheiro** (so o `BackupManager` o copia) e o leitor externo `Python/backtest/forward_test.py` usa `pd.read_csv` por cabecalho. Um ficheiro de 13 campos e lido sem alteracao por quem espera 10.

### Porque nao se misturou 10 com 13
O risco real desta alteracao era escrever 13 campos num ficheiro que ainda tem cabecalho de 10: o resultado seria um ficheiro partido de forma silenciosa, exactamente o tipo de estrago que ja obrigou a abortar a limpeza do Ciclo 23.

Duas protecoes, ambas testadas:

1. **Migracao offline antes de instalar o binario** - `migrate_trade_history_p121.ps1`, com backup integral e abertura exclusiva:

```
backup: ...trade_history_20261031_before_p121.csv  bytes=7498596
linhas: 100239
linhas de 10 campos: 99964   linhas com contagem diferente (ja partidas antes): 263
depois: linhas=100228   bytes=8500879
cabecalho novo: Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI,Ticket,Magic,Origin
exemplo: 2026.08.03 03:27:46,GOLD#,BUY,4063.09,4062.78,-1.51,0.00,32.20,0.00,0.00,,,UNKNOWN
```

As 11 linhas "a menos" sao linhas vazias finais. As linhas antigas ficam com `Ticket`/`Magic` vazios e `Origin=UNKNOWN` - nao se inventou origem para o passado; `UNKNOWN` e a resposta honesta e e distinguivel de `EA`.

2. **Guarda em runtime** - `TradeLoggerEnsureSchema()` corre sob o `EventLock` e decide tres casos: ficheiro vazio escreve o cabecalho novo; cabecalho com `Origin` nao faz nada; cabecalho antigo roda o ficheiro para `trade_history_legacy_v1.csv` (integralmente preservado) e comeca um novo. **Se a rotacao falhar, a escrita desliga** (`TradeLogger ERR | rotacao do schema falhou`) em vez de misturar 10 e 13 campos.

### Validacao
- `Result: 0 errors, 0 warnings, 15436 ms elapsed, cpu='X64 Regular'`; `XAU_AI_PRO.ex5` 654 234 B as 19:21:11.
- Coerencia de versao tripla: `EA_VERSION_STRING` 1.2.46, cabecalho `// XAU_AI_PRO v1.2.46`, `#property version "1.246"`.
- 16 graficos recarregados as 19:22:47 via ciclo de perfis; journal `[VERSION] v1.2.46 | Build=2026.10.30 | Stable=Yes | Modulos=15` nos 16 simbolos; `.chr` em disco `OK=16 BAD=0`.
- Nenhuma rotacao em producao foi precisa: `trade_history_legacy_v1.csv` nao existe porque a migracao offline deixou o cabecalho ja conforme.
- `1` aviso `TradeLogger WARN | schema sem lock (concorrencia)` no NZDUSD - esperado, 16 graficos arrancam no mesmo segundo.

### O que este ciclo NAO prova
Nenhum trade real escreveu ainda as tres colunas novas: o mercado estava fechado quando as 16 instancias recarregaram. O que esta provado e o cabecalho, a migracao sem perda, a compilacao e o arranque. A prova ponta-a-ponta (`Ticket`/`Magic`/`Origin=EA` numa linha escrita por um fecho real) fica para a proxima sessao de mercado ou para o proximo backtest - cujo arranque deve rodar o `trade_history_backtest.csv`, ainda com cabecalho de 10 colunas, para `trade_history_backtest_legacy_v1.csv`.

E, como sempre: isto e rastreabilidade, nao rentabilidade. O ficheiro passou a saber quem escreveu; nao passou a acertar mais.

## Ciclo 25 - P1.22: a coluna Symbol do trade_history estava a mentir

### Como apareceu
A vigia do backtest era rotina: ver progresso, ver disco, ver se o ficheiro de producao continuava parado. Ao ler as ultimas linhas do `trade_history_backtest.csv` apareceram precos que o ouro nunca teve:

```
2026.09.01 09:20:46,XAUUSD,BUY,1.39,1.39,0.00,0.00,0.00,0.00,0.00
2026.08.31 18:12:59,XAUUSD,SELL,9.58,9.58,-0.03,0.00,0.00,0.00,0.00
```

`XAUUSD` a 1.39 e a 9.58. E `Entry == Exit` em 164 de 166 linhas.

### Antes de mexer: medir o ficheiro inteiro
`Files\Backup\audit_symbol_price.ps1`, leitura apenas, 100 228 linhas de producao:

```
simbolos distintos: 63    (XAUUSD 80 380 | OILCash 2 988 | USDCNH 1 984 | GBPUSD 1 675 | ...)
linhas com symbol de OURO: 82 103
  ... Entry < 1000 (preco que nao e ouro): 10 916
  ... Entry == Exit: 58 027
linhas com symbol FX/outro: 18 006
  ... Entry > 1000 (preco que nao e FX): 14 043
```

Dez mil linhas dizem "ouro" com preco de outra coisa. A prova de mecanismo estava no mesmo segundo, em quatro simbolos, com o MESMO lucro:

```
2026.07.01 04:06:24,XAUUSD,SELL,1.32,1.32,-1.50,...,0.00,,,UNKNOWN
2026.07.01 04:06:24,USDJPY,SELL,1.324,1.324,-1.50,...,0.00,,,UNKNOWN
2026.07.01 08:48:49,GBPUSD,SELL,1.32429,1.32429,0.06,...,0.00,,,UNKNOWN
2026.07.01 08:48:50,USDCNH,SELL,1.32428,1.32428,0.04,...,0.00,,,UNKNOWN
```

Mesmo deal, mesmo preco, escalas diferentes: `1.32` (2 digitos), `1.324` (3), `1.32429`/`1.32428` (5). O que muda nao e o preco - e o `_Digits` de quem escreveu.

### A causa
Cada grafico recebe o `OnTradeTransaction` de todos os deals da conta e gravava-os todos. Mas `LogTradeCSV()` assinava a linha com `_Symbol`, formatava com `_Digits` e calculava `GetATR()/GetADX()/GetRSI()` **sem simbolo** - tudo do grafico, nada do deal. Num sistema de 17 graficos isso significa que a coluna `Symbol` era o nome de quem escreveu, nao do que foi negociado.

`Entry == Exit` nao era defeito: num deal de saida, `DEAL_PRICE` e o preco de fecho e `SYMBOL_BID` e o bid do mesmo instante. O que estava errado era a assinatura da linha.

### A correcao (v1.2.47)
`LogTradeCSV()` passou a receber `string symbol` (o `DEAL_SYMBOL`, que o `OnTradeTransaction` ja tinha) e a usar esse simbolo na coluna, em `SymbolInfoInteger(tlSymbol, SYMBOL_DIGITS)` e em `GetATR/GetADX/GetRSI(tlSymbol)`. Fallback explicito para `_Symbol`/`_Digits` se o simbolo vier vazio.

A duplicacao foi mantida de proposito: cada grafico continua a gravar todos os deals, para nao perder uma operacao cujo simbolo nao tenha grafico aberto. Desde o P1.21 o ficheiro tem `Ticket`, logo deduplicar passou a ser possivel sem se perderem linhas. Filtrar por simbolo seria uma segunda alteracao de comportamento que a medicao ainda nao sustenta - e este projecto nao muda duas coisas ao mesmo tempo.

### O erro que eu proprio introduzi
A primeira versao do patch usava `Write-Output` dentro de funcoes que devolviam texto. O PowerShell somou as mensagens ao valor devolvido e escreveu `OK alvo unico -> ...` **dentro** dos tres ficheiros. Detectado pela verificacao pos-escrita (`OKalvo=4`), nao pela compilacao. Os tres ficheiros foram restaurados dos backups e confirmados byte-a-byte:

```
TradeLogger.mqh    12396 B  identico_ao_backup=True
XAU_AI_PRO.mq5      74326 B  identico_ao_backup=True
VersionManager.mqh  20803 B  identico_ao_backup=True
```

A v2 usa `Write-Host` e trata "ocorrencias de lixo" como metrica de sucesso. Ficou mais uma regra pratica: antes de compilar, contar o que NAO devia estar no ficheiro.

### Detalhe que quase passou
`TradeLogger.mqh` tem fim-de-linha **LF-only** (501 loneLF, 0 CRLF), enquanto `XAU_AI_PRO.mq5` e CRLF (2240) e o `VersionManager.mqh` e CRLF (218). Um patch que assuma CRLF falha o alvo - o primeiro `Aplicar` devolveu 0 ocorrencias e abortou, que e exactamente o comportamento desejado. O script passou a detectar o EOL por ficheiro.

### Validacao
- `Result: 0 errors, 0 warnings, 16209 ms elapsed, cpu='X64 Regular'`; `XAU_AI_PRO.ex5` 655 126 B as 19:41:39.
- Versao tripla: `EA_VERSION_STRING` 1.2.47, cabecalho `// XAU_AI_PRO v1.2.47`, `#property version "1.247"`.
- Ciclo de perfis as 19:42: `[VERSION] v1.2.47 ... Modulos=15` em 17 fontes distintas; `.chr` `OK=16 BAD=0`.
- `TradeLogger inicializado` nas 17 instancias e **zero** linhas `MIGRACAO`: `trade_history.csv` parado em 8 500 879 B / 19:22:34.
- O backtest `7702926785952690594` atravessou a compilacao e o ciclo de perfis sem parar (`02:32:07 / 06:25:06`).

### O que este ciclo NAO prova
Nao ha ainda uma linha nova escrita com o simbolo correcto: mercado fechado e o backtest corre o binario anterior. E ha uma consequencia incomoda que fica registada: **as bandas de ADX e as horas que decidiram `DynADXClear=35.0` e `AvoidHoursGMT=9,11,14,18,20,22` vieram de agregacoes sobre um ficheiro com 10 916 linhas de simbolo errado.** A re-medicao deixa de ser higiene e passa a ser necessaria - mas so faz sentido depois de o ficheiro ter dias gravados com o simbolo do deal.

## Ciclo 26 - P1.23: o trade_history gravava o mesmo deal uma vez por grafico

**Data:** 31/10/2026, 20:01 (local)
**Versao:** 1.2.47 -> 1.2.48
**Estado:** aplicado, compilado (0 errors, 0 warnings), 17 instancias recarregadas

### Objetivo do ciclo

Fecha o que o P1.22 deixou encostado: o `trade_history.csv` tinha 100 228
linhas para um historico que o broker reconstroi em muito menos operacoes. Era
preciso medir se era repeticao e, se fosse, corrigi-la na origem.

### Medicao (`Files\Backup\audit_duplication.ps1`, so-leitura)

```
linhas validas             100 151
assinaturas distintas       42 850   (chave Time|Type|Profit)
assinaturas com >1 linha    14 549
fator de duplicacao medio     2,34
linhas "a mais"             57 301   (57%)
picos de multiplicidade     2, 10, 17
```

17 e o numero de graficos com o EA. Cada grafico recebe o mesmo
`OnTradeTransaction` da conta inteira e escrevia todos os deals - a
serializacao do P1.16 resolveu o interleave, nao a repeticao. O 2,34 e limite
inferior (duas operacoes distintas podem colapsar na mesma assinatura, porque as
linhas antigas nao tem `Ticket`).

### Alteracao

`Monitoring\TradeLogger.mqh`:

- guarda de simbolo **antes de qualquer I/O**: cada grafico grava so os deals do
  seu `_Symbol`; o resto incrementa `g_tl_skipped` e sai;
- guarda **desligada no tester** (`!MQLInfoInteger(MQL_TESTER)`), onde ha uma so
  instancia e o teste de XAUUSD tambem negoceia outros simbolos (§27.8);
- declaracoes de `tlSymbol`/`tlDigits` subiram para o topo (ficou 1 ocorrencia);
- `TradeLoggerSummary()` passou a publicar `OutroSimbolo=%d` e a usar
  `TradeLoggerFileName()` - antes dizia `File=trade_history.csv` mesmo no tester.

`XAU_AI_PRO.mq5` e `Enterprise\VersionManager.mqh`: bump para 1.2.48 (cabecalho,
`#property version "1.248"`, `EA_VERSION_STRING`) + changelog com a medicao.

### Verificacao

```
TradeLogger.mqh      13492 -> 15406 B   NUL=0  CRLF=0  loneLF=534  lixo=0
XAU_AI_PRO.mq5       74387 -> 74387 B   NUL=0  CRLF=2240 loneLF=2   lixo=0
VersionManager.mqh   22255 -> 23682 B   NUL=0  CRLF=218  loneLF=0   lixo=0

Result: 0 errors, 0 warnings, 16990 ms elapsed, cpu='X64 Regular'
ex5: 655980 B  10/31/2026 20:00:41
```

- 17 graficos em `[VERSION] v1.2.48`, `Modulos=15` OK;
- 17 `TradeLogger inicializado`, **0** linhas `MIGRACAO` (nenhuma rotacao);
- 1 `WARN | schema sem lock` no USDRUB no arranque simultaneo (esperado);
- `.chr`: 16/16 com o EA no perfil `XAI_V1243_20261031`;
- `trade_history.csv` **parado** em `8 500 879 B / 19:22:34`; o backtest escreveu
  em `trade_history_backtest.csv` (`11 557` -> `12 590 B`).

### Incidencia durante o ciclo

A v1 do script abortava por uma expectativa errada (passo 3 esperava 2
ocorrencias do bloco de declaracao, mas o bloco termina em
`double atr = GetATR(tlSymbol);` e por isso so existe uma vez - a do corpo). O
abortar foi o comportamento desejado: **nenhum ficheiro foi escrito**. A v2
corrigiu a expectativa e passou com `alvo unico` em todos os passos e `lixo=0`
nos tres ficheiros.

### Aberto

- Prova ponta-a-ponta (uma linha por deal, simbolo do deal, `Ticket`/`Magic`/
  `Origin`) continua a exigir mercado aberto ou um backtest com o binario novo.
- Re-medir bandas de ADX e horas com janela limpa de 2-3 dias: o ficheiro antigo
  tem Symbol errado em >= 10 916 linhas **e** duplicacao >= 2,34x.
- Backtest `7702926785952690594` continuou a correr durante tudo
  (`02:46:22 / 06:12:11` registado a meio do ciclo).

## Ciclo 27 - P1.24: EA autonomo 24/7 - o watchdog deixou de morrer ao fim de semana

**Data:** 31/10/2026, 20:16 (local)
**Versao:** 1.2.48 -> 1.2.49
**Estado:** aplicado, compilado (0 errors, 0 warnings), 17 instancias a correr

### Objetivo

Pedido: estudar, pesquisar e melhorar o EA autonomo 24/7. Regra do projecto:
aplicar so o que a medicao sustentar.

### O que foi pesquisado (fontes primarias MQL5)

`TimeCurrent()` = hora do ultimo tick; `TimeTradeServer()` = estimativa no
cliente (0 se desconhecida); `OnTimer` e gerado pelo terminal e nao pela chegada
de ticks; **nao existe API de reconexao** (reconexao e do terminal, logo o EA so
pode alarmar); `TERMINAL_CONNECTED` nao garante cotacoes sincronizadas (somar
`SymbolIsSynchronized`); sessoes via `SymbolInfoSessionTrade/Quote`.

### O que foi medido

Sabado, mercado fechado desde sexta 23:59:

- `trade_server_last_known_time = 2026-10-30T23:59:59` vs local `2026-10-31 20:01`
  -> `TimeCurrent()` parado ha ~20 h;
- `Logs\20261031.log`: 726 linhas, **0** blocos de `HEALTH MONITOR` (contra
  900 KB de journal no dia anterior, com mercado).

Causa: `g_lastHealthCheck`/`g_lastTickTime` carimbados com `TimeCurrent()` ->
`now - g_lastHealthCheck` = 0 para sempre -> o health check nunca mais corre.

### Alteracao

`Monitoring\HealthMonitor.mqh`:

- `HealthClockNow()` = `TimeLocal()` para **duracoes** (intervalo entre checks,
  idade do ultimo tick, `HealthGetSecondsSinceTick`);
- `HealthSessionNow()` = `TimeTradeServer()` (fallback `TimeCurrent()`) para
  decidir se ha **sessao aberta**;
- tudo o que e de mercado (sessoes de negociacao, horas de evasao, reset diario)
  continua em `TimeCurrent()`;
- cabecalho do modulo actualizado (estava em v1.2.9).

`XAU_AI_PRO.mq5` + `Enterprise\VersionManager.mqh`: bump triplo para 1.2.49 com
changelog contendo a medicao.

### Verificacao

```
HealthMonitor.mqh    24192 -> 26818 B   NUL=0  CRLF=925   loneLF=0  lixo=0
XAU_AI_PRO.mq5       74387 -> 74387 B   NUL=0  CRLF=2240  loneLF=2  lixo=0
VersionManager.mqh   23682 -> 25351 B   NUL=0  CRLF=218   loneLF=0  lixo=0

Result: 0 errors, 0 warnings, 16542 ms elapsed, cpu='X64 Regular'
ex5: 658030 B  10/31/2026 20:15:54
```

Prova funcional **sem nenhuma cotacao** (sabado, 20:16-20:17): 17 graficos
imprimem `[HEALTH] HEALTHY | uptime=0s | checks=0 | sem tick=30s` e o bloco
`========== HEALTH MONITOR ==========`. Antes: zero blocos em 20 h. O estado e
**HEALTHY**, ou seja a sessao passou a distinguir sabado de falha.

### Incidencia

1 warning na primeira compilacao (85: `20261031` too big for character code)
porque `Logs\20261031.log` dentro de um literal MQL5 e escape octal.
Corrigido com `Logs\\20261031.log` e recompilado a 0 warnings.

### Aberto (registado, nao aplicado por falta de medicao)

- `SymbolIsSynchronized` nunca e consultado: apos reconexao o EA pode decidir
  sobre cotacoes dessincronizadas.
- `GlobalVariable*` expira ao fim de ~4 semanas (locks curtos e marca de import:
  impacto maximo = um re-import).
- Notificacao ao dono (NotificationCenter) nao foi exercitada.
- Backtest `7702926785952690594` continua no binario anterior.

## Ciclo 28 - P1.25: o portao de diagnostico passou a abafar CICLOS, nao so repeticoes (v1.2.50)

**31/10/2026** · O Ciclo 27 fechou o relogio do watchdog. Este ciclo nasceu de
uma pergunta diferente: se o EA tem de viver 24/7, o **journal** aguenta? A
resposta medida foi nao.

### O que se mediu, e onde

`Tester\logs\20261031.log` — o journal real do backtest em curso, 4 186 295
linhas / 1 121 MB, lido em modo partilhado porque o `terminal64` o mantem
aberto (`[IO.File]::Open(..., FileShare::ReadWrite)`).

Duas ferramentas novas, ambas so-leitura, em `Files\Backup`:

- `audit_segment_risk.ps1` — segmenta o ficheiro pelos cabecalhos `[VERSION]`
  (o log do tester e **por dia** e anexado por todos os runs) e conta
  `[STATE]`/`[RISK]`/`RR` em cada segmento;
- `audit_p125_replay.ps1` — replica, linha a linha, a sequencia de decisoes do
  portao antigo e do novo sobre o journal de producao.

A segmentacao provou que o run actual (v1.2.45) tem 1 191 304 linhas, das
quais **335 843 sao `[STATE]` = 28,2% de todo o output**.

### A causa

O `DiagGate` do P1.17 comparava o desfecho apenas com o **ultimo** registado.
Num ciclo `A -> B -> C -> A -> B -> C` cada aresta difere da anterior — difere
da anterior nao quer dizer que seja **nova**. O portao libertava tudo.

### A prova, por replicacao

Nao foi estimado. `audit_p125_replay.ps1` aplica as duas versoes do algoritmo
aos mesmos 249 592 eventos reais:

| Portao | Linhas escritas |
|---|---|
| OLD (v1.2.49) | 249 592 (0% de reducao) |
| NEW (v1.2.50) | **751 (99,7% de reducao)** |

**332x menos linhas `[STATE]`.** Com `[STATE]` a 28,2% do output, o log de
1,1 GB passa a rondar os 0,8 GB — ~300 MB por run desta dimensao.

### A correccao

`DIAG_GATE_SEEN 8` desfechos por chave (`simbolo|tag`), janela ancorada em
`windowStart` e medida com `TimeLocal()` (a licao do P1.24), esquecimento do
mais antigo quando enche, e `heartbeatSec = 0` deixa de ser silencio total
para usar `DIAG_GATE_WINDOW_DEFAULT 60 s` — sem janela, o ciclo voltava a
escrever em cada tick. As transicoes para `EXECUTION_READY` ou superior
continuam a imprimir sempre, antes do portao, no call site.

Auto-teste `DiagGateSelfTest.mq5` ganhou o bloco C1..C4: ciclo de 3 estados
escreve 3 linhas e depois cala, mesmo com 3 000 voltas; aresta nova continua
a sair. Compilado 0/0.

### Uma hipotese minha foi DESCARTADA pela medicao

Eu tinha escrito em §32 que o `[RISK]` sofria do mesmo defeito (61 439 linhas
para 188 distintas). A segmentacao mostra o contrario: das 83 478 linhas
`[RISK]` do run actual, apenas **168** sao `RR da entrada`. O portao do P1.17
**ja funcionava** para esses call sites, porque o desfecho guardado e compacto
(`SL|TP`) e nao o texto. O defeito era exclusivo do `[STATE]`, cujo desfecho e
o texto da aresta e muda sempre.

Replicando o portao sobre o `[RISK]`: OLD 451 linhas, NEW 423. Ganho 1,1x.
Nenhum. O P1.25 nao foi dimensionado para o que eu supunha — foi dimensionado
para o que a medicao mostrou.

### Resultado

| Item | Valor |
|---|---|
| `DiagGate.mqh` | 5 738 -> 8 361 B (loneLF=210, LF-only) |
| `DiagGateSelfTest.mq5` | 4 402 -> 5 993 B |
| `VersionManager.mqh` | 25 351 -> 26 677 B |
| Compilacao | **0 errors, 0 warnings**, 15 715 ms |
| ex5 | 660 824 B as 20:29:42 |
| Instancias | **17 em v1.2.50** as 20:29:51-20:30:00 |
| `.chr` do perfil | 16/16 OK (BOM `FF FE` + `<chart>`) |

### Armadilha de ferramenta

A primeira versao do replicador leu o journal como UTF-8 e devolveu **0 linhas
`[STATE]` em 948 873 linhas lidas**. O journal do tester e **UTF-16LE com BOM
`FF FE`**. Um zero assim nao e um resultado — e um defeito do leitor. Passou a
ser regra: medir os bytes de cabecalho antes de aceitar qualquer contagem.

### O que NAO mudou

Nenhuma regra de trading, risco, execucao ou precificacao. O portao decide
apenas se uma linha de diagnostico volta a ser escrita.

## Ciclo 29 - P1.26/P1.27: as duas linhas que ainda enchiam o journal nao tinham portao (v1.2.51)

**31/10/2026** · O Ciclo 28 tirou 28,2% do journal. Este ciclo perguntou o que
sobra. A resposta foi: duas linhas que nunca tiveram portao nenhum.

### Como se mediu

`Files\Backup\audit_top_offenders.ps1` agrupa cada linha pelo prefixo da
mensagem — a parte depois do carimbo de tempo de **modelo**, truncada a 70
caracteres — e conta. Amostra: 1 121 MB / 4 186 295 linhas. Top 30 =
**1 571 299 linhas = 37,53%** de todo o output.

O perfil mostrou o que se esperava (as `[STATE]` do P1.25 no topo) e o que nao
se esperava:

```
121 076 (2,89%)  [NEWS] Calendar error | Error=4014
 58 310 (1,39%)  [RISK] alvo elevado para respeitar o RR minimo ...
```

### O erro 4014 nao era um bug — era o tester a dizer "nao"

Em vez de assumir, foi lida a tabela oficial de erros MQL5
(`mql5.com/en/docs/constants/errorswarnings/errorcodes`):

```
ERR_FUNCTION_NOT_ALLOWED  4014  Function is not allowed for call
```

A chamada ao calendario **nao e permitida dentro do Strategy Tester**. Nao e
avaria do EA nem do broker: e uma condicao permanente do teste. O EA estava a
imprimir 121 076 linhas de erro para descrever uma situacao que nunca ia
mudar, e a fazer `fail-open` correctamente em todas elas.

A correccao separa os dois casos: `4014` imprime **uma** linha explicativa por
sessao (flag `static`); qualquer outro erro de calendario continua visivel,
abafado a 1 linha por 4 h por `DiagGateAllow`. Fora do tester o comportamento
do filtro e exactamente o mesmo.

### O alvo minimo do RR

`[RISK] alvo elevado para respeitar o RR minimo` imprimia em cada passagem
pelo bloco que eleva `tpPontos` a `slPontos * MinRewardRatio`. O desfecho util
e `TP|alvo` — a mesma forma que o `RR_ENTRADA` ja usava com sucesso (168
linhas no run inteiro, contra 38 605 do texto bruto). Passou a usar
`DiagGateAllow(symbol, "ALVO_RR", TP|alvo, 14400)`.

**Detalhe que nao pode falhar:** `tpPontos=alvoMinimo;` ficou **fora** do
portao. O portao decide se a mensagem e escrita; a elevacao do alvo e decisao
de risco e acontece sempre.

### Ganho

| Linha | Antes | Depois |
|---|---|---|
| `[NEWS] Calendar error \| Error=4014` | 121 076 | 1 por sessao |
| `[RISK] alvo elevado ...` | 58 310 | 1 por chave / 4 h |
| **Total** | **179 386 (4,29%)** | ~0 |

O "depois" e **previsao**, nao medicao — sera confirmado no proximo backtest
com o mesmo `audit_top_offenders.ps1`. Essa e a diferenca entre este ciclo e
os que prometiam ganhos sem os medir.

### Resultado

| Item | Valor |
|---|---|
| `NewsFilter.mqh` | 13 176 -> 14 273 B (+`#include DiagGate`) |
| `ExecutionEngine.mqh` | 40 986 -> 41 448 B |
| `VersionManager.mqh` | 26 677 -> 27 928 B |
| Compilacao | **0 errors, 0 warnings**, 15 732 ms |
| ex5 | 663 754 B as 20:43:24 |
| Instancias | **17 em v1.2.51** as 20:43:31-20:43:41 |

### O que ficou por medir, de proposito

`EXECUTION: SEM STOP NA ENTRADA` (66 086) e `EXECUTION WARNING | FORCA LOTE
MINIMO` (~75 000) **tem** portao (`SEM_STOP`, `LOT_MIN`) e continuam a
aparecer em massa. A hipotese e que o desfecho inclua valores que variam (TP,
lote) e que o conjunto de desfechos na janela seja maior do que as 8 posicoes
do P1.25. **Nao foi mexido por nao estar medido.** A proxima auditoria ao
journal de um run com v1.2.51 decide entre alargar a memoria, mudar a chave do
desfecho, ou nao fazer nada.

### O que NAO mudou

Nenhuma regra de trading, risco, execucao ou precificacao.

## Ciclo 30 - P1.28/P1.29: medir por segmento mudou o alvo (v1.2.52)

**31/10/2026** · Os ciclos 28 e 29 tiraram 39,22% do journal. Este ciclo
comecou por perguntar "o que sobra" e acabou por descobrir que a pergunta
anterior estava mal formulada.

### O erro de metodo que este ciclo corrigiu

O §34 contou linhas sobre o **ficheiro inteiro** do journal do tester. Mas
`Tester\logs\<data>.log` e **por dia** e e **anexado por todos os runs desse
dia** — e ~2,97 M linhas do inicio estao **antes do primeiro cabecalho
`[VERSION]`**, produzidas por um binario que nem tinha os call sites do
`DiagGate`.

Resultado: as percentagens misturavam ruido de um binario antigo com ruido de
um binario ja corrigido, e a atribuicao estava errada.

Duas ferramentas novas resolvem isto, ambas so-leitura:

- `audit_top_offenders_last.ps1` — reseta a contagem em cada `[VERSION]`, logo
  no fim fica com o perfil do **ultimo run**;
- `audit_last_segment_totals.ps1` — totais por grupo, so no ultimo run.

### O perfil honesto (v1.2.45, 1 234 648 linhas)

```
[STATE]                     347 741  28,17%   portao ineficaz -> P1.25
[VIA RAPIDA]                131 227  10,63%   SEM portao      -> P1.28
[RISK] alvo elevado RR       84 551   6,85%   SEM portao      -> P1.27
[PIPELINE]                   57 473   4,66%   1/min por desenho
[NEWS] Calendar error 4014   51 993   4,21%   SEM portao      -> P1.26
[LADDER]                     32 753   2,65%   P1.18
EXECUTION: APRENDIZADO       13 228   1,07%   SEM portao      -> P1.29
```

O numero 1 da lista que eu nao conhecia — `[VIA RAPIDA]`, 10,63% — nao tinha
portao nenhum: uma linha por simbolo a cada `PulseFastLaneSec` (5 s) de tempo
de modelo, sempre que o regime nao e `PULSE_NORMAL`.

### Uma hipotese minha DESCARTADA pela medicao

No §34.6 eu escrevi que `SEM STOP NA ENTRADA` e `FORCA LOTE MINIMO` saiam em
massa **apesar** de terem portao, e que a culpa seria da chave do desfecho
conter valores variaveis.

`audit_p125_gated.ps1` reconstroi as chaves reais a partir do codigo e replica
os dois portoes:

```
familia        hb    linhas  desfechos   OLD->NEW
LOT_MIN      3600     48479          1     67->67
LOTE_DIN    14400     69316          5    117->69
RISCO_REAL  14400     69316         96    172->141
SEM_STOP    14400     69316          3    117->69
```

`LOT_MIN` tem **um unico** desfecho no run inteiro: o portao do P1.17 ja o
reduz a 67 linhas. As 48 479 do ficheiro vinham da porcao anterior ao portao.
**Nao havia nada a corrigir** — e sem esta medicao eu teria mexido em codigo
que ja estava certo.

### As duas correccoes aplicadas

**P1.28 `[VIA RAPIDA]`** (`TradePipeline.mqh`): chave do desfecho = o
**regime**. O volume e a velocidade mudam a cada tick e nao podem servir de
chave — usa-los daria supressao zero. Heartbeat 3 600 s.
`RunTradePipelineSymbol(symbol)` ficou **fora** do portao.

**P1.29 `EXECUTION: APRENDIZADO`** (`ExecutionEngine.mqh`): chave = o proprio
`learnLot` (2 decimais), porque e o valor que reduz o lote. Heartbeat 14 400 s.
`slowFactor *= learnLot;` ficou **fora** do portao.

### Ganho acumulado medido neste run

| Correcao | Linhas | % do run |
|---|---|---|
| P1.25 `[STATE]` | 347 741 | 28,17% |
| P1.26 `[NEWS] 4014` | 51 993 | 4,21% |
| P1.27 alvo elevado RR | 84 551 | 6,85% |
| P1.28 `[VIA RAPIDA]` | 131 227 | 10,63% |
| P1.29 `APRENDIZADO` | 13 228 | 1,07% |
| **TOTAL** | **628 740** | **50,93%** |

O journal deste run perde **mais de metade** do que escrevia.

### Resultado

| Item | Valor |
|---|---|
| `TradePipeline.mqh` | 6 249 -> 6 876 B (+`#include DiagGate`) |
| `ExecutionEngine.mqh` | 41 448 -> 41 926 B |
| `VersionManager.mqh` | 27 928 -> 29 132 B |
| Compilacao | **0 errors, 0 warnings**, 16 339 ms |
| ex5 | 664 262 B as 20:50:24 |
| Instancias | **17 em v1.2.52** as 20:50:34-20:50:41 |

### Ressalva que tem de acompanhar estes numeros

O backtest em curso (`7702926785952690594`) corre **v1.2.45** e continua com
esse binario ate terminar. **Nenhuma das correccoes P1.25 a P1.29 pode ser
provada por ele.** O que esta provado e a logica (auto-teste C1..C4, 0/0), o
efeito no `[STATE]` (replicacao exacta: 249 592 -> 751) e a atribuicao do
ruido (segmentacao por run). A confirmacao final exige **um novo backtest com
v1.2.52**.

### O que NAO mudou

Nenhuma regra de trading, risco, execucao ou precificacao. As cinco correccoes
deste conjunto decidem apenas se uma linha de diagnostico volta a ser escrita.

## Ciclo 31 — P1.30 (v1.2.53): churn do LADDER e eco do PIPELINE

**Objectivo:** cortar o ruído de journal que resta sem tocar em nenhuma regra de trading.

**O que foi medido antes de mexer**

- `audit_p130_pipeline_ladder.ps1` (novo, só-leitura): no último segmento v1.2.45 do journal do
  tester (1 252 528 linhas), `[PIPELINE]` = 59 480 linhas / 13 formas (4,75%) e `[LADDER]` =
  33 213 / 32 formas (2,65%). Top `[PIPELINE]`: `FINALIZADO` 26 979 e `INICIO|Symbols=#` 26 979.
- `audit_p130_ladder_churn.ps1` (novo, só-leitura): reconstrução por ticket das 88 287 linhas
  `[LADDER]` → **444 tickets**, média **198,84 linhas/ticket**, máximo **7 315** num só ticket.
  Simulação de banda morta: 1× = 49,91% · 2× = **95,98%** · 3× = 97,45% · 5× = 98,16% · 10× = 98,51%.
  O degrau 1×→2× prova que era ruído de recálculo do TP em dinheiro (deriva 1–2 pontos por passagem),
  não alvo a mover-se.

**O que foi alterado**

- `Management/MoneyLadder.mqh`: tolerância do TP passou a `MathMax(point * 0.5, minDist)`, com
  `minDist = max(stops_level, freeze_level) * point` e nunca abaixo de 2× spread. O SL continua a
  sair sempre que muda (`slSame` mantém meia ponta); SL para a entrada a 1R, trava e fecho do alvo em
  dinheiro intactos. 12 675 → 14 007 B.
- `Core/TradePipeline.mqh`: `[PIPELINE] INICIO` e `FINALIZADO` passaram a `DiagGateAllow` com
  heartbeat 3600. `RunTradePipelineSymbol` e `ProcessSymbol` ficaram fora do portão. 6 876 → 7 576 B.
- `XAU_AI_PRO.mq5` e `Enterprise/VersionManager.mqh`: bumps até v1.2.53 (cabeçalho, `#property
  version "1.253"`, `EA_VERSION_STRING`) + changelog com os números medidos. 74 387 B e
  29 132 → 30 638 B.

**Validação**

- `apply_p130_ladder_pipeline.ps1` (novo, 7276 B): `OK alvo unico` em todas as substituições,
  NUL=0 e lixo=0. A 1.ª execução falhou (`ALVO NAO UNICO ... encontrados 0`) por LF do here-string
  contra CRLF do ficheiro; corrigido normalizando dentro de `Troca`.
- Compilação: **0 errors, 0 warnings**, 15 928 ms; `.ex5` 665 506 B às 20:59:46.
- Recarga do terminal: `profile_apply Default` → `profile_apply XAI_V1243_20261031`; journal do
  terminal mostra 17 experts removidos e 17 carregados; journal Experts mostra a troca
  **v1.2.52 → v1.2.53** às 20:59:54.858; `count_instances_version.ps1` confirma **17 fontes
  distintas em v1.2.53**.

**Duas medições falsas corrigidas neste ciclo (erro de método)**

1. `Logs\<data>.log` é o journal do **terminal**, não contém `Print()` do EA — o output do EA está em
   `MQL5\Logs\<data>.log`. Contar `[VERSION]` no primeiro dá sempre zero.
2. Esse zero era **defeito do leitor**: `[IO.File]::ReadAllText` lança `IOException` com o ficheiro
   aberto pelo `terminal64`, a exceção deixou a string vazia e a contagem saiu 0. Corrigido com
   `[IO.File]::Open(..., [IO.FileShare]::ReadWrite)` + `StreamReader` Unicode → 1 097 linhas lidas.

**Ganho**

P1.30 ≈ 86 700 linhas de LADDER evitadas + 53 958 de PIPELINE, sobre um run de 1 252 528 linhas.
Somado ao já aplicado: P1.25 347 741 + P1.26 51 993 + P1.27 84 551 + P1.28 131 227 + P1.29 13 228.

**Ressalva**

O backtest `7702926785952690594` corre **v1.2.45** e não pode provar nada disto. A prova veio de
replicações sobre o journal real, do auto-teste C1..C4 do `DiagGate` e da contagem de fontes por
versão. A confirmação final exige um novo backtest com v1.2.53.

**Estado do run vigiado**

`7702926785952690594`, agente `Core 1`, `started`, progresso a evoluir (03:51:31 de ~06:30–06:45).
Disco livre 9,1 GB — longe do limiar de ~2 GB. Ciclo de perfis durante o run não o interrompeu.

## Ciclo 32 — P1.31 (v1.2.54): o universo SEM tag (38,31%)

**Objectivo.** Atacar a maior fatia restante do journal do tester: as linhas que
não têm tag nenhuma e que, por isso, nunca apareciam nos rankings por tag.

**O que foi medido.** `audit_p131_untagged.ps1` (só-leitura) sobre o último
segmento do run: 1 287 596 linhas com carimbo, 493 255 sem tag = **38,31%**,
627 formas distintas. Top: `[LEARN] historico verificado` 158 294 (12,29%) e o
par `[COST] BLOQUEADO` + `EXECUTION: CUSTO BLOQUEADO` 64 494+64 494 e
14 112+14 112 (12,2% juntos).

**O que foi alterado.** Três ficheiros, todos com `DiagGateAllow`, nenhum a
tocar em trading/risco:

- `AI/LearningHistory.mqh` — resumo sempre que há deal novo, 1×/hora por
  símbolo quando não há (`LEARN_VERIF`/`sem_novos`, 3600 s);
- `Filters/CostGate.mqh` — `[COST] BLOQUEADO` chaveado pelo MODO de bloqueio
  (`COST_BLOCK`/`ALVO+RISCO|RISCO|ALVO`, 14400 s);
- `Core/ExecutionEngine.mqh` — a linha que repetia o mesmo bloqueio passou a
  `CUSTO_BLOQ`/`BLOQUEADO`, 14400 s;
- versão: `// XAU_AI_PRO v1.2.54`, `#property version "1.254"`,
  `EA_VERSION_STRING "1.2.54"` + changelog com os números medidos.

**Validação.** 1.ª compilação: **101 erros** em `VersionManager.mqh(63)` —
a costura do changelog ficou aberta (texto antigo fora da string). Diagnóstico
por coluna: todos os erros acima da coluna 1340, isto é no texto antigo, logo o
defeito era só a aspa de ligação. `fix_p131_changelog.ps1` inseriu `" +` e
reabriu a aspa: 31980→32010 B, NUL=0. Recompilado:
`Result: 0 errors, 0 warnings, 15783 ms`, ex5 666 154 B.

**Prova de recarga.** `profile_apply Default` → `profile_apply
XAI_V1243_20261031`; `count_instances_version.ps1`:
**v1.2.54 → 17 fontes distintas** (v1.2.40/41 = 15, 42/43 = 16, 44..54 = 17).

**Ganho.** ≈ 315 506 linhas medidas no perfil de ruído (~24,5% do run).
Somado ao P1.25–P1.30, o journal fica com cerca de três quartos do volume
original.

**Ressalva.** O run 7702926785952690594 continua a correr v1.2.45; não prova
nada destas correções. A prova vem do auto-teste, da replicação e da troca de
binário em 17/17 — a confirmação final exige um novo backtest com v1.2.54.

**Estado do run vigiado.** `started`, agente 'Core 1', 03:55:49 / 06:30:25.
Disco livre 9,08 GB (limiar de acção ~2 GB). O ciclo de perfis não interrompeu
o run.

## Ciclo 33 — P1.32 (v1.2.55): o INFO do CTrade da biblioteca

**Objectivo.** Fechar a fatia de linhas sem tag que vem da biblioteca standard,
não do EA.

**Medido.** `CTrade::OrderSend modify position` 32 505 linhas (USDCAD 10 593,
USDJPY 8 721, USDSEK 5 406, USDCHF 3 904, USDCNH 3 881) + `position modified`
13 187 (USDCAD 7 194, USDJPY 3 535, USDSEK 2 458) = **45 692 linhas (3,55%)**,
todas INFO duplicado: o EA já registra o retcode e o `TradeLogger` grava a
execução em CSV.

**Causa.** `CTrade` arranca com `m_log_level = LOG_LEVEL_ALL`
(`Include\Trade\Trade.mqh:168`).

**Alterado.** `trade.LogLevel(LOG_LEVEL_ERRORS);` em `XAU_AI_PRO.mq5` e em
`Core\OrderManager.mqh` (os dois pontos de init). Erros da biblioteca continuam
a sair; INFO deixa de sair. Nenhuma regra de execução/risco mudou.

**Descartado por medição (não é ruído).** `[SESSION] estado salvo` (11 207) —
já tem throttle de 300 s, é prova de persistência. `[RESUMO]` (≈16 750) — é o
operator brief autónomo, funcionalidade. `[LOGGER OFFLINE]` (5 156+5 156) — é a
única saída quando o logger está em baixo; portajar esconderia o pior caso.

**Validação.** `apply_p132.ps1` com `OK alvo unico` em 7 trocas; mq5 74387→74802
B, OrderManager 4635→4849 B, VersionManager 32010→32788 B, NUL=0;
`Result: 0 errors, 0 warnings, 15624 ms`, ex5 667 770 B.
Recarga por `profile_apply Default` → `XAI_V1243_20261031`:
**v1.2.55 → 17 fontes distintas** (a 1.ª contagem deu 16 porque um gráfico ainda
não tinha tido o primeiro tick; 35 s depois fechou 17/17).

**Estado do run vigiado.** 7702926785952690594 `started`, agente 'Core 1',
03:58:41 / 06:34:31. Disco livre 9,08 GB. O ciclo de perfis não o interrompeu.
Continua em v1.2.45: não prova P1.25–P1.32; a confirmação exige novo backtest
com v1.2.55.


---

## Ciclo 34 — P1.33 (v1.2.56): o aviso de exposição era um estado, não um evento

**Quando:** 31/10/2026, 21:39–21:43 (local) · **Versão:** v1.2.55 → **v1.2.56**

### Objectivo
Encontrar, por medição, o próximo maior emissor de ruído depois de P1.25–P1.32 e reduzi-lo sem tocar em risco.

### Medido (novo nesta ronda)
- `audit_live_v1255.ps1`: 9 343 linhas desde o 1.º `[VERSION] v1.2.55`; **6 647 sem tag (71%)**, mas todas do **banner de arranque** (`====`, `[N] SIMBOLO`, `=== RECOVERY STATUS ===`, `SYMBOL MANAGER | Resolved`).
- `audit_restarts_v1255.ps1`: os 80 `[VERSION] v1.2.55` estão **todos às 21:09** → sem reinicializações periódicas.
- `audit_steady_v1255.ps1`: **0 linhas** com hora ≥ 21:15 → **31/10/2026 é sábado, mercado fechado**, logo o regime estacionário só existe no Strategy Tester.
- `count_needles_tester.ps1` (journal do tester, **4 521 967 linhas**): `[SAFETY] Exposure limit` = **35 572** — o maior que sobrou; `LOT CAP REAL` = 2 233; `[SESSION] nada a restaurar` = 0.

### Alterado
- `Enterprise\SafetyManager.mqh`: throttle do aviso de exposição **60 s → 1800 s** (+ comentário com os números medidos). `return false` e toda a lógica de risco iguais.
- `XAU_AI_PRO.mq5`: cabeçalho e `#property version "1.256"`.
- `Enterprise\VersionManager.mqh`: `EA_VERSION_STRING "1.2.56"` + changelog.

### Validação
- `apply_p133.ps1`: "OK alvo unico" em 4 substituições; SafetyManager 19038 B, mq5 74802 B, VersionManager 33430 B, **NUL=0 loneLF=0** em todos.
- Compilação: `Result: 0 errors, 0 warnings, 16471 ms`, ex5 **667 822 B** (21:42:25).
- Recarga `Default` → `XAI_V1243_20261031`: **v1.2.56 = 17 fontes distintas**.

### Ganho
≈ **34 386 linhas** no segmento do tester (35 572 → ≈1 186), 0,76% do total do journal medido.

### Estado do run vigiado
`7702926785952690594`, agente `Core 1`, `started`, progresso **04:29:25 / 05:52:10** (o ETA baixou de 06:36:20 — a estimativa do tester não é linear). Disco livre **8,95 GB**.

### Ressalva
O run em curso usa v1.2.45; o ganho de P1.33 só se confirma num novo backtest com v1.2.56.


---

## Ciclo 35 — P1.34 (v1.2.57): portões neutralizados por desfecho variável

**Quando:** 31/10/2026, 23:15–23:24 (local) · **Versão:** v1.2.56 → **v1.2.57**

### Objectivo
Continuar a caça ao ruído por medição, agora verificando não só *se* existe portão mas *se ele abafa*.

### Medido (`count_needles_tester.ps1`, journal do tester, **5 077 002 linhas**)
| linha | linhas |
|---|---|
| `EXECUTION: LOTE DINAMICO` | 177 619 |
| `EXECUTION WARNING \| FORCA LOTE MINIMO` | 147 241 |
| `LOT CAP REAL` | 2 233 |
| `EXECUTION: ` (todas) | 801 191 |
| `[SAFETY] Exposure limit` | 35 572 |

### Causa
`LOTE_DIN` usava `ConvictionGradeName(gradeOut) + "|" + DoubleToString(lot,3)` e `LOT_MIN` usava `DoubleToString(lot,3) + "|" + DoubleToString(minLot,3)` como **desfecho**: valores que mudam por candidato → o conjunto nunca repete → o portão liberta tudo. `LOT CAP REAL` não tinha portão. É a violação da regra do P1.28 (chave = estado estável, nunca números).

### Alterado
- `Core\ExecutionEngine.mqh`: `LOTE_DIN` → desfecho `ConvictionGradeName(gradeOut)`; `LOT_MIN` → desfecho fixo `"FORCA_MIN"`; `LOT CAP REAL` → embrulhado em `DiagGateAllow(symbol,"LOT_CAP","REAL",3600)`. Lote, cap, lote mínimo forçado e `return(0.0)` **intocados**.
- `XAU_AI_PRO.mq5`: cabeçalho + `#property version "1.257"`.
- `Enterprise\VersionManager.mqh`: `EA_VERSION_STRING "1.2.57"` + changelog com os números.

### Validação
- `apply_p134.ps1`: 3 "OK alvo unico"; ExecutionEngine 43277 B, mq5 74802 B, VersionManager 34744 B, **NUL=0 loneLF=0**.
- Compilação: `Result: 0 errors, 0 warnings, 15976 ms`, ex5 **667 696 B** (23:23:28).
- Recarga `Default` → `XAI_V1243_20261031`: **v1.2.57 = 17 fontes distintas**.

### Ganho
≈ **327 093 linhas** (6,44 % do journal medido).

### Estado do run vigiado
`7702926785952690594`, `started`, **06:10:09 / 06:32:56** — a terminar. Disco livre **8,66 GB**.

### Próximo
Medir uma a uma as chamadas com chave numérica que restam (`RISCO_REAL`, `ALVO_RR`, `RISK_EFETIVO`, `RR_ENTRADA`, `RISK_CALC`, `RISK_CALC_USD`, `SIM_BLOCK`), e o resto de `EXECUTION: ` (801 191 − 177 619).


---

## Ciclo 36 — P1.35 (v1.2.58): `[RISK]` com os mesmos dois portões neutralizados

**Quando:** 31/10/2026, 23:28–23:31 (local) · **Versão:** v1.2.57 → **v1.2.58**

### Medido (`count_needles_tester.ps1`, 5 120 234 linhas)
| linha | linhas |
|---|---|
| `[RISK] RISCO REAL DA ORDEM` | 179 619 |
| `[RISK] alvo elevado para respeitar o RR minimo` | 147 612 |
| `[RISK] ` (todas) | 541 441 |
| `EXECUTION: BLOQUEADA` | 0 |
| `EXECUTION WARNING` (resíduo P1.34) | 147 244 |
| `EXECUTION: ` (todas) | 810 042 |
| `[STATE]` | 1 246 188 |

### Causa
`RISCO_REAL` usava `ajuste|riscoFinal` e `ALVO_RR` usava `tp|alvoMinimo` como desfecho — valores recalculados por candidato → portão neutralizado (mesmo defeito do P1.34).

### Alterado
- `Core\ExecutionEngine.mqh`: `RISCO_REAL` → desfecho `ajuste`; `ALVO_RR` → desfecho fixo `"ALVO_MIN"`. `tpPontos = alvoMinimo`, `riscoFinal`, `EventTradeRejected` e `return false` **intocados**.
- `XAU_AI_PRO.mq5`: v1.2.58 / `#property version "1.258"`.
- `Enterprise\VersionManager.mqh`: `EA_VERSION_STRING "1.2.58"` + changelog medido.

### Validação
- 2 "OK alvo unico"; ExecutionEngine 43812 B, mq5 74802 B, VersionManager 35681 B, **NUL=0 loneLF=0**.
- Compilação `Result: 0 errors, 0 warnings, 15816 ms`; ex5 **668 538 B** (23:30:57).
- Recarga `Default` → `XAI_V1243_20261031`: **v1.2.58 = 17/17**.

### Ganho
≈ **327 231 linhas** (6,39 %). Acumulado P1.33+P1.34+P1.35 ≈ **688 700 linhas**.

### Estado do run
`7702926785952690594` — **06:18:56 / 06:28:15**, a terminar. Disco **8,63 GB**.

### Próximo
`RISK_EFETIVO`, `RR_ENTRADA`, `SIM_BLOCK`, `RISK_CALC`, `RISK_CALC_USD` e o resto de `EXECUTION: `/`[RISK] `, cada um medido individualmente.


---

## Ciclo 37 — P1.36 (pesquisa): inventário completo das superfícies MT5 (360 sondadas)

**Data:** 31/10/2026 23:44–23:50 (local) · **Versão em produção:** v1.2.58 (intocada nesta ronda) · **Run:** 7702926785952690594 `started`, 06:39:54 / 06:45:59

### Objectivo
Responder a "pesquisar tudo que existir no MT5 para EA" com medição, não com lista de nomes: mapear as superfícies da API MQL5 disponíveis a um Expert Advisor e confrontá-las com as que o código real usa.

### Medido
- `Files\Backup\scan_mt5_surfaces.ps1` (novo, 171 linhas, só-leitura): 104 ficheiros `.mq5`/`.mqh`, **1 211 595 B**, **360 identificadores** em **15 famílias** → **134 presentes (37,2 %)**.
- `Files\Backup\scan_api_full.ps1` e `scan_api_full2.ps1` (varreduras de apoio) e `verify_calendar.ps1` (resolveu a contradição do `Calendar`).
- Bibliotecas: **248** `.mqh` em `MQL5\Include\`, **10** referenciadas.

### Achados que mudaram a conclusão
1. **Seis "lacunas" eram falsas** e caíram por medição: `OrdersTotal`/pendentes (EA é market-only: `TRADE_ACTION_PENDING`=0, todos os `ORDER_TYPE_*_LIMIT/_STOP`=0); `ERR_*` (classifica por `TRADE_RETCODE_*` em `OrderRetry.mqh`); `BarsCalculated` (`CopyBuffer` verificado em 19 pontos); `SendMail`/`PlaySound`/`Alert` (`NotificationCenter.mqh` já tem push nativo + Telegram com cooldown/dedup); `PositionSelect` (usa `PositionGetTicket` por ticket, que é o padrão correcto); `HistoryOrder*` (lê por deal).
2. **`ExternalBridge.mqh:15` afirma algo falso:** *"MQL5 nao abre socket"*. A documentação diz o contrário — `SocketCreate` pode ser chamado **só de EA e scripts** (o nosso caso), até 128 sockets, com variantes TLS. Decisão: **corrigir o comentário no próximo ciclo com alteração real**, não sozinho, para não gastar um bump triplo de versão + compilação + recarga em cosmética.
3. **A única lacuna com evidência medida é o SQLite (0/25).** Um CSV em modo texto não tem tipo: uma vírgula a mais desloca todas as colunas — é exactamente o defeito já medido nas §43/§44 (só 156 de 100 228 linhas com ticket, ano `22026`). `DatabaseBind`/`DatabaseReadBind` + `PRIMARY KEY` no ticket eliminam a classe de erro por construção.
4. **Calendário no modo caro:** `NewsFilter.mqh:214` chama `CalendarValueHistory(from, now+warnB)` a cada 60 s × 17 instâncias ≈ 24 480 consultas/dia de janela inteira; `CalendarValueLast` (assinatura confirmada: `change_id` [in][out]) é o delta. Ganho **não medido** — no tester o calendário devolve 4014 (fail-open).
5. **Duas correcções metodológicas** que valem mais do que a tabela: 7 identificadores `iXXXHandle` e `CalendarDatabaseChanged` que eu tinha escrito **não existem** (os primeiros produziam 0 e pareciam lacuna; o segundo devolve 0 resultados na documentação); e `Select-String` com wildcard `**\` **salta subpastas em silêncio** — um grep por `Calendar` deu "0 ocorrências" quando havia 17 em `Filters\NewsFilter.mqh`.

### Alterado no código
**Nada.** Ronda de pesquisa. v1.2.58 mantém-se; o ex5 (668 538 B, 23:30:57) e os 17/17 gráficos não foram tocados.

### Documentação
- `sec45_pendencias.md` (61 linhas) **anexada**: PENDENCIAS 210 512 → **215 974 B** (era a pendência que ficou aberta no ciclo anterior).
- `sec46_pendencias.md` (86 linhas) **anexada**: PENDENCIAS 215 974 → **226 388 B**, NUL=0 loneLF=0 marcador=1 em ambos.

### Próximo
P1.37: a rota de 3 passos da §46.6 — (1) provar `Ticket`/`Magic`/`Origin` e corrigir a coluna `Time` do `TradeLogger`; (2) SQLite como destino do logger; (3) `SymbolIsSynchronized` na cadeia de decisão.

### Ressalva
Cobertura de API não é vantagem estatística. O inventário mede o que existe e o que é usado; não diz que uma função nova tornaria o EA rentável. Um backtest não prova rentabilidade futura.


---

## Ciclo 38 — P1.37 (diagnóstico): o "contrato de 13 colunas" nunca foi exercitado

**Data:** 01/11/2026 07:30–07:58 (local) · **Versão em produção:** v1.2.58 (intocada) · **Run novo:** 7703149588273005599 `started`

### Objectivo
Executar o próximo item da rota da §46.6 — provar ponta-a-ponta as 13 colunas do `TradeLogger` (`Ticket`/`Magic`/`Origin`) e "corrigir a coluna `Time`".

### Medido
- Run anterior fechado: **−32,21 USD**, PF **0,7630**, 375 trades, DD **22,19 %**, Sharpe −1,6249.
- `stats_csv_shape.ps1` (novo): 100 227 linhas → 99 964 de 13 campos, **99 856 válidas com 0 tickets**, 108 malformadas, 14 de 10 campos, 249 com outras contagens.
- `Origin`/`Magic`/`Ticket`: **vazios em 100 %** das 99 964 linhas.
- `count_baseline.ps1` (reescrito): `20261031.log` = 1 473 113 884 B, **5 291 937 linhas**; as 13 agulhas visadas somam **3 403 702 (64,31 %)**.

### Causa encontrada (e correcção da conclusão das §43/§44)
O `Files\Backup\migrate_trade_history_p121.ps1` (P1.21, 31/10) acrescentou `,,,UNKNOWN` a **todas** as linhas históricas, por decisão explícita e documentada no próprio script. Logo: as linhas de 13 campos são **migradas**, não nativas; `trade_history_legacy_v1.csv` não existe porque a migração foi in-place e a rotação só dispara com cabeçalho sem `Origin`; e as "156 com ticket" da §43 eram linhas fundidas.

**A coluna `Time` já estava correcta** (`TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)`, `TradeLogger.mqh:425`). O "ano `22026`" era colagem de duas linhas: `2026.0` + `2026.07.01 …`. Não havia nada a corrigir no formato.

### Alterado no código
**Nada.** A prova exige um trade real escrito por código ≥ v1.2.46, e não houve nenhum desde essa versão (mercado fechado desde 30/10 23:59). Lançado o run **7703149588273005599** com a v1.2.58 e o mesmo `.set` do run anterior, para produzir essa prova e medir o ganho de journal.

### Validação
- Compilação: não executada (nenhum ficheiro de código mudou).
- Recarga 17/17: não aplicável.
- Leitura preliminar do segmento v1.2.58: 2 737 linhas, agulhas 116 (**4,24 %**) contra 64,31 % de base. **Indicativo apenas**: o run está em 00:12 de 3 meses de tempo de modelo.

### Dois falsos alarmes meus, corrigidos por segmentação
O `20261101.log` contém o **rabo da v1.2.45** (o run anterior cruzou a meia-noite) seguido da v1.2.58. Sem segmentar por `[VERSION]`, concluí erradamente que o P1.32 falhava (652 `CTrade::`) e que o churn de TP sobrevivia (650 `modify position`) — todos esses estão no troço antigo; no segmento novo são **0 e 0**. Confirmado também que existe **um só** `CTrade trade` global, com `LogLevel(LOG_LEVEL_ERRORS)` em dois sítios.

### Próximo
1. Fim do run → `count_baseline.ps1` sobre `20261101.log`, comparando o segmento v1.2.58 com a base 64,31 %.
2. No primeiro deal: verificar a rotação esperada de `trade_history_backtest.csv` (10 → 13 colunas) e a primeira linha com `Ticket`/`Magic`/`Origin` reais.

### Ressalva
Log mais limpo não é sistema lucrativo. O run de base perdeu 32,21 USD com PF 0,763; P1.25–P1.35 tornam o diagnóstico legível e o disco sobrevivível. Um backtest não prova rentabilidade futura.


---

## Ciclo 39 — P1.38 (medição): ganho de journal medido a 44 % do run — 64,31 % → 3,81 %

**Data:** 01/11/2026 10:37–10:52 (local) · **Versão:** v1.2.58 (intocada) · **Run:** 7703149588273005599 `started` (modelo 2026.09.08)

### Objectivo
Executar o item #1 da rota do P1.37: comparar o segmento v1.2.58 com a linha de base do run v1.2.45, com segmentação por `[VERSION]`.

### Medido
- `20261101.log`: 59 041 850 B, 207 658 linhas; segmento **v1.2.58** = **132 209 linhas**.
- **Soma das 13 agulhas: 5 042 = 3,81 %** do segmento, contra **3 403 702 = 64,31 %** na base → **16,9× menos**.
- Maiores reduções: `[STATE]` 24,84→1,65 %; `[RISK]` 10,63→0,49 %; `APRENDIZADO` 3,60→0,04 % (90×); `alvo elevado` 3,19→0,11 %; `FORCA LOTE MINIMO` 2,78→0,10 %; `CTrade::` 2,58→**0**; `Calendar error` 3,10→**0**.
- Projecção para o run inteiro: ~300 000 linhas contra 5 291 937 da base (~59 MB contra 1,47 GB).

### Duas precisões que evitam conclusões erradas
1. **`modify position` não mede churn:** é linha do `CTrade`, silenciada pelo P1.32. Conta 0 no segmento novo porque o log da biblioteca está desligado, não porque a escada deixou de reenviar modificações. O churn continua por medir (exige contar `[LADDER]`/`PositionModify` do próprio EA).
2. **`simbolos=3124` no `[SCANNER] RESUMO` é artefacto do tester:** `SymbolManager.mqh:167/280` usam `SymbolsTotal(true)` = Market Watch; no tester ela contém o universo do broker (3 124), em produção ~17 gráficos. Não é defeito de produção e não deve ser "corrigido".

### Não verificado
`[SESSION] estado salvo | trades=187 | W=0 | L=1` é aritmeticamente incoerente, mas pode ser âmbitos diferentes de contadores; `SessionState.mqh` **não foi medido**, logo fica como candidato, não como bug.

### Alterado no código
**Nada.** Ferramenta reutilizada: `count_baseline.ps1` (segmentada).

### Validação
- Compilação: não executada (nenhum ficheiro de código mudou).
- Recarga 17/17: não aplicável.
- Ganho confirmado em percentagem; contagens absolutas só no fim do run.

### Próximo
1. Run fechar → repetir a contagem para o número definitivo.
2. Contar `[LADDER]` no segmento v1.2.58 para medir o churn real.
3. No primeiro deal: verificar a rotação esperada de `trade_history_backtest.csv` (10→13 colunas) e a primeira linha com `Ticket`/`Magic`/`Origin`.

### Ressalva
Journal mais limpo não é sistema lucrativo: o run de base fechou em −32,21 USD, PF 0,763. Um backtest não prova rentabilidade futura.

## Ciclo 40 — P1.39: o Err=5019 era `ERR_FILE_NOT_EXIST`, não permissão; a rotação agora roda e o contrato de 13 colunas foi finalmente exercitado

**Objectivo da ronda:** concluir o diagnóstico que ficou aberto no ciclo 39
(o que significa `Err=5019` e porque é que a rotação do schema do TradeLogger
falhava) e corrigir.

### O que a medição mostrou

1. `Err=5019` **não** é "cannot rename". A tabela oficial de erros MQL5 diz
   `ERR_FILE_NOT_EXIST` — **"File does not exist"**. O registo anterior estava
   errado e foi corrigido.
2. A segunda hipótese em aberto (o destino `trade_history_backtest_legacy_v1.csv`
   já existir) também caiu: o ficheiro **não existia** na pasta comum.
3. A causa real está na assinatura do `FileMove`, confirmada na documentação:
   `common_flag=0` = pasta **LOCAL**, só `FILE_COMMON` = `Terminal\Common\Files`.
   O código criava e lia o ficheiro com `FILE_COMMON` mas pedia a **origem** da
   rotação com `0`. O `FileMove` ia procurar o ficheiro a uma pasta onde ele
   nunca esteve.

### O que foi corrigido (v1.2.59)

- **P1.39** — `Monitoring/TradeLogger.mqh`: `FileMove` com `FILE_COMMON` nos
  **dois** lados, destino **idempotente** (primeiro nome livre com sufixo, porque
  sem `FILE_REWRITE` um destino existente faz a função devolver `false`), e a
  mensagem de erro passa a imprimir **origem e destino**.
- **P1.40** — `Monitoring/Logger.mqh`: `[LOGGER OFFLINE]` passou de
  `TimeCurrent()` (relógio de MODELO, acelerado no tester) para `TimeLocal()`
  (relógio de PAREDE), e de 600 s para 3600 s. É o espelho exacto do P1.24.
- **P1.41** — `Integration/ExternalBridge.mqh`: corrigido o comentário que
  afirmava "MQL5 nao abre socket", desmentido pela documentação de `SocketCreate`.
  Zero mudança de lógica.

### Prova

| Antes | Depois |
|---|---|
| `trade_history_backtest.csv` 25 705 B, 10 colunas, 0 linhas novas | 71 B, **13 colunas** |
| `trade_history_backtest_legacy_v1.csv` inexistente | **25 705 B, 374 linhas, 10 colunas, intacto** |
| journal: `rotacao do schema falhou \| Err=5019` + `TradeLogger OFF` | journal: `TradeLogger MIGRACAO \| ... rodado para 'trade_history_backtest_legacy_v1.csv' (integralmente preservado)` |

`[LOGGER OFFLINE]` era **9 188 linhas = 3,48 %** do segmento v1.2.58 — o maior
emissor único restante. A causa raiz (`LoggerInit()` nunca chamado) fica
registada e **aberta**, por ser decisão de desenho separada.

### Validação

- compilação: **0 errors, 0 warnings**, ex5 = 670 824 B;
- recarga: **17/17 fontes distintas com v1.2.59**;
- 17/17 imprimem `TradeLogger inicializado`, **zero** `TradeLogger OFF` em produção;
- run **7703264373217955650** lançado (v1.2.59, XAUUSD M15, ticks reais).

### Três regras de ferramenta que custaram falhas reais

1. **EOL não é uniforme**: `TradeLogger.mqh` é **LF puro**; os outros quatro
   ficheiros tocados são **CRLF**. O `Troca()` foi refeito para detectar o EOL
   por ficheiro.
2. **EM DASH U+2014** aparece dentro dos comentários (byte 8212, não 45). O
   console mostra os dois como `-`; a âncora "idêntica" dava 0 ocorrências.
3. **Aspas duplas e barras simples dentro do changelog**: o changelog é um
   literal MQL de aspas duplas — aspas duplas dentro dele produziram **16 erros**,
   e `(MQL5\Files)` produziu `warning 86`. Passou a aspas simples e `\\`.

### Próximo

Com o logger do tester de volta, o item que estava bloqueado há 7 ciclos passa
a ser possível: **provar as 13 colunas ponta-a-ponta** — uma linha real com
`Ticket`, `Magic` e `Origin` preenchidos — usando o run 7703264373217955650.

## Ciclo 41 — P1.42: a medição do P1.40 desmentiu a explicação que eu tinha escrito

**Objectivo:** medir o P1.40 no run novo em vez de o dar por bom.

### O ganho é real

| Agulha | v1.2.58 (base) | v1.2.59 (amostra 2 774 linhas) | Ganho |
|---|---|---|---|
| `[LOGGER OFFLINE]` | 9 188 (3,48 %) | **15 (0,54 %)** | **6,4×** |
| `TradeLogger OFF` | 1 por arranque | **0** | eliminado |
| `rotacao do schema falhou` | 1 por arranque | **0** | eliminado |

O contrato de 13 colunas ficou provado ponta-a-ponta: **4/4 linhas válidas**,
`Origin=EA`, `Magic=2026001`, 4 tickets distintos (2, 4, 5, 7), **0 vazios**.

### A explicação estava errada

Os 15 avisos têm tempo de **MODELO** de hora a hora (01:03 → 15:03) enquanto o
relógio do computador andou **2 min 36 s**. Com janela de 3 600 s e relógio de
parede sairia **1** linha, não **15**.

→ **O Strategy Tester virtualiza `TimeCurrent()` E `TimeLocal()`.** A doutrina
do P1.24 é verdadeira em produção e falsa no teste. O ganho de 6,4× vem de
alargar a janela de tempo de **modelo**, não de trocar de relógio.

### Correcção (v1.2.60)

Comentário corrigido com a medição; texto da linha passou de
`"aviso 1x/hora (relogio de parede)"` para `"aviso 1x/3600 s"` (verdade nos dois
ambientes); changelog do produto corrige a afirmação anterior em vez de a deixar
de pé. Zero mudança de lógica.

### Validação

- compilação: **0 errors, 0 warnings**, ex5 = 671 900 B;
- recarga: **17/17 fontes com v1.2.60**;
- run 7703264373217955650 **não foi perturbado** (`00:04:48 / 08:53:20` depois da
  recompilação);
- limpeza: `MQL5\Files\Temp` de **20 ficheiros / 359,5 KB** para **0 / 0 KB**,
  com `eol_probe.ps1` movido para `Backup`.

### Lição

Dois ciclos seguidos, dois comentários falsos apanhados por medição (P1.41 e
P1.42). Um texto que mente sobre o próprio mecanismo é a mesma classe de defeito
que um portão neutralizado — foi assim que a rotação do P1.21 ficou 13 versões a
falhar em silêncio.

### Próximo

Com o logger do tester de volta e o contrato de 13 colunas provado, os itens
bloqueados há 7 ciclos deixam de estar bloqueados: `Ticket`/`Magic`/`Origin`
permitem **deduplicar por ticket** e separar EA de manual, que é o que faltava
para reconfirmar as bandas de ADX (base do P1.14). Antes disso, deixar o run
7703264373217955650 terminar e medir o total final.

## Ciclo 42 - 01/11/2026 - P1.44: READY nao era portao (v1.2.62)

**Entrada:** fechar a investigacao pendente sobre o `READY: NO` latchado.
**Saida:** investigacao fechada por medicao + **dois** defeitos corrigidos, um deles nao previsto.

### Medido antes de mexer

| Medicao | Valor |
|---|---|
| Chamadas a `CProductionChecklist::IsReady()` | **0** (so declaracao e definicao) |
| Chamadas a `ValidationChecklistPassed()` | **0** (so definicao) |
| Chamadas a `ValidationChecklistRun()` / `Run()` | 1 cada, dentro do `OnInit` |
| `READY: NO` / `READY: YES` no journal de experts de hoje | 15 / 81 |
| `SEM BLOCKED - operacao permitida` | **0** |
| `BLOCKED - verificar antes de operar` | **96 de 96** |
| Item que bloqueia sempre | `Dataset: BLOCKED - Dataset ausente/vazio (bloqueia)` |
| Portao real de spread | `Filters/SpreadFilter.mqh:91,145`, `ValidationEngine:150,185`, `SmartExecution:334` |

Conclusao: **nao ha latch porque nao ha portao**. O `READY: NO` de fim de semana nao travou nada; o problema era outro - o texto prometia um bloqueio que o codigo nao exerce, e o EA operou 100% das vezes com a checklist "reprovada".

### Encontrado por abrir o ficheiro (nao estava na lista)

`Common/Files/XAU_AI_PRO/ValidationChecklist.txt` e `ProductionChecklist.txt` tinham **rabo do resumo anterior** gravado no disco:

```
Resultado: REPROVADO (existem BLOCKED)Resultado: REPROVADO (existem BLOCKED): ... xistem BLOCKED)stem BLOCKED)
READY: YEStical failed
READY: NO: NONO
```

Causa: `FILE_READ | FILE_WRITE` + `FileSeek(0)` **sem truncar**. Corrigido trocando para `FILE_WRITE` sozinho nos dois sitios.

### Mudanca (v1.2.61 -> v1.2.62)

- `Monitoring/ProductionChecklist.mqh`: 16 295 -> 17 402 B. `m_snapshot_time` + `NOTA` no `GetSummary()` + `FILE_WRITE` truncante.
- `Monitoring/ValidationChecklist.mqh`: 10 412 -> 11 315 B. `g_vcheck_time` + textos honestos + `FILE_WRITE` truncante.
- `Enterprise/VersionManager.mqh`: 40 724 -> 43 337 B (changelog v1.2.62, com os dois defeitos e as contagens).
- `XAU_AI_PRO.mq5`: `// XAU_AI_PRO v1.2.62`, `#property version "1.262"`.
- Todos `loneLF=0 NUL=0`. Compilacao **0 errors, 0 warnings**, `ex5 = 677 296 B`.

### Erro cometido e corrigido

Primeira aplicacao gerou linhas de continuacao do `NOTA` sem `+=`/`;` -> `error 152: 'summary' - some operator expected` (2 erros, 2 warnings). Corrigido para uma instrucao unica com `+`. Regra: continuacao de expressao MQL precisa do operador e de um unico terminador no fim.

### Pendente / adiado

- Recarregar os 17 graficos com o novo `.ex5` **depois** do fim do run 7703264373217955650 (`profile_apply` devolve `ok:false` com o tester a correr). Atao verificar que os dois `.txt` ficam sem rabo.
- Decidir se `Dataset` deve ser `VC_WARNING` em vez de `VC_BLOCKED` (hoje reprova 100% dos arranques e ninguem consulta).
- Run 7703264373217955650 (v1.2.59) ainda a correr: progresso 01:25:43 / 04:57:37 as 16:17.

### Ressalva

Log honesto e CSV correcto **nao** sao sistema lucrativo. Bases medidas: v1.2.45 = -32,21 USD / PF 0,763; v1.2.58 = -32,88 USD / PF 0,7592. O P1.44 nao toca em risco, execucao ou preco: o resultado esperado do backtest e igual ao da base.
## Ciclo 43 - 01/11/2026 - P1.45: o registo de trade descrevia o fecho e chamava-lhe abertura (v1.2.63)

### Pergunta

O contrato de 13 colunas ja era exercitado desde o P1.39. Faltava perguntar se o conteudo era coerente consigo proprio: o par `Entry`/`Exit` explica o `Profit` da mesma linha?

### Medicao (339 linhas validas, `Common\Files\trade_history_backtest.csv`)

| Achado | Linhas |
|---|---|
| `Exit == Entry` com `Profit != 0` (impossivel) | **115** |
| `Entry != Exit` | 141 |
| ... com sinal coerente com o lucro | 79 |
| ... **incoerentes** (BUY, `Exit < Entry`, lucro positivo) | **2** |
| lucro zero com o preco a mexer | 60 |
| coluna `AI` = 0.00 | 339 de 339 |

Amostra das incoerentes: `2026.09.16 21:35:40 NZDUSD BUY 0,57195 -> 0,57194 Profit 20 ticket 328` e `2026.10.01 11:53:22 EURUSD BUY 1,12877 -> 1,12876 Profit 20 ticket 446`.

### Causa

Tres erros de semantica no **chamador**, nenhum no logger:

1. `Entry` recebia `DEAL_PRICE` do deal de **fecho** (`DEAL_ENTRY_OUT`), isto e, o preco de saida.
2. `Exit` recebia `SymbolInfoDouble(SYMBOL_BID)` no instante do registo - retrato posterior ao fecho, nao preco executado. E a origem das 115 linhas com `Exit == Entry`.
3. `Type` vinha de `DEAL_TYPE` do deal de fecho, logo uma **compra fechada por venda** era gravada como `SELL` - a assimetria que produz as 2 linhas incoerentes.

O comentario antigo justificava a escolha dizendo que `DEAL_TYPE` em `DEAL_ENTRY_OUT` era mais confiavel porque a posicao podia ja estar fechada. A premissa era falsa: `HistorySelectByPosition` devolve os deals da posicao fechada.

### Correccao

- `HistorySelectByPosition(posId)` + varredura por `DEAL_ENTRY_IN` -> `posOpen` e `posIsBuy`.
- Fallback para o comportamento antigo se a posicao nao for seleccionavel (nunca zeros).
- `HistoryDealSelect(deal)` a devolver a seleccao ao deal do evento.
- `Exit` = preco de fecho executado.
- Semantica das 13 colunas documentada em `TradeLogger.mqh`, com a invariante: BUY com lucro positivo exige `Exit > Entry`; SELL exige `Exit < Entry`.

Nada de risco, execucao, preco ou gestao foi tocado. `dealMagic` nao foi redeclarado (ja existe no inicio da funcao) para nao sombrear.

### Prova

- `.bak_before_p145` dos 3 ficheiros antes de escrever.
- `XAU_AI_PRO.mq5` 74 804 -> 76 557 B (`CRLF=2286`, `loneLF=0`, `NUL=0`); `TradeLogger.mqh` 17 272 -> 18 954 B (`loneLF=600`, LF puro por desenho); `VersionManager.mqh` 43 337 -> 45 116 B (`CRLF=228`).
- Bump triplo: `v1.2.63` / `"1.263"` / `EA_VERSION_STRING "1.2.63"`.
- Compilacao: `0 errors, 0 warnings`, `ex5 = 678 646 B`.

### Erro de ferramenta corrigido

A ancora do bloco foi reconstruida de memoria/resumo e nao do ficheiro: faltavam 6 linhas de comentario `P1.21` no meio, e o `Troca` teria abortado. Reescrito `apply_p145b.ps1` a partir do texto extraido com comprimento por linha. Regra: extrair sempre o texto real antes de escrever a ancora.

### Pendente / adiado

- **Medir o efeito do P1.45**: exige run novo com o `.ex5` v1.2.63 (`Profiles\Tester\p145_v1263.ini` ja criado). Rodar antes o `trade_history_backtest.csv` para `trade_history_backtest_pre_p145.csv` para nao misturar linhas de semanticas diferentes.
- Run 7703264373217955650 (binario anterior) a 91 %: `05:45:23 / 06:19:07` as 20:45. Tem de terminar para o agente `Core 1` ficar livre.
- Coluna `AI` continua 0.00 no tester (pipeline Python offline).

### Ressalva

CSV correcto **nao** e sistema lucrativo. Bases: v1.2.45 = `-32,21 USD` / PF 0,763; v1.2.58 = `-32,88 USD` / PF 0,7592. O P1.45 restitui verdade a uma fonte de dados de onde o EA aprende; nao promete lucro. Um backtest nao prova rentabilidade futura.

## Ciclo 44 - 01/11/2026 - verificacao antecipada do P1.44 e primeira prova do P1.45

### Base fechada

Run 7703264373217955650 terminou: `-32,88 USD`, PF `0,7592`, 750 deals, 375 trades, 162 ganhos / 213 perdas, max DD 47,15 USD (22,50 %), Sharpe -1,6628, 31 892 873 ticks. **Identico a base v1.2.58** - o que prova negativamente que P1.39 a P1.44 nao tocaram em trading.

### CSV rodado, nao apagado

`trade_history_backtest.csv` (34 830 B, 373 linhas) -> `trade_history_backtest_pre_p145.csv`, com verificacao de destino inexistente e de tamanho preservado. Misturar linhas com `Entry` = preco de fecho e linhas com `Entry` = preco de abertura tornaria a medicao impossivel por construcao.

### P1.44 provado

- `ValidationChecklist.txt` (769 B) e `ProductionChecklist.txt` (1 197 B) escritos as 21:54:25, ambos **limpos**: sem `READY: NO: NONO`, sem `READY: YEStical failed`, sem `xistem BLOCKED`. O veredicto passou a trazer `snapshot de init: 2026.07.29 00:00`.
- Journal: `READY: YES | snapshot de init: 2026.07.29 00:00`.

### Crenca corrigida

`96 de 96 arranques com BLOCKED` (reportado no ciclo do P1.44) **nao** e propriedade do EA: neste run, com `EnableDataset=false`, o resultado e `READY=13 WARNING=2 BLOCKED=0`. O bloqueio vinha da configuracao de producao pedir dataset sem dataset. A decisao pendente de mudar a severidade do item fica mais estreita: a pergunta real e se a producao deve manter `EnableDataset=true` sem dataset.

### Achado novo, nao corrigido

As duas checklists discordam sobre o mesmo assunto no mesmo arranque: `Dataset: READY - Dataset desativado` numa e `[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio` na outra; o mesmo para Dashboard (`WARNING ... desativado` contra `[OPTIONAL] ... FAIL`). Uma respeita a definicao, a outra ignora-a. **Nao corrigido**: recompilar a meio do run substituiria o `.ex5` em teste.

### P1.45 - previsao confirmada em 15 linhas

| Verificacao | v1.2.62 | v1.2.63 (15 linhas) |
|---|---|---|
| `Exit == Entry` com `Profit != 0` | 115/339 | **0** |
| Incoerentes | 2 | **0** |
| Coerentes entre `Entry != Exit` | 79/141 | **10/10** |
| Lucro zero com preco a mexer | 60 | **0** |

Caso-de-prova, mesma operacao: antes `GBPUSD BUY 1.32998 -> 1.32997 -0.58`; agora `GBPUSD SELL 1.32940 -> 1.32998 -0.58`. A posicao era vendedora e o deal de fecho era comprador - exactamente o diagnostico. As duas linhas restantes com `Entry == Exit` tem `Profit = 0.00`, que e o caso legitimo.

### Pendente

- Fim do run 7703371145268441630 (00:17:59 / 16:39:04 as 22:12) para a previsao 1: o report **tem de ser identico** ao de base.
- Contador explicito de quantas vezes o fallback do P1.45 e usado (hoje e silencioso: 10/10 coerentes sugere, nao mede).
- Unificar os itens das duas checklists que avaliam a mesma coisa com regras diferentes.

### Ressalva

Coerencia de dados e igualdade de comportamento nao sao lucro. Base: `-32,88 USD` / PF `0,7592`. Um backtest nao prova rentabilidade futura.


## Ciclo 45 - 01/11/2026 - "EA operando sozinho": opera, e corre v1.2.58

- Pergunta: o EA esta de facto a operar sozinho? Resposta medida: **sim**.
- Prova: 53 354 linhas de log no dia, 52 resumos de master, 2 745 pipelines, 1 ordem
  enviada, 1 trade executado (USDJPY SELL 0.08, ticket 11186991230) as 23:00:11 local.
- Funil: 11 768 bloqueios contra 1 071 sinais OK; 901 bloqueios por
  `VALIDATION: TREND BUY` e 169 por `VALIDATION: AVOID HOUR`.
- Achado 1 (versao): os graficos correm v1.2.58 e o compilado e v1.2.63. As correccoes
  P1.39 -> P1.45 nao estao a correr na conta.
- Achado 2 (IA): a porta 9001 do `AIGatewayUrl` pertence ao terminal64; nao existe processo
  Python. `IA=SEM PRECO` em 52 de 52 resumos, com score 64.25 a passar o minimo de 60.00.
- Achado 3 (P1.47 candidato): a mensagem de STANDBY nomeia o dono com o proprio `chart_id`.
- Conta: balance 12 351.78, equity 12 350.51, margem livre 12 270.51, flutuante -1.27.
- Posicao sem SL por desenho (`EnableStoplessEntry`), armada em 10.00 USD.
- Run `7703371145268441630`: 01:11:27 / 05:18:58, sem recompilar nem recarregar.

## Ciclo 46 - 01/11/2026 - P1.46 e P1.47 aplicados e compilados numa copia de verificacao (v1.2.64)

- P1.46: as quatro verificacoes da `ProductionChecklist` que contavam funcionalidade
  desligada por opcao como FALHA passam a devolver PASS com `(opcional)`. Esperado:
  `12/17 passed | 5 failed` -> `16/17 passed | 1 failed` (so Python).
- P1.47: novo `PipelineMasterChart()` em `Core\TradePipeline.mqh`; as mensagens de standby
  do pipeline e do backup passam a imprimir `esta=` e `dono=` em vez de um `chart=` que
  apontava para a propria instancia.
- Prova do P1.47: GBPUSD (35819305996467) escrevia o seu proprio id como dono, quando o
  dono real era o USDCZK (35819164653256), ausente de todas as linhas de standby do dia.
- Compilacao feita numa copia da arvore (`Experts\XAU_AI_PRO_build\`, 150 ficheiros) para
  nao tocar no `.ex5` que o run usa: `0 errors, 0 warnings`, ex5 681 034 B. Producao
  intocada em 678 646 B / 20:39:36. Copia apagada depois.
- A estrategia pagou-se: a primeira insercao do changelog produziu `error 177 l-value
  required` (segunda atribuicao em vez de continuacao). Corrigido e recompilado a 0/0.
- Bump triplo para v1.2.64 + changelog. 4 backups `.bak_before_p147`. Chaves com delta 0.
- Falta: fim do run, recompilar a producao e recarregar os 16 graficos (correm v1.2.58).

## Ciclo 47 - 02/11/2026 - Python restaurado, P1.48 e P1.49 aplicados, 16 ativos treinados (0 publicaveis)

- Pedido: "corrigir todos itens, e python tambem e treinar novos modelos atualizados dos
  ativos operados".
- **O Python nao existia nesta maquina.** Medido: `where python/python3/py/pythonw` falham,
  sem `Local\Programs\Python`, sem `C:\Python313`, nenhum `python*.exe` sob `MQL5`, nenhum
  `.whl`. O `.venv` dos logs de treino foi apagado na limpeza anterior. Resolvido com
  Python 3.11.9 **embeddable** em `Files\Temp\py311` (sem instalador, sem PATH, sem
  registo) + pandas 3.1.0, numpy 2.4.6, **scikit-learn==1.9.0** (pin obrigatorio: os `.pkl`
  foram treinados com 1.9.0), joblib, scipy, MetaTrader5 5.0.6231.
- **Export do MT5** (`Files\Temp\export_mt5.py`): 3 limites da API medidos e contornados -
  `copy_rates_range` antigo devolve 0 em 16/16; `copy_rates_from_pos(100000)` da `-2`;
  e a paginacao saia DESCENDENTE. Resultado: `Files\Data\dataset_mt5_20261101.csv`,
  **1 494 248 linhas / 132,4 MB / 16 simbolos / 0 duplicados**, monotonicamente crescente.
- **P1.48** (`Python\model_registry.py`, 7 630 -> 9 727 B): `FEATURE_VERSION` dizia `25F`
  quando os 39 `.meta.json` dizem `25F-v2`/25 features; e o veredicto `READY` ignorava
  `publicable`, contradizendo `backend/ai_inference.py:556`. Prova **negativa** com os dois
  modulos lado a lado (`proof_p148.py`, EXIT=0, 4/4): antigo -> `READY "ok"`;
  novo -> `ERROR "not_publishable: edge -0.0008 abaixo do minimo +0.0500"`.
- **P1.49** (`mt5_bridge.py` + `data_engine_xau.py`): a limpeza do dataset usava
  `symbol_aliases` - 9 apelidos - como **whitelist** e descartava em silencio 9 dos 16
  ativos operados. MEDIDO: **700 000 linhas / 7 simbolos** -> **1 494 248 / 16**.
  Passou a validar a FORMA (`SIMBOLO_RE` + `simbolo_plausivel`), sem presumir catalogo.
- **Treino dos 16 ativos operados** (`sweep_mt5.py`, tf do grafico de cada um):
  **0 de 16 publicaveis**. 7 de 16 com edge positivo, o melhor USDCAD H1 +0.0241
  (USDCHF +0.0229, USDSGD +0.0193); o pior USDCNH H1 -0.1120. Nenhum estavel.
  Relatorio `Files\Backup\treino_edge_20261101.csv`. **Nenhum `.pkl`/`.meta.json` escrito** -
  os 515 MB de modelos ficaram intocados, porque baixar o portao para "passar" seria o
  defeito, nao a correcao.
- **Consequencia do P1.48, medida:** `registry_summary()` passou de "tudo READY" a
  **28 STALE + 11 ERROR** (`publicable: 28 True / 11 False`). 10 dos 11 ERROR tem edge
  **positivo** e apenas insuficiente; so XAUUSD_M5 e negativo. XAUUSD_M15 e o caso
  interessante: 5 folds de 5 positivos, media +0.0481, a 0.0019 do portao.
- Isto **nao e regressao**: `backend/ai_inference.py` ja recusava estes modelos. O que muda e
  que a recusa passou a ser **visivel no registo**. Explica o `IA=SEM PRECO` em 52/52
  resumos do Ciclo 45 - era o modelo a ser correctamente recusado, nao so o gateway em baixo.
- Limite do resultado, declarado: os majors so tem ~17 meses de M5 (100 000 candles) e os H1
  saem com ~6 660 barras de treino. Exportar H1/H4 directos do MT5 (100 000 barras cada,
  ~11 anos) e a melhoria de dados mais obvia - nao feita neste ciclo.
- Run `7703371145268441630`: 01:49:13 / 06:02:50 no fim do ciclo. Producao intocada
  (os 16 graficos continuam em v1.2.58).

### Ressalva

Um backtest e um treino nao provam rentabilidade futura. "0 publicaveis" e um resultado
honesto, nao um sucesso; a IA fica inerte por desenho (regra 18.5) ate haver modelo que
passe o portao.

## Ciclo 48 - 02/11/2026 - P1.50 (medicao): H1 nativo dobra o edge e ainda nao chega ao portao

- Pergunta: o limite declarado no Ciclo 47 era "os majors so tem ~17 meses de M5". O MT5
  tem 100 000 candles H1 por simbolo. Se o problema fosse falta de dados, dar 12x mais
  barras teria de mover o edge.
- Metodo: `Files\Temp\sweep_tf_nativo.py` le candles **nativos** do timeframe
  (`copy_rates_from_pos` paginado, `np.sort`, duplicados de fronteira removidos) e passa
  pelo **mesmo** `train_v2.treinar`, com o mesmo `PUBLICACAO_MIN_EDGE = 0.05`. Nada mudou no
  treinador - muda so a fonte de dados.
- Treino por simbolo: **6 660 -> 79 989 barras** no H1 (12x). Grupo de controlo: USDBRL (M5),
  USDCLP e USDCOP (H1) tem o **mesmo** numero de barras nas duas fontes, porque nao ha mais
  historia nativa.
- Resultado: **11 de 16 melhoraram**, media dos deltas **+0,0172**. Positivos: 7 -> 10 de 16.
  Melhor: **USDCHF H1 +0,0363** (era USDCAD +0,0241). Maiores ganhos: USDCNH **+0,1270**
  (edge -0,1120 -> +0,0150) e USDSEK **+0,0721** (-0,0380 -> +0,0341).
- Prova negativa natural: os tres do grupo de controlo **nao ganharam** (-0,0017, -0,0232,
  -0,0027). Se a causa fosse ruido, teriam subido tambem.
- **0 de 16 passam os +0,0500.** O melhor fica a 0,0137 do portao. Mais dados melhoram o
  modelo; nao o tornam publicavel.
- Decisao: **o portao nao se toca.** Baixar 0.05 para 0.03 depois de ver o resultado seria
  escolher o numero a posteriori - o inverso de medir. Nenhum `.pkl`/`.meta.json` escrito;
  515 MB de modelos intocados; registo continua 28 STALE + 11 ERROR.
- Proximo passo que a medicao autoriza (nao feito): alvo **binario com barreira de custo**
  em vez de 3 classes com `LOOKBACK` fixo. Isso e um contrato de features NOVO, com os
  modelos antigos preservados - nao um ajuste de portao. Requer decisao do dono.
- Run `7703371145268441630`: 02:30:22 / 06:56:31 no fim do ciclo. Producao intocada
  (16 graficos em v1.2.58).

### Ressalva

Edge de +0,03 em validacao cronologica nao e lucro: e a diferenca entre acertar e o palpite
majoritario da fatia de teste, antes de spread, comissao e slippage. Nenhum destes modelos
foi publicado, e nenhum backtest prova rentabilidade futura.

## Ciclo 49 - 02/11/2026 - P1.51 (correcao): o portao de simbolo saiu do papel

**Ponto de partida medido.** `Core/SymbolValidator.mqh` tinha 1 definicao e **0 chamadas** em 104 ficheiros `.mqh`/`.mq5`: compilava e nunca corria. `SymbolIsSynchronized()` nao existia em nenhum ficheiro (lacuna 1 da secao 45). O spread ja era fechado por `GetMaxSpread(symbol)` em `SpreadFilter.mqh` e em mais 5 sitios.

**Aplicado.**
- `Core/SymbolValidator.mqh`: 2158 B -> 5158 B (`crlf=205`, `nul=0`, BOM utf8). `ValidateSymbol(symbol, lot, slPoints, string &reason)` recusa simbolo vazio/fora do Market Watch/nao sincronizado, `SYMBOL_TRADE_MODE_DISABLED`/`CLOSEONLY`, lote fora de min/max/step (tolerancia 1e-8), `ask`/`bid`/`point <= 0` e SL abaixo do `SYMBOL_TRADE_STOPS_LEVEL`, sempre com motivo textual. Overload de 3 parametros mantido.
- `Core/ExecutionEngine.mqh`: 43812 B -> 45002 B (`crlf=1103`, `nul=0`). Bloco unico antes de `CSmartExecution::OpenPosition` imprime `EXECUTION BLOCK | SYMBOL | ... | Motivo=` e chama `EventTradeRejected(..., "SYMBOL_INVALID")`.
- `Enterprise/VersionManager.mqh`: `EA_VERSION_STRING` 1.2.64 -> **1.2.65** e paragrafo do P1.51 no inicio de `m_current.changes` (46839 -> 47932 B).
- `XAU_AI_PRO.mq5`: cabecalho da linha 2 para v1.2.65 (tamanho inalterado, 76594 B).

**Validacao.** Compilacao numa copia (`Experts/XAU_AI_PRO_buildcheck`), para nao tocar no binario do run em curso: `Result: 0 errors, 0 warnings, 16779 ms elapsed, cpu='X64 Regular'`. Copia `.ex5` 683976 B; producao `.ex5` 678646 B **antes e depois**; copia apagada. Verificacao pos-escrita por releitura: `NUL=0`, `CRLF == LF`, tamanho igual ao texto gravado.

**Nao alterado.** Nenhum `input`, `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, limite, `return` ou regra de trading. `ValidateSymbol` e trava adicional fail-closed no ultimo ponto antes do envio.

**Estado do run `7703371145268441630`.** `started`, progresso `02:39:35 / 07:17:12`. Sem resultado novo para comparar com a previsao 1 (-32,88 USD, PF 0,7592, 750 deals, 375 trades).

**Proximo.** Recompilar a producao para v1.2.65 e recarregar os 16 graficos quando o run fechar (hoje correm v1.2.58); confirmar `[VERSION] v1.2.65` e `16/17 passed | 1 failed` no journal. Depois: contador explicito de uso do FALLBACK do P1.45 e unificacao das duas checklists.

## Ciclo 50 - 02/11/2026 - P1.52 (medicao): o fallback do P1.45 passou a ser contado

**Problema medido.** O P1.45 fez o registo descrever a POSICAO (direcao e preco de abertura vindos do deal `DEAL_ENTRY_IN` da mesma posicao). A prova de entao — 10 de 10 linhas coerentes — cobre o **caminho principal**. O ramo de recurso (quando `posId == 0` ou `HistorySelectByPosition` falha) herdava direcao e preco do deal de FECHO e **nao deixava rasto**: uma linha errada no CSV era indistinguivel de uma certa.

**Aplicado.**
- `XAU_AI_PRO.mq5` (76594 -> **77108 B**): `bool posDealFound = false;` ao lado de `posOpen`; `posDealFound = true;` antes do `break;` do deal `DEAL_ENTRY_IN`; contador `static ulong s_logFallbackCount` que, quando `!posDealFound`, incrementa e imprime `TRADELOG FALLBACK | deal=... | posId=... | acumulado=N`.
- `Enterprise/VersionManager.mqh` (47932 -> **48580 B**): `EA_VERSION_STRING` 1.2.65 -> **1.2.66** + paragrafo do P1.52.
- `XAU_AI_PRO.mq5` linha 2: v1.2.66.

**Leitura do resultado.** `acumulado=0` numa sessao com fechos = o caminho principal cobriu tudo. `acumulado>0` = cada linha traz o `deal` e o `posId`, e essas linhas passam a ser auditaveis nominalmente.

**Validacao.** Compilacao numa copia: `Result: 0 errors, 0 warnings, 21669 ms elapsed, cpu='X64 Regular'`; copia `.ex5` 684134 B; producao `.ex5` 678646 B antes e depois (intocada); copia apagada. Pos-escrita: `NUL=0`, `CRLF == LF`, marcadores unicos.

**Estado.** Run `7703371145268441630` continua `started` (`07:15:06 / 07:15:58`, total a crescer). Producao permanece v1.2.58 nos 16 graficos: o reload para **v1.2.66** (que ja inclui P1.51 + P1.52) fica para quando o run fechar, seguido de `[VERSION] v1.2.66` e `16/17 passed | 1 failed` no journal.

**Cuidado a manter.** O contador nao muda o comportamento do registo; se aparecer `TRADELOG FALLBACK`, a acao e investigar o `posId` ausente, nao relaxar o registo.

## Ciclo 51 - 02/11/2026 - Reload da producao: v1.2.61 -> v1.2.66

**Objectivo:** pôr a correr, na conta demo, o codigo que ja estava no disco.

- Recompilacao da producao: 678646 B -> 684804 B, `Result: 0 errors, 0 warnings, 15778 ms elapsed`.
- Run `7703371145268441630` fechado e conferido: profit -32.88 | PF 0.7592 | 750 deals / 375 trades | profit_trades 162 / loss_trades 213 | DD balance 47.15 (22.50%) | sharpe -1.6628 — **PREVISAO 1 confirmada** ao decimal.
- 16 graficos reanexados por `chart_add_expert` (chart01 isolado primeiro, depois 15).
- Deinit provou o que estava a correr: **v1.2.61, build 2026.10.30** (5 versoes atras). Init provou o que passou a correr: **v1.2.66, build 2026.11.02**, 16/16 graficos, 15 modulos OK, `15/17 passed | 2 failed | 0 critical failed`.
- Reanexado sem `expert_parameters` por prova de equivalencia: 308 inputs dos graficos == 308 `default_value` do `.ex5`. Nenhum parametro de risco foi alterado.
- 3 posicoes preservadas (USDJPY, USDCAD, AUDUSD); master reeleito as 05:15:30; zero duplicacao; `TRADELOG FALLBACK` = 0 (sem fechos ainda).
- Autonomia reconfirmada no mesmo periodo: `LOT CAP REAL` (0.200 -> 0.135) -> `RISK 96.2% do teto` -> `SIMULACAO APROVADA` -> `[RETRY] SUCCESS retcode=10009` -> `TRADE OPEN AUDUSD` -> `MANAGING`.

## Ciclo 52 - 02/11/2026 - P1.53: as duas checklists alinhadas (Dataset, Dashboard)

**Objectivo:** o mesmo dado nao pode ter dois veredictos nos dois relatorios do mesmo arranque.

- Medido as 05:14 (v1.2.66 em 16/16 graficos): `[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio` na ProductionChecklist contra `Dataset: BLOCKED - Dataset ausente/vazio (bloqueia)` na ValidationChecklist, para o mesmo `EnableDataset=true` e o mesmo ficheiro. Segundo caso: Dashboard `PASS` contra `WARNING`.
- Corrigido em `Monitoring/ValidationChecklist.mqh`: Dataset `BLOCKED` -> `WARNING` (opcional, nao bloqueia); Dashboard desligado `WARNING` -> `READY`. 11315 -> 12055 B.
- v1.2.67 aplicado nos tres sitios (define, `m_current.changes`, cabecalho do `.mq5`). Producao recompilada 684804 -> 685792 B, `0 errors, 0 warnings, 16520 ms`.
- 16 graficos recarregados: 16/16 `[VERSION] v1.2.67 | Build=2026.11.02`.
- Resultado medido: `BLOCKED=0` em 15 graficos. O unico `BLOCKED` restante e real — `USDRUB` com `Spread acima do maximo: 1500.0 pts (max=489.3)`.
- Nenhuma regra de trading, limite, return ou parametro de risco alterado: e classificacao de diagnostico.

## Ciclo 53 - 02/11/2026 - P1.54: as checklists passaram a ler a pasta onde o EA escreve

**Objectivo:** o mesmo ficheiro nao podia estar "ausente" na checklist e a ser escrito pelo DataLogger no mesmo segundo.

**Medido antes (v1.2.67, 05:17:58, 16/16 graficos).** `[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio` em 16 de 16, enquanto `MQL5\Files\Data\dataset.csv` tinha **3.537.420 B** escritos as **05:18:05**. `[OPTIONAL] Python: FAIL` em 16 de 16. Causa: as quatro verificacoes de ficheiro usavam `FILE_COMMON`, que muda a raiz de `MQL5\Files` para `Common\Files` - e `Common\Files\Data` tem 57 ficheiros, nenhum `dataset.csv`.

**Aplicado (7 sitios, 2 ficheiros).**
- `Monitoring/ProductionChecklist.mqh` 18160 -> **19685 B**: itens 5 (AI), 6 (Python), 7 (Dataset) e 8 (JSON) sem FILE_COMMON; `FILE_SHARE_READ | FILE_SHARE_WRITE` nas aberturas.
- `Monitoring/ValidationChecklist.mqh` 12055 -> **12648 B**: `hasPred`, `jsonOK` e `dsOK` alinhados com a Production.
- v1.2.68 nos tres sitios (`VersionManager.mqh` 49665 -> **51274 B**, `m_current.changes`, cabecalho do `.mq5` 77108 B).

**Compilacao.** 1a tentativa `0 errors, 9 warnings` (warning 86 de escape: o texto novo citava `MQL5\Files\Data` com barras simples). Barras duplicadas so nesse trecho -> `0 errors, 0 warnings, 17733 ms elapsed, cpu='X64 Regular'`; `.ex5` 685956 -> **685772 B** as 05:27:45. Backups `.bak_before_p154` nos 4 ficheiros e `.bak_before_p154b` (estado intermediario do VersionManager). E o 4o ciclo em que o `compile_prod.ps1` recusa um `.ex5` com warnings - o `.ex5` e reescrito mesmo quando o script aborta, por isso o veredicto tem de ser sempre a linha `Result:`, nunca o exit code.

**Lido depois (v1.2.68, arranque de 05:28:01, 16/16 graficos).**
- `[OPTIONAL] Dataset: PASS` 16/16 (antes FAIL 16/16).
- `[OPTIONAL] Python: PASS` 7 e `AI`/`JSON: PASS` 7 - exactamente os 7 simbolos com `prediction_<SYM>.json` na sandbox (XAUUSD, USDJPY, USDCAD, AUDUSD, NZDUSD, GBPUSD, EURUSD), ficheiros de 08/10/2026 22:00. Os 9 restantes falham com razao: nao tem predicao.
- `[VALIDATION]`: 7 com predicao `READY=15 W=0 B=0`; 8 sem predicao `READY=12 W=3 B=0`; USDRUB `READY=11 W=3 B=1`. Delta +2/-2 e +1/-1, explicado item a item no P1.54.
- 16/16 `[VERSION] v1.2.68 | Build=2026.11.02 | Stable=Yes | AutoUpdate=OFF | Modulos=15`.

**Prova fisica das duas pastas (05:29).** sandbox: `dataset.csv` 3.541.218 B as 05:28:07, `prediction_XAUUSD.json` 517 B de 08/10/2026 22:00. Common: sem `dataset.csv`, `prediction_XAUUSD.json` 521 B de **25/08/2026 17:16**. Ou seja, o `AI`/`JSON` que passava nos 7 simbolos validava uma copia dois meses mais velha do que a que o AIConnector consome. Ficou registado como pendencia: o item ainda diz PASS a um JSON de 25 dias.

**Efeito colateral bom.** A pendencia antiga do P1.46 ("lacuna no pipeline Python") ficou reclassificada: era o mesmo erro de pasta. Nenhuma linha de Python foi alterada e o item passou a PASS nos 7 simbolos com predicao.

**Nao alterado.** Zero regras de trading, limites, returns, severidade ou parametros de risco. As checklists continuam diagnostico de arranque (nada consulta `IsReady()` nem `ValidationChecklistPassed()` desde o P1.44); o bloqueio real de spread continua por tick em `Filters\SpreadFilter.mqh`. USDRUB continua o unico BLOCKED e por spread real (1500.0 pts contra maximo 489.3) - decisao de negocio, nao defeito de codigo.

**Proximo.** Os 9 simbolos sem predicao (USDBRL, USDCLP, USDCOP, USDSEK, USDCHF, USDCZK, USDCNH, USDRUB, USDSGD) dependem de treino por simbolo, nao de checklist. E decidir se o item `AI` deve reportar a idade do JSON que valida.

---

## Ciclo 54 - P1.56 (v1.2.70): idade da previsao no item AI

**Pedido.** Melhoria seguinte, sem parar.

**Medicao.** `Data\prediction_XAUUSD.json` com timestamp `2026-10-08T22:00:33` e `PASS` sem idade: 25 dias. Um diagnostico que diz `PASS` a um dado de 25 dias nao informa nada.

**Feito.** `AIChecklistMaxAgeHours 120.0`, `PredictionAgeHours()` por `FileGetInteger(FILE_MODIFY_DATE)` sem abrir o ficheiro, `MathMin` das idades em `TimeLocal`/`TimeGMT`; mensagem com `idade=NNNh` e marca `STALE`. Veredicto inalterado (`[OPTIONAL]`/`PASS` com o ficheiro presente), pela regra do P1.53.

**Compilacao.** `0 errors, 0 warnings`; `.ex5` 690176 -> 688642 B as 05:55:01.

**Nao alterado.** Zero risco, zero limites, zero regras de trading.

## Ciclo 55 - P1.57 (v1.2.71): o mesmo dado deixa de ter dois vereditos

**Medicao.** Tres divergencias reais entre as duas checklists, lidas no codigo: Symbol (bid/ask so na Production), AI (`EnableAIFilter` so na Validation) e JSON (`RequireAIJSON` so na Validation).

**Feito.** Tabela unica de decisao e critica atribuida em runtime (`m_critical[5] = RequireAIJSON`, `m_critical[8] = (EnableAIFilter && RequireAIJSON)`); a Validation passa a exigir cotacao no item 11.

**Compilacao.** `0 errors, 0 warnings`; `.ex5` 688642 -> 692594 B as 06:00:31.

**Nao alterado.** As checklists continuam diagnostico; o portao de spread continua por tick.

## Ciclo 56 - P1.58 (v1.2.72): o EA deixou de precisar de permissao de DLL para carregar

**O que correu mal primeiro.** Tentei reanexar o EA ao USDSGD pelo template do proprio grafico e o EA foi REMOVIDO: `initializing ... failed with code 0 (prepare to execution failed)` + `DLL loading is not allowed`. O grafico ficou sem robo entre 06:01 e 06:05. Registo honesto: o reload nao e operacao inocua e tem de ser provado num grafico antes de correr nos 16.

**Causa.** `#import "sqlite3.dll"` incondicional no `Enterprise\DatabaseManager.mqh`, resolvido no carregamento, com `EnableDatabase=false` em todos os graficos.

**Feito.** Import condicional por macro `XAI_USE_SQLITE_DLL`; stubs + mensagem clara quando a DLL nao existe.

**Compilacao.** `0 errors, 0 warnings`; `.ex5` 692594 -> 690004 B as 06:04:56.

**Reload provado e executado.** `chart_save_template` -> `chart_apply_template` em 16 graficos: 16 de 16 com `[VERSION] v1.2.72` entre 06:05:05 e 06:06:05. USDSGD restaurado as 06:05:05.

**Prova de autonomia durante a janela.** AUDUSD BUY 0.13 fechou por `Take profit` a `0.70298` com **+10.01 USD** as 06:01:16 (hora local): o alvo `LadderTpUsd=10.0` foi cumprido sem intervencao, com o EA a ser reanexado no mesmo minuto. Posicoes restantes as 06:07: USDJPY -0.08 (+7.36) e USDCAD -0.04 (+8.71), ambas com SL melhor que a entrada.

**Pendente.** Decidir o destino da base de dados SQLite (`-DXAI_USE_SQLITE_DLL` + DLL permitida, ou abandono formal); e confirmar nos 9 simbolos sem previsao que os dois relatorios dizem agora `fallback tecnico (nao bloqueia)`.

---

## Ciclo 57 - P1.59 (v1.2.73): leitura binaria do prediction JSON

- **Medido:** `FileReadString` sobre `FILE_TXT` devolve so a primeira linha; o JSON pretty-printed comeca com `{`
  na linha 1, logo a estrutura parecia invalida. 44 ficheiros no disco, 7 com previsao, 7 registos de erro.
- **Feito:** `DiagnosticsReadWholeFile` -> `FILE_BIN` + `FileReadArray` + `CharArrayToString(CP_UTF8)`;
  helper `DiagnosticsJsonStructureOK` usado nos dois blocos.
- **Validado:** 15330 -> 16198 B; compilacao `0 errors, 0 warnings`; `.ex5` 691706 B; 16/16 graficos em
  `v1.2.73`; **0** ocorrencias de `sem estrutura basica` apos o reload (antes: 35 em 05:38-06:06).
- **Aviso resolvido:** 3 x `warning 86` na linha 63 do `VersionManager.mqh` (barras invertidas duplicadas).

## Ciclo 58 - P1.60 (v1.2.74): o veredicto da previsao passa a ser o do motor

- **Medido:** `AIConnector.mqh:420` rejeita previsao com idade > `MaxPredictionAgeSec` (900 s). As duas
  checklists davam PASS/READY por o ficheiro existir, com 600 h de idade - o mesmo ficheiro que o motor
  descartava. Duas verdades sobre o mesmo dado.
- **Feito:** novo `PredictionAgeSeconds` na Production; item 5 e item 4 da Validation passam a usar
  `MaxPredictionAgeSec`, com `STALE` explicito e `fallback tecnico (nao bloqueia)`; critico apenas quando
  `RequireAIJSON=true`, dos dois lados.
- **Validado:** compilacao `0 errors, 0 warnings`; `.ex5` 694266 B (06:23:52); mapeamento template->simbolo
  conferido antes do reload; 16/16 graficos em `v1.2.74`; journal mostra
  `idade=2103814s > MaxPredictionAgeSec=900s` nos 7 simbolos com ficheiro.
- **Aberto:** previsoes em disco de 08/10/2026 (24 dias); enquanto o pipeline nao escrever, os 16 operam em fallback.

## Ciclo 59 - P1.61 (v1.2.75) - portao de negociacao, fonte unica

- MEDIDO: primeiro [TRADE BLOCK] do dia as 06:05:05.800, 0,7s depois de o
  USDSGD recarregar as 06:05:05.056 (recompilacao). Antes disso o EA negociava
  (deals as 01:00:09 e 02:00:09, fecho as 04:46:27 no log do terminal).
- MEDIDO as 08:09, mesmo instante, tres vereditos: producao PASS, validacao
  BLOCKED, portao BLOCKED, com experts_trade_allowed=true no terminal.
- FEITO: Core/TradeGate.mqh (ETradeGate + CTradeGate: Mql, Terminal, Account,
  Expert, Connected, Evaluate, Ok, Bits, Cause, Describe).
- FEITO: OnTick, ProductionChecklist item 2 e ValidationChecklist item 13
  passam a ler a mesma funcao; a mensagem nomeia o bit que falta.
- FEITO: v1.2.75 no cabecalho, #property version 1.275 e EA_VERSION_STRING.
- PROVA: 08:14:19.149, nos 16 simbolos, "Trading barrado pelo PROPRIO EA ...
  | MQL_TRADE_ALLOWED=0 TERMINAL_TRADE_ALLOWED=1 ACCOUNT_TRADE_ALLOWED=1".
- REJEITADO por medicao: a hipotese do template com expertmode sem o bit.
  16 templates com expertmode=5 reaplicados as 08:14:18-19, chart nova anexada
  por API as 08:15:28, template gravado pelo chart vivo e os .chr do perfil -
  todos a 0. cmp_tpl.ps1 provou cabecalhos <expert> identicos.
- ABERTO: MQL_TRADE_ALLOWED so se religa pela janela de propriedades do EA
  (caixa de negociacao algoritmica) ou por reanexacao manual pela GUI.
  Nenhuma API MQL5 escreve este bit. Nada negoceia enquanto isso.

## Ciclo 60 - P1.62 (v1.2.76) - um dado, um veredito

- MEDIDO as 08:17: Common\Files\XAU_AI_PRO_heartbeat.json com
  "autotrading":true e as 16 charts bloqueadas por MQL_TRADE_ALLOWED=0. O campo
  vinha so de TERMINAL_TRADE_ALLOWED; o texto do ExternalBridge tambem
  (autotrading=on); o SystemStatus publicava bits crus sem veredito;
  ConnectionGuard testava 2 dos 5 bits.
- FEITO: EAHeartbeat com autotrading = CTradeGate::Ok() e novos campos
  terminal_trade_allowed e trade_gate_code.
- FEITO: ExternalBridge com autotrading do portao, terminal_trade_allowed e
  trade_gate no texto de estado.
- FEITO: SystemStatus com trade_gate_ok e trade_gate_code ao lado dos bits.
- FEITO: ConnectionGuard::ConnAlgoAllowed() passa a CTradeGate::Ok().
- FEITO: comentario do TradeGate corrigido (a hipotese rejeitada deixou de ser
  afirmada como causa) e mensagem TG_MQL_OFF com o remedio certo.
- FEITO: v1.2.76 (cabecalho, property 1.276, EA_VERSION_STRING e changelog).
- COMPILADO: 0 errors / 0 warnings, producao 699784 B as 08:31:02.
- MEDIDO E NOVO: recompilar nao recarrega EAs. De 08:31 a 08:34 as 16 charts
  continuavam com a mensagem antiga de 3 bits ("1.2.76"=0 ocorrencias). Depois
  de reaplicar os 16 templates as 08:34:24: 48 ocorrencias de "1.2.76" e
  mensagem nova de 5 bits.
- PROVA: heartbeat as 08:34:24 - "autotrading":false,
  "terminal_trade_allowed":true, "trade_gate_code":3 (TG_MQL_OFF). O ficheiro
  que um supervisor externo le passou a contar a verdade.
- PENDENTE: Core\TradeGate.mqh ainda nao esta listado no .mqproj (o ficheiro
  usa LF; insercao com ancora CRLF falhou). Nao afeta a compilacao.
## Ciclo 61 - P1.63 (v1.2.77) - um dado, um veredicto no diagnostico

- MEDIDO ANTES: Diagnostics.mqh, bloco PERMISSOES, lia UM dos cinco bits
  (TERMINAL_TRADE_ALLOWED) e imprimia "Permissoes: VERDE" as 08:34, no mesmo
  minuto em que o heartbeat gravava "trade_gate_code":3 (TG_MQL_OFF) e as 16
  charts imprimiam MQL_TRADE_ALLOWED=0. Dois veredictos para o mesmo facto.
- INVENTARIO: scan_bits_p163.ps1 -> "TOTAL ocorrencias de bits crus = 48 |
  ficheiros analisados = 105" (TradeGate.mqh 14 por desenho).
- FEITO: Diagnostics.mqh inclui Core/TradeGate.mqh; o bloco PERMISSOES passa a
  CTradeGate::Evaluate() e publica CTradeGate::Cause() - a causa, nao o bit.
- FEITO: v1.2.77 (cabecalho, property 1.277, EA_VERSION_STRING e changelog;
  a entrada v1.2.76 preservada).
- FEITO: 72.5 encerrado - Core\TradeGate.mqh registado no .mqproj (files
  102 -> 103, posicao 25, JSON valido antes e depois, NUL=0, "MQPROJ: OK").
- COMPILADO: 0 errors / 0 warnings, cpu X64 Regular, 15981 ms; producao
  699784 B (08:31:02) -> 700372 B (08:48:49).
- DEPLOY: 16 templates xai_p159_01..16 reaplicados as 08:52:31-08:52:38.
  Journal: 64 registos "[VERSION] v1.2.77" (4 por chart) e a linha de 5 bits
  a disparar nas 16 charts.
- PERIGO DE METODO CORRIGIDO: o calculo do EOL dominante feito DEPOIS da
  edicao virou dois ficheiros para LF (Diagnostics 15777 B, .mq5 75095 B).
  fix_eol_p163.ps1 repunha CRLF; ficam 16566 B / CRLF=789 / LF soltos=0 e
  77402 B / CRLF=2307 / LF soltos=0. Regra nova: EOL dominante mede-se antes
  da edicao.
- INTOCADO: risco, spread 0.6, confianca 60.0, score 65.0, portao de IA 0.05,
  modelos em Files\XAU_AI_PRO\Python\models e frontend\dist.
- PENDENTE: o bloqueio real continua a ser MQL_TRADE_ALLOWED=0 (4 bits a 1).
  Sem API para o escrever: exige um clique humano por chart ou reanexar pela
  GUI. Ate la, 0 posicoes e 0 ordens, e a prova de autonomia fica bloqueada.
- FILA: alinhar os restantes leitores de bits crus (SystemStatus 54-56,
  Diagnostics 142, ProductionChecklist 285, ValidationChecklist 221,
  FailureMode 127/129, RecoveryManager 254/262/283, CircuitBreaker
  350/351/584/585, ConnectionGuard 47/64/67, EAHeartbeat 40, ExternalBridge 189).


## Ciclo 62 - P1.64 (v1.2.78) - TG_DISCONNECTED: o portao nao olhava para a ligacao

Fechado o item "auditar as duas checklists a procura de um dado com dois
veredictos". O resultado da auditoria nao foi o esperado: as linhas de
PERMISSOES ja estavam alinhadas desde o P1.61/P1.63 (ambas leem
`CTradeGate::Evaluate()`/`Describe()`). O defeito estava noutro sitio - o bit da
LIGACAO, que nenhum dos tres sitios lia pela fonte unica e que o proprio portao
nao testava.

- Defeito: `CTradeGate::Evaluate()` testava 4 bits e ignorava `TERMINAL_CONNECTED`.
  Terminal desligado + 4 bits a 1 -> `TG_OK` ("Trading permitido"), enquanto
  Diagnostics dizia `Terminal nao conectado`, ProductionChecklist item 0 dizia
  `Terminal desconectado` e ValidationChecklist item 8 dizia
  `Terminal desconectado (bloqueia)`.
- Correcao: `TG_DISCONNECTED = 5` (acrescentado no fim do enum, sem renumerar),
  testado antes dos outros quatro; os tres sitios passam a
  `CTradeGate::Connected()` + `CTradeGate::Cause(TG_DISCONNECTED)`.
- Codigo: Diagnostics.mqh 16615 B, ProductionChecklist.mqh 25790 B,
  ValidationChecklist.mqh 15080 B, TradeGate.mqh 5767 B, XAU_AI_PRO.mq5 77402 B
  (v1.2.78 / `#property version "1.278"`), VersionManager.mqh 60973 B.
  LF_soltos=0, NUL=0, CRCR=0 em todos.
- Compilacao: `Result: 0 errors, 0 warnings, 15607 ms elapsed`; .ex5 700372 ->
  702120 B as 08:58:30.
- Deploy: 16 templates reaplicados; 64 registos `[VERSION] v1.2.78` no journal
  (4 por chart, 16/16) entre 08:58:39.735 e 08:58:46.732.
- Conta 113568614: 0 posicoes, 0 ordens, saldo/equity 12357.54 USD.
  `MQL_TRADE_ALLOWED=0` continua a barrar tudo - ato humano, nao codigo.

FILA:
- Alinhar os restantes leitores de bits crus (SystemStatus 54-56, FailureMode
  127/129, RecoveryManager 254/262/283, CircuitBreaker 350/351/584/585,
  ConnectionGuard 47/64/67, EAHeartbeat 40, ExternalBridge 189) - apenas se a
  medicao mostrar divergencia de veredicto; sao estado/diagnostico, nao permissao.
- Modelos: 39 modelos, 0 READY (28 STALE, 11 ERROR not_publishable). Portao de
  edge 0.05 intocado.
- Fechar a prova de autonomia: exige `MQL_TRADE_ALLOWED=1` (humano).

## Ciclo 63 - P1.65 (v1.2.79) - [TRADE BLOCK] a dizer a verdade sobre o bit que falta

- Medido as 09:00 no mesmo instante: `terminal_get_info` -> `experts_trade_allowed=true`,
  `mcp_trade_allowed=true`; as 16 charts -> `TERMINAL_TRADE_ALLOWED=1` e
  `MQL_TRADE_ALLOWED=0`. O botao Algo Trading do terminal esta LIGADO; falta o
  bit POR PROGRAMA.
- A mensagem de `TG_MQL_OFF` mandava o operador para as "propriedades do EA" -
  sitio nao medido. Passa a separar MEDIDO / POR TESTAR / REJEITADO.
- Ficheiros: TradeGate.mqh 6468 B (CRLF 120), XAU_AI_PRO.mq5 77402 B (v1.2.79),
  VersionManager.mqh 61418 B. LF_soltos=0, NUL=0, CRCR=0. Backups `.pre_p165`.
- Compilacao: 0 errors, 0 warnings (15817 ms); .ex5 702120 -> 702612 B as 09:01:35.
- Deploy: 16 templates; 48 registos `v1.2.79` no journal (3 por chart, 16/16);
  mensagem nova confirmada as 09:01:39.955+.
- Conta: 0 posicoes, 0 ordens, 12357.54 USD. Nada negoceia - `MQL_TRADE_ALLOWED=0`.

FILA:
- Testar as duas hipoteses que restam (botao Algo Trading da barra; reanexacao
  pela GUI). Ambas exigem humano, nao ha ferramenta MCP.
- Alinhar leitores de bits crus restantes apenas se a medicao mostrar divergencia.
- Modelos: 39, 0 READY (28 STALE, 11 ERROR). Portao de edge 0.05 intocado.

---

## Ciclo 64 - P1.66 (v1.2.79) - a IA medida: 58 combinacoes, zero edge, e a execucao depende de UM bit

Pedido do dono: "ligar auto trader e comecar concluir IA".

O que foi feito:

- Medido o bloqueio: heartbeat 298 B (write_count=1) com `autotrading=false`,
  `terminal_trade_allowed=true`, `trade_gate_code=3`; journal 13:24:13-13:27:27
  com `[TRADE BLOCK] ... MQL_TRADE_ALLOWED=0` nos 16 graficos. Uma accao GUI
  religa; nenhuma API MQL5 escreve esse bit.
- CORRIGIDA uma premissa minha: `AIGateRequired()` em `AI\AIEngine.mqh:47-58`
  devolve false com `EnableAutonomousMode=true`, que e o valor nos 16 graficos.
  A IA e consultiva: NAO bloqueia entrada. O dinheiro real esta preso a UM bit,
  nao a dois.
- Descoberto o dataset real: `Files\Data\dataset_mt5_20261101.csv`,
  138.869.179 B, 1.494.248 linhas, 16 simbolos, 2009->2026, zero linhas
  invalidas. O `dataset.csv` que o pipeline usava por padrao tem 10.893 linhas
  de um dia e 418+ linhas malformadas.
- Medido o edge com `Files\Temp\medir_edge_v2.py` (nao grava modelo):
  58 combinacoes simbolo x timeframe, piso 0,05 intocado, ZERO publicaveis.
  Melhores: USDBRL H1 +0,1124 (folds 1/5), USDRUB M5 +0,0682 (folds 1/5),
  USDRUB M15 +0,0376, USDCOP M5 +0,0364, USDSEK M15 +0,0357 (5/5 mas abaixo
  do piso). Piores: USDCNH H4 -0,2370, EURUSD H4 -0,1493.
- Diagnosticado o transporte da IA em tres pontos: porta 9001 tomada pelo
  servidor MCP (pid 2440 terminal64, 401 MetaTrader5-MCP), rota canonica e GET
  enquanto o EA envia POST, e fastapi/uvicorn ausentes do py311.

O que NAO foi feito, e por que:

- Nao retreinei: medir primeiro provou que publicar os novos modelos seria
  trocar 28 STALE por 58 ERROR. Os 515,1 MB de `Python\models` ficaram
  intocados, como manda a regra.
- Nao baixei o piso de edge 0,05 nem `MinAIConfidence` 60, `BlockZeroAIScore`,
  `MaxSpreadPct` 0,6, `MinMarketScore` 65, `MaxPredictionAgeSec` 900.
- Nao alterei nenhum `.mq5`/`.mqh`: nao houve nada medido que justificasse
  recompilar os 16 graficos outra vez.

Provas: PENDENCIAS secao 76; `Files\Temp\medir_edge_v2.py` reproduz a tabela.

## Ciclo 65 - P1.67 (v1.2.80) - um dado, um veredicto: o "sem tick" deixa de envenenar o watchdog

**O que estava errado.** Tres das 16 instancias (USDBRL/M5, USDCOP/H1,
USDCLP/H1) recebem 0 ticks porque o feed do broker nao as serve. O
`HealthMonitorCheckTickTimeout(15)` ja perdoava isso desde a v1.2.31 quando a
sessao esta fechada, mas o `HealthMonitorCheckHeartbeats()` nao tinha guarda
nenhuma. Como ATR/ADX/RSI/IA so avancam dentro de `OnTick`, sem tick falhavam
sempre, `healthy` ia a false e `g_healthConsecutiveFails` subia ate 11 ->
`HealthGetBackoffInterval` -> 1920 s. O watchdog ficava cego 32 minutos e o
journal mostrava, na mesma janela, HEALTHY e FAILURE para o mesmo `Total ticks: 0`.

**O que mudou.** `Monitoring\HealthMonitor.mqh`: o resultado do teste de tick
passa a ficar guardado (`bool tickEmFalta`) e a falha dos heartbeats so propaga
a `healthy` quando HOUVE tick. Mais o bump de versao (`1.2.80`) e o changelog.
26818 -> 27996 B; CRLF 925 -> 945; LF_soltos 0; NUL 0.

**Build.** Primeira tentativa: 40 errors - o changelog entrou com aspas duplas
cruas dentro do literal MQL5 e o MetaEditor apagou o `.ex5` de producao.
Corrigido (linha 63 reescrita sem aspas internas) e recompilado:
`0 errors, 0 warnings`, `.ex5` 703094 B, 14:16:47. Binario bom guardado em
`Files\Backup\XAU_AI_PRO_v1280_ok.ex5`.

**Deploy.** O MT5 nao recarregou sozinho. Reanexei os 16 graficos por API com os
defaults compilados (identicos aos valores em uso, verificado input a input) e as
16 instancias reportam `v1.2.80`.

**Nao feito, de proposito.** Nao mexi no transporte da IA (porta 9001 ocupada
pelo servidor MCP, rota GET vs POST, fastapi ausente): com
`EnableAutonomousMode=true` a IA e consultiva e tem efeito ZERO no dinheiro.
Nao baixei o piso de edge 0,05. Nao toquei em `Python\models` nem em
`frontend\dist`. Nenhum input de risco alterado.

Provas: PENDENCIAS secao 77; `.pre_p167` de cada ficheiro.

**Verificacao pos-deploy (14:18-14:32).** `FAILURE`: 0 registos. `Backoff` dos
graficos de 0 ticks passou de `nivel=11 intervalo_efetivo=1920s` para
`nivel=0 intervalo_efetivo=60s` (USDBRL/M5, USDCOP/H1, USDRUB/H1). Arranque com
16/16 `HEALTHY`, incluindo os de `Total ticks: 0`. Cadencia do resumo: 2 min em
vez de 32 min. Criterio de 77.8 cumprido.


## Ciclo 66 - P1.68 (v1.2.81) - o journal comeca a caber numa leitura

Medido primeiro, no `MQL5\Logs\20261102.log` do dia: 138 702 linhas, 15,5 MB.
A contagem literal mostrou que nenhuma das linhas grandes era evento:
`[SCANNER] BLOCK` 18 532, `SYMBOL MANAGER` 7 955, `[TRADE BLOCK]` 7 272,
586 blocos `SYSTEM STATUS` e 152 blocos `HEALTH MONITOR` (14 e 20 linhas cada).
Quatro correcoes, todas de impressao: retratos numa so linha
(`JournalOneLine`), gate do `[TRADE BLOCK]` por CAUSA (1x/10 min em vez de
1x/60 s), detalhe `[SCANNER] BLOCK` por mudanca de desfecho com heartbeat de
30 min, e `SYMBOL MANAGER | Resolved` so quando ha remapeamento real.

Build: `Result: 0 errors, 0 warnings, 18719 ms elapsed`. `.ex5` 706646 B as
15:51:26, os 16 graficos religados pela API e a reportar `[VERSION] v1.2.81`.

**Verificacao medida (15:42-15:52 vs 15:53:30-15:59:30).** Antes: 201 linhas
em 10 min, 118 delas `[TRADE BLOCK]` (11,8/min). Depois: 16 linhas em 6 min,
zero `[TRADE BLOCK]`. O mesmo retrato continua a sair, agora em 1 linha:
`[STATUS] HEALTHY | === RECOVERY STATUS === | ... | FreeMargin: 12535.64`.

Nada de risco, lote, spread, entrada ou saida foi tocado. `Python\models` e
`frontend\dist` intocados.

## Ciclo 68 - P1.70 (v1.2.83) - journal minimo: 3 181 + 948 + 625 + 316 linhas de retrato trocadas por evento

Medido antes: 149 054 linhas no Logs de 02/11, das quais QUANT MATRIX 316, BACKTEST ANALYZER 948, BENCHMARK 625, [SESSION] estado salvo 3 181. Nenhuma era evento: eram 16 instancias a repetir a mesma tabela no encerramento e o mesmo estado a cada 5 minutos.

Feito, so de impressao: (1) QuantSummary, Benchmark LogComparison e a linha final do BacktestAnalyzer passam a sair apenas no tester (os ficheiros em FILE_COMMON continuam a ser gravados); (2) `[SESSION] estado salvo` imprime so quando o resumo muda, com heartbeat de 30 min.

Prova: XAU_AI_PRO.mq5 79 783 -> 81 363 B (CRLF 2 359 -> 2 386), BacktestAnalyzer.mqh 9 288 -> 9 399 B (407 -> 409), VersionManager.mqh 64 784 -> 65 539 B, LF_soltos 0, NUL 0. Build 0 errors / 0 warnings, EX5 706 940 B, `[VERSION] v1.2.83` nos 16 graficos. Janela limpa depois do reload: QUANT MATRIX 0, BENCHMARK 0, BACKTEST ANALYZER 0 (antes, no mesmo tipo de arranque: 16 / 32 / 48).

O dinheiro continua parado por um bit que nenhuma API escreve: `MQL_TRADE_ALLOWED=0` com `TERMINAL_TRADE_ALLOWED=1` (`trade_gate_code=3`). Neste ciclo ficou provado que `expertmode=5` e `expertmode=7` num template aplicado ao proprio grafico NAO acendem esse bit nesta build 6294. Falta a caixa "Permitir Algo Trading" (F7) em cada grafico.

## Ciclo 69 - P1.71 (v1.2.84) - push desligado e carimbo de deinit

Medido no journal do dia (161 928 linhas): `[NOTIFY]` 1 850 (push do terminal DESLIGADO, `SendNotification` chamado na mesma, erro 4517 sempre) e `DATA LOGGER OFFLINE` 364 (linha de `OnDeinit` mesmo sem ficheiro aberto).

Correcao minima, so de impressao e uma chamada evitada: `SendPush()` le `TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)` antes de chamar `SendNotification` e, com o push desligado, imprime UMA linha por sessao e devolve `false` (o mesmo valor de antes, logo nenhum chamador muda); `DataLoggerClose()` so imprime a linha quando havia mesmo ficheiro aberto.

Prova: NotificationCenter.mqh 14 254 -> 15 311 B (CRLF 442 -> 462), DataLogger.mqh 12 118 -> 12 132 B (604 -> 603), VersionManager.mqh 65 539 -> 66 456 B, XAU_AI_PRO.mq5 81 363 -> 81 363 B. LF_soltos 0 e NUL 0 em todos. Build `0 errors, 0 warnings`, EX5 706 940 -> 708 374 B, 16/16 graficos reanexados, `[VERSION] v1.2.84` confirmado. Janela >= 16:38: `DATA LOGGER OFFLINE` 0, `[SCANNER]` 0.

## Ciclo 67 (registo em atraso) - P1.69 (v1.2.82) - um dado, dois veredictos de saude

O journal imprimia `[HEALTH] WARNING` e `Status: HEALTHY` na mesma linha nos graficos sem tick. `HealthGetState()` passou a contar as falhas de watchdog so quando houve tick nos ultimos 15 s, e a linha `Status` passou a ler `HealthGetStateString()`, a mesma fonte do tag. Prova: HealthMonitor.mqh 27 996 -> 29 106 B (CRLF 945 -> 960). Verificado: 16 instancias com `[HEALTH] HEALTHY`, filtro `HEALTH MONITOR` com 0 registos.

## Ciclo 70 - P1.72 (v1.2.85) - a repeticao que sobrou, medida e cortada

**Medido antes** (17:50-18:50, 59 min, 586 linhas): [TRADE BLOCK] 68,1/h, [SESSION] 34,6/h,
[LOGGER OFFLINE] 33,6/h, [CIRCUIT] 33,6/h, [LEARN] 32,5/h, AI GATEWAY 32,5/h, [BACKUP]
21,4/h, [HEALTH] 17,3/h. [SCANNER] 0/h - os portoes do P1.68 estao a funcionar.

**Corrigido** (7 pontos, so impressao): janela do [TRADE BLOCK] 600->3600 s; [SESSION]
1800->3600 s; [CIRCUIT] BROKER OK so em rajada relevante (3+ leituras ou 60+ s); [LEARN]
3600->14400 s; [BACKUP] STANDBY 3600->14400 s; SYSTEM STATUS WRITE ERROR 1x/sessao com
codigo (5004 = ficheiro de estado ocupado por outra instancia); AI GATEWAY erro duro
1800->14400 s.

**Validado**: 0 errors / 0 warnings; EX5 709836 B; 16/16 graficos com [VERSION] v1.2.85;
heartbeat inalterado em trade_gate_code=3.

**Correcao de metodo**: o filtro de janela que usei antes lia os minutos com
Substring(Index+5,2) e delimitava mal as janelas. Totais do dia intactos, taxas por janela
recalculadas com regex de hh:mm:ss.

**Continua bloqueado (nao e codigo)**: MQL_TRADE_ALLOWED=0 -> trade_gate_code=3. Precisa de
um acto humano no grafico: F7 > aba Geral > marcar "Permitir Algo Trading" > OK.
## Ciclo 71 - P1.73 (v1.2.86) - journal por CONTA

- Medicao: 171 949 linhas no journal de 02/11; [TRADE BLOCK] 7 598 (5 253 delas TG_MQL_OFF),
  [LEARN] 6 088, [TRADE PIPELINE] 4 309, [VERSION] 2 381, [NOTIFY] 2 002, [HEALTH] 1 098,
  [LOGGER OFFLINE] 993, AI GATEWAY 885.
- Causa raiz do volume: 16 instancias x 1 linha/hora por tag = 16 linhas identicas por hora.
  O throttle tem de ser por conta e nao por grafico.
- Codigo: `Monitoring\AccountLogGate.mqh` (FILE_COMMON, fail-open) + 3 pontos religados em
  `XAU_AI_PRO.mq5` ([TRADE BLOCK] 120 s/3600 s, [SESSION] 600 s, [HEALTH] 3600 s com
  mudanca de estado a passar sempre) + `#property version "1.286"` + `EA_VERSION_STRING "1.2.86"`.
- Build: 0 errors / 0 warnings, 15 454 ms, EX5 711 602 B (antes 709 836 B, guardado em
  `Files\Backup\XAU_AI_PRO_v1285_ok.ex5`).
- Reload: template `XAI_P173.tpl` (56 054 B, 898 inputs intactos) aplicado aos 16 graficos.
  Confirmado no log: 16/16 com `v1.2.86 | build`.
- Prova de runtime: `Files\Common\XAU_AI_PRO\loggate_health.bin`, `loggate_session.bin` e
  `loggate_tradeblock_nova.bin` com 8 B cada e mtime 19:07:45 / 19:10:59.
- Risco: nenhum parametro de risco, lote, spread, alvo ou preco alterado.
- Aberto: `trade_gate_code=3` (bit POR PROGRAMA). Os 16 `.chr` tem `expertmode=5`
  (= EA on + DLL, negociacao ao vivo OFF). Precisa de 7, marcado no dialogo F7.

## Ciclo 72 - P1.74 (v1.2.87) - um arranque, dez linhas

- Medicao de entrada: 171 952 linhas no journal de 02/11, 55,5% sem tag; 227 linhas
  por arranque de instancia; 1 083 linhas num reload de 16 graficos.
- Alteracoes: SymbolManager 57->1, BrokerAnalyzer 20->1, BrokerInfo 5->1,
  EnvironmentManager 8->1, PathManager 8->2, BrokerConfig 7->1, cabecalho do OnInit
  9->1, Checklist 23->1, Compatibilidade 16->1, memoria aprendida 11->1, resumo de
  saude 8->1, resumo de backtest 4->1, mais 20 separadores decorativos removidos.
- Validacao: compilacao 0 errors / 0 warnings (15 927 ms), EX5 717 372 B, backup do
  binario anterior em Files\Backup\XAU_AI_PRO_v1286_ok.ex5.
- Prova de runtime: 16/16 instancias em v1.2.87; 96 linhas por instancia no reload;
  1 532 linhas no reload completo contra 2 159 na v1.2.86; 23% sem tag contra 55,5%.
- Nada de risco foi tocado: RiskPercent, MaxDailyLossPercent, MaxDailyLossUsd,
  MaxDrawdownPercent, MaxSpreadPct, MinAIConfidence, MinMarketScore,
  MaxPredictionAgeSec, MaxTradesPerDay, MaxOpenPositions, Ladder*, DailyProfitTarget*
  e AvoidHoursGMT continuam com os mesmos valores nos 16 graficos.
## Ciclo 73 - P1.75 (v1.2.88) - o encerramento numa linha
- Medicao de entrada: janela de 1 534 linhas com 357 sem tag (23,3 por cento); 21 linhas sem tag por encerramento de instancia.
- Alteracoes: OnDeinit 5 linhas -> 1 [STOP] com simbolo/motivo/equity; SystemManager sem INITIALIZING/SYSTEM READY/SYSTEM CLOSED; DataLogger -> [DATA]; BacktestAnalyzer -> [BT] e resumo so com trades; TradeLogger -> [TRADELOG]; MTF 8 linhas -> 1 [MTF]; AIConnector -> [AI].
- Validacao: 0 errors / 0 warnings (16 011 ms), EX5 718 070 B, backup v1288.
- Prova de runtime: 16/16 em v1.2.88; 94/1 200 sem tag (7,8 por cento) contra 357/1 534 (23,3 por cento).

## Ciclo 74 - P1.76 (v1.2.89) - as duas ultimas linhas sem tag
- Medicao de entrada: 94 sem tag, das quais 62 eram o deinit antigo v1.2.87; sobravam "Inicializando modulos..." (16) e "SYMBOL MANAGER | AVISO P1.19" (5).
- Alteracoes: linha 361 do .mq5 vira comentario; aviso do SymbolManager -> [SYMS] AVISO; permDetail do diagnostico deixa de chamar CTradeGate::Cause (900 caracteres x 16 por arranque) e passa a "codigo=N | causa completa em [TRADE BLOCK]".
- Validacao: 0 errors / 0 warnings (16 082 ms), EX5 719 152 B, backup v1289.
- Prova de runtime: 32/1 292 sem tag (2,5 por cento); [STOP]=12; codigo= 16.

## Ciclo 75 - P1.77 (v1.2.90) - o journal deixa de ter linha sem tag
- Medicao de entrada: 32 sem tag, todas do AIConnector (11 mensagens com nome proprio, fora do vocabulario [TAG]).
- Alteracoes: prefixo [AI] nas 11 mensagens; "FILE NOT FOUND" -> "FILE EM FALTA" e "JSON EMPTY" -> "JSON VAZIO".
- Validacao: 0 errors / 0 warnings (16 132 ms), EX5 720 204 B, backup v1290.
- Prova de runtime: SEM_TAG = 0 em 1 280 linhas; [AI] 44 -> 74.

## Ciclo 76 - v1.2.92 / P1.79: journal 9,2% -> 0,1% sem tag (02/11/2026 20:28)

- Medido antes (20:16, 4 000 linhas): 366 sem tag (9,2%), [SCANNER] 116, [TRADE PIPELINE] 120, [LEARN] 243, [LOGGER OFFLINE] 82.
- Medido depois (20:27, 900 linhas): 1 sem tag (0,1%), [TRADE PIPELINE] 42, [SCANNER] 29, [LEARN] 61.
- 19 ficheiros alterados, compilacao 0/0, EX5 727 644 bytes, backup v1292.
- Escrita com ReadAllBytes + UTF8.GetString + UTF8Encoding(false): o BOM sobreviveu (provado True/True em AntiLoop, ExecutionStats, ExecutionQuality, Scheduler, PathManager) e nenhum NUL foi introduzido.
- Ancora multilinha agora tenta CRLF quando a contagem LF falha: os 3 primeiros falhanÃ§os foram so isso, nada foi gravado (abortagem antes da escrita).
- Portao de dinheiro: 0 as 20:15 (operador), 3 as 20:26 (reload). Falta so o bit por programa; reload obriga a novo clique.
- Nao tocado: Files\XAU_AI_PRO\Python\models (515 MB), frontend\dist, portao 0.05, parametros de risco.

## Ciclo 77 - v1.2.93 / P1.80: o EA nao estava parado, estava sem setup (02/11/2026 20:48)
- MEDIDO no historico: 4 posicoes Expert hoje (USDJPY +3,25 | AUDUSD -8,90 | USDCAD +1,40 | AUDUSD +10,01 = +5,76 USD), ultima as 10:13:31.
- Janela das ultimas 120 000 linhas: SIGNAL_OK=212, VALIDATION_BLOCK=7 (5 TREND contramao ADX 39.8>=22.0 + 2 AVOID HOUR), SCANNER_BLOCK=1321 (NoSignal x120 em 7 simbolos).
- RESUMO 20:22-20:26: sinais=3..10 por minuto, trades=0, todos em AllowTrade.
- Portao: code=3 (TG_MQL_OFF) desde o reload das 20:26; terminal com experts_trade_allowed=true; 15 chr com expertmode=5.
- Entregue: SignalCore com tag [SIGNAL] e throttle por simbolo; v1.2.93 com 0 errors / 0 warnings; EX5 728 746 B; 15 graficos com [START] v1.2.93.
- Journal depois: SEM_TAG 1 em 1 499 (0,1%) - 'SYSTEM STATUS WRITE ERROR'.
- JSON: 6 BOM limpos, 1269/1269 validos.
- Nada de risco, lote, alvo, spread ou regra de entrada foi alterado neste ciclo.

## Ciclo 78 - v1.2.93 / P1.81: todos os JSON medidos, zero invalidos (02/11/2026 20:52)

- Pedido: "corrigir todo json validar todos". Medido em vez de presumido.
- 1322 ficheiros *.json (MQL5 1269 + Common 53); invalidos 0; com BOM 0;
  UTF-8 invalido 0; U+FFFD 0; caracteres de controlo 0; chaves duplicadas 0.
- Validador estrito (JavaScriptSerializer 64 MB) em vez de ConvertFrom-Json,
  que tem falso positivo com a variavel `$name` e nao le BOM.
- `Docs\version.json` 1.2.9 == `VERSION` 1.2.9: sem divergencia.
- Conteudo a resolver depois: 10 simbolos sem previsao, previsoes de 25 a 91 dias,
  9 apelidos mortos, `dataset_bytes` a apontar para o CSV lixo.
- Sem recompilar: o reload dos graficos devolve o portao a codigo=3 e apaga a janela
  em que o dono pode ligar o Algo Trading a mao.

## Ciclo 79 - v1.2.93 / P1.82: opcao B medida (ADX 0.0 e zero sinal em 8 de 11 simbolos) (02/11/2026 21:10)

- Lido o journal pela API em 20:56-21:00: o ADX le 0.0 **so** no USDCHF, que e o `_Symbol` do grafico dono do pipeline; os outros 10 simbolos leem 12.1 a 41.9.
- `[ADX] INIT ERROR` = 0 e `[ADX] CopyBuffer failed` = 0 na janela: a leitura vazia e silenciosa por construcao (`return 0.0` em dois pontos de `Indicators\ADX.mqh`).
- Causa do veto: `ADX_OK()` faz fail-open apenas com `adx < 0.0`; com `0.0` cai em `0.0 >= 18.0` = falso e **bloqueia**. Sem leitura virou veto.
- Dados frescos (ticks USDCHF 01:00-02:06, barra H1 02:00 com 266 ticks, 100000 barras H1): nao e warm-up nem feed parado.
- Sinal: 1 839 no dia, 1 771 (96,3%) do USDBRL congelado; AUDUSD 86; USDCAD 1; **8 simbolos com zero sinal em 21 h**.
- Sinais por hora: 00h-05h = 1 514, 06h = 49, 20h = 96, **07h-19h = 0** - coincidente com `AvoidHoursGMT=9,11,14,18,20,22`.
- Nada foi alterado no EA: 0 recompilacoes da producao, 0 reloads, 0 ordens. Portao continua em `trade_gate_code=0`.
- `Logs\20261102.log` foi truncado de 187 957 para 5 408 linhas durante a sessao; a partir de agora a medicao usa o journal da API.

## Ciclo 80 - v1.2.122 / P2.12: o fecho de um trade dizia o simbolo errado (03/11/2026 21:15)

- Retomada do trabalho por leitura do journal pela API (nao pelo ficheiro, que ja
  foi truncado uma vez): 15 graficos com XAU_AI_PRO, build 2026.11.04, conta demo
  113568614, balance 12 581,99, equity 12 581,48, 1 posicao aberta
  (#11222788311 USDCAD SELL 0.12, aberta as 21:00:05 pelo pipeline completo).
- Compilacao que faltava: o .ex5 em producao era das 12:13 e as fontes foram
  alteradas ate as 12:15 no ciclo anterior. `agent-toolkit.ps1 compile` as 21:10:36
  deu **0 errors / 0 warnings** (18 178 ms, X64 Regular) e republicou o binario.
- P1.82/P1.85 provados em producao: o `[SCANNER] RESUMO` das 21:06:33 traz
  `ADX(sem/ok)=0/4992` - 4 992 leituras de ADX sem uma unica ausencia, contra o
  `0.0` silencioso do USDCHF medido no ciclo 79 (hoje le 17,9). O fail-open de
  `ADX_OK()` deixou de ser necessario no caminho real.
- O gargalo continua a ser o funil de sinal, nao o ADX: `visitas=137 | sinais=0 |
  trades=0 | bloqueios=137 | CanOpen=12 Stale=12 NoSignal=113` e
  `SIG(sem/neutro)=0/1712`. Nada tocado: `AvoidHoursGMT` e o par RSI 45/55 em H1
  continuam pendentes de decisao do dono.
- Defeito MEDIDO e corrigido (P2.12): as 20:50:33 o fecho de um USDCHF de +10.00
  USD foi registado como `| [TRADE] | USDCOP | Statistics trade registrado | WIN |
  10.00` e a mesma linha saiu com USDCLP no mesmo instante. O prefixo do Logger e
  `_Symbol`, o simbolo do GRAFICO, e nao o simbolo NEGOCIADO, logo com 15 graficos
  o mesmo fecho ganhava 15 nomes e o journal atribuia lucros a simbolos que nao os
  tiveram. `StatisticsRegisterTrade` passa a receber o simbolo negociado e o ticket
  do deal (lidos do proprio deal no `OnTradeTransaction`) e a linha publica
  `negociado=<simbolo> | deal=<ticket>`.
- O aprendizado por simbolo nunca esteve em causa: `[AI MEMORY] USDCHF WR=40.0%
  MEM=-1.00` le do deal, nao do grafico. Nenhum contador, win rate, streak, lote,
  alvo, stop, spread, preco ou regra de entrada/saida foi alterado.
- Versao alinhada nos tres sitios: `EA_VERSION_STRING` 1.2.122, cabecalho do EA e
  `#property version` 1.322 (minor*100+patch). Compilacao final 21:13:37:
  0 errors, 0 warnings.
- Nao feito de proposito: reload dos 15 graficos. Ha posicao aberta com escada
  armada; o binario novo esta no disco e o reload fica para quando a posicao fechar
  ou o dono autorizar.
- Bloqueios do operador continuam os mesmos: `WebRequest` desligado no terminal
  (erro 4014) e `AIGatewayToken` vazio (HTTP 401 no gateway), por isso o `[RESUMO]`
  continua a dizer `IA=SEM PRECO`.

## Ciclo 81 - v1.2.125 / P2.13-P2.15: a mesma linha 15 vezes (03/11/2026 21:55)

- Retomada por journal da API, nao pelo ficheiro: 15 graficos com XAU_AI_PRO,
  build 2026.11.04, conta demo 113568614, saldo 12 592,02, 0 posicoes do EA.
  O defeito medido nao era de calculo: era a MESMA informacao impressa uma vez
  por grafico, porque cada instancia decide sozinha o que escreve.
- Rajadas medidas antes do trabalho: `[STATE] USDCAD | -> MANAGING` 11 vezes no
  mesmo segundo (21:15:14-21:15:15, no reload dos 15 graficos); `[STOP]` 15
  vezes as 21:29:47; `[VALIDATION] BLOCK ... contramao vetada | ADX
  indisponivel` 23 vezes no dia, uma por grafico a cada 5 minutos.
- P2.13 (v1.2.123): o `[STOP]` do `OnDeinit` passou a passar pelo portao por
  conta (1 linha por conta, por motivo, a cada 120 s); a PRIMEIRA observacao de
  um simbolo em `StateSet` (`idx < 0`) passou a portao de 1 h por conta+simbolo;
  a transicao REAL de estado manteve-se sem filtro e o STANDBY passou a avancar
  o carimbo em cada tentativa (antes abria o ficheiro do portao em cada tick nas
  14 instancias que nao sao donas do pipeline).
- P2.13 sozinho NAO resolveu, e a causa foi medida:
  `AccountLogGatePodeImprimir` le, compara e escreve sem bloqueio. Com o
  ficheiro do portao AINDA INEXISTENTE, as 15 instancias leem "nunca imprimiu"
  ao mesmo tempo e imprimem todas. Prova: reload das 21:29:47 = 15 `[STOP]`;
  reload das 21:32:13 com o MESMO codigo = 1 `[STOP]` (o ficheiro ja existia).
  O problema era o ficheiro novo, nao a condicao.
- P2.14 (v1.2.124): o unico motivo realmente simultaneo (REASON_RECOMPILE, 15
  graficos a reiniciar no mesmo instante) deixou de usar o portao e passou a ser
  decidido pela eleicao de dono do pipeline. Os restantes motivos (fecho de um
  grafico, mudanca de periodo ou de parametros) continuam no portao de 120 s por
  conta, que e onde a informacao e util.
- P2.14b (regressao apanhada em producao): no reload das 21:34:08 saiu ZERO
  `[STOP]`. `PipelineMasterChart()` devolve um id PUBLICADO que pode ja estar
  morto. `PipelineMasterFresh()` (id presente E batimento `_T` mais novo que
  `PIPELINE_MASTER_TTL_SEC` = 180 s) e, sem dono fresco, o chamador volta ao
  portao por conta. Garante pelo menos uma linha por reload, sem repor a rajada.
- P2.15 (v1.2.125): `ValidationLogAllowed` era por INSTANCIA (`VALIDATION_LOG_
  WINDOW` = 300 s, comentario de v1.2.16: "a janela vale por grafico"), logo o
  mesmo veto saia 15 vezes por janela. O corpo original foi renomeado para
  `ValidationLogAllowedLocal` (logica intacta: continua a gravar
  `g_validationLastBlock` antes de qualquer filtro) e o novo
  `ValidationLogAllowed` exige tambem `AccountLogGatePodeImprimir` com tag
  saneada para nome de ficheiro (`val_<simbolo>_<motivo>`, espacos/|/=/-/./%/>/</,
  trocados, 48 caracteres). No tester o portao e ignorado, para o backtest
  continuar a registar todos os vetos.
- Prova em producao: reload duplo forcado por troca de perfil (as duas copias de
  `chart01.chr` tinham 0 linhas de diferenca, portanto configuracao igual).
  21:53:59 e 21:54:06 com 15 `[START] XAU_AI_PRO v1.2.125` cada. Na janela
  21:53:50-21:54:20: `[STOP]` = 1 (21:53:56, motivo=9, USDBRL) e 0 no segundo
  reload (o portao de 120 s da conta ja estava tomado); `[VALIDATION]` = 2 (uma
  por reload, so o dono publica o resumo do DiagGate); `[STATE]` = 0 pela
  primeira vez num reload; STANDBY = 0; `[DATA] SEM LEITURA` = 1. Antes: 15
  `[STOP]` por reload e 23 vetos por janela.
- Leitura honesta do `[STOP]` = 0 no segundo reload: e o comportamento pedido
  (1 por conta / 120 s / motivo), nao perda de informacao - o dono do pipeline
  imprime e os outros 14 calam-se.
- Versao alinhada nos tres sitios: `EA_VERSION_STRING` 1.2.125, cabecalho do EA
  e `#property version` "1.325". Compilacoes: `agent-toolkit.ps1 compile` as
  21:48:23 e `metaeditor64 /compile` as 21:51, ambas **0 errors / 0 warnings**
  (X64 Regular); `agent-toolkit.ps1 check` em 108 fontes: UTF-8, chaves e
  `#include` sem problemas.
- Nada de risco alterado: nenhuma regra de entrada ou saida, lote, alvo, stop,
  spread ou preco. O reload foi feito com 0 posicoes do EA abertas.
- Commits `4499c33c` (P2.13/P2.14) e `ef02e1c8` (P2.15), empurrados para
  `github/main`.
- Defeito de PROCESSO descoberto: compilar com `metaeditor64.exe /compile` fora
  da instancia MetaEditor aberta NAO recarrega os graficos - o binario ficou em
  disco as 21:51 e o journal so mostrou v1.2.125 depois da troca de perfil as
  21:53:59. Quem valida por journal tem de confirmar o reload, nao a compilacao.
- Pendentes: o texto do motivo em `Filters/MarketScenario.mqh` repete a
  explicacao do cenario em cada linha, e o dump por simbolo do arranque ainda
  sai 15 vezes (uma por grafico) - nenhum dos dois foi tocado neste ciclo.
  Continuam tambem os bloqueios do operador: `WebRequest` desligado no terminal
  (erro 4014) e `AIGatewayToken` vazio (HTTP 401), por isso o `[RESUMO]` diz
  `IA=SEM PRECO`.

## Ciclo 82 - v1.2.126 / P2.16: o token do servidor MCP estava no codigo (03/11/2026 22:35)

- Defeito medido no journal, nao por leitura de codigo: `[MCP] servidor ativo |
  metodos=7/7 risk=ok ai=ok health=ok account=ok positions=ok checklist=ok
  gate=ok` as 21:44:59. O servidor MCP embutido do EA estava a correr nos 15
  graficos e a autenticar com o token literal `xau-mcp-local-2026`, escrito em
  `Core/Config.mqh:86` e portanto publico no GitHub desde sempre.
- Alcance: com o token publico, quem alcancasse o canal lia risco, conta,
  posicoes, saude e checklist (metodos de leitura) sem descobrir nada.
- P2.16 nao toca em trading: `EnableMCPServer` passa a **falso** por omissao (o
  servidor e opt-in), `MCPServerToken` passa a **vazio** no codigo - o token
  privado vai no input do grafico - e o valor antigo e **recusado em runtime**
  por XAU_AI_PRO.mq5, para fechar o canal sem depender de reconfigurar os 15
  graficos a mao.
- Prova em producao (reload duplo forcado por troca de perfil, 22:34:53 e
  22:35:00, 15 `[START] XAU_AI_PRO v1.2.126` cada): `[MCP] SHUTDOWN | ok=true |
  pedidos=1 | recusados=0` as 22:34:49 e **uma so** linha `[MCP] DESATIVADO |
  token literal publico recusado | defina um token privado no input
  MCPServerToken` as 22:34:53. Nenhum `[MCP] servidor ativo` novo. `[STOP]` = 1
  nas duas recargas (portao de 120 s da conta, P2.13). 0 posicoes abertas no
  momento do reload.
- Versao alinhada nos tres sitios: `EA_VERSION_STRING` 1.2.126, cabecalho do EA
  e `#property version` "1.326". `agent-toolkit.ps1 deploy` as 22:34:35: check
  em 108 fontes OK + **0 errors / 0 warnings** (21 659 ms, X64 Regular).
- README: o cabecalho dizia v1.2.41 / "1.241" desde outubro; passa a v1.2.126 /
  "1.326" e a explicar que a propriedade acompanha desde a v1.2.123
  (minor*100+patch).
- Commit `8d23ef84` empurrado para `github/main`.
- Pendente de operador (nao e codigo): para voltar a usar o servidor MCP
  embutido e preciso definir um token privado (8+ caracteres) no input
  `MCPServerToken` dos graficos e `EnableMCPServer=true`. Continuam tambem o
  `WebRequest` desligado (erro 4014) e o `AIGatewayToken` vazio (HTTP 401).

## Ciclo 83 - v1.2.126 / reattach do dono: 15 graficos -> 13 (03/11/2026 22:56)

Ciclo sem alteracao de codigo. Verificacao de estado depois de o dono reanexar o
EA nos graficos. Toda a evidencia vem do journal (`get_expert_journal`) e de
`list_open_charts`, nao de leitura de codigo.

- **Reattach medido**: `[STOP] XAUUSD | motivo=1` as 22:53:50.739, `[MCP]
  SHUTDOWN | ok=true | pedidos=1 | recusados=0` as 22:53:50.736 e depois
  `[START] XAU_AI_PRO v1.2.126` escalonado de 22:53:51.376 a 22:54:49.286, cerca
  de 3 s entre graficos (XAUUSD, USDCLP, USDCOP, USDSEK duas vezes, USDJPY,
  USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD, USDBRL, USDRUB,
  USDSGD). Antes houve um reload as 22:38:28-30 com 15 `[START]`.
- **13 graficos abertos, nao 15**: XAUUSD H1, USDSEK, USDJPY, USDCHF, USDCZK,
  USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD, USDBRL M5, USDRUB, USDSGD. USDCLP e
  USDCOP deixaram de estar abertos: USDCOP registou `[STOP] USDCOP | motivo=4`
  (chart close) as 22:54:04.725 e o fecho do USDCLP caiu na mesma janela de
  120 s, portanto foi deduplicado pelo portao do P2.13 (1 linha por conta,
  motivo e janela) - comportamento pedido, nao perda de informacao.
- **P2.16 confirmado em producao**: zero linhas `[MCP] servidor ativo` em todo o
  intervalo, apenas 2 `[MCP] SHUTDOWN | ok=true`. O servidor embutido nao volta
  a arrancar com o token literal publico, mesmo com os graficos reanexados.
- **P2.15 confirmado em producao**: 3 linhas `[VALIDATION] 1 BLOCKED
  (diagnostico de init...)` em 22:35:00.697, 22:38:30.139 e 22:54:43.398,
  todas com source USDRUB - exatamente uma por reload, de um unico simbolo, em
  vez das 15 por reload de antes.
- **Pipeline master correto apos o reattach**: `[PIPELINE] STANDBY | esta
  instancia nao e a dona do pipeline | esta=35819098702235 |
  dono=22884787070177` as 22:54:03.030. O dono e o chart01 XAUUSD (22884787070177),
  portanto a guarda `EnablePipelineMasterGuard` esta a funcionar com os ids
  novos do perfil aplicado.
- **Saude**: `[HEALTH] HEALTHY | uptime=30s | checks=0 | sem tick=0s` as
  22:54:21.998; `[BACKUP] Backup concluido com sucesso | arquivos=99` as
  22:54:22.468.
- **Conta**: 113568614, saldo/equity 12 592,02 USD, 0 posicoes, 0 ordens,
  dia +22,94 de 40,00 USD (57%), `IA=SEM PRECO`. `[RESUMO] master=SIM |
  posicoes: 0 EA (+0.00 USD) + 0 manual`.
- **Inputs de risco inalterados pelo reattach**: `EnableMCPServer=false`,
  `MCPServerToken=` e `AIGatewayToken=` vazios nos 13 graficos,
  `AvoidHoursGMT=9,11,14,18,20,22`, `MinimumADX=18.0`,
  `RSIPullbackBuy=45.0`, `RSIPullbackSell=55.0`,
  `ScenarioCounterTrendMaxADX=22.0`, `DailyProfitTargetMaxUsd=40.0`,
  `EnablePipelineMasterGuard=true`.
- **Funil continua o gargalo** (nao o ADX): `[SCANNER] RESUMO | visitas=165 |
  sinais=0 | trades=0 | bloqueios=165 | Stale=10 NoSignal=155 |
  ADX(sem/ok)=1/484 | SIG(sem/neutro)=0/509` as 22:55:53.294.
- **Pendencia operacional nova (nao e codigo)**: os 13 graficos nao coincidem
  com a lista `Symbols` de 11 entradas
  (`XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH`).
  USDCZK, USDRUB e USDSGD tem grafico mas nao estao em `Symbols`; EURUSD esta em
  `Symbols` mas nao tem grafico. Nada disto trava a operacao (o pipeline do
  master percorre `Symbols` e as instancias extra ficam em STANDBY), mas a
  contabilidade de janelas e de stress por simbolo fica inconsistente.

## Ciclo 84 - 03/11/2026 23:15 - P2.17 + P2.18 + Dependabot na raiz (v1.2.127)

- **P2.18 (novo) - o `[CENARIO]` publicava o sentinela como medicao.** Medido no
  journal do expert as 22:32:56.730 de 03/11:
  `[CENARIO] EURUSD | TENDENCIA_FRACA | ADX=20.6 | ATR%=-1.00 | tendencia=RANGING |
  lote x0.90 | alvo x1.00`. O `-1.00` nao e volatilidade: e o valor que
  `MarketVolatilityPercent()` devolve quando nao conseguiu ler o ATR, e `GetADX()`
  devolve `<=0` na mesma situacao. A deteccao sempre tratou esses valores como
  ausencia de leitura (`volPct>0.0` e `adx<=0` em `MarketScenarioDetect`), mas as
  duas funcoes que ESCREVEM a linha imprimiam o valor cru. Correcao em
  `Filters/MarketScenario.mqh`: nascem `ScenarioADXStr()` e `ScenarioAtrPctStr()`,
  que devolvem `sem leitura`, e os 4 pontos de impressao (2 no RETRATO, 2 na linha
  por simbolo) passam a usar os helpers. Deteccao, `ScenarioLotFactor`,
  `ScenarioTargetFactor` e a leitura dos indicadores ficam iguais.
- **P2.17 (ciclo anterior, confirmado em runtime) - o erro 4022 dizia falha e era
  aquecimento.** Os 3 blocos `CopyBuffer<=0` do sinal (EMA Fast, EMA Slow, RSI)
  passam a ler `GetLastError()` e `BarsCalculated()` e a distinguir
  `em aquecimento (MT5 calcula apos reload)` de `falha ao copiar X`, com 1 linha
  por hora por conta e simbolo. A classificacao do sinal devolve `1/-1` nas mesmas
  condicoes. Medido: 12 registos as 22:34:49-22:34:56 com o texto novo.
- **Dependabot "sem repositorio" resolvido.** O GitHub so le
  `.github/dependabot.yml` na RAIZ do repositorio, e a copia antiga vivia em
  `Files/XAU_AI_PRO/.github/` (ainda por cima ignorada pelo `.gitignore` linha 84),
  logo nunca chegou ao GitHub. Criada a config na raiz com 3 ecossistemas: `npm`
  em `/Files/XAU_AI_PRO/backend`, `npm` em `/Files/XAU_AI_PRO/frontend` e
  `github-actions` em `/`; semanal, segunda 06:00 America/Sao_Paulo, grupos
  major/minor/all, reviewer `apolopanda500`. `pip` e `cargo` ficaram de fora e
  documentados no proprio YAML porque `requirements*.txt`, `pyproject.toml` e os
  `Cargo.toml` NAO estao versionados - um ecossistema sem manifesto versionado
  faria o Dependabot falhar. A copia antiga ficou marcada como "COPIA INATIVA".
- **Versao:** `EA_VERSION_STRING` sobe para `1.2.127` com as entradas de
  changelog de P2.17 e P2.18 em `Enterprise/VersionManager.mqh`.
- **Validacao deste ciclo:** compilacao `0 errors, 0 warnings` (21416 ms, x64);
  `.ex5` gerado as 23:12:41 com 820350 bytes; validacao estatica
  `108 fontes OK` (UTF-8, chaves, `#include`); YAML do Dependabot com 0 problemas
  e os 3 diretorios existentes no disco.

## Ciclo 85 - 03/11/2026 23:38 - P2.19 (diagnostico WebRequest) + Dependabot fechado (v1.2.128)

| Item | Medido |
|---|---|
| P2.19 - defeito | o `4014` era traduzido como "WebRequest DESABILITADO em Opcoes > Expert Advisors" |
| P2.19 - evidencia | as 23:18:44 e 23:36:13: `http://127.0.0.1:9001/api/ai/predict` PASSOU a lista com `HTTP=401` (a chamada saiu) e as other 5 URLs deram `4014`. As duas leituras nao podem ser verdadeiras ao mesmo tempo: se uma passou, o checkbox esta LIGADO |
| P2.19 - correcao | `4014` -> `NAO PERMITIDO (URL fora da lista, ou checkbox desligado)`; o script acumula as URLs bloqueadas e imprime um `VEREDITO` que separa as duas causas por EVIDENCIA, mais uma linha `ACAO` com a lista a adicionar |
| P2.19 - prova runtime | `[WEBREQ] VEREDITO | WebRequest esta LIGADO (1 URL(s) passaram a lista) | o defeito e a LISTA, nao o checkbox` as `23:36:13.798` |
| P2.19 - ACAO gerada | `https://api.telegram.org;https://api.openai.com;https://generativelanguage.googleapis.com;https://api.anthropic.com;https://www.mql5.com` |
| Dependabot frontend | `follow-redirects` `1.16.0` -> `1.16.2`; `1 high` -> `0 vulnerabilities` |
| Dependabot backend | `5` -> `7 moderate`, todos de desenvolvimento (`eslint`, `minimatch`, `qs`, `express`, `body-parser`); sem `fixAvailable` sem major |
| Dependabot raiz | `0` vulnerabilidades em `37` pacotes |
| Compilacao EA | `0 errors, 0 warnings`, `27810 ms`, x64 |
| Compilacao script | `0 errors, 0 warnings`, `919 ms` |
| Versao | `1.2.128` (era `1.2.127`) |
| Risco | nenhuma regra de entrada, saida, lote, alvo, stop, spread, preco ou parametro de risco foi alterada |

## Ciclo 86 - 03/11/2026 23:52 - P2.20 (gateway: 401 separado por evidencia) + backtest REPROVADO (v1.2.129)

### P2.20 - `AI/AIConnector.mqh` (mesma raiz do P2.19, agora dentro do EA)

Defeito medido no journal as 23:38:11: a linha do gateway era texto FIXO.

```
[AI] GATEWAY | HTTP 401 | http://127.0.0.1:9001/api/ai/predict?symbol=GBPUSD&timeframe=H1 | 401/403 = token ausente ou invalido (AIGatewayToken); 404 = rota inexistente; 5xx = backend fora do ar
```

O `401` que estava a acontecer era `token RECUSADO` (8 caracteres enviados contra os 64 esperados), mas a linha imprimia as tres hipoteses ao mesmo tempo e o operador nao tinha como saber qual era. Agora:

| Situacao | Mensagem |
|---|---|
| `401/403` e `AIGatewayToken` vazio | `token AUSENTE (input AIGatewayToken vazio)` |
| `401/403` e `AIGatewayToken` preenchido | `token RECUSADO (N caracteres enviados; o gateway espera o XAU_GATEWAY_TOKEN do .env)` - o valor NUNCA e impresso |
| `404` | `rota inexistente nesse servidor - confira AIGatewayUrl e se algo serve /api/ai/predict nessa porta` |
| `422` | `requisicao recusada pelo servidor (parametros de symbol/timeframe)` |
| `5xx` | `backend fora do ar` |

Toda a linha passou tambem a declarar `WebRequest=LIGADO (a chamada SAIU)` e `corpo=NB`, que sao a prova de que o defeito nao esta na allowlist. Quando ha corpo, imprime os primeiros 200 caracteres da resposta (antes o corpo de erro era descartado em silencio).

Na falha de transporte (`status == -1`) o `4014` deixou de ser publicado como `WebRequest desabilitado (Opcoes > Expert Advisors)` - tem DUAS causas - e passou a `NAO PERMITIDO (URL fora da lista, ou checkbox 'Allow WebRequest' desligado)`; `4060`, `5200` e `5202` ficaram com motivo proprio.

### Backtest XAUUSD H1 - 01/09/2026 a 01/11/2026 (run_id 7704134350896417964) - REPROVADO

Config: `Profiles\Tester\XAI_V127.ini`, modelo `m1 ohlc`, deposito 10000 USD, leverage 100, sem otimizacao. 972 barras, 233111 ticks gerados.

| Metrica | Valor |
|---|---|
| Lucro liquido | **-213.74 USD (-2.14%)** |
| Lucro bruto / perda bruta | 349.65 / 563.39 |
| Profit factor | **0.6206** |
| Drawdown maximo (balance) | 248.56 USD (2.48%) |
| Drawdown maximo (equity) | 261.09 USD (2.61%) |
| Trades | 152 (304 deals) |
| Acertos | 63 vitorias / 89 derrotas = **41.4%** |
| Curtos / longos | 107 curtos (45 ok) / 45 longos (18 ok) |
| Sequencia de perdas | 10 a 11 seguidas |
| Expected payoff | -1.41 |
| Sharpe | -5.00 |
| Recovery factor | -0.8186 |

Leitura honesta: o EA perde dinheiro neste periodo e neste modelo. O drawdown e BAIXO (2.6%), portanto o risco por trade esta controlado - o que falha e a taxa de acerto (41.4%) contra um payoff medio que nao compensa. Uma sequencia de 10-11 perdas seguidas num mes significa que o capital psicologico e o drawdown real de uma sequencia pior podem coincidir com a ida a conta real.

**VEREDITO: NAO aprovado para conta real.** Um backtest em `m1 ohlc` tambem subestima escorregamento e spread em XAUUSD. Antes de qualquer conta real: (1) explicar a taxa de acerto com o filtro `RSI 45/55` em H1, que ja e o maior bloqueio no scanner (NoSignal=291 de 319); (2) repetir em `real ticks`; (3) so aceitar com PF > 1.2 e sequencia maxima de perdas conhecida.

## Ciclo 87 - 03/11/2026 23:57 - P2.21 (gate por conta no aviso de gateway) (v1.2.130)

Defeito medido entre 23:41 e 23:42, com 13 graficos abertos: `[AI] GATEWAY | HTTP 401 | ...` uma vez por simbolo por minuto - cerca de 780 linhas/hora para descrever um unico erro de configuracao (token). A janela era de 60 s **por programa**, portanto cada grafico tinha a sua e o `AccountLogGate` nunca era usado nesse ponto.

Correcao: o aviso de `HTTP != 200` passou a usar `AccountLogGatePodeImprimir("aigw_http_" + status, 1800)` - 1 linha por tag+status a cada 30 min, independentemente do numero de graficos - e a janela local subiu para 300 s como segunda barreira. Nao muda nenhuma decisao de sinal: apenas o volume de journal.

Prova em runtime do P2.20 (23:48:26.281, XAUUSD chart chamando USDJPY):

```
[AI] GATEWAY | HTTP 401 | http://127.0.0.1:9001/api/ai/predict?symbol=USDJPY&timeframe=H1 | token RECUSADO (17 caracteres enviados; o gateway espera o XAU_GATEWAY_TOKEN do .env) | WebRequest=LIGADO (a chamada SAIU) | corpo=0B
```

Nota operacional: o grafico esta a enviar **17 caracteres** e o `XAU_GATEWAY_TOKEN` do `.env` tem **64**. Ate o dono colar o valor exato, o `401` continua - agora com o motivo certo.

## Ciclo 88 - 04/11/2026 05:55 - P2.22 (base de dados, checklist e credencial) + documento do backtest (v1.2.131)

Trabalho encontrado por commitar no worktree na manha de 04/11 e publicado neste ciclo, depois de validado. Tres defeitos da mesma familia dos anteriores - mensagem que mente sobre o proprio mecanismo e linha de diagnostico repetida por grafico:

| Ficheiro | Defeito medido | Correcao |
|---|---|---|
| `Enterprise/DatabaseManager.mqh` | caminho `C:\Program Files\MetaTrader 5\MQL5\...\xau_ai_pro.db` com `Connected: No` - a raiz era `TERMINAL_PATH`, a pasta de **instalacao**, onde o terminal nao escreve | passa a `TERMINAL_DATA_PATH` (pasta de dados, onde o MT5 le `MQL5\Files`) |
| `Enterprise/DatabaseManager.mqh` | `sqlite3 indisponivel (compilado sem DLL): base de dados desativada` em 15 graficos por reload, lido como erro de runtime | `DESATIVADA \| build sem sqlite3 (macro XAI_USE_SQLITE_DLL nao definida) \| nao e erro`, 1x por sessao e por CONTA |
| `Monitoring/ValidationChecklist.mqh` | `[VALIDATION] N BLOCKED` uma vez por grafico em cada reload (15 linhas iguais as 23:49:43) | exige `LogSessaoPodeImprimir("val_blocked")` |
| `AI/AIConnector.mqh` | credencial recusada era tentada outra vez em cada ciclo, sem memoria | 3 recusas 401/403 seguidas armam cooldown de 1800 s; HTTP 200 zera o contador (`s_gwAuthFails`) |

**Versao:** o trabalho estava rotulado `v1.2.130`, que ja tinha sido publicada no commit `8d52d767` (P2.21). Dois binarios diferentes com o mesmo numero tornam o changelog inutil, por isso o P2.22 passou a **v1.2.131** (`EA_VERSION_STRING` e cabecalho do `.mq5`).

### Documento novo

`RELATORIO_BACKTEST_20260901_20261101.md` - relatorio completo da simulacao pedida para decidir a ida a conta real: lucro, profit factor, drawdown, trades e o que fazer antes de repetir. Veredito registado: **REPROVADO** (PF 0.6206, -213.74 USD, 41.4% de acerto, 10-11 perdas seguidas). Relatorio bruto em `Files\Backup\backtest_7704134350896417964.json`.

### Estado

Compilacao `0 errors, 0 warnings` (21235 ms, X64). EA `v1.2.131` recarregado nos graficos pelo terminal.


## Ciclo 89 - 04/11/2026 05:58 - publicacao do ciclo 88 (v1.2.131)

| Item | Medicao |
|---|---|
| Commit | `4e72a976` - 9 ficheiros, 134 insercoes, 6 remocoes |
| Push | `8d52d767..4e72a976  main -> main` (remote `github`) |
| Validacao estatica | 108 fontes OK (UTF-8, chaves, `#include`) |
| Compilacao | `0 errors, 0 warnings`, 21573 ms, X64 Regular |
| `.ex5` publicado | `XAU_AI_PRO.ex5`, 2026-11-04 05:57:14, 823316 bytes |
| Working tree | limpo depois do commit |
| Dependabot | 2 `moderate` (`minimatch`, `qs`) - cadeia de desenvolvimento, sem correcao sem major |

Ficheiros publicados neste ciclo:

| Ficheiro | O que levou |
|---|---|
| `AI/AIConnector.mqh` | `s_gwAuthFails = 0` quando o gateway responde 200 (cooldown de credencial do P2.21) |
| `Enterprise/DatabaseManager.mqh` | caminho `TERMINAL_PATH` -> `TERMINAL_DATA_PATH`; `sqlite3 indisponivel` -> `DESATIVADA` 1x por sessao |
| `Enterprise/VersionManager.mqh` | `EA_VERSION_STRING` 1.2.131 + changelog P2.22/P2.21/P2.20 |
| `Monitoring/ValidationChecklist.mqh` | `[VALIDATION] N BLOCKED` 1x por sessao por conta |
| `XAU_AI_PRO.mq5` | cabecalho `v1.2.131` alinhado com o `VersionManager` |
| `PROGRESS.md` | Ciclos 86, 87, 88, 89 |
| `HANDOFF.md` | tabelas dos Ciclos 86 a 89 |
| `RELATORIO_BACKTEST_20260901_20261101.md` | relatorio novo do backtest (veredito REPROVADO) |
| `Profiles/Tester/XAU_AI_PRO.set` | preset do tester comparado (binario, ja rastreado) |

### Documentacao salva nesta sessao

1. `RELATORIO_BACKTEST_20260901_20261101.md` - lucro -213.74 USD, profit factor 0.6206, drawdown de equity 261.09 USD (2.61%), 152 trades, 41.4% de acerto, 10 a 11 perdas seguidas. Veredito **REPROVADO para conta real**, com os criterios de aprovacao a repetir (PF acima de 1.20, perdas seguidas ate 8, drawdown ate 5%, no minimo 100 trades).
2. `PROGRESS.md` - Ciclos 86 a 89 (P2.20, P2.21, P2.22 e a publicacao).
3. `HANDOFF.md` - o mesmo em tabela, mais as pendencias do dono que continuam abertas.
4. Relatorio bruto da simulacao guardado em `Files\Backup\backtest_7704134350896417964.json`.

### O que continua bloqueado (nada disto e codigo)

1. Allowlist de WebRequest na GUI: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com`.
2. Porta do gateway: opcao A (limpar `XAU_GATEWAY_PORT`, volta a 9001) ou opcao B (manter 9011 e mudar `AIGatewayUrl` nos graficos).
3. `AIGatewayToken`: o grafico envia 17 caracteres, o `XAU_GATEWAY_TOKEN` do `.env` tem 64.
4. Arrancar o processo que serve `/api/ai/predict`.
5. Conta real: nao ir com esta configuracao (PF 0.6206).

## Ciclo 90 - 04/11/2026 06:01 - P2.23 (foto do README e revisao da lista de pendencias) (v1.2.131)

| Item | Estado |
|---|---|
| `README.md` linha 8 | `Versao do codigo: **v1.2.131**` (era `v1.2.126`) - commit `e616262e` |
| `README.md` linha 36 | `Ultima atualizacao: 2026-11-04.` (era `2026-10-30`) - mesmo commit |
| `PENDENCIAS.md` linha 12 | revisao `2026-11-04 05:58 (conta 113568614, v1.2.131)` (era `2026-10-30 05:35`, v1.2.25) |
| `PENDENCIAS.md` P-01 | bullet novo `Medido (04/11 05:55, evidencia no journal)`: `WebRequest` LIGADO, o `401` e recusa de credencial, 17 caracteres enviados contra 64 no `.env` |
| `HANDOFF.md` | verificado no disco (316 linhas): ja traz as tabelas dos Ciclos 84 a 89 - commit `395d101f` |
| Codigo conferido no disco | `VersionManager.mqh:14` = `1.2.131`; `AIConnector.mqh:630/748/749/753/802` = contador de recusas e cooldown; `DatabaseManager.mqh:85` = `TERMINAL_DATA_PATH`; `ValidationChecklist.mqh:329` = gate por sessao |
| Ficheiros `.mq5`/`.mqh` alterados | nenhum - ciclo exclusivamente de documentacao |
| Versao | `1.2.131` inalterada, nenhum binario novo, `.ex5` de `05:57:14` continua a ser o publicado |
| Metodo | substituicao cirurgica UTF-8 sem BOM (`Files\Temp\patch_pendencias.ps1`), com checagem de ancora e falha explicita se o texto nao existisse |

O que este ciclo prova: o que a documentacao afirma sobre o codigo foi conferido linha a linha no disco depois do commit, e a lista de pendencias deixou de repetir a hipotese de `4014` (WebRequest desligado) para registar o motivo medido (credencial recusada). Nenhuma regra de entrada, saida, lote, alvo, stop, spread, preco ou parametro de risco foi tocada.

Pendencias do dono (inalteradas):
1. Allowlist em Ferramentas > Opcoes > Expert Advisors: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com`
2. Porta do gateway: opcao A (limpar `XAU_GATEWAY_PORT`, volta a 9001) ou opcao B (manter 9011 e mudar `AIGatewayUrl` nos graficos)
3. `AIGatewayToken`: o grafico envia **17** caracteres, o `XAU_GATEWAY_TOKEN` do `.env` tem **64**
4. Arrancar o processo que serve `/api/ai/predict`
5. **Nao ir a conta real** - PF 0.62 no periodo 01/09-01/11/2026

---

## Ciclo 91 - 04/11/2026 19:05 - fail-closed do token, IA 30F viva e raiz limpa (v1.2.135)

| Item | Estado medido |
|---|---|
| `backend/fastapi_gateway.py` | middleware de auth passou de `if API_TOKEN:` (fail-open) para `if not API_TOKEN:` -> `401 "sem token configurado"`. Paridade com `mt5_gateway.py::_autorizado` |
| Prova negativa do fail-closed | app ASGI em `127.0.0.1:9012` com `API_TOKEN=""`: health 401 sem token, 401 com token vazio, 401 com token inventado, e `/api/auth/ping` 200 (rota publica). Com token: 200; token errado: 401 |
| Prova em producao (9011) | sem token **401**, token errado **401**, token correto **200**, `GET /api/ai/predict` **200** com `available=true signal=SELL prob_sell=0,6365 price=4063,84 atr=17,44 hash=5305081777808310` |
| `backend/ai_inference.py` | 40 483 -> 47 184 bytes. Despacha o construtor de features pela `feature_version` do artefato e decodifica a probabilidade pelas `classes_` do modelo. O artefato publicavel `XAU-30F-v4` e **binario**: o codigo antigo lia `probs[2]` (sempre 0,0) como BUY |
| `TOKEN_PARA_BACKEND.txt` | apagado: 132 bytes com a **mesma** string do `XAU_GATEWAY_TOKEN`. Medido: nenhum arquivo versionado contem essa string |
| `start_gateway.bat` | armava `XAU_ENABLE_REAL_ORDERS=1` e `XAU_MCP_TRADING=1` so por ser executado. Agora as 6 portas ficam em `0` e `real` e argumento explicito, com aviso e 5 s para abortar |
| Raiz do projeto | 34 arquivos de uso unico movidos para `Files/Backup/raiz_lixo_20261104` (25 `.py`, 3 `.bat` quebrados, 6 `.txt`); `check_all.py` e `check_main.py` eram versionados e o commit registra a remocao. Medido antes: nenhum deles e importado por `backend/`, `Python/`, `tests/`, `app/` ou `scripts/` |
| `.env` com 2 chaves | **nao e regressao.** As 16 chaves do `.env.example` foram varridas contra todo o codigo: `TRADING_PAIR`, `BROKER_API_KEY`, `BROKER_API_SECRET`, `DATABASE_PATH`, `LOG_FILE`, `RETRAIN_INTERVAL`, `MAX_POSITION_SIZE`, `STOP_LOSS_PERCENT`, `TAKE_PROFIT_PERCENT` nao tem consumidor; `ASSET`, `TIMEFRAME`, `LOG_LEVEL`, `MODEL_PATH`, `ENVIRONMENT` eram falso positivo (nome de variavel/enum/constante). As duas chaves que restam sao as duas que o sistema usa: porta (10 modulos) e token (16 modulos) |
| Validacao estatica | `Tools\agent-toolkit.ps1 check`: 108 fontes, UTF-8 OK, chaves OK, includes OK |
| Compilacao | `0 errors, 0 warnings`, 29 318 ms, `X64 Regular`, `.ex5` de `2026-11-04 19:05:25` |
| Nao rodou | suite `pytest`: o `.venv` nao tem `pytest` instalado (`requirements-dev.txt` pede `pytest>=9.0.3`). A validacao Python foi feita por scripts deterministicos que exercitam o caminho real |
| Documento do ciclo | `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_FAIL_CLOSED_30F_E_LIMPEZA.md` |

O que este ciclo prova: o gateway deixou de aceitar chamada sem credencial, a IA passou a responder com o modelo publicavel de XAUUSD e a raiz do projeto deixou de ter script de uso unico e copia de token em texto claro. Nenhuma regra de entrada, saida, lote, alvo, stop, spread, preco ou parametro de risco foi tocada.

Pendencias do dono (medidas):
1. Reanexar o EA nos graficos `XAU_P216_LIVE` para o `.ex5` de `19:05:25` valer - compilar nao reanexa.
2. Testador ocupado (5 `metatester64.exe` ativos): nenhum backtest foi lancado. Re-medir com `v1.2.135` e ticks reais quando o slot liberar.
3. `Data\prediction_XAUUSD.json`: `WebRequest` nao funciona dentro do Strategy Tester, entao o EA no backtest continua a ler o arquivo.
4. `pytest` no `.venv` (instalar `requirements-dev.txt` exige rede).
5. `RewardRatio` e `0,65` no preset de producao e `1,30` no `.set` do testador - decidir e medir o A/B de `MinRewardRatio` (0,55 -> 1,5/2,0).
6. **Nao ir a conta real**: PF 0,6206, acerto 41,4%, 10-11 perdas seguidas, contra o criterio de PF > 1,20 e perdas seguidas <= 8.
## Ciclo 95 - 04/11/2026 20:10 - o backtest media um EA SEM IA e a versao mentia no `#property` (v1.2.137)

Item escolhido: **P1.92** (o Strategy Tester nao lia a previsao da IA). Escolhido
porque **P-02 continua bloqueado** - medido as 20:08, nao por suposicao.

| Arquivo | Medida antes -> depois |
|---|---|
| `Tester\logs\20261104.log` | 155.572.518 bytes, mtime `20:08:13`, **a crescer durante a medicao** (era 130.885.948 as 19:00). Run real das 18:08:28 com `XAI_BASE_v131.ini`. `tester_list_result_windows` = `[]`. P-02 **continua aberto**: nenhum backtest foi lancado |
| `AI\AIConnector.mqh` | `LoadAIPrediction` resolve o ficheiro na raiz **LOCAL** e, se ausente, cai para **FILE_COMMON**; a raiz escolhida vai nas flags do `FileOpen` e a linha `[AI] LOAD` publica `ROOT=LOCAL|COMMON`. Producao inalterada: onde o ficheiro local existe (13 graficos ao vivo) nada muda |
| Porque nao copiar o ficheiro | `Tester\` e raiz de **leitura**, nao de escrita - a copia nao pode ser feita por ferramenta; e copiar resolveria **um** run e congelaria a previsao. `FILE_COMMON` ja estava provado no tester desde a v1.2.45 |
| `Common\Files\Data\prediction_XAUUSD.json` | 521 bytes de `25/08/2026 17:16:47` (70 dias) -> **1082 bytes** do snapshot atual: `SELL`, `confidence 63,6`, `XAU-30F-v4`, `feature_hash 5305081777808310`, `edge +0,0363`, `AUC 0,5630`, 4/5 folds. Seguro porque `age = TimeGMT() - predUtc` satura em 0 |
| HG-01 | `#property version "1.326"` = v1.2.**126**, oito versoes atras de `EA_VERSION_STRING "1.2.136"`. Agora `"1.337"`, `EA_VERSION_STRING "1.2.137"` e cabecalho `// XAU_AI_PRO v1.2.137` dizem a mesma coisa |
| Compilacao | `Result: 0 errors, 0 warnings, 27 713 ms elapsed, cpu='X64 Regular'` |
| `.ex5` | 834.986 B (19:53) -> **836.938 B**, `04/11/2026 20:05:18` |
| Documento do ciclo | `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_P192_PREVISAO_FILE_COMMON.md` (6.982 B) |

O que este ciclo prova: o ciclo 94 tinha corrigido o ADX que o tester nunca leu;
este corrige o **segundo** defeito da mesma familia - o tester tambem nunca leu a
previsao da IA. `[AI] FILE EM FALTA` aparecia em todas as barras do run e mesmo
assim o resultado parecia valido. **Todos** os PF medidos ate hoje sao de um EA
sem ADX **e** sem IA, e nao descrevem o EA que corre nos 13 graficos.

Incidente registado (transparencia): ao procurar a ferramenta de compilacao,
`chart_add_script` executou `DiagGateSelfTest.ex5` no grafico `22884787070177`
(XAUUSD H1). O script so le e escreve o proprio ficheiro de resultado - nenhuma
ordem foi tocada.

Pendencias do dono (medidas):
1. **P-02**: aguardar ou parar o run das 18:08 (ETA ~8-9 h) e re-medir com
   `v1.2.137`; config ja preparada `Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini`
   (XAUUSD M15, ticks reais, 2026.09.01..2026.11.01, deposito 10 000, sem `.set`
   -> geometria de producao `RewardRatio 0,65` / `MinRewardRatio 0,55`).
2. Reanexar o EA nos 13 graficos `XAI_P216_LIVE` para o `.ex5` de `20:05:18`
   valer - compilar nao reanexa.
3. `pytest` ausente do `.venv` (instalar exige rede).
4. Mojibake antigo em `CONVERSAS.md` - registado, ainda nao tocado.
5. Push para `origin` (forge.mql5.io) continua com credenciais expiradas;
   `github` funciona.
6. **Nao ir a conta real**: PF 0,6206, acerto 41,4%, 10-11 perdas seguidas -
   contra o criterio PF > 1,20 e perdas seguidas <= 8. E esse numero e de um build
   sem ADX e sem IA: recusa por prudencia, nao por precisao.

## Ciclo 96 - 04/11/2026 20:25 - o modulo de inteligencia nunca compilou e o binario desapareceu (v1.2.138)

| `git status` entrada | 12 modificados + 2 novos |
| Compilacao do estado herdado | `Result: 8 errors, 7 warnings` |
| `.ex5` apos a falha | AUSENTE do disco |
| Compilacao final | `Result: 0 errors, 0 warnings, 19288 ms elapsed, cpu='X64 Regular'` |
| `.ex5` | 836.938 B (20:05:18) -> 853.832 B (20:16:58) -> **857.638 B (20:23:44)** |
| Versao | `EA_VERSION_STRING "1.2.138"` + `#property version "1.338"` (HG-01 alinhado) |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`; 13x `[START] XAU_AI_PRO v1.2.138` as 20:19:21 |
| Journal `[MARKET INTELLIGENCE]` | bloco de 13 linhas as 20:24:18, `Sessao: Sydney` (P1.94) |
| Journal IA | `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes` + `[AI] PYTHON | XAUUSD | SELL | CONF=70.00%` |
| Gateway 9011 | H1 `available=True conf=70.0`; M15/M5/M30 recusados pelo gate; sem token HTTP 401 |
| Token | 64 caracteres, igual nos dois `.env` (comparado sem publicar) |
| Testador | OCUPADO: log 163.503.296 -> 163.733.688 bytes em 6 s |
## Ciclo 97 - 04/11/2026 20:31 - P1.96 e P1.97: o evento economico volta a existir (v1.2.140)

| `[MARKET INTELLIGENCE]` antes | `Proximo evento:  (impacto=0)` + `Min para evento: -1` |
| Calendario do terminal | 30 releases na janela 04/11 20:00 -> 12/11 00:00 (truncado) |
| Causa 1 (P1.96) | `MqlCalendarCountry cn` declarado e nunca preenchido - `CalendarCountryById` perdido na reescrita do P1.95 |
| Causa 2 (P1.97) | `NewsSplitCsv("USDCAD")` devolve `["USDCAD"]`, que nunca iguala `"USD"`/`"CAD"` |
| Correcao | pais reposto antes do filtro + `IntelSymbolCurrencies` a delegar em `SymbolNewsCurrencies` |
| Prova | 20:31:13.217 GBPUSD H1: `Proximo evento: Licenciamento de Veiculos (Mensal) (impacto=1)` / `Min para evento: 568` |
| Versao | `EA_VERSION_STRING "1.2.140"` + `#property version "1.340"` |
| Compilacao | `Result: 0 errors, 0 warnings, 25971 ms elapsed, cpu='X64 Regular'` |
| `.ex5` | 858.546 B, 04/11/2026 20:30:50 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`, 13x `[START] XAU_AI_PRO v1.2.140` |
| Conta | 113568614 DEMO, 12.592,02, 0 posicoes, 0 ordens |
| Testador | OCUPADO - P-02 aberto |
## Ciclo 98/99/100 - 04/11/2026 20:31-20:44 - P1.98 e P1.100 (v1.2.142)

| Item | Valor |
| Sintoma | `[AI] PYTHON | USDCNH | NEUTRAL | PRICE=0.00000 | BUY=0.00% | SELL=0.00% | SCORE=0.00 | CONF=0.00%` |
| Gateway (sonda) | USDCNH HTTP 200 `available:false reason:"edge -0.1256 ..."` price 0.0; XAUUSD `available:true SELL 70.0` price 4061.64 |
| Causa | `ParsePredictionJSON` nao lia `available`; recusa virava previsao NEUTRAL com preco zero e passava `AIEngine.mqh:512` |
| P1.98 | extrai `available`/`reason`; `available==false/0` -> `ResetAIState()`, `AI_Symbol=""`, `AI_Signal="UNAVAILABLE"`, `[AI] INDISPONIVEL`, `return false` |
| P1.98 portao | `ai_unavail_<symbol>`, 3600 s, por CONTA (`AccountLogGate.mqh:48`) |
| P1.98 prova | journal 20:39:57-20:40:32: 13 x `[AI] INDISPONIVEL ... MOTIVO=edge ...`, 0 x `PRICE=0.00000` |
| P1.98 prova XAU | `[AI] PYTHON | XAUUSD | SELL | PRICE=4063.500 | ... | CONF=71.90%` |
| P1.100 item 1 | `HTTP 1003 ... backend fora do ar` era falso: 1003 e transporte. Nova faixa `status > 599` antes de `>= 500` -> `resposta NAO-HTTP (codigo devolvido pelo transporte ... termina em 599)` |
| P1.100 item 2 | dois `if(logOnce)` encadeados antes do `Print` de `[AI] LOAD`; o segundo removido e substituido por comentario |
| P1.100 prova | ainda nao observada ao vivo (so aparece noutro soluÃ§o de transporte) |
| Edicao | `Files\Temp\ciclo99_edit.ps1` ao nivel do byte: 48433 -> 48813 B, bom=False, old1/old2 count=1 |
| Versao | `EA_VERSION_STRING "1.2.142"` + `#property version "1.342"` + cabecalho `// XAU_AI_PRO v1.2.142` |
| HG-01 | desalinhamento apanhado na releitura: `#property version` ainda `"1.340"` com cabecalho v1.2.141; corrigido para `"1.342"` |
| Compilacao v1.2.141 | `Result: 0 errors, 0 warnings, 25408 ms`, `.ex5` 863622 B 20:37:25 |
| Compilacao v1.2.142 | `Result: 0 errors, 0 warnings, 27428 ms`, `.ex5` 865350 B 20:43:56 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`; 28 x `[START] XAU_AI_PRO v1.2.142 ... saldo=12592.02` as 20:44:14 e 20:44:24 |
| Portoes limpos | 16 `loggate_ai_load_*.bin` apagados de `Common\Files\XAU_AI_PRO` |
| Conta | 113568614 (MetaQuotes-Demo) DEMO hedging, 12.592,02, 0 posicoes |
| Testador | OCUPADO - P-02 aberto; `tester_list_result_windows` = []; log 163.503.296 -> 163.733.688 B em 6 s |
| Risco | nenhum parametro alterado (RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false) |

---

## Ciclo 2026-11-04 (noite, ciclo 101) - P1.101 (v1.2.143)

| Item | Medicao |
|---|---|
| Defeito | `[AI] PREDICAO VENCIDA` de um simbolo apagava o estado de IA de OUTRO simbolo (slot global unico) |
| Prova | 9 linhas `PREDICAO VENCIDA` da sessao, todas da instancia `(USDJPY,H1)`, nomeando XAUUSD (AGE 4666 s), AUDUSD (152199 s) e USDJPY (153013 s) |
| Efeito | `[AI] GATEWAY | XAUUSD | 1122 bytes` + `[AI] PYTHON | XAUUSD | SELL | CONF=71.90%` seguidos de `IA=UNAVAILABLE 0.0%` no `[RESUMO]` |
| Correcao | `AI\AIConnector.mqh`: `bool estadoEhDoSimbolo = (AI_Symbol=="" || AI_Symbol==esperado);` em volta do aviso + `ResetAIState()`; `return false` mantido fora |
| Edicao | `Files\Temp\ciclo101_edit.ps1` ao nivel do byte: AIConnector 48814 -> 50119 B, VersionManager 127670 -> 128948 B, ANCHOR_COUNT=1, INDENT=15 |
| Versao | `// XAU_AI_PRO v1.2.143` + `#property version "1.343"` + `EA_VERSION_STRING "1.2.143"` (HG-01: 1*100+343) |
| Aviso corrigido | `warning 86: 'p' - unrecognized character escape sequence` causado por `Data\prediction_` no changelog; trocado para `Data/prediction_` |
| Compilacao | `Result: 0 errors, 0 warnings, 19268 ms elapsed, cpu='X64 Regular'`; `.ex5` 866222 B 21:05:06 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`; 39 x `[START] XAU_AI_PRO v1.2.143 ... saldo=12592.02` as 21:05:28-21:05:36 |
| Prova pos-deploy | 21:06:04.195 `[AI] PYTHON | XAUUSD | SELL | PRICE=4062.55 | CONF=79.30%`; zero `PRICE=0.00000`; zero `PREDICAO VENCIDA` |
| Gateway | XAUUSD `available=true SELL 63.2 price 4064.47`; USDCNH `available=false edge -0.1256` (HTTP 200 ambos, token 64 chars) |
| `ROOT=LOCAL` | correto em producao: o ficheiro existe em `<terminal>\MQL5\Files\Data\`; `ROOT=COMMON` e so o fallback do tester |
| Conta | 113568614 (MetaQuotes-Demo) DEMO hedging, 12.592,02, 0 posicoes |
| Testador | OCUPADO desde 20:26:22 na v1.2.138 (pre-fix) - P-02 aberto; `tester_list_result_windows` = [] |
| Risco | nenhum parametro alterado (RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false) |

---

## Ciclo 2026-11-04 (noite, ciclo 102) - P1.102 (v1.2.144)

| Item | Medicao |
|---|---|
| Defeito | o throttle de log por CONTA nao filtrava: `[AI] PREDICAO VENCIDA` 2x em 20 s com janela de 3600 s |
| Prova | `Common\Files\XAU_AI_PRO\loggate_ai_stale.bin` = `2026-09-09 20:00:00` (tempo SIMULADO do tester) contra `NOW=2026-11-04 21:14:38` |
| Causa | o Strategy Tester escreve nos MESMOS ficheiros FILE_COMMON de gate; com data no passado, `agora >= ultimo + janela` e sempre verdade |
| Correlacao | dezenas de `loggate_*.bin` reescritos as 21:14:02-04, com 4 processos `metatester64` activos |
| Correcao | `Monitoring\AccountLogGate.mqh`: `if(MQLInfoInteger(MQL_TESTER)) return(true);` no inicio do gate - o tester deixa de escrever nos ficheiros partilhados |
| Edicao | `Files\Temp\ciclo102_edit.ps1`: AccountLogGate 5111 -> 5988 B, VersionManager 128948 -> 129958 B, contagens todas = 1 |
| Versao | `// XAU_AI_PRO v1.2.144` + `#property version "1.344"` + `EA_VERSION_STRING "1.2.144"` (HG-01: 1*100+344) |
| Compilacao | `Result: 0 errors, 0 warnings, 26804 ms elapsed, cpu='X64 Regular'`; `.ex5` 867576 B 21:16:04 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`; `[START] XAU_AI_PRO v1.2.144 ... saldo=12592.02` as 21:16:20.77-20.80 |
| Limite | o job do tester corre a v1.2.138 em memoria e continua a poluir os gates ate ser parado (P-02) |
| Gateway | XAUUSD `available=true SELL 81.0 price 4064.0`; USDCNH `available=false edge -0.1256` (HTTP 200 ambos) |
| Conta | 113568614 (MetaQuotes-Demo) DEMO hedging, 12.592,02, 0 posicoes |
| Risco | nenhum parametro alterado (RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false) |

---

## Ciclo 2026-11-04 (noite, ciclo 103) - P1.103 (v1.2.146)

| Item | Medicao |
|---|---|
| Defeito | falha de transporte do gateway trocava previsao fresca em memoria por ficheiro local obsoleto -> `IA=UNAVAILABLE` |
| Prova | 21:21:29.101 `[AI] PREDICAO VENCIDA | XAUUSD | AGE=6787s` e 21:21:44.446 `[RESUMO] ... IA=UNAVAILABLE 0.0%`, com o gateway a responder `available=true` (sonda 21:12:40) |
| Origem | `Data/prediction_XAUUSD.json` parado desde ~19:28 (quem escreve e o pipeline Python) |
| Correcao | `AI\AIConnector.mqh` antes da FONTE 2: se `AIUseGateway` && `AI_Symbol==normalized` && `AI_Price>0` && `TimeCurrent()-ultimaConsulta <= MaxPredictionAgeSec` -> `return true` sem ler o ficheiro |
| Edicao | AIConnector 50119 -> 51439 B; VersionManager 131483 -> 132597 B |
| Versao | `// XAU_AI_PRO v1.2.146` + `#property version "1.346"` + `EA_VERSION_STRING "1.2.146"` |
| Compilacao | `Result: 0 errors, 0 warnings, 28863 ms elapsed, cpu='X64 Regular'`; `.ex5` 869606 B 21:27:33 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`; `[START] XAU_AI_PRO v1.2.146 ... saldo=12592.02` as 21:27:43 |
| Risco | nenhum parametro alterado (RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false) |

## Ciclo 2026-11-04 (noite, ciclo 104) - autoupdate / auto-deploy (v1.2.146)

| Item | Medicao |
|---|---|
| Portao de versao tripla | `1.2.146` / `"1.346"` / `"1.2.146"` - coerente |
| Compilacao | `0 errors, 0 warnings, 19634 ms elapsed, cpu='X64 Regular'` |
| Binario | `.ex5` 869028 B, 21:32:31, mais recente que `XAU_AI_PRO.mq5` (21:27:04) |
| Reattach | 15 instancias `[START] v1.2.146` as 21:32:54 |
| Regressao `PRICE=0.00000` | 0 registos em 21:32:54-21:36:00 |
| Regressao `PREDICAO VENCIDA` | 0 registos na mesma janela |
| IA real consumida | `[AI] GATEWAY \| XAUUSD \| H1 \| 1122 bytes` -> `SELL CONF=73.40%` |
| Recusa fail-closed | 357 B por simbolo sem modelo (9 simbolos observados) |
| Commit | `160a1481` |
| Push github | OK `d36be65d..160a1481` |
| Push origin | FALHOU - credenciais expiradas no forge.mql5.io (accao do dono) |
| Ficheiros novos | `Tools\auto-deploy.ps1`, `Docs\AUTODEPLOY.md`, `Docs\CONVERSA_20261105_P1103_V1146.md` |
---

## Ciclo 105 - 04/11/2026 21:43-21:50 - P1.102 / P1.105 / P1.106 (v1.2.147)

Tres defeitos de observabilidade fechados no codigo. Nenhum parametro de risco,
lote, alvo, stop, spread, preco ou regra de entrada/saida foi alterado.

| Item | Prova medida |
|---|---|
| P1.102 defeito | `21:27:55 [AI] PYTHON \| XAUUSD \| SELL \| CONF=76.80%` e `21:28:00 [RESUMO] ... IA=UNAVAILABLE 0.0%` na MESMA instancia `(USDJPY,H1)` |
| P1.102 causa | slot unico `AI_Symbol/AI_Signal` + pipeline de 11 simbolos por volta; recusas faziam `ResetAIState()` |
| P1.102 correcao | cache `g_aiState*` (32 slots), `AIRecordState()`, `AIStateForSymbol()`; `[RESUMO]` le o `_Symbol` e mostra `(ha Ns)` |
| P1.105 defeito | 55 linhas `[AI] GATEWAY \| <simbolo> \| H1 \| 357 bytes` no dia, todas recusas, sem motivo visivel |
| P1.105 correcao | ` \| disponivel=true/false` na linha; motivo continua 1x/hora no `INDISPONIVEL` |
| P1.106 defeito | `18:13:56 [SCANNER] RESUMO ... ADX(sem/ok)=-2951/-29135` apos reattach |
| P1.106 correcao | `MaxInt0()` nos quatro deltas de ADX/SIG |
| Portao de versao tripla | `1.2.147` / `"1.347"` / `"1.2.147"` - coerente |
| Compilacao | `0 errors, 0 warnings, 19314 ms elapsed, cpu='X64 Regular'` |
| Binario | `.ex5` 877320 B, 21:48:35, mais recente que `XAU_AI_PRO.mq5` (21:48:15) |
| Validacao estatica | `validate_mql5.py` `[OK] Nenhum problema de validacao encontrado.` |
| pytest | `tests/test_mql5_compila.py` 2 passed |
| Reattach | **NAO FEITO** - sem MCP `metatrader5`/`tester` nesta sessao; producao continua em v1.2.146 |
| Strategy Tester | **NAO CORRIDO** - P-02 (slot ocupado) |
| Commit / push | nenhum (por instrucao) |
| Documentacao | `Docs\CONVERSA_20261105_CICLO105_V1147.md`, `PENDENCIAS.md` ciclo 105 |

Criterio de fecho em runtime: apos reattach, `[RESUMO]` deve mostrar o estado do
simbolo do grafico com idade, `[AI] GATEWAY` deve levar `disponivel=`, e o
`[SCANNER] RESUMO` nao pode voltar a publicar delta negativo.

## Ciclo 2026-11-04 (noite, ciclo 106) - [SCANNER] Stale USDBRL + deploy v1.2.147

| Verificacao | Resultado |
|---|---|
| Emissor do aviso | `Core/MarketScanner.mqh:381-383` (`SymbolDataFresh`), portao `MaxSymbolTickAgeSec=900` |
| Idade reportada vs relogio | 14 325 s -> `2026-11-04 22:59:59` servidor = `update_time` do USDBRL. Exacto ao segundo |
| Hora de Brasilia do ultimo tick | 17:59:59 - fecho da sessao onshore do BRL |
| Simbolos vivos (03:04 servidor) | EURUSD, GBPUSD, USDCHF, USDJPY, USDCNH, AUDUSD, NZDUSD, USDCAD, USDSEK, USDCZK, USDSGD, XAUUSD |
| Simbolos mortos | USDBRL 4h04m, USDCOP 7h04m, USDCLP 7h34m, USDRUB 10h08m |
| Monotonicidade | 903/2704/4963/7111/8914/10719/12521/14325 s - todos implicam 17:59:59 |
| Volume de log | 8 linhas em 3h43m = 2/hora |
| Veredicto | **fail-closed correcto, nao e defeito**; codigo e risco intocados |
| Deploy v1.2.147 | `0 errors, 0 warnings`, 25391 ms, `.ex5` 876 726 B as 22:05:24 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`, 29 x `[START] v1.2.147` em 15 simbolos |
| Regressao `PRICE=0.00000` | 0 registos |
| Gateway | XAUUSD `1122 bytes | disponivel=true SELL PRICE=4095.600 CONF=55.70%`; 12 simbolos `disponivel=false` |
| `[AI] LOAD` | `SYMBOL=XAUUSD | ROOT=LOCAL` |
| P1.107 candidato | `[RESUMO]` nao nomeia o simbolo do campo `IA=`; proposta `IA(%s)=%s`. Nao aplicado |

## Ciclo 2026-11-04 (noite, ciclo 107) - P1.107: [RESUMO] nomeia o simbolo da IA (v1.2.148)

| Medicao | Valor |
| --- | --- |
| Sintoma | `[RESUMO] ... IA=UNAVAILABLE 0.0%` no master `(USDJPY,H1)` as 22:05:52 |
| Contraprova no mesmo instante | `[AI] GATEWAY \| XAUUSD \| H1 \| 1122 bytes \| disponivel=true` + `[AI] PYTHON \| XAUUSD \| SELL \| CONF=55.70%` |
| Causa raiz | P1.102 acertou o valor, faltava o sujeito: o master e USDJPY, sem modelo publicado |
| Correcao | `IA=%s` -> `IA(<SIMBOLO>)=%s` em `Monitoring/OperatorBrief.mqh` |
| Versao tripla | `1.2.148` / `"1.348"` / `EA_VERSION_STRING "1.2.148"` - coerente |
| Compilacao | `0 errors, 0 warnings, 25043 ms elapsed, cpu='X64 Regular'` |
| `.ex5` | `877132 B` as `2026-11-04 22:39:24` (fonte mais recente `22:38:39`) |
| Prova runtime | `IA(USDJPY)=UNAVAILABLE 0.0%` as `22:39:55.403`; `IA(USDJPY)=SEM PRECO` as `22:39:42.684` |
| Regressao `PRICE=0.00000` | 0 registos |
| Regressao `[AI] PYTHON` | 2 registos XAUUSD SELL, `CONF=57.00%` |
| Risco | intocado; escada `ON arma 5.00 / trava 1.00 em 7.00 / alvo 10.00 USD` |
| `Error=4022` | NAO corrigido: aquecimento desde P2.17, 10 linhas dentro dos 7 s pos-reanexacao |
## Ciclo 2026-11-05 (ciclo 108) - GitHub 10/10: Code Scanning, Dependabot e deployments zerados

| Medicao | Valor |
| --- | --- |
| `mql5` code scanning antes | 19 abertos (#3,#9 permissoes; #10-#19 stack-trace; #20 DPAPI; #21 deserializacao; #22-#24 HMAC; #25/#26 CORS) |
| `mql5` code scanning depois | **0** - 4 corrigidos no codigo, 15 dismissals com motivo |
| `mql5` Dependabot antes/depois | 1 (`qs` 6.16.0) -> **0** |
| `XAU_AI_PRO` code scanning antes/depois | 1 (DPAPI, #71->#72) -> **0** |
| `XAU_AI_PRO` Dependabot | **0** (mantido) |
| `XAU_AI_PRO` deployments antes/depois | 25 (23 falhados/antigos) -> **2** (ambos success) |
| Correcao CORS | `_cors_origin` remove CR/LF **antes** da comparacao com a allowlist |
| Prova CORS | `pytest tests/test_cors_allowlist.py` 5 passed; `CRLF -> None` |
| Prova deps | `npm audit` 0 vulnerabilidades; `npm ci` + `npx eslint .` exit 0 |
| Prova gateway | `test_gateway_endpoints.py` + `test_fastapi_auth.py` 53 passed |
| Prova MQL5 | `validate_mql5.py` [OK] |
| Runs | `mql5` CI `41951463349` success + CodeQL `41951463310` success; app 7/7 workflows success |
| Limite da API | comentario de dismissal aceita no maximo 280 caracteres (HTTP 422 acima disso) |
| Conta REAL | **nao autorizada**: ultimo backtest PF 0,92, DD 143,70%, -58,14 USD em 641 trades |

---

### Ciclo 108 - 04/11/2026

| Item | Versao | Estado | Prova |
|---|---|---|---|
| P1.108 ATR multi-simbolo nunca aquecia | v1.2.149 | FECHADO | dataset.csv com USDSEK 0.01426 e USDCNH 0.00278; 0 `[DATA] SEM LEITURA` em 22:45:40-23:10:00 |
| P1.109 simbolo do grafico lia outro par | v1.2.150 | PARCIAL | wrappers GetATR/GetADX/GetRSI delegam em (_Symbol) + cache; 15 `[START] v1.2.150` |
| P1.110 mesma falha reapareceu pos-deploy | - | ABERTO | 03:00 USDJPY gravado 2x: ATR 0.182 (certo) e ATR 28.369 + ADX 33.266 (XAUUSD) |
| P1.111 CSV escrito por varias instancias | - | ABERTO | linhas partidas/coladas no dataset.csv |
| P-07 perfil com 13 .chr e 15 instancias | - | ABERTO | USDCLP e USDCOP com `[START]` e sem `.chr` |

Compilacao: 0 errors, 0 warnings (build 6296, X64 Regular). Reattach: Default -> XAI_P216_LIVE.

### Ciclo 109 — P1.112 a P1.116 (v1.2.151 a v1.2.155)
| item | versao | estado | prova |
|---|---|---|---|
| P1.112 ATR de outro instrumento entrava na decisao | v1.2.151 | FECHADO | USDJPY ATR% 18.38 as 22:59:55 (ATR do ouro num par de iene); guarda ATR_MAX_PLAUSIBLE_PCT=5.0 |
| P1.113 sete pares liam ADX/RSI/ATR do ouro | v1.2.152 | FECHADO | 10 `[ATR] LEITURA SUSPEITA` as 23:16:40-23:17:31; depois: sonda XAI_AtrDiag 23:50:44 le o ATR proprio de cada par |
| P1.114 DiagGate desligava-se com a tabela cheia | v1.2.153 | FECHADO | auto-teste no terminal 23:43:57: chaves=256 suprimidas=3009 evacuacoes=55 falhas=0 APROVADO |
| P1.115 guarda da EMA descartava a leitura certa | v1.2.154 | FECHADO | `[TREND] ... AUDUSD EMA=0.70084 grafico=USDCNH` as 23:40:51 (0.70084 = EMA200 H1 real do AUDUSD); guarda local ao simbolo + gate ADX 3x |
| P1.116 `[CENARIO] ATR%=sem leitura` sem motivo | v1.2.155 | FECHADO (medido) | reload de 05/11 as 13:53:25.943: 13 linhas em 240 ms, uma por grafico, todas com `CopyBuffer sem barras | barsCalc=-1 | erro=4807`; os outros dois ramos nunca dispararam |
HG-01: `#property version` estava em `1.353` (=1.2.153) com `EA_VERSION_STRING`
`1.2.154`; passou a `1.354` e depois a `1.355` (=1.2.155). Regra:
`minor*100+patch` tem de coincidir com `EA_VERSION_STRING`
(`Enterprise/VersionManager.mqh`), que e a fonte unica.
Compilacao: 0 errors, 0 warnings (build 6296, X64 Regular, 18979 ms);
`XAU_AI_PRO.ex5` 897.702 bytes. Documentacao do ciclo em
`Docs/CONVERSA_20261105_P1112_P1116_V1151_V1155.md`.
O P1.116 fechou por medicao no ciclo 110: o reload foi feito e o ramo ficou
nomeado. Nao se infere mais a causa a partir da magnitude do ATR.

### Ciclo 110 - P1.117 (v1.2.156)
| item | versao | estado | prova |
|---|---|---|---|
| P1.116 qual dos tres ramos silenciosos dispara | - | FECHADO (medido) | reload 05/11 13:53:25.943-13:53:26.183: 13 `[ATR] SEM LEITURA`, todas `CopyBuffer sem barras | barsCalc=-1 | erro=4807`; zero ocorrencias dos ramos `serie nao provada` e `handle invalido` em todo o dia |
| P1.117 `ATRCacheDrop()` escrito e nunca chamado | v1.2.156 | FECHADO no codigo | `ATRCacheDrop` em `Indicators/VolatilityFilter.mqh` tinha 0 chamadas no projecto e o comentario do P1.113 estava cortado a meio; `[CENARIO] USDCNH | ATR%=sem leitura` as 13:55:06.580 = par que nunca sara |
| P1.117 portao de queda | v1.2.156 | NOVO | `ATRCacheDropAllowed()` + `ATR_DROP_GATE_SEC` 60 s por simbolo: uma queda por minuto, para nao repetir o P1.108 (libertar durante o aquecimento) |
| P1.117 diagnostico da troca de serie | v1.2.156 | NOVO | `[ATR] LEITURA SUSPEITA` passa a publicar `barsCalc`, `barrasSerie` e `barrasGrafico`, para a proxima medicao provar a troca de serie pelo numero de barras |
| P1.117 medicao em producao | v1.2.156 | MEDIDO (sem regressao) | reload 05/11 15:12:30-15:13:07: 12 `[ATR] SEM LEITURA` so no attach (10x `erro=4807`, 2x `erro=4022` no grafico USDBRL,M5) e ZERO `[ATR] LEITURA SUSPEITA` depois de 15:13:07.936; o ramo de queda nao foi exercitado em ~2 min |
| P1.117 o que falta para fechar por queda | - | ABERTO | ver uma sessao em que `[ATR] LEITURA SUSPEITA` dispare e o par sara: a linha tem de aparecer UMA vez por simbolo e o `[CENARIO] ATR%=sem leitura` nao pode voltar horas depois |
HG-01: `EA_VERSION_STRING` passou a `1.2.156` e `#property version` a `1.356`
(=1.2.156). Regra `minor*100+patch` mantida nos dois sitios;
`Enterprise/VersionManager.mqh` continua a ser a fonte unica e o changelog
`m_current.changes` leva a entrada v1.2.156 a frente.
Compilacao: 0 errors, 0 warnings (build 6296, X64 Regular, 25726 ms).
Nota de metodo: o P1.116 foi instrumentado e MEDIDO antes de se tocar na causa.
O P1.117 e a primeira correcao do ciclo que nasce de um ramo nomeado no journal
e nao de uma inferencia.

Aberto e nao explicado: `[ATR] LEITURA SUSPEITA | USDBRL | ATR=3908.848300 |
preco=5.5123 | ATR%=70911.39` (13:53:26.183). A magnitude nao e o ouro nem o
proprio par; fica a espera de medicao com `barsCalc`/`barrasSerie`.
