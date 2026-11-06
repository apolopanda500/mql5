# AGENTE 2 - caixa de entrada e diario

> Voce e o **Agente 2**. Leia primeiro `_EQUIPE/README.md`, depois
> `_EQUIPE/QUADRO.md` e `_EQUIPE/DECISOES.md`. So escreva neste arquivo e nos
> documentos que sao seus (`PENDENCIAS.md`, `PROGRESS.md`, `CONVERSAS.md`,
> `README.md`, `AUTONOMIA_24_7.md`).
> **Voce nao tem acesso ao terminal MT5 nem ao MetaEditor.** Nao edita
> `.mq5`/`.mqh`, nao compila, nao recarrega, nao commita codigo.

---

## 0. Cartao de identidade (PREENCHER ANTES DE QUALQUER COISA)

```
FERRAMENTA/MODELO:
RAIZES QUE CONSIGO LER:
RAIZES QUE CONSIGO ESCREVER:
O QUE CONSIGO EXECUTAR (shell? python? git?):
SEI COMPILAR MQL5?  sim / nao
SEI LER JOURNAL DO MT5?  sim / nao
DATA/HORA EM QUE ASSUMI:
```

Sem este cartao, o Agente 1 assume que voce nao tem acesso a nada e nao delega
tarefa para voce.

---

## 1. Briefing do projeto (o que voce precisa saber de cor)

**O que e:** Expert Advisor **XAU_AI_PRO** em MQL5 para MetaTrader 5. Robo de
trading algoritmico com gate de IA (gateway HTTP), gestao de risco e
arquitetura modular. Pasta: `MQL5/Experts/XAU_AI_PRO/`.

**Versao atual:** v1.2.167 no codigo, compilada com **0 errors, 0 warnings**;
**v1.2.159 rodando** nos 13 graficos. Ou seja: existe uma fila de correcoes
prontas que ainda nao chegaram ao mercado (v1.2.161, .162, .166, .167).

**Estrutura real** (confira sempre no disco antes de assumir caminho):

```
Experts/XAU_AI_PRO/
  XAU_AI_PRO.mq5        entry point, OnInit/OnTick/OnDeinit
  Core/                 Config (inputs), SymbolManager (universo), Risk, Execution, TradePipeline, BrokerConfig, MarketScanner
  AI/                   AIConnector (gateway, LoadAIPrediction), AIEngine (AITradeAllowed)
  Indicators/           handles, EMA200, ADX, ATR
  Filters/              filtros de entrada
  Management/           gestao de posicao
  Monitoring/           AccountLogGate, OperatorBrief, NotificationCenter
  Enterprise/           VersionManager (EA_VERSION_STRING), outros
  Data/                 dataset (ignorado pelo git)
  PENDENCIAS.md         IDs P1.xxx - cada defeito com evidencia
  PROGRESS.md           diario tecnico por ciclo
  CONVERSAS.md          registro de decisoes do dono
```

**Ambiente:** conta **demo 113568614**, terminal build 6296, login MQL5
`APOLOPANDA500`, perfil de graficos `XAI_P216_LIVE` com 13 graficos.

**Fatos medidos que voce nao deve redescobrir:**

- O EA ficou **24 h sem abrir posicao** por duas causas: (1) gate de IA
  aritmeticamente insatisfativel (corrigido em v1.2.162); (2) gateway
  respondendo **HTTP 401** (depende do dono).
- `[VALIDATION] BLOCK | TREND ... | contramao vetada` e
  `[VALIDATION] BLOCK | ADX` **estao corretos** - sao filtros funcionando.
- O universo de simbolos era so o input `Symbols` (11), enquanto o Market Watch
  tem 21. Corrigido em v1.2.167 (universo universal).
- `GOLD` nesta corretora e **acao** (Barrick Gold), nao o metal.
- Regra de versao: `#property version` aceita so `xxx.yyy`
  (minor*100+patch) - v1.2.167 -> `"1.367"`. A versao legivel de verdade e
  `EA_VERSION_STRING` em `Enterprise/VersionManager.mqh`.

