# SESSAO 2026-11-07 - DELTA (turno 2)

**Agente:** DELTA (mede, contesta, assina)
**Janela:** 07/11/2026 16:10 - 16:32 (hora local do terminal, UTC-3)
**Regra aplicada:** D-069 / "quem faz nao assina". Nada abaixo e assinatura de gate.
**Estado do canal no inicio:** LOCK do CMD (merge B) expirou as 16:21:00; as
16:21:15 o ALFA tomou o LOCK (`P1.138/G3: normalizacao do MarketScore -
compile unico da v1.2.184`, TTL 40 min, expira 17:01:15). DELTA nao compilou
e nao escreveu codigo-fonte neste turno.

---

## 1. Terminal e conta (medido agora, nao herdado)

- Conta **113568614** (MetaQuotes-Demo, hedging, build 6308): balance
  **12636.32**, equity **12636.32**, margin 0.00, free margin 12636.32.
- **0 posicoes, 0 ordens.** Nada foi aberto, fechado ou modificado por mim.
- `experts_trade_allowed=true`, `mcp_trade_allowed=true`.

### 1.1 Duas desconexoes reais do servidor, medidas (nao simuladas)

Journal do terminal:

```
16:21:43.485  Network  '113568614': connection to MetaQuotes-Demo lost
16:21:56.967  Network  '113568614': authorized ... Access Point BR 1 (ping 233.51 ms)
16:22:30.964  Network  '113568614': connection to MetaQuotes-Demo lost
16:23:43.088  Network  '113568614': authorized ... Access Point US 1 (ping 229.67 ms)
```

Os 15 graficos reagiram no mesmo segundo, um por instancia:

```
16:21:45.829 .. 16:21:46.209  XAU_AI_PRO (...)
[CIRCUIT] BROKER INSTAVEL | leituras=1 | 0s | carencia de start |
aguardando confirmacao (nao bloqueia)
```

**O que isto prova:** o caminho de resiliencia a desconexao do broker existe e
dispara em 15 de 15 instancias, com mensagem explicita e sem bloquear. **O que
isto NAO prova:** nao substitui o cenario "desconexao" do GATE F2, porque nao
havia posicao aberta, o mercado estava fechado e nao houve fecho/retoma
observavel. Fica como **observacao positiva nao assinada**.

`retransmit_percent=1.86` e ping ~230 ms: o link para o servidor esta instavel
hoje, e isso e relevante para qualquer prova futura baseada em ticks.

---

## 2. Binario: o que esta no disco e o que esta EM EXECUCAO

| | Versao | Evidencia |
|---|---|---|
| Fonte (`#property version`) | **1.384** | `XAU_AI_PRO.mq5:22`, mtime 16:19:21 |
| Fonte (`EA_VERSION_STRING`) | **1.2.184** | `Enterprise/VersionManager.mqh:14`, mtime 16:19:29 |
| `.ex5` no disco | **1.2.184** | 964056 B, mtime **16:23:11**, MD5 `931459A39634DD7A95ED1EA74D412FC4` |
| Em execucao nos 15 graficos | **1.2.183** | ultimo `[START] XAU_AI_PRO v1.2.183`, 14:36:56 |

**Nao houve reattach.** A janela 16:21:00-16:28:00 do journal do EA tem
exactamente 15 registos, todos `[CIRCUIT] BROKER INSTAVEL`, e **zero `[START]`**.
O `[CIRCUIT]` das 16:21:45 explica-se pela perda de ligacao das 16:21:43, nao por
arranque.

**Consequencia operacional:** o P1.138/G3 esta compilado mas **nao esta em
producao**. Qualquer texto que diga "v1.2.184 publicado nos 15 graficos" e
falso neste instante - falta o reattach, que exige o LOCK.

---

## 3. HG-01 fechado na v1.2.184, mas HG-01b / D-074 SOBREVIVEU ao compile

ALFA subiu a identidade para 1.384 / 1.2.184 de forma coerente
(`minor*100+patch` = `2*100+184` = 384). **HG-01 esta fechado para esta versao.**

O que **nao** foi corrigido:

```
Monitoring/EventEmitter.mqh:77      #define EV_VERSION_STRING "1.2.9"
Monitoring/EventEmitter.mqh:233     "EA inicializado " EV_VERSION_STRING, extra, "ONLINE");
```

Com o produto em **1.2.184**, esta terceira fonte esta agora **175 versoes
atras**. O changelog da v1.2.184 nao a menciona.

### 3.1 Censo completo: cinco fontes de identidade, nao tres

Medido em todos os `.mq5`/`.mqh` da arvore:

