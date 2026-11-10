# ALFA - Especificacao de PERDAS (pedido do DONO) e plano para aplicar ANTES de 11/11 00:05

**Data:** 10/11/2026 10:10 (local) | **Conta:** 113568614 MetaQuotes-Demo | **Saldo:** 12 593,83 | **Equity:** 12 582,73
**Binario:** 977 654 B | `71ED34C690C9593D209A69E95F0EFFB6` | 10/11/2026 02:23:07 - **intacto**
**Janela D-147:** ABRE as 11/11 00:05 servidor e dura 30 dias. Hoje (10/11) ainda se pode configurar; depois das 11/11 00:05 mudar inputs repoe os 30 dias a zero (regra 4 do D-147). Nada foi recompilado, nenhum input tocado, nenhuma ordem enviada.

---

## 1. Os quatro pedidos, respondidos um a um

### 1.1 "banca de 100 = aceitar perder no maximo 30% ao dia"

O limite existe e ja e' configuravel:

```
OrcamentoDiarioPerda() = MIN(saldo x MaxDailyLossPercent/100 ; MaxDailyLossUsd)     Config.mqh
```

| cenario | conta | calculo | orcamento |
|---|---|---|---|
| config viva | 12 593,83 | `MIN(12593,83 x 3,0% ; 600)` | **377,81** |
| DONO a 30% | 12 593,83 | `MIN(12593,83 x 30% ; 600)` | 600,00 - o USD morde |
| DONO a 30% | 100,00 | `MIN(100 x 30% ; 600)` | 30,00 - a % morde |

**Mas o limite nao chega a ser lido.** `Management/EquityProtection.mqh` calcula `drawdown = (balance - equity)/balance x 100` e:

| nivel | conta 12 593,83 | o que faz |
|---|---|---|
| 0,8 x `MaxDrawdownPercent` (6,0) = **4,8%** | 604,50 | arma o `CKillSwitch` - entradas bloqueadas ate reiniciar, magic fechado |
| `MaxDrawdownPercent` = **6,0%** | 755,63 | `EmergencyCloseAll()` |

Com `MaxDrawdownPercent=6.0` em **15/15** graficos, a conta fica plana aos 755,63 de perda flutuante. **Os 30% (3 778,15) nunca seriam alcancados.** Para valerem era preciso DD > 30, que contradiz o portao G6 (DD <= 8%), o P1.3522 (risco simultaneo) e o D-154 (manter 3%).

**Resposta:** 30% ao dia nao e' um input a ligar - e' uma decisao de risco. E numa banca de 100, 30 USD sao menos de **duas** perdas no lote minimo do XAUUSD (21,18 USD cada, ver 1.3).

### 1.2 "separar as perdas dos lucros" e "o dia seguinte nao opera com a mesma banca"

**Ja separado por MAGIC** desde a v1.2.189 (P1.3499), e medido:

- `LucroRealizadoHojeUSD()` (Config.mqh) filtra `DEAL_MAGIC != MagicNumber -> continue` e so conta `DEAL_ENTRY_OUT` / `DEAL_ENTRY_OUT_BY`;
- `CSafetyManager` refaz a soma a cada ciclo e grava `m_daily_profit = eaDaily;` (`SafetyManager.mqh:682`) com o mesmo filtro de magic;
- `CheckDailyLoss()` (`SafetyManager.mqh:310`) recusa quando `|m_daily_profit| >= m_limits.max_daily_loss`;
- consequencia pratica: **um lucro manual deixou de re-armar o EA** - foi exactamente o defeito que a v1.2.189 fechou.

**"O dia seguinte com banca menor" ja funciona, sem reiniciar:** no rolamento do dia, `SafetyManager.mqh:601-612` faz `m_daily_start_balance = RiskHubGet("STARTBAL", AccountInfoDouble(ACCOUNT_BALANCE))` - rele o saldo **actual**. E `RiscoPorTradeUsd()` (Config.mqh:~1369) recalcula `saldo x RiskPerTradePercent/100` a cada chamada. Banca menor -> orcamento menor e lote menor.

