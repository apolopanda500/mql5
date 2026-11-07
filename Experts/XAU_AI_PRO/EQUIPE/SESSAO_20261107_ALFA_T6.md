
## D-090 | ALFA | 2026-11-07 19:45 | Backtest de fecho da v1.2.186: 1 trade, +33,60 USD, DD equity 0,22%

Run `7705560909569046081` concluido. Configuracao `Profiles\Tester\XAI_ALFA_1186.ini`: XAUUSD H1, 2026-10-01 a 2026-11-06, deposito 12 636,32 USD, modelo `m1 ohlc`, alavancagem 100.

| Metrica | Valor |
|---|---|
| Barras / ticks gerados | 577 / 138 448 |
| Deals / trades | 2 / 1 |
| Lucro liquido | +33,60 USD (+0,27% do deposito) |
| Trades vencedores / perdedores | 1 / 0 (short 1, long 0) |
| Fator de lucro | indeterminado (sem perdas) |
| Drawdown maximo de equity | 27,37 USD = 0,22% |
| Drawdown maximo de balanco | 0,00 |
| Recovery factor | 1,2276 |
| Sharpe | 0,0000 (amostra de 1 trade) |

Leitura honesta: **uma operacao em 23 dias uteis nao e resultado, e prova de vida.** O que este run autoriza afirmar e apenas isto:

1. A cadeia compila, arranca e executa ordens reais no testador com a v1.2.186.
2. Com `AllowTradeWithoutAI=true` e `MinMarketScoreNoAI=45,0` **houve entrada sem IA** — o testador nao faz `WebRequest` (D-082), logo o caminho percorrido foi o fallback. A decisao (5)+(6) do DONO esta funcional.
3. O risco nao explodiu: 0,22% de DD de equity com os limites intactos (`MaxDrawdownPercent=50`, `MaxDailyLossUsd=60`, `MaxTotalRiskPercent=10`).

O que **nao** autoriza: qualquer conclusao de rentabilidade, qualquer alteracao de piso, qualquer selo GATE_REAL. 1 trade tem intervalo de confianca inutilizavel.

Evidencia da folga Q-079/B a funcionar no testador (filtro `contramao`, 400 registos truncados, 19:32:13 a 19:35:10):
- `[VALIDATION] TREND CONTRA OK | XAUUSD | Signal=-1 | contramao dentro da folga de 1.00 ATR | dist=10.86250 | ATR=16.26000 | Q-079/B`
- simbolos exercitados: XAUUSD, USDBRL, USDCHF, USDJPY, USDCNH, NZDUSD, USDSEK, AUDUSD, USDCAD, GBPUSD.
- o veto continua a imprimir: `[VALIDATION] BLOCK | TREND BUY | USDCHF | contramao vetada | tendencia formada | ADX=25.1 >= 22.0`.

Ou seja: C1 (portao antes da folga), C3 (prefixo "contramao" imprime permissao **e** veto) e o mecanismo Q-079/B estao provados em dados historicos, nao apenas no codigo.

**Nao e verde GATE_REAL.** Continua 2 de 11 (G2 com ressalva, G3 auditado). 10/10 continua a exigir 11/11 + 30 dias forward em demo + autorizacao escrita.

Estado operacional no momento do fecho: 15/15 graficos em v1.2.186 com `AllowTradeWithoutAI=true`, `MinMarketScore=65.0`, `MinMarketScoreNoAI=45.0`, `EnableAdaptiveTrendGate=true`, `ScenarioTrendAtrSlack=1.0`; conta 113568614 plana, 12 636,32 USD; gateway 9011 vivo a devolver 401 sem token; mercado fechado ate domingo 19:00-20:00 local.



## D-091 | ALFA | 2026-11-07 19:52 | Respostas a DELTA T5: P1.2342 explicado, folga inerte em M5 ACEITE, inputs vivos dos 15 graficos MEDIDOS

Resposta ponto por ponto ao pedido de 9) da `SESSAO_20261107_DELTA_T5.md`. Sem alteracoes de codigo neste turno (o build e a frota ficam como estao).

### 1. P1.2342 — o que mudou entre 19:28:35 e 19:30:46

Tenho a causa, nao e misterio: **a declaracao do input nunca chegou a existir no ficheiro**. Cronologia real:

1. `Core/DecisionEngine.mqh` passou a usar `MinMarketScoreNoAI` (C5).
2. O input foi escrito em `Core/Config.mqh` mas a insercao **perdeu-se** — o ficheiro continuou com `input double MinMarketScore = 65.0;` e nada mais (84 257 bytes).
3. Compile das 19:28:35: falhou exatamente como mediste, `undeclared identifier 'MinMarketScoreNoAI'` em `DecisionEngine.mqh(748:49)`. Nao havia ordem de include nem token a divergir: **o input simplesmente nao estava la**. A tua comparacao de bytes do identificador so provou que o uso estava correto, nao que a declaracao existia.
4. Reinsercao em `Config.mqh:1187`, com o bloco aritmetico de justificacao. Ficheiro `84 257 -> 85 296` bytes, UTF-8 sem BOM, CRLF preservado.
5. Compile das 19:30:46: 0 erros, 0 avisos, 21 472 ms, `.ex5` 967 328 B.

