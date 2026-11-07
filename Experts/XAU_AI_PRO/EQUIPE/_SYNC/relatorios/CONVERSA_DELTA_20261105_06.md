# CONVERSA ARQUIVADA :: DELTA :: turno 2026-11-05 23:30 -> 2026-11-06 05:55

Arquivo de sessao. Guardado fora do canal (o canal estava bloqueado por lock do ALFA no momento do fecho).
Objetivo: qualquer agente ou o DONO reconstroem o que foi feito, medido e decidido, sem depender de memoria.

---

## 1. Pedido do DONO neste turno

> "vamos iniciar os trabalhos juntos e sem parar ate concluir o maximo esta noite, 10/10, sem interrupcoes.
>  Concluir o projeto sem paradas e muitas perguntas, fazer tudo automatico. No fim: salvar conversas,
>  anotar documentos atualizados e encerrar os trabalhos por hoje."

## 2. O que foi aberto no inicio do turno (estado herdado)

- B-031 (backtest) tinha sido lancado e estava "started" ha ~40 min, sem resultado.
- Duvida aberta: o ATR falhava com erro=4807 / barsCalc=-1 no terminal vivo e no tester.
- Disco em queda (~-42 MB/min), log do tester a crescer para 500+ MB.
- Deliberacao pendente do DONO sobre 6 perguntas (R-003, GOLD vs XAUUSD, limpeza de logs, etc.).

## 3. Trabalho executado, por ordem

### 3.1 B-031 run1 (binario antigo) — FECHADO com numeros reais
run_id 7704874073263362126, XAUUSD H1, 2026.08.01-2026.11.05, m1 ohlc, 10000 USD.
- lucro -163.63 USD | PF 0.6643 | DD 454.70 USD = 4.42 % | 9 trades (4G/5P) | Sharpe -0.2537
- binario carregado 927391 B = ANTIGO (sem P1.132) -> estes numeros NAO descrevem o EA atual
- baseline ATR por contagem direta do log: 1 428 980 linhas erro=4807, 1 399 481 SEM LEITURA,
  29 499 HANDLE MORTO, log 659.93 MB
-> publicado: D-041 no DECISOES.md, diario041 no AGENTE_2.md, quadro041 no QUADRO_ESTADO.md,
   av041 ao DONO e ao ALFA.

### 3.2 B-031b (A/B do P1.132) — FECHADO
run_id 7704884692122883821, binario 929558 B (com P1.132), mesmo ini/set.
- ATR: erro=4807 1 428 980 -> 222 878 (-84.40 %); SEM LEITURA -84.41 %; HANDLE MORTO -84.19 %;
  log 659.93 -> 122.43 MB (-81.45 %)
- comercial: +66.15 USD, 9 trades, 9 vitorias / 0 perdas, DD equity 0.58 %, PF indefinido
- leitura: a correcao MELHORA o ATR de forma material; o resultado comercial NAO e utilizavel (9 trades)
-> bloco D-046 escrito (nao publicado: canal bloqueado)

### 3.3 B-031c (controlo de repetibilidade) — FECHADO
run_id 7704894539993498139, mesmo binario e config do B-031b.
- identico ao ultimo decimal em todos os campos (+66.15 / 58.72 DD / 9977.80 equity / 9 trades / Sharpe 3.1127)
- conclusao: o Strategy Tester e DETERMINISTICO nestas condicoes; o metodo A/B e valido; a estrategia
  continua nao validada (repetir nao e provar vantagem)

### 3.4 Achados de codigo (leitura, sem alterar nada)
- `Core\SignalCore.mqh:372-375` — BUY exige fast>slow && rsi<45 && rsi>rsi[2]; SELL exige fast<slow &&
  rsi>55 && rsi<rsi[2] (EMA50/EMA200 M15; defaults 45/55 em `Config.mqh:813-814`).
  => "0 shorts" e ESTRUTURAL em tendencia de alta, nao e avaria. Suspeita que eu proprio levantei em
     av041 e que eu proprio retirei. (O ALFA chegou a mesma conclusao em D-048.)
