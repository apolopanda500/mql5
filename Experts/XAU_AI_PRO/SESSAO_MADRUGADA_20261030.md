# SESSÃO MADRUGADA — 29/10/2026 22:59 → 30/10/2026 05:21 (local UTC−3)

Registo completo da sessão de trabalho no EA **XAU_AI_PRO** (conta demo 113568614,
MetaQuotes-Demo, hedging, build 6292 x64, magic 2026001).

Documento gerado a pedido do dono: **"salvar tudo conversas"**.
Contém os pedidos, o diagnóstico, as decisões, os patches, os números medidos e
o que ficou pendente.

---

## 1. Pedidos do dono (ordem cronológica)

1. "faca o seu melhor deixar nosso EA muito bom operar bastante durante esta madrugada"
2. (anteriores, já em curso) corrigir tudo mas **manter sempre sair no lucro**;
   EA autónomo; treinar do jeito combinado; ensinar a operar notícias;
   sem lote fixo; entrar sem stop e só depois pôr stop na entrada ou acima;
   meta 10–20 USD/dia com banca ≤ 200; 50 posições e 100 trades/dia; risco 5–10%;
   aprender com operações manuais; journal com 0 erros.
3. "salvar tudo conversas" (este documento).

Regras que **nunca** podem ser violadas:
- o stop só sobe para a **entrada ou acima** dela, nunca abaixo;
- a saída no lucro é obrigatória (escada em dólares é a dona de SL/TP);
- o EA tem de operar sozinho (pausas expiram sem intervenção).

---

## 2. Diagnóstico da madrugada

### 2.1 Bloqueio global: SAFE_MODE persistido do Circuit Breaker
Journal, 22:29:33 → 22:31:46, em todos os 16 gráficos:

```
[TRADE BLOCK] CIRCUIT BREAKER | State=SAFE_MODE | Reason=Broker connection or trading disabled
[TRADE BLOCK] CIRCUIT BREAKER | State=SAFE_MODE | Reason=restaurado apos reinicio
```

- Causa: `CheckBrokerError()` lia `TERMINAL_CONNECTED` / `ACCOUNT_TRADE_ALLOWED`
  num instante de reconexão e o SAFE_MODE era **persistido em GlobalVariable**
  (`XAI_PRO_CB_SAFE_UNTIL`), sobrevivendo ao reload.
- Estado final: **resolvido**. No reload das 23:01 o estado foi descartado
  (broker ligado e liberado) e às 23:06–23:14 já não havia nenhum `[TRADE BLOCK]`.
- A árvore já continha a correção de histerese (`CircuitBrokerFailMinCheck=3`,
  `CircuitBrokerFailMinSeconds=15`, `CircuitWarmupSeconds=30`) e v1.2.24 no
  `Enterprise/CircuitBreaker.mqh`, proveniente do outro processo que edita o repo.

### 2.2 A perda que apagava o dia
Histórico real (29/10):

| Hora | Símbolo | Lote | Entrada | Fecho | Motivo | Resultado |
|---|---|---|---|---|---|---|
| 20:31:00 | NZDUSD SELL | 0.41 | 0.56288 | 0.56283 | Take profit | **+2.05** |
| 20:31:06 | USDBRL SELL | 0.01 | 5.4573 | 5.4603 | Expert | −0.55 |
| 20:33:02 | USDCHF SELL | 0.34 | 0.82626 | 0.82631 | Stop loss | −2.06 |
| 20:33:13 | GBPUSD BUY | 0.41 | 1.33642 | 1.33637 | Stop loss | −2.05 |
| 20:33:31 | USDCAD SELL | 0.56 | 1.39809 | 1.39813 | Stop loss | −1.60 |
| 20:34:16 | USDSEK SELL | 0.06 | 9.86051 | 9.86293 | Expert | −1.46 |
| 20:34:29 | USDCNH SELL | 0.04 | 6.65671 | 6.65623 | Expert | +0.28 |
| 20:35:01 | NZDUSD SELL | 0.01 | 0.56264 | 0.56298 | Expert | −0.34 |
| **21:45:06** | **NZDUSD SELL** | **0.60** | **0.56319** | **0.56354** | **Expert** | **−20.92** |

**Causa-raiz medida:** o lote é dimensionado com `StopLossPoints = 300`, mas a
`MoneyLadder` arma o stop a **1R ≈ 5 pontos** na NZDUSD. O risco efetivo ficou
~6× acima do planejado: 0,60 lote × 3,5 pips = 20,92 USD — exatamente o tamanho
da meta diária, perdido num único trade.

Operações **manuais** do dono no mesmo dia (XAUUSD, 20:16–20:26): +1,10 / +5,20 /
+13,10 / +1,82 — base do aprendizado por histórico já ativo no EA.

