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

## Atualizacao 22:56 (mesma sessao) - reattach do dono, 13 graficos

O dono reanexou o EA nos graficos. Verificado por journal e por
`list_open_charts`, sem alteracao de codigo:

| Item | Medido |
| --- | --- |
| Reattach | `[STOP] XAUUSD motivo=1` 22:53:50.739, `[MCP] SHUTDOWN ok=true` 22:53:50.736, `[START] v1.2.126` de 22:53:51 a 22:54:49 (~3 s por grafico) |
| Graficos abertos | **13**: XAUUSD H1, USDSEK, USDJPY, USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD, USDBRL M5, USDRUB, USDSGD |
| Fechados | USDCLP e USDCOP. `[STOP] USDCOP motivo=4` 22:54:04.725; o do USDCLP caiu na mesma janela de 120 s e foi deduplicado pelo portao do P2.13 |
| MCP embutido | 0 linhas `[MCP] servidor ativo`, 2 `[MCP] SHUTDOWN`. P2.16 confirmado com os graficos reanexados |
| `[VALIDATION]` | 3 linhas em 3 reloads, todas USDRUB. P2.15 confirmado |
| Pipeline master | `[PIPELINE] STANDBY` 22:54:03.030, dono=22884787070177 (chart01 XAUUSD) |
| Conta | 113568614, 12 592,02 USD, **0 posicoes**, dia +22,94 de 40,00 USD (57%), `IA=SEM PRECO` |
| Funil | `[SCANNER] RESUMO` 22:55:53: visitas=165, sinais=0, NoSignal=155, Stale=10 |

- Inconsistencia de configuracao a decidir pelo dono: 13 graficos contra
  `Symbols` de 11 entradas. USDCZK, USDRUB e USDSGD tem grafico mas nao estao em
  `Symbols`; EURUSD esta em `Symbols` e nao tem grafico. Nao trava nada (as
  instancias sem dono ficam em STANDBY), mas separa a realidade do que esta
  declarado.
- Continuam por decidir: `AvoidHoursGMT=9,11,14,18,20,22` e o par RSI 45/55 em
  H1 (**NoSignal=155 de 165 visitas** e o bloqueio dominante); `WebRequest`
  desligado (erro 4014) e `AIGatewayToken` vazio (HTTP 401, journal diz
  `IA=SEM PRECO` e `[AI] PREDICAO VENCIDA`).


## Ciclo 84 - 03/11/2026 23:15 - v1.2.127 (P2.17 + P2.18 + Dependabot)

| Item | Medicao |
|---|---|
| Versao publicada | `1.2.127` (era `1.2.126`) |
| Compilacao | `0 errors, 0 warnings`, 21416 ms, x64 |
| `.ex5` | 23:12:41, 820350 bytes |
| Validacao estatica | 108 fontes OK (UTF-8, chaves, includes) |
| P2.18 | `[CENARIO]` deixa de publicar `ATR%=-1.00` e `ADX<=0`; passa a `sem leitura` |
| P2.17 | `[SIGNAL] SEM LEITURA` distingue aquecimento do indicador de falha real |
| Dependabot | `.github/dependabot.yml` na raiz: npm backend, npm frontend, github-actions |

- Nada disto altera regra de entrada ou de saida, lote, alvo, stop, spread,
  preco ou parametro de risco: P2.17 e P2.18 sao texto de journal.
- Continua por decidir pelo dono: `AvoidHoursGMT=9,11,14,18,20,22`, o par RSI
  45/55 em H1, os 13 graficos contra `Symbols` de 11 entradas, `WebRequest`
  desligado (erro 4014) e `AIGatewayToken` vazio (`IA=SEM PRECO`).

## Ciclo 85 - 03/11/2026 23:38 - v1.2.128 (P2.19 + Dependabot)

| Item | Estado |
|---|---|
| Versao publicada | `1.2.128` (era `1.2.127`) |
| Compilacao EA | `0 errors, 0 warnings`, `27810 ms`, x64 |
| Compilacao `Scripts\XAI_WebRequestCheck.mq5` | `0 errors, 0 warnings`, `919 ms` |
| P2.19 | `4014` deixa de ser publicado como "DESABILITADO"; passa a `NAO PERMITIDO` e o fim imprime `VEREDITO` + `ACAO` |
| Prova P2.19 | `VEREDITO | WebRequest esta LIGADO (1 URL(s) passaram a lista) | o defeito e a LISTA, nao o checkbox` as `23:36:13.798` |
| Dependabot frontend | `1 high` (`follow-redirects`) -> `0` |
| Dependabot backend | `7 moderate`, todos de desenvolvimento, sem correcao sem major |
| WebRequest medido | `1` permitida (`9001`), `5` bloqueadas por lista (`4014`), `0` indefinidas |

Pendencias do dono neste ciclo:

1. Adicionar em Ferramentas > Opcoes > Expert Advisors > Allow WebRequest for listed URL: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com` (uma por vez). A allowlist fica fora das raizes de escrita do agente.
2. O `401` em `9001/api/ai/predict` e o bloqueio real da IA: o gateway nao serve o EA e o `AIGatewayToken=12345678` nao coincide com `XAU_GATEWAY_TOKEN` (64 chars) do `.env`.


## Ciclo 86 - 03/11/2026 23:52 - v1.2.129 (P2.20 + backtest REPROVADO)

| Item | Estado |
|---|---|
| P2.20 `AIConnector.mqh` | `401` separa `token AUSENTE` de `token RECUSADO (N chars)`; `404`/`422`/`5xx` com motivo proprio; linha declara `WebRequest=LIGADO` + `corpo=NB`; `4014` deixa de ser so "desabilitado" |
| Compilacao | `0 errors, 0 warnings`, `21386 ms`, x64 |
| Backtest 7704134350896417964 | lucro **-213.74 USD**, PF **0.6206**, DD 2.48%, 152 trades, 41.4% de acerto, 10-11 perdas seguidas - **REPROVADO para conta real** |

Pendencias do dono que continuam abertas:
1. Adicionar em Ferramentas > Opcoes > Expert Advisors > Allow WebRequest for listed URL: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com`
2. Decidir a porta: opcao A (limpar `XAU_GATEWAY_PORT`, volta a 9001) ou opcao B (manter 9011 e mudar `AIGatewayUrl` nos 13 graficos)
3. Colar em `AIGatewayToken` o valor de `XAU_GATEWAY_TOKEN` (64 chars, em `MQL5\Files\XAU_AI_PRO\.env`)
4. Nada serve `/api/ai/predict`: arrancar o gateway Python
5. Nao ir a conta real: o backtest do periodo 01/09-01/11/2026 deu PF 0.62


## Ciclo 87 - 03/11/2026 23:57 - v1.2.130 (P2.21)