- `Core\OrderManager.mqh` — OpenBuy()/OpenSell() com formula propria de SL/TP e NENHUM chamador em todo o
  EA. O caminho real e `MarketScanner.mqh:743 -> ExecutionEngine.mqh:246`. Codigo morto; nada apagado.
- `Core\DecisionEngine.mqh:519` — as linhas [SCORE] imprimem subscores de qualidade (emaStrength,
  rsiQuality, adxQuality). TOTAL=100.00 em 11 de 11 amostras => score satura no tecto e o gate
  MinMarketScore nao discrimina neste periodo. NAO medi se e estrutural ou conjuntural.

### 3.5 Infraestrutura e estado
- espelho re-medido: 110 fontes, 0 divergentes (3 divergencias as 00:33 eram transitorias, durante edicao)
- `equipe-auto.ps1` corrido: canal integro, auditor com o espelho divergente nesse instante, disco 2930 MB
- disco fechou em ~2820 MB livres; Tester\logs ~3900 MB (fora da raiz de escrita — so o DONO apaga)

## 4. Correccao registada (importante)

Levantei "0 shorts" como suspeita de assimetria no filtro de venda. Fui ao codigo antes de publicar e a
regra exige EMA50<EMA200 para vender. Retirei a suspeita no proprio bloco, em vez de deixar a duvida a
correr. Registo a correccao porque um erro nao corrigido custa mais do que um erro assumido.

## 5. O que ficou por publicar (bloqueio medido, nao desleixo)

O canal recusou todas as escritas com:
`RECUSADO: canal bloqueado :: ALFA | <motivo> :: quem escreve tem de ser o dono do lock`
Ocorrencias: 00:35, 00:47, 01:00, 01:20, 05:49 (este ultimo ja com o lock do B-033 / binario 1.2.172).
Nao forcei unlock de lock alheio — o protocolo e explicito e a razao do lock era boa (congelar o .ex5
durante um job de tester).

Fila pronta em `MQL5\Files\Temp\` (conteudo final, revisto):
1. `d046.txt`      -> DECISOES.md   (bloco D-046 completo + adenda §10)
2. `diario046.txt` -> AGENTE_2.md
3. `quadro046.txt` -> QUADRO_ESTADO.md
4. `av046_dono.txt`-> INBOX_DONO.md (comando aviso -Para DONO)
5. `av046_alfa.txt`-> INBOX_AGENTE_1.md (comando aviso -Para ALFA)
Comandos exactos em `PENDENTE_046_publicar.md`.

## 6. Estado do projeto no fecho (lido do ledger, nao suposto)

O ATR FECHOU depois do meu bloco. Registos do ALFA no DECISOES.md:
- D-047 (00:36) P1.134 — o P1.132 nao cobria o handle recusado; a serie passa a primeira alternativa
- D-049 (00:58) P1.135 — o 4807 passa a ser curado (handle recriado)
- D-051 (01:24) compilacao 1.2.172 (931194 B, hash 0A28EDFC5BDC) + B-032 lancado por offset
- D-052 (02:12) B-032: SEM LEITURA 218214 -> 0 | HANDLE MORTO 4663 -> 0 | SERIE OK 0 -> 1 | equity 10257.16
Leitura honesta: o defeito que eu documentei em D-036/D-038/D-041 foi fechado por trabalho do ALFA sobre a
minha linha de base. As duas contagens independentes (minha 4 663 HANDLE MORTO e a do D-050) bateram.

## 7. Limites deste turno (para nao ser lido como mais do que e)

- Um simbolo (XAUUSD), um periodo (3 meses), modelo m1 ohlc. Nao e every tick nem multi-simbolo.
- 9 trades por run: zero significancia estatistica. Nenhum numero comercial daqui autoriza optimizar nada.
- Nada tocado em risco/lote/stop/alvo/spread. Nenhum reattach. Nenhum commit/push. Nenhuma compilacao.
- Numeros que nao medi estao marcados "nao medido" no corpo dos blocos — nunca substituidos por estimativa.
