# SESSAO_20261107 — DELTA · Turno 3 (auditoria do G3)

- **Autor:** DELTA (mede, contesta, assina)
- **Quando:** 07/11/2026, 17:36–17:58 (hora do terminal)
- **Objeto:** auditar a única prova nova que sustentava o G3 proposto pelo CMD no turno 3 — o A/B de Strategy Tester de 16:12 e 16:49.
- **IDs:** D-083 (veredicto), P1.2336 (defeito novo do contador)
- **Disciplina do turno:** 0 compiles, 0 reattach, 0 ordens, 0 alteracoes de risco, 0 linhas de codigo-fonte tocadas. LOCK respeitado (LIVRE desde 17:29:48, nao usado).

---

## 1. Veredicto em uma linha

**O G3 e AUDITAVEL e esta CONFIRMADO na substancia** (saturacao em 100,00 eliminada: 466 -> 0; distribuicao viva: sd 7,47 > 5; teto 70,97). **Mas** a auditoria produz tres correcoes ao texto do commit e **um defeito novo que invalida uma frase usada por todos nos** (o campo `trades=` do `[SCANNER] RESUMO` nao conta execucoes).

| Questao | Veredicto DELTA |
|---|---|
| O A/B correu o .ex5 entregue? | **SIM** — nao os 964197/964093 como ficheiros: sao recompilacoes do MetaTester da **mesma fonte**. Prova em §3. |
| `466/529 = 88,09% -> 0/598 = 0,00%` | **466 -> 0 CONFIRMADO.** O split e **506/621** (total 1127 nos dois casos): 92,09% -> 0,00%. Ver §4. |
| `sd 7,58 (>5)` | **Nao reproduz exatamente.** Medido: A sd **4,05**, B sd **7,47**. Criterio (>5) cumprido por B. |
| `trades 27 -> 7`, `W/L 11/16 -> 3/4` | **CONFIRMADO ao centavo** (contagem de deals no log). |
| `profit +15,71 -> -121,51` | **CONFIRMADO ao centavo** (soma das 27 e das 7 linhas de P/L). |
| `PF 1.06 -> 0.42` | **CONFIRMADO por recalculo** (259,20/243,49 = 1,0645; 86,40/207,91 = 0,4156). |
| `MaxDD 109,56 -> 240,64` / `Sharpe 0,15 -> -0,73` | **NAO reproduzidos.** Exigem curva de equity; o log do tester nao a contem. Ficam por auditar. |
| G3 verde? | **SIM, em tester** — com duas ressalvas escritas em §7. O GATE_REAL nao muda por isto: producao continua inobservavel (D-079). |

---

## 2. Retratacao da minha propria suspeita (ADENDA 3, §2)

No turno anterior escrevi que o A/B "nao correu o .ex5 entregue" porque havia tres tamanhos (`964197`, `964093`, `964056`) e nenhum era o ficheiro em disco. **Essa leitura estava incompleta e retiro-a como conclusao.**

Medido agora:

1. O root `...\D0E8209F77C8CF37AD8BF550E51FF075\Tester` **nao contem um unico `.ex5`** (`find_files_by_glob **/*.ex5` -> lista vazia). Logo os 964197/964093 **nunca foram ficheiros em pasta de agente**.
2. Sao o resultado da **recompilacao que o MetaTester faz da fonte** no arranque do teste, e o desvio e **constante**:

| Run | Carregou | .ex5 em disco no momento | Delta |
|---|---|---|---|
| A · 16:12:54.126 | 964 197 B | 964 160 B (14:36, pre-v1.2.184) | **+37** |
| B · 16:49:11.281 | 964 093 B | 964 056 B (16:23:11, v1.2.184) | **+37** |

Dois pares independentes com o **mesmo delta de +37 bytes** nao e coincidencia: e a mesma fonte compilada pelo mesmo compilador (build 6308) com um blob de identificacao diferente. **A = fonte de antes; B = fonte de depois (v1.2.184). O par A/B e legitimo.**

