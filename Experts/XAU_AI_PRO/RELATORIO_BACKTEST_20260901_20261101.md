# Relatorio de backtest - XAUUSD H1 - 01/09/2026 a 01/11/2026

**VEREDITO: REPROVADO. Nao ir a conta real com esta configuracao.**

| Campo | Valor |
|---|---|
| run_id | `7704134350896417964` |
| Simbolo / periodo | XAUUSD / H1 |
| Janela testada | 2026-09-01 ate 2026-11-01 |
| Modelo de ticks | `m1 ohlc` |
| Deposito inicial | 10 000.00 USD |
| Leverage | 100 |
| Otimizacao | desligada |
| Config usado | `MQL5\Profiles\Tester\XAI_V127.ini` |
| Versao do EA em teste | `v1.2.127` (compilada antes do P2.19) |
| Barras geradas | 972 |
| Ticks gerados | 233 111 |
| Relatorio bruto | `MQL5\Files\Backup\backtest_7704134350896417964.json` |

## Resultado

| Metrica | Valor |
|---|---|
| Lucro liquido | **-213.74 USD (-2.14%)** |
| Lucro bruto | 349.65 USD |
| Perda bruta | 563.39 USD |
| **Profit factor** | **0.6206** |
| Expected payoff | -1.41 USD por trade |
| Recovery factor | -0.8186 |
| Sharpe | -5.00 |
| **Drawdown maximo (balance)** | 248.56 USD (2.48%) |
| **Drawdown maximo (equity)** | 261.09 USD (2.61%) |
| Equity minima | 9 749.16 USD |
| Balance minima | 9 758.57 USD |
| Margin level minimo | 2 221.36% |
| Maior lucro / maior perda por trade | +13.84 / -28.89 USD |
| Sequencia maxima de lucros | 7 |
| **Sequencia maxima de perdas** | 10 a 11 |

## Trades

| Metrica | Valor |
|---|---|
| **Trades fechados** | **152** (304 deals) |
| Acertos | **63 (41.4%)** |
| Falhas | 89 (58.6%) |
| Curtos / acertos | 107 / 45 |
| Longos / acertos | 45 / 18 |

## Leitura honesta

1. **O risco por trade esta controlado.** Drawdown maximo de 2.61% num mes de 152 trades significa que o dimensionamento de posicao e os stops funcionam. Isto nao e o problema.
2. **O problema e a taxa de acerto contra o payoff.** 41.4% com expected payoff de -1.41 USD por trade nao fecha a conta: o EA precisa de 45-50% de acerto com o payoff atual, ou de um payoff maior com o acerto atual.
3. **Os curtos carregam o resultado.** 107 curtos com 45 acertos (42.1%) contra 45 longos com 18 (40.0%). Nao ha assimetria que justifique desligar um lado; o defeito e de sinal, nao de direcao.
4. **A sequencia de 10-11 perdas seguidas e o numero que importa para a conta real.** Num mes isso aconteceu; com 1% de risco por trade, 11 perdas seguidas custam ~11% do capital. Com o `MaxDrawdownPercent` atual o EA pararia antes - mas parar por drawdown num mes real e um resultado pior do que nao operar.
5. **O modelo `m1 ohlc` subestima o custo.** Em XAUUSD o spread e o escorregamento em noticias nao aparecem neste modelo. O resultado real tende a ser pior, nao melhor.

## O que fazer antes de repetir

1. **Explicar o `NoSignal`.** No scanner ao vivo, 291 de 319 bloqueios sao `NoSignal`, e o `RSI 45/55` em H1 e o filtro dominante. Se o filtro recusa a maioria das velas, o EA opera pouco e mal - o que combina com 152 trades em 2 meses.
2. **Repetir em `real ticks`** na mesma janela, para medir o custo real de execucao antes de tirar conclusoes sobre o payoff.
3. **Criterio de aprovacao explicito**, decidido antes do teste: `profit factor > 1.20`, `max consecutive losses <= 8`, `drawdown <= 5%` e pelo menos 100 trades. Sem criterio definido antes, qualquer curva serve para justificar uma decisao ja tomada.
4. **Uma janela de 2 meses nao e prova.** Antes de conta real, no minimo 12 meses e uma janela fora de amostra.

## Aviso

Um backtest nao prova rentabilidade futura. O codigo implementa a logica pedida; o resultado acima mostra que a logica, nesta configuracao e neste periodo, perde dinheiro. Qualquer ida a conta real antes de resolver o ponto 1 deste documento e uma aposta, nao uma validacao.
