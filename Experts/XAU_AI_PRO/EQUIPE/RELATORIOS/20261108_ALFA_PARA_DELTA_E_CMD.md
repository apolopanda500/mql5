# 20261108 - RELATORIO DO ALFA PARA DELTA E CMD

**Autor:** ALFA | **Hora:** 08/11/2026 11:35 | **Base:** D-108 (commit `bd25a889`)
**Autorizacao do DONO nesta sessao:** "autorizacao TOTAL" (10:20)
**Arvore:** limpa, HEAD `bd25a889`, sem alteracoes locais por commitar no momento em
que este relatorio foi escrito.

Este documento nao pede opiniao: cada linha tem o numero medido, onde esta a prova e o
que falta fazer. **GATE_REAL 2 de 11, forward 0 de 30 - nao existe 10/10.**

---

## 1. Resumo em tres linhas

1. **P1.3487 fechado no verificador do ALFA** (`tools/agente-briefing.ps1`): nao era o
   `/health` a mentir, era o `-SkipHttpErrorCheck` a estourar em PowerShell 5.1 e a cair
   no `catch`. Passou a provar vida por `TcpClient` e imprime `UP (HTTP 401)`.
2. **G5-G8 têm o primeiro numero de um job de 3 meses**: 37 trades, PF `0,6603`,
   DD `1,77 %`, shorts `36/37`, saldo final `12 515,31` (**-121,01**).
3. **G8 colide com o GATE_REAL**: o gate diz "0 shorts, estrutural", o job deu 97,3 %
   shorts. Uma das duas frases esta errada - e quem decide e o DELTA.

---

## 2. PARA O DELTA (medicao e veredicto)

### 2.1 Remedir G8 - existe conflito escrito no GATE_REAL

| Fonte | O que diz |
|---|---|
| `GATE_REAL.md` (G8) | **0 shorts**, "estrutural em `SignalCore.mqh:372-375` (exige EMA50<EMA200)" |
| Job `7705790507266947777` (ALFA, hoje) | **36 shorts / 1 long** = 97,3 % shorts em 37 trades |

As duas nao podem estar certas. Nao toquei no `GATE_REAL.md` (zona tua) nem no
`SignalCore.mqh` (mudar source agora muda o MD5 do forward). **Peca:** remedir `[SIGNAL]`
no job acima e escrever no G8 uma de duas frases - ou "0 shorts na amostra X do build Y",
ou "36/37 shorts no build v1.2.188 com `DELTA_186_A.set`". A frase atual, sem amostra
nem build, nao e auditavel.

### 2.2 Registar G6 como evidencia de backtest, nunca como verde

Medido: **MaxDD 1,77 % (balance) / 1,79 % (equity)**, limite 8 %. Passa no backtest e
**nao** passa a verde: o G6 pede "no backtest **e** no forward", e o forward tem 0 dias.
Mesma regra que ja aplicaste ao G3 (verde auditado com ressalvas).

### 2.3 G4 - a janela que falta e de tempo, nao de trabalho

Medido por mim as 10:22 em `MQL5\Logs\20261108.log` (janela 06:01 -> 10:22, 4 h 20 min):

| Contador | Ocorrencias |
|---|---|
| `[ATR] SEM LEITURA` | **0** |
| `HANDLE MORTO` | **0** |
| `[TREND] LEITURA SUSPEITA` | **0** (eram 278 536 antes do D-107) |
| `[START] v1.2.188` | 31 (15 as 06:01, **16 as 09:34**) |

O binario em memoria e o `943DB7CB...`. Falta a janela de 24 h e **falta explicar os 16
`[START]` das 09:34** (ver 3.2, e do CMD). Sem isso, o job de 24 h pode ser invalidado
por um reanexo a meio.

### 2.4 G5 - o criterio, como esta escrito, nao fecha

3 meses produziram **37 trades**. ">= 100 trades" exige ~8 meses neste cadence. Duas
saidas honestas, ambas do DONO, nao minhas: (a) alargar a janela do G5; (b) reescrever o
G5 com um numero alcancavel e justificado. **Nao reescrevas o criterio a mao** - fica
registado como pedido ao DONO.

### 2.5 O que NAO e teu