| Item | Estado |
|---|---|
| P2.21 `AIConnector.mqh` | aviso de `HTTP != 200` passa a 1 linha por tag+status a cada 30 min POR CONTA (~780 linhas/hora -> ~2) |
| P2.20 provado em runtime | `23:48:26.281 | token RECUSADO (17 caracteres enviados ...) | WebRequest=LIGADO (a chamada SAIU) | corpo=0B` |
| Token em uso vs esperado | grafico envia **17** caracteres; `XAU_GATEWAY_TOKEN` no `.env` tem **64** |


## Ciclo 88 - 04/11/2026 05:55 - v1.2.131 (P2.22 + documento do backtest)

| Item | Estado |
|---|---|
| `DatabaseManager` path | `TERMINAL_PATH` (instalacao) -> `TERMINAL_DATA_PATH` (dados) |
| `DatabaseManager` mensagem | `sqlite3 indisponivel` -> `DESATIVADA \| build sem sqlite3 \| nao e erro`, 1x/sessao por conta |
| `ValidationChecklist` | `[VALIDATION] N BLOCKED` passa a 1x/sessao por conta (era 1x por grafico por reload) |
| `AIConnector` cooldown | 3 recusas 401/403 seguidas -> 1800 s sem round-trip; HTTP 200 zera |
| Versao | P2.22 estava rotulado 1.2.130 (ja publicado); corrigido para **v1.2.131** |
| Documento | `RELATORIO_BACKTEST_20260901_20261101.md` + `Files\Backup\backtest_7704134350896417964.json` |
| Compilacao | `0 errors, 0 warnings`, 21235 ms, x64 |

Pendencias do dono (inalteradas):
1. Allowlist em Ferramentas > Opcoes > Expert Advisors: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com`
2. Porta: opcao A (limpar `XAU_GATEWAY_PORT`, volta a 9001) ou opcao B (manter 9011 e mudar `AIGatewayUrl` nos graficos)
3. `AIGatewayToken`: o grafico envia **17** caracteres, o `XAU_GATEWAY_TOKEN` do `.env` tem **64**
4. Arrancar o gateway Python (`/api/ai/predict` nao tem quem o sirva)
5. **Nao ir a conta real** - ver `RELATORIO_BACKTEST_20260901_20261101.md` (PF 0.62)


## Ciclo 89 - 04/11/2026 05:58 - ciclo 88 publicado (v1.2.131)

| Item | Estado |
|---|---|
| Commit | `4e72a976` (9 ficheiros, 134 insercoes, 6 remocoes) |
| Push | `8d52d767..4e72a976  main -> main` |
| Compilacao | `0 errors, 0 warnings`, `21573 ms`, X64 |
| `.ex5` | `05:57:14`, **823316** bytes |
| Validacao estatica | 108 fontes OK |
| Working tree | limpo |
| Dependabot | 2 `moderate` (`minimatch`, `qs`), dev-chain, sem fix sem major |

- Documentacao salva: `RELATORIO_BACKTEST_20260901_20261101.md` (veredito REPROVADO, PF 0.6206), `PROGRESS.md` Ciclos 86 a 89, este `HANDOFF.md`.
- Nenhuma regra de entrada, saida, lote, alvo, stop, spread ou parametro de risco foi tocada nos Ciclos 86 a 89: tudo o que mudou foi texto de journal, caminho da base de dados, numero de versao e documentacao.

Pendencias do dono (inalteradas):
1. Allowlist em Ferramentas > Opcoes > Expert Advisors: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com`
2. Porta: opcao A (limpar `XAU_GATEWAY_PORT`, volta a 9001) ou opcao B (manter 9011 e mudar `AIGatewayUrl` nos graficos)
3. `AIGatewayToken`: o grafico envia **17** caracteres, o `XAU_GATEWAY_TOKEN` do `.env` tem **64**
4. Arrancar o gateway Python (`/api/ai/predict` nao tem quem o sirva)
5. **Nao ir a conta real** - PF 0.62 no periodo 01/09-01/11/2026


## Ciclo 90 - 04/11/2026 06:01 - documentacao do ciclo 88 fechada (v1.2.131)

| Item | Estado |
|---|---|
| `README.md` | `Versao do codigo: **v1.2.131**` + `Ultima atualizacao: 2026-11-04.` - commit `e616262e` |
| `PENDENCIAS.md` | revisao `2026-11-04 05:58 (conta 113568614, v1.2.131)` |
| `PENDENCIAS.md` P-01 | `WebRequest` LIGADO, `401` = credencial recusada, **17** caracteres enviados contra **64** no `.env` |
| `HANDOFF.md` | 316 linhas, Ciclos 84 a 89 ja presentes - commit `395d101f` |
| Codigo conferido | `VersionManager.mqh:14` `1.2.131`; `AIConnector.mqh:630/748/749/753/802`; `DatabaseManager.mqh:85`; `ValidationChecklist.mqh:329` |
| Codigo alterado | nenhum - ciclo so de documentacao, `.ex5` de `05:57:14` mantem-se |

Pendencias do dono (inalteradas):
1. Allowlist em Ferramentas > Opcoes > Expert Advisors: `https://api.telegram.org`, `https://api.openai.com`, `https://generativelanguage.googleapis.com`, `https://api.anthropic.com`, `https://www.mql5.com`
2. Porta: opcao A (limpar `XAU_GATEWAY_PORT`, volta a 9001) ou opcao B (manter 9011 e mudar `AIGatewayUrl` nos graficos)
3. `AIGatewayToken`: o grafico envia **17** caracteres, o `XAU_GATEWAY_TOKEN` do `.env` tem **64**
4. Arrancar o gateway Python (`/api/ai/predict` nao tem quem o sirva)
5. **Nao ir a conta real** - PF 0.62 no periodo 01/09-01/11/2026

## Ciclo 91 - 04/11/2026 19:05 - fail-closed do token, IA 30F viva e raiz limpa (v1.2.135)

| Item | Estado |
|---|---|
| `backend/fastapi_gateway.py` | auth **fail-closed**: sem `XAU_GATEWAY_TOKEN`, `401 "sem token configurado"` (antes `if API_TOKEN:` deixava passar tudo) |
| Prova negativa | app em `9012` com `API_TOKEN=""`: 401 sem token, 401 token vazio, 401 token inventado, `/api/auth/ping` 200. Com token: 200 / token errado: 401 |
| Producao (9011) | 401 / 401 / 200 e `predict` 200 `available=true signal=SELL prob_sell=0,6365 price=4063,84 hash=5305081777808310` |
| `backend/ai_inference.py` | 40 483 -> 47 184 bytes; features pela `feature_version` do artefato e probabilidade pelas `classes_` (o modelo `XAU-30F-v4` e binario, `probs[2]` era sempre 0,0) |
| `TOKEN_PARA_BACKEND.txt` | apagado; nenhum arquivo versionado continha a string |
| `start_gateway.bat` | portas de execucao em `0` por padrao; `real` e argumento explicito com 5 s para abortar |
| Raiz | 34 arquivos movidos para `Files/Backup/raiz_lixo_20261104`; 2 versionados removidos (`check_all.py`, `check_main.py`) |
| `.env` 2 chaves | nao e regressao: as 16 do `.env.example` nao tem consumidor real; as 2 presentes sao as 2 usadas |
| Validacao | `check`: 108 fontes OK; `compile`: **0 errors, 0 warnings**, `.ex5` `19:05:25` |
| Nao rodou | `pytest` - ausente do `.venv` |
| Documento | `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_FAIL_CLOSED_30F_E_LIMPEZA.md` |

