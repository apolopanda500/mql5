# QUADRO DE ESTADO - XAU_AI_PRO

Atualizado por: **Agente 1** em 05/11/2026 21:45 (hora local).
Regra: este arquivo so carrega **o que foi medido**. Estimativa vai marcada
como `[estimativa]`.

---

## 1. Versao e producao

| Item | Valor medido |
|---|---|
| Versao no codigo | **v1.2.167** (`#property version "1.367"`) |
| `EA_VERSION_STRING` | `"1.2.167"` |
| Ultimo build | **0 errors, 0 warnings** (MetaEditor build 6296, x64 Regular) |
| `XAU_AI_PRO.ex5` | compilado 05/11 21:36 |
| Versao rodando nos graficos | **v1.2.159** - 13 graficos, perfil `XAI_P216_LIVE` |
| Ultimo commit local | `53585733` P1.126-P1.129 (v1.2.166) |
| Commit pendente | **v1.2.167 (P1.130) - 6 arquivos, ainda nao commitado** |
| Conta | demo **113568614**, login MQL5 `APOLOPANDA500` |
| Terminal | build **6296**, x64, pasta `D0E8209F77C8CF37AD8BF550E51FF075` |

Consequencia direta: **tudo em v1.2.161/162/166/167 e codigo compilado, nao
codigo em producao.** Nenhuma correcao dessas chegou ao mercado.

---

## 2. Por que o EA ficou 24 h sem abrir posicao (medido)

Duas causas, em sequencia. A primeira ja foi corrigida em codigo; a segunda
depende do dono.

### Causa 1 - gate de IA insatisfativel (P1.125, v1.2.162, commitado)

`GetAIConfidence` aplicava `AIUnavailableConfidenceCap` (40) exatamente quando
`AIGateRequired()` era verdadeiro. Como `MinAIConfidence` = 60, o resultado era
sempre 40 < 60 e `AITradeAllowed` retornava `false` **para todos os simbolos**,
tivesse ou nao gateway.

Evidencia: journal de 05/11 entre 01:00 e 14:54 - 25 linhas
`[VALIDATION] BLOCK | AI` (AUDUSD, USDJPY, NZDUSD, USDCAD, USDSEK),
**zero** `AI OK`, **zero** `[ADV AI]` (o veto de `FinalAIAllow` nunca disparou).

### Causa 2 - gateway respondendo 401 (P1.124, sem correcao possivel em codigo)

Sonda autorizada em `/`, `/health` e `/api/ai/predict` para XAUUSD, EURUSD,
USDCNH e USDSGD: **HTTP 401 em todas**. `XAU_AI_GATEWAY_TOKEN` e
`XAU_AI_API_TOKEN` inexistentes no ambiente; `AIGatewayToken` vazio nos 13
graficos.

Com `AllowTradeWithoutAI=false`, `EnableAIFilter=true` e
`EnableAutonomousMode=false`, **nenhum simbolo passa o gate** - XAUUSD
incluido. Nao e bug: e o desenho "IA real veta e exige gateway".

**Bloqueio do dono:** provisionar token **ou** autorizar
`EnableAutonomousMode=true` (IA consultora).

---

## 3. Bloqueios que estao corretos por desenho (nao mexer)

Medidos no journal 05/11 20:56-21:25, depois do P1.123 (cache de handle por
simbolo, que devolveu a EMA200 correta):

- `[VALIDATION] BLOCK | TREND SELL | USDCAD | contramao vetada | ADX=57.8 >= 22.0`
- `[VALIDATION] BLOCK | TREND BUY | USDCNH | contramao vetada | ADX=47.3/50.6/52.0/52.7`
- `[VALIDATION] GBPUSD | ADX=17.76 | Min=18.00` -> abaixo de `MinimumADX`

Se um agente achar que isso e defeito, precisa provar com numero novo.

---

## 4. Universo de simbolos (P1.130, v1.2.167, nao commitado)

Medido em 05/11 21:30:

- **Market Watch: 21 simbolos.**
- **`Symbols` (input): 11 simbolos** (XAUUSD, EURUSD, GBPUSD, USDJPY, AUDUSD,
  USDCAD, NZDUSD, USDCHF, USDBRL, USDSEK, USDCNH).
- **10 simbolos nunca avaliados pelo pipeline:** AMD, MSFT, INTC, NVDA, GOLD,
  USDCLP, USDCOP, USDCZK, USDRUB, USDSGD. Destes, USDCZK, USDRUB e USDSGD
  tinham grafico aberto e negociavam sozinhos, nunca pelo pipeline.
