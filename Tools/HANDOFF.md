# HANDOFF — 2026-11-03 21:15 (local) — ver "Atualizacao 21:15" no fim

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

## Atualizacao 21:15 (mesma sessao)

Estado medido por API (journal do terminal + conta), nao por ficheiro de log.

| Item | Medido |
|---|---|
| EA em operacao | **v1.2.121** nos 15 graficos (binario das 12:13) |
| EA compilado agora | **v1.2.122**, 0 errors / 0 warnings as 21:13:37 (`Tools\agent-toolkit.ps1 compile`) |
| conta | demo 113568614, balance **12 581,99** / equity **12 581,48** |
| posicoes | **1** — `#11222788311 USDCAD SELL 0.12` aberta 21:00:05 pelo pipeline completo |
| dia | **+12,91 de 40,00 USD (32%)** |
| funil do scanner (21:06:33) | `visitas=137 sinais=0 trades=0 bloqueios=137 CanOpen=12 Stale=12 NoSignal=113`, `ADX(sem/ok)=0/4992`, `SIG(sem/neutro)=0/1712` |
| repositorio | branch `main`, working tree **sujo** (nao commitado nesta sessao) |

O que mudou nesta sessao:

1. **Compilacao fechada**: o `.ex5` era das 12:13 e as fontes foram alteradas ate
   12:37 — o binario em uso estava desatualizado. Recompilado 0/0.
2. `P2.12` (novo): a linha `Statistics trade registrado` atribuia o resultado ao
  simbolo do grafico (ex.: `[TRADE] | USDCOP | ... | WIN | 10.00` para um ganho de
  USDCAD/USDCHF). Passa a publicar `negociado=<simbolo> | deal=<ticket>`.
  Ficheiros: `Monitoring/Statistics.mqh`, `XAU_AI_PRO.mq5` (call site),
  `Enterprise/VersionManager.mqh` (versao 1.2.122 + changelog).
3. **P1.82/P1.85 confirmados em producao**: `ADX(sem/ok)=0/4992` — nenhuma leitura
  de ADX ausente, e o USDCHF (que lia `0.0`) le 17,9. O fail-open de `ADX_OK()`
  deixou de ser necessario no caminho real.

Pendente (por ordem de valor):

1. **Reload dos 15 graficos** para a v1.2.122 — adiado de proposito: ha posicao
   aberta com escada armada. O binario ja esta no disco.
2. **Operador**: marcar `Permitir WebRequest para URLs listadas` e adicionar
   `http://127.0.0.1:9001`; preencher `AIGatewayToken`. Sem isso o `[RESUMO]`
   continua `IA=SEM PRECO`.
3. **Dono**: decisao sobre `AvoidHoursGMT=9,11,14,18,20,22` e par RSI 45/55 em H1 —
   `NoSignal=113` de 137 visitas e o gargalo real, nao o ADX.
4. **Commit/push** do working tree (71 ficheiros) — exige pedido explicito.

## Atualizacao 21:55 (mesma sessao) - v1.2.125 no ar

| Item | Medido |
|---|---|
| EA em operacao | **v1.2.125** nos 15 graficos (reload as 21:53:59 e 21:54:06) |
| EA compilado | 0 errors / 0 warnings - `agent-toolkit.ps1 compile` 21:48:23 e `metaeditor64 /compile` 21:51 |
| conta | demo 113568614, saldo **12 592,02** / equity **12 592,02** |
| posicoes | **0** (nenhuma do EA, nenhuma manual) |
| dia | **+22,94 de 40,00 USD (57%)** |
| commits | `4499c33c` (P2.13/P2.14) e `ef02e1c8` (P2.15), empurrados para `github/main` |
| repositorio | branch `main`, working tree com os ficheiros do outro agente (nao tocados) |

O que mudou nesta sessao (so journal - nenhuma regra de entrada, saida, lote,
alvo, stop, spread ou preco foi alterada):

1. **P2.13** - `[STOP]` do `OnDeinit` atras de portao por conta (1 / motivo /
   120 s); primeira observacao de simbolo em `StateSet` com portao de 1 h por
   conta+simbolo; STANDBY avanca o carimbo em cada tentativa. Motivo medido:
   `[STATE] USDCAD | -> MANAGING` 11 vezes no mesmo segundo e 15 `[STOP]` no
   reload das 21:29:47.