Pendencias do dono (medidas):
1. Reanexar o EA nos graficos para o `.ex5` novo valer (compilar nao reanexa).
2. Testador ocupado (5 `metatester64.exe`): nenhum backtest lancado.
3. `prediction_XAUUSD.json` continua necessario no backtest (`WebRequest` nao existe no tester).
4. `pytest` no `.venv`.
5. `RewardRatio` 0,65 (producao) vs 1,30 (testador) + A/B de `MinRewardRatio`.
6. **Nao ir a conta real**: PF 0,6206, 41,4% de acerto, 10-11 perdas seguidas.
---

# Handoff - Ciclo 95 (04/11/2026 20:10) - v1.2.137

Estado medido, nao presumido. Quem assumir o terminal le isto antes de mexer.

| Item | Estado |
|---|---|
| Versao | `v1.2.137` | `EA_VERSION_STRING "1.2.137"` | `#property version "1.337"` - os tres iguais (HG-01 fechado) |
| `.ex5` | **836.938 bytes**, `04/11/2026 20:05:18` (antes 834.986 B as 19:53) |
| Compilacao | `Result: 0 errors, 0 warnings, 27 713 ms elapsed, cpu='X64 Regular'` |
| Terminais | `terminal64` pid **12016** (desde 16:11:32), `MetaEditor64` pid **12548** (desde 16:22:05) |
| Strategy Tester | **OCUPADO.** `Tester\logs\20261104.log` com **155.572.518 bytes** e mtime `20:08:13`, a crescer. Run das 18:08:28 com `XAI_BASE_v131.ini`. `tester_list_result_windows` = `[]` |
| `AI\AIConnector.mqh` | `LoadAIPrediction`: raiz **LOCAL** primeiro, `FILE_COMMON` como fallback; raiz vai nas flags do `FileOpen`; `[AI] LOAD` publica `ROOT=LOCAL|COMMON` |
| `Common\Files\Data\prediction_XAUUSD.json` | **1082 bytes** do snapshot atual (`SELL`, `confidence 63,6`, `XAU-30F-v4`, `feature_hash 5305081777808310`). Estava em 521 B de 25/08/2026 |
| Graficos ao vivo | 13 graficos `XAI_P216_LIVE`, todos com `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` e o mesmo bloco de inputs. **Ainda com o binario anterior a `20:05:18`** - compilar nao reanexa |
| Gateway Python | 9011, fail-closed (401 sem token). Ver `Tools\api-probe.ps1` |
| Documento do ciclo | `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_P192_PREVISAO_FILE_COMMON.md` (6.982 B) |

## O que mudou neste ciclo

1. **P1.92 fechado** - o Strategy Tester lia um EA **sem IA**. A sandbox do tester
   e `Tester\Agent-<ip>-<porta>\MQL5\Files\` e o pipeline Python nunca escreve la.
   Agora ha fallback para `FILE_COMMON`, que resolve para a pasta Common verdadeira
   dentro do tester (provado na v1.2.45).
2. **HG-01 fechado** - `#property version "1.326"` (v1.2.126) estava oito versoes
   atras do codigo. Agora `"1.337"`.
3. **Copia em Common refrescada** - de 521 B/70 dias para 1082 B do snapshot atual.

## Pendencias do dono (medidas)

1. **P-02**: parar ou aguardar o run das 18:08 (ETA ~8-9 h). Depois re-medir com
   `Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini` (XAUUSD M15, ticks reais,
   2026.09.01..2026.11.01, deposito 10 000, sem `.set` -> geometria de producao).
   Criterio de fecho: `tester_get_status` sem job ativo.
2. **Reanexar** o EA nos 13 graficos para o `.ex5` de `20:05:18` valer.
3. **P-03** meta diaria: 20 USD (`DailyProfitTargetUsd`) vs teto 40 USD
   (`DailyProfitTargetMaxUsd`) - decidir.
4. **P-04** `StoplessEmergencyPoints = 0` (sem colchao de emergencia) - decidir.
5. **P-05** notificacoes bloqueadas: `send request failed (connect to
   194.164.179.242 failed, 10060 wsa error)`.
6. `pytest` ausente do `.venv`.
7. **Nao ir a conta real**: PF 0,6206, acerto 41,4%, 10-11 perdas seguidas. E esse
   numero e de um build **sem ADX e sem IA** - recusa por prudencia, nao por
   precisao. Criterio: PF > 1,20 **e** perdas seguidas <= 8, com
   `EnableRealAccountGuard=true` e risco baixo.

## Regra que continua valendo

Nenhum PF medido ate hoje descreve o EA atual. Antes de qualquer conversa sobre
conta real, re-medir com `v1.2.137` e confirmar no journal do tester as duas
linhas: `[AI] LOAD ... ROOT=COMMON` e a leitura de ADX (sem
`BarsCalculated` negativo em serie).

# Handoff - Ciclo 96 (04/11/2026 20:25) - v1.2.138

| Item | Valor | Prova |
|---|---|---|
| Versao | `v1.2.138` | `EA_VERSION_STRING "1.2.138"` + `#property version "1.338"` + cabecalho |
| `.ex5` | 857.638 bytes, `20:23:44` | recompilado apos as correcoes |
| Compilacao | `Result: 0 errors, 0 warnings` | `MQL5\Files\Temp\compile_c96c.log` |
| Graficos | 13 x `[START] XAU_AI_PRO v1.2.138` | journal do expert, 20:19:21 |
| Inteligencia | bloco `[MARKET INTELLIGENCE]` publicado, `Sessao: Sydney` | journal, 20:24:18 |
| IA | `[AI] PYTHON | XAUUSD | SELL | CONF=70.00%` | journal, 20:19:15 |
| Gateway | 9011 a escuta, fail-closed (401 sem token) | sonda com e sem `Authorization` |
| Token | 64 caracteres, igual nos dois `.env` | comparacao sem publicar o valor |
| Conta | DEMO 113568614, saldo 12592.02, 0 posicoes, 0 ordens | `get_trading_account_info` |
| Testador | **OCUPADO** | log a crescer, `tester_list_result_windows` = [] |

**Regra que continua a valer:** nenhum PF medido ate hoje descreve este EA. Antes de qualquer conversa sobre conta real, re-medir com `v1.2.138` e confirmar no journal do tester `[AI] LOAD ... ROOT=COMMON` e leitura de ADX.