- Mecanica: `InitSymbolManager` monta `ActiveSymbols[]` e **essa lista e o
  unico universo consumido** (`TradePipeline.mqh` -> `TotalSymbols()` /
  `GetTradeSymbol(i)`). O input `Symbols` nao limita nada por si.

Correcao aplicada em v1.2.167: `SymbolsFromMarketWatch=true` ->
`ActiveSymbols` = `Symbols` (ordem de prioridade) + Market Watch +
simbolo do grafico, filtrado por `IsSymbolTradeable`. Log diario
`[SYMS] UNIVERSO | marketwatch= | deSymbols= | adicionadosDoMarketWatch= |
grafico= | ativos= | origem=`.

### 4.1 Colisao de nome GOLD (medida)

Nesta corretora **`GOLD` e acao**, nao metal:

| Simbolo | Descricao | contract_size | exemode | bid |
|---|---|---|---|---|
| XAUUSD | Gold vs US Dollar | 100.0 | MARKET | 4106.66 |
| GOLD | Barrick Gold Corporation (XNYS) | 1.0 | EXCHANGE | 37.40 |

`NormalizeAISymbol` mandava os dois para `XAUUSD` -> um grafico de acao pedia
ao gateway a predicao do metal. Corrigido com a guarda `deBolsa`
(`SYMBOL_TRADE_EXEMODE == SYMBOL_TRADE_EXECUTION_EXCHANGE`).

---

## 5. Divisao de arquivos (sem sobreposicao)

| Caminho | Dono | Observacao |
|---|---|---|
| `Experts/XAU_AI_PRO/**/*.mq5`, `*.mqh`, `.mqproj` | **Agente 1** | so ele edita e compila |
| `Experts/XAU_AI_PRO/XAU_AI_PRO.ex5` | **Agente 1** | binario, gerado |
| `Experts/XAU_AI_PRO/PENDENCIAS.md` | **Agente 2** | IDs P1.xxx |
| `Experts/XAU_AI_PRO/PROGRESS.md` | **Agente 2** | diario tecnico |
| `Experts/XAU_AI_PRO/CONVERSAS.md` | **Agente 2** | registro de decisoes do dono |
| `Experts/XAU_AI_PRO/README.md` | **Agente 2** | visao do projeto |
| `Experts/XAU_AI_PRO/AUTONOMIA_24_7.md` | **Agente 2** | |
| `Tools/HANDOFF.md` | **Agente 2** (conteudo) / Agente 1 (numeros) | |
| `Tools/*.ps1` | **Agente 3** | toolkit, api-probe, verify-gateway |
| `Experts/XAU_AI_PRO/Data/**`, `MQL5/Files/*.csv` (dataset) | **Agente 3** | |
| `_EQUIPE/**` | cada um na sua caixa | quadro e decisoes: aditivo |
| `Profiles/**` | **ninguem** sem autorizacao | inclui `Tester/XAU_AI_PRO.set` |

---

## 6. Fila de tarefas

| ID | Tarefa | Dono | Estado | Evidencia exigida |
|---|---|---|---|---|
| T-001 | commitar v1.2.167 (P1.130) local, caminhos explicitos | Agente 1 | **aberto** | hash do commit |
| T-002 | completar changelog v1.2.167 (universo + GOLD) | Agente 2 | **aberto** | diff em `VersionManager.mqh`/docs |
| T-003 | decidir token do gateway vs `EnableAutonomousMode` | **dono** | **bloqueante** | journal com `AI OK` |
| T-004 | decidir recarga nos 13 graficos | **dono** | **bloqueante** | - |
| T-005 | provar P1.119 em producao (handle/barsCalc/serieSync) | Agente 1 | depende de T-004 | linhas de log |
| T-006 | investigar `[ATR] LEITURA SUSPEITA | USDBRL | ATR=3831.556600 | barsCalc=2204 | barrasSerie=24599` | Agente 1 | aberto | 3 leituras comparadas |
| T-007 | descompasso de features 30F vs 25F no gateway | Agente 3 | aberto | payload x contrato do modelo |
| T-008 | P1.111 - varias instancias escrevendo `dataset.csv` | Agente 3 | aberto | proposta de lock/election |
| T-009 | remedir PF (0.6206 e o numero antigo) | Agente 3 | aberto | relatorio do tester |
| T-010 | P1.110 - contaminacao de simbolo por instancia | Agente 1 | aberto | log por instancia |
| T-011 | `EnableVolatilityFilter=false` nos 13 graficos | **dono** | aberto | - |

Estado possivel: `aberto` | `em andamento` | `bloqueado` | `fechado`.
Ninguem muda o estado de uma tarefa de outro dono.
