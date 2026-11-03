# XAU_AI_PRO — Indice do projeto

> Expert Advisor MQL5 multiativo (16 graficos), arquitetura modular, com escada
> de saida em dolares, aprendizado a partir do historico real e camadas de
> risco de carteira. Este arquivo e o PONTO DE ENTRADA da documentacao: diz
> onde cada assunto esta e qual e o estado atual medido.
>
> Versao do codigo: **v1.2.41** (`Enterprise/VersionManager.mqh` ->
> `EA_VERSION_STRING`). `#property version "1.241"` nao acompanha: MQL5 aceita
> somente dois numeros na propriedade, entao ela e o espelho "1.241".
>
> Conta REAL: `Core/RealAccountGuard.mqh` (v1.2.37, P1.10). Inerte no testador e
> em demo; em `ACCOUNT_TRADE_MODE_REAL` aperta tres regras de seguranca pura
> (lote minimo acima do teto bloqueia, vigia do stopless nunca fica em 0R,
> maximo de 1 posicao sem stop por simbolo) e publica `[REAL GUARD]` no arranque.
>
> Journal (v1.2.39, P1.3 + P1.12) e disco (v1.2.40, P1.13): o scanner emite UM resumo por minuto em vez
> de uma linha por simbolo, o bloco completo do `HEALTH MONITOR` sai 1x/hora e a
> falha de copia do backup sai 1x/hora com contador de avisos abafados. Objectivo
> medido: <200 linhas/hora em operacao normal.
>
> Disco (v1.2.40, P1.13): o `audit_log.csv` passou a rodar por tamanho
> (`AuditLogMaxSizeMb = 8`, limite efectivo 16 MB, nada e apagado) porque era ele -
> e nao a retencao de snapshots, que esta correcta em 10 - que levava cada backup a
> 78,8 MB e o disco a 0,37 GB livres.
>
> Historico (v1.2.41, P1.16): o 	rade_history.csv - o ficheiro de onde o EA
> aprende - deixou de ser escrito com handle persistente. Medido em 31/10 sobre
> 99 560 registos validos: 371 linhas partidas e 369 reinicios de ordem temporal.
> Monitoring/TradeLogger.mqh passou ao padrao F4
> (ABRIR -> LOCK -> SEEK(END) -> WRITE -> FLUSH -> FECHAR dentro do EventLock),
> como o EventEmitter e o BackupManager: sem handle persistente nao ha EOF em
> cache a gravar por cima de outra instancia e sem lock nao ha interleave. Trade nao
> gravado e um DROP contado e impresso, nunca uma linha partida.
>
> Ultima atualizacao: 2026-10-30.

---

## 1. Onde ler o que

| Documento | Para que serve |
|---|---|
| `README.md` (este) | Indice, mapa de modulos, estado ao vivo. |
| `PENDENCIAS.md` | **Lista unica de pendencias** (P / AT / CD / HG / IN), com dono, impacto e criterio de fechamento. Comece por aqui em qualquer sessao nova. |
| `PENDENCIAS_20261030.md` | Pendencias da sessao 29->30/10 (P0/P1/P2) com ficheiro:linha, valor actual e criterio de aceitacao. |
| `SESSAO_MADRUGADA_20261030.md` | Registo tecnico da sessao (patches, diagnosticos, tabelas). |
| `SESSAO_MADRUGADA_20261030_CONVERSA.md` | Transcricao resumida dos pedidos e das respostas. |
| `SESSAO_MADRUGADA_20261030_experimentos.csv` | Serie de backtests (versao, lucro, PF, DD). |
| `PROGRESS.md` | **Registro cronologico** de tudo que foi medido, decidido e mudado. Fonte da verdade historica. Comece pelas secoes `v1.2.19` em diante. |
| `BASELINE_v120.md` | Baseline numerico da v1.2.0 (referencia de comparacao). |
| `RELATORIO_FINAL_ETAPAS1_13.md` | Fechamento das etapas 1 a 13 do roadmap. |
| `ETAPA10_FINAL.md` | Deteccao de broker/ambiente (simbolo, digits, point, spread, volume, stops, freeze). |
| `ETAPA12_13_FORWARD_TEST_PRODUCTION.md` | Forward test e criterios de producao. |
| `ETAPA_20_7_20_8.md` | Ciclo 20.7 / 20.8 (reconciliacao de auditoria). |
| `FASE_FINAL_20_5_20_11.md` | Fase final do roadmap. |
| `PLANO_20_15_CHECKLIST_CIRURGICO.md` | Checklist cirurgico de mudancas. |
| `RECONCILIACAO_20_8_PROTOCOLO.md` | Protocolo de reconciliacao (audit x execucao). |
| `F4_EVENTEMITTER_SERIALIZADO.md` | EventEmitter serializado (evita corrupcao de log). |
| `FORWARD_TEST_20_6.md`, `FORWARD_DEMO_REATTACH_v120.md`, `FORWARD_WINDOW_TRACKER.md` | Forward test: janelas, reattach, rastreio. |
| `DECISAO_SIMBOLOS_20260828.md` | Decisao de quais simbolos operar. |
| `SECURITY_v120.md` | Postura de seguranca (segredos, WebRequest, limites). |

