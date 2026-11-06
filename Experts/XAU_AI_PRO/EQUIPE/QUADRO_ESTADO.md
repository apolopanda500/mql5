# QUADRO DE ESTADO - XAU_AI_PRO (medido, nao opinado)

Regra: toda linha tem **numero** e **hora**. Linha sem medida nao entra aqui -
entra no diario do agente.

Ultima medicao global: **05/11/2026 21:41** (DELTA).

---

## 1. Versao e binario

| Item | Valor | Como foi medido |
|---|---|---|
| Fonte no disco | **v1.2.167** | `XAU_AI_PRO.mq5:2` = `// XAU_AI_PRO v1.2.167`; `:22` = `#property version   "1.367"` |
| `EA_VERSION_STRING` | `"1.2.167"` | `Enterprise/VersionManager.mqh:1` |
| Ultimo compile | **0 errors, 0 warnings** | 05/11 21:33, 22 579 ms, cpu X64 Regular (DELTA) |
| `XAU_AI_PRO.ex5` | **928 854 bytes**, 05/11 **21:36** | `dir` na pasta do EA |
| Versao rodando | **build de 21:57** nos **13 graficos** | reattach **22:10:47.878 -> 22:11:06.500**: **13x `[START] XAU_AI_PRO v1.2.167`**, cada um precedido de `[STOP] ... motivo=1` (ALFA, `D-014`) |
| Binario em disco | **927 354 B**, 05/11 **21:57:47** (compile CMD, 0/0) | **carregado nos 13 graficos desde 22:10:47** (`D-014`). Medido 22:18: nenhum `.mq5`/`.mqh` mais novo que o `.ex5`, logo binario e fontes batem |
| Perfil ativo | `XAI_P216_LIVE` | `profile_apply` 21:37 -> `ok:true` |
| Ultimo commit local | `d23b42c6` = v1.2.167 (05/11 21:59) | `git log -1`; **push para `github/main` feito: `dc1db5e5..d23b42c6`** |
| Compile de 05/11 21:57 | **0 errors, 0 warnings**, 20 825 ms, `.ex5` **927 354 B** 21:57:47 | `metaeditor64.exe /compile` (CMD) |
| Espelho | **110/110 fontes, 0 divergentes** (21:57) | SHA-256, CMD |

> Correcao de fato: o `AGENTE_1.md` §4.1 diz "versao rodando = v1.2.159".
> Isso estava certo as 21:36:00 e ficou **errado as 21:36:40**. Medido agora:
> producao roda **v1.2.167**. O reload aconteceu por compilacao (o terminal
> reanexa sozinho o `.ex5` recompilado) e foi reforcado pelo `profile_apply`.

---

## 2. Conta e graficos

| Item | Valor |
|---|---|
| Conta | demo **113568614**, MetaQuotes Ltd./MetaQuotes-Demo |
| Saldo / equity | 12 636.32 / 12 636.32 |
| Graficos abertos | **13**: XAUUSD H1, USDSEK, USDJPY, USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD (H1), USDBRL **M5**, USDRUB, USDSGD (H1) |
| `USDCOP` / `USDCLP` | estavam no perfil as 21:37 (15 graficos) e **nao estao** as 21:39 |
| Posicoes abertas | **0** (`[RESUMO]` 21:39:36: `posicoes: 0 EA (+0.00 USD) + 0 manual`) |
| Trades do dia | **0** |

---

## 3. Posse (ver PROTOCOLO §4)

| Zona | Dono |
|---|---|
| `AI/**`, `Core/SymbolManager.mqh`, `Core/Config.mqh`, `Indicators/**` | ALFA |
| `Monitoring/**`, `Enterprise/NotificationCenter.mqh`, `Monitoring/AccountLogGate.mqh`, build/deploy/terminal | DELTA |
| app `MQL5/Files/XAU_AI_PRO/**`, `backend/**`, espelho | CMD |
| `XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh` | compartilhado, 1 por vez |
| `PENDENCIAS.md`, `PROGRESS.md`, `Tools/HANDOFF.md` | append-only, cada um no seu bloco |
| **`git`: commit, push e deploy** | **CMD** (decisao do dono, 05/11 21:56) |

