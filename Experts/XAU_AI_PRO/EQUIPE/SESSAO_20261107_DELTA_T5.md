# SESSAO_20261107_DELTA_T5 - v1.2.186 auditada (D-089)

Agente: DELTA (mede, contesta, assina). Turno 5.
Janela de medicao: 07/11/2026 19:29:15 a 19:32:10 (hora local).
Regra respeitada: 0 compiles, 0 reattach, 0 ordens, 0 linhas de fonte alteradas,
0 parametros de risco tocados. LOCK livre durante todo o turno.

---

## 1) Veredicto em uma linha

A v1.2.186 existe, compilou (as 19:30:46) e esta a correr em 15/15 graficos,
com as ordens C1..C5 dentro do binario e a IA real a responder ao byte; mas
**durante 2 min 11 s (19:28:35 a 19:30:46) NAO EXISTIA binario em disco**
enquanto 15 graficos apontavam para ele, e **o piso continua com 0 amostras
de producao**. Nada disto e 10/10.

---

## 2) O que mudou, item por item (reclamado -> medido)

| Item | Alegacao implicita | Medido por DELTA | Veredicto |
|---|---|---|---|
| `.ex5` novo | "v1.2.186 compilada" | **967 328 B**, 19:30:46, MD5 `10212E8702FB0A14D070240D3BA22B85` | CONFIRMADO |
| Identidade | "#property 1.386 / EA_VERSION_STRING 1.2.186" | `.ex5` version `1.386`, build_time `22:30:46Z`, compiler 6308, 323 inputs (324 params); `VersionManager.mqh:14` = `"1.2.186"`; `XAU_AI_PRO.mq5:22` = `"1.386"` | CONFIRMADO |
| Reattach | "15 graficos na versao nova" | **16** `[START] XAU_AI_PRO v1.2.186` (`MQL5\Logs\20261107.log`): 15 as 19:30:47 + XAUUSD outra vez as 19:31:06 | CONFIRMADO (16, nao 15) |
| IA real | "alimenta o EA" | `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes | disponivel=true` as **19:31:36**, 7 min depois do reattach; 14 simbolos `disponivel=false` | CONFIRMADO |
| Gateway | "9011 vivo e autenticado" | `api-probe.ps1`: raiz `401` (desenho), predicao **sem** token `401`, **com** token `HTTP 200` `available=true` `SELL 72.4` `price 4065.82` `atr 20.98` | CONFIRMADO |
| Risco | "intocado" | `.ex5` #13 `10.0`, #14 `60.0`, #15 `50.0`, #1 `2026001`, #32 `300`, #33 `600`, #189 `65.0` | CONFIRMADO |
| Conta | "plana" | 113568614 demo hedging, balance=equity **12 636,32** USD, 0 posicoes, 0 ordens | CONFIRMADO |

---

## 3) As ordens do DONO (C1..C6) dentro do binario

| Ordem | Onde | Estado medido |
|---|---|---|
| **C1 / R1** a folga respeita `EnableAdaptiveTrendGate=false` | `Filters/MarketScenario.mqh:203` (`if(!EnableAdaptiveTrendGate)` com `return(false)`) **antes** da folga em `:215` | **FEITO** |
| **C2 / R2** ATR de H1 e nao `Period()` | `:215` `if(ScenarioTrendAtrSlack > 0.0 && Period() == TrendTF)` | **FEITO, mas por regra mais estreita** (ver 4.1) |
| **C3 / R3** linha positiva no journal | `Core/ValidationEngine.mqh` imprime `[VALIDATION] TREND CONTRA OK` quando `StringFind(trendWhy,"contramao") == 0` | **FEITO no codigo**; **0 ocorrencias reais** (ver 5) |
| **C4** `AllowTradeWithoutAI` default true | input **#104** = `true` (era `false`) | **FEITO** |
| **C5** piso condicional | input **#190** `MinMarketScoreNoAI` = `45.0`; uso em `Core/DecisionEngine.mqh:748` `score<(AILeituraReal() ? MinMarketScore : MinMarketScoreNoAI)` | **FEITO** |
| **C6** alinhar `.mqproj` / `EV_VERSION_STRING` | nao medido neste turno | **PENDENTE de medicao** |

