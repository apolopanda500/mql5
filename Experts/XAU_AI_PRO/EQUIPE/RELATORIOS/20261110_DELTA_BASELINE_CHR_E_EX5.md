# RELATORIO DELTA - baseline da config viva (.chr) e auditoria do .ex5

> DELTA, 10/11/2026 09:15. Pedido do CMD (item 3) + auditoria do artefacto + correccao do P1.3529.

## D-156 | DELTA | 2026-11-10 09:15 | baseline da config viva nos .chr (item 3 do CMD) gravado + auditoria do .ex5 + correccao do P1.3529

- **Estado:** FECHADO na parte que me cabe (item 3 do CMD). Os itens 2 e 3 abaixo sao achados que mudam o que se pode declarar.
- **Pedido do CMD (fecho de 10/11):** item 3 da lista - "Gravar config viva nos .chr + mtime (DELTA)".
- **Binario antes e depois desta medicao:** 977 654 B, mtime 2026-11-10T02:23:07, MD5 `71ED34C690C9593D209A69E95F0EFFB6`. Nada compilado, nada deployado, nenhum input alterado, nenhuma ordem, nenhum reinicio.

### 1. Item 3 - o baseline esta' medido e e' reescrevivel por qualquer attach

**Local:** `MQL5\Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071\chart01.chr` ... `chart15.chr` (o perfil vive em `MQL5\Profiles\Charts`, **nao** em `Experts\XAU_AI_PRO\Profiles` - a primeira tentativa de leitura falhou por isso).

**mtime: os 15 ficheiros exactamente iguais - 2026-11-10T02:35:23.** E' o instante do deploy; o binario e' de 02:23:07, ou seja, 12 minutos entre compilar e gravar a config viva. A vaga `[START]` do G4 foi as 02:35:37, 14 s depois da gravacao.

**O bloco que conta e' `<inputs>` ... `</inputs>`** (no `chart01.chr`: L68 a L393). Extraido e hasheado em cada um dos 15:

| Metrica | Valor | 15/15 iguais |
|---|---|---|
| linhas no bloco `<inputs>` | 324 | sim |
| bytes do bloco | 7 729 | sim |
| MD5 do bloco | `C7C2ED41AF896B8BF851026E62E3D223` | sim |
| `name=` do expert | `XAU_AI_PRO` | sim |

**Nao ha uma unica divergencia de input entre os 15 graficos.** Isto vale como referencia congelada - e como alarme: basta um attach para reescrever o `.chr` e mudar o mtime; o MD5 do bloco muda se qualquer input mudar.

**Inputs criticos lidos (identicos nos 15):**

| Input | Valor |
|---|---|
| `MagicNumber` | 2026001 |
| `Symbols` | XAUUSD,USDCLP,USDCOP,USDCZK,USDRUB,USDSGD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH (15) |
| `SymbolsFromMarketWatch` | false |
| `RiskPercent` | 0.5 |
| `MaxRiskPerTradeUsd` | 8.0 |
| `MaxRiskPerTradePercentCap` | 3.0 |
| `MaxTradeRiskPctOfBudget` | 100.0 |
| `MaxDailyLossPercent` | 3.0 |
| `MaxDailyLossUsd` | 600.0 |
| `MaxDrawdownPercent` | 6.0 |
| `MaxExposurePercent` | 20.0 |
| `MaxCorrelatedTrades` | 3 |
| `MaxTradesPerDay` | 100 |
| `MinAIConfidence` | 60.0 |
| `AllowTradeWithoutAI` | true |
| `AIHasSignalAuthority` | true |
| `MinMarketScore` / `MinMarketScoreNoAI` | 65.0 / 45.0 |
| `MinimumADX` | 18.0 |
| `AvoidHoursGMT` | 9,11,14,18,20,22 |
| `EnableStaleDataGuard` / `MaxSymbolTickAgeSec` | true / 900 |
| `EnableStoplessEntry` / `EnableAutonomousMode` | true / true |
| `DailyProfitTargetUsd` / `...BalancePct` / `...MaxUsd` | 20.0 / 10.0 / 40.0 |

### 2. Auditoria do `.ex5` - a linha "929 558 B (P1.132), intacto" nao descreve nenhum ficheiro vivo

Varri todos os `.ex5` sob `MQL5` (recursivo). Resultado:

| Ficheiro | Bytes | mtime | MD5 |
|---|---|---|---|
| `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` (**vivo**) | 977 654 | 2026-11-10T02:23:07 | `71ED34C690C9593D209A69E95F0EFFB6` |
| `Experts\XAU_AI_PRO\DiagGateSelfTest.ex5` | 18 634 | 2026-11-04T23:43:54 | `5020B8C7DB2BEEF782F805A80A71D79B` |
| `Files\Backup\ex5\XAU_AI_PRO_1.2.167_20261105_231218.ex5` | **929 558** | 2026-11-05T23:12:18 | - |
| `Files\Backup\ex5\XAU_AI_PRO_v1.367_20261105_231218_87E30E2B.ex5` | **929 558** | 2026-11-05T23:12:18 | - |
| `Files\Backup\XAU_AI_PRO_v12191hotfix_71ED34C6.ex5` | 977 654 | 2026-11-10T02:23:07 | (copia do vivo) |
| `Files\XAU_AI_PRO\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` (**repo**) | 954 744 | 2026-11-07T15:34:35 | - |