> **Build x commit x deploy (dono, 05/11 21:56).** O dono atribuiu ao **CMD**
> as tres operacoes de publicacao: `commit`, `push` e `deploy`. Isso **nao**
> autoriza `git add -A`: 91 entradas no working tree, das quais 81 sao a arvore
> espelhada `Files/XAU_AI_PRO/MQL5/**`. Commit e sempre por caminho explicito.
> `push` para `origin` (Forge) continua **proibido** (credencial expirada,
> `D-001` do legado); `push` para `github` exige o "vai" do dono por evento.
> As outras camadas (codigo MQL5, app, docs) ficam em aberto ate o dono dizer.

Arquivos **contaminados por dois agentes** (precisa de acordo antes da proxima
edicao): `AI/AIConnector.mqh` (ALFA pos guarda `deBolsa` do GOLD-acao;
DELTA pos `AIClockRelogio`), `XAU_AI_PRO.mq5`,
`Enterprise/VersionManager.mqh`.

---

## 4. Provas fechadas (com evidencia)

| Ciclo | Versao | O que ficou provado | Evidencia |
|---|---|---|---|
| P1.126 | v1.2.163 | EA reconecta sozinho ao gateway | `[AI] GATEWAY RECUPERADO` 20:35:04.522, `falhas=159 cego=357s resposta=357B sem intervencao` |
| P1.127 | v1.2.164 | falha e recuperacao visiveis no journal | `[AI] GATEWAY \| HTTP 1001` 20:29:09.157 / 20:34:09.379; recuperacao 20:35:04.522 |
| P1.128 | v1.2.165 | relogio do rasto de reconexao nao congela com o broker em baixo | `AccountLogGate` + gate com `TimeLocal()` |
| P1.129 | v1.2.166 | notificacao deixou de sair 1x por GRAFICO | antes: `[RELATORIO]` 8x 20:28:21 e 12x 20:29:29; 13x `EA finalizado(reason=9)` 20:28:49. depois: **1x** `reason=9` 20:50:54.593 e **1x** `[RELATORIO]` 20:51:34.589 |
| P1.131 (DELTA) | v1.2.167 | gates de notificacao continuam a segurar 13 graficos | 05/11 21:36:40 reload -> **1x** `EA finalizado(reason=2)`; 21:37:09 -> **1x** `reason=9`; 21:39:27 -> **1x** `reason=9`. Zero `[RELATORIO]` depois de 01:51:33 (servidor) |

---

## 5. Fila aberta (ID unico e dono)

| ID | Resumo | Dono | Estado |
|---|---|---|---|
| P1.110 | contaminacao de simbolo por instancia | ALFA | aberto |
| P1.111 | varias instancias escrevem `dataset.csv` sem sincronismo | CMD | aberto |
| P1.119 | dedup de instancia de indicador por (nome, periodo, params) ignorando simbolo | ALFA | aberto |
| P1.124 | gateway 401 + features 30F vs 25F | CMD | aberto |
| **P1.130** | **COLISAO**: ALFA = universo `SymbolsFromMarketWatch` + guarda GOLD-acao; DELTA = os dois relogios `TimeCurrent` restantes | **FECHADA (a)** ALFA/DELTA 21:53 | **ABERTO** |
| P1.131 | DELTA: relogios de `AIConnector`/`OperatorBrief` unificados em `AIClockRelogio()` | DELTA | **fechado, prova na §4** |
| - | `[ATR] LEITURA SUSPEITA \| USDBRL \| ATR=3831.556600 \| ATR%=69424.83 \| barsCalc=2204 \| barrasSerie=24599` | ALFA | aberto |
| - | PF 0.6206 a remedir (win rate 41.4%, 10-11 perdas seguidas) | CMD | aberto |
| - | `EnableVolatilityFilter=false` nos 13 graficos | dono | aberto |
| - | gateway Python **nao** e servico Windows: nao sobrevive a reboot | CMD | aberto |
| - | 12 chamadas `POST /api/ai/predict` **sem credencial** vindas de outro processo | CMD | aberto |
| - | espelho da app 158 versoes atras (agora sincronizado, nao commitado) | CMD | aberto |

---

## 6. Bloqueio de operacao (medido)

Duas causas, encadeadas:

1. **P1.125 (v1.2.162, commitado)** - `GetAIConfidence` aplicava
   `AIUnavailableConfidenceCap` (40) quando `AIGateRequired()` era verdadeiro, e
   40 < `MinAIConfidence` (60): o gate de IA era insatisfativel para **todos**
   os simbolos. Journal 05/11 01:00-14:54: 25 `[VALIDATION] BLOCK | AI`, zero
   `AI OK`.
