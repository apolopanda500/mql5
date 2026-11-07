# SESSAO 07/11/2026 - ALFA turno 3 - REVISAO INDEPENDENTE DA v1.2.185 (Q-079 = B)

- **Papel:** ALFA (lider, revisao de codigo; nao faz commit nem push)
- **Pedido:** ler as ultimas alteracoes e sincronizar com os outros agentes
- **Alvo da revisao:** CMD turno 6 / D-084 + D-085 - v1.2.185, Q-079 = B
- **Estado do LOCK:** LIVRE desde 07/11 19:00:41 (li antes de escrever)
- **Conta 113568614:** 0 posicoes, 0 ordens, equity 12 636,32 - intocada
- **GATE_REAL:** 2 de 11 (nao muda com esta revisao)

---

## 1. O que eu li (e nao apenas aceitei)

| Fonte | O que confirmei |
|---|---|
| `Filters/MarketScenario.mqh:168-260` | `ScenarioTrendGate` inteiro, incluindo o bloco novo da folga (199-222) |
| `Core/Config.mqh:1509-1515` | comentario D-079 + `input double ScenarioTrendAtrSlack = 1.0` |
| `Core/ValidationEngine.mqh:325-375` | **unico** chamador do gate e o que ele imprime em caso de passagem |
| `Filters/TrendFilter.mqh` | `TrendBuy/TrendSell/GetTrendEMA`, EMA 200 em `TrendTF` (H1) |
| `Indicators/VolatilityFilter.mqh:408-422, 630, 661, 764` | `GetATR` usa `(ENUM_TIMEFRAMES)Period()` - **periodo do grafico**, nao H1 |
| `.ex5` vivo (964 998 B, 1.385, build 6308) | 322 inputs; `#227 ScenarioTrendAtrSlack = 1.0`; `#261 TrendTF = 16385 (H1)`; piso 65; 10/60/50 %; magic 2026001 |
| Journal do expert 18:58-19:06 | `Q-079/B` = **0** ocorrencias; `TREND CONTRA OK` = **0** ocorrencias |
| `EQUIPE/GATE_REAL.md` | 2 verdes de 11, medido 07/11 17:56 |

---

## 2. VEREDICTO

**ACEITE TECNICO COM 3 RESSALVAS.** A v1.2.185 faz o que a Q-079 = B pediu, nao
mexe em risco e e reversivel por input. Nenhuma das ressalvas bloqueia a
permanencia em demo; a **R1** tem de ser decidida antes de qualquer conta real,
porque altera o significado de um input de direcao.

### 2.1 O que esta CORRETO (confirmado, nao presumido)

- **C1 - criterio antigo primeiro.** O portao continua a testar
  `bid > EMA200` (BUY) / `bid < EMA200` (SELL). A folga so e avaliada quando o
  sinal esta **contra** a EMA.
- **C2 - reversivel sem tocar em codigo.** O bloco esta dentro de
  `if(ScenarioTrendAtrSlack > 0.0)`. Com `0.0` o comportamento e exactamente o
  anterior (veto de contramao pelo rigor antigo).
- **C3 - a guarda nao foi apagada.** Acima da folga continuam, na ordem:
  `EnableAdaptiveTrendGate=false` -> veto; `adx <= 0` -> veto; `adx >= 22`
  (`ScenarioCounterTrendMaxADX`) -> veto; `SCENARIO_VOLATILE` -> veto. Nada foi
  afrouxado fora da banda.
- **C4 - sem leitura, rigor antigo.** A condicao
  `if(GetTrendEMA(emaRef, symbol) && bidRef > 0.0 && atrRef > 0.0)` falha quando
  falta EMA ou ATR (`GetATR` devolve `0.0` no ramo sem serie/handle) e o fluxo cai
  no bloco antigo. Nao ha caminho em que a ausencia de dado **aprove**.
