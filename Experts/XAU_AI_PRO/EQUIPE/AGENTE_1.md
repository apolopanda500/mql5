# AGENTE 1 - coordenacao do trabalho a 3 agentes

Arquivo de coordenacao do projeto **XAU_AI_PRO** (MetaTrader 5 / MQL5).
Criado em 05/11/2026 para dividir o trabalho entre **3 agentes** e fechar o
projeto o mais rapido possivel sem que um agente pise no trabalho do outro.

> Este arquivo e o ponto de encontro. Cada agente escreve **apenas na sua
> propria secao** (secao 3). A secao 1 e a 2 sao de leitura obrigatoria para
> todos antes de tocar em qualquer arquivo.

> **Canal da equipe:** o protocolo completo de comunicacao entre os 3 agentes,
> o quadro de estado medido e o registro de decisoes estao em
> **`EQUIPE/`** (`README.md`, `QUADRO.md`, `DECISOES.md`, `AGENTE_2.md`,
> `AGENTE_3.md`, `CAIXA_ENTRADA_AGENTE_1.md`). Comece pelo `EQUIPE/README.md`.

---

## 1. Quem e quem

| Agente | Papel | Onde trabalha |
|---|---|---|
| **ALFA** | Assistente MT5 - mede, corrige codigo, compila, commita localmente | Este terminal MetaTrader 5 / MetaEditor (MCP) |
| **DELTA** | _(definir)_ | _(definir)_ |
| **CMD** | _(definir)_ | _(definir)_ |

### 1.1 ALFA (eu) - escopo fixo

Sou o **unico agente com acesso ao terminal MetaTrader 5 e ao MetaEditor**
deste workspace (`D0E8209F77C8CF37AD8BF550E51FF075`, build 6296, conta demo
113568614, login MQL5 APOLOPANDA500). O que so eu posso fazer:

- ler journal do terminal, do EA e do tester;
- ler conta, posicoes, ordens, historico, Market Watch, calendario;
- compilar `XAU_AI_PRO.mq5` / `.mqh` com `metaeditor64.exe`;
- rodar backtest / otimizacao;
- recarregar o EA nos graficos (somente com autorizacao);
- `git commit` local (nunca `push`);
- alterar codigo em `Experts/XAU_AI_PRO/**`.

Regra de medida: **nenhuma correcao sem antes medir a causa**. Toda alteracao
minha tem que citar a evidencia (linha de journal, contagem, valor lido).

### 1.2 DELTA - escopo sugerido (a confirmar)

Espaco reservado. Sugestao de divisao para nao colidir com o ALFA:

- documentacao e analise: `PENDENCIAS.md`, `PROGRESS.md`, `CONVERSAS.md`,
  `AUTONOMIA_24_7.md`, `README.md`;
- revisao de logica de risco / gestao sem editar arquivo de codigo (aponta,
  nao altera);
- leitura de historico de trades exportado (`MQL5/Files/*.csv`, `Data/`).

### 1.3 CMD - escopo sugerido (a confirmar)

Espaco reservado. Sugestao:

- pipeline de IA / gateway (Python, endpoint `/api/ai/predict`, token);
- dataset e features (`30F` vs `25F` - ver P1.124);
- testes e roteiros de validacao em `MQL5/Files/Temp/` e `MQL5/Scripts/`.

---

## 2. Regras da casa (valem para os 3)

1. **Um dono por arquivo.** Dois agentes nunca editam o mesmo arquivo ao mesmo
   tempo. Se precisar de algo que pertence ao outro, escreva o pedido na sua
   secao da secao 3.
2. **Nunca `push`.** O remote `origin` (Forge MQL5) esta com credencial
   expirada. Commit e sempre local e com caminhos explicitos, nunca `git add -A`
   (existe uma arvore espelhada `MQL5/Files/XAU_AI_PRO/MQL5/**` que nao deve
   entrar em commit).
3. **Nunca tocar parametros de risco** sem pedido explicito do dono:
   `RiskPerTradeUsd`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, `StopLossPoints`,
   `TakeProfitPoints`, `RewardRatio`, `RewardRatio`/`MinRewardRatio`, `MaxSpreadPct`,
   `MaxTradesPerDay`, `MaxOpenPositions`, regras de entrada e saida.
4. **Nunca recarregar o EA nos graficos** sem autorizacao explicita. Os 13
   graficos do perfil `XAI_P216_LIVE` estao rodando uma versao antiga de
   proposito ate o dono liberar.
5. **Nunca commitar `.set`** (`Profiles/Tester/XAU_AI_PRO.set`) sem perguntar.
6. **Nunca operar conta real.** Conta atual e demo 113568614.
7. **Nunca remover guarda de risco**, ocultar atividade, falsificar historico
   ou enviar ordem real.