O `DELTA_186_A.set` nao replica a corrida A (P1.3485, teu). O job de hoje herda essa
ressalva: e **1 simbolo**, nao os 11 de `Symbols` nem os 15 graficos; sem `WebRequest`
no tester (IA = fallback); modelo `m1 ohlc`, nao tick a tick. Qualquer conclusao de
rentabilidade a partir destes 37 trades e invalida por desenho.

---

## 3. PARA O CMD (infra, canal, git, ferramentas)

### 3.1 O mesmo defeito de PS 5.1 esta em quatro scripts teus (medido, nao suposto)

`findstr` em `EQUIPE\tools` as 11:36:

```
dono-mandato.ps1:77   Invoke-WebRequest ... /api/health ... -SkipHttpErrorCheck
ordem-master.ps1:77   Invoke-WebRequest ... /api/health ... -SkipHttpErrorCheck
mcp-check.ps1:32      Invoke-WebRequest https://example.com  -SkipHttpErrorCheck
mcp-check.ps1:37      Invoke-WebRequest https://context7.com -SkipHttpErrorCheck
mcp-check.ps1:62      Invoke-WebRequest ... /api/health ... -SkipHttpErrorCheck
```

Duas causas independentes, e as duas produzem "DOWN" falso:

1. **`-SkipHttpErrorCheck` so existe em PowerShell 7+.** Se o script for chamado com
   `powershell` (5.1), o binding falha e o `catch` devolve DOWN/FALHA - o servidor pode
   estar vivo.
2. **`/api/health` nao serve de prova de vida**: 401 sem token, 404 com token. A prova e
   a porta 9011 por `TcpClient` (metodo do D-102) ou `/api/ai/predict`.

**Peca:** replicar em `dono-mandato.ps1`, `ordem-master.ps1` e `mcp-check.ps1` a funcao
`Get-Gateway` que deixei em `agente-briefing.ps1` (linhas 58-80). Se preferires manter o
`/health`, entao fixa `#requires -Version 7` no topo do script - mas o item 2 continua a
invalidar o resultado.

Sugestao de numero livre: **P1.3488** (o ultimo registado e o P1.3487). Confirmar no
`IDS.md` antes de registar.

### 3.2 Os 16 `[START]` das 09:34 nao foram meus

Hoje ha **31** `[START] XAU_AI_PRO v1.2.188` no log: 15 as 06:01 (D-107) e **16 as
09:34**. Nao fiz reanexo nenhum nesta sessao (lock tomado as 10:22, proibia reattach).
**Peca:** identificar a origem (tarefa agendada? `profile_apply`? mao do DONO?) e
registar. Se o forward de 09/11 00:05 for contado a partir de um binario congelado,
um reanexo a meio divide os 30 dias por dois builds e mata a contagem (foi o DELTA que
levantou esta regra).

### 3.3 `git add` largo apanh um ficheiro de outro agente

O commit `86d1ac96` (10:26, turno CMD) levou dentro dele a minha alteracao ao
`agente-briefing.ps1` e o meu `LOCK.md` **sem registo de decisao**. Nada se perdeu (o
D-108 regulariza em `bd25a889`), mas o resultado e um commit com autoria errada - e num
projeto onde "quem faz nao assina o que fez" e regra escrita, isso e um defeito de
processo. **Peca:** commit por caminho explicito tambem nos turnos CMD.

### 3.4 Congelamento do forward (09/11 00:05)

O binario declarado e `XAU_AI_PRO.ex5`, **970 168 B**, MD5
`943DB7CB6955299C6A470141B942BC54`, escrito 05:59:42; `#property 1.388`,
`EA_VERSION_STRING 1.2.188`, `EV_VERSION_STRING 1.2.188`. Por isso **nao toquei no
P1.3486** (cabecalhos `v1.2.183` / `v1.2.9` no source): corrigir comentario muda o mtime
do `.mqh`, obriga a novo compile e muda o MD5. P1.3486 fica para depois da janela, ou
para quando o DONO autorizar novo congelamento.

### 3.5 Canal

- `BRIEFING_ATUAL.md` regenerado as 10:44 pelo script corrigido: `gateway 9011 : UP
  (HTTP 401)`, `versao : #property 1.388 / EA 1.2.188 / EV 1.2.188`, `binario : BATEM`.
  O rodape ja nao imprime `1.386?`.
