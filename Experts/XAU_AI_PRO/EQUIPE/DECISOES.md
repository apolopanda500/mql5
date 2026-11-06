# REGISTRO DE DECISOES - XAU_AI_PRO

Formato: `D-nnn | data | assunto | estado | quem decide | o que foi decidido`.

Estados: **ABERTA** (espera o dono), **FECHADA** (decidida, com a fonte),
**PROPOSTA** (agente propoe, dono confirma).

Regra: decisao fechada nao se rediscute por palpite. Se a medicao mudou,
abre-se `D-novA` citando a nova medida e a antiga.

---

## D-001 | 05/11/2026 | canal de comunicacao entre agentes

- **Estado:** FECHADA (dono, 05/11 21:40)
- **Decisao:** o canal e **arquivo no repositorio**, pasta
  `MQL5/Experts/XAU_AI_PRO/EQUIPE/`: `PROTOCOLO.md` (regras),
  `QUADRO_ESTADO.md` (estado medido), `DECISOES.md` (este arquivo) e uma
  `INBOX_AGENTE_n.md` por agente. Diarios individuais continuam em
  `AGENTE_1.md`, `EQUIPE/AGENTE_2.md`, `AGENTE_3.md`.
- **Consequencia:** pedido que nao esta na inbox nao existe. "Avisado no chat"
  nao vale como comunicacao.

---

## D-002 | 05/11/2026 | P1.130 esta com DOIS donos e DOIS assuntos

- **Estado:** **FECHADA (a)** em 05/11 21:53 - ALFA e DELTA acordaram; o dono pode reverter
- **Medido:**
  - ALFA registou em `AGENTE_1.md` §3.1: `P1.130` = universo universal
    (`SymbolsFromMarketWatch` em `Core/SymbolManager.mqh` + `Core/Config.mqh`)
    + guarda `deBolsa` no alias GOLD/XAU em `AI/AIConnector.mqh`.
  - DELTA registou nos fontes: `P1.130` = os dois relogios `TimeCurrent()`
    que faltavam (`AI/AIConnector.mqh`, `Monitoring/OperatorBrief.mqh`), com o
    texto `v1.2.167 (05/11/2026) - P1.130: fechar os dois relogios...` em
    `Enterprise/VersionManager.mqh:63`.
  - **Os dois estao compilados no mesmo `v1.2.167`.** Nao houve perda de
    codigo; o que colide e o **nome** da pendencia.
- **Opcoes:**
  - **(a)** ALFA mantem `P1.130` (universo) e DELTA renomeia o seu para
    `P1.131` - exige editar 4 pontos de comentario (2 `.mqh` + o texto de
    `VersionManager.mqh` + o comentario em `XAU_AI_PRO.mq5`) e recompilar.
    Custo: 1 compile (~23 s), zero risco de logica.
  - **(b)** DELTA mantem `P1.130` e ALFA renomeia o seu - mesmo custo,
    so que no lado do ALFA.
  - **(c)** Nao renomear nada: `P1.130` fica ambigua e toda referencia futura
    precisa dizer `P1.130-universo` ou `P1.130-relogios`. Zero edicao, custo
    permanente de leitura.
- **Recomendacao do DELTA:** **(a)**. Ja aplicou a si mesmo a renomeacao
  para `P1.131` no `QUADRO_ESTADO.md` §5; o codigo continua dizendo `P1.130`
  ate o dono autorizar o recompile.
- **Decidido (a), 05/11 21:53:** ALFA fica com `P1.130` (universo
  `SymbolsFromMarketWatch` + guarda `deBolsa`) e o DELTA renomeou o seu para
  `P1.131`. **Aplicado nos fontes, comentario apenas, zero logica:**
  `AI/AIConnector.mqh` linhas 111, 145 e 1316; `Monitoring/OperatorBrief.mqh`
  linha 121; `Enterprise/VersionManager.mqh` linha 63. Contagem no disco:
  `AIConnector.mqh` P1.130=1 (a guarda do ALFA, linha 213) e P1.131=3;
  `Config.mqh` P1.130=1 e `SymbolManager.mqh` P1.130=1 (do ALFA, intactos).
