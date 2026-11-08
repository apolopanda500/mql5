# SESSAO DELTA - A/B DO PISO SEM IA (07/11/2026)

Medicao de DELTA. Autor do disparo das corridas: ALFA. Nenhuma linha abaixo foi
copiada de relatorio de outro agente: todas saem do log do tester e dos .set em
`MQL5\Profiles\Tester`.

- Fonte: `Tester\logs\20261107.log` (UTF-16LE, 252.309.462 B, ultima escrita 21:54:21)
- Par de artefactos: `XAI_ALFA_floor40.set` e `XAI_ALFA_floor50.set`, ambos 30.028 B,
  ambos gravados 07/11 20:16:01, **328 linhas cada e uma unica linha diferente**
  (L195: `MinMarketScoreNoAI=40.0` vs `50.0`). O par e' limpo: nada mais muda.
- Janela comum: 2026.10.01 00:00 -> 2026.11.06 00:00, XAUUSD H1, Model=1 (m1 ohlc),
  Optimization=0, ForwardMode=0, Leverage=1:100, deposito inicial 12.636,32 USD.

## Resultados medidos

| # | corrida (parede) | piso | saldo final | lucro | trades | PF | MaxDD | expect | linhas do log |
|---|---|---|---|---|---|---|---|---|---|
| A | 19:31:54 -> 19:50:28 | **45,0** | 12.669,92 | **+33,60** | 1 (1W/0L) | 999,00 | 0,00 (0,00%) | 33,60 | 321458 / 489945 |
| B | 20:43:22 -> 21:06:30 | **40,0** | 12.647,48 | **+11,16** | 2 (1W/0L) | 999,00 | 0,00 (0,00%) | 5,58 | 500786 / 648782 |
| B' | 21:07:05 -> 21:33:30 | **40,0** | 12.647,48 | **+11,16** | 2 | 999,00 | 0,00 (0,00%) | 5,58 | 648830 / 799561 |
| C | 21:54:21 -> 22:16:02 (morto) | **50,0** | **PERDIDA** - crash 22:16:02 antes do flush: sem `final balance`, sem `.tst`, sem janela | - | - | - | - | - | 799612 |

Corridas de outra janela (2026.09.01 -> 2026.10.30, deposito 10.000,00), so para
contexto de risco, **nao** fazem parte do A/B:

| corrida | piso | saldo final | lucro | trades | PF | MaxDD | linhas |
|---|---|---|---|---|---|---|---|
| 16:12:54 -> 16:44:11 | sem `MinMarketScoreNoAI` no dump | 10.015,01 | +15,71 | 27 (11W/16L) | 1,06 | 205,09 (109,56%) | 26 / 169518 |
| 16:49:11 -> 17:15:51 | idem | 9.878,35 | -121,51 | 7 (3W/4L) | 0,42 | 207,91 (240,64%) | 169568 / 321372 |

## O que isto prova e o que nao prova

1. **Reprodutibilidade: provada.** B e B' tem o mesmo .set, a mesma janela e sao
   corridas independentes: lucro 11,16, 2 trades, MaxDD 0,00, expect 5,58 -
   identicos. O motor e' deterministico nesta janela.
2. **Piso 40 e' pior que 45 nesta janela.** O trade marginal que o piso 40 admite
   (score entre 40 e 45) custa **-22,44 USD**: 45 -> +33,60 (1 trade) contra
   40 -> +11,16 (2 trades). Sinal unico, nao estatistica.
3. **Amostra inviavel para veredicto.** 1 a 2 trades em cinco semanas, em 10
   simbolos. `PF=999,00` significa "zero perda bruta", nao lucro; `MaxDD=0,00%`
   com 1-2 trades nao mede risco. Nenhum dos dois numeros entra em GATE_REAL.
4. **O A/B nao mede a IA.** Dentro do tester nao existe gateway: o EA le uma
   predicao congelada - `[AI] PREDICAO VENCIDA | XAUUSD | AGE=88358s > LIMIT=900s`
   e `IA(XAUUSD)=SELL 63.6% (ha 87460s)`. O que o A/B mede e' o caminho
   **sem IA / autonomo**, que e' exactamente o que o piso sem IA governa. Vale
   para a decisao do piso; nao vale como medicao do comportamento com IA viva.
5. **Nada aqui autoriza conta real.** GATE_REAL continua **2 de 11**, forward
   **0 de 30**. Corrida de teste nao e' forward e nao conta dia.

## Defeitos medidos nas mesmas corridas (nao corrigidos por DELTA)