**Pendente de GUI (so o dono):** a allowlist de WebRequest do terminal nao e alteravel por ferramenta. Esta funcional: o EA recebeu 1122 bytes do gateway.
## Ciclo 97 - 04/11/2026 20:31 - v1.2.140 (P1.96 + P1.97 fechados)

- **Versao em uso:** `1.2.140` (`#property version "1.340"`). `.ex5` 858.546 B, 04/11 20:30:50.
- **Compilacao:** `Result: 0 errors, 0 warnings, 25971 ms elapsed, cpu='X64 Regular'`.
- **Reattach:** `profile_apply Default` -> `profile_apply XAI_P216_LIVE`; 13x `[START] XAU_AI_PRO v1.2.140`.
- **Conta:** 113568614 (MetaQuotes-Demo), saldo 12.592,02, 0 posicoes, 0 ordens.
- **Gateway:** 127.0.0.1:9011 a escutar; H1 `available=True SELL conf=70.0`; sem `Bearer` devolve 401.
- **`[MARKET INTELLIGENCE]`:** publicado uma vez por hora por CONTA (gate `market_intel`, 3600 s). Para forcar, apagar `Common\Files\XAU_AI_PRO\loggate_market_intel.bin` e esperar ~50 s.
- **`Proximo evento`:** deixou de sair vazio as 20:31:13 - `Licenciamento de Veiculos (Mensal) (impacto=1)` / `Min para evento: 568`.
- **Testador:** OCUPADO (P-02). Nao lancar backtest por cima.
- **Conta real:** proibida. PF historico 0,6206 e de um build sem ADX e sem IA.

## Ciclo 98/99/100 - 04/11/2026 20:44 - v1.2.142 (P1.98 + P1.100)

- **Versao em uso:** `1.2.142` (`#property version "1.342"`, cabecalho e
  `EA_VERSION_STRING` alinhados). `.ex5` 865350 B, 04/11 20:43:56.
- **Compilacao:** `Result: 0 errors, 0 warnings, 27428 ms elapsed,
  cpu='X64 Regular'` (`Files\Temp\compile_c100.log`).
- **Reattach:** `profile_apply Default` -> `profile_apply XAI_P216_LIVE`;
  28x `[START] XAU_AI_PRO v1.2.142 ... saldo=12592.02` as 20:44:14 e 20:44:24.
- **P1.98 (fechado):** recusa do gateway (`available:false`) deixa de ser
  publicada como previsao `NEUTRAL PRICE=0.00000`. Passa a
  `[AI] INDISPONIVEL | <sym> | MOTIVO=<reason>` (1/hora/simbolo/conta) e
  `LoadAIPrediction()` devolve `false`, logo `AIEngine.mqh:512` bloqueia.
- **P1.100 (fechado):** `HTTP 1003 ... backend fora do ar` era falso. Nova faixa
  `status > 599` testada antes de `>= 500` ->
  `resposta NAO-HTTP (codigo devolvido pelo transporte ...)`. Removido tambem o
  `if(logOnce)` duplicado antes do `Print` de `[AI] LOAD`.
- **Prova P1.98:** journal 20:39:57-20:40:32 com 13x `[AI] INDISPONIVEL` e zero
  `PRICE=0.00000`; XAUUSD manteve `SELL PRICE=4063.500 CONF=71.90%`.
- **Portoes limpos:** 16 `loggate_ai_load_*.bin` apagados de
  `Common\Files\XAU_AI_PRO`.
- **Conta:** 113568614 (MetaQuotes-Demo), DEMO hedging, 12.592,02,
  0 posicoes, 0 ordens.
- **Gateway:** 127.0.0.1:9011 a escutar; fail-closed 401 sem `Bearer`.
- **Testador:** OCUPADO (P-02). Nao lancar backtest por cima.
- **Conta real:** proibida. PF historico 0,6206 e de um build sem ADX e sem IA.

---

## Ciclo 101 - 2026-11-04 21:07 (UTC 2026-11-05T00:07Z)

| Campo | Valor |
|---|---|
| Build em uso | `XAU_AI_PRO v1.2.143`, `.ex5` 866222 B, 21:05:06, `0 errors, 0 warnings` |
| Versao tripla | header `v1.2.143`, `#property version "1.343"`, `EA_VERSION_STRING "1.2.143"` |
| Graficos | 15 + 15 reanexados por `profile_apply Default` -> `XAI_P216_LIVE` as 21:05:28-21:05:36 |
| Conta | 113568614 MetaQuotes-Demo, DEMO hedging, saldo/equity 12592.02, 0 posicoes |
| IA | XAUUSD com previsao fresca (`SELL`, `CONF=79.30%`, 21:06:04); restantes simbolos sem modelo -> recusa fail-closed |
| Gateway | `http://127.0.0.1:9011` no ar, token de 64 chars, `available=true` para XAUUSD |
| Testador | OCUPADO desde 20:26:22 na v1.2.138 (pre-fix) - P-02; `tester_list_result_windows` = [] |
| Bloqueios | P-02 (DONO: Stop manual), P1.100 nao exercitado, P1.102 candidato, P-03/P-04/P-05 |
| Risco | inalterado: RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false |
| Governanca | conta real proibida (PF > 1.20 E perdas consecutivas <= 8, com guarda e risco baixo) |

---

## Ciclo 102 - 2026-11-04 21:18 (UTC 2026-11-05T00:18Z)

| Campo | Valor |
|---|---|
| Build em uso | `XAU_AI_PRO v1.2.144`, `.ex5` 867576 B, 21:16:04, `0 errors, 0 warnings` |
| Versao tripla | header `v1.2.144`, `#property version "1.344"`, `EA_VERSION_STRING "1.2.144"` |
| Ultima correcao | P1.102 - o Strategy Tester deixou de escrever o tempo simulado nos ficheiros de gate partilhados (throttle por conta restaurado) |
| Graficos | reanexados por `profile_apply Default` -> `XAI_P216_LIVE` as 21:16:20 |
| Conta | 113568614 MetaQuotes-Demo, DEMO hedging, 12592.02, 0 posicoes |
| IA | gateway vivo (`available=true` para XAUUSD, conf 81.0); restantes simbolos sem modelo -> recusa fail-closed |
| Testador | OCUPADO (job de 20:26:22 na v1.2.138, 4 processos `metatester64`) - P-02; `tester_list_result_windows` = [] |
| Gates | `loggate_ai_stale.bin` estava com `2026-09-09 20:00:00` (tempo do tester) antes da v1.2.144 |
| Risco | inalterado: RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false |
| Governanca | conta real proibida (PF > 1.20 E perdas consecutivas <= 8, com guarda e risco baixo) |

---

## Ciclo 103/104 - 2026-11-04 21:33 (UTC 2026-11-05T00:33Z)