O que eu nao podia ver antes e que o binario do tester nao e o binario do disco — e nao precisa de ser.

---

## 3. Timeline medida do par A/B

```
16:12:42.823  perfil XAU_AI_PRO.XAUUSD.H1.20260901_20261101.100.ini carregado
16:12:43.837  testing of Experts\XAU_AI_PRO\XAU_AI_PRO.ex5 2026.09.01 -> 2026.11.01
16:12:54.126  expert file added ... 964197 bytes   (A comeca)
16:44:11.813  final balance 10015.01 USD | OnTester result 4.827425131543225  (A termina)
16:49:11.281  expert file added ... 964093 bytes   (B comeca)
17:15:51.556  final balance 9878.35 USD  | OnTester result 0                   (B termina)
```

Nota de metodo: o run **B so terminou as 17:15:51**, e o CMD reporta o turno como medido as 17:34–17:41 — consistente com leitura de resultado ja fechado.

---

## 4. Reproducao da estatistica do G3 (`[SCORE]`)

Fonte: `Tester\logs\20261107.log` (96 293 048 B, UTF-16LE), 321 402 linhas, lido com `FileShare::ReadWrite` (o terminal mantem o ficheiro aberto). Fronteira dos runs = linha **169565** (o `expert file added` do run B).

| Metrica | CMD (commit 3ce229f9) | DELTA medido | Situacao |
|---|---|---|---|
| `[SCORE]` total | 1127 (529+598) | **1127** (506+621) | total exato |
| Linhas com `TOTAL=100.00` | 466 | **466** | exato |
| Run A: saturados / n | 466/529 = **88,09%** | 466/506 = **92,09%** | divergencia de fronteira (23 amostras) |
| Run B: saturados / n | 0/598 = **0,00%** | 0/621 = **0,00%** | exato no que importa |
| sd | 7,58 | A **4,05** / B **7,47** | nao reproduz |
| Media | — | A **98,81** / B **50,87** | — |
| Min / Max | teto 70,97 | A **85,00 / 100,00** · B **30,43 / 70,97** | teto **exato** |

**O que isto prova, sem margem:** em A o score estava degenerado (minimo 85, mediana 100, P10..P90 todos = 100: a normalizacao anterior empurrava tudo para o teto). Em B ha distribuicao (P10=P25=P50=47,83; P75=P90=60,87; max 70,97). **O P1.138 fez o que prometia.** O criterio "sd>5" cumpre-se com 7,47.

**Cautela que falta no commit:** `[SCORE]` **nao e o universo** — passa por `DecisionLogDue(symbol,"SCORE",900)`, ou seja, no maximo 1 linha por simbolo a cada 900 s. Foram 1127 amostras para ~22 458 sinais nos dois runs (~5%). E uma amostra sistematica valida, mas o numero nao pode ser lido como "todas as pontuacoes".

**Divergencia de fronteira (23 amostras):** com o meu corte o run A tem 506 e o B 621; o commit usa 529 e 598. O total 1127 coincide, logo a diferenca e so o ponto de corte — nao documentado. O indicador que decide (0 saturados em B) e 0 nos dois cortes.

---

## 5. O A/B economico — reproduzido linha a linha

Somando as linhas `[TRADE] | ... | Statistics trade registrado | ... | WIN/LOSS | valor` do log:

| | Run A (pre-v1.2.184) | Run B (v1.2.184) |
|---|---|---|
| `[TRADE] OPEN` | 12 | 4 |
| deals registados | **27** | **7** |
| WIN / LOSS (deals) | **11 / 16** | **3 / 4** |
| lucro bruto | **259,20** | **86,40** |
| perda bruta | **243,49** | **207,91** |
| resultado | **+15,71** | **-121,51** |
| PF recalculado | **1,0645** | **0,4156** |
| saldo final do tester | 10 015,01 (-0,70 de custos) | 9 878,35 (-0,14 de custos) |

**Todos os numeros do commit batem ao centavo.** O `+15,71` do commit e o P/L bruto dos deals; o `10 015,01` do log e o saldo liquido de swap/comissao. Os dois estao certos — e a diferenca de 0,70/0,14 explica-se.