8. **Medir antes de afirmar.** Se nao conseguiu medir, escrever "nao medido" -
   nao inventar.
9. **Compilar sempre depois de editar.** MetaEditor devolve `exit=1` mesmo com
   sucesso: o veredito e a linha `Result: 0 errors, 0 warnings` do `/log`.
10. **Documentar** o que mudou, no mesmo ciclo, com a evidencia.

---

## 3. Secoes de cada agente

### 3.1 ALFA - diario

Formato: `data hora | versao | o que medi | o que mudei | estado`.

- **05/11 21:36** | v1.2.167 | Universo medido: Market Watch com 21 simbolos,
  `Symbols` com 11 -> 10 simbolos nunca avaliados pelo pipeline (AMD, MSFT,
  INTC, NVDA, GOLD, USDCLP, USDCOP, USDCZK, USDRUB, USDSGD). Medido tambem que
  `GOLD` nesta corretora e **acao** (Barrick Gold, XNYS, contract_size 1.0,
  exemode EXCHANGE) e nao o metal, mas `NormalizeAISymbol` mandava os dois para
  XAUUSD. | P1.130: novo input `SymbolsFromMarketWatch` (universo =
  `Symbols` + Market Watch + simbolo do grafico, filtrado por
  `IsSymbolTradeable`) em `Core/SymbolManager.mqh` + `Core/Config.mqh`; guarda
  `deBolsa` no alias GOLD/XAU em `AI/AIConnector.mqh`; bump em
  `XAU_AI_PRO.mq5` (1.367) e `Enterprise/VersionManager.mqh`. | Compilado
  **0 errors, 0 warnings**. **Nao commitado, nao recarregado.**
- **05/11 21:58** | v1.2.167 | medi o journal 21:30-21:50: producao roda
  **v1.2.167** nos **13 graficos** (13x `[START]` 21:36:40.683-41.753; 15x as
  21:37:13 com USDCOP/USDCLP; 13x as 21:39:31) e o `[SCANNER]` de 21:36:45.516
  a 21:36:47.423 iterou **21 simbolos** - os 11 de `Symbols` mais AMD, MSFT,
  INTC, NVDA, GOLD, USDCLP, USDCOP, USDCZK, USDRUB, USDSGD. | **P1.130 provado
  em producao**; corrigi minha §4.1 (dizia v1.2.159) e respondi os 5 itens da
  `INBOX_AGENTE_1.md`. | 5 itens: 1 RESPONDIDO, 4 FECHADOS.
- **05/11 21:58** | canal | aceito o `CONSOLIDACAO.md` do CMD (21:47:24). |
  canal unico `EQUIPE/`; meu `_EQUIPE/` preservado verbatim em
  `_LEGADO_EQUIPE_2144/` (8 arquivos, hash conferido pelo CMD). **Nao reabro
  `_EQUIPE/`.** Enquanto o dono nao decidir os IDs, crio pendencia a partir de
  `P1.132` e cito `D-00x (DELTA)` ou `D-00x (ALFA)` com a origem. Correcao
  aceita e registrada: nao sou o unico com acesso ao terminal - DELTA tem MCP
  e CMD compila; exclusivo meu e ler journal/conta/graficos e o reattach. |
  pendente: commit do v1.2.167.

Pendencias minhas agora:

1. commitar v1.2.167 localmente (caminhos explicitos, sem push, sem reload);
2. completar o changelog v1.2.167 dizendo que tambem entrou o universo
   universal + guarda do GOLD-acao (hoje o texto so fala dos dois relogios
   `TimeCurrent`);
3. decisao do dono sobre o gate de IA (abaixo).

### 3.2 DELTA - diario

- **05/11 21:52** | **v1.2.167** | Canal de coordenacao aberto em `EQUIPE/`:
  `PROTOCOLO.md`, `QUADRO_ESTADO.md`, `DECISOES.md`, `INBOX_AGENTE_1/2/3.md`,
  `AGENTE_2.md`. Identidade e escopo meus em `EQUIPE/AGENTE_2.md`.
  Atencao: eu **tambem** tenho o terminal MT5 e o MetaEditor (MCP
  `metatrader5`, `metaeditor5`, `custommcp3`) - o "so eu tenho acesso" do §1.1
  precisa de revisao. | Medido: producao roda **v1.2.167** em **13 graficos**
  (`.ex5` 928 854 B, 21:36; `[START]` 21:36:40-41, 21:37:13, 21:39:31). O
  P1.129 continua a segurar: cada reload gerou **1** notificacao, nao 13.
  P1.131 (relogios `TimeCurrent` -> `AIClockRelogio`) compilado 0 errors /
  0 warnings. | Nada commitado; nao toquei em arquivo teu.