Regra de leitura: **decisao de risco/entrada so vale se estiver em
`PROGRESS.md` com o numero medido que a justifica.** Documento sem medicao e
intencao, nao prova.

---

## 2. Mapa de modulos (o que cada pasta faz)

```
XAU_AI_PRO/
├── XAU_AI_PRO.mq5      Entry point: OnInit / OnTick / OnTimer / OnDeinit,
│                       orquestra os modulos na ordem do pipeline.
├── XAU_AI_PRO.mqproj   Projeto MetaEditor (unidade de build).
├── AI/                 Motor de IA + memoria de aprendizado.
├── Core/               Config, decisao, execucao, risco, estado, pipeline.
├── Enterprise/         Robustez: circuit breaker, retry, backup, qualidade.
├── Filters/            Portoes de entrada: cenario, custo, sessao, spread...
├── Indicators/         ATR, ADX, RSI, MarketPulse, volatilidade.
├── Integration/        Ponte externa (heartbeat, gateway/Python).
├── Management/         Gestao da posicao aberta: escada em USD, break even.
├── Monitoring/         Log, saude, status, dashboard, auditoria.
└── Data/               Runtime (CSV de aprendizado, sessao, auditoria). Git-ignored.
```

### AI/ — inteligencia e memoria

| Arquivo | Papel |
|---|---|
| `AIEngine.mqh` | Score da IA, frescor (`AI_IsStale`), `AIConflictBlocks()`, `FinalAIAllow()`. |
| `AIConnector.mqh` | HTTP/WebRequest para o gateway Python + fallback por arquivo. |
| `AIClient.mqh` | Cliente enxuto de predicao. |
| `LearningHistory.mqh` | Diario append-only do aprendizado + ingestao via `HistorySelect` (trades do EA **e** manuais). |
| `AILearningMemory.mqh` | Memoria volatil por simbolo (reconstruida pelo `LearningHistory`). |
| `AdaptiveWeights.mqh` | Peso adaptativo por modulo de score. |
| `Dataset.mqh`, `DataLogger.mqh` | Coleta de features para o pipeline Python. |
| `AIMetrics.mqh`, `ModelGovernance.mqh` | Metricas e governanca do modelo (nao troca de motor sem medicao). |

### Core/ — decisao e execucao

| Arquivo | Papel |
|---|---|
| `Config.mqh` | **Todos os `input`** do EA (risco, alvos, escada, cenarios, custo). |
| `TradePipeline.mqh` | Eleicao da instancia **mestre** (`XAI_PRO_PIPE_MASTER_<login>` + heartbeat TTL 180 s). |
| `MarketScanner.mqh` | Varre a cesta de simbolos, trava por tempo por simbolo. |
| `SignalCore.mqh`, `SignalCoreV2.mqh` | Geracao de sinal tecnico (A/B por input). |
| `DecisionEngine.mqh` | `AllowTradeEx()`: correlacao -> score -> veto IA -> motivo do bloqueio. |
| `ValidationEngine.mqh` | Portoes finais: spread, cenario/tendencia, hora proibida (GMT), log com throttle. |
| `ExecutionEngine.mqh` | Lote -> alvo -> `CostGate` -> risco x orcamento -> envio da ordem. |
| `RiskEngine.mqh`, `RiskCenter.mqh`, `RiskHub.mqh` | Cadeia equity -> % -> SL -> tick -> lote; drawdown. |
| `PositionManager.mqh` | Gestao da posicao aberta, trava da meta do dia. |
| `SessionState.mqh` | Estado do dia persistido (`Data/XAU_AI_PRO_session.csv`). |
| `SymbolManager.mqh`, `SymbolValidator.mqh`, `BrokerInfo.mqh`, `BrokerConfig.mqh` | Perfil do simbolo/broker sem hard-code. |
| `StateMachine.mqh`, `TimeFrameManager.mqh`, `CompatibilityManager.mqh` | Estados, TF, compatibilidade. |