| # | Ficheiro:linha | Declaracao | Veredicto |
|---|---|---|---|
| 1 | `Enterprise/VersionManager.mqh:14` | `#define EA_VERSION_STRING "1.2.184"` | **correcta** |
| 2 | `XAU_AI_PRO.mq5:22` | `#property version "1.384"` | **correcta** |
| 3 | `Monitoring/EventEmitter.mqh:77` | `#define EV_VERSION_STRING "1.2.9"` | **errada e viva** |
| 4 | `Monitoring/ProductionChecklist.mqh:8` | `#property version "1.290"` | errada, **inerte** |
| 5 | `Monitoring/ValidationChecklist.mqh:9` | `#property version "1.290"` | errada, **inerte** |

As duas `#property` dentro de `#include` sao inertes: o compilador aplica apenas
as propriedades do ficheiro principal, portanto nao chegam ao `.ex5`. Sao
divida cosmetica, nao defeito de binario.

Ha ainda tres cabecalhos de comentario a dizer `v1.2.9`
(`Core/Config.mqh:1`, `Monitoring/EventEmitter.mqh:3`, `Enterprise/VersionManager.mqh:1`)
e `AI/AILearningMemory.mqh:1`.

### 3.2 Achado novo: `EV_VERSION_STRING` tem DOIS consumidores, nao um

O canal tinha registado um consumidor (a linha de journal). Sao dois:

```
Integration/ExternalBridge.mqh:89   #ifdef EV_VERSION_STRING
Integration/ExternalBridge.mqh:90   return EV_VERSION_STRING;      // EB_Version()
Monitoring/EventEmitter.mqh:233     "EA inicializado " EV_VERSION_STRING
```

`EB_Version()` publica a versao num **ficheiro lido pela app / ponte externa**.
Nao e uma linha de log que se ignora: e um canal legivel por maquina a
declarar **1.2.9** como versao do EA. Isto eleva a severidade do D-074.

### 3.3 Causa estrutural (porque e que o literal duplicado nasceu)

Ordem real dos includes no `XAU_AI_PRO.mq5`:

```
32:  #include "Core/Config.mqh"
50:  #include "Monitoring/EventEmitter.mqh"     <-- usa a versao aqui
...
201: #include "Enterprise/VersionManager.mqh"   <-- define a versao aqui
```

Quando o `EventEmitter` e compilado, `EA_VERSION_STRING` ainda **nao existe**.
O literal foi duplicado para resolver isso - e a partir daí ninguem o voltou a
subir. **Qualquer correcao tem de colocar a identidade canónica antes da linha
50**, senao o mesmo problema volta na proxima versao.

### 3.4 Proposta para o ALFA (nao implementada por mim)

Uma fonte unica num ficheiro incluido antes de `Core/Config.mqh` (linha 32),
com o alias historico preservado para nao partir o `ExternalBridge`:

```
#define EA_VERSION_STRING "1.2.184"       // UNICO literal da arvore
#define EV_VERSION_STRING EA_VERSION_STRING   // alias, mesmo valor
```

e nos tres sitios actuais (`VersionManager:14`, `EventEmitter:77`, e o
`.mq5`) passa a haver `#ifndef` em vez de literal. Assim o `EV_VERSION_STRING`
do `ExternalBridge` deixa de poder divergir por construcao. Fica ao criterio do
ALFA a forma final; o que peço e que **a proxima versao nao volte a ter dois
literais**.

---

## 4. Verificacao independente do P1.138 / GATE_REAL G3 (v1.2.184)

O changelog (`VersionManager.mqh:63`) afirma tres coisas. Verifiquei as tres no
codigo, nao no texto.

### 4.1 A base 50.0 saiu mesmo - CONFIRMADO

`Core/DecisionEngine.mqh:196-202`:

```
// v1.2.184 (P1.138) - G3: sem base arbitraria. ...
double score=0.0;
```

Confirmado `0.0`, e nao `50.0`.

### 4.2 A normalizacao e a fraccao dos pontos possiveis - CONFIRMADO

`Core/DecisionEngine.mqh:471-486`:

```
const double maxScorePoints=115.0;
double scorePoints=score;
score = 100.0 * score / maxScorePoints;
if(score>100.0) score=100.0;
if(score<0.0)   score=0.0;
MarketScore = NormalizeDouble(score,2);
```

Aritmetica do changelog verificada, parcela a parcela:
`20 (EMA) + 15 (RSI) + 15 (ADX) + 10 (KCI dir) + 5 (KCI vol) + 50 (IA a 100%) = 115` ✔

- Sem IA: `(20+15+15)/115*100 = 43.478` -> changelog diz **43.48** ✔
- IA a 72.4%: `(50 + 0.5*72.4)/115*100 = 86.2/115*100 = 74.956` -> changelog diz
  **74.9**. E **truncamento**, nao arredondamento (74.96 arredondaria a 75.0).
  Divergencia de 0.06 pontos, sem efeito pratico, mas fica registada.

### 4.3 O piso `MinMarketScore=65.0` continua a filtrar? MEDIDO COM OS LIMITES DO APRENDIZADO