### 5.1 O que o commit NAO diz, e devia

1. **B tem 4 posicoes.** O `-121,51` inteiro vem de **um** deal: `2026.10.12 01:00:00 | LOSS | -147,54`. Sem esse trade, B estaria em **+26,03**. Um A/B com n=4 nao suporta a frase "A/B pior" como conclusao; suporta apenas "neste par de corridas, B perdeu".
2. **B para de negociar depois de 12/10.** A ultima execucao de B e 12/10; a janela vai ate 01/11. O run A negoceia ate 29/10. B nao "piorou por ser pior": ficou **quase silencioso** na segunda metade.
3. **`trades` no commit sao deals, nao posicoes.** A: 12 posicoes -> 27 deals (clusters de 3–5 deals em segundos: 17:17:40, 17:17:59, 17:18:00, 17:18:20). B: 4 posicoes -> 7 deals. Contar deals como trades infla o numero de perdas e distorce a taxa de acerto.
4. **MaxDD e Sharpe nao auditados.** O log do tester nao publica curva de equity; so `final balance` e `OnTester result`. Nao assino o que nao medi.

---

## 6. DEFEITO NOVO (P1.2336) — o contador `trades=` do RESUMO nao conta execucoes

Este e o achado do turno, e e maior que o G3.

```
RUN A: 3704 janelas [SCANNER] RESUMO | soma trades= 0 | deals reais registados no log: 27
RUN B: 3725 janelas [SCANNER] RESUMO | soma trades= 0 | deals reais registados no log:  7
```

Nas **7429** janelas dos dois runs o campo `trades=` do RESUMO declarou **zero** enquanto **34 deals** foram executados e registados com WIN/LOSS e valor. O campo nao esta "a menos por arredondamento": esta **estruturalmente a zero**.

**Consequencia imediata e desconfortavel:** a frase "em producao, 0 trades" — que eu proprio usei em D-079 e que o CMD repetiu no turno 3 — **nao pode ser sustentada pelo RESUMO**. O `trades=0` de 05/11 vale exatamente o mesmo que o `trades=0` do run A: nada.

**O que continua de pe, e e o que eu devia ter citado:** o `trades=0` de producao esta provado pela **conta**, nao pelo log — 0 posicoes abertas, 0 ordens, e o historico de deals da conta 113568614 sem entradas. Essa e a prova; o RESUMO e corroboracao invalida.

**Acao (ALFA):** `ScanBlock(SCAN_*)`/contador de trades do `MarketScanner.mqh` — o incremento de `g_scanTrades` nao acontece no caminho de execucao real (ou e incrementado num ramo que nao e o que fecha a posicao). Corrigir e adicionar invariante: `visitas = NoSignal+Stale+Cooldown+JaNegociado+DirHist+AllowTrade+ExecFail` (hoje **nem essa identidade fecha**: A soma 165 785 de bloqueios para 165 785 visitas, mas `AllowTrade+ExecFail = 11 122 = sinais` e `CanOpen=208` fica fora de tudo).

---

## 7. Funil comparado (o que realmente mudou com o P1.138)

| Balde | Run A | Run B | Delta |
|---|---|---|---|
| janelas RESUMO | 3 704 | 3 725 | +21 |
| visitas | 165 785 | 167 171 | +1 386 |
| sinais | 11 122 | 11 336 | +214 |
| NoSignal | 144 432 | 145 886 | +1 454 |
| Stale | 9 944 | 9 905 | -39 |
| JaNegociado | 79 | 24 | -55 |
| Cooldown | 0 | 0 | 0 |
| DirHist | 0 | 0 | 0 |
| AllowTrade (passaram o portao) | 9 823 | 11 301 | +1 478 |
| ExecFail | 1 299 | 35 | **-1 264** |
| CanOpen | 208 | 20 | **-188** |
| deals (log) | 27 | 7 | **-20** |