2. **P2.13 nao bastou** - `AccountLogGatePodeImprimir` le-compara-escreve sem
   bloqueio: com o ficheiro do portao ainda inexistente, as 15 instancias leem
   "nunca imprimiu" ao mesmo tempo. Medicao que prova: 21:29:47 = 15 `[STOP]`;
   21:32:13 com o MESMO codigo = 1 `[STOP]`.
3. **P2.14/P2.14b** - o unico motivo simultaneo (`REASON_RECOMPILE`) passou a ser
   decidido pela eleicao de dono do pipeline, com `PipelineMasterFresh()` (id
   publicado + batimento `_T` < 180 s); sem dono fresco volta ao portao de 120 s.
   A v1.2.124 chegou a produzir ZERO `[STOP]` (dono publicado morto) - corrigido.
4. **P2.15** - `ValidationLogAllowed` era por INSTANCIA: o mesmo veto saia 15
   vezes por janela de 300 s (23 no dia). Passou a exigir tambem o portao por
   conta com tag saneada (`val_<simbolo>_<motivo>`); o tester continua a registar
   todos os vetos.
5. **Prova em producao** (janela 21:53:50-21:54:20, dois reloads): `[STOP]` = 1 e
   0; `[VALIDATION]` = 2 (uma por reload); `[STATE]` = 0; STANDBY = 0;
   `[DATA] SEM LEITURA` = 1. Antes: 15 `[STOP]` por reload.
6. **Defeito de processo**: `metaeditor64 /compile` fora da instancia MetaEditor
   aberta **nao recarrega** os graficos. O binario ficou em disco as 21:51 e o
   journal so mostrou v1.2.125 depois de forcar a troca de perfil as 21:53:59
   (as duas copias de `chart01.chr` tinham 0 linhas de diferenca). Quem valida por
   journal tem de confirmar o RELOAD, nao a compilacao.

Correcao de facto do que esta escrito acima: `MCPServerToken` **nao esta vazio** -
e o literal `xau-mcp-local-2026`, igual nos 15 graficos e versionado em
`Core/Config.mqh:86` (portanto publico no GitHub). Isso e divida de seguranca, nao
de configuracao.

Pendente (por ordem de valor):

1. Journal: reescrever o motivo em `Filters/MarketScenario.mqh` (repete a
   explicacao do cenario em cada linha) e o dump por simbolo do arranque.
2. Operador: marcar `Permitir WebRequest para URLs listadas` + `http://127.0.0.1:9001`
   (erro 4014) e preencher `AIGatewayToken` (HTTP 401) - sem isso `IA=SEM PRECO`.
3. Dono: decisao sobre `AvoidHoursGMT=9,11,14,18,20,22` e par RSI 45/55 em H1
   (`NoSignal=113` de 137 visitas e o gargalo real).
4. Seguranca: tirar `MCPServerToken` do codigo versionado (ler de ficheiro).
5. Docs: `README.md` ainda anuncia v1.2.25 no cabecalho; `PROGRESS.md` ja tem o
   Ciclo 81.

## Atualizacao 22:35 (mesma sessao) - servidor MCP embutido desligado

- `[MCP] servidor ativo | metodos=7/7 ...` as 21:44:59 provou que o servidor MCP
  do EA corria nos 15 graficos autenticado com o token literal publico
  (`Core/Config.mqh`, GitHub). **Corrigido na v1.2.126 / P2.16**: default
  `EnableMCPServer=false`, `MCPServerToken=""` no codigo e o valor antigo
  recusado em runtime. Journal de 22:34:53: `[MCP] DESATIVADO | token literal
  publico recusado | defina um token privado no input MCPServerToken`.
- Para voltar a usar o servidor embutido: token privado (8+ caracteres) no input
  `MCPServerToken` dos graficos + `EnableMCPServer=true`. O token nao volta ao
  codigo.
- Estado as 22:34:53: v1.2.126 nos 15 graficos, **0 posicoes**, saldo/equity
  **12 592,02**, dia **+22,94 de 40,00 USD (57%)**, `IA=SEM PRECO`.
  Compilacao/deploy 0 errors / 0 warnings. Commit `8d23ef84` (P2.16);
  anteriormente `ef02e1c8` (P2.15) e `2aa63fca` (docs Ciclo 81).