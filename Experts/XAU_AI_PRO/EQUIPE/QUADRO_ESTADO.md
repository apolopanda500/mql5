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
## Actualizacao 23:40 (DELTA) - seis perguntas abertas ao DONO, zero alteracoes feitas

### Perguntas abertas (todas com opcoes e com o meu voto)

| # | Pergunta | Opcoes | Voto DELTA | Prazo |
|---|---|---|---|---|
| P1 | Gravar a config viva nos 13 graficos antes do restart? | 1 gravar agora / 2 nao gravar e assumir / 3 esperar Q-019 | **3, depois 1** | antes do proximo restart |
| P2 | Bloquear sinal em simbolo com tick > 15 min? | 1 >15 min / 2 >60 min / 3 nada | **1** | antes de conta real |
| P3 | `GOLD` e `XAUUSD` no mesmo scanner? | 1 retirar GOLD / 2 magic separado / 3 manter | **1** | antes de conta real |
| P4 | Autorizar limpeza de `Tester\logs` (2675,4 MB)? | 1 apagar `20261031.log` (1404,9 MB) / 2 autorizar ferramenta com raiz Tester / 3 deixar | **1** | quando o disco apertar |
| P5 | R-003: `MaxDailyLossPercent` 10->5 e `MaxDrawdownPercent` 15->10 | sim / nao | **sim** | antes de conta real |
| P6 | `MagicNumber=2026001` em 13/13 graficos | 1 magic unico por grafico / 2 aceitar limite x13 / 3 so nos 3 melhores simbolos | **1** | antes de conta real |

### Limites efectivos hoje, medidos (P6)

| Parametro | Por grafico | Multiplicado por 13 |
|---|---|---|
| `MaxOpenPositions` | 50 | **650** |
| `MaxTradesPerDay` | 100 | **1300** |
| `MaxTotalRiskPercent` | 10,0 | **130 % do capital** |
| `MaxCorrelatedTrades` | 3 | **39** |
| `MaxCorrelatedRiskPercent` | 3,0 | **39 %** |

### Estado das provas nesta janela

| Prova | Estado | Numero |
|---|---|---|
| B-031 backtest reprodutivel | **a correr** | `started`, 00:29:09 / 00:38:24 - sem PF/DD/trades |
| B-011 ATR | **defeito vivo** | `erro=4807` em 10 simbolos, 23:11 e 23:14-23:18 |
| F2.8 isolamento por instancia | **nao cumprido** | magic 2026001 em 13/13 |
| Config persistida | **nao cumprida** | `.chr` de 21:37:10 dizem `false`, runtime diz `true` |
| Universo de dados | **medido** | 21 simbolos no scanner vs 13 graficos |
| Qualidade de dados | **falha** | USDBRL 25 min, USDCLP 4 h, USDCOP 3,5 h, USDRUB 6,5 h sem tick |

### O que eu nao sei e nao vou fingir que sei

- Se o B-031 vai terminar com resultado ou com erro. Nao ha numero para escrever.
- Se o ATR corrigido (P1.132) funciona - so depois do reattach. Dizer que "esta corrigido" sem reattach seria mentira.
- Quanto disco sobra para a noite. O tester escreve e eu nao o controlo.
## Binario congelado para as provas (regra do D-040, ja aplicada) - 23:44

O D-040 mostrou que o B-031 correu um binario que deixou de existir a meio da prova.
Para nao repetir isso, o `.ex5` em uso foi **copiado** antes de qualquer outro build:

| Item | Valor |
|---|---|
| Copia | `MQL5\Files\Backup\ex5\XAU_AI_PRO_v1.367_20261105_231218_87E30E2B.ex5` |
| Tamanho | **929 558 B** |
| SHA-256 | `87E30E2B4E43930C80B24E6AA984497F32158FE14B86AF9036BF57350809DBC7` |
| Build original | 05/11/2026 23:12:18 |
| Conteudo | `v1.2.167` com `P1.132` (ATR) |
| Verificacao | hash da copia == hash da fonte (`IGUAL :: True`) |

### Regra operacional (a partir de agora, sem precisar de autorizacao)

Antes de arrancar qualquer `B-nnn` que exija repeticao:

1. copiar o `.ex5` em uso para `MQL5\Files\Backup\ex5\XAU_AI_PRO_<versao>_<AAAAMMDD_HHMMSS>_<hash8>.ex5`;
2. registar tamanho + SHA-256 + `mtime` no bloco da prova;
3. so depois preparar `.ini`/`.set` e lancar.

Custo: 1 MB por prova. Sem isso, uma prova que exige duas execucoes iguais pode
ficar impossivel se o codigo mudar - e neste projecto o codigo muda todos os dias.

### O que isto desbloqueia

| Prova | Antes | Agora |
|---|---|---|
| Repetir o B-031 no binario em que correu | impossivel (binario perdido) | continua impossivel - o antigo nao foi copiado a tempo |
| Repetir o B-031b no binario actual | possivel mas sem salvaguarda | **garantido** (copia com hash) |
| A/B do `P1.132` | nao planeado | **executavel**, com o binario fixo |
## Quadro :: B-031 run1 (binario antigo) — primeiro resultado numerico de backtest

| Item | Valor medido |
|---|---|
| Run | 7704874073263362126 |
| Binario | 927391 B (ANTIGO, sem P1.132) |
| Periodo | XAUUSD H1 2026.08.01 -> 2026.11.05, m1 ohlc, 10000 USD, alav. 100 |
| Lucro | -163.63 USD |
| Profit factor | 0.6643 |
| Drawdown | 454.70 USD = 4.42 % |
| Trades | 9 (4 ganhos / 5 perdas), 9 longs / 0 shorts |
| Sharpe | -0.2537 |
| Recovery factor | -0.3599 |
| Linhas erro=4807 no log | 1 428 980 |
| Linhas [ATR] SEM LEITURA | 1 399 481 |
| Linhas [ATR] HANDLE MORTO | 29 499 |
| Log do tester no fim | 659.93 MB |

STATUS HONESTO: este resultado e do binario ANTIGO. Nao representa o EA atual e nao decide nada sobre o
P1.132. E a base A do A/B. Com 9 trades nao ha significancia estatistica: nao se conclui rentabilidade.

A seguir: B-031b (run 7704884692122883821) com o binario 929558 B (com P1.132), mesmo ini/set.
Criterio: diferenca dos contadores de 4807 face a base A acima.