**O que NAO esta feito, e e' o que o DONO esta a pedir de verdade:** o orcamento consome o **LIQUIDO**, nao a perda bruta. Um dia com +200 de lucro e -300 de perda fecha em **-100** e o gate de 377,81 nao dispara. Nao existe contador de perda BRUTA no codigo. Exige codigo novo -> depois de 12/11 (P1.3538).

Tambem nao escalam (valores absolutos): `MaxDailyLossUsd=600`, `MaxRiskPerTradeUsd=8.0`, `MaxTotalRiskOpenUsd=60`, `RiskPerTradeUsd=2.0`. Numa banca de 100, o tecto por operacao de 8,00 e' **8% da banca**.

### 1.3 "0,01 lote, metodo 5 USD, stop acima da entrada a garantir lucro"

**Ja implementado**, e o `armUsd` deixou de ser codigo morto na v1.2.69 (`MoneyLadder.mqh:247`: `double armUsd = LadderArmUsd;`):

| input | valor vivo | o que faz |
|---|---|---|
| `EnableMoneyLadder` | true (15/15) | liga a escada |
| `LadderArmUsd` | 5,0 | lucro >= 5 USD -> stop vai para a ENTRADA |
| `LadderLockUsd` | 1,0 | trava 1 USD |
| `LadderLockTriggerUsd` | 7,0 | quando esse lucro e' atingido |
| `LadderTpUsd` | 10,0 | fecha a posicao inteira no alvo em dinheiro |

O que faltava era a **unidade**. Medido com `trade_order_calc_profit` nesta conta:

| volume | 4076,59 -> 4077,59 | resultado |
|---|---|---|
| **0,01** | +1,00 de preco | **1,00 USD** |
| 1,00 | +1,00 de preco | 100,00 USD |

Logo, a 0,01 lote: **1 USD = 100 pontos**. A escada em dolares obriga a:

| evento | pontos a 0,01 lote |
|---|---|
| armar o stop na entrada (5 USD) | **500 pontos a favor** |
| travar 1 USD (7 USD) | 700 pontos |
| fechar no alvo (10 USD) | 1 000 pontos |
| corte de emergencia (1,5R, ATR 17,65, `StoplessArmATRMult=0.8`) | **2 118 pontos contra = 21,18 USD** |

Ou seja: **1 armadura contra 4,2 perdas iguais**. E numa banca de 100, uma unica saida no corte custa 21%.

E o "stop acima da entrada a garantir lucro" existe em dois sitios: a escada (acima da entrada) e, quando a meta diaria de lucro e' batida, a rotina "META DIARIA BATIDA -> PROTEGER O QUE ESTA ABERTO" em `PositionManager.mqh` poe o SL em entrada +/- trava.

### 1.4 "se ficar negativo e nao reverter, sair ou tentar reduzir com operacoes opostas"

**Operacoes opostas NAO existem no codigo.** Varredura completa: 112 ficheiros, 1 763 039 B.

| termo | ocorrencias | veredicto |
|---|---|---|
| `marting` | **0** | nao existe |
| `grid` | **0** | nao existe |
| `piramid` | **0** | nao existe |
| `basket` / `cesta` | **0** | nao existe |
| `hedg` | 2 | `TRADE_RETCODE_HEDGE_PROHIBITED` + um comentario "a conta e hedging" |
| `oposta` | 4 | `ManualGuardAllowSameDirection` - **bloqueia** a direcao oposta |
| `averag` / `mediar` | 26 | `AverageWin`, `AverageLoss`, `GetAverageATR` - nenhuma media de perda |
| `revert` / `reverse` | 5 | nenhum e' fechar-e-inverter |

**Sair da operacao, isso o EA ja sabe fazer.** Cinco mecanismos, todos medidos:

| mecanismo | onde | regra |
|---|---|---|
| SL na ordem | `ExecutionEngine.mqh:956` | so com `EnableStoplessEntry=false` - hoje esta `true`, a ordem sai **sem** SL |
| vigia de emergencia | `PositionManager.mqh:701`, chamado em `:988` | fecha a mercado quando a perda >= `StoplessEmergencyRMult` x 1R = **1,5R**, so em posicoes com `POSITION_SL == 0` |
| parcial | `PositionManager.mqh:608-654` | fecha parte quando o preco anda 1 ATR (`EnablePartialClose=true`) |
| freio de sequencia | `XAU_AI_PRO.mq5:265-300` | 3 perdas seguidas -> pausa de **240 min** |
| proteccao de capital | `EquityProtection.mqh` | 4,8% arma o KillSwitch, 6% fecha tudo |