Leitura: o portao de admissao **abriu** (AllowTrade +1 478), a falha de execucao **desabou** (-1 264) e as ordens efetivas **desabaram** (-20 deals, -188 CanOpen). Isso nao e "o EA ficou pior no sinal": e o **piso de score a 65,00 numa escala nova** a estrangular a ponta do funil.

### 7.1 A distribuicao diz exatamente onde o piso corta

| Piso | Run A (passam) | Run B (passam) |
|---|---|---|
| 35 | 506 (100%) | 596 (96,0%) |
| 40 | 506 (100%) | 593 (95,5%) |
| 45 | 506 (100%) | 567 (**91,3%**) |
| 50 | 506 (100%) | 198 (**31,9%**) |
| 55 | 506 (100%) | 184 (29,6%) |
| 60 | 506 (100%) | 174 (28,0%) |
| **65 (atual)** | 506 (100%) | **9 (1,4%)** |

E a distribuicao e **bimodal**: P10=P25=P50=**47,83** e P75=P90=**60,87**. Nao ha massa entre 48 e 60. Portanto a grelha 65/55/45/35 do D-081 **nao e uma escala**: 65 -> 1,4%, 55 -> 29,6%, 45 -> 91,3%, 35 -> 96%. O piso **nao e um botao continuo, e um comutador entre dois regimes** (quase fechado / quase aberto).

Isto responde a pergunta 2 do CMD com medicao, nao com opiniao.

---

## 8. O que isto faz ao GATE_REAL

- **G3: de "aguarda auditoria" para VERDE AUDITADO**, com duas ressalvas escritas que passam a fazer parte do criterio:
  1. **So tester.** Em producao o passo 3 continua inalcancavel (D-079 mantem-se integralmente).
  2. **Amostra troteada**: 1127 linhas para ~22 458 sinais, `DecisionLogDue(...,900)` por simbolo. Aceitavel como amostra sistematica; nao citar como censo.
- **G2: mantem a ressalva de durabilidade** que o CMD ja registou.
- **Contagem honesta: 2 de 11** (G2 com ressalva, G3 agora auditado). **Nao existe 10/10.** A producao corre 1.2.183 e a v1.2.184 nunca foi observada fora do tester.
- **D-079 nao cai, mas aperta-se:** a prova de "0 trades" em producao passa a depender **exclusivamente da conta** (0 deals / 0 ordens), porque o RESUMO nao serve de prova (P1.2336).

---

## 9. Posicao do DELTA sobre as 4 perguntas ao DONO

**Q-079 (portao de tendencia A/B/C) — recomendo (B).**
- (A) e (C) eliminam a contradicao transformando o portao numa **tautologia** do sinal: fica a haver uma regra onde hoje ha duas, e perde-se a funcao de seguranca (nao comprar dentro de tendencia maior contraria).
- (B) mantem o portao como guarda **independente** e remove o caso patologico (pullback fundo que atravessa a EMA200 H1 por margem inferior a 1 ATR). E a unica das tres que corrige o defeito sem apagar a guarda.
- Qualquer das tres **obriga a remedicao**, e a remedicao so vale alguma coisa se o piso do score for decidido **antes** (ver §9.2): senao o funil continua a morrer 1 passo a frente e a medicao nao distingue as duas causas.

**MinMarketScore (pergunta 2) — o piso 65,00 esta errado para a escala nova; a grelha do D-081 tambem.**
- Numeros de §7.1: 65 -> 1,4% (mata o EA na pratica); 55 -> 29,6%; 45 -> 91,3%.
- Nao e um botao continuo (bimodal 47,83 / 60,87). Escolher entre **regime restritivo** (~30%: piso 50–60) e **regime permeavel** (~91%: piso 45) e uma decisao de apetite de risco do DONO, **nao** de engenharia.
- Sem escolha do DONO, tudo o que se medir a seguir mede o piso, nao o EA.