### 2.3 Journal afogado
- `DATA LOGGER SAVED` dispara por símbolo e por vela fechada; com 17 gráficos e
  11 símbolos gerava centenas de linhas no fecho de cada H1 (observado ~200
  registos em 4 s às 22:00).
- `ForwardHeartbeatSec = 1` → um heartbeat por segundo **por gráfico**.
- `EXECUTION SUMMARY` a cada 30 s por gráfico.

Efeito prático: os avisos e erros reais saíam da janela visível do journal.

### 2.4 Horas: a madrugada NÃO estava bloqueada
- `AvoidHoursList = "0,20"` (hora de servidor) e `EnableAvoidHoursGMT = true`
  com `AvoidHoursGMT = "18,22"` (**GMT**).
- `TradeStartHour = 0`, `TradeEndHour = 24`.
- Relação medida neste broker: **servidor = local + 5h**, logo madrugada local
  23h–07h = **GMT 02–10**, fora do veto `{18, 22}`.
- `EnableSessionFilter = false` nos gráficos.
→ Nenhuma alteração necessária para operar de madrugada.

---

## 3. Alterações feitas — v1.2.26

Compilado com **0 errors, 0 warnings** (13950 ms, cpu='X64 Regular').

### 3.1 `Core/Config.mqh`
- Novo input:
  ```mql5
  input double MaxRiskPerTradeUsd = 8.0;   // perda maxima REAL por operacao (0 = desliga)
  ```
- Novo helper `NoiseDistancePointsForRisk(string symbol)`: devolve em **pontos**
  a distância que o preço tem de andar para armar o stop na entrada (1R),
  usando a **mesma regra** da `MoneyLadder`:
  `max(ATR × StoplessArmATRMult, StoplessArmMinPoints × point, stops_level × point, 2 × spread)`.

### 3.2 `Core/ExecutionEngine.mqh` — `CalculateDynamicLot()`
- Depois de todo o escalonamento (convicção, cenário, sessão, aprendizagem) e
  antes do arredondamento por `SYMBOL_VOLUME_STEP`, o lote é **capado pelo risco
  real**:
  ```mql5
  if(MaxRiskPerTradeUsd > 0.0)
  {
     double oneRPoints = NoiseDistancePointsForRisk(symbol);
     if(oneRPoints > 0.0)
     {
        double perLotReal = RiscoEmDinheiroDaOrdem(symbol, 1.0, oneRPoints);
        if(perLotReal > 0.0)
        {
           double capReal = MaxRiskPerTradeUsd / perLotReal;
           if(lot > capReal)
           {
              PrintFormat("LOT CAP REAL | %s | 1R=%.0f pts | ...", ...);
              lot = capReal;
           }
        }
     }
  }
  ```
- Efeito no caso medido: NZDUSD passaria de 0,60 → ~0,16 lote (−20,92 → ~−5,6 USD).

### 3.3 `AI/DataLogger.mqh`
- `Print("DATA LOGGER SAVED | ...")` passou a ser condicional a
  `EnableVerboseDebug`. A gravação no CSV **não** mudou.

### 3.4 `Monitoring/ForwardTestRunner.mqh`
- `ForwardHeartbeatSec`: `1` → `300`.

### 3.5 `Enterprise/VersionManager.mqh`
- `EA_VERSION_STRING`: `"1.2.25"` → `"1.2.26"`.

---

## 4. Validação em conta demo

- 17 gráficos recarregados com o `.ex5` novo: `XAU_AI_PRO v1.2.26` +
  `[VERSION] v1.2.26 | Build=2026.10.30` em todos.
- `[INIT] all modules OK` (system, signalcore, ADX, RSI, trend, MTF, symbol
  manager, execution engine) — sem `INIT_FAILED`.
- Health monitor: **Broker/AI/Dataset/File/JSON/Python/Indicator errors = 0**.
- `[TRADE BLOCK]`: **0 registos** entre 23:06 e 23:14.
- Conta: saldo 12 348,57 USD, equity 12 348,57, livre 12 348,57, **flat**
  (0 posições, 0 ordens) no momento do reload.

---

## 5. Histórico de versões e backtests desta linha de trabalho

Período fixo em todos os runs: **XAUUSD M15, 2026.10.20 → 2026.10.29**,
depósito 200 USD, leverage 1:100, modelo *m1 ohlc*, sem otimização
(`MQL5\Profiles\Tester\xai_v129_short.ini` + `xai_v129_short.set`).

