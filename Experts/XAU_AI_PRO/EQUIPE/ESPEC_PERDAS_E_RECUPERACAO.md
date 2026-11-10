# ESPEC — Perdas, metas e recuperacao (pedido do DONO, 10/11/2026 09:49)

Documento de especificacao. **Nada aqui foi aplicado**: alterar inputs reescreve os `.chr`
(bloco `<inputs>` MD5 `C7C2ED41AF896B8BF851026E62E3D223`) e mudar codigo muda o MD5 do
binario `71ED34C690C9593D209A69E95F0EFFB6` — em qualquer dos casos **os 30 dias voltam a zero** (D-147).

---

## 0. O pedido, item por item

| # | O que o DONO pediu | Existe hoje? | Veredicto |
|---|---|---|---|
| 1 | banca 100 → perder no maximo **30% ao dia** | a formula existe, o valor e' 3% | **input**, nao codigo |
| 2 | ensinar o EA a **separar perdas de lucros** | separa por **magic** (manual vs EA), mas soma **liquido** | **codigo** (lacuna real) |
| 3 | depois de -30%, **nao operar no dia seguinte com a mesma banca** | o lote acompanha o saldo, o **orçamento nao** | **codigo** (P1.3526) |
| 4 | por lote: 0.01 e **"metodo 5 USD"** | **ja' existe** (`LadderArmUsd=5.0`) | medido |
| 5 | stop acima da entrada **garantindo lucro** | impossivel na abertura; existe em R + escada | **ja' existe** no que a fisica permite |
| 6 | se ficar negativo e nao reverter, **sair** | SL 300 pts + parcial 30%; **sem time stop** | **codigo** (lacuna real) |
| 7 | **operacoes opostas** para diminuir prejuizo | nao existe (e nao reduz) | **rejeitado com numeros** |

---

## 1. Limite diario = percentagem da banca

`Core/Config.mqh:1092-1100` (`OrcamentoDiarioPerda`):

```
teto_diario = MIN(MaxDailyLossUsd, saldo x MaxDailyLossPercent / 100)
```

| Banca | % | Tecto diario | `MaxDailyLossUsd=600` morde? |
|---|---|---|---|
| 100 | **30%** | **30,00** | nao |
| 100 | 3% (hoje) | 3,00 | nao |
| 12 593,83 | 3% (hoje) | **377,81** | nao |
| 12 593,83 | 30% | 3 778,15 | nao |
| 20 000+ | qualquer >4,76% | 600,00 | **sim** |

Para a banca de 100 o pedido e' coerente: **`MaxDailyLossPercent=30.0`** e o tecto em USD deixa
de interferir. **Mas 30% so' faz sentido em banca pequena**: nos 12 593,83 de hoje seriam
**3 778,15 USD num dia**, o que fecha a janela de 30 dias na primeira sessao. Recomendacao:
30% para banca de 100; **3-5% enquanto a banca for esta**.

## 2. Separar perdas de lucros — a lacuna medida

O que ja' esta' certo: `Enterprise/SafetyManager.mqh:670-682` soma **so' deals com
`MagicNumber`** — operacoes manuais (magic 0) nao abrem nem fecham o gate (v1.2.189).

O que esta' errado para o que o DONO quer: a soma e' **liquida**.

```mql5
eaDaily += HistoryDealGetDouble(deal, DEAL_PROFIT) + SWAP + COMMISSION;   // soma COM sinal
m_daily_profit = eaDaily;
// :704
perda = (m_daily_profit < 0.0) ? MathAbs(m_daily_profit) : 0.0;
```

Consequencia aritmetica: um dia com **+80 de lucro e depois -100 de perda** chega ao gate como
**-20**. O orçamento de 30 so' seria atingido com **-110**. Ou seja: **o lucro do dia compra
tolerancia de perda**. O DONO quer o contrario — perda e lucro em caixas separadas:

- **caixa A (perdas)**: soma dos deals **negativos** do dia; e' esta que consome o orçamento;
- **caixa B (lucros)**: soma dos deals positivos; **nao** abate a caixa A;
- o dia fecha quando **caixa A >= orçamento** (ou quando o liquido <= -orçamento, o que for mais cedo);
- o lucro continua a contar para a meta (D-158) e para o `DailyProfitTarget`.

