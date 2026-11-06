# AGENTE 1 - assistente MT5 / EA

Caixa de entrada e diario do **Agente 1**. Este e o unico agente com acesso ao
terminal MetaTrader 5 e ao MetaEditor deste workspace.

> Leia antes: `_EQUIPE/README.md` (protocolo) -> `_EQUIPE/QUADRO.md` (estado) ->
> `_EQUIPE/DECISOES.md` (decisoes) -> `_EQUIPE/REUNIAO.md` (pauta comum).

---

## 0. Cartao de identidade

```
FERRAMENTA/MODELO: MetaTrader Assistant (MCP metatrader5 + custommcp3 + shell)
RAIZES QUE CONSIGO LER:
  MQL5, Tester, Logs, Common (terminal D0E8209F77C8CF37AD8BF550E51FF075)
RAIZES QUE CONSIGO ESCREVER:
  MQL5, Common
O QUE CONSIGO EXECUTAR:
  shell (PowerShell/cmd/git), metaeditor64.exe, scripts .ps1 do projeto
SEI COMPILAR MQL5?  sim - build 6296, x64 Regular
SEI LER JOURNAL DO MT5?  sim - terminal, EA e tester
SEI OPERAR O TERMINAL?  sim - simbolos, graficos, indicadores, EA, tester
DATA/HORA EM QUE ASSUMI: 05/11/2026 (sessao em curso)
```

---

## 1. Escopo (o que so eu faco)

- ler journal do terminal, do EA e do tester;
- ler conta, posicoes, ordens, historico, Market Watch, calendario economico;
- compilar `XAU_AI_PRO.mq5` / `.mqh` com `metaeditor64.exe`;
- rodar backtest / otimizacao no Strategy Tester;
- recarregar o EA nos graficos - **somente com autorizacao do dono (D-002)**;
- editar codigo `Experts/XAU_AI_PRO/**/*.mq5|mqh` (D-008);
- `git commit` local com caminho explicito (D-001, nunca `push`).

Regra de medida: **nenhuma correcao sem antes medir a causa**. Toda alteracao
minha cita a evidencia (linha de journal, contagem, valor lido).

Fora do meu escopo: documentacao (Agente 2), gateway/dataset/`Tools/*.ps1`
(Agente 3), decisoes de risco e de recarga (dono).

---

## 2. Estado do meu trabalho

| Item | Valor medido |
|---|---|
| Versao no codigo | **v1.2.167** (`#property version "1.367"`) |
| Ultimo build | **0 errors, 0 warnings** (05/11 21:36) |
| `XAU_AI_PRO.ex5` | compilado 05/11 21:36 |
| Rodando nos graficos | **v1.2.159**, 13 graficos do perfil `XAI_P216_LIVE` |
| Commitado | ate `53585733` (P1.126-P1.129, v1.2.166) |
| **Pendente de commit** | v1.2.167 / P1.130 - 6 arquivos |
| Nao recarregado | v1.2.161, .162, .166, .167 |

### 2.1 Causa medida das 24 h sem posicao

1. **P1.125 (v1.2.162, commitado)** - gate de IA insatisfativel para todos os
   simbolos: `GetAIConfidence` aplicava `AIUnavailableConfidenceCap` (40)
   quando `AIGateRequired()` era verdadeiro e 40 < `MinAIConfidence` (60).
   Journal 05/11 01:00-14:54: 25 x `[VALIDATION] BLOCK | AI`, 0 `AI OK`,
   0 `[ADV AI]`.
2. **Gateway em HTTP 401** (P1.124) - sem token no ambiente e
   `AIGatewayToken` vazio nos 13 graficos. **Depende do dono (P-001).**

---

## 3. Diario

Formato: `data hora | versao | o que medi | o que mudei | estado`.

- **05/11 21:36** | v1.2.167 | Market Watch 21 simbolos x `Symbols` 11 -> 10
  simbolos nunca avaliados pelo pipeline; `GOLD` nesta corretora e acao
  (Barrick Gold, XNYS, contract_size 1.0, exemode EXCHANGE) e nao o metal.
  | P1.130: `SymbolsFromMarketWatch` (universo = `Symbols` + Market Watch +
  grafico, filtrado por `IsSymbolTradeable`) em `Core/SymbolManager.mqh` +
  `Core/Config.mqh`; guarda `deBolsa` no alias GOLD/XAU em
  `AI/AIConnector.mqh`; bump em `XAU_AI_PRO.mq5` e
  `Enterprise/VersionManager.mqh`. | Compilado 0/0. **Nao commitado, nao
  recarregado.**
- **05/11 21:45** | v1.2.167 | reunido o canal dos 3 agentes em `_EQUIPE/`.
  | criados `README.md`, `QUADRO.md`, `DECISOES.md`, `AGENTE_2.md`,
  `AGENTE_3.md`, `CAIXA_ENTRADA_AGENTE_1.md`, `REUNIAO.md` e este arquivo.
  | documentacao apenas - nada de codigo tocado, nada compilado.

### Pendencias minhas agora

1. commitar v1.2.167 (T-001), caminhos explicitos, sem push, sem reload;
2. investigar `[ATR] LEITURA SUSPEITA | USDBRL | ATR=3831.556600 |
   barsCalc=2204 | barrasSerie=24599` (T-006);
3. provar P1.119 em producao depois da recarga (T-005, depende de P-002).

---

## 4. Mensagens que eu emiti

| # | Para | Assunto | Estado |
|---|---|---|---|
| MSG-001 | Agente 2 | assumir T-002: changelog v1.2.167 incompleto | ABERTO |
| MSG-002 | Agente 2 | divida documental herdada (`PENDENCIAS.md` x `PENDENCIAS_20261030.md`) | ABERTO |
| MSG-003 | Agente 3 | T-007: fechar descompasso 30F x 25F e o 401 | ABERTO |
| MSG-004 | Agente 3 | T-008: P1.111 `dataset.csv` escrito por 13 instancias | ABERTO |
| MSG-005 | 2 + 3 | canal aberto, estado do projeto, o que espero de cada um | ABERTO |
| MSG-006 | Agente 2 | nao commitar enquanto eu nao fechar o v1.2.167 | ABERTO |

Corpo completo de cada uma esta na caixa do destinatario: MSG-001/002/006 em
`AGENTE_2.md`, MSG-003/004 em `AGENTE_3.md`, MSG-005 em
`CAIXA_ENTRADA_AGENTE_1.md`.

---

## 5. Meu protocolo de sessao

1. ler `CAIXA_ENTRADA_AGENTE_1.md` procurando `ESTADO: ABERTO`;
2. ler o diario do Agente 2 e do Agente 3;
3. responder com evidencia medida e mudar o estado para `RESPONDIDO`;
4. registrar no meu diario (secao 3) o que fiz e o que ficou;
5. se o pedido exigir decisao do dono, escalar em `REUNIAO.md` (pauta aberta).

---

## 6. Pedidos que eu recebi

_(preenchido pelo Agente 1 ao responder `CAIXA_ENTRADA_AGENTE_1.md`)_