| Campo | Valor |
|---|---|
| Build em uso | `XAU_AI_PRO v1.2.146`, `.ex5` 869028 B, 21:32:31, `0 errors, 0 warnings` |
| Versao tripla | header `v1.2.146`, `#property version "1.346"`, `EA_VERSION_STRING "1.2.146"` (verificada por `Tools\auto-deploy.ps1`) |
| Ultima correcao | P1.103 - uma falha de TRANSPORTE do gateway deixa de trocar uma previsao fresca em memoria por um ficheiro local obsoleto |
| Graficos | 15 instancias `[START] v1.2.146` as 21:32:54 (XAUUSD, USDCLP, USDCOP, USDRUB, USDSGD, USDCZK, USDCNH, AUDUSD, USDCHF, NZDUSD, USDBRL M5, GBPUSD, USDSEK, USDCAD, USDJPY) |
| Conta | 113568614 MetaQuotes-Demo, DEMO hedging, 12592.02, 0 posicoes |
| IA | gateway autenticado: `[AI] GATEWAY \| XAUUSD \| H1 \| 1122 bytes` + `SELL CONF=73.40%`; simbolos sem modelo -> recusa 357 B, bloqueados |
| Regressao | `PRICE=0.00000` = 0 registos e `[AI] PREDICAO VENCIDA` = 0 registos na janela 21:32:54-21:36:00 |
| Autoupdate | novo `Tools\auto-deploy.ps1`: gate de versao tripla -> compilar -> verificar `.ex5` -> imprimir reattach MCP; `-Commit` faz commit+push nos dois remotes. Detalhe em `Docs/AUTODEPLOY.md` |
| Grafico sem EA | `chart14.chr` (2.o XAUUSD,H1) nao tem EA por desenho - evita segunda instancia no mesmo simbolo/magic 2026001 |
| Testador | OCUPADO desde 20:26:22 na v1.2.138 (pre-fix) - P-02; `tester_list_result_windows` = [] |
| Bloqueios | P-02 (DONO: Stop manual), P1.103 nao exercitada em falha real, P1.100 sem disparo, P-03/P-04/P-05 |
| Risco | inalterado: RewardRatio 0.65, MaxDailyLossUsd 60, RiskPercent 1.0, MinAIConfidence 60.0, AllowTradeWithoutAI false |
| Governanca | conta real proibida (PF > 1.20 E perdas consecutivas <= 8, com guarda e risco baixo) |

### Ciclo 106 - 2026-11-04 22:12 - [SCANNER] Stale USDBRL (correcto) + v1.2.147 em producao

| Item | Estado medido |
|---|---|
| Build em uso | `XAU_AI_PRO v1.2.147`, `.ex5` 876 726 B, 22:05:24, `0 errors, 0 warnings` |
| Versao tripla | header `v1.2.147` / `#property version "1.347"` / `EA_VERSION_STRING "1.2.147"` |
| Graficos | 15 instancias `[START] v1.2.147` as 22:05:34 (XAUUSD, USDCLP, USDCOP, USDRUB, USDSGD, USDCZK, USDCNH, AUDUSD, USDCHF, NZDUSD, USDBRL M5, GBPUSD, USDSEK, USDCAD, USDJPY) |
| `[SCANNER] BLOCK Stale USDBRL` | **nao e defeito** - feed morto desde 2026-11-04 22:59:59 servidor (17:59:59 Brasilia); portao `MaxSymbolTickAgeSec=900` |
| Simbolos mortos as 03:04 servidor | USDBRL 4h04m, USDCOP 7h04m, USDCLP 7h34m, USDRUB 10h08m; os 12 liquidos vivos ao segundo |
| Gateway | XAUUSD `1122 bytes | disponivel=true`, `SELL PRICE=4095.600 CONF=55.70%`; 12 simbolos `disponivel=false` (357 B) |
| `[AI] LOAD` | `SYMBOL=XAUUSD | ROOT=LOCAL` |
| Posicoes | 0 |
| Risco | inalterado (RewardRatio 0.65, MaxDailyLossUsd 60, DailyProfitTargetUsd 20 / Max 40, RiskPercent 1.0, StoplessEmergencyPoints 0) |
| P-02 Strategy Tester | continua DONO - slot ocupado, sem numero novo de PF |
| P1.107 | novo, por decidir: `[RESUMO]` nao nomeia o simbolo do campo `IA=` |

### Ciclo 107 - 2026-11-04 22:40 - P1.107 entregue, v1.2.148 em producao
| Item | Valor |
| --- | --- |
| Build em uso | `XAU_AI_PRO v1.2.148`, `.ex5` `877 132 B`, `22:39:24`, `0 errors, 0 warnings` |
| Mudanca | `[RESUMO]` publica `IA(<SIMBOLO>)=<sinal> <conf>%` (`Monitoring/OperatorBrief.mqh`) |
| Graficos | 15 instancias reanexadas via `profile_apply Default` -> `XAI_P216_LIVE` |
| Conta | `113568614` (MetaQuotes-Demo), saldo `12592.02`, 0 posicoes |
| Ia real | `[AI] PYTHON \| XAUUSD \| SELL \| CONF=57.00%`; `[AI] GATEWAY` com `disponivel=true` em XAUUSD |
| Risco | intocado; escada `ON arma 5.00 / trava 1.00 em 7.00 / alvo 10.00 USD` |
| Docs | `Docs\CONVERSA_20261105_CICLO107_P1107_V1148.md` |
| Proximo | P1.103 ao vivo (parar gateway), P-07 perfil 14 vs 15, P-02 tester (dono) |

---

## Ciclo 108 - 04/11/2026 23:05

- Build em producao: **XAU_AI_PRO v1.2.150** (`#property version "1.350"`),
  `.ex5` 879812 B de 22:58:26, compilado com 0 errors / 0 warnings (build 6296).
- Reattach feito: `profile_apply Default` -> `profile_apply XAI_P216_LIVE`.
  15 `[START] XAU_AI_PRO v1.2.150` entre 22:58:40.304 e 22:58:51.683
  (inclui USDCLP e USDCOP, que nao existem em `Profiles\Charts\XAI_P216_LIVE`
  - a divergencia P-07 continua).
- Conta 113568614 (MetaQuotes-Demo, DEMO, hedging) saldo/equity 12592.02, 0 posicoes.
- Risco inalterado: RewardRatio 0.65 / MinRewardRatio 0.55 / MaxDailyLossUsd 60 /
  MaxDrawdownPercent 15 / DailyProfitTargetUsd 20 / MaxUsd 40 / StreakBrakeLosses 3 /
  RiskPercent 1.0 / RiskPerTradeUsd 2.0 / MinAIConfidence 60 / MaxPredictionAgeSec 900 /
  MinimumADX 18 / StoplessEmergencyPoints 0 / escada 5-1-7-10 USD /
  EnableRealAccountGuard true / AllowTradeWithoutAI false.