- **Falta:** o `compile` para o `.ex5` voltar a bater com os fontes. Agora e
  do CMD (`D-006`).
- **Risco medido:** compilar faz o terminal reanexar os 13 graficos sozinho
  (visto 05/11 21:36:40) - e ato de producao, ver `D-003`.

---

## D-003 | 05/11/2026 | quem reanexa o EA nos graficos

- **Estado:** ABERTA
- **Contexto medido:** ALFA diz "so o dono reanexa";
  `PROTOCOLO.md` §5.5 diz "1 agente por vez, com autorizacao na hora".
  DELTA reanexou 05/11 21:37 (`profile_apply XAI_P216_LIVE`) e isso
  **funcionou**: 13x `[START] v1.2.167`, zero tempestade de notificacao.
- **Proposta:** `profile_apply` pode ser usado por **um** agente designado,
  desde que anuncie na inbox dos outros dois antes e meça o `[START]` depois.
- **Falta:** `D-003 = ( ) ALFA ( ) DELTA ( ) so o dono`.

---

## D-004 | 05/11/2026 | gate de IA: token ou modo autonomo

- **Estado:** ABERTA - **bloqueia toda a operacao**
- **Medido:** gateway responde **401** em `/`, `/health` e `/api/ai/predict`;
  `AIGatewayToken` vazio nos 13 graficos; `XAU_AI_GATEWAY_TOKEN` inexistente no
  ambiente. Com `AllowTradeWithoutAI=false`, `EnableAIFilter=true`,
  `EnableAutonomousMode=false`, **nenhum** simbolo passa (P1.125 ja corrigiu o
  teto de confianca; falta a credencial).
- **Opcoes:** (a) provisionar `XAU_GATEWAY_TOKEN` no gateway **e**
  `AIGatewayToken` nos 13 graficos; (b) `EnableAutonomousMode=true` (IA passa a
  consultora).
- **Nota:** (b) muda o perfil de risco do EA. Se for escolhido, e decisao
  consciente do dono, nao default de agente.
- **Correcao medida (CMD, 05/11 21:51):** o `XAU_GATEWAY_TOKEN` **existe** no
  `.env` (64 chars) e `GET /api/ai/predict?symbol=XAUUSD&timeframe=H1` com
  `Authorization: Bearer` devolve **HTTP 200** com `available=true`,
  `signal=BUY`, `conf=57.2`. Sem cabecalho devolve 401. Logo **nao falta
  token no gateway**; a opcao (a) nao exige provisionamento. O que falta
  provar e se o EA encontra o `.env` a partir do terminal (journal). Ver
  `QUADRO_ESTADO.md` §6.1. A opcao (b) deixa de ter justificacao tecnica.
- **Falta:** `D-004 = (a) / (b)`.

---

## D-005 | 05/11/2026 | posse das zonas de codigo

- **Estado:** PROPOSTA (fechada por omissao se ninguem contestar ate 06/11 12:00)
- **Proposta:** `AI/**`, `Core/SymbolManager.mqh`, `Core/Config.mqh`,
  `Indicators/**` = ALFA; `Monitoring/**`,
  `Enterprise/NotificationCenter.mqh`, `Monitoring/AccountLogGate.mqh`,
  build/deploy/terminal = DELTA; app `MQL5/Files/XAU_AI_PRO/**`,
  `backend/**`, espelho = CMD; `XAU_AI_PRO.mq5` e
  `Enterprise/VersionManager.mqh` = compartilhados 1 por vez.
- **Motivo:** e exatamente a divisao que o trabalho de cada um ja vinha
  seguindo; formaliza o que ja aconteceu e evita colisao de escrita.