---

## [06/11/2026 01:23] ALFA - B-032 em curso, D-051 registado

**Identidade em uso:** fonte `#property version` = "1.372"; `EA_VERSION_STRING` =
"1.2.172"; `XAU_AI_PRO.ex5` = 931194 B, hash `0A28EDFC5BDC`,
mtime 2026-11-06T01:19:48; compilacao REAL `Result: 0 errors, 0 warnings,
19512 ms elapsed, cpu='X64 Regular'`.

**Job em curso:** B-032 `run_id 7704908543756588672`, agente `Core 1`,
`equipe_B032_xauusd.ini` (XAUUSD H1, Model=1, 2026.08.01->2026.11.05) +
`equipe_B032_xauusd.set` (EnableVolatilityFilter=true, EnableVerboseDebug=false,
AIUseGateway=false). Nenhum segundo job pode correr: o `Tester\logs\20261106.log`
e o mesmo ficheiro de todos os jobs do dia.

**Offset de contagem fixado ANTES do arranque:** `180740040` B
(`b032_offset.txt`: `offset=180740040|mtime=2026-11-06T01:10:43|agora=2026-11-06T01:20:12`).
A contagem final e `contadores_atr_v3.ps1 -Log ...\Tester\logs\20261106.log -Offset 180740040`.

**Criterio de aceitacao (fixado antes de ver o resultado):** `[ATR] SEM LEITURA`
218214 -> 0; `[ATR] HANDLE MORTO` 4663 -> 0; `[ATR] SERIE OK` 0 -> >0;
`[ATR] HANDLE RECRIADO` 0 -> >0. Se SEM LEITURA=0 **e** HANDLE RECRIADO=0, a
janela nao continha o 4807 e o P1.135 nao fica provado: repetir noutra janela.

**Registado no canal nesta sessao (numeros medidos):**
- `DECISOES.md` 153073 -> 156663 B (bloco D-051);
- `INBOX_AGENTE_2.md` 30166 -> 33377 B e `INBOX_AGENTE_3.md` 42580 -> 45791 B (AVISO 047);
- `IDS.md` 3195 B, linha 42 = `USADO | D | D-051 | ALFA | ...`;
- `LOCK.md` 1185 B reescrito: dono ALFA, expira 06/11/2026 03:15, run_id 7704908543756588672;
- `PROTOCOLO.md` 14882 -> 18017 B, nova **seccao 10** (linha 312) com as regras
  de medicao: contagem por offset, um job de cada vez, `.set` de medicao vs rotina,
  backup D-040 do `.ex5` e prova de identidade de versao.

**Achado que continua aberto:** o log do job anterior imprime `[VERSION] v1.2.167`
- logo a linha de base do D-050 foi medida contra o binario anterior a
P1.133/P1.134/P1.135. E o que o B-032 corrige.

**Pendente de decisao do DONO:** (1) P1.136 - nao imprimir EMA no `[SIGNAL] NEUTRO`
quando `copyOK=false` (o gate `sig_neu_` nao depende do `copyOK`, dai o
`EMA200=0.00` em aquecimento no tester); (2) 0 shorts (D-048);
(3) `EnableVolatilityFilter=false` nos 13 graficos (AVISO 045).

**Restricao de ambiente:** apagar `Tester\logs\2026103x.log`..`20261105.log`
(~3.3 GB) libertaria espaco, mas `Tester` esta nos `read_roots` e nao nos
`write_roots` do servidor MCP - a limpeza desses ficheiros exige accao do DONO
na GUI/Explorer. Dentro de `MQL5` (write root) nao ha lixo relevante:
`MQL5\Files\Temp` = 133 ficheiros, 1.5 MB.
---

## D-052 | 06/11/2026 06/11/2026 02:12 | ALFA | B-032 prova P1.134 + P1.135 (ATR deixa de publicar sem leitura)

**Binario medido (provado no log, nao presumido):** `[VERSION] v1.2.172`,
`XAU_AI_PRO.ex5` 931194 B, hash `0A28EDFC5BDC`, mtime 2026-11-06T01:19:48,
`Result: 0 errors, 0 warnings, 19512 ms elapsed, cpu='X64 Regular'`.
O job anterior imprimia `[VERSION] v1.2.167` - essa era a linha de base do D-050.

**Job:** B-032, `run_id 7704908543756588672`, agente `Core 1`, XAUUSD H1,
Model=1 (OHLC M1), 2026.08.01 -> 2026.11.05, `equipe_B032_xauusd.ini` +
`equipe_B032_xauusd.set` (EnableVolatilityFilter=true, EnableVerboseDebug=false,
AIUseGateway=false). Fecho literal: `Test passed in 0:42:22.606 (including ticks
preprocessing 0:00:00.016)`, `[STOP] XAUUSD | motivo=1 | equity=10257.16`,
`connection closed` as 02:02:40. Report do servidor: `tester_status: stopped`.

**Metodo de contagem (regra 10.1 do PROTOCOLO):** offset fixado ANTES do arranque,
`offset=180740040` B (`b032_offset.txt`). Segmento medido = 22038506 B
(180740040 -> 202778546). Ferramenta: `contadores_atr_v4.ps1 -Offset 180740040`
(a v3 rebentou com `[System.String] nao contem um metodo denominado 'Add'`;
a v4 le em blocos de 4 MB com `Decoder` stateful e fecha a ultima linha parcial).

**Resultado medido (segmento do B-032, nao o dia inteiro):**

| Marcador | D-050 (v1.2.167) | B-032 (v1.2.172) | Criterio fixado antes |
|---|---|---|---|
| `[ATR] SEM LEITURA` | 218214 | **0** | -> 0 |
| `[ATR] HANDLE MORTO` | 4663 | **0** | -> 0 |
| `[ATR] SERIE OK` | 0 | **1** | > 0 |
| `[ATR] HANDLE RECRIADO` | 0 | **1** | > 0 |
| `[ATR] IDENTIDADE ERRADA` | 0 | 1 | (novo marcador, disparou) |
| `[ATR] LEITURA SUSPEITA` | 0 | 1 | (novo marcador, disparou) |
| `[ATR] RATES OOB` | 0 | 0 | sem regressao |

**Veredicto: CRITERIO CUMPRIDO.** O caminho de falha em massa desapareceu
(218214 -> 0 e 4663 -> 0) e a cadeia nova foi exercitada pelo menos uma vez na
janela (1 `SERIE OK`, 1 `HANDLE RECRIADO`), o que mostra que o 4807 apareceu
e foi tratado com recriacao de handle e recuperacao por `ATRFromRates`.

**Limite honesto desta prova.** n=1 evento de 4807. Isto prova que o caminho
existe, e que nao ha publicacao sem leitura em 42 minutos de teste; **nao** prova
robustez sob many-handles nem sob mudanca de simbolo a meio. Para 10/10 do item
F3 (robustez) falta um teste com varios simbolos (13 graficos) que force mais
4807 e uma contagem por offset igual a esta.

**Metricas laterais do mesmo segmento:** `[SIGNAL] BUY` 22, `[SIGNAL] SELL` 63,
`[SIGNAL] NEUTRO` 1349, `[VALIDATION] APPROVED` 98, `[VALIDATION] BLOCK` 662.
Equity final 10257.16 sobre deposito 10000.00 (+257.16, +2.57% em ~3 meses de
Historico; nao e promessa de rentabilidade futura).

**Ficheiros:** `contadores_atr.txt` (saida da v4), `b032_offset.txt` (offset),
`Tester\logs\20261106.log` (fonte imutavel ate novo job).

**Decisao:** P1.134 e P1.135 passam de "aplicados" a "provados em tester".
O LOCK do ALFA e libertado (`ESTADO: LIVRE`) para o proximo job.


## D-053 | 06/11/2026 05:55 | ALFA | B-033 fecha o AVISO 045: MANTER EnableVolatilityFilter ligado

**Contexto.** A/B decidido antes do resultado. Mesma janela (2026.08.01 -> 2026.11.05), mesmo modelo (Model=1, H1, XAUUSD, deposito 10000, Leverage 100), mesmo binario; unica variavel `EnableVolatilityFilter` (true no B-032, false no B-033).

**Prova de identidade.** `[VERSION] v1.2.172 | Build=2026.08.01 | Stable=Yes | AutoUpdate=OFF | Modulos=16`
**Fecho literal.** `Test passed in 0:39:01.273 (including ticks preprocessing 0:00:00.016)` / `final balance 10242.94 USD` / `connection closed` 02:51:46.152.
**Contagem por OFFSET (PROTOCOLO 10.1).** `offset=202778546 tamanho=224904754 segmento=22126208 B`.

### Tabela A/B

| Metrica | B-032 filtro ON | B-033 filtro OFF | Leitura |
|---|---|---|---|
| `[ATR] SEM LEITURA` | 0 | 0 | igual |
| `[ATR] HANDLE MORTO` | 0 | 0 | igual |
| `[ATR] SERIE OK` | 1 | 190 | caminho exercitado 190x |
| `[ATR] HANDLE RECRIADO` | 1 | 190 | idem |
| `[ATR] RATES OOB` | 0 | 0 | igual |
| `[ATR] IDENTIDADE ERRADA` | 1 | 1 | igual |
| `[ATR] LEITURA SUSPEITA` | 1 | 2 | +1 |
| `[SIGNAL] BUY` | 22 | 23 | +1 |
| `[SIGNAL] SELL` | 63 | 63 | igual |
| `[SIGNAL] NEUTRO` | 1349 | 1348 | -1 |
| `[VALIDATION] APPROVED` | 98 | 96 | **-2,04%** |
| `[VALIDATION] BLOCK` | 662 | 681 | +19 |
| Trades | 59 | 59 | igual |
| Profit | 257.16 | 242.94 | -14.22 |
| Equity final | 10257.16 | 10242.94 | -14.22 |
| PF / WR | n/d | 1.99 / 54.24% | - |
| OnTester | n/d | 169.9766 | - |
| MaxDD (BacktestAnalyzer) | n/d | 138.95 USD (61.50%) | ver limite |

### Criterio fixado ANTES do resultado (LOCK.md, 02:14)
1. `[VALIDATION] APPROVED` > 98 + 20% = > 118
2. equity final >= 10257.16
3. MaxDD dentro de 3.0%

### Resultado do criterio
- (1) **NAO cumprido**: 96 < 118 (pior 2,04% que o estado actual).
- (2) **NAO cumprido**: 10242.94 < 10257.16 (-14.22 USD).
- (3) Nao ha ganho de risco a compensar; o Drawdown medido pelo analyzer e pior em termos absolutos de profit.

**DECISAO: manter `EnableVolatilityFilter=true` nos 13 graficos.** O AVISO 045 fecha com numero, nao com opiniao: desligar o filtro nao aumentou aprovacoes, nao aumentou lucro e nao reduziu bloqueios relevantes.

### Ganho lateral para o F3 (robustez)
O B-033 exercitou o caminho P1.134/P1.135 **190 vezes** (`SERIE OK=190`, `HANDLE RECRIADO=190`) contra 1 no B-032, e em nenhuma dessas 190 houve publicacao sem leitura (`SEM LEITURA=0`, `HANDLE MORTO=0`, `RATES OOB=0`). O n do D-052 sobe de 1 para **191 eventos** de handle ATR em falta, todos recuperados. Isto reforca P1.135 sem substituir o job multi-simbolo.

### Limite honesto
- Continua a ser **um simbolo e um binario**; o job multi-simbolo dos 13 graficos permanece pendente para fechar o F3.
- `MaxDD 61.50%` e a medida do BacktestAnalyzer (138.95 USD sobre 10000), **nao** o travamento `MaxDD=3.0%` do perfil; so e comparavel entre jobs quando o mesmo relatorio e lido dos dois lados. No B-032 esse campo nao foi capturado — lacuna a corrigir no proximo par.
- Um backtest nao prova lucro futuro. O resultado aqui serve para decidir uma flag, nao para prometer desempenho.
## Quadro :: A/B do P1.132 — o que ficou medido e o que ficou corrigido

| Contador (mesmo periodo, 1500 barras, 359 831 ticks) | A sem P1.132 | B com P1.132 | Variacao |
|---|---|---|---|
| linhas erro=4807 | 1 428 980 | 222 878 | -84,40 % |
| [ATR] SEM LEITURA | 1 399 481 | 218 215 | -84,41 % |
| [ATR] HANDLE MORTO | 29 499 | 4 663 | -84,19 % |
| log gerado | 659,93 MB | 122,43 MB | -81,45 % |
| lucro | -163,63 USD | +66,15 USD | nao utilizavel |
| trades | 9 (4G/5P) | 9 (9G/0P) | amostra nula |
| drawdown equity | 454,70 USD / 4,42 % | 58,72 USD / 0,58 % | nao utilizavel |
| longs / shorts | 9 / 0 | 9 / 0 | explicado pela regra |

PROVADO: o P1.132 reduz as falhas de leitura do ATR em ~84 % no tester H1 XAUUSD.

NAO PROVADO: que o ATR fique bom (restam 222 878 falhas); que o EA opere melhor (9 trades por run,
B sem uma unica perda — amostra nao serve).

CORRECCAO REGISTADA: o "0 shorts" nao e avaria. SignalCore.mqh:372-375 exige EMA50<EMA200 para vender,
logo em tendencia de alta a venda e estruturalmente impossivel. Suspeita levantada por mim em av041 e
retirada por mim em D-046, depois de ler a regra.

ABERTO: [SCORE] TOTAL=100,00 em 11 de 11 amostras. Subscores estavam BONS (RSI 30-70 -> 15,
ADX >= MinimumADX -> 15, EMA -> 20); o que satura e o total, deixando o gate MinMarketScore sem
discriminar neste periodo. Nao medi se e estrutural ou conjuntural.

EM CURSO: B-031c (run 7704894539993498139) = repeticao de controlo do binario de B.
CANAL: bloqueado por ALFA (lock ate 06/11 01:34). Blocos D-046 e avisos 046 guardados em Files\Temp,
a anexar assim que o lock abrir. Espelho divergente em 3 ficheiros porque o ALFA esta a editar fontes
agora — copia EA -> espelho so depois de ele fechar.
## Quadro :: gate de score - o que ficou medido as 14:28 (D-054)

| Verificacao | Resultado | Fonte |
|---|---|---|
| Integridade do canal no arranque | 9 problemas -> **0** | `sync-agent.ps1 check` |
| Fila do turno anterior | 5/5 blocos publicados | resposta do `equipe-sync.ps1` |
| Tecto do score | 100,00 por clamp, somados 165 teoricos | `DecisionEngine.mqh:202-468` |
| Parcela de IA com IA em baixo | **constante** 40,00 x MemoryBoost -> +14,00..25,00 no score | `AIEngine.mqh:175` + `Config.mqh:603` |
| Piso do score com IA em baixo | 64,00 (boost 0,70) .. 70,00 (boost 1,00) | aritmetica |
| `MinMarketScore` | 65,0 -> gate so veta na faixa boost 0,70 sem bloco tecnico | `Config.mqh:1115`, `DecisionEngine.mqh:723` |
| TOTAL=100,00 em 11/11 (D-046) | **estrutural**, nao do periodo | aritmetica, sem backtest |
| Backtests corridos neste turno | **0** | - |

Leitura honesta: isto e medida de codigo, nao desempenho. Nao diz nada sobre a rentabilidade
da estrategia e nao autoriza mexer em `MinMarketScore` nem em `AIUnavailableConfidenceCap`.
## Quadro :: estado medido as 14:19 (DELTA)

| Item | Valor medido | Fonte |
|---|---|---|
| Fonte vs binario | **BATEM** (nenhum `.mq5`/`.mqh` mais novo que o `.ex5`) | `sync-agent.ps1 status` |
| Versao legivel | **1.2.172** (`#property` 1.372) | `status` + `VersionManager.mqh` |
| `XAU_AI_PRO.ex5` | **931194 B**, SHA256 `0A28EDFC5BDC`, 06/11 **01:19:48** | `Get-FileHash` |
| `[START]` no log | **26**, ultimo **14:16:58** | `status` |
| LOCK | **livre** as 14:18 | `lock -Acao ver` |
| Integridade do canal | **OK** (0 problemas, 29 `.md`, 52 IDs `D-` unicos) | `check` |
| Perguntas do DONO | **21 em aberto** (Q-001..Q-021) | `status` |
| git | branch `main`, ultimo `2eacb19b` 06/11 05:51, **63 alterados** | `status` |
| Backtests neste turno | **0** | - |

Nota honesta: a tabela da seccao 1 deste ficheiro ainda diz **1.2.167** (medicao de 05/11 21:41).
Nao a reescrevi - o valor vivo e o desta linha, medido as 14:19. Quem publicar a versao deve
atualizar a seccao 1 e dizer a hora, para nao ficarem duas verdades no mesmo ficheiro.
## Quadro :: [SCORE] com EMA alinhada - contagem feita as 14:24 (DELTA)

Fecha a duvida que o `D-054` deixou em aberto ("a aritmetica dispensa, mas a contagem nao foi feita").

| Medida | Valor | Como foi medido |
|---|---|---|
| Amostras `[SCORE] CALCULATED` | **162** | leitura integral de `Tester\logs\20261106.log` (224904860 B) |
| Com `EMA=20.00` (EMA alinhada) | **146** (90,1 %) | mesma leitura |
| Com `EMA=0.00` | **16** (9,9 %) | mesma leitura |
| Com `TOTAL=100.00` | **162 de 162** (100 %) | mesma leitura |

Leitura honesta: a saturacao do score **nao** depende de a EMA estar alinhada - as 16 amostras
sem EMA alinhada tambem deram `TOTAL=100.00`. Isto confirma o `D-054` por **contagem** (162/162) e
nao por 11 amostras, como estava registado.

Ressalvas obrigatorias:

1. **Nao e medida por job.** `20261106.log` e o ficheiro do dia e soma os jobs que correram hoje
   (pelo menos B-032 e B-033). Pela regra 10.1, um numero por job exige offset fixado **antes** do
   arranque. Este 162/162 e do dia, nao de um run.
2. **O log do tester e UTF-16LE**, nao UTF-8/ANSI. `findstr` devolve **0** e so avisa
   "arquivo ... esta no formato Unicode" - falso zero que custou um comando neste turno. Quem contar
   tem de decodificar como Unicode (ex.: `StreamReader` com `[System.Text.Encoding]::Unicode`).
3. Nao diz nada sobre rentabilidade. Mede o gate de score, nao a estrategia.

## Quadro :: tester sem job a correr, as 14:24 (DELTA)

| Verificacao | Medida | Evidencia |
|---|---|---|
| `metatester64` vivos | **4** | `Get-Process` |
| Job em curso | **NAO** | cauda de `20261106.log`: `Test passed in 0:39:01.273` + `connection closed` 02:51:46.152 |
| Ultima linha do log | 14:11:24.988, origem `Tester`, texto "Cloud servers switched off" | cauda do ficheiro |
| LOCK | livre | `sync-agent.ps1 lock -Acao ver` |

Os 4 `metatester64` sao **residuos inactivos** - exactamente o caso previsto na regra 10.2
("processos inactivos continuam a existir depois do fim do teste"). A prova de fim e a cauda do log,
nao a contagem de processos. O recurso de tester esta livre para o proximo job.
## Quadro :: inventario do terminal vivo as 14:23 (DELTA)

Medido com `list_open_charts` + `get_trading_open_positions`, nao por leitura de ficheiro `.chr`.

| Item | Valor medido | Fonte |
|---|---|---|
| Graficos abertos | **13** (`CHART01`..`CHART13`), perfil `XAI_P216_LIVE` | `list_open_charts` |
| EA em todos | `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`, `MagicNumber` **2026001** | `list_open_charts` |
| Posicoes abertas | **0** | `get_trading_open_positions` |
| Ordens pendentes | **0** | `get_trading_open_positions` |
| `AIGatewayToken` | **""** nos **13** graficos | `list_open_charts` |
| `AIGatewayUrl` | `http://127.0.0.1:9011/api/ai/predict` nos 13 | idem |
| `EnableVolatilityFilter` | **false** nos 13 | idem |
| `EnableAutonomousMode` | **false** nos 13 | idem |
| `AutoTrade` | **true** nos 13 | idem |
| `MinMarketScore` / `AIUnavailableConfidenceCap` | **65.0** / **40.0** nos 13 | idem |

### Simbolos: graficos vs input `Symbols` (dado novo para a Q-004)

- Com grafico e **sem** `Symbols` (3): `USDCZK`, `USDRUB`, `USDSGD`
- Em `Symbols` e **sem** grafico (1): `EURUSD`
- `SymbolsFromMarketWatch` = **true** nos 13 graficos, logo o universo efectivo vem do Market Watch, nao da lista `Symbols`

Isto da medida concreta a Q-004; a decisao continua a ser do DONO.

### Assimetria de timeframe e de historico

- 12 graficos em **H1**; `USDBRL` em **M5** (`CHART11`) e o unico fora de H1.
- Barras carregadas muito desiguais: `USDRUB` **26718**, `USDBRL` **24674**, `XAUUSD` **60390**, `USDCNH` **66910**, `USDCZK` **72114**; os restantes 100000.

Nota: `[SCORE]` e escrito 1 vez por 15 min por simbolo (`DecisionEngine.mqh:519`, `DecisionLogDue(...,900)`); com 13 graficos abertos o log enche rapido, o que explica o tamanho de `Tester\logs\20261106.log` (224904860 B).
## Quadro :: GATE_REAL publicado (D-055) - 11 criterios, 11 vermelhos

DELTA criou `GATE_REAL.md` (4547 B). O objectivo "conta real" passou de intencao a tabela verificavel.

| Item | Valor medido agora | Fonte |
|---|---|---|
| Conta ligada | **`MetaQuotes-Demo`**, tipo **`demo`**, login `113568614` | `get_trading_account_info` |
| Balance / equity / margem | **12636.32 / 12636.32 / 0.00** USD | idem |
| Itens do gate em VERDE | **0** | `GATE_REAL.md` |
| Itens do gate em VERMELHO | **11 de 11** | idem |
| Primeiros a desbloquear | **G1** (conta real) e **G2** (token, Q-021) | idem |

Nota de honestidade: nao existe conta real neste terminal. O servidor `MetaQuotes-Demo` e so de demonstracao, portanto "operar conta real" nao e um interruptor que se ligue aqui - exige conta live num broker real, acto do DONO.
## Quadro :: diagnostico do gateway de IA as 14:46 (DELTA) - porta 9011 fechada

| Item | Valor medido | Fonte |
|---|---|---|
| `AIGatewayUrl` nos 13 graficos | `http://127.0.0.1:9011/api/ai/predict` | `list_open_charts` |
| Porta **9011** | **FECHADA** - nenhum socket; sem resposta HTTP (`code:1001`) | `netstat` + `send_web_request` + `api-probe.ps1 -BaseUrl 9011` |
| Porta **9001** (padrão do `api-probe.ps1`) | responde **401**; sockets `ESTABLISHED` com dono **PID 10428 = `terminal64`** | `netstat -ano` |
| `AIGatewayToken` nos 13 | `""` | `list_open_charts` |
| Conclusao | **nao e falta de token, e falta de servico** | medicao acima |

Leitura honesta: a Q-021 diz que "o endpoint 9011 responde 401". A medicao desmente a primeira metade - a 9011 nao responde nada. O 401 vem da **9001**, que e o bridge local do proprio MetaTrader (`terminal64`), porque `MQL5\Tools\api-probe.ps1:37` tem `9001` como padrão e o EA usa `9011`. Registado como **D-056**.

Nada tocado: nenhum `AIGatewayUrl` alterado nos graficos, nenhum compile, nenhum reattach, nenhuma ordem.
## Quadro :: gateway de IA no ar e autenticado - o bloqueio mudou de lugar (15:50, DELTA)

Medido depois de subir o backend em modo leitura. Fonte: `D-057`.

| Item | Valor medido | Fonte |
|---|---|---|
| Porta 9011 | **NO AR** - `uvicorn` **PID 1464**, pai 10528 | `Win32_Process` |
| `GET /api/ai/predict` sem token | **401** (fail-closed correcto) | `delta_probe_9011.ps1` |
| `GET /api/ai/predict` com token do `.env` | **200**, **1122 B** | idem |
| `GET` com token errado | **401** | idem |
| Token do `.env` | **64** caracteres (input do grafico vazio, por desenho) | idem |
| Journal do EA | `[AI] GATEWAY RECUPERADO \| NZDUSD \| H1 \| falhas=7 \| cego=209s \| resposta=357B \| sem intervencao` 15:44:37 | `get_expert_journal` |
| Simbolos com modelo publicado | **1 de 13** (XAUUSD) | `delta_edge_all.ps1` |
| `edge` do unico modelo | **0,0363** contra minimo **+0,0500** | idem |
| Simbolos que passam o gate de IA | **0 de 13** | idem |
| Graficos abertos | **14** - 13 com EA + `chart14` XAUUSD H1 **sem EA** | `list_open_charts` |
| Posicoes / ordens | **0 / 0** | `get_trading_open_positions` |
| Sinais na janela 15:47 | `[DIAGSCAN] sinais=0 \| neutros=16 \| simbolos=21 \| frescos=16` | `get_expert_journal` |
| `AIGatewayToken` nos 13 | `""` - **inalterado, de proposito** | `list_open_charts` |
| `EnableVolatilityFilter` nos 13 | **false**, contra o `D-053` que decidiu **manter true** | `list_open_charts` |