Isto e' **codigo novo** (v1.2.192). Nao ha input que o resolva.

## 3. Banca que encolhe — o orçamento tem de encolher com ela

`m_limits.max_daily_loss = OrcamentoDiarioPerda()` corre **uma vez** no `Init`
(`SafetyManager.mqh:146-147`) e `SetLimits` (`:218`) **nao tem um unico consumidor**. Ja'
`m_daily_start_balance` e' reescrito a cada dia novo (`:601-612`). Resultado medido (P1.3526):
com a banca a cair de 12 593 para 6 000, o tecto **fica nos 377,81** (6,3%) em vez de 180.

Para o caso do DONO (banca 100 → 70 depois de um dia de -30%):

| Dia | Banca | 30% = orçamento | Orçamento **actual** (congelado) | Efeito |
|---|---|---|---|---|
| 1 | 100 | 30,00 | 30,00 | correcto |
| 2 | 70 | **21,00** | **30,00** | permite perder 43% da banca viva |
| 3 | 49 | 14,70 | 30,00 | permite perder 61% |

A correccao e' codigo: recalcular o orçamento **no rollover do dia** a partir de
`m_daily_start_balance`, e (proposta) **sombra pos-perda**: no dia seguinte a um dia que feche
em -X%, o orçamento desse dia = 50% do normal. Isso e' o "nao vai poder operar no dia seguinte
com a mesma banca" traduzido em regra.

## 4. Por lote — os numeros reais do XAUUSD

Medido agora (`get_marketwatch_symbols` + `trade_order_calc_profit`): `contract_size=100`,
`tick_size=0.01`, `tick_value=0.10`, `volume_min=0.01`, bid **4077,00** / ask **4077,13**
(spread **13 pontos**), `swap_long=-12,60` / `swap_short=-4,60` por lote por dia.

| Grandeza | 0,01 lote | 0,10 lote | 1,00 lote |
|---|---|---|---|
| 1,00 USD de movimento do ouro | 1,00 USD | 10,00 USD | 100,00 USD |
| `StopLossPoints=300` (=3,00 de preco) | **3,00 USD** | 30,00 USD | 300,00 USD |
| **R** (risco por trade) | **3,00 USD** | 30,00 | 300,00 |
| spread de entrada (13 pts) | 0,13 USD | 1,30 | 13,00 |
| swap de um dia (compra) | 0,126 USD | 1,26 | 12,60 |

**"Metodo 5 USD" ja' existe**: `EnableMoneyLadder=true`, `LadderArmUsd=5.0`,
`LadderLockUsd=1.0`, `LadderLockTriggerUsd=7.0`, `LadderTpUsd=10.0` — arma aos **5,00**,
tranca **1,00** ao chegar a **7,00**, alvo **10,00**. Em R: 5,00 = **1,67 R**, 7,00 = 2,33 R,
10,00 = **3,33 R**.

**Alerta de escala (banca 100):** `RiskPercent=0.5` daria 0,50 USD por trade, mas o lote minimo
ja' arrisca **3,00 USD** — e `BlockWhenMinLotExceedsRiskCap=true` (`Config.mqh:1465`,
`ExecutionEngine.mqh:633`) **bloqueia a entrada**. Com banca de 100 o EA **nao opera** com os
inputs de hoje. Para operar: `RiskPercent` >= **3,0** (3,00 = 1 lote minimo) e
`MaxRiskPerTradeUsd` de 8,00 para **3,00** (8,00 = 8% da banca por trade).

## 5. "Stop acima da entrada garantindo lucro"

**Na abertura e' impossivel.** Numa compra o stop tem de estar **abaixo** do preco; um stop
acima do preco de entrada dispara no mesmo instante e realiza a perda. Lucro so' se tranca
**depois** de o preco andar a favor. O EP ja' faz isso da unica forma correcta:

| Mecanismo | Inputs vivos | Efeito a 0,01 lote |
|---|---|---|
| Break-even em R | `EnableBreakEven=true`, `BreakEvenInR=true`, `BreakEvenTriggerR=0.6`, `BreakEvenLockR=0.3` | aos **+0,6 R** (+1,80 USD) o stop vai para **+0,3 R** (+0,90 USD) → lucro garantido de 0,90 |
| Escada em dinheiro | arma 5,00 / tranca 1,00 em 7,00 | a partir de +7,00 USD, piso de **+1,00 USD** |
| Parcial | `EnablePartialClose=true`, `PartialPercent=30.0`, `PartialTriggerATRMult=1.0` | fecha **30%** a 1 ATR |