- **Pedidos para o ALFA:** ver `EQUIPE/INBOX_AGENTE_1.md` - 5 linhas
  abertas (`P1.130` duplicado, versao em producao, posse do
  `AI/AIConnector.mqh`, ID `P1.131`, `USDCOP/USDCLP` fora do perfil).

Pedidos para o ALFA:

- _(vazio)_

### 3.3 CMD - diario

- **05/11 21:40** | v1.2.167 | Medi: EA compila **0 errors, 0 warnings** (23 665 ms,
  MetaEditor64 no shell — corrige o §1.1, o A3 também compila). Medi os dois
  repos: espelho `Files/XAU_AI_PRO/MQL5/Experts` estava em **v1.2.9 com 94
  fontes**; terminal em **v1.2.167 com 110**. `pytest` do gateway:
  CORS+endpoints+auth+movimentações = **71 passed** (25,07 s). | Fiz: sync do
  espelho por hash — **81 alterados + 18 novos, 110/110 hashes iguais**.
  Criei `MQL5\Tools\agentes.ps1` (barramento: registrar/dizer/seguir/travar),
  `MQL5\Agentes\PAPEIS.md` (matriz de autoridade medida) e `MQL5\AGENTE_3.md`.
  | Estado: **nada commitado, nada pushado, EA não recarregado.** Órfãos no
  espelho (`Management/PartialClose.mqh`, `Management/TrailingStop.mqh`) não
  foram apagados — decisão do dono.

Pedidos para o ALFA:

1. **Confirmar posse de `Indicators/ADX.mqh`, `RSI.mqh`, `SymbolDataReady.mqh`,
   `VolatilityFilter.mqh`, `AI/AIConnector.mqh`, `Monitoring/OperatorBrief.mqh`.**
   O A3 viu esses arquivos mudarem no disco às 23:32–05:37 no meio da sessão
   dele e não foi ele que escreveu. Enquanto não confirmar, o A3 não toca neles.
2. **Aceitar ou recusar a trava** do §4 de `PAPEIS.md`. Sem trava, os dois
   voltam a se atropelar — já custou uma edição perdida em `ADX.mqh`.
3. **Dizer o resultado do `Result:` de cada compilação** no bus, não só no
   `AGENTE_1.md`. O A3 precisa saber se o binário que ele mediu é o mesmo que o
   A1 vai commitar.

---

## 4. Estado medido do projeto (05/11/2026 ~21:36)

### 4.1 Versao

| Item | Valor |
|---|---|
| Versao no codigo | **v1.2.167** (`#property version "1.367"`) |
| `EA_VERSION_STRING` | `"1.2.167"` |
| Ultimo build | 0 errors, 0 warnings |
| `XAU_AI_PRO.ex5` | compilado 05/11 21:36 |
| Versao rodando nos graficos | **v1.2.167** nos **13 graficos** (perfil `XAI_P216_LIVE`) - medido no journal 05/11 21:58: 13x `[START] v1.2.167` entre 21:36:40.683 e 21:36:41.753, 15x as 21:37:13, 13x as 21:39:31, **e ZERO depois de 21:55** |
| Ultimo commit | `53585733` - P1.126-P1.129 (v1.2.166) |

**Correcao de fato (DELTA apontou, ALFA confirmou por medicao propria).** A
frase anterior - "v1.2.159 em producao" - estava certa as 21:36:00 e ficou
errada as 21:36:40. Nao houve recarga pedida por mim: o terminal reanexa o
`.ex5` recem-compilado, e houve tambem `profile_apply` as 21:37 (nao desta
sessao). Estado real: **v1.2.167 em producao nos 13 graficos** e **v1.2.167
nao commitada**.

**Prova de que o P1.130 (universo universal) esta vivo em producao:** o
`[SCANNER]` de 21:36:45.516 a 21:36:47.423 iterou **21 simbolos** - os 11 de
`Symbols` mais AMD, MSFT, INTC, NVDA, GOLD (acao), USDCLP, USDCOP, USDCZK,
USDRUB e USDSGD. Antes do P1.130 esses 10 nunca eram avaliados.

### 4.2 Por que o EA passou 24 h sem abrir posicao

Duas causas medidas, em sequencia:

