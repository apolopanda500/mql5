# AGENTE 3 - caixa de entrada e diario

> Voce e o **Agente 3**. Leia primeiro `_EQUIPE/README.md`, depois
> `_EQUIPE/QUADRO.md` e `_EQUIPE/DECISOES.md`. So escreva neste arquivo e no
> que e seu (`Tools/*.ps1`, `Experts/XAU_AI_PRO/Data/**`, dataset em
> `MQL5/Files/*.csv`).
> **Voce nao tem acesso ao terminal MT5 nem ao MetaEditor.** Nao edita
> `.mq5`/`.mqh`, nao compila, nao recarrega, nao commita codigo MQL5.

---

## 0. Cartao de identidade (PREENCHER ANTES DE QUALQUER COISA)

```
FERRAMENTA/MODELO:
RAIZES QUE CONSIGO LER:
RAIZES QUE CONSIGO ESCREVER:
O QUE CONSIGO EXECUTAR (shell? python? curl? git?):
TENHO ACESSO AO GATEWAY (http://127.0.0.1:9011)?  sim / nao
TENHO O CODIGO-FONTE DO GATEWAY/MODELO?  sim (onde:) / nao
SEI LER JOURNAL DO MT5?  sim / nao
DATA/HORA EM QUE ASSUMI:
```

---

## 1. Briefing (o que voce precisa saber de cor)

**O que e:** Expert Advisor **XAU_AI_PRO** em MQL5 para MetaTrader 5, com
**gate de IA** por HTTP. O EA pergunta a predicao antes de entrar:

- input `AIUseGateway=true`
- `AIGatewayUrl=http://127.0.0.1:9011/api/ai/predict`
- `AIGatewayToken=''` (**vazio nos 13 graficos**)
- `AIPollSeconds=15`, `AIRequestTimeoutMs=15000`
- `EnableAIFilter=true`, `AllowTradeWithoutAI=false`,
  `EnableAutonomousMode=false`, `MinAIConfidence=60.0`,
  `AIUnavailableConfidenceCap=40.0`, `BlockZeroAIScore=true`,
  `AIHasSignalAuthority=false`, `AIHasSignalAuthority` / `AIAuthorityMinScore=75.0`,
  `AIConflictMinScore=80.0`

**Caminho do gate no codigo** (para voce saber onde apontar defeito):

1. `Monitoring/...` -> `ValidationEngine.mqh:485` chama `AITradeAllowed(symbol)`;
2. `AI/AIEngine.mqh` -> `AITradeAllowed` tem quatro `return false` independentes:
   `signal==0`, `confidence < MinAIConfidence`, `AI_Signal` oposto,
   contra-tendencia acima de `GetAIVetoThreshold()`;
3. `AI/AIConnector.mqh` -> `LoadAIPrediction` (HTTP) e `GetAIConfidence`;
4. `AIGateRequired()` e verdadeiro quando `EnableAIFilter=true` **e**
   `EnableAutonomousMode=false` **e** `AllowTradeWithoutAI=false`.

**O que esta medido hoje:**

| Fato | Numero |
|---|---|
| Gateway em `/`, `/health`, `/api/ai/predict` | **HTTP 401 em todos** |
| Simbolos testados na sonda | XAUUSD, EURUSD, USDCNH, USDSGD |
| `XAU_AI_GATEWAY_TOKEN` no ambiente | **nao definido**, tamanho 0 |
| `XAU_AI_API_TOKEN` no ambiente | **nao definido**, tamanho 0 |
| `AIGatewayToken` nos 13 graficos | **vazio** |
| Journal 05/11 01:00-14:54 | 25 x `[VALIDATION] BLOCK | AI`, **0** `AI OK`, **0** `[ADV AI]` |
| Descompasso de features | **30F enviados / 25F esperados pelo modelo** (P1.124) |

**Historico que voce nao precisa redescobrir:**

- **P1.125 (v1.2.162):** o gate era **aritmeticamente insatisfativel**.
  `GetAIConfidence` aplicava `AIUnavailableConfidenceCap` (40) exatamente quando
  `AIGateRequired()` era verdadeiro, e 40 < `MinAIConfidence` (60) ->
  `AITradeAllowed` retornava `false` para **todos** os simbolos, com ou sem
  gateway. Corrigido com a flag `aiReal`
  (`LoadAIPrediction(symbol) && AI_Signal!="UNAVAILABLE"`): o cap agora so vale
  quando **nao** ha leitura real.
- **P1.126-P1.129 (v1.2.166):** reconexao autonoma ao gateway com escada
  `60/120/300/600/900 s`, estado de cegueira, linha
  `[AI] GATEWAY RECUPERADO | symbol | tf | falhas=N | cego=Ns | resposta=NB`,
  e relogio que **nao congela**: `TimeCurrent()` para de andar quando o link
  com o broker cai (medido: servidor 2026-11-06 01:25 x local 2026-11-05
  20:25 = 18000 s). Em producao usa-se `TimeLocal()`; no tester, `TimeCurrent()`.
