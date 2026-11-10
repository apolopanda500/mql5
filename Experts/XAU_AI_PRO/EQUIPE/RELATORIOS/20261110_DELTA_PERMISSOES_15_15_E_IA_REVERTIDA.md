# RELATORIO DE ESTAGIO - DELTA - 10/11/2026 10:47

**Assunto:** verificacao de `MQL_TRADE_ALLOWED` nos 15 graficos (pedido do CMD) e
descoberta de que a IA obrigatoria tinha revertido.
**Estado:** verificado e corrigido. Canal registado: **D-169** + **P1.3582 a P1.3585**.
**Binario:** intocado - `977654 B`, `MD5 71ED34C690C9593D209A69E5F0EFFB6` (v1.2.191).

---

## 1. O que foi pedido

Depois do deploy das 20:30, o ALFA/DELTA deviam confirmar `MQL_TRADE_ALLOWED=1`
nos 15 graficos e religar onde estivesse a 0 - porque o reattach por template
nao repoe o bit.

## 2. O que foi medido (e como)

O journal **nao servia**: hoje so' 5 dos 15 simbolos tinham linha `[PERM]`
(sai ~1x/hora por grafico), 5 tinham `[DIAGSCAN]` (rotativo ~5 min) e 1 o
heartbeat (so' o master do pipeline escreve).

Foi por isso criada uma sonda directa: `MQL5\Scripts\XAI_PermProbe.mq5`
(compilado 0 errors / 0 warnings, build 6314), que le o bit **no grafico onde e'
executado** e escreve uma linha em `MQL5\Files\Data\permission_probe.csv`.
Corrida nos 15 graficos por `chart_add_script`, as **10:42:53 local**
(15:42:53 servidor):

```
LIGADO=15  DESLIGADO=0  simbolos_distintos=15
AUDUSD GBPUSD NZDUSD USDBRL USDCAD USDCHF USDCLP USDCNH USDCOP
USDCZK USDJPY USDRUB USDSEK USDSGD XAUUSD
colunas: mql=1 terminal=1 account=1 expert=1 connected=1 codigo=0
```

Concorda com `system_status.json` as 15:43:08 servidor:
`ea_trade_allowed:true, trade_gate_ok:true, trade_gate_code:0` (contra
`false / 3` as 15:35:50).

**Resposta ao CMD: neste momento nao ha nada a religar - 15 de 15 ligados.**

## 3. O que apareceu no caminho - e e' P0

A IA obrigatoria (`AllowTradeWithoutAI=false`, decisao D-167) **tinha
revertido**.

| Instante | Medicao |
|---|---|
| ~10:33 | `AISWP_01..15.tpl` gravados do vivo: `false=15` |
| **10:37:07** | **15 linhas `[START]` entre 10:37:07.530 e 10:37:07.613** (XAUUSD 10:37:07.613) |
| 10:42 | `AISW_RECHECK_01.tpl` / `AISW_RECHECK_12.tpl` gravados do vivo: `AllowTradeWithoutAI=true` |

Lido: **o valor aplicado por template vive no grafico, nao no ficheiro.** No
reinicio o terminal recarrega o `.chr` do perfil e o valor volta ao que la'
estiver. E' a mesma classe de falha do bit `MQL_TRADE_ALLOWED` - estado de
sessao que nao sobrevive a reinicio, **sem erro e sem aviso**.

Custo evitado: o forward abre hoje as 15:27 servidor. Sem esta medicao, teria
comecado com IA obrigatoria e passado a correr sem ela 40 minutos depois, em
silencio, e o dossier registaria "IA obrigatoria" para um periodo que nao a teve.

## 4. Correcao aplicada - e desta vez gravada

```
1) chart_apply_template AISW_01..15        -> 15/15 graficos vivos
2) prova no vivo: AISW2_01 / AISW2_07 / AISW2_14
   -> sym=XAUUSD / USDCZK / USDRUB | AllowTradeWithoutAI=false | Magic=2026001
3) profile_add XAU_AI_PRO_15CHARTS_Q071    -> grava o perfil (.chr)
4) verificacao no disco:
   chart01..chart15.CHR  ->  TOTAL=15 false=15 true=0
```

Sem tocar no binario, sem tocar em risco, sem tocar em inputs de capital.

## 5. Regra que passa a valer

Depois de **qualquer** reinicio, a verificacao tem de ser feita **no vivo**, e o
que tem de ficar gravado e' o `.chr` (perfil), nao so' o grafico. Isto aplica-se
a verificacao pos-deploy das 20:30: confirmar o bit **e** os inputs, e regravar o
perfil se algum input tiver revertido. Declarar "esta' feito" a partir de um
template aplicado e' declarar sobre estado volatil.

## 6. Ferramenta corrigida

`EQUIPE\tools\perm-sweep.ps1` (sonda de recurso pelo journal) tinha tres
defeitos, todos corrigidos:

1. o `[PERM]` publica o bit cru (`1`=ligado) e a escala de `Core/TradeGate.mqh`
   e' o inverso (`0`=OK) - invertia o veredicto;
2. os regex do `system_status.json` falhavam pelo espaco depois dos dois pontos
   (`"trade_gate_code": 3`);
3. o journal esta' aberto em escrita pelo terminal e `ReadLines` falhava com
   "arquivo em uso" - passou a leitura partilhada (`FileShare.ReadWrite|Delete`).

## 7. O que continua de outros

| Porta | Estado | Dono |
|---|---|---|
| `[AI] GATEWAY | HTTP 1003`, corpo 0 B | IA indisponivel com o gateway de pe' | CMD / Q-021 |
| `AIAuthorityMinScore=75.0` vs ultima opiniao 62.0% | recusa | DONO |
| MTF (M15 EMA20/50) | 42 recusas em 42 sinais | DONO ("nao sei") |
| Relogio: DELTA mede servidor = local + 5h; CMD diz + 3h | por resolver | CMD |
| `GATE_REAL.md` linhas 136 / 144-145 ainda com "abre 11/11 00:05", "0 de 30" | por reescrever | CMD |
| Forward Gate corre 00:20 local - dia 1 sem medicao | por agendar hoje | CMD |

Com estas portas de pe', o numero esperado de trades continua a ser **zero** e
o forward mede pre-condicao, nao desempenho. G11 continua **0/30**.

## 8. O que o DELTA NAO fez

- nao tocou no binario nem recompilou o EA;
- nao alterou nenhum input de risco (`RiskPercent`, `MaxDailyLoss*`,
  `MaxDrawdown*`, `MaxOpenPositions`, `MinMarketScore`);
- nao desligou o MTF (o DONO respondeu "nao sei");
- nao reiniciou o gateway da IA;
- nao declarou nada no `GATE_REAL.md` (so' o CMD declara);
- nao abriu, alterou nem fechou ordens.

## 9. Fica agendado

- **Pos-deploy 20:30:** repetir `XAI_PermProbe` nos 15 e, se algum grafico
  tiver reiniciado, reconfirmar `AllowTradeWithoutAI` no vivo e regravar o
  perfil.
- O CMD deve ser informado de que a contagem diaria de `sem_permissao` que ele
  acrescentou ao `forward-gate.ps1` mede o journal, e o journal cobre 5/15 - a
  contagem e' um **minimo**, nunca o universo.