2. **Gateway sem autorizacao** - HTTP **401** na raiz, `/health` e
   `/api/ai/predict` (XAUUSD, EURUSD, USDCNH, USDSGD).
   `XAU_AI_GATEWAY_TOKEN`/`XAU_AI_API_TOKEN` nao existem no ambiente e
   `AIGatewayToken` esta vazio nos 13 graficos.

Com `AllowTradeWithoutAI=false` + `EnableAIFilter=true` +
`EnableAutonomousMode=false`, nenhum simbolo passa. **Nao e bug** - e o
comportamento documentado.

Filtros corretos funcionando (nao sao defeito): `[VALIDATION] BLOCK | TREND SELL
| USDCAD | contramao vetada | ADX=57.8 >= 22.0`; `GBPUSD | ADX=17.76 | Min=18.00`.

**Decisao do dono, bloqueante:** (a) provisionar token no gateway **ou**
(b) `EnableAutonomousMode=true` (IA vira consultora).

> **FECHADO em 05/11 22:15 — `D-011` + `D-012`.** Nao ha bloqueio de
> autenticacao: o EA autentica (journal `[AI] GATEWAY ... 1121 bytes |
> disponivel=true`, zero 401 entre 21:36:45 e 21:39:59). A causa real de
> `trades=0` e outra e esta medida: so o **XAUUSD** tem modelo publicado (H1);
> os outros **20** devolvem `disponivel=false`; e `MinAIConfidence=60.0` contra
> CONF **56.6-63.3**. `[SCANNER] RESUMO` 22:02:10: `visitas=1489 | sinais=142 |
> trades=0 | bloqueios=1489`. **Nao e bug de codigo** — e configuracao de risco
> e cobertura de modelo, decisao do dono.

### 6.1 Correc&#807;ao medida (CMD, 05/11 21:51) — a causa 2 acima esta ERRADA

Medido agora, sem imprimir o valor do segredo:

| Prova | Resultado |
|---|---|
| `XAU_GATEWAY_TOKEN` no `.env` da raiz da app | **existe, 64 caracteres** |
| `GET /api/ai/predict?symbol=XAUUSD&timeframe=H1` **com** `Authorization: Bearer` | **HTTP 200**, `available=true`, `signal=BUY`, `conf=57.2` ("inferencia real do modelo publicado") |
| mesma rota **sem** cabecalho | HTTP 401 (fail-closed correto) |
| `GET /` e `/health` com token | HTTP 404 — as rotas nao existem; a autenticacao passou |
| `M15` / `M5` | 200 com `available=false`: o modelo so esta publicado em H1 |

Portanto **nao falta token no gateway**. O que continua por provar e o outro
lado: o `AI/AIConnector.mqh` monta `Authorization: Bearer <AIGatewayTokenEfetivo()>`
(L1037-L1040) e o `AIGatewayTokenEfetivo()` le o `.env` (L793) — falta a linha
de journal que prove que o EA **encontra** esse ficheiro a partir do terminal.
Se o EA levar 401, a falha e de caminho/leitura do `.env`, nao de credencial.

**Consequencia para `D-004`:** a opcao (a) nao exige provisionar nada; a
opcao (b) (`EnableAutonomousMode=true`) e desnecessaria para destravar
autenticacao e **nao deve** ser escolhida para esse fim.

---

Registro da colisao de ID (05/11 21:53, DELTA): `D-002` fechada em (a) -
`P1.130` = universo do ALFA, `P1.131` = relogios do DELTA. Os comentarios dos
fontes foram renomeados (5 pontos, comentario apenas) e o `.ex5` em producao
continua o do compile de 21:36:40: **fonte e binario dessincronizados por
comentario**, comportamento igual. Falta 1 compile, agora do CMD (`D-006`).

Medido 22:07 (DELTA), depois do ciclo do CMD: compile **0 errors, 0 warnings**
as 21:57:47 -> `.ex5` **927 354 B, 21:57**; **zero `[START]`** no journal entre
21:55 e 22:12 e `Notifications.log` parado em **2188 linhas** -> o EA **nao**
recarregou; producao corre o binario carregado as 21:39. Diferenca entre os dois
binarios: **comentario apenas** (`P1.130` -> `P1.131`). Commits do CMD: EA
`d23b42c6` (push `github/main` `dc1db5e5..d23b42c6`), espelho `1bb5122` em
`develop` (**nao** pushed).