- **P1.128:** o relatorio diario passou a usar portao por **conta**
  (`relatorio_diario`, 82800 s) - antes cada uma das 13 instancias mandava o
  seu.
- **P1.130 (v1.2.167):** universo de simbolos virou `Symbols` + Market Watch +
  simbolo do grafico; `GOLD` so vira `XAUUSD` se **nao** for de bolsa (nesta
  corretora `GOLD` e a acao Barrick Gold, `contract_size` 1.0, exemode
  EXCHANGE).

**Ferramentas que ja existem e sao suas:**

```powershell
Tools\api-probe.ps1       # porta, raiz, rota de predicao com e sem token
Tools\verify-gateway.ps1  # verificacao do gateway
Tools\start-gateway.ps1   # subida do gateway
Tools\agent-toolkit.ps1   # status / check / compile do repo
Tools\WEBREQUEST_GATEWAY_UNBLOCK.md  # allowlist de WebRequest do terminal
```

**Atencao:** a allowlist de WebRequest e opcao do terminal, **fora** das
raizes do MCP - so o operador altera na GUI. Se a sonda falhar por allowlist,
isso e do dono, nao seu.

---

## 2. Seu escopo

1. **Gateway/IA:** contrato do endpoint, autenticacao, formato do payload,
   descompasso 30F x 25F, tempo de resposta, comportamento em 401/1003.
2. **Dataset:** `dataset.csv` e features - P1.111 (varias instancias do EA
   escrevendo o mesmo arquivo sem sincronismo). Proposta de lock/election.
3. **Medicao de desempenho:** remedir o PF (o 0.6206 e numero antigo) e
   entregar o numero novo com o relatorio do tester.
4. **Ferramentas:** `Tools/*.ps1` sao seus. Podem melhorar `api-probe.ps1` e
   `verify-gateway.ps1`.

Fora do escopo: editar `.mq5`/`.mqh`, compilar, recarregar EA, `git push`,
decidir parametro de risco.

---

## 3. Diario

Formato: `data hora | versao | o que medi | o que escrevi | estado`.

- _(vazio - aguardando o Agente 3)_

---

## 4. Mensagens

### MSG-003 | Agente 1 -> Agente 3 | 2026-11-05 21:45
TIPO: pedido
ASSUNTO: T-007 - fechar o descompasso 30F x 25F e o 401
ESTADO: ABERTO
EVIDENCIA: a sonda devolve **401** em `/`, `/health` e `/api/ai/predict`
(XAUUSD, EURUSD, USDCNH, USDSGD). Nenhum token no ambiente nem nos graficos.
O P1.124 registra "30 features enviadas x 25 esperadas pelo modelo", mas isso
**nao foi reproduzido** desde que o 401 apareceu - o 401 acontece antes de o
modelo ver o payload.
CORPO:
1. Responda com numero: qual e o contrato real do `/api/ai/predict`
   (metodo, headers, corpo, quantidade de features, nomes e ordem)?
2. O descompasso 30F x 25F ainda existe ou era efeito de versao antiga do
   gateway? Cite a linha de codigo do gateway ou o erro exato.
3. Existe algum modo sem token (localhost confiavel, chave em arquivo,
   variavel de ambiente) que dispense provisionar token novo? Se sim, diga
   qual e como testar **sem** escrever segredo em arquivo versionado.
4. Nao altere `MinAIConfidence`, `AIUnavailableConfidenceCap` nem
   `AllowTradeWithoutAI` - decisao D-006.
PRAZO/IMPACTO: sem isso o EA nao opera nenhum simbolo (P-001).

### MSG-004 | Agente 1 -> Agente 3 | 2026-11-05 21:45
TIPO: pedido
ASSUNTO: T-008 - P1.111, `dataset.csv` escrito por 13 instancias
ESTADO: ABERTO
EVIDENCIA: ha 13 graficos com o EA no perfil `XAI_P216_LIVE`, todos com os
mesmos inputs; `Data/` e `MQL5/Files/*.csv` sao compartilhados pelo terminal.
O EA ja tem `EnablePipelineMasterGuard=true` + eleicao de master para o
pipeline - mas **nao** ha eleicao equivalente para escrita do dataset.
CORPO: proponha o desenho (arquivo por instancia? lock por nome? eleicao de
escritor reaproveitando `PipelineMasterChart()`?) e o custo de cada opcao.
Nao implemente em MQL5 - o Agente 1 implementa depois da decisao.
PRAZO/IMPACTO: escrita concorrente corrompe feature de treino e contamina a
proxima medicao de PF.

---

## 5. Pedidos para o Agente 1

_(o que so ele pode fazer: journal, compilar, recarregar, commitar, tester.)_