| Versão | Mudança | Lucro | PF | Trades | Wins/Losses | Máx perdas seguidas | DD |
|---|---|---|---|---|---|---|---|
| 1.2.16 | base | −4,63 | 0,9315 | 23 | — | 12 | 24,72% |
| 1.2.20 | freio de sequência (3 perdas → pausa 240 min) | **+21,23** | 1,4404 | 16 | — | 6 | 16,31% |
| 1.2.21 | envelope de risco pela distância de armadura | −13,40 | — | 16 | — | — | — |
| 1.2.22 | piso conservador `max(armadura, StopLossPoints)` | −14,78 | 0,4313 | 16 | 4/12 | 10 | 13,00% |
| 1.2.23 | armadura **1R** na MoneyLadder | **+14,76** | **2,1742** | **41** | **29/12** | **2** | 2,33% |

Notas:
- v1.2.23: 82 deals, DD equity 7,88%, Sharpe 3,6981, recovery 0,90,
  expected payoff 0,36. Triplicou os trades mantendo 70,7% de acerto.
- v1.2.20 tem **mais lucro absoluto** (+21,23 vs +14,76), mas v1.2.23 tem
  **PF 2,17 vs 1,44**, `max_con_loss` 2 vs 6 e DD 2,33% vs 16,31% → mais estável
  e opera muito mais, que era o objetivo da madrugada.
- Regressão documentada: contar o envelope só pela armadura (v1.2.21) liberou
  demasiadas entradas simultâneas e virou o resultado negativo.
- Reprodutibilidade confirmada: dois runs independentes do mesmo `.ex5`
  deram exatamente os mesmos 23 trades / −4,63 USD.

---

## 6. Comandos usados nesta sessão (para reproduzir)

```bat
:: procurar símbolos no código
cd /d "...\MQL5\Experts\XAU_AI_PRO" & findstr /S /I /N /C:"AvoidHours" *.mq5 *.mqh

:: aplicar patch (script gerado em MQL5\Files\Temp)
cd /d "...\MQL5\Files\Temp" & powershell -NoProfile -ExecutionPolicy Bypass -File apply_v1226.ps1

:: compilar
start "" /wait "C:\Program Files\MetaTrader 5\MetaEditor64.exe" ^
  /compile:"...\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5" ^
  /inc:"...\MQL5" ^
  /log:"...\MQL5\Files\Temp\compile_v1226.log"
```

Leitura do log do MetaEditor (UTF‑16LE) via PowerShell:
`[IO.File]::Open($f,'Open','Read','ReadWrite')` + `New-Object IO.StreamReader($fs,[Text.Encoding]::Unicode)`.

---

## 7. Pendente / próximo passo

1. **Backtest de 3 meses** com a v1.2.26:
   `MQL5\Profiles\Tester\xai_xau_m15_fast.ini` (2026.07.29 → 2026.10.29,
   200 USD, 1:100) e reportar PF, acerto, nº trades, DD e lucro.
2. Depois: **"every tick based on real ticks"** antes de qualquer conta real.
3. Confirmar em journal o novo log `LOT CAP REAL | <símbolo> | 1R=… pts`.
4. Igualar os parâmetros do NZDUSD aos restantes gráficos (foi reanexado por
   último com conjunto reduzido: `AutoTrade, MagicNumber, MaxTradesPerDay=100,
   MaxOpenPositions=50, MaxRiskPerTradeUsd=8.0, EnableMoneyLadder=true`).
5. **Latch por vela** no pipeline: o mesmo candle re-dispara `RunTradePipeline()`
   (já existe throttle de 60 s); numa sessão anterior isso gerou 1,4 GB de log
   com `EXECUTION: BLOQUEADA | <sym> | envelope de risco aberto cheio` repetido
   no mesmo timestamp.
6. Avisos de lote mínimo forçado em conta pequena:
   `EXECUTION WARNING | FORCA LOTE MINIMO | Lot=0.000 | Min=0.010`.
7. Envelope de risco: `MaxTotalRiskPercent = 10.0` sobre 12 348 USD = 1 234 USD —
   muito acima da meta diária de 10–20 USD. Rever o teto.
8. `DailyProfitTargetMaxUsd = 100` domina na conta atual
   (`max(20, 12 348 × 10%)` limitado a 100).
9. Testar `xai_streak2.set` (`StreakBrakeLosses=2`, `StreakBrakePauseMinutes=360`),
   já preparado mas nunca corrido.
10. Confirmar no journal `[LEARN] OPERACAO MANUAL APRENDIDA | <symbol> | deal=<n> | profit=<x>`.

---

## 8. Avisos honestos

- O teto `MaxRiskPerTradeUsd = 8.0` é uma **perda máxima**, não um alvo.
- Nenhum destes resultados garante lucro futuro; um backtest não é prova de
  rentabilidade. A validação tem de continuar em demo e depois em *real ticks*.
- O EA opera com stop posto **depois** de ficar verde (entrada sem stop, por
  decisão explícita do dono). Isso aumenta o risco de gap antes da armadura —
  mitigado pelo teto de lote em dólares introduzido nesta sessão.