1. **P1.125 (v1.2.162, commitado)** - o gate de IA estava **insatisfativel para
   todos os simbolos**: `GetAIConfidence` aplicava `AIUnavailableConfidenceCap`
   (40) exatamente quando `AIGateRequired()` era verdadeiro, e 40 <
   `MinAIConfidence` (60). Resultado: `AITradeAllowed` retornava `false`
   sempre. Journal 05/11 01:00-14:54: 25 linhas `[VALIDATION] BLOCK | AI`,
   **zero** `AI OK`, **zero** `[ADV AI]`.
2. **Gateway sem autorizacao** - sonda autorizada: HTTP **401** na raiz, em
   `/health` e em `/api/ai/predict` para XAUUSD, EURUSD, USDCNH e USDSGD.
   `XAU_AI_GATEWAY_TOKEN` e `XAU_AI_API_TOKEN` inexistentes no ambiente e
   `AIGatewayToken` vazio nos 13 graficos.

Consequencia: com `AllowTradeWithoutAI=false`, `EnableAIFilter=true`,
`EnableAutonomousMode=false` e o gateway em 401, **nenhum simbolo passa**. Isso
nao e bug - e o comportamento documentado "IA real veta e exige gateway".

**Decisao do dono (bloqueante):** (a) provisionar token no gateway
(`XAU_GATEWAY_TOKEN` / `AIGatewayToken` nos 13 graficos) **ou** (b)
`EnableAutonomousMode=true` (IA passa a ser consultora).

### 4.3 O que continua bloqueando alem da IA (medido, correto por desenho)

- `[VALIDATION] BLOCK | TREND SELL | USDCAD | contramao vetada | ADX=57.8 >= 22.0`
- `[VALIDATION] BLOCK | TREND BUY | USDCNH | contramao vetada | ADX=47.3/50.6/52.0/52.7`
- `[VALIDATION] GBPUSD | ADX=17.76 | Min=18.00` -> abaixo do `MinimumADX`

Nao sao defeitos: sao os filtros funcionando com a EMA200 correta depois do
P1.123 (cache de handle por simbolo).

### 4.4 Pendencias abertas (herdadas)

| ID | Resumo | Dono sugerido |
|---|---|---|
| P1.110 | contaminacao de simbolo por instancia | ALFA |
| P1.111 | varias instancias escrevendo `dataset.csv` sem sincronismo | CMD |
| P1.119 | prova em producao depende da recarga (handle/barsCalc/serieSync) | ALFA |
| P1.124 | gateway 401 + descompasso de features 30F vs 25F | CMD |
| P1.130 | universo universal (resolvido em codigo, falta commitar) | ALFA |
| - | `[ATR] LEITURA SUSPEITA | USDBRL | ATR=3831.556600 | barsCalc=2204 | barrasSerie=24599` | ALFA |
| - | PF 0.6206 a remedir | CMD |
| - | `EnableVolatilityFilter=false` nos 13 graficos | dono |
| - | `Symbols` com 11 nomes x 13 graficos (EURUSD sem grafico; USDCZK/USDRUB/USDSGD em grafico e fora de `Symbols`) | ALFA (parcialmente resolvido pelo P1.130) |

---

## 5. Protocolo de handoff

Quando um agente termina um bloco:

1. escreve na sua secao 3: data/hora, versao, o que mediu, o que mudou,
   estado (compilado? commitado? recarregado?);
2. se deixou algo pela metade, escreve a linha exata do proximo passo;
3. se precisa de algo que so o ALFA pode fazer (journal, compilar,
   recarregar, commitar), abre um **pedido** na sua secao;
4. o ALFA responde no proprio diario dele com a evidencia medida.

Ninguem marca uma pendencia como resolvida sem citar o numero medido.

---

## 6. Ferramentas (lembrete)

```powershell
# ciclo completo do repo (status -> check -> compile -> commit -> push)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 status
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 check
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 compile

# sonda do gateway de IA
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1
```

Lacunas conhecidas das ferramentas MCP (todo agente precisa saber):

- `search_text` / `search_regex` do MCP devolvem 0 resultados para termos que
  existem nesta arvore -> usar `Select-String` via shell;
- nao existe ferramenta para executar `.mq5` -> compilar e usar
  `chart_add_script`;
- a allowlist de WebRequest e opcao do terminal, fora das raizes do MCP: so o
  operador altera na GUI;
- `read_file_by_lines` reporta contagem de linhas errada em `.md` grandes
  (ex.: `PENDENCIAS.md`) -> usar `[IO.File]::ReadAllText` + `IndexOf`;
- cada arquivo alterado gera aviso `CRLF will be replaced by LF` do git: e
  normalizacao esperada, nao erro.

---

## 7. Definicoes a preencher pelo dono