## 6. "Ficou negativo e nao reverte" — sair ou segurar

Existe: SL duro `StopLossPoints=300` (3,00 a 0,01), parcial de 30%, trailing ATR,
`StreakBrake` (3 perdas → pausa de **240 min**), bloqueio de noticias
(`BlockHighImpactNewsMin=15`).

**Nao existe: limite de tempo em posicao.** Procura por `MaxHoldMinutes|TimeStop` no EA: **0
ocorrencias**. Uma posicao perdedora pode ficar aberta indefinidamente, a pagar swap
(**0,126 USD/dia** a 0,01) e a ocupar margem. E' a lacuna real do item "sair da operacao":
proposta v1.2.192 — `MaxHoldMinutes` (ex.: 240) e `MaxHoldMinutesInLoss` (ex.: 120), com
fecho ao mercado quando excedido.

## 7. "Operacoes opostas para diminuir o prejuizo" — recusado, com numeros

Abrir a oposta com o mesmo volume **nao reduz a perda: congela-a** e acrescenta custo.

- 0,01 lote comprado a perder 10,00 → abrir 0,01 vendido fixa o resultado em -10,00 **e paga**
  spread de 0,13 na perna nova + swap dos dois lados (**0,126 + 0,046 = 0,17 USD/dia**);
- enquanto o lock estiver de pe', o resultado nao melhora: para libertar lucro e' preciso
  escolher um lado e voltar a ter risco;
- agrava o `MaxExposurePercent=20.0` e o `MaxCorrelatedTrades=3`, e num dia de -30% o bloqueio
  por orçamento ja' teria fechado a porta a novas entradas.

Alternativas que **reduzem** de facto a perda, ja' disponiveis: parcial de 30%, reduzir lote,
aceitar o SL. Grid, martingale e hedge progressivo **aumentam** o risco de cauda — nao sao
recuperacao, sao adiamento. Se o DONO quiser o lock mesmo assim, fica registado como decisao
dele, com este custo escrito ao lado.

## 8. Classificacao: input vs codigo

| Item | Como se faz | Aplicavel dentro da janela? |
|---|---|---|
| 30% diario | `MaxDailyLossPercent=30.0` | nao — reescreve `.chr`, muda o bloco de inputs |
| risco por trade na banca 100 | `RiskPercent=3.0`, `MaxRiskPerTradeUsd=3.0` | nao — idem |
| metodo 5 USD | **ja' esta'** (5 / 1 em 7 / 10) | nada a fazer |
| BE a garantir lucro | **ja' esta'** (0,6 R → +0,3 R) | nada a fazer |
| separar perdas de lucros (bruto) | codigo v1.2.192 | nao — novo MD5 |
| orçamento reescalar + sombra pos-perda | codigo v1.2.192 (P1.3526) | nao — novo MD5 |
| time stop | codigo v1.2.192 (novo input) | nao — novo MD5 |
| escada de meta 15/30/50% (D-158) | codigo v1.2.192 | nao — novo MD5 |

## 9. Configuracao recomendada

**Banca 100 (o exemplo do DONO):**

| Input | Valor | Racional |
|---|---|---|
| `MaxDailyLossPercent` | **30.0** | 30,00/dia |
| `MaxDailyLossUsd` | 0 (ou 600) | nao deve morder |
| `RiskPercent` | **3.0** | 3,00 = 1 lote minimo a 300 pts |
| `MaxRiskPerTradeUsd` | **3.0** | 8,00 seria 8% da banca |
| `StopLossPoints` | 300 | R = 3,00 |
| escada / BE | 5-1-7-10 e 0,6 R→0,3 R | como esta' |
| perdas consecutivas | 3 → 240 min | -9% antes da pausa |
| max perdas no dia | **10** | 10 x 3,00 = 30,00 = o orçamento |

**Banca actual 12 593,83 (dentro da janela):** manter `3.0%` (377,81/dia) e `RiskPercent=0.5`.
Subir para 30% aqui e' destruir o dossier num dia.

---
DELTA, 10/11/2026 09:55. Nada compilado, nada deployado, nenhum input alterado, nenhuma ordem.