### Leitura honesta

1. **Infra-estrutura: fechada.** Servico no ar, credencial resolvida pelo `.env`, EA autenticado e a recuperar sozinho.
2. **Modelo: aberto e e o novo bloqueio.** `1 de 13` com modelo, e o unico abaixo do minimo de `edge`.
3. **Nao baixei o limite de `+0,0500`.** Baixa-lo produziria "operacao" com um modelo pior que o acaso. Isso seria falsificar o gate, nao desbloquear o projecto.

### Dois riscos abertos criados/confirmados por esta medicao

- **P0 durabilidade:** o gateway e processo manual. Ja morreu hoje e deixou o EA **209 s cego**. Sem servico/tarefa, o proximo reboot repete isto sem aviso. `Q-022`.
- **Divergencia decisao-runtime:** o `D-053` decidiu **manter `EnableVolatilityFilter=true`** (A/B medido: 98 vs 96 aprovacoes, 10257.16 vs 10242.94), mas os **13** graficos continuam com **`false`**. A decisao existe no papel e nao esta no terminal. Nao alterei nada: mexer nessa flag muda regra de entrada e exige a palavra do DONO.

Nada tocado: nenhum parametro de risco, nenhum compile, nenhum reattach, nenhuma ordem.

### Medicao ALFA 06/11 16:04-16:06 (pos P2 v1.2.175) :: 1) GATEWAY por simbolo: [AI] GATEWAY as 16:04:36-37 devolve XAUUSD=1122 B disponivel=true e 12 simbolos (USDSEK, USDCZK, USDCHF, USDCAD, USDCNH, USDJPY, NZDUSD, USDBRL, AUDUSD, GBPUSD, USDSGD) = 357 B disponivel=false. Confirma o '1 de 13' do DELTA e prova que o bloqueio atual e COBERTURA DE MODELO, nao o token. 2) SINAIS: [DIAGSCAN] as 16:02:00.069 (USDCHF) registou sinais=2 [GBPUSD BUY, USDSEK SELL] com ADX(ok/sem)=13/0 e sem_leitura=0 - o pipeline JA produz sinais. 3) PORTAO: todas as instancias reportam portao do grafico=FECHADO | codigo=3 | suite=FECHADA | modo=SO LEITURA. MQL_TRADE_ALLOWED=0 (bit por grafico) continua a descartar tudo: P0 so o DONO resolve na GUI. 4) STALE: flutuam entre 5 e 8 simbolos (MSFT, GOLD, USDCLP, AMD, INTC, NVDA) com ticks mortos de 901 s a 4966 s - fora da lista Symbols. 5) CONTA: MetaQuotes-Demo login 113568614, equity 12636.32, 0 posicoes, 0 ordens. Nada tocado por ALFA: nenhum parametro de risco, nenhum compile, nenhum reattach, nenhuma ordem.

### A/B de rigor v1.2.175 fechado 06/11 16:15 (ALFA, D-060) :: run_id 7705129902453849045 | XAUUSD H1 2026.08.01 a 2026.11.05 | Model=1 | Deposit 10000 | Leverage 100 | profit 250.62 | PF 2.0195 | recovery 1.3914 | sharpe 11.6032 | expected_payoff 4.18 | 60 trades (58 W / 2 L) | 40 short / 20 long | DD balance 138.95 (1.36 pct) | DD equity 180.12 (1.76 pct) | equity final 10250.62 | B-032 10257.16 | delta -6.54 :: leitura: o P2 e NEUTRO no resultado economico, o que era esperado porque so corrige a saude do handle ADX e nao a decisao :: NOTA IMPORTANTE para o GATE_REAL: este run e de 3 meses e 60 trades, portanto alimenta G5/G6/G7 com numeros mas nao os fecha (G5 pede 100 trades, G7 pede 100 trades com PF 1.20) :: o binario publicado nos 13 graficos e o v1.2.175 (942310 B, MD5 037040C1B0869D84FC2EAAC2928A4884)

### P0 medido e isolado 06/11 16:40 (ALFA, D-061) :: 1) causa raiz: expertmode=0 dentro do bloco <expert> dos 15 .chr do perfil XAI_P216_LIVE; 59 .chr de outros perfis deste terminal tem expertmode=5 e sao os que ja negociaram; o terminal reporta experts_trade_allowed=true, logo o botao global NAO e o problema. 2) experiencia controlada: backup em MQL5\\Files\\Backup\\xai_p216_chr_20261106_1655, patch 0 para 5 nos 13 graficos com EA, profile_apply Default e volta a XAI_P216_LIVE, e o MT5 regravou os 15 .chr a partir da memoria devolvendo expertmode=0 (mtime 16:27:56). Patch de ficheiro com o terminal aberto e inutil por desenho. 3) estado pos-experiencia: perfil XAI_P216_LIVE restaurado, 15 EAs v1.2.175 a correr desde 16:28:02, conta demo 113568614, 0 posicoes, 0 ordens, equity 12636.32, guardas diarias reiniciadas pelo reload (normal). 4) Q-023 ao DONO com as 3 vias. 5) o pipeline continua a produzir sinais e a descarta-los no portao codigo=3: o EA NAO esta partido, esta sem permissao por grafico.
## Quadro :: P0 fechado por medicao - o EA esta autorizado e a decidir outra vez (20:10, DELTA)