- **C5 - risco intocado.** Nenhuma escrita em lote, SL, TP, `MaxTotalRiskPercent`
  ou envelope dentro do bloco. `ScenarioLotFactor` e o envelope continuam a
  mandar. O binario confirma 10/60/50 %, piso 65, magic 2026001, 322 inputs.
- **C6 - simetria correta para o defeito.** `MathAbs(bid - EMA) <= folga` aceita
  BUY ate 1 ATR **abaixo** da EMA e SELL ate 1 ATR **acima** - que e exactamente
  o pullback fundo que a regra de entrada (EMA50 > EMA200 + RSI < 45) procura.
- **C7 - auditavel quando dispara.** O `reason` publica
  `dist=`, `ATR=` e o selo `Q-079/B`.
- **C8 - um unico chamador.** `ValidationEngine.mqh:345`, dentro de
  `if(EnableTrendFilter)`. Sem chamadas paralelas nem duplicacao de leitura.

### 2.2 R1 (ALTA) - a folga passa por cima de `EnableAdaptiveTrendGate = false`

O bloco da folga esta **antes** de `if(!EnableAdaptiveTrendGate)`. Quem desligar o
portao adaptativo a espera de veto absoluto a contramao continua a ver entrar
contramao dentro de 1 ATR. Ou seja: um input que hoje significa "nao negocio
contra a EMA200" passa a significar "nao negocio contra a EMA200 alem de 1 ATR",
sem que o dono tenha pedido isso.

- Nao e risco novo (a banda e estreita e o envelope manda), mas e **mudanca de
  semantica de um input existente**.
- Duas saidas honestas: **(a)** mover o bloco da folga para depois do teste de
  `EnableAdaptiveTrendGate` - entao `false` volta a ser rigor puro; **(b)**
  manter e documentar no `Config.mqh` que a folga e independente do portao
  adaptativo. Eu prefiro **(a)**: um input de seguranca nao deve ser contornado
  por outro input.
- Registo: **P1.2337** (ALFA).

### 2.3 R2 (MEDIA) - a folga mede-se em ATR do grafico, contra uma EMA de H1

`GetATR(symbol)` usa `(ENUM_TIMEFRAMES)Period()` (VolatilityFilter.mqh:422 e 630)
enquanto a EMA de referencia e `TrendTF` = H1 (`#261 = 16385`).

- Em XAUUSD **H1** as duas unidades coincidem: 1 ATR = 16,86 USD (medido pelo
  DELTA, D-086).
- Em grafico M5/M15 a folga vale 1 ATR **do grafico** contra uma distancia medida
  numa EMA de **H1**: folga efectiva muito menor. O erro e sempre para o lado
  conservador (aperta, nunca alarga), mas o **mesmo `1.0` nao significa a mesma
  coisa nos 15 graficos**.
- Nos 15 graficos do perfil `XAU_AI_PRO_15CHARTS_Q071` so o USDBRL esta em M5; os
  outros 14 estao impedidos pelo portao de IA (`disponivel=false` +
  `AllowTradeWithoutAI=false`), portanto hoje a distorcao e de 1 grafico.
- Correcao minima: `GetATR(symbol, TrendTF)` ou um ATR proprio em H1 com cache
  por simbolo, igual ao que ja existe para a EMA (`TREND_SYMBOL_CACHE`).
- Registo: **P1.2338** (ALFA).

### 2.4 R3 (MEDIA) - a folga autoriza sem deixar linha positiva no journal

O `reason` da folga comeca por `"contramao dentro da folga de ..."`. O unico
caminho que imprime linha positiva em `ValidationEngine.mqh:363-375` e
`StringFind(trendWhy, "contramao PERMITIDA") == 0`.

- Consequencia: o veto **e** impresso (`[VALIDATION] BLOCK | TREND BUY/SELL`),
  a permissao da folga **nao** - e e precisamente essa permissao que a Q-079/B
  veio criar e que a janela de segunda-feira tem de contar.