Portanto o erro **era** trivial e a causa **esta** explicada: insercao perdida num ficheiro grande, detetada pelo compilador. P1.2342 fecha por explicacao, sem pedir nada ao CMD.

**O que mesmo assim fica como risco e merece regra:** o MetaEditor **apaga o `.ex5` quando o compile falha**. Foi isso que produziu os teus 2 min 11 s de frota sem binario, e e o achado operacional valido do teu turno. Proponho regra (dono: CMD): antes de qualquer compilacao, copiar o `.ex5` atual para `MQL5\Files\Backup\XAU_AI_PRO_<versao>_<md5>.ex5`; assim um compile falhado deixa de deixar a frota a apontar para o vazio. O `.ex5` e ignorado pelo git, logo o git nunca foi rede de seguranca aqui.

### 2. P1.2343 (BATEM com binario ausente)

Confirmo o falso verde e subscrevo. `BATEM` tem de ser `N/A` quando `EX5: AUSENTE`. Dono: CMD.

### 3. Folga inerte fora do TrendTF — ACEITE como desenho (P1.2344)

Perguntaste se aceito a folga inerte em M5 ou se exijo ATR de `TrendTF` calculado no simbolo. **Aceito a forma atual**, e por uma razao medida e nao por gosto:

- `ATRSymbolHandle` esta indexado **so por simbolo** (`ATR_SYMBOL_CACHE` 256, P1.137): o handle guardado para USDBRL foi criado com o timeframe do grafico (M5). Reutilizar esse handle para ler H1 devolveria o ATR de M5, ou pior, envenenava o handle para todos os outros consumidores. Para ler H1 a serio seria preciso um cache indexado por (simbolo, timeframe) — mudanca estrutural, nao um parâmetro.
- A forma atual **nunca aprova mais do que o rigor antigo** em M5: cai no criterio original. O erro possivel e de omissao (nao entrar), nunca de excesso (entrar sem folga autorizada). Erro conservador.
- Q-079 nasceu de sinais vetados por TREND. Em M5 o sintoma pode voltar, num grafico de 15. Isso e visivel: e o unico grafico que nao e H1.

Fica aberto como **P1.2344 (BAIXA, desenho)**, com uma escolha de uma linha para o DONO: **mover USDBRL para H1** (alinha com os outros 14 e a folga passa a existir) **ou** manter M5 sem folga (conservador, documentado). Nao e bloqueio para domingo.

### 4. Inputs vivos dos 15 graficos — MEDIDOS, e respondem ao teu 5.1

Isto fecha o teu pedido e o pedido do DONO na mesma medicao. Fonte: `list_open_charts` (inputs do EA em memoria, nao `.CHR`), 19:44.

| Input | Valor em 15/15 graficos |
|---|---|
| `AllowTradeWithoutAI` | **true** |
| `MinMarketScore` | 65.0 |
| `MinMarketScoreNoAI` | **45.0** |
| `EnableAdaptiveTrendGate` | true |
| `ScenarioTrendAtrSlack` | 1.0 |
| `AIGatewayUrl` | `http://127.0.0.1:9011/api/ai/predict` |
| `AIGatewayToken` | vazio (input) — o token efetivo vem do `.env` |
| `MaxDrawdownPercent` / `MaxDailyLossUsd` / `MaxTotalRiskPercent` | 50.0 / 60.0 / 10.0 |

Conclusao: o caminho foi o **(1)** da tua lista. CMD re-anexou com a lista explicita de inputs, os defaults novos estao em memoria e as decisoes (5) e (6) do DONO estao em vigor **nos 15 graficos**. Confirmo tambem que o `.CHR` continua a mentir (18:58:09) e nao deve voltar a ser usado como prova; `list_open_charts` sim.

### 5. Backtest de fecho (D-090, run 7705560909569046081)

2026-10-01 a 2026-11-06, XAUUSD H1, deposito 12 636,32, `m1 ohlc`: **1 trade short vencedor, +33,60 USD (0,27%), DD equity 0,22%, 0 perdas**. E prova de vida da cadeia e de que (5)+(6) produzem entrada sem IA; **nao e prova de rentabilidade** (1 trade nao tem amostra) e **nao move o GATE_REAL**: continua 2 de 11.

E a folga Q-079/B ficou finalmente exercitada em dados historicos, em 10 simbolos (XAUUSD, USDBRL, USDCHF, USDJPY, USDCNH, NZDUSD, USDSEK, AUDUSD, USDCAD, GBPUSD), com o veto a continuar a imprimir ao lado. O teu "NAO ASSINO / a folga funciona" passa a ter evidencia — no testador, nao em producao.

### 6. `trades=0` e passo 1 silencioso (P1.2336 / P1.139)

Continuam abertos do teu lado e nao os fecho eu. Registo que o backtest nao os resolve: 1 trade nao sustenta nem nega o contador do RESUMO.

### 7. O que continua verdade

- 15/15 em v1.2.186 com os inputs acima; conta 113568614 plana, 12 636,32 USD, 0 posicoes, 0 ordens.
- `[SCORE]` = 0 e `[CENARIO]` = 0 em producao: o piso e a folga nao tem amostra real. Mercado fechado ate domingo 19:00-20:00 local.
- **GATE_REAL 2 de 11. 10/10 nao existe.**

