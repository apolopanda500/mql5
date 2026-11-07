# SESSAO 2026-11-07 - DELTA - TURNO 2 - ADENDA 3

**Assunto:** B-nova fechado — porque e que `[SCORE] CALCULATED` nunca imprime.
**Autor:** DELTA (mede e assina; nao edita codigo)
**Hora:** 07/11/2026 16:45 (local)
**Estado do LOCK:** OCUPADO por ALFA (16:21:15 -> 17:01:15). Neste turno: **0 compiles,
0 reattach, 0 ordens, 0 ficheiros de codigo-fonte tocados.**

---

## 1. Retratacao expressa da ADENDA 2 (ponto A6.1)

A ADENDA 2 afirmou que "nao existe nenhum `loggate_SCORE_*.bin`" provava que a linha
`[SCORE] CALCULATED` nunca foi executada. **A inferencia e invalida e fica retratada.**

Medido em `Core/DecisionEngine.mqh:49-77`: `DecisionLogDue()` e um throttle **em memoria**
(`g_decLogKey[]` / `g_decLogAt[]`, `DECLOG_MAX = 64`). Nao abre, nao le e nao escreve
ficheiro nenhum. A ausencia de `loggate_SCORE_*` e o comportamento normal do codigo e
nao prova nada sobre execucao.

O ponto A6.2 da mesma adenda (`loggate_version_1.2.184.bin` inexistente; ultima e
`1.2.183` as 15:59:45) **mantem-se valido** como indicio do nao-deploy, e nao depende
desta inferencia.

A conclusao da ADENDA 2 sobre o *resultado* (a linha nao sai) continua correta — mas
passa a estar provada por outro caminho, o do ponto 3 abaixo.

---

## 2. Objeto e metodo

Pergunta: porque e que `[SCORE] CALCULATED` (DecisionEngine.mqh:533) praticamente nunca
aparece no journal?

Metodo: leitura do codigo da cadeia de decisao + contagem no journal de producao
(`MQL5/Logs/20261105.log` e `20261106.log`, decodificados como UTF-16LE) e no
`[SCANNER] RESUMO`, que publica por janela a contagem de cada balde de saida.

Fonte de verdade usada: os **64 baldes** de `[SCANNER] RESUMO` de 05/11, somados.

---

## 3. Funil medido — 05/11 (dia completo, 64 janelas publicadas)

| Etapa | Contagem | Nota |
|---|---:|---|
| visitas (simbolo x ciclo) | 18 375 | |
| **Stale** (preco morto) | 4 966 | 27,0% das visitas |
| **NoSignal** (`GetCombinedSignal` == 0) | 11 833 | 64,4% das visitas |
| **sinais** (sinal composto != 0) | **1 576** | 8,6% das visitas |
| **AllowTrade** (entrou em `AllowTradeEx`) | **1 576** | **100,00% dos sinais** |
| **trades** | **0** | **zero no dia inteiro** |
| DirHist | 0 | |
| Cooldown | 0 | |
| JaNegociado | 0 | |
| ExecFail | 0 | |

Leitura direta: **`AllowTrade == sinais` em 64 de 64 janelas.** Nao houve um unico
sinal que passasse de `AllowTradeEx`. E `trades = 0` em 64 de 64 janelas.

O `[SCANNER] RESUMO` prova tambem que a infraestrutura de leitura do sinal esta sã:
`SIG(sem/neutro) = 0 / 6420` na ultima janela e `0` em **todas** as 64 janelas para o
campo `sem` (falhas de leitura). O `GetSignal` le tudo; quem recusa e a regra.

---

## 4. A causa — o passo 1 de `AllowTradeEx` e mudo

`Core/DecisionEngine.mqh:629-643`:

```mql5
g_validationLastBlock="";

if(!ValidateTrade(symbol, signal))
{
   reason = "VALIDATION: " + ((g_validationLastBlock=="")?"sem detalhe":g_validationLastBlock);

   return false;          // <-- nenhum Print
}
```

Todos os outros passos de `AllowTradeEx` (NEWS, MARKET INTEL, score, IA) imprimem
`DECISION BLOCKED | ...`. **O passo 1 nao imprime nada.** O motivo existe apenas em
`reason`, que o chamador (`MarketScanner.mqh:724-731`) so publica dentro de
`ScanBlock(SCAN_ALLOW_TRADE, ...)`, que exige `EnableVerboseDebug` e passa pelo
`DiagGateAllow` de 1800 s.

Consequencia medida: **`DECISION BLOCKED` = 0 linhas em 05/11 e 0 em 06/11**, com
1 576 sinais recusados. A recusa nao deixa rasto na tag que o operador filtra.

O rasto existe noutra tag — `[VALIDATION] BLOCK`, com portao de 5 min por conta e por
simbolo, portanto uma amostra:

| Motivo do veto | Linhas 05/11 | % |
|---|---:|---:|
| `TREND SELL` | 85 | 30,1% |
| `TREND BUY` | 80 | 28,4% |
| `ADX` | 46 | 16,3% |
| `AI` | 36 | 12,8% |
| `AVOID HOUR` | 35 | 12,4% |
| **Total `[VALIDATION] BLOCK`** | **282** | 100% |

**Os dois motivos de tendencia somam 165 de 282 = 58,5% de todos os vetos.**

---

## 5. A contradicao estrutural (o achado do turno)

As duas regras que decidem a mesma coisa usam definicoes de "tendencia" **diferentes e
incompativeis**:

**Sinal** (`Core/SignalCore.mqh:360-363`, handles em `:110-112`):

```mql5
if(fast[1]>slow[1] && rsi[1]<RSIPullbackBuy && rsi[1]>rsi[2])
   sinalLocal = 1;
```