Autorizacao total do dono aos 3 agentes (05/11 22:10, `D-012`): ALFA, DELTA e CMD
operam sem pedir autorizacao passo-a-passo dentro das suas zonas - ler journal,
compilar, commitar, `push` para `github`, publicar o espelho e **reanexar os
graficos**. `D-003` (quem reanexa) e o push do espelho (`D-011`) ficam fechados
por isso. **Limites que nao se movem:** conta real, parametros de risco/lote/
stop/alvo/spread, remocao de guardas, `push` para `origin`/CodeBase.
Serializacao continua: **1 compila por vez, 1 reanexa por vez**, anunciado antes.

**Reattach feito as 22:10:47-22:11:06 (ALFA), medido 22:20 (DELTA):** 13
`[START] XAU_AI_PRO v1.2.167`, um por grafico, e `Notifications.log` de 2188 para
2189 linhas com **uma unica** linha nova para 13 reloads (o gate do `P1.129`
segura uma rajada de 13). **Producao corre agora o build das 21:57:47 - fonte e
binario batem.** `D-003` fecha por execucao.

Medido 22:20 (DELTA), depois do reattach: **13 graficos vivos** - 13 `[AI]
GATEWAY` entre 22:11:04 e 22:11:37, um por grafico; XAUUSD `1121 bytes |
disponivel=true`, os outros 12 `357 bytes | disponivel=false`. `[RESUMO]`
22:16:06 master=SIM, posicoes 0, trades=0. **Ressalva medida:** 10 simbolos com
`[ATR] HANDLE MORTO | barsCalc=-1 | erro=4807` entre 22:14:26 e 22:18:04 e o
USDCNH ainda `ATR%=sem leitura` as 22:20:25 - o handle **nao** e recriado no uso
seguinte. Registado ao ALFA em `INBOX_AGENTE_1.md`; nenhum codigo foi tocado.

Ultima alteracao: 05/11/2026 22:20 - DELTA.


---

## 6. Documentos de comando da equipe (D-018, 05/11 22:55)

| Documento | O que fixa | Estado |
|---|---|---|
| `PLANO_10_10.md` | fases `F0`..`F9`, portoes numericos, mapa de donos, definicao de 10/10 | publicado |
| `BACKLOG.md` | `B-001`..`B-034` com dono, criterio e estado | publicado |
| `FERRAMENTAS.md` | runtimes, MCP instalados, scripts, contrato de limpeza | publicado |

**Medido as 22:55:**

- `sync-agent.ps1 check` -> **OK, sem problemas** (21 IDs unicos, 16 perguntas).
- `Tools/equipe-audit.ps1 all` -> UTF-8 ok, **espelho 110/110, 0 divergentes**.
- Fila do DONO: **Q-001..Q-016**, 16 abertas.
- Producao: **v1.2.167 nos 13 graficos** desde 22:10:47.
- Trades: **0** (razao medida: 1 modelo H1 de 21 simbolos + `MinAIConfidence`
  60 vs CONF 56-63). Decisao de universo entregue ao DONO em `Q-013`.
- Conta real: **bloqueada** pelos portoes `F2` e `F6` do `PLANO_10_10.md`.


---

## Actualizacao 05/11/2026 23:08-23:25 (DELTA)

### Configuracao viva dos 13 graficos - medida por `list_open_charts`, nao por amostra

| # | Simbolo | TF | Magic | `AllowTradeWithoutAI` | `EnableVolatilityFilter` | `AIGatewayToken` |
|---|---|---|---|---|---|---|
| 01 | XAUUSD | H1 | 2026001 | true | false | `""` vazio |
| 02 | USDSEK | H1 | 2026001 | true | false | `""` vazio |
| 03 | USDJPY | H1 | 2026001 | true | false | `""` vazio |
| 04 | USDCHF | H1 | 2026001 | true | false | `""` vazio |
| 05 | USDCZK | H1 | 2026001 | true | false | `""` vazio |
| 06 | USDCAD | H1 | 2026001 | true | false | `""` vazio |
| 07 | USDCNH | H1 | 2026001 | true | false | `""` vazio |
| 08 | AUDUSD | H1 | 2026001 | true | false | `""` vazio |
| 09 | NZDUSD | H1 | 2026001 | true | false | `""` vazio |
| 10 | GBPUSD | H1 | 2026001 | true | false | `""` vazio |
| 11 | USDBRL | **M5** | 2026001 | true | false | `""` vazio |
| 12 | USDRUB | H1 | 2026001 | true | false | `""` vazio |
| 13 | USDSGD | H1 | 2026001 | true | false | `""` vazio |