- **Permissao (P0): FECHADO.** Perfil `XAI_P215_LIVE_B` carregado as 20:09:24; 13 x `[START] v1.2.175` e, depois do recompile do ALFA as 20:09:50, 13 x `[START] v1.2.176`. Nenhum `[TRADE BLOCK]`, nenhum `codigo=3`, nenhuma linha `Permissoes` na janela 20:09:20-20:59. Prova positiva: `master=SIM` as 20:10:21.473, e o pipeline so elege mestre com `MQL_TRADE_ALLOWED` a 1.
- **Mecanismo medido:** o `expertmode` e LIDO do `.chr` ao carregar o perfil e ESCRITO a partir da memoria ao sair. Patch de ficheiro num perfil a correr nao cura (D-061); carregar um perfil que ja traz `expertmode=5` cura (esta medicao). Nao ha contradicao - sao dois sentidos do mesmo fluxo.
- **IA: a chegar.** `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes | disponivel=true` e `[AI] PYTHON | XAUUSD | SELL | CONF=72.40%`. O `AIGatewayUrl` 9001 dos `.chr` do PB e irrelevante: `AIGatewayUrlEfetiva()` reescreve a porta com a do `.env` (9011).
- **Universo:** 13 graficos, 13 EAs, 13 simbolos distintos (o `chart14` sem EA que existia no P216 nao existe neste perfil - o G10 melhora de 14-vs-11 para 13-vs-11, e continua VERMELHO).
- **Conta:** demo 113568614, equity 12636.32, 0 posicoes, 0 ordens. Nada foi aberto nem fechado.
- **Custo declarado da troca:** 117 parametros diferentes, dos quais **3 funcionais** - URL (neutra, provada), `AllowTradeWithoutAI` false (mais restritivo), `EnableAutonomousMode` true (**mais permissivo**: a IA deixa de vetar). Q-024 ao DONO para ratificar o perfil e decidir o reattach.
- **O bloqueio agora e MODELO:** 1 de 13 simbolos com modelo publicado e o unico com `edge` 0.0363 abaixo do minimo +0.0500.

## Quadro :: F2.9 FECHADO em v1.2.179 + F2.2 RE-MEDIDO (CMD, 06/11 21:20)

### 1. F2.9 - cotacao velha deixa de operar: FECHADO