- Aberto: P1.110 (leitura cruzada de indicador ainda intermitente),
  P1.111 (dataset.csv escrito por varias instancias), P-07, P-02/P-03/P-04 (dono).
- Proximo: identificar a instancia que le o outro par (coluna de instancia no
  dataset) e so depois re-medir o PF no Strategy Tester.

---

## Ciclo 109/110 - 05/11/2026 15:15 - fecho do XAU AI PRO (v1.2.156)

| Campo | Valor |
|---|---|
| Build em producao | `XAU_AI_PRO v1.2.156`, `.ex5` compilado com `0 errors, 0 warnings` (build 6296, X64 Regular, 25726 ms) |
| Versao tripla | header `v1.2.156`, `#property version "1.356"`, `EA_VERSION_STRING "1.2.156"` (HG-01) |
| Commits locais | `a9cfa33d` (ciclo 109, v1.2.151-155) e `c54f0983` (ciclo 110, v1.2.156). Sem push |
| Reload | 3 arranques: 15 graficos 15:12:30.169-15:12:30.871; 13 graficos 15:12:37.404-15:12:37.458; 13 graficos 15:13:06.496-15:13:07.936 - todos `[START] XAU_AI_PRO v1.2.156` |
| Graficos | 13 no perfil `XAI_P216_LIVE`, todos com `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` e `AutoTrade=true` |
| Conta | 113568614 MetaQuotes-Demo, DEMO hedging, saldo/equity **12636.32**, **0 posicoes**, **0 ordens** |
| `[ATR]` no reload | 12 linhas entre 15:12:30.864 e 15:12:33.966, todas `CopyBuffer sem barras \| barsCalc=-1`: 10x `erro=4807`, 2x `erro=4022` (grafico USDBRL,M5). **Zero** `[ATR] LEITURA SUSPEITA` depois de 15:13:07.936 |
| P1.116 | FECHADO por medicao: o ramo persistente e o 3.o (`CopyBuffer` sem barras no attach) |
| P1.117 | FECHADO no codigo: `ATRCacheDrop()` tinha 0 chamadas; agora `ATRCacheDropAllowed()` (portao 60 s por simbolo) + `ATRCacheDrop(symbol)` no ramo suspeito |
| P1.117 em producao | **sem regressao**, mas o ramo de queda NAO foi exercitado em ~2 min (nenhuma leitura suspeita). Falta uma sessao em que a suspeita dispare e o par sara |
| Risco | inalterado: RewardRatio 0.65 / MinRewardRatio 0.55 / MaxDailyLossUsd 60 / MaxDrawdownPercent 15 / DailyProfitTargetUsd 20 / MaxUsd 40 / StreakBrakeLosses 3 / RiskPercent 1.0 / RiskPerTradeUsd 2.0 / MinAIConfidence 60 / MaxPredictionAgeSec 900 / MinimumADX 18 / StoplessEmergencyPoints 0 / escada 5-1-7-10 USD / EnableRealAccountGuard true / AllowTradeWithoutAI false |
| Docs | `Docs\CONVERSA_20261105_P1112_P1116_V1151_V1155.md` (ciclo 109) e `Docs\CONVERSA_20261105_P1117_V1156.md` (ciclo 110) |

### Portas que ficaram fechadas

1. `P1.116` - instrumentado, medido e nomeado; nao se infere mais a causa pela magnitude do ATR.
2. `P1.117` - a causa (codigo morto) esta corrigida e compilada; a ausencia de regressao esta medida.
3. `Profiles/Tester/XAU_AI_PRO.set` - estava modificado e por gravar desde as 05:38 (`RewardRatio 1.30 -> 1.60`, `MinRewardRatio 1.00 -> 1.60`, `EnableAdaptiveTargets true -> false`). Ficou em commit proprio `chore(tester)` para nao perder a informacao; reverter com `git revert` se nao foi intencional. Nao afecta a producao (graficos com 0.65 / 0.55 / true).

### Portas que so o dono fecha

1. **Push**: todos os commits sao locais. `origin` = Forge MQL5, `github` = `apolopanda500/mql5`. Nada foi publicado.
2. **`[ATR] LEITURA SUSPEITA | USDBRL | ATR=3908.848300 | preco=5.5123 | ATR%=70911.39`** (13:53:26.183) - magnitude que nao e o ouro nem o proprio par. Com `barsCalc`/`barrasSerie`/`barrasGrafico` no log, a proxima ocorrencia responde sozinha.
3. Herdadas de `PENDENCIAS.md`: P1.110, P1.111, contradicao de simbolos (11 em `Symbols` vs 13 graficos), `EnableVolatilityFilter=false`, gateway 401/1003 com contrato 30F vs 25F, `MCPServerToken` vazio, PF a re-medir.
4. **Conta real continua proibida**: PF 0.6206, acerto 41.4%, 10-11 perdas seguidas - e esse numero e de um build sem ADX e sem IA.

---

## Ciclo 111 - 05/11/2026 15:35 - P1.118 medido e o P1.119 que ele revelou (v1.2.157)

| Campo | Valor |
|---|---|
| Build em producao | `XAU_AI_PRO v1.2.157`, `.ex5` compilado com `0 errors, 0 warnings` (build 6296, X64 Regular, 24806 ms) |
| Versao tripla | header `v1.2.157`, `#property version "1.357"`, `EA_VERSION_STRING "1.2.157"` (HG-01 fechado) |
| Commits locais | `513fbe12` (v1.2.157 + docs corrigidas). Anteriores: `3bbc4aa3`, `79aaccf6`, `c54f0983`, `a9cfa33d`. Sem push |
| Reload | 2 vagas as 15:19:59.004-15:19:59.058 (15 graficos) e 15:20:09.339-15:20:09.369 (13 graficos); reload de fecho as 15:26:46.458-15:26:46.504 (15) e 15:26:54.996-15:26:55.036 (13) - todos `[START] XAU_AI_PRO v1.2.157` |
| Graficos | 13 no perfil `XAI_P216_LIVE`, `AutoTrade=true` |
| Conta | 113568614 MetaQuotes-Demo, DEMO hedging, saldo/equity **12636.32**, **0 posicoes**, **0 ordens** |
| `[ATR] HANDLE MORTO` | 11 linhas entre 15:23:14.590 e 15:25:01.819, UMA por simbolo (USDBRL, USDCNH, USDCHF, USDCAD, AUDUSD, USDJPY, GBPUSD, USDSEK, NZDUSD, USDCZK, USDSGD), todas `sem barras ha 180 s \| barsCalc=-1 \| erro=4807 \| entrada removida da cache` -> P1.118 funciona |
| `[ATR] SEM LEITURA` (gates limpos) | 12 linhas entre 15:31:05.262 e 15:32:11.607, todas `CopyBuffer sem barras \| barsCalc=-1 \| erro=4807 \| grafico=<o proprio par>` - DEPOIS do drop e da recriacao |
| `[CENARIO]` | 15:28:14.015 `XAUUSD ... ATR%=sem leitura` e 15:28:35.864 `USDCNH ... ATR%=sem leitura`, ambos do grafico `USDCNH,H1` -> o sintoma NAO fechou |
| Prova cruzada | `XAI_AtrDiag` as 15:18:10 no mesmo grafico `USDCNH,H1`: `XAUUSD atr=22.476429 atrPct=0.5485 bars=60369`, `USDCNH atr=0.002087 atrPct=0.0313 bars=66887` - o mesmo `iATR` criado por SCRIPT aquece |
| Risco | inalterado: RewardRatio 0.65 / MinRewardRatio 0.55 / MaxDailyLossUsd 60 / MaxDrawdownPercent 15 / DailyProfitTargetUsd 20 / MaxUsd 40 / StreakBrakeLosses 3 / RiskPercent 1.0 / RiskPerTradeUsd 2.0 / MinAIConfidence 60 / MaxPredictionAgeSec 900 / MinimumADX 18 / StoplessEmergencyPoints 0 / escada 5-1-7-10 USD / EnableRealAccountGuard true / AllowTradeWithoutAI false |
| Docs | `Docs\CONVERSA_20261105_P1117_V1156.md` (seccoes 6 e 9), `PENDENCIAS.md` (P1.118 e P1.119), `PROGRESS.md` (linhas do ciclo 110), `CONVERSAS.md` |