Barras carregadas: 100 000 em 8 graficos; USDSEK 100 000; USDCZK 72 099; USDCNH 66 895; USDBRL 24 627; USDRUB 26 711; XAUUSD 60 375.

### O que os `.chr` em disco dizem - e a data que explica tudo

`MQL5\Profiles\Charts\XAI_P216_LIVE\CHART01..CHART13.CHR` - **os 13 com `LastWriteTime = 2026-11-05 21:37:10`**, exactamente a hora do `profile_apply` do perfil.

Valores lidos (UTF-16): `AllowTradeWithoutAI=false`, `EnableAIFilter=true`, `EnableAutonomousMode=false`, `MinAIConfidence=60.0`, `RiskPercent=1.0`, `MaxDailyLossPercent=10.0`, `MaxDrawdownPercent=15.0`, `SymbolsFromMarketWatch=true`.

**Nao ha contradicao com o runtime: ha duas datas.** O `.chr` e a ultima gravacao do perfil (21:37:10); o `true` do `AllowTradeWithoutAI` foi posto no reattach das 22:10:47 e **nunca foi gravado em disco**.

### Risco P0 aberto por esta medicao

Um **restart do terminal** carrega os `.chr` das 21:37:10 e devolve `AllowTradeWithoutAI=false` aos 13 graficos, anulando o `D-014` e o `Q-014` sem decisao registada. Enquanto a configuracao viva nao for gravada (e o mtime nao for reconferido), vale por escrito: **a configuracao de producao nao sobrevive a um restart**. Pergunta ao DONO em `INBOX_DONO.md` (3 opcoes numeradas; voto do DELTA: `Q-019` -> reattach -> gravar -> medir mtime).

### `F2.8` / `F2.7` - numeros do impacto

`MagicNumber=2026001` nos **13 de 13**, logo os limites por instancia multiplicam por 13:

| Limite | Por grafico | Tecto teorico |
|---|---|---|
| `MaxOpenPositions` | 50 | 650 |
| `MaxTradesPerDay` | 100 | 1300 |
| `MaxTotalRiskPercent` | 10.0 | **130 % do capital** |
| `MaxCorrelatedTrades` | 3 | 39 |
| `MaxCorrelatedRiskPercent` | 3.0 | 39 % |

### Outras constantes medidas (13/13)

`AIUnavailableConfidenceCap=40.0` e `MinSimulationProbability=0.5` (a cadeia do `D-028`); `RewardRatio=0.65` vs `MinRewardRatio=0.55`; `StopLossPoints=300` / `TakeProfitPoints=600`; `RiskPerTradeUsd=2.0`, `MaxRiskPerTradeUsd=8.0`, `MaxRiskPerTradePercentCap=3.0`; `AvoidHoursGMT=9,11,14,18,20,22` com `EnableAvoidHoursGMT=true` (**6 horas por dia** bloqueadas); `EnableDataset=true` + `SaveDatasetCSV=true` (**o `P1.111` esta activo em producao**); `EnableDatabase=false`; `EnableRealAccountGuard=true`.

### Estado das provas nesta hora

| Item | Estado | Prova |
|---|---|---|
| `B-031` backtest reprodutivel | **A CORRER** | `run_id 7704874073263362126`, `started`, 00:13:35 -> 00:16:37 de ~00:36. Sem PF/DD/trades |
| `B-011` ATR | por provar | `P1.132` compilado as 23:12:18, **nao reattachado** (`Q-019`) |
| Espelho EA | **1 divergente** | `[FAIL] DIFF Indicators\VolatilityFilter.mqh` |
| Canal | **integro** | `equipe-sync.ps1 check` = 0 problemas, 11 ficheiros `CR=0` e UTF-8 |
| Binario | **mudou 3x** | 927 354 B (21:57:47) -> 928 854 B (build 00:36:40) -> 929 558 B (23:12:18) |
| Trades | **0** | inalterado |

Fonte: DELTA, `D-031` e `AGENTE_2.md` bloco 23:05-23:25. Nenhum parametro de risco alterado, nenhum `.ex5` compilado, nenhum reattach, nenhum commit.