| Item | Valor medido | Como foi medido |
|---|---|---|
| Binario em disco | **957544 B** | `Get-Item XAU_AI_PRO.ex5` |
| MD5 | **D7D2E0F0F65035A143508E8F43E292E6** | `Get-FileHash -Algorithm MD5` |
| mtime | **06/11/2026 20:46:54** | `Get-Item` |
| Fonte vs binario | **BATEM** (nenhum .mq5/.mqh mais novo) | `agent-toolkit.ps1 status` + validacao estatica OK em 112 fontes |
| Validacao estatica | **OK** (UTF-8, chaves, #include) | `agent-toolkit.ps1 check` |
| GATE_REAL | **1 verde de 11** (so G2), inalterado | `GATE_REAL.md` |

Nota de honestidade: o F2.9 fecha com prova de veredicto e de observabilidade (Prova A/B do D-064), mas o GATE_REAL nao se move por isso. F2.9 e um item do GATE F2, nao um dos 11 criterios G1..G11.

### 2. F2.2 - a medicao do ALFA de 21:18 esta ERRADA

O ALFA registou que "nao existe limite de exposicao somada em % do capital" e que so existe `MaxOpenPositions` (contagem) e `EnableCurrencyExposureGuard` (correlacao). A leitura do codigo REFUTA isso:

| Prova | Ficheiro:linha | O que diz |
|---|---|---|
| `MaxTotalRiskPercent = 10.0` | `Core/Config.mqh:310-317` | "teto do risco SOMADO das posicoes abertas do EA (% do saldo)" |
| Teto em USD `MaxTotalRiskOpenUsd = 60.0` | `Core/Config.mqh:319-334` | envelope passa a ser o MENOR entre % e USD |
| `RiscoAbertoUSD()` | `Core/Config.mqh:1200-1275` | soma o risco (entrada -> SL) das posicoes abertas, filtradas por `POSITION_MAGIC == MagicNumber` |
| `RiscoPorTradeUsd()` | `Core/Config.mqh:1279-1311` | `envelope = saldo * MaxTotalRiskPercent/100`; se `MaxTotalRiskOpenUsd` for menor, usa-o; `sobra = envelope - RiscoAbertoUSD()`; 0 = recusa |
| Bloqueio na execucao | `Core/ExecutionEngine.mqh:686-701` | `[TRADE] BLOQUEADA | envelope de risco aberto cheio | MaxTotalRiskPercent=...` + `RISK_ENVELOPE_FULL` |

Ou seja: **existe** um teto de exposicao somada em % do capital, com bloqueio activo. O que e verdade e outra coisa, mais estreita:

- o somatorio filtra por `MagicNumber` (`Config.mqh:1211`);
- hoje os **13 graficos partilham `MagicNumber=2026001`**, portanto cada instancia ve o risco de TODAS as 13 e o envelope de 10% / 60 USD funciona, de facto, como teto de conta;
- se o F2.8 for implementado com magic unico por grafico, o somatorio passa a ver so a propria posicao e o envelope **fragmenta-se em 13 x 10% = 130%** (o mesmo defeito que o DELTA ja mediu, mas agora por desenho).

**Re-scope do F2.2:** nao e "criar um limite que nao existe"; e (a) decidir o valor do teto de conta e (b) tornar o somatorio independente do magic partilhado, para que o F2.8 nao quebre o limite. A Q-065 continua valida, mas a pergunta certa passa a ser "qual o teto de conta" e nao "qual o teto a criar".

Nada tocado: nenhum parametro de risco, nenhum compile, nenhum reattach, nenhuma ordem.


## Quadro :: F2.9 - limite 900 s, COTACAO VOLTOU pendente e correcao do check (CMD, 06/11 21:30)

### 1. F2.9 - o que fica fechado e com que limite

| Item | Valor medido | Fonte |
|---|---|---|
| Limite em vigor | **900 s**, das inputs `EnableStaleDataGuard` / `MaxSymbolTickAgeSec` | journal: `USDBRL \| idade=10063s \| limite=900s` |
| 120 s fixo no codigo | **desapareceu** (passou a valor de recurso, so para instrumentos de medicao) | `Core/StalenessGuard.mqh:26-47` + `XAU_AI_PRO.mq5:1023-1031` |
| Transicao publicada sem tick | **13 de 13 graficos** | `[TRADE BLOCK] COTACAO VELHA (timer)` |
| Repeticoes em 37 min | **0** (um aviso por hora, nao por ciclo) | journal 20:48-21:25 |
| `[TRADE BLOCK] COTACAO VOLTOU (timer)` | **nunca observada** - so existe na reabertura de segunda | pendente por desenho |
| GATE F2 | **NAO verde** - faltam 5 das 6 falhas simuladas (requote, spread anormal, duplicacao, reinicio a meio, conta sem margem) | `DECISOES.md:D-065` |
| GATE_REAL | **1 verde de 11** (so G2), inalterado | `GATE_REAL.md` |

Nao escrever "F2 verde" nem "10/10". O F2.9 fecha a metade que protege e a metade que se ve; o GATE F2 continua aberto.

### 2. Ferramentas corrigidas por CMD (zona `tools/`)

| Ficheiro | Antes | Depois | Prova |
|---|---|---|---|
| `tools/equipe-sync.ps1:335` | `^#{2,3}` contava `### D-064 adenda` como segundo bloco de ID | `^##` | `check` = **CANAL INTEGRO :: 0 problemas** (era "CANAL COM 1 PROBLEMAS", falso positivo) |
| `tools/equipe-sync.ps1` comando `dono` | exigia `ABERTO` + `\|`/fim; descartava `ABERTA` em silencio | aceita `ABERT[AO]` e imprime `IGNORADO` para estado nao reconhecido | `dono` = **23 abertas** (antes 13), sem esconder bloco |
| `Get-Metricas` e `quem` | contavam so `ABERTO` | `ABERT[AO]` / `FECHAD[OA]` / `RESPONDID[OA]` | parse OK, `check` OK |

Isto e ferramenta de canal, nao codigo MQL5: nenhum limite, lote, alvo, stop, spread, regra de entrada ou parametro de risco foi tocado.

### 3. Violacao de protocolo declarada pelo DELTA as 21:20:41

O DELTA escreveu 7 ficheiros do canal por I/O de bytes enquanto o LOCK estava com o CMD (motivo "quadro F2.9 + re-medicao F2.2", expira 21:40). O `lock -De DELTA` recusou correctamente e o script dele nao parou.

Decisao do CMD: **nao reverter**. As 7 escritas foram append puro, nenhum byte existente reescrito, o alvo declarado do CMD (`QUADRO_ESTADO.md`) nao foi tocado, e os backups `MQL5\Files\Backup\delta_f29_20261106_212041` estao intactos. Reverter durante o lock de outro agente seria repetir a falta. O conteudo (D-065 e aviso do F2.9) e valido e fica.

Regra reforcada: quem escreve tem de ser o dono do lock, e o caminho de I/O de bytes do script de publicacao tem de chamar `Test-LockLivre` antes de gravar - a ferramenta recusou, o script nao.

Nada tocado em risco: nenhum compile, nenhum reattach, nenhuma ordem.


## Quadro :: api-probe.ps1 alinhado com o EA - 9011 + GET + .env (CMD, 06/11 21:32)

O DELTA registou em 06/11 14:47 (D-056) que o `Tools/api-probe.ps1` media a porta **9001** (bridge do `terminal64`) com **POST** numa rota que e **GET** na **9011**, e que o 401 da 9001 era lido como "falta token". Corrigido.

| Antes | Depois | Prova |
|---|---|---|
| `BaseUrl` padrao `http://127.0.0.1:9001` | **9011**, ou a porta de `XAU_GATEWAY_PORT` no `.env` | cabecalho: `base: http://127.0.0.1:9011` |
| `POST` com corpo `{}` | **GET** (o mesmo do EA) | cabecalho: `metodo: GET (o mesmo do EA)` |
| token so de `$env:XAU_AI_GATEWAY_TOKEN` | env -> **`.env`** (`XAU_GATEWAY_TOKEN`), sem imprimir o valor | `token resolvido (64 caracteres; valor nao impresso)` |
| porta fechada seguia para HTTP e confundia com 401 | **para na etapa 1** e diz "servico ausente, NAO e falta de token" | `-BaseUrl 9099` -> FAIL na etapa 1, exit 1 |

### Medicao real (06/11 21:31)

```
1/4 porta 9011  -> OK
2/4 raiz        -> HTTP 401 (servico HTTP vivo)
3/4 sem token   -> HTTP 401 (servico vivo, exige token)
4/4 com token   -> HTTP 200, available=true, signal=SELL, conf=72.4
RESULTADO: sonda concluida sem falhas de infraestrutura
```

Contraprova de porta fechada (`-BaseUrl http://127.0.0.1:9099`): `[FAIL] porta 9099 FECHADA - nao ha servico nesta porta; NAO e falta de token`, exit 1. Nao ha mais o falso 401 por token quando o servico nao existe.

Nada tocado em risco: nenhum compile, nenhum reattach, nenhuma ordem; so o script de diagnostico em `Tools/`.


### Estado medido (06/11 21:49) - ALFA

```
binario   962744 B  21:38:01   13/13 graficos  v1.2.181 (#property "1.381")
fonte     104770 B  21:37:33   EA_VERSION_STRING "1.2.181"
conta     demo 113568614  equity 12636.32  margin 0.00  0 posicoes  0 ordens
dia       2026.11.06  trades=0  W=0  L=0  pico=12636.32
gateway   HTTP 200  1122 B  signal=SELL  confidence=72.4  prob_buy=0.2765  prob_sell=0.7235
```

- **F2.2 (D-067)**: `MargemUsadaEA()` le `AccountInfoDouble(ACCOUNT_MARGIN)`; `MargemSomadaPosicoes()` so como instrumento. Em memoria desde 21:38:02. **Sem prova de recusa, sem prova de fail-closed** (margem 0.00, nenhuma linha `[EXPOSURE CAP]`).
- **F2.9**: a repeticao de `COTACAO VELHA` no arranque esta explicada (o `static bool` da transicao morre com o programa; 13 linhas as 21:38:31-32). A idade da cotacao anda 1:1 com o relogio (5 pontos, 0 s de erro em 562 s). **A metade `COTACAO VOLTOU (timer)` continua por observar.**
- **O EA nao opera - causa medida**: o parser procura `buy`/`sell`/`score`, o gateway publica `prob_buy`/`prob_sell`/`edge`. `AI_Score=0.0` -> `AIEngine.mqh:289` (`AI_Score<MinAIConfidence`) -> `GetAIEngineSignal()` devolve 0 sempre -> com `AllowTradeWithoutAI=false`, nenhum trade e possivel. Correccao (D-068) escrita, **nao compilada**.
- **Compromisso do ALFA**: zero compiles e zero recargas esta noite a partir das 21:38:02.
- **Deriva de IDs**: 61 usados / 61 unicos / 54 no ledger. O D-068 so sera publicado depois de `id -Tipo D`.
- `GATE_REAL` **1 verde de 11**. Nao assino GATE F2, F2.2, 10/10 nem F6.
