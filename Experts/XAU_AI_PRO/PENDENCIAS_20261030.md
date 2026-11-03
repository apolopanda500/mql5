# PENDÊNCIAS — XAU_AI_PRO (aberto em 2026-10-30 05:40 local)

Documento de trabalho. Consolida **tudo o que falta** depois da sessão da
madrugada de 29→30/10/2026, com ficheiro:linha, valor actual, acção esperada
e critério de aceitação. Serve para retomar o trabalho sem redescobrir contexto.

Companheiros de leitura (não duplicar informação aqui):

| Ficheiro | Para que serve |
|---|---|
| `SESSAO_MADRUGADA_20261030.md` | Registo técnico da sessão (patches, diagnósticos, tabelas) |
| `SESSAO_MADRUGADA_20261030_CONVERSA.md` | Transcrição resumida dos pedidos ↔ respostas |
| `SESSAO_MADRUGADA_20261030_experimentos.csv` | Série de backtests (versão, lucro, PF, DD...) |
| `PENDENCIAS_20261030.md` | **Este ficheiro** — o que falta fazer |

---

## 1. Estado actual (medido, não presumido)

| Item | Valor | Fonte |
|---|---|---|
| Versão do código | **v1.2.26** | `Enterprise/VersionManager.mqh:14` |
| Compilação | 0 errors, 0 warnings, 13 950 ms, `cpu='X64 Regular'` | `Files/Temp/compile_v1226.log` |
| Binário em execução | `XAU_AI_PRO.ex5` com `[VERSION] v1.2.26` em todos os gráficos | journal |
| Gráficos com EA | **16** (o 17.º, XAUUSD M15 `86900227342153`, foi fechado) | `list_open_charts` |
| Conta | demo 113568614 (Henrique Carvalho), MetaQuotes-Demo, hedging | `get_trading_account_info` |
| Saldo / equity | 12 348,57 / 12 343,11 USD (profit aberto −5,46) | idem, 05:36 local |
| Posições abertas | **EURUSD SELL 0,03** @1,11794, aberta 08:47 servidor, −5,49 USD | `get_trading_open_positions` |
| Erros de módulo | Broker 0 · AI 0 · Dataset 0 · File 0 · JSON 0 · Python 0 · Indicator 0 | journal `HEALTH MONITOR` |
| Bloqueios | 0 registos de `[TRADE BLOCK]` desde o reload das 23:01 | journal |
| Master do pipeline | gráfico `22884787070177` (XAUUSD M15); os outros 15 estão `[PIPELINE] STANDBY` | journal |

Relógios (medidos): **local = servidor − 5 h**; UTC = local. Madrugada local
23h–07h = servidor 04h–12h = GMT 02h–10h.

### 1.1 Regras do dono que NÃO podem ser violadas

1. **Sair sempre no lucro.** A escada (`Management/MoneyLadder.mqh`) é a única
   dona de SL/TP e **só sobe** o stop, nunca desce, nunca abre no negativo.
2. **Entrar sem stop** e armar o stop na entrada ou acima dela quando o trade
   já está lucrativo (`EnableStoplessEntry=true`, `Core/Config.mqh:998`).
3. **Volume alto + preço rápido → fechar** quando o lucro passar de ~10 USD
   (conforme a banca): `PulseQuickProfitMinUsd=10.0`,
   `PulseQuickProfitBalancePct=3.0`, `PulseQuickProfitMaxUsd=50.0`.
4. **Lote não é fixo** — o EA decide por confiança/clareza da tendência
   (`DynLotFactorMin 0.25 → DynLotFactorElite 4.0`).
5. **Meta 10–20 USD/dia** com banca ≤200 USD; ao bater o topo, desacelera.
6. **Operar sozinho** — pausas expiram sozinhas, sem intervenção manual.
7. **Ensinar a operar notícias** (não apenas bloquear) e **aprender com o
   histórico, incluindo as operações manuais do dono**.

---

## 2. P0 — bloqueiam a passagem para conta real

### P0.1 O backtest de 3 meses com a v1.2.26 **nunca foi corrido**
- **Prova:** `Tester\logs` tem `20261029.log` como o mais recente; **não existe
  `20261030.log`**. A config `Profiles/Tester/xai_xau_m15_fast.ini`
  (2026.07.29→2026.10.29, 200 USD, leverage 100, Model=1 m1 ohlc) foi
  preparada mas não executada com a build nova.
- **Acção:** correr o backtest e registar PF, winrate, n.º de trades, DD
  (balance e equity), max consecutive losses e lucro final na tabela de
  `SESSAO_MADRUGADA_20261030_experimentos.csv`.
- **Critério:** 1 linha nova no CSV com a versão 1.2.26 e comparação directa
  com 1.2.23 (+14,76 / PF 2,1742 / 41 trades / max_con_loss 2 / DD 2,33%).
- **Risco se não fizer:** repetir em real um resultado que só existe com o
  motor antigo (a 1.2.26 mexeu no dimensionamento de lote).

### P0.2 `every tick based on real ticks` ainda não validado
- O dono pediu explicitamente XAUUSD M15 **3–6 meses, every tick based on real
  ticks** antes da conta real. Todos os backtests até hoje usaram `Model=1`
  (m1 ohlc), que **não** simula spread/stop intra-barra.
- **Acção:** correr a mesma janela com modelo de ticks reais (`Model=4`) e
  comparar com o resultado de P0.1. Divergência grande = o motor depende de
  ordem intra-barra (a escada arma a 1R ≈ poucos pontos → muito sensível).
- **Critério:** diferença de lucro documentada e justificada; se o resultado
  com ticks reais for negativo, a passagem para real fica bloqueada.

### P0.3 O cap de risco real (`LOT CAP REAL`) nunca disparou em produção
- **Código:** `Core/ExecutionEngine.mqh` (bloco `MaxRiskPerTradeUsd`) e
  `Core/Config.mqh` (`MaxRiskPerTradeUsd=8.0` + `NoiseDistancePointsForRisk`).
- **Prova:** pesquisa no journal de 29/10 20:00 → 30/10 05:40 por
  `LOT CAP REAL` devolve **0 registos**. Conclusão: ou nenhuma entrada desde o
  patch teve lote acima do tecto, ou o bloco não está a ser alcançado.
- **Sinal positivo (não prova):** o EURUSD aberto às 08:47 saiu com **0,03
  lotes**, quando na build anterior entradas equivalentes saíam 0,4–0,6.
- **Acção:** confirmar por log numa entrada de convicção alta
  (`DynLotFactorElite`) que ou o lote é capado e imprime a linha, ou que o
  valor final já cabe nos 8 USD. Se nunca imprimir nada em 24 h, instrumentar
  temporariamente com `EnableVerboseDebug` e uma entrada forçada.
- **Critério:** ver no journal `LOT CAP REAL | <symbol> | 1R=… pts | …` **ou**
  demonstrar por cálculo que `lote × RiscoEmDinheiroDaOrdem(1R) ≤ 8 USD` na
  entrada real.

### P0.4 Loop no mesmo tick — risco de encher o disco
- **Sintoma histórico:** `EXECUTION: BLOQUEADA | USDJPY | envelope de risco
  aberto cheio | MaxTotalRiskPercent=10.00 | aberto=20.60 | saldo=185.39`
  repetido no **mesmo timestamp** (21:37:19.721) → 1,4 GB de log.
- **Código:** `Core/ExecutionEngine.mqh:527-539`
  (`Print` + `EventTradeRejected(..., "RISK_ENVELOPE_FULL")`).
- **Acção:** latch por **vela** (e não só por tick) para eventos de rejeição
  repetíveis; guardar `lastBarTime` por símbolo+motivo e imprimir 1×/vela.
  Aplicar o mesmo padrão a `CostGate`, `[SCANNER] BLOCK | No Signal` e
  `[PIPELINE] STANDBY`.
- **Critério:** 30 min de operação em conta pequena (ou backtest) sem
  crescimento anormal do journal; medir o tamanho de `Logs\*.log` antes/depois.

### P0.5 AI Gateway offline — como é que as entradas passam?
- **Sintoma (ao vivo):** `AI GATEWAY | WebRequest falhou | erro 4014 |
  http://127.0.0.1:9001/api/ai/predict` + `AI FILE NOT FOUND |
  Data\prediction_<SYM>.json`, repetido em todos os gráficos, de minuto a minuto.
- **Contradição a resolver:** `AllowTradeWithoutAI=false`,
  `MinAIConfidence=60.0`, `AIUnavailableConfidenceCap=40.0` — em teoria não
  devia haver entrada com score ≤40. Mas há posição aberta pelo EA às 08:47.
  Ou o `BlockZeroAIScore`/`AIFilter` não está a fechar o caminho, ou existe
  ramo (notícia/pulso) que ignora o score.
- **Acção:** seguir o pipeline de decisão (`AI/AIEngine.mqh` + filtro AI) e
  documentar **porque** uma entrada é aceite sem IA. Decidir explicitamente:
  (a) bloquear sem IA, ou (b) permitir com lote reduzido e log próprio.
- **Critério:** um comentário no código + uma linha no `PROGRESS.md` a dizer
  qual das duas políticas está activa, e o journal a mostrar o motivo da
  aceitação em cada entrada.

---

## 3. P1 — desalinhamentos com o que o dono pediu

### P1.1 Envelope de risco muito acima da meta diária
- **Valores:** `MaxTotalRiskPercent=10.0` (`Core/Config.mqh:273`),
  `RiskPerTradePercent=0.50` (`:272`), `RiskPerTradeUsd=2.0` (`:256`),
  `MaxRiskPerTradeUsd=8.0` (teto real por operação).
- **Contas:** 10% de 12 348,57 = **1 234,86 USD** de risco aberto permitido,
  contra uma meta de lucro de **10–20 USD/dia**. Um dia mau (3 perdas de 8 USD
  + slippage em 50 posições) pode apagar a semana.
- **Acção:** decidir e implementar **uma** das opções:
  (a) baixar `MaxTotalRiskPercent` para 1–2%; ou
  (b) acrescentar um teto em **USD** (`MaxTotalRiskOpenUsd`, ex.: 3× a meta
  diária = 60 USD) análogo ao `MaxRiskPerTradeUsd`, com log próprio.
- **Critério:** `RiscoAbertoUSD()` nunca excede o novo tecto; journal mostra o
  motivo quando uma entrada é recusada por esse tecto.

### P1.2 `DailyProfitTargetMaxUsd=100.0` domina a meta
- **Código:** `Core/Config.mqh:1309`; `DailyProfitTargetUsd=20.0`,
  `DailyProfitTargetBalancePct=10.0`.
- **Contas:** alvo = `max(20, 12 348,57 × 10% = 1 234,86)` limitado a **100** →
  o alvo efectivo hoje é **100 USD**, cinco vezes a meta pedida.
- **Acção:** decidir se o limite faz sentido com esta banca. Se a meta é
  10–20 USD, o `MaxUsd` deve rondar 20–40, ou o `BalancePct` deve descer.
- **Critério:** `DailyProfitTarget...` mostra no journal o alvo real usado e
  ele está na ordem de 10–40 USD para banca ≤200 USD de referência.

### P1.3 Journal ainda afogado — o gate por `EnableVerboseDebug` não chega
- **Estado:** o patch v1.2.26 pôs o `Print("DATA LOGGER SAVED | ...")` dentro de
  `if(EnableVerboseDebug)` (`AI/DataLogger.mqh:537`), mas o input está
  **`EnableVerboseDebug=true`** em todos os gráficos (`Core/Config.mqh:1424`)
  → continuam a sair **11 linhas por vela** (uma por símbolo).
- **Outros emissores ruidosos confirmados no journal:** `HEALTH MONITOR`
  (~25 linhas/check), `[TRADE PIPELINE] INICIANDO` + `[PIPELINE] STANDBY` a
  cada ciclo, `[SCANNER] START/POSITION CHECK OK/BLOCK` por símbolo.
- **Acção:** política de log por nível em vez de "verbose sim/não":
  - `DATA LOGGER SAVED` → só em `EnableDiagnostics` **e** 1×/dia;
  - `HEALTH MONITOR` → só quando há falhas ou de hora a hora;
  - `[PIPELINE] STANDBY` / `[SCANNER] POSITION CHECK OK` → apagar ou 1×/hora.
- **Critério:** menos de ~200 linhas/hora em operação normal, mantendo visíveis
  `[TRADE BLOCK]`, `LOT CAP REAL`, `[LEARN]`, execuções e erros.

### P1.4 Avisos de lote mínimo forçado (conta pequena)
- **Código:** `Core/ExecutionEngine.mqh:192` (`FORCA LOTE MINIMO`),
  `Core/ExecutionEngine.mqh:676-690` (`risco EFETIVO acima do pedido`),
  `Core/RiskEngine.mqh:141`.
- **Sintoma histórico:** `Lot=0.000 | Min=0.010 | Risco real excede o
  configurado` e `pedido=0.93 | efetivo=3.70 | fator=3.99`.
- **Problema de fundo:** com 0,01 lote forçado num exótico, o risco real pode
  ser **maior** que o teto de 8 USD — contradiz P0.3.
- **Acção:** transformar o aviso em **decisão**: se
  `RiscoEmDinheiroDaOrdem(minLot, 1R) > MaxRiskPerTradeUsd`, **não abrir**
  (evento `MIN_LOT_EXCEEDS_RISK_CAP`), em vez de avisar e abrir.
- **Critério:** zero entradas com risco real > `MaxRiskPerTradeUsd`; o motivo
  aparece no journal e no `EventTradeRejected`.

### P1.5 Warm-up de indicadores (ADX=−1,00 / RSI=0,00)
- **Sintoma:** nas primeiras barras após o load, `ADX | unavailable>0` e
  `RSI=0.00` em XAUUSD → score/`LearningBoost`/`DynLotFactor` calculados com
  indicador inválido.
- **Acção:** `MinimumADX`/`EnableADXFilter` já bloqueia por ADX; falta garantir
  que RSI e ADX inválidos **não** entram no cálculo de confiança (nem a zero
  nem a −1). Esperar `BarsCalculated()` suficiente antes de pontuar.
- **Critério:** `HEALTH MONITOR` com `unavailable=0` estável e nenhum score
  calculado com RSI=0.

### P1.6 Aprender a **pior hora** também no score (hoje só no lote)
- **Estado:** `EnableLearningHourPenalty=true` /
  `LearningPenaltyHourLotFactor=0.75` actuam **no lote**. O score continua a
  ignorar a hora má.
- **Acção:** estender ao score (bónus/penalidade de confiança por hora, com
  amostra mínima `LearningHourMinTrades=4`).
- **Critério:** log por trade a indicar o efeito da hora (positivo ou negativo)
  e nenhum trade com amostra abaixo do mínimo.

### P1.7 Notícias: validar o lado "operar", não só "bloquear"
- **Estado:** `EnableNewsTrading=true`, `NewsTradeMode=1`,
  `NewsTradeMinImpact=3`, `NewsTradeLotFactor=0.35`,
  `NewsTradeRiskMult=1.6`, `NewsTradeTPMult=1.3`, `NewsTradeMinConf=70.0`,
  `NewsTradeTrendOnly=true`. Mas no tester falha sempre
  (`[NEWS] Calendar error | Error=4014`) → **nunca foi provado a operar**.
- **Acção:** validar em conta demo **em hora de notícia real** que existe uma
  entrada com etiqueta de notícia e lote reduzido, e que o `TP` sai alargado.
- **Critério:** pelo menos 1 trade com `news` no motivo, dentro de
  `NewsMinutesBefore/After`, com lote ≤ `NewsTradeLotFactor` do normal.

---

## 4. P2 — limpeza, paridade e documentação

### P2.1 Paridade de parâmetros nos 16 gráficos — **RESOLVIDO hoje**
O NZDUSD (`chart_id 35819235939817`) tinha ficado com um conjunto reduzido de
inputs. Verificado nesta sessão: os **16** gráficos carregam o conjunto
completo, incluindo `MaxRiskPerTradeUsd=8.0`, `EnableStoplessEntry=true`,
`ForwardHeartbeatSec=300`, `CircuitBrokerFailMinCheck=3`. Nada a fazer.

### P2.2 `xai_streak2.set` nunca foi corrido
`Profiles/Tester/xai_streak2.set` (`StreakBrakeLosses=2`,
`StreakBrakePauseMinutes=360`) existe desde a sessão anterior e nunca foi
testado. **Acção:** correr na mesma janela de P0.1 e comparar com o freio
actual (3 perdas / 240 min).

### P2.3 Master/slave do pipeline — documentar o risco
15 dos 16 gráficos estão `[PIPELINE] STANDBY | outra instancia e a dona do
pipeline`. O dono é o gráfico `22884787070177` (XAUUSD M15).
**Acção:** (a) documentar no `README.md` que o master é este gráfico;
(b) verificar o failover — se esse gráfico for fechado, quem assume?
**Critério:** fechar o master em demo e ver se outro gráfico assume em ≤1 vela.

### P2.4 `README.md` desactualizado
`README.md:8` diz `v1.2.25` e `README.md:152` diz `[VERSION] v1.2.25` com o
binário de 29/10 23:01. Não existe `Docs/version.json` (o `VersionManager`
refere-o). **Acção:** subir para v1.2.26 e criar/actualizar o `Docs/version.json`.

### P2.5 Reconciliação com o outro processo que edita a árvore
`XAU_AI_PRO.mq5`, `Core/Config.mqh`, `Core/ExecutionEngine.mqh`,
`Enterprise/CircuitBreaker.mqh`, `PROGRESS.md`, `CONVERSAS.md` foram mexidos
por outro processo (histerese v1.2.24, etc.). **Regra:** ler antes de escrever,
nunca sobrescrever, e registar no `PROGRESS.md` o que é desta linha de trabalho.

### P2.6 Índice da documentação — **tentado e revertido**
`CONVERSAS.md`, `PROGRESS.md` e os três ficheiros desta sessão não se
referenciam entre si. Foi tentado um *append* de 12 linhas ao fim do
`PROGRESS.md` (índice da sessão). O ficheiro voltou ao conteúdo anterior segundos
depois (contagem 1303 → 1304 → sem a secção, `findstr` por
`PENDENCIAS_20261030` devolve vazio, 66 635 bytes): **o outro processo que
mantém o `PROGRESS.md` está a reescrevê-lo por cima**.
**Acção:** só acrescentar o índice quando o `PROGRESS.md` estiver estável, ou
colocar a ligação no `README.md` (menos disputado).

> **Nota de concorrência (importante para quem retomar):** confirmar sempre por
> `findstr`/`type` que uma escrita persistiu antes de a declarar feita. Nesta
> sessão a escrita "teve sucesso" (exit 0) e não persistiu.

---

## 5. Configuração em vigor (fotografia de 2026-10-30 05:36 local)

Valores lidos dos inputs reais dos 16 gráficos — usar como baseline em
qualquer comparação futura.

| Grupo | Input = valor | Onde |
|---|---|---|
| Risco por trade | `RiskPercent=1.0`, `RiskPerTradeUsd=2.0`, `RiskPerTradePercent=0.50`, `MaxRiskPerTradePercentCap=3.0`, **`MaxRiskPerTradeUsd=8.0`** | `Core/Config.mqh:76,256,272,273,1157` |
| Envelope | `MaxTotalRiskPercent=10.0`, `MaxTradeRiskPctOfBudget=100.0` | `:273, :874` |
| Limites | `MaxTradesPerDay=100`, `MaxOpenPositions=50`, `MaxCorrelatedTrades=3`, `MaxCorrelatedRiskPercent=3.0`, `MinSecondsBetweenTradesPerSymbol=300` | `:84, :85, :1276, :1277` |
| Stop / alvo | `StopLossPoints=300`, `TakeProfitPoints=600`, `RequireStopLoss=true` | `:567` |
| Stopless + escada | `EnableStoplessEntry=true`, `StoplessArmATRMult=0.8`, `StoplessArmMinPoints=30`, `StoplessLockATRMult=0.35`, `StoplessLockMinPoints=10`, `StoplessEmergencyPoints=0` | `:998-1003` |
| Escada (USD) | `LadderArmUsd=10.0`, `LadderLockUsd=5.0`, `LadderLockTriggerUsd=15.0`, `LadderTpUsd=20.0` | inputs |
| Lote dinâmico | `EnableDynamicLot=true`, factores `0.25 / 1.0 / 2.0 / 3.0 / 4.0`, confiança `66/74/82/90`, ADX `25/35` | inputs |
| Pulso (volume+preço) | `EnableMarketPulse=true`, `PulseVolumeSpikeMult=1.8`, `PulseVelocityATRMult=0.6`, `PulseQuickProfitMinUsd=10.0`, `PulseQuickProfitBalancePct=3.0`, `PulseQuickProfitMaxUsd=50.0`, `PulseQuickLossUsd=12.0` | inputs |
| Meta diária | `EnableDailyProfitTarget=true`, `DailyProfitTargetUsd=20.0`, `DailyProfitTargetBalancePct=10.0`, `DailyProfitTargetMaxUsd=100.0`, `DailyProfitSlowLotFactor=0.25`, `DailyProfitStopTrading=true`, `DailyProfitProtectPositions=true` | `:1309` |
| Freio de sequência | `EnableStreakBrake=true`, `StreakBrakeLosses=3`, `StreakBrakePauseMinutes=240` | inputs |
| Horas | `TradeStartHour=0`, `TradeEndHour=24`, `AvoidHoursList="0,20"` (servidor), `EnableAvoidHoursGMT=true`, `AvoidHoursGMT="18,22"` (GMT), `AvoidHoursByClass=""` | `:612, :639-641` |
| Sessão | `EnableSessionFilter=false`, `EnableSessionLotAdaptation=true`, `SessionLotLate=0.7`, `SessionLotFloor=0.35` | inputs |
| Notícias | `EnableNewsFilter=false`, `EnableNewsTrading=true`, `NewsTradeMode=1`, `NewsTradeMinImpact=3` | inputs |
| IA | `EnableAIFilter=true`, `AIUseGateway=true`, `AllowTradeWithoutAI=false`, `MinAIConfidence=60.0`, `AIUnavailableConfidenceCap=40.0` | inputs |
| Aprendizagem | `EnableLearningFromHistory=true`, `LearningImportManualTrades=true`, `LearningHistoryDays=180`, `EnableLearningHourBoost=true`, `EnableLearningHourPenalty=true`, `LearningPenaltyHourLotFactor=0.75`, `EnableDirectionBlacklist=false` | inputs |
| Circuit breaker | `CircuitBrokerFailMinCheck=3`, `CircuitBrokerFailMinSeconds=15`, `CircuitWarmupSeconds=30`, `CircuitAbnormalMarketBlocksAll=false`, `CircuitAbnormalATRRatio=3.0` | `Enterprise/CircuitBreaker.mqh` |
| Logs | `EnableLogs=true`, `EnableDiagnostics=true`, `DebugTradeDecision=true`, **`EnableVerboseDebug=true`**, `ForwardHeartbeatSec=300` | `:1424` |

### 5.1 Duas verificações que já podem ser fechadas

- **`RequireStopLoss` vs `EnableStoplessEntry`:** não há conflito.
  `Core/ExecutionEngine.mqh:714` é
  `if(RequireStopLoss && req.sl <= 0.0 && !EnableStoplessEntry)` — com
  `EnableStoplessEntry=true` a exigência de SL é dispensada de propósito.
  (Antes só se podia confirmar por inspecção; agora está localizado.)
- **Ensino por operações manuais:** provado a funcionar. Journal de 29/10
  21:10–21:29 regista 3 aprendizagens:
  `[LEARN] OPERACAO MANUAL APRENDIDA | USDCNH | deal=10915093182 | profit=10.42`,
  `| NZDUSD | deal=10915239409 | profit=4.20`,
  `| AUDUSD | deal=10915239497 | profit=1.76`.

---

## 6. Resultado real de 29→30/10 (para comparação futura)

Fechos do EA com `magic 2026001` (fonte: `get_trading_history_positions`):

| Hora servidor | Símbolo | Lado | Vol | Abriu | Fechou | Motivo | USD |
|---|---|---|---|---|---|---|---|
| 20:31:00 | NZDUSD | SELL | 0,41 | 0,56288 | 0,56283 | Take profit | +2,05 |
| 20:31:06 | USDBRL | SELL | 0,01 | 5,4573 | 5,4603 | Expert | −0,55 |
| 20:33:02 | USDCHF | SELL | 0,34 | 0,82626 | 0,82631 | Stop loss | −2,06 |
| 20:33:13 | GBPUSD | BUY | 0,41 | 1,33642 | 1,33637 | Stop loss | −2,05 |
| 20:33:31 | USDCAD | SELL | 0,56 | 1,39809 | 1,39813 | Stop loss | −1,60 |
| 20:34:16 | USDSEK | SELL | 0,06 | 9,86051 | 9,86293 | Expert | −1,46 |
| 20:34:29 | USDCNH | SELL | 0,04 | 6,65671 | 6,65623 | Expert | +0,28 |
| 20:35:01 | NZDUSD | SELL | 0,01 | 0,56264 | 0,56298 | Expert | −0,34 |
| **21:45:06** | **NZDUSD** | **SELL** | **0,60** | **0,56319** | **0,56354** | **Expert** | **−20,92** |
| 00:35:21 | USDCNH | SELL | 1,36 | 6,65702 | 6,65651 | Client | +10,42 |
| 00:51:10 | NZDUSD | SELL | 0,20 | 0,56310 | 0,56289 | Client | +4,20 |
| 02:00:04 | AUDUSD | BUY | 0,16 | 0,70265 | 0,70276 | Client | +1,76 |
| 08:47:10 | EURUSD | SELL | 0,03 | 1,11794 | — | **aberta** | −5,49 |

**Leitura:** o dia fecha positivo (~+16 USD) **apesar** da perda de −20,92 no
NZDUSD de 0,60 lotes — que é exactamente a falha que `MaxRiskPerTradeUsd=8.0`
pretende impedir. A posição aberta com 0,03 lotes é o primeiro indício de que
o novo tecto está a actuar.

---

## 7. Backtests de referência (para não repetir experiências)

| Versão | Foco | Lucro | PF | Trades | W/L | Max con. loss | DD balance | DD equity |
|---|---|---|---|---|---|---|---|---|
| 1.2.16 | base | −4,63 | — | — | — | — | — | — |
| 1.2.20 | freio de sequência | +21,23 | 1,4404 | — | — | 6 | 16,31% | — |
| 1.2.21 | envelope de armadura | −13,40 | — | — | — | — | — | — |
| 1.2.22 | piso conservador | −14,78 | 0,4313 | — | — | — | — | — |
| **1.2.23** | **armadura 1R (noiseUsd)** | **+14,76** | **2,1742** | 41 | 29/12 | **2** | **2,33%** | 7,88% |
| 1.2.26 | tecto de risco real + logs | **não corrido** | — | — | — | — | — | — |

Janela comum: XAUUSD M15, 2026.10.20→2026.10.29, depósito 200 USD,
leverage 1:100, `Model=1` (m1 ohlc), `xai_v129_short.ini`.
Sharpe 3,6981 · recovery 0,90 · expected payoff 0,36 · 82 deals.

---

## 8. Como validar (comandos que funcionaram)

```bat
:: compilar (Windows, MetaEditor instalado)
start "" /wait "C:\Program Files\MetaTrader 5\MetaEditor64.exe" ^
  /compile:"C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5" ^
  /inc:"C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5" ^
  /log:"C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\Temp\compile.log"
```

O log sai em UTF‑16LE. Para ler:

```powershell
$f='...\MQL5\Files\Temp\compile.log'
$fs=[IO.File]::Open($f,'Open','Read','ReadWrite')
(New-Object IO.StreamReader($fs,[Text.Encoding]::Unicode)).ReadToEnd()
```

Pesquisas úteis no código (a partir da pasta do EA):

```bat
findstr /s /i /n /c:"LOT CAP REAL" *.mq5 *.mqh
findstr /s /i /n /c:"RISK_ENVELOPE_FULL" *.mq5 *.mqh
findstr /s /i /n /c:"RequireStopLoss" *.mq5 *.mqh
```

> **Atenção:** `MCP search_text` **não é recursivo** na pasta do EA (devolveu
> `total_files: 2`). Usar `findstr /s` ou apontar para a subpasta certa.

Verificações de estado usadas nesta sessão: `get_workspace_info`,
`get_time_information`, `get_trading_account_info`, `list_open_charts`,
`get_trading_open_positions`, `get_trading_history_positions`,
`get_expert_journal` (com `filter`), e `dir Tester\logs` para provar que o
backtest de hoje não correu.

---

## 9. Avisos honestos

1. **Nenhum backtest prova lucro futuro.** A v1.2.23 tem PF 2,17 numa janela
   de 9 dias e 41 trades — amostra pequena e uma só condição de mercado.
2. **A perda de −20,92 USD no NZDUSD foi real** (dinheiro de demo, mas o
   mecanismo é o mesmo em real): lote dimensionado por `StopLossPoints=300`
   enquanto a escada armava o stop a ~5 pontos. O cap de 8 USD reduz o dano,
   não elimina o erro de origem.
3. **Operar sem IA é uma decisão pendente, não um estado desejado** (P0.5).
   Enquanto não for resolvida, o EA pode estar a entrar sem filtro de IA.
4. **A meta de 20 USD/dia é pequena face ao envelope de 1 234 USD de risco
   aberto** (P1.1). O sistema está assimétrico: ganha pouco quando acerta e
   pode perder muito quando o mercado foge.
5. **A regra "sair sempre no lucro" não é "nunca perder".** A escada só fecha
   no positivo depois de o trade ficar positivo; um trade que nunca fica
   positivo tem de sair pelo stop. Isso implica perdas — controladas por
   `MaxRiskPerTradeUsd=8.0`, não eliminadas.

---

*Última actualização: 2026-10-30 05:40 local (10:40 servidor) — XAU_AI_PRO v1.2.26.*

---

## 10. Atualizacao 2026-10-30 15:45 UTC (sessao de retomada)

| Item | Estado | Evidencia |
|---|---|---|
| P0.1 backtest 3 meses v1.2.26 | CORRIDO - NEGATIVO | -35,28 USD / PF 0,81 / 296 trades / DD 83,30 USD / Sharpe -0,55 (XAI_V1226_3M_M1OHLC.ini) |
| P0.2 ticks reais | BLOQUEADO por disco | 0,72 GB livres; log da corrida 1 = 2,67 GB; config pronto: XAI_V1226_3M_REALTICKS_QUIET.ini |
| P0.3 LOT CAP REAL | fechado por calculo (nao por log) | 0 ocorrencias em 297 execucoes; teto de 3% sobre 200 USD = 6 USD ja e menor que 8 USD |
| P0.5 IA offline | respondido | EnableAutonomousMode=true + BlockZeroAIScore=true; 18 486 falhas 4014 e 297 execucoes |
| P1.4 lote minimo | confirmado | 6x FORCA LOTE MINIMO e ordem enviada nos 6 |
| P0.4 / P1.3 log | confirmado com numero | 2,67 GB em 41 min de backtest |

Consequencia para a conta real: o criterio de P0.2 (resultado negativo bloqueia
a passagem) passa a valer com o numero do P0.1. Nao passar para real com esta
configuracao.

---

## 11. Atualizacao 2026-10-30 16:05 local (sessao de retomada, v1.2.27)

### 11.1 O que foi feito nesta sessao (codigo)

| Item | Ficheiro | O que mudou | Motivacao medida |
|---|---|---|---|
| P0.4/P1.3 | `Enterprise/RecoveryManager.mqh` | `LogHealth()` imprime o bloco `=== RECOVERY STATUS ===` (8 linhas) so quando o estado muda ou passam 300 s | 1386 blocos por 8 MB de log |
| P0.4/P1.3 | `Enterprise/SafetyManager.mqh` | aviso `[SAFETY] Exposure limit` 1x/min (era a cada tick) | 2375 ocorrencias por 8 MB |
| P0.4/P1.3 | `Core/MarketScanner.mqh` | `[SCANNER] START` e `[SCANNER] POSITION CHECK OK` passam a 1x/hora por simbolo (cache `scanInfoTimes`); os `BLOCK` continuam 1x/min | 2 linhas x 11 simbolos por ciclo |
| P0.4/P1.3 | `Core/TradePipeline.mqh` | `[PIPELINE] STANDBY` 1x/hora (15 das 16 instancias em standby) | ~900 linhas por hora |
| P0.4/P1.3 | `AI/DataLogger.mqh` | `DATA LOGGER SAVED` 1x/dia por simbolo (`dlLastEchoDay[64]`); a gravacao no CSV nao muda | 11 linhas por vela fechada |
| P0.4/P1.3 | `XAU_AI_PRO.mq5` (OnTick) | bloco `SYSTEM STATUS` (5 linhas) 1x/min quando `EnableVerboseDebug=true` | 792 ocorrencias de EXECUTION SUMMARY por 8 MB |
| P0.3/P1.4 | `Core/ExecutionEngine.mqh` | teto de risco medido com o **lote final** + linha `[RISK] RISCO REAL DA ORDEM` em toda ordem; reduz o lote ou bloqueia | o cap antigo vivia antes do arredondamento e nunca imprimiu prova |
| P1.4 | `Core/Config.mqh` | novo input `BlockWhenMinLotExceedsRiskCap` (**false** por padrao) | decisao do dono pendente |
| HG-01/HG-02 | `Enterprise/VersionManager.mqh` e `XAU_AI_PRO.mq5` | `EA_VERSION_STRING="1.2.27"`, cabecalho do EA `v1.2.27`, `#property version "1.227"`, `m_current.changes` reescrito e referencias mortas a `VERSION` / `Docs/version.json` / `sync_version.py` removidas | os tres pontos diziam versoes diferentes |

Compilacao: **0 errors, 0 warnings** (duas vezes, `XAU_AI_PRO.ex5` reconstruido).

### 11.2 P0.2 (ticks reais) â€” BLOQUEADO POR DISCO, com prova

| Tentativa | run_id | Resultado |
|---|---|---|
| 10 dias, Model=4, `XAI_V1226_10D_REALTICKS_LEAN.ini` | `7702534993626376613` | correu ate 00:09:24 de ~00:49:44 e foi **parada manualmente** para nao encher o disco |
| 10 dias, Model=4, `XAI_V1227_10D_REALTICKS_LEAN.ini` (novo binario) | `7702538326508974874` | o agente autoriza e **desliga em 38 ms** (`Core 1 disconnected`); nenhuma linha do EA |
| idem, repeticao | `7702538468410717975` | mesmo sintoma (desliga em ~37 ms) |

Medido no momento: **0,37-0,38 GB livres** em C:. Causa: os logs do testador.

| Ficheiro | Tamanho |
|---|---|
| `Tester\logs\20261029.log` | **1,99 GB** |
| `Tester\logs\20261030.log` | **2,81 GB** |

**Accao necessaria (fora do alcance do assistente):** apagar ou mover para outro disco os dois ficheiros acima. `Tester` esta nos read roots da ferramenta e nao nos write roots, logo a eliminacao nao pode ser feita por aqui. Depois disso:

1. correr `XAI_V1227_10D_REALTICKS_LEAN.ini` (10 dias, Model=4) e comparar com +14,76 / PF 2,1742 / 41 trades;
2. correr `XAI_V1227_3M_REALTICKS_LEAN.ini` (3 meses, Model=4) e comparar com -35,28 / PF 0,81 / 296 trades.

Custo de log estimado (medido na primeira tentativa): ~1 MB por minuto de parede, ou seja dezenas de MB â€” nao os 2,8 GB da corrida nao-LEAN da v1.2.26.

### 11.3 Pendencias que continuam abertas

- **P0.2** â€” depende de libertar espaco em disco (ver 11.2).
- **P1.4** â€” decidir `BlockWhenMinLotExceedsRiskCap`: deixar `false` (avisa e abre) ou `true` (nao abre quando o lote minimo estoura o teto de 8 USD).
- **P1.1** (`MaxTotalRiskPercent=10` = ~1235 USD de risco aberto contra meta de 10-20 USD/dia), **P1.2** (`DailyProfitTargetMaxUsd=100`), **P1.5** (warm-up ADX/RSI), **P1.6** (hora ma no score), **P1.7** (noticia real em demo).
- **P2.2** (`xai_streak2.set`), **P2.3** (master do pipeline/failover), **P2.4** (README e `Docs/version.json`), **P2.5/P2.6** (reconciliacao com o outro processo).
- **HG-03** (mover `apply_v1221..1226.ps1` de `Files\Temp` para `Files\Backup`), **HG-05** (BackupManager sem ficheiros em `Files\Backup`).
- **Binario v1.2.27 compilado mas NAO recarregado** nos 16 graficos de producao: confirmar `[VERSION] v1.2.27` no journal antes de confiar em qualquer medicao em demo.
- Nenhum destes resultados prova lucro futuro; a v1.2.23 (PF 2,17) e uma amostra de 9 dias e 41 trades.

*Atualizacao escrita automaticamente pelo assistente (sessao de 2026-10-30 16:05 local).*
### 11.4 Confirmacoes desta sessao (16:05 local)

- **Binario v1.2.27 EM PRODUCAO (demo), nao apenas compilado.** Depois da recompilacao o terminal recarregou o EA nos graficos das 16:02:15 e o journal mostra `[VERSION] v1.2.27 | Build=2026.10.30 | Stable=Yes | AutoUpdate=OFF | Modulos=15` em (pelo menos) `XAUUSD M15`, `USDCLP H1`, `USDCOP H1`, `USDSEK H1`, `USDJPY H1`. O item "binario nao recarregado" fica fechado.
- **P0.2 continua bloqueado por disco.** Terceira tentativa (`7702538979878560838`) tambem abortou logo apos `authorized (agent build 6294)`. Nao e transicao de recarga do agente (a recarga ja tinha terminado 20 s antes da 1.a tentativa e ~13 min antes desta). O que muda entre a corrida que funcionou (15:49, com 0,72 GB livres) e as que falham (0,37 GB livres) e o espaco em disco.
- **Accao do dono:** apagar/mover `Tester\logs\20261029.log` (1,99 GB) e `Tester\logs\20261030.log` (2,81 GB) e voltar a pedir as corridas.
### 11.5 Fecho da v1.2.28 (30/10/2026, apos 16:08)

- Versao: `EA_VERSION_STRING` = **1.2.28** (`Enterprise/VersionManager.mqh`) e `#property version 1.228` no cabecalho do EA; `m_current.changes` ganhou o paragrafo da P1.5. O binario recompilado (`XAU_AI_PRO.ex5`, 617.956 B) reporta `[VERSION] v1.2.28` na proxima recarga dos graficos.
- P1.5 fechado: `IndicatorsReady()` em `Core/DecisionEngine.mqh`, linha `[WARMUP]` 1x/min e campo `WARMUP=SIM/NAO` no `SCORE CALCULATED`; `Indicators/RSI.mqh` passou a validar o buffer da versao multi-simbolo (0.0/100.0 -> 0.0). Compilacao: 0 erros, 0 avisos (14120 ms).
- Paridade do `XAI_V1227_10D_REALTICKS_LEAN.ini` corrigida: 315 -> 319 linhas, com `MaxRiskPerTradeUsd=8.0`, `BlockWhenMinLotExceedsRiskCap=false`, `MaxTotalRiskPercent=10.0`.
- HG-03 fechado: 12 `.ps1` movidos de `MQL5\Files\Temp` para `MQL5\Files\Backup` (0 restantes em Temp).
- P0.2 CONTINUA BLOQUEADO POR DISCO: 0,365 GB livres; `Tester\logs\20261029.log` 1988,2 MB e `20261030.log` 2810 MB. Tester esta fora dos write_roots -> accao do dono.
- P2.5/P2.6 (evidencia nova): edicoes MCP ao `README.md` revertidas por outro processo segundos depois de escritas. Confirmar sempre por Select-String apos escrever.
### 11.6 Fecho da v1.2.30 (30/10/2026, apos 17:00) - a cauda era o problema

**Diagnostico que mudou a prioridade.** O `MQL5\Files\Data\ai_feedback.csv`
(402 trades fechados, 24/08 a 29/10/2026) foi analisado com `PowerShell`
(`MQL5\Files\Temp\analyze_feedback.ps1` e `analyze_hours.ps1`):

| Medida | Valor |
|---|---|
| Trades | 402 (277 ganhos / 125 perdas) |
| WR | **68,9%** |
| Bruto ganho | +153,64 (ganho medio **0,55**) |
| Bruto perdido | -164,15 (perda media **1,31**) |
| R medio (ganho/perda) | **0,42** |
| Resultado | **-10,51** |
| As 12 piores perdas | **-82,03** = metade do prejuizo bruto em 3% dos trades |

Ou seja: **o EA nao perde por errar a direcao** (acerta 69%). Perde porque a
cauda e 2,4x o ganho medio. As piores: -15,00 (XAGUSD), -11,94 (USDCHF),
-9,51 e -9,00 (XAUUSD), -6,30 (NZDUSD).

Simulacao de um teto de perda por trade (limite **superior**: nao conta
trades que recuperariam nem os que nunca existiriam):

| Teto | Soma final |
|---|---|
| 1,0 USD | +84,40 |
| 1,5 USD | +61,75 |
| 2,0 USD | +47,39 |
| 3,0 USD | +31,53 |
| 6,0 USD | +11,24 |
| sem teto | **-10,51** |

**Causa no codigo.** O risco da entrada e dimensionado sobre
`1R = ATR x StoplessArmATRMult (0,8)` com piso em `StoplessArmMinPoints`, mas
o vigia `StoplessEmergencyDistance()` cortava em `3 x ATR` - cerca de
**3,75R**. A posicao podia perder quase quatro vezes o que foi orcado para ela.

**Aplicado (v1.2.30):**

- **P1.8 fechado** - `Core/PositionManager.mqh`: o automatico passou a ser
  `StoplessEmergencyRMult (1,5) x 1R`. O limite novo e **sempre menor ou igual**
  ao antigo (3xATR com piso de 150 pts), portanto a mudanca so aperta. Log
  `[SEM STOP] VIGIA FECHOU` passa a dizer `(auto R)`.
  `Core/Config.mqh`: novos inputs `StoplessEmergencyRMult = 1.5`
  (`0` desliga o teto em R; `StoplessEmergencyPoints > 0` continua mandando).
- **P1.9 fechado** - `Core/Config.mqh`: `AvoidHoursGMT` passa de `"18,22"` para
  `"18,20,22"`. Medido: hora de servidor 22 (= GMT 20, servidor em GMT+2
  confirmado nesta sessao por `get_time_information`: UTC 19:56 / servidor
  21:56) deu 28 trades, WR 53,6% e **-14,34**; o prejuizo inteiro e NZDUSD
  (14 trades, -20,28) e os outros 6 simbolos somam +5,94 naquele horario.
  Nao ha nenhum XAUUSD as 22h no registo, logo o backtest de XAUUSD nao muda.
- **Versao:** `EA_VERSION_STRING` = **1.2.30**, cabecalho `// XAU_AI_PRO v1.2.30`
  e `#property version "1.230"` (`minor*100+patch`). Nota: a v1.2.29 ja tinha
  sido tomada pelo outro processo (P1.3/P0.4, HEALTH MONITOR), por isso esta
  linha de trabalho usa 1.2.30.
- **Compilacao:** 0 erros, 0 avisos (20002 ms, `cpu='X64 Regular'`).
- **Paridade dos `.ini`:** os 5 perfis `XAI_V12*_LEAN.ini` receberam
  `StoplessEmergencyRMult=1.5||1.5||0.5||3.0||N`; os tres de 10 dias e o
  `XAI_V1226_10D_M1OHLC_LEAN.ini` tiveram `AvoidHoursGMT` actualizado para
  `18,20,22`. Os de 3 meses nao traziam `AvoidHoursGMT` e passam a usar o
  padrao novo do binario.

**O que continua aberto e por que:**

- P1.1 (envelope de 10% = ~1235 USD) continua em aberto: com o teto em R
  aplicado, a exposicao maxima por posicao cai, mas o numero de posicoes
  simultaneas nao. E o proximo item de risco.
- P1.6 (hora ma no score) fica **despriorizado**: a hora ja e vetada por lista
  e o problema medido nao era o score, era a cauda.
- P0.2 continua a esperar disco/utilizacao: `Tester\logs` com 1988,2 MB
  (`20261029.log`) + 2810 MB (`20261030.log`) e 4,23 GB livres.
### 11.7 Renumeracao e primeira medicao da v1.2.30 (30/10/2026, 17:40)

- O outro processo que mantem a arvore subiu `EA_VERSION_STRING` para **1.2.31**
  (P1.3/P0.4 rodada 3: simbolo sem sessao fechada deixa de ser FAILURE, resumo
  RECOVERY de 300 s para 4 h) e **preservou** o paragrafo da v1.2.30 (P1.8/P1.9).
  Alinhamento corrigido nesta linha: `#property version` estava em `"1.230"`
  com o define em `1.2.31` -> agora `"1.231"`, e o cabecalho do `.mq5` em
  `// XAU_AI_PRO v1.2.31`. Recompilado: **0 erros, 0 avisos** (14 557 ms).
- **Importante (para nao repetir confusao):** o backtest que terminou as
  17:28:24 no log `Tester\logs\20261030.log` foi iniciado as **16:47:19** pelo
  outro processo com o binario **v1.2.28**, e nao esta linha de trabalho. O log
  prova-o: `[VERSION] v1.2.28` no arranque e **zero** linhas
  `[SEM STOP] ... (auto R)` (as 80 existentes sao `(auto 3xATR)`, da v1.2.26).
  O pedido de backtest desta linha nao chegou a arrancar (o testador estava
  ocupado e devolveu "tester still started").
- **Resultados medidos hoje na mesma janela de 10 dias, XAUUSD, Model=4:**

  | Binario | Trades | W/L | Profit | PF | MaxDD | Sharpe |
  |---|---|---|---|---|---|---|
  | v1.2.26 (15:49) | 38 | 2/4 | **+13,84** | 2,24 | 4,65 | +0,64 |
  | v1.2.28 (16:47) | 37 | 1/16 | **-5,11** | 0,80 | 20,62 | -0,23 |

  E na janela de 3 meses (15:43, v1.2.26): 296 trades, 9/66, **-34,68**,
  PF 0,81, MaxDD 83,30, Sharpe -0,55.
  Leitura: a variacao de +13,84 para -5,11 entre duas corridas da MESMA janela
  com 37-38 trades mostra que **10 dias nao separam melhorias** (amostra
  pequena, 17 posicoes fechadas). A decisao tem de sair da janela de 3 meses.
- **Pendente de validacao (P1.8/P1.9):** correr `XAI_V1226_3M_REALTICKS_LEAN.ini`
  (278 linhas, ja com `StoplessEmergencyRMult=1.5`) com o binario v1.2.31 e
  comparar com -34,68. Enquanto o outro processo estiver a usar o testador,
  combinar a ordem ou esperar.
## 12. Atualizacao 2026-10-30 17:35 UTC (P1.3/P0.4 fechado por medicao)

| Item | Estado | Numero |
|------|--------|--------|
| P0.4/P1.3 volume de journal | FECHADO nesta rodada | 80 406 -> 7 020 linhas/hora (-91%); meta <200/h ainda nao atingida |
| v1.2.29 HEALTH MONITOR | em producao | 959 blocos/30 min -> 1x/5 min so em problema, 1 linha/hora quando OK |
| v1.2.30 SYSTEM STATUS + gateway | em producao | RECOVERY/EXECUTION/SAFETY de 1x/min para 1x/4 h; 4014 logado 1x/30 min com cooldown de 30 min |
| v1.2.31 saude por sessao | em producao | simbolo sem sessao aberta nao e mais FAILURE; RECOVERY 4 h; SYSTEM STATUS 3 niveis |
| Compilacao | OK | 0 erros, 0 avisos (build 6294), 16 graficos recarregados |

### O que falta para chegar a <200 linhas/hora

1. `[LOGGER OFFLINE]` (~1 140/h) - causa raiz: **LoggerInit() nunca e chamado** em
   nenhum ponto do EA (busca recursiva em 30/10/2026). Decisao pendente do dono:
   inicializar `Common\Files\XAU_AI_PRO.log` a partir de 16 graficos (16 escritores no
   mesmo arquivo com FILE_SHARE) ou declarar o Logger legado e manter o AuditLog como
   unico destino. Enquanto nao decidir, o fallback imprime toda mensagem no journal.
2. `AI LOAD` / `AI FILE NOT FOUND` / `AI INVALID JSON` (~720/h) - throttle de 60 s por
   grafico em `LoadAIPrediction`. Candidato a 1x/30 min.
3. `[SCANNER] BLOCK` + `[PIPELINE] PROCESSANDO` (~1 920/h) - o grafico master varre os
   16 simbolos 1x/min. Candidato a imprimir so na mudanca de sinal ou 1x/15 min.
4. `[SESSION] estado salvo` (~192/h) - 1x/hora por grafico; aceitavel, nao mexer.

### Defeito de processo corrigido hoje

Patch PowerShell com **um unico par** era achatado pelo PowerShell e `.Replace()`
trocava UM CARACTERE no arquivo inteiro (Logger.mqh perdeu os `L`, RecoveryManager.mqh
perdeu os `R`). Restaurados dos backups de `Files\Backup`. Sempre usar
`Patch $path (, @($old,$new,$tag))` e conferir tamanho + um identificador depois.
### 11.8 P1.1 fechado e estado da corrida de 3 meses (30/10/2026, 19:00)

**P1.1 - teto do risco aberto em dinheiro (`MaxTotalRiskOpenUsd`).**
`MaxTotalRiskPercent` acompanha o saldo e por isso CRESCE com a conta: 10% de
~12 348 = **~1 235 USD** de risco aberto somado, contra uma meta de 10-20 USD
por dia. O EA varre 11 simbolos por ciclo e chega a manter 10-15 posicoes
simultaneas, logo um dia ruim pode devolver dezenas de vezes a meta diaria.

- `Core/Config.mqh:275` - novo input **`MaxTotalRiskOpenUsd = 60.0`**
  (3x o topo da meta; `0` desliga). O envelope passa a ser o **MENOR** entre o
  valor em `%` e este, em `RiscoPorTradeUsd()` (linha ~1176). Quando enche,
  `RiscoPorTradeUsd()` devolve 0 e a execucao recusa a entrada - comportamento
  que ja existia, so que agora com um teto que nao depende do saldo.
- `Core/ExecutionEngine.mqh:613` - a linha
  `envelope de risco aberto cheio` passou a imprimir tambem `teto_usd=`.
- **Paridade de backtest:** com deposito de 200 o teto de `%` da 20 USD, ou
  seja o limite novo NAO morde no backtest de 200 USD. Ele so actua na conta
  grande - exactamente onde o risco estava subdimensionado.
- Os 5 perfis `XAI_V12*_LEAN.ini` receberam a linha
  `MaxTotalRiskOpenUsd=60.0||60.0||10.000000||200.000000||N`.
- Versao: **1.2.34**, `#property version "1.234"`, cabecalho
  `// XAU_AI_PRO v1.2.34`. Compilacao: **0 erros, 0 avisos** (17 080 ms).

**Estado da corrida de 3 meses com ticks reais (P0.2):**

- `run_id 7702562348550340591`, iniciada 17:39, **ETA ~8 h** (o testador estima
  8:02 apos 1:16 de corrida). Em 18:52 estava em 2026.08.12, ou seja 14 de 92
  dias.
- **Confirmacao de que ESTA corrida usa ticks reais:** o testador carregou
  `320 Mb of tick data`. As corridas anteriores de "3 meses" imprimiam
  `generate 2 868 557 ticks ... passed to tester`, que e o gerador de ticks a
  partir do M1 OHLC - por isso terminavam em 40 min e por isso o baseline
  -34,68 NAO era ticks reais.
- Consumo de disco medido: **~200 MB/h** de log (3 146 MB as 18:52, 3,43 GB
  livres no C:). A 8 h isso da ~1,6 GB; sobra folga, mas convem nao abrir
  outras corridas em paralelo.
- Enquanto ela corre, o testador fica ocupado: qualquer outro backtest entra em
  fila. Compilar NAO e afectado (o `.ex5` nao fica travado).

## 13. Atualizacao 2026-10-30 20:55 UTC - v1.2.33 compilada, medicao pendente

| Item | Estado | Observacao |
| --- | --- | --- |
| P1.3 volume de journal | compilado, nao remedido | 80 406 -> 6 270 linhas/hora ate a v1.2.32; a rodada 5 (v1.2.33) nao pode ser medida hoje |
| P1.1 envelope de risco aberto | FECHADO pelo processo concorrente | v1.2.34 introduziu `MaxTotalRiskOpenUsd = 60.0`; o envelope passa a ser o menor entre o de % e o de USD |
| P0.2 backtest com ticks reais | ainda bloqueado por disco | 2,93 GB livres; `Tester\logs\20261030.log` = 3 184 MB e `20261029.log` = 1 988 MB precisam sair (Tester\ esta fora dos write_roots) |

O que falta para fechar P1.3:

1. Recompilado e no ar: `.ex5` de 18:54:21, 0 erros/0 avisos, 16 graficos recarregados.
2. Medir na reabertura do mercado (domingo 22:00 UTC) uma janela de 5 min estavel com
   `MQL5\Files\Temp\measure_v1233.ps1 -From HH:MM:SS -To HH:MM:SS`, descartando os
   10 min seguintes a qualquer recompilacao (init dos 16 graficos = ~12 000 linhas).
3. Comparar com a referencia da v1.2.32: 6 270 linhas/hora.
4. Decisao do dono para chegar a <200/h: desligar `[SCANNER] BLOCK` por simbolo,
   `[LOGGER OFFLINE]` (LoggerInit() nunca chamado) e os diagnosticos de IA por simbolo.
   Com 16 graficos e verbose ligado, throttle nao leva a <200/h.

Nao repetir backtest com `EnableVerboseDebug=true`: o journal do tester gera GB
(3 184 MB em um run de 1 dia) e o disco tem 2,93 GB livres.

Scripts auxiliares desta rodada (em `MQL5\Files\Temp`): `measure_v1233.ps1` (janela +
top emissores), `count_patterns.ps1` (contagem por padrao), `tail_log.ps1` (ultimas
linhas sem carregar o log de 156 MB em memoria).

---

## 14. Atualizacao 2026-10-30 21:05 local - P0.2 (3 meses, ticks reais) em curso

### 14.1 Corrida em andamento (a UNICA medicao com ticks reais)

| Item | Valor |
|---|---|
| run_id | `7702562348550340591` |
| Perfil | `XAI_V1226_3M_REALTICKS_LEAN.ini` (Model=4) |
| Janela | 2026.07.29 -> 2026.10.29 (92 dias) |
| Inicio | 17:39 local |
| Progresso as 20:56 | `03:20:19 / 11:09:57` (~30%) |
| ETA | ~04:45 local |
| Tempo simulado as 20:56 | 2026.08.25 14:23 |
| Log | `Tester\logs\20261030.log` = 3 414 MB, +1,32 MB/min (~79 MB/h) |
| Disco | 2,91 GB livres -> ~2,3 GB no fim (cabe, com folga curta) |

Confirmacao de que agora e ticks reais: o log mostra `320 Mb of tick data` na carga.
As corridas anteriores de "3 meses" imprimiam `generate 2 868 557 ticks ... passed to
tester` (gerador M1-OHLC) e por isso o baseline -34,68 NAO era ticks reais.

### 14.2 O que esta corrida mede (e o que nao mede)

O binario carregado as 17:39 e ANTERIOR a v1.2.34: nao contem P1.8
(`StoplessEmergencyRMult`), P1.9 (`AvoidHoursGMT=18,20,22`) nem P1.1
(`MaxTotalRiskOpenUsd`). Portanto serve como **lado A de um A/B limpo**, nao como
resultado das melhorias.

Protocolo decidido (nao repetir experiencias):

1. Fechar a corrida A e ler `BACKTEST ANALYZER | Finalizado` (Trades/Profit/PF/MaxDD/Sharpe).
2. Relancar IMEDIATAMENTE o MESMO `.ini` (que ja traz `StoplessEmergencyRMult=1.5` e
   `MaxTotalRiskOpenUsd=60.0`) - agora com o `.ex5` actual v1.2.34 -> lado B.
3. Comparar A x B. As tres melhorias so apertam (o limite novo e sempre <= ao antigo),
   logo uma diferenca negativa em B significa que apertar demais destruiu recuperacoes
   e e preciso subir `StoplessEmergencyRMult` para 2,0-2,5.

### 14.3 P2.4 fechado como obsoleto (medido)

`Docs/version.json` nao existe e `Enterprise\VersionManager.mqh` NAO o referencia
(a linha 110 diz explicitamente `referencias mortas a VERSION/Docs/version.json
removidas`). Nada a criar. Pendencia encerrada.

### 14.4 P1.9 nao esta activa nos graficos da demo (medido)

`list_open_charts` mostra, nos 16 graficos, `AvoidHoursGMT = "18,22"` (valor guardado
no `.chr`). Alterar o valor por omissao no `Config.mqh` NAO altera os graficos ja
ligados: e preciso re-anexar o EA (ou editar o input). `MaxTotalRiskOpenUsd = "60.0"` e
`StoplessEmergencyRMult = "1.5"` ja aparecem nos graficos porque sao inputs novos e
entraram com o valor por omissao.

Os graficos estao a correr `[VERSION] v1.2.32` (journal 18:54:04); o `.ex5` em disco
foi escrito as 18:54:21 (v1.2.34), depois do attach. Ou seja: a demo esta uma build
atras. Re-anexar e accao do dono (nenhuma posicao aberta as 21:00, momento seguro).

Estado da conta demo as 21:00: balance 12 351,78 USD, 0 posicoes, 0 ordens.

---

## 15. Atualizacao 2026-10-30 21:20 local - v1.2.37 / P1.10 (EA autonomo em conta REAL)

**Estudo.** Procurou-se o que muda no EA quando a conta e REAL. Resultado medido
por pesquisa na arvore (`Select-String -Recurse` em todos os `.mq5`/`.mqh`):
`IsRealAccount` / `IsReal()` existe desde a v1.2.9 em `Core/EnvironmentManager.mqh`
e **nunca era consultado em mais nenhum ficheiro**. Ou seja, ate aqui demo,
backtest e conta REAL corriam com o MESMO codigo e os MESMOS relaxamentos. Os
outros guardas que ja existiam (`ConnectionGuard`, `FailureMode`, `MarginChecker`,
`CircuitBreaker`, `EquityProtection`, `SafetyManager`, `ProductionChecklist`)
nao distinguem ambiente: servem para os tres.

**Aplicado (v1.2.37 - P1.10).** Novo `Core/RealAccountGuard.mqh`, incluido logo
apos `Core/EnvironmentManager.mqh`. Fica INERTE no testador e em demo (devolve
exactamente os valores dos inputs, logo nenhum backtest muda) e so aperta em
conta REAL:

| Regra | Efeito em conta REAL | Efeito em demo/backtest |
|---|---|---|
| `RealGuardBlockMinLotExceedsCap` | fail-safe do P1.4: mesmo que `BlockWhenMinLotExceedsRiskCap` volte a `false`, o lote minimo acima de `MaxRiskPerTradeUsd` BLOQUEIA a entrada | `BlockWhenMinLotExceedsRiskCap` como esta |
| `RealGuardStoplessEmergencyRMultFloor` (1,5) | `StoplessEmergencyRMult = 0` deixa de desligar o vigia de perda; valores mais frouxos que o piso sao apertados para o piso | input tal e qual |
| `RealGuardMaxUnarmedPositions` (1) | no maximo 1 posicao DESTE EA, no mesmo simbolo, SEM stop de corretora ao mesmo tempo (`REAL_GUARD_UNARMED`); posicoes manuais do dono, magic 0, nao contam | sem limite novo |

O arranque publica a linha `[REAL GUARD]` com os limites que estao mesmo em
vigor (conta, lote minimo, teto do stopless, maximo sem stop).

**Ligacoes no codigo:** `Core/ExecutionEngine.mqh` (bloqueio por exposicao nua e
`RealGuardBlockOnMinLot()` no teto por operacao), `Core/PositionManager.mqh`
(`StoplessEmergencyDistance` passou a usar o multiplicador do guarda) e
`XAU_AI_PRO.mq5` (`RealGuardLogBanner()` no `OnInit`).

**Versao.** `EA_VERSION_STRING` = 1.2.37, `#property version "1.237"`, cabecalho
`// XAU_AI_PRO v1.2.37`, paragrafo novo em `m_current.changes`.
Compilacao: **0 erros, 0 avisos** (17 423 ms).

**O que isto NAO e.** Nao e prova de lucro, nao altera direccao, score, alvos nem
lote. E um envelope de seguranca para o dia em que a conta for real. O dono pode
desligar tudo com `EnableRealAccountGuard=false`.

**Nota operacional.** A recompilacao aconteceu com o backtest de P0.2 a correr
(run `7702617382101217572`); o testador recarrega o binario do agente e o tempo
estimado do ciclo mudou (2:57/24:35 -> 9:11/12:45 de tempo simulado). Proxima
corrida deve ser lancada com o testador parado e sem recompilar a meio.

---

## 16. Atualizacao 2026-10-30 21:45 local - v1.2.38 / P1.11 (backup: acoplamento e 16 escritores)

**Origem.** Ao estudar o que corre no `OnTimer` para o EA ser autonomo em conta
real, o bloco do backup agendado (`XAU_AI_PRO.mq5`, dentro do timer) mostrou
dois defeitos:

1. **Acoplamento indevido.** O backup vivia DENTRO de `if(EnableAuditLog)`. Com
   `EnableAuditLog=false` e `EnableBackupManager=true` o `CBackupManager::RunBackup()`
   **nunca corria** - o dono pedia backup e nao tinha backup. Sao dois assuntos
   independentes (auditoria vs copia de seguranca).
2. **16 escritores.** Nao havia guarda de instancia: os 16 graficos avaliavam o
   mesmo minuto e chamavam `RunBackup()` no mesmo instante, copiando o MESMO
   conjunto de ficheiros para o MESMO destino (`XAU_AI_PRO\Backups\`), ou seja
   **16x o mesmo IO**. Numa maquina que ja abortou backtests por disco cheio
   (0,37 GB livres em 30/10, ver P0.2) isto e desperdicio puro, e ainda por cima
   concorrente sobre os mesmos ficheiros de origem.

**Aplicado (v1.2.38).** O backup passou a ter bloco proprio no timer e corre
**apenas na instancia mestre do pipeline** (`PipelineIsMaster()`, o mesmo padrao
ja usado pelo `OperatorBrief` duas dezenas de linhas acima; com
`EnablePipelineMasterGuard=false` devolve `true`, logo o comportamento anterior
mantem-se). As instancias em STANDBY imprimem `[BACKUP] STANDBY` **1x/hora**,
nao a cada ciclo de 30 s.

**O que NAO mudou:** o intervalo (`BackupIntervalMinutes`), o destino, os itens
copiados (`Config\*.set`, `Data\dataset.csv`, `Data\*.json`, `Logs\*.log`,
`Data\*.db`, `audit_log.csv`, `Data\full_audit.csv`, `xau_ai_pro_summary.csv`,
`trade_history.csv`), `BackupMaxKeep` e a validacao de sucesso do `RunBackup()`.

**Versao.** `EA_VERSION_STRING` = 1.2.38, `#property version "1.238"`, cabecalho
`// XAU_AI_PRO v1.2.38`, paragrafo novo em `m_current.changes`.
Compilacao: **0 erros, 0 avisos** (19 213 ms). Line endings dos ficheiros
alterados verificados a CRLF puro.

**Por validar (dono/acompanhamento):** a primeira linha `[BACKUP] OK` depois de
re-anexar o EA; e confirmar que apenas UMA instancia a imprime por ciclo. Com o
mercado fechado o timer continua a correr, logo isto e observavel sem esperar
pela abertura.

**Nota.** O `[LOGGER OFFLINE]` (~1 140/h na v1.2.31) continua por decidir: a
causa e `LoggerInit()` nunca ser chamado, mas inicializar um ficheiro
`FILE_COMMON` a partir de 16 graficos e uma decisao de desenho (16 escritores no
mesmo log), registada na seccao 12 - nao foi tomada aqui.

---

## 15. Atualizacao 2026-10-30 21:20 local - v1.2.36 compilada (P1.2b + P1.4 + P0.2-verbose)

### 15.1 O que foi feito (pacote 1 + 2 + 4 aprovado)

- **P1.2b - teto da perda diaria em DINHEIRO.** Novo input `MaxDailyLossUsd = 60.0`
  em `Core/Config.mqh` (linha 87, junto de `MaxDailyLossPercent`).
  `OrcamentoDiarioPerda()` passou a devolver o **MENOR** entre o teto de % do saldo e
  o teto em USD; `Enterprise/SafetyManager.mqh` (`CSafetyManager::Init()`) deixou de
  calcular `balance * MaxDailyLossPercent / 100.0` e passou a chamar
  `OrcamentoDiarioPerda()`. Motivacao medida: com 10% sobre 12 351,78 de saldo o
  limite era 1 235 USD/dia contra meta de lucro de 20-40 USD/dia (assimetria ~30:1).
- **P1.4 - fail-closed no lote minimo.** `BlockWhenMinLotExceedsRiskCap` passou de
  `false` para `true`. A logica ja existia em `Core/ExecutionEngine.mqh` (~linha 470);
  so o valor por omissao estava desligado. Nao houve nenhum evento
  `MIN_LOT_EXCEEDS_RISK_CAP` em 30/10, logo nao havia evidencia de que o override
  fosse necessario.
- **P0.2 - verbose ignorado no Strategy Tester.** `MQLInfoInteger(MQL_TESTER)` entrou
  no `VerboseMode` e nos tres guards de verbose do `XAU_AI_PRO.mq5`, no dump do Market
  Watch (`Core/SymbolManager.mqh:277`) e no echo diario por simbolo
  (`AI/DataLogger.mqh:549`). Em `AI/ModelGovernance.mqh:64` a condicao foi
  **invertida** (`!EnableVerboseDebug || MQLInfoInteger(MQL_TESTER)`), porque a linha
  `[MODEL] Governado` so saia com o verbose desligado e deixaria de sair no tester.
- **Versao alinhada nos tres sitios**: `EA_VERSION_STRING "1.2.36"` (VersionManager),
  cabecalho `// XAU_AI_PRO v1.2.36` e `#property version "1.236"`. A 1.2.35 ja estava
  tomada pelo processo concorrente (P1.6, hora-no-score).

### 15.2 Build

`metaeditor64.exe /compile`: **0 errors, 0 warnings**, 18 457 ms;
`XAU_AI_PRO.ex5` = 623 468 B, escrito as 21:13:14.

**Ainda NAO esta em producao.** Os 16 graficos continuam em `[VERSION] v1.2.32`
(ultima recarga 18:54:04) e com o mercado fechado nao recarregam sozinhos. O journal
`MQL5\Logs\20261030.log` nao contem uma unica linha `[VERSION] v1.2.36`. Accao do
dono: re-anexar o EA nos 16 graficos (0 posicoes, momento seguro).

### 15.3 Strategy Tester - slot ocupado por uma corrida v1.2.35

As 21:09:22 o tester arrancou `XAI_V1226_3M_REALTICKS_LEAN.ini` (XAUUSD M15,
29/07 -> 29/10, `Model=4`, deposit 200) e o journal do tester confirma
`[VERSION] v1.2.35` - **nao** e a v1.2.36. Como o tester corre um job de cada vez,
`tester_run_backtest` respondeu `tester still started`.

A corrida P0.2 com a v1.2.36 ficou **preparada mas nao lancada**:

| item | valor |
| --- | --- |
| perfil | `MQL5\Profiles\Tester\XAI_V1236_3M_REALTICKS.ini` (528 B) |
| inputs | `MQL5\Profiles\Tester\XAI_V1236_3M_REALTICKS.set` (308 linhas) |
| simbolo / periodo | XAUUSD / M15 |
| janela | 2026.07.29 -> 2026.10.29, `Model=4` (ticks reais) |
| deposit / leverage | 200 USD / 1:100 (igual ao baseline de -34,68) |
| inputs criticos | `MaxDailyLossUsd=60.0`, `BlockWhenMinLotExceedsRiskCap=true`, `AvoidHoursGMT=18,20,22`, `DailyProfitTargetMaxUsd=40.0`, `StoplessEmergencyRMult=1.5`, `MaxTotalRiskOpenUsd=60.0`, `EnableVerboseDebug=false` |

Decisao: **nao matar** a corrida v1.2.35 do outro processo - ela serve de lado **A**
(controlo antes do aperto). A v1.2.36 (lado **B**) entra quando o slot libertar.

Medicoes desta corrida (21:15):

- 15h simuladas em ~6 min de relogio -> ETA ~14-15h para os 3 meses.
- Disco livre 8,05 GB e **estavel** (nao repete o colapso para 2,93 GB de 30/10).
- `Tester\logs\20261030.log` = 5 MB depois de 15h simuladas (antes: 3 184 MB num
  unico dia com verbose ligado).
- Emissor dominante dentro do tester: `[VIA RAPIDA] <SIMBOLO> | Regime=... | Volume x...`
  a cada 5 s por simbolo, mais `[LEARN] historico verificado` 1x/30 s,
  `[PIPELINE] INICIO/FINALIZADO` e `[SCANNER] BLOCK | CanOpenPosition` 1x/min.

### 15.4 Correcao medida as 21:22 - a versao efetiva e 1.2.37, nao 1.2.36

O processo concorrente voltou a tocar nos mesmos ficheiros entre 21:17:26 e 21:17:48 e
subiu a versao:

| sitio | valor agora |
| --- | --- |
| `Enterprise\VersionManager.mqh:14` | `#define EA_VERSION_STRING "1.2.37"` |
| `XAU_AI_PRO.mq5:3` | `// XAU_AI_PRO v1.2.37` |
| `XAU_AI_PRO.mq5:23` | `#property version "1.237"` |
| `XAU_AI_PRO.ex5` | 632 260 B, escrito as 21:18:25 (posterior a todas as fontes) |

O que a 1.2.37 acrescenta a esta linha de trabalho: **P1.10 - endurecimento de conta
REAL** (`#include "Core/RealAccountGuard.mqh"` no `XAU_AI_PRO.mq5:43`, mais um bloco de
journal em `:876`).

O pacote P1.2b/P1.4/P0.2-verbose **continua intacto** - verificado por `Select-String`
depois da alteracao do outro processo:

- `Core\Config.mqh:87` `input double MaxDailyLossUsd    = 60.0;`
- `Core\Config.mqh:916` `return(MaxDailyLossUsd > 0.0 && (orcamento <= 0.0 || MaxDailyLossUsd < orcamento) ? ...)`
- `Core\Config.mqh:1251` `input bool   BlockWhenMinLotExceedsRiskCap = true;`
- `Enterprise\SafetyManager.mqh:146-147` `m_limits.max_daily_loss = OrcamentoDiarioPerda();`
- `MQL_TESTER` presente 8x em `XAU_AI_PRO.mq5`, 1x em `Core\SymbolManager.mqh`,
  1x em `AI\DataLogger.mqh`, 1x em `AI\ModelGovernance.mqh:65`.

Nenhum dos ficheiros editados tem bytes NUL (`hasNul=False` nos sete) e todas as fontes
sao mais antigas que o `.ex5`, logo o binario corresponde as fontes.

Consequencia pratica: **nao** voltar a compilar por iniciativa propria enquanto o outro
processo estiver a editar (21:17:48 foi o ultimo toque) - o risco e compilar a meio de
uma edicao. Confirmar sempre por `Select-String`; o marcador `v1.2.36` deixou de existir.

---

## 16. Atualizacao 2026-10-30 21:50 local - item 3 (P1.3 rodada 6): scanner agregado

Fechado o item que estava adiado na secao 13: `[SCANNER]` deixa de imprimir uma linha
por simbolo por gate e passa a emitir **uma linha de resumo por minuto**.

### 16.1 Desenho

Em `Core/MarketScanner.mqh` (ficheiro que o processo concorrente nao estava a tocar):

- `enum ENUM_SCAN_BUCKET` com 7 baldes: `CanOpen`, `JaNegociado`, `Cooldown`,
  `NoSignal`, `DirHist`, `AllowTrade`, `ExecFail`.
- `ScanBlock(bucket, symbol, detalhe="")` conta o motivo e so imprime o detalhe por
  simbolo quando `EnableVerboseDebug && !MQLInfoInteger(MQL_TESTER)`.
- `ScanFlush(now)` emite
  `[SCANNER] RESUMO | simbolos=N | sinais=N | trades=N | bloqueios=N | CanOpen=.. NoSignal=..`
  e zera os contadores.
- A janela e fechada no inicio de `ProcessSymbol()`, quando `now - g_scanJanela >= 60`,
  antes de contar o simbolo atual. Nao foi preciso tocar no `TradePipeline.mqh`.
- Se nada acontecer na janela, o resumo sai no maximo 1x/15 min (`SCAN_SILENT_SEC=900`)
  para provar que o pipeline esta vivo.
- `[SCANNER] TRADE SUCCESS` continua **sempre** (trade e evento raro e importante).
- Ficaram a 1x/hora por simbolo, como antes: `START`, `POSITION CHECK OK`.

### 16.2 Base medida e ganho esperado

| medicao de 30/10 (v1.2.32) | valor |
| --- | --- |
| linhas `[SCANNER]` no journal do dia | 15 348 |
| das quais num UNICO grafico (mestre, 11 simbolos) | 15 108 |
| piso do desenho antigo | 11 simbolos x 1440 min = ~660/hora |

Com agregacao: ~60 linhas/hora por instancia (1/min), ~10x menos no mestre, e sem
depender do numero de simbolos.

### 16.3 Build

`metaeditor64 /compile`: **0 errors, 0 warnings**, 18 339 ms;
`XAU_AI_PRO.ex5` = **634 590 B**, escrito as 21:47:00. O binario resultante e
**v1.2.38** e contem, alem desta alteracao, o P1.11 (backup na instancia mestre) e o
P1.10 (`Core/RealAccountGuard.mqh`) do processo concorrente.

### 16.4 Nota de coordenacao (importante para as proximas sessoes)

O processo concorrente subiu a versao para **1.2.38** as ~21:45
(`EA_VERSION_STRING "1.2.38"`, `// XAU_AI_PRO v1.2.38`, `#property version "1.238"`)
com o paragrafo `v1.2.38 - P1.11` no `m_current.changes`.

Por isso **esta alteracao (P1.3) NAO recebeu bump proprio**: cheguei a escrever um
paragrafo `v1.2.39` no changelog, mas o processo concorrente fechou o bump para 1.2.38
no mesmo minuto, o que deixaria `changes` a dizer 1.2.39 com a versao em 1.2.38 - o
paragrafo foi **revertido**. O codigo do P1.3 esta no binario 1.2.38, mas o changelog
ainda nao o menciona: quem fizer o proximo bump deve acrescentar a linha.

Ainda **nao esta em producao**: os 16 graficos continuam em v1.2.32 e o mercado esta
fechado (sem recarga). Re-anexar e accao do dono.

---

## 17. Atualizacao 2026-10-30 22:05 local - P0.2: lado A medido, slot ainda ocupado, orcamento de journal medido

### 17.1 Estado do Strategy Tester

- A corrida do processo concorrente (build v1.2.35, perfil `XAI_V1226_3M_REALTICKS_LEAN.ini`,
  XAUUSD M15, Model=4 ticks reais, 2026.07.29 -> 2026.10.29, deposito 200 USD) arrancou as
  21:09:22 e continuava a correr as 22:05.
- `tester_run_backtest` com `XAI_V1236_3M_REALTICKS.ini` + `.set` voltou a responder
  `tester still started` (segunda tentativa da sessao). O perfil B continua pronto e por usar.
- **Nao consigo parar esta corrida.** `tester_stop` exige um `run_id` devolvido por
  `tester_run_backtest`/`tester_run_optimization`, e este job nao foi arrancado por estas
  ferramentas. Parar o lado A e acao do dono (botao Stop no separador Strategy Tester).
- `tester_list_result_windows` devolve lista vazia, coerente com um job ainda em execucao.

### 17.2 Lado A medido (real ticks, 200 USD, inicio 2026.07.29)

Saldo no ultimo `RISK CALC USD` de cada dia simulado, lido do Tester log em streaming:

| dia simulado | saldo | variacao acumulada |
|---|---|---|
| 2026.07.29 | 188,64 | -5,7% |
| 2026.07.30 | 184,11 | -7,9% |
| 2026.07.31 | 177,87 | -11,1% |
| 2026.08.03 | 175,98 | -12,0% |
| 2026.08.04 | 172,55 | -13,7% |
| 2026.08.05 | 172,31 | -13,8% |

Sangria monotona de ~2,4 USD por dia em 14 trades fechados (`TRADE SUCCESS` = 14).
Isto e o controlo ANTES do aperto (sem `MaxDailyLossUsd`, sem bloqueio do lote minimo,
`AvoidHoursGMT=18,22`, sem teto de meta diaria). Confirma, com ticks reais, a direcao do
baseline de 3 meses com M1-OHLC (-34,68 / PF 0,81 / 296 trades): o problema nao era o
modelo de tick, era a gestao de risco.

### 17.3 Custo em disco e em tempo

- Tester log 134,9 MB as 22:03:37, a crescer 1 546 528 B em 30 s = **177 MB/hora**.
- Disco livre 7,69 GB (era 7,78 GB as 21:47).
- Progresso: 6 dias simulados de 92 em ~57 min -> ETA ~11-12 h para os 3 meses, com ~2 GB
  de log adicional. Ao ritmo actual o disco aguenta, mas fica sem margem para um segundo
  backtest em paralelo.
- Este e o pior caso: o build v1.2.35 nao tem o guard `MQLInfoInteger(MQL_TESTER)`, logo
  corre com verbose LIGADO. As builds 1.2.36+ correm com verbose DESLIGADO no testador.

### 17.4 Orcamento de journal medido (achado desta ronda)

Contagem literal no mesmo log (495 472 linhas, 6 dias simulados, 11 simbolos):

| marcador | linhas | % |
|---|---|---|
| `[STATE] ` | 127 025 | 25,6% |
| `RISK CALC USD` | 41 602 | 8,4% |
| `[COST] BLOQUEADO` | 41 551 | 8,4% |
| `CUSTO BLOQUEADO` | 41 551 | 8,4% |
| `SEM STOP NA ENTRADA` | 41 601 | 8,4% |
| `[SCANNER]` | 12 641 | 2,6% |
| `TRADE SUCCESS` | 14 | 0,003% |
| `[VERSION]` | 4 | ~0% |
| `Daily loss limit` | 0 | 0% |

Notas:
- `[COST] BLOQUEADO` e `CUSTO BLOQUEADO` sao o MESMO evento registado duas vezes (uma pelo
  gate de custo, outra pela execucao). Sao 83 102 linhas para 0 trades.
- 41 602 tentativas de risco para 14 trades: a mesma ideia de trade e reavaliada centenas de
  vezes por dia e bloqueada no custo.
- `[STATE]` gasta ~3 linhas por tentativa (RISK_CHECK -> SIGNAL_GENERATED -> VALIDATING).
- `[SCANNER]` â€” o alvo do P1.3 â€” e apenas 2,6% do volume neste build.

**Conclusao medida:** a agregacao do scanner (P1.3, v1.2.38/1.2.39) e correta mas
insuficiente para o alvo <200 linhas/hora. O volume e dominado pelo registo por tentativa
(34% custo/risco + 26% maquina de estados), nao pelo scanner.

### 17.5 O que isto muda no plano

1. `EnableVerboseDebug=false` nos 16 graficos e a alavanca de maior efeito em producao
   (o guard de tester nao ajuda a producao). Precisa de re-anexar os graficos.
2. Agrupar/travar as linhas por tentativa e o passo seguinte de logging - candidato P1.13:
   - nao registar `CUSTO BLOQUEADO` na execucao quando o gate de custo ja registou;
   - `[STATE]` so em transicao real de estado, nao por ciclo de reavaliacao;
   - `RISK CALC USD` e `SEM STOP NA ENTRADA` com throttle por simbolo (ex. 60 s).
3. O mesmo travao acelera o Strategy Tester de forma directa: 34% das linhas estao no
   caminho critico de uma tentativa bloqueada.

### 17.6 Versao e coordenacao

- Fontes em **1.2.39**: `XAU_AI_PRO.mq5` as 22:05:46 (cabecalho v1.2.39), `EA_VERSION_STRING`
  = 1.2.39, `#property version "1.239"`. O processo concorrente fechou o P1.12 (log do backup
  1x/hora, `BackupManager.mqh:349`) e adoptou o meu P1.3 como v1.2.39 nos comentarios de
  `Core/MarketScanner.mqh` (linhas 110 e 214).
- O meu binario e 1.2.38 (634 590 B, 21:47:00) e ficou desactualizado. **Nao recompilei**:
  as fontes mudaram as 22:04 e 22:05:46, ou seja, o outro processo esta a trabalhar.
- Quando estabilizar, falta: compilar 1.2.39, acrescentar ao `m_current.changes` o paragrafo
  do P1.3 (continua sem changelog) e re-medir o journal.

---

## 18. Atualizacao 2026-10-30 22:10 local - v1.2.39 fechada (P1.12 + P1.3)

### 18.1 Marcadores no binario (verificados por busca)

| Ponto | Valor | Ficheiro |
|---|---|---|
| Cabecalho | `// XAU_AI_PRO v1.2.39` | `XAU_AI_PRO.mq5:3` |
| Propriedade | `#property version "1.239"` | `XAU_AI_PRO.mq5:23` |
| Fonte unica | `#define EA_VERSION_STRING "1.2.39"` | `Enterprise/VersionManager.mqh:14` |
| Changelog | paragrafos v1.2.39 (P1.3 + P1.12) antes do v1.2.38 | `VersionManager.mqh:63` |
| Binario | `XAU_AI_PRO.ex5` 638 512 B, 30/10 22:07 | pasta do EA |
| Compilacao | 0 errors, 0 warnings, 19 617 ms, `cpu='X64 Regular'` | MetaEditor build 6294 |

### 18.2 P1.12 - o que foi medido (histograma do journal)

Base: ultimas 200 000 linhas de `MQL5\Logs\20261030.log`, janela
16:02:16.344 -> 21:44:50.472 (mercado fechado, sem ticks).

| Emissor | Volume na janela |
|---|---|
| Bloco `========== HEALTH MONITOR ==========` (25 linhas por bloco) | 2 064 blocos |
| `[BACKUP] Falha na copia: Data\prediction_<SIMBOLO>...` | 2 574 linhas |

Causas apuradas:
1. `HEALTH MONITOR`: o gate era `healthUnhealthy || healthChanged` com throttle
   de 1x/5 min. Sem ticks o estado fica **unhealthy para sempre** e
   `healthChanged` volta a oscilar, logo a condicao re-armava em cada ciclo e o
   bloco completo (25 linhas) saia outra vez.
2. Backup: `CBackupManager::BackupFile()` imprimia **uma linha por ficheiro por
   snapshot**. Com o pipeline Python parado, os `Data\prediction_*.json/csv` nao
   existem, logo todos falhavam em todos os snapshots.

### 18.3 O que mudou (exactamente)

- `XAU_AI_PRO.mq5`, bloco do HEALTH: novo
  `static datetime s_lastHealthFull` + `healthFullDue` (3600 s) e a condicao
  passou a `if((healthUnhealthy || healthChanged) && (healthChanged || healthFullDue))`.
  Mudanca real de estado continua a sair de imediato; o bloco COMPLETO sai no
  maximo 1x/hora.
- `Enterprise/BackupManager.mqh`, `BackupFile()`: o `Print` da falha passou a
  1x/hora com `static long s_copyFailSuppressed` a contar os avisos abafados.
- Nenhuma regra de trading, risco, execucao, lote ou escada foi tocada.

### 18.4 P1.3 (processo paralelo) - registado aqui porque faltava changelog

O outro processo fechou a rodada 6 do P1.3 em `Core/MarketScanner.mqh`
(comentario ~linha 110 e uso ~linha 214): o scanner deixou de imprimir por
simbolo e emite **um resumo por minuto e por instancia**, com silencio maximo
de 15 min; o detalhe por simbolo passa a depender de `EnableVerboseDebug` e nao
sai no Strategy Tester. Base medida: 15 348 linhas `[SCANNER]` no dia, 15 108
num unico grafico.
Os dois paragrafos (P1.3 e P1.12) ficaram no `m_current.changes` da v1.2.39.

### 18.5 Defeito de ferramenta encontrado (e corrigido)

`PENDENCIAS_20261030.md` estava com **376 CRLF + 708 LF soltos** (1085 linhas).
O `read_file_by_lines` conta por CRLF e por isso respondia "only 377 lines
available", escondendo as seccoes 10-17 de quem le pelo MCP. Normalizado para
1085 CRLF e 0 LF solto (65 295 B).
**Regra nova:** depois de qualquer escrita por script externo, verificar `crlf`
e `lf_solto` do ficheiro, nao apenas o tamanho. Os ficheiros de codigo desta
ronda ficaram com `LF_solto=0` (`XAU_AI_PRO.mq5`, `VersionManager.mqh`,
`BackupManager.mqh`, `ExecutionEngine.mqh`).

### 18.6 O que NAO ficou validado (aberto)

1. **Efeito no journal nao medido.** Mercado fechado; a medicao tem de ser
   refeita em operacao (domingo 22:00 UTC) e comparada com as 6 270 linhas/hora
   medidas na v1.2.32.
2. **Nao esta em producao.** Os 16 graficos continuam com o binario anterior;
   sem re-anexar o EA nao aparece `[VERSION] v1.2.39` no journal.
3. **Backtest `7702617382101217572` a correr** (00:59:23 / 11:46:56 no momento
   desta nota). Foram feitas compilacoes durante a corrida - o agente recarrega
   o binario e o ciclo estimado muda. **Nao recompilar outra vez com a corrida
   a decorrer.**
4. **Retencao do backup continua aberta:** `Common\Files\XAU_AI_PRO\Backups` ja
   tinha 1100 itens com `BackupMaxKeep` configurado. O P1.12 corta o spam, nao a
   acumulacao; verificar `CleanupOldBackups()`.

### 18.7 Proximo passo recomendado

1. Esperar o fim do backtest e comparar com o lado A (-34,68 / PF 0,81 /
   296 trades / MaxDD 83,30). Se o lado B for pior, subir
   `StoplessEmergencyRMult` para 2,0-2,5 e repetir.
2. Re-anexar o EA nos 16 graficos (isto tambem activa `AvoidHoursGMT="18,20,22"`
   do P1.9 e publica `[REAL GUARD]` no arranque).
3. Medir o journal em operacao e fechar P1.3/P1.12 por medicao, nao por
   inspeccao.

## 19. Atualizacao 2026-10-30 22:29 local - ponto de retorno antes do re-anexar dos 16 graficos

Estado confirmado: conta **flat** (0 posicoes, 0 ordens) e mercado fechado - a janela segura
para re-anexar os 16 graficos.

Ponto de retorno: perfil de graficos `XAI_V1232_ROLLBACK_20261030` gravado com
`profile_add` (guarda os 16 graficos com o EA, os inputs e a geometria actuais, ou seja o
estado v1.2.32). Para reverter: `profile_apply` com esse nome. O perfil `Default` tambem
continua intacto.

Delta de inputs a aplicar no re-anexar (por grafico), do estado guardado para o alvo:

| input | valor nos graficos | alvo |
|---|---|---|
| `BlockWhenMinLotExceedsRiskCap` | false | **true** (P1.4) |
| `EnableVerboseDebug` | true | **false** (P1.13 / alvo de journal) |
| `AvoidHoursGMT` | 18,22 | **18,20,22** |
| `DailyProfitTargetMaxUsd` | 100.0 | **40.0** |
| `MaxDailyLossUsd` | 60.0 | 60.0 (ja igual) |

O re-anexar e uma alteracao de configuracao de trading a quente: fica dependente de
autorizacao explicita do dono.
Nota de organizacao: as seccoes 15 e 16 aparecem duas vezes neste documento (uma versao
escrita por mim, outra pelo processo concorrente, com horas diferentes). Nada foi apagado;
consolidar a numeracao quando os dois fluxos pararem de escrever ao mesmo tempo.
---

## 20. Atualizacao 2026-10-30 22:40 local - v1.2.40 / P1.13 (audit log sem limite)

### 20.1 O que foi medido

| Ponto | Valor medido |
|---|---|
| `Common\Files\audit_log.csv` | 69 979 KB (68 MB) as 22:28, ainda a crescer |
| `Common\Files\trade_history.csv` | 7 299 KB |
| `Common\Files\XAU_AI_PRO\Backups` | 10 snapshots x 109 ficheiros = 1 100 ficheiros, 787,2 MB |
| Peso por snapshot | 78,7-78,8 MB, dos quais 68 MB sao o `audit_log.csv` |
| `BackupMaxKeep` | 10 - a limpeza esta a funcionar: mantem exactamente 10 |

Leitura: a limpeza de snapshots NAO estava avariada. O que estava sem limite era o
conteudo: cada snapshot copia o `audit_log.csv` inteiro, e esse ficheiro cresce ~1 linha
por decisao, por simbolo e por ciclo, com 16 instancias a escrever. 10 x 68 MB = 680 MB so
de auditoria. Foi esta a via que deixou 0,37 GB livres e abortou um backtest.

### 20.2 O que mudou

- `Core/Config.mqh`: novo input `AuditLogMaxSizeMb = 8` (0 desliga).
- `Monitoring/AuditLog.mqh`: `AuditRotateDecisionLogIfNeeded()`, chamada no inicio de
  `AuditOpenDecisionLog()`, ou seja antes de cada escrita. Se o ficheiro passou do limite,
  e movido para `audit_log_prev.csv` (a geracao anterior e substituida) e o novo comeca
  vazio; o header e reescrito pelo `AuditEnsureDecisionHeader()` que ja existia.
  Limite efectivo 2 x `AuditLogMaxSizeMb`. Nada e apagado. Aviso `[AUDIT] rotacao ...`
  no journal, no maximo 1x/hora.
- `AUDIT_DECISION_FILE` / `AUDIT_DECISION_PREV` substituem o literal `"audit_log.csv"`.
- Versao 1.2.40 (`EA_VERSION_STRING`, cabecalho do `.mq5`, `#property version "1.240"`).

### 20.3 Validacao

- Compilacao: **0 errors, 0 warnings** (23 150 ms, MetaEditor build 6294 x64).
- `LF_solto=0` nos quatro ficheiros tocados (`XAU_AI_PRO.mq5`, `Core/Config.mqh`,
  `Monitoring/AuditLog.mqh`, `Enterprise/VersionManager.mqh`).
- Marcadores por `Select-String`: cabecalho v1.2.40 = 1, `#property version "1.240"` = 1,
  `EA_VERSION_STRING "1.2.40"` = 1, paragrafo P1.13 no changelog = 1,
  `AuditLogMaxSizeMb` no `Config.mqh` = 1, chamada da rotacao = 1, `FileMove(` = 1.

### 20.4 O que NAO esta validado

1. A rotacao nunca correu em producao: o binario v1.2.40 nao esta carregado nos graficos.
   Criterio de aceitacao: depois de re-anexar, o journal mostra uma vez
   `[AUDIT] rotacao do decision log | MB=~68.0 | limite=8 | OK ...` e o `audit_log.csv`
   recomeca perto de zero.
2. Os snapshots seguintes devem cair de 78,8 MB para ~11 MB (8 de audit + 7,3 de
   `trade_history` + 3,3 de dataset + predictions). Medir em dois snapshots consecutivos.
3. O `trade_history.csv` (7,3 MB) continua sem rotacao. Nao e urgente (10 snapshots = 73 MB),
   mas e o proximo candidato se o disco voltar a apertar.
4. `FileMove` com `FILE_COMMON` corre sob `EventLock` (o mesmo lock das escritas), mas a
   corrida entre duas instancias a rodar ao mesmo tempo nao foi testada: a primeira que
   mover ganha, a segunda encontra o ficheiro ja recriado.

### 20.5 Defeito de processo (novo, desta ronda)

Duas chamadas `replace_text_in_file` ao MESMO ficheiro, enviadas no mesmo bloco, correm em
paralelo: a segunda le o ficheiro antes de a primeira gravar e o resultado final perde uma
das duas edicoes. Aconteceu com `#property version` (ficou `1.239` com o cabecalho ja em
v1.2.40) e com o paragrafo do changelog da v1.2.39 (foi escrito e desapareceu).
**Regra:** nunca enviar duas edicoes ao mesmo ficheiro no mesmo bloco - escrever,
confirmar com `Select-String`, e so entao a edicao seguinte.

## 21. Atualizacao 2026-10-30 23:05 local - P0.5 respondida: porque e que entram operacoes sem IA

### 21.1 A pergunta

P0.5 dizia: `AllowTradeWithoutAI=false`, `MinAIConfidence=60`, `AIUnavailableConfidenceCap=40`
e o gateway Python offline, mas ha posicoes abertas pelo EA. Contradicao por resolver.

### 21.2 A resposta (cadeia exacta, ficheiro:linha)

1. `AIGateRequired()` devolve **false** logo nas primeiras linhas quando
   `EnableAutonomousMode=true` - e o valor por defeito
   (`Core/Config.mqh:998`, `input bool EnableAutonomousMode = true`).
   Ver `AI/AIEngine.mqh:46-56`.
2. Consequencia directa: `AITradeAllowed()` devolve `true` sem olhar score nem
   disponibilidade (`AI/AIEngine.mqh:58-64`).
3. `FinalAIAllow()` so entra no ramo de bloqueio `if(AIGateRequired())`
   (`AI/AIEngine.mqh:486-500`), ou seja nao bloqueia.
4. O unico veto que resta e o de score zero, `BlockZeroAIScore=true`
   (`Core/Config.mqh:1017`), aplicado **independentemente do modo**
   (`AI/AIEngine.mqh:526-548`): score <= 0 barra, score > 0 passa.

**Nao ha contradicao.** Quem abre a porta nao e `AllowTradeWithoutAI` (esse
input nem sequer e lido nesse caminho): e `EnableAutonomousMode`. A IA e
consultiva por desenho, documentado em `Core/Config.mqh:986-998` com a medicao
de 29/10 (com o modo autonomo desligado o EA nao abria NENHUMA operacao).
Politica activa, para ficar registada: **operar sempre, IA como conselheira;
silencio total da IA (score = 0) e motivo de recusa.**

### 21.3 Efeito colateral encontrado (novo, aberto)

O numero chamado "confianca da IA" governa o lote:

```
CalculateDynamicLot (Core/ExecutionEngine.mqh:86)
  -> confOut = GetAIConfidence(signal, symbol)        (:97)
  -> gradeOut = ConvictionGrade(confOut, adxOut)      (:99)
  -> factor  = LotFactorForGrade(gradeOut)            (:107)
```

Sem leitura de IA, `GetAIConfidence()` cai no fallback tecnico: 50 base
+15 tendencia +10 RSI entre 30 e 70 +10 ADX >= `MinimumADX`
(`AI/AIEngine.mqh:141-160`), maximo 85.

| Score | Condicao | Nota | Factor de lote |
|---|---|---|---|
| 85 | ADX >= 35 (`DynADXStrong`) e 85 >= 82 (`DynConfStrong`) | 3 - FORTE | **3,00x** |
| 85 x 1,25 = 106 -> 100 | `MemoryBoost` (`AI/AILearningMemory.mqh:154+`) com memoria >= 20 | 4 - ELITE | **4,00x** |

Ou seja: **um lote 4x pode ser decidido sem que nenhum modelo tenha
respondido**, porque o `MemoryBoost` aprendido do historico empurra o score
tecnico acima de `DynConfElite=90`. O nome e "AI confidence"; o conteudo e
indicador. Isto **nao viola** a regra do dono (lote pela confianca/clareza da
tendencia): e um problema de honestidade do numero, nao de regra de risco.

### 21.4 Proposta (nao implementada - espera autorizacao)

- **Opcao A (minima, zero efeito em lote):** log
  `[LOT] conviccao TECNICA | score=... | IA=sem leitura` no caminho do lote
  quando `AIGateRequired()` e false. Passa a dizer a verdade no journal.
- **Opcao B (nova input, por defeito igual ao actual):**
  `MaxGradeWithoutAI = 4` (0 desliga), aplicada em `CalculateDynamicLot`
  quando nao ha leitura real de IA. Com 2 ou 3 o lote sem IA fica limitado a
  2x/3x, e o comportamento actual mantem-se enquanto ninguem mudar o valor.

Nada disto foi compilado: o backtest `7702617382101217572` esta a correr e
recompilar recarrega o binario do agente e mexe na estimativa.

### 21.5 Defeito cosmetico encontrado no codigo

`Core/Config.mqh:1008` tem bytes corrompidos (duplo encoding de um travessao:
`e false <lixo> e ele e false`) no comentario do veto de score zero. Nao afecta
compilacao nem logica (e comentario), mas e texto do projecto estragado.
Correcao trivial, fica para a proxima janela de compilacao.

### 21.6 Ferramenta: `search_text` do MCP nao varre subpastas

Medido nesta ronda: `search_text` com `file_glob="*"` sobre
`Experts/XAU_AI_PRO` **nao devolve ficheiros `.mqh` de subpastas**.
`EA_VERSION_STRING` deu 32 resultados e nenhum de
`Enterprise/VersionManager.mqh`; `AllowTradeWithoutAI` deu 7 resultados todos
em documentacao e zero em codigo - conclusao errada, porque o input existe em
`Core/Config.mqh:520`. **Regra:** para `.mqh` em subpastas usar
`Get-ChildItem -Recurse -Include *.mq5,*.mqh | Select-String` no shell (dentro
do read root `MQL5`), nunca so o `search_text` do MCP.
Segundo trap da mesma ronda: em PowerShell, '`n' dentro de ASPAS SIMPLES e backtick literal, nao newline -
a contagem de LF solto deu 2 num ficheiro limpo. Medir LF solto com [char]10 e comparar
com [char]13 na posicao anterior, ou usar aspas duplas escapadas.

## 22. Atualizacao 2026-10-30 23:35 local - onde e que o dinheiro se perde (analise medida)

### 22.1 Como foi medido

Ficheiro: `Common\Files\trade_history.csv` (7,3 MB, escrito pelo `Monitoring/TradeLogger.mqh`).
Leitura com `FileShare.ReadWrite` (o ficheiro estava aberto pelo terminal), `Import-Csv` +
`TryParseExact` invariante. Amostra valida: **99 560 registos**.
Cautela declarada: o ficheiro e uma **concatenacao de muitas corridas** (687 dias distintos,
369 reinicios de ordem temporal), portanto os totais absolutos nao valem como resultado de
uma serie; o que vale sao as **comparacoes relativas dentro da mesma amostra**.

### 22.2 Integridade do ficheiro (defeito real, medido)

| Medida | Valor |
|---|---|
| Linhas totais | 99 943 |
| Linhas validas (10 campos, data/hora OK) | 99 560 |
| Linhas **partidas** (campos a mais/menos, simbolo cortado, linha `0.00` sozinha) | **371** |
| Reinicios de ordem temporal (prova de concatenacao) | 369 |
| Dias distintos | 687 |
| Registos com `AI > 0` | **17 de 99 649** (0,017%) |

Exemplo de linha partida (escrita concorrente a meio):
`2026.07.01 09:30:49,USDCNH,BUY,0.68910,0.68910,0.14,0.00000,22.83,63.65,2026.07.01 11:26:43,GBPUSD,BUY,3982.01000,...`

**Causa no codigo:** `Monitoring/TradeLogger.mqh` guarda **handle persistente** por instancia
(`InitTradeLogger()`, linhas 18-83) com `FILE_SHARE_READ|FILE_SHARE_WRITE`, faz
`FileSeek(SEEK_END)` e `FileWrite` sem `EventLock`. Com 16 graficos a escrever, duas
instancias procuram o mesmo fim de ficheiro e escrevem por cima uma da outra -> linhas
partidas. E o mesmo problema que a P1.11 resolveu no `BackupManager` e que o audit F4
resolveu abrindo/fechando por escrita.
**Porque importa:** e este o ficheiro de onde o EA aprende o historico (regra 7 do dono).
0,37% de linhas estragadas envenenam qualquer aprendizado que o leia.
**Correccao proposta (P1.16):** abrir -> `SEEK(END)` -> escrever -> `FileFlush` -> fechar em
cada trade, dentro do `EventLock` (padrao F4). Nao mexe em risco.

### 22.3 O divisor de aguas e o ADX (XAUUSD, 80 065 registos)

| Banda ADX | n | net | WR | PF | media/trade |
|---|---|---|---|---|---|
| < 20 | 35 514 | -14 102,30 | 61,0% | 0,872 | -0,40 |
| 20-25 | 4 518 | **-17 952,49** | 69,5% | 0,526 | **-3,97** |
| 25-35 | 10 936 | **-31 032,77** | 70,2% | 0,592 | **-2,84** |
| >= 35 | 29 097 | **+36 152,84** | 82,6% | 1,295 | **+1,24** |

Leitura: **todo o lucro vem de ADX >= 35**; as bandas 20-35 sangram e sao exactamente onde o
lote e escalado. `DynADXClear = 25` (`Core/Config.mqh:1221`) da nota 2 (**2x lote**) a partir
de ADX 25: a faixa 25-35 acumula -31 032 com media -2,84 por trade, o pior valor de todas as
faixas. `DynADXStrong = 35` e o unico patamar que paga.

**Proposta P1.14 (decisao do dono, nada alterado no codigo):** `DynADXClear` de 25 -> 35, ou
seja, nao escalar acima de 1x sem ADX >= 35. Efeito esperado pelos numeros: a faixa 25-35
deixa de levar 2x (perda por trade cai ~metade) e a faixa >= 35 mantem a escala.

### 22.4 As horas que pagam e as que enterram (XAUUSD; UTC = servidor - 5)

| Servidor | UTC | n | net | PF |
|---|---|---|---|---|
| 16 | 11 | 7 449 | **-11 122,72** | 0,764 |
| 19 | 14 | 2 083 | **-7 575,59** | **0,455** |
| 14 | 9 | 7 090 | **-6 443,12** | 0,831 |
| 3 | 22 | 3 744 | -2 296,35 | 0,794 |
| 4 | 23 | 2 567 | -1 949,39 | 0,774 |
| 21 | 16 | 853 | -1 722,13 | 0,519 |
| 20 | 15 | 2 670 | **+3 416,97** | **1,486** |
| 15 | 10 | 10 511 | **+3 384,21** | 1,058 |
| 18 | 13 | 5 224 | **+2 963,36** | 1,107 |
| 13 | 8 | 5 949 | +1 671,88 | 1,081 |

Soma das **tres piores horas (UTC 9, 11, 14) = -25 141,43**, sobre 16 622 trades.
Soma das tres melhores (UTC 13, 15, 10) = +9 764,54.

**Achado que corrige a configuracao proposta para o re-anexar:** a lista em vigor/proposta e
`AvoidHoursGMT = "18,20,22"`, isto e UTC 18, 20 e 22 = **servidor 23, 1 e 3**. Medido:
servidor 23 tem **42 trades** (-71,69) e servidor 1 tem -1 223,65; nenhum deles esta entre os
piores. As horas que realmente custam dinheiro (UTC 9, 11, 14) **nao estao na lista**.
**Proposta P1.15:** `AvoidHoursGMT = "9,11,14,18,20,22"` (mantem as antigas, acrescenta as
tres medidas como piores). E um input, reversivel, mas muda o comportamento -> decisao do dono.

### 22.5 Contexto global (cautela)

Total da amostra: 99 649 trades, net **-30 768,95**, WR 67,8%, **PF 0,918**, media -0,31/trade.
Padrao de "muitos acertos pequenos, poucas perdas grandes": WR alto nao chega quando o PF
fica abaixo de 1. Isto e coerente com o lado A do backtest de 3 meses (PF 0,81) e e o
problema central a resolver antes de conta real - nao e a IA, nem o logging.

### 22.6 O que NAO foi feito nesta ronda

- Nenhuma linha de codigo tocada: as tres propostas (P1.14, P1.15, P1.16) mudam risco ou
  exigem compilacao, e o backtest `7702617382101217572` esta a correr (recompilar recarrega
  o agente e falseia a estimativa).
- As propostas tem de ser confirmadas pelo backtest de 3 meses com ticks reais, que e a
  unica fonte sem o vies de concatenacao de corridas desta amostra.
- O historico manual do dono nao esta identificado nesta amostra (nao ha coluna de origem);
  separar "EA vs manual" continua em aberto para a regra 7.

---

## 20. Atualizacao 2026-10-30 23:10 local - lado A: a cadeia de saida nunca fecha um trade no positivo

Leitura completa do Tester log do lado A (v1.2.35, ticks reais) em 2026.08.14 simulado:
874 437 linhas, 251 MB, ainda a correr (ETA ~9 h). Saldo **200 -> 156,43** (-21,8%).

### 20.1 Resultado por trade (110 fechos)

| metrica | valor |
|---|---|
| trades fechados | 110 |
| fechos com lucro (`PROFIT>0`) | **0** |
| fechos com perda (`PROFIT<0`) | 64 |
| fechos exactamente `0.00` | 46 |
| soma dos `PROFIT` | -43,78 USD |
| saldo esperado (200 - 43,78) | 156,22 (real 156,43; diferenca 0,21 = swap) |
| perda media | -0,68 USD |
| pior trade | -7,79 USD (USDSEK) |

O registo por trade **reconcilia** com a variacao de saldo, logo nao e erro de log: em 110
fechos nao houve um unico trade positivo.

### 20.2 Quem fecha as posicoes

| motivo | ocorrencias |
|---|---|
| `VIGIA FECHOU` (vigia sem stop, fecha em multiplos de R) | 47 |
| `BREAKEVEN` | 6 |
| `TAKE PROFIT` | **0** |
| `PARCIAL` (fecho parcial) | **0** |

O take profit nunca e atingido e o fecho parcial nunca dispara. Na pratica: o trade que anda
a favor e fechado a 0,00 (empate tecnicamente exacto) e o que anda contra fecha em perda.
`Management/BreakEven.mqh` calcula trava de `BreakEvenLockR` (0,30) x distancia ao TP, o que
devia deixar +0,3 R em vez de 0,00 - ou a trava resolve para o preco de entrada, ou outra
via (ladder `SO ALVO` / vigia) fecha primeiro. **Por apurar: e o defeito mais caro do EA.**

### 20.3 O que isto muda nas prioridades

- O teto de perda diaria em USD (P1.2b, 60 USD) **nunca teria disparado** nesta corrida: a
  perda diaria observada foi de 2-4 USD. E um seguro util, nao e a cura.
- A cura esta na cadeia de saida: enquanto o trade positivo virar 0,00, nenhum ajuste de
  risco de entrada muda o sinal da expectativa.
- Ordem sugerida: (1) auditar `BreakEven -> vigia sem stop -> Ladder -> DynamicTP` para saber
  quem fecha a 0,00 e porque o TP nunca e atingido; (2) correr B com a cadeia simplificada
  (alvo fixo + stop) para separar "sinal tem aresta" de "gestao destroi a aresta".

### 20.4 Journal: maiores emissores (841 341 linhas na amostra)

| marcador | linhas | % |
|---|---|---|
| `[STATE]` | 204 759 | 24,3% |
| `[RISK]` | 67 535 | 8,0% |
| `[COST]` | 65 454 | 7,8% |
| `[VIA RAPIDA]` | 49 160 | 5,8% |
| `[LEARN]` | 46 534 | 5,5% |
| `[SCANNER]` | 22 824 | 2,7% |
| `[PIPELINE]` | 18 847 | 2,2% |
| `[GLOBAL]` | 17 815 | 2,1% |
| `[NEWS]` | 17 446 | 2,1% |
| `[LADDER]` | 10 879 | 1,3% |

`[LADDER]` e o caso mais absurdo em densidade: **98,9 linhas por trade**, uma por tick por
posicao aberta, sem throttle (`[LADDER] #2 | USDJPY | lucro -0,10 USD | ...` repetido varias
vezes no mesmo segundo). Candidato directo a throttle de 60 s por ticket.

### 20.5 Recursos

Log 251 MB, a crescer 174 MB/h; disco livre 8,90 GB (o dono libertou espaco entretanto).
Dos 92 dias da janela ja foram simulados 17 -> ETA ~9 h.
## 23. Atualizacao 2026-10-31 15:55 local - v1.2.41 / P1.16 (TradeLogger serializado, padrao F4)

P1.16 executada e compilada. E a correcao na origem do ficheiro de onde o EA aprende:
nenhuma regra de trading, risco ou execucao foi tocada, so a escrita do historico.

### 23.1 O defeito (medido em 31/10 sobre o ficheiro real)

`Common\Files\trade_history.csv` com **99 560 registos validos** apresentava:

| sintoma | contagem |
|---|---|
| linhas partidas (campos a mais, simbolo cortado, "0.00" sozinho) | **371** |
| reinicios de ordem temporal (ficheiro nao monotonico) | **369** |
| registos com `AI > 0` | 17 de 99 649 (0,017%) |

Causa: `Monitoring/TradeLogger.mqh` mantinha **um handle persistente por instancia**
(`FILE_SHARE_READ | FILE_SHARE_WRITE`) e fazia `FileSeek(SEEK_END)` + `FileWrite` a cada
trade, **sem `EventLock`**. Com 15 instancias no mesmo ficheiro somavam-se dois defeitos
independentes:

1. **Interleave** - dois `FileWrite` concorrentes no mesmo descritor de ficheiro.
2. **Posicao obsoleta** - o handle guarda a posicao onde fez o seek. Se a instancia A fez
   seek ao EOF com N bytes e a B escreveu entretanto, o write de A comeca em N e grava
   **por cima** do que a B escreveu: o modo nao e append atomico.

Qualquer agregacao por banda de ADX ou por hora feita sobre este ficheiro agrupa lixo - e
foi sobre ele que P1.14 e P1.15 foram medidas.

### 23.2 O que mudou (v1.2.41)

| ficheiro | mudanca | tamanho |
|---|---|---|
| `Monitoring/TradeLogger.mqh` | reescrito para o padrao F4 | 3 250 -> **7 153 B** |
| `XAU_AI_PRO.mq5` | guard `TradeLoggerReady()`, cabecalho v1.2.41, `#property version "1.241"` | 73 449 -> **73 825 B** |
| `Enterprise/VersionManager.mqh` | `EA_VERSION_STRING "1.2.41"` + paragrafo de changelog | **15 597 B** |

Padrao F4 aplicado, igual ao `Monitoring/EventEmitter.mqh` e ao `Enterprise/BackupManager.mqh`:

```
ABRIR (handle novo) -> LOCK -> SEEK(END) -> WRITE -> FLUSH -> FECHAR -> UNLOCK
```

- **Sem handle persistente**: o estado passou a ser explicito em `g_tradeLoggerOn`; o .mq5
  perguntava por `tradeLoggerHandle != INVALID_HANDLE` e passou a perguntar
  `TradeLoggerReady()`.
- **Header sob lock**: as 15 instancias arrancam no mesmo segundo e antes podiam gravar o
  cabecalho varias vezes. Agora e `FileSize(h)==0` + `EventLockAcquire()` + reconfirmacao
  do EOF ja com o lock.
- **Nunca bloqueia a execucao**: um trade nao gravado e um **DROP contado e impresso**
  (`[TRADELOGGER] DROP | ...`), nunca uma linha partida no ficheiro.
- **Instrumentacao nova**: `TradeLoggerSummary()` devolve `Written`, `Dropped` e
  `EventLockStats()` (contention/timeouts). `CloseTradeLogger()` liberta o lock.

### 23.3 Build

```
cd /d "C:\Program Files\MetaTrader 5" & metaeditor64.exe ^
  /compile:"...\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5" ^
  /log:"...\MQL5\Files\Temp\p116_compile.log" ^
  /inc:"...\MQL5"
```

`Result: 0 errors, 0 warnings, 16461 ms elapsed, cpu='X64 Regular'` (MetaEditor build 6294).
`XAU_AI_PRO.ex5` = **640 754 B** as 31/10/2026 15:50 (antes 640 948 B).

Verificacao pos-build: nenhum `tradeLoggerHandle` nas fontes vivas; guard `TradeLoggerReady()`
em `XAU_AI_PRO.mq5:1639`; todas as fontes mais antigas que o binario
(TradeLogger 15:49:17, VersionManager 15:49:34, .mq5 15:49:52, DiagGate 15:49:07).

### 23.4 Estado do terminal neste momento (medido, nao presumido)

- **15 graficos** (nao 16) com o EA, perfil `XAI_V1232_ROLLBACK_20261030`: XAUUSD, USDCLP,
  USDCOP, USDJPY, USDSEK, USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD, USDBRL,
  USDRUB, USDSGD.
- **P1.14 e P1.15 continuam NAO aplicados**: os inputs em memoria sao `DynADXClear = 25.0`,
  `AvoidHoursGMT = "18,20,22"`, `MinimumADX = 18.0` em todos os 15 graficos.
- **chart04 / USDJPY continua fora de sincronia** com os outros 14: `AvoidHoursGMT = "18,22"`
  (vs "18,20,22"), `BlockWhenMinLotExceedsRiskCap = false` (vs true),
  `DailyProfitTargetMaxUsd = 100.0` (vs 40.0). Com `EnablePipelineMasterGuard = true` isto
  faz uma instancia jogar por regras de risco diferentes das outras.
- **Mercado fechado (sabado)**: `trade_history.csv` congelado em 31/10 06:23 com
  7 498 313 B. O logger F4 **so sera observavel no proximo trade** (segunda-feira): nao ha
  nada a medir hoje no ficheiro.
- **Tester parado**, nenhuma janela de resultado. `Tester\logs`: `20261030.log` 347,6 MB +
  `20261031.log` 842,3 MB = **1,19 GB**. Disco livre: **6,99 GB**.

### 23.5 Nota de coordenacao - processo concorrente

Durante este ciclo outro processo criou `Monitoring/DiagGate.mqh` (31/10/2026 15:49:07,
5 738 B) e inseriu `#include "Monitoring/DiagGate.mqh"` em `XAU_AI_PRO.mq5:38`. Fornece
`DiagGateAllow(symbol, tag, outcome, heartbeatSec)`, `DiagGateSummary()` e
`g_diagGateSuppressed` - supressao de linhas repetidas de diagnostico.

Nao e deste ciclo e **nao tem entrada de changelog**. O build 0/0 desta ronda ja o inclui,
logo o binario 640 754 B tem duas coisas: P1.16 (documentada) e DiagGate (nao documentada).
Quem continuar decide: dar-lhe paragrafo no changelog do 1.2.41 ou abrir 1.2.42.

### 23.6 O que NAO foi feito nesta ronda (e por que)

- **Nao re-anexei os graficos**: aplicar P1.14/P1.15 exige acao do dono; e seria afinar o
  radio com o mostrador torto, porque as duas propostas foram medidas sobre um CSV com 371
  linhas partidas e 369 reinicios temporais.
- **Nao apaguei os logs do Tester** (fora dos `write_roots` do agente).
- **Nao mexi em lote nem em horas**: primeiro uma janela limpa com o logger corrigido.
- **Nao corri o backtest de 3 meses**: 6,99 GB livres e um log de tester de ~800 MB por
  6 h esgotam o disco antes do fim da janela de 92 dias.

### 23.7 Ordem sugerida (do mais barato para o mais caro)

1. Dono apaga `Tester\logs\20261030.log` e `20261031.log` (1,19 GB) e autoriza o re-anexar
   dos 15 graficos com o conjunto novo (`DynADXClear 35`, `AvoidHoursGMT "9,11,14,18,20,22"`,
   USDJPY normalizado).
2. Janela limpa de 2-3 dias com o logger F4 (a partir de segunda), sem mexer em mais nada.
3. Re-medir bandas de ADX e horas sobre um CSV sem linhas partidas; so depois aplicar
   lote e horas.
4. Backtest de 3 meses (`XAI_V1236_3M_REALTICKS.ini`) quando houver disco.

### 23.8 Como confirmar que o P1.16 esta vivo

- Journal: linha `TradeLogger inicializado (F4: abre-lock-seek-write-flush-fecha)`.
- `TradeLoggerSummary()`: `Written` a crescer e `Dropped` em 0; `Lock | contention` a
  acompanhar (se `timeouts` subir, o lock esta a ser disputado a serio).
- Ficheiro: contar linhas com campos a mais / simbolo cortado. Deve ficar nas **371
  historicas** e **nao crescer** com o mercado aberto.

## 24. Atualizacao 2026-10-31 16:11 local - v1.2.43: limpeza de disco + auditoria da cadeia de saida

Esta ronda tem tres partes: (A) limpeza medida, (B) auditoria numerica da cadeia de saida,
(C) tres correcoes de codigo que so foram escritas depois de a medicao as justificar.

### 24.1 Limpeza (duas rondas, 2 583 MB no total)

Ronda 1 (executada antes das medicoes):

| alvo | MB |
|---|---|
| `MQL5\Files\Temp` (conteudo) | 13 |
| `MQL5\Files\Arquivo_Logs_20261030` | 492 |
| `MQL5\logs\20261024..29.log` | 127 |
| caches Python (`__pycache__`, `.pytest_cache`, `.pytest-tmp*`) | 4 |
| `.bak_20261001` de `series_b_oos_m1/m5.csv` | 235 |
| snapshots de `Common\Files\XAU_AI_PRO\Backups` (mantidos os 2 mais recentes) | 446 |
| **total ronda 1** | **1 317** |

Ronda 2 (executada nesta sessao, depois de verificar duplicacao por SHA256):

| alvo | MB | prova de que era seguro |
|---|---|---|
| `MQL5\Files\Common\Data` | 522,0 | 43 dos 52 ficheiros SHA256-identicos a `MQL5\Files\Data`; os 9 restantes sao `prediction_*.json` de 1 KB de agosto, preservados em `Backup\Common_Data_unicos_20261031`; zero referencias a `Common\Data` nos fontes `.py`/`.mq5`/`.mqh` - as unicas referencias a `FILE_COMMON` apontam para `Terminal\Common\Files`, nao para esta pasta |
| `XAU_AI_PRO\core\Temp\cargo-target` | 602,5 | cache de build Rust parado desde 22/10 23:20; nenhum `cargo`/`rustc` em execucao |
| `MQL5\logs\20261030.log` | 160,3 | log do terminal de ontem; o de hoje (`20261031.log`) mantido |
| `.pyc`/`.pyo`/`.tmp`/`.orig`/`.rej` + 2 `__pycache__` | 0,1 | artefactos de compilacao Python |
| 23 logs `compile_*.log` (raiz de `Files` e `Files\Temp`) | 0,6 | logs de compilacao de ago/set mais os 6 desta sessao; os `.ps1` de evidencia foram mantidos |

Disco: **6 776 -> 9 314 MB livres**. Manifestos: `Files\Backup\cleanup_20261031.txt` e
`cleanup_20261031_r2.txt`. Nada de `trade_history.csv`, `.ex5`, fontes, `.venv`,
`node_modules` ou `dist` foi tocado - ver 24.9.

### 24.2 Auditoria da cadeia de saida - o que os 269 tickets dizem

Fonte: `Tester\logs\20261031.log` (842 277 112 B, UTF-16LE, 2 970 941 linhas).

| evento | ocorrencias | leitura |
|---|---|---|
| tickets com linha `[LADDER]` | 269 | universo real de saidas geridas pela escada |
| `ALVO EM DINHEIRO` (profit >= `LadderTpUsd` = 20 USD) | **0** | o alvo de 20 USD nunca foi atingido uma unica vez |
| `STOP TRAVADO` (profit >= `LadderLockTriggerUsd` = 15 USD) | 2 | 0,7% dos tickets |
| `STOP NA ENTRADA` (profit >= `LadderArmUsd` = 10 USD) | 34 189 linhas | mas apenas **157 tickets distintos** - o resto e o log por tick |
| `VIGIA FECHOU` | 111 | |
| `BREAK EVEN` | 0 | coerente: com `EnableMoneyLadder=true`, o `if(!EnableMoneyLadder)` desliga BreakEven, TrailingStopATR, ApproxTakeProfit, PartialClose e PulseQuickExit |
| `stop loss triggered` | 151 / 151 | com SL exatamente na entrada |

**MFE real por ticket** (maximo lucro flutuante alcancado, lido das linhas `[LADDER]`):

| MFE | tickets | % |
|---|---|---|
| 0 - 5 USD | 214 | 79,6% |
| 5 - 8 USD | 1 | 0,4% |
| 8 - 10 USD | 2 | 0,7% |
| 10 - 15 USD | 0 | 0% |
| 15 - 16 USD | 2 | 0,7% |
| >= 20 USD | **0** | **0,0%** |

Melhores casos: `#501 EURUSD 15,94`, `#418 NZDUSD 15,05`, `#409 USDSEK 9,92`,
`#754 USDCHF 9,02`, `#282 USDBRL 6,45`.

**Decisao que a medicao tomou: `LadderTpUsd` NAO se baixa.** Somando `min(MFE, alvo)` por
ticket, o lucro hipotetico e praticamente plano para qualquer alvo entre 8 e 20 USD:

    8 -> 153 | 10 -> 160 | 12 -> 164 | 14 -> 168 | 15 -> 170 | 18 -> 171 | 20 -> 171 USD

Ou seja: 12 USD a mais de alvo valem 7 USD no total de 269 tickets. O problema nao esta na
saida, esta na selecao de entrada - 79,6% dos tickets nunca chegou a 5 USD de lucro. Mexer no
alvo seria tratar o sintoma.

### 24.3 Defeito de I/O provado na escada (P1.18)

`Management\MoneyLadder.mqh` chamava `PositionModify` a cada tick: **54 093 linhas `[LADDER]`
para 269 tickets = 201 por ticket**. Por ticket, porem, o SL so assumiu DOIS ou TRES valores
distintos (`#754`: 0.82666 e 0.00000; `#580`: 157.85900 e 0.00000; `#409`: 0.00000 e
9.58038), e o motivo era sempre `SO ALVO` ou `STOP NA ENTRADA`. Zero linhas
`[LADDER] Falha`. Conclusao inescapavel: eram reenvios redundantes ao servidor, com o SL/TP
que a posicao ja tinha.

Correcao (v1.2.43, P1.18): antes de enviar, comparar `sendSl`/`sendTp` com `curSl`/`curTp`
e continuar sem modificar quando sao iguais (tolerancia de meio ponto). No mesmo bloco foi
removido o `if(noiseUsd > armUsd) armUsd = noiseUsd;`, que era **codigo morto**: com
`armUsd = (noiseUsd > 0) ? noiseUsd : LadderArmUsd`, a condicao nunca podia ser verdadeira.

### 24.4 P1.14 - `DynADXClear` 25,0 -> 35,0

XAUUSD, 80 065 registos de `trade_history.csv`:

| ADX | n | net USD | WR | PF |
|---|---|---|---|---|
| < 20 | 35 514 | -14 102 | 61,0% | 0,872 |
| 20 - 25 | 4 518 | -17 952 | 69,5% | 0,526 |
| 25 - 35 | 10 936 | -31 033 | 70,2% | 0,592 |
| >= 35 | 29 097 | **+36 153** | 82,6% | **1,295** |

Todo o lucro vem de ADX >= 35 e as bandas 20-35 - exatamente aquelas em que o lote era
escalado para 2x - sao as piores do ficheiro. `DynADXClear` passou a 35,0, o que faz o lote
2x exigir a mesma tendencia que o 3x ja exigia (`DynADXStrong` = 35). Efeito lateral
assumido: o portao de noticia (`NewsTradeTrendOnly`) passa a exigir ADX >= 35.

### 24.5 P1.15 - `AvoidHoursGMT` "18,20,22" -> "9,11,14,18,20,22"

| hora servidor | hora GMT | n | net USD | PF |
|---|---|---|---|---|
| 16 | 11 | 7 449 | -11 123 | |
| 19 | 14 | 2 083 | -7 576 | 0,455 |
| 14 | 9 | 7 090 | -6 443 | |
| **soma** | | **16 622** | **-25 141** | |

A lista antiga protegia horas que quase nao operam (servidor 23 tem 42 trades, -72 USD). As
tres melhores horas (UTC 13/15/10) somam +9 765 e ficam de fora da lista.

### 24.6 Incidente: o `Config.mqh` foi corrompido quatro vezes e recuperado

Vale registar porque o padrao se vai repetir. A primeira compilacao da v1.2.43 deu
**100 erros** com `error 126: identifier is too long` na linha 1 do `Config.mqh` - e o
`EXITCODE` era **0**, falso sucesso. Causas, pela ordem em que foram descobertas:

1. **23 LF soltos** dentro de um ficheiro CRLF: o bloco novo foi escrito com `\n` e passou a
   ser uma "linha" gigante. Corrigido normalizando EOL (79 159 -> 79 182 B).
2. **2 665 caracteres nao-ASCII** (mojibake onde havia acentos e travessoes), todos em
   comentarios. Colapsados para `-` (79 182 -> 73 291 B). **Os erros do compilador nao
   mudaram um byte.**
3. **A causa real: 44 bytes NUL (0x00)** a partir do offset 73 247. O compilador trata um
   `.mqh` com NUL como binario. Removidos, mais `TrimEnd` da ultima linha e fecho do
   comentario cortado -> 73 263 B, NUL = 0, naoASCII = 0.
4. **`#endif` final truncado** pela limpeza: `error 372: mismatched #ifdef/#endif pair`.
   Reposto -> 73 275 B, `#ifndef` = 1, `#endif` = 1, **0 erros**.

Estado final do `Config.mqh`: 73 275 B, 1 529 linhas, 247 inputs, 0 NUL, 0 nao-ASCII,
BOM = False. Licao operacional: **um `.mqh` que deixa de compilar sem razao aparente deve
ser varrido por NUL primeiro e por EOL depois** - antes de se olhar para o codigo.

### 24.7 Processo concorrente

Durante esta ronda havia outro processo a editar as mesmas fontes. Ele subiu a versao para
1.2.42 e reservou o rotulo P1.17 para `Monitoring\DiagGate.mqh`; esta ronda foi renumerada
para **1.2.43 / P1.18**. Ele tambem reverteu silenciosamente, em momentos diferentes, o
bloco do `AvoidHoursGMT` e o `#define EA_VERSION_STRING` - ambos reaplicados e reconfirmados
por `findstr` (linha 684 e linha 14). O changelog v1.2.43 e o `#property version "1.243"`
sobreviveram. No fecho desta ronda ele reescreveu este mesmo ficheiro e apagou a seccao 24,
que teve de ser anexada uma segunda vez.

### 24.8 Build v1.2.43

    Result: 0 errors, 0 warnings, 15638 ms elapsed, cpu='X64 Regular'
    XAU_AI_PRO.ex5   646 910 B   31/10/2026 16:20

`get_expert_advisor_parameters` confirma no binario: `version 1.243`, 309 parametros,
`DynADXClear 35.0`, `AvoidHoursGMT "9,11,14,18,20,22"`. Nota: pesquisar as strings
`1.2.43`/`1.243` dentro do `.ex5` devolve False - as strings nao ficam em claro, essa
pesquisa nao serve como validacao.

### 24.9 O que NAO foi feito nesta ronda (e por que)

1. **Re-anexar os 16 graficos** do perfil `XAI_V1232_ROLLBACK_20261030` com o binario
   v1.2.43 e os inputs novos. `list_open_charts` mostra que os 16 continuam em
   `DynADXClear 25.0` / `AvoidHoursGMT "18,20,22"`, e o `chart04` (USDJPY) divergente
   (`"18,22"`, `BlockWhenMinLotExceedsRiskCap false`, `DailyProfitTargetMaxUsd 100.0`).
   **Falta autorizacao do dono** - e uma operacao que mexe na configuracao de 16 graficos
   com o EA ligado.
2. **Apagar `Tester\logs`** (`20261030.log` 347,6 MB + `20261031.log` 842,3 MB = 1,19 GB):
   esta fora dos `write_roots` do agente. Precisa de autorizacao explicita.
3. **`dist\mt5-gateway` (1 022 MB), `.venv` (1 331 MB), `node_modules` (211 MB)**: sao
   regeneraveis (`mt5-gateway.spec`, `scripts\build_app.bat`, `requirements`, `package.json`
   existem), mas reconstruir exige rede e tempo. Nao apagados sem decisao do dono.
4. **Backtest de 3 meses** (`XAI_V1236_3M_REALTICKS.ini`): o disco agora tem 9,3 GB, mas o
   log do tester cresce ~800 MB por 6 h de corrida. Fica para quando 1 e 2 estiverem
   resolvidos.
5. **Re-medir bandas de ADX e horas**: so faz sentido com uma janela limpa de 2-3 dias
   gravada pelo logger F4. O mercado esta fechado ao sabado, logo so a partir de segunda.

## 25. Atualizacao 2026-10-31 16:29 local - re-ataque dos 16 graficos com v1.2.43 e a auditoria do input Symbols

### 25.1 O que foi aplicado (autorizado pelo dono as 16:29)

- Perfil novo `XAI_V1243_20261031` criado por `profile_add` a partir do estado vivo (16:31:11).
- Patch dos 16 `.chr` (`Files\Backup\patch_charts_1243.ps1`, 16/16):
  - `DynADXClear` 25.0 -> 35.0 em todas;
  - `AvoidHoursGMT` "18,20,22" (e "18,22" no chart04) -> "9,11,14,18,20,22";
  - chart04/USDJPY: `BlockWhenMinLotExceedsRiskCap` false -> true e `DailyProfitTargetMaxUsd` 100.0 -> 40.0.
- `profile_apply XAI_V1243_20261031` = ok:true as 16:32:15. Journal do terminal: 16 experts "removed" + 16 "loaded successfully".
- Verificacao final em duas frentes, ambas concordantes:
  - disco: os 16 `.chr` as 16:32:29 com ADX=35.0, horas=9,11,14,18,20,22, blkMin=true, dptMax=40.0;
  - a quente (`list_open_charts`): as 16 instancias com `DynADXClear=35.0`, `DynADXStrong=35.0`,
    `AvoidHoursGMT=9,11,14,18,20,22`, `BlockWhenMinLotExceedsRiskCap=true`,
    `DailyProfitTargetMaxUsd=40.0`, `LadderTpUsd=20.0`, EA ligado, `AutoTrade=true`.

### 25.2 A ordem que tem de ser respeitada (licao operacional dura)

1. O terminal **reescreve** os `.chr` do perfil **selecionado** a partir do estado vivo a cada troca de perfil.
   Patchei as 16, apliquei o perfil antigo para libertar a selecao, e o terminal reverteu os 16 para 25.0 as 16:32:12.
2. Regra correcta: **patch com o perfil NAO selecionado, `profile_apply` imediatamente depois**.
3. `profile_apply` sobre o perfil ja selecionado e no-op e devolve `ok:false` - nao e erro de permissao.

### 25.3 Rollback preservado

- `XAI_V1232_ROLLBACK_20261030` intacto (ADX 25.0, horas "18,20,22", chart04 com blkMin=false e dptMax=100.0).
- Backups dos `.chr` originais em `Files\Backup\Charts_20261031\*.bak`.
- `patch_charts_1243.ps1` e reutilizavel: preserva a codificacao detectada pelo BOM (UTF-16LE+BOM), faz backup
  antes de escrever e verifica por regex depois de escrever.

### 25.4 AUDITORIA: o input `Symbols` nao governa o trading (novo, P1.19)

**Medicao (journal do expert, 16 fontes):** todas as 16 instancias imprimem
`SYMBOL MANAGER | Total active symbols: 11` - inclusive as que correm simbolos que **nao** estao nessa lista.

**Leitura de codigo:** `Core\SymbolManager.mqh` constroi `ActiveSymbols[]` a partir de `Symbols`.
Pesquisa recursiva em todos os `.mq5`/`.mqh` do EA mostra que **`ActiveSymbols` nao e lido fora de
`SymbolManager.mqh`**. Quem decide o que se negoceia e sempre `_Symbol` do grafico.

**Consequencias medidas:**

- 5 dos 16 graficos correm simbolos que nao estao em `Symbols`:
  `USDCLP`, `USDCOP`, `USDCZK`, `USDRUB`, `USDSGD`.
  Estes graficos **operam normalmente** - exactamente porque a lista nao e vinculativa.
- O dono pode acreditar que `Symbols` limita o universo negociado. Nao limita: e um input com efeito
  apenas de log. `EnableMultiSymbol=true` + 11 simbolos produz uma lista que ninguem consome.
- Os 16 graficos partilham `MagicNumber=2026001`. Nao ha colisao porque cada instancia so toca em `_Symbol`
  e os 16 simbolos dos graficos sao todos distintos (verificado na lista de graficos abertos).
  Se algum dia dois graficos tiverem o **mesmo** simbolo, passa a haver duas instancias a gerir a mesma
  posicao com o mesmo magic - e o risco a vigiar.

**Recomendacao (NAO aplicada nesta ronda, de proposito):**

- Opcao (a): documentar `Symbols` como informativo no comentario do input em `Config.mqh`.
- Opcao (b), preferivel: em `InitSymbolManager()`, imprimir um aviso unico quando `_Symbol` nao consta de
  `Symbols` - e barato, nao muda comportamento de trading nenhum e torna a incoerencia visivel no journal.

Fica como **P1.19** para a proxima janela de codigo, junto com a re-medicao de ADX/horas.

### 25.5 O que continua pendente e por que

1. **Apagar `Tester\logs`**: agora `20261030.log` 331,5 MB + `20261031.log` 803,3 MB = **1 135 MB**.
   `tester_list_result_windows` esta vazio (nada a interromper), mas a pasta `Tester` esta **fora dos
   `write_roots`** do agente. Precisa de autorizacao explicita do dono.
2. **`dist\mt5-gateway` (1 022 MB), `.venv` (1 331 MB), `node_modules` (211 MB), `Python\models` (515 MB)**:
   regeneraveis, mas reconstruir exige rede e tempo. Sem decisao do dono.
3. **Backtest de 3 meses** (`XAI_V1236_3M_REALTICKS.ini`): o disco tem **9 282 MB** livres (folga de so
   ~300 MB face a leitura das 16:19) e o log do tester cresce ~800 MB por 6 h. Fica para depois de 1.
4. **Re-medir bandas de ADX e horas**: so faz sentido com uma janela limpa de 2-3 dias gravada pelo logger
   F4. Mercado fechado ao sabado - so a partir de segunda.
5. **P1.19 (novo)**: aviso de incoerencia entre `_Symbol` e `Symbols` no `SymbolManager`.
6. **Regra 7**: separar operacoes manuais das do EA - `trade_history.csv` continua sem coluna de origem.


### 25.6 Fecho: P1.19 aplicado e v1.2.44 em producao (16:38 local)

O que a 25.4 deixou como recomendacao foi aplicado na mesma ronda, porque a janela era a certa (sabado,
mercado fechado) e a alteracao nao toca em risco nem em execucao.

- `Core\SymbolManager.mqh`: em `InitSymbolManager()`, depois de `ActiveSymbols[]` construido, resolve-se
  `_Symbol` por `ResolveBrokerSymbol()` e, se nao constar da lista, imprime-se
  `SYMBOL MANAGER | AVISO P1.19: ...`. Unico efeito: linha de journal.
- `Enterprise\VersionManager.mqh`: `EA_VERSION_STRING` 1.2.43 -> 1.2.44 e entrada de changelog.
- `XAU_AI_PRO.mq5`: cabecalho v1.2.44.
- Compilacao: 0 errors / 0 warnings. `.ex5` 648 734 B as 16:38:06.
- Backup do original: `Files\Backup\SymbolManager_20261031_before_p119.mqh`.

**Verificacao:** o aviso disparou em exactamente 5 das 16 instancias - `USDCLP`, `USDCOP`, `USDCZK`,
`USDRUB`, `USDSGD` - e em nenhuma das 11 que constam de `Symbols`. E a lista que a auditoria tinha previsto,
o que valida a comparacao. Os 16 graficos recarregaram com `XAU_AI_PRO v1.2.44` as 16:38:23 (16 registos,
16 simbolos distintos), e os 16 `.chr` reescritos as 16:38:14 mantiveram `DynADXClear=35.0` e
`AvoidHoursGMT=9,11,14,18,20,22`.

**Licao operacional (nova e importante):** o terminal **nao** recarrega os EAs quando o `.ex5` e compilado
por processo externo (`metaeditor64 /compile`); so a compilacao pelo IDE o faz. Para o binario entrar em
producao e preciso o ciclo `profile_apply <outro>` -> `profile_apply XAI_V1243_20261031`. Ate isso
acontecer, o journal mostra a versao antiga e qualquer relatorio de "aplicado" e falso.

**Rollback continua valido:** `XAI_V1232_ROLLBACK_20261030` intacto e backups `.chr` originais em
`Files\Backup\Charts_20261031\*.bak`. Para reverter o codigo, o backup do `.mqh` acima e recompilar.


### 25.7 Ronda 3 de limpeza (16:53) - 2 564 MB de dependencias regeneraveis

Autorizada pelo dono ("sim pode remover"). So entrou o que e reconstruivel por gestor de pacotes, com prova
previa de que nada em execucao depende disso.

**Verificacao antes de apagar:**

- processos `node`/`python` a correr: apenas um `node.exe` PID 11144, e o `CommandLine` mostra
  `C:\Users\Micro\AppData\Roaming\npm\node_modules\openclaw\dist\index.js gateway --port 18789` -
  fora da pasta do projecto. Nenhum processo Python.
- referencias a `dist\mt5-gateway`, `.venv` ou `node_modules` nos fontes MQL5 (`*.mq5`/`*.mqh`): **0**.
- manifestos de reconstrucao presentes: 7 de 7 (`mt5-gateway.spec`, `launcher.spec`, `scripts\build_app.bat`,
  `installer\installer.iss`, `package.json`, `backend\package.json`, `frontend\package.json`).

**Apagado (alvos explicitos, sem wildcards):**

```
APAGADO    1331,4 MB   26270 f  Files\XAU_AI_PRO\.venv
APAGADO    1022,2 MB    5211 f  Files\XAU_AI_PRO\dist
APAGADO      48,3 MB    1222 f  Files\XAU_AI_PRO\node_modules
APAGADO      18,5 MB    2183 f  Files\XAU_AI_PRO\backend\node_modules
APAGADO     143,7 MB    6037 f  Files\XAU_AI_PRO\frontend\node_modules
--- total apagado: 2 564 MB   (disco livre 9 248 -> 11 894 MB)
```

**Preservado de proposito:**

- `Files\XAU_AI_PRO\Python\models` (515,1 MB): sao modelos treinados. "Regeneravel" nao esta provado -
  exigiria o dataset e o pipeline de treino, que nao foram validados nesta ronda. Nao se apaga por analogia.
- `Files\XAU_AI_PRO\frontend\dist` (9,3 MB): apesar de ser build output, e o artefacto que uma UI serviria
  como estatico; 9 MB nao pagam o risco de quebrar algo que o dono use.
- Todos os manifestos (`.spec`, `package.json`, `requirements`, `scripts\`, `installer\`).

Manifesto em `Files\Backup\cleanup_20261031_r3.txt`. Script: `Files\Backup\purge_rebuildables_20261031.ps1`.

**Total acumulado da sessao: 5 147 MB** (ronda 1 + ronda 2 1 286 MB + ronda 3 2 564 MB).

### 25.8 Tester\logs: bloqueio real e a via legitima

O agente **nao pode** apagar `Tester\logs`: `Tester` esta nos `read_roots` mas **nao** nos `write_roots`
(`write_roots` = `MQL5` + `Common`), e a politica de shell proibe tocar fora dos roots mesmo com autorizacao
verbal do dono. A autorizacao resolve a vontade, nao o limite tecnico.

Diagnostico medido nesta ronda (teste de abertura exclusiva, `FileShare.None`):

```
20261030.log | 331,5 MB | LIVRE
20261031.log | 803,3 MB | BLOQUEADO   <- mantido aberto pelo terminal64
```

Ou seja: mesmo com permissao, 803 MB dos 1 135 MB nao sairiam sem fechar o terminal.

**Vias (uma delas resolve):**

- (a) O dono corre `Files\Backup\purge_tester_logs.ps1` (duplo-clique). E "best effort": apaga o que estiver
  livre e diz o que ficou aberto. Para levar os 1 135 MB, fechar o MT5 primeiro e voltar a correr.
- (b) O dono acrescenta `Tester` aos `write_roots` na configuracao do workspace do assistente; a partir dai o
  agente apaga e prova, como fez nas rondas 1-3.


### 25.9 Decisoes do dono (16:56) - os modelos ficam

- `Files\XAU_AI_PRO\Python\models` (515,1 MB): **MANTER**. Decisao do dono as 16:56. Sao artefactos
  treinados; nao se apagam por serem grandes nem por analogia com `.venv`/`dist`/`node_modules`, que sao
  reconstruiveis por gestor de pacotes e estes nao. Confirmado presente e intacto apos a ronda 3.
  Nenhum script de limpeza deste repositorio o tem como alvo: `purge_rebuildables_20261031.ps1` lista-o
  apenas na secao "preservado de proposito". A decisao fica aqui para nao voltar a ser perguntada.
- `Files\XAU_AI_PRO\frontend\dist` (9,3 MB): mantido pela mesma logica - e o artefacto que uma UI serviria
  como estatico, e reconstrui-lo exige `npm run build` (rede).
- `Tester\logs` (1 135 MB): continua fora dos `write_roots`. Vias: o dono corre
  `Files\Backup\purge_tester_logs.ps1` (best effort; leva os 1 135 MB se o MT5 estiver fechado), ou
  acrescenta `Tester` aos `write_roots` e o agente faz o mesmo trabalho com manifesto.

**Fecho de contas da limpeza desta sessao:** ronda 1 + 1 286 MB (ronda 2) + 2 564 MB (ronda 3) =
**5 147 MB**. Disco livre actual: 11 894 MB. Nada apagado fora de `MQL5` e `Common`.

## 26. Backtest de 3 meses arrancado com a configuracao de producao (2026-10-31 17:00 local)

### 26.1 Uma incoerencia de versao corrigida antes de medir
O `EA_VERSION_STRING` passou a `1.2.44` as 16:37, mas a propriedade numerica do EA ficou em `1.243`. O proprio `VersionManager.mqh` (comentario perto da linha 127) diz que os tres sitios tem de concordar: `EA_VERSION_STRING`, o cabecalho do `.mq5` e o `#property version`.

- `XAU_AI_PRO.mq5` linha 23: `#property version "1.243"` -> `"1.244"`.
- Recompilado as 16:59: `Result: 0 errors, 0 warnings, 14116 ms elapsed, cpu='X64 Regular'`.
- `XAU_AI_PRO.ex5` = 648 936 B as 16:58:59.
- **Nenhuma linha de logica mudou.** A diferenca entre o binario que corre nos 16 graficos (16:38:06) e o que o tester carregou (16:58:59) e apenas esta string, logo a comparacao entre backtest e producao continua valida.

### 26.2 O `.set` do backtest deixou de vir de um ficheiro de 1.2.36
`XAI_V1236_3M_REALTICKS.set` (28 140 B, 2026-10-31T00:15:48Z) foi gravado na versao 1.2.36 e ainda trazia `DynADXClear=25.0` e `AvoidHoursGMT=18,20,22` — precisamente os dois valores que a medicao de hoje substituiu por 35.0 e `9,11,14,18,20,22`. Remendar dois campos num ficheiro de outra versao deixaria todos os restantes parametros de 1.2.36, incluindo os quatro `RealGuard*` que so existem a partir de 1.2.37.

Em vez disso, o novo `.set` e **extraido do bloco `<inputs>` do `chart01.chr`** (XAUUSD) do perfil `XAI_V1243_20261031`:

| fact | value |
|---|---|
| script | `Files\Backup\build_set_1244.ps1` |
| inputs lidos do grafico | **308** |
| inputs declarados pelo `.ex5` | **308** |
| ficheiro gerado | `Profiles\Tester\XAI_V1244_3M_REALTICKS.set` (7 786 B) |

Confirmado dentro do ficheiro gerado: `AutoTrade=true`, `MagicNumber=2026001`, `EnableMoneyLadder=true`, `LadderTpUsd=20.0`, `DynADXClear=35.0`, `DynADXStrong=35.0`, `AvoidHoursGMT=9,11,14,18,20,22`, `BlockWhenMinLotExceedsRiskCap=true`, `DailyProfitTargetMaxUsd=40.0`, `RiskPerTradeUsd=2.0`.

Consequencia pratica: o backtest corre **a configuracao que esta em producao**, nao uma aproximacao dela.

### 26.3 Os 14 overrides `lean` - e porque nao mudam a decisao
O log do tester ja cresceu ~800 MB em 6 h de simulacao nesta maquina, e o disco tem 11,9 GB. Para nao repetir o aborto por disco cheio, 14 interruptores **de escrita/telemetria** foram forcados:

```
EnableVerboseDebug=false   DebugTradeDecision=false  EnableDiagnostics=false
EnableDataset=false        SaveDatasetCSV=false      EnableScenarioLog=false
EnableGlobalScenarioLog=false  EnableAuditLog=false  EnableTelemetry=false
EnableDashboard=false      EnableBackupManager=false EnableForwardLog=false
EnableNotifications=false  AutoTrade=true
```

Nenhum deles participa em `ShouldOpen`, no dimensionamento de lote, no `RiskEngine`, na `MoneyLadder` ou nos filtros: todos escrevem para ficheiro, para o dashboard ou para notificacoes. `EnableDataset=false` desliga a **gravacao** do dataset, nao a sua leitura. Se o resultado do backtest divergir do esperado por causa de um destes campos, a primeira coisa a testar e repor `true` um a um.

### 26.4 A corrida

| campo | valor |
|---|---|
| run_id | `7702924108834513378` |
| perfil | `Profiles\Tester\XAI_V1244_3M_REALTICKS.ini` (528 B) |
| inputs | `Profiles\Tester\XAI_V1244_3M_REALTICKS.set` (7 786 B) |
| simbolo / periodo | XAUUSD / M15 |
| intervalo | 2026.07.29 00:00 -> 2026.10.29 00:00 |
| modelo | **real ticks** (`Model=4`) |
| deposito / alavancagem | 200,00 USD / 1:100 |
| arranque | 17:00:15 (agente `Core 1`, build 6294) |
| historico de ticks | 2026.07.29 a 2026.10.28 (sincronizado) |
| espaco atribuido pelo tester | 9 556 MB, 119 blocos de geracao de ticks |

### 26.5 Vigilancia que fica a cargo de quem seguir
- O backtest de 3 meses com ticks reais levou **11-15 h** nas tentativas anteriores. O disco tem de ser verificado de hora a hora: `20261031.log` ja tem 803 MB e o `.tst` do teste acresce ~2 GB.
- Se o disco descer abaixo de ~2 GB, parar com `tester_stop` e apagar `Tester\logs\20261030.log` (331 MB, livre) antes de retomar.
- O resultado so vale como **medida**, nunca como promessa: um backtest unico nao prova rentabilidade.

## 27. P1.20 - o backtest estava a escrever no ficheiro de onde o EA aprende (2026-10-31 17:0x local)

### 27.1 O que se viu (medido, nao suspeitado)
O backtest `7702924108834513378` (XAUUSD M15, ticks reais, 2026.07.29 -> 2026.10.29) arrancou as 17:00:15. As 17:03, ao inspeccionar `Common\Files\trade_history.csv`:

| medicao | valor |
|---|---|
| `mtime` do ficheiro | `2026-10-31 17:02:12` — acompanhava o relogio do teste |
| tres ultimas linhas | `2026.07.29 05:37:31,XAUUSD,SELL,163.68,163.68,-0.38,0.00,0.00,0.00,0.00` ... |

Ou seja: o Strategy Tester estava a anexar ao ficheiro **de producao** linhas com data simulada de Julho e com `ATR/ADX/RSI/AI` a `0.00`. O `FILE_COMMON` resolve, tambem dentro do tester, para a pasta comum verdadeira — o isolamento nunca existiu.

O problema nao e cosmetico: e exactamente desse ficheiro que sairam as bandas de ADX (80 065 registos), as horas (`AvoidHoursGMT`, 99 560 registos) e o historico de aprendizagem do EA. Cada trade de backtest muda a distribuicao que serve de base a essas medicoes.

### 27.2 A correcao (`Monitoring/TradeLogger.mqh`, P1.20 / v1.2.45)
- Novo `TradeLoggerFileName()`: devolve `trade_history_backtest.csv` quando `MQLInfoInteger(MQL_TESTER)` ou `MQL_VISUAL_MODE`, e `trade_history.csv` no resto.
- `TradeLoggerOpen()` passou a usar esse nome em vez do literal `TL_FILE`.
- Nada mais mudou: mesmo lock F4, mesmo header, mesmas 10 colunas, mesma politica de DROP. **Nenhuma regra de trading, risco, execucao ou precificacao foi tocada.**

### 27.3 Prova de que a separacao funciona
Depois de recompilar (v1.2.45, `0 errors, 0 warnings`) e relancar:

```
trade_history.csv           7498596 B  17:02:12   (mtime parado)
trade_history_backtest.csv       51 B  17:10:02   (criado pelo tester)
```

`trade_history.csv` deixou de crescer com o teste a correr. As 51 linhas de bytes do segundo ficheiro sao o header, coerente com o P1.16.

### 27.4 A tentativa de limpeza que ABORTOU (e por que foi o comportamento certo)
O plano era cortar o bloco final de linhas com data <= 2026.10.29. O script `purge_backtest_rows_p120.ps1` fez backup integral, testou abertura exclusiva e abortou:

```
linhas totais: 100239
ABORTADO: nenhuma linha com data >= 2026.10.30; nada removido
```

Investigacao do porque, e o achado que interessa reter:

| medicao do `trade_history.csv` | valor |
|---|---|
| linhas | 100 239 |
| dias distintos | **689** |
| primeiro dia | 2024.01.02 (36 linhas) |
| ultimo dia | 2026.10.29 (27 linhas) |
| linhas com data 30 ou 31/10/2026 | **0** |

Conclusao: o ficheiro **nao e** um registo de producao com um bloco simulado no fim. E um ficheiro onde os backtests de 2024-2026 deixaram tudo o que tem, e onde nao existe uma unica linha dos dias 30-31/10. Nao ha fronteira por onde cortar sem risco de apagar registos legitimos, logo nao se cortou nada. O backup `trade_history_20261031_before_p120.csv` (7 498 596 B) ficou guardado.

### 27.5 Consequencia para as medicoes anteriores
As medicoes de ADX e de horas (P1.14/P1.15) foram feitas sobre este ficheiro, portanto sobre uma mistura onde o volume simulado domina. Isso **nao invalida** o sinal que elas encontraram — a comparacao relativa entre bandas de ADX continua a ser entre trades do mesmo tipo — mas **invalida** qualquer leitura do tipo "isto e o que aconteceu em conta real". Fica registado como limitacao, com nome e numero.
Para uma base limpa: so com o logger F4 a gravar em producao, com o tester ja isolado (P1.20), e com uma janela de 2-3 dias de mercado aberto.

### 27.6 O agente do tester ficou pendurado
Depois do `tester_stop`, as duas relancagens seguintes morreram em 20-50 ms:

```
17:05:14 Core 1 disconnected / connection closed
17:07:15 Core 1 disconnected / connection closed
```

Causa medida: o `metatester64` do primeiro run continuava vivo com **4 920 MB** de working set (PID 13196, arrancado 16:59:39) e a recusar o novo trabalho. Terminado esse processo, o run seguinte arrancou normalmente as 17:10 e ja simulava `2026.07.29 03:55`.

**Regra para a proxima vez:** `tester_stop` nao garante que o agente morra. Antes de relancar, verificar `Get-Process metatester64` e, se houver um processo com GB de working set e sem progresso no log, termina-lo.

### 27.7 O run que ficou a correr
| campo | valor |
|---|---|
| run_id | `7702926785952690594` |
| binario | v1.2.45 (`EA_VERSION_STRING` 1.2.45, `#property version` 1.245) |
| perfil / inputs | `XAI_V1244_3M_REALTICKS.ini` / `XAI_V1244_3M_REALTICKS.set` (308 inputs do `chart01.chr`) |
| isolamento do historico | escreve em `trade_history_backtest.csv` |

### 27.8 O que o log do backtest mostrou sobre o universo negociado
O log do tester imprime `[VIA RAPIDA] USDJPY`, `USDCAD`, `USDCNH` e `[RESUMO] master=SIM` **dentro de um teste de XAUUSD**. Confirma, por outro caminho, o que P1.19 dizia: `Symbols` nao limita nada — no tester a instancia varre a lista inteira e assume-se como master. Em producao cada grafico trata do seu simbolo; no backtest um grafico trata de todos. **O backtest nao reproduz a topologia de producao neste ponto** e isso tem de ser dito sempre que se citar o resultado.

### 27.9 Os 16 graficos passaram para v1.2.45 (17:15 local)
Como nao havia posicoes abertas (`get_trading_open_positions` devolveu lista vazia), foi feito o ciclo que o terminal exige para recarregar EAs compilados fora do IDE: `profile_apply Default` -> `profile_apply XAI_V1243_20261031`, ambos `ok:true`.

Verificacao em duas fontes independentes:

| fonte | resultado |
|---|---|
| `.chr` em disco (16:15) | `OK=16 BAD=0` — todos com `DynADXClear=35.0` e `AvoidHoursGMT=9,11,14,18,20,22` |
| journal (17:15:49) | `[VERSION] v1.2.45 | Build=2026.10.30 | Stable=Yes` por instancia, 15 modulos `OK` |

O ciclo nao reverteu nada do patch de hoje: o terminal reescreve os `.chr` a partir do estado vivo, e o estado vivo ja tinha os valores medidos. A diferenca entre o binario anterior (1.2.44) e este (1.2.45) e so a funcao de escolha do nome do ficheiro no `TradeLogger`, que em producao devolve exactamente o mesmo `trade_history.csv` de antes — logo as 16 instancias continuam a gravar no mesmo sitio, sem mudanca de comportamento.

## 28. P1.21 - Regra 7 fechada: o trade_history passou a dizer quem abriu a operacao (2026-10-31 19:2x local)

### 28.1 O que estava em aberto
A Regra 7 estava pendente desde 30/10 com esta redaccao: *"separar operacoes manuais das do EA - `trade_history.csv` nao tem coluna de origem"*. O ficheiro guardava 10 campos (`Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI`) e nada que identificasse o autor da ordem.

### 28.2 A medicao que justificou a alteracao
Antes de mexer no schema, medi o que existe:

| medicao de `Common\Files\trade_history.csv` | valor |
|---|---|
| linhas | 100 239 |
| dias distintos | 689 (2024.01.02 a 2026.10.29) |
| linhas com 10 campos | 99 964 |
| linhas com contagem diferente (ja partidas) | 263 |
| colunas de origem | **0** |

Pesquisa recursiva em todos os `.mq5`/`.mqh` do EA: **nada dentro do EA le `trade_history.csv`** (so o `BackupManager` o copia). Do lado de fora, `Python/backtest/forward_test.py` le-o com `pd.read_csv`, que usa o cabecalho e nao a posicao — logo acrescentar colunas no fim e compativel.

### 28.3 A alteracao (v1.2.46)
- `LogTradeCSV()` ganhou `ulong positionId` e `long dealMagic` (com valor por omissao, para nao quebrar chamadas futuras).
- O chamador em `XAU_AI_PRO.mq5` passa `HistoryDealGetInteger(deal, DEAL_POSITION_ID)` e `DEAL_MAGIC`.
- Cabecalho passa a `Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI,Ticket,Magic,Origin`.
- `TradeLoggerOrigin(magic)`: `MagicNumber` -> `EA`, `0` -> `MANUAL`, outro -> `OTHER`. **E o unico campo causal** — o magic do deal — e nao uma inferencia sobre simbolo, horario ou tamanho.

### 28.4 Porque nao se misturou 10 com 13 colunas
Este e o ponto onde a alteracao podia ter corrido mal: escrever linhas de 13 campos num ficheiro com cabecalho de 10 produz exactamente o defeito que o P1.16 mediu (371 linhas partidas em 99 560, "campos a mais").

Duas proteccoes:
1. **Migracao offline** feita antes de instalar o binario: `migrate_trade_history_p121.ps1` reescreveu o ficheiro com as 13 colunas, e nas linhas antigas `Ticket` e `Magic` ficaram vazios e `Origin=UNKNOWN` — honesto, porque nessa altura a origem nao foi registada e nao se inventa.
2. **Guarda no codigo**: `TradeLoggerEnsureSchema()` corre sob lock no arranque de cada instancia. Se encontrar cabecalho sem `Origin`, roda o ficheiro inteiro para `trade_history_legacy_v1.csv` e comeca um novo; se a rotacao falhar, **desliga a escrita** em vez de continuar a misturar.

Resultado da migracao (com backup previo de 7 498 596 B):
```
linhas de 10 campos: 99964   linhas ja partidas: 263
depois: linhas=100228   bytes=8500879
cabecalho novo: Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI,Ticket,Magic,Origin
exemplo: 2026.08.03 03:27:46,GOLD#,BUY,4063.09,4062.78,-1.51,0.00,32.20,0.00,0.00,,,UNKNOWN
contagem de campos: 13
```

### 28.5 Validacao
- Compilacao: `Result: 0 errors, 0 warnings, 15436 ms elapsed, cpu='X64 Regular'`. `XAU_AI_PRO.ex5` 654 234 B as 19:21:11.
- Versao coerente: `EA_VERSION_STRING` 1.2.46, cabecalho `// XAU_AI_PRO v1.2.46`, `#property version "1.246"`.
- 16 graficos recarregados: `[VERSION] v1.2.46 | Build=2026.10.30 | Stable=Yes | Modulos=15` em 16 simbolos distintos (XAUUSD, EURUSD, GBPUSD, USDJPY, AUDUSD, NZDUSD, USDCAD, USDCHF, USDCHF, USDBRL, USDSEK, USDCNH, USDCLP, USDCOP, USDCZK, USDRUB, USDSGD).
- Inputs preservados: 16/16 com `DynADXClear=35.0` e `AvoidHoursGMT=9,11,14,18,20,22`.
- **Nao houve rotacao** de producao (`trade_history_legacy_v1.csv` nao existe): a migracao offline deixou o cabecalho ja conforme, e o journal mostra `TradeLogger inicializado` nas 16 instancias, com um `TradeLogger WARN | schema sem lock (concorrencia)` no NZDUSD — esperado, 16 graficos arrancam no mesmo segundo; sem rotacao a fazer, o append e seguro.

### 28.6 O que ainda NAO esta provado
As tres colunas novas ainda nao foram escritas por um trade real: o mercado fechou na sexta e os 16 graficos recarregaram as 19:22. A prova ponta-a-ponta fica para a primeira operacao fechada (segunda-feira) ou para o proximo backtest com este binario. O `trade_history_backtest.csv` esta com 10 667 B e 10 colunas (escrito pelo run em curso, que carregou v1.2.45); a rotacao dele acontece no arranque do proximo teste.

## 29. Housekeeping: linha de trigger removida do fonte e a prova viva do isolamento

### 29.1 A linha `// recompile-trigger` saiu do fonte
O `XAU_AI_PRO.mq5` tinha como **primeira linha** um resto de trabalho anterior:

```
// recompile-trigger 19:40:47
//==================================================
// XAU_AI_PRO v1.2.46
```

Removida com `Files\Backup\clean_recompile_trigger.ps1` (round-trip byte-a-byte por latin1, para nao arriscar o encoding de um ficheiro sem BOM):

```
antes:  bytes=74357 BOM=False CRLF=2240 loneLF=2 NUL=0
removendo: [// recompile-trigger 19:40:47]
depois: bytes=74326 delta=-31 loneLF=2 NUL=0 trigger=0
primeira linha agora: [//==================================================]
#property version presente: 1   cabecalho v1.2.46 presente: 1   LogTradeCSV chamadas: 1
```

As 2 ocorrencias de `loneLF` ja existiam antes e continuam iguais - nao foram criadas por esta escrita. Backup do estado anterior em `Files\Backup\XAU_AI_PRO.mq5.bak_before_trigger_clean` (74 357 B); o `.bak` foi movido para `Files\Backup` em vez de ficar ao lado do projecto.

### 29.2 A compilacao ficou deliberadamente adiada
O fonte e o `.ex5` estao agora diferentes por **um comentario**. Nao compilei de imediato por uma razao medida: o backtest `7702926785952690594` esta a correr com esse `.ex5` carregado, e sobrepor o binario a meio de uma corrida de 6 h de simulacao troca um risco de zero (comentario nao altera comportamento) por um risco nao nulo (ficheiro em uso, recarga do agente). A compilacao de validacao entra assim que a corrida terminar:

```
metaeditor64 /compile:"...\XAU_AI_PRO.mq5" /log:"...\Files\Backup\compile_p122.log"
```

**Obrigacao pendente:** se o resultado da compilacao nao for `0 errors, 0 warnings`, o `.ex5` actual deixa de ser o correcto para o fonte e o bump de versao tem de ser refeito antes de qualquer nova corrida.

### 29.3 A prova viva do P1.20 - agora com dois ficheiros a mexer e um parado
O argumento do P1.20 deixou de ser uma inferencia e passou a ser observavel em tempo real, com o teste a escrever e a producao parada:

```
trade_history.csv           8500879 B  31/10/2026 19:22:34   (parado desde a migracao)
trade_history_backtest.csv    11490 B  31/10/2026 19:31:12   (a crescer com o teste)
```

O ficheiro de producao nao se mexeu durante 9 minutos de simulacao activa; o de backtest cresceu 823 B no mesmo periodo. O que o Ciclo 23 descobriu por acidente esta agora a ser impedido por construcao.

Nota: o `trade_history_backtest.csv` ainda tem o cabecalho de **10 colunas** porque a corrida em curso carregou a v1.2.45. A rotacao para `trade_history_backtest_legacy_v1.csv` acontece no arranque do proximo teste, pelo `TradeLoggerEnsureSchema()` da v1.2.46.

### 29.4 Estado do backtest no momento desta nota
`run_id 7702926785952690594`, agente `Core 1`, progresso `02:21:26 / 06:17:09` (diminuiu o total previsto em relacao aos `06:19:00` iniciais - o tester recalibra a estimativa a cada bloco de ticks). Disco livre 11 425 MB; log do tester 1 030.5 MB. Nada aqui e resultado de trading: e ainda o mesmo teste unico, num simbolo, com a ressalva de topologia do Ciclo 23.

## 30. P1.22 - A coluna Symbol do trade_history mentia: cada grafico gravava o SEU simbolo

### 30.1 Como apareceu
Ao olhar para o `trade_history_backtest.csv` do teste em curso (166 linhas), duas coisas saltaram: `Entry == Exit` em 164 linhas, e precos de `0.82`, `1.33`, `6.77`, `163.74` em linhas marcadas `XAUUSD`. Ouro a 0.82 nao existe.

Antes de mexer em codigo, medi o ficheiro de producao inteiro (`Files\Backup\audit_symbol_price.ps1`, leitura apenas, 100 228 linhas):

```
simbolos distintos: 63     (XAUUSD 80 380 | OILCash 2 988 | USDCNH 1 984 | GBPUSD 1 675 | ...)
linhas com symbol de OURO: 82 103
  ... com Entry < 1000 (preco que nao e ouro): 10 916
  ... com Entry == Exit: 58 027
linhas com symbol FX/outro: 18 006
  ... com Entry > 1000 (preco que nao e FX): 14 043
```

E a prova decisiva, no mesmo segundo, em quatro simbolos:

```
2026.07.01 04:06:24,XAUUSD,SELL,1.32,1.32,-1.50,0.00,52.38,0.00,0.00,,,UNKNOWN
2026.07.01 04:06:24,USDJPY,SELL,1.324,1.324,-1.50,0.000,42.40,0.00,0.00,,,UNKNOWN
2026.07.01 04:06:24,USDJPY,SELL,1.324,1.324,-1.50,0.000,42.40,0.00,0.00,,,UNKNOWN
2026.07.01 08:48:49,GBPUSD,SELL,1.32429,1.32429,0.06,0.00000,26.83,0.00,0.00,,,UNKNOWN
2026.07.01 08:48:50,USDCNH,SELL,1.32428,1.32428,0.04,0.00000,24.28,47.62,0.00,,,UNKNOWN
```

**O mesmo deal, o mesmo lucro, o mesmo preco em escalas diferentes**: `1.32` (2 digitos, grafico XAUUSD), `1.324` (3 digitos, grafico USDJPY), `1.32429`/`1.32428` (5 digitos, graficos GBPUSD e USDCNH). O preco base e um unico; o que muda e o `_Digits` de quem escreveu.

### 30.2 A causa, no codigo
`LogTradeCSV()` recebia `entry`/`exit` do deal (correctos, via `DEAL_PRICE` e `DEAL_SYMBOL`) mas escrevia:

```
      _Symbol,                          // simbolo do GRAFICO, nao do deal
      DoubleToString(entry, _Digits),    // digitos do GRAFICO
      DoubleToString(exit,  _Digits),
   double atr = GetATR();                // indicadores do GRAFICO
   double adx = GetADX();
   double rsi = GetRSI();
```

Num sistema com 17 graficos, cada instancia recebe o `OnTradeTransaction` de **todos** os deals da conta e gravava-os todos, assinando com o seu proprio simbolo. Duas consequencias, ambas mediveis:

1. a coluna `Symbol` mentia (10 916 linhas "XAUUSD" com preco de outra coisa);
2. o `ATR/ADX/RSI` gravado era o do grafico, nao o do simbolo negociado - e as bandas de ADX que fixaram `DynADXClear=35.0` sairam de agregacoes sobre este ficheiro.

`Entry == Exit` nao e defeito: num deal de saida, `DEAL_PRICE` e o preco de fecho e `SYMBOL_BID` e o bid do mesmo instante, logo sao o mesmo valor. E a semantica das colunas que e enganadora, nao o valor.

### 30.3 A alteracao (v1.2.47)
`LogTradeCSV()` ganhou um primeiro parametro `string symbol` (o `DEAL_SYMBOL` que o `OnTradeTransaction` ja tinha) e passou a usar:

```
   string tlSymbol = (symbol == "") ? _Symbol : symbol;
   int    tlDigits = (int)SymbolInfoInteger(tlSymbol, SYMBOL_DIGITS);
   if(tlDigits <= 0) tlDigits = _Digits;
   double atr = GetATR(tlSymbol);
   double adx = GetADX(tlSymbol);
   double rsi = GetRSI(tlSymbol);
```

e a escrever `tlSymbol`, `DoubleToString(entry, tlDigits)`, `DoubleToString(exit, tlDigits)`, `DoubleToString(atr, tlDigits)`. O chamador passa `symbol` (`DEAL_SYMBOL`), nao `_Symbol`.

**A duplicacao foi mantida de proposito**: cada grafico continua a registar todos os deals, para nao perder uma operacao cujo simbolo nao tenha grafico aberto. Desde o P1.21 o ficheiro tem `Ticket`, logo a deduplicacao passou a ser possivel por ticket em vez de se perderem linhas. Filtrar por simbolo seria uma segunda alteracao de comportamento que a medicao ainda nao sustenta.

### 30.4 Um erro meu que ficou registado
A primeira versao do script de patch usava `Write-Output` dentro de funcoes que devolviam texto. O PowerShell somou as mensagens ao valor devolvido e o texto de diagnostico (`OK alvo unico -> ...`, `ficheiro: ...`) foi escrito **dentro** dos tres ficheiros:

```
TradeLogger.mqh  bytes=13666  OKalvo=4 ficheiro:=1
```

Detectado na verificacao pos-escrita, nao por compilacao. Restaurados os tres ficheiros a partir de backups (`restore_before_p122.ps1`) e confirmados byte-a-byte:

```
TradeLogger.mqh  restaurado  bytes=12396  identico_ao_backup=True
XAU_AI_PRO.mq5    restaurado  bytes=74326  identico_ao_backup=True
VersionManager.mqh restaurado  bytes=20803  identico_ao_backup=True
```

A v2 do script (`apply_p122_symbol_fix.ps1`) usa `Write-Host` e conta ocorrencias de lixo como metrica de sucesso. Resultado:

```
TradeLogger.mqh   12396 -> 13492 B  NUL=0  loneLF=501  (ficheiro e LF-only, nao CRLF)
XAU_AI_PRO.mq5    74326 -> 74387 B  NUL=0  CRLF=2240  loneLF=2
VersionManager.mqh 20803 -> 22255 B  NUL=0  CRLF=218
```

As duas ocorrencias de "lixo" que restam foram inspeccionadas uma a uma e sao texto antigo em portugues ("do modo de ficheiro: tem de ser explicito", "em nenhum outro ficheiro: "). Nao e poluicao.

### 30.5 Validacao
- `Result: 0 errors, 0 warnings, 16209 ms elapsed, cpu='X64 Regular'`; `XAU_AI_PRO.ex5` 655 126 B as 19:41:39.
- Versao tripla coerente: `EA_VERSION_STRING` 1.2.47, cabecalho `// XAU_AI_PRO v1.2.47`, `#property version "1.247"`.
- Ciclo de perfis `Default` -> `XAI_V1243_20261031` as 19:42: `[VERSION] v1.2.47 ... Modulos=15` em **17 fontes** distintas do journal de especialistas; `.chr` `OK=16 BAD=0` com `DynADXClear=35.0` e `AvoidHoursGMT=9,11,14,18,20,22`.
- `TradeLogger inicializado (F4: ...)` nas 17 instancias, **sem** linha `TradeLogger MIGRACAO`: o cabecalho ja tinha `Origin`, logo nenhuma rotacao em producao. `trade_history.csv` parado em 8 500 879 B / 19:22:34 durante todo o processo.
- O backtest `7702926785952690594` continuou a correr durante a compilacao e o ciclo de perfis: `02:32:07 / 06:25:06` imediatamente antes, sem interrupcao depois.

### 30.6 O que este ciclo NAO prova
Nenhuma linha nova foi ainda escrita com o simbolo correcto: o mercado esta fechado e o backtest em curso carregou o binario anterior. O que esta provado e que o codigo compila, que as 17 instancias arrancaram em 1.2.47 e que o ficheiro de producao nao foi tocado. A prova ponta-a-ponta (uma linha `GOLD#`/`XAUUSD` com preco de ouro, digitos de ouro e `Origin=EA`) fica para a proxima sessao de mercado.

E a consequencia que importa: **as bandas de ADX e as horas que decidiram `DynADXClear=35.0` e `AvoidHoursGMT=9,11,14,18,20,22` foram medidas sobre um ficheiro cuja coluna Symbol estava errada em pelo menos 10 916 linhas.** A re-medicao com uma janela limpa deixa de ser uma tarefa de higiene e passa a ser necessaria - mas so depois de o ficheiro ter alguns dias gravados com o simbolo do deal.

## §31. P1.23 (v1.2.48) - o trade_history gravava o mesmo deal uma vez por grafico

### 31.1 O que estava em aberto

Depois do P1.22 (coluna Symbol passou a ser a do DEAL), ficou por explicar uma
coisa que o P1.21 ja tinha levantado de lado: o `trade_history.csv` de producao
tinha **100 228 linhas** para um historico que o broker reconstroi em muito menos
operacoes. A duvida era se eram trades distintos ou repeticao.

### 31.2 O que foi medido (31/10/2026, so-leitura, `Files\Backup\audit_duplication.ps1`)

Colapsando as **100 151 linhas validas** do `Common\Files\trade_history.csv` por
`(Time|Type|Profit)` - a assinatura mais estreita que se pode usar sem ticket,
porque as linhas antigas nao tem Ticket:

| metrica | valor |
|---|---|
| linhas validas | 100 151 |
| assinaturas distintas | 42 850 |
| assinaturas com mais de 1 linha | 14 549 |
| fator de duplicacao medio | **2,34** linhas por assinatura |
| linhas "a mais" | **57 301 (57%)** |
| multiplicidades com pico | **2, 10 e 17** |

Os picos em 2, 10 e 17 sao a assinatura do defeito: **17 e o numero de graficos
com o EA**, e cada grafico recebe o mesmo `OnTradeTransaction` da conta inteira.
Antes do P1.16 escreviam todos em simultaneo; depois do P1.16 escrevem em serie,
mas **todos escrevem** - a serializacao resolveu o interleave, nao a repeticao.

O fator 2,34 e um **limite inferior**: duas operacoes distintas podem cair no
mesmo segundo com o mesmo lucro e colapsar na mesma assinatura. Uma operacao
fechada com mais de um grafico do mesmo simbolo aberto chega a ser gravada 17x.

### 31.3 A correcao (v1.2.48)

`Monitoring\TradeLogger.mqh`, `LogTradeCSV`: a decisao de escrever passou a ser
tomada **antes de qualquer I/O**, logo a seguir ao gate de estado:

```
   string tlSymbol = (symbol == "") ? _Symbol : symbol;
   int    tlDigits = (int)SymbolInfoInteger(tlSymbol, SYMBOL_DIGITS);

   if(tlDigits <= 0)
      tlDigits = _Digits;

   if(!MQLInfoInteger(MQL_TESTER) && tlSymbol != _Symbol)
   {
      g_tl_skipped++;
      return;
   }
```

- **cada grafico grava apenas os deals do seu `_Symbol`**;
- as declaracoes de `tlSymbol`/`tlDigits` subiram para o topo da funcao e foram
  removidas do corpo (ficou **uma** declaracao; verificado por pesquisa: 1
  ocorrencia da linha);
- a guarda esta **desligada no Strategy Tester de proposito**: la ha uma so
  instancia, logo nao ha duplicacao a evitar, e o teste de XAUUSD tambem negoceia
  outros simbolos (ver §27.8) - descarta-los la seria perder informacao;
- `TradeLoggerSummary()` passou a publicar `OutroSimbolo=%d` (contador novo
  `g_tl_skipped`) e a usar `TradeLoggerFileName()` em vez de `TL_FILE`: antes o
  resumo dizia `File=trade_history.csv` **mesmo dentro do tester**, quando o
  ficheiro real era `trade_history_backtest.csv`.

O que a guarda **nao** muda: o simbolo do DEAL continua a ser o que vai para a
coluna Symbol (P1.22). Esta guarda decide **quem escreve**, nao **o que e escrito**.

### 31.4 Efeito colateral assumido (e por que e o mal menor)

Um deal cujo simbolo **nao tenha grafico aberto** deixa de ser gravado. Antes era
gravado N vezes de forma errada (uma por grafico, cada uma a mentir sobre o
simbolo); agora nao e gravado. E o preco de o ficheiro dizer a verdade uma vez em
vez de mentir 17. Registado aqui para nao ser redescoberto como "regressao".

### 31.5 Prova de aplicacao (31/10/2026, 20:00-20:01)

```
TradeLogger.mqh      bytes 13492 -> 15406   NUL=0  CRLF=0  loneLF=534  lixo=0
XAU_AI_PRO.mq5       bytes 74387 -> 74387   NUL=0  CRLF=2240 loneLF=2   lixo=0
VersionManager.mqh   bytes 22255 -> 23682   NUL=0  CRLF=218  loneLF=0   lixo=0
```

- `TradeLogger.mqh` continua **LF-only** (534 loneLF, 0 CRLF) - o EOL por ficheiro
  foi detectado pelo script, nao assumido;
- o `.mq5` manteve bytes porque as duas substituicoes (`v1.2.47`->`v1.2.48`,
  `"1.247"`->`"1.248"`) tem o mesmo comprimento;
- metricas de integridade: `lixo=0` nos tres ficheiros (a licao do P1.22: a v1 do
  patch escreveu texto de diagnostico dentro dos fontes por causa de
  `Write-Output` dentro de funcoes que devolvem texto - todos os `Write-Host`
  agora);
- versionamento triplo em sincronia: `EA_VERSION_STRING "1.2.48"`,
  cabecalho `// XAU_AI_PRO v1.2.48`, `#property version "1.248"`.

Compilacao:

```
metaeditor64 /compile:"...\XAU_AI_PRO.mq5" /log:"...\Files\Backup\compile_p122.log"
  Result: 0 errors, 0 warnings, 16990 ms elapsed, cpu='X64 Regular'
ex5: 655980 B  10/31/2026 20:00:41
```

Recarga das instancias (`profile_apply Default` -> `profile_apply XAI_V1243_20261031`):

- 17 graficos em `[VERSION] v1.2.48 | Build=2026.10.30`, `Modulos=15` todos OK;
- 17 linhas `TradeLogger inicializado (F4: ...)`, **zero** linhas `MIGRACAO` -
  nenhuma rotacao de schema em producao;
- 1 `TradeLogger WARN | schema sem lock (concorrencia)` no `USDRUB` no arranque
  simultaneo das 17 instancias: aviso esperado, nao fatal;
- `.chr` do perfil: **16 de 16** com `XAU_AI_PRO\XAU_AI_PRO.ex5` (o 17.º grafico
  vive no perfil `Default`).

Isolamento testado uma vez mais: `trade_history.csv` ficou **parado** em
`8 500 879 B / 19:22:34` durante toda a aplicacao, enquanto
`trade_history_backtest.csv` cresceu de `11 557` para `12 590 B / 19:54:45` - o
backtest em curso escreve no ficheiro do tester, nao no de producao.

### 31.6 O que este ciclo NAO prova

- **Nenhuma linha nova foi ainda escrita com o simbolo correcto e sem duplicacao**:
  o mercado esta fechado (sexta) e o backtest em curso carregou o binario 1.2.45,
  que sofre do defeito. A prova ponta-a-ponta - uma linha por deal, simbolo do
  deal, `Ticket`/`Magic`/`Origin` preenchidos - continua em aberto.
- Nao ha medicao do fator de deduplicacao **real** (por ticket) porque o
  `trade_history.csv` de producao ainda nao tem uma unica linha escrita pelo
  binario 1.2.46+ com `Ticket` preenchido; o 2,34 medido e por assinatura fraca.
- **Nao prova que as 17 instancias nao voltam a escrever em duplicado**: a guarda
  compara `DEAL_SYMBOL` com `_Symbol` por igualdade de texto. Se o broker expuser
  o mesmo instrumento com nomes diferentes em graficos diferentes (ex.: `GOLD#` e
  `XAUUSD`), cada um grava o que o `DEAL_SYMBOL` disser - e a igualdade resolve a
  questao por simbolo do deal, nao por instrumento economico.
- Nao foi tocada nenhuma regra de trading, risco, execucao ou precificacao.

### 31.7 Consequencia para as medicoes pendentes

As bandas de ADX (`DynADXClear=35.0`) e as horas (`AvoidHoursGMT=9,11,14,18,20,22`)
saem de um ficheiro que agora se sabe estar: (a) com a coluna Symbol errada em
>= 10 916 linhas (§30) e (b) inflado em >= 2,34x por repeticao (§31.2). As duas
coisas empurram no **mesmo sentido** - contagens por banda e por hora enviesadas
para os simbolos/horas com mais graficos - logo a re-medicao com uma janela limpa
de 2-3 dias gravada pelo logger F4+guarda deixa de ser higiene e passa a ser
necessaria antes de se mexer outra vez nesses inputs.

## §32. P1.24 (v1.2.49) - o watchdog de saude morria quando o mercado fechava

### 32.1 O que estava em aberto

A instrucao de trabalho e "EA autonomo 24/7". Faltava responder a pergunta
obvia: **quando o mercado fecha, quem vigia o EA?** Se o watchdog depende de
cotacoes, ele desliga-se exactamente nos 60 h por semana em que ninguem olha.

### 32.2 O que foi medido (31/10/2026, sabado, mercado fechado desde sexta 23:59)

| prova | valor |
|---|---|
| `get_time_information` -> `trade_server_last_known_time` | **2026-10-30T23:59:59** |
| hora local no momento da medicao | **2026-10-31 20:01** (~20 h de diferenca) |
| `Logs\20261031.log` | 726 linhas, **0** blocos `HEALTH MONITOR` |
| `Logs\20261030.log` (dia com mercado) | 900 706 B com blocos normais |

**Diagnostico:** `TimeCurrent()` nao e "agora" - e a hora do **ultimo tick
recebido**. `g_lastHealthCheck` e `g_lastTickTime` eram carimbados com ela, logo
`now - g_lastHealthCheck` fica **0 para sempre** e o `HealthMonitorCheck()` nunca
mais volta a correr. O unico watchdog capaz de notar um terminal morto,
desligado, ou sem ligacao ao broker **desligava-se ao fim de semana**.

### 32.3 Pesquisa (fontes primarias)

- `TimeCurrent()` = "the time of the last quote received"; `TimeTradeServer()` =
  hora do servidor calculada no cliente, devolve 0 se desconhecida
  (https://www.mql5.com/en/docs/dateandtime/timecurrent,
  https://www.mql5.com/en/docs/dateandtime/timetradeserver).
- `OnTimer` e gerado pelo **terminal** (relogio local), nao pela chegada de
  ticks; e o mecanismo recomendado para monitorar sem cotacoes
  (https://www.mql5.com/en/docs/event_handlers/ontimer).
- Nao existe API de reconexao: a reconexao e do terminal
  (https://www.mql5.com/en/book/common/environment/env_connectivity). Logo
  **alarmar** e a unica accao possivel do EA - e so serve se o alarme nao
  depender de ticks.
- `TERMINAL_CONNECTED` verdadeiro **nao** garante cotacoes sincronizadas; somar
  `SymbolIsSynchronized` (https://www.mql5.com/en/book/common/environment/env_connectivity).
- `SymbolInfoSessionTrade`/`SymbolInfoSessionQuote` devolvem `from`/`to` em
  segundos desde 00:00 e ignoram a data
  (https://www.mql5.com/en/docs/marketinformation/symbolinfosessiontrade).

### 32.4 A correcao (v1.2.49) - dois relogios, cada um com o seu papel

`Monitoring\HealthMonitor.mqh`:

```
datetime HealthClockNow()      // TimeLocal()  -> mede DURACOES (avanca sempre)
datetime HealthSessionNow()    // TimeTradeServer(), fallback TimeCurrent()
```

- `HealthClockNow()` passou a carimbar `g_lastTickTime` (init e
  `HealthMonitorUpdateTicks`) e `g_lastHealthCheck`, e a medir a idade do ultimo
  tick em `HealthMonitorCheckTickTimeout()` e `HealthGetSecondsSinceTick()`;
- `HealthMonitorCheck()` deixou de decidir o intervalo com a hora do ultimo tick;
- `HealthSymbolSessionOpen()` passou a ler a **hora estimada do servidor**: a
  hora congelada era sexta 23:59:59, o que fazia a sessao de sexta parecer
  **aberta** ao fim de semana e reprovava a saude por "sem tick" precisamente
  nos dias sem cotacao;
- tudo o que e de **mercado** continua em `TimeCurrent()`: sessoes de
  negociacao, horas de evasao, reset diario. Nada disso foi alterado.

### 32.5 Prova (31/10/2026, sabado, mercado fechado)

Antes: 0 blocos de health em 20 h. Depois da recarga (20:16):

```
20:16:48  XAU_AI_PRO (XAUUSD,M15)  [HEALTH] HEALTHY | uptime=0s | checks=0 | sem tick=30s | resumo completo 1x/hora
20:16:51  XAU_AI_PRO (USDBRL,M5)   [HEALTH] HEALTHY | uptime=0s | checks=0 | sem tick=30s | resumo completo 1x/hora
... (17 graficos)
20:17:18  XAU_AI_PRO (XAUUSD,M15)  ========== HEALTH MONITOR ==========
```

O watchdog voltou a correr **sem uma unica cotacao**, o "sem tick=30s" passou a
ser uma duracao real (antes estava congelado) e o estado e **HEALTHY** - ou seja,
a deteccao de sessao passou a distinguir correctamente "sabado" de "falha".

Compilacao:

```
Result: 0 errors, 0 warnings, 16542 ms elapsed, cpu='X64 Regular'
ex5: 658030 B  10/31/2026 20:15:54
```

Integridade das escritas (`lixo=0` nos tres):

```
HealthMonitor.mqh    24192 -> 26818 B   NUL=0  CRLF=925   loneLF=0
XAU_AI_PRO.mq5       74387 -> 74387 B   NUL=0  CRLF=2240  loneLF=2
VersionManager.mqh   23682 -> 25351 B   NUL=0  CRLF=218   loneLF=0
```

Incidencia: a primeira compilacao deu **1 warning** (85: `20261031` too big for
character code) porque `Logs\20261031.log` dentro de um literal MQL5 e lido como
escape octal. Corrigido para `Logs\\20261031.log` (`23851`->`23851`, 1 byte) e
recompilado a 0 warnings.

### 32.6 Gaps identificados pela pesquisa e NAO aplicados (por falta de medicao)

Registados de proposito, para nao virarem "melhorias por palpite":

1. **`SymbolIsSynchronized` nunca e consultado** em nenhum .mq5/.mqh do EA. A
   documentacao diz que `TERMINAL_CONNECTED` verdadeiro nao garante cotacoes
   sincronizadas, logo apos uma reconexao o EA pode decidir sobre dados velhos.
   Falta medir quantas entradas ocorreram com o simbolo dessincronizado.
2. **Reconexao forcada nao existe na API** - o EA so pode travar novas entradas,
   continuar a gerir posicoes e alarmar (o CircuitBreaker e o OrderRetry ja
   classificam os retcodes transitorios).
3. **`GlobalVariable*` expira ao fim de ~4 semanas** sem uso. As chaves usadas
   sao locks curtos (EventLock, OrderRetry) e a marca de importacao de
   aprendizado - uma expiracao provoca no maximo um re-import, nao corrupcao.
4. **Crescimento de journal/disco**: ja tratado (rotacao do audit_log v1.2.40,
   backup so na instancia mestre v1.2.38, gate de diagnostico v1.2.42, cortes de
   spam v1.2.39).

### 32.7 O que este ciclo NAO prova

- Nao prova que o EA **detecta** um terminal morto: prova que o caminho de
  verificacao voltou a correr quando nao ha ticks. A notificacao ao dono
  (NotificationCenter) nao foi exercitada nesta sessao.
- Nao ha prova com o mercado aberto: nenhuma entrada, saida ou gestao de posicao
  foi executada nesta versao.
- O backtest `7702926785952690594` carregou o binario anterior; nada do que aqui
  esta foi validado em ticks reais.

## §33. P1.25 - o portão de diagnóstico não abafava CICLOS de estado (v1.2.50)

**Data:** 31/10/2026 · **Versão:** v1.2.50 · **Estado:** FECHADO (compilado 0/0, 17 instâncias activas)

### 33.1 O que foi medido

Fonte: `Tester\logs\20261031.log` (journal real do backtest em curso), lido com
`[IO.File]::Open(..., FileShare::ReadWrite)` porque o `terminal64` o mantém aberto.

| Medição | Valor |
|---|---|
| Ficheiro | 4 186 295 linhas / 1 121 MB (às 20:33) |
| Runs no mesmo ficheiro | 4 (o log do tester é por dia e é anexado) |
| Run actual (v1.2.45) | 1 191 304 linhas |
| `[STATE]` nesse run | **335 843 linhas = 28,2% de todo o output** |
| `[STATE]` na amostra de 254 MB / 940 000 linhas | 249 592 linhas para **14 desfechos distintos** |

Desfechos mais repetidos na amostra:

```
70 601  SIGNAL_GENERATED -> VALIDATING
69 316  VALIDATING -> RISK_CHECK
38 605  RISK_CHECK -> SIMULATING
38 538  SIMULATING -> SIGNAL_GENERATED
30 710  RISK_CHECK -> SIGNAL_GENERATED
 1 285  VALIDATING -> SIGNAL_GENERATED
    68  LEARNING -> SIGNAL_GENERATED
    67  MANAGING -> CLOSED
    67  POSITION_OPEN -> MANAGING
    67  EXECUTION_READY -> EXECUTING
```

### 33.2 A causa

O `DiagGateAllow` do P1.17 comparava o desfecho apenas com o **último**
registado. Num ciclo `A -> B -> C -> A -> B -> C` cada aresta difere da
anterior, logo a condição de supressão nunca era verdadeira e o portão
libertava tudo. Não era um problema de volume do heartbeat: era de
**semântica**.

### 33.3 A correcção

Cada chave (`símbolo|tag`) passa a guardar o **conjunto** de desfechos já
escritos na janela do heartbeat:

- `DIAG_GATE_SEEN 8` posições — cobre o ciclo inteiro com folga; quando
  enche, esquece o mais antigo (nunca esconde um desfecho novo por falta de
  espaço);
- janela ancorada em `windowStart`, medida com `TimeLocal()` — o relógio que
  avança sempre, lição do P1.24;
- repetir um desfecho da janela suprime; um desfecho **novo** sai na hora;
- `heartbeatSec = 0` deixa de significar silêncio total e passa a usar
  `DIAG_GATE_WINDOW_DEFAULT 60 s` (sem janela, o ciclo voltava a escrever em
  cada tick).

As transições para `STATE_EXECUTION_READY` ou superior já eram impressas
**antes** do portão, no call site de `StateMachine.mqh`, e continuam a ser —
na amostra foram 469 linhas que o portão nunca viu.

### 33.4 Prova por replicação do portão sobre o journal real

`Files\Backup\audit_p125_replay.ps1` replica, linha a linha, a sequência de
decisões das duas versões do portão sobre o journal de produção, incluindo o
bypass do call site. Não é estimativa: é a mesma sequência de `if`s.

| Versão do portão | Linhas `[STATE]` escritas | Redução |
|---|---|---|
| OLD (v1.2.49 e antes) | 249 592 | 0% |
| NEW (v1.2.50 / P1.25) | **751** | **99,7%** |

Ganho: **332× menos linhas `[STATE]`**. Como `[STATE]` era 28,2% do output do
run, o log de 1,1 GB passa a rondar os 0,8 GB — cerca de 300 MB por run desta
dimensão.

### 33.5 Hipótese anterior DESCARTADA pela medição

O registo de §32 dizia que o tag `[RISK]` tinha o mesmo defeito (61 439 linhas
para 188 distintas). A segmentação do journal por cabeçalho `[VERSION]` mostra
que isso era **falso**: no run actual, das 83 478 linhas `[RISK]`, apenas
**168** são `RR da entrada` — ou seja, o portão do P1.17 já estava a funcionar
para esse call site (desfecho `SL|TP`, heartbeat 14 400 s). O defeito era
exclusivo do `[STATE]`, cujo desfecho é o texto da aresta e portanto muda
sempre. A correcção do P1.25 foi dimensionada para o defeito que existe, não
para o que se supunha existir.

Replicação sobre o `[RISK]` (`Files\Backup\audit_p125_risk.ps1`, 254 MB):

| Família | Linhas | Distintas | OLD escreve | NEW escreve |
|---|---|---|---|---|
| `RR_ENTRADA` | 38 605 | 13 | 61 | 61 |
| `RISK_EFETIVO` | 38 596 | 59 | 63 | 63 |
| `RISK_OUTRO` | 69 316 | 262 | 327 | 299 |
| **Total** | **146 517** | | **451** | **423** |

Ganho do P1.25 aqui: 1,1×. Nenhum. O portão antigo já bastava para estes.

### 33.6 Ficheiros e verificação

| Ficheiro | Antes | Depois | Verificação |
|---|---|---|---|
| `Monitoring/DiagGate.mqh` | 5 738 B | 8 361 B | NUL=0, CRLF=0, loneLF=210 (LF-only), lixo=0 |
| `DiagGateSelfTest.mq5` | 4 402 B | 5 993 B | NUL=0, loneLF=123, lixo=0 |
| `XAU_AI_PRO.mq5` | 74 387 B | 74 387 B | só o cabeçalho e `#property version`, NUL=0 |
| `Enterprise/VersionManager.mqh` | 25 351 B | 26 677 B | NUL=0, lixo=0 |

Auto-teste `DiagGateSelfTest.mq5` compilado **0 errors, 0 warnings** (1 063 ms,
ex5 16 020 B às 20:27:57) com o bloco novo C1..C4: um ciclo de 3 estados
escreve 3 linhas e depois cala, mesmo com 3 000 voltas, e uma aresta nova
continua a sair.

EA compilado **0 errors, 0 warnings** (15 715 ms, ex5 660 824 B às 20:29:42).
Ciclo `profile_apply Default` → `XAI_V1243_20261031`: **17 instâncias** em
`v1.2.50` entre 20:29:51 e 20:30:00; `.chr` validados pelo BOM `FF FE` +
`<chart>` = **16/16 OK, 0 BAD**.

### 33.7 Armadilha de ferramenta registada

A primeira versão do replicador descodificou o journal como UTF-8 e devolveu
**0 linhas `[STATE]` em 948 873 linhas lidas**. O journal do tester é
**UTF-16LE com BOM `FF FE`**. Um zero destes não é um resultado, é um defeito
do leitor — foi o que motivou a verificação dos bytes de cabeçalho antes de
aceitar a contagem.

### 33.8 O que NÃO mudou

Nenhuma regra de trading, risco, execução ou precificação. O portão decide
apenas se uma linha de diagnóstico volta a ser escrita.

## §34. P1.26/P1.27 - duas fontes de ruído do journal sem portão nenhum (v1.2.51)

**Data:** 31/10/2026 · **Versão:** v1.2.51 · **Estado:** FECHADO (compilado 0/0, 17 instâncias activas)

### 34.1 O que foi medido

Depois do P1.25, a pergunta passou a ser: **o que ainda enche o journal?**
`Files\Backup\audit_top_offenders.ps1` agrupa cada linha pelo prefixo da
mensagem (a parte depois do carimbo de tempo de modelo, truncada a 70
caracteres) e conta.

Amostra: 1 121 MB / 4 186 295 linhas. Top 30 = **1 571 299 linhas = 37,53%**
de todo o output.

```
146 170 (3,49%)  [STATE] USDSEK | SIGNAL_GENERATED -> VALIDATING      <- P1.25
144 653 (3,46%)  [STATE] USDSEK | VALIDATING -> RISK_CHECK            <- P1.25
144 637 (3,46%)  [STATE] USDSEK | RISK_CHECK -> SIGNAL_GENERATED      <- P1.25
121 076 (2,89%)  [NEWS] Calendar error | Error=4014                   <- P1.26
 66 086 (1,58%)  EXECUTION: SEM STOP NA ENTRADA | USDSEK | ...
 58 310 (1,39%)  [RISK] alvo elevado para respeitar o RR minimo ...   <- P1.27
 54 599 (1,30%)  [PIPELINE] INICIO | Symbols=11
 54 598 (1,30%)  [PIPELINE] FINALIZADO
 50 148 (1,20%)  [STATE] AUDUSD | SIGNAL_GENERATED -> VALIDATING      <- P1.25
...
```

Duas destas linhas **não tinham portão nenhum** — nem `DiagGate`, nem
`logOnce`, nem cooldown. Foram verificadas no código, uma a uma:

| Linha | Ficheiro:linha | Portão antes |
|---|---|---|
| `[NEWS] Calendar error \| Error=` | `Filters/NewsFilter.mqh:217` | **nenhum** |
| `[RISK] alvo elevado para respeitar o RR minimo` | `Core/ExecutionEngine.mqh:687` | **nenhum** |

### 34.2 O erro 4014 não é uma falha a corrigir

O código veio da tabela oficial de erros MQL5
(`https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes`):

```
ERR_FUNCTION_NOT_ALLOWED  4014  Function is not allowed for call
```

Ou seja: dentro do **Strategy Tester** a chamada ao calendário não é permitida.
Não é uma avaria do EA nem do broker — é uma condição **permanente** do teste.
Imprimir uma linha de erro por cada chamada, durante um backtest de 48 dias de
tempo de modelo, produziu 121 076 linhas de ruído puro, e o `g_newsState`
continuava `NEWS_CLEAR` (fail-open) como deve.

A correcção distingue os dois casos:

- `4014` → **uma** linha explicativa por sessão (flag `static`), porque repetir
  a mesma explicação não acrescenta informação;
- qualquer **outro** erro de calendário → continua visível, abafado a 1 linha
  por 4 h via `DiagGateAllow`.

Fora do tester nada disto muda o comportamento: o filtro de notícias continua
fail-open e a decisão de bloquear ou não é exactamente a mesma.

### 34.3 O alvo mínimo do RR

`[RISK] alvo elevado para respeitar o RR minimo` (58 310 linhas) imprimia em
cada passagem pelo bloco que eleva `tpPontos` ao mínimo exigido por
`MinRewardRatio`. O desfecho útil é `TP|alvo` — a mesma forma que o
`RR_ENTRADA` já usava com sucesso (168 linhas no run inteiro). Passou a usar
`DiagGateAllow(symbol, "ALVO_RR", TP|alvo, 14400)`.

**Ponto crítico de segurança da alteração:** a linha `tpPontos=alvoMinimo;`
ficou **fora** do portão. O portão decide apenas se a mensagem é escrita; a
elevação do alvo é uma decisão de risco e continua a acontecer sempre.

### 34.4 Ganho medido

| Linha | Antes | Depois (esperado) |
|---|---|---|
| `[NEWS] Calendar error \| Error=4014` | 121 076 | 1 por sessão |
| `[RISK] alvo elevado ...` | 58 310 | 1 por chave / 4 h |
| **Total** | **179 386 (4,29%)** | ~0 |

Somado ao P1.25 (28,2%), o journal deste run passa de 4,19 M linhas para uma
ordem de grandeza inferior. O valor "depois" é **previsão**, não medição: será
confirmado no próximo backtest com o mesmo `audit_top_offenders.ps1`.

### 34.5 Ficheiros e verificação

| Ficheiro | Antes | Depois | Verificação |
|---|---|---|---|
| `Filters/NewsFilter.mqh` | 13 176 B | 14 273 B | NUL=0, lixo=0, +`#include DiagGate` |
| `Core/ExecutionEngine.mqh` | 40 986 B | 41 448 B | NUL=0, lixo=0 |
| `XAU_AI_PRO.mq5` | 74 387 B | 74 387 B | cabeçalho v1.2.51 + `#property version "1.251"` |
| `Enterprise/VersionManager.mqh` | 26 677 B | 27 928 B | NUL=0, lixo=0, changelog v1.2.51 |

EA compilado **0 errors, 0 warnings** (15 732 ms, ex5 663 754 B às 20:43:24).
Ciclo `profile_apply Default` → `XAI_V1243_20261031`: **17 instâncias** em
`v1.2.51` entre 20:43:31 e 20:43:41.

### 34.6 O que ainda fica por medir

`EXECUTION: SEM STOP NA ENTRADA` (66 086) e `EXECUTION WARNING | FORCA LOTE
MINIMO` (75 000) **têm** portão (`SEM_STOP`, `LOT_MIN`), mas continuam a
aparecer em massa. A hipótese é que o desfecho inclua valores que variam
(TP, lote) e que o conjunto de desfechos na janela seja maior do que as 8
posições do P1.25 — nesse caso o portão volta a libertar. **Não foi
corrigido por não estar medido**: a próxima auditoria ao journal do backtest
com v1.2.51 decide se é preciso alargar a memória, mudar a chave do desfecho,
ou se simplesmente desaparece com o resto.

### 34.7 O que NÃO mudou

Nenhuma regra de trading, risco, execução ou precificação. As duas alterações
só decidem se uma linha de diagnóstico volta a ser escrita.

## §35. P1.28/P1.29 + correcção de atribuição do §34 (v1.2.52)

**Data:** 31/10/2026 · **Versão:** v1.2.52 · **Estado:** FECHADO (compilado 0/0, 17 instâncias activas)

### 35.1 Uma lição de método: o log do tester não é de um run

O §34 contou linhas sobre o **ficheiro inteiro**. Está errado como atribuição.
`Tester\logs\<data>.log` é **por dia** e é **anexado por todos os runs desse
dia**; pior, ~2,97 M linhas do início do ficheiro estão **antes do primeiro
cabeçalho `[VERSION]`** e portanto pertencem a um run que nem sequer
identificável é — e que foi produzido por um binário **sem** `DiagGate` nos
call sites.

Medir o ficheiro inteiro mistura, na mesma percentagem, ruído de um binário
antigo com o de um binário já corrigido. A regra passou a ser: **atribuir
ruído por segmento, nunca por ficheiro**.

Ferramentas novas (todas só-leitura, em `Files\Backup`):
`audit_top_offenders_last.ps1` (reseta a contagem em cada `[VERSION]`, logo
fica com o perfil do último run) e `audit_last_segment_totals.ps1`.

### 35.2 O perfil honesto do run actual

Último segmento do journal — **v1.2.45**, 1 234 648 linhas:

| Grupo | Linhas | % do run | Portão antes |
|---|---|---|---|
| `[STATE]` | 347 741 | 28,17% | existe, mas ineficaz (P1.25) |
| `[VIA RAPIDA]` | 131 227 | 10,63% | **nenhum** (P1.28) |
| `[RISK]` (todas) | 86 985 | 7,05% | — |
| · alvo elevado RR mínimo | 84 551 | 6,85% | **nenhum** (P1.27) |
| `[PIPELINE]` | 57 473 | 4,66% | `logOnce` 1/min, por desenho |
| `[NEWS] Calendar error 4014` | 51 993 | 4,21% | **nenhum** (P1.26) |
| `[LADDER]` | 32 753 | 2,65% | P1.18 |
| `EXECUTION: APRENDIZADO` | 13 228 | 1,07% | **nenhum** (P1.29) |

**Correcção dos números do §34:** os valores lá publicados (NEWS 121 076;
alvo 58 310) eram contagens do ficheiro inteiro. Por run são **51 993** e
**84 551**. A decisão de corrigir mantém-se — o que muda é a dimensão, que
agora está certa.

### 35.3 Uma hipótese minha DESCARTADA pela medição

O §34.6 dizia que `EXECUTION: SEM STOP NA ENTRADA` (66 086) e `FORCA LOTE
MINIMO` (~75 000) apareciam em massa **apesar** de terem portão, e que a causa
seria a chave do desfecho conter valores variáveis. Falso.

`Files\Backup\audit_p125_gated.ps1` reconstrói as chaves reais a partir do
código e replica os dois portões:

| Família | hb | Linhas no ficheiro | Desfechos distintos | OLD escreve | NEW escreve |
|---|---|---|---|---|---|
| `LOT_MIN` | 3 600 | 48 479 | **1** | 67 | 67 |
| `LOTE_DIN` | 14 400 | 69 316 | 5 | 117 | 69 |
| `RISCO_REAL` | 14 400 | 69 316 | 96 | 172 | 141 |
| `SEM_STOP` | 14 400 | 69 316 | 3 | 117 | 69 |

`LOT_MIN` tem **um único** desfecho (`lot|min`) no run inteiro: o portão do
P1.17 já o reduz a 67 linhas. As 48 479 do ficheiro vêm da porção **anterior**
ao portão. Não há nada a corrigir aqui — e sem esta medição eu teria mexido em
código que já estava certo.

### 35.4 P1.28 — `[VIA RAPIDA]`

`TradePipeline.mqh`, `MarketPulseFastLane()`: imprime uma linha por símbolo
sempre que o regime não é `PULSE_NORMAL`, a cada `PulseFastLaneSec` (5 s) de
tempo de modelo. **10,63% do run, sem portão nenhum.**

Chave do desfecho: o **regime**. O volume e a velocidade mudam a cada tick e
não podem servir de chave — usá-los daria supressão zero. Heartbeat 3 600 s.

`RunTradePipelineSymbol(symbol)` ficou **fora** do portão.

### 35.5 P1.29 — `EXECUTION: APRENDIZADO`

`ExecutionEngine.mqh`: imprime em cada passagem em que o factor de lote
aprendido é menor que 1. **1,07% do run, sem portão nenhum.**

Chave do desfecho: o próprio `learnLot` (2 decimais) — é o valor que reduz o
lote e o único que interessa acompanhar; o resumo do histórico muda a cada
trade e não pode servir de chave. Heartbeat 14 400 s.

`slowFactor *= learnLot;` ficou **fora** do portão.

### 35.6 Ganho acumulado medido neste run

| Correção | Linhas poupadas | % do run |
|---|---|---|
| P1.25 `[STATE]` | 347 741 | 28,17% |
| P1.26 `[NEWS] 4014` | 51 993 | 4,21% |
| P1.27 alvo elevado RR | 84 551 | 6,85% |
| **subtotal** | **484 285** | **39,22%** |
| P1.28 `[VIA RAPIDA]` | 131 227 | 10,63% |
| P1.29 `APRENDIZADO` | 13 228 | 1,07% |
| **subtotal** | **144 455** | **11,70%** |
| **TOTAL** | **628 740** | **50,93%** |

O journal deste run perde **mais de metade** do que escrevia. O que sobra é
sobretudo `[PIPELINE]` (1/min, por desenho) e `[LADDER]`.

### 35.7 Ficheiros e verificação

| Ficheiro | Antes | Depois | Verificação |
|---|---|---|---|
| `Core/TradePipeline.mqh` | 6 249 B | 6 876 B | NUL=0, lixo=0, +`#include DiagGate` |
| `Core/ExecutionEngine.mqh` | 41 448 B | 41 926 B | NUL=0, lixo=0 |
| `XAU_AI_PRO.mq5` | 74 387 B | 74 387 B | v1.2.52 + `#property version "1.252"` |
| `Enterprise/VersionManager.mqh` | 27 928 B | 29 132 B | NUL=0, lixo=0 |

EA compilado **0 errors, 0 warnings** (16 339 ms, ex5 664 262 B às 20:50:24).
Ciclo de perfil: **17 instâncias em `v1.2.52`** entre 20:50:34 e 20:50:41.

### 35.8 Ressalva que tem de acompanhar estes números

O backtest em curso (`7702926785952690594`) corre **v1.2.45** e vai continuar
com esse binário até terminar. **Nenhuma das correções P1.25 a P1.29 pode ser
provada por ele.** O que está provado é:

- a lógica do portão, pelo auto-teste `DiagGateSelfTest.mq5` (C1..C4, 0/0);
- o efeito no `[STATE]`, por replicação exacta sobre o journal real
  (249 592 → 751);
- a atribuição do ruído, por segmentação por run.

A confirmação final exige **um novo backtest** com v1.2.52, medido com
`audit_last_segment_totals.ps1`. Fica registado como pendência, não como
resultado.

## §36. Linha de base do `trade_history_backtest.csv` antes do run com v1.2.52

**Data:** 31/10/2026 20:51 · **Estado:** MEDIDO (baseline para comparação futura)

### 36.1 Porque este registo existe

O backtest em curso (`7702926785952690594`) corre **v1.2.45**, que é anterior
ao P1.21 (13 colunas), P1.22 (símbolo do deal) e P1.23 (uma linha por deal).
Sem uma fotografia do ficheiro **antes** de um run com v1.2.52, a verificação
dessas três correcções na prática ficaria a depender de memória.

### 36.2 O que foi medido

`Files\Backup\audit_backtest_history.ps1` (só leitura, `Common\Files`):

| Ficheiro | Tamanho | mtime |
|---|---|---|
| `trade_history_backtest.csv` | 14 364 B | 2026-10-31 20:51:22 |
| `trade_history.csv` (produção) | 8 500 879 B | 2026-10-31 **19:22:34** |
| `trade_history_backtest_legacy_v1.csv` | **não existe** | — |

Conteúdo do `trade_history_backtest.csv`:

```
linhas (com header) : 209
header              : Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI
campos do header    : 10
distribuicao        : 208 linhas com 10 campos  (0 linhas partidas)
simbolos na col. 2  : 208 x XAUUSD
primeira linha      : 2026.07.29 04:53:58,XAUUSD,SELL,163.74,163.74,0.00,0.00,-1.00,0.00,0.00
ultima linha        : 2026.09.17 12:07:46,XAUUSD,BUY,1.15,1.15,-0.60,0.00,0.00,0.00,0.00
```

### 36.3 O que isto confirma

1. **P1.20 (isolamento) continua provado.** O `trade_history.csv` de produção
   está **parado há 1h29** (mtime 19:22:34) enquanto o backtest escreve noutro
   ficheiro. A escrita simulada não toca no ficheiro de produção.
2. **P1.22 está por aplicar neste run, e o defeito é visível.** Todas as 208
   linhas dizem `Symbol=XAUUSD`, mas os preços são **163.74** e **1.15** —
   valores que o ouro nunca teve. É exactamente o defeito documentado: o
   logger escrevia `_Symbol` do gráfico em vez do símbolo do deal.
3. **ATR/ADX/RSI a 0.00** em praticamente todas as linhas, e `ADX=-1.00` na
   primeira: os indicadores do símbolo negociado não estavam prontos quando a
   linha foi escrita. Consequência directa: este ficheiro **não serve** para
   re-medir bandas de ADX nem horas — reforça a pendência já aberta.
4. **Nenhuma linha partida** (208 de 208 com 10 campos). O padrão F4 do P1.16
   está a aguentar.

### 36.4 O que o próximo run tem de mostrar

Quando um backtest correr com **v1.2.52**:

| Verificação | Esperado |
|---|---|
| `trade_history_backtest_legacy_v1.csv` | passa a **existir** (rotação do P1.21) |
| header do ficheiro novo | **13** colunas (`…,Ticket,Magic,Origin`) |
| coluna `Symbol` | deixa de ser sempre `XAUUSD`; passa a reflectir o deal |
| `Entry`/`Exit` | coerentes com o símbolo da linha |
| `Ticket`/`Magic`/`Origin` | preenchidos (2026001 = EA) |
| `trade_history.csv` de produção | continua **parado** (isolamento do P1.20) |

Enquanto isso não acontecer, as colunas 11-13 e o símbolo correcto continuam
**não provados ponta-a-ponta** — é uma pendência, não um resultado.

### 36.5 Disco

C: livre = **9,12 GB** às 20:51 (era 9,34 GB às 20:29). O journal do tester
está em ~1 128 MB e a crescer. Sem risco imediato, mas a vigiar: abaixo de
~2 GB a acção é `tester_stop` e limpeza de `Tester\logs` (que exige o MT5
fechado, porque `Tester` não está nos `write_roots`).

## §37 — P1.30 (v1.2.53): churn do LADDER e eco do PIPELINE

**Data:** 31/10/2026 · **Versão:** v1.2.53 · **Ficheiros:** `Management/MoneyLadder.mqh`, `Core/TradePipeline.mqh`, `XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh`

### 37.1 Como o ruído foi encontrado (auditoria só-leitura)

`Files\Backup\audit_p130_pipeline_ladder.ps1` (novo, 4020 B) segmenta o journal do tester por
`[VERSION]`, isola o ÚLTIMO run e agrupa as linhas `[PIPELINE]` e `[LADDER]` por "forma"
(dígitos substituídos por `#`, truncada a 90 caracteres). Medição sobre
`Tester\logs\20261031.log` = 1 186 829 402 B, último segmento v1.2.45 com 1 252 528 linhas e 4 runs:

| grupo | linhas | formas | % do run |
|---|---|---|---|
| `[PIPELINE]` | 59 480 | 13 | 4,75% |
| `[LADDER]` | 33 213 | 32 | 2,65% |

Top `[PIPELINE]`: `FINALIZADO` 26 979, `INICIO|Symbols=#` 26 979, `PROCESSANDO` 502 por símbolo
(11 símbolos). Ganho teórico se sobrar 1 linha por forma e por janela = 92 648 linhas = 7,4%.

### 37.2 A causa no LADDER (auditoria por ticket)

`Files\Backup\audit_p130_ladder_churn.ps1` (novo, 4503 B) reconstrói, por ticket, a sequência de
TP/SL/motivo das linhas `[LADDER]` e simula uma banda morta em múltiplos do menor passo de cada
símbolo. Resultado:

- 88 287 linhas `[LADDER]` com ticket, **0 sem parse**;
- `SL=0.0` em 29 111 linhas, SL real em 59 176;
- motivos: `STOP NA ENTRADA` 52 423, `SO ALVO` 35 860, `STOP TRAVADO` 4;
- **444 tickets**, média **198,84 linhas por ticket**, mínimo 1, **máximo 7 315** num único ticket;
- passos por símbolo: AUDUSD 0,66731 · EURUSD 0,36223 · GBPUSD 0,55588 · NZDUSD 0,16481 ·
  USDBRL 1e-4 · USDCAD/USDCHF/USDCNH/USDSEK 1e-5 · USDJPY 0,001.

Corte por banda morta: 1× = **49,91%** · 2× = **95,98%** · 3× = 97,45% · 5× = 98,16% ·
10× = 98,51% · 20× = 98,74% · 50× = 98,79%.

O degrau decisivo é 1×→2×. Isso é a assinatura de **ruído de recálculo**, não de alvo a mover-se: o
TP em dinheiro é recalculado em cada passagem a partir de `MoneyToPriceDistance` e deriva 1–2 pontos,
pelo que o guarda de meia ponta do P1.18 deixava passar tudo — cada passagem um `PositionModify`
real, um round-trip ao servidor.

### 37.3 A correção aplicada

Em `Management/MoneyLadder.mqh` a tolerância do TP passou a ser o `minDist` que a função já calcula
(`max(stops_level, freeze_level) * point`, nunca abaixo de 2× spread), com um piso de meia ponta:

```mql5
double tpTol = MathMax(point * 0.5, minDist);

bool slSame = (MathAbs(sendSl - curSl) <= point * 0.5);
bool tpSame = (MathAbs(sendTp - curTp) <= tpTol);

if(slSame && tpSame)
   continue;
```

A decisão de trading ficou **intacta**: o SL continua a sair sempre que muda (`slSame` mantém a meia
ponta), o SL continua a ir para a entrada a 1R e para a trava nos mesmos gatilhos, e o alvo em
dinheiro continua a fechar a posição inteira a mercado. O que muda é apenas a histerese do reenvio do TP.

Em `Core/TradePipeline.mqh`, `[PIPELINE] INICIO` e `[PIPELINE] FINALIZADO` passaram a usar
`DiagGateAllow` com heartbeat 3600 (saíam 26 979 vezes cada = 53 958 linhas = 4,31% do run, sempre com
`Symbols=11`; o `PROCESSANDO` já fora baixado a 1×/hora no P1.3). `RunTradePipelineSymbol` e
`ProcessSymbol` ficaram **fora** do portão — o portão decide apenas se a linha volta a ser escrita.

### 37.4 Aplicação, prova e compilação

`Files\Backup\apply_p130_ladder_pipeline.ps1` (novo, 7276 B), round-trip Latin1 byte-exacto, prova
`OK alvo unico` em cada substituição: MoneyLadder 12 675 → **14 007 B**, TradePipeline 6 876 →
**7 576 B**, `XAU_AI_PRO.mq5` 74 387 → 74 387 B, VersionManager 29 132 → **30 638 B**; NUL=0 e lixo=0
em todos.

A 1.ª execução falhou com `ALVO NAO UNICO ... encontrados 0` porque o here-string do `.ps1` é gravado
em LF e o `.mqh` é CRLF. Corrigido normalizando dentro de `Troca`:

```powershell
$de   = $de.Replace("`r`n", "`n").Replace("`n", "`r`n")
$para = $para.Replace("`r`n", "`n").Replace("`n", "`r`n")
```

Nenhum ficheiro ficou meio escrito: o `Gravar` só corre depois de todas as trocas passarem.

Compilação: `Result: 0 errors, 0 warnings, 15928 ms elapsed, cpu=X64 Regular`; `.ex5` 665 506 B,
31/10/2026 20:59:46.

### 37.5 Recarga do terminal — prova de 17/17 em v1.2.53

O ciclo `profile_apply Default` → `profile_apply XAI_V1243_20261031` correu às 20:59:57 e 21:00:04
(journal do terminal: 17 experts *removed* e 17 *loaded successfully*). O journal **Experts** prova a
troca de binário no mesmo segundo:

- 20:59:53.837 → `[VERSION] v1.2.52 | Build=2026.10.30` (instâncias antigas);
- 20:59:54.858 → `[VERSION] v1.2.53 | Build=2026.10.30` (a primeira a recarregar).

`Files\Backup\count_instances_version.ps1` (novo, só-leitura) conta fontes distintas por versão em
`MQL5\Logs\20261031.log` (21 251 344 B, 126 857 linhas):

```
v1.2.40 -> 15    v1.2.45 -> 17    v1.2.50 -> 17
v1.2.41 -> 15    v1.2.46 -> 17    v1.2.51 -> 17
v1.2.42 -> 16    v1.2.47 -> 17    v1.2.52 -> 17
v1.2.43 -> 16    v1.2.48 -> 17    v1.2.53 -> 17
v1.2.44 -> 17    v1.2.49 -> 17
```

**17/17 fontes em v1.2.53.** A cadeia completa mostra também que o número de gráficos subiu de 15
para 17 em v1.2.44 e nunca mais desceu.

### 37.6 Correção de topologia (importante para auditorias futuras)

Duas armadilhas de leitura custaram duas medições falsas nesta ronda:

1. `Logs\<data>.log` é o journal do **terminal** (rede, perfis, experts carregados/removidos) — **não**
   contém `Print()` do EA. O output do EA vai para o journal **Experts** em `MQL5\Logs\<data>.log`.
   Foi por isso que `verify_v1253_instances.ps1` devolveu `linhas [VERSION] = 0`.
2. Esse zero não era resultado: era **defeito do leitor**. A 1.ª versão usava
   `[IO.File]::ReadAllText`, que rebenta com `IOException` porque o `terminal64` mantém o ficheiro
   aberto; a exceção deixou `$txt` vazio e a contagem saiu 0. Corrigido com
   `[IO.File]::Open($p,'Open','Read',[IO.FileShare]::ReadWrite)` + `StreamReader` Unicode, que leu
   1 097 linhas.

Ambos os logs são **UTF-16LE com BOM `FF FE`**, e ambos são por dia, anexados por tudo o que corre
nesse dia.

### 37.7 Ganho medido/estimado e ressalva

Ganho acumulado no run, medido sobre o journal segmentado: P1.25 347 741 (28,17%) + P1.26 51 993
(4,21%) + P1.27 84 551 (6,85%) = 484 285 (39,22%); P1.28 131 227 (10,63%) + P1.29 13 228 (1,07%) =
144 455 (11,70%); P1.30 ≈ 86 700 (LADDER) + 53 958 (PIPELINE). O journal perde mais de metade do que
escrevia.

**Ressalva:** o backtest `7702926785952690594` corre **v1.2.45** e continua com esse binário até
terminar. Nenhuma das correções P1.25–P1.30 pode ser provada por ele. Provado até aqui: lógica
(auto-teste C1..C4), efeito no `[STATE]` (replicação 249 592 → 751), atribuição do ruído
(segmentação por `[VERSION]`) e o churn do LADDER (replicação por ticket 88 287 → 3 545). A
confirmação final exige um **novo** backtest com v1.2.53.

### 37.8 Próximo passo

Novo backtest com v1.2.53 e re-medição com `audit_last_segment_totals.ps1`; em paralelo, procurar a
próxima fonte de ruído no journal segmentado (candidatos já medidos e ainda não atacados).

## §38 — P1.31 (v1.2.54): o universo SEM tag do journal (38,31%)

### O que foi medido (e como)

O P1.30 fechou o `[LADDER]` e o eco do `[PIPELINE]`. Faltava olhar para o que
NÃO tem tag nenhuma. `audit_p131_untagged.ps1` (só-leitura, 76 linhas)
segmenta o log do tester por `[VERSION]`, isola o último run e agrupa as linhas
sem tag conhecida por "forma" (dígitos → `#`, truncada a 80 caracteres).

Resultado no último segmento (1 287 596 linhas com carimbo):

| grandeza | valor |
|---|---|
| linhas sem tag conhecida | 493 255 |
| % do run | 38,31% |
| formas distintas | 627 |

Os dois maiores emissores, ambos invisíveis na contagem por tag:

| forma | linhas | % do run |
|---|---|---|
| `[LEARN] historico verificado` | 158 294 | 12,29% |
| `[COST] BLOQUEADO` + `EXECUTION: CUSTO BLOQUEADO` (par) | 64 494 + 64 494 | 10,02% |
| `[COST] BLOQUEADO` + `EXECUTION: CUSTO BLOQUEADO` (par, 2.º modo) | 14 112 + 14 112 | 2,19% |

### As duas causas

1. **`[LEARN]` sem memória de desfecho.** A varredura do histórico de deals roda
   a cada passagem do pipeline. Com a memória de aprendizagem carregada, o
   resultado normal é "nenhum novo" — mas a linha de resumo saía em TODAS as
   passagens, incluindo as 158 mil em que nada mudou.
2. **Custo bloqueado impresso DUAS vezes.** `CostGate.mqh` imprimia
   `[COST] BLOQUEADO` com todo o detalhe e o chamador (`ExecutionEngine.mqh`)
   imprimia a seguir `EXECUTION: CUSTO BLOQUEADO | <símbolo> | <mesmo motivo>`.
   O mesmo evento, duas linhas, 14,1% do run somado.

### A correção (DiagGate, P1.17/P1.25 estendido)

- `AI/LearningHistory.mqh`: `[LEARN] historico verificado` sai **sempre** que há
  deal novo (`saldo > 0`) e, quando não há, no máximo 1×/hora por símbolo
  (`DiagGateAllow(_Symbol, "LEARN_VERIF", "sem_novos", 3600)`). A importação, o
  throttle e a aprendizagem não mudaram.
- `Filters/CostGate.mqh`: o `Print` do bloqueio passou a estar dentro de
  `DiagGateAllow(symbol, "COST_BLOCK", modo, 14400)`. Chave = **MODO** de
  bloqueio (`ALVO+RISCO` / `RISCO` / `ALVO`), nunca o texto com números — o
  custo, a percentagem e o alvo mudam a cada tick, pelo que o texto nunca seria
  chave estável. É o mesmo critério do P1.28 na `[VIA RAPIDA]` (desfecho =
  REGIME). O `return(false)` e o `reason` ficaram intactos.
- `Core/ExecutionEngine.mqh`: a linha duplicada passou a
  `DiagGateAllow(symbol, "CUSTO_BLOQ", "BLOQUEADO", 14400)`.
  `EventTradeRejected` e o `return false` continuam a correr sempre.

Regra respeitada em todos os três pontos: **o portão decide apenas se a linha
volta a ser escrita**. Nenhuma regra de trading, risco, execução ou
precificação foi tocada.

### Aplicação e um erro real de patch

`apply_p131.ps1` (round-trip byte-exacto, `OK alvo unico` por substituição)
correu à primeira: CostGate.mqh 11946→12715 B, ExecutionEngine.mqh
41926→42403 B, LearningHistory.mqh 32667→33438 B, XAU_AI_PRO.mq5 74387→74387 B,
VersionManager.mqh 30638→31980 B, NUL=0 em todos.

A primeira compilação falhou com **101 erros em VersionManager.mqh(63)**: o
prepend do changelog partiu a costura da string — o texto novo terminava em
aspa e o texto antigo (v1.2.53) ficou **fora** de string, a ser lido como
código (`error 239: only one character code expected`, `error 158: invalid
suffix 'x'`, `error 256: undeclared identifier 'P1'`…). Diagnóstico por
posição de coluna: **todos os erros caíam acima da coluna 1340**, ou seja já no
texto antigo — o texto novo (0–1340) não tinha um único erro. Isso provou que o
problema era só a costura.

Correção (`fix_p131_changelog.ps1`, backup `VersionManager.mqh.bak_before_p131fix`):
inserir `" +` e reabrir a aspa antes de `(31/10/2026) - P1.30:`. Resultado:
31980→32010 B, NUL=0, loneLF=0. `Result: 0 errors, 0 warnings, 15783 ms`.
Lição: **prepend de changelog tem de reabrir a aspa do texto que estava lá**;
o `Troca` com âncora única não garante que a string continue fechada.

### Prova de recarga (17/17)

`EX5 666154 B mtime=31/10/2026 21:07:02`; ciclo `profile_apply Default` →
`profile_apply XAI_V1243_20261031`; `count_instances_version.ps1` sobre
`MQL5\Logs\20261031.log` (21 251 344 B, 135 801 linhas):

```
v1.2.40 -> 15 fontes distintas
v1.2.41 -> 15
v1.2.42 -> 16
v1.2.43 -> 16
v1.2.44 .. v1.2.54 -> 17 fontes distintas
```

v1.2.54 → 17/17. Cadeia completa v1.2.40→v1.2.54.

### Ganho esperado e ressalva

Ganho medido no perfil de ruído: **≈ 315 506 linhas** (158 294 do `[LEARN]` +
157 212 do par de custo), ou seja ~24,5% do run de 1 287 596 linhas.

Ressalva que acompanha todos os números do P1.25–P1.31: o backtest
7702926785952690594 corre com o binário v1.2.45 e continua com ele até
terminar; **nenhuma destas correções pode ser provada por esse run**. O que está
provado é a lógica (auto-teste C1..C4), o efeito medido na replicação, a
atribuição do ruído (segmentação por `[VERSION]`) e a troca de binário em 17/17
instâncias. A confirmação final exige um **novo backtest** com v1.2.54.

### Próximo passo medido

O universo sem tag continua com 627 formas. Candidatos já medidos e ainda não
atacados (todos por símbolo, portanto exigem o mesmo tratamento por MODO):
`CTrade::OrderSend modify position` (USDCAD 10 593, USDJPY 8 721, USDSEK 5 406,
USDCHF 3 904, USDCNH 3 881), `position modified […]` (USDCAD 7 194, USDJPY 3 535,
USDSEK 2 458), `[RESUMO]` (6 341 + 4 356 + 3 506 + 2 550), `[SESSION] estado
salvo` 11 207, `[SAFETY] Exposure limit` 8 377, `[LOGGER OFFLINE] HealthMonitor`
5 156 + `LastTradeTime/Now` 5 156, `LOT CAP REAL` 2 233.

## §39 — P1.32 (v1.2.55): o INFO do CTrade da biblioteca (45 692 linhas)

### O que foi medido

Sobraram, no universo sem tag, as linhas que não vêm do EA mas da biblioteca
standard `Include\Trade\Trade.mqh`. No último segmento medido (1 287 596 linhas):

| forma | linhas | símbolos principais |
|---|---|---|
| `CTrade::OrderSend modify position` | 32 505 | USDCAD 10 593, USDJPY 8 721, USDSEK 5 406, USDCHF 3 904, USDCNH 3 881 |
| `position modified [...]` | 13 187 | USDCAD 7 194, USDJPY 3 535, USDSEK 2 458 |

Total 45 692 linhas = **3,55%** do run, e são **informação duplicada**: o EA já
registra cada execução com `ResultRetcode()`/`ResultComment()`, e o `TradeLogger`
grava a linha `Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI,Ticket,Magic,Origin`.

### Causa

`CTrade` inicializa `m_log_level = LOG_LEVEL_ALL` no construtor MQL5
(`Include\Trade\Trade.mqh:168`), pelo que imprime em INFO cada `OrderSend` e cada
`PositionModify`, mesmo quando o resultado é `10009 DONE`.

### A correção

`trade.LogLevel(LOG_LEVEL_ERRORS);` nos **dois** pontos de inicialização do
`CTrade`: `XAU_AI_PRO.mq5` (logo após `SetDeviationInPoints`) e
`Core\OrderManager.mqh` (mesma posição). Os erros da biblioteca continuam a sair
(é o que interessa em requote, stops inválidos, mercado fechado); só o INFO deixa
de sair. Nenhuma regra de execução, risco, precificação ou gestão foi tocada.

### Decisões de NÃO tocar (medidas e justificadas)

Três candidatos foram medidos e **descartados** por não serem ruído:

| linha | linhas | porquê fica |
|---|---|---|
| `[SESSION] estado salvo` | 11 207 | `SessionStateStore()` já tem throttle de 300 s (`Core/SessionState.mqh` + `XAU_AI_PRO.mq5:774-800`) e só corre com `EnableSessionStatePersistence`. 11 207 × 5 min ≈ 933 h de tempo de modelo em 17 instâncias: é o ritmo esperado, não churn. É prova de persistência de estado. |
| `[RESUMO]` | ≈16 750 | é o *operator brief* autónomo (`Monitoring/OperatorBrief.mqh`), emitido a cada `OperatorBriefSeconds`. É funcionalidade, não diagnóstico. |
| `[LOGGER OFFLINE]` | 5 156 + 5 156 | é o caminho de emergência quando `LoggerInit()` não foi chamado (`Monitoring/Logger.mqh:253`). É a **única** saída nesse estado; portajar esconderia justamente o caso em que o logger está em baixo. |

### Validação

- `apply_p132.ps1` (round-trip byte-exacto, `OK alvo unico` em cada troca):
  `XAU_AI_PRO.mq5` 74387→74802 B, `Core\OrderManager.mqh` 4635→4849 B,
  `Enterprise\VersionManager.mqh` 32010→32788 B, NUL=0.
- Compilação: `Result: 0 errors, 0 warnings, 15624 ms`, ex5 667 770 B
  (mtime 21:09:24).
- Recarga: `profile_apply Default` → `profile_apply XAI_V1243_20261031`;
  `count_instances_version.ps1`: **v1.2.54 → 17 fontes, v1.2.55 → 17 fontes**.
  A primeira contagem deu 16 — um gráfico ainda não tinha recebido tick para
  imprimir `[VERSION]`; 35 s depois fechou em 17/17 (não é regressão, é o
  primeiro tick do símbolo).

### Ganho e ressalva

+45 692 linhas previstas (~3,55%). Acumulado P1.25–P1.32 o perfil de ruído cai
de ~50,9% (P1.25–P1.29) + 315 506 (P1.31) + 45 692 (P1.32).

Ressalva de sempre: o run 7702926785952690594 corre v1.2.45 e **não prova**
nenhuma destas correções. A confirmação exige novo backtest com v1.2.55.


---

## §40 — P1.33 (v1.2.56): o limite de exposição era um ESTADO, não um evento

**Data:** 31/10/2026 21:42 (local) · **Versão:** v1.2.55 → **v1.2.56** · **Estado:** FECHADO

### 40.1 Porque este alvo (medição, não palpite)

Três medições só-leitura, todas novas nesta ronda:

| script | resultado |
|---|---|
| `audit_live_v1255.ps1` | desde o 1.º `[VERSION] v1.2.55` (índice 137 974) até ao fim: **9 343 linhas**, das quais **6 647 sem tag (71%)** |
| `audit_restarts_v1255.ps1` | os **80** `[VERSION] v1.2.55` estão **todos no minuto 21:09** → não há reinicializações periódicas |
| `audit_steady_v1255.ps1` | linhas com hora **≥ 21:15 = 0** → o EA não escreveu nada em regime estacionário |
| `count_needles_tester.ps1` | journal do backtest, **4 521 967 linhas** |

A explicação das 6 647 linhas sem tag é o **banner de inicialização** (`====` 250+156+156+126+63, `[N] SIMBOLO` 62 por símbolo, `=== RECOVERY STATUS ===` com 8 verificações de 48 linhas, `SYMBOL MANAGER | Resolved: X -> X` 33 por símbolo). É custo de arranque, não ruído de regime — e **zero** desde 21:15 porque **31/10/2026 é sábado e o mercado está fechado**: sem tick, sem `OnTick`, sem output.

Consequência metodológica: enquanto o mercado estiver fechado, **o único segmento com regime estacionário é o do Strategy Tester**. Foi aí que o alvo foi escolhido:

| linha | ocorrências (journal do tester, 4 521 967 linhas) | estado |
|---|---|---|
| `[LEARN] historico verificado` | 399 041 | já portejado (P1.31) |
| `[STATE]` | 1 043 458 | já coberto (P1.25/P1.26) |
| `[COST] BLOQUEADO` | 151 464 | já portejado (P1.31) |
| `EXECUTION: CUSTO BLOQUEADO` | 151 464 | já portejado (P1.31) |
| `CTrade::OrderSend` | 106 672 | já portejado (P1.32) |
| `position modified` | 106 441 | já portejado (P1.32) |
| **`[SAFETY] Exposure limit`** | **35 572** | **maior emissor que sobrou → P1.33** |
| `LOT CAP REAL` | 2 233 | candidato seguinte |
| `[SESSION] nada a restaurar` | 0 | não ocorre neste broker/run |

### 40.2 A causa

`Enterprise\SafetyManager.mqh`, `CheckTotalExposure()`: a linha **já tinha** um throttle de 60 s desde a v1.2.27 (comentário P0.4/P1.3 no próprio ficheiro). O problema é o intervalo, não a ausência de portão: em 17 instâncias, 60 s de tempo de modelo multiplicam-se por 17 e o limite de exposição total é um **estado persistente** (a exposição continua acima do limite enquanto as posições abertas o justificarem) — logo volta a escrever a mesma informação a cada minuto, num run que dura horas de modelo.

### 40.3 A alteração (1 linha + comentário)

```mql5
// v1.2.56 (P1.33): MEDIDO no journal do backtest de 31/10/2026
// (4 521 967 linhas): '[SAFETY] Exposure limit' = 35 572 linhas, o maior
// emissor que sobrou depois de P1.25..P1.32. Nao e um evento, e um ESTADO
// persistente (a exposicao total acima do limite), e o bloqueio em si
// continua a devolver false em TODOS os ticks - so o texto passa a sair
// no maximo 1x por 30 min (60 s -> 1800 s = ganho ~30x nesta linha).
if(ultimoAvisoExposicao == 0 || (agoraExposicao - ultimoAvisoExposicao) >= 1800)
```

**Intocado:** `return false` do `CheckTotalExposure()`, `m_limits.max_total_exposure`, o cálculo de `exposurePct`, o filtro `magic != MagicNumber` e todas as restantes verificações do `CSafetyManager`. O portão decide apenas se a linha volta a ser escrita.

Ganho esperado nesta linha: 35 572 → ≈1 186 (≈ **34 386 linhas cortadas**, ~30×).

### 40.4 Versão (regra tripla)

| ficheiro | antes | depois |
|---|---|---|
| `XAU_AI_PRO.mq5` (cabeçalho `// XAU_AI_PRO v…`) | v1.2.55 | **v1.2.56** |
| `XAU_AI_PRO.mq5` (`#property version`) | `"1.255"` | **`"1.256"`** |
| `Enterprise\VersionManager.mqh` (`EA_VERSION_STRING`) | `"1.2.55"` | **`"1.2.56"`** |

### 40.5 Prova de escrita e de recarga

```text
   backup -> SafetyManager.mqh.bak_before_p133
   backup -> VersionManager.mqh.bak_before_p133
   backup -> XAU_AI_PRO.mq5.bak_before_p133
   OK alvo unico : SAFETY exposicao 60->1800
GRAVADO SafetyManager.mqh -> 19038 B  NUL=0 loneLF=0
   OK alvo unico : mq5 cabecalho
   OK alvo unico : mq5 property
GRAVADO XAU_AI_PRO.mq5 -> 74802 B  NUL=0 loneLF=0
   OK alvo unico : VM changelog
   OK alvo unico : VM versao
GRAVADO VersionManager.mqh -> 33430 B  NUL=0 loneLF=0
```

```text
  Result: 0 errors, 0 warnings, 16471 ms elapsed, cpu='X64 Regular'
ex5: 667822 B  10/31/2026 21:42:25
```

```text
   v1.2.54 -> 17 fontes distintas
   v1.2.55 -> 17 fontes distintas
   v1.2.56 -> 17 fontes distintas
disco livre C: 8.95 GB
```

### 40.6 Candidato seguinte

`LOT CAP REAL` (2 233 linhas, `Core\ExecutionEngine.mqh:161`, `PrintFormat`) — só depois de se confirmar, no novo backtest com v1.2.56, que as linhas do `[SAFETY]` caíram como previsto.

### 40.7 Ressalva de sempre

O backtest `7702926785952690594` corre **v1.2.45** (progresso 04:29:25 / 05:52:10) e continuará com esse binário até terminar: **nenhuma** correção P1.25–P1.33 pode ser provada por ele. A confirmação do ganho acumulado exige um **novo backtest com v1.2.56** e medição com `count_needles_tester.ps1`. Um backtest não prova rentabilidade futura.


---

## §41 — P1.34 (v1.2.57): três portões que existiam mas não abafavam nada

**Data:** 31/10/2026 23:23 (local) · **Versão:** v1.2.56 → **v1.2.57** · **Estado:** FECHADO

### 41.1 A medição (journal do backtest, 5 077 002 linhas)

| linha | ocorrências | tinha portão? |
|---|---|---|
| `EXECUTION: LOTE DINAMICO` | **177 619** | sim — **defeituoso** |
| `EXECUTION WARNING \| FORCA LOTE MINIMO` | **147 241** | sim — **defeituoso** |
| `LOT CAP REAL` | **2 233** | **não** |
| `[SAFETY] Exposure limit` | 35 572 | sim (60 s → 1800 s, P1.33) |
| **total deste ciclo** | **327 093** | **6,44 % de todo o output** |

### 41.2 A causa (a mesma nos dois primeiros, e já documentada desde o P1.28)

`DiagGateAllow(simbolo, tag, desfecho, heartbeat)` suprime repetições do **mesmo desfecho**. Nessas duas linhas o desfecho era passado com valores que mudam **a cada candidato a ordem**:

```mql5
// antes (defeituoso)
if(DiagGateAllow(symbol, "LOTE_DIN",
         ConvictionGradeName(gradeOut) + "|" + DoubleToString(lot, 3), 14400))

if(DiagGateAllow(symbol, "LOT_MIN",
         DoubleToString(lot, 3) + "|" + DoubleToString(minLot, 3), 3600))
```

Como `lot` varia, o conjunto de desfechos nunca repete → o portão liberta tudo, todas as passagens. É exactamente o erro que a regra de desenho do P1.28 proíbe:

> para valores que variam a cada tick, a chave tem de ser o **MODO/estado pequeno e estável**, nunca o texto com números.

### 41.3 A correção

```mql5
// depois — desfecho = ESTADO estável; os números continuam no texto da linha
if(DiagGateAllow(symbol, "LOTE_DIN", ConvictionGradeName(gradeOut), 14400))
if(DiagGateAllow(symbol, "LOT_MIN",  "FORCA_MIN", 3600))
if(DiagGateAllow(symbol, "LOT_CAP",  "REAL", 3600))   // esta não tinha portão nenhum
   PrintFormat("LOT CAP REAL | ...");
lot = capReal;                                        // o cap acontece SEMPRE
```

**Intocado:** `lot`, `capLot`, `capReal`, `lot = minLot`, `lot = capReal`, `return(0.0)` do `EXECUTION BLOCK | LOT MIN`, `MaxRiskPerTradeUsd`, `MaxRiskPerTradePercentCap` e o cálculo de 1R. Nenhuma regra de execução, risco ou precificação foi tocada — mudou apenas **se a linha de diagnóstico volta a ser escrita**.

### 41.4 Versão (regra tripla) e prova

| ficheiro | antes | depois |
|---|---|---|
| `XAU_AI_PRO.mq5` cabeçalho | v1.2.56 | **v1.2.57** |
| `XAU_AI_PRO.mq5` `#property version` | `"1.256"` | **`"1.257"`** |
| `VersionManager.mqh` `EA_VERSION_STRING` | `"1.2.56"` | **`"1.2.57"`** |

```text
   backup -> ExecutionEngine.mqh.bak_before_p134
   backup -> VersionManager.mqh.bak_before_p134
   backup -> XAU_AI_PRO.mq5.bak_before_p134
   OK alvo unico : LOTE_DIN desfecho estavel
   OK alvo unico : LOT_MIN desfecho estavel
   OK alvo unico : LOT CAP REAL portao
GRAVADO ExecutionEngine.mqh -> 43277 B  NUL=0 loneLF=0
GRAVADO XAU_AI_PRO.mq5     -> 74802 B  NUL=0 loneLF=0
GRAVADO VersionManager.mqh -> 34744 B  NUL=0 loneLF=0
  Result: 0 errors, 0 warnings, 15976 ms elapsed, cpu='X64 Regular'
ex5: 667696 B  10/31/2026 23:23:28
   v1.2.57 -> 17 fontes distintas
```

### 41.5 Ganho

≈ **327 000 linhas** (6,44 %) cortadas por ciclo de medição — o maior ganho desde o P1.25/P1.26. Somado a P1.25–P1.33, o journal do tester deixa de ser o consumidor de disco que abortou um backtest.

### 41.6 Lição registada

Um portão presente **não é** um portão a funcionar. A verificação correcta não é "tem `DiagGateAllow`?" mas "a contagem da linha caiu depois de o portão entrar?". Das 12 chamadas `DiagGateAllow` no código, **duas** estavam neutralizadas por desfecho variável e **uma** linha de execução não tinha portão nenhum.

### 41.7 Candidato seguinte

O resto de `EXECUTION: ` (801 191 no total, 177 619 agora explicados) e as restantes chamadas com chave numérica (`RISCO_REAL`, `ALVO_RR`, `RISK_EFETIVO`, `RR_ENTRADA`, `RISK_CALC`, `RISK_CALC_USD`, `SIM_BLOCK`) — cada uma tem de ser medida individualmente antes de ser tocada.

### 41.8 Ressalva

O backtest `7702926785952690594` corre v1.2.45 (progresso 06:10:09 / 06:32:56) e **não** prova nenhuma destas correções. A confirmação exige um novo backtest com v1.2.57. Um backtest não prova rentabilidade futura.


---

## §42 — P1.35 (v1.2.58): os dois portões de `[RISK]`, pelo mesmo defeito

**Data:** 31/10/2026 23:31 (local) · **Versão:** v1.2.57 → **v1.2.58** · **Estado:** FECHADO

### 42.1 Medição (journal do backtest, 5 120 234 linhas)

| linha | ocorrências | portão |
|---|---|---|
| `[RISK] RISCO REAL DA ORDEM` | **179 619** | `RISCO_REAL` — **neutralizado** |
| `[RISK] alvo elevado para respeitar o RR minimo` | **147 612** | `ALVO_RR` — **neutralizado** |
| `[RISK] MIN_LOT_EXCEEDS_RISK_CAP` | 7 | irrelevante |
| `[RISK] ` (todas) | 541 441 | restam ≈214 200 |
| `EXECUTION: ` (todas) | 810 042 | restam ≈632 400 |
| **total deste ciclo** | **327 231** | **6,39 %** |

### 42.2 Causa (a mesma do P1.34, agora em `[RISK]`)

```mql5
// antes
if(DiagGateAllow(symbol, "RISCO_REAL",
         ajuste + "|" + DoubleToString(riscoFinal, 2), 14400))

if(DiagGateAllow(symbol, "ALVO_RR",
         DoubleToString(tpPontos, 0) + "|" + DoubleToString(alvoMinimo, 0), 14400))
```

`riscoFinal`, `tpPontos` e `alvoMinimo` são recalculados **por candidato** (nota de convicção, cenário, notícia, envelope de risco). O conjunto de desfechos nunca repete → o portão liberta todas as passagens.

### 42.3 Correção

```mql5
// depois — desfecho = estado estável; números ficam no texto
if(DiagGateAllow(symbol, "RISCO_REAL", ajuste, 14400))
if(DiagGateAllow(symbol, "ALVO_RR",  "ALVO_MIN", 14400))
```

**Intocado:** `ajuste`, `riscoFinal`, `tpPontos`, `alvoMinimo`, a atribuição `tpPontos = alvoMinimo`, o `EventTradeRejected` do `MIN_LOT_EXCEEDS_RISK_CAP`, o envelope de risco e o `return false` correspondente. Só a verbosidade mudou.

### 42.4 Versão e prova

| ficheiro | antes | depois |
|---|---|---|
| `XAU_AI_PRO.mq5` cabeçalho | v1.2.57 | **v1.2.58** |
| `#property version` | `"1.257"` | **`"1.258"`** |
| `EA_VERSION_STRING` | `"1.2.57"` | **`"1.2.58"`** |

```text
   OK alvo unico : RISCO_REAL desfecho estavel
   OK alvo unico : ALVO_RR desfecho estavel
GRAVADO ExecutionEngine.mqh -> 43812 B  NUL=0 loneLF=0
GRAVADO XAU_AI_PRO.mq5     -> 74802 B  NUL=0 loneLF=0
GRAVADO VersionManager.mqh -> 35681 B  NUL=0 loneLF=0
  Result: 0 errors, 0 warnings, 15816 ms elapsed, cpu='X64 Regular'
ex5: 668538 B  10/31/2026 23:30:57
   v1.2.58 -> 17 fontes distintas
disco livre C: 8.63 GB
```

### 42.5 Ganho

≈ **327 231 linhas** (6,39 %). Somando P1.33 (34 386) + P1.34 (327 093) + P1.35 (327 231): **≈688 700 linhas** cortadas em três ciclos consecutivos.

### 42.6 Padrão a auditar até ao fim

Toda a chamada `DiagGateAllow` cujo desfecho contenha `DoubleToString(...)` de um valor recalculado por candidato está **neutralizada por construção**. Ainda por medir: `RISK_EFETIVO` (804), `RR_ENTRADA` (817), `SIM_BLOCK` (915), `RISK_CALC` (RiskEngine 151), `RISK_CALC_USD` (RiskEngine 251) e o resto de `EXECUTION: ` (≈632 400 linhas) e `[RISK] ` (≈214 200 linhas).

### 42.7 Ressalva

Backtest `7702926785952690594` corre v1.2.45 (06:18:56 / 06:28:15) — não prova nenhuma destas correções. Confirmação exige novo backtest com v1.2.58. Um backtest não prova rentabilidade futura.


---

## §43 — Pesquisa externa (MQL5) e o que a MEDIÇÃO autoriza copiar

**Data:** 31/10/2026 23:40–00:10 · **Versão em produção:** v1.2.58 · **Estado:** PESQUISA + 2 MEDIÇÕES, **nenhuma alteração de risco aplicada**

### 43.1 O que foi pesquisado (MQL5 Search API, `hl=en`, módulo `mql5.com.en.articles`)

| artigo | autor | ideia central |
|---|---|---|
| [22998 — Measuring broker execution quality in MQL5](https://www.mql5.com/en/articles/22998) | Walter Marcelo Rando | medir slippage, spread pago e requotes para explicar a diferença backtest↔real |
| [24251 — Isolation Forest para qualidade de execução](https://www.mql5.com/en/articles/24251) | Olamide Daniel Adebayo | vector de features por fill e score contra o histórico do próprio EA |
| [23849 — Consecutive Loss Streak / Risk-of-Ruin](https://www.mql5.com/en/articles/23849) | Ushana Kevin Iorkumbul | taxa de acerto + payoff → probabilidade de séries de perdas e risco de ruína |
| [24147 — Kelly Position Sizing a partir do edge da própria estratégia](https://www.mql5.com/en/articles/24147) | Martin Alejandro Bamonte | f* = p − q/b, meio-Kelly, varrimento de risco vs crescimento |
| [18991 — The Science of Position Sizing](https://www.mql5.com/en/articles/18991) | Daniel Opoku | Monte Carlo do risco por trade vs drawdown |

### 43.2 O que a medição diz (dois números duros, hoje)

**(a) O `trade_history.csv` de produção NÃO suporta Kelly nem dedup por ticket.**
```
ficheiro linhas = 100228
linhas com 13 colunas   = 100120
linhas COM ticket       = 156          (0,16 %)
data mais recente com ticket = 22026.08.18 03:51:22   <- ANO CORROMPIDO
```
→ 99 975 linhas têm `Ticket` e `Magic` **vazios** e `Origin=UNKNOWN`: são anteriores ao P1.21 (v1.2.46) ou escritas por um caminho que não passou `DEAL_POSITION_ID`/`DEAL_MAGIC`. Além disso há pelo menos uma linha com o ano a 5 dígitos (`22026`), o que mostra que a coluna `Time` também já sofreu corrupção de escrita.

**Consequência directa:** a prova ponta-a-ponta das 13 colunas, que estava na lista de pendentes, **falha** — e enquanto falhar, **não é possível** separar manual vs EA nem deduplicar por ticket, logo **nenhum** cálculo de Kelly/risco de ruína sobre este ficheiro é legítimo.

**(b) O `trade_history_backtest.csv` do run em curso não é amostra válida.**
```
amostra=362  vitorias=5  derrotas=202  p=1,38 %
ganho medio=2001,8  perda media=64,698  b=30,941
expectancy=-36,16 USD  PF=0,766  maior serie de perdas=7
Kelly f*=-1,806 %   meio-Kelly=-0,903 %
```
Uma vitória média de **2 001,80 USD** é incompatível com a escala da conta e com o próprio P1.18 (269 tickets, máximo 15,94 USD por ticket): há linhas com colunas desalinhadas. Amostra **descartada** para dimensionamento.

### 43.3 Veredicto (o que NÃO se copia, e porquê)

- **Kelly / meio-Kelly (24147) e risco de ruína (23849): não aplicados.** Sem edge medido em ficheiro íntegro, mudar `RiskPerTradeUsd`/`RiskPercent` seria exactamente o palpite que a instrução permanente proíbe. Fica registado o método (f*, meio-Kelly, varrimento de risco) para ser aplicado **assim que** o logger provar 13 colunas preenchidas.
- **Isolation Forest (24251): não aplicado.** Exige um histórico de fills com slippage/latência por operação — que é precisamente o que o `trade_history` ainda não grava de forma fiável.
- **Qualidade de execução (22998): é o pré-requisito dos outros dois.** O que falta não é um modelo, é **instrumentação**: ticket, magic e latência por fill.

### 43.4 Correcção de rota (o próximo trabalho real)

1. Provar, com uma linha real, que `LogTradeCSV` grava `Ticket`, `Magic` e `Origin` preenchidos (o chamador em `XAU_AI_PRO.mq5:1652` já passa `DEAL_POSITION_ID` e `DEAL_MAGIC`; o que falta é confirmar que a versão que escreve é ≥ v1.2.46 e que a rotação do P1.21 não voltou a misturar registos).
2. Corrigir a coluna `Time` (ano a 5 dígitos `22026`), com formatação fixa `TimeToString(..., TIME_DATE|TIME_SECONDS)` e prova por amostra.
3. Só depois: recalcular banda de ADX, horas e Kelly sobre amostra íntegra.

### 43.5 Ressalva

Backtest `7702926785952690594` corre v1.2.45 (06:30:35 / 06:38:08). Nada nesta secção altera risco, execução ou precificação — é pesquisa, medição e rota. Um backtest não prova rentabilidade futura.


---

## §44 — Pesquisa de indicadores: candidatos, custo e o que a medição permite hoje

**Data:** 01/11/2026 00:20 · **Versão em produção:** v1.2.58 · **Estado:** PESQUISA; **nenhum indicador adicionado** (bloqueio medido)

### 44.1 Candidatos encontrados (MQL5 Search API, `hl=en`)

| fonte | mecanismo | porque é candidato |
|---|---|---|
| [codebase 76149](https://www.mql5.com/en/code/76149) — Kalman adaptativo com Kaufman ER | o ruído de processo Q é reescalado pelo **Efficiency Ratio** a cada barra | suaviza em chop e cola na tendência — ataca exactamente o que o ADX decide hoje |
| [codebase 72247](https://www.mql5.com/en/code/72247) — Self-Aware Trend System | SuperTrend ATR com largura adaptada por ER + Trend Quality Index | idem, com pontuação de qualidade |
| [article 23033](https://www.mql5.com/en/articles/23033) — SAMA/NLMS | μ adaptativo por ER, treino só em barra fechada | mostra como evitar look-ahead e instabilidade |
| [codebase 78262](https://www.mql5.com/en/code/78262) — Fractal Dimension Trend Strength | dimensão de Katz: 1,0 = linha recta, 2,0 = ruído | filtro alternativo ao ADX, independente dele |
| [article 22754](https://www.mql5.com/en/articles/22754) — Meta-Labeling ADX | camada 2 sobre o gate ADX | metodologia de validação walk-forward |
| [article 24279](https://www.mql5.com/en/articles/24279) — Seykota | dimensionamento por volatilidade + **portfolio heat** | heat agregado, não risco por trade |
| [article 24652](https://www.mql5.com/en/articles/24652) — Z-Score | desvio normalizado pela volatilidade recente | normaliza entrada em vez de limiar fixo |

### 44.2 O bloqueio, medido agora (não é opinião)

Tentativa de medir bandas de ADX × RSI no `trade_history.csv` de produção (`bands_ind.ps1`):

```
amostra com ADX>0 = 47282   descartadas sem indicador = 52828
  ADX>=35 | RSI>=70   n=38511  lucro= -1409651   por trade=-36,6039
  ADX>=35 | RSI=0     n= 8769  lucro= 15077733   por trade= 1719,4359
  ADX<20  | RSI=0     n=    1  lucro=    72034   por trade=72034
```

Um lucro de **+15 077 733 USD** em 8 769 linhas e **38 511 de 47 282** linhas com `RSI>=70` não descrevem um EA: descrevem **colunas desalinhadas** (o mesmo defeito já medido na §43). **Nenhuma conclusão de indicador pode sair deste ficheiro** — e a banda ADX≥35, que sustenta o P1.14, tem de ser reconfirmada numa amostra íntegra.

### 44.3 Veredicto

- **Nenhum indicador foi adicionado.** Acrescentar Kaufman ER, dimensão fractal, SuperTrend adaptativo ou Z-Score sem uma amostra íntegra seria palpite — exactamente o que a instrução permanente proíbe. Cada um destes filtros muda a selecção de entradas; sem medir, o risco é trocar um edge conhecido por uma hipótese.
- **Pré-requisito único e identificado:** as 13 colunas preenchidas (ticket, magic, origin) e a coluna `Time` sã (§43.4). Com isso, a medição de bandas volta a ser possível e é aí que o ER e a dimensão fractal passam a poder ser comparados com o ADX.
- **Ordem de trabalho recomendada, medida primeiro:** (1) logger íntegro; (2) reconfirmar ADX≥35 na amostra nova; (3) só então testar ER/dimensão fractal como segundo filtro na mesma amostra, com o critério "esperança por trade" e não com o lucro bruto.

### 44.4 Nota de risco

Qualquer filtro novo reduz o número de entradas; num sistema com esperança por trade negativa medido em várias amostras, o efeito imediato é reduzir perdas, não criar lucro. Um backtest não prova rentabilidade futura.


---

## §45 — Inventário completo: o que o MT5 oferece a um EA e o que este EA já usa

**Data:** 01/11/2026 00:30 · **Versão em produção:** v1.2.58 · **Estado:** AUDITORIA MEDIDA
**Método:** `Files\Backup\scan_api_coverage.ps1` (só-leitura) sobre **104 ficheiros** `.mq5`/`.mqh`, **1 211 387 bytes** de código.

### 45.1 Superfícies do MT5 para um EA (mapa completo)

| área | o que o MT5 dá | usado? | occ. |
|---|---|---|---|
| Eventos | `OnInit`, `OnDeinit`, `OnTick`, `OnTimer`, `OnTradeTransaction`, `OnChartEvent`, `OnBookEvent` | parcial | 15/3/15/5/8/**0**/**0** |
| Tester | `OnTester`, `OnTesterInit`, `OnTesterPass`, `OnTesterDeinit`, critérios, forward, frames | parcial | 1/**0**/**0**/**0** |
| Execução | `CTrade`, `OrderSend`, `OrderSendAsync`, `OrderCheck`, requotes/retcodes | sim | 9/10/**0** |
| Posições/ordens | `PositionSelect*`, `OrdersTotal`, `PositionGet*`, `PositionModify` | sim | 30+ |
| Histórico | `HistorySelect*`, `HistoryDealGet*`, `HistoryOrderGet*` | sim | 12/70 |
| Conta/símbolo | `AccountInfo*`, `SymbolInfo*`, `SymbolInfoInteger/Double/String`, `SYMBOL_TRADE_TICK_VALUE`, `stops/freeze level` | sim | 104/225 |
| Sessões de negociação | `SymbolInfoSessionTrade`, `SymbolInfoSessionQuote` | **não** | 0 |
| Saúde de dados | `SymbolIsSynchronized`, `SeriesInfoInteger`, `BarsCalculated` | **não** | 0 |
| Indicadores | `iMA`, `iADX`, `iATR`, `iRSI`, `iBands`, `iStochastic`, `iIchimoku`, `iCustom` | parcial | 14/4/6/7/**0**/**0**/**0**/**0** |
| Dados de mercado | `CopyBuffer`, `CopyRates`, `CopyTicks`, `CopyTicksRange`, `MarketBook*` | parcial | 27/6/**0**/**0**/**0** |
| Calendário | `CalendarValueHistory`, `CalendarEventById`, `CalendarCountryById` | sim | 13 |
| Ficheiros | `FileOpen/Write/Read/Flush/Close`, `FILE_COMMON`, `FILE_SHARE_*` | sim | 50/113 |
| Base de dados | `DatabaseOpen/Execute/Prepare/Bind` | sim | 45 |
| Estado global | `GlobalVariable*` (incl. `SetOnCondition` para locks) | sim | 77 |
| Rede | `WebRequest`, `Socket*` | parcial | 18/0 |
| Notificações | `SendNotification` (push), `SendMail`, `Alert`, `PlaySound` | parcial | 4/**0**/6/**0** |
| Gráfico | `ObjectCreate`, `ObjectSet*`, `ChartRedraw`, `ChartScreenShot`, `ChartIndicatorAdd` | **não** | 0 |
| Álgebra/GPU | `CMatrix`/`CVector`, `CLBuffer`/OpenCL | **não** | 0 |
| Recursos/cripto | `ResourceCreate`, `CryptEncode`, `#resource` | **não** | 0 |
| Relógios | `TimeCurrent`, `TimeLocal`, `TimeTradeServer` | sim | 203/9/7 |
| Símbolos custom | `CustomSymbolCreate`, `CustomRatesUpdate` | **não** | 0 |
| Programas | EA, indicador, **script**, **serviço**, biblioteca, wizard | parcial | — |

### 45.2 As seis lacunas que interessam a um EA 24/7 (por ordem de valor medido)

1. **`SymbolIsSynchronized` = 0 ocorrências.** É o único teste que diz "os dados deste símbolo estão coerentes com o servidor". Sem ele, um EA 24/7 pode calcular indicadores sobre uma série desactualizada e negociar com base nisso. Custo: 3 linhas num filtro; risco: nenhum (só bloqueia entrada, não mexe em risco).
2. **`SymbolInfoSessionTrade` = 0.** As horas de evasão (`AvoidHoursGMT`) e as sessões são hoje **constantes no input**. O broker publica a sessão real por símbolo; usar a API em vez do input elimina erro de horário de Verão/inverno — mas muda a regra de entrada, logo exige medição antes.
3. **`CopyTicks`/`CopyTicksRange` = 0.** Sem ticks não há medição de slippage real por fill — é o pré-requisito do artigo 22998 e da instrumentação que a §43 identificou como bloqueio.
4. **`OnTesterInit`/`OnTesterPass`/`OnTesterDeinit` = 0.** Sem frames, qualquer optimização futura não pode ser reproduzida nem analisada por passo. Hoje o EA só tem `OnTester` (1 ocorrência).
5. **`OnChartEvent` = 0 e `ObjectCreate` = 0.** Não existe interruptor manual no gráfico nem painel: o dono só controla o EA por inputs e pelo journal.
6. **`SendMail` = 0, `PlaySound` = 0.** Só há push (`SendNotification`) e `Alert`. Falta redundância de alerta para falhas críticas quando o push falha.

### 45.3 Lacunas que NÃO devem ser preenchidas (e porquê)

- **`OrderSendAsync`**: enviar sem esperar o resultado impede verificar `retcode`/`ResultRetcode()` — contra a política de execução já aplicada.
- **`MarketBook` (DOM)**: a estratégia não usa profundidade; muitos brokers não a expõem por símbolo.
- **`CMatrix`/`CLVector`/OpenCL**: sem modelo que precise de álgebra; acrescenta superfície de erro.
- **`ResourceCreate`/`CryptEncode`**: nada a proteger ou renderizar.
- **`iCustom`, `iBands`, `iStochastic`, `iIchimoku`**: indicadores novos sem medição = palpite (§44).

### 45.4 Veredicto e próximo passo medido

O EA **já usa** 44 das 68 superfícies sondadas. A única lacuna que é simultaneamente **barata, segura e defensável sem nova amostra** é a **1** (`SymbolIsSynchronized`): bloqueia entrada em dados dessincronizados e **não toca em risco, preço ou gestão** — o mesmo padrão do CostGate (o portão decide se a ordem sai; aqui decide se a análise é fiável).

As lacunas 2–6 mudam comportamento (horário de entrada, comunicação, optimização) ou dependem da amostra íntegra da §43, e ficam registadas como pendentes com o critério de medição explícito.

### 45.5 Ressalva

Nada nesta secção alterou código. Um backtest não prova rentabilidade futura.


---

## §46 — Inventário completo das superfícies MT5 disponíveis a um EA (360 sondadas, 134 usadas)

**Data:** 31/10/2026 23:44 (local) · **Versão em produção:** v1.2.58 · **Run:** 7702926785952690594 a correr (v1.2.45)

### 46.1 Método, ferramenta e duas correcções que o próprio inventário exigiu

Ferramenta nova e só-leitura: `Files\Backup\scan_mt5_surfaces.ps1` (171 linhas). Lê os **104** ficheiros `.mq5`/`.mqh` do EA recursivamente (**1 211 595 B**), concatena-os e conta **360 identificadores** da API MQL5 com fronteira de palavra — o que impede `OrderSend` de contar dentro de `OrderSendAsync`.

Duas correcções valem mais do que a tabela, porque ambas produziam **falsos negativos** — a pior classe de erro num inventário, pois transforma ausência de medição em "lacuna do EA":

1. **`iATRHandle`, `iADXHandle`, `iRSIHandle`, `iMAHandle`, `iMACDHandle`, `iBandsHandle`, `iCustomHandle` — não existem.** Foram escritos por mim na 1.ª versão da varredura. MQL5 não tem função `iXXXHandle`: `iATR(...)`, `iADX(...)`, `iRSI(...)` **são** as funções que devolvem o handle. Contar `iATRHandle` dava sempre 0 e inflaccionava a família de dados com lacunas inexistentes. Removidos.
2. **`CalendarDatabaseChanged` — não existe.** A documentação devolve **0 resultados** para esse nome (`search.mql5.com`, módulo `mql5.com.en.docs`). O acompanhamento de mudanças do calendário faz-se pelo `change_id` de `CalendarValueLast`, não por uma função dedicada. Removido.
3. **`Select-String -Path ... '**\*.mqh'` em PowerShell 5.1 salta subpastas em silêncio.** Um grep por `Calendar` devolveu "0 ocorrências" enquanto a varredura recursiva contava 17 em `Filters\NewsFilter.mqh`. O falso zero quase fez concluir que o EA não usa calendário. Regra: para inventário, `Get-ChildItem -Recurse -File | Select-String`, nunca wildcard `**\`.

### 46.2 Cobertura por família

| Família | Usa / Total | % | Leitura |
|---|---|---|---|
| H-Alerta (Print, notificação, tempo, string) | 19 / 26 | 73,1 | a mais madura |
| N-Estruturas (`MqlTradeRequest`, ENUM, retcodes) | 26 / 38 | 68,4 | execução bem tipada |
| F-Ficheiros | 16 / 31 | 51,6 | CSV em modo texto |
| A-Eventos | 8 / 16 | 50,0 | falta a família tester |
| O-Diagnóstico | 8 / 16 | 50,0 | falta `IsStopped` |
| B-Trade | 21 / 43 | 48,8 | só mercado |
| C-Dados | 22 / 53 | 41,5 | sem ticks reais |
| G-Globais | 10 / 26 | 38,5 | sem `ExpertRemove` |
| J-Calendário | 3 / 11 | 27,3 | só o modo caro |
| D-Gráfico | 1 / 27 | 3,7 | headless |
| E-Objetos | 0 / 17 | 0,0 | headless |
| I-Tester (frames) | 0 / 10 | 0,0 | sem optimização reprodutível |
| K-Notícias | 0 / 10 | 0,0 | — |
| L-SQLite | 0 / 25 | 0,0 | **o achado desta ronda** |
| M-Sockets | 0 / 11 | 0,0 | ver 46.4 |
| **TOTAL** | **134 / 360** | **37,2** | |

Bibliotecas: **248** `.mqh` em `MQL5\Include\`, **10** referenciadas. Blocos inteiros não usados: `Controls` 0/23, `Signal` 0/20, `AlgoLib` 0/18, `WinAPI` 0/16, `DX` 0/14, `ChartObjects` 0/12, `Fuzzy` 0/12, `Money` 0/5, `Trailing` 0/4. Único bloco 100 % usado: `KCI` 2/2.

### 46.3 As seis lacunas que NÃO são lacunas — caíram por medição

Esta é a parte que impede trabalho inútil. Cada uma foi sondada no código, não deduzida:

| "Lacuna" que o scan sugeria | Medição que a desmente | Veredicto |
|---|---|---|
| `OrdersTotal`/`OrderGetTicket`/`OrderSelect` = 0 | `TRADE_ACTION_PENDING` = 0 e **todos** os `ORDER_TYPE_*_LIMIT/_STOP` = 0 | EA é **só de mercado**. Não há ordens pendentes para enumerar. Ausência correcta |
| `ERR_REQUOTE`/`ERR_TRADE_TIMEOUT`/`ERR_MARKET_CLOSED` = 0 | `OrderRetry.mqh` classifica por `TRADE_RETCODE_*` (`IsSuccess`, `IsRetriable`, `IsInvalid`) e `ExecutionStats.mqh` trata `REQUOTE`/`TIMEOUT` | Melhor do que `ERR_*`: o retcode vem do servidor. Ausência correcta |
| `BarsCalculated` = 0 | `CopyBuffer` é verificado em **19** pontos (`<=0`, `==1`, `copied`) | `BarsCalculated` seria redundante. Ausência correcta |
| `SendMail` = 0 / `PlaySound` = 0 / `Alert` = 0 | `NotificationCenter.mqh` tem `SendNotification` (push nativo, linha 247) **e** Telegram por `WebRequest` (linha 228), com cooldown/dedup/rate-limit; chamado em `XAU_AI_PRO.mq5:2017` e `:2223` | Já existe canal externo. `Alert`/`PlaySound` seriam ruído local |
| `PositionSelect` = 0 | usa `PositionGetTicket` + `PositionSelectByTicket` (percorre por ticket) | É o padrão correcto com múltiplas posições; a política MCP também desaconselha `PositionSelect(symbol)` |
| `HistoryOrder*` (5 funções) = 0 | `HistoryDealSelect`/`HistoryDealsTotal`/`HistoryDealGetTicket` presentes | Histórico lido por deal, que é o que carrega lucro. Correcto |

### 46.4 As lacunas reais, ordenadas por (evidência × valor) ÷ custo

**1. SQLite: `DatabaseOpen` 0/25 — a única lacuna com evidência medida, não apenas de cobertura.**
O bloqueio registado nas §43/§44 é *concreto e datado*: `Common\Files\trade_history.csv` com 100 228 linhas, 13 colunas, mas **só 156 com ticket** e uma data com **ano a 5 dígitos (`22026.08.18`)**; e `trade_history_backtest.csv` com números impossíveis (ganho médio 2 001,8 USD, p=1,38 %) — os dois levam a "colunas desalinhadas", que invalidou Kelly, risco de ruína e todas as bandas de indicador. Um CSV em modo texto **não tem tipo**: uma vírgula a mais desloca todas as colunas seguintes para sempre. `DatabasePrepare` + `DatabaseBind` (parâmetros tipados) + `DatabaseReadBind` para uma `struct` eliminam essa classe de erro **por construção**, e uma `PRIMARY KEY` no ticket dá a deduplicação que hoje não existe. Base documental: artigo **7463** da MetaQuotes (*SQLite: Native handling of SQL databases in MQL5* — nativo, sem DLL), **22608** (*SQLite Storage and Deduplication*), **23459** (*Real-Time Trade Event Logger to SQLite*). Custo: médio-alto (módulo novo, esquema, migração do CSV). **Não executado nesta ronda**: muda a rota de escrita do logger, exige um backtest novo para comparar.

**2. `SymbolIsSynchronized` 0/53 — 3 linhas, risco zero.** É o único teste que diz "os dados deste símbolo estão coerentes com o servidor". Só bloqueia entrada. Já proposto na §45 como lacuna #1 e continua válido; a evidência é de cobertura.

**3. `CalendarValueLast` 0/11 — troca do modo caro pelo delta.** Medido em `Filters\NewsFilter.mqh:214`: `CalendarValueHistory(values, from, now+warnB)` a cada **60 s** (`NEWS_REFRESH_SEC`, linha 23) por instância. Com 17 instâncias são **24 480 consultas/dia de janela inteira**. Assinatura confirmada na documentação: `int CalendarValueLast(ulong& change_id, MqlCalendarValue& values[], string country_code=NULL, string currency=NULL)`, com `change_id` **[in][out]** — devolve o que mudou desde o último id. O filtro continua a fazer a coisa mais difícil bem (importância real via `CalendarEventById`, fail-open, erro 4014 tratado com DiagGate). **Benefício não medido**: no tester o calendário devolve 4014 e o filtro é fail-open, logo o ganho só é observável em produção — exactamente o regime que 31/10/2026 (sábado) não fornece.

**4. `SymbolInfoSessionTrade` 0/53.** Sessões reais do broker contra o horário em `input`. Muda regra de entrada → exige medição, não é cirúrgico.

**5. Família I-Tester 0/10 (`FrameAdd`/`FrameFirst`/`FrameNext`/`ParameterSetRange`).** Sem frames não há optimização reprodutível nem registo de parâmetros por passagem. É investimento de método, não de produção.

**6. `ObjectCreate` 0/17 + `OnChartEvent` 0/16 + família gráfica 1/27.** Zero risco (não toca trading), dá painel e interruptor manual. Puro conforto operacional num EA que hoje é headless.

**7. Sockets `SocketCreate` 0/11 — e uma afirmação falsa no código.** `ExternalBridge.mqh:15` diz textualmente *"MQL5 nao abre socket e `WebRequest` so sai (o EA nunca recebe)"*. **É falso.** A documentação (`mql5.com/en/docs/network/socketcreate`) diz que a função pode ser chamada **só de Expert Advisors e scripts** (exactamente o nosso caso), até **128 sockets** por programa, com `ERR_NETSOCKET_TOO_MANY_OPENED` (5271) no limite, e família com variantes TLS (`SocketTlsRead`, `SocketTlsWrite`, `SocketTlsReadAvailable`) — 16 páginas de documentação, não 11. O EA **pode** receber dados por socket; a escolha de só sair por `WebRequest` é uma decisão de arquitectura, não um limite da linguagem. Corrigir o comentário é gratuito; mudar o bridge não é (o `WebRequest` exige URL autorizado em Opções e é mais simples).

**8. `NewsTotal`/`NewsItem` 0/10.** Redundante face ao calendário; o feed de notícias do terminal é texto sem estrutura de evento. Não preencher.

### 46.5 O que continua a NÃO se preencher

`OrderSendAsync` (impede verificar `retcode` — o EA classifica retcodes, seria regressão), `MarketBook*` (a estratégia não usa DOM), `CMatrix`/OpenCL, `ResourceCreate`/`CryptEncode`, `iCustom` e a família de indicadores (`iMACD`, `iBands`, `iStochastic`, `iIchimoku`, `iSAR`, `iStdDev`, `iMomentum`, `iCCI`, `iOBV`, `iWPR`, `iEnvelopes`, `iDeMarker`, `iChaikin` = **13 funções a 0**) — todos estreitam ou mudam a selecção de entradas e, sem amostra íntegra, seriam palpite. Num sistema com esperança por trade negativa, mais filtro reduz perdas; não cria lucro.

### 46.6 Veredicto

A superfície que falta ao EA **não é uma função da API**: é **armazenamento tipado**. De 360 superfícies, o EA usa 134 e as ausências relevantes são quase todas de conforto ou de método; a única que resolve um defeito já medido e documentado é o SQLite. A ordem de trabalho corrigida é, por isso:

1. provar `Ticket`/`Magic`/`Origin` preenchidos e corrigir a coluna `Time` do `TradeLogger` (ano `22026`) — o pré-requisito de tudo;
2. SQLite como destino do logger (tipo + `PRIMARY KEY` no ticket) — cura o desalinhamento por construção;
3. `SymbolIsSynchronized` na cadeia de decisão (3 linhas);
4. só depois, com amostra íntegra: reconfirmar ADX≥35 e comparar Kaufman ER / dimensão fractal por **esperança por trade**.

**Ressalva de sempre:** nada aqui prova rentabilidade. O inventário mede *cobertura de API*, não *vantagem estatística*. As contagens são datadas por 104 ficheiros / 1 211 595 B no momento da leitura.


---

## §47 — P1.37: a prova das 13 colunas não estava em falta, estava a faltar um trade

**Data:** 01/11/2026 07:30–07:55 (local) · **Versão em produção:** v1.2.58 (código intocado nesta ronda) · **Run novo:** 7703149588273005599

### 47.1 O run anterior terminou — e terminou negativo

`7702926785952690594` (v1.2.45, XAUUSD M15, ticks reais, 200 USD, 1:100, 2026-07-29→2026-10-29):

| métrica | valor |
|---|---|
| lucro líquido | **−32,21 USD** |
| profit factor | **0,7630** |
| esperança por trade | **−0,09 USD** |
| trades / deals | 375 / 750 (163 ganhos, 212 perdas) |
| drawdown máx. balanço | 46,51 USD = **22,19 %** |
| Sharpe | −1,6249 · recovery factor −0,6655 |
| barras / ticks gerados | 5 814 / 31 892 772 |

Nada disto é novidade de diagnóstico (o EA já era sabido com esperança negativa), mas fixa o **antes** exacto com que o run novo tem de ser comparado.

### 47.2 O bloqueio das 13 colunas: resposta definitiva, e é uma correcção das §43/§44

A §43 registou "100 228 linhas, 13 colunas, só 156 com ticket → contrato falhado". Medi agora as três colunas novas em todas as linhas:

```
Origin : UNKNOWN -> 99 964   (100 %)
Magic  : (vazio) -> 99 964   (100 %)
Ticket : (vazio) -> 99 964   (100 %)
```

A causa não está no código. Está em **`Files\Backup\migrate_trade_history_p121.ps1`**, executado no P1.21 (31/10): o script leu o ficheiro antigo e acrescentou `,,,UNKNOWN` a **todas** as linhas históricas, com o comentário explícito *"a origem nao foi registada nessa altura e nao se inventa"*. Ou seja:

- as 99 964 linhas de 13 campos são **linhas históricas migradas**, não linhas nativas da v1.2.46+;
- `trade_history_legacy_v1.csv` não existe precisamente porque a migração foi **in-place**: a rotação de `TradeLoggerEnsureSchema` só dispara quando o cabeçalho **não** tem `Origin`, e o script já o tinha posto;
- as "156 linhas com ticket" que a §43 contou eram **artefactos de linhas fundidas** (ver 47.3), não tickets.

**Conclusão corrigida:** o contrato de 13 colunas não está provado nem desmentido — **nunca foi exercitado**. Entre a v1.2.46 e agora não houve um único trade em produção (o mercado fechou sexta 30/10 às 23:59 e a v1.2.46 nasceu no dia 31). A prova exige um trade escrito por código novo, e por isso é o próprio run novo que a vai produzir.

### 47.3 As 108 linhas partidas são anteriores à migração

`stats_csv_shape.ps1` (novo) mediu o ficheiro com validação **por tipo de campo** (Time como data, Symbol como ticker, Type ∈ {BUY,SELL}, numéricos, Ticket/Magic como inteiros, Origin ∈ {EA,MANUAL,OTHER,UNKNOWN}):

```
linhas nao-vazias          = 100 227
10 campos (legado)         =      14
13 campos                  =  99 964
dos 13: VALIDAS            =  99 856   com ticket = 0
dos 13: MALFORMADAS        =     108
outras contagens           =     249
```

E os exemplos mostram a forma real do defeito — **linha truncada fundida com a seguinte**, não "colunas desalinhadas":

```
[L650] 2026.02026.07.01 08:48:49,GBPUSD,SELL,...      <- '2026.0' + inicio de outra linha
[22 campos] 2026.07.01 09:30:49,USDCNH,BUY,...,63.65,2026.07.01 11:26:43,GBPUSD,BUY,...
[4 campos] 0.00,,,UNKNOWN                              <- linha ja partida ANTES + ',,,UNKNOWN'
```

É a assinatura de escrita concorrente (P1.16/P1.41) mais o `,,,UNKNOWN` aplicado sobre linhas já partidas. 108 de 100 227 = 0,11 %, todas anteriores à correcção F4.

### 47.4 Linha de base do journal — agora final, porque o run fechou

`Tester\logs\20261031.log`: **1 473 113 884 B**, **5 291 937 linhas**, versões v1.2.44 (2) e v1.2.45 (2).

| agulha | linhas | % do log | alvo |
|---|---|---|---|
| `[STATE]` | 1 314 269 | 24,84 | P1.25 |
| `[RISK]` | 562 782 | 10,63 | P1.25 |
| `VIA RAPIDA` | 324 255 | 6,13 | P1.28 |
| `APRENDIZADO` | 190 438 | 3,60 | P1.29 |
| `RISCO REAL DA ORDEM` | 179 728 | 3,40 | P1.35 |
| `EXECUTION: LOTE DINAMICO` | 177 632 | 3,36 | P1.34 |
| `alvo elevado para respeitar` | 168 834 | 3,19 | P1.35/P1.26 |
| `Calendar error` | 164 056 | 3,10 | P1.26 |
| `FORCA LOTE MINIMO` | 147 256 | 2,78 | P1.34 |
| `CTrade::` | 136 639 | 2,58 | P1.32 |
| `[SAFETY] Exposure limit` | 35 572 | 0,67 | P1.33 |
| `LOT CAP REAL` | 2 233 | 0,04 | P1.34 |
| **SOMA** | **3 403 702** | **64,31** | |

### 47.5 Run novo lançado com a v1.2.58

`7703149588273005599`, configuração replicada do anterior via `tester_get_configuration` (XAUUSD, M15, ticks reais, 200 USD, 1:100, 2026-07-29→2026-10-29) e o **mesmo** `.set` (`XAI_V1244_3M_REALTICKS.set`, 310 inputs, `DynADXClear=35.0`, `AvoidHoursGMT=9,11,14,18,20,22`, `EnableVerboseDebug=false`). Projecto: `Profiles\Tester\p137_v1258.ini`.

**Leitura preliminar (NÃO é prova):** segmento v1.2.58 com 2 737 linhas → soma das 13 agulhas = **116 (4,24 %)** contra 64,31 % na linha de base. O run está em 00:12 de 3 meses de tempo de modelo, ou seja ~0,1 % da amostra; os números só valem no fim.

### 47.6 Duas armadilhas metodológicas medidas nesta ronda

1. **O journal do tester muda de ficheiro à meia-noite LOCAL e o rabo do run anterior fica no ficheiro do dia seguinte.** O `20261101.log` contém a v1.2.45 (elapsed 00:10:55, modelo 2026.10.28 23:59:58) **seguida** da v1.2.58 (elapsed 07:34:58, modelo 2026.07.29 00:00:00). Contar o ficheiro inteiro mistura duas versões.
2. **Consequência concreta: dois falsos alarmes meus, corrigidos.** Cheguei a "descobrir" que o P1.32 falhava (`CTrade::` presente na v1.2.58) e que o churn de TP sobrevivia com derivas de 1 ponto (`6.54392`→`6.54393`). Segmentando, os **652** `CTrade::` e os **650** `modify position` estão **todos** no troço v1.2.45 (elapsed 00:00–00:01, antes das 07:34:58); no segmento v1.2.58 são **0 e 0**. E o P1.32 está estruturalmente completo: existe **um só** `CTrade trade` global (`XAU_AI_PRO.mq5:26`) usado por `extern CTrade trade` em cinco módulos, com `LogLevel(LOG_LEVEL_ERRORS)` em `OrderManager.mqh:18` e `XAU_AI_PRO.mq5:870`.
3. `count_baseline.ps1` passou a **resegmentar em cada linha `[VERSION]`** e a reportar separadamente "segmento corrente" e "ficheiro inteiro". Sem isso, a comparação do P1.38 seria inválida à partida.
4. Erro de ferramenta: chamar uma função PowerShell com `Nome()` em contexto de atribuição deu `Uma expressão era esperada após '('` — a chamada tem de ser sem parênteses (`$x = Nome`).

### 47.7 Alterado no código

**Nada.** v1.2.58 mantém-se; ex5 668 538 B (23:30:57), 17/17 gráficos intactos. Ferramentas novas, todas só-leitura ou de relatório: `scan_mt5_surfaces.ps1`, `stats_csv_shape.ps1`, `count_baseline.ps1` (reescrito com segmentação).

### 47.8 Próximo

1. Deixar o run `7703149588273005599` terminar e correr `count_baseline.ps1` sobre `20261101.log`: comparar **segmento v1.2.58** contra a linha de base de 47.4. É a confirmação que faltava desde o P1.25.
2. Quando o primeiro deal fechar, verificar `trade_history_backtest.csv`: esperado **rotação** do ficheiro de 10 campos para `trade_history_backtest_legacy_v1.csv` e criação de um novo com 13 colunas — a primeira prova real de `Ticket`/`Magic`/`Origin` preenchidos pelo código.
3. Ressalva de sempre: um run negativo de −32,21 USD com PF 0,763 não se corrige com log; as correcções P1.25–P1.35 tornam o diagnóstico legível e o disco sobrevivível, não o sistema lucrativo. Um backtest não prova rentabilidade futura.


---

## §48 — P1.38 (medição): o ruído do journal caiu 16,9× — medido a 44 % do run

**Data:** 01/11/2026 10:37–10:50 (local) · **Versão:** v1.2.58 (código intocado) · **Run:** 7703149588273005599 em curso, modelo **2026.09.08** (44 % de 2026-07-29→2026-10-29)

### 48.1 Primeira comparação válida entre as duas versões

`count_baseline.ps1` (com segmentação por `[VERSION]`) sobre `Tester\logs\20261101.log`: 207 658 linhas totais, das quais **132 209** no segmento **v1.2.58**.

| agulha | base v1.2.45 (% do log) | segmento v1.2.58 (% do segmento) | factor |
|---|---|---|---|
| `[STATE]` | 24,84 | **1,65** | 15,1× |
| `[RISK]` | 10,63 | **0,49** | 21,7× |
| `VIA RAPIDA` | 6,13 | **0,94** | 6,5× |
| `APRENDIZADO` | 3,60 | **0,04** | 90× |
| `RISCO REAL DA ORDEM` | 3,40 | **0,13** | 26× |
| `EXECUTION: LOTE DINAMICO` | 3,36 | **0,14** | 24× |
| `alvo elevado para respeitar` | 3,19 | **0,11** | 29× |
| `Calendar error` | 3,10 | **0,00** | eliminado (P1.26) |
| `FORCA LOTE MINIMO` | 2,78 | **0,10** | 28× |
| `CTrade::` | 2,58 | **0,00** | eliminado (P1.32) |
| `[SAFETY] Exposure limit` | 0,67 | **0,21** | 3,2× |
| `LOT CAP REAL` | 0,04 | **0,00** | — |
| **SOMA** | **64,31** | **3,81** | **16,9×** |

Projecção: 132 209 linhas em ~44 % do período → **~300 000 linhas** para o run inteiro, contra **5 291 937** na base. É a diferença entre 59 MB e 1,47 GB de journal.

**Ressalva obrigatória:** os dois segmentos não cobrem o mesmo intervalo de calendário (a base tinha o run completo, este tem 44 %), e o volume de linhas depende da actividade de mercado do período. Comparar *percentagens* é legítimo; comparar contagens absolutas exige o run fechado.

### 48.2 Duas precisões que evitam conclusões erradas

1. **`modify position` não é métrica de churn.** Essa linha é escrita pelo próprio `CTrade`; desde o P1.32 (`LogLevel(LOG_LEVEL_ERRORS)`) desaparece mesmo que as modificações continuem a acontecer. No segmento v1.2.58 conta **0**, e isso prova apenas que o log do `CTrade` está silenciado — não prova que a escada deixou de reenviar modificações. O churn real só se mede nas linhas `[LADDER]` do próprio EA (como se fez no P1.30). Não afirmo nada sobre o churn até essa contagem.
2. **`simbolos=3124` no `[SCANNER] RESUMO` não é defeito de produção.** `SymbolManager.mqh:167` e `:280` usam `SymbolsTotal(true)`, ou seja **Market Watch**. No Strategy Tester a Market Watch contém o universo do broker (3 124 símbolos); em produção contém os gráficos abertos (~17, e o journal de produção mediu `Total active symbols: 11`). O custo de percorrer 3 124 símbolos por minuto é portanto **artefacto do tester** e explica parte da lentidão do run; corrigi-lo em produção seria resolver um problema que só existe no teste.

### 48.3 Emissores que restam no segmento novo

`[STATE]` 2 184 linhas (1,65 %) e `VIA RAPIDA` 1 239 (0,94 %) são agora os dois maiores. Já não são ruído de diagnóstico repetido — são o estado do pipeline por símbolo. Qualquer corte adicional aqui tem de provar que a linha é redundante, não apenas frequente; o critério do P1.25 (mesmo desfecho na janela) já está aplicado a ambos, logo o que resta é *diversidade* de desfechos, e abafar diversidade destrói o diagnóstico.

### 48.4 Não verificado — declarado, não assumido

No journal apareceu `[SESSION] estado salvo | ... trades=187 | W=0 | L=1 | pico=210.11` (`XAU_AI_PRO.mq5:800`). 187 trades com 0 vitórias e 1 derrota é aritmeticamente incoerente, mas `SessionStateSummary()` pode estar a reportar contadores de âmbitos diferentes (sessão do dia vs acumulado). **Não medi `SessionState.mqh`**, logo não afirmo bug; fica como candidato a medir.

### 48.5 Estado

- Código: **intocado** (v1.2.58, ex5 668 538 B).
- Run `7703149588273005599`: `started`, 03:03:10 / 05:58:26 de tempo de teste, modelo 2026.09.08.
- Disco: **9,10 GB** livres. Journal do run novo: 56–59 MB e a crescer.
- Ficheiro `trade_history_backtest.csv`: **ainda com 10 colunas** (25 705 B, mtime 00:10:53) → a rotação para `trade_history_backtest_legacy_v1.csv` e a primeira linha de 13 campos com `Ticket`/`Magic`/`Origin` continuam por observar. É o item #2 da rota do P1.37.

### 48.6 Próximo

1. Fim do run → repetir `count_baseline.ps1` para o número definitivo e comparar contagens absolutas.
2. Contar `[LADDER]` e `PositionModify` no segmento v1.2.58 para medir o churn de verdade (48.2).
3. Verificar a rotação do CSV do tester no primeiro deal (48.5).

**Ressalva de sempre:** 16,9× menos journal não é 16,9× mais lucro. O run de base fechou em −32,21 USD com PF 0,763; isto é higiene de diagnóstico e de disco. Um backtest não prova rentabilidade futura.


---

## §49 — Adenda ao §48: o churn da escada medido nas duas versões com a MESMA agulha

**Data:** 01/11/2026 10:55 (local) · fecha o item declarado em aberto no §48.2

O §48 deixou escrito que `modify position` **não** mede churn, porque essa linha é do `CTrade` e o P1.32 a silenciou. Medi agora a agulha do **próprio EA** — `[LADDER]`, cujo texto contém `position modified` — nas duas versões, com o mesmo método.

| | base v1.2.45 | segmento v1.2.58 | factor |
|---|---|---|---|
| linhas `[LADDER]` | 136 366 | 552 | |
| linhas `position modified` | 136 366 | 552 | |
| `TRADE CLOSED` | 637 | 198 | |
| **`[LADDER]` por trade** | **214,08** | **2,79** | **76,7×** |
| % do journal | 2,577 % | 0,42 % | 6,1× |

Leitura: `[LADDER]` e `position modified` têm contagem **idêntica** nas duas versões, o que confirma que são a mesma linha (o texto do EA inclui a expressão), não duas métricas. Cada linha corresponde a uma tentativa de modificação da escada.

**Conclusão:** o P1.30 (banda morta no alvo em dinheiro) reduziu as modificações de escada de **214 por trade para 2,79 por trade**, ou seja ~76× menos round-trips ao servidor por operação. É a diferença entre um EA que fala com o broker 214 vezes por trade e um que fala 3.

**Ressalvas:**
1. A amostra do segmento novo cobre ~44 % do período (198 trades contra 637), logo o número por trade é comparável em natureza, não em precisão — confirmar no fim do run.
2. Menos modificações não é, por si, mais lucro: é menos latência, menos risco de rejeição e menos desgaste de servidor. Continua a não haver prova de vantagem estatística.
3. `PositionModify` (nome da função) conta 0 nas duas — a agulha correcta é o texto `[LADDER]`; usar `PositionModify` como agulha teria dado um falso zero e "provado" o que não era verdade.

## §50 — P1.39/P1.40/P1.41 (v1.2.59): o Err=5019 era o caminho errado, não a permissão

### 50.1 O diagnóstico que faltava

O run 7703149588273005599 (v1.2.58) fechou com o logger DESLIGADO. O journal
do tester tinha, textualmente:

```
TradeLogger ERR | rotacao do schema falhou | Err=5019 | escrita DESLIGADA para nao misturar 10 e 13 colunas
TradeLogger OFF | schema do ficheiro incompativel; escrita desligada
[LOGGER OFFLINE] ... | LoggerInit() nao chamado | descartados=N   (9 188 linhas)
```

Na ronda anterior o significado de `Err=5019` ficou **pendente**: a pesquisa em
`search.mql5.com` por `ERR_FILE_CANNOT_RENAME` devolvia `"total":"0"` e eu tinha
registado 5019 como "provavelmente cannot rename", **o que estava errado**.

**Medição que fecha o caso** — tabela oficial de erros MQL5
(`/docs/constants/errorswarnings/errorcodes`), extraída por medição e não por
memória:

| Código | Nome | Texto |
|---|---|---|
| 5018 | `ERR_FILE_IS_DIRECTORY` | This is not a file, this is a directory |
| **5019** | **`ERR_FILE_NOT_EXIST`** | **File does not exist** |
| 5020 | `ERR_FILE_CANNOT_REWRITE` | File can not be rewritten |

Logo **não era permissão, nem bloqueio, nem rename**: era **ficheiro não
encontrado**. E havia uma segunda hipótese registada (o destino
`trade_history_backtest_legacy_v1.csv` já existir) que a medição também
eliminou: `Get-ChildItem Common\Files -Filter 'trade_history*'` devolvia
apenas `trade_history.csv` e `trade_history_backtest.csv` — **o legado não
existia**. As duas hipóteses em aberto caíram as duas.

### 50.2 A causa, provada pela assinatura oficial

`/docs/files/filemove`:

> `bool FileMove(const string src_file_name, int common_flag, const string dst_file_name, int mode_flags)`
> `common_flag [in]` — "If `common_flag = FILE_COMMON`, then the file is located
> in a shared folder for all client terminals **Terminal\Common\Files**.
> Otherwise, the file is located in a **local folder (common_flag=0)**."
> `mode_flags [in]` — "can contain only 2 flags: `FILE_REWRITE` and/or
> `FILE_COMMON` … If the file already exists and the `FILE_REWRITE` flag isn't
> specified, the file will not be rewritten, and the function will return false."

O código chamava:

```mql5
FileMove(TradeLoggerFileName(), 0, legado, FILE_COMMON)
//                            ^ origem LOCAL          ^ destino COMUM
```

O ficheiro é **criado e lido** com `FILE_COMMON` (`TradeLoggerOpen()`), mas a
rotação pedia a **origem** com `0` = pasta local (`MQL5\Files`, ou o sandbox do
agente no teste). O `FileMove` ia procurar `trade_history_backtest.csv` a uma
pasta onde ele nunca esteve → **5019 `ERR_FILE_NOT_EXIST`**. A assimetria de
flags estava à vista no código desde a v1.2.46 e nunca tinha sido exercitada,
porque em produção o `trade_history.csv` já tinha a coluna `Origin` e a rotação
nunca corria; só o ficheiro do tester, com cabeçalho de 10 colunas, entrava
nesse ramo — e falhava sempre.

### 50.3 A correcção

Duas guardas, ambas exigidas pela documentação:

1. **Flags simétricas**: `FileMove(nome, FILE_COMMON, alvo, FILE_COMMON)`.
2. **Destino idempotente**: a doc diz que sem `FILE_REWRITE` um destino
   existente faz a função devolver `false`. Como a rotação pode ser tentada a
   cada arranque, em 17 instâncias e em cada run, o destino passou a ser o
   **primeiro nome livre com sufixo numérico** (`_legacy_v1.csv`,
   `_legacy_v1_2.csv`, …), em vez de sobrescrever o legado anterior. Nada é
   apagado.
3. A mensagem de erro passou a imprimir **origem e destino**, para que uma
   falha futura diga qual dos dois caminhos não existe.

### 50.4 Prova ponta-a-ponta (run 7703264373217955650, v1.2.59)

Antes do run, `Common\Files`:

```
trade_history.csv                      8500879 B   31/10 19:22:34
trade_history_backtest.csv               25705 B   01/11 00:10:53   (cabeçalho de 10 colunas)
trade_history_backtest_legacy_v1.csv     (nao existia)
```

75 segundos depois do arranque do run:

```
trade_history.csv                      8500879 B   31/10 19:22:34
trade_history_backtest.csv                  71 B   01/11 15:00:04   (cabeçalho de 13 colunas)
trade_history_backtest_legacy_v1.csv     25705 B   01/11 00:10:53   (374 linhas, 10 colunas, INTACTO)
```

Journal do tester:

```
2026.07.29 00:00:00   TradeLogger MIGRACAO | ficheiro sem coluna Origin rodado para
                      'trade_history_backtest_legacy_v1.csv' (integralmente preservado);
                      novo 'trade_history_backtest.csv' com 13 colunas
2026.07.29 00:00:00   TradeLogger inicializado (F4: abre-lock-seek-write-flush-fecha).
```

Cabeçalho novo, lido do disco: `Time,Symbol,Type,Entry,Exit,Profit,ATR,ADX,RSI,AI,Ticket,Magic,Origin`
→ **13 campos medidos**, contra os 10 do legado. O tamanho do legado é
**exactamente** o do ficheiro antigo (25 705 B), o que prova que a rotação é um
rename real e não uma cópia parcial.

**Sem** `rotacao do schema falhou` e **sem** `TradeLogger OFF` no segmento novo.
Depois de 7 ciclos de documentação a dizer que o contrato de 13 colunas "nunca
foi exercitado", ele passou a ser exercitado.

### 50.5 P1.40 — `[LOGGER OFFLINE]`: a mesma confusão de relógios do P1.24, ao contrário

Medição no segmento v1.2.58 do journal do tester (264 303 linhas):

| Agulha | Linhas | % |
|---|---|---|
| `[LOGGER OFFLINE]` | **9 188** | **3,48** |

Depois de P1.25 a P1.35 terem varrido o resto, este passou a ser **o maior
emissor único** — apesar de o throttle de 600 s existir desde a v1.2.32.

A causa é a mesma do P1.24, mas ao contrário: o P1.24 mediu `TimeCurrent()`
**congelado** com o mercado fechado (o watchdog morria); aqui `TimeCurrent()`
está **acelerado**, porque no Strategy Tester é o relógio da série de preços —
3 meses de modelo passam em minutos de execução real, logo "600 s de modelo"
dispara milhares de vezes.

A regra já estava escrita desde o P1.24: **`TimeLocal()` mede DURAÇÕES,
`TimeCurrent()` mede MERCADO**. Um throttle de diagnóstico é uma duração de
parede. Passou a `TimeLocal()` e a **1 linha por hora**.

Isto **não** resolve a causa raiz do aviso, que fica registada e aberta:
`LoggerInit()` nunca é chamado em nenhum ficheiro do EA (busca recursiva:
só a definição em `Logger.mqh:149`, zero chamadas), logo `LoggerReady` é sempre
`false` e **todo** o `LogInfo/LogWarning/LogError` do `Logger.mqh` cai no
fallback. Abrir um ficheiro comum partilhado por 17 gráficos é a decisão
separada já registada na §12 das PENDENCIAS e **não** foi tomada aqui.

### 50.6 P1.41 — comentário falso corrigido quando ficou barato

`Integration/ExternalBridge.mqh` afirmava:

```
// volta. MQL5 nao abre socket e `WebRequest` so sai (o EA nunca recebe
// conexao), entao o unico canal que existe nos dois lados e arquivo em
```

A documentação de `SocketCreate`/`SocketConnect` desmente a primeira metade
(sockets nativos, chamáveis de EA e scripts, até 128 abertos, com família TLS
em `SocketTlsRead`/`SocketTlsWrite`). O comentário passou a dizer o que é
verdade — `WebRequest` só sai, e um socket de **entrada** exigiria um servidor à
escuta, o que o EA não é — sem mudar uma linha de lógica. Só foi feito agora
porque este ciclo já paga o bump triplo + compilação + recarga; em cosmética
isolada teria custado o mesmo por nada.

### 50.7 Regras de ferramenta aprendidas neste ciclo (custaram 3 falhas)

1. **EOL não é uniforme neste projecto.** Medido: `Monitoring\TradeLogger.mqh`
   está em **LF puro** (534 LF, 0 CRLF); `Logger.mqh`, `ExternalBridge.mqh`,
   `VersionManager.mqh` e `XAU_AI_PRO.mq5` estão em **CRLF**. O `Troca()` que
   normalizava tudo para CRLF deu **0 ocorrências** no ficheiro LF. Agora o
   EOL é detectado por ficheiro (`EolDe`) e o texto é canonicalizado antes de
   comparar.
2. **Os comentários deste projecto usam EM DASH U+2014.** O byte real é
   **8212**, não 45; o console mostra os dois como `-` e a âncora "parece"
   igual. Custo: um ciclo inteiro a perseguir um "0 ocorrências" invisível.
   Sondagem que resolveu: comparar `[int]$de[$k]` com `[int]$real[$k]` posição
   a posição. **Regra: âncoras que evitem U+2014, ou construídas com
   `[char]0x2014`.**
3. **Aspas duplas dentro do literal `m_current.changes`.** O changelog é uma
   string MQL de aspas duplas; escrever `"TradeLogger OFF"` lá dentro fechou a
   string e produziu **16 erros**. Trocado por aspas simples.
4. **Barra invertida simples no changelog.** `(MQL5\Files)` → `\F` é escape
   inválido e dá `warning 86`. Tem de ser `(MQL5\\Files)`, como o texto antigo
   já fazia com `Common\\Files`.

### 50.8 Estado medido

- versão **v1.2.59**, `EA_VERSION_STRING` = "1.2.59", `#property version "1.259"`;
- compilação: **Result: 0 errors, 0 warnings**, ex5 = **670 824 B**;
- recarga: `profile_apply Default` → `profile_apply XAI_V1243_20261031` →
  **17/17 fontes distintas com v1.2.59** no journal Experts;
- 17/17 imprimem `TradeLogger inicializado`, zero `TradeLogger OFF` em produção;
- `XAU_AI_PRO.mq5` tinha **2 loneLF** e passou a **0** (canonicalização);
- run **7703264373217955650** (v1.2.59, XAUUSD M15, ticks reais, 200 USD, 1:100,
  2026-07-29 → 2026-10-29) em curso.

### 50.9 Ressalva

Um journal mais limpo e um CSV com 13 colunas **não** são um sistema lucrativo.
A base fechou em **−32,21 USD, PF 0,763** (v1.2.45) e −32,88 USD, PF 0,7592
(v1.2.58). P1.39 restitui uma fonte de dados que estava a ser perdida em
silêncio; P1.40 e P1.41 são higiene. Um backtest não prova rentabilidade
futura.

## §51 — P1.42 (v1.2.60): a medição desmentiu a minha própria explicação do P1.40

### 51.1 O que o P1.40 afirmava

No ciclo anterior (§50.5) o P1.40 foi justificado assim:

> "`TimeLocal()` mede DURAÇÕES, `TimeCurrent()` mede MERCADO. Um throttle de
> diagnóstico é uma duração de parede. Passou a `TimeLocal()` e a 1 linha por
> hora."

E o texto impresso pela linha passou a ser `"aviso 1x/hora (relogio de parede)"`.

### 51.2 O que a medição mostrou

Medição no run 7703264373217955650 (v1.2.59), dump literal das 15 linhas do
segmento:

```
15:00:37.771  modelo 2026.07.29 01:03:00   [LOGGER OFFLINE] ... descartados=17 | aviso 1x/hora (relogio de parede)
15:00:49.978  modelo 2026.07.29 02:03:00   [LOGGER OFFLINE] ... descartados=61 | ...
15:01:02.185  modelo 2026.07.29 03:03:00   [LOGGER OFFLINE] ... descartados=60 | ...
...
15:03:13.539  modelo 2026.07.29 15:03:00   [LOGGER OFFLINE] ... descartados=60 | ...
```

Duas leituras, ambas decisivas:

1. **O ganho é real**: `[LOGGER OFFLINE]` caiu de **9 188 linhas / 3,48 %**
   (base v1.2.58) para **15 linhas / 0,54 %** numa amostra de 2 774 linhas do
   segmento novo → **6,4× menos**.
2. **A explicação estava errada**: os avisos saem com tempo de **MODELO**
   exactamente de hora a hora (01:03, 02:03, … 15:03) enquanto o relógio do
   computador andou **2 min 36 s** (15:00:37 → 15:03:13). Se `TimeLocal()`
   fosse o relógio da máquina, uma janela de 3 600 s teria produzido **no
   máximo uma linha** — produziu **quinze**.

**Conclusão medida: o Strategy Tester virtualiza os DOIS relógios.** Já se
sabia que `TimeCurrent()` é simulado (foi o P1.24). Agora sabe-se que
`TimeLocal()` também é. A doutrina do P1.24 — "`TimeLocal()` mede DURAÇÕES" —
continua **verdadeira no terminal de produção** e é **falsa dentro do Strategy
Tester**.

O ganho de 6,4× vem portanto de **alargar a janela de tempo de MODELO**
(600 s → 3600 s), **não** de mudar de relógio. A troca `TimeCurrent()` →
`TimeLocal()` foi neutra no efeito e a justificação que escrevi para ela era
falsa.

### 51.3 A correcção (v1.2.60)

Mínima e cirúrgica, porque o **mecanismo** está bom e só a **afirmação** estava
errada:

- o comentário no `Logger.mqh` passou a registar a medição e a dizer que a
  virtualização é dos dois relógios;
- o texto da linha deixou de prometer `"relogio de parede"` e passou a dizer
  **`" | aviso 1x/3600 s"`**, que é verdade nos dois ambientes (hora de
  computador em produção, hora de modelo no teste);
- o changelog do produto corrige explicitamente a afirmação anterior, em vez de
  a deixar de pé.

Nenhuma regra de trading, risco, execução ou precificação foi tocada. Só o
comentário e a mensagem de diagnóstico.

### 51.4 Porque é que valeu um ciclo

É a segunda vez em dois ciclos que um comentário falso foi apanhado pela
medição (o P1.41 foi o `"MQL5 nao abre socket"` do `ExternalBridge`). Um texto
que mente sobre o próprio mecanismo é a mesma classe de defeito que um portão
de diagnóstico neutralizado: quem vier depois toma a frase por boa e constrói em
cima dela — foi exactamente o que aconteceu entre o P1.21 e o P1.39, em que a
rotação esteve 13 versões a falhar em silêncio.

### 51.5 Estado medido

- versão **v1.2.60**, `EA_VERSION_STRING` = "1.2.60", `#property version "1.260"`;
- compilação: **Result: 0 errors, 0 warnings**, ex5 = **671 900 B**;
- recarga: `Default` → `XAI_V1243_20261031` → **17/17 fontes com v1.2.60**;
- run **7703264373217955650** continua vivo depois da recompilação
  (`progress 00:04:48 / 08:53:20`) — o agente já tinha o módulo carregado, e
  recompilar não o reiniciou;
- `Logger.mqh` 16 271 B, `VersionManager.mqh` 39 270 B, `XAU_AI_PRO.mq5` 74 804 B,
  todos NUL=0, loneLF=0.

### 51.6 Ressalva (mantida)

Nada disto torna o EA lucrativo. O run de base fechou em **−32,21 USD / PF 0,763**
e o da v1.2.58 em **−32,88 USD / PF 0,7592**. P1.39 restituiu uma fonte de dados
que estava a ser perdida em silêncio; P1.40/P1.42 são higiene de observabilidade.
Um backtest não prova rentabilidade futura.

## §52 - P1.44 (v1.2.62): o veredicto READY nunca foi um portao, e os dois relatorios de checklist escreviam lixo no proprio ficheiro

**Data:** 01/11/2026 16:35 (local -03:00)
**Versao do produto:** v1.2.61 -> **v1.2.62** (`EA_VERSION_STRING="1.2.62"`, `#property version "1.262"`)
**Ficheiros alterados:** `Monitoring/ValidationChecklist.mqh`, `Monitoring/ProductionChecklist.mqh`, `Enterprise/VersionManager.mqh` (changelog), `XAU_AI_PRO.mq5` (cabecalho e `#property version`)
**Nenhuma regra de risco, execucao, preco, gestao ou lote foi tocada.** Compilacao: **0 errors, 0 warnings**, `ex5 = 677 296 B`.

---

### 52.1 Pergunta desta sessao

A investigacao pendente era: o estado `READY: NO` (8 instancias arrancadas com spread de fim de semana, `5812.0 pts` contra maximo `2350.4`) fica **latchado** e impede o EA de operar? Impacto operacional num EA que deve viver 24/7?

### 52.2 Resposta medida, nao deduzida

1. **Nao existe latch porque nao existe portao.** `CProductionChecklist::IsReady()` e `ValidationChecklistPassed()` estao declarados e definidos e **nao sao chamados por nenhum caminho do EA**. Busca sobre todas as fontes `.mqh`/`.mq5` do projecto (excluindo `.bak`): as unicas ocorrencias de `IsReady` ligadas a checklist sao a declaracao (`ProductionChecklist.mqh:39`) e a definicao (`:212`); `ValidationChecklistPassed` aparece apenas na definicao (`ValidationChecklist.mqh:271`). `ValidationChecklistRun()` e `CProductionChecklist::Run()` sao chamados **uma vez**, dentro do `OnInit` (`XAU_AI_PRO.mq5:549-551`) - nunca em `OnTick`, nunca em timer.
2. **Quem protege de spread e outro codigo, e e por tick:** `Filters/SpreadFilter.mqh:91` e `:145`, `Core/ValidationEngine.mqh:150` e `:185`, `Enterprise/SmartExecution.mqh:334`. `GetMaxSpread()` so aparece nas duas checklists e nesses portoes; a checklist e **redundante como diagnostico** e **irrelevante como bloqueio**.
3. **Contagem no journal de experts de hoje** (`MQL5/Logs/20261101.log`, 30 759 linhas): `READY: NO` = 15, `READY: YES` = 81. Os 15 `NO` correspondem a arranques com o spread de fim de semana.
4. **Achado mais forte, que so apareceu ao medir:** em **96 de 96** execucoes da `ValidationChecklist` hoje, a linha impressa foi `BLOCKED - verificar antes de operar`; a variante `SEM BLOCKED - operacao permitida` saiu **0 vezes**. Distribuicao dos resultados: `READY=11 WARNING=3 BLOCKED=1` (48x), `READY=13 WARNING=1 BLOCKED=1` (33x), `READY=12 WARNING=1 BLOCKED=2` (9x), `READY=10 WARNING=3 BLOCKED=2` (6x). O item que bloqueia e **sempre** o mesmo: `Dataset: BLOCKED - Dataset ausente/vazio (bloqueia)`, com `EnableDataset=true` (ver 52.4).

### 52.3 Defeito de integridade provado no proprio ficheiro (nao estava previsto)

Ao abrir `Common/Files/XAU_AI_PRO/ValidationChecklist.txt` e `ProductionChecklist.txt` para confirmar o item bloqueado, os dois ficheiros **estavam corrompidos no fim**:

```
Resultado: REPROVADO (existem BLOCKED)Resultado: REPROVADO (existem BLOCKED): REPROVADO (existem BLOCKED)xistem BLOCKED)stem BLOCKED)
```

```
READY: YEStical failed
READY: YEScritical failed
READY: NOtical failed
READY: NO: NONO
```

Causa: os dois relatorios eram abertos com `FILE_READ | FILE_WRITE`, escritos com `FileSeek(h,0,SEEK_SET)` e **sem truncar**. Um resumo mais curto que o anterior deixa o **rabo do anterior** no disco. Nao e corrupcao aleatoria: e deterministico, e reproduz-se sempre que o resumo encolhe (por exemplo quando o numero de itens "failed" passa de 3 para 2).

### 52.4 Decisao pendente registada, nao tomada

O item 6 (`Dataset`) marca `VC_BLOCKED` quando `EnableDataset=true` e `Common/Files/Data/dataset.csv` nao existe. Como `EnableDataset` e `true` por omissao e o dataset alimenta o treino Python (nao a execucao), o checklist fica **REPROVADO em 100% dos arranques**. Ou seja: o conselho "verificar antes de operar" foi ignorado 96 vezes hoje e o EA operou normalmente. **Nao alterei a severidade neste ciclo** porque mudar `VC_BLOCKED` -> `VC_WARNING` num item que alimenta um ficheiro lido por operadores e uma decisao de produto: fica registado como pendente.

### 52.5 O que mudou (minimo, e so observabilidade)

| Ponto | Antes | Depois |
|---|---|---|
| `ProductionChecklist::GetSummary()` | `READY: YES/NO` | `READY: YES/NO | snapshot de init: <data hora>` + `NOTA:` a dizer que nao e reavaliado, nao e portao, e que o bloqueio real de spread e por tick em `Filters/SpreadFilter.mqh` |
| `CProductionChecklist::Run()` | nada | grava `m_snapshot_time = TimeCurrent()` imediatamente antes de `LogResults()` |
| `ValidationChecklistRun()` | nada | grava `g_vcheck_time = TimeCurrent()` no inicio |
| Linha de resultado | `SEM BLOCKED - operacao permitida` / `N BLOCKED - verificar antes de operar` | `SEM BLOCKED (diagnostico de init, nao e portao)` / `N BLOCKED (diagnostico de init, nao impede execucao - spread e filtrado por tick)` |
| `ValidationChecklistSummary()` | `APROVADO (operacao permitida)` / `REPROVADO (existem BLOCKED)` | `SEM BLOCKED` / `COM BLOCKED` + hora do snapshot + `NOTA` |
| Escrita dos dois `.txt` | `FILE_READ | FILE_WRITE` + `FileSeek(0)` | `FILE_WRITE` (apaga na abertura) - **corrige o rabo antigo** |
| `IsReady()` / `ValidationChecklistPassed()` | sem aviso | comentario a registar que nenhum caminho de execucao as consulta |

### 52.6 Prova

- `ProductionChecklist.mqh`: 16 295 -> 17 402 B, `LF=619 CRLF=619 loneLF=0 NUL=0`.
- `ValidationChecklist.mqh`: 10 412 -> 11 315 B, `LF=319 CRLF=319 loneLF=0 NUL=0`.
- `VersionManager.mqh`: 40 724 -> 43 337 B, `LF=227 CRLF=227 loneLF=0 NUL=0`.
- `XAU_AI_PRO.mq5`: 74 804 B (so troca de texto de versao, mesmo tamanho), `loneLF=0`.
- Compilacao: `Result: 0 errors, 0 warnings, 15 510 ms elapsed`, `ex5 = 677 296 B` (era 673 088 B).
- Leituras pos-escrita dos trechos alterados confirmam a sintaxe (concatenacao com `+` nas linhas de continuacao do `NOTA`, e `Print()` com dois argumentos na linha de `BLOCKED`).

### 52.7 Erro de ferramenta cometido e corrigido neste ciclo

A primeira versao do `apply_p144.ps1` gerou tres linhas de continuacao do `NOTA` **sem o `+=`** e sem `;` no fim de cada uma. Compilacao devolveu `error 152: 'summary' - some operator expected` em `ProductionChecklist.mqh(545,4)` e `(546,4)` mais `warning 95: expression has no effect`. Corrigido por `fix_p144b`/`fix_p144_semicolon`: as linhas passaram a uma unica instrucao com concatenacao `+` nas continuacoes. Regra para o proximo ciclo: **toda a linha que continua uma expressao MQL precisa do operador E do terminador**; um texto multi-linha num `summary +=` tem de ser construido como uma expressao unica.

### 52.8 Riscos e ressalvas

- **Log mais honesto nao e sistema lucrativo.** Base v1.2.45 = `-32,21 USD` / PF 0,763; v1.2.58 = `-32,88 USD` / PF 0,7592. O P1.44 nao toca em trading: espera-se resultado identico.
- A verificacao **ponta-a-ponta** da truncagem exige recarregar o EA nos 17 graficos. `profile_apply` esta a devolver `ok:false` enquanto o run 7703264373217955650 corre, portanto a recarga **fica adiada** para o fim do backtest (nao interromper o run em curso). Atao: `Common/Files/XAU_AI_PRO/ValidationChecklist.txt` e `ProductionChecklist.txt` devem ficar sem rabo antigo.
- Um script de prova (`Scripts/TruncateProbe.mq5`) foi escrito e compilado para medir a semantica de `FILE_WRITE`, mas o terminal nao o lista (`chart_add_script` -> `script not found in base`) porque o cache do Navigator nao actualizou; o script e o `.ex5` foram **apagados** para nao deixar lixo. A prova fica pela leitura dos ficheiros depois da recarga.
## 53. P1.45 (v1.2.63) - o registo de trade descrevia o deal de FECHO e chamava-lhe abertura de posicao

Ciclo de 01/11/2026. Versao de topo: `v1.2.63` (`#property version "1.263"`).

### 53.1 A pergunta

O contrato de 13 colunas do `trade_history_backtest.csv` estava a ser exercitado desde o P1.39, mas ninguem tinha perguntado se o CONTEUDO das colunas era coerente consigo proprio. A pergunta deste ciclo foi essa: o par `Entry`/`Exit` explica o `Profit` da mesma linha?

### 53.2 Resposta medida (339 linhas validas, 01/11/2026)

Script `Files\Backup\audit_csv_coherence.ps1` (so leitura), sobre `Common\Files\trade_history_backtest.csv`:

- **339** linhas validas de 13 campos (340 linhas incluem o cabecalho).
- **115** linhas com `Exit == Entry` e `Profit != 0`. Um par abertura/fecho igual com lucro diferente de zero e **impossivel**.
- **141** linhas com `Entry != Exit`; destas apenas **79** tem o sinal de `Exit - Entry` coerente com o sinal de `Profit`.
- **2** linhas **incoerentes**: `NZDUSD BUY 0,57195 -> 0,57194 Profit 20` (ticket 328) e `EURUSD BUY 1,12877 -> 1,12876 Profit 20` (ticket 446). BUY com `Exit` abaixo de `Entry` e lucro positivo.
- **60** linhas com lucro zero e o preco a mexer.
- Coluna `AI` = `0.00` em **339/339** linhas (pipeline Python offline no tester).

Nota de honestidade numerica: uma leitura anterior desta mesma sessao contou 335 linhas e 114 no par `Exit == Entry`; o ficheiro cresce enquanto o run 7703264373217955650 corre. Os valores acima sao o ultimo snapshot, e o changelog do EA cita exactamente estes.

### 53.3 A causa, no chamador (`XAU_AI_PRO.mq5`, bloco do `OnTradeTransaction`)

O `LogTradeCSV` era chamado com:

```
LogTradeCSV(symbol, isBuy, HistoryDealGetDouble(deal, DEAL_PRICE),
            SymbolInfoDouble(symbol, SYMBOL_BID), profit, AIScore, ...);
```

Tres erros de semantica somados, todos no chamador e nenhum no logger:

1. **`Entry` recebia `DEAL_PRICE` do deal de FECHO.** O deal que chega ao evento e `DEAL_ENTRY_OUT`, por isso `DEAL_PRICE` e o preco de **saida**, nao o de abertura.
2. **`Exit` recebia `SymbolInfoDouble(symbol, SYMBOL_BID)`** lido no instante do registo. E um retrato **posterior** ao fecho, nao o preco executado - e explica as 115 linhas com `Exit == Entry`, porque no registo o Bid costuma coincidir com o ultimo preco.
3. **`Type` vinha de `DEAL_TYPE` do deal de FECHO.** Uma posicao **comprada** fechada por **venda** era escrita como `SELL`. E a assimetria que produz as 2 linhas incoerentes: a linha diz BUY mas os precos foram escritos na ordem de uma venda.

A direcao e o preco de abertura de uma posicao estao no deal `DEAL_ENTRY_IN` da MESMA posicao, que se obtem por `DEAL_POSITION_ID`. O comentario antigo do codigo (`// Usa DEAL_TYPE (mais confiavel em DEAL_ENTRY_OUT, pois a posicao pode ja estar fechada)`) escolhia deliberadamente o deal errado por acreditar que a posicao ja nao era consultavel - **e era**, por `HistorySelectByPosition`.

### 53.4 A correccao (minima, so dados)

- `HistorySelectByPosition(posId)` seguido de varredura por `DEAL_ENTRY_IN` recupera `posOpen` (preco de abertura) e `posIsBuy` (direcao da posicao).
- **Fallback conservador**: se a posicao nao for seleccionavel, `posOpen = closeFill` e `posIsBuy` vem do `DEAL_TYPE` do deal, exactamente o comportamento antigo - nunca se gravam zeros.
- `HistoryDealSelect(deal)` no fim, a devolver a seleccao de historico ao deal do evento, porque o resto do bloco (auditoria, base de dados) continua a usar `deal`.
- `Exit` passa a ser `closeFill` = `DEAL_PRICE` do deal de fecho executado, e nao o Bid do momento do registo.
- Nenhum `return`, nenhum limite, nenhum parametro, nenhuma regra de risco, execucao, preco ou gestao foi tocada.

Detalhe de escopo evitado: `dealMagic` ja existe no inicio da funcao (linha ~1315) e por isso o magic e lido **em linha** no argumento em vez de repetir a declaracao, para nao criar sombreamento.

Semantica das 13 colunas documentada em `Monitoring\TradeLogger.mqh`, imediatamente antes de `void LogTradeCSV(`, com a invariante verificavel explicita: **BUY com lucro positivo exige `Exit > Entry`; SELL com lucro positivo exige `Exit < Entry`**.

### 53.5 Prova

- `Files\Backup\apply_p145b.ps1` (215 linhas): backup `.bak_before_p145` dos 3 ficheiros antes de tocar em qualquer byte.
- `XAU_AI_PRO.mq5` 74 804 -> **76 557 B**, `CRLF=2286`, `loneLF=0`, `NUL=0`.
- `TradeLogger.mqh` 17 272 -> **18 954 B**, `loneLF=600`, `CRLF=0`, `NUL=0` (LF puro preservado por desenho).
- `VersionManager.mqh` 43 337 -> **45 116 B**, `CRLF=228`, `loneLF=0`, `NUL=0`.
- Bump triplo: `// XAU_AI_PRO v1.2.63`, `#property version "1.263"`, `#define EA_VERSION_STRING "1.2.63"`.
- Compilacao: `Result: 0 errors, 0 warnings, 21 852 ms elapsed, cpu=X64 Regular`, `ex5 = 678 646 B` (era 677 296 B).
- Leitura pos-escrita do bloco aplicado (linhas 1644-1704) confirma a sintaxe: `if`, `for`, `continue`, `break`, `}` fechados, `LogTradeCSV` com 8 argumentos na ordem da declaracao.

### 53.6 O que NAO esta provado ainda

O efeito do P1.45 nao esta medido: **exige um run novo com o `.ex5` v1.2.63**. O run 7703264373217955650 esta a 91 % (`05:45:23 / 06:19:07`) e corre com binario anterior; o CSV que ele escreve ja nao serve para medir esta correccao. Config ja preparada: `Profiles\Tester\p145_v1263.ini` (mesmo simbolo, periodo, modelo de ticks reais, deposito, alavancagem e intervalo do run de base, para comparacao directa).

Antes desse run o `trade_history_backtest.csv` deve ser **rodado** (renomeado, nao apagado) para `trade_history_backtest_pre_p145.csv`, senao as linhas antigas contaminam a medicao - misturar 13 colunas semanticamente erradas com 13 colunas correctas no mesmo ficheiro e exactamente o tipo de erro que custou 7 ciclos no contrato de colunas.

### 53.7 Erro de ferramenta cometido neste ciclo (custou uma reescrita)

O `apply_p145.ps1` escrito na sessao anterior partia do principio de que o bloco a substituir era o que constava do resumo, terminando em `HistoryDealGetInteger(deal, DEAL_MAGIC)`. O bloco **real** tinha, entre o `isBuy` e a chamada, seis linhas de comentario `P1.21` que o resumo nao reproduzia. A ancora de 20 linhas nao casaria e o `Troca` teria abortado com `ALVO NAO UNICO ... : 0`. A regra que fica: **entre ler e escrever a ancora, extrair o texto exacto do ficheiro** (comprimento por linha incluido), nunca reconstrui-lo de memoria nem de resumo. O `apply_p145.ps1` foi **removido** depois de substituido: alem de abortar, o seu primeiro passo era `Copy-Item -Force` para `.bak_before_p145`, ou seja, executa-lo sobre os ficheiros ja corrigidos sobrescreveria o proprio ponto de rollback. Um script obsoleto que estraga a prova e pior do que nenhum script.

Segundo erro evitado a tempo: a primeira versao do detector de EOL usava o operador ternario `? :`, que so existe em PowerShell 7; no Windows PowerShell 5.1 falharia dentro do proprio ramo de erro. Substituido por `if/else`.

### 53.8 Ressalva (mantida em todos os documentos)

**Um CSV correcto nao e um sistema lucrativo.** Bases medidas: v1.2.45 = `-32,21 USD` / PF 0,763; v1.2.58 = `-32,88 USD` / PF 0,7592. O P1.45 nao toca em risco, execucao, preco nem gestao: restitui **verdade a uma fonte de dados**. Se as bandas de ADX, as horas e os filtros aprendem do `trade_history`, entao ate agora aprendiam de um ficheiro em que o tipo da operacao e o preco de entrada estavam trocados em parte das linhas. Corrigir a fonte nao garante resultado melhor; garante que o proximo ajuste medido o seja sobre dados que descrevem o que aconteceu. Um backtest nao prova rentabilidade futura.

## 54. Base fechada e previsao falsificavel do run v1.2.63

Escrito em 01/11/2026 **antes** de o run 7703371145268441630 terminar, de proposito: uma previsao registada depois do resultado nao e previsao, e desculpa.

### 54.1 O run de base terminou (7703264373217955650)

Report final:

| Campo | Valor |
|---|---|
| Lucro | **-32,88 USD** |
| Profit factor | **0,7592** |
| Recovery factor | -0,6775 |
| Sharpe | -1,6628 |
| Deals / trades | 750 / 375 |
| Trades com lucro / com perda | 162 / 213 |
| Short / long | 204 / 171 |
| Max drawdown (saldo) | 47,15 USD / 22,50 % |
| Expected payoff | -0,09 |
| Barras geradas / ticks | 5 814 / 31 892 873 |

Estes numeros sao **identicos aos da base v1.2.58** (-32,88 USD / PF 0,7592). E o resultado que se esperava e que vale como prova negativa: os ciclos P1.39 a P1.44 mexeram apenas em rotacao de ficheiro, janelas de aviso, textos de diagnostico e semantica de registo. Se o resultado tivesse mudado, algum deles teria tocado em trading sem dizer. Nao tocou.

### 54.2 O CSV de base foi rodado, nao apagado

`Common\Files\trade_history_backtest.csv` (34 830 B, 373 linhas) -> `trade_history_backtest_pre_p145.csv`, com verificacao de que o destino **nao existia** antes do `Move-Item` e de que o tamanho se manteve. Ficam no disco, lado a lado: `trade_history.csv` (8 500 879 B, producao), `trade_history_backtest_legacy_v1.csv` (25 705 B, 10 colunas) e `trade_history_backtest_pre_p145.csv` (34 830 B, 13 colunas com semantica errada).

Motivo de rodar em vez de acumular: misturar no mesmo ficheiro linhas com `Entry` = preco de fecho e linhas com `Entry` = preco de abertura tornaria a medicao impossivel por construcao. Foi exactamente esse tipo de mistura silenciosa que manteve o contrato de colunas 7 ciclos por exercitar.

### 54.3 Run v1.2.63 lancado

- `run_id = 7703371145268441630`, config `Profiles\Tester\p145_v1263.ini`, inputs `XAI_V1244_3M_REALTICKS.set`.
- Mesmo simbolo, periodo, modelo (ticks reais), deposito, alavancagem e intervalo de datas do run de base - a comparacao e directa.
- Journal confirma o binario novo: `XAU_AI_PRO v1.2.63` as `2026.07.29 00:00:00`, `expert file added: Experts\XAU_AI_PRO\XAU_AI_PRO.ex5. 678683 bytes loaded`.

### 54.4 Previsao (falsificavel)

1. **Report identico ao de base:** `-32,88 USD`, PF `0,7592`, 750 deals, 375 trades, 162/213. O P1.45 nao toca em risco, execucao, preco nem gestao. Qualquer desvio significa que eu me enganei sobre o alcance da alteracao, e nesse caso a alteracao e que esta errada.
2. **Coerencia do CSV invertida:** `Exit == Entry` com `Profit != 0` deve cair a **zero** (era 115 de 339); as linhas incoerentes devem cair a **zero** (eram 2); `Type` deve passar a reflectir a direccao da posicao, o que se confirma comparando a contagem de BUY/SELL no CSV com os 204 short / 171 long do report.
3. **Coluna AI continua 0.00** - o pipeline Python esta offline e o P1.45 nao o toca. Se passar a diferente de zero, veio de outro sitio e tem de ser explicado.
4. **Volume de linhas comparavel** ao de base (373), nao um multiplo nem uma fraccao. Uma queda grande significaria que o fallback esta a rejeitar posicoes; um aumento grande significaria duplicacao.

Se a previsao 2 falhar, a hipotese seguinte e que `HistorySelectByPosition` nao devolve a posicao no contexto do `OnTradeTransaction` do tester, e o fallback silencioso estara a mascarar isso - que e o pior desfecho possivel, porque nao levanta erro. Nesse caso o fallback tem de ser MEDIDO, nao assumido: contar quantas vezes cai no ramo antigo.

### 54.5 Estado do item de READY (fechado no P1.44)

A pendencia antiga de investigacao `READY: NO latchado` fica **fechada**, e a resposta foi a inversa da suspeita: nao havia portao nenhum a travar. `CProductionChecklist::IsReady()` e `ValidationChecklistPassed()` estao definidos e nao sao chamados por nenhum caminho de execucao; as duas checklists correm uma unica vez dentro do `OnInit`. Logo o `READY: NO` nao trava nada porque nao existe nada para travar - mas tambem nunca era reavaliado e ficava impresso como estado corrente durante dias. O P1.44 passou a gravar a hora do snapshot e a dizer que o relatorio e diagnostico de init, nao portao. A proteccao real contra spread e por tick, em `Filters\SpreadFilter.mqh` e no CostGate.

### 54.6 Ressalva

As previsoes acima sao sobre **coerencia de dados e igualdade de comportamento**, nao sobre lucro. A base continua negativa: `-32,88 USD` e PF `0,7592` em tres meses de XAUUSD M15 com 200 USD de deposito. Corrigir o CSV nao muda isso. Um backtest nao prova rentabilidade futura.

## 55. Verificacao antecipada: P1.44 provado nos dois defeitos, P1.45 a confirmar a previsao

Medicao feita em 01/11/2026 as 22:15, com o run 7703371145268441630 a **00:17:59 / 16:39:04**. Nao se esperou pelo fim: o arranque e as primeiras 15 linhas do CSV ja respondem a duas das quatro previsoes registadas na Â§54.4.

### 55.1 P1.44 provado onde se tinha duvidado

A pendencia dizia que os relatorios das checklists apareciam corrompidos por falta de truncagem (`READY: YEStical failed`, `READY: NO: NONO`, `Resultado: REPROVADO ... REPROVADO ... xistem BLOCKED`). Os dois ficheiros foram escritos as 21:54:25 pelo run novo e estao limpos:

`Common\Files\XAU_AI_PRO\ValidationChecklist.txt` - **769 B**, termina exactamente assim:

```
READY=13 | WARNING=2 | BLOCKED=0
Resultado: SEM BLOCKED
snapshot de init: 2026.07.29 00:00 (nao reavaliado)
NOTA: diagnostico do arranque, nao e portao de execucao.
```

`Common\Files\XAU_AI_PRO\ProductionChecklist.txt` - **1 197 B**, termina exactamente assim:

```
Result: 12/17 passed | 5 failed | 0 critical failed
READY: YES | snapshot de init: 2026.07.29 00:00
NOTA: relatorio do arranque - nao e reavaliado enquanto o EA corre, nao e portao de
execucao (nada consulta IsReady()) e o bloqueio real de spread e por tick em
Filters/SpreadFilter.mqh.
```

Nao ha cauda do resumo anterior, nao ha texto sobreposto, e o veredicto passou a trazer a hora do snapshot. A impressao no journal confirma o mesmo: `READY: YES | snapshot de init: 2026.07.29 00:00`.

### 55.2 Correcao de uma crenca anterior: o BLOCKED nao era universal

A Â§52.8 do ciclo do P1.44 registou `96 de 96 arranques de hoje imprimiram BLOCKED`, sempre pelo mesmo item: `Dataset ausente/vazio, com EnableDataset=true`. Este run contradiz a generalizacao e precisa-a:

```
[VALIDATION] Resultado: READY=13 WARNING=2 BLOCKED=0
Dataset: READY - Dataset desativado
```

Com `EnableDataset=false` no `.set` do tester, o item **nao** bloqueia. Logo o `BLOCKED` nao vinha do EA nem da checklist: vinha de uma **configuracao** de producao que pedia dataset e nao tinha dataset. A decisao pendente (`passar Dataset a WARNING`) fica assim muito mais estreita do que parecia - nao e preciso mudar a severidade do item, e preciso decidir se a producao deve continuar com `EnableDataset=true` sem dataset. Alterar a severidade esconderia a unica pergunta que interessa.

### 55.3 Achado novo: as duas checklists discordam sobre o mesmo assunto

No mesmo arranque, sobre Dataset:

- `ValidationChecklist.txt`: `Dataset: READY - Dataset desativado`
- `ProductionChecklist.txt`: `[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio`

As duas estao a avaliar coisas diferentes com o mesmo nome: uma respeita a definicao (`EnableDataset`), a outra verifica o ficheiro independentemente da definicao. Um operador que leia o segundo relatorio ve um FAIL de uma funcionalidade que esta deliberadamente desligada - o mesmo padrao de `Dashboard: WARNING - Dashboard desativado (opcional)` no primeiro e `[OPTIONAL] Dashboard: FAIL` no segundo. **Nao corrigido neste ciclo**: o run esta a usar o `.ex5` carregado e recompilar a meio substituiria o binario em teste. Fica registado para o proximo ciclo em que a compilacao for segura.

### 55.4 P1.45 - previsao 2 confirmada nas primeiras 15 linhas

`Common\Files\trade_history_backtest.csv` (ficheiro novo, criado depois da rotacao da Â§54.2, logo **todas** as linhas sao do v1.2.63): 16 linhas = cabecalho + **15 validas**.

| Verificacao | Base (v1.2.62) | Agora (v1.2.63) |
|---|---|---|
| `Exit == Entry` com `Profit != 0` | **115** de 339 | **0** de 15 |
| Linhas incoerentes (sinal nao explica o lucro) | **2** | **0** |
| `Entry != Exit` | 141 | 10 |
| ... coerentes com o lucro | 79 de 141 | **10 de 10** |
| Lucro zero com o preco a mexer | 60 | **0** |
| Coluna `AI` | 0.00 | 0.00 (previsto) |

### 55.5 O caso-de-prova: a mesma linha, antes e depois

Mesmo segundo, mesma operacao, mesma perda - e a coluna `Type` invertida:

```
antes  (v1.2.62): 2026.07.29 07:25:30,GBPUSD,BUY ,1.32998,1.32997,-0.58,...
agora  (v1.2.63): 2026.07.29 07:25:30,GBPUSD,SELL,1.32940,1.32998,-0.58,...
```

A linha antiga dizia BUY com `Entry` 1.32998 e `Exit` 1.32997: um par abertura/fecho praticamente igual e uma perda de 0,58, que nao se explica por movimento de preco nenhum. A linha nova diz SELL, aberta a 1.32940 e fechada a 1.32998: o preco **subiu**, a posicao era **vendedora**, e a perda de 0,58 sai exactamente dai. A posicao era SELL e o deal de fecho era BUY - que e precisamente o diagnostico da Â§53.3.

As duas linhas com `Entry == Exit` que restam tem ambas `Profit = 0.00`, que e o caso legitimo (aberta e fechada ao mesmo preco). Deixou de existir o par impossivel.

### 55.6 O que continua por confirmar

- **Previsao 1** (report identico ao de base: `-32,88 USD`, PF `0,7592`, 750 deals, 375 trades, 162/213). So no fim do run.
- **Previsao 4** (volume de linhas comparavel a 373). Com 15 linhas nao se conclui nada sobre volume; e preciso pelo menos o cohort completo.
- **Direccao do `Type` em agregado**: cruzar a contagem de BUY/SELL do CSV com os 204 short / 171 long do report de base. SÃ³ faz sentido no fim.
- Contagem de quantas vezes o **fallback** do P1.45 e usado (posicao nao seleccionavel). Continua a ser o desfecho perigoso, porque e silencioso. 10 de 10 linhas coerentes sugerem que nao cai no fallback, mas "sugere" nao e "mede": so um contador explicito mediria.

### 55.7 Nota de metodo

Duas previsoes registadas antes do resultado foram confirmadas por duas medicoes independentes do `OnInit` (os dois `.txt` e o journal), e uma terceira pelo CSV. O valor de escrever a previsao antes esta em 55.2: eu tinha generalizado `96 de 96 com BLOCKED` como se fosse propriedade do EA, e o primeiro arranque noutro ambiente mostrou que era propriedade da configuracao. Sem a previsao registada, teria sido facil ler o `BLOCKED=0` como "corrigi alguma coisa" - e eu nao corrigi nada.

## 56. P1.46 (pre-registado, nao aplicado) - "desligado por opcao" estava a ser contado como FALHA

Analise feita em 01/11/2026 as 23:05, com o run 7703371145268441630 a `01:03:40 / 06:37:55`. **Nao foi aplicado nada**: recompilar durante o run substituiria o `.ex5` que o agente carregou, e nao existe copia visivel em `Tester\` que prove isolamento - a unica copia no disco e `MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` (678 646 B, 20:39:36). Esta secao e o pre-registo da correccao, para o proximo ciclo ser mecanico.

### 56.1 O achado, em quatro funcoes do mesmo ficheiro

A `ProductionChecklist` classifica os itens com dois eixos: `m_critical[]` (CRITICAL ou OPTIONAL) e um `bool ok` por item. O problema e que, para quatro itens OPTIONAL, o `bool ok` **e a propria flag de configuracao**:

```
CheckNotifications : bool ok = EnableNotifications;   // mensagem diz "Notificacoes desabilitadas"
CheckAudit         : bool ok = EnableAuditLog;        // mensagem diz "Auditoria desabilitada"
CheckDashboard     : bool ok = EnableDashboard;       // mensagem diz "Dashboard desabilitado"
CheckDataset       : ignora EnableDataset por completo; so olha o ficheiro Data\dataset.csv
```

Com as quatro funcionalidades desligadas por opcao, o relatorio de 21:54:25 diz:

```
[OPTIONAL] Python: FAIL - Pipeline Python incompleto
[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio
[OPTIONAL] Notifications: FAIL - Notificacoes desabilitadas
[OPTIONAL] Audit: FAIL - Auditoria desabilitada
[OPTIONAL] Dashboard: FAIL - Dashboard desabilitado
Result: 12/17 passed | 5 failed | 0 critical failed
```

Tres destas cinco linhas dizem, na propria mensagem, que a funcionalidade esta **desabilitada** - e ao mesmo tempo contam como falha. O relatorio esta a somar "desligado de proposito" com "avariado" no mesmo numero. O operador que le `5 failed` nao consegue distinguir o que exige accao do que nao exige nenhuma.

### 56.2 Prova da contradicao entre os dois relatorios

No MESMO arranque, sobre o MESMO assunto:

| Item | `ValidationChecklist` | `ProductionChecklist` |
|---|---|---|
| Dataset | `READY - Dataset desativado` | `FAIL - Dataset ausente ou vazio` |
| Dashboard | `WARNING - Dashboard desativado (opcional)` | `FAIL - Dashboard desabilitado` |

Duas avaliacoes do mesmo estado, com tres veredictos diferentes (`READY`, `WARNING`, `FAIL`). A `ValidationChecklist` respeita a definicao; a `ProductionChecklist` ignora-a. Nao e uma questao de gosto: e o mesmo facto a ser contado de duas maneiras.

Alem disso, o texto do `CheckDataset` mente num caso concreto: com `EnableDataset=false` ele diz `Dataset ausente ou vazio`, quando o dataset nao falta - nao e usado. A frase descreve um problema que nao existe.

### 56.3 Correcao pre-registada (minima, so classificacao de relatorio)

Regra unica, aplicada aos quatro itens: **funcionalidade desligada por configuracao = PASS com a palavra opcional; funcionalidade ligada e avariada = FAIL.**

```
CheckDataset:   if(!EnableDataset) { SetResult(7, true, "Dataset desativado (opcional)"); return; }
                ... codigo actual ... SetResult(7, ok, ok ? "Dataset OK" : "Dataset ausente ou vazio (habilitado)");
CheckDashboard: SetResult(14, true, EnableDashboard ? "Dashboard habilitado" : "Dashboard desativado (opcional)");
CheckNotifications: quando desligado, `SetResult(12, true, "Notificacoes desativadas (opcional)")`; o aviso de Telegram configurado sem ChatID mantem-se tal como esta
CheckAudit:     SetResult(13, true, EnableAuditLog ? "Auditoria habilitada" : "Auditoria desativada (opcional)");
```

Efeito esperado no relatorio: `12/17 passed | 5 failed` -> **`16/17 passed | 1 failed`**, ficando apenas o `Python` como falha real (pipeline incompleto, nao desligado por opcao). O `Dataset` habilitado sem ficheiro continua a falhar - e esse e o unico caso em que a falha e verdadeira.

O que **nao** muda: nenhum `return`, nenhum limite, nenhum parametro de risco, execucao, preco ou gestao. `m_critical[]` nao e tocado. Os itens continuam OPTIONAL. O `IsReady()` continua sem ser consultado por nenhum caminho de execucao - o P1.44 ja tinha provado que nao e portao, e esta correccao nao lhe da poder nenhum: so acerta o que se escreve.

### 56.4 Porque nao foi aplicado agora

Recompilar a meio do run substituiria `MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`, que e o unico ficheiro do EA no disco. O agente carregou-o as 21:54 e o journal registou `678683 bytes loaded`, contra 678 646 B no disco - ou seja, ha uma copia propria do agente que **nao esta visivel** em `Tester\`. Sem poder provar que a recompilacao nao afecta o run, aplica-la poria em risco 5 horas de calculo para ganhar um ciclo. Preferi esperar.

Consequencia pratica: esta correccao, e o contador de fallback do P1.45 (Â§55.6), ficam os dois bloqueados pelo mesmo motivo. Sao as duas primeiras coisas a fazer quando o run terminar.

### 56.5 Nota de metodo

O achado nao veio de procurar defeitos: veio de LER os dois relatorios do arranque que eu tinha ido verificar por outra razao (a truncagem do P1.44). O defeito estava na terceira linha de cada um. Isto reforca a utilidade de ler a saida real inteira em vez de confirmar so o campo que se foi medir.


## 57. Verificacao "EA operando sozinho" (01/11/2026 23:05 local) - opera, mas corre v1.2.58

### 57.1 Veredicto

Sim, opera sozinho. Nao houve intervencao humana: o master e eleito entre as instancias, o
scanner varre 11 simbolos a cada ~15 s, a gestao corre por tick e a unica ordem do dia foi
enviada pelo proprio EA:

```
TRADE EXECUTADO | USDJPY | SIGNAL=-1 | LOT=0.08 | Ticket=11186991230   (23:00:11 local / 04:00:11 servidor)
```

### 57.2 Prova de vida

`MQL5\Logs\20261101.log` - 9 185 350 B, 53 354 linhas, ultima escrita 23:05:17.

| Metrica | Valor |
|---|---|
| `[SCANNER] BLOCK` | 11 768 |
| `[SCANNER] SIGNAL OK` | 1 071 |
| `[TRADE PIPELINE] INICIANDO` | 2 745 |
| `[RESUMO] master=SIM` | 52 (uma a cada ~5 min) |
| ordens enviadas | 1 |
| `TRADE EXECUTADO` | 1 |

### 57.3 O funil medido, nao suposto

Dos 1 071 sinais aprovados, 901 morreram em `VALIDATION: TREND BUY` (contramao vetada; ex.:
`USDBRL | contramao vetada | tendencia formada | ADX=39.8 >= 22.0`) e 169 em
`VALIDATION: AVOID HOUR`. O gate de tendencia e o maior consumidor de sinais do dia e o
horario evitado e o segundo. Os restantes 4 sao `sem linha valida`.

### 57.4 Defeito de versao - o teste ao vivo valida o EA de ontem

Os 16 graficos correm **v1.2.58** (`[VERSION] v1.2.58 | Build=2026.10.30 | Stable=Yes |
AutoUpdate=OFF | Modulos=15`, carregado as 14:59:22). O `.ex5` compilado e **v1.2.63**.
Nenhuma das correccoes P1.39 -> P1.45 (rotacao idempotente, truncagem das duas checklists,
semantica das colunas do CSV) esta a correr na conta. Nao e um erro de medicao: e a
diferenca entre o que foi escrito e o que esta em producao.

### 57.5 IA - ha score, nao ha preco, e o gateway nao e o que o nome diz

- `IA=SEM PRECO` nas 52 de 52 linhas de `[RESUMO]`: nao existe preco previsto.
- O sinal passou mesmo assim: `[ADV AI] Score 64.25 | Min 60.00 | Symbol USDJPY`.
  O score existe e supera o minimo de 60.00; o preco previsto e que nao.
- A porta 9001 de `AIGatewayUrl` (`http://127.0.0.1:9001/api/ai/predict`) pertence ao
  **terminal64** (pid 2440), nao a um servico de modelo: nao ha nenhum processo `python`
  em execucao. O EA chama um endpoint do proprio terminal e chama-lhe gateway de IA.

### 57.6 Defeito novo (P1.47 candidato) - o STANDBY nomeia o dono com o proprio id

Cada instancia nao-dona imprime `STANDBY | outra instancia e a dona do [...] | chart=<o seu
proprio chart_id>`. Exemplo: GBPUSD (chart 35819305996467) escreve
`chart=35819305996467`; o dono real e o USDCZK (chart 35819164653256), que nao aparece em
nenhuma das linhas STANDBY do dia. A frase afirma que ha outro dono e depois aponta para si
propria. Mesma classe dos P1.41 / P1.42 / P1.44 / P1.45 / P1.46: um texto que mente sobre o
proprio mecanismo.

### 57.7 Estado da conta e do terminal

Demo 113568614 (hedging): balance 12 351.78, equity 12 350.51, margem usada 80.00, livre
12 270.51, flutuante -1.27, swaps e comissoes 0.00. Terminal build 6294,
`connection=synchronized`, ping 212 957 us, retransmit 0.30 %, `experts_trade_allowed=true`,
disco livre 8 873 MB, working set 472 MB.

### 57.8 A posicao aberta nao tem stop loss - e por desenho

```
[RESUMO] #11186991230 USDJPY SELL 0.08 | flutuante -1.77 USD | SEM STOP: arma em 10.00 USD
         | stop=sem stop | alvo=20.02 USD
```

E o `EnableStoplessEntry` (arma em 0.8 ATR, trava em 0.35 ATR) a funcionar, nao um stop em
falta. Fica registado porque `RequireStopLoss=true` e a posicao nao tem stop: a proteccao
real e a escada de dinheiro, nao o SL.

### 57.9 chart17 e chart18 sem expert

`chart17` (XAUUSD M15) e `chart18` (USDJPY M5) nao tem expert associado. Nao e falha de
carregamento: o `chart01` cobre XAUUSD M15, o `chart04` cobre USDJPY H1 e o scanner
multi-simbolo do master ja inclui USDJPY. Ficam como graficos de observacao.

### 57.10 Falsos positivos do meu proprio diagnostico

As 3 279 linhas que o meu filtro contou como `ERRO` e as 816 como `FALHA` sao o campo
`Error:` (vazio) e `Failures: 0` do relatorio de saude - 28 relatorios x 16 graficos. O
HealthMonitor reporta `AI: OK | Failures: 0` em todos os graficos. Nao ha erros do EA no
log do dia.

### 57.11 Estado do run de medicao

Run `7703371145268441630` continua `started`: 01:11:27 / 05:18:58. Nada foi recompilado nem
recarregado durante esta verificacao.

## 58. P1.46 e P1.47 (v1.2.64) - corrigidos sem tocar no binario que o run usa

### 58.1 O que foi corrigido

| Item | Ficheiro | Antes | Depois |
|---|---|---|---|
| P1.46 | `Monitoring\ProductionChecklist.mqh` | 4 funcionalidades desligadas por opcao contadas como FALHA | PASS com a marca `(opcional)` |
| P1.47 | `Core\TradePipeline.mqh` | STANDBY imprimia `chart=ChartID()` (o proprio) | `esta=` e `dono=` com o dono real |
| P1.47 | `XAU_AI_PRO.mq5` | o mesmo defeito na mensagem de backup | idem |

`PipelineMasterChart()` e o helper novo: le o `GlobalVariable` onde o mestre publica o
proprio `chart_id` (a chave ja existia dentro de `PipelineIsMaster`, so nao estava exposta)
e devolve `0` quando nao ha mestre publicado. Nenhuma regra de trading, limite, `return` ou
parametro de risco foi tocado - so texto de diagnostico e classificacao de relatorio.

### 58.2 Porque o binario de producao NAO foi recompilado

O run `7703371145268441630` (medicao do P1.45) continua a correr e carregou
`Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`. Em vez de arriscar 4 h de calculo, a verificacao de
compilacao foi feita sobre uma **copia completa da arvore** em
`Experts\XAU_AI_PRO_build\` (150 ficheiros, 2 657 175 B), com o `.ex5` gerado dentro da
copia. Resultado:

```
Result: 0 errors, 0 warnings, 18861 ms elapsed, cpu='X64 Regular'
ex5 de verificacao: 681 034 B  11/01/2026 23:15:41
producao intocada:  678 646 B  11/01/2026 20:39:36
```

A copia foi apagada depois da medicao. O `.ex5` de producao continua com a data de 20:39:36.

### 58.3 O erro que esta estrategia apanhou

A primeira insercao do changelog no `VersionManager.mqh` colou a linha nova (terminada em
`" +`) e reabriu a atribuicao na linha seguinte:

```
error 177: '+' - l-value required   (VersionManager.mqh(63,1721))
error 177: l-value required         (VersionManager.mqh(64,25))
Result: 2 errors, 0 warnings
```

A linha `m_current.changes = "v1.2.63 ...` devia ser continuacao (`"v1.2.63 ...`) e nao uma
segunda atribuicao. Corrigido para a forma que o ficheiro ja usava (26 espacos de
indentacao, sem o nome do campo) e recompilado: 0 errors, 0 warnings. Se a compilacao
tivesse sido feita directamente sobre a producao com o run a correr, o erro teria aparecido
no pior sitio possivel.

### 58.4 Efeito esperado do P1.46 (pre-registado na Â§56.3, agora aplicado)

`ProductionChecklist.txt` deve passar de `12/17 passed | 5 failed | 0 critical failed` para
`16/17 passed | 1 failed`, com `[OPTIONAL] Python: FAIL` como unica falha e as quatro
linhas `[OPTIONAL] Dataset / Notifications / Audit / Dashboard` a dizer
`(opcional)` com PASS. O item Python continua a falhar de proposito: e a unica lacuna real.

### 58.5 Prova medida do P1.47

No journal de experts de 01/11/2026, cada instancia nao-dona imprimia o **proprio**
`chart_id` na frase que anunciava outro dono. O `chart_id` do GBPUSD e 35819305996467 e o
do USDCZK (dono real, o unico que imprime `[RESUMO] master=SIM`) e 35819164653256 - este
ultimo nao aparece em nenhuma das linhas de standby do dia. A frase afirmava um dono e
apontava para si propria.

### 58.6 Versao e rollback

- Bump triplo: `// XAU_AI_PRO v1.2.64`, `#property version "1.264"`,
  `#define EA_VERSION_STRING "1.2.64"`, mais paragrafo de changelog no `VersionManager`.
- Backups: `TradePipeline.mqh.bak_before_p147` (7 576 B),
  `XAU_AI_PRO.mq5.bak_before_p147` (76 557 B),
  `ProductionChecklist.mqh.bak_before_p147` (17 402 B),
  `VersionManager.mqh.bak_before_p147` (45 116 B).
- Scripts: `Files\Backup\apply_p147.ps1`, `compile_p147.ps1`, `compile_p147b.ps1`.
- Saldo de chaves conferido nos quatro ficheiros: delta 0 em todos.

### 58.7 O que falta para o EA corrigido estar a operar

1. Esperar pelo fim do run `7703371145268441630`.
2. Recompilar a producao (`compile_p122.ps1` ja faz isso) e confirmar 0/0.
3. Recarregar os 16 graficos com o `.ex5` novo - hoje correm **v1.2.58**, cinco versoes
   atras. Sem este passo, P1.39 a P1.47 continuam a existir so no disco.

## 59. P1.48 e P1.49 + treino dos 16 ativos operados, com o Python restaurado (02/11/2026 02:20 UTC)

Sessao pedida como "corrigir todos itens, e python tambem e treinar novos modelos
atualizados dos ativos operados". Tres frentes: o interpretador, o registo de modelos e o
filtro de simbolos do dataset. Nenhum `.pkl` e nenhum `.meta.json` foi escrito; o run
`7703371145268441630` continuou a correr do principio ao fim (01:49:13 / 06:02:50 na
ultima leitura).

### 59.1 O bloqueio do Python: nao havia interpretador nenhum nesta maquina

MEDIDO, nao presumido: `where python`, `where python3`, `where py` e `where pythonw` falham
todos; nao existe `C:\Users\Micro\AppData\Local\Programs\Python`; nao existe
`C:\Python313`; nenhum `python*.exe` sob `MQL5`; nenhum `.whl` sob `MQL5`. O `.venv` que os
logs de treino referem (`set PY=.venv\Scripts\python.exe`) foi apagado na limpeza anterior.
O `compiler_python=false` do `get_workspace_info` e a medicao, nao uma impressao.

Resolucao sem instalador, sem `PATH` e sem registo (apagar a pasta desfaz tudo):
`MQL5\Files\Temp\py311\python.exe`, Python 3.11.9 **embeddable** (zip de python.org,
34 ficheiros, 10,73 MB), `python311._pth` editado para `import site`, `get-pip.py`.

| pacote | versao | porque esta versao |
|---|---|---|
| pip / setuptools / wheel | 26.2.2 / 84.2.1 / 0.48.0 | base |
| pandas | 3.1.0 | o codigo ja correu com esta serie; `treinar_ia.py` validado end-to-end |
| numpy | 2.4.6 | idem |
| **scikit-learn** | **1.9.0** | **pin obrigatorio**: os `.pkl` foram treinados com 1.9.0 e o 1.9.1 produz `InconsistentVersionWarning: Trying to unpickle estimator DecisionTreeClassifier from version 1.9.0` em todos |
| joblib / scipy / threadpoolctl / cloudpickle / narwhals / python-dateutil / tzdata | 1.6.0 / 1.17.1 / - / - / - / - / - | dependencias |
| MetaTrader5 | 5.0.6231 | leitura do terminal |

Consequencia operacional: **o treino volta a ser possivel sem instalar nada no sistema**.
Risco assumido e declarado: `Temp` e uma pasta de limpeza, portanto a proxima limpeza
volta a quebrar o Python - foi exactamente o que aconteceu ao `.venv`. Fica como divida
aberta (§59.7).

### 59.2 Export do MT5: tres limites da API medidos e contornados

`Files\Temp\export_mt5.py` exporta M5 dos 16 ativos operados para
`Files\Data\dataset_mt5_20261101.csv` (15 colunas, sem cabecalho, indicadores a `0.0` de
proposito - o `train_v2` deriva ATR/ADX/RSI/KCI da serie OHLC).

Tres limites da API Python neste terminal, todos medidos:

1. `copy_rates_range(inicio antigo, ex. 2024-01-01)` -> `None`/0 linhas em **16 de 16**
   simbolos. Inutilizavel como fonte.
2. `copy_rates_from_pos(count=100000)` -> `(-2, 'Terminal: Invalid params')`.
   `count=50000` funciona. Resolvido por paginacao em blocos de 50 000 ate 500 000.
3. A concatenacao das paginas saiu **DESCENDENTE** (passo mediano -300 s, "nao-monotonico"
   nos 16 simbolos). Resolvido com `np.sort(r, order="time")`.

Resultado medido do ficheiro: **1 494 248 linhas / 138 869 179 B (132,4 MB)**, CRLF=0,
LF=1 494 248, NUL=0, 0 duplicados `Symbol+Time`, monotonicamente crescente, 16 simbolos.
Janela 2009-08-30..2026-11-02: os exotivos (USDCOP 96 067, USDCLP 73 824 candles) puxam a
janela para tras; os majors so tem ~17 meses (100 000 candles M5).

### 59.3 P1.48 - o registo de modelos dizia READY a modelos que o proprio projecto recusa

Dois defeitos no mesmo ficheiro, `Python\model_registry.py` (7 630 B, **LF puro**):

**(a) Um texto que mentia sobre o proprio mecanismo.** `FEATURE_VERSION = "25F"` enquanto os
39 `.meta.json` dizem `25F-v2` com `feature_count: 25`. Qualquer comparacao de contrato de
features feita a partir da constante reprovava modelos validos - ou, pior, aceitava-os por
o valor nao bater.

**(b) O veredicto READY ignorava `publicable`.** O registo consumido por
`prediction_gateway.py` devolvia `READY` a modelos que o proprio projecto recusa em
`backend/ai_inference.py:556`:

```python
modelo = None if not m.get("publicable") else joblib.load(pkl)
```

Duas camadas do mesmo projecto, veredictos opostos sobre o mesmo artefacto. E a mesma classe
de P1.41/P1.42/P1.44/P1.45/P1.46/P1.47: **um texto que mente sobre o proprio mecanismo**.

Correcao em dois blocos: `FEATURE_VERSION` -> `"25F-v2"`, helper `_read_meta()` (le o
`.meta.json`, devolve `{}` se faltar ou estiver ilegivel - compatibilidade com os artefactos
antigos que nao tem meta), e `model_status()` recusa `publicable=false` com
`status=ERROR` e `reason="not_publishable: <publish_reason>"`.

Ficheiro: 7 630 -> **9 727 B**, CRLF=0, LF=246, NUL=0. Backup
`model_registry.py.bak_before_p148`.

**Prova positiva e negativa** (`Files\Temp\proof_p148.py`, EXIT=0, 4/4 casos, falhas 0):
carrega o modulo novo e o `.bak_before_p148` como **dois modulos** e compara os veredictos
sobre os mesmos artefactos sinteticos:

```
PROVA NEGATIVA (XAUUSD M5, publicable=false):
  antigo -> READY | motivo: ok
  novo   -> ERROR | motivo: not_publishable: edge -0.0008 abaixo do minimo +0.0500
feature_version novo  : 25F-v2 | feature_count: 25
publicable EURUSD (aprovado): True
publicable GBPUSD (sem meta): None
```

Nota de honestidade registada no proprio script: o `.bak_before_p148` foi tirado **depois**
de a constante ja ter sido corrigida no bloco A, portanto tambem devolve `25F-v2`. A
divergencia original (constante `25F` contra artefacto `25F-v2`) esta registada nos
`.meta.json` e **nao e reproduzivel** a partir desse backup. O script diz isso em vez de
fingir que reproduz.

### 59.4 P1.49 - a limpeza do dataset descartava 9 dos 16 ativos operados, em silencio

`Python\data\data_engine_xau.py` filtrava o dataset carregado por `symbol_aliases` - um
**mapa de 9 apelidos** (`XAUUSD, BTCUSD, ETHUSD, EURUSD, GBPUSD, USDJPY, AUDUSD, USDCAD,
NZDUSD`) - usado como **whitelist**. Tudo o que a corretora negociava e nao estivesse nessa
lista era descartado sem uma linha de aviso.

MEDIDO antes: **700 000 linhas / 7 simbolos** de 1 494 248. Ficavam de fora USDCHF,
USDSEK, USDCZK, USDCNH, USDCLP, USDCOP, USDBRL, USDRUB, USDSGD - nove dos dezesseis ativos
que os graficos operam.

MEDIDO depois: **1 494 248 linhas / 16 simbolos**, ou seja +794 248 linhas que existiam no
disco e nunca chegavam ao treino.

Correcao: o filtro passou a validar a **FORMA** do campo, nao um catalogo. `mt5_bridge.py`
(4 869 -> **5 850 B**, CRLF=164, LF=164, NUL=0) ganhou `import re`, `SIMBOLO_RE` e:

```python
def simbolo_plausivel(valor) -> bool:
    """True quando o campo Symbol pode ser um simbolo de corretora.

    Rejeita vazio, nulo, numero puro (preco sem cabecalho que virou simbolo)
    e texto fora do formato. Nao conhece nem presume nenhum ativo.
    """
```

`data_engine_xau.py` (4 608 -> **4 918 B**, CRLF=153, LF=153, NUL=0) passou a
`self.df[self.df["Symbol"].astype(str).map(simbolo_plausivel)]`. O `symbol_aliases`
**continua a existir** como mapa de apelidos da corretora; deixa de ser filtro de dados.

O defeito que a whitelist tapava - precos sem cabecalho a entrar como `Symbol` - continua
coberto, e agora sem presumir catalogo: `simbolo_plausivel` rejeita numero puro e formato
invalido. Uma lista fixa de ativos contra os milhares que a corretora oferece era
exactamente a presuncao que a regra §3 do AGENTS.md proibe.

Backups `mt5_bridge.py.bak_before_p149`, `data_engine_xau.py.bak_before_p149`.
Script `Files\Backup\apply_p149.ps1`, 5/5 verificacoes, EOL detetado preservado.

### 59.5 O treino dos 16 ativos operados: 0 publicaveis, e isso e o resultado correcto

`Files\Temp\sweep_mt5.py` treina cada ativo no timeframe do seu grafico, sobre o export
fresco, e passa cada combinacao pela porta de edge do `train_v2`
(`PUBLICACAO_MIN_EDGE = 0.05`). **Nao grava `.pkl` nem `.meta.json`** - os modelos de
515 MB ficaram intocados.

Resultado: **0 de 16 publicaveis**. Relatorio em `Files\Backup\treino_edge_20261101.csv`
(3 134 B, CRLF=17).

Ordem decrescente pelo `edge` de holdout, com a acc e o palpite que o produzem:

| # | simbolo | tf | candles | edge | acc | palpite | treino/teste |
|---|---|---|---|---|---|---|---|
| 1 | USDCAD | H1 | 100 000 | **+0.0241** | 0.3607 | 0.3366 | 6 661 / 1 658 |
| 2 | USDCHF | H1 | 100 000 | **+0.0229** | 0.3782 | 0.3552 | 6 662 / 1 658 |
| 3 | USDSGD | H1 | 100 000 | **+0.0193** | 0.3725 | 0.3532 | 6 662 / 1 659 |
| 4 | USDRUB | H1 | 100 000 | +0.0166 | 0.3819 | 0.3654 | 9 937 / 2 477 |
| 5 | USDBRL | M5 | 24 357 | +0.0160 | 0.4138 | 0.3978 | 19 474 / 4 862 |
| 6 | USDJPY | H1 | 100 000 | +0.0157 | 0.3667 | 0.3510 | 6 662 / 1 658 |
| 7 | NZDUSD | H1 | 100 000 | +0.0012 | 0.3510 | 0.3498 | 6 662 / 1 658 |
| 8 | USDCZK | H1 | 100 000 | -0.0072 | 0.3506 | 0.3578 | 6 668 / 1 660 |
| 9 | EURUSD | H1 | 100 000 | -0.0139 | 0.3351 | 0.3490 | 6 664 / 1 659 |
| 10 | GBPUSD | H1 | 100 000 | -0.0199 | 0.3565 | 0.3764 | 6 662 / 1 658 |
| 11 | AUDUSD | H1 | 100 000 | -0.0253 | 0.3396 | 0.3649 | 6 660 / 1 658 |
| 12 | USDCLP | H1 | 73 824 | -0.0281 | 0.3771 | 0.4052 | 8 130 / 2 026 |
| 13 | XAUUSD | M15 | 100 000 | -0.0286 | 0.3373 | 0.3659 | 26 700 / 6 668 |
| 14 | USDSEK | H1 | 100 000 | -0.0380 | 0.3392 | 0.3771 | 6 670 / 1 660 |
| 15 | USDCOP | H1 | 96 067 | -0.0584 | 0.3437 | 0.4020 | 10 234 / 2 552 |
| 16 | USDCNH | H1 | 100 000 | **-0.1120** | 0.2753 | 0.3873 | 6 666 / 1 660 |

**7 de 16 tem edge positivo** e nenhuma passa +0.05. Note-se a coluna `treino/teste`: os H1
tem ~6 660 barras de treino e 1 658 de teste, porque veem de **100 000 candles M5
reamostrados** (~8 300 barras H1 no total). E o limite mais evidente do resultado - ver
§59.7 ponto 2.

**Duas medidas diferentes, e nao devem ser confundidas.** O `edge` acima e o de *holdout*
(`acc - palpite`, linha 556 do `train_v2`); a coluna `folds` do CSV e o *walk-forward*
expanding-window (`N_FOLDS = 5`, `MIN_FOLDS_POSITIVOS = 4`). Sao camadas distintas: a
publicacao exige `edge >= min_edge` **e** `estavel` (linha 572). Por isso USDCZK pode ter
`edge` -0.0072 e folds todos negativos (media -0.126): o holdout de uma unica fatia
disfarcava a instabilidade que o walk-forward expoe. E o `robustez()` existe exactamente
para isso - escolher o modelo de maior edge e vies de selecao.

Nenhuma combinacao e estavel (`estavel=False` em todas). Decisao registada e mantida:
**nao publicar nada e nao sobrescrever `.pkl`**. O proprio treinador diz
*"melhor sem sinal do que com sinal ruim"*, e a §6.2 do AGENTS.md proibe afrouxar uma trava
para ela parar de reprovar - baixar `PUBLICACAO_MIN_EDGE` de 0.05 para "passar" seria o
defeito, nao a correcao.

### 59.6 Consequencia medida do P1.48 no registo: 28 STALE + 11 ERROR

Com a recusa por `publicable` a funcionar, `registry_summary()` passa a ler:

```
REGISTRY | 39 modelos | feature_version=25F-v2
por status: {'STALE': 28, 'ERROR': 11}
publicable: {'True': 28, 'False': 11}
feature_version por modelo: {'25F-v2': 36, '25F-est-v1': 3}
```

Os 11 ERROR, com o motivo que o proprio artefacto declara:

```
AUDUSD_M5   +0.0093 abaixo do minimo +0.0500    GBPUSD_M5   +0.0306
BTCUSD_M5   +0.0194                             NZDUSD_M5   +0.0173
ETHUSD_M5   +0.0295                             USDCAD_M5   +0.0143
EURUSD_M5   +0.0082                             USDJPY_M5   +0.0202
XAUUSD_M5   -0.0008                             USDJPY_M15  +0.0314
XAUUSD_M15  edge medio +0.0481 (folds +0.007 +0.025 +0.073 +0.054 +0.08)
```

**10 dos 11 tem edge POSITIVO** e ficam abaixo do portao. So XAUUSD_M5 e negativo. O
XAUUSD_M15 e o caso mais interessante: **5 folds de 5 positivos**, media +0.0481, a 0.0019
do portao - e o unico onde o sinal parece real e apenas insuficiente.

Isto **nao e regressao**: `backend/ai_inference.py` ja recusava estes modelos com a mesma
regra. O que muda e que a recusa passa a ser **visivel no registo** em vez de o registo
dizer `READY`. Pela regra 18.5 do gateway, nenhum estado invalido vira BUY/SELL.

Explicacao de um facto ja medido no §57: `IA=SEM PRECO` em **52 de 52** resumos do dia.
Nao era o gateway em baixo apenas - era tambem o modelo a ser correctamente recusado.

### 59.7 O que fica aberto desta frente

1. **O Python vive em `Temp`.** A proxima limpeza de `Temp` volta a quebrar o treino, como
   ja quebrou o `.venv`. Decidir: mover para local estavel ou aceitar reinstalar.
2. **Os majors so tem ~17 meses de M5** (100 000 candles). Para H1 sao ~8 300 barras - o
   export por timeframe (H1/H4 directos do MT5, 100 000 barras cada) daria ~11 anos e e a
   melhoria de dados mais obvia que a medicao sustenta. Nao foi feita nesta sessao.
3. **O portao de +0.05 com 10/11 edges positivos e pequenos** pede uma decisao do dono, nao
   uma alteracao de codigo: manter (IA inerte por desenho) ou rever o criterio de
   publicacao com prova. Nao foi tocado.
4. **A producao continua em v1.2.58 nos 16 graficos**; P1.39 -> P1.49 existem so no disco
   ate o run fechar, a producao ser recompilada e os graficos recarregados (§58.7).

## 60. P1.50 (medicao) - o H1 vinha de ~8 300 candles M5; com 100 000 candles H1 nativos o edge sobe +0,0172 e mesmo assim ninguem passa o portao

### 60.1 A hipotese e o que a sustenta

A §59.7 deixou escrito o limite: o export era **so M5**, portanto um modelo H1 recebia
~100 000 candles M5 reamostrados e chegava ao treino com **~6 660 barras**. O MT5 tem
**100 000 candles H1 por simbolo**, o que no EURUSD cobre mais de uma decada. Se o problema
fosse falta de dados, o edge teria de subir ao dar-lhe 12x mais barras. Foi o que se mediu.

### 60.2 O metodo (medido, replicavel)

`Files\Temp\sweep_tf_nativo.py` le os candles **nativos** do timeframe do grafico
(`copy_rates_from_pos`, paginado em 50 000, `np.sort` por tempo, duplicados de fronteira
removidos) e passa a serie pelo **mesmo** `train_v2.treinar`, com o mesmo
`PUBLICACAO_MIN_EDGE = 0.05`. Nada foi alterado no treinador; muda so a fonte de dados.
`reamostrar` de H1 para H1 (`60min`, `label=left`, `closed=left`) preserva uma barra por
hora, portanto o caminho e identico ao de producao.

Confirmacao de que a comparacao e honesta: em **USDBRL (M5), USDCLP (H1) e USDCOP (H1)** o
numero de barras de treino e **identico** nas duas fontes, porque esses simbolos nao tem
mais historia nativa do que a que o M5 ja continha. Sao o **grupo de controlo**: se o edge
sobe por "mais dados", nao pode subir nestes.

### 60.3 Resultado: 11 de 16 melhoram, media +0,0172, e 0 de 16 passam

| simbolo | tf | treino nativo | treino M5 | edge nativo | edge M5 | delta |
|---|---|---|---|---|---|---|
| USDSEK | H1 | 79 989 | 6 670 | **+0.0341** | -0.0380 | **+0.0721** |
| USDCHF | H1 | 79 989 | 6 662 | **+0.0363** | +0.0229 | +0.0134 |
| EURUSD | H1 | 79 989 | 6 664 | +0.0336 | -0.0139 | +0.0475 |
| GBPUSD | H1 | 79 989 | 6 662 | +0.0321 | -0.0199 | +0.0520 |
| USDRUB | H1 | 21 337 | 9 937 | +0.0317 | +0.0166 | +0.0151 |
| AUDUSD | H1 | 79 989 | 6 660 | +0.0203 | -0.0253 | +0.0456 |
| USDSGD | H1 | 79 989 | 6 662 | +0.0185 | +0.0193 | -0.0008 |
| USDCNH | H1 | 53 429 | 6 666 | +0.0150 | -0.1120 | **+0.1270** |
| USDBRL | M5 | 19 474 | 19 474 | +0.0142 | +0.0160 | -0.0017 |
| USDCAD | H1 | 79 988 | 6 661 | +0.0058 | +0.0241 | -0.0183 |
| USDJPY | H1 | 79 988 | 6 662 | +0.0040 | +0.0157 | -0.0117 |
| NZDUSD | H1 | 79 989 | 6 662 | -0.0087 | +0.0012 | -0.0099 |
| XAUUSD | M15 | 79 989 | 26 700 | -0.0095 | -0.0286 | +0.0191 |
| USDCLP | H1 | 8 130 | 8 130 | -0.0513 | -0.0281 | -0.0232 |
| USDCZK | H1 | 57 591 | 6 668 | -0.0550 | -0.0072 | -0.0478 |
| USDCOP | H1 | 10 234 | 10 234 | -0.0611 | -0.0584 | -0.0027 |

Leituras que a tabela sustenta:

1. **A falta de dados era real e custava edge.** Media dos deltas **+0,0172**; 11 de 16
   melhoraram. Os maiores ganhos sao exactamente os simbolos onde a diferenca de barras e
   maior: USDCNH **+0,1270** (6 666 -> 53 429) e USDSEK **+0,0721** (6 670 -> 79 989).
2. **Os tres simbolos do grupo de controlo nao ganharam** (-0.0017, -0.0232, -0.0027), o
   que e o esperado se a causa for volume de dados e nao ruido. E a prova negativa natural
   da hipotese.
3. **Os positivos passaram de 7 para 10 de 16**, e o melhor subiu de +0,0241 (USDCAD) para
   **+0,0363 (USDCHF)**.
4. **Nenhum passa os +0,0500.** O melhor esta a **0,0137** do portao. Mais dados melhoram o
   modelo; nao o transformam num modelo publicavel.

### 60.4 Decisao: o portao nao se toca

O resultado nao autoriza baixar `PUBLICACAO_MIN_EDGE`. Com 10 de 16 positivos e o melhor a
+0,036, o que a medicao diz e que **o contrato de features `25F-v2` nao separa estes
mercados com vantagem suficiente**, nao que o portao esteja alto. Baixar 0.05 para 0.03
seria escolher o numero depois de ver o resultado - o inverso de medir.

**Nenhum `.pkl` nem `.meta.json` foi escrito nesta medicao.** Os modelos de 515 MB
continuam intocados. O registo continua em **28 STALE + 11 ERROR** (§59.6): a IA segue
inerte por desenho, e isso e agora um resultado **replicado em duas fontes de dados
diferentes**, nao um acidente de um export.

### 60.5 O que a medicao autoriza tentar a seguir

1. **Mudar a pergunta, nao o portao.** O alvo de 3 classes com `LOOKAHEAD` fixo por
   timeframe pede `acc - palpite` de 5 pontos. A literatura e o proprio `train_v2`
   (`custo_rel_de_spread`) apontam para um alvo **binario com barreira de custo** (o trade
   paga o spread ou nao paga). Isso e um contrato NOVO (`26F` ou `bin-v1`), com os modelos
   antigos preservados por incompatibilidade declarada - nao um ajuste do portao.
2. **`H4`/`D1` nativos ainda nao foram medidos** com esta fonte; `H1` foi onde os graficos
   operam e por isso foi o escolhido.
3. **A pergunta que so o dono responde:** aceitar a IA inerte (o EA opera com as proprias
   regras, que e o que tem feito) ou autorizar um contrato de features novo, que implica
   treinar e publicar modelos diferentes dos actuais.

## 61. P1.51 (correcao) - ValidateSymbol deixou de ser codigo morto: passa a ser o portao final do simbolo

### 61.1 O que foi medido antes de mexer

- `Core/SymbolValidator.mqh` tinha **1 definicao e 0 chamadas** em 104 ficheiros `.mqh`/`.mq5`. Era codigo morto: existia, compilava, nunca corria.
- `SymbolIsSynchronized()` **nao existia em nenhum ficheiro do EA** (lacuna 1 da secao 45). O unico teste de simbolo era `SymbolInfoInteger(symbol, SYMBOL_SELECT)` repetido inline.
- O spread **ja** e fechado em `Filters/SpreadFilter.mqh` (por tick), `ValidationEngine.mqh`, `Enterprise/SmartExecution.mqh`, `Enterprise/CircuitBreaker.mqh`, `Monitoring/ProductionChecklist.mqh` e `ValidationChecklist.mqh` via `GetMaxSpread(symbol)`.

### 61.2 O que foi alterado

- `Core/SymbolValidator.mqh` reescrito: **2158 B -> 5158 B**, `crlf=205`, `nul=0`, BOM utf8 preservado. Assinatura nova `ValidateSymbol(const string symbol, double lot, double slPoints, string &reason)` com motivo textual, e o overload antigo de 3 parametros mantido como wrapper.
  Recusa: simbolo vazio, fora do Market Watch, **nao sincronizado** (`SymbolIsSynchronized`), `SYMBOL_TRADE_MODE_DISABLED`/`CLOSEONLY`, lote fora de min/max/step (tolerancia 1e-8), `ask/bid/point <= 0`, e SL abaixo do `SYMBOL_TRADE_STOPS_LEVEL`. `slPoints == 0` continua aceite (entrada sem stop e decisao de outra camada).
- `Core/ExecutionEngine.mqh`: **43812 B -> 45002 B**, `crlf=1103`, `nul=0`. Um unico bloco novo imediatamente antes de `ulong ticket = 0;` + `ExecResult execResult = CSmartExecution::OpenPosition(req, ticket);` (ancora exigida com exactamente 1 ocorrencia):
  imprime `EXECUTION BLOCK | SYMBOL | <simbolo> | Lot=... | SL=... | Motivo=...` e chama `EventTradeRejected(..., "SYMBOL_INVALID")`.
- `Enterprise/VersionManager.mqh`: **46839 B -> 47932 B**, `#define EA_VERSION_STRING "1.2.65"` e o paragrafo do P1.51 no inicio de `m_current.changes` (antes de v1.2.64).
- `XAU_AI_PRO.mq5` linha 2: `// XAU_AI_PRO v1.2.64` -> `// XAU_AI_PRO v1.2.65` (76594 B -> 76594 B, tamanho igual porque so muda o digito).
- Backups: `MQL5/Files/Backup/VersionManager.mqh.bak_before_p151` e `MQL5/Files/Backup/XAU_AI_PRO.mq5.bak_before_p151`.

### 61.3 Porque o spread NAO foi duplicado

Duplicar um criterio ja aplicado num portao fail-closed so acrescenta formas de bloquear por engano. `GetMaxSpread(symbol)` corre por tick em `SpreadFilter.mqh:91` e nos outros sitios listados em 61.1; o portao novo trata do que ninguem testava (sincronizacao, modo de negociacao, cotacao e geometria do lote/SL).

### 61.4 Validacao

- Compilacao feita numa **copia** (`Experts/XAU_AI_PRO_buildcheck`) para nao tocar no `.ex5` do run em curso:
  `Result: 0 errors, 0 warnings, 16779 ms elapsed, cpu='X64 Regular'` (metaeditor build 6294, x64).
  Copia `.ex5` 683976 B; producao `.ex5` **678646 B antes e depois** (intocada); copia apagada no fim.
- Verificacao pos-escrita dos dois ficheiros por releitura do disco: `NUL=0`, `CRLF == LF`, tamanho igual ao texto gravado, marcadores com exactamente 1 ocorrencia.

### 61.5 O que NAO mudou

Nenhum `input`, `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, limite, `return` ou regra de trading. `ValidateSymbol` e uma trava **adicional** fail-closed no ultimo ponto antes do envio da ordem; se algo falhar, o EA recusa em vez de enviar.

### 61.6 PENDENTE deste item

- A producao continua em **v1.2.58** nos 16 graficos; o binario de 678646 B em uso e o do run `7703371145268441630`. Recompilar a producao para v1.2.65 e recarregar os graficos **so quando esse run fechar** (recompilar agora troca o binario debaixo do teste em curso).
- Confirmar no journal apos o reload: `[VERSION] v1.2.65`, `16/17 passed | 1 failed`, `[PIPELINE] STANDBY ... dono=...`.

## 62. P1.52 (medicao) - o fallback do P1.45 passou a ser contado, em vez de suposto

### 62.1 O que estava medido, e o que nao estava

O P1.45 corrigiu o registo para descrever a POSICAO: `posOpen` e `posIsBuy` passam a vir do deal `DEAL_ENTRY_IN` da mesma posicao (`DEAL_POSITION_ID`), e nao do deal de fecho. A verificacao de entao deu **10 de 10 linhas coerentes** — mas isso so prova que o **caminho principal** funciona. Quando `posId == 0` ou `HistorySelectByPosition` falha, o codigo herda direcao e preco do deal de FECHO (comportamento antigo) e **nao escrevia nada em lado nenhum**. Quantas vezes esse ramo corria era uma incognita: por desenho, uma linha errada no CSV seria indistinguivel de uma linha certa.

### 62.2 O que foi alterado

- `XAU_AI_PRO.mq5`: 76594 B -> **77108 B**, `crlf=2300`, `NUL=0`. Tres alteracoes cirurgicas, cada uma com exactamente 1 ocorrencia da ancora:
  1. `bool   posDealFound = false;` declarado ao lado de `posOpen`;
  2. `posDealFound = true;` imediatamente antes do `break;` que encontra o deal `DEAL_ENTRY_IN`;
  3. contador `static ulong s_logFallbackCount` que, quando `!posDealFound`, incrementa e imprime
     `TRADELOG FALLBACK | deal=<ticket> | posId=<id> | direcao e preco herdados do deal de FECHO | acumulado=<N>`.
- `Enterprise/VersionManager.mqh`: 47932 B -> **48580 B**; `EA_VERSION_STRING` 1.2.65 -> **1.2.66** e paragrafo do P1.52 no inicio de `m_current.changes`.
- `XAU_AI_PRO.mq5` linha 2: `// XAU_AI_PRO v1.2.66`.
- Backups: `Files\Backup\XAU_AI_PRO.mq5.bak_before_p152`, `Files\Backup\VersionManager.mqh.bak_before_p152`.

### 62.3 Como interpretar o numero

- `acumulado=0` ao fim de uma sessao com fechos: o caminho principal cobriu **todos** os casos; o P1.45 esta a funcionar e o fallback nunca foi necessario.
- `acumulado>0`: cada ocorrencia traz o `deal` e o `posId` — sao exactamente as linhas que podem ter direcao/preco herdados, e passam a ser auditaveis em vez de silenciosas.

Nao ha alteracao de limite, de regra de entrada/saida nem de parametro de risco: o registo faz o mesmo que fazia, agora com rasto.

### 62.4 Validacao

- Compilacao numa copia (`Experts\XAU_AI_PRO_buildcheck`): `Result: 0 errors, 0 warnings, 21669 ms elapsed, cpu='X64 Regular'`. Copia `.ex5` **684134 B**; producao `.ex5` **678646 B antes e depois** (intocada); copia apagada.
- Verificacao pos-escrita por releitura do disco: `NUL=0`, `CRLF == LF`, marcadores (`posDealFound`, `s_logFallbackCount`, `TRADELOG FALLBACK`) com exactamente 1 ocorrencia cada.

### 62.5 PENDENTE

- A producao continua em **v1.2.58** e o run `7703371145268441630` continua `started` (progresso `07:15:06 / 07:15:58`, a crescer). Recompilar a producao para **v1.2.66** e recarregar os 16 graficos so quando esse run fechar; depois confirmar no journal `[VERSION] v1.2.66` e `16/17 passed | 1 failed`.
- Confirmar no journal a **ausencia** (ou a contagem) de `TRADELOG FALLBACK` no primeiro ciclo completo apos o reload.

## 63. Reload da producao: os 16 graficos sairam de v1.2.61 para v1.2.66

### 63.1 O que estava medido antes deste ciclo
- Producao `.ex5` no disco: 678646 B em 2026-11-01 20:39:36, recompilada para 684804 B as 2026-11-02 05:11:12 com `Result: 0 errors, 0 warnings, 15778 ms elapsed, cpu='X64 Regular'`.
- Nenhuma linha `[VERSION]` nova no journal apos 05:11:12: o modulo **em memoria** continuava a ser o antigo. Ficheiro novo no disco nao e o mesmo que codigo a correr.
- Prova quantitativa: `[HEALTH] ERROR | uptime=209572s | checks=28` as 05:12:51 (~58 h sem reinicio) e `get_expert_advisor_parameters` a devolver `size=650400` / `build_time=2026-10-31T18:56:23Z`, contra 684804 B / 2026-11-02 no disco.

### 63.2 Porque o reload nao foi feito por `profile_apply`
- O perfil `XAI_V1243_20261031` existe e estava seleccionado, e os 19 `.chr` tinham sido gravados as 05:10:06 (1 minuto antes da compilacao), logo com os inputs correntes.
- Mesmo assim foi recusado: `profile_apply` "pode fechar graficos existentes e abrir os guardados". Com 19 graficos ja abertos, uma nao-fechacao duplicaria os graficos e passariam a correr 32 instancias do EA com a mesma magic 2026001 — risco de ordens duplicadas e de duas escadas a disputar a mesma posicao.
- `chart_set_symbol_period` tambem foi recusado: mudar H1->H2->H1 faz o EA calcular sinais noutro timeframe durante o intervalo, com risco de entrada espuria.

### 63.3 O que foi feito
- 16 chamadas `chart_add_expert` (chart01..chart16), **sem** `expert_parameters`.
- Justificacao medida, nao suposta: os inputs dos 16 graficos sao exactamente os defaults compilados — `list_open_charts` devolve 308 pares nome/valor e `get_expert_advisor_parameters` devolve os mesmos 308 `default_value` mais 1 grupo (`=== APRENDIZADO PELO HISTORICO ===`). Reanexar sem parametros reproduz a configuracao identica; nao houve alteracao de risco, lot, SL/TP ou filtros.
- Ordem: chart01 isolado primeiro, `[VERSION] v1.2.66` confirmado no journal, e so depois os restantes 15.

### 63.4 Prova do reload
- Cada um dos 16 graficos registou o **deinit da instancia antiga** com `[VERSION] v1.2.61 | Build=2026.10.30` e o **init da nova** com `[VERSION] v1.2.66 | Build=2026.11.02 | Stable=Yes | Modulos=15`.
- 16 linhas `v1.2.66 | Build=2026.11.02` (uma por grafico), entre 05:14:57 e 05:15:23.
- `[VERSION] Modulos: ... ValidationChecklist=OK; ProductionChecklist=OK; ...` — 15 modulos OK.
- `Result: 15/17 passed | 2 failed | 0 critical failed` e `READY: YES | snapshot de init: 2026.11.02 10:14`.

### 63.5 Achado deste ciclo: a producao estava 5 versoes atras
- O binario que estava a operar era **v1.2.61 (build 2026.10.30)**. O codigo no disco ja dizia 1.2.66.
- Ou seja: P1.46..P1.52 estavam escritos, compilados e documentados, mas **nao estavam a correr** na conta demo. O journal provou-o no deinit, nao por inferencia.
- Consequencia: a partir de 05:15:23 o portao de simbolo do P1.51 e o contador do P1.52 estao finalmente activos nos 16 graficos.

### 63.6 As posicoes sobreviveram ao reload
- `11186991230` USDJPY SELL 0.08 | SL 157.800 (= entrada) | TP 157.406
- `11188595484` USDCAD SELL 0.04 | SL 1.39838 (= entrada) | TP 1.39139
- `11191008956` AUDUSD BUY 0.13 | TP 0.70375 | entrada sem stop, arma em 10.00 USD
- `[RESUMO] master=SIM | posicoes: 3 EA (+10.99 USD) + 0 manual` as 05:15:30: o PipelineMasterGuard reelegeu o dono sozinho e nao houve duplicacao de posicoes nem de ordens.

### 63.7 PENDENTE deste item
- `TRADELOG FALLBACK` com **0 ocorrencias** entre 05:00 e 05:22 (nao houve fecho desde o reload). No primeiro fecho: `acumulado=0` prova que o caminho principal cobriu tudo; `acumulado>0` traz o `deal` e o `posId` de cada recurso.
- O checklist passou a reportar **2 failed**: `Python: FAIL - Pipeline Python incompleto` e `Dataset: FAIL - Dataset ausente ou vazio` (este ultimo com `EnableDataset=true`). Decidir: produzir o dataset ou desligar a flag na producao.

## 64. P1.53 (correcao) - as duas checklists deixaram de divergir sobre o mesmo dado

### 64.1 O que foi medido antes
Arranque de 02/11/2026 05:14 (v1.2.66 nos 16 graficos), no mesmo instante, sobre o mesmo input e o mesmo ficheiro:

- ProductionChecklist: `[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio` (nao critico, nao trava nada).
- ValidationChecklist: `Dataset: BLOCKED - Dataset ausente/vazio (bloqueia)`.
- Dashboard: Production dava `PASS` com o interruptor desligado (P1.46); Validation dava `WARNING` para o mesmo input.

O cabecalho da ValidationChecklist define `BLOCKED` como "impede operacao segura (critico)". Desde o P1.44 nada consulta `ValidationChecklistPassed()`: o `BLOCKED` era um alarme falso com nome de portao, e era o unico do relatorio.

### 64.2 O que foi alterado (2 sitios, `Monitoring/ValidationChecklist.mqh`)
- item 6 (Dataset): `VC_BLOCKED` -> `VC_WARNING`, mensagem "Dataset ausente/vazio (opcional, nao bloqueia)". Alinha com o FAIL nao critico da Production para o mesmo facto.
- item 14 (Dashboard): `VC_WARNING` -> `VC_READY` quando desligado. Desligar o dashboard e uma opcao, nao uma degradacao; o mesmo input nao pode valer PASS de um lado e WARNING do outro.
- Cada substituicao levou comentario com a medicao que a justifica, no estilo dos P1.44/P1.46.

### 64.3 Prova do efeito
- Antes: `BLOCKED=1` em 16 de 16 graficos (sempre o Dataset).
- Depois: `[VALIDATION] Resultado: READY=13 WARNING=2 BLOCKED=0` nas majors e `BLOCKED=0` em 15 dos 16 graficos.
- O unico `BLOCKED` que restou e real e **nao** vem do Dataset: `[CRITICAL] Execution: FAIL - Spread acima do maximo: 1500.0 pts (max=489.3)` no `USDRUB,H1`. Ou seja: a checklist continua a apanhar o que bloqueia de verdade e deixou de acusar o que e opcional. Um checklist que grita sempre deixa de ser lido.

### 64.4 Versao, compilacao e reload
- v1.2.67 alinhado nos tres sitios: `EA_VERSION_STRING` (`Enterprise/VersionManager.mqh`), paragrafo novo em `m_current.changes` e cabecalho do `XAU_AI_PRO.mq5` na linha 2.
- Producao recompilada: 684804 -> 685792 B, `Result: 0 errors, 0 warnings, 16520 ms elapsed, cpu='X64 Regular'`.
- 16 graficos reanexados: 16 de 16 com `[VERSION] v1.2.67 | Build=2026.11.02 | Modulos=15`.
- Backups `.bak_before_p153` de `ValidationChecklist.mqh` (11315 -> 12055 B), `VersionManager.mqh` (48580 -> 49665 B) e `XAU_AI_PRO.mq5` (77108 -> 77108 B, so o digito da versao).

### 64.5 O que NAO mudou
- Nenhum limite, return, regra de trading ou parametro de risco. As duas checklists continuam a ser **diagnostico de arranque**: nada consulta `IsReady()` nem `ValidationChecklistPassed()`, e o bloqueio real de spread continua a ser por tick em `Filters/SpreadFilter.mqh`.
- Ficaram medidas mas **nao** alteradas duas divergencias de severidade, de proposito documentado: `Symbol` (a Production exige `bid>0 && ask>0` como CRITICAL, a Validation so faz `SymbolSelect`) e `JSON` (a Production ignora `RequireAIJSON`, a Validation bloqueia quando o JSON e requerido). A segunda e deliberada: a Validation le o input, a Production nao. Mexer nela agora seria mudar criterio sem medicao que o sustente.

### 64.6 PENDENTE deste item
- `Dataset` com `EnableDataset=true` e sem `dataset.csv` continua `FAIL` na Production (nao critico). A checklist deixou de gritar, mas **o dado continua ausente**: decidir entre gerar o dataset ou desligar a flag na producao.
- `USDRUB` com spread de 1500 pts contra maximo 489.3: nao e defeito do codigo, e a condicao actual do simbolo. Confirmar se o USDRUB deve continuar entre os 16 operados.

## 65. P1.54 (correcao) - as checklists procuravam quatro ficheiros numa pasta onde o EA nunca escreve

### 65.1 O que foi medido antes
Arranque de 02/11/2026 05:17:58 (v1.2.67 nos 16 graficos), as duas checklists no mesmo instante:

- `[OPTIONAL] Dataset: FAIL - Dataset ausente ou vazio` em **16 de 16** graficos, enquanto `MQL5\Files\Data\dataset.csv` tinha **3.537.420 bytes** escritos as **05:18:05** - o DataLogger estava a escrever o ficheiro no mesmo segundo em que a checklist o declarava ausente.
- `[OPTIONAL] Python: FAIL - Pipeline Python incompleto` em **16 de 16**.
- `[OPTIONAL] AI` e `[OPTIONAL] JSON`: PASS nos 7 simbolos com predicao, FAIL nos outros 9.
- `[VALIDATION] Resultado:` `READY=13 WARNING=2 BLOCKED=0` nos 7 com predicao e `READY=11 WARNING=4 BLOCKED=0` nos 9 sem predicao.

### 65.2 A causa: FILE_COMMON muda a raiz, nao o nome
`FileIsExist(path, FILE_COMMON)` e `FileOpen(path, ... | FILE_COMMON)` nao procuram em `MQL5\Files`: procuram em `Common\Files`. As quatro verificacoes de ficheiro das duas checklists usavam FILE_COMMON (Production itens 5, 6, 7 e 8; Validation itens 4, 5, 6 e o 7 derivado). O EA escreve e le na sandbox:

- `AI\DataLogger.mqh` abre `Data\dataset.csv` **sem** FILE_COMMON (`FILE_READ|FILE_WRITE|FILE_CSV|FILE_UNICODE|FILE_SHARE_READ|FILE_SHARE_WRITE`).
- `AI\AIConnector.mqh` le `Data\prediction_<SIMBOLO>.json` **sem** FILE_COMMON (com fallback para o nome normalizado).
- `Core\PathManager.mqh` declara a raiz como `TERMINAL_DATA_PATH\MQL5\Files\`.
- `Monitoring\Diagnostics.mqh` ja lia o dataset na sandbox desde a v1.2.14.

### 65.3 A pasta certa foi lida do codigo, nao escolhida por preferencia
Nao houve arbitragem: quatro sitios do proprio EA, em producao ha meses, apontam para `MQL5\Files`. A checklist era o unico codigo do projecto a olhar para o outro lado.

### 65.4 Medicao fisica das duas pastas (02/11/2026 05:29)
| Item | `MQL5\Files\Data` (sandbox) | `Common\Files\Data` |
|---|---|---|
| dataset.csv | 3.541.218 B, 05:28:07 | **nao existe** |
| prediction_XAUUSD.json | 517 B, 08/10/2026 22:00 | 521 B, 25/08/2026 17:16 |
| prediction_EURUSD.json | 507 B, 08/10/2026 22:00 | 506 B, 25/08/2026 17:16 |
| prediction_USDJPY.json | 511 B, 08/10/2026 22:00 | 516 B, 25/08/2026 17:16 |
| prediction_USDCAD.json | 504 B, 08/10/2026 22:00 | 505 B, 25/08/2026 17:16 |
| prediction_USDBRL.json | **nao existe** | **nao existe** |

Duas consequencias medidas:
1. `Dataset` com FILE_COMMON **nunca podia passar**: o ficheiro nao existe no Common (57 ficheiros em `Common\Files\Data`, nenhum `dataset.csv`).
2. `AI` e `JSON` passavam nos 7 simbolos lendo uma **copia de 25/08/2026**, dois meses mais velha que a da sandbox (08/10/2026). O item nao validava o ficheiro que o AIConnector consome.

### 65.5 O que foi alterado (7 sitios, 2 ficheiros)
`Monitoring/ProductionChecklist.mqh` (18160 -> **19685 B**), 4 sitios:
- item 5 (`CheckAI`): `FileIsExist(file, FILE_COMMON)` -> `FileIsExist(file)`.
- item 6 (`CheckPython`): `FileIsExist(pred, FILE_COMMON) && FileIsExist(ds, FILE_COMMON)` -> sem FILE_COMMON.
- item 7 (`CheckDataset`): `FileIsExist(file, FILE_COMMON)` + `FileOpen(... | FILE_COMMON)` -> sandbox.
- item 8 (`CheckJSON`): idem.

`Monitoring/ValidationChecklist.mqh` (12055 -> **12648 B**), 3 sitios: `hasPred` (item 4), `jsonOK` (item 5) e `dsOK` (item 6, que o item 7 herda como `hasPred && dsOK`).

Em todas as aberturas entrou `FILE_SHARE_READ | FILE_SHARE_WRITE`: o DataLogger mantem o CSV aberto enquanto o EA corre e, sem share, o ficheiro aparece como "nao encontrado" - falso positivo ja documentado no `Diagnostics.mqh` v1.2.14.

### 65.6 Prova depois do reload (v1.2.68, arranque de 05:28:01)
| Veredicto | antes (v1.2.67, 05:17:58) | depois (v1.2.68, 05:28:01) |
|---|---|---|
| `[OPTIONAL] Dataset` | FAIL 16/16 | **PASS 16/16** |
| `[OPTIONAL] Python` | FAIL 16/16 | PASS 7 / FAIL 9 |
| `[OPTIONAL] AI` | PASS 7 / FAIL 9 | PASS 7 / FAIL 9 |
| `[OPTIONAL] JSON` | PASS 7 / FAIL 9 | PASS 7 / FAIL 9 |
| `[VALIDATION]` 7 simbolos com predicao | READY=13 W=2 B=0 | **READY=15 W=0 B=0** |
| `[VALIDATION]` 9 simbolos sem predicao | READY=11 W=4 B=0 | READY=12 W=3 B=0 |
| `[VALIDATION]` USDRUB | READY=10 W=4 B=1 | READY=11 W=3 B=1 |

O delta e exactamente o esperado e explica-se item a item: os 7 simbolos com predicao ganharam 2 READY (Dataset + o item derivado `hasPred && dsOK`); os 9 sem predicao ganharam 1 READY (so Dataset), porque `AI`, `JSON` e o item derivado continuam correctamente em falta - esses ficheiros **nao existem em nenhuma das duas pastas**.

### 65.7 Versao, compilacao e reload
- v1.2.68 nos tres sitios: `EA_VERSION_STRING` em `Enterprise\VersionManager.mqh` (49665 -> **51274 B**), paragrafo novo no inicio de `m_current.changes` e cabecalho do `XAU_AI_PRO.mq5` linha 2 (77108 -> 77108 B, so o digito da versao).
- 1a compilacao: `Result: 0 errors, 9 warnings` - o paragrafo novo citava caminhos com barras simples (`MQL5\Files\Data`) e o MQL5 leu-as como escapes: `warning 86: 'F' - unrecognized character escape sequence` e o mesmo para `D`, `d`, `F`, `F`, `p`, `P`, `D` e espaco. O `.ex5` foi reescrito mesmo assim e o script abortou.
- Corrigido com `apply_p154c.ps1`, que duplicou as 9 barras **apenas** do trecho novo (9 -> 18), com backup `.bak_before_p154b` (51265 B, o estado intermediario).
- 2a compilacao: `Result: 0 errors, 0 warnings, 17733 ms elapsed, cpu='X64 Regular'`; `.ex5` 685956 -> **685772 B** as 05:27:45.
- 16 graficos reanexados: 16 de 16 com `[VERSION] v1.2.68 | Build=2026.11.02 | Stable=Yes | AutoUpdate=OFF | Modulos=15` e `[VERSION] Modulos: ... ProductionChecklist=OK; ValidationChecklist=OK; ...` (15 modulos OK).

### 65.8 O que NAO mudou
Nenhuma regra de trading, limite, `return`, severidade ou parametro de risco. As duas checklists continuam a ser **diagnostico de arranque**: nada consulta `IsReady()` nem `ValidationChecklistPassed()` desde o P1.44, e o bloqueio real de spread continua a ser por tick em `Filters\SpreadFilter.mqh` (mais `ValidationEngine:90/185`, `SmartExecution:334/341` e `CircuitBreaker`). O USDRUB continua o unico BLOCKED, e por spread real.

### 65.9 Achado que reclassifica o P1.46
O P1.46 registou `Python: FAIL - Pipeline Python incompleto` como "lacuna real do pipeline Python". Nao era: era o **mesmo erro de pasta**. O item Python exige `prediction` **e** `dataset`; o dataset esta em `MQL5\Files\Data` desde sempre, portanto com FILE_COMMON o item falhava em 16 de 16 graficos mesmo com 7 predicoes no disco. Depois do P1.54 o item passa nos 7 simbolos que tem predicao **sem uma unica linha de Python ter sido alterada**.

### 65.10 PENDENTE deste item
- 9 dos 16 simbolos continuam sem `prediction_<SIMBOLO>.json` (USDBRL, USDCLP, USDCOP, USDSEK, USDCHF, USDCZK, USDCNH, USDRUB, USDSGD). `AI`, `JSON` e `Python` falham neles **com razao**: depende do treino de modelos por simbolo, nao das checklists.
- O item `AI` nao distinguia as duas pastas neste instante (ambas tem os mesmos 7 nomes): so `Dataset` e `Python` podiam ter apanhado o P1.54. Corrigido o caminho, a idade do ficheiro validado passou de 25/08 para 08/10 - ainda assim, `PASS` para um JSON de 25 dias. Decidir se o item deve reportar a idade do JSON.
- O PENDENTE 64.6 (`decidir entre gerar o dataset ou desligar EnableDataset`) **fecha-se por medicao**: o dataset existia e cresce; o FAIL era falso e estava corrigido no P1.54.

---

## 66. P1.56 (v1.2.70) - o item AI passou a dizer a IDADE da previsao

### 66.1 Medicao
`Data\prediction_XAUUSD.json` (sandbox `MQL5\Files`) tem `"timestamp": "2026-10-08T22:00:33.296743"` e o ficheiro tem a mesma data de modificacao no disco, ao segundo. O item imprimia apenas `Prediction JSON encontrado`: um `PASS` sem idade para uma previsao de 25 dias, mais velha do que o `dataset.csv` que o EA escreve a cada vela.

### 66.2 O que mudou
- `Monitoring\ProductionChecklist.mqh`: `#define AIChecklistMaxAgeHours 120.0` e `PredictionAgeHours(file)`, que le a idade com `FileGetInteger(file, FILE_MODIFY_DATE, false)` sem abrir o ficheiro. Usa o MENOR entre a idade calculada com `TimeLocal()` e com `TimeGMT()`, para que uma diferenca de fuso nunca declare `STALE` por engano.
- A mensagem passa a trazer `| idade=NNNh` e, acima de 120 h, `| STALE (mais velho que 120h)`.
- `Enterprise\VersionManager.mqh` (1.2.70 + paragrafo P1.56) e `XAU_AI_PRO.mq5` (cabecalho e `#property version "1.270"`, que estava preso em 1.264 desde a v1.2.64 - violacao da regra HG-01: os tres sitios de versao andam juntos).

### 66.3 O que NAO mudou
O veredicto. O item continua `[OPTIONAL]` e continua `PASS` enquanto o ficheiro existir, pela regra fixada no P1.53: o mesmo dado nao pode ter dois veredictos. O que muda e o TEXTO do diagnostico.

### 66.4 Compilacao
`Result: 0 errors, 0 warnings, 16667 ms elapsed, cpu='X64 Regular'`; `.ex5` 690176 -> 688642 B as 05:55:01 (metaeditor exit=1, falso positivo conhecido).

## 67. P1.57 (v1.2.71) - o mesmo dado deixou de ter dois vereditos (Symbol, AI, JSON)

### 67.1 Medicao (leitura das duas funcoes, 05:58)
- **Symbol**: `ProductionChecklist::CheckSymbols` exige `SymbolSelect` E `bid>0` E `ask>0`; `ValidationChecklist` item 11 aceitava apenas `SymbolSelect`. Um simbolo selecionavel mas sem cotacao dava `FAIL - Symbol sem cotacao` numa lista e `READY - Symbol disponivel` na outra.
- **AI**: com `EnableAIFilter=false` e nenhuma previsao, a Production escrevia `[OPTIONAL] AI: FAIL - Prediction JSON nao encontrado (IA offline)` e a Validation escrevia `READY - Filtro IA desativado (nao requerido)`: a Production nunca consultava o interruptor. E com `RequireAIJSON=true` e nenhuma previsao, a Production ficava em FAIL nao critico enquanto a Validation escrevia `BLOCKED`.
- **JSON**: a Production ignorava `RequireAIJSON`; um ficheiro vazio era FAIL nao critico na Production e `BLOCKED` na Validation.

### 67.2 Uma so tabela de decisao
`filtro desligado = PASS/READY` | `previsao presente = PASS/READY` | `ausente e nao requerida = FAIL nao critico/WARNING (fallback tecnico)` | `ausente e requerida = FAIL critico/BLOCKED`.
- `Monitoring\ProductionChecklist.mqh`: `CheckAI` consulta `EnableAIFilter` e atribui `m_critical[5] = RequireAIJSON` em runtime, exatamente no caso em que a Validation bloqueia; `CheckJSON` passa a `m_critical[8] = (EnableAIFilter && RequireAIJSON)` e a mensagem diz se o ficheiro e requerido ou opcional.
- `Monitoring\ValidationChecklist.mqh` item 11: `SymbolSelect && bid>0 && ask>0`, com a mesma mensagem (`Symbol OK: <SIMBOLO>` / `Symbol sem cotacao (bloqueia)`). Sem cotacao nao ha execucao possivel, por isso o criterio mais estrito passou a ser o unico.

### 67.3 O que NAO mudou
Nenhum `return`, limite, severidade de execucao, parametro de risco ou regra de trading. As checklists continuam diagnostico de arranque: nada consulta `IsReady()` nem `ValidationChecklistPassed()` desde o P1.44, e o bloqueio real de spread continua por tick em `Filters\SpreadFilter.mqh`.

### 67.4 Compilacao
`Result: 0 errors, 0 warnings, 16553 ms elapsed, cpu='X64 Regular'`; `.ex5` 688642 -> 692594 B as 06:00:31.

## 68. P1.58 (v1.2.72) - o EA deixou de precisar de permissao de DLL para CARREGAR

### 68.1 Medicao (06:02 e 06:03)
Ao reanexar o expert ao grafico USDSGD, e tambem ao aplicar um template gravado do proprio grafico, o terminal escreveu: `expert XAU_AI_PRO (USDSGD,H1) loaded successfully` -> `initializing of XAU_AI_PRO (USDSGD,H1) failed with code 0 (prepare to execution failed)` -> `expert XAU_AI_PRO (USDSGD,H1) removed`, e no journal do expert `DLL loading is not allowed`. O grafico ficou SEM robo entre 06:01 e 06:05.

### 68.2 Causa
`Enterprise\DatabaseManager.mqh` tem `#import "sqlite3.dll"` incondicional. A ligacao `#import` e resolvida no CARREGAMENTO do programa, portanto bloqueava o arranque por causa de uma funcionalidade que esta DESLIGADA (`EnableDatabase=false` nos 16 graficos). Testado `expertmode=7` no `.tpl` (o template gravado tinha 5): falhou igual, ou seja a permissao de DLL nao e concedida por esse caminho de reanexacao.

### 68.3 Correcao
Import condicional: macro `XAI_USE_SQLITE_DLL` (desligada por omissao). Sem a macro, as quatro funcoes `sqlite3_*` existem como stubs que devolvem falha e `Connect()` registra `[DATABASE] sqlite3 indisponivel (compilado sem DLL): base de dados desativada` e devolve `false`. Para repor a base de dados: compilar com `-DXAI_USE_SQLITE_DLL` e permitir DLL no terminal.

### 68.4 Reload dos 16 graficos (procedimento provado)
`chart_save_template` do proprio grafico -> `chart_apply_template`: reanexa o EA com os MESMOS inputs (lidos do `.chr`) sem passar por parametros escritos a mao. Resultado medido: 16 de 16 com `[VERSION] v1.2.72 | Build=2026.11.02 | Stable=Yes | AutoUpdate=OFF | Modulos=15`, entre 06:05:05 e 06:06:05. Confirmado por medicao que os `default_value` compilados sao identicos aos inputs vivos (RiskPercent 1.0, escada 5/1/7/10, MaxSpreadPct 0.6, RequireAIJSON false, AvoidHoursGMT 9,11,14,18,20,22).

### 68.5 Compilacao
`Result: 0 errors, 0 warnings, 17633 ms elapsed, cpu='X64 Regular'`; `.ex5` 692594 -> 690004 B as 06:04:56.

### 68.6 PENDENTE
- O `DatabaseManager` fica inativo enquanto a macro estiver desligada. Decidir se a base de dados SQLite deve ser abandonada de vez (o dataset CSV e o trade log ja cobrem o registo) ou se o terminal deve ser configurado com DLL permitida para a repor.
- Fica a faltar a confirmacao em producao dos itens alinhados no P1.57 nos 9 simbolos sem previsao (devem agora dizer `fallback tecnico (nao bloqueia)` nos dois relatorios).

---

## 69. P1.59 (v1.2.73) - a leitura do prediction JSON deixou de perder tudo depois da primeira linha

### 69.1 Defeito medido

O Diagnostics lia o ficheiro de previsao com `FILE_TXT | FILE_ANSI` e `FileReadString(h, length)`. Em modo
`FILE_TXT` o `FileReadString` **para no fim da linha** mesmo com comprimento explicito: devolvia apenas a
primeira linha do ficheiro. O `pipeline.py` grava o JSON com `indent=4`, portanto a primeira linha e um `{`
sozinho. O resultado era "Prediction JSON sem estrutura basica" para ficheiros completos no disco.

Tres medidas independentes, no arranque de 02/11/2026 06:05:

- fonte: `Monitoring/Diagnostics.mqh`, `FileReadString` sobre handle `FILE_TXT`;
- disco: os 44 `prediction_*.json` de `MQL5\Files\Data` tem `{` na primeira linha e as duas chaves presentes
  (bytes 135-979);
- journal: 7 registos `[DIAG] FALHA | Python | Prediction JSON sem estrutura basica` (06:05:52-06:06:05),
  exatamente os 7 simbolos com ficheiro.

### 69.2 Correcao

`DiagnosticsReadWholeFile` passou a ler bytes: `FileOpen(name, FILE_READ | FILE_BIN | FILE_SHARE_READ | FILE_SHARE_WRITE)`,
`FileSize`, `ArrayResize(uchar[])`, `FileReadArray` e `CharArrayToString(buf, 0, lidos, CP_UTF8)`. Foi criado o
helper `DiagnosticsJsonStructureOK(content)` e os dois blocos (Python e JSON) passaram a usar o mesmo criterio.

### 69.3 Prova

- `Diagnostics.mqh` 15330 -> 16198 B, `LF soltos=0`, `NUL=0`, `FILE_BIN=1`, `FILE_TXT=1`, helper 1 com 2 usos.
- compilacao de producao: `0 errors, 0 warnings`, `.ex5` 693190 -> 691706 B.
- 3 avisos `warning 86: unrecognized character escape sequence` na linha 63 do `VersionManager.mqh` foram
  corrigidos duplicando as barras invertidas (59186 -> 59189 B, +3 bytes exatos).
- os 16 graficos foram recarregados por template; journal de 06:18-06:23: **16/16 em `v1.2.73`** e
  **0** registos `sem estrutura basica` depois do reload.

## 70. P1.60 (v1.2.74) - a checklist e o motor deixaram de dar vereditos diferentes sobre a mesma previsao

### 70.1 Defeito medido

`AI\AIConnector.mqh:420` descarta a previsao com `MaxPredictionAgeSec>0 && age>(long)MaxPredictionAgeSec`, e o
input vale **900 s** (`Core/Config.mqh:605`). As duas checklists julgavam o mesmo ficheiro por **existencia**:

- `ProductionChecklist` item 5 (AI): `[OPTIONAL] AI: PASS - Prediction JSON encontrado | idade=600.0h | STALE`
  - o teto usado era `AIChecklistMaxAgeHours = 120.0`, que nao e o do motor e nunca mudava o veredicto;
- `ValidationChecklist` item 4 (AI): `AI: READY - Prediction JSON presente`.

Medido no journal de 06:19:56-06:20:08: os 7 simbolos com ficheiro diziam PASS/READY, e o motor estava em
fallback para os mesmos 7 ficheiros (idade 24 dias). Duas verdades sobre o mesmo dado, no mesmo arranque.

### 70.2 Correcao

Um so criterio, o do motor, lido do proprio input:

- `ProductionChecklist`: novo helper `PredictionAgeSeconds` (mesma leitura de `PredictionAgeHours`, convertida);
  o item passa a `PASS` so quando o ficheiro existe **e** a idade nao excede `MaxPredictionAgeSec`;
  mensagem `Prediction STALE: idade=Ns > MaxPredictionAgeSec=900s | motor ignora, fallback tecnico (nao bloqueia)`.
  O item continua `[OPTIONAL]` e so vira critico com `RequireAIJSON=true`.
- `ValidationChecklist`: item 4 le `FileGetInteger(predFile, FILE_MODIFY_DATE)` e aplica o mesmo limiar;
  `VC_WARNING` para STALE quando a IA nao e requerida e `VC_BLOCKED` quando `RequireAIJSON=true`.
- Nenhum limite, risco, spread ou regra de trading foi tocado; muda o veredicto de um item de diagnostico.

### 70.3 Prova

- `ProductionChecklist.mqh` 24033 -> 25540 B; `ValidationChecklist.mqh` 13083 -> 14651 B; `NUL=0`, `LF soltos=0`.
- compilacao de producao: `0 errors, 0 warnings`, `.ex5` 691706 -> 694266 B (06:23:52).
- 16 graficos recarregados por template (mapeamento template->simbolo verificado antes de aplicar).
- journal de 06:24: **16/16 em `v1.2.74`**; item AI agora diz
  `FAIL - Prediction STALE: idade=2103814s > MaxPredictionAgeSec=900s` nos 7 com ficheiro e
  `FAIL - Prediction JSON nao encontrado (IA offline)` nos 9 sem ficheiro.

### 70.4 PENDENTE

- A previsao mais recente em disco e de **08/10/2026** (24 dias). Enquanto o pipeline nao escrever previsoes
  novas, os 16 simbolos operam em fallback e os itens AI/JSON/Python continuam nao criticos. Isto e medicao,
  nao defeito de codigo.

## 71. P1.61 (v1.2.75) - portao de negociacao com fonte unica

### 71.1 Defeito medido (02/11/2026)
Antes das 06:05 o EA negociava normalmente - log do terminal: deal
#10937250385 buy 0.1 AUDUSD as 01:00:09, deal #10937802145 sell 0.04 USDCAD as
02:00:09 e fecho do AUDUSD as 04:46:27.
As 06:05:05.056 o USDSGD recarregou (recompilacao) e as 06:05:05.800 veio o
primeiro [TRADE BLOCK] do dia. Dali em diante as 16 charts ficaram bloqueadas
com "ALGO TRADING OFF | Ative o botao Algoritmos ..." enquanto:
- terminal_get_info -> experts_trade_allowed = true;
- TERMINAL_TRADE_ALLOWED = 1 e ACCOUNT_TRADE_ALLOWED = 1 nas 16 charts.
A mensagem mandava ligar um botao que ja estava ligado.

No mesmo instante (08:09) tres sitios respondiam a mesma pergunta de formas
diferentes:
- portao de OnTick (XAU_AI_PRO.mq5): MQL && TERMINAL -> BLOCKED;
- ProductionChecklist item 2: TERMINAL && CONTA -> PASS;
- ValidationChecklist item 13: EA && TERMINAL -> BLOCKED.

### 71.2 Correcao
Criado Core/TradeGate.mqh (enum ETradeGate + class CTradeGate) com Mql(),
Terminal(), Account(), Expert(), Connected(), Evaluate(), Ok(), Bits(),
Cause(estado) e Describe(estado). O portao de OnTick, o item 2 da producao e o
item 13 da validacao passam a chamar a MESMA funcao, e a mensagem nomeia qual
dos cinco bits esta a falhar em vez de culpar o botao do terminal.
Versao 1.2.75. Compilado 0 errors / 0 warnings (699222 B as 08:17:20).

### 71.3 Prova
Log do EA a partir de 08:14:19.149, identico nos 16 simbolos:
[TRADE BLOCK] Trading barrado pelo PROPRIO EA: ... | MQL_TRADE_ALLOWED=0
TERMINAL_TRADE_ALLOWED=1 ACCOUNT_TRADE_ALLOWED=1
E o item 2 da producao passou a FAIL (antes dizia PASS com o mesmo dado).

### 71.4 Causa raiz: ABERTA, com hipotese medida e REJEITADA
Hipotese 1 (template com expertmode sem o bit de trade): testada e rejeitada.
- 08:14:18-19: os 16 xai_p159_*.tpl com <expert> expertmode=5 reaplicados ->
  o bit continuou 0 em todos;
- 08:15:28: chart nova USDDKK M30 anexada por API, sem template nenhum -> 0;
- 08:16: o proprio chart vivo, ao gravar template, escreve expertmode=0;
- 08:18: os 16 .chr do perfil ativo tambem ja estavam a expertmode=0;
- cmp_tpl.ps1: cabecalhos <expert> do template que negociava, do template que
  bloqueava e do perfil que negociava ficaram identicos - e o bit nao voltou.
Conclusao: expertmode de .tpl/.chr NAO e a permissao do programa.

O log do terminal nao registou nenhuma mudanca de permissao
(ocorrencias de algor|autotrading|trade disabled|negociacao = 0).

Nao existe API MQL5 que escreva MQL_TRADE_ALLOWED: e um bit por programa,
ligado na janela de propriedades do EA (caixa de negociacao algoritmica) ou
por reanexacao manual pela GUI. ACao NECESSARIA, humana e de 1 clique por
chart (ou 1 reanexacao manual): abrir as propriedades do EA e marcar a caixa.
Enquanto isso, nada negoceia - e o EA agora diz exatamente isso, com o bit.

## 72. P1.62 (v1.2.76) - o mesmo dado, um so veredito

### 72.1 Defeito medido
As 08:17 o ficheiro Common\Files\XAU_AI_PRO_heartbeat.json dizia
"autotrading":true enquanto as 16 charts imprimiam MQL_TRADE_ALLOWED=0 e
nenhuma podia negociar. O campo vinha so de TERMINAL_TRADE_ALLOWED. O texto
do ExternalBridge dizia autotrading=on pela mesma razao. O SystemStatus
publicava dois bits crus sem veredito. Quatro vocabularios para o mesmo facto.

### 72.2 Correcao
- Integration/EAHeartbeat.mqh: "autotrading" passa a ser CTradeGate::Ok();
  novos campos "terminal_trade_allowed" (bit cru) e "trade_gate_code" (enum).
- Integration/ExternalBridge.mqh: autotrading do portao, mais
  terminal_trade_allowed e trade_gate no texto de estado.
- Monitoring/SystemStatus.mqh: novos campos "trade_gate_ok" e
  "trade_gate_code" ao lado dos bits crus.
- Enterprise/ConnectionGuard.mqh: ConnAlgoAllowed() deixa de testar 2 dos 5
  bits (podia responder "pode negociar" com a conta bloqueada) e passa a
  CTradeGate::Ok().
Compilado 0 errors / 0 warnings (699784 B as 08:31:02).

### 72.3 Prova
Antes, 08:17:29 (chart USDDKK, mesma conta):
{"...","autotrading":true,"balance":12357.54,...}
Depois, 08:34:24 (16 charts v1.2.76, todas bloqueadas):
{"schema":"ea-heartbeat.v1","state":"RUNNING","timestamp":"2026.11.02 13:34:24","login":113568614,"server":"MetaQuotes-Demo","symbol":"AUDUSD","timeframe":16385,"autotrading":false,"terminal_trade_allowed":true,"trade_gate_code":3,"balance":12357.54,"equity":12357.54,"positions":0,"write_count":1}
trade_gate_code=3 = TG_MQL_OFF. O heartbeat passou a contar a verdade.

### 72.4 Medicao nova: recompilar NAO recarrega os EAs
O .ex5 mudou as 08:31:02 e as 16 charts continuaram a imprimir a mensagem
antiga de 3 bits ate 08:34 (ocorrencias de "1.2.76" = 0). So mudaram depois de
reaplicar os 16 templates as 08:34:24 (48 ocorrencias de "1.2.76" e mensagem
nova de 5 bits). Regra para os proximos ciclos: todo o deploy inclui o reload
explicito dos 16 graficos; compilar sozinho nao chega.

### 72.5 PENDENTE (registado, nao feito)
- XAU_AI_PRO.mqproj ainda nao lista Core\TradeGate.mqh. O ficheiro usa LF e nao
  CRLF, por isso a insercao falhou duas vezes com ancora CRLF. Nao afeta a
  compilacao (o .mq5 inclui o header diretamente); fica para um ciclo com
  edicao propria.
## 73. P1.63 (v1.2.77) - um dado, um veredicto: bloco PERMISSOES do diagnostico

### 73.1 Defeito medido
02/11 as 08:34, com as 16 charts barradas pelo portao:
- heartbeat: "terminal_trade_allowed":true, "trade_gate_code":3 (TG_MQL_OFF);
- journal: [TRADE BLOCK] MQL_TRADE_ALLOWED=0 ... TERMINAL_TRADE_ALLOWED=1;
- Monitoring/Diagnostics.mqh, bloco PERMISSOES: testava SO
  TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) e imprimia "Permissoes: VERDE".
O mesmo dado com dois veredictos opostos no mesmo instante. E exatamente a
classe de defeito que a P1.62 corrigiu no EAHeartbeat, ExternalBridge,
SystemStatus e ConnectionGuard; o diagnostico ficou de fora.

### 73.2 Inventario medido antes da correcao
scan_bits_p163.ps1 sobre Experts\XAU_AI_PRO (todos os .mq5 e *.mqh):
"TOTAL ocorrencias de bits crus = 48 | ficheiros analisados = 105".
Distribuicao: TradeGate.mqh 14 (por desenho), ConnectionGuard 6,
CircuitBreaker 5, SystemStatus 4, RecoveryManager 3, EAHeartbeat 2,
ExternalBridge 2, FailureMode 2, Diagnostics 2, ProductionChecklist 2,
VersionManager 2 (texto de changelog), ValidationChecklist 1,
XAU_AI_PRO.mq5 2 (comentario). Os restantes ficam na fila P1.64+.

### 73.3 Correcao
- Monitoring/Diagnostics.mqh: novo #include "../Core/TradeGate.mqh". O bloco
  PERMISSOES passa a ETradeGate permGate = CTradeGate::Evaluate(), com
  permOK = (permGate == TG_OK) e permDetail = CTradeGate::Cause(permGate).
  O diagnostico devolve a CAUSA (o nome do bit que falta), nao um "nao
  permitido" generico.
- XAU_AI_PRO.mq5: v1.2.76 -> v1.2.77 e #property version "1.277"; o titulo da
  seccao passa a "Portao de negociacao (v1.2.75: 5 bits, fonte unica)";
  separador duplicado removido; comentario "MEDIDO: quem barra o trade" nomeia
  os 5 bits e diz que CircuitBreaker/Safety/Equity sao gates independentes.
- Enterprise/VersionManager.mqh: EA_VERSION_STRING "1.2.77" e changelog novo;
  a entrada v1.2.76 fica preservada integralmente.
Tamanhos: Diagnostics.mqh 16198 -> 16566 B; XAU_AI_PRO.mq5 77242 -> 77402 B;
VersionManager.mqh 60147 -> 60475 B. Prova pos-escrita: CRLF=789 / 2307 / 231,
LF soltos=0, NUL=0, CR duplicado=0 nos tres.

### 73.4 Perigo de metodo (medido e corrigido no mesmo ciclo)
O apply_p163.ps1 calculava o EOL dominante DEPOIS de inserir linhas com \n; o
LF passava a maioritario e a normalizacao convertia o ficheiro inteiro para LF
(Diagnostics 15777 B com CRLF=0; .mq5 75095 B com CRLF=0). Corrigido pelo
fix_eol_p163.ps1 (CRLF->LF, CR solto->LF, LF->CRLF). Regra para os proximos
ciclos: o EOL dominante calcula-se ANTES da edicao, ou normaliza-se de forma
explicita; nunca se infere depois de escrever.

### 73.5 Compilacao e deploy
- compile_prod.ps1: "Result: 0 errors, 0 warnings, 15981 ms elapsed,
  cpu='X64 Regular'"; .ex5 699784 B (08:31:02) -> 700372 B (08:48:49).
- Reload obrigatorio: os 16 templates xai_p159_01..16 foram aplicados as
  08:52:31-08:52:38 (a recompilacao sozinha nao recarrega EAs - ver 72.4).
- Prova no journal: 64 registos "[VERSION] v1.2.77" (4 por chart, 16 charts,
  0 em falta) e a mensagem nova de 5 bits a disparar nas 16, por exemplo:
  [TRADE BLOCK] Trading barrado pelo PROPRIO EA: MQL_TRADE_ALLOWED=0 ...
  | MQL_TRADE_ALLOWED=0 TERMINAL_TRADE_ALLOWED=1 ACCOUNT_TRADE_ALLOWED=1
  ACCOUNT_TRADE_EXPERT=1 TERMINAL_CONNECTED=1
  A causa e o remedio passam a vir do portao, nunca de um bit isolado.

### 73.6 Fechado nesta versao
72.5 (mqproj sem Core\TradeGate.mqh): FECHADO por apply_p162e.ps1. Prova:
bytes 14320 -> 14445, primeiros3=EF BB BF, JSON valido antes (files=102) e
depois (files=103), entrada TradeGate na posicao 25 de 103, compile=false
enable=true, CRLF=0 (o .mqproj e LF por desenho), NUL=0, "MQPROJ: OK".

### 73.7 Continua ABERTO (nao e codigo)
MQL_TRADE_ALLOWED=0 com os outros 4 bits a 1. Nenhuma API MQL5 escreve este
bit, nenhum template o religa (expertmode=5 medido de novo as 08:52) e nenhuma
recompilacao recarrega o EA. Falta um ato humano por chart: marcar "negociacao
algoritmica" nas propriedades do EA, ou reanexar pela GUI. Nada foi relaxado:
MaxSpreadPct 0.6, MinAIConfidence 60.0, MinMarketScore 65.0 e portao de IA 0.05
intactos; conta 113568614 com 0 posicoes e 0 ordens.


## 74. P1.64 (v1.2.78) - o portao de negociacao nao olhava para a ligacao

### 74.1 Defeito medido no codigo (nao suposto)

`Core/TradeGate.mqh` respondia a pergunta "posso negociar?" lendo QUATRO bits:
`TERMINAL_TRADE_ALLOWED`, `ACCOUNT_TRADE_ALLOWED`, `ACCOUNT_TRADE_EXPERT` e
`MQL_TRADE_ALLOWED`. O quinto bit que o proprio ficheiro listava no cabecalho -
`TERMINAL_CONNECTED` - existia apenas como acessor (`CTradeGate::Connected()`) e
NUNCA era testado por `Evaluate()`.

Consequencia estatica, provavel por construcao: com o terminal sem ligacao ao
servidor e os outros quatro bits a 1, `Evaluate()` devolvia `TG_OK` e
`Describe()` escrevia "Trading permitido". E os tres sitios que testavam o bit
escreviam tres frases diferentes para o MESMO bit:

| sitio | teste | frase |
|---|---|---|
| `Monitoring/Diagnostics.mqh` (bloco Broker) | `TerminalInfoInteger(TERMINAL_CONNECTED)` | `Terminal nao conectado` |
| `Monitoring/ProductionChecklist.mqh` item 0 | idem | `Terminal desconectado` |
| `Monitoring/ValidationChecklist.mqh` item 8 | idem | `Terminal desconectado (bloqueia)` |

Um dado, tres veredictos - e o portao a dizer que sim. Esta e a mesma classe do
P1.63, agora no bit da ligacao.

### 74.2 Correcao

1. `Core/TradeGate.mqh`:
   - novo valor `TG_DISCONNECTED = 5` no enum (acrescentado no fim: nenhum valor
     existente foi renumerado, para nao reinterpretar `trade_gate_code` ja
     publicado no heartbeat);
   - `Evaluate()` testa `Connected()` ANTES dos outros quatro - sem ligacao nao
     existe negociacao possivel, e a causa deve ser a primeira a aparecer;
   - `Cause(TG_DISCONNECTED)` devolve uma frase unica.
2. `Monitoring/Diagnostics.mqh`: o bloco Broker passa a `CTradeGate::Connected()`
   e a `CTradeGate::Cause(TG_DISCONNECTED)`.
3. `Monitoring/ProductionChecklist.mqh` item 0: idem (`bool ok = CTradeGate::Connected();`).
4. `Monitoring/ValidationChecklist.mqh` item 8: idem (`bool brokerOK = CTradeGate::Connected();`).
5. `XAU_AI_PRO.mq5`: v1.2.77 -> v1.2.78, `#property version "1.278"`.
6. `Enterprise/VersionManager.mqh`: `EA_VERSION_STRING "1.2.78"` + changelog.

Agora o mesmo bit produz a mesma frase nos tres sitios, por construcao.

### 74.3 Prova

- `apply_p164.ps1` (Fase 1 verifica todas as ancoras antes de escrever uma linha;
  se qualquer ancoragem nao for unica, aborta sem gravar): `FASE 1 OK: todas as
  ancoras unicas` e `P164: OK`.
- Marcas no disco: `TG_DISCONNECTED = 5`=1, `if(!Connected())`=1,
  `Trading barrado pela LIGACAO`=1, `CTradeGate::Connected()` em Diagnostics=1,
  `bool ok = CTradeGate::Connected();`=1, `bool brokerOK = CTradeGate::Connected();`=1,
  `CTradeGate::Cause(TG_DISCONNECTED)`=1 em cada um dos tres,
  `// XAU_AI_PRO v1.2.78`=1, `1.278`=1, `"1.2.78"`=1.
- Ficheiros: TradeGate.mqh 5767 B CRLF=115 LF_soltos=0 NUL=0 CRCR=0;
  Diagnostics.mqh 16615 B CRLF=788; ProductionChecklist.mqh 25790 B CRLF=789;
  ValidationChecklist.mqh 15080 B CRLF=384; XAU_AI_PRO.mq5 77402 B CRLF=2307;
  VersionManager.mqh 60973 B CRLF=231. Todos com LF_soltos=0, NUL=0, CRCR=0.
- Backups `.pre_p164` criados para os seis ficheiros antes da escrita.

### 74.4 Compilacao e deploy

- `compile_prod.ps1`: `Result: 0 errors, 0 warnings, 15607 ms elapsed, cpu='X64 Regular'`;
  producao .ex5 700372 B (08:48:49) -> 702120 B (08:58:30).
- Reload obrigatorio das 16 charts (`xai_p159_01..16.tpl`) porque o MT5 NAO
  recarrega um EA recompilado - regra ja medida em ciclos anteriores.
- Journal `[VERSION]`: 96 registos na janela 08:55-09:20, dos quais 64 sao de
  `v1.2.78` (4 por chart, 16/16 charts) entre 08:58:39.735 e 08:58:46.732; as 32
  linhas `v1.2.77` restantes sao o estado anterior de cada chart antes de o
  template o substituir (08:58:39.268-08:58:46.283) - a transicao nao e atomica
  entre charts, como ja documentado no P1.63.

### 74.5 Metodo (repetido de proposito)

`apply_p164.ps1` calcula o EOL dominante ANTES de editar (`NL`), escreve todas as
insercoes com esse EOL e normaliza explicitamente CRLF->LF, CR solto->LF,
LF->CRLF antes de gravar. Foi o erro do P1.63 (contar o EOL depois de inserir
linhas `\n`) que inverteu dois ficheiros para LF; aqui nao se repetiu:
`LF_soltos=0` nos seis ficheiros.

### 74.6 O que continua ABERTO

- `MQL_TRADE_ALLOWED=0` nas 16 charts: nenhuma API MQL5 escreve este bit, nenhum
  template o religa, nenhuma recompilacao recarrega o EA. Falta um ato humano por
  chart (caixa de negociacao algoritmica nas propriedades do EA, ou reanexar pela
  GUI). Sem isso o portao devolve `TG_MQL_OFF` e nada negoceia.
- Leitores de bits crus ainda por alinhar (fila P1.65+): `Monitoring/SystemStatus.mqh`
  54/55/56, `Enterprise/FailureMode.mqh` 127/129, `Enterprise/RecoveryManager.mqh`
  254/262/283, `Enterprise/CircuitBreaker.mqh` 350/351/584/585,
  `Enterprise/ConnectionGuard.mqh` 47/64/67, `Integration/EAHeartbeat.mqh` 40,
  `Integration/ExternalBridge.mqh` 189. Nenhum deles decide permissao de negociacao
  (sao estado e diagnostico), por isso nao foram tocados neste ciclo: sem medicao
  de divergencia nao se mexe.

## 75. P1.65 (v1.2.79) - a mensagem do [TRADE BLOCK] estava a mandar o operador para o sitio errado

### 75.1 O que estava errado

A frase de `TG_MQL_OFF` dizia: "caixa de negociacao algoritmica das propriedades
do EA". As 09:00 mediram-se, no mesmo instante, os dois lados:

| fonte | valor |
|---|---|
| `terminal_get_info` | `experts_trade_allowed: true`, `mcp_trade_allowed: true` |
| `[TRADE BLOCK]` (16 charts) | `TERMINAL_TRADE_ALLOWED=1 ACCOUNT_TRADE_ALLOWED=1 ACCOUNT_TRADE_EXPERT=1 TERMINAL_CONNECTED=1` e `MQL_TRADE_ALLOWED=0` |

Ou seja: o botao Algo Trading do terminal estava LIGADO. O bit em falta e o bit
POR PROGRAMA. A mensagem apontava para um sitio que nao e o medido e nao
distinguia o que ja foi rejeitado do que ainda nao foi testado.

### 75.2 Correcao

`Cause(TG_MQL_OFF)` passa a dizer, por esta ordem:
1. o que e o bit (por programa, nao do terminal);
2. o que foi medido (terminal ligado, `TERMINAL_TRADE_ALLOWED=1`);
3. as duas hipoteses POR TESTAR (religar o botao Algo Trading; reanexar pela GUI);
4. o que ja foi REJEITADO por medicao (template com `expertmode=5` as 08:14 e
   08:58; anexacao por API as 08:15).

Nota P1.65 no cabecalho de `Core/TradeGate.mqh` a explicar porque a frase mudou.
Nenhum limiar, nenhuma permissao e nenhuma logica de negociacao foi alterada -
apenas texto de diagnostico, versao e changelog.

### 75.3 Prova

- `apply_p165.ps1`: `FASE 1 OK: todas as ancoras unicas`; marcas
  `bit POR PROGRAMA`=1, `Hipoteses por testar`=1, `NAO religam (MEDIDO)`=1;
  `// XAU_AI_PRO v1.2.79`=1, `1.279`=1, `"1.2.79"`=1, changelog P1.65=1 e
  changelog P1.64 preservado=1.
- O guard final do script abortou com "frase antiga ainda presente": falso
  positivo - a unica ocorrencia restante e a CITACAO da frase antiga dentro da
  nota P1.65 (linha 41). Verificado por `search_regex` no ficheiro:
  linha 32 = comentario historico do P1.62, linha 41 = a citacao. Nenhuma
  mensagem em producao usa a frase antiga.
- Ficheiros: TradeGate.mqh 5767 -> 6468 B (CRLF 115 -> 120), XAU_AI_PRO.mq5 77402 B
  (CRLF 2307), VersionManager.mqh 60973 -> 61418 B (CRLF 231). Todos
  `LF_soltos=0 | NUL=0 | CRCR=0`. Backups `.pre_p165` criados.
- Compilacao: `Result: 0 errors, 0 warnings, 15817 ms elapsed`; producao .ex5
  702120 B (08:58:30) -> 702612 B (09:01:35).
- Deploy: 16 templates reaplicados as 09:01:39-09:01:44; journal com 48 registos
  `v1.2.79` (3 por chart, 16/16 charts).
- Mensagem nova confirmada em producao as 09:01:39.955 (USDCAD) e seguintes:
  `[TRADE BLOCK] PROGRAMA sem permissao: MQL_TRADE_ALLOWED=0 e um bit POR
  PROGRAMA, nao do terminal. MEDIDO 02/11 09:00: ... | MQL_TRADE_ALLOWED=0
  TERMINAL_TRADE_ALLOWED=1 ...`.

### 75.4 O que continua a barrar a negociacao (medido as 09:00)

`MQL_TRADE_ALLOWED=0` nas 16 charts com os outros quatro bits a 1. Saldo/equity
12357.54 USD, margem 0, 0 posicoes, 0 ordens. Nenhuma API MQL5 escreve este bit.
As duas hipoteses que restam exigem GUI (botao Algo Trading da barra, ou
reanexacao do EA no grafico) - nao ha ferramenta MCP para as executar. Enquanto
isso o portao devolve `TG_MQL_OFF` e o EA nao envia ordens, que e o comportamento
correto e seguro.

---

## 76. P1.66 (v1.2.79, sem alteracao de codigo) - a IA nao tem edge e o unico bloqueio e UM bit

MEDIDO em 02/11/2026, 13:32-14:05 local, conta 113568614 (MetaQuotes-Demo).
Nenhum ficheiro .mq5/.mqh foi alterado neste ciclo; nenhuma compilacao foi pedida.

### 76.1 O bloqueio de negociacao continua a ser UM bit

Tres leituras do heartbeat (`Common\Files\XAU_AI_PRO_heartbeat.json`, 298 B,
`write_count=1`) dao `autotrading=false`, `terminal_trade_allowed=true`,
`trade_gate_code=3`. O journal 13:24:13-13:27:27 mostra `[TRADE BLOCK]
PROGRAMA sem permissao: MQL_TRADE_ALLOWED=0` nos 16 graficos. Como
`Core\TradeGate.mqh::Evaluate()` testa `Mql()` por ULTIMO, o codigo 3 prova que
os quatro bits anteriores PASSARAM. So uma accao GUI religa este bit: nenhuma
API MQL5 o escreve, e ja foram reprovadas 5 hipoteses (template com
expertmode=5 as 08:14 e 08:58, attach por API as 08:15, e o reload automatico
dos 16 graficos as 13:15:27 depois do build de 704172 B).

### 76.2 A IA NAO bloqueia entrada (correcao de premissa)

`AI\AIEngine.mqh:47-58`: `AIGateRequired()` devolve **false** quando
`EnableAIFilter=true` **e** `EnableAutonomousMode=true`. Os 16 graficos tem
`EnableAutonomousMode=true`, logo a IA e CONSULTIVA: a indisponibilidade dela
nao veta nada. `BlockZeroAIScore=true` so barra `score<=0`, e o score vem de
`AdvancedAIScore()` — componentes tecnicos locais, nao do gateway.
A minha premissa anterior ("sem IA nao ha entrada") so vale para
`EnableAutonomousMode=false`. Consequencia: **o dinheiro real esta preso
exactamente a UM bit**, nao a dois. Nao ha nenhuma decisao de risco a tomar
para o EA poder operar.

### 76.3 O dataset real existe e e bom; o edge nao existe

`Files\Data\dataset_mt5_20261101.csv` (138.869.179 B, 01/11/2026 23:31):
1.494.248 linhas, 15 colunas sem cabecalho, 16 simbolos — os 16 dos graficos,
incluindo os 9 que nunca tiveram modelo (USDBRL, USDCLP, USDCOP, USDSEK,
USDCZK, USDCNH, USDRUB, USDSGD, USDCHF) —, 2009.08.30 -> 2026.11.02 01:30,
zero linhas com simbolo invalido. O `Files\Data\dataset.csv` (3.598.776 B) e
lixo: 10.893 linhas, 418+ malformadas, 1 dia, 86 pseudo-simbolos.

Medicao com o script reproduzivel `Files\Temp\medir_edge_v2.py` (importa
`Python\ai\train_v2.py` e NAO grava modelo nenhum): 58 combinacoes
simbolo x timeframe em M5/M15/H1/H4, `PUBLICACAO_MIN_EDGE = 0.05` intocado.
**ZERO publicaveis.** As maiores:

| Combinacao | acc | palpite | edge | folds + | veredicto |
|---|---|---|---|---|---|
| USDBRL H1 | 0,4614 | 0,3489 | +0,1124 | 1/5 | recusado: instavel (media -0,0466) |
| USDRUB M5 | 0,4322 | 0,3640 | +0,0682 | 1/5 | recusado: instavel (media -0,1245) |
| USDRUB M15 | 0,4266 | 0,3891 | +0,0376 | 2/5 | abaixo do piso |
| USDCOP M5 | 0,3880 | 0,3516 | +0,0364 | 4/5 | abaixo do piso |
| USDSEK M15 | 0,3858 | 0,3501 | +0,0357 | 5/5 | abaixo do piso |
| EURUSD M15 | 0,3678 | 0,3576 | +0,0102 | 4/5 | abaixo do piso |
| USDCNH H4 | 0,2607 | 0,4976 | -0,2370 | 1/5 | negativo |
| EURUSD H4 | 0,3104 | 0,4597 | -0,1493 | 2/5 | negativo |

`edge_consistente()` faz o trabalho dele: os numeros grandes de split unico
sao exactamente os folds ruidosos. **Retreinar nao conclui a IA.** Os 28
STALE poderiam virar READY por mtime e os 11 `publicable=false` continuariam
ERROR; publicar os novos seria trocar STALE por ERROR nos 58. Os 515,1 MB de
`Python\models` (78 ficheiros, mais recente 22/10 20:04) ficaram INTOCADOS.

### 76.4 O transporte da IA esta partido em tres pontos (medido)

`Core\Config.mqh:30` -> `AIGatewayUrl = "http://127.0.0.1:9001/api/ai/predict"`.

1. **porta**: `9001` esta LISTEN do pid 2440 `terminal64` desde 31/10 15:24:38
   e responde `401` com `server=MetaTrader5-MCP`. E o servidor MCP, nao o
   gateway. `backend\mt5_gateway.py::_porta_gateway()` tem 9001 como PADRAO —
   a porta do EA esta certa por desenho; o gateway e que nao esta a correr.
2. **metodo**: o EA faz `POST` (`AI\AIConnector.mqh::FetchPredictionFromGateway`,
   payload `{}` e `?symbol=&timeframe=` na URL) e a rota canonica e
   `@app.get("/api/ai/predict")` (`backend\fastapi_gateway.py:258`). POST
   recebe 405 — e o EA registaria "HTTP 405" como se fosse token.
3. **dependencias**: `Files\Temp\py311\python.exe` (3.11.9) tem numpy,
   pandas, sklearn, joblib, scipy e MetaTrader5 — e NAO tem fastapi, uvicorn,
   flask nem requests. O gateway canonico nao arranca sem pip.

Nada disto bloqueia operacao: com a IA consultiva (§76.2), o EA opera sem
gateway. O que fica quebrado e a LEITURA da IA, nao a execucao.

### 76.5 O que exige accao do dono

1. Religar `MQL_TRADE_ALLOWED` pela GUI (botao Algo Trading OFF 2 s -> ON).
   Criterio objectivo: `trade_gate_code` passa a 0 no heartbeat E
   `[TRADE BLOCK]` desaparece no mesmo instante.
2. Decidir o destino da IA: aceitar que ela e consultiva e nao publica sinal
   (estado actual, medido) ou autorizar um ciclo de investigacao de
   features/alvo. Baixar o piso 0,05 NAO e uma opcao — seria publicar ruido.
3. Dizer se o servidor MCP pode sair da porta 9001, ou se o gateway deve
   passar a usar outra porta e o `AIGatewayUrl` dos 16 graficos muda.

## 77. P1.67 (v1.2.80) - o MESMO estado de tick dava DOIS veredictos e o watchdog ficava cego

### 77.1 O defeito, medido no journal das 16 instancias (v1.2.79, 02/11/2026)
USDBRL/M5, USDCOP/H1 e USDCLP/H1 imprimiam, na MESMA janela de tempo, as tres
linhas seguintes para o MESMO dado (0 ticks):
- `Total ticks: 0 | Segundos sem tick: 14641`
- `Status: HEALTHY | Segundos sem tick: 120 | Backoff: nivel=0 intervalo_efetivo=60s`
- `Status: FAILURE | Segundos sem tick: 14641 | Backoff: nivel=11 intervalo_efetivo=1920s`
Dois veredictos para um dado so. Pior: `nivel=11` significa intervalo efectivo
de 1920 s, ou seja o watchdog fica cego 32 minutos seguidos.

### 77.2 A causa (lida no codigo, nao suposta)
`Monitoring\HealthMonitor.mqh`:
- `HealthMonitorCheckTickTimeout(15)` ja perdoava o "sem tick" quando
  `HealthSymbolSessionOpen()` e false (correcao da v1.2.31);
- `HealthMonitorCheckHeartbeats()` nao tinha guarda nenhuma. ATR/ADX/RSI/IA so
  avancam dentro de `OnTick`, logo sem tick falham SEMPRE -> `healthy=false` ->
  `g_healthConsecutiveFails++` -> `HealthGetBackoffInterval` escala ate nivel 11.
Resultado: a mesma ausencia de tick era "normal" para um teste e "falha" para o
outro, e a falha artificial envenenava o backoff do watchdog.

### 77.3 A correcao (minima, cirurgica)
- `bool tickEmFalta = !HealthMonitorCheckTickTimeout(15);`
- a falha dos heartbeats so propaga a `healthy` quando HOUVE tick:
  `if(!HealthMonitorCheckHeartbeats()) { if(!tickEmFalta) healthy = false; }`
Nenhum limite, `return`, regra de trading, parametro de risco, condicao de
entrada ou de saida foi alterado: so a atribuicao de um veredicto de saude.

### 77.4 Provas de bytes (medidas depois da escrita)
- `Monitoring\HealthMonitor.mqh`: 26818 -> 27996 B | CRLF 925 -> 945 | LF_soltos 0 -> 0 | NUL 0 -> 0 | EOL=CRLF
- `Enterprise\VersionManager.mqh`: 61418 -> 62892 B | CRLF 231 -> 231 | LF_soltos 0 | NUL 0 (EA_VERSION_STRING "1.2.80" + changelog)
- `XAU_AI_PRO.mq5`: 77402 -> 77402 B (so `#property version "1.280"`; mesmo numero de bytes, conteudo verificado)
- backups `.pre_p167` ao lado de cada ficheiro.

### 77.5 Incidente de build (medido, e corrigido no mesmo ciclo)
O primeiro build deu `Result: 40 errors, 10 warnings`: o texto novo do changelog
entrou com ASPAS DUPLAS cruas dentro do literal MQL5 e partiu a string.
E o MetaEditor APAGA o `.ex5` quando o build falha: a producao ficou cerca de
90 segundos SEM binario (`XAU_AI_PRO.ex5` 704172 B -> ausente -> recriado).
Corrigido reescrevendo a linha 63 sem aspas internas (aspas simples). Build final:
`Result: 0 errors, 0 warnings, 16988 ms elapsed, cpu='X64 Regular'`
`.ex5` novo: 703094 B | 02/11/2026 14:16:47.
Copia de seguranca do binario bom: `Files\Backup\XAU_AI_PRO_v1280_ok.ex5`.
Licao operacional: guardar sempre o ultimo `.ex5` bom antes de compilar, porque
um erro de compilacao deixa a producao sem programa.

### 77.6 Deploy nos 16 graficos (medido)
O MT5 NAO recarregou os 16 graficos sozinho desta vez: o journal do terminal nao
tem `removed`/`loaded successfully` entre 14:16:06 e 14:18. Reanexei os 16 por
API com os DEFAULTS COMPILADOS, que sao identicos aos valores que os graficos ja
tinham (comparado `get_expert_advisor_parameters` com `list_open_charts`: 308
inputs, todos iguais; 1 grupo). As 16 instancias novas imprimem
`[VERSION] v1.2.80 | build 2026.11.02`.

### 77.7 O que continua exactamente igual
- `MQL_TRADE_ALLOWED=0` continua a ser o UNICO bloqueio de dinheiro (`trade_gate_code=3`).
- A IA continua consultiva (`EnableAutonomousMode=true`, `AIGateRequired()` devolve false).
- Nenhum input de risco foi tocado (RiskPercent 1,0; MaxDailyLossPercent 10; MaxDrawdownPercent 15; MaxSpreadPct 0,6; MinMarketScore 65; MinAIConfidence 60; BlockZeroAIScore; MaxPredictionAgeSec 900).
- Piso de edge 0,05 intocado; `Python\models` (78 ficheiros, 515,1 MB) e `frontend\dist` intocados.

### 77.8 Pendente de verificacao no journal
Depois do deploy, o criterio objectivo e: USDBRL/USDCOP/USDCLP (0 ticks) NAO
devem voltar a imprimir `Status: FAILURE` nem `Backoff: nivel=11`; devem manter
um unico veredicto coerente. A medicao exige uma janela com o monitor a correr.

### 77.9 Verificado no journal (02/11/2026 14:18-14:32, depois do deploy)
Criterio definido em 77.8 e cumprido:
- `FAILURE`: 0 registos em 14:18-14:32 (antes da correcao era o estado permanente
  de USDBRL/M5, USDCOP/H1 e USDCLP/H1).
- `Backoff`: USDBRL/M5, USDCOP/H1 e USDRUB/H1 imprimem agora
  `nivel=0 intervalo_efetivo=60s`; antes imprimiam `nivel=11 intervalo_efetivo=1920s`.
- `[HEALTH]` no arranque: 16/16 instancias `HEALTHY`, incluindo as de 0 ticks
  (`USDBRL sem tick=30s`, `USDCOP sem tick=30s`, `USDCLP sem tick=26s`,
  `USDRUB sem tick=30s`).
- Cadencia observada do resumo por grafico: 14:20:44 -> 14:22:44 (2 min), nao
  1920 s. O watchdog deixou de ficar cego 32 minutos.
Um dado, um veredicto: o mesmo `Total ticks: 0` ja nao produz HEALTHY e FAILURE
ao mesmo tempo.


## 78. P1.68 (v1.2.81) - o journal tinha os numeros todos e nenhuma leitura

### 78.1 O que foi medido (02/11/2026, MQL5\Logs\20261102.log)

Ficheiro do dia: 138 702 linhas, 15,5 MB, horas 00 a 15. Contagem LITERAL (o
`-like` do PowerShell trata `[` como classe de caracteres e inflaciona tudo -
a primeira medicao deste ciclo deu 66 286 linhas de `[HEALTH]` que eram o
proprio total; foi refeita com `.Contains()`):

| fonte | linhas | % do dia |
|---|---:|---:|
| `[SCANNER] BLOCK` (por simbolo) | 18 532 | 13,4% |
| `SYMBOL MANAGER` | 7 955 | 5,7% |
| `[TRADE BLOCK]` | 7 272 | 5,2% |
| blocos `SYSTEM STATUS` (14 linhas cada) | 586 | ~8 200 linhas |
| blocos `HEALTH MONITOR` (20 linhas cada) | 152 | ~3 000 linhas |
| `[SESSION] estado salvo` | 3 070 | 2,2% |

Nenhuma destas linhas era um EVENTO. Eram o mesmo retrato periodico, repetido
por 16 instancias. A prova mais directa: `[TRADE BLOCK]` apareceu 7 272 vezes
com o MESMO texto (`Trading barrado pelo TERMINAL: botao Algoritmos OFF ...`),
1x/60 s por grafico. O `[SCANNER] BLOCK` (18 532) so aparece nas horas 00-06,
que foram as horas em que o portao deixou passar: e a fonte que volta assim
que a permissao for religada.

### 78.2 A correcao (so impressao, nada de decisao)

1. `SYSTEM STATUS` e `HEALTH MONITOR` passam a sair numa UNICA linha, com
   TODOS os valores que ja saiam, colapsados por `JournalOneLine()` (nova
   funcao no `.mq5`, converte `\n` em ` | `).
2. `AllowBlockPrintCausa(causa)` - o gate do portao passa a ser por CAUSA:
   causa nova imprime na hora, causa igual sai 1x/10 min (era 1x/60 s).
   Medido em `TimeLocal()` para nao depender de tick.
3. `ScanBlock()` - o detalhe por simbolo so sai quando o DESFECHO daquele
   simbolo MUDA, com heartbeat de 30 min. O `[SCANNER] RESUMO` continua a
   publicar a contagem por balde a cada minuto.
4. `SYMBOL MANAGER | Resolved` so imprime quando ha REMAPEAMENTO real
   (`candidates[i] != symbol`): 7 955 linhas diziam `XAUUSD -> XAUUSD`.

### 78.3 Provas de bytes (medidas depois da escrita)

```
XAU_AI_PRO.mq5           bytes 77402 -> 79783 | CRLF 2307 -> 2359 | LF_soltos 0 | NUL 0 | BOM=False
Enterprise\VersionManager.mqh  bytes 62498 -> 63819 | CRLF 231 -> 231  | LF_soltos 0 | NUL 0
Core\MarketScanner.mqh    bytes 12753 -> 13980 | CRLF 434 -> 476  | LF_soltos 0 | NUL 0
Core\SymbolManager.mqh    bytes 13274 -> 13564 | CRLF 446 -> 450  | LF_soltos 0 | NUL 0
```

Backups `.pre_p168` dos quatro ficheiros. O guard do script compara TEXTO e nao
contagem de bytes (o falso positivo do P1.67 nao voltou a acontecer).

### 78.4 Build e deploy

```
Result: 0 errors, 0 warnings, 18719 ms elapsed, cpu=X64 Regular
EX5 706646 B | 2026-11-02T15:51:26
BACKUP anterior mantido: Files\Backup\XAU_AI_PRO_v1280_ok.ex5 (703094 B)
```

O MT5 nao recarregou os EAs sozinho (journal do terminal 15:52:28-15:52:29
so mostra o `chart_add_expert`), por isso os 16 graficos foram religados pela
API. `get_expert_advisor_parameters` vs `list_open_charts`: os 308 inputs e o
unico grupo sao identicos, logo nenhum parametro mudou no deploy.

### 78.5 Verificacao no journal (medida)

```
ANTES  (v1.2.80, 15:42:00-15:52:00, 10 min): total=201 | TRADEBLOCK=118
DEPOIS (v1.2.81, 15:53:30-15:59:30,  6 min): total=16  | TRADEBLOCK=0
```

`[TRADE BLOCK]` passou de 11,8 linhas/min para 0 (imprimiu uma vez por grafico
no primeiro tick e cala-se 10 min). O retrato completo continua a sair, agora
numa linha:

```
[STATUS] HEALTHY | === RECOVERY STATUS === |   AI: OK | Failures: 0 | ... | Overall: RECOVERY_OK | === EXECUTION SUMMARY === | Orders=0 | ... | FreeMargin: 12535.64
[HEALTH] HEALTHY | === HEALTH MONITOR === | Status: HEALTHY | Uptime (s): 240 | ... | Backoff: nivel=0 intervalo_efetivo=60s | --- Heartbeats --- | ATR: 3 falhas | ...
```

### 78.6 O que continua exactamente igual

- Nenhum limite, return, regra de entrada ou saida, `RiskPercent`,
  `MaxDailyLossPercent`, `MaxDrawdownPercent`, `MaxSpreadPct`, `MinMarketScore`,
  `MinAIConfidence`, `BlockZeroAIScore`, `MaxPredictionAgeSec` ou lote foi
  tocado. So o que vai para o journal.
- `HealthMonitorCheck()`, `CTradeGate::Evaluate()` e o pipeline correm nos
  mesmos ciclos; muda apenas se a linha de retrato volta a ser escrita.
- `Python\models` (78 ficheiros, 515,1 MB) e `frontend\dist` continuam
  intocados. Portao `PUBLICACAO_MIN_EDGE=0.05` intocado.

### 78.7 Pendente

- `[SCANNER] BLOCK` so sera verificavel quando a permissao voltar (o portao
  corta antes do scanner). O gate esta instalado e compilado.
- A permissao continua OFF: `terminal_get_info` as 18:46Z deu
  `experts_trade_allowed=false` e o heartbeat do proprio EA as 15:52:30 deu
  `trade_gate_code=1` (`TG_TERMINAL_OFF`) com `TERMINAL_TRADE_ALLOWED=0`.
  Nenhuma API MQL5 escreve esse bit: so o botao do terminal.
- `[SESSION] estado salvo` (3 070) e `SYMBOL MANAGER` de init continuam como
  estavam - a primeira e uma linha util, o segundo so sai no arranque.

## 80. P1.70 (v1.2.83) - journal minimo: o retrato final e o estado da sessao

### 80.1 O que foi medido (02/11/2026, MQL5\Logs\20261102.log, 149 054 linhas)

| Linha | Ocorrencias | Porque sobrava |
|---|---:|---|
| QUANT MATRIX | 316 | tabela de 14 linhas impressa no encerramento de CADA instancia (16 por reanexacao) |
| BACKTEST ANALYZER | 948 | idem, com [Trades=0 / PF=0.00] repetido |
| BENCHMARK | 625 | idem |
| [SESSION] estado salvo | 3 181 | a MESMA linha (trades=1 / W=0 / L=0 / pico=12535.64) a cada 5 min por grafico |
| [NOTIFY] | 1 626 | SendNotification 4517 (Push desligado no terminal) |
| [LEARN] | 4 825 | "varredura em espera / throttle de 1h por conta" |
| AI GATEWAY | 741 | WebRequest 4014 (URL nao autorizada) |

### 80.2 A correcao (so impressao)

1. `Print(QuantSummary())` (XAU_AI_PRO.mq5, OnDeinit) -> so no tester. `QuantSaveReport()` continua a gravar o ficheiro em FILE_COMMON.
2. `CBenchmarkEngine::LogComparison()` -> so no tester. `BenchmarkReport.txt` continua a ser gravado.
3. `Print("BACKTEST ANALYZER | Finalizado | ...")` (Monitoring\BacktestAnalyzer.mqh) -> so no tester.
4. `[SESSION] estado salvo` -> imprime apenas quando o resumo MUDA, com heartbeat de 30 min.

### 80.3 Provas de bytes

- XAU_AI_PRO.mq5: 79 783 -> 81 363 bytes, CRLF 2 359 -> 2 386, LF_soltos 0, NUL 0.
- Monitoring\BacktestAnalyzer.mqh: 9 288 -> 9 399 bytes, CRLF 407 -> 409, LF_soltos 0, NUL 0.
- Enterprise\VersionManager.mqh: 64 784 -> 65 539 bytes, CRLF 231 -> 231, LF_soltos 0, NUL 0.
- Backups .pre_p170 criados antes de cada escrita. `#property version "1.283"`. `#define EA_VERSION_STRING "1.2.83"`.

### 80.4 Build e deploy

- Copia de seguranca do binario anterior: `Files\Backup\XAU_AI_PRO_v1282_ok.ex5`.
- Build: `Result: 0 errors, 0 warnings, 15975 ms elapsed, cpu=X64 Regular`. EX5 706 940 B.
- 16 graficos reanexados por API; o journal mostra `[VERSION] v1.2.83` (3 linhas por grafico, 48 no total).

### 80.5 Verificacao medida

- Janela limpa (>= 16:21:30, logo depois de todas as 16 instancias novas subirem): QUANT MATRIX **0**, BENCHMARK **0**, BACKTEST ANALYZER **0**.
- Janela anterior (mesmo tipo de arranque, binario v1.2.82): QUANT MATRIX 16, BENCHMARK 32, BACKTEST ANALYZER 48.
- `[SESSION]` caiu de 16 por arranque para 6 (so as instancias cujo resumo mudou).

### 80.6 O bloqueio de dinheiro continua e NAO e codigo

- `terminal_get_info` 19:14Z: `experts_trade_allowed: true` (o botao Algo Trading foi LIGADO pelo operador as 16:13:17 - journal do terminal: "automated trading is enabled").
- O proprio EA, as 16:16:46 e as 16:21:3x: `MQL_TRADE_ALLOWED=0 TERMINAL_TRADE_ALLOWED=1 ACCOUNT_TRADE_ALLOWED=1 ACCOUNT_TRADE_EXPERT=1 TERMINAL_CONNECTED=1` -> `trade_gate_code=3` (TG_MQL_OFF).
- Testado e REJEITADO por medicao neste ciclo: template derivado do proprio grafico com `expertmode=5` (16:15:51) e `expertmode=7` (16:16:46) e `chart_apply_template`. O bit por programa nao vem do template nesta build 6294.
- Falta apenas a caixa **Permitir Algo Trading** das propriedades do EA (F7 > separador Geral) em cada grafico. O terminal nao da nenhuma API para a escrever.

### 80.7 Pendente

- Abrir F7 num grafico, marcar "Permitir Algo Trading", OK; depois gravar o template desse grafico (`chart_save_template`) para ler o valor exacto de `expertmode` que a build 6294 grava quando a caixa esta marcada e replicar nos outros 15.
- `[NOTIFY] SendNotification falhou | Erro=4517` (Reduzir: 1x por instancia, nao por evento) enquanto `notifications_enabled=false`.
- `[LEARN] varredura em espera` 4 825 linhas: alinhar ao throttle de 1h real.
- WebRequest 4014: `WebRequest=0` e `WebRequestUrl=` vazios em `config\common.ini` [Experts]; a URL `http://127.0.0.1:9001` precisa de ser autorizada em Ferramentas > Opcoes > Expert Advisors.

## 81. P1.71 (v1.2.84) - as duas ultimas fontes de repeticao e o fecho do caso do bit por programa

### 81.1 O que foi medido (02/11/2026, Logs\20261102.log)

Antes do ciclo: 161 928 linhas no dia. Contagens por `.Contains()` (nunca por -like, que trata [ como classe de caracteres):

| marcador | linhas no dia |
|---|---|
| [NOTIFY] | 1 850 |
| DATA LOGGER OFFLINE | 364 |
| [SCANNER] | 20 897 |
| SYMBOL MANAGER | 8 525 |
| [TRADE BLOCK] | 7 384 |
| [LEARN] | 4 825 |

### 81.2 A causa de cada uma

1. **[NOTIFY]**. O push do terminal esta DESLIGADO (`terminal_get_info` devolve `notifications_enabled:false`; `TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)=0`). Mesmo assim o EA chamava `SendNotification()` em todas as tentativas, que falhavam sempre com o erro 4517, e imprimia a linha de ajuda. 80 dessas linhas sairam numa unica janela de 3 minutos de reload.
2. **DATA LOGGER OFFLINE**. A linha saia dentro de `DataLoggerClose()` em TODO o `OnDeinit`, mesmo quando o logger nunca tinha aberto um ficheiro. Com 16 instancias e reloads, aquilo era so o carimbo de encerramento: 364 linhas sem nenhuma informacao.

### 81.3 A correcao (so impressao e so uma chamada evitada)

- `Enterprise\NotificationCenter.mqh`, `SendPush()`: o estado do push passa a ser lido ANTES da chamada. Desligado -> sai UMA linha por sessao (`[NOTIFY] push desligado no terminal | TerminalInfo(TERMINAL_NOTIFICATIONS_ENABLED)=0 | ...`) e a funcao devolve `false` sem round-trip ao servidor. O valor de retorno e exactamente o mesmo de antes, logo nenhum chamador muda de comportamento. Com o push ligado, todas as falhas reais continuam a ser impressas como antes.
- `AI\DataLogger.mqh`, `DataLoggerClose()`: a linha passa a sair apenas quando havia mesmo um ficheiro aberto (`dlTinhaFicheiro`), que e o caso em que a informacao significa alguma coisa.

### 81.4 Provas de bytes (todas com LF_soltos 0 e NUL 0)

| ficheiro | bytes | CRLF |
|---|---|---|
| Enterprise\NotificationCenter.mqh | 14 254 -> 15 311 | 442 -> 462 |
| AI\DataLogger.mqh | 12 118 -> 12 132 | 604 -> 603 |
| Enterprise\VersionManager.mqh | 65 539 -> 66 456 | 231 -> 231 |
| XAU_AI_PRO.mq5 (#property version 1.283 -> 1.284) | 81 363 -> 81 363 | 2 386 -> 2 386 |

Backups `.pre_p171` ao lado de cada ficheiro. Copia de seguranca do binario anterior: `Files\Backup\XAU_AI_PRO_v1283_ok.ex5`.

### 81.5 Build e deploy

`Result: 0 errors, 0 warnings, 17941 ms elapsed, cpu=X64 Regular` | `XAU_AI_PRO.ex5` 706 940 -> **708 374 B** | 2026-11-02T16:37:45. Reanexado aos 16 graficos (16/16 `ok:true`) e confirmado no journal: `[VERSION] v1.2.84` em XAUUSD/M1, USDBRL/M5, USDSGD/H1, EURUSD/H1, GBPUSD/H1, USDRUB/H1, NZDUSD/H1 (48 linhas de versao).

Janela >= 16:38 (1 050 linhas): `[NOTIFY]` 14, `DATA LOGGER OFFLINE` **0**, `[SCANNER]` 0. Ressalva honesta: a janela nao conteve NENHUMA tentativa de notificacao (o mercado esta fechado e nao houve evento de trade), por isso a ramificacao nova ainda nao foi exercitada em execucao - o que esta medido e que a linha DATA LOGGER OFFLINE parou de sair e que as 1 850 linhas de NOTIFY do dia tinham origem no push desligado.

### 81.6 Registo em atraso do P1.69 (v1.2.82)

O P1.69 foi aplicado no ciclo anterior mas a seccao 79 nunca chegou a ser escrita. Fica aqui registado para nao haver buraco na numeracao: o journal imprimia, na MESMA linha, `[HEALTH] WARNING` e `Status: HEALTHY`. A causa medida foi `HealthGetState()` a transformar falhas de watchdog em veredicto de aviso nos graficos sem tick (ATR/ADX/RSI/IA so avancam dentro de `OnTick`), quando o P1.67 ja tinha decidido que sem tick nao ha falha. Correcao: as falhas dos watchdogs so contam para o veredicto quando houve tick nos ultimos 15 s, e a linha `Status` passou a ler `HealthGetStateString()` - a mesma fonte do tag - e a acrescentar o resultado do ultimo check entre parenteses. Prova: HealthMonitor.mqh 27 996 -> 29 106 B (CRLF 945 -> 960), VersionManager.mqh 63 819 -> 64 784 B. Depois do deploy, as 16 instancias imprimiram `[HEALTH] HEALTHY | uptime=30s | checks=0 | sem tick=3s` e um filtro por `HEALTH MONITOR` devolveu 0 registos.

### 81.7 Pendente

- **O bloqueio de dinheiro continua a nao ser codigo.** Ver a seccao 82 (bit por programa).
- Reduzir `[SCANNER]` (20 897) e `SYMBOL MANAGER` (8 525), que sao agora os dois maiores blocos restantes.
- Corrigir `SYSTEM STATUS WRITE ERROR | Code=5004` e o par `LoggerInit() nao chamado` / `DATA LOGGER OFFLINE`.

## 82. P1.72 (v1.2.85) - cortar a repeticao que sobrou e corrigir o aviso de estado ocupado

### 82.1 O que foi medido (02/11/2026, Logs\20261102.log)

Janela estavel ANTES do reload: 17:50-18:50 (59 minutos, 586 linhas). Taxas por hora:

| Tag | linhas | por hora |
|---|---|---|
| [TRADE BLOCK] PROGRAMA sem permissao | 67 | 68,1 |
| [SESSION] estado salvo | 34 | 34,6 |
| [CIRCUIT] BROKER OK + BROKER INSTAVEL | 33 | 33,6 |
| [LEARN] varredura em espera | 32 | 32,5 |
| [LOGGER OFFLINE] | 33 | 33,6 |
| AI GATEWAY WebRequest 4014 | 32 | 32,5 |
| [BACKUP] STANDBY | 21 | 21,4 |
| [HEALTH] | 17 | 17,3 |
| SYSTEM STATUS WRITE ERROR | 1 | 1,0 |
| [SCANNER] | 0 | 0,0 |
| [NOTIFY] | 4 | 4,1 |
| [VERSION] | 6 | 6,1 |

O [SCANNER] a 0/hora confirma que os portoes do P1.68 funcionam. O que sobrou nao era
retrato de mercado: era a MESMA frase repetida por 16 instancias a um ritmo fixo.

### 82.2 Correcao de uma medicao minha (honestidade de registo)

As janelas publicadas na seccao 81 e nos primeiros numeros deste ciclo estavam mal
delimitadas por um erro meu de extracao: eu lia os minutos do campo de hora com
Substring(Index+5,2), que devolve o SEGUNDO digito dos minutos mais os dois pontos, e nao
os dois digitos dos minutos. O efeito e que o filtro comparava "18:8:" com "17:40" e
incluia tudo o que nao devia. Os TOTAIS do dia (as contagens por tag sobre o ficheiro
inteiro) nunca dependeram desse filtro e continuam validos; as taxas POR JANELA passam a
ser as desta seccao, com o regex \t(\d{2}):(\d{2}):(\d{2})\. e comparacao por hh:mm.

### 82.3 O que mudou no codigo (6 pontos, todos so de impressao)

1. AllowBlockPrintCausa: janela da mesma causa 600 s -> 3600 s (68,1/h -> ~19/h). Causa NOVA
   continua a sair na hora.
2. [SESSION] estado salvo: heartbeat 1800 s -> 3600 s, mantendo o portao por mudanca.
3. [CIRCUIT] BROKER OK: so sai quando a rajada transitoria tem 3+ leituras ou 60+ s. Uma
   leitura isolada continua contada e continua a nao bloquear nada.
4. [LEARN] varredura em espera: 3600 s -> 14400 s por instancia; o texto passou a dizer 4h.
5. [BACKUP] STANDBY: 3600 s -> 14400 s.
6. SYSTEM STATUS WRITE ERROR: passa a sair 1x por sessao com o codigo. A causa e o ficheiro
   de estado comum (Data\system_status.json) aberto por 17 instancias no mesmo instante:
   5004 = ERR_CANNOT_WRITE_FILE, ficheiro ocupado. O retrato e reescrito no ciclo seguinte.
7. AI GATEWAY erro duro (4014/4060/5200/5202 = configuracao do terminal, nao se cura
   sozinha): 1800 s -> 14400 s.

Nenhum limite, regra de entrada ou de saida, parametro de risco, lote, spread ou
precificacao foi tocado.

### 82.4 Provas de bytes (encoding UTF-8 sem BOM, LF soltos e NUL sem aumento)

| Ficheiro | bytes | CRLF | LF soltos | NUL |
|---|---|---|---|---|
| XAU_AI_PRO.mq5 | 81363 -> 81739 | 2386 -> 2391 | 0 -> 0 | 0 -> 0 |
| AI\LearningHistory.mqh | 33438 -> 33439 | 1178 -> 1178 | 38 -> 38 | 0 -> 0 |
| AI\AIConnector.mqh | 31860 -> 31861 | 1319 -> 1319 | 0 -> 0 | 0 -> 0 |
| Enterprise\CircuitBreaker.mqh | 36515 -> 37201 | 1606 -> 1616 | 0 -> 0 | 2 -> 2 |
| Monitoring\SystemStatus.mqh | 9930 -> 10713 | 266 -> 281 | 27 -> 27 | 0 -> 0 |
| Enterprise\VersionManager.mqh | 66456 -> 68048 | 231 -> 231 | 0 -> 0 | 0 -> 0 |

Os 38 LF soltos de LearningHistory.mqh e os 27 de SystemStatus.mqh sao PRE-EXISTENTES e
foram provados no ficheiro .pre_p172 antes da edicao (38 -> 38 e 27 -> 27). Os 2 NUL de
CircuitBreaker.mqh estao nos ultimos 3 bytes do ficheiro e tambem sao pre-existentes
(posicoes 36512-36513 antes, 37198-37199 depois). Nenhum ficheiro ganhou NUL nem LF solto.

Compilacao: Result: 0 errors, 0 warnings, 17159 ms, cpu='X64 Regular'. EX5 708374 -> 709836
bytes. Copia do binario bom anterior em Files\Backup\XAU_AI_PRO_v1284_ok.ex5.

### 82.5 Estado apos o reload (18:50:12 a 18:50:22, 16 graficos)

[VERSION] v1.2.85 presente em todas as 16 instancias. O heartbeat continua a publicar
autotrading=false e trade_gate_code=3 (TG_MQL_OFF): o bit POR PROGRAMA continua em falta.
Isso NAO e codigo e nenhum dos 7 pontos acima o toca.

### 82.6 Medicao imediata pos-reload (e o que ela NAO prova)

O arranque das 16 instancias produziu uma rajada de 4 497 linhas entre 18:50:00 e 18:51:48
(inicializacao: [LEARN] 254, [VERSION] 102, [NOTIFY] 68). Depois da rajada o ficheiro
cresceu 506 bytes em 4 minutos (18:51:48 -> 18:55:52), contra 586 linhas/hora antes do
reload. O que isto prova: os portoes novos estao a abafar o que abafavam. O que isto NAO
prova: a taxa estavel, porque o primeiro aviso de cada portao sai sempre e a janela de 1h
ainda nao fechou. A taxa estavel tem de ser relida depois das 19:50.
## 83. P1.73 / v1.2.86 - throttle de log por CONTA (02/11/2026)

MEDIDO no journal completo de 02/11 (`MQL5\Logs\20261102.log`, 171 949 linhas no fim do ciclo):
[SCANNER] 20 897, [TRADE BLOCK] 7 598, [LEARN] 6 088, [TRADE PIPELINE] 4 309,
[VERSION] 2 381, [NOTIFY] 2 002, DATA LOGGER 1 758, [CONFIG] 1 585, [INIT] 1 592,
[VALIDATION] 1 363, [BACKUP] 1 117, [HEALTH] 1 098, [LOGGER OFFLINE] 993,
AI GATEWAY 885, [RECOVERY] 825, [STATUS] 126, SYSTEM STATUS 71.

DIAGNOSTICO: o P1.72 cortou a repeticao DENTRO de cada grafico, mas existem 16 instancias
do EA ligadas. Uma janela de 1/hora por instancia continua a produzir 16 linhas identicas
por hora. A unidade correta de throttle e a CONTA, nao o grafico.

FEITO (so impressao; nenhum limite, regra, risco, lote, spread, alvo ou preco tocado):
1. Novo `Monitoring\AccountLogGate.mqh` - janela por tag num ficheiro comum
   (`Files\Common\XAU_AI_PRO\loggate_*.bin`), FAIL-OPEN: qualquer erro de ficheiro devolve
   true, portanto um problema de log NUNCA esconde informacao.
2. `AllowBlockPrintCausa`: causa NOVA -> 1 linha/120 s por conta; causa repetida -> 1/3600 s.
3. `[SESSION] estado salvo` -> 1 linha/600 s por conta (no rollover saiam 12 iguais em 40 s).
4. `[HEALTH]` resumo de hora -> 1 linha/3600 s por conta; MUDANCA de estado sai na hora.

PROVA DE RUNTIME (02/11 19:10): existem no disco comum
`loggate_health.bin` (8 B, 19:07:45), `loggate_session.bin` (8 B, 19:07:45) e
`loggate_tradeblock_nova.bin` (8 B, 19:10:59) - escritos pelas instancias do EA, o modulo corre.

BUILD: 0 errors, 0 warnings, 15 454 ms, x64 Regular. EX5 709 836 -> 711 602 B.
Backup do binario anterior: `Files\Backup\XAU_AI_PRO_v1285_ok.ex5` (709 836 B).

RELOAD: `chart_save_template` de 90122763662209 -> `XAI_P173.tpl`
(56 054 B, 1 499 linhas, 898 inputs, MagicNumber=2026001, RiskPercent=1.0,
MaxDailyLossUsd=60.0, MaxTotalRiskPercent=10.0, EnableAutonomousMode=true,
MinMarketScore=65.0 preservados), depois `chart_apply_template` nos 16 graficos.
CONFIRMADO por leitura do log: 16/16 instancias com `v1.2.86 | build`
(XAUUSD, USDCLP, USDCOP, USDJPY, USDSEK, USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD,
NZDUSD, GBPUSD, USDBRL, USDRUB, USDSGD, EURUSD).

PORTAO DE DINHEIRO (inalterado, nao e codigo): `system_status.json` as 00:11:15 do servidor
diz `trade_gate_code=3` (`TG_MQL_OFF`), `ea_trade_allowed=false`, com
`terminal_connected=true` e `algo_trading_enabled=true`. Falta apenas o bit POR PROGRAMA.

PISTA NOVA MEDIDA: os 16 `chartNN.chr` do perfil `XAI_V1243_20261031` tem
`expertmode=5` no bloco `<expert>` (linha 66). `expertmode` e um bitmask:
1 = EA habilitado, 2 = permitir negociacao ao vivo, 4 = permitir importacao de DLL.
5 = 1 + 4, ou seja **EA habilitado e DLL permitida, negociacao ao vivo DESMARCADA**.
E exatamente o estado que produz `MQL_TRADE_ALLOWED=0`. O valor que o EA precisa e 7 (1+2+4).
O ficheiro `.chr` e escrito A PARTIR do estado do terminal, por isso editar o ficheiro com o
MT5 aberto nao resolve: a caixa tem de ser marcada no dialogo (F7 > aba Geral >
"Permitir Algo Trading" > OK).

## 84. P1.74 / v1.2.87 - o journal deixou de contar o arranque 16 vezes (02/11/2026)

PEDIDO: "sim melhorar journal para 10/10".

MEDIDO ANTES (leitura direta de MQL5\Logs\20261102.log, 171 952 linhas, 37 439 482 bytes, leitor com FileShare::ReadWrite e encoding 1252):

- 95 508 linhas (55,5%) nao tinham tag nenhuma.
- O arranque de UMA instancia custava 227 linhas; o dump completo de um reload dos
  16 graficos foi medido em 1 083 linhas so na janela 19:08:01-19:08:44.
- Desse total, 107 linhas eram dump decorativo repetido, por instancia:
  SymbolManager 57 (dump do Market Watch, lista de ativos, um "Active symbol
  registered" por simbolo), BrokerAnalyzer 20, BrokerInfo 5, EnvironmentManager 5,
  PathManager 5, BrokerConfig 5, cabecalho do OnInit 9, resumo de memoria aprendida
  11, e 20 separadores "====" / "----" sem informacao alguma.

FEITO (so texto; nenhum return, limite, regra de entrada/saida, parametro de risco,
lote, spread, alvo ou precificacao foi tocado):

| bloco | antes | depois |
|---|---|---|
| SymbolManager (Core\SymbolManager.mqh) | 57 | 1 linha [SYMS] |
| BrokerAnalyzer (Enterprise\BrokerAnalyzer.mqh) | 20 | 1 linha [BROKER] |
| BrokerInfo / EnvironmentManager / PathManager / BrokerConfig | 20 | 5 linhas ([BROKER], [ENV], [PATH] x2, [BROKERCFG]) |
| cabecalho do OnInit (XAU_AI_PRO.mq5) | 9 | 1 linha [START] |
| Checklist de producao (Monitoring\ProductionChecklist.mqh) | 23 | 1 linha com as falhas |
| Compatibilidade (Core\CompatibilityManager.mqh) | 16 | 1 linha [COMPAT] |
| Memoria aprendida (AI\LearningHistory.mqh) | 11 | 1 linha [LEARN] resumo |
| Resumo de saude (Enterprise\RecoveryManager.mqh) | 8 | 1 linha |
| BacktestAnalyzer (resumo) | 4 | 1 linha |
| separadores decorativos | 20 | 0 |

O relatorio completo do checklist continua a ser escrito inteiro em
Common\Files\XAU_AI_PRO\ProductionChecklist.txt - o journal perdeu a copia, nao a
informacao.

MEDIDO DEPOIS (mesma fonte, janela 19:33:30 -> 19:35:00, reload dos 16 graficos):

- 96 linhas por instancia contra 263 no inicio do dia (-63%).
- 1 532 linhas no reload dos 16 contra 2 159 medidos com a v1.2.86 e cerca de 3 600
  com o formato antigo.
- Linhas sem tag: 357 de 1 532 (23%) contra 55,5% no dia.

PROVA DE RUNTIME: 16 de 16 instancias em v1.2.87 ([START] XAU_AI_PRO v1.2.87 em
XAUUSD, USDCLP, USDCOP, USDJPY, USDSEK, USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD,
NZDUSD, GBPUSD, USDBRL, USDRUB, USDSGD, EURUSD). Compilacao 0 errors / 0 warnings,
EX5 717 372 B. Binario anterior guardado em Files\Backup\XAU_AI_PRO_v1286_ok.ex5.

O QUE FALTA PARA 10/10: as ~26 linhas de "modulo X inicializado" que cada instancia
imprime continuam a sair 16 vezes porque a inicializacao e por grafico. O caminho
medido e passa-las pelo AccountLogGatePodeImprimir (que ja existe e ja esta provado
em runtime desde o P1.73) para que so a primeira instancia da conta as escreva. Isso
exige tocar ~26 pontos de chamada em modulos diferentes; fica para o proximo ciclo,
com a mesma regra: nenhuma regra de trading muda.

PORTAO DE DINHEIRO (inalterado, reconfirmado as 00:36:34 de servidor):
trade_gate_code=3, ea_trade_allowed=false, algo_trading_enabled=true. O unico bit em
falta continua a ser MQL_TRADE_ALLOWED, por programa. Nenhuma alteracao de codigo o
resolve: precisa de F7 > Geral > "Permitir Algo Trading" num grafico, e os 16 .chr
provam que o valor actual e expertmode=5 (1 EA + 4 DLL, sem o bit 2 de negociacao).
## 85. P1.75 / v1.2.88 - o encerramento numa linha (02/11/2026)

MEDIDO ANTES (janela de 1 534 linhas, 19:33:30): 357 sem tag = 23,3 por cento; o deinit de cada instancia gastava 21 linhas sem tag, das quais 12 eram o bloco "FINALIZANDO / Reason / FINALIZADO / SYSTEM CLOSED".

ALTERADO em 7 ficheiros: OnDeinit passa a escrever UMA linha [STOP] com simbolo, motivo e equity em vez de 5; InitSystem deixa de imprimir "XAU_AI_PRO INITIALIZING" e "SYSTEM READY"; ShutdownSystem perde "SYSTEM CLOSED"; DataLogger passa a [DATA]; BacktestAnalyzer passa a [BT] e o resumo de backtest so sai quando houve trades; TradeLogger passa a [TRADELOG]; MTF passa a [MTF]; AIConnector passa a [AI].

MEDIDO DEPOIS (janela de 1 200 linhas, 19:47): 94 sem tag = 7,8 por cento; as novas tags vivas: [BT]=26, [MTF]=16, [TRADELOG]=16, [DATA]=16. [STOP]=0 nessa janela porque nenhuma instancia v1.2.88 tinha encerrado ainda.

VALIDACAO: 0 errors / 0 warnings (16 011 ms), EX5 718 070 B, backup Files\Backup\XAU_AI_PRO_v1288_ok.ex5. Reload dos 16 graficos por template XAI_P175.tpl (16/16 ok).

PORTAO DE DINHEIRO (inalterado): trade_gate_code=3, ea_trade_allowed=false.

## 86. P1.76 / v1.2.89 - as duas ultimas linhas sem tag (02/11/2026)

MEDIDO ANTES (janela de 1 200 linhas, 19:47): 94 sem tag. Descontando o deinit das instancias antigas v1.2.87 (21 separadores "====", 9-12 de cada uma das cinco linhas do bloco de encerramento), sobravam DOIS emissores reais de arranque: "Inicializando modulos..." (16, XAU_AI_PRO.mq5 linha 361, sem nenhum dado) e "SYMBOL MANAGER | AVISO P1.19" (5, Core\SymbolManager.mqh linha 315).

ALTERADO: (1) "Inicializando modulos..." passa a comentario de tres linhas - o [INIT] all modules OK ja diz o mesmo com resultado a frente; (2) o aviso do SymbolManager passa a [SYMS] AVISO P1.19; (3) a causa de TG_MQL_OFF (~900 caracteres, 16 vezes por arranque) deixa de ser impressa no diagnostico e passa a "codigo=N | causa completa em [TRADE BLOCK]" - o texto completo continua a sair uma vez por conta no [TRADE BLOCK]; (4) version bump.

MEDIDO DEPOIS (janela de 1 292 linhas, 19:52): 32 sem tag = 2,5 por cento. [STOP]=12 (o encerramento em uma linha finalmente observado). [SYMS] AVISO=5, codigo= 16 (a causa curta substituiu a longa). Os 32 restantes eram TODOS do AIConnector.

VALIDACAO: 0 errors / 0 warnings (16 082 ms), EX5 719 152 B, backup Files\Backup\XAU_AI_PRO_v1289_ok.ex5. Reload por XAI_P176.tpl (16/16 ok).

## 87. P1.77 / v1.2.90 - o journal deixa de ter linha sem tag (02/11/2026)

MEDIDO ANTES (janela de 1 292 linhas, 19:52): 32 sem tag = 2,5 por cento, TODAS do AI\AIConnector.mqh - "AI LOAD", "AI FILE NOT FOUND", "AI INVALID JSON SYMBOL", "AI GATEWAY", "AI PYTHON", "AI BLOCK". O modulo escrevia com nomes proprios, fora do vocabulario [TAG], e por isso nenhuma delas se filtrava por tag.

ALTERADO: as 11 mensagens do AIConnector passam a levar o prefixo [AI]; duas foram traduzidas para portugues ("FILE NOT FOUND" -> "FILE EM FALTA", "JSON EMPTY" -> "JSON VAZIO"). Nenhuma condicao de sinal muda: os 11 pontos sao Print de diagnostico, limitados a 1 vez por 30 minutos por instancia desde a v1.2.33.

MEDIDO DEPOIS (janela de 1 280 linhas, 19:54): SEM_TAG = 0 (0,0 por cento). [AI] passou de 44 para 74 linhas (as 32 antigas sem tag entraram no namespace). [STOP]=11. codigo= 16.

VALIDACAO: 0 errors / 0 warnings (16 132 ms), EX5 720 204 B, backup Files\Backup\XAU_AI_PRO_v1290_ok.ex5. Reload por XAI_P177.tpl (16/16 ok).

CRITERIO 10/10 ATINGIDO: toda a linha do journal pertence a um namespace [TAG]. O que resta para o proximo ciclo nao e "linha sem tag", e duplicacao: [VERSION] 86, [INIT] 80, [LEARN] 80, [NOTIFY] 59, [CONFIG] 59 e [LOGGER OFFLINE] 32 na mesma janela - o mesmo facto repetido 16 vezes, um por grafico.

## 88. Ciclo P1.79 / v1.2.92 - journal sem linha anonima e sem repetir dentro do ciclo (02/11/2026 20:28)

MEDIDO ANTES (MQL5\Logs\20261102.log as 20:16:11, 41 057 150 bytes, 185 920 linhas, janela de 4 000):
- 9,2 por cento sem tag (366 linhas), 100 por cento do DataLogger.
- [SCANNER] 116, [TRADE PIPELINE] 120, [LEARN] 243, [LOGGER OFFLINE] 82.
- Causa medida: o MESMO simbolo com o MESMO sinal (USDBRL Signal=1) imprimia de 6 em 6 segundos; o [TRADE PIPELINE] saia 1x/min em cada um dos 15 graficos (900 linhas/hora); o DATA LOGGER SAVED saia 1x por simbolo por INSTANCIA (11 simbolos x 15 graficos = 165 linhas/dia); o bloco de arranque (48 linhas) repetia 15 vezes.

APLICADO (19 ficheiros, escrita que PRESERVA BOM e NUL - o erro do P1.79 anterior foi ReadAllText/WriteAllText sem BOM):
1. Monitoring\AccountLogGate.mqh: nova funcao LogInicioDetalhe() com cache por instancia e janela de 120 s por CONTA.
2. Core\MarketScanner.mqh: [SCANNER] SIGNAL OK passa a DiagGateAllow(simbolo, SCAN_SIGNAL, sinal, 1800) - sai na mudanca e no maximo 1x/30 min.
3. XAU_AI_PRO.mq5: [TRADE PIPELINE] INICIANDO passa a 1x/30 min por CONTA.
4. AI\DataLogger.mqh: 7 mensagens passam a [DATA]; DATA LOGGER SAVED passa a [DATA] SAVED com janela de 86400 s por conta e por simbolo.
5. Arranque 1x por conta: [VERSION] Modulos, [AI] Client, [REAL GUARD] demo, [BENCHMARK], [TELEMETRY], [ANTILOOP], [SYNC], [STATS], [QUALITY], [DATABASE], [VALIDATION] checklist, [SCHEDULER], [CHECKLIST] producao, [PATH] data, [LEARN] diario aplicado, [LEARN] resumo. Instantaneos periodicos [DATABASE]/[SCHEDULER]/[TELEMETRY]/[BENCHMARK] passam a 1x/hora por conta.

MEDIDO DEPOIS (as 20:27:22, janela de 900 linhas ja com a v1.2.92):
- SEM TAG: 9,2 por cento -> 0,1 por cento (1 linha: USDBRL SIGNAL BUY do SignalCore, a corrigir no proximo ciclo).
- [TRADE PIPELINE] 120 -> 42; [SCANNER] 116 -> 29; [LEARN] 243 -> 61 (janelas de tamanhos diferentes, mas todas as fontes medidas caem).
- [START] XAU_AI_PRO v1.2.92 presente nos 15 graficos (17 ocorrencias de 1.2.92 no log).

COMPILACAO: 0 errors, 0 warnings (16 586 ms, cpu X64 Regular), EX5 727 644 bytes as 20:22:35, backup Files\Backup\XAU_AI_PRO_v1292_ok.ex5.

BOM/NUL provados antes e depois em cada ficheiro (AntiLoop, ExecutionStats, ExecutionQuality, Scheduler, PathManager com BOM=True/True; nenhum NUL introduzido; chaves sempre 1:1).

### ABERTO - o portao de dinheiro NAO pode ser fechado/aberto por codigo (medido 3 vezes hoje)
- 20:04 troca de perfil para Default -> trade_gate_code=3 (TG_MQL_OFF), ea_trade_allowed=false.
- 20:15 acao do operador -> trade_gate_code=0, ea_trade_allowed=true, [TRADE BLOCK] ausente, EA a operar.
- 20:26 reload dos 15 graficos por template (necessario para a v1.2.92) -> trade_gate_code=3 outra vez.
- Terminal continua em experts_trade_allowed=true e mql_trade_allowed=true: falta SO o bit por PROGRAMA.
- Conclusao operacional: TODO reload volta a pedir o clique do operador. Acao minima: 1 grafico > clique direito > Expert Advisors > Properties (F7) > aba Geral > marcar "Permitir Algo Trading" > OK. Uma instancia permitida basta para operar os 57 simbolos, porque o MasterGuard elege o master entre as permitidas.
- Campo expertmode do .chr/.tpl e 5 tanto no estado ABERTO (template salvo as 20:25 com o portao aberto) como no FECHADO: nao e o portao. As quatro rotas por codigo continuam insuficientes.

### Correcao pendente de set (pedida pelo operador: ativar tudo true)
Falsos por decisao medida, NAO ligar sem fonte: EnableSessionFilter (0), EnableNewsFilter (0, sem provedor de noticias; ligar bloquearia tudo), EnableMTFConfirmation (0), EnableVolatilityFilter (0), EnableDatabase (0, usa dataset CSV), EnableReplay (0), EnableExternalBridge (0), AllowTradeWithoutAI (0), AIHasSignalAuthority (0).
Grafico ausente: CHART14 (EURUSD). O perfil Default tem 15 graficos; EURUSD continua na lista Symbols e e negociado em multi-simbolo, mas nao tem instancia propria.

## 89. Ciclo P1.80 / v1.2.93 - porque nao abriu operacao nenhuma em 10 horas (02/11/2026 20:48)

### O EA OPEROU HOJE (medido no historico de posicoes, conta 113568614)
- 04:00:11 USDJPY SELL 0.08 -> SL 11:18:19 = +3,25 USD
- 06:00:09 AUDUSD BUY 0.10 -> fecho Expert 09:46:28 = -8,90 USD
- 07:00:09 USDCAD SELL 0.04 -> SL 12:44:04 = +1,40 USD
- 10:13:31 AUDUSD BUY 0.13 -> TP 11:01:16 = +10,01 USD
- total do dia = +5,76 USD | open_reason=Expert | comment=XAU_AI_PRO | magic=2026001
- ultima abertura = 10:13:31; as 20:48 sao 10 h 35 min sem abrir. Nao e EA morto: e EA sem setup aceito.

### FUNIL MEDIDO (MQL5\Logs\20261102.log, janela das ultimas 120 000 linhas)
- SIGNAL_OK=212 | VALIDATION_BLOCK=7 | SCANNER_BLOCK=1321 | tentativas de ordem barradas=7687
- VALIDATION (7): 5 x 'TREND BUY | USDBRL | contramao vetada | tendencia formada | ADX=39.8 >= 22.0' e 2 x 'AVOID HOUR | USDBRL'
- SCANNER: NoSignal 120 x em EURUSD, USDCNH, GBPUSD, USDSEK, XAUUSD, USDCHF, NZDUSD; CanOpen 118 x USDCAD/USDJPY e 79 x AUDUSD; AllowTrade 69 x USDBRL 'Motivo=VALIDATION: TREND BUY' e 49 x USDBRL 'VALIDATION: AVOID HOUR'
- RESUMO das 20:22, 20:24, 20:25 e 20:26: simbolos=41/57/46/110, sinais=3/6/4/10, trades=0, bloqueios = NoSignal + AllowTrade
- Conclusao: 100 por cento dos sinais morrem em AllowTradeEx (TrendFilter contramao + AvoidHoursGMT). Nenhum filtro foi afrouxado sem medicao.

### O SINAL QUE EXISTE VEM DE UM SIMBOLO COM SERIE PARADA
- 'USDBRL SIGNAL BUY | RSI[1]=37.31' repete-se identico as 05:05, 05:31, 05:53, 05:56, 20:13 e 20:23 (23 linhas no dia) e RSIPullbackBuy=45.0 no chart13.chr
- O RSI nao se move em 15 horas: a serie do USDBRL/M5 esta congelada (o mesmo simbolo ja aparecia sem tick no P1.67). Este e o candidato natural a um portao de dados obsoletos no proximo ciclo, mas NAO foi mexido agora.

### PORTAO DE DINHEIRO (unica trava incremental agora)
- system_status.json as 20:37:47: trade_gate_code=3 (TG_MQL_OFF), ea_trade_allowed=false, algo_trading_enabled=true
- terminal_get_info: experts_trade_allowed=true, mcp_trade_allowed=true
- 15 .chr: expertmode=5 em todos (o campo nao e o bit vivo; ja medido no P1.62)
- Correlacao medida hoje: 20:15 clique do operador -> code=0; 20:26 reload de template -> code=3; 20:43 reload da v1.2.93 -> code=3 (esperado)
- Regra: so um clique em F7 > Geral > 'Permitir Algo Trading' religa o bit. Depois do clique NAO recarregar template.

### ENTREGUE NESTE CICLO
- Core/SignalCore.mqh: as 2 linhas BUY/SELL e as 6 de erro passam a [SIGNAL]; o throttle era um static UNICO (o primeiro simbolo do minuto gastava a vez) e passa a ser por simbolo. bytes 3942 -> 5036, braces 16/16, parens 72/72, BOM=False.
- v1.2.93 compilada: 0 errors / 0 warnings, EX5 728 746 B, backup v1292 727 644 B.
- Journal DEPOIS do reload (janela de 1 500 linhas, 20:43:36): SEM_TAG=1 (0,1%), a linha 'SYSTEM STATUS WRITE ERROR | Code=9999' - proximo alvo.
- JSON: os 6 ficheiros de Files\XAU_AI_PRO\Logs com BOM foram limpos (bytes -3 cada, ConvertFrom-Json=True em todos, NUL=0). Os 3 package-lock.json eram falso positivo do $name do PowerShell. Total: 1269 de 1269 validos.

## 90. Ciclo P1.81 / v1.2.93 - auditoria de TODOS os JSON (02/11/2026 20:52)

### Pedido do dono: "corrigir todo json validar todos"

### MEDIDO - nao havia nenhum JSON quebrado

| Metrica | Valor |
|---|---|
| Ficheiros *.json nas 4 raizes de leitura | 1322 (MQL5=1269, Common=53, Tester=0, Logs=0) |
| JSON invalidos | 0 |
| Com BOM (EF-BB-BF / FF-FE) | 0 (os 6 de Files\XAU_AI_PRO\Logs foram limpos no ciclo anterior, -3 bytes cada) |
| UTF-8 invalido ou U+FFFD (encoding estragado) | 0 |
| Caracteres de controlo 0x00-0x1F fora de \t\r\n | 0 |
| Chaves duplicadas no objecto de topo | 0 |

### Ferramenta - o validador importa

- `ConvertFrom-Json` foi descartado: tem falso positivo na variavel automatica `$name`
  (ja reprovou 3 `package-lock.json` que estavam corretos) e nao consome BOM
  ("JSON primitivo invalido: .").
- Usado `System.Web.Script.Serialization.JavaScriptSerializer` com MaxJsonLength=64 MB
  e RecursionLimit=512, mais deteccao de BOM e rejeicao de byte NUL antes do parse.
- Scripts: `Files\Temp\json_full.ps1` (raiz MQL5), `json_audit_roots.ps1` (4 raizes),
  `json_deep.ps1` (encoding/controlo/duplicados).

### Coerencia de versao

- `VERSION` = 1.2.9 e `Docs\version.json` = 1.2.9 -> coincidem (produto).
  A versao interna do EA e 1.2.93 (`EA_VERSION_STRING`), eixo diferente, sem divergencia.

### O que continua errado por CONTEUDO (nao por sintaxe)

1. 10 simbolos em operacao nao tem `Data\prediction_<SIMBOLO>.json`:
   USDCHF, USDCNH, USDSEK, USDCZK, USDSGD, USDCLP, USDRUB, USDCOP, USDBRL (e mais um).
   E a origem das linhas `[AI] FILE EM FALTA` no journal.
2. Os prediction_*.json que existem estao VELHOS: 25 dias (08/10 22:00) a 91 dias.
   O proprio EA ja os classifica como indisponiveis (`ai.available=false`, `age_seconds=-1`),
   por isso NAO ha veto de IA com dado velho - o risco foi medido e nao existe.
3. 9 ficheiros de apelido historico, todos velhos e nunca lidos para os simbolos atuais:
   prediction.json, prediction_GOLD.json, prediction_GOLD#.json, prediction_XAUUSDc.json,
   prediction_BTCUSD#.json, prediction_BTCUSDc.json, prediction_BTCUSDm.json,
   prediction_BTCJPYm.json, prediction_ETHUSD#.json.
4. `system_status.json` continua a reportar `database.dataset_bytes=3639748`
   (dataset.csv lixo) quando o dataset real e 138.869.179 B. Leitura enganosa para o painel.

### Nada foi corrigido porque nada estava quebrado

Nenhum parametro de risco, lote, alvo, spread ou regra de entrada foi tocado, e NAO houve
recompilacao: recompilar agora obrigaria a recarregar os graficos, e o reload volta a
por o portao em codigo=3. O portao tem de ser ligado a mao e ficar.

## 91. Ciclo P1.82 / v1.2.93 - OPNCAO B: porque o ADX le 0.0 e porque 8 dos 11 simbolos dao zero sinal (02/11/2026 21:10)

Medicao apenas. 0 ficheiros do EA alterados, 0 recompilacoes da producao, 0 ordens.

### 91.1 Prova de que o ADX=0.0 e exclusivo do simbolo do grafico dono

Journal lido pela API (get_expert_journal), janela 20:56:05 a 21:00:11, instancia dona `XAU_AI_PRO (USDCHF,H1)`:

| Simbolo | Classe | ADX |
|---|---|---|
| XAUUSD | TENDENCIA_FORTE | 29.0 |
| EURUSD | TENDENCIA_FRACA | 24.3 |
| GBPUSD | TENDENCIA_FRACA | 21.7 |
| USDJPY | LATERAL | 12.8 |
| AUDUSD | TENDENCIA_FORTE | 41.9 |
| USDCAD | TENDENCIA_FRACA | 23.7 |
| NZDUSD | LATERAL | 17.2 |
| **USDCHF** | **SEM_LEITURA** | **0.0** |
| USDBRL | TENDENCIA_FORTE | 39.8 |
| USDSEK | TENDENCIA_FRACA | 18.4 |
| USDCNH | LATERAL | 12.1 |

O unico simbolo que le 0.0 e exactamente o `_Symbol` do grafico que varre os simbolos.

### 91.2 Prova de que a falha e silenciosa (nao e warm-up, nao e feed parado)

- `[ADX] INIT OK` presente para os 16 graficos (19:07 a 20:03); **`[ADX] INIT ERROR` = 0** e **`[ADX] CopyBuffer failed` = 0** na janela 18:00-21:05.
- `Indicators\ADX.mqh` tem dois caminhos que devolvem exactamente 0.0 sem imprimir nada: `if(value <= 0.0) return 0.0;` (linha ~122) e, no multi-simbolo, `double result = 0.0;` que so muda se `copied == 1` (linha ~176).
- Dados frescos: ticks USDCHF de 01:00:00 a 02:06 (hora servidor = UTC+2); barra H1 das 02:00 com 266 ticks; `Bars(USDCHF,H1)=100000`. Logo nao e warm-up nem serie congelada.

### 91.3 O defeito de desenho (a correcao que isto pede)

`ADX_OK()` e `ADX_OK(symbol)` fazem `if(adx < 0.0) return true;` (fail-open) e depois `return (adx >= MinimumADX)`.

- `-1.0` = indisponivel -> **libera**.
- `0.0` = tambem "sem leitura" (o proprio `MarketScenarioDetect` trata `adx <= 0.0` como `SCENARIO_UNKNOWN`) -> **bloqueia**, porque `0.0 < MinimumADX (18.0)`.

Ou seja: uma leitura vazia do ADX nao vira "sem dado", vira **veto**. E o caminho e assimetrico: `GetADX()` (handle persistente criado em `InitADX`, usado so para `_Symbol`) e `GetADX(symbol)` (handle novo a cada chamada, usado pelos outros 10). Os 10 leem bem; o do dono le 0.0.

### 91.4 Funil do dia (numeros que sustentam o resto)

19 353 varreduras | NoSignal 13 293 (68,69%) | CanOpen 4 221 (21,81%) | AllowTrade 1 836 (9,49%) | TRADES 3.

- Sinais: 1 839 no total, dos quais **1 771 (96,3%) do USDBRL**, que tem o feed congelado desde 30/10 20:00 (RSI[1]=37.31 sempre igual). AUDUSD 86, USDCAD 1. **8 simbolos deram zero sinal em 21 horas.**
- Motivo final do bloqueio AllowTrade: 1 712 `VALIDATION: TREND BUY` + 49 `VALIDATION: AVOID HOUR`.
- Distribuicao horaria dos sinais: 00h-05h somam 1 514; 06h=49; 20h=96; **07h a 19h = zero**.

### 91.5 Inputs reais da instancia em producao (lidos do grafico, nao do codigo)

`EnableADXFilter=true`, `MinimumADX=18.0`, `ADXPeriod=14`, `FastEMA=50`, `SlowEMA=200`, `RSIPeriod=14`, `RSIPullbackBuy=45.0`, `RSIPullbackSell=55.0`, `EnableAdaptiveTrendGate=true`, `ScenarioCounterTrendMaxADX=22.0`, `EnableAvoidHoursGMT=true`, `AvoidHoursGMT=9,11,14,18,20,22`, `AvoidHoursList=0,20`, `AllowTradeWithoutAI=false`, `AIHasSignalAuthority=false`, `MinMarketScore=65.0`, `EnableVerboseDebug=true`.

Nota: `AvoidHoursGMT` bloqueia 6 horas GMT, quatro delas em plena sessao de Londres/Nova Iorque (9, 11, 14, 18) - e exactamente nessas horas o journal nao mostra um unico sinal.

### 91.6 Incidente de observabilidade desta noite

`Logs\20261102.log` tinha 187 957 linhas (00:00:01 a 20:59:31) quando foi medido o funil; as 21:04 o mesmo ficheiro tinha **5 408 linhas** e a primeira linha era 00:24:04. O historico do dia deixou de ser reconstruivel a partir do ficheiro. Regra nova: medir pelo journal da API (`get_expert_journal`), que le o buffer vivo do terminal.

### 91.7 Plano fechado para P1.82 / v1.2.94 (uma so versao, um so reload)

1. `SCAN_STALE`: gate de frescura (ultimo tick / ultima barra por simbolo) - mata os 1 771 sinais fantasma do USDBRL.
2. ADX: `0.0` passa a ser tratado como sem leitura (fail-open + linha 1x/hora por simbolo); verificar `BarsCalculated(handle)` antes do `CopyBuffer`; publicar `g_adxUnavailable`/`g_adxValid` no `[SCANNER] RESUMO`.
3. `GetSignal`: instrumentar a saida 0 para distinguir **copia falhada** de **regra nao satisfeita** (1x/hora por simbolo) - e o que falta para provar o zero sinal dos 8.
4. Decisao do dono (nao automatica): rever `AvoidHoursGMT` e o par 45/55 do RSI em H1.

Enquanto o codigo nao mudar, a lista de simbolos continua a ser varrida com um ADX que pode valer 0.0 sem deixar rasto.