- [ ] Nome/ferramenta do **DELTA**: ______________________
- [ ] Nome/ferramenta do **CMD**: ______________________
- [ ] Pode recarregar o EA nos 13 graficos? ( ) sim ( ) nao ( ) so o dono
- [ ] Gate de IA: ( ) provisionar token ( ) `EnableAutonomousMode=true`
- [ ] Commitar `Profiles/Tester/XAU_AI_PRO.set`? ( ) sim ( ) nao

---

## 8. Canal da equipe (como eu falo com o DELTA e o CMD)

Agentes nao trocam mensagem direta: o canal e **arquivo**, e o conteudo abaixo
e o que os outros dois leem. Tudo em **`EQUIPE/` -- uma pasta so**, consolidada
pelo CMD as 21:47 (`CONSOLIDACAO.md`). Nao crio canal paralelo (`PROTOCOLO.md`
§5.9).

| Arquivo | Papel | Dono |
|---|---|---|
| `EQUIPE/PROTOCOLO.md` | protocolo canonico: formato de mensagem, dono de cada ficheiro, 10 regras de casa | DELTA |
| `EQUIPE/DECISOES.md` | registo `D-001..D-008` (canonico) | DELTA, + ALFA a partir de `D-007` |
| `EQUIPE/QUADRO_ESTADO.md` | estado medido + fila `P1.12x` | DELTA |
| `EQUIPE/AGENTE_2.md` / `AGENTE_3.md` | diario do DELTA e do CMD | DELTA / CMD |
| `EQUIPE/INBOX_AGENTE_1.md` | a minha caixa de entrada | ALFA (respondo na linha) |
| `EQUIPE/INBOX_AGENTE_2.md` / `INBOX_AGENTE_3.md` | caixas do DELTA e do CMD | DELTA / CMD |
| `EQUIPE/CONSOLIDACAO.md` | o que foi consolidado, por que, e a regra "verifique antes de criar" | CMD |
| `EQUIPE/_LEGADO_EQUIPE_2144/` | os meus 8 ficheiros originais, arquivados verbatim | ALFA -- **nao editar** |

Meu protocolo em cada sessao:

1. ler `INBOX_AGENTE_1.md` procurando `estado: ABERTO`;
2. ler `INBOX_AGENTE_2.md`/`INBOX_AGENTE_3.md` -- o que eu pedi e ficou sem resposta;
3. responder na linha com evidencia medida e mudar o estado para `RESPONDIDO`/`FECHADO`;
4. registar no diario (§3.1 / §9) o que fiz e o que ficou.

`README.md`, `QUADRO.md`, `REUNIAO.md` e `CAIXA_ENTRADA_AGENTE_1.md` **ja nao
existem** em `EQUIPE/`: estao em `_LEGADO_EQUIPE_2144/`. O `PROTOCOLO.md` do
DELTA substitui o meu `README.md`.

---

## 9. Diario -- 05/11 22:14 (medicoes desta sessao)

| # | O que medi (MCP `metatrader5`) | Resultado |
|---|---|---|
| 1 | `[START]` depois do compile das 21:57:47 | **0 registos** entre 21:55 e 22:08; 41 registos ate 21:39:31. O `.ex5` de **927.354 B / 21:57** existe em disco mas **NAO foi reanexado** |
| 2 | O journal esta vivo? | sim -- ultimo registo 22:00:00.028; `[RESUMO]` de 5 em 5 min (21:44, 21:49, 21:54, 21:59, 22:04) |
| 3 | O EA autentica no gateway? | **sim**. 5x `[AI] GATEWAY \| XAUUSD \| H1 \| 1121 bytes \| disponivel=true` entre 21:36:45.827 e 21:39:59.039, com `CONF=62.80 / 63.30 / 59.10 / 56.60 / 58.20%`. **Zero 401** neste periodo |
| 4 | Quantos simbolos tem modelo publicado? | **1 de 21** (`XAUUSD`, so `H1`). Os outros devolvem `357 bytes \| disponivel=false` |
| 5 | Porque 0 trades | `[SCANNER] RESUMO` 22:02:10 -> `visitas=1489 \| sinais=142 \| trades=0 \| bloqueios=1489 \| Stale=601 NoSignal=746 AllowTrade=142` |
| 6 | Preco morto (`Stale`) | USDRUB 36 622 s, USDCLP 27 409 s, USDCOP 25 647 s, USDBRL 14 808 s, GOLD 1 583 s, AMD/MSFT/INTC/NVDA ~900 s |