---

## D-006 | 05/11/2026 | commit de v1.2.167

- **Estado:** **FECHADA (dono, 05/11 21:53)** - `commit`, `push` e `deploy` = **CMD** (registro detalhado em `D-007`)
- **Medido:** ultimo commit `53585733` = v1.2.166. v1.2.167 (relogios +
  universo + guarda GOLD-acao) esta **so no working tree**.
- **Proposta:** um unico commit local, caminhos explicitos, **sem `push`**, com
  o changelog de `VersionManager.mqh` corrigido para citar as duas frentes
  (`P1.130-universo` e `P1.131-relogios`) - ver `D-002`.
- **Decidido (dono, 05/11 21:53):** `commit`, `push` e `deploy` passam a ser
  **do CMD**. O DELTA nao commita, nao faz push e nao faz deploy. `D-002` ja
  esta em (a), logo o commit cita as duas frentes no changelog.
- **Aviso medido:** `origin` (Forge MQL5) esta com credencial expirada;
  `github` (`apolopanda500/mql5`) e o remote de colaboracao. `push` que falhe
  nao e bug de codigo - e credencial.

---

## D-007 | 05/11/2026 | `commit`, `push` e `deploy` passam a ser do CMD

- **Estado:** FECHADA (dono, 05/11 21:51)
- **Decisao:** **CMD** e o dono de `git commit`, `git push` e **deploy**.
  ALFA e DELTA **nao** commitam, nao fazem `push` e nao fazem deploy.
- **Consequencia imediata:** o commit do v1.2.167 (`D-006`, antes atribuido ao
  ALFA como `A-01`/`T-001`) passa a ser acao do **CMD**.
- **Lacuna que precisa de definicao (medida, nao opiniao):**
  1. `push` para **qual** remote? `origin` = Forge MQL5 e esta com credencial
     expirada; `github` = `apolopanda500/mql5`. Sem essa definicao o "push"
     nao tem destino.
  2. **"deploy" = o que?** build do `.ex5`? publicar no CodeBase? reattach nos
     13 graficos? Reattach exige MCP do terminal - e o CMD **nao** tem MCP
     (`CONSOLIDACAO.md` §1). Se o deploy incluir reattach, essa parte continua
     com ALFA/DELTA e o CMD faz so o build/publicacao.
  3. Continua valendo: payload de deploy nao pode arrastar a arvore espelhada
     `MQL5/Files/XAU_AI_PRO/MQL5/**` nem `Profiles/Tester/*.set`.

---

## D-008 | 05/11/2026 | divisao de camadas do EA (PROPOSTA do ALFA)

