# REGISTRO DE DECISOES - XAU_AI_PRO

Uma decisao so existe aqui se estiver escrita, datada e com evidencia.
Decisao fechada **nao se discute de novo**: se voce discorda, abra mensagem na
sua caixa com numero medido novo; nao edite a decisao.

Formato: `D-NNN` = fechada, `P-NNN` = pendente (precisa do dono).

---

## Fechadas

### D-001 | 05/11/2026 | Nunca `push`
Credencial do remote `origin` (Forge MQL5) expirada; e o remote `github`
exige intencao explicita. Commit e **local**. Proibido `git add -A` por causa
da arvore espelhada `MQL5/Files/XAU_AI_PRO/MQL5/**` e de
`Profiles/Tester/XAU_AI_PRO.set`.
Decidido por: dono. Evidencia: instrucao direta + estado do repo.

### D-002 | 05/11/2026 | Nao recarregar o EA nos graficos sem autorizacao
Os 13 graficos do perfil `XAI_P216_LIVE` rodam v1.2.159 de proposito.
Decidido por: dono. Evidencia: instrucao direta.

### D-003 | 05/11/2026 | Nunca alterar parametros de risco
`RiskPerTradeUsd`, `MaxDailyLossPercent`, `MaxDrawdownPercent`,
`StopLossPoints`, `TakeProfitPoints`, `RewardRatio`, `MinRewardRatio`,
`MaxSpreadPct`, `MaxTradesPerDay`, `MaxOpenPositions`, regras de entrada e
saida. Vale para os tres agentes.
Decidido por: dono. Evidencia: instrucao permanente.

### D-004 | 05/11/2026 | Universo = `Symbols` + Market Watch + simbolo do grafico
`ActiveSymbols[]` e o unico universo consumido pelo pipeline
(`TradePipeline.mqh` -> `TotalSymbols()`/`GetTradeSymbol(i)`). `Symbols`
continua sendo a **ordem de prioridade**; Market Watch entra por
`SymbolsFromMarketWatch` (novo input, default `true`), filtrado por
`IsSymbolTradeable`. Rejeitadas: lista fixa maior em `Symbols` (envelhece) e
remover `Symbols` (perde a prioridade).
Evidencia: Market Watch 21 simbolos x `Symbols` 11; 10 simbolos nunca
avaliados pelo pipeline em 05/11 21:30.
Implementado: v1.2.167 (P1.130) - **compilado, nao commitado, nao recarregado**.

### D-005 | 05/11/2026 | `GOLD` so vira `XAUUSD` se NAO for de bolsa
Nesta corretora `GOLD` = Barrick Gold Corporation (XNYS, `contract_size` 1.0,
`exemode` EXCHANGE, bid 37.40) e `XAUUSD` = metal (`contract_size` 100.0,
MARKET, bid 4106.66). O alias passa a exigir
`SYMBOL_TRADE_EXEMODE != SYMBOL_TRADE_EXECUTION_EXCHANGE`.
Evidencia: `SymbolInfoInteger` lido nos dois simbolos em 05/11 21:30.
Implementado: v1.2.167 em `AI/AIConnector.mqh`.

### D-006 | 05/11/2026 | Gate de IA: nao afrouxar codigo, resolver a causa
O bloqueio atual e **autenticacao** (HTTP 401 em `/`, `/health`,
`/api/ai/predict` de XAUUSD/EURUSD/USDCNH/USDSGD; tokens de ambiente ausentes;
`AIGatewayToken` vazio nos 13 graficos), nao aritmetica. Nao se altera
`MinAIConfidence` nem `AIUnavailableConfidenceCap` para "destravar".
Saida: token no gateway **ou** `EnableAutonomousMode=true` (decisao do dono).
Evidencia: sonda de 05/11 12:38 + `PENDENCIAS.md` P1.124/P1.125.

### D-007 | 05/11/2026 | Agente 1 e o unico com acesso ao terminal MT5
Somente o Agente 1 le journal, conta, posicoes, Market Watch, compila, roda
tester, recarrega e faz commit. Agentes 2 e 3 pedem a ele, via caixa.
Evidencia: `get_workspace_info` dos servidores MCP deste workspace.

### D-008 | 05/11/2026 | Um dono por arquivo
Nenhum arquivo tem dois donos. Ver `QUADRO.md` secao 5. Codigo `.mq5/.mqh`
pertence ao Agente 1; ninguem mais edita.
Evidencia: necessidade operacional - dois agentes no mesmo arquivo se
sobrescrevem.

### D-009 | 05/11/2026 | Medir antes de afirmar
Toda correcao cita a evidencia (linha de journal, contagem, valor lido).
"Nao medido" e resposta valida. Numero inventado contamina as decisoes de
todos.
Evidencia: causa raiz das 24 h sem posicao so apareceu porque a medicao
desmentiu a hipotese anterior (P1.124 dizia "cobertura"; era 401).

---

## Pendentes (precisam do dono)

### P-001 | Token do gateway vs modo autonomo  **[BLOQUEIA TUDO]**
- (a) provisionar `XAU_GATEWAY_TOKEN` no gateway e `AIGatewayToken` nos 13
  graficos; ou
- (b) `EnableAutonomousMode=true` -> IA deixa de vetar, vira consultora.
Sem isso, nenhum simbolo abre posicao. Impacto: zero operacao.

### P-002 | Recarga nos 13 graficos
v1.2.161, v1.2.162, v1.2.166 e v1.2.167 estao compiladas e nao carregadas.
Recarregar publica P1.123/P1.125/P1.130 em producao. Autoriza?

### P-003 | Commitar `Profiles/Tester/XAU_AI_PRO.set`?
Arquivo esta modificado e fora de todos os commits por decisao.

### P-004 | P1.111 - varias instancias escrevendo `dataset.csv`
Cada instancia do EA escreve no mesmo arquivo sem sincronismo. Precisa eleger
um escritor (similar a `PipelineMasterGuard`) ou separar por instancia.

### P-005 | `EnableVolatilityFilter=false` nos 13 graficos
Filtro de volatilidade desligado em producao. Ligar muda a taxa de entrada -
decisao do dono, nao do agente.

### P-006 | Simbolos com grafico e sem `Symbols` (e vice-versa)
`Symbols` tem 11 nomes; ha 13 graficos. EURUSD esta em `Symbols` sem grafico;
USDCZK, USDRUB e USDSGD tem grafico e nao estao em `Symbols`. O P1.130 cobre
o pipeline; a organizacao dos graficos e do dono.