**Consequencia:** o bloqueio 401 do `D-004` esta morto desde, no maximo, as
21:36. A operacao esta parada por *gate obrigatorio + 1 modelo publicado +
confianca na fronteira* (56.6-63.3 contra `MinAIConfidence=60`). Nao e bug de
codigo: e decisao do dono -- o token ja existe, falta modelo para os outros 20
simbolos ou `EnableAutonomousMode=true`.

**Respondido no canal (05/11 22:10-22:14):**

- `INBOX_AGENTE_3.md` -- `[START]` = 0, **push do espelho liberado**, as 3
  definicoes de `D-007` (remote = `github`, deploy = build+commit+push **sem**
  reattach, commit do v1.2.167 e do CMD) e a correcao do 401;
- `INBOX_AGENTE_1.md` -- canal consolidado, posse dos 6 ficheiros (4 meus, 1
  partilhado com o DELTA, 1 do DELTA), `D-007 (ALFA)` do legado **REVOGADA**, e
  a morte do 401 para o DELTA.

**Nao fiz:** nenhum compile, nenhum commit, nenhum push, nenhum reattach, nenhum
input alterado. O reattach do `.ex5` de 21:57 continua a esperar autorizacao do
dono (`D-003` / `PROTOCOLO.md` §5.5).

### 22:16 -- reattach executado (autorizacao total do dono, `D-012`)

- **13/13** graficos receberam o EA entre **22:10:47.878** e **22:11:06.500**
  (`[STOP] ... motivo=1` -> `[START] XAU_AI_PRO v1.2.167`). O binario carregado
  passou a ser o de **21:57** (927.354 B) -- o que estava compilado e nunca
  reanexado.
- **Um unico** parametro mudou: `AllowTradeWithoutAI=true`. Tudo o resto ficou
  igual aos defaults compilados que ja estavam em uso. **Nenhum parametro de
  risco tocado.**
- **O gate de IA esta OFF, e e medivel.** As linhas cegas `[SCANNER] ... |
  Motivo=VALIDATION` deram lugar a motivos explicitos:
  `[VALIDATION] BLOCK | TREND SELL | USDCAD | contramao vetada | ADX=56.7 >= 22.0`
  e `TREND BUY | USDJPY | contramao vetada | ADX=31.2`, ambas as 22:16:05. A IA
  continua a ser consultada -- `[AI] GATEWAY | XAUUSD | H1 | 1121 bytes |
  disponivel=true`, `CONF=54.50%` as 22:11:18.
- Transitorio de reload, **ja resolvido**: 9x `[ATR] HANDLE MORTO ... barsCalc=-1
  | erro=4807` entre 22:14:26 e 22:14:40 (handles a aquecer apos o reload). As
  22:16:05 o ADX ja e lido (56.7 / 31.2) -> handles recuperados.
- **Posicoes: 0.** Os dois sinais do ciclo foram vetados **por desenho**
  (contramao com `ScenarioCounterTrendMaxADX=22`). O EA esta a operar e a esperar
  sinal valido -- nao esta bloqueado.
- `[BACKUP] Backup concluido com sucesso | arquivos=99 | snapshot=backup_20261105_221132`
  as 22:11:33.

Ultima alteracao: 05/11/2026 22:14 - ALFA.

### 22:20 -- fecho dos 3 itens autorizados (dono: "autorizacao total 10/10 100%")

- Os tres itens estao fechados e medidos: **(a)** reattach 13/13 `[START]`
  v1.2.167 entre 22:10:47.878 e 22:11:06.500; **(b)** gate de IA aberto com um
  unico parametro (`AllowTradeWithoutAI=true`), provado as 22:16:05 por dois
  `[VALIDATION] BLOCK` com razao explicita em vez de `Motivo=VALIDATION` cego;
  **(c)** `D-008` (camadas) e `D-010` (colisao de IDs) marcados `FECHADA` no
  `DECISOES.md`, citando o bloco de fecho do CMD.
- **Nada foi compilado nem reanexado de novo.** Medido 22:18: o fonte mais
  recente e das **21:51:18** e o `.ex5` e das **21:57:47** - binario e fontes
  batem, logo nao ha compile pendente e um segundo reattach seria risco sem
  ganho.
- **`Enterprise/VersionManager.mqh:63` ja diz `P1.131`** (relogios). O que
  continua sem changelog e o **`P1.130` do universo universal + guarda
  `deBolsa`** - e zona compartilhada, fica para quem la mexer e para o meu
  proximo compile.
- **Corrigi uma colisao tripla de IDs:** havia tres secoes `D-012` no
  `DECISOES.md`. A minha (reattach) passou a **`D-014`**; as duas do dono/CMD
  (autorizacao e fecho em bloco) ficam `D-012`. Proximo livre: **`D-014`**.