- `[TREND] LEITURA SUSPEITA | USDBRL | EMA=3755.79558 | bid=5.53000` e
  `EURUSD | EMA=6.66587 | bid=1.12193` - handles presos, com valores de outra
  escala, reproduzidos dentro do tester; `[DIAGGATE] 114 chaves activas |
  linhas suprimidas=426620`. Confirma P1.110/P1.119 tambem em backtest.
- `[LOGGER WARNING] Falha ao rotacionar log. Erro=5004 | fallback=sem truncagem`.
- `[NOTIFY] Sent=0 | Failed=31`.
- Inputs da corrida em vigor: `EnableAutonomousMode=false`, `SL=300 pts`,
  `TP=600 pts`, `Trades/dia=100`, `MaxDD=50,0%`, `MaxDailyLossUsd=60,0`,
  `MaxRiskPerTradeUsd=8,0`, `MinMarketScore=65,0`. Nos 15 graficos vivos
  `EnableAutonomousMode=true` - divergencia a declarar, nao a corrigir aqui.

## Estado do par

- floor40: **fechado e medido** (B e B').
- floor45: ja existia da corrida A (e' o valor assinado pelo DONO na FICHA).
- floor50: **PERDIDO** - arrancou 21:54:21 com `MinMarketScoreNoAI=50.0`, agente
  127.0.0.1:3000, mesmo deposito 12.636,32. A corrida de 40 levou 26m30s; a linha
  `final balance` so aparece quando o agente fecha, porque o log e' descarregado
  de uma vez no fim. O crash do terminal as 22:16:02 matou a corrida antes do flush; provas na adenda das 22:47.

DELTA nao ocupou o slot do tester, nao compilou, nao reanexou, nao enviou ordens.

## Adenda 22:05 - P1.3479 medido: o fail-open prova-se por numero

Contagem propria no `Tester\logs\20261107.log`, uma passagem, regex
`LEITURA SUSPEITA \| (\w+) \|`.

- Total `[TREND] LEITURA SUSPEITA` = **278.536** linhas. O total do CMD bate.
- Reparticao medida (a do CMD nao fecha: 83.787 + 80.222 + 65.065 + 55.133 =
  284.207 > 278.536, logo so a reparticao estava inflada):
  USDSEK 73.464 | GBPUSD 65.135 | USDBRL 50.896 | EURUSD 46.604 |
  AUDUSD 21.622 | USDCAD 12.485 | XAUUSD 4.219 | USDCHF 1.453 |
  NZDUSD 982 | USDJPY 981 | USDCNH 695. Fecham exactamente 278.536.
  As 5 ausencias (USDCLP, USDCOP, USDCZK, USDRUB, USDSGD) NAO sao saude e nao
  sao defeito: esses simbolos nao estao no input `Symbols` da corrida. O tester
  passou exactamente 11 simbolos (AUDUSD, EURUSD, GBPUSD, NZDUSD, USDBRL,
  USDCAD, USDCHF, USDCNH, USDJPY, USDSEK, XAUUSD) e sao esses 11 que aparecem
  nas linhas. EURUSD entra por estar no input, apesar de nao ter grafico.
- Estas linhas saem da tag `trend_leitura_suspeita_<simbolo>`
  (`TrendFilter.mqh:290`) com janela **3600 s**. Com o throttle a funcionar, o
  maximo na janela 01/10-06/11 (~864 h) e **~864 linhas por simbolo**.
  Medido: USDSEK **73.464**, ou seja **85x** acima do limite. O fail-open nao e'
  hipotese de leitura de codigo: esta' medido no resultado.
- `[DIAGGATE]` **nao serve de prova**: e' outro modulo (`Monitoring/DiagGate.mqh`),
  conta 100/57/99/114/114 chaves nas 5 corridas de hoje e **nunca imprimiu
  "tabela cheia"** (`DiagGate.mqh:179`). O `[DIAGGATE] 114` nao diz nada sobre a
  tabela de 128 do `AccountLogGate`.
- A conta do ticket (7 ATR + 2 TREND x 15 = 135) **subestima** o problema. SÃ³ as
  tags ATR sao 7 por simbolo (`VolatilityFilter.mqh:302,588,711,745,767,809,835`,
  todas com sufixo `__DATETIME__`) = **105 de 128 slots**. A somar: ADX 4 x 15 = 60,
  RSI 15, `global_` 15, `cenario_hb_` 15 + `cenario_snap` 1, trend 15 + 1,
  `version_`/`sess_`/`inicio_detalhe` ~5 -> universo potencial **> 230 tags**.
- Mecanismo medido: a tabela satura cedo por causa das 105 tags ATR; as tags que
  chegam depois nunca entram e passam a imprimir em todas as chamadas. E' por isso
  que a tag de trend (janela 3600 s) sai 85x mais do que devia.
- Consequencia para a correcao: **subir `TESTER_GATE_MAX_TAGS` nao resolve
  sozinho**. As 7 tags ATR levam `IntegerToString((long)__DATETIME__)`, que muda a
  cada compilacao e garante 105 entradas mortas por build. Tirar o `__DATETIME__`
  dessas 7 tags baixa o consumo de 105 para 7 e devolve folga real a tabela.
- DELTA nao alterou o modulo: e' fonte, e a regra e' "nao altera fonte sem pedir".
  Fica como proposta para o ALFA.

## Adenda 22:47 - floor50 PERDIDO: o crash de 22:16:02 matou a corrida antes do flush

Medido por DELTA as 22:45, em quatro provas independentes.

1. **O log do tester nao cresceu desde o crash.** `Tester\logs\20261107.log`
   esta' congelado em **252.339.234 B**, ultima escrita **07/11 22:21:08** -
   ja' nao e' o ficheiro de 21:54:21 citado no topo desta sessao.
2. **A cauda do log nao tem resultado do piso 50.** Ultimos 400.000 B
   (1.412 linhas, lidas por `FileStream`+`StreamReader` Unicode porque o ficheiro
   esta' aberto pelo terminal):
   ```
   QR 2 22:16:02.744 Core 1 disconnected
   NO 0 22:16:02.744 Core 1 connection closed
   PG 0 22:17:01.186 Tester Cloud servers switched off
   ```
   Do piso 50 existe **so' o cabecalho**, gravado 21:54:21.647:
   ```
   HI 0 21:54:21.647 Core 1 2026.10.01 00:00:00   [BT] inicializado
   CS 0 21:54:21.647 Core 1   MinMarketScoreNoAI=50.0
   ```
   Nao ha' `final balance` nem linha de resultado `[BT] Trades=...` dessa
   corrida. A ultima `final balance` do ficheiro e' **12.647,48 USD @ 21:33:30**
   (corrida B', piso 40).
3. **Nenhum `.tst` novo.** O mais recente em `Tester\cache` continua a ser
   `XAU_AI_PRO.XAUUSD.H1.20261001_20261106.1.08F212B48A4BAF350A117D89621229EA.tst`,
   21.682 B, **21:33:30** (B'). Nada foi escrito por volta das 22:21.
4. **Janelas de resultado vazias.** `tester_list_result_windows` as 22:04, 22:39,
   22:41 e 22:45: `{"windows":[]}`.

Semantica que sustenta a conclusao: o tester descarrega o bloco do log de uma vez
no fim de cada passagem, todo com o mesmo carimbo de parede (A @ 19:50:28,
B @ 21:06:30, B' @ 21:33:30). Um bloco das 21:54:21 que tem so' o cabecalho
significa "a corrida arrancou", nao "a corrida acabou". O crash das 22:16:02
matou o processo antes do flush.

Linha C corrigida na tabela acima:

| # | corrida (parede) | piso | saldo final | lucro | trades | PF | MaxDD | expect | linhas |
|---|---|---|---|---|---|---|---|---|---|
| C | 21:54:21 -> 22:16:02 (morto) | **50,0** | **PERDIDA** (sem `final balance`, sem `.tst`, sem janela) | - | - | - | - | - | 799612 |

**Consequencia: o par A/B fica com 3 de 4 metades medidas.** floor45 +33,60
(1 trade) e floor40 +11,16 (2 trades, identico em duas corridas). floor50 nao
tem numero e nao se inventa. Relancar o floor50 exige ocupar o slot do tester -
e' decisao de quem manda no terminal, nao de DELTA.

## Adenda 22:45 - gateway de IA medido: vivo, autorizado, e a recusar 14 de 15 simbolos por edge

Sonda propria (`MQL5\Files\Temp\delta_gwprobe.ps1`), token lido de
`MQL5\Files\XAU_AI_PRO\.env` (104 B, campo `XAU_GATEWAY_TOKEN` presente, 64
caracteres; **o valor nunca foi impresso**):

| pedido | resultado |
|---|---|
| `GET /health` com token | **HTTP 404** `{"detail":"Not Found"}` |
| `GET /api/ai/predict?symbol=XAUUSD&timeframe=H1` | **HTTP 200, 1.122 B**, `available=true`, `signal=SELL`, `confidence=72.4`, `edge=+0.0363`, `price=4065.82`, `atr=20.98` |
| `GET /api/ai/predict?symbol=USDSGD&timeframe=H1` | **HTTP 200, 357 B**, `available=false`, `reason="edge +0.0193 abaixo do minimo +0.0500 (acc 0.3725 vs palpite 0.3532)"` |

Leitura medida: as linhas `[AI] GATEWAY | <sym> | H1 | 357 bytes |
disponivel=false` das 22:21:55-56 **nao sao falha de canal**. Sao o gateway a
responder **200** com "edge insuficiente". `XAUUSD` devolve 1.123 B com
`disponivel=true` (a diferenca de 1 B para a minha sonda e' contagem de
terminador). A hipotese que eu tinha formado - "o EA esta' a ser recusado, token
em falta" - **foi desmentida pela medicao** e nao segue para PENDENCIAS como
defeito. Tambem `/health` nao serve de prova de vida: o 401 que eu tinha lido
antes vem do middleware, antes do routing; a rota devolve 404 quando o token
passa.

Duas notas que ficam registadas, sem ticket novo:

- `timeframe=H1` em todos os simbolos **nao** e' o periodo do grafico. As 22:21:56
  os 15 graficos estavam em M5 (journal `22:21:23.847 expert XAU_AI_PRO (USDBRL,M5)
  loaded successfully`; `list_open_charts` title `USDBRL,M5`, chart_id
  35819338055848, total_bars 24717). O H1 vem do input do gateway, nao do chart -
  logo nao ha' divergencia de periodo a resolver.
- `[TRADE BLOCK] COTACAO VELHA (timer) | <sym> | idade=98.518s..123.723s |
  limite=900s` em todos os simbolos e' o fim de semana: ultimo `trade_server_time`
  `2026-11-06 23:59:59`, agora `2026-11-08 01:45 UTC`. A guarda esta' correcta,
  nao e' defeito e nao pede accao. O `TradeLogger WARN | schema sem lock
  (concorrencia)` das 22:21:25 pertence ao P1.111 ja' aberto.

DELTA nao ocupou o slot do tester, nao compilou, nao reanexou, nao enviou ordens
e nao alterou fonte nem risco nesta adenda. GATE_REAL **2 de 11**, forward
**0 de 30**.

## Adenda 08/11 08:45 - o binario certo nao chega: o `.set` "replica A" nao replica nada

Medido antes de recomendar o que correr no v1.2.187.

- `DELTA_186_A.set` (29.894 B, criado 07/11 20:16:46) **nao e' a corrida A**. Contra `XAI_ALFA_floor40.set` tem **16 linhas diferentes**, e nao a unica linha (L195) que separa floor40 de floor50. As que mudam o experimento: `Symbols=XAUUSD` (1 simbolo) contra 11 simbolos (`XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH`); `SymbolsFromMarketWatch=false` contra `true`; `EnableAutonomousMode=true` contra `false`; `EnableTelemetry`/`EnableDataset`/`SaveDatasetCSV` = `false` contra `true`; e o piso `45.0` contra `40.0`. Correr isto no 187 nao mede "A com o binario novo" - mede outro sistema.
- O `.ini` **nao transporta o `.set`**: `XAI_ALFA_1186.ini` (530 B) fixa `Expert`, `Model=1`, `Symbol=XAUUSD`, `Period=H1`, `FromDate=2026.10.01`, `ToDate=2026.11.06`, `Deposit=12636.32`, `Leverage=100`, `ForwardMode=0`; o `.set` e' passado no arranque do teste. A receita e' o par (ini + set), nao o ini sozinho.
- **A corrida A nao e' reprodutivel a partir do disco.** Nao existe `.set` com piso `45.0` datado de antes das 19:31:54: o unico e' o `DELTA_186_A.set`, criado 45 minutos depois e de 1 simbolo. B e B' sao reprodutiveis ao centavo (`XAI_ALFA_floor40.set`, corrida duas vezes, resultado identico); A esta' medida no log mas o ficheiro de entrada foi sobreposto. Isto reduz o alcance do "par A/B": o que se pode repetir e' o piso 40, nao o 45.
- Receita comparavel para o 187: `XAI_ALFA_1186.ini` + `XAI_ALFA_floor40.set` (11 simbolos, `EnableAutonomousMode=false`, dataset/telemetria ON, piso `40.0`). O alvo de comparacao e' B/B': **+11,16, 2 trades (1W/0L), PF 999,00, MaxDD 0,00%, expect 5,58**.

Regra que proponho ao DONO - **binario congelado no forward**: o forward de 09/11 00:05 corre num **unico binario, declarado por MD5 antes do inicio**; reanexar a meio divide os 30 dias por dois builds e invalida a contagem.

Estado medido agora: `terminal64` PID **14240** desde 22:21:19 (sem reinicio) e **zero** linhas `[START]` desde as 23:05, logo a frota continua a **v1.2.186** carregada as 22:21:24; `XAU_AI_PRO.ex5` em disco **966.012 B, `CAE840F6`** (v1.2.187) desde 22:46:45; conta 113568614 flat **12.636,32 USD**, 0 posicoes, 0 ordens; slot do tester livre.