### Portas que ficaram fechadas

1. `P1.116` - fechado por medicao (duas vezes): o ruido de ATR e o ramo `CopyBuffer` sem barras.
2. `P1.117` - fechado no codigo; `ATRCacheDrop` deixou de ser codigo morto, com portao de 60 s por simbolo.
3. `P1.118` - fechado no codigo E medido em producao: 11 `[ATR] HANDLE MORTO`, uma por simbolo, com a idade de 180 s escrita na linha.
4. `Profiles\Tester\XAU_AI_PRO.set` - ficou em commit proprio `79aaccf6`; o terminal volta a tocar-lhe no comentario `; saved automatically on`, que e reescrito a cada compilacao e nao muda nenhum input.

### Portas que so o dono fecha

1. **Push**: todos os commits sao locais. `origin` = Forge MQL5, `github` = `apolopanda500/mql5`. Nada foi publicado.
2. **P1.119 (novo, aberto)**: o `iATR` criado pelo EA nunca aquece - `barsCalc=-1`/`erro=4807` nos 13 graficos mesmo depois do drop/recreate, enquanto o ADX da MESMA instancia le (ADX=51.6 na mesma linha em que o ATR% falha) e o `iATR` de um script le. Hipotese escrita: o handle nasce antes de a serie ter barras (`XAI_WaitSeriesReady` garante a serie, nao as barras) e o MT5 nao o recalcula.
3. **`[ATR] LEITURA SUSPEITA | USDBRL ...` (13:53:26.183)** - sem nova ocorrencia desde que os campos `barsCalc`/`barrasSerie`/`barrasGrafico` entraram; a proxima ocorrencia responde sozinha.
4. Herdadas de `PENDENCIAS.md`: P1.110, P1.111, contradicao de simbolos (11 em `Symbols` vs 13 graficos), `EnableVolatilityFilter=false`, gateway 401/1003 com contrato 30F vs 25F, `MCPServerToken` vazio, PF a re-medir.
5. **Conta real continua proibida**: PF 0.6206, acerto 41.4%, 10-11 perdas seguidas - e esse numero e de um build sem ADX e sem IA.

### Ciclo 1119/1120 (05/11, tarde): o diagnostico do ATR passa a poder ser lido

1. `P1.120` (v1.2.158): `ScenarioAtrPctStr` publica `sem leitura(atr=<v>,bid=<v>)` em vez do texto fixo `sem leitura`; o ramo `CopyBuffer sem barras` do `GetATR` publica o `bid`. So diagnostico - o valor devolvido continua `0.0`.
2. `P1.121` (v1.2.159): as tres chaves do portao do ATR (`atr_no_read_`, `atr_handle_morto_`, `atr_absurdo_`) passam a incluir `IntegerToString((long)__DATETIME__)`. O estado em `Common\Files\XAU_AI_PRO\loggate_*.bin` tinha 3600 s por conta e a vez de XAUUSD (15:12:30.864) e USDCNH (15:12:31.846) ja estava gasta: um build antigo calava um build novo. A janela mantem-se em 3600 s, logo nao ha mais ruido dentro do mesmo build.
3. Warning do ciclo: `VersionManager.mqh(63,147) : warning 86: 'F' - unrecognized character escape sequence`, de `Common\Files` dentro do literal do changelog; corrigido para `Common\\Files`. O texto do aviso so se le correndo o `metaeditor64.exe` com `/compile` e `/log` para um ficheiro proprio - o `metaeditor.log` guarda apenas o resumo.
4. Estado do codigo: `#property version "1.359"` e `EA_VERSION_STRING "1.2.159"`; compilacao `0 errors, 0 warnings` (build 6296, X64 Regular, 22177 ms). Binario `XAU_AI_PRO.ex5` regenerado; o EA nos graficos NAO foi recarregado.
5. Numeracao: `P1.119` continua a ser o item aberto do ciclo anterior (o `iATR` do EA que nunca aquece) - os itens deste ciclo sao `P1.120` e `P1.121`.
6. Continua proibido: push (`origin` = Forge MQL5, `github` = `apolopanda500/mql5`) e conta real (PF 0.6206, acerto 41.4 por cento, 10-11 perdas seguidas, e esse numero e de um build sem ADX e sem IA).

## Medicao de 05/11 15:40 (v1.2.159)

- conta: MetaQuotes-Demo 113568614 (hedging), saldo 12636.32 USD, 0 posicoes,
  0 ordens, servidor 20:40.
- perfil aplicado: `XAI_P216_LIVE` as 15:40:14.9; 13 graficos, todos com
  `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`, zero indicadores anexados.
- versao em producao: v1.2.159 (HG-01 em dia: 1.359 / 1.2.159).
- gateway de IA: nao arrancado nesta janela (`services_list` vazio); a URL dos
  treze graficos aponta para `http://127.0.0.1:9011/api/ai/predict` com token
  vazio (cai no `.env`), logo as entradas dependem de `AllowTradeWithoutAI`.
- ATR: os treze graficos leem hoje o ATR do XAUUSD (22.597860) e a guarda P1.112
  devolve 0.0 - ver P1.119 em `PENDENCIAS.md`. Nao ha ATR errado a chegar a
  decisao.
- git: HEAD local, sem push. Push, USDBRL, itens herdados e a proibicao de conta
  real continuam a ser portas que so o dono fecha.
---