Este e o ponto que o changelog **nao cobre** e onde eu esperava encontrar uma
brecha. O `DecisionEngine.mqh:503` aplica `LearningAdjustedScore()` **depois** da
normalizacao e do clamp, e o `[SCORE]` publica o valor **pos-aprendizado**. Se os
multiplicadores do aprendizado fossem livres, o piso voltava a ser decorativo.

Limites medidos, um por um:

| Multiplicador | Ficheiro:linha | Maximo |
|---|---|---|
| `MemoryBoost` | `AI/AILearningMemory.mqh:154-191` | **1.25** (memoryStrength >= 20) |
| `DirBoost` | `AI/LearningHistory.mqh:220-240` | **1.10** (WR direccional >= 70%) |
| `LearningHourScoreFactor` -> `HourBoost` | `AI/LearningHistory.mqh:1053-1081`, `338-358` | **1.08** (WR da hora >= 70%) |

Produto maximo teorico: `1.25 * 1.10 * 1.08 = 1.485`

Resgate maximo de um sinal **sem IA e sem KCI**:
`43.478 * 1.485 = 64.57`  **< 65.0**

**Veredicto:** o piso **filtra de facto**. Um sinal que so tenha EMA+RSI+ADX e
recusado mesmo no melhor caso possivel de memoria, direccao e hora - falha por
**0.43 pontos**. Para passar sem IA e preciso pelo menos um componente KCI:
`(50+10)/115*100 = 52.17`, e `52.17 * 1.485 = 77.5`.

`LearningAdjustedScore` tem clamp proprio a 0..100 (`LearningHistory.mqh:1107-1111`),
logo o produto nao pode estourar acima de 100 nem descer abaixo de 0.

**Assinatura do G3: NAO.** O que assino e que a correcao faz o que diz e que o
piso passou a morder. O G3 do GATE_REAL exige prova em **journal de producao** -
linhas `[SCORE]` com `PTS` e `TOTAL` a mostrarem dispersao real - e isso nao
existe ainda: o build **nao esta reattachado** e o mercado esta fechado.
Nenhuma linha `[SCORE]` nova foi produzida depois das 16:23:11.

### 4.4 Objeccao que deixo escrita (para o ALFA)

A margem de 0.43 pontos do 4.3 e **fina por construcao**: resulta de os pesos do
aprendizado terem sido calibrados para uma escala em que o score saturava em
100. Agora que a escala e 0..100 sobre 115 pontos, o aprendizado vale
relativamente **mais**. Se alguem subir `MemoryBoost` para 1.30, ou o piso da
hora, o sinal so-EMA+RSI+ADX passa a passar com `43.478*1.544=67.1` e o G3 volta
a morrer em silencio. Nao peço alteracao agora; peço que o proximo a mexer nos
multiplicadores saiba que **1.495 e o limite**: acima disso o piso deixa de
filtrar sinais sem IA.

---

## 5. GATE_REAL: continua 1 verde de 11

Nada mudou. G3 e exactamente um dos vermelhos, e o patch que o endereça **nao
esta em execucao**. Nao escrevo 10/10, nao assino gate, nao declaro pronto.

---

## 6. Pendencias que este turno fecha e as que abre

**Fechadas por medicao (sem escrever codigo):**
- Item (a) do `INBOX_AGENTE_1.md` ("alinhar HG-01 e escrever a entrada v1.2.183
  no changelog"): **cumprido** - entrada v1.2.183 na linha 64 e v1.2.184 na 63.
- Verificacao independente do P1.138: feita, com limites do aprendizado medidos
  pela primeira vez.

**Abertas (com dono):**
- **ALFA** - HG-01b/D-074 sobreviveu a v1.2.184; ver 3.3/3.4. Sao agora **175**
  versoes de deriva, com consumidor legivel por maquina.
- **ALFA** - falta o **reattach** dos 15 graficos para a v1.2.184 sair do disco
  e entrar em producao (precisa do LOCK, que e dele ate 17:01:15).
- **ALFA** - a linha 74.9 vs 74.96 (truncamento documentado ao contrario).
- **CMD** - espelho `VERSION` em `MQL5/Files/XAU_AI_PRO/VERSION` diz **1.2.181**
  contra EA **1.2.184** (medido: `type VERSION` -> `1.2.181`).
- **CMD** - commit dos documentos do canal e dos ficheiros de codigo.
- **DONO / todos** - GATE_REAL G1, G3..G11 seguem vermelhos; janela forward de
  30 dias nao arrancou.

---

## 7. Disciplina deste turno

- 0 compiles, 0 reattach, 0 ordens, 0 alteracoes de parametro de risco.
- Nenhum ficheiro de codigo-fonte foi tocado (LOCK do ALFA respeitado a partir
  das 16:21:15; escrevi apenas este documento e a caixa do canal, via Mutex).
- Nenhum texto de "10/10" foi escrito, nem aqui nem no canal.

**Assinatura: DELTA, 07/11/2026 16:32 (UTC-3) - medido. Nada assinado como
fecho de gate.**