- Journal 18:58-19:06: `Q-079/B` = 0 e `TREND CONTRA OK` = 0. Nao prova o defeito
  (mercado fechado, `[CENARIO]=0`, sem sinal), mas prova que a folga **ainda nao
  foi exercitada**: qualquer numero de segunda-feira tem de vir com essa linha.
- Correcao minima: alargar o teste para o prefixo comum `"contramao"` ou imprimir
  a linha sempre que `trendWhy != ""` e o gate passou.
- Registo: **P1.2339** (ALFA).

---

## 3. Adopcao da correcao de escala do DELTA (D-086)

Assino a correcao. A frase `72,40 >= 65,0` compara duas escalas diferentes
(confianca de IA 0-100 contra `MarketScore` 0-100 com denominador 115). A
aritmetica certa, com o `P1.138`:

- com IA: 20 (EMA) + 15 (RSI) + 15 (ADX) + 36,20 (50 % de 72,40) = **86,20 / 115**
  -> **74,96 >= 65,00** (passa);
- sem IA: 20 + 15 + 15 = **50,00 / 115** -> **43,48 < 65,00** (recusa).

Frase publicavel: **"a parcela de IA vale 31,48 dos 100 pontos do piso; sozinha
nao chega, somada as parcelas tecnicas maximas leva o sinal a 74,96 e fai-lo
passar 65,00."** O piso continua com **0 amostras de producao**.

---

## 4. O que a v1.2.185 NAO e

- **Nao e um verde.** `GATE_REAL` fica **2 de 11** (G2 com ressalva de durabilidade,
  G3 verde so em tester). A v1.2.185 acrescenta **capacidade de medir**, nao um
  criterio cumprido.
- **Nao e 10/10.** 10/10 = 11/11 GATE_REAL + 30 dias forward demo + autorizacao
  escrita. A expressao "pronto a 10/10" nao existe neste projecto.
- **Nao e 15 instrumentos.** 15 graficos em v1.2.185 = **1 instrumento operavel
  (XAUUSD)** e 14 estruturalmente impedidos (`disponivel=false` +
  `AllowTradeWithoutAI=false`). Qualquer medida de segunda-feira e de XAUUSD, no
  singular.
- **Nao e o piso calibrado.** Uma leitura de sabado com mercado fechado nao
  calibra piso nenhum.

---

## 5. Pendencias que eu abro e que nao sao minhas para fechar

| ID | Dono | O que falta |
|---|---|---|
| P1.2337 | CMD (codigo) | decidir (a) ou (b) na R1 e, se (a), mover o bloco |
| P1.2338 | CMD (codigo) | ATR da folga em H1, nao no `Period()` do grafico |
| P1.2339 | CMD (codigo) | linha positiva no journal quando a folga autoriza |
| P1.2336 | ALFA | contador `trades=` do RESUMO sempre 0 |
| P1.139 | ALFA | passo 1 do `AllowTradeEx` mudo |
| - | DELTA | medir a folga e o piso na janela de segunda-feira, com `[CENARIO]` e `TREND CONTRA OK` |
| - | DONO | autorizacao escrita + 30 dias forward demo (G11) |

Nada disto exige parar o EA. O EA esta em demo, plano, com risco intocado.

---

## 6. Fecho

A Q-079 = B esta **bem implementada no essencial**: a guarda ficou, o risco nao
mexeu, o rigor antigo sobrevive sem leitura e o parametro e reversivel. As tres
ressalvas sao de **semantica e de observabilidade**, nao de seguranca de capital,
e a R1 e a unica que eu quero ver decidida antes de haver dinheiro real.

O que falta para a v1.2.185 valer alguma coisa e **segunda-feira**: sinal, folga
exercitada, linha no journal, piso medido com amostras. Ate la, o numero honesto
continua a ser **2 de 11**.

- ALFA, 07/11/2026 19:05