- BUY: `EMA50 > EMA200` em `PERIOD_CURRENT` (graficos H1) **e** `RSI[1] < 45` **e** `RSI[1] > RSI[2]`
- SELL: `EMA50 < EMA200` **e** `RSI[1] > 55` **e** `RSI[1] < RSI[2]`

**Portao** (`Filters/MarketScenario.mqh:168-240` + `Filters/TrendFilter.mqh:309-330`):

```mql5
bool alinhado = (signal == 1) ? TrendBuy(symbol) : TrendSell(symbol);
...
return (bid > ema);   // ema = iMA(symbol, TrendTF=PERIOD_H1, 200, MODE_EMA)
```

- "alinhado" = **`bid > EMA200(H1)`** — preco acima da ancora, nada sobre EMA50.

As duas condicoes nao sao a mesma coisa. Pior: **opõem-se exactamente no caso que a
regra de entrada procura.** A regra quer um *pullback fundo* (`RSI < 45`). Num pullback
fundo o `bid` cai abaixo da EMA200 H1 enquanto a EMA50 (que tem 50 barras de memoria)
ainda esta acima da EMA200. Nesse instante:

- o sinal diz BUY (EMA50 > EMA200, RSI<45 a virar);
- o portao diz "contramao vetada | tendencia formada" porque `bid < EMA200`.

Quanto melhor o pullback pela regra de entrada, mais provavel o veto. Os 165 vetos de
tendencia medidos sao essa assimetria a acontecer em producao.

---

## 6. Consequencia para o GATE_REAL G3 — muda a natureza do bloqueio

`CalculateMarketScore` so e chamado em `DecisionEngine.mqh:737`, **passo 3** de
`AllowTradeEx`. Como 100% dos sinais morrem no **passo 1**, o passo 3 nunca corre.

Logo `[SCORE] CALCULATED` nao sai, e o P1.138 (normalizacao `100*score/115`) fica
**sem instrumento de verificacao em producao**.

Isto e mais forte do que o relatado no turno anterior. Nao e "falta o reattach da
v1.2.184": mesmo com o reattach feito, **o G3 continua inobservavel** enquanto o
`ValidateTrade` recusar todos os sinais. Corrigir a normalizacao sem corrigir o funil
produz um numero que ninguem consegue medir.

Ordem correta de trabalho: **funil primeiro, score depois.**

---

## 7. Achado lateral: 06/11 nao teve dia

| Metrica | 05/11 | 06/11 |
|---|---:|---:|
| `[SCANNER] RESUMO` | 64 | **0** |
| `[VALIDATION]` | 459 | 7 |
| `[SIGNAL] BUY/SELL` | 53 | 69 |
| `[SCORE] CALCULATED` | 1 | 0 |
| `[START]` | — | **292** |

292 `[START]` em 06/11 contra **zero** janelas `[SCANNER] RESUMO`: o dia foi consumido
por reinicializacoes e nunca chegou a formar uma janela estavel de 15 min. Sem janela
nao ha RESUMO, e sem RESUMO nao ha medicao. 06/11 **nao serve como dia de referencia**
para nenhuma prova — e o unico dia em que seria possivel comparar antes/depois do
P1.138.

---

## 8. Propostas (dono ALFA; nao toquei em codigo)

1. **P1.139 (impressao, sem risco de logica):** o passo 1 de `AllowTradeEx` passa a
   imprimir `DECISION BLOCKED | VALIDATION | Symbol=... | Reason=...` pelo mesmo
   `allowLogOnce` dos outros passos. Sem isto, 58,5% dos vetos do EA ficam fora da tag
   que o operador filtra. Custo: ~1 linha/min por instancia, ja limitado pelo portao.
2. **Q-079 (decisao de desenho, aberta ao DONO as 16:47):** as duas definicoes de tendencia tem de
   ser uma so. Tres saidas possiveis, todas explicitas:
   - (a) o portao passa a ler a MESMA condicao do sinal (`EMA50 vs EMA200`), e o
     pullback deixa de ser "contramao";
   - (b) o portao mantem `bid vs EMA200`, mas com folga (ex.: 1 ATR), para o pullback
     fundo nao ser classificado como reversao;
   - (c) a regra de entrada passa a exigir `bid > EMA200`, e o pullback fundo deixa de
     gerar sinal.
   Sem escolha explicita, o EA continua a gerar sinais que ele proprio veta.
3. **Pre-requisito do G3:** nao pedir assinatura de G3 antes do funil ter passado pelo
   passo 3 pelo menos uma vez em producao, com `[SCORE] ... PTS=` no journal.

---

## 9. O que este turno NAO assina

- **G3 / P1.138:** nao assinado. A normalizacao esta correta por aritmetica (verificado
  no turno 2: 20+15+15+10+5+50 = 115; 43,478 sem IA; 74,956 a 72,4%), mas e
  inobservavel em producao por ausencia de sinal sobrevivente.
- **GATE_REAL:** mantem-se **1 verde de 11** (so G2). Nao escrevi, e nao escreverei,
  "10/10" enquanto o GATE_REAL nao estiver 11 de 11.
- **Os 165 vetos de tendencia:** medidos, nao interpretados como defeito ate o DONO
  escolher uma das saidas da Q-079. Podem ser o desenho pretendido (operar so a favor
  da EMA200); nesse caso o defeito esta na regra de sinal, nao no portao.

---

## 10. Ficheiros temporarios

`MQL5/Files/Temp/probe_sinal.ps1`, `probe_resumo.ps1`, `probe_serie.ps1`,
`probe_val.ps1`, `probe_soma.ps1` — apagados no fim do turno.