## ENCERRAMENTO do ciclo 112 (v1.2.159) - o que fica provado e as portas que so o dono fecha

Estado no instante do fecho: HEAD `44b4bfaf` (379 commits, todos locais, nenhum push), working tree limpo, conta 113568614 (MetaQuotes-Demo, hedging) com 0 posicoes e 0 ordens, `alerts_list` vazio, `services_list` vazio, treze graficos do perfil `XAI_P216_LIVE` com `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` (v1.2.159; HG-01 em dia: `1.359` = `1.2.159`).

### O que fica PROVADO

1. Codigo: v1.2.158/P1.120 e v1.2.159/P1.121 compilam com `0 errors, 0 warnings` (build 6296, X64 Regular) e sao o que corre nos treze graficos.
2. Recarga: `profile_apply XAI_P216_LIVE` devolveu `ok`, com treze linhas `[START] XAU_AI_PRO v1.2.159` no journal, zero indicadores anexados.
3. P1.119 - causa MEDIDA: o ATR lido pelos treze graficos e o do XAUUSD (`22.597860` em nove pares; `barsCalc=60369`, que e o numero de barras do `XAUUSD,H1`), inclusive no simbolo do PROPRIO grafico com a serie provada; a cura automatica (drop + recreate) devolve o mesmo valor. A hipotese "o handle nasce antes de a serie ter barras" fica rejeitada pelos numeros.
4. Risco: nenhum ATR errado chega a decisao - todas as linhas terminam em `devolvido=0.0` pela guarda do P1.112. O custo e de DADOS (par sem candle no dataset), nao de risco.
5. `.set` do tester: a unica diferenca face a HEAD era o comentario `; saved automatically on ...` que o MetaEditor reescreve a cada compilacao; nenhum input muda (producao corre `RewardRatio 0.65`, `MinRewardRatio 0.55`, `EnableAdaptiveTargets true`).

### O que NAO fica provado (nao deve ser lido como provado)

1. P1.119 continua ABERTO: falta a sonda isolada que responda a uma pergunta unica - o terminal deduplica a instancia do indicador por (nome, timeframe, parametros) ignorando o simbolo, ou o handle nasce ligado a serie errada?
2. P1.121 nao foi provado no seu mecanismo: os `.bin` do ATR foram apagados as 15:31, logo a ausencia de bloqueio do loggate nao e atribuivel ao carimbo de compilacao `__DATETIME__`; a prova exigiria dois builds seguidos na mesma janela.
3. PF 0.6206 e acerto 41.4% nao foram remedidos neste ciclo.

### Portas que so o dono fecha

1. `push` para `origin` (Forge MQL5) e para `github` (apolopanda500/mql5): 379 commits locais, nada enviado.
2. O commit `6fe56e53` tem rotulo `docs(ciclo111)` e leva dentro o codigo v1.2.158/P1.119; separar ou aceitar e decisao do dono.
3. `USDBRL,M5` (CHART11): `ATR=3831.556600` com `barsCalc=2204` contra `barrasSerie=24599` - aberto proprio, que o P1.119 dos pares H1 nao explica.
4. Herdadas: P1.110/P1.111 (`dataset.csv` escrito por varias instancias), contradicao de simbolos (`Symbols` com 11 pares contra 13 graficos; EURUSD sem grafico; USDCZK/USDRUB/USDSGD com grafico e fora de `Symbols`; CHART11 em USDBRL,M5), `EnableVolatilityFilter=false` nos treze, gateway de IA com 401/1003 e contrato de features 30F contra 25F (`services_list` vazio, sem gateway a correr).
5. Conta real continua PROIBIDA: o numero conhecido (PF 0.6206, acerto 41.4%, 10-11 perdas seguidas) e de um build sem ADX e sem IA.

### O que fica a correr

Treze graficos com o EA anexado, `AutoTrade=true`, conta demo, 0 posicoes, 0 ordens, 0 alertas, 0 servicos. O EA nao foi removido dos graficos nem o AutoTrading foi desligado: o pedido foi fechar o TRABALHO, nao parar a producao. Para parar de vez, remover o EA dos treze graficos (ou desligar o AutoTrading) - accao de um clique, do dono.
## 05/11 19:08 - P1.119 medido (v1.2.160 compilada, NAO recarregada)

- Sonda `Scripts/XAI_AtrDiag.mq5` v1.010 as 19:16:10 no grafico `AUDUSD,H1`:
  handles `10`..`23` distintos, um por simbolo, cada um com `barsCalc` igual as
  barras do SEU simbolo; mesmo par -> mesmo handle; outro par/periodo -> handle
  novo. O terminal NAO deduplica e nao liga o handle a serie errada num script.
- EA em producao: o `ATR%` do mestre `USDCNH,H1` alterna entre `0.03` e
  `sem leitura` a cada ~90 s, e os ciclos maus sao os mesmos em que o ADX e o
  RSI falham (`[DATA] SEM LEITURA` em 5 graficos as 19:00:35-19:01:11 com
  `ATR=0.000000`, `RSI=0.00`, `ADX=51.17`). O ATR a zero e sintoma do P1.110.
- Binario: v1.2.160 (`#property version "1.360"`), `0 errors, 0 warnings`.
  Os 13 graficos continuam a correr a v1.2.159: falta recarga autorizada.

## 05/11 19:53 - P1.123 corrigido (v1.2.161 compilada, NAO recarregada)

- `Core/SignalCore.mqh`: handles do sinal em cache por simbolo; sem `IndicatorRelease` na leitura.
- `XAU_AI_PRO.ex5` reconstruido: 913720 B, 19:53:30, 0 errors / 0 warnings.
- Causa medida das 24 h sem entrada: EMA de tendencia contaminada (44.60460 repetido em 5 simbolos) -> `ScenarioTrendGate` vetou 100% dos sinais.
- Os 13 graficos continuam a correr v1.2.159 ate haver reload autorizado.

## 05/11 20:00 - P1.125 corrigido (v1.2.162 compilada, NAO recarregada)

`AI/AIEngine.mqh` `GetAIConfidence`: o teto do fallback (`AIUnavailableConfidenceCap=40`)
era aplicado quando `AIGateRequired()` era verdadeiro (modo em que a IA e obrigatoria),
logo `AITradeAllowed()` devolvia false sempre - 40 < `MinAIConfidence` 60. Passa a marcar
`aiReal` e a capar so o fallback. 0 errors / 0 warnings, ex5 915628 bytes as 19:59:27.

Medido antes: 25 `[VALIDATION] BLOCK | AI` em 05/11, 0 `AI OK`, 0 `[ADV AI]`; gateway
9011 com 401 no root e nos 11 simbolos; `AIGatewayToken` vazio nos 13 graficos.

Continua por fazer: reload dos 13 graficos (a correr v1.2.159) e a decisao do dono sobre
o token do gateway ou `EnableAutonomousMode=true`.