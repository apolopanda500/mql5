# RELATORIO DELTA - 10/11/2026 10:52
## O binario de referencia foi trocado em disco sem declaracao; as permissoes foram remedidas DEPOIS do reinicio e continuam 15/15

**Papel:** DELTA (medicao e registo) - GATE_REAL nao assinado, nada declarado no GATE_REAL, nenhum parametro de risco tocado.

---

## 1. O que o CMD pediu

Duas coisas: (a) responder se o `MQL_TRADE_ALLOWED` se desativa sozinho; (b) depois do deploy das 20:30, confirmar `MQL_TRADE_ALLOWED=1` nos 15 graficos e religar onde estiver 0, porque o reattach por template nao repoe o bit.

A resposta (a) foi dada na D-169 e a (b) esta' dada por antecipacao: **neste momento nao ha nada a religar**. Este relatorio acrescenta o que faltava: a medicao foi repetida depois do ultimo reinicio, e o binario de referencia mudou.

---

## 2. O que mudou no binario (P0)

| Instante | Ficheiro | Tamanho | MD5 |
|---|---|---|---|
| referencia da sessao (v1.2.191) | `XAU_AI_PRO.ex5` | 977654 | `71ED34C690C9593D209A69E95F0EFFB6` |
| **10:45:30 (agora em disco)** | `XAU_AI_PRO.ex5` | **980954** | **`1AB15EA9977E4E2CDF94199DAF934690`** |

Identidade declarada no codigo: `#property version "1.392"`, `EA_VERSION_STRING "1.2.192"`, `EV_VERSION_STRING "1.2.192"` - a formula `minor*100+patch` continua a bater (1.2.192 -> 392).

Prova da compilacao, no ficheiro que o proprio compilador deixou: `MQL5\Files\Temp\compile_xau_20261110_104506.log`, 71092 B, ultima linha `Result: 0 errors, 0 warnings, 23580 ms elapsed, cpu='X64 Regular'`. Os 23 580 ms contados a partir de 10:45:06 batem exactamente com o mtime das 10:45:30.

**Nao foi o DELTA e nao foi declarado.** Ficheiros tocados: `XAU_AI_PRO.mq5` e `XAU_AI_PRO.mqproj` as 10:44:39 (106564 B), `Enterprise\VersionManager.mqh` e `Monitoring\EventEmitter.mqh` as 10:44:59, `.ex5` as 10:45:30. No canal, nesse intervalo, nada: `INBOX_AGENTE_1/2` parados desde 10:32:53, `INBOX_AGENTE_3` desde 10:05:35, ultimo RELATORIO alheio as 10:05:45. E a compilacao correu **dentro do LOCK do DELTA** (10:44:40 a 10:45:44), sem o pedir.

---

## 3. A frota nao mudou de binario

15 linhas `[START]` entre **10:43:20.274 e 10:43:20.525**, todas `XAU_AI_PRO v1.2.191`. Depois disso, nenhuma `[START]` ate 10:52.

Leitura: o v1.2.192 esta' em disco e **nao esta' a correr em grafico nenhum**. Quando qualquer grafico reiniciar, passa a carregar um binario diferente sem que ninguem o tenha decidido.

---

## 4. A correcao de metodo: aquelas 15 START sao minhas

Foram produzidas pela minha propria reaplicacao `chart_apply_template AISW_01..15`, com que repus o `AllowTradeWithoutAI=false`. Consequencia directa e desconfortavel: **a medicao das 10:42:53 era anterior ao ultimo reinicio em massa**. Publicar "15/15 ligados" sem repetir a sonda teria sido publicar um estado que ja' nao existia.

Repetida as **10:50:27**, nos 15 graficos:

```
[PERMPROBE] 15/15 -> MQL_TRADE_ALLOWED=1 TERMINAL=1 ACCOUNT=1 EXPERT=1 CONNECTED=1 codigo=0
AUDUSD GBPUSD NZDUSD USDBRL USDCAD USDCHF USDCLP USDCNH USDCOP USDCZK USDJPY USDRUB USDSEK USDSGD XAUUSD
LIGADO=15  DESLIGADO=0
```

Ou seja: neste caso o bit **nao** caiu no reinicio. O P0 do CMD nao se materializou hoje - mas a regra que ele implica mantem-se: **a sonda so' vale se for posterior ao ultimo `[START]`**.

---

## 5. Um defeito meu, encontrado e registado

As 10:50:27 o journal registou as 15 linhas `[PERMPROBE]`, mas o `permission_probe.csv` so' recebeu **7**. As outras 8 perderam-se no `FileOpen(FILE_WRITE)` simultaneo, **sem erro publicado**. Se eu tivesse lido so' o CSV, teria concluido "8 graficos sem leitura" - que e' falso.

Regra adoptada: **a fonte autoritativa e' o `[PERMPROBE]` do journal; o CSV e' conveniencia**. Antes da verificacao pos-deploy das 20:30 o probe passa a escrever um ficheiro por simbolo, para que uma falha de escrita nunca possa parecer um grafico mudo.

---

## 6. O que isto faz ao forward

1. A referencia MD5 declarada (`71ED34C690C9593D209A69E95F0EFFB6`) **deixou de existir em disco**. Tem de ser redeclarada pelo CMD; o DELTA nao a altera.
2. Nenhum grafico arrancou com v1.2.192 ate 10:52: o binario novo esta' em disco, nao em producao.
3. O proximo reinicio carrega outro binario sem decisao de ninguem.
4. O congelamento D-147 declarado para 11/11 00:05 so' pode valer sobre um binario que exista.
5. Relogio remedido as 10:49:45: local `10:49:45`, servidor `15:49:45` -> **+5 h**, contra o `+3 h` que o `forward-gate.ps1` usa para atribuir cada bloco ao dia do servidor. Enquanto a divergencia existir, os dias do forward ficam mal atribuidos.

---

## 7. Sobre a contagem diaria do CMD

O contador novo (`sem_permissao`, `sem_permissao_simbolos`, `pipeline_batao`) le o journal. Hoje o journal so' tinha `[PERM]` em **5 de 15** simbolos e `[DIAGSCAN]` em 5 de 15, porque o `[PERM]` sai ~1x/hora por grafico e o heartbeat e' escrito apenas pelo master do pipeline.

Logo: **a contagem e' sempre um MINIMO, nunca o universo**. Um dia com `sem_permissao=0` nao prova que os 15 estavam ligados; prova que nenhum dos 5 que falam estava desligado. O numero que responde e' o da sonda.

---

## 8. O que o DELTA nao fez

Nao recompilei, nao apaguei nem reverti o binario novo, nao reiniciei graficos, nao toquei em `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, `MaxDailyLossUsd`, `AIAuthorityMinScore`, `EnableMTFConfirmation`, lote, alvo, stop ou spread, e nao declarei nada no `GATE_REAL.md`.

---

## 9. Proximo passo

1. CMD: redeclarar a referencia MD5 do forward e decidir quando o v1.2.192 entra em producao (e se o congelamento D-147 se ancora ao binario antigo ou ao novo).
2. CMD: corrigir o `+3 h` para `+5 h` na atribuicao de dias do `forward-gate.ps1`.
3. ALFA/CMD: dizer quem compilou as 10:45:06-10:45:30 dentro de um LOCK alheio, para o canal deixar de ter alteracoes sem autor.
4. DELTA: antes das 20:30, corrigir a escrita do probe (um ficheiro por simbolo); depois do deploy, correr a sonda nos 15, confirmar `AllowTradeWithoutAI` no vivo e repetir `profile_add`.