`P1.2341` (confirmar 45,0) fica respondido por medicao: o valor entregue e
45,0, e 45,0 e 79,6% do tecto tecnico sem IA (56,52), como ALFA propos.

---

## 4) Duas coisas que a versao nao diz e eu assino com ressalva

### 4.1 A folga e INERTE fora do `TrendTF`

O `:215` nao calcula o ATR de H1 e usa-o no grafico corrente: ele **so deixa
a folga existir quando `Period() == TrendTF`**. `TrendTF` = `16385` (H1).
Consequencia medida: nos 14 graficos H1 a folga existe; **no USDBRL M5 ela
nunca entra** e o portao volta ao rigor antigo. Nao e um bug de risco — e uma
decisao de desenho mais estreita do que "ATR de H1", e tem de estar escrita,
porque o Q-079 nasceu justamente de sinais vetados por TREND e o unico grafico
que nao e H1 e o que fica de fora.

### 4.2 Janela sem binario (o achado operacional do turno)

| Hora | Facto medido |
|---|---|
| 19:28:35.684 | `metaeditor.log`: `XAU_AI_PRO.mq5 - 1 errors, 0 warnings` / `compile failed` |
| 19:28:35 a 19:30:46 | **`XAU_AI_PRO.ex5` AUSENTE do disco** (`EX5: AUSENTE`) |
| 19:30:46 | `.ex5` novo 967 328 B |
| 19:30:47 | reattach 15/15 |

O erro exato do compile falhado, reproduzido por mim com `syntax_check`
(funcao de leitura, nao compila para disco):

```
error: undeclared identifier 'MinMarketScoreNoAI',
       Core\DecisionEngine.mqh(748:49)
```

Porque isto importa: `Config.mqh:1187` **declara** `input double
MinMarketScoreNoAI = 45.0;`, sem `#if` a envolve-la (o ficheiro tem
`#if*=1` e `#endif=1`, guarda `CONFIG_MQH` na linha 2), e `Config.mqh` e
incluido em `XAU_AI_PRO.mq5:33`, antes de `DecisionEngine.mqh` em `:118`.
Comparei os bytes do identificador nos dois ficheiros: `4D 69 6E 4D 61 72 6B
65 74 53 63 6F 72 65 4E 6F 41 49` (18 caracteres) **identicos**. Ou seja: a
declaracao existe, o uso e o mesmo token, a ordem de include e favoravel, e
mesmo assim o compilador recusou. Entre 19:28:35 e 19:30:46 alguem mudou algo
que nao esta registado no journal.

Nao e um detalhe de estilo: e a diferenca entre "o build falhou por um erro
trivial" e "o build falhou por uma causa que ainda nao esta explicada". A
segunda pode voltar. Abro `P1.2342` para que CMD diga, por escrito, **o que
mudou** entre os dois compiles.

E o risco pratico: durante 2 min 11 s os 15 graficos apontavam para um ficheiro
que nao existia. Um reinicio do terminal nessa janela deixava a frota sem nada
para carregar. O `.ex5` e `gitignore`-ado, portanto nem o git o protegia.

---

## 5) O que continua por medir (e por isso nao assino)

| Facto | Medicao |
|---|---|
| Amostras de producao do piso | `[SCORE]` = **0** depois dos dois builds |
| Folga exercitada | `[CENARIO]` = **0** |
| Linha positiva `TREND CONTRA OK` | **0** reais; as 4 `[VALIDATION]` do log sao do checklist de init das **14:27** |
| Mercado | `[TRADE BLOCK] COTACAO VELHA (timer) | XAUUSD | idade=91897s | limite=900s` -> sabado, sem ticks |
| Inputs vivos apos 19:30:47 | **NAO MEDIDOS** (ver 5.1) |

