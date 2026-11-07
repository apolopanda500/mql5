# SESSAO 07/11/2026 - CMD (turno 5): respostas do DONO, IA real no ar

**Papel:** CMD (infra/entrega). **Janela:** 07/11/2026 18:38 -> 19:10.
**Compile:** ZERO. **Reattach:** ZERO (o DONO respondeu 3 = b). **Ordens:** ZERO.
**Parametros de risco:** intocados. **Conta:** 113568614, 0 posicoes, 0 ordens.

---

## 1. Respostas do DONO (transcricao literal)

Texto recebido: *"1. Q-079 resposta . 2. Piso do score vamos instalar IA REAL DE UMA
VEZ POR TODAS PARA TERMINAR ESTE PROJETO. 3. Reattach b. 4. Magic: A. 5. Token da
IA e porta 9001 instalar IA real 10/10"*

| # | Item | Resposta | Estado |
|---|---|---|---|
| 1 | **Q-079** | **em branco** ("Q-079 resposta .") | **PENDENTE - falta A, B ou C** |
| 2 | Piso do score | "instalar IA REAL de uma vez por todas" | lido como **(f)**: IA real primeiro; piso decide-se depois, com IA a ler de verdade |
| 3 | Reattach | **b** - esperar | registado |
| 4 | Magic | **A** - manter magic unico | registado |
| 5 | Token / porta | "instalar IA real" | executado no lado servidor: gateway em **9011**, MCP fica em **9001** |

**O "10/10" nao e registado como estado** (regra D-069/D-070). GATE_REAL continua
**2 de 11**. O DONO escreveu a palavra; o canal nao a converte em gate.

**Nao interpretei o item 1.** Escolher A, B ou C por conta propria seria assinar
decisao de risco que nao e minha. Fica a pergunta repetida no fim deste ficheiro.

## 2. IA real - o que foi instalado (lado servidor)

| Passo | Resultado medido |
|---|---|
| `.env` | `XAU_GATEWAY_TOKEN` presente, **64 caracteres** (valor lido em memoria, nunca impresso) |
| Porta 9011 | estava **livre**; MCP do MT5 continua em 9001 |
| Gateway | `python -m uvicorn backend.fastapi_gateway:app --port 9011`, **pid 13276**, arrancado 18:45:05 |
| Modo | **leitura/diagnostico**: `XAU_ENABLE_REAL_ORDERS=0`, `XAU_ENABLE_DEMO_ORDERS=0`, `XAU_ENABLE_MT5_EXECUTION=0`, `XAU_ENABLE_TRADE_COMMANDS=0`, `XAU_MCP_TRADING=0` |
| `/api/health` | **200** `{"ok":true,"uptime_sec":48,"source":"mt5_gateway","gateway_build":"xau-ai-pro-1.2.181-universal-20261107"}` |
| `/api/ai/predict?symbol=XAUUSD&timeframe=H1` | **200** `available=true`, `signal=SELL`, `confidence=72.4`, `prob_buy=0.2765`, `prob_sell=0.7235`, `edge=+0.0363`, `price=4065.82`, `model="XAUUSD 1H"`, `inference_ms=8811` |
| Sem token | **401** `token invalido` - fail-closed correto |
| Parser do EA | le `prob_buy`/`prob_sell`, `signal` e `confidence` (`AIConnector.mqh:346/352`) - a resposta e consumivel |

### O que ainda falta para a IA chegar ao EA

`AIGatewayToken` continua **vazio** no input do EA. O token e a URL ficam nos
parametros do grafico, o que **exige reiniciar o EA** - e o DONO respondeu **3 = b
(esperar reattach)**. Portanto: **IA real esta no ar, mas o EA ainda nao a le**.
Essa e a diferenca entre "instalada" e "em uso", e fica escrita.

## 3. Consequencias medidas

- **Piso do score (f)**: a medicao do piso em demo so tem valor depois de o EA ler
  a IA real. Com `EnableAutonomousMode=false` (padrao do fonte) a IA volta a vetar
  e exige gateway; nos 20 ativos sem modelo o score fica 0 e, com
  `BlockZeroAIScore=true`, isso bloqueia. Decisao de universo por confirmar.
- **Ordem tecnica que resta**: Q-079 (A/B/C) -> 1 compile -> reattach (com token)
  -> janela em demo com IA real -> decidir piso com numeros reais.
- **Gateway nao e servico**: o processo pid 13276 morre com a sessao/reinicio. Para
  "de uma vez por todas" falta regista-lo como tarefa de arranque (Task Scheduler)
  ou servico. Nao foi feito: e instalacao no sistema, pede confirmacao.

## 4. Estado medido

| Item | Valor |
|---|---|
| Gateway IA | 9011, pid 13276, modo leitura, `/api/health` 200 |
| MCP MT5 | 9001, 401 fail-closed (inalterado) |
| EA a correr | **v1.2.183** nos 15 graficos, sem token, sem reattach |
| `.ex5` | 964 056 B, 16:23:11, MD5 `931459A39634DD7A95ED1EA74D412FC4` |
| Conta | Demo 113568614, equity 12 636,32, 0 posicoes, 0 ordens |
| Canal | `check` OK |
| GATE_REAL | **2 de 11** (G2 com ressalva; G3 auditado com 3 ressalvas) |

## 5. O que este turno NAO fez

- Nao escolheu Q-079.
- Nao compilou, nao reanexou, nao alterou parametro de risco nem lote/SL/TP.
- Nao armou execucao: todas as flags de ordem ficaram em 0.
- Nao registou "10/10" como estado.
- Nao instalou o gateway como servico (pede autorizacao a parte).
