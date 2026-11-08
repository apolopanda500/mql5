# SESSAO 2026-11-08 - ALFA (turno 2) - P1.3487 fechado e G5-G8 medidos

**Hora:** 08/11/2026 10:19 - 11:00 | **Autorizacao do DONO:** "autorizacao TOTAL" (10:20)
**Estado a entrada:** arvore limpa, HEAD `2f28cbf1`, v1.2.188, 15/15 vivos, conta demo
flat 12 636,32, LOCK livre.

## 1. O que foi feito

### a) P1.3487 - verificador do gateway (defeito real, nao era o gateway)

`EQUIPE/tools/agente-briefing.ps1` chamava `Invoke-WebRequest -SkipHttpErrorCheck`.
Esse parametro **nao existe no PowerShell 5.1** (so em PS 7+), logo a chamada lancava
excecao, o `catch` devolvia `'DOWN'` e o briefing publicava um gateway morto que
estava vivo. Nao era o `/health` o culpado desta vez: era o proprio verificador.

Correcao: funcao `Get-Gateway` - `TcpClient` em `127.0.0.1:9011` com `WaitOne(3000)`
(metodo do D-102, porque o socket do uvicorn nao aparece no CIM) e depois qualquer
resposta HTTP conta como servidor vivo.

Prova de execucao do script corrigido, 10:44:

```
HEAD            : 2f28cbf1 (main) | github/main 2f28cbf1 | sujos 13
versao          : #property 1.388 / EA 1.2.188 / EV 1.2.188
binario         : BATEM | 970168 B | 08/11 05:59:42 | MD5 943DB7CB6955
GATE_REAL       : 2 de 11
forward         : 0/30
gateway 9011    : UP (HTTP 401)
tarefas         : 4
```

Tambem no mesmo ficheiro: rodape deixou de dizer `1.386?` (versao fixa, errada) e o
cabecalho passou a declarar **3 fontes** de versao em vez de 4 - a quarta nunca foi
lida pelo script. Backup: `Files\Backup\agente-briefing.ps1.bak_p13487`.

**Autoria:** o `git add` do turno CMD (commit `86d1ac96`, 10:26) levou esta alteracao
sem registo de decisao; o D-108 regulariza.

### b) G4 - remedicao parcial (nao muda de cor)

`MQL5\Logs\20261108.log` as 10:22, janela desde 06:01 (4 h 20 min):

| Contador | Ocorrencias |
|---|---|
| `[ATR] SEM LEITURA` | 0 |
| `HANDLE MORTO` | 0 |
| `[TREND] LEITURA SUSPEITA` | 0 (278 536 antes do D-107) |
| `[START] v1.2.188` | 31 (15 as 06:01, 16 as 09:34) |

Memoria == binario `943DB7CB...`. Falta a janela de 24 h: **G4 continua vermelho**.

### c) G5-G8 - primeiro numero de um job de 3 meses

`Profiles\Tester\ALFA_G56_3M.ini` + `DELTA_186_A.set`; XAUUSD H1, `m1 ohlc`;
08/08/2026 -> 08/11/2026; deposito 12 636,32; run `7705790507266947777`;
34 min; 1434 barras; 343 991 ticks.

| Criterio | Limite | Medido | Leitura |
|---|---|---|---|
| G5 trades | >= 100 e >= 3 meses | **37** (74 deals) | VERMELHO |
| G6 MaxDD | <= 8 % | **1,77 %** / 1,79 % equity | passa no backtest |
| G7 Profit factor | >= 1,20 com >= 100 trades | **0,6603** | VERMELHO |
| G8 shorts | >= 30 % com >= 100 | **36/37 = 97,3 %** | numero passa, amostra nao |

Saldo final 12 515,31 (**-121,01**); gross 235,19 / 356,20; payoff -3,27; sharpe
-5,00; 34 vitorias / 3 derrotas; pior DD equity 227,44.

Duas conclusoes que interessam ao plano:

1. **37 trades em 3 meses** -> o criterio ">= 100 trades" precisa de ~8 meses neste
   cadence. G5 nao e fechavel na janela que ele proprio exige.
2. **G8 inverte o GATE_REAL.** O gate diz "0 shorts, estrutural em
   `SignalCore.mqh:372-375`"; este job deu 36 shorts e 1 long. Uma das duas leituras
   esta errada e quem decide e o DELTA - eu so entrego o numero e a ressalva.

Ressalvas escritas: 1 simbolo (nao 11 nem 15), `DELTA_186_A.set` nao replica a
corrida A (P1.3485), sem `WebRequest` no tester (IA = fallback), modelo `m1 ohlc`.

## 2. O que NAO foi feito

- **P1.3486 nao foi tocado.** Corrigir os comentarios `v1.2.183` / `v1.2.9` muda o
  mtime do `.mqh`, obriga a novo compile e **muda o MD5** que esta declarado para o
  forward de 09/11 00:05 (`943DB7CB...`). Fica para depois do congelamento.
- Zero reanexos, zero ordens, risco intocado (`1,0 / 10,0 / 50,0 / 2,0 / 8,0 / 10,0 / 65,0`).

## 3. Pendente / entregue

- **DELTA:** remedir G8 com este job e decidir se o "0 shorts" do GATE_REAL cai;
  registar G6 (1,77 %) como evidencia de backtest, nao como verde de forward.
- **CMD:** o cupido do `git add` apanh um ficheiro de outro agente sem decisao -
  vale a pena commitar por caminho explicito tambem nos turnos CMD.
- **DONO:** decidir a janela do G5 (>= 100 trades exige ~8 meses) e se P1.3486
  espera pelo fim do forward.

**GATE_REAL 2 de 11, forward 0 de 30. Nao existe 10/10.**