### 5.1 O `.CHR` mentiu outra vez

`CHART01.CHR` tem mtime **18:58:09** — anterior ao reattach — e ainda diz
`AllowTradeWithoutAI=false`, `MinMarketScore=65.0`, `AIGatewayToken=`,
`AIGatewayUrl=http://127.0.0.1:9001/...`. Nao serve como prova do que esta em
memoria. A ultima leitura viva que tenho e das 19:29, ainda em v1.2.185.

Duas possibilidades, ambas coerentes com o que medi:

1. CMD re-anexou **sem** `expert_parameters` -> valem os defaults novos
   (#104 `true`, #190 `45.0`) e as decisoes (5) e (6) do DONO estao em vigor;
2. CMD passou a lista explicita -> pode ter reposto `AllowTradeWithoutAI=false`
   e nao ter `MinMarketScoreNoAI` (a chave nao existia nos `.set` antigos).

Nao posso escolher por deducao. **Pedido a CMD**: dizer qual dos dois caminhos
foi usado e confirmar, com `list_open_charts` ou `get_expert_advisor_parameters`
do grafico anexado, os valores vivos de `AllowTradeWithoutAI`,
`MinMarketScoreNoAI`, `MinMarketScore` e `AIGatewayToken`.

---

## 6) Erro meu, corrigido no mesmo turno

Na primeira leitura vi em `Logs\20261107.log`
`19:31:02.297 web request GET ...:9011/api/ai/predict ... failed with code 401`
e ia registar "a IA caiu depois do reattach". Errado: a fonte dessa linha e
`127.0.0.1`, que e o MCP a sondar **sem** token, nao o EA. O EA respondeu
`HTTP 200` com `disponivel=true` as 19:31:36. Registo a correccao para que
ninguem persiga um 401 fantasma.

---

## 7) Falso verde na ferramenta de estado

`sync-agent.ps1 status` imprimiu, no mesmo bloco:

```
binario         : AUSENTE
binario x fonte : BATEM (nenhum .mq5/.mqh mais novo que o .ex5)
```

Um "BATEM" e impossivel quando nao ha binario: o teste e "existe algum fonte
mais novo que o `.ex5`?", e sem `.ex5` a resposta sai `BATEM`. E um **OK falso**
na ferramenta que o proprio canal usa para decidir se pode entregar. Abro
`P1.2343` para o corrigir (dono: CMD, e o dono do script).

---

## 8) Assinatura

### ASSINO

1. `XAU_AI_PRO.ex5` = **967 328 B**, 19:30:46, MD5 `10212E8702FB0A14D070240D3BA22B85`, `#property 1.386`, 323 inputs — e a v1.2.186.
2. **16** `[START] XAU_AI_PRO v1.2.186` entre 19:30:47 e 19:31:06; 15 graficos anexados.
3. `ScenarioTrendAtrSlack` #228 = `1.0` e a guarda passou para **antes** da folga (`MarketScenario.mqh:203` antes de `:215`): **R1 fechado**.
4. `AllowTradeWithoutAI` #104 = `true` e `MinMarketScoreNoAI` #190 = `45.0` existem no binario: **C4 e C5 entregues**.
5. Parametros de risco inalterados, verificados no binario novo.
6. IA real, depois do reattach: `XAUUSD 1122 B disponivel=true`, `SELL 72,35%`, `SCORE 72,40` (19:31:36); gateway autentica `200` com token e recusa `401` sem token.
7. Conta plana: 12 636,32 USD, 0 posicoes, 0 ordens.

### NAO ASSINO

1. **"a folga funciona"** — `[CENARIO]` = 0; nunca foi exercitada; e no USDBRL M5 nunca podera ser.
2. **"o piso deixa entrar os 14 simbolos"** — `[SCORE]` = 0 amostras de producao; e depende dos inputs vivos que nao consegui medir (5.1).
3. **"o build esta sob controlo"** — houve 2 min 11 s sem binario em disco e a causa da falha de compile continua **sem explicacao registada** (P1.2342).
4. Qualquer **10/10**, qualquer **GATE_REAL acima de 2 de 11**.

---

## 9) Pedidos

| Para | Pedido |
|---|---|
| **CMD** | `P1.2342`: o que mudou entre o compile falhado das 19:28:35 e o que passou as 19:30:46? Sem isso o erro pode voltar e nao sabemos por que saiu. |
| **CMD** | `P1.2343`: corrigir o `BATEM` com `.ex5` ausente no `sync-agent.ps1 status`. |
| **CMD** | Confirmar os inputs vivos dos 15 graficos (5.1) e se C6 (`.mqproj` / `EV_VERSION_STRING`) foi feito. |
| **ALFA** | Rever `MarketScenario.mqh:203-232` na forma final (guarda -> folga condicionada a `Period()==TrendTF` -> rigor antigo) e dizer se aceita a folga inerte em M5 como desenho ou se exige ATR de `TrendTF` calculado no simbolo. |
| **ALFA** | `P1.2336` e `P1.139` continuam abertos do meu lado; sem eles o `trades=0` do RESUMO e o passo 1 silencioso seguem sem prova. |
| **DONO** | A decisao (5) esta entregue como `45,0`. O (6) so produz entradas se os 15 graficos ficarem com `AllowTradeWithoutAI=true` **e** `MinMarketScoreNoAI=45.0` em memoria — confirmar isso e a diferenca entre "operar todos" e "nao operar nenhum". |

---

## 10) Estado medido as 19:32

- EA em memoria: **v1.2.186** (16 `[START]`), 15 graficos anexados.
- Binario: 967 328 B, 19:30:46, MD5 `10212E87...`.
- Fonte: 4+ ficheiros alterados desde o HEAD `90f75f7b`; worktree com 20 alterados.
- IA: `XAUUSD disponivel=true`; 14 simbolos `disponivel=false`.
- Mercado: fechado (`idade=91897s`), sem ticks -> nada a validar hoje.
- Conta: 12 636,32 USD, 0 posicoes, 0 ordens.
- `GATE_REAL`: **2 de 11**. `10/10`: **nao existe**.

---

## 11) ADENDO de fecho do turno (medido as 19:37-19:41) - tres correccoes minhas e dois achados novos

Escrevo este adendo porque, depois de fechar o corpo acima, medi mais tres coisas
que mudam o que ali esta escrito. Corrijo-me a mim e nao a ninguem.

### 11.1 Correccao minha: sao 30 `[START]` v1.2.186, nao 16

No ponto 2 e no Assino/1 escrevi **16** `[START]`. Errado por defeito. Contagem
crua no `MQL5\Logs\20261107.log` (316 168 B, 1065 linhas, UTF-16LE lido com
`[System.IO.File]::Open` + `StreamReader` Unicode):

| Marca | Ocorrencias no log de hoje |
|---|---|
| `[START] XAU_AI_PRO v1.2.186` | **30** |
| `[START] XAU_AI_PRO v1.2.185` | 15 |
| `[SCORE] CALCULATED` | **0** |
| `[CENARIO]` | **0** |
| `[VALIDATION]` | 4 (checklist de init das 14:27) |
| `[VALIDATION] TREND CONTRA OK` | **0** |
| `[AI] GATEWAY` | 98 |
| `[AI] PYTHON` | 5 |
| `[TRADE BLOCK] COTACAO VELHA` | 299 |
| `AVOID HOUR` | 0 |

As 30 dividem-se em tres vagas, e a divisao explica tudo:

| Vaga | Hora | N | Origem |
|---|---|---|---|
| A | 19:30:46.508 - 19:30:47.881 | 15 | reinicio automatico ao recompilar |
| B | 19:31:06.509 | 1 | XAUUSD outra vez (`[STOP] motivo=1` as 19:31:06.382) |
| C | 19:31:30.469 - 19:31:36.417 | 14 | reattach explicito, 7 + 7 |

Portanto o numero honesto e **30 arranques da v1.2.186 para 15 graficos**, e nao
"15/15 religados uma vez". Bate com o que o ALFA escreve no `SESSAO_..._ALFA_T5.md`
(ponto 5: 1 as 19:31:06 + 14 entre 19:31:30 e 19:31:36), e o meu "16" era so a
vaga A mais a B, medido antes de a vaga C acabar. Mantenho o fundo do ponto 2 -
a frota esta na v1.2.186 - e retiro o numero.

### 11.2 C6 ja nao e "pendente de medicao": esta FEITO

No ponto 3 deixei C6 como **PENDENTE**. Ja medi, no `git diff` do worktree:

```
XAU_AI_PRO.mqproj : -"version":"1.290" / -"description":"XAU_AI_PRO v1.2.9 ..."
                    +"version":"1.386" / +"description":"XAU_AI_PRO v1.2.186 ..."
Monitoring/EventEmitter.mqh : -#define EV_VERSION_STRING "1.2.9"
                              +#define EV_VERSION_STRING "1.2.186"
```

C6 **FEITO**: as quatro fontes de identidade concordam com o binario
(`#property 1.386`, `EA_VERSION_STRING 1.2.186`, `EV_VERSION_STRING 1.2.186`,
`.mqproj 1.386 / v1.2.186`). O `.mqproj` estava 177 versoes atras; deixa de estar.

### 11.3 O P1.2342 esta explicado por mtime, e o P1.2342 nao volta a ser misterio

No ponto 4.2 escrevi "alguem mudou algo que nao esta registado no journal".
Registei agora as horas de modificacao dos ficheiros:

| Ficheiro | mtime |
|---|---|
| compile falhado | **19:28:35.684** |
| `Core/Config.mqh` | **19:29:52** |
| `Core/DecisionEngine.mqh` | **19:30:09** |
| `.ex5` que passou | **19:30:46** |

O `Config.mqh` foi escrito **1 min 17 s DEPOIS** do compile que falhou, e o
`DecisionEngine.mqh` **1 min 34 s** depois. Ou seja: no instante do erro
`undeclared identifier 'MinMarketScoreNoAI'` a declaracao **ainda nao existia**
no ficheiro; o `:1187` que eu vi e que o ALFA cita foi escrito depois, no
intervalo de 19:29:52 a 19:30:09, e o compile das 19:30:46 ja o apanhou.

O ALFA confirma-o por escrito no `SESSAO_..._ALFA_T5.md` ponto 1: "o input nunca
chegou a `Config.mqh` ... a insercao anterior perdeu-se". Duas fontes
independentes, a mesma conclusao. **P1.2342 fecha-se por medicao** - o que
continua aberto e o facto operacional, nao a causa: durante **2 min 11 s** os 15
graficos apontavam para um `.ex5` que nao existia em disco, e o `.ex5` e
`gitignore`-ado.

### 11.4 O ponto 5.1 deixou de ser ignorancia: inputs vivos MEDIDOS

Fechei a duvida que abri no 5.1 (`.CHR` a mentir, dois caminhos possiveis) com
`list_open_charts` as **19:34**, ou seja depois do reattach das 19:31:36:

- **15 graficos** com `XAU_AI_PRO` anexado a `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`;
- nos 15, os mesmos valores vivos: `AllowTradeWithoutAI=true`,
  `MinMarketScoreNoAI=45.0`, `MinMarketScore=65.0`, `ScenarioTrendAtrSlack=1.0`,
  `EnableAdaptiveTrendGate=true`, `EnableAIFilter=true`, `BlockZeroAIScore=true`,
  `MinAIConfidence=60.0`, `AIUnavailableConfidenceCap=40.0`, `MagicNumber=2026001`,
  `MaxDailyLossPercent=10.0`, `MaxDailyLossUsd=60.0`, `MaxDrawdownPercent=50.0`,
  `MaxTotalRiskPercent=10.0`, `MaxExposurePercent=20.0`,
  `AIGatewayUrl=http://127.0.0.1:9011/api/ai/predict`, `AIGatewayToken=''`,
  `EnableAvoidHoursGMT=true`, `AvoidHoursGMT=9,11,14,18,20,22`.

O caminho 2 que eu temia (reattach com lista velha a repor `false`) **nao
aconteceu**. As decisoes (5) e (6) do DONO estao em memoria, nao so no codigo.
O `.CHR` de 18:58:09 era mesmo um documento morto.

### 11.5 Achado novo e desconfortavel: `EnableAutonomousMode=true` nos 15

`Core/Config.mqh:1164` declara `input bool EnableAutonomousMode = false;` com o
comentario "IA real: veta e exige gateway (era consultiva)". Nos **15** graficos
vivos esta **`true`**.

Isso importa porque em `AI/AIEngine.mqh`:

```mql5
bool AIGateRequired(){ if(!EnableAIFilter) return(false);
                       if(EnableAutonomousMode) return(false);
                       return(!AllowTradeWithoutAI); }
```

Com `EnableAutonomousMode=true` o portao de IA **devolve false antes de olhar
para `AllowTradeWithoutAI`**, e `FinalAIAllow()` faz `if(!AIGateRequired())
return(true)` no fim. Consequencia: neste momento a unica trava de IA que resta
e `BlockZeroAIScore` (score<=0 bloqueia). Nem a decisao (6) nem o default novo
sao o interruptor que abriu a frota - o interruptor que a abriu ja estava
ligado desde antes, e ninguem o registou como decisao.

Nao e um erro de codigo. E um facto que muda a leitura da decisao (6): "operar
todos" ja era verdade em memoria antes de o DONO a decidir, por uma via que nao
passou pelo canal. Fica escrito para que o proximo turno nao atribua a abertura
a um commit que nao a fez.

### 11.6 Achado novo: o perfil diz "15 graficos" e tem 17, dois deles vazios

`list_open_charts` devolve **17** graficos abertos do perfil
`XAU_AI_PRO_15CHARTS_Q071`: os 15 com o expert + **CHART16 e CHART17**
(`XAUUSD`, `H1`) com `"indicators": []` e **sem** expert anexado.

Duas consequencias praticas: (a) "15/15" e verdade para os que carregam o EA, mas
o perfil nao esta limpo; (b) dois graficos XAUUSD H1 em branco no mesmo perfil
sao ruido de diagnostico - quem contar `[START]` por simbolo vai ver XAUUSD
repetido e pode concluir duplicacao que nao existe.

### 11.7 O veto que vai contaminar a amostra de segunda

`ValidationEngine.mqh:296` chama `IsAvoidedHourGlobal(symbol)` e, com
`EnableAvoidHoursGMT=true` e `AvoidHoursGMT="9,11,14,18,20,22"`, **seis horas GMT
por dia** ficam vetadas para todos os simbolos. `GlobalScenario.mqh:748-784`
documenta que a lista se le em GMT e que a hora 20 do servidor (GMT+2) e GMT 18,
meio da sessao de Nova Iorque.

Hoje `AVOID HOUR` = **0** no log, mas so porque nada chega a `ValidateTrade`
(o timer bloqueia antes com `COTACAO VELHA`, 299 vezes). Na primeira janela de
mercado aberto este veto vai aparecer, e vai aparecer como causa parcial de
qualquer `[SCORE]=0` que eu venha a medir. Fica declarado **antes** da medicao,
para nao virar desculpa depois.

### 11.8 Assinatura revista (substitui o ponto 8 naquilo que ele corrige)

**Assino igualmente** os 7 pontos do corpo, com duas emendas: onde diz "16
`[START]`" leia-se **30 arranques** (15+1+14); onde diz C6 "pendente" leia-se
**FEITO**.

**Acrescento ao que assino**: os inputs vivos dos 15 graficos as 19:34 (11.4)
e o fecho do P1.2342 por mtime (11.3).

**Continuo a nao assinar**: a folga (0 `[CENARIO]`), o piso em producao
(0 `[SCORE]`), `TREND CONTRA OK` (0), e qualquer numero acima de **GATE_REAL 2 de 11**.
Nao existe 10/10; 10/10 exigiria 11 de 11, 30 dias de forward em demo e
autorizacao escrita.

- DELTA, 07/11/2026 19:41 local. 0 compiles, 0 reattach, 0 ordens, 0 linhas de
  fonte alteradas, 0 parametros de risco tocados neste turno.

---

## 12) Sincronizacao do canal (19:37-19:42) - 9 problemas medidos, 8 corrigidos, 1 fica para o ALFA

Chamado a sincronizar tudo, corri `sync-agent.ps1 check` e ele devolveu
**9 problemas**. Nenhum era meu, todos eram de encoding. Medi-os byte a byte
antes de tocar em nada.

| Ficheiro | Defeito medido | Accao |
|---|---|---|
| `DECISOES.md`, `IDS.md`, `INBOX_AGENTE_2.md`, `INBOX_AGENTE_3.md`, `INBOX_DONO.md`, `PRESENCA.md`, `SYNC_LOG.md` | **3 CR** cada, sempre no mesmo padrao `<LF><CR><LF>` - um CR solto antes do LF, em tres fronteiras de bloco | removidos mecanicanamente (só o byte 13, mais nada) |
| `SESSAO_20261107_ALFA_T5.md` | **BOM UTF-8** (239,187,191) + 1 CR final | BOM e CR removidos; **texto do ALFA nao foi tocado** |

Byte a byte: 321902 -> 321899, 19744 -> 19741, 112972 -> 112969, 163912 ->
163909, 116584 -> 116581, 17062 -> 17059, 55551 -> 55548. Em cada caso o
delta e **exactamente** o numero de CR removidos - prova de que nada mais
mudou. O `SESSAO_ALFA_T5` foi de 6323 -> 6319 B (3 do BOM + 1 do CR).

Depois: `sync-agent.ps1 check` -> **RESULTADO: OK - sem problemas detectados**.
`equipe-audit.ps1` -> **`[OK] todos os ficheiros do canal sao UTF-8 valido`**,
`RESULTADO: ok`, 11 ficheiros medidos com **CR=0** em todos.

O padrao `<LF><CR><LF>` em tres pontos de cada bloco nao e aleatorio: e o
mesmo defeito de origem do caso `d080_alfa.txt` (string vinda do Windows a
entrar num ficheiro que o canal exige LF puro). Fica aberto como **P1.2344**
para o CMD, dono do `sync-agent.ps1`: o `post` esta a introduzir CR em tres
posicoes e o `check` so o detecta depois.

Fica aberto tambem o que **nao** corrigi, porque nao e meu para corrigir:

1. **D-089 duplicado.** Reservei D-089 as 19:32 (`IDS.md`, dono `sistema`) e
   publiquei as 19:38. O bloco do ALFA, escrito as 19:40, usa o **mesmo
   numero** e esta em 7 ficheiros. Um dos dois tem de passar a D-090. Nao
   renumero texto de outro agente: proponho que o ALFA decida e execute.
2. **A linha do ledger do D-089 continua vazia.**
   `USADO | D | D-089 | sistema | 07/11/2026 19:32:10 |` sem texto, enquanto
   o corpo do ALFA entrou como prosa em `IDS.md` (que e o ledger, nao o
   mural). O `post` reserva o ID mas nao o preenche, e escreve o corpo no
   ficheiro errado. Mesmo P1.2344.
3. `IDS.md`: **84 linhas no ledger para 77 IDs usados** - 7 IDs reservados e
   nunca usados. Nao apaguei nenhum.

- DELTA, 07/11/2026 19:42 local. Neste bloco de sincronizacao: 0 compiles,
  0 reattach, 0 ordens, 0 linhas de fonte alteradas, 0 parametros de risco
  tocados. Alterados por mim: apenas fim-de-linha e BOM dos 8 ficheiros de
  canal acima, com o LOCK tomado e liberto (pegar 19:39 / liberar 19:39).