**Reattach dos 15 graficos (pergunta 3) — tecnicamente seguro, mas sem valor de medicao hoje.**
- O canal mostra que o A/B de tester reproduz o mesmo funil de producao (sinais passam, ordens nao). Reattach sozinho poe a 1.2.184 a correr e a decisao fica igualmente bloqueada no piso e no portao.
- Ordem correta: **Q-079 + piso decididos -> 1 compile -> reattach -> janela de observacao**. Reattach antes disso consome a unica variavel limpa que temos.

**Porta 9001 (pergunta 4) — confirmo o achado do CMD e subscrevo.**
- O `/health` em 9001 responde `401` com `Server: MetaTrader5-MCP` (dono pid 2852, o `terminal64`). Nao e o gateway XAU.
- Regra para o canal: **"porta 9001 ocupada" nao significa "gateway no ar"**. Quem medir disponibilidade do gateway tem de medir o payload, nao a porta. Fica registado como armadilha de medicao, no espirito do §5 do AGENTS.md.

---

## 10. Correcoes a pedir ao CMD (texto do commit, nao do git)

O commit `3ce229f9` ja foi publicado. Nao peco reescrita de historia; peco **errata na sessao do CMD** para os quatro pontos:

1. `466/529 = 88,09%` -> `466/506 = 92,09%` (ou documentar o corte que da 529).
2. `sd 7,58` -> `A 4,05 / B 7,47` (o criterio >5 cumpre-se com 7,47).
3. Acrescentar: `[SCORE]` e amostra troteada a 900 s/simbolo (1127 de ~22 458 sinais).
4. Acrescentar: **B tem 4 posicoes e o prejuizo inteiro vem de 1 deal (-147,54 em 12/10)** — o A/B nao tem poder estatistico e nao decide o piso.

E uma correcao que e minha: **em D-079 e na ADENDA 3, onde citei `trades=0` do RESUMO como prova, a prova certa e a conta (0 deals/0 ordens).** P1.2336 explica por que.

---

## 11. Estado medido no fim do turno

| Item | Valor |
|---|---|
| Conta 113568614 | saldo = equity = 12 636,32 USD · 0 posicoes · 0 ordens |
| EA a correr | v1.2.183 (15 graficos, desde 15:59:45) |
| .ex5 em disco | 964 056 B · 16:23:11 · MD5 931459A39634DD7A95ED1EA74D412FC4 |
| Fonte commitada | v1.2.184 (`3ce229f9`) |
| LOCK | LIVRE (ultimo dono: sistema, 17:29:48) |
| GATE_REAL | **2 de 11** (G2 com ressalva · G3 auditado) |
| Canal | integro, `check` OK |
| Escritas no terminal | 0 |

---

## 12. Fica em aberto (para o proximo turno)

1. **P1.2336** — contador `trades=` do RESUMO e a identidade dos baldes (ALFA).
2. **P1.139** (do turno anterior, continua aberta) — passo 1 de `AllowTradeEx` mudo; 58,5% dos vetos sem `DECISION BLOCKED`.
3. **MaxDD / Sharpe** do A/B — nao auditaveis a partir do log; exigem relatorio do tester (e `tester_list_result_windows` devolve `{"windows":[]}`, nao ha janelas).
4. **Q-079 + piso** — bloqueio unico entre hoje e o EA poder operar.
5. **`AVOID HOUR`** — nos dois runs e o 1.o motivo de `[VALIDATION] BLOCK` em volume (A 2 570 / B 2 715 amostras), acima de `ADX` e logo abaixo de `TREND BUY+SELL` somados (A 4 422 / B 4 028). Nunca foi calibrado com dados; candidato a proximo B-nova.
6. **NEWS / MARKET INTEL: 0 blocos nos dois runs** — o tester nao tem calendario economico. O portao de noticias **nunca foi testado em backtest**; qualquer conclusao do A/B vale so para o subconjunto sem noticias. Lacuna de fidelidade a declarar sempre.

---

*DELTA — medi, contestei o que eu proprio tinha assinado ontem, e assino o que medi. O G3 passou. O funil continua fechado. E o `trades=0` que todos citamos nunca foi do log.*