- **Estado:** PROPOSTA - **falta o dono confirmar** (o dono disse "o restante
  vamos ver quem fica com quais camadas")
- **Medido:** 8 camadas com codigo, **113 arquivos** `.mq5`/`.mqh`,
  **1.703.598 B** no total (comando `Get-ChildItem -Filter *.mq*`, 05/11 22:03)

| Camada | Medido | Proposta de dono | Por que |
|---|---|---|---|
| `Core/**` | 32 arqs / 375.013 B | **ALFA** | `SymbolManager` (universo), `Config` (inputs), `TradePipeline`, `Risk`, `Execution` |
| `AI/**` | 10 arqs / 163.166 B | **ALFA** | `AIConnector`, `AIEngine`, gate de IA. `AIConnector.mqh` (64.407 B) esta contaminado com o DELTA - ver D-002 |
| `Indicators/**` | 8 arqs / 61.469 B | **ALFA** | handles, `ADX`, `ATR`, `RSI`, `VolatilityFilter`, `SymbolDataReady` |
| `Filters/**` | 10 arqs / 116.498 B | **ALFA** | filtros de entrada |
| `Management/**` | 5 arqs / 28.956 B | **ALFA** | `BreakEven`, `DailyRisk`, `EquityProtection`, `MoneyLadder`, `PortfolioManager` |
| `Monitoring/**` | 21 arqs / 305.424 B | **DELTA** | `AccountLogGate`, `OperatorBrief`, `NotificationCenter`, `[RESUMO]` |
| `Enterprise/**` | 25 arqs / 530.260 B | **DELTA** | `VersionManager`, `NotificationCenter`, governanca |
| `Integration/**` | 2 arqs / 14.911 B | **a definir** | `EAHeartbeat.mqh` + `ExternalBridge.mqh` - fronteira terminal/externo; candidato natural ao CMD, mas precisa inspecao antes |
| raiz (`XAU_AI_PRO.mq5`, `DiagGateSelfTest.mq5`) | 2 arqs / 107.901 B | **compartilhado, 1 por vez** | entrada/`OnTick`/`OnDeinit`; ja e regra do `PROTOCOLO` §4 |
| app `MQL5/Files/XAU_AI_PRO/**`, `backend/**`, espelho, `Tools/*.ps1` | nao medido aqui | **CMD** | gateway Python, dataset, testes, git/build (D-007) |

- **Regra que a proposta preserva:** nenhuma camada tem dois donos; `Core/Config.mqh`
  e `Core/SymbolManager.mqh` ficam com quem ja os mediu (ALFA) para nao repetir
  o conflito de `AIConnector.mqh`.
- **Alternativa registrada:** se o dono preferir separar por *assunto* (risco x
  IA x execucao) em vez de por pasta, a tabela acima continua valendo como
  ponto de partida, so os limites mudam.

---


---

## D-010 | 05/11/2026 | colisao de IDs entre os dois DECISOES.md

- **Estado:** ABERTA - **decisao do dono**
- **Medido (CMD, 05/11 21:48):** `EQUIPE/DECISOES.md` (canonico) e
  `EQUIPE/_LEGADO_EQUIPE_2144/DECISOES.md` (antigo do ALFA) usam os **mesmos
  IDs para coisas diferentes**: `D-002` = "P1.130 duplicado" num e "nao
  recarregar sem autorizacao" no outro. O legado tem ainda `D-007`..`D-009` e
  `P-001`..`P-006`, que nao existem aqui.
- **Opcoes:** (a) proposta do CMD - este arquivo e o canonico, os IDs do ALFA
  viram `A1-D-00n` e os `P-00n` sao importados; (b) renumerar o legado para
  `D-010`..`D-018`.
- **Efeito imediato (nao espera a decisao):** todo agente cita a origem -
  `D-002 (DELTA)` ou `D-002 (ALFA)`.
- **Por que este item e `D-010`:** quando abri, `D-007` (`commit`/`push`/`deploy`
  = CMD) e `D-008` (camadas) ja existiam aqui; `D-009` esta reservado, e o ALFA tambem usa `D-007`..`D-009` no legado. Reusar qualquer um criaria colisao nova.
- **Falta:** `D-010 = (a) / (b)`.

---

## D-011 | 05/11/2026 | o bloqueio 401 do `D-004` esta morto - e o push do espelho nao depende de `[START]`

- **Estado:** FECHADA por medicao (ALFA, 05/11 22:14)
- **O que foi medido** (`get_expert_journal`, `source = XAU_AI_PRO (USDCNH,H1)`):

  ```
  [AI] GATEWAY | XAUUSD | H1 | 1121 bytes | disponivel=true   21:36:45.827  CONF=62.80%
  [AI] GATEWAY | XAUUSD | H1 | 1121 bytes | disponivel=true   21:37:17.841  CONF=63.30%
  [AI] GATEWAY | XAUUSD | H1 | 1121 bytes | disponivel=true   21:37:44.295  CONF=59.10%
  [AI] GATEWAY | XAUUSD | H1 | 1121 bytes | disponivel=true   21:39:34.848  CONF=56.60%
  [AI] GATEWAY | XAUUSD | H1 | 1121 bytes | disponivel=true   21:39:59.039  CONF=58.20%
  ```

  **Zero 401 no periodo.** O EA autentica e recebe corpo de 1121 B. O caminho
  `AIGatewayTokenEfetivo()` funciona dentro do terminal. O `D-004` (gateway
  401 / `AIGatewayToken=""` nos 13 graficos) fica **SUPERSEDIDO** - nao cita-lo
  como bloqueio activo.
- **Porque 0 trades, medido:** `[SCANNER] RESUMO` 22:02:10.151 ->
  `visitas=1489 | sinais=142 | trades=0 | bloqueios=1489 | Stale=601 NoSignal=746 AllowTrade=142`.
  So o **XAUUSD** tem modelo publicado (H1); os outros **20** devolvem
  `357 bytes | disponivel=false`. E `MinAIConfidence=60.0` contra CONF
  **56.6-63.3**. Com `EnableAIFilter=true` + `AllowTradeWithoutAI=false` +
  `EnableAutonomousMode=false`, 20 de 21 simbolos nunca passam e o XAUUSD passa
  so as vezes. **Nao e bug de codigo.**
- **`[START]` depois do compile das 21:57:47:** **0 registos** entre 21:55 e
  22:08 (41 registos ate 21:39:31). O `.ex5` de 927.354 B / 21:57 esta em disco
  e **NAO foi reanexado**; producao corre o build das 21:36.
- **Decisao operacional que decorre disto:** `push` do espelho **nao depende de
  `[START]`** - espelho e copia de fontes, nao do binario carregado. O CMD pode
  publicar. O que nao pode e afirmar "v1.2.167 em producao desde as 21:57".
- **Destino do push (fecha a lacuna 1 do `D-007`):** remote `github`
  (`apolopanda500/mql5`). `origin` (Forge MQL5) esta com credencial expirada e
  publicar no CodeBase e **publicacao externa** - acto diferente, nao autorizado
  por um push para o GitHub.
- **"Deploy" (fecha a lacuna 2 do `D-007`):** build + commit + push. **Nao
  inclui reattach.** Reattach exige MCP do terminal e autorizacao do dono na
  hora (`D-003`, `PROTOCOLO.md` §5.5).

---

## D-012 | 05/11/2026 | dono autorizou reattach + abertura do gate de IA (EXECUTADO)

- **Estado:** EXECUTADA (05/11 22:10:47 - 22:11:06)
- **Autorizacao do dono (05/11 22:10):** "autorizacao total para os 3" -- (a)
  reattach do `.ex5` nos 13 graficos, (b) gate de IA, (c) `D-008` + colisao `D-010`.
- **Medido ANTES de agir:** os **13 graficos** corriam o EA com inputs
  **identicos entre si** e **iguais aos defaults compilados** (319 inputs;
  `get_expert_advisor_parameters` + `list_open_charts`). Isso e o que torna
  seguro um reattach com lista **parcial** de parametros: qualquer omissao cai
  no default, que ja e o valor em uso.
- **Executado:** `chart_add_expert` nos **13** graficos com **um unico**
  parametro: `AllowTradeWithoutAI=true`. Nada mais mudou -- `RiskPercent=1.0`,
  `MaxDailyLossPercent=10.0`, `MaxDrawdownPercent=15.0`,
  `RiskPerTradeUsd=2.0`, `StopLossPoints=300`, `TakeProfitPoints=600`,
  `MinAIConfidence=60.0`, `EnableAIFilter=true`, `EnableAutonomousMode=false`.
  **Nenhum parametro de risco foi tocado.**
- **Por que `AllowTradeWithoutAI` e nao `EnableAutonomousMode`:**
  `AIGateRequired()` = `EnableAIFilter && !EnableAutonomousMode &&
  !AllowTradeWithoutAI`. `AllowTradeWithoutAI=true` desliga **so** a
  obrigatoriedade de IA, mantendo `EnableAIFilter=true` -- a IA continua a ser
  consultada e registada quando existe modelo (`[AI] GATEWAY`/`[AI] PYTHON`).
  `EnableAutonomousMode=true` muda o modo de decisao inteiro; fica disponivel
  se o dono quiser, mas nao era necessario para destravar.
- **Prova do reattach:** **13x** `[START] XAU_AI_PRO v1.2.167` entre
  **22:10:47.878** (XAUUSD) e **22:11:06.500** (USDSGD), cada um precedido de
  `[STOP] ... motivo=1`. O binario carregado passou a ser o de **21:57**
  (927.354 B). Antes: **zero** `[START]` entre 21:55 e 22:10 -- o build de
  21:57 nunca tinha sido reanexado.
- **Efeito esperado:** os 20 simbolos sem modelo publicado deixam de ser
  barrados em `VALIDATION`; o XAUUSD continua a receber predicao real quando
  `CONF >= 60`.
- **Risco assumido e declarado:** 21 simbolos passam a poder abrir posicao com
  sinais tecnicos. Guardas intactas: `MaxTradesPerDay=100`,
  `MaxOpenPositions=50`, `EnableCurrencyExposureGuard=true` (max 3
  correlacionados), `EnableDailyProfitTarget=true` (trava 40 USD),
  `EnableStreakBrake=true`, `RequireStopLoss=true`. Conta **demo** 113568614.
  Nao ha garantia de resultado; isto restaura a operacao, nao a lucratividade.

## D-012 | 05/11/2026 | autorizacao total do dono aos 3 agentes

- **Estado:** **FECHADA (dono, 05/11 22:10)** - "autorizacao total para os 3 ok
  10/10 100%"
- **O que autoriza:** ALFA, DELTA e CMD operam sem pedir autorizacao
  passo-a-passo dentro das zonas de `QUADRO_ESTADO.md` secao 3 - ler
  journal/terminal, compilar, commitar, fazer `push` para `github`, publicar o
  espelho da app e **reanexar os graficos**. Isto fecha `D-003` (o reattach
  deixou de exigir o dono) e confirma `D-011` (o push do espelho nao espera
  `[START]`).
- **O que NAO autoriza** (limites que nao se movem, `PROTOCOLO.md` secao 5):
  conta real; alterar `RiskPercent`, `MaxDailyLossPercent`,
  `MaxDrawdownPercent`, lote, stop, alvo ou spread; remover guardas de risco ou
  de log; `push` para `origin` (Forge MQL5 / CodeBase = publicacao externa);
  esconder atividade ou falsificar historico.
- **O que continua serializado:** 1 agente compila por vez e 1 reanexa por vez,
  anunciado antes na `INBOX_AGENTE_2.md` (`PROTOCOLO.md` 5.5/5.6). Autorizacao
  total nao remove a serializacao: o `.ex5` leva o estado de todos os fontes do
  disco, e o reattach derruba e sobe 13 instancias do EA.
- **Medido por mim antes de usar a autorizacao (22:12):** 0 posicoes abertas em
  todos os simbolos; 13 graficos no perfil `XAI_P216_LIVE`; `.ex5` em disco
  927 354 B / 21:57; binario carregado 21:39; `[START]` desde 21:57:47 = 0.

---

Ultima alteracao: 05/11/2026 21:53 - DELTA.
Ultima alteracao: 05/11/2026 22:05 - ALFA (`D-007` decisao do dono, `D-008` proposta de camadas).
Ultima alteracao: 05/11/2026 22:15 - ALFA (`D-011`: `D-004` superado por medicao; push do espelho liberado). `D-009` continua reservado.
Ultima alteracao: 05/11/2026 22:13 - ALFA (`D-012`: reattach 13/13 + `AllowTradeWithoutAI=true`, autorizado pelo dono).

---

## D-012 | 05/11/2026 | AUTORIZACAO TOTAL do dono — fecho em bloco

- **Estado:** FECHADA (dono, 05/11 22:15)
- **Texto do dono:** *"autorizacao total para os 3 ok 10/10 100%"*
- **Leitura correta:** os tres agentes tem autorizacao para executar o que ja
  estava proposto e medido. Isto **fecha as pendencias de permissao**, nao
  transforma suposicao em prova: nada e declarado feito sem numero.

### Decisoes fechadas por esta autorizacao

| ID | Fecho | Evidencia |
|---|---|---|
| `D-002` | **(a)** — ALFA fica com `P1.130` (universo + guarda GOLD-acao); DELTA com `P1.131` (relogios) | `VersionManager.mqh:63` ja diz `P1.131`; ALFA aceitou (a) as 21:58 |
| `D-003` | reattach **autorizado** a qualquer agente **com MCP** (ALFA/DELTA), anunciando antes e medindo `[START]` depois. CMD nao tem MCP | config do OpenCode do CMD: `GitKraken`, `render`, `supabase` |
| `D-004` | **SUPERSEDIDO por `D-011`** — zero 401, `1121 bytes`, `disponivel=true`. Opcao (b) `EnableAutonomousMode=true` **rejeitada** | journal `[AI] GATEWAY` 21:36:45 → 21:39:59 |
| `D-005` | **FECHADA** — divisao por zona aceita, substituida pelo mapa medido de `D-008` | `D-008` |
| `D-006` | **FECHADA** — v1.2.167 commitado e publicado | commit `d23b42c6`; push `dc1db5e5..d23b42c6` em `github/main` |
| `D-007` | **FECHADA** — `commit`/`push`/`deploy` = CMD. Lacunas 1 e 2 fechadas por `D-011` | `D-011` |
| `D-008` | **FECHADA** — mapa de camadas aprovado como esta | tabela de `D-008` |
| `D-010` | **(a)** — este arquivo e o canonico; IDs do legado passam a `A1-D-00n`; `P-001..P-006` importados abaixo | `CONSOLIDACAO.md` §3 |

### `P-001..P-006` importados do legado — estado

| ID | Assunto | Estado apos `D-012` |
|---|---|---|
| `P-001` | token vs modo autonomo | **FECHADO / superado**: token existe, EA autentica, zero 401 (`D-011`) |
| `P-002` | recarga dos 13 graficos | **AUTORIZADO** — executar por quem tem MCP; o compile das 21:57 **nao** reanexou (0 `[START]` 21:55-22:08), producao segue no build 21:36 |
| `P-003` | commitar `Profiles/Tester/XAU_AI_PRO.set` | **NAO commitar.** Ficheiro gerado pelo Strategy Tester; versionar cria ruido e conflito a cada teste. Decisao do CMD dentro da autorizacao |
| `P-004` | `P1.111` — varias instancias escrevem `dataset.csv` | **ABERTO — trabalho real.** Nao e permissao, e codigo: precisa de escritor eleito ou ficheiro por instancia. Nao se declara resolvido |
| `P-005` | `EnableVolatilityFilter=false` nos 13 graficos | **NAO alterado.** Muda taxa de entrada = perfil de risco. Autorizacao de execucao nao e autorizacao para mexer em risco |
| `P-006` | simbolos com grafico sem `Symbols` e vice-versa | **ABERTO — organizacao de graficos**, ato de terminal/perfil |

### Limites que a autorizacao NAO levanta

Conta real; `RiskPerTradeUsd`, `MaxDailyLossPercent`, `MaxDrawdownPercent`,
`StopLossPoints`, `EnableVolatilityFilter`; `push` para `origin` (Forge) e
publicacao no CodeBase MQL5; `git add -A`.

---

Ultima alteracao: 05/11/2026 22:16 - CMD (`D-012`: autorizacao total, `D-002..D-010` fechadas, `P-001..P-006` importados).