---

## 2. Seu escopo

Voce cuida de **documentacao, analise e revisao**. Concretamente:

1. `PENDENCIAS.md` - cada defeito com ID `P1.xxx`: sintoma medido, causa raiz,
   correcao, versao, estado.
2. `PROGRESS.md` - um bloco por ciclo de trabalho, com data e evidencia.
3. `CONVERSAS.md` - decisoes do dono, transcritas.
4. `README.md` - visao do projeto (estrutura, como compilar, como validar).
5. `AUTONOMIA_24_7.md` - requisitos de operacao 24 h.
6. Revisao: ler codigo e **apontar** defeito com linha e evidencia (voce nao
   corrige codigo - o Agente 1 corrige).

Nao faz parte do seu escopo: editar `.mq5`/`.mqh`, compilar, recarregar EA,
`git push`, decidir parametro de risco, decidir recarga.

---

## 3. Diario

Formato: `data hora | versao | o que medi | o que escrevi | estado`.

- _(vazio - aguardando o Agente 2)_

---

## 4. Mensagens

### MSG-001 | Agente 1 -> Agente 2 | 2026-11-05 21:45
TIPO: pedido
ASSUNTO: assumir T-002 (changelog do v1.2.167 incompleto) e o briefing acima
ESTADO: ABERTO
EVIDENCIA: `Enterprise/VersionManager.mqh` esta em `EA_VERSION_STRING "1.2.167"`
com um registro v1.2.167 que descreve **apenas** os dois relogios `TimeCurrent`
(`g_aiStateWhen` do `[RESUMO]` em `Monitoring/OperatorBrief.mqh` e o portao de
1800 s do `LoadAIPrediction`). Nada sobre o universo universal nem sobre a
guarda do GOLD-acao, que sao a outra metade do P1.130.
CORPO:
1. Depois que eu commitar o v1.2.167, acrescente ao registro v1.2.167 (e ao
   `PROGRESS.md`/`PENDENCIAS.md`) a parte **P1.130 - universo universal**:
   `Symbols` + Market Watch + simbolo do grafico, input
   `SymbolsFromMarketWatch` (default `true`), filtro `IsSymbolTradeable`,
   log diario `[SYMS] UNIVERSO`, e o caso GOLD-acao x XAUUSD-metal com a
   guarda `deBolsa` (`SYMBOL_TRADE_EXEMODE == SYMBOL_TRADE_EXECUTION_EXCHANGE`).
2. Nao reescreva o texto dos relogios - e aditivo.
3. Quando terminar, abra `MSG-001` na sua caixa com ESTADO `RESPONDIDO`.
PRAZO/IMPACTO: o changelog e a unica memoria do porquê; se ficar pela metade,
o proximo agente vai "corrigir" o que ja esta correto.

### MSG-002 | Agente 1 -> Agente 2 | 2026-11-05 21:45
TIPO: informacao
ASSUNTO: divida documental que voce herda
ESTADO: ABERTO
EVIDENCIA: consultei o estado do repo: `HANDOFF.md` tem 61.585 bytes e
`PENDENCIAS_20261030.md` tem 415.946 bytes; `PROGRESS.md` 311.307 bytes e
`PENDENCIAS.md` 93.384 bytes.
CORPO: existem dois arquivos de pendencias (`PENDENCIAS.md` e o
`PENDENCIAS_20261030.md` de 415 KB). Proponha, no seu diario, o que e arquivo
morto e o que ainda vale, **sem apagar nada** - arquivamento e decisao do dono.
PRAZO/IMPACTO: hoje ninguem sabe qual dos dois e a verdade.

---

## 5. Pedidos para o Agente 1

_(escreva aqui o que so ele pode fazer: journal, compilar, recarregar,
commitar, medir no terminal. Use o bloco de mensagem do `README.md`.)_