### Filters/ — portoes (ordem em que barram)

| Arquivo | Papel |
|---|---|
| `GlobalScenario.mqh` | Classe do ativo, sessao GMT, fator de lote por sessao, guarda de correlacao de moeda, **horas proibidas em GMT**. |
| `MarketScenario.mqh` | ADX + ATR% -> `ENUM_MARKET_SCENARIO` (TENDENCIA_FORTE/TENDENCIA/LATERAL/VOLATIL). |
| `CostGate.mqh` | **Custo (spread + comissao) em dolares contra o alvo e o risco.** |
| `SessionFilter.mqh` | Caminho legado de hora (hora de servidor) quando `EnableAvoidHoursGMT=false`. |
| `SpreadFilter.mqh`, `NewsFilter.mqh`, `TrendFilter.mqh`, `MultiTimeframeFilter.mqh`, `MarketRegime.mqh` | Spread, noticias, tendencia, multi-TF, regime. |

### Management/ — saida

| Arquivo | Papel |
|---|---|
| `MoneyLadder.mqh` | **Escada em dolares**: arma em 10, trava em 5 depois de 15, alvo 20 (dono unico de SL/TP quando ligada). |
| `BreakEven.mqh` | Break even em **R** (`BreakEvenInR`, gatilho 0,60 R, trava 0,30 R). |
| `DailyRisk.mqh`, `EquityProtection.mqh`, `PortfolioManager.mqh` | Risco diario, protecao de equity, carteira. |

### Enterprise/ — robustez

`CircuitBreaker.mqh` (SAFE MODE com histerese), `OrderRetry.mqh`,
`ExecutionQuality.mqh`, `ExecutionStats.mqh`, `RecoveryManager.mqh`,
`SafetyManager.mqh`, `BackupManager.mqh`, `PositionSynchronizer.mqh`,
`MarginChecker.mqh`, `VolumeValidator.mqh`, `NotificationCenter.mqh`,
`VersionManager.mqh`, `AntiLoop.mqh`, `FailureMode.mqh`, `SmartExecution.mqh`,
`Telemetry.mqh`, `TradeMonitor.mqh`, `BenchmarkEngine.mqh`,
`BrokerAnalyzer.mqh`, `ConfigManager.mqh`, `ConnectionGuard.mqh`,
`DatabaseManager.mqh`, `Scheduler.mqh`, `SimulationEngine.mqh`.

### Monitoring/ — observabilidade

`SystemStatus.mqh`, `HealthMonitor.mqh`, `OperatorBrief.mqh` (`[RESUMO]`),
`Diagnostics.mqh`, `AuditLog.mqh`, `EventEmitter.mqh`, `Statistics.mqh`,
`PerformanceAnalyzer.mqh`, `QuantValidator.mqh`, `ProductionChecklist.mqh`,
`ValidationChecklist.mqh`, `TradeLogger.mqh`, `Dashboard.mqh`,
`ForwardTestRunner.mqh`, `ReplayEngine.mqh`, `BacktestAnalyzer.mqh`.

---

## 3. Ordem real dos portoes (por que "nao abriu")

```
OnTick (somente a instancia mestre processa a cesta)
 1. TradePipeline      -> nao e mestre? STANDBY, nao processa.
 2. MarketScanner      -> sinal tecnico; trava MinSecondsBetweenTradesPerSymbol.
 3. DecisionEngine     -> CurrencyExposureGuard -> score minimo -> veto IA.
 4. ValidationEngine   -> spread -> cenario/tendencia -> hora proibida (GMT).
 5. ExecutionEngine    -> lote -> alvo -> CostGate -> risco x orcamento -> envio.
```

