# HANDOFF — 2026-11-03 07:20 (local)

Passagem de contexto para o proximo agente. Todos os itens abaixo foram
**medidos** nesta sessao. Nenhum segredo, token ou numero de conta completo.

## Terminal

- MetaTrader 5, build **6296**, target **x64**
- compilador: `C:\Program Files\MetaTrader 5\metaeditor64.exe`
- conexao com o servidor: ativa

## Conta

- tipo: **demo** (MetaQuotes-Demo)
- login: mascarado (`1135****14`)
- moeda: USD — balance/equity ~ **12.569,08**
- posicoes abertas: **0**

## EA em operacao

- **15 graficos**, todos com `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`
- `MagicNumber = 2026001`, `AutoTrade = true`
- simbolos: XAUUSD H1, USDCLP, USDCOP, USDSEK, USDJPY, USDCHF, USDCZK,
  USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD H1, USDBRL M5, USDRUB, USDSGD
- `AIGatewayUrl = http://127.0.0.1:9001/api/ai/predict`
- `AIGatewayToken`: **vazio**
- `NotifyTelegramToken` / `NotifyTelegramChatID`: **vazios** (caminho Telegram inativo)
- `EnableMCPServer = false` / `MCPServerToken` vazio (servidor MCP embutido no EA, desligado)

## Bloqueios conhecidos

| # | Sintoma | Causa raiz medida | Dono da correcao |
|---|---|---|---|
| 1 | `[AI] GATEWAY falhou \| erro=4014` no journal; `XAI_WebRequestCheck` marca **todas** as 6 URLs como `BLOQUEADA / DESABILITADO` | **WebRequest desabilitado** no terminal (checkbox nao marcado). Nao e problema de lista: se fosse, o erro seria 4060 | **operador** (GUI) |
| 2 | probe da API retorna **HTTP 401** em `/`, `/openapi.json` e `/api/ai/predict` | gateway exige `Authorization: Bearer <API_TOKEN>`; o EA **nao envia** o header porque `AIGatewayToken` esta vazio (`if(StringLen(AIGatewayToken) > 0)`) | **operador** (preencher input) |
| 3 | `[SCANNER] trades=0` com ~100 visitas e ~95 bloqueios | filtros vetando; motivo dominante `ADX indisponivel` em USDCNH | agente pode investigar |

O servico do gateway **esta de pe**: porta TCP 9001 aceita conexao e responde
HTTP. O problema nao e o backend estar fora — e autenticacao + WebRequest.

## Repositorio

- HEAD: `b65a8fdb` (`chore(repo): marca .set como binario e .ps1 como CRLF; atualiza preset do tester`)
- branch `main`, upstream `github/main`
- ahead/behind vs upstream: **0 0**
- working tree: limpo no momento da medicao
- ultimos commits: `2ade45a4` (MCP no EA), `c0bf4f13` (manual/sonda/comandos), `b65a8fdb` (.gitattributes + preset)

## Feito nesta sessao

- destrackeada a app aninhada `Files/XAU_AI_PRO` (5.515 arquivos com
  `node_modules`) e backups de edicao; repo de ~6.300 para **795** arquivos
- restaurado `XAU_AI_PRO.mqproj` (estava apagado do disco)
- removidos 7 workflows starter sem relacao com MQL5
- `Tools/agent-toolkit.ps1` — ciclo `status/check/compile/commit/push/deploy/full`
- `Scripts/XAI_WebRequestCheck.mq5` — classificador de allowlist (compilado, 0 errors)
- `Tools/AGENT_COMMANDS.md`, `Tools/api-probe.ps1`, `.claude/commands/*.md`
- secao "Operacao por outro agente IA" no `AGENTS.md`
- `Core/MCPServer.mqh` integrado ao EA (servidor MCP embutido); compilacao
  corrigida para **0 errors, 0 warnings**
- `.gitattributes` ajustado: `*.set` como binario (MetaEditor grava UTF-16) e
  `*.ps1` como CRLF

## Proximo passo recomendado

1. Operador: marcar `Ferramentas > Opcoes > Expert Advisors > "Permitir
   WebRequest para URLs listadas"` e adicionar `http://127.0.0.1:9001`.
2. Operador: descobrir o `API_TOKEN` do backend e preencher `AIGatewayToken`
   nos 15 graficos (ou desligar a exigencia de token no gateway).
3. Agente: reexecutar `/webrequest` e `/diagnose` para confirmar
   `PERMITIDA | HTTP=200` e o retorno do `[AI] GATEWAY`.
4. Agente: investigar por que `ADX indisponivel` veta USDCNH em todos os ciclos.