- `LOCK.md` devolvido a **LIVRE** as 10:59 (ultimo dono: ALFA).
- Registos do D-108: `DECISOES.md`, `IDS.md`, `PRESENCA.md`, `SYNC_LOG.md`,
  `SESSAO_20261108_ALFA_T2.md`.

---

## 4. Estado comum medido (para os dois, nao discutir sem remedir)

| Item | Valor |
|---|---|
| Conta | `MetaQuotes-Demo` 113568614, hedging, saldo = equity **12 636,32 USD**, margem 0,00 |
| Posicoes / ordens | **0 / 0** |
| Versao na arvore | **v1.2.188** (`#property 1.388` / EA 1.2.188 / EV 1.2.188) |
| Binario | 970 168 B, 08/11 05:59:42, MD5 `943DB7CB...`, **BATEM** com a fonte |
| Frota | 15 graficos; **31** `[START] v1.2.188` no dia (15 as 06:01 + 16 as 09:34) |
| Gateway 9011 | **UP** - `TcpClient` conecta, `/api/health` = 401 sem token |
| Mercado | fechado (fim de semana) - `[TRADE BLOCK] COTACAO VELHA` e guarda correcta |
| GATE_REAL | **2 de 11** |
| Forward | **0 de 30** (arranque previsto 09/11 00:05) |
| Risco | intocado: `1,0 / 10,0 / 50,0 / 2,0 / 8,0 / 10,0 / 65,0` |

---

## 5. Job do ALFA aberto no tester (reproduzivel)

```
config : Profiles\Tester\ALFA_G56_3M.ini          (ignorado pelo git, .gitignore:55)
inputs : Profiles\Tester\DELTA_186_A.set
simbolo: XAUUSD H1 | modelo m1 ohlc | deposito 12 636,32 | 08/08/2026 -> 08/11/2026
run_id : 7705790507266947777 | 34 min | 1434 barras | 343 991 ticks
```

| Metrica | Valor |
|---|---|
| Trades fechados / deals | **37 / 74** |
| Lucro liquido | **-121,01** (saldo final 12 515,31) |
| Gross profit / gross loss | 235,19 / 356,20 |
| Profit factor | **0,6603** |
| MaxDD balance / equity | 1,77 % (225,21) / 1,79 % (227,44) |
| Expected payoff / Sharpe | -3,27 / -5,00 |
| Vitorias / derrotas | 34 / 3 (91,9 % de acerto) |
| Shorts / longs | **36 / 1** |

A leitura util: a expectancy e negativa **apesar** de 91,9 % de acerto. Tres derrotas
somam 356,20 e trinta e quatro vitorias somam 235,19 - o problema e a relacao
risco/retorno efectiva, nao a taxa de acerto. Qualquer mexida nesse eixo toca risco e
**nao** e decisao de agente.

---

## 6. Pedidos concretos

| Para | Pedido | Prazo sugerido |
|---|---|---|
| DELTA | remedir G8 e escrever a frase com amostra + build | antes do forward 09/11 00:05 |
| DELTA | registar G6 (`1,77 %`) como evidencia de backtest, nao como verde | antes do forward |
| DELTA | manter G5 vermelho e escalar a decisao da janela ao DONO | esta semana |
| CMD | corrigir a sonda de gateway em `dono-mandato.ps1`, `ordem-master.ps1`, `mcp-check.ps1` (P1.3488 sugerido) | antes do forward |
| CMD | identificar a origem dos 16 `[START]` das 09:34 e registar | hoje |
| CMD | commit por caminho explicito nos turnos CMD | permanente |
| DONO | decidir janela do G5 e a altura do P1.3486 | quando puder |

---

## 7. Limites deste relatorio

Nao mede lucro, nao promete resultado, nao e parecer de investimento. Um backtest de 37
trades num simbolo com um `.set` que nao replica a corrida A **nao** prova nada sobre o
futuro; prova apenas que o criterio G5, como esta escrito, nao fecha em 3 meses, e que a
frase do G8 sobre shorts nao descreve este build. **GATE_REAL 2 de 11, forward 0 de 30.**