Cada etapa escreve o motivo exato no journal (`Motivo=` no `[SCANNER] BLOCK`,
`[VALIDATION] BLOCK | ...`, `EXECUTION: CUSTO BLOQUEADO`, `[RISK] ...`). **A
resposta para "por que nao entrou" esta no journal, nao em suposicao.**

### 3.1 Instancia mestre do pipeline (P2.3)

Com `EnablePipelineMasterGuard=true`, **uma unica** instancia por conta executa
o pipeline e a gestao de posicoes. A eleicao usa a variavel global
`XAI_PRO_PIPE_MASTER_<login>` e um heartbeat com TTL de **180 s**
(`Core/TradePipeline.mqh`, `PIPELINE_MASTER_TTL_SEC`).

- Enquanto o dono publica heartbeat, as outras instancias escrevem
  `[PIPELINE] STANDBY | outra instancia e a dona do pipeline` **1x/hora**.
- **Failover:** se o dono parar de publicar por >= 180 s (grafico fechado, EA
  removido, terminal fechado), a primeira instancia que avaliar
  `PipelineIsMaster()` assume e publica o seu proprio heartbeat. Nao ha
  intervencao manual.
- **Risco:** os 180 s sao o tempo maximo sem pipeline. Nesse intervalo
  nenhuma instancia abre nem gere posicoes. Fechar o grafico mestre com
  posicoes abertas deixa-as sem escada durante esse intervalo - fechar o
  mestre com a cesta vazia ou re-anexar o EA logo em seguida.
- O mestre observado na demo em 30/10/2026 era o grafico `22884787070177`
  (XAUUSD M15), mas a identidade e **dinamica**: nao fixar o chart id.

---

## 4. Estado ao vivo (medido em 2026-10-30 05:21, conta 113568614)

| Item | Valor medido |
|---|---|
| Conta | 113568614 (MetaQuotes-Demo, hedging) |
| MagicNumber / comentario | `2026001` / `XAU_AI_PRO` |
| Graficos com o EA | 15 (XAUUSD M15 + 14 pares), medido em 31/10 15:56 - o perfil tem 15 graficos, nao 16 |
| Binario carregado | `XAU_AI_PRO.ex5` recompilado em 31/10 15:50 com **v1.2.41** (P1.16, 0 erros/0 avisos, 640 754 B). Os 15 graficos foram re-anexados as 15:24:54 com o binario anterior (**v1.2.40**) e continuam com os inputs antigos (`DynADXClear 25.0`, `AvoidHoursGMT "18,20,22"`, `MinimumADX 18.0`): P1.14/P1.15 nao estao aplicados e `[VERSION]` so muda depois de re-anexar de novo - inputs guardados no `.chr` nao mudam sozinhos |
| Posicoes abertas | 1 - EURUSD `sell` 0,03 @ 1,11794 (ticket `11171034182`), TP 1,11127 |
| Resultado do dia | +16,38 USD realizados em 3 fechamentos |
| Trades do dia | 3 de 100 (`Trades: 3/100`) |
| Recuperacao / saude | `RECOVERY_OK` / `HEALTHY`, 0 falhas em todos os canais |
| `[GLOBAL]` | Ativo: classe + sessao GMT + fator de lote (ex.: `USDBRL classe=EXOTICO ... lote x0.64`) |
| `[CIRCUIT]` | Somente `initialized`; **0** ocorrencias de `SAFE MODE` na madrugada |
| `[COST]` | **Confirmado em producao** as 30/10 03:47: custo 0,06 US$ = 0,6% do alvo, spread 2,0 pts, alvo 312 pts |

Leitura honesta: o robo esta **ativo e saudavel** e voltou a operar - o
primeiro `[COST] OK` real apareceu as 03:47 e gerou a entrada EURUSD. Tres
fechamentos positivos somam +16,38 e **nao** sao estatistica nem prova de lucro.

---

## 5. Parametros que mexem em dinheiro (nao alterar sem medicao)

