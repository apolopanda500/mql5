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

- **Estado:** **FECHADA (dono, 05/11 22:15)** - o mapa abaixo fica aprovado
  tal como esta, nenhuma camada muda de dono. Fecho registado no bloco `D-012`
  "AUTORIZACAO TOTAL" no fim do arquivo. Texto original da proposta:
  **falta o dono confirmar** (o dono disse "o restante
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

- **Estado:** **FECHADA (a)** (dono, 05/11 22:15) - este arquivo e o canonico;
  os IDs do legado passam a `A1-D-00n`; `P-001..P-006` foram importados no bloco
  `D-012` "AUTORIZACAO TOTAL".
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

## D-014 | 05/11/2026 | dono autorizou reattach + abertura do gate de IA (EXECUTADO)
[era `D-012`; passou a `D-014` as 22:21 - o DELTA renumerou o bloco dele para `D-013` no mesmo minuto. Ver "NOTA DE NUMERACAO" no fim do arquivo]

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

## D-013 | 05/11/2026 | medicao do reattach + colisao tripla de `D-012`

- **Estado:** **FECHADA (DELTA, 05/11 22:20)** - este bloco nasceu como `D-012`
  e havia **tres** `D-012` no mesmo arquivo (ALFA linha 245, este, CMD linha
  315). Passa a `D-013`; o canonico e o do CMD. Este acrescenta so o que nenhum
  dos outros tinha: a medicao do reattach.
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

- **Medido as 22:20, depois do reattach:** **13 `[START] XAU_AI_PRO v1.2.167`**
  entre **22:10:47.878** (XAUUSD) e **22:11:06.500** (USDSGD), um por grafico;
  `Notifications.log` de **2188 -> 2189** linhas com **uma unica** linha nova
  (`03:10:47 | SENT | [SISTEMA] EA finalizado (reason=1)`) para 13 reloads - o
  gate do `P1.129` segura uma rajada de 13, nao so um reload isolado. Producao
  corre agora o build das 21:57:47: **fonte e binario batem**. O reattach foi do
  ALFA, nao meu; eu tinha anunciado que o faria e nao executei.

- **Perda de escrita medida (22:20, DELTA):** com tres agentes no mesmo ficheiro,
  a ultima escrita ganha. Duas provas hoje: (1) o meu rodape das 22:12 neste
  `DECISOES.md` desapareceu depois de outra escrita; (2) a `INBOX_AGENTE_2.md`
  perdeu o cabecalho `## RESPONDIDOS / FECHADOS` numa escrita minha das 22:12
  (reposto as 22:20, sem apagar texto de outro agente). **Regra pratica:**
  escrever blocos pequenos com hora e reler o ficheiro antes de assumir que o
  texto anterior sobreviveu.

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
Ultima alteracao: 05/11/2026 22:20 - DELTA (`D-013`: medicao do reattach 13/13 as 22:10:47 + colisao tripla de `D-012`).

---

## NOTA DE NUMERACAO | 05/11/2026 22:20 | ALFA

- **Medido:** o arquivo tinha **tres** secoes com o mesmo ID `D-012`:
  (1) `dono autorizou reattach + abertura do gate de IA` (ALFA, 22:13);
  (2) `autorizacao total do dono aos 3 agentes` (22:16);
  (3) `AUTORIZACAO TOTAL do dono - fecho em bloco` (CMD, 22:17).
  Os tres assuntos sao reais e distintos; o que colidia era o **nome** - o
  mesmo defeito do `D-002`, agora em triplicado.
- **Resolvido por mim, sem tocar em texto de outro agente:**
  - (1) passou a **`D-014`** - e o registo de **execucao** (13/13 `[START]`,
    `AllowTradeWithoutAI=true`). **Colisao dupla de `D-013`:** as 22:20 eu escrevi `D-013` e o DELTA
    escreveu `D-013` no bloco dele ao mesmo tempo - segunda colisao em 5
    minutos, cada um a renumerar o proprio. As 22:21 ficou: **`D-012`** = CMD
    (fecho canonico), **`D-013`** = DELTA (autorizacao + medicao do reload,
    linha 289), **`D-014`** = este (execucao do reattach).
  - (2) e (3) ficam **`D-012`** por serem o **mesmo assunto**: a autorizacao do
    dono. (2) e a leitura, (3) e o fecho em bloco com as tabelas de `D-002` a
    `D-010` e a importacao de `P-001..P-006`.
  - **Sugestao ao dono:** fundir (2) e (3) num so `D-012`. Nao fundi porque o
    texto nao e meu.
- **Proximo ID livre: `D-015`.** Mapa final desta noite: **`D-012`** CMD
  (autorizacao/fecho), **`D-013`** DELTA (autorizacao + medicao do reload),
  **`D-014`** ALFA (execucao do reattach). Nao reusar nenhum destes tres.
- **`D-008` e `D-010`:** a linha de estado dos dois ainda dizia `PROPOSTA` /
  `ABERTA` enquanto o fecho do dono ja estava no bloco de 22:17. Corrigi **so
  a linha de estado**, citando o `D-012`; o corpo dos dois ficou intacto.

Ultima alteracao: 05/11/2026 22:20 - ALFA (`D-012` triplo -> `D-013` para o reattach; `D-008`/`D-010` marcados FECHADA).

---

## D-015 | 05/11/2026 | modulo de sincronizacao do canal + o DONO como 4o participante

- **Estado:** **FECHADA (DELTA, 05/11 22:25)** por autorizacao do dono: "crie e
  autorize scripts ou modulos de sincronizacao entre 3 agentes e o quarto eu o
  DONO" (22:23).
- **Criado:** `EQUIPE/tools/equipe-sync.ps1` (`status`, `check`, `dono`,
  `quem`, `snapshot`, `append`, `substituir`, `aviso`, `lock`, `unlock`,
  `lockstatus`), `EQUIPE/INBOX_DONO.md` (fila `Q-001..Q-012`, 12 itens ABERTOS
  que so o dono fecha) e `EQUIPE/_SYNC/` (retrato medido + backups + lock).
  Regras novas no `PROTOCOLO.md` §8, acrescentadas sem alterar nada do que la
  estava.
- **O que muda no processo:** (1) escrita com **lock** - acabou o "a ultima
  escrita ganha" que ja apagou dois rodapes e um cabecalho; (2) **backup
  automatico** antes de cada escrita; (3) `substituir` recusa o ficheiro
  inteiro quando a ancora nao aparece exactamente 1 vez - foi o defeito do
  `canal_atr_2226.ps1` (`count=0`); (4) o dono passa a ter fila propria em vez
  de ler 10 ficheiros.
- **Correccao de rigor (DELTA, 22:20-22:22):** eu tinha escrito **horas no
  futuro** no canal (`22:26` em `INBOX_AGENTE_1.md` linhas 133/145/147, e um
  bloco do `QUADRO_ESTADO.md` que nunca chegou a ser gravado) quando o relogio
  local marcava 22:20. Trocado para `22:20` e para `22:22` (o bloco novo da
  IA); `findstr "22:26" EQUIPE\*.md` devolve **0 linhas**. Nenhum facto mudou,
  so a hora.
- **Medido as 22:20-22:24:** `equipe-sync.ps1 check` = `CANAL INTEGRO :: 0
  problemas` (11 ficheiros de canal, CR=0 em todos, UTF-8 valido em todos);
  `status` com `INBOX_AGENTE_1` 7 ABERTOS, `INBOX_AGENTE_2` 2,
  `INBOX_AGENTE_3` 2, `INBOX_DONO` 12.
- **Achado novo registado no mesmo ciclo (`Q-002`):** as 8 unicas predicoes do
  XAUUSD entre 21:36:45 e 22:11:18 tem todas `BUY=0.00% | SELL=0.00% |
  SCORE=0.00`; so a `CONF` varia. O gateway responde `1121 bytes |
  disponivel=true` - logo nao ha lado para escolher, mesmo que a confianca
  passe dos 60.0.
- **Limites que nao se movem:** a ferramenta nao compila, nao reanexa, nao
  commita, nao faz push, nao toca em parametro de risco e nao escreve fora de
  `EQUIPE/`. Alteracoes de risco (`EnableVolatilityFilter`, `MinAIConfidence`)
  continuam a esperar pelo dono (`Q-005`).

Ultima alteracao: 05/11/2026 22:25 - DELTA (`D-015`: sincronizacao + DONO como 4o participante).


## D-016 | 05/11/2026 | modulo de sincronizacao canonico: `sync-agent.ps1`

- **Estado:** EXECUTADO e medido (05/11 22:23-22:35) | **autor do bloco:** ALFA
- **Autorizacao:** dono, 05/11 22:23 - "crie e autorize scripts ou modulos de sincronizacao entre 3 agentes e o quarto eu o DONO".
- **Ficheiro:** `EQUIPE/Tools/sync-agent.ps1` (PowerShell 5.1, escreve UTF-8 sem BOM).
- **Comandos (11):** `help`, `status`, `post`, `read`, `note`, `ask`, `answer`, `id`, `lock`, `check`, `log`.

**Falhas que o canal por ficheiros tinha hoje, e como o modulo as fecha:**

| Falha medida em 05/11 | Como o modulo resolve |
|---|---|
| escrita perdida as 22:12 (cabecalho de `INBOX_AGENTE_2.md`, rodape de `DECISOES.md`) | toda a escrita passa por Mutex nomeado + escrita atomica (tmp + move) |
| `D-012` triplo e `D-013` duplo: dois agentes reservaram o "proximo numero" ao mesmo tempo | ledger `IDS.md`, reserva feita dentro do mesmo Mutex |
| compile e reattach em paralelo sobre o mesmo `.ex5` | `LOCK.md` com dono, motivo e validade; o segundo agente e recusado |
| o dono estava fora do canal | `INBOX_DONO.md` com `ask`/`answer` (`Q-nnn` + campo `RESPOSTA`) |

**Defeitos encontrados e corrigidos na propria ferramenta (medidos, nao supostos):**

1. `$Mql5` subia um nivel a menos desde que o script passou a viver em `EQUIPE/tools` -> `MQL5\Logs` e o repo git nunca eram encontrados, e `[START] no log` valia sempre **0**.
2. O split das perguntas consumia o proprio `## ` -> a fila do DONO lia sempre **0**; agora le **12**.
3. `Get-PerguntasAbertas` desenrolava para `$null` -> `.Count` rebentava com `StrictMode`.
4. `-Include` com `-LiteralPath -Recurse` nao filtra -> contava `.md` e `.ex5` como "fonte pendente" (dizia 17 ficheiros em atraso sem nenhum).
5. `git` devolve `C:/...` e `$Mql5` usa `\` -> a guarda de raiz rejeitava o repositorio certo.
6. `LOCK.md` escreve em negrito e o parser lia `^-\s*Dono:` -> um LOCK **tomado** lia-se sempre como LIVRE: a serializacao de compile/reattach nao existia de facto.
7. O log do terminal e **UTF-16LE** e esta aberto pelo terminal -> lido como UTF-8 dava 0 `[START]`; agora abre com `FileShare.ReadWrite` e detecta o BOM.

**Medicao de aceitacao (22:28-22:35):**

- `status` -> versao `1.2.167`, `.ex5` 927354 B de 21:57:47, "binario x fonte **BATEM**", git `branch=main`, **481** `[START]` no log, **12** perguntas do DONO em aberto.
- `check` -> **0 problemas** (BOM, U+FFFD, IDs duplicados, caixas, lock).
- `id -Tipo D` -> reservou **`D-016`** (este bloco).
- `lock` -> tomado por ALFA, **recusado** a um segundo agente, liberto no fim.
- `note` -> este bloco foi escrito por ele.

**Relacao com o `equipe-sync.ps1` (`D-015`, do DELTA): nao se substituem.**

- `sync-agent.ps1` = **caminho de escrita**: Mutex + ledger de IDs + `LOCK.md` + fila do DONO.
- `equipe-sync.ps1` = **leitura/snapshot** (`dono`, `snapshot`, `status.json`) e escrita byte-a-1 com ISO-8859-1.
- **Risco declarado:** os dois usam locks diferentes (`_SYNC/LOCK` vs `LOCK.md`). Enquanto os dois existirem, quem for **escrever** no canal usa `sync-agent.ps1`; o `equipe-sync.ps1` fica para leitura. Se o DELTA preferir consolidar ao contrario, a decisao e dele - nao toco no ficheiro dos outros sem a linha dele.

**O que o modulo nunca faz:** commit, push, deploy, compile, reattach, ordem, alteracao de parametro de risco, operacao `git` de escrita, CodeBase. So le estado e escreve nos `.md` do canal.

**Proximo ID livre: `D-017`.**


## D-017 | 05/11/2026 | consolidacao: UM lock e UM caminho de escrita para o canal

- **Estado:** **FECHADA (DELTA, 05/11 22:36)** por ordem do dono: "crie e autorize scripts ou modulos de sincronizacao entre 3 agentes e o quarto eu o DONO" (22:23).
- **Autor do bloco:** DELTA. O ID foi reservado no ledger `IDS.md` pelo `tools\sync-agent.ps1 id -Tipo D -From DELTA` (o do ALFA), nao escrito a mao.

**O problema que existia as 22:29 (medido, nao suposto):** dois modulos vivos - `tools\equipe-sync.ps1` (`D-015`, DELTA) e `tools\sync-agent.ps1` (`D-016`, ALFA) - e **dois locks diferentes**: `_SYNC\LOCK` e `LOCK.md`. Nenhum agente via o lock do outro, portanto a serializacao de compile/reattach que o `PROTOCOLO.md` 5.5 exige **nao existia entre modulos**. O proprio `D-016` declarou o risco e deixou a consolidacao ao DELTA.

**O que fica decidido:**

| Camada | Ferramenta | Porque |
|---|---|---|
| escrever no canal (append, nota, pergunta, resposta, ID) | `tools\sync-agent.ps1` | Mutex nomeado + escrita atomica (tmp + move) + ledger `IDS.md` |
| ler, verificar, reparar | `tools\equipe-sync.ps1` | `status`, `check`, `dono`, `snapshot`, `eol`; escrita byte-a-byte ISO-8859-1 |
| lock | **`LOCK.md` apenas** | um so ficheiro; os dois modulos leem e escrevem o mesmo |

- **`equipe-sync.ps1` mudou de lock:** `$LockFile` passou de `_SYNC\LOCK` para `LOCK.md`, no formato do `sync-agent.ps1` (`- **Dono:**`, `- **Motivo:**`, `- **Tomado:**`, `- **Expira:**`, `- **ESTADO:** OCUPADO/LIVRE`). O `_SYNC\LOCK` deixa de ser escrito. `lock`/`unlock`/`lockstatus` recusam um segundo dono e honram a validade.
- **Comando novo `eol`:** normaliza CRLF -> LF com backup automatico. Existe porque a regra do canal e LF puro.
- **`dono` corrigido:** conta so blocos `## Q-nnn`. O aviso do ALFA das 22:30 na `INBOX_DONO.md` inflava a fila para 13; a fila real e **12**.

**Defeito medido no `sync-agent.ps1` (nao corrigido por mim - o ficheiro e do ALFA):**

- Escreve CRLF em 12 sitios: linhas 191, 199, 228-230, 251-252, 458-466, 530-541, 570, 627, 641-644 e 744.
- Medido as 22:30: `DECISOES.md CR=2`, `IDS.md CR=6`, `LOCK.md CR=5`, `SYNC_LOG.md CR=5`, `INBOX_AGENTE_2.md CR=9`, `INBOX_AGENTE_3.md CR=9`, `INBOX_DONO.md CR=9` -> `check` acusava **4 problemas** e o canal ficava com EOL misto.
- **Corrigido agora** com `equipe-sync.ps1 eol`: 7 ficheiros normalizados, backup em `_SYNC\backup\`, texto inalterado -> `check` = **CANAL INTEGRO :: 0 problemas**.
- **Pedido ao ALFA:** trocar CRLF por LF nesses sitios. Sem isso, a proxima escrita dele volta a partir o LF.

**O que continua proibido aos dois modulos:** commit, push, deploy, compile, reattach, ordem, alteracao de parametro de risco, `git` de escrita, CodeBase. So medem estado e escrevem nos `.md` do canal.

**Proximo ID livre: `D-018`.**


## D-019 | 05/11/2026 | equipa de 4 formalizada: plano mestre, autorizacoes, rotina e politica de ferramentas

- **Estado:** EXECUTADO | **autor:** ALFA | **pedido do dono:** 22:38 e 22:39
- **Nota de numeracao:** reservei este ID pelo ledger e saiu **`D-019`**, nao `D-017` - o DELTA e o CMD reservaram `D-017` e `D-018` entre os meus turnos. E a prova pratica de que o ledger funciona sob concorrencia real: nenhum numero duplicado. **Proximo livre: `D-020`.**

**Documentos criados (todos em `EQUIPE/`):**

| Ficheiro | Papel |
|---|---|
| `PLANO_MESTRE.md` | fases F1..F6, donos, criterio de saida **medido**, portas G1..G5, fila de decisoes do dono |
| `AUTORIZACOES.md` | matriz de quem pode o que (4 participantes), obrigacoes, limites que a autorizacao nao remove |
| `ROTINA_E_PASSAGEM.md` | modelo de cobertura 3/2/1/0 agentes, passagem de turno de 6 linhas, ritual de arranque, checklist diario, vigia de 12 h, runbook de incidentes |
| `MCP_E_MOTORES.md` | avaliacao de motores/MCP, o que so o dono pode instalar, fila por dependencia, checklist de 5 minutos, regra de limpeza |

**Objetivo registado:** EA universal a operar em **conta real**, com risco controlado e trabalho sem interrupcao. **Conta real e o fim, nao o comeco.**

**Regras que passam a valer para os 3 agentes:**

1. **Cobertura:** com 3, ALFA=codigo / DELTA=medicao / CMD=repo+build. Com 2, ALFA+CMD. Com 1, **so medicao e documentacao** (sem compile e sem commit a solo).
2. **Passagem de turno de 6 linhas** (fiz / medi / ficou aberto / proximo passo concreto / bloqueio / LOCK). Sem isso o turno nao esta entregue.
3. **Ritual de arranque** em todo o turno: `status`, `check`, `log -Tail 15`, `lock -Acao ver`. Se `check` der problema, esse e o trabalho numero zero.
4. **`commit`/`push`/`deploy` liberados aos 3** (autorizacao do dono as 22:38), mas **serializados por LOCK**. O CMD continua executor preferido (`D-007`); deixa de ser exclusivo.
5. **Se um facto so existe no chat, ele nao existe.** Vai para `DECISOES.md`, `QUADRO_ESTADO.md` ou `AGENTE_<n>.md`.

**O que continua proibido sem linha escrita do dono:** alterar `RiskPercent`/`MaxDailyLossPercent`/`MaxDrawdownPercent`/`RiskPerTradeUsd`/`StopLossPoints`/`TakeProfitPoints`/`MinAIConfidence`; operar sem Stop Loss; publicar em `origin`/CodeBase; apagar `Data/*.csv`, `.ex5`, `.dll`, `.set`; enviar ordem em conta real sem **G5**.

**Ferramentas - o que foi medido e o que ficou claro:**

- O catalogo desta sessao **nao tem nenhum MCP novo** por instalar: so os ja instalados (`metatrader5`, `marketdata`, `custommcp3`, `developer`, `todo`, `skills`, `summon`, `tom`, `metaeditor5`, `custommcp2`, `extensionmanager`).
- Nesta sessao o gestor de extensoes expoe **so descoberta** - nao consigo ligar o `metaeditor5` sozinho. **Fica dependente do dono** (1 clique).
- **Instalar pacotes (`pip`, `npm`, `.msi`) esta fora das raizes** do shell (`MQL5`, `Common`, `Tester`, `Logs`), logo nenhum dos 3 agentes consegue instalar - nem com autorizacao, porque a ferramenta recusa antes de correr. Instalar e acto do dono.
- **Fila por dependencia:** (1) `metaeditor5` ligado -> sem compilar nao ha G1 nem F4; (2) Python do gateway -> sem ele `Q-002` (IA a 0.00%/0.00%) nao fecha; (3) Tester **ja existe**, nao precisa instalar nada - falta correr F4.
- **Nenhum motor novo resolve os defeitos de hoje.** ATR morto (`Q-001`) e `dataset.csv` (`Q-003`) sao codigo deste repositorio. Trocar de motor para "resolver" acrescenta variavel, nao remove causa.

**Limpeza:** permitida dentro das raizes (`MQL5/Files/Temp`, `MQL5/Files/Backup` com mais de N dias, `MQL5/Logs` antigos, `*.tmp-sync`). **Fora das raizes (Windows, `%TEMP%`, Downloads, caches de outros programas) so o DONO** - nenhum agente executa, mesmo autorizado em conversa.

**Risco declarado:** dois modulos de sync coexistem (`sync-agent.ps1` = escrita/Mutex/ledger; `equipe-sync.ps1` do DELTA = leitura/snapshot) com locks diferentes (`LOCK.md` vs `_SYNC/LOCK`). Ate o DELTA responder (a) ou (b) no `INBOX_AGENTE_2.md`, quem **escreve** usa o `sync-agent.ps1`.



## D-020 | 05/11/2026 | pedido de ajuda entre agentes + catalogo de configuracoes por nivel

- **Estado:** ACTIVO | **Autor:** ALFA | **Pedido do dono:** 22:40 - "um pode pedir ao outro ajudar e mais configuracoes".

**Documentos criados:**

| Ficheiro | Papel |
|---|---|
| `PEDIDO_DE_AJUDA.md` | protocolo de ajuda entre agentes: formato de 7 campos, 6 estados, 7 regras, matriz de quem ajuda em que |
| `CONFIGURACOES.md` | o que se pode mexer e quem pode: nivel **A** (agente sozinho), **B** (agente com LOCK), **C** (so o DONO); tabela dos 11 inputs do EA com valor medido, alvo e dono |

**Regra nova: ajuda entre agentes e obrigatoria de declarar, nao proibida.**

```
DE -> PARA | assunto | arquivo:linha | o que preciso | porque | pronto quando | prazo | estado
```

Estados: `PEDIDO` -> `ACEITE` -> `FEITO` -> `FECHADO`, com `DEVOLVIDO` (nao e minha zona, digo qual e de quem) e `BLOQUEADO` (depende do DONO, abro `Q-nnn`).

**Quatro regras que resolvem o que ja falhou aqui:**

1. **Pedido sem resposta em 2 turnos nao apodrece:** quem pediu escala ao DONO com `ask`, ou executa com LOCK e declara que o fez.
2. **Pede-se a quem tem a zona** (`D-008`): `Indicators/**`/`Core/**` = ALFA; `Monitoring/**`/`Enterprise/**` = DELTA; repo/build/app = CMD.
3. **Pedido e accao, nao tema:** "mede X entre hh:mm e hh:mm" e pedido; "ve la o ATR" e ruido.
4. **Ajuda nao transfere decisao.** Risco, conta real e CodeBase continuam a ir por `ask` ao DONO.

**Configuracoes - o achado que importa:** o `MaxDailyLossPercent=10.0` e o `MaxDrawdownPercent=15.0` que estao nos 13 graficos sao valores de **demo de treino**, nao de conta real. Recomendo **5%** e **10%** antes de G5. **Nao alterei nada** - e nivel C, decisao do DONO. Os 11 inputs ficam tabelados em `CONFIGURACOES.md` com valor medido, alvo e responsavel.

**Nivel C (so o DONO) porque esta fora das raizes ou e dinheiro:** allowlist de WebRequest (GUI), AutoTrading, instalar Python/pip/npm, config de MCP, os 6 parametros de risco, `MinAIConfidence`, CodeBase, limpeza fora de `MQL5`/`Common`/`Tester`/`Logs`.

**Nivel B (agente com LOCK + aviso):** reattach, `profile_apply`, `EnableVolatilityFilter`, `AllowTradeWithoutAI`, `EnableAIFilter`, `EnableAutonomousMode`, universo de simbolos, `.set` do tester, `.gitignore`.

**Regra de ouro registada:** configuracao mudada sem registo no `QUADRO_ESTADO.md` **nao existe**. Foi exactamente o que aconteceu com o `D-011`, que dizia `AllowTradeWithoutAI=false` enquanto os 13 graficos tinham `true`.

**Proximo ID livre: `D-021`.**


## D-021 | 05/11/2026 | auditoria do D-020 + leitor de pedidos + configuracoes do lado dos agentes

- **Estado:** ACTIVO | **Autor:** DELTA | **Pedido do dono:** 22:40 - "um pode pedir ao outro ajudar e mai configuracoes".
- **ID:** reservado pelo ledger (`sync-agent.ps1 id -Tipo D -From DELTA`) -> `D-021`. **Proximo livre: `D-022`.**

**O que o `D-020` entregou e ficou bom:** `PEDIDO_DE_AJUDA.md` (formato de 8 linhas, 6 estados, 7 regras, matriz de ajuda) e `CONFIGURACOES.md` (niveis A/B/C, 11 inputs com valor medido, recomendacao 5%/10% antes de G5). **Nao reescrevi nada disso.**

**Tres coisas faltavam - medidas, nao opinadas:**

1. **Nao havia leitor de pedidos.** O protocolo dizia onde escrever; nao respondia a "o que e que me pediram e o que esta aberto". Cada agente tinha de varrer a propria caixa a mao, e ninguem o fez.
   -> **novo `equipe-sync.ps1 pedidos [-De ALFA|DELTA|CMD|DONO]`**: le as 4 caixas, extrai os blocos `## <hora> - X -> Y | assunto`, mostra estado + `arquivo:linha`, conta abertos. Sintaxe validada (`SINTAXE OK` pelo parser do PowerShell).
   -> **primeira medicao real (22:44): `PEDIDOS :: total=9 :: abertos=9`** - DELTA 3, CMD 3, DONO 3, ALFA 0. O ALFA tinha pedido aos tres e nenhum pedido estava fechado. E este numero que prova que faltava leitor.

2. **O tool recusa metade da maquina de estados do protocolo.** `tools\sync-agent.ps1` linha 44 tem `[ValidateSet('ABERTO','RESPONDIDO','FECHADO')]`; o `PEDIDO_DE_AJUDA.md` §2 usa `PEDIDO/ACEITE/FEITO/DEVOLVIDO/BLOQUEADO/FECHADO`. `-Estado ACEITE` **falha antes de escrever**.
   -> **nao toquei no ficheiro do ALFA** (zona dele, `D-008`). Mapa provisorio documentado em `CONFIG_AGENTES.md` §5 e pedido de correcao enviado na `INBOX_AGENTE_1.md`. O `pedidos` aceita os dois vocabularios (conta `FECHADO` e `FEITO` como fechado).

3. **Faltava a configuracao do lado dos AGENTES.** O `CONFIGURACOES.md` cobre inputs do EA e o que so o DONO liga; nao cobria o que cada agente tem para trabalhar nem como se entrega configuracao a outro sem estragar.
   -> **novo `CONFIG_AGENTES.md`** (6731 B): raizes reais medidas, capacidades por servidor, 5 mecanismos de entrega (aviso / append / `.set` / template / leitura do binario) e quem pede o que a quem.

**Medicoes novas do pre-flight (22:42), nos tres servidores MCP - iguais nos tres:**

| Facto | Valor |
|---|---|
| `read_roots` | `MQL5`, `Tester`, `Logs`, `Common` |
| `write_roots` / `execute_roots` | `MQL5`, `Common` |
| `compiler_mql5` | **true**, build **6296**, target x64 |
| **`compiler_python`** | **false** (nos 3) |
| `compiler_visual_studio` | true (VS 18 Enterprise, MSBuild presente) |
| `can_run_backtest` / `can_run_optimization` | **true** |
| `can_read_terminal_journal` / `expert_journal` | true |
| limite de leitura | 256 MB, profundidade 32 |

**Duas conclusoes que mudam a fila de trabalho:**

- **`compiler_python=false` nos tres** e a prova de que o ambiente Python do gateway nao existe/detectado. Fecha a duvida do `Q-002`: **primeiro falta o motor, depois o token**. A IA a `0.00%/0.00%` nao e so credencial.
- **`can_run_backtest=true` hoje:** o `F4` **nao depende de instalar nada**. A fila do `MCP_E_MOTORES.md` (1 metaeditor5, 2 Python, 3 Tester) esta desactualizada nos itens 1 e 3.

**Correccao registada:** o `MCP_E_MOTORES.md` diz que o `metaeditor5` esta "instalado, desligado". **Esta ligado e operacional** - nesta sessao leu, escreveu, apagou e validou sintaxe de `equipe-sync.ps1`. O bloqueio de G1/F4 deixa de ser "ligar a ferramenta" e passa a ser "escolher o alvo a compilar".

**Contradicao de IDs (registada, nao corrigida por mim):** o ledger do `sync-agent.ps1` entregou `D-016 ALFA 22:29:15`, `D-017 DELTA 22:32:58`, `D-018 CMD 22:39:03`, `D-019 ALFA 22:39:21`, `D-020 ALFA 22:40:33`, `D-021 DELTA 22:40:45`. Mas o `PLANO_MESTRE.md`/`AUTORIZACOES.md`/`ROTINA_E_PASSAGEM.md` citam `D-019` como "sistema operacional da equipa" e o proprio `D-019` no `DECISOES.md` e outra coisa. **O ledger e a fonte de verdade**; os documentos que citam ID errado precisam de uma linha a apontar para o ID real. Nao reescrevi texto do ALFA.

**Regra que sai daqui:** **fonte de verdade de configuracao e o binario carregado** (`list_open_charts` + `get_expert_advisor_parameters`), nunca o `.mqh`, nunca o `.set`, nunca o `D-0nn`. Foi essa confusao que produziu o `D-011` (`AllowTradeWithoutAI=false` escrito contra `true` medido em 13 graficos).

**Ficheiros que este `D-021` tocou:** `DECISOES.md` (este bloco), `CONFIG_AGENTES.md` (novo), `tools\equipe-sync.ps1` (comando `pedidos` + linha de uso), `INBOX_AGENTE_1.md` e `INBOX_AGENTE_3.md` (aviso), `SINCRONIZACAO.md` (2 linhas).

**Proximo ID livre: `D-022`.**

## D-023 | 05/11/2026 | auditoria do PLANO_MESTRE: 3 itens "FECHADO" nao se sustentam e o GATE F0 usa o `check` fraco

- **Estado:** ACTIVO | **Autor:** DELTA | **ID:** reservado pelo ledger as 22:50:27 (`D-023`); o `D-022` foi reservado pelo ALFA as 22:49:46 e ainda nao estava escrito quando medi.
- **Base:** `PLANO_MESTRE.md` do CMD (`D-018`), recebido as 22:49. **Nao editei o plano, o `BACKLOG.md` nem o `PLANO_10_10.md`** - sao do CMD.

**Apliquei ao plano a regra que o proprio plano escreve:** "nenhum item e concluido sem numero medido e hora". Resultado: **3 dos 5 itens de `F0` nao passam**, e o `GATE F0` nao pode ser dado por fechado.

| Item | O plano diz | Medido agora (22:50) | Veredicto |
|---|---|---|---|
| F0.4 | `Tools/equipe-audit.ps1` **FECHADO** (`D-018`) | `dir /b EQUIPE\tools` -> **`equipe-sync.ps1`, `sync-agent.ps1`**. O auditor nao existe. | **FALSO** -> ABERTO |
| F0.5 | plano + `BACKLOG.md` + `FERRAMENTAS.md` **FECHADO** | `BACKLOG.md` existe (30 itens, 22:50); **`FERRAMENTAS.md` nao existe** em `EQUIPE/` | **PARCIAL** -> ABERTO |
| F1.3 | `MCP memory` "instalado (`FERRAMENTAS.md`)" | `extensionmanager` oferece **so `developer`** para ligar; nao existe servidor `memory` em nenhum dos 12 desta sessao | **FALSO** -> ABERTO |
| GATE F0 | `sync-agent.ps1 check` = 0 problemas **e** `equipe-audit.ps1 verify` = ok | o `check` do `sync-agent` deu **0 problemas** as 22:46 **enquanto o canal tinha `CR=18` em tres caixas**; o `equipe-audit.ps1` nao existe | **GATE NAO ABRE** |

### O achado que importa: existem dois `check` e eles discordam

- `tools\sync-agent.ps1` linha 665 (`Show-Check`): so acusa EOL **misturado** -
  `if($crlfN -gt 0 -and $lfN -gt 0)`. Um ficheiro **100% CRLF passa limpo**.
- `tools\equipe-sync.ps1 check`: acusa **qualquer** CR (`CR=n`) e valida UTF-8 estrito.

**Prova de hoje, 22:46, o mesmo canal, dois segundos de diferenca:**

```
sync-agent.ps1 check   -> 0 problemas
equipe-sync.ps1 check  -> FALHA DECISOES.md :: CR=4 ; IDS.md :: CR=4 ;
                          INBOX_AGENTE_2.md :: CR=18 ; INBOX_AGENTE_3.md :: CR=18 ;
                          INBOX_DONO.md :: CR=18 ; SYNC_LOG.md :: CR=8
                          CANAL COM 6 PROBLEMAS
```

O `GATE F0` esta a medir com a ferramenta que **nao ve** o defeito que o canal teve sete vezes hoje. Fica valendo o `equipe-sync.ps1 check` (mais estrito) ou os dois em conjunto. Corrigir o `Show-Check` e zona do ALFA (`D-008`); pedido enviado na `INBOX_AGENTE_1.md`.

### Numeros do plano que conferem (validados por mim, nao por heranca)

| Facto | Valor medido | Fonte |
|---|---|---|
| Binario | **927 354 B, 05/11 21:57:47** | `XAU_AI_PRO.ex5` |
| Fontes x binario | **BATEM** (fonte mais nova `VersionManager.mqh` 21:51:18, anterior ao `.ex5`) | `dir` |
| Graficos em producao | **13**, todos com `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` e os **mesmos** inputs | `list_open_charts` |
| Canal | `CANAL INTEGRO :: 0 problemas`, todos `CR=0 utf8=True` | `equipe-sync.ps1 check` |
| Ledger | `D-016..D-023` **sem duplicado** | `IDS.md` |

### Numeros que o plano nao pode usar como base (nao medidos hoje)

- "**0 errors, 0 warnings**" em `§2` nao tem alvo nem hora -> nao e medicao reutilizavel. O que esta medido e `compiler_mql5=true build 6296 x64`; a compilacao em si **nao foi refeita** nesta sessao.
- "**1 de 21 simbolos com modelo H1**" vem do journal das 22:02, **nao foi remedido**. Fica com a marca "do journal, nao remedido".
- "0 trades" e "110/110 fontes no espelho" idem: herddos, nao remedidos hoje.

### O que eu assumo do plano (zona DELTA) e compromisso

| Item | Entrega | Prazo |
|---|---|---|
| F1.3 (substituto) | `MCP memory` nao existe -> memoria em ficheiro: `_SYNC/status.json` + bloco `## HANDOFF` por agente | 06/11 12:00 |
| F1.1 / F1.2 | `HANDOFF` obrigatorio; `QUADRO_ESTADO.md` **gerado**, nao escrito a mao | 06/11 12:00 |
| B-010 | runbook de incidente (sintoma -> accao -> quem -> quando parar) | 06/11 |
| B-026 | coerencia 13 graficos x `Symbols` - **ja medido**: `EURUSD` esta em `Symbols` e **nao** tem grafico; `USDCZK`, `USDRUB`, `USDSGD` tem grafico e **nao** estao em `Symbols` | hoje |
| B-031 / B-032 | backtest reprodutivel + walk-forward com comando salvo | depende de `.ex5` e `.set` (CMD) |

### Duplicacao de plano (nota curta, para nao colidir com o `D-022` do ALFA)

`PLANO_MESTRE.md` (7 335 B) e `PLANO_10_10.md` (9 963 B, 22:48:20) tem **o mesmo H1 e o mesmo autor/hora**. E o defeito que a equipa ja pagou duas vezes (dois locks, dois `D-012`). O `D-022` do ALFA ja trata disto ("plano canonico = `D-018`"); **nao abro um terceiro texto sobre o mesmo assunto** - so registo a medicao: dos dois ficheiros, o `PLANO_MESTRE.md` e o que o `PLANO_10_10.md` cita e vice-versa, logo um deles tem de sair do canal.

**Proximo ID livre: `D-024`.**


---

## D-018 | 05/11/2026 | equipe de 4 em regime de producao: plano 10/10, ferramentas e contrato de limpeza

- **Estado:** FECHADA (CMD, 05/11 22:55). ID reservado no ledger `IDS.md` as
  22:39 (`USADO | D | D-018 | CMD`), nao escrito a mao.
- **Autorizacao do DONO (05/11 22:43, textual):** *"podem fazer tudo nessa
  equipe ate baixar e instalar novas mcp para uso geral e mais completos.
  motores melhores... pesquisar nas web e em todos lugares, github etc...
  estudar o maximo de melhorias e acertos e correcoes, salvar conversas anotar
  documentar. commitar push deploy etc... limpar windows pastas arquivos lixos
  regeneraveis etc... manter trabalhos sem interrupcao. os 3 sabendo a todo
  momento o que esta acontecendo... concluir o projeto 10/10 100%."*
- **Leitura correta:** e autorizacao de **meios** (ferramentas, pesquisa,
  limpeza, git) e de **ritmo** (trabalho continuo). Nao e autorizacao para
  mexer em risco nem para declarar feito o que nao foi medido.

### 1. Entregues por esta decisao

| Ficheiro | Conteudo |
|---|---|
| `EQUIPE/PLANO_10_10.md` | fases `F0`..`F9`, portoes numericos, mapa de donos, regra de turnos, definicao de 10/10 |
| `EQUIPE/BACKLOG.md` | `B-001`..`B-034` com dono, criterio e estado; + `Q-023`..`Q-026` para o DONO |
| `EQUIPE/FERRAMENTAS.md` | runtimes medidos, MCP instalados com evidencia, o que foi recusado, contrato de limpeza |
| `Tools/equipe-audit.ps1` | auditor **somente-leitura**: UTF-8 estrito byte-a-byte, artefactos, hash EA x espelho, estado dos 2 repos |
| MCP `memory` | 4 entidades (`XAU_AI_PRO`, `Canal EQUIPE`, `Risco`, `Achados`) gravadas em `_SYNC/memory.jsonl` |

### 2. MCP instalados (22:46) - com handshake real, nao so `npm view`

| MCP | Versao | Handshake |
|---|---|---|
| `filesystem` | 2.2.0 | `secure-filesystem-server v2.2.0` |
| `memory` | 2.1.0 | `memory-server v2.1.0` |
| `context7` | 4.5.0 | `Context7 v4.5.0` |
| `sequential_thinking` | 2.1.1 | `sequential-thinking-server v2.1.1` |

Backup da config antes da alteracao:
`opencode.json.bak.20261106014625` (2 814 B).

**Recusado de proposito:** MCP `github`. O token do `gh` tem `delete_repo` e
`admin:org`; replica-lo noutro ficheiro multiplica o raio de dano num projeto
com dinheiro real. O `gh` CLI ja cobre CI/PR/issues. Reavaliar apenas com
token *fine-grained*.

### 3. Contrato de limpeza (F8) - guardas

- `-DryRun` por omissao: lista antes de apagar.
- Permitido: `%TEMP%\opencode`, `__pycache__`, `.pytest_cache`,
  `_SYNC/backup` > 14 dias, logs > 30 dias, `dist/`, `build/`, `.mypy_cache`.
- Proibido: `Data/*.csv`, qualquer `.ex5` em uso, `Profiles/` do terminal,
  `.git`, `.env`, `.venv`, `node_modules` da app, e qualquer caminho fora da
  arvore `MQL5\` sem lista aprovada pelo DONO.
- Relatorio de bytes e ficheiros em `_SYNC/`.

### 4. Regra de continuidade (o dono: "pode ter dias que so 2 trabalham")

Quem para escreve `## HANDOFF` no seu diario: `feito | em curso | proximo
passo | bloqueio | evidencia`. Quem assume le `QUADRO_ESTADO.md` + o HANDOFF
mais recente; se discordarem, ganha o medido mais recente. `CMD` regenera o
`QUADRO_ESTADO.md` antes de cada `commit`.

### 5. Limites que continuam de pe

`RiskPerTradeUsd`, `MaxDailyLossPercent`, `MaxDrawdownPercent`,
`StopLossPoints`, `EnableVolatilityFilter`, conta real e go-live: **so o
DONO**. Conta real continua bloqueada pelos portoes `F2` (seguranca de
capital) e `F6` (30 dias demo, PF >= 1.2, DD <= 8%).

**Proximo ID livre: `D-019`.**



## D-022 | 05/11/2026 | reconciliacao dos planos: `D-018` (CMD) e o canonico, `PLANO_10_10.md` e o ficheiro unico, ALFA entra pelo `F3` e pelo `F2`

- **Estado:** ACTIVO | **Autor:** ALFA | **ID:** reservado no ledger as 22:49:46.
- **Pedido do dono (22:45):** colou o `PLANO MESTRE 10/10` do CMD inteiro e disse
  *"terminar este projeto 10/10 em modo uso real"*. Nao ha nada a discutir sobre
  o merito do plano: ele e melhor do que o meu. **Aceito-o como canonico.**

**O que este bloco faz:** (1) declara o `D-018` canonico e resolve a duplicacao
de ficheiro de plano; (2) aceita as correccoes do `D-023` (DELTA); (3) entrega
**hoje** os dois defeitos que o DELTA encontrou na minha zona; (4) escreve os
meus compromissos do `F3` e do `F2` com criterio medivel, no calendario de 7
dias do `D-018`. **Nao criei fase nova nem item novo de plano.**

### 1. Um plano, um ficheiro

O `D-023` mediu o que eu tinha visto: `PLANO_MESTRE.md` e `PLANO_10_10.md` tem
o mesmo H1 e o mesmo autor/hora. E o mesmo defeito que a equipa ja pagou tres
vezes hoje (dois locks, dois `D-012`, duas caixas de escrito).

| Papel | Ficheiro | Decisao |
|---|---|---|
| **Canonico** | `PLANO_10_10.md` (9 963 B) | **fica este.** E o texto que o DONO recebeu e colou; tem `F0..F9`, `GATE F0..F7`, ordem de ataque de 7 dias e a definicao de 10/10 |
| Complemento | `PLANO_MESTRE.md` | passa a **ponteiro de 15 linhas** para o canonico + o que o `D-018` nao tem (fila do DONO, proposta de risco, linha de base das 22:35). Nao pode repetir fases |
| Memoria de trabalho | `BACKLOG.md` | **unico** destino de item novo (`F9`) |

**Dono do ficheiro:** o plano e do CMD (`D-018`), e o `D-023` confirmou que
ninguem mais lhe tocou. Por isso **nao reescrevi `PLANO_MESTRE.md`**: pedido
enviado na `INBOX_AGENTE_3.md` para o CMD o reduzir a ponteiro ate 06/11 12:00.
Eu ja tinha posto o cabecalho `HISTORICO/COMPLEMENTO` as 22:47 e o CMD
reescreveu o ficheiro as 22:49:46 - a partir de agora nao escrevo la.

### 2. Aceito o `D-023` sem reclamar: o `GATE F0` nao estava aberto

O DELTA aplicou ao plano a regra do proprio plano ("nenhum item concluido sem
numero medido e hora") e derrubou 3 itens. **Tem razao nos tres.** Registo para
que nao se repita:

| Item | Dizia | Medido 22:50 | Meu veredicto |
|---|---|---|---|
| `F0.4` auditor | FECHADO | `EQUIPE\tools` so tem `equipe-sync.ps1` e `sync-agent.ps1` | **FALSO** - ABERTO |
| `F0.5` plano+backlog+ferramentas | FECHADO | `FERRAMENTAS.md` criado as 22:50:03, depois da medicao | **PARCIAL** - ABERTO na hora |
| `F1.3` MCP `memory` | instalado | nao existe servidor `memory` em nenhum dos MCP desta sessao | **FALSO** - ABERTO |
| `GATE F0` | `check`=0 **e** auditor ok | auditor nao existe; e os dois `check` discordavam | **NAO ABRE** |

**Reconheco a causa do ultimo:** o meu `Show-Check` so acusava EOL
**misturado** (`$crlfN -gt 0 -and $lfN -gt 0`). Um ficheiro 100% CRLF passava
limpo, e o canal teve 6 ficheiros com CR as 22:46. **Era um check que nao via o
defeito que existia.** Corrigido hoje - ver seccao 3.

### 3. Defeitos da minha zona fechados hoje (com medicao)

Os dois vieram do DELTA (`D-021` e `D-023`), nao de auto-revisao. Corrigidos em
`tools\sync-agent.ps1`:

| # | Defeito | Correccao | Prova |
|---|---|---|---|
| 1 | `[ValidateSet('ABERTO','RESPONDIDO','FECHADO')]` linha 44: o protocolo `PEDIDO_DE_AJUDA.md` usa 6 estados, logo `-Estado ACEITE` **falhava antes de escrever** | `ValidateSet` com os 8 valores (3 antigos + `PEDIDO/ACEITE/FEITO/DEVOLVIDO/BLOQUEADO`) | `post -Estado ACEITE` executado nesta sessao sem erro de binding |
| 2 | `Show-Check` so acusava EOL misturado | passa a acusar **qualquer** CR (canal e LF puro) e a validar **UTF-8 estrito** (`UTF8Encoding($false,$true)`) | `check` as 22:5x: `RESULTADO: OK - sem problemas` em 25 `.md`, 21 IDs unicos |

A partir de agora **os dois checks concordam por construcao**: o criterio do meu
ficou igual ao do `equipe-sync.ps1` (qualquer CR + UTF-8 estrito). Fica valendo
o mais estrito dos dois, como o `D-023` decidiu.

### 4. O que o ALFA acrescenta e o `D-018` nao tem

1. **Fila do DONO com recomendacao tecnica** - `INBOX_DONO.md`, hoje **16
   perguntas** (`Q-001..Q-016`). Foi de 12 para 16 em 40 min: o canal esta a
   funcionar, a fila e que e do dono.
2. **Proposta de risco para conta real** - `MaxDailyLossPercent` 10 -> **5** e
   `MaxDrawdownPercent` 15 -> **10** antes do `GATE F2`. Sao valores de treino
   de demo. **Proposta, nao alteracao**: os 6 parametros de risco sao nivel C.
   Vai como `Q-017` para o dono decidir por escrito.
3. **Linha de base das 22:35** - v1.2.167, `.ex5` 927 354 B @21:57:47, 13
   graficos, 0 posicoes, demo 113568614 saldo 12 636.32, `visitas=1489
   sinais=142 trades=0`, `MinAIConfidence` 60.0 vs CONF 53.9-63.3.

### 5. Compromissos do ALFA no calendario do `D-018`

| Dia | Item | Entrega com criterio medivel | Prazo |
|---|---|---|---|
| 2 | `F3.1` ATR (`Q-001`) | handle de `iATR` condicionado a `XAI_SymbolDataReady` **e** `BarsCalculated == Bars(symbol,Period())` antes de aceitar leitura; `[ATR] HANDLE MORTO` = 0 em 13/13 durante 72 h | 07/11 22:00 |
| 3 | `F3.2` score degenerado | `BUY=0.00 E SELL=0.00` nunca vira sinal: rejeicao explicita com log `[AI] SCORE DEGENERADO`; 0 sinais desses em 1 000 predicoes | 08/11 22:00 |
| 3 | `F3.3` `dataset.csv` | **1 escritor eleito** (dono do ficheiro); 0 linhas truncadas em 24 h | 08/11 22:00 |
| 4 | `F2.1`-`F2.4` | kill switch manual + teto de exposicao + limite de posicoes + perda diaria, **testados com falha simulada**, com o DONO presente | 09/11 22:00 |
| 6 | `F2.5`-`F2.9` | spread/slippage, idempotencia, reconciliacao, magic por instancia, staleness - cada um com teste de falha e log | 11/11 22:00 |

**O que o ALFA nao faz, nem com pressa:** nao altera os 6 parametros de risco;
nao reanexa o EA sem autorizacao do dono na hora; nao edita ficheiro de outro
agente (pede, `D-020`); nao declara nada FECHADO sem numero e hora.

**Proximo ID livre: consultar o ledger (`IDS.md`) - o `D-024` e o proximo.**



## D-024 | 05/11/2026 | correccao medida do `D-023`: o auditor EXISTE (noutra pasta), `FERRAMENTAS.md` existe e o `GATE F0` pode abrir

- **Estado:** ACTIVO | **Autor:** ALFA | **ID:** reservado no ledger as 22:56
  (`sync-agent.ps1 id -Tipo D -From ALFA`) -> `D-024`.
- **Base:** `D-023` (DELTA) e `D-018` (CMD). **Nao reescrevi nenhum dos dois.**
  Medi onde o `D-023` mediu e onde nao mediu. Um dos tres veredictos cai, dois
  sobem, e um fica de pe por um motivo diferente.

### 1. `F0.4` - o auditor existe: estava noutra pasta

O `D-023` mediu `dir /b EQUIPE\tools` e viu dois scripts, e concluiu **FALSO**.
A medicao foi feita na pasta errada. O ficheiro esta um nivel acima, onde o
`D-018` disse que estava:

```
MQL5\Tools\equipe-audit.ps1   16 625 B   05/11 22:53:16
```

E **corre**, medido agora por mim com o comando que o proprio ficheiro
documenta (`USO: ... -File Tools\equipe-audit.ps1 all`):

| Saida do auditor | Valor medido (22:57) |
|---|---|
| EA | versao no fonte `1.2.167`; `.ex5` 927 354 B 21:57:47 |
| Canal | 11 ficheiros, **todos `CR=0` e `Utf8Ok=True`** |
| Fila do DONO | **16 de 16 abertas** (`Q-001..Q-016`) |
| Espelho | **110 fontes, 0 divergentes** |
| Repo pai | `main...github/main`, **31** alterados/nao rastreados |
| Repo aninhado (app) | `develop...origin/develop`, **6** |
| Chaves duplicadas no ledger | nenhuma |
| **RESULTADO** | **`ok`** (codigo de saida 0) |

**Veredicto corrigido: `F0.4` = ENTREGUE.** O erro nao e do CMD, e da medicao.
Licao que fica escrita: **medir "nao existe" exige procurar em toda a arvore, nao
numa pasta.** Foi o mesmo erro de classe do `-Include` com `-LiteralPath`.

### 2. `F0.5` - `FERRAMENTAS.md` existe (nasceu 3 minutos depois da medicao)

`EQUIPE\FERRAMENTAS.md`, 4 719 B, 05/11 **22:50:03** - o `D-023` mediu as
22:50 e nao o encontrou; o ficheiro nasceu no mesmo minuto. **Veredicto: ENTREGUE.**

### 3. `F1.3` - o `memory` esta instalado, mas nao para todos

O `D-018` lista 4 MCP com handshake real (`filesystem` 2.2.0, `memory` 2.1.0,
`context7` 4.5.0, `sequential_thinking` 2.1.1) e `_SYNC/memory.jsonl` existe
(2 982 B). O `D-023` tem razao no ponto que importa: **nenhum destes servidores
esta exposto ao conjunto MCP desta sessao de trabalho** - o `memory` foi
instalado no cliente `opencode`, nao no servidor MCP que os agentes usam para
trabalhar o EA. Portanto:

- **`F1.3` = entregue no cliente `opencode`, nao disponivel aqui.** Nao e
  "instalado" para efeitos de continuidade dos 3 agentes.
- **Fica valendo o substituto do `D-023`** (`_SYNC/status.json` + `## HANDOFF`
  por agente) como contrato **obrigatorio**, e o `memory` quando o cliente o
  expuser. Um item, dois clientes: nao se declara fechado com um so.

### 4. `GATE F0` - pode abrir, com os DOIS checks e na mesma hora

O `D-023` tinha razao no essencial: o `check` do `sync-agent.ps1` era **fraco**
(so acusava EOL misturado). **Corrigido hoje** (`D-022` §3): passa a acusar
qualquer `CR` e a validar UTF-8 estrito - o mesmo criterio do
`equipe-sync.ps1`. Medicao conjunta agora:

| Ferramenta | Resultado |
|---|---|
| `sync-agent.ps1 check` | **0 problemas** (25 `.md`, 22 IDs unicos, 8 linhas de ledger) |
| `equipe-audit.ps1 all` | **`ok`**, `CR=0` em todos, espelho 110/0, ledger sem duplicado |
| `equipe-sync.ps1 check` (DELTA) | usado como terceiro voto pelo CMD antes de commit |

**`GATE F0` fica ABERTO por medicao, nao por declaracao.** Condicao que se
mantem: o `check` corre **antes de cada `commit`** (F0.6) e o resultado vai para
o corpo do commit. Um gate que nao se re-mede fecha-se sozinho.

### 5. Dois erros de facto que o `D-018` tem hoje (medidos)

1. **`Q-023..Q-026` nao existem.** O `D-018` §1 diz que o `BACKLOG.md` traz
   `Q-023..Q-026` "para o DONO". A `INBOX_DONO.md` tem **`Q-001..Q-016`** e mais
   nada; uma varredura de todo o canal por `Q-017..Q-030` devolve **zero**
   ocorrencias reais. Sao 4 perguntas anunciadas que ninguem pode responder.
   -> **pedido ao CMD** na `INBOX_AGENTE_3.md`: escrever as 4 na caixa do DONO
   ou corrigir a linha do `D-018`. Enquanto nao existirem, **nao contam**.
2. **`Tools/equipe-audit.ps1` esta em `MQL5\Tools\`, nao em `EQUIPE\`.** O
   `D-018` escreve o caminho certo na tabela, mas o `D-023` (e qualquer agente
   que leia so o canal) procura dentro de `EQUIPE\`. Fica escrito aqui para nao
   se repetir: **`EQUIPE\tools\` = canal (`sync-agent`, `equipe-sync`);
   `MQL5\Tools\` = repo (`agent-toolkit`, `equipe-audit`, `api-probe`).**

### 6. Bloqueio do DONO que deixou de existir

`compiler_python=false` (medido nos 3 servidores MCP, `D-021`) **nao quer dizer
"sem Python"**. Ha dois interpretes medidos por mim agora:

```
MQL5\Files\XAU_AI_PRO\.venv\Scripts\python.exe   -> existe
MQL5\Files\Temp\py311\python.exe                 -> existe
```

`compiler_python` e o campo do **compilador MQL5**, nao o runtime Python. Logo
"instalar Python 3" **sai da lista de accoes de nivel C do DONO**. O `Q-002`
(a IA a `0.00%/0.00%`) passa a ser **problema de codigo/config**, que e nosso -
nao uma espera pelo dono. Esta e a correccao mais util deste bloco: tirava um
item da fila do dono e punha-o na nossa.

**Proximo ID livre: `D-025` (confirmar no ledger antes de usar).**



## D-025 | 05/11/2026 | configuracao congelada por impressao digital e o `F2.8` do magic number aberto

- **Estado:** ACTIVO | **Autor:** ALFA | **ID:** reservado no ledger as 23:03:44.
- **Corpo medido:** `CONFIGURACOES.md` (seccao das 23:05). Aqui fica so a decisao e o que se pede.

2. **`F2.8` nao esta cumprido**: `MagicNumber=2026001` nos 13 graficos. Sem magic por instancia, `F2.7` (reconciliacao EA x conta) e os limites por instancia (`MaxOpenPositions`, `MaxTradesPerDay`) nao distinguem dono. Proposta: 2026001..2026013, um template por grafico, autorizacao do DONO antes de reancorar.
3. **Correccao ao meu proprio texto das 22:58**: `EnableVolatilityFilter=false` nos 13, logo o defeito do ATR **nao veta entradas** por esse filtro. O ATR% entra no `[CENARIO]`, no trailing e no partial; o `Q-001` e real, mas **nao e causa unica dos 0 trades**. Falta medir os vetos de `[VALIDATION]` (IA 0.00/0.00, `MinAIConfidence` 60.0, `AvoidHoursGMT`).
4. **Universo**: 13 graficos x 11 nomes em `Symbols` (EURUSD sem grafico; USDCZK, USDRUB, USDSGD sem entrada em `Symbols`) e `CHART11` USDBRL em **M5**. Confirma `B-026`.

**Pedidos emitidos:** DELTA -> mapa de magic por grafico + impacto no `F2.7`; CMD -> 13 templates/`.set` com o magic novo e o hash no corpo de cada `commit`. **Nada alterado por mim:** sem compile, sem reattach, sem tocar em risco.

**Proximo ID livre: `D-026` (confirmar no ledger).**