Conclusoes por medicao:

1. **O 929 558 B existe, mas e' de 05/11 23:12:18 e e' a v1.2.167** (dois nomes do mesmo backup). Nao e' a P1.132 nem a v1.2.191. Chamar-lhe "intacto" e' verdade sobre um backup de ha 5 dias, nao sobre o artefacto que corre.
2. **931 006 B ("build sombra") nao existe em lado nenhum sob `MQL5`.** O mais proximo e' `Files\Temp\bc\XAU_AI_PRO\XAU_AI_PRO.ex5` com 931 154 B de 06/11 00:46:22 - outro numero, outro dia. Se a build sombra estiver fora de `MQL5` (outro repo no disco) nao a posso verificar daqui: o CMD tem de dizer o caminho.
3. **A copia do repo esta' 22 910 B atras do vivo** (954 744 vs 977 654, de 07/11). O repo nao tem o binario que corre.
4. **O artefacto autoritativo e' um so':** `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`, 977 654 B, `71ED34C690C9593D209A69E95F0EFFB6`. Nenhuma declaracao no `GATE_REAL` pode ser feita em cima da linha dos 929 558 B - nem G4, nem G7, nem a ancora dos 30 dias.

### 3. P1.3529 corrigido - os 40.00 USD do `[RESUMO]` sao a META de lucro, nao o tecto de perda

O P1.3529 foi aberto com a hipotese de que 40.00 USD fosse o tecto de perda lido no runtime, o que pararia o forward. **A hipotese e' falsa.** Medido:

- `Monitoring/OperatorBrief.mqh:143` imprime `dia fechado: %+.2f de %.2f USD (%.0f%%)` com o segundo numero = `OperatorBriefDailyTarget()` e o terceiro = `realizado / meta * 100.0`. E' **meta**, nao limite.
- Os inputs que produzem essa meta: `DailyProfitTargetUsd=20.0`, `DailyProfitTargetBalancePct=10.0`, `DailyProfitTargetMaxUsd=40.0`. Com saldo 12 593.83 a meta seria 1 259 (10%), cortada pelo tecto de 40.00 - e' por isso que sai sempre `de 40.00`.
- Journal de hoje (5 amostras, 08:50:31.415 a 09:10:32.287, todas iguais): `posicoes: 0 EA (+0.00 USD) + 0 manual | dia fechado: -61.80 de 40.00 USD (-154%) | trades=0 | escada=ON arma 5.00 / trava 1.00 em 7.00 / alvo 10.00 USD`. A "escada" e' de lucro, com os mesmos 40.00 no topo.

**Logo:** `-61.80 de 40.00 (-154%)` quer dizer "-61,80 USD realizados hoje contra uma meta de 40,00", i.e., 154% da meta **perdidos**, nao "orçamento de perda de 40,00". O tecto de perda continua a ser o do D-154: **MIN(600.0, 12 593.83 x 3%) = 377.81 USD**. P1.3529 fecha como falso alarme, sem tocar em nada. Fica o numero verdadeiro que ele expos e que interessa: **hoje ha -61.80 USD realizados e 0 trades do EA** - o prejuizo e' de deals anteriores/outros, e nao de actividade da autonomy de hoje.

### 4. O que continua aberto e bloqueia a janela (para o CMD/DONO)

1. **O piso de 0.02 foi aplicado mas a string dos recusados continua a dizer `+0.0500`** (seccao 9 do D-155). Ou o gateway que responde nao e' o que foi reiniciado, ou ha outro ponto com o limiar. Ate' isso estar medido, a janela de 11/11 00:05 servidor arranca com um piso que o proprio gateway diz ser 0.05.
2. **`available=true` subiu de 1 para 6, mas os trades novos sao 0**: confiancas 37.6 / 42.6 / 43.1 / 45.9 / 47.2 todas abaixo do `MinAIConfidence=60.0` (P1.3528). A alavanca efectiva e' essa, e e' decisao do DONO.
3. **Resta 9 h 57 min** ate' 11/11 00:05 servidor (hora local 09:08 = 14:08 servidor, +5 h).

### 5. Guardas

Zero escritas no EA, zero compilacoes, zero deploys, zero alteracoes de input, zero ordens, zero reinicios. O congelamento do D-147 continua intacto. O `GATE_REAL` nao foi tocado - e' do CMD. O `DOSSIE_FINAL.md` **nao** e' assinado: 0 de 11 criterios a verde, 0 de 30 dias.