| Input | Onde | Efeito |
|---|---|---|
| `RiskPerTradePercent` | `Config.mqh` | Risco por operacao (0,50%). |
| `MaxRiskPerTradePercentCap` | `Config.mqh` | Teto do risco por trade (3,0%). |
| `MaxTotalRiskPercent` | `Config.mqh` | Envelope de risco aberto (10,0%). |
| `MaxDailyLossPercent` / `MaxDrawdownPercent` | `Config.mqh` | Freios de perda. |
| `EnableMoneyLadder`, `LadderArmUsd/LockUsd/LockTriggerUsd/TpUsd` | `Config.mqh` | Escada de saida em **dolares** (10 / 5 / 15 / 20). |
| `EnableStoplessEntry`, `StoplessArm*` | `Config.mqh` | Entrada sem SL, SL armado depois. |
| `EnableCostGate`, `MaxCostPctOfTarget`, `MaxCostPctOfRisk`, `CommissionPerLotUsd` | `Config.mqh` | Trava de custo. |
| `EnableAvoidHoursGMT`, `AvoidHoursGMT`, `AvoidHoursByClass` | `Config.mqh` | Horas proibidas em GMT. |
| `CircuitBrokerFailMinCheck/MinSeconds/WarmupSeconds` | `CircuitBreaker.mqh` | Histerese do SAFE MODE por broker. |
| `EnableAutonomousMode`, `MinMarketScore`, `BlockZeroAIScore` | `Config.mqh` | IA consultiva vs IA com veto. |

**Regra do projeto:** toda mudanca aqui exige o numero antes e depois
(`PROGRESS.md`) e, quando possivel, backtest.

---

## 6. Como compilar e validar

```bat
:: Compilar (Windows com MetaEditor instalado)
"C:\Program Files\MetaTrader 5\MetaEditor64.exe" /compile:"...\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5" /log
```

Pela IDE: abrir `XAU_AI_PRO.mqproj` e compilar. Alvo: **0 erros, 0 avisos**.
Validacao estatica (sem MetaEditor), na pasta do EA:

```bat
py -3 ../../.github/scripts/validate_mql5.py
```

Convencoes que quebram o build se ignoradas:
- encoding **UTF-8**; `.mqh` antigos tem BOM e devem preserva-lo;
- quebra de linha **CRLF** (LF solto quebra o padrao do projeto);
- `#include` e case-sensitive no disco.

---

## 7. Pendencias abertas (ordem de valor)

1. **WebRequest + token**: habilitar `Ferramentas > Opcoes > Expert Advisors >
   Permitir WebRequest para URLs listadas` com `http://127.0.0.1:9001` e
   preencher `AIGatewayToken`. Sem isso o erro 4014 persiste e a IA roda em
   fallback (`RequireAIJSON=false`, `AllowTradeWithoutAI=false`).
2. **Meta efetiva do dia**: `EnableDailyTargetBalancePct=true` com
   `DailyProfitTargetBalancePct=10` e `DailyProfitTargetMaxUsd=40` faz a meta
   de hoje ser **40 USD** (teto de P1.2; era 100), nao os 20 USD do `LadderTpUsd`. Decisao do dono.
3. **Backtest 20-29/10** (`Profiles/Tester/xai_v1300_c5.ini` + `.set`):
   comparar com o baseline 303 trades / PF 0,8961 / -30,95 / DD 1,68%.
   Atualizar o `.set` com os inputs novos antes, senao herda defaults.
4. **`StoplessEmergencyPoints`** = 0 hoje (sem colchao de emergencia).
5. **Lote 1,36 em USDCNH** — revisar `RiskPerTradePercent` x
   `DynLotFactorElite` x `ScenarioLotFactor` x `SessionLotFactor`.
6. **Sonda `XAI_TargetProbe`** repetir com a escada ativa e comparar
   `realizado_R` x `mfe_R` antes de mexer em alvo > 1 R.
7. **Aberto desde v1.2.26** (continua na fila): alimentar o `CostGate` com **slippage realizado**
   (`ExecutionQuality.mqh` ja registra); reancorar
   `CostMinViableTargetPoints` por backtest.

---

## 8. Aviso

Este EA executa ordens reais quando anexado a uma conta real. Nenhuma
afirmacao de lucratividade aqui e promessa: backtest nao prova resultado
futuro. Toda versao deste projeto e validada por compilacao 0/0 **e** por
leitura do journal ao vivo antes de ser considerada ativa.