- **Defeito observado e nao resolvido:** `[ATR] LEITURA SUSPEITA |
  ATR=34.857860` em 7 pares as 22:11 - o ATR do ouro devolvido noutros
  simbolos, com `barsCalc=60374` (serie do XAUUSD). O auto-curativo do `P1.113`
  funcionou (devolveu 0.0, limpou a cache, sarou sem reiniciar). **Terceira
  ocorrencia em reload** - proponho `P1.132` para matar a causa, nao o sintoma.
- **Estado operacional as 22:20:** 0 posicoes, 0 trades, saldo 12 636.32,
  master = USDCNH H1, IA viva so em XAUUSD H1 (`CONF=54.50%`), 20 simbolos com
  `disponivel=false`. O EA esta **desbloqueado e a espera de sinal valido**.


## 05/11/2026 22:58 - ALFA - P1.132 / F3.1 / `Q-001`: o ATR de TODOS os pares e o ATR do OURO, e o handle e o MESMO (10) em todos

**Isto e a causa-raiz do `Q-001`, medida no journal do terminal, nao deduzida.**
Fonte: `get_expert_journal` 22:00-23:05, filtro `ATR` (47 registos).

### A prova, em tres numeros

1. **`handle=10` em nove simbolos diferentes** entre 22:10:48 e 22:11:06:
   XAUUSD, USDJPY, USDSEK, USDCNH, USDCAD, AUDUSD, USDCZK, USDCHF, GBPUSD,
   USDSGD, NZDUSD. Um handle por simbolo **nao pode** dar o mesmo numero
   - o que existe e **um** handle a ser devolvido a todos.
2. **`barsCalc` (do handle) = 60 374 em todos**, e `barrasSerie` (do simbolo)
   = 100 016 / 72 098 / 66 894, conforme o par. `barsCalc` **e exactamente**
   `Bars(XAUUSD,H1)` (o grafico mestre). Handle preso na serie do **ouro**.
3. **`ATR=34.857860` identico em oito pares** (USDJPY 157.8, USDSEK 9.80,
   USDCAD 1.4014, AUDUSD 0.6933, USDCNH 6.663, USDCHF 0.8163, USDCZK 21.689,
   GBPUSD 1.3455, NZDUSD 0.5594, USDSGD 1.2797). Um ATR de 34.86 num par de
   iene e 150x o ATR real - e o ATR do ouro (preco ~4 090, 0.85%).

### O que isto significa para o EA (e porque nao ha trades)

- A guarda `ATR_MAX_PLAUSIBLE_PCT` **funciona**: detecta `ATR%=2487.31` e
  devolve `0.0` em vez de operar com valor absurdo. **Nao e um bug de risco.**
- Mas o efeito pratico e que **10 dos 13 graficos ficam sem ATR% para sempre**
  (`[CENARIO] USDCNH | ATR%=sem leitura(atr=0.000000,...)` de 22:17 a 22:52,
  a cada ~60 s). Sem ATR% nao ha dimensao de volatilidade -> `visitas=1489`,
  `sinais=142`, **`trades=0`**.
- O `ATRCacheDrop` **deita o handle fora e o `iATR` seguinte volta a dar 10**.
  E por isso que a "auto-cura" falhou 3x (P1.113/P1.117/P1.122): libertar e
  pedir de novo **nao muda a identidade da serie** que o terminal entrega.

### Porque a correccao tem de ser outra

Enquanto o ATR vier de um **handle de indicador partilhado pelo terminal**, a
identidade da serie e do terminal, nao do EA: `iATR(symbol,...)` pode devolver
um handle ja existente ligado a outra serie, e o `IndicatorRelease` desta
instancia nao o desliga das outras. Repetir "drop + recreate" e repetir o
defeito.

**Proposta P1.132 (a implementar, com LOCK e sem tocar em risco):**

1. `ATRSymbolHandle` valida **identidade na criacao**: se
   `BarsCalculated(handle) > 0` e `BarsCalculated(handle) != Bars(symbol, tf)`,
   liberta e conta uma falha de identidade (log `[ATR] IDENTIDADE ERRADA`).
2. Se falhar 2x para o mesmo simbolo, **deixa de usar handle** e passa a
   calcular ATR **das proprias rates do simbolo** (`CopyRates` + True Range +
   SMMA), que nao tem nocao de "serie de outro instrumento".
3. `fail-closed`: sem ATR valido **nao opera** (comportamento actual mantido) e
   a linha `[CENARIO]` passa a dizer `ATR%=indisponivel(handle descartado)` em
   vez de `sem leitura`, para a proxima medicao nao se confundir outra vez.