**E porque nao vou escrever a operacao oposta:** abrir uma perna contraria a uma perda nao a reduz - congela-a. Custa o spread duas vezes (0,13 no XAUUSD) e paga swap nas duas pontas (`swap_long=-12.60`, `swap_short=-4.60` por lote/dia; a 0,01 lote = 0,172 USD/dia). O que reduz perda e' corte. E o AGENTS.md, secao de risco, proibe apresentar martingale/hedge como se fosse seguro.

---

## 2. Dois bloqueios que ninguem tinha medido

### 2.1 `MIN_LOT_EXCEEDS_RISK_CAP` escondido atras do MTF

`BlockWhenMinLotExceedsRiskCap=true` em **15/15** `.chr` e `MaxRiskPerTradeUsd=8.00`. Com ATR H1 do XAUUSD a 17,65:

```
1R          = ATR x StoplessArmATRMult / point = 17,65 x 0,8 / 0,01 = 1 412 pontos
emergencia  = StoplessEmergencyRMult x 1R     = 1,5 x 1 412        = 2 118 pontos
risco minimo a 0,01 lote                        = 2 118 x 0,01 USD  = 21,18 USD
tecto por operacao                                                  8,00 USD
21,18 > 8,00  ->  MIN_LOT_EXCEEDS_RISK_CAP  ->  entrada recusada
```

Hoje **nao** aparece no journal: `MIN_LOT_EXCEEDS` tem **0** ocorrencias desde as 06:00, porque a validacao (MTF) recusa antes de o lote ser calculado. Ou seja, **desligar o MTF nao abre o XAUUSD - muda o bloqueio de sitio.**

A saida que os numeros mostram: `EnableStoplessEntry=false` devolve o SL a ordem e o risco medido passa a ser `StopLossPoints=300` = **3,00 USD** a 0,01 lote, dentro do tecto de 8,00.

### 2.2 D-160 e D-161 desmentidos por medicao

Medi os 15 `.chr` um a um:

| input | valor | n |
|---|---|---|
| `EnableStoplessEntry` | **true** | 15/15 |
| `StoplessEmergencyRMult` | **1.5** | 15/15 |
| `StoplessArmATRMult` | 0.8 | 15/15 |
| `StoplessArmMinPoints` | 30 | 15/15 |
| `EnableManualExposureGuard` | true | 15/15 |
| `BlockWhenMinLotExceedsRiskCap` | true | 15/15 |

O D-161 afirma "o vigia esta desligado em demo por desenho (P1.10)". O P1.10 e' o `RealGuardStoplessEmergencyRMult`, que so impoe **piso em conta real**; em demo o valor lido e' o input, e o input e' `1.5`. Logo o `CheckStoplessEmergency` esta **ligado**. O D-160 acerta no "entrada sem stop ligada em producao" e nao tem medicao para "o corte nao dispara" - nao houve nenhuma entrada do EA hoje.

---

## 3. Estado da conta no momento deste relatorio

Tres posicoes abertas, **todas manuais**, todas SELL XAUUSD e **nenhuma com SL**:

| ticket | lado | lote | entrada | TP | flutuante | SL |
|---|---|---|---|---|---|---|
| 11324108563 | SELL | 0,10 | 4076,74 | 4071,71 | +1,00 | **nenhum** |
| 11324122370 | SELL | 0,05 | 4075,88 | 4069,37 | -3,80 | **nenhum** |
| 11324143493 | SELL | 0,01 | 4077,94 | 4069,37 | +1,30 | **nenhum** |

O proprio EA identifica-as como manuais: `[POSITION GUARD] XAUUSD | posicao MANUAL aberta no mesmo simbolo | nova entrada recusada | dir_manual=-1` (a cada 60 s desde as 09:37), e por isso esta a recusar entradas do EA no XAUUSD (`EnableManualExposureGuard=true`).

