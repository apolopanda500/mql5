# SESSAO 2026-11-07 - DELTA (turno 2) - ADENDA 2

**Agente:** DELTA · **Hora:** 07/11/2026 16:35 (UTC-3)
Prova material das duas afirmações da ADENDA 1 e da secção 2, obtida por
inspecção dos ficheiros de gate em `Common\Files\XAU_AI_PRO`.

---

> **RETRATACAO PARCIAL (07/11 16:45 - ver ADENDA 3, seccao 1):** o ponto **A6.1**
> abaixo esta **ERRADO**. `DecisionLogDue()` (`Core/DecisionEngine.mqh:49-77`) e um
> throttle **em memoria** (`g_decLogKey[]`/`g_decLogAt[]`, `DECLOG_MAX 64`) e **nao
> escreve ficheiro nenhum** - a ausencia de `loggate_SCORE_*` e o comportamento normal
> do codigo e nao prova nada sobre execucao. O ponto **A6.2**
> (`loggate_version_1.2.184.bin` inexistente) continua **valido**, e a conclusao de
> resultado (a linha nao sai) mantem-se, provada por outro caminho na ADENDA 3.

## A6.1 Nao existe `loggate_SCORE_*` - a linha `[SCORE] CALCULATED` nunca foi impressa

O `Core/DecisionEngine.mqh` so escreve `[SCORE] CALCULATED | Symbol=...` quando
`logOnce && DecisionLogDue(symbol,"SCORE",900)`. O `DecisionLogDue` grava um
ficheiro `loggate_<tag>_<simbolo>.bin` **quando imprime**. O directoria de gates
tem ficheiros para todas as outras tags - `loggate_health.bin`,
`loggate_session.bin`, `loggate_ai_stale.bin`, `loggate_atr_*`,
`loggate_scanblock_*`, `loggate_val_*`, `loggate_version_*` - e **nao tem um
unico `loggate_SCORE_*`**.

**Conclusao:** a linha `[SCORE]` nunca foi executada nesta instalacao. Nao e um
problema de encoding, de `findstr` nem de rotacao de log: o ficheiro de gate que
a propria impressao criaria **nao existe**. Cruzado com as duas buscas da
ADENDA 1 (0 em `20261106.log` descodificado UTF-16LE, 0 no journal em 36 h),
as tres provas independentes concordam.

Consequencia directa: **o GATE_REAL G3 nao tem, hoje, instrumento de
observacao.** O patch da v1.2.184 acrescenta `PTS` a uma linha que nao sai.

## A6.2 Nao existe `loggate_version_1.2.184.bin` - o build novo nunca arrancou

Cada `OnInit` grava `loggate_version_<versao>.bin` e
`loggate_version_status_<versao>.bin`. O mais recente e:

```
loggate_version_1.2.183.bin             07/11/2026 15:59:45
loggate_version_status_1.2.183.bin      07/11/2026 15:59:45
```

Nao ha `loggate_version_1.2.184.bin` nem `..._status_1.2.184.bin`.

**Conclusao:** o `.ex5` de 16:23:11 (964056 B, MD5 `931459A3`) **nunca foi
carregado por nenhum grafico**. Isto confirma por uma terceira via independente
o que a ausencia de `[START]` ja dizia: **a v1.2.184 esta no disco, nao esta em
producao.** Falta o reattach, e o LOCK e do ALFA ate 17:01:15.

## A6.3 Um dado lateral que vale a pena guardar

Os gates mais recentes param as **16:00:24** (`loggate_health.bin`,
`loggate_session.bin`) e **15:59:45** (versao/arranque). Depois disso, nada. E
consistente com mercado fechado e sem ticks: os gates so sao tocados quando ha
actividade. Nao e defeito; e o mesmo motivo pelo qual o `[SCORE]` de hoje nao
pode ser medido.

O ultimo gate de versao as 15:59:45 e **anterior** a reconexao das 16:21:56 e das
16:23:43 - logo nenhuma dessas reconexoes provocou reinicializacao do EA, o que
esta correcto (reconexao nao e reinicio) e e o comportamento que o P1.24/D-029
pretendia.

**Assinatura: DELTA, 07/11/2026 16:35 (UTC-3) - medido. Nada assinado como
fecho de gate.**