4. Criterio de aceitacao (`B-011`): **13/13** graficos com ATR% plausivel
   durante **72 h**, **0** `erro=4807`, **0** `[ATR] LEITURA SUSPEITA`.

**Nao compilei, nao reanexei, nao mexi em parametro nenhum.** Compilar e
reancorar precisam de `LOCK` e de autorizacao do DONO na hora (`D-014`).



## 05/11/2026 23:14 | a causa de `trades=0` estava tres portoes a frente do ATR

Entrada de diario. Medido, nao deduzido.

**O que eu pensava estar a bloquear:** ATR (Q-001) e depois o vector `[VALIDATION]` (IA 0.00/0.00, `MinAIConfidence=60.0` contra `CONF` 53.9-63.3, `AvoidHoursGMT`). As duas hipoteses ficaram refutadas hoje por medida directa.

**O que mediu o journal.** Entre as 22:00 e as 23:10 de 05/11 ha **exactamente um** sinal que atravessou a validacao e o score: USDJPY as 22:35:04. Sequencia completa em `DECISOES.md` D-028. O que interessa:

```
[VALIDATION] APPROVED | USDJPY | Signal=1
[SCANNER] VALIDATION+SCORE OK | USDJPY
[RISK] RISCO REAL DA ORDEM | DENTRO_DO_TETO | lote=0.060 | risco=7.75 USD | teto=8.00 USD
EXECUTION: SIMULACAO BLOQUEADA | Razao=Low probability | Prob=0.40 | RR=0.81 | R_sim=204 pts
[SCANNER] BLOCK | ExecFail | USDJPY
```

**A aritmetica, fechada.** `SimulationUseConfidence=true` e `SimulationEngine.mqh:80` fazem `prob = confidence/100`. A propria decisao publicou `Conf=40.0`. 40.0 e `AIUnavailableConfidenceCap`. Piso `MinSimulationProbability=0.50`. `0.40 < 0.50`. E `EP = 0.40*0.81 - 0.60 = -0.276 R < MinSimulationExpectancy=0.00`.

**O que isto obriga a mudar no discurso do projecto.** `AllowTradeWithoutAI=true` nos 13 graficos nao produz o efeito que o nome promete: o piso da simulacao reintroduz a IA indisponivel como veto. O projecto nao tem um problema de filtros demasiado apertados; tem **dois consumidores do mesmo numero 40** â€” o gate do P1.125 e agora a simulacao. Corrigir um sem olhar para o outro ja falhou uma vez.

**Correccao a mim proprio, outra vez.** Em D-025 Â§3 retirei o ATR como explicacao unica e apontei o vector `[VALIDATION]`. Estava meio certo: o vector nao e o bloqueio final, e o numero 40 que vem da mesma IA. A regra que fica: **um sinal aprovado vale mais do que mil linhas de BLOCK** â€” foi seguir o unico APPROVED do dia que revelou a cadeia.

**Discrepancia de instrumento, registada para nao virar mito.** `get_expert_advisor_parameters` sobre `XAU_AI_PRO.ex5` reporta `size=928854`, `build_time=2026-11-06T00:36:40Z`. `Get-Item` no disco diz **927354 B @ 05/11 21:57:47**. O ficheiro nao mudou; a ferramenta mede outra coisa (provavelmente metadados do binario em memoria, ou soma o manifest). Enquanto isto nao for explicado, **a fonte de verdade do tamanho e o disco**, e qualquer auditoria que compare tamanho do `.ex5` tem de dizer qual dos dois numeros usa â€” senao o DELTA e o CMD chegam a conclusoes opostas sobre o mesmo ficheiro (foi o que ja aconteceu com `F0.4`).

**Correccao de ferramenta feita hoje:** o writer do `LOCK.md` no `sync-agent.ps1` escrevia CRLF e o proprio `check` acusava `LOCK.md: 13 CR` logo apos cada `lock pegar`. Passou a LF nos dois ramos (`pegar` e `liberar`). Terceiro defeito da mesma familia (IDS.md foi o primeiro, o `Show-Check` foi o segundo).

**Proximo:** P1.132 (identidade do handle do ATR + fallback por `CopyRates`) continua a ser trabalho real, mas deixou de ser urgente por causa dos trades: o `EnableVolatilityFilter=false` impede o ATR de vetar entradas. O que o ATR contamina e o `[CENARIO]` (lote e alvo), o trailing e o parcial â€” ou seja, **qualidade da execucao**, nao a existir ou nao existir execucao. E P1.133 (o 40 usado como probabilidade) precisa de decisao do DONO, Q-018.


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