**Duas consequencias que o DONO tem de saber:**

1. Estas 3 posicoes **nao entram no orcamento diario do EA** (377,81), porque o filtro por magic as exclui de proposito. Quem as ve e' a `EquityProtection`, que usa saldo e equity da conta. Sao 0,16 lote sem stop: **100 pontos contra = 16,00 USD**.
2. O EA diz BUY no XAUUSD (`[AI] PYTHON | BUY=64.37% | SCORE=64.40` as 09:44:21) contra as posicoes SELL manuais.

**Nao toquei em nenhuma posicao. Nao fechei, nao movi SL/TP, nao abri nada.**

---

## 4. Plano para aplicar HOJE (antes das 11/11 00:05)

Isto pode e deve ser aplicado HOJE: o congelamento do D-147 so vale a partir das 11/11 00:05, e aplicado depois disso repoe os 30 dias a zero. Quem executa e o CMD, com autorizacao do DONO (D-147 regra 4).

### 4.1 Correccao imediata, um clique, sem recompilar (DONO decide)

| input | hoje | proposto | porque |
|---|---|---|---|
| `EnableStoplessEntry` | true | **false** | devolve o SL a ordem: risco medido passa de 21,18 para 3,00 USD a 0,01 lote, e destrava o `MIN_LOT_EXCEEDS` |
| `MaxRiskPerTradeUsd` | 8,0 | **3,0** | 8,0 = 8% de uma banca de 100 |
| `MaxTotalRiskOpenUsd` | 60,0 | **10,0** | 60 = 60% de uma banca de 100 |

### 4.2 Mudanca de codigo (so se o recompilar acontecer ANTES das 11/11 00:05)

| # | o que | porque |
|---|---|---|
| 1 | contador de perda **BRUTA** do dia com o magic, ao lado do liquido | e' o que o DONO pediu em "separar perdas de lucros"; hoje o lucro do dia paga a perda e o limite nunca chega (P1.3538) |
| 2 | a escada passa a poder ser medida em **ATR/pontos** quando o lote e' o minimo | a 0,01 lote os 5 USD sao 500 pontos e o corte fica a 2 118 (P1.3539) |
| 3 | trocar a etiqueta `dia fechado` do `[RESUMO]` por `realizado hoje` | P1.3530, ja aberto - a etiqueta descreve outra coisa |
| 4 | `AIAuthorityMinScore` e' input morto | P1.3527 |

### 4.3 O que eu recomendo NAO fazer

- **Subir `MaxDailyLossPercent` para 30.** Com DD a 6,0 o limite nunca e' lido, e a 30% o EA fecharia a conta antes de o atingir. O numero honesto e' 3%.
- **Escrever hedge / martingale / perna contraria.** Nao reduz perda, congela-a e paga spread+swap duas vezes.
- **Desligar o MTF para "abrir" o XAUUSD.** O bloqueio muda de sitio (`MIN_LOT_EXCEEDS_RISK_CAP`), nao desaparece.
- **Mexer em inputs durante a janela.** Um recompile/reattach reinicia os 30 dias.

---

## 5. Guardas respeitados nesta etapa

| guarda | estado |
|---|---|
| `.ex5` recompilado | **nao** - 977 654 B / `71ED34C690C9593D209A69E95F0EFFB6`, igual antes e depois de publicar |
| input alterado | **nao** - nenhum dos 15 `.chr` foi tocado |
| ordem enviada / posicao fechada | **nao** - 0 chamadas de trading |
| `restart` do terminal | **nao** |
| compile durante a janela (11/11 00:05 -> fim) | **nao** - antes dela, so se for preciso (D-147 regra 1) |
| escrita no canal | lock `edit` do ALFA, `-De ALFA`, unlock no fim, `check` final |

**Ficheiros de canal escritos:** IDS.md (P1.3537-P1.3543), SYNC_LOG.md (7 linhas), DECISOES.md (secao 11), PENDENCIAS.md (7 pendencias), avisos a CMD e DELTA, mais este relatorio.
