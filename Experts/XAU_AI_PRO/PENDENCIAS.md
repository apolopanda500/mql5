# PENDENCIAS — XAU_AI_PRO

> Fonte unica das pendencias. Indice geral em `README.md`, historico tecnico em
> `PROGRESS.md`, conversas em `CONVERSAS.md`.
>
> **Como usar este arquivo**
> - Cada item tem ID, dono, impacto e criterio de fechamento. Fechar = cumprir o
>   criterio e registrar uma linha em `PROGRESS.md` com o numero que provou.
> - Dono: `DONO` = so o dono do terminal resolve (clicar, autorizar, decidir);
>   `AGENTE` = trabalho de codigo/medicao aqui; `AMBOS` = quem estiver na vez.
> - Nada aqui e promessa de lucro. Backtest nao prova lucro futuro.
> - Ultima revisao desta lista: 2026-11-04 21:50 (conta 113568614, v1.2.147
>   compilada e validada; producao ainda em v1.2.146 ate reattach).

---

## 1. Bloqueios que so o dono resolve (sem isso, o resto fica em modo degradado)

### P-01 — gateway de IA inacessivel ao EA (porta, metodo e token) `DONO`
- **RESOLVIDO em parte (04/11 18:06): a allowlist esta fechada.** `WebRequest`
  para `http://127.0.0.1:9011` passou a ser **PERMITIDO**, medido no journal:
  `9011/api/ai/predict`, `9011/` e `localhost:9011` devolvem `HTTP=401` com
  `body=37B` (corpo do gateway), contra `body=0B` do `9001` (MCP do terminal).
  A causa do "nao salva" era o **formato**: entrada com caminho ou barra final
  (`.../api/ai/predict`, `.../`) e descartada em silencio pelo terminal — o
  `common.ini` chegou a **encolher** (5916 -> 5324 B) nessas tentativas. Gravar
  `http://127.0.0.1:9011` (sem barra, sem caminho) + OK na sub-janela + OK em
  Options funcionou: `common.ini` 5324 -> **6100 B**, blob 1087 -> **1475** hex,
  e a entrada vale para qualquer caminho daquele host:porta.
  Falta ainda: (a) `AIGatewayUrl=AIGatewayToken` nos 15 graficos; (b) P-01b.
- **RESOLVIDO em 04/11 19:05 (v1.2.135):** o gateway roda o middleware
  **fail-closed**. Antes era `if API_TOKEN:` em `backend/fastapi_gateway.py`:
  sem a variavel, qualquer chamada passava sem credencial. Agora, sem
  `XAU_GATEWAY_TOKEN`, tudo e recusado com `401 "sem token configurado"`
  (paridade com `mt5_gateway.py::_autorizado`). Medido em `127.0.0.1:9011`:
  sem token **401**, token errado **401**, token correto **200**, e
  `GET /api/ai/predict` **200** com `available=true signal=SELL
  prob_sell=0,6365 price=4063,84 atr=17,44 hash=5305081777808310`.
  O item (a) deixou de ser necessario: `AIGatewayTokenEfetivo` e
  `AIGatewayUrlEfetiva` leem token e porta do `.env` a cada chamada, entao os
  graficos nao precisam ser reconfigurados - precisam receber o `.ex5` novo.
- **P-01b FECHADO (04/11 19:05):** `backend/ai_inference.py` passou a despachar
  o construtor de features pela `feature_version` declarada no artefato e a
  decodificar a probabilidade pelas `classes_` do modelo. O unico modelo
  publicavel de XAUUSD e `XAU-30F-v4` (30 features, **binario**): o runtime
  lia `probs[2]` como BUY, que num modelo binario e sempre `0,0`, e jogava
  `probs[1]` (probabilidade de SUBIR) no campo NEUTRO. Os 80 artefatos
  `25F-v2` mantem o caminho anterior sem alteracao. Provas em
  `Docs/CONVERSA_20261104_FAIL_CLOSED_30F_E_LIMPEZA.md`.
- **Medido (04/11 16:45):** gateway sobe em `9011` com o `.env` (token de 64
  caracteres) e responde `GET /api/ai/predict` com **200**; `POST` devolve
  **405** (a rota so existe como `GET`). O EA foi corrigido para `GET` na
  v1.2.132 (compilado 0 errors / 0 warnings).
- **Por que importa:** com `RequireAIJSON=false` e `AllowTradeWithoutAI=false`, o
  portao de IA roda em **fallback** (`Files\Data\prediction_<SIMBOLO>.json`,
  `MaxPredictionAgeSec=900`). O EA opera, mas nao com a IA de verdade.
- **Como fechar:** (1) subir o gateway em `9011` — `Tools\start-gateway.ps1`,
  que forca os gates de trade a `0`; (2) **[feito 04/11 18:06]** no terminal,
  `Ferramentas > Opcoes > Expert Advisors`, marcar "Permitir WebRequest para
  URLs listadas" e adicionar `http://127.0.0.1:9011` **(sem barra final e sem
  caminho - nesse formato o terminal descarta a entrada)**; (3) colar os 64
  caracteres de `XAU_GATEWAY_TOKEN` em
  `AIGatewayToken` nos 15 graficos (pela GUI; o preset e versionado).
- **Criterio:** `Tools\verify-gateway.ps1` sem falhas e journal sem `4014`,
  `4060`, `5200` ou `5202`, com uma predicao consumida (`[AI] ... score=...`).
  Fechar registando a data no `PROGRESS.md`.
- **CORRECAO (04/11 16:30, medicao nova):** a leitura anterior ("401 =
  credencial recusada") estava **errada**. `127.0.0.1:9001` pertence ao **MCP
  embutido do MT5** (`config\assistant.ini`: `[MCP.MetaTrader] Endpoint=
  http://127.0.0.1:9001/mcp`, LISTEN no pid do `terminal64`), nao ao gateway.
  O `401` veio do terminal. O gateway esta configurado para `9011`
  (`XAU_GATEWAY_PORT`) e **nao esta no ar**. Alem disso o EA faz `POST` e
  `backend\fastapi_gateway.py:258` so declara `@app.get`, e o exe instalado
  (`%LOCALAPPDATA%\XAU AI PRO\bridge\mt5-gateway.exe`, 25/10) nem contem a
  rota. Colar o token sozinho **nao** desbloqueia. Passo-a-passo e evidencias
  em `Tools\WEBREQUEST_GATEWAY_UNBLOCK.md`; medicao em
  `Tools\verify-gateway.ps1`.
- **Medido (04/11 16:25):** os 15 graficos `Profiles\Charts\Default\*.chr`
  estao com `AIGatewayUrl` = 9001 e `AIGatewayToken` **vazio**; o preset
  versionado `Presets\XAU_AI_PRO.PRO.set` tem 17 caracteres, que sao um
  **placeholder** (contem a palavra TOKEN). O `XAU_GATEWAY_TOKEN` do `.env`
  tem **64**. O token real nunca deve ir para o preset (ficheiro versionado).

### P-01b — modelo publicado declara 30 features e o runtime monta 25 `AGENTE`
- **Medido (04/11 16:45):** `GET /api/ai/predict?symbol=XAUUSD&timeframe=H1`
  devolve `200` com `available:false` e
  `erro na inferencia: X has 25 features, but HistGradientBoostingClassifier
  is expecting 30 features as input`.
- **Evidencia:** `Python\models\XAUUSD_H1.pkl` — `feature_version=XAU-30F-v4`,
  `feature_count=30`, status READY, publicable true (40 h); o consumidor
  `backend\ai_inference.py` monta **25** (`FEATURE_VERSION=25F-v2`).
- **Por que importa:** sem isto o EA recebe `available:false` mesmo com porta,
  metodo e token corretos. Nao e rede nem WebRequest.
- **Como fechar:** retreinar e republicar o modelo no contrato atual, ou alinhar
  a lista de features do runtime ao artefato. Decisao de pipeline.
- **Criterio:** o mesmo GET deixa de trazer `erro na inferencia` e devolve
  `available:true` com `signal` diferente de `NEUTRAL` (ou a recusa passa a ser
  so de edge/AUC, que e regra de produto).

### P-02 — Testador de Estrategia ocupado (bloqueia toda medicao) `DONO`
- **Medido:** um job de teste segue rodando desde o ciclo anterior, ocupando o
  unico slot do Strategy Tester.
- **Como fechar:** clicar **Stop** no Testador (ou aguardar terminar).
- **Criterio:** `tester_get_status` sem job ativo. Sem isso, AT-01..AT-03 nao
  rodam.

### P-03 — Qual e a meta diaria? 100 USD ou 20 USD? `DONO`
- **Medido:** `EnableDailyTargetBalancePct=true`, `DailyProfitTargetBalancePct=10`,
  `DailyProfitTargetMaxUsd=100` => meta efetiva **100 USD**; e
  `LadderTpUsd=20` fecha a escada em 20 USD por posicao.
- **Conflito:** um numero manda parar o dia, o outro manda fechar o trade. Nao
  sao a mesma coisa e o journal mistura os dois.
- **Como fechar:** decidir a meta do dia e deixar **um** caminho ligado; se a
  meta for 20 USD, baixar `DailyProfitTargetMaxUsd` para 20 (ou desligar o alvo
  por percentual) e registrar a decisao no `README.md` secao 5.
- **Criterio:** um unico numero documentado como "meta do dia", coerente com os
  inputs dos 16 graficos.

### P-04 — `StoplessEmergencyPoints=0` (entrada sem colchao) `DONO`
- **Medido:** `EnableStoplessEntry=true`, `StoplessArmATRMult=0.8`,
  `StoplessArmMinPoints=30`, `StoplessEmergencyPoints=0`.
- **Por que importa:** a entrada e feita sem SL e o SL e armado depois. Se o
  armar falhar (broker lento, spread, freeze level), a posicao fica **sem
  stop**.
- **Como fechar:** decidir um valor de emergencia (ex.: 30-50 pontos acima do
  ATR de armamento) e aplicar nos 16 graficos.
- **Criterio:** nenhuma posicao pode existir por mais de N segundos sem SL;
  provar com um ciclo de posicoes abertas no journal.

### P-05 — Notificacoes nao saem do terminal `DONO`
- **Medido:** `email_enabled=false`, `notifications_enabled=false` no terminal;
  `NotifyTelegramToken=""` e `NotifyTelegramChatID=""`.
- **Como fechar:** ligar push/e-mail no terminal (ou preencher Telegram) e testar
  um evento.
- **Criterio:** um evento de teste chega no celular/e-mail. Sem isso, o dono
  descobre problema de risco tarde.
- **Correcao de observabilidade (v1.2.145, 04/11/2026):** o *registo* das
  notificacoes estava ilegivel e sem limite, independentemente do envio. MEDIDO
  as 21:17 em `Common\Files\Notifications.log`: 53 200 689 bytes, 1 644 441
  linhas, 41 491 blocos `HEALTH MONITOR` de ~39.6 linhas cada e a linha 1 era
  `2026.08.14 00:00:00FAIL[RELATORIO] Profit=0.00` (data, estado e mensagem
  colados, porque o separador implicito do `FileWrite` nao sai no ficheiro).
  O `[NOTIFY] Failed` do tester as 20:58:22 dizia `1156` para 578 mensagens —
  o contador somava duas vezes a mesma falha. Corrigido: uma notificacao = uma
  linha delimitada por ` | `, tecto de 400 caracteres, rotacao para
  `Notifications.old.log` acima de 8 MB e contagem unica por mensagem.
  `0 errors, 0 warnings`; `validate_mql5.py` `[OK]`; `pytest
  tests/test_mql5_compila.py` 2 passed. Falta reanexar o EA para a v1.2.145
  entrar em producao.

---

## 2. Medicoes pendentes (dependem do P-02)

### AT-01 — Backtest 20-29/10 com o `.set` atualizado `AGENTE`
- **Config:** `xai_v1300_c5.ini` + `.set`. **Antes de rodar**, atualizar o `.set`
  com todos os inputs novos, senao ele herda defaults e o resultado nao
  representa producao: `EnableMoneyLadder` / `LadderArmUsd` / `LadderLockUsd` /
  `LadderLockTriggerUsd` / `LadderTpUsd`; `EnableOperatorBrief`;
  `EnableScenarioAdaptation` + `Scenario*`; `EnableCurrencyExposureGuard` +
  `MaxCorrelatedTrades` / `MaxCorrelatedRiskPercent`; `EnableSessionLotAdaptation`
  + `SessionLot*`; `EnableAvoidHoursGMT` + `AvoidHoursGMT`; `EnableCostGate` +
  `MaxCostPctOfTarget` / `MaxCostPctOfRisk` / `CommissionPerLotUsd`;
  `CircuitBrokerFailMinCheck` / `CircuitBrokerFailMinSeconds` /
  `CircuitWarmupSeconds`.
- **Baseline para comparar:** 303 trades / PF 0.8961 / resultado -30,95 / DD
  1,68%.
- **Criterio:** relatorio salvo + tabela comparativa (baseline x atual) anexada
  ao `PROGRESS.md`.

### AT-02 — Isolar o efeito do `CostGate` `AGENTE`
- **Como:** mesma janela, `EnableCostGate=false` x `true`.
- **Por que importa:** o gate pode **reduzir** entradas boas; hoje ele aprovou o
  unico caso real (custo 0,6% do alvo). Nao se sabe se esta barrando trade.
- **Criterio:** numero de entradas e PF nas duas configuracoes.

### AT-03 — Isolar `EnableAdaptiveTrendGate` e `MaxCorrelatedTrades` `AGENTE`
- **Como:** `MaxCorrelatedTrades` em 1 e em 3, e gate adaptativo on/off (4
  rodadas curtas, ou 2 com o resto fixo).
- **Por que:** o gate adaptativo barra contra-tendencia em LATERAL — pode estar
  certo ou estar perdendo reversao.

### AT-04 — Sonda `XAI_TargetProbe` com a escada ativa `AGENTE`
- **Onde:** `Data\XAI_targets_probe.csv` (existe).
- **O que medir:** `realizado_R` x `mfe_R` por trade — quanto o preco andou a
  favor depois do fechamento.
- **Por que:** foi o que mostrou que o TP "curto" era o break even em 10 pontos,
  nao o alvo. Repetir agora com `EnableMoneyLadder=true`.
- **Criterio:** decidir TP > 1 R **so** com backtest limpo (pedido anterior do
  dono: "melhorar alvos curtos").

---

## 3. Codigo candidato a v1.2.26 (so depois de AT-01..AT-03)

### CD-01 — `CostGate` com slippage REALIZADO `AGENTE`
- **Hoje:** o gate usa spread corrente + comissao declarada.
  `Enterprise/ExecutionQuality.mqh` ja registra `req.price` x preco real de
  execucao.
- **Mudanca:** alimentar o custo com o slippage medido (media por simbolo, com
  fallback no spread quando nao houver amostra).
- **Risco:** mudar regra de dinheiro sem medicao — por isso vem depois do AT-02.

### CD-02 — Reancorar `CostMinViableTargetPoints` `AGENTE`
- **Hoje:** o minimo viavel e calculado; se o alvo for menor, o gate **bloqueia**.
- **Mudanca:** com o numero do AT-02, reancorar o minino (ou deixar bloquear so
  quando o custo passar do teto `MaxCostPctOfTarget`).

### CD-03 — Fatiamento de ordem (TWAP/VWAP/iceberg) `AGENTE`
- **Status:** descartado por medicao (lote pequeno em 16 simbolos; fatiar
  aumenta comissao). Reavaliar **apenas** se o lote medio subir e o CD-01
  mostrar slippage relevante.

### CD-04 — Risco efetivo por trade em US$ observavel `AGENTE`
- **Hoje:** existe `MaxRiskPerTradeUsd=8.0` e
  `MaxRiskPerTradePercentCap=3.0`, mas nao ha uma linha de journal provando o
  risco em dolares de cada ordem (o lote 1,36 do USDCNH passou por varios
  multiplicadores — ver IN-01).
- **Mudanca:** imprimir `risco_usd` calculado (distancia do SL x valor do ponto
  x volume) na mesma linha do `[EXECUTION]`, antes do envio.

---

## 4. Higiene de projeto e documentacao

### HG-01 — Versao em tres lugares `AGENTE`
- **Medido:** `XAU_AI_PRO.mq5` ainda tem no cabecalho `XAU_AI_PRO v1.2.9` e
  `#property version "1.290"`, enquanto `EA_VERSION_STRING` e `"1.2.25"`.
- **Regra que fica:** a cada ciclo subir **os tres** juntos —
  `EA_VERSION_STRING` (`Enterprise/VersionManager.mqh`), o comentario do
  `.mq5` e o `#property version` (forma `xxx.yyy`; 2.25 -> `1.2250`).
- **Criterio:** journal `[VERSION]`, fonte e `#property` contando a mesma
  historia. Foi exatamente esse descasamento que fez o journal mentir antes.

### HG-02 — Referencia morta ao arquivo `VERSION` `AGENTE`
- **Medido:** o comentario do `VersionManager.mqh` cita um `VERSION` na raiz que
  **nao existe** mais no projeto.
- **Mudanca:** remover o comentario ou recriar o arquivo como fonte canonica.
  Nao deixar documentacao apontando para o vazio.

### HG-03 — Scripts antigos em `Files\Temp` `AGENTE`
- **Medido:** `apply_v1221.ps1`, `apply_v1222.ps1`, `apply_v1223.ps1`,
  `apply_v1226.ps1` continuam la.
- **Mudanca:** mover para `Files\Backup` (registro de como cada versao foi
  aplicada) ou apagar. Decidir e nao deixar crescendo.

### HG-04 — Secao 4 do `README.md` e foto, nao filme `AGENTE`
- **Regra:** a cada sessao, atualizar a secao 4 com o estado medido e a hora da
  medicao. Estado velho no indice e pior que estado ausente.

### HG-05 — `BackupManager` esta gerando backup? `AGENTE`
- **Medido:** `EnableBackupManager=true`, `BackupIntervalMinutes=60`,
  `BackupMaxKeep=10`, mas `Files\Backup` tem so 2 arquivos (um `.bak_v1215` e um
  CSV de aprendizado).
- **Mudanca:** conferir se o backup automatico esta escrevendo (ou se o
  intervalo so dispara em nova barra / outro caminho).

---

## 5. Inconsistencias medidas (investigar antes de mudar regra)

### IN-01 — Lote 1,36 em USDCNH com risco desproporcional `AMBOS`
- **Medido:** fechou **+10,42** em 02:10 (server), mas o volume 1,36 num par
  exotico veio de `RiskPerTradePercent=0,5` x `EnableDynamicLot` com
  `DynLotFactorElite=4.0` x `ScenarioLotFactor` x `SessionLotFactor`.
- **Regra do dono que fica:** "ganhar com risco desproporcional nao valida o
  risco".
- **Criterio:** medir o risco em US$ daquele trade (nao o resultado) e provar
  que ele passou pelo `MaxRiskPerTradeUsd=8.0`. Se passou, o cap esta errado ou
  nao e aplicado; se nao passou, o lote e justificado.

### IN-02 — 16 graficos x `Symbols` com 11 `AGENTE`
- **Medido:** `Symbols="XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH"`
  (11), mas ha grafico de **USDCLP, USDCOP, USDCZK, USDRUB, USDSGD** (5 fora da
  lista) e **XAUUSD aparece em 2 graficos** (M15 `chart01` e H1 `chart14`).
- **Por que importa:** o que o scanner da cesta cobre e o que os graficos
  mostram sao conjuntos diferentes; risco correlacionado e contagem de
  exposicao podem divergir.
- **Criterio:** decidir se a cesta `Symbols` vira a fonte unica (e os graficos
  extras saem) ou se `Symbols` e ampliada. Registrar a decisao.

### IN-03 — `DailyProfit` global e flutuante, nao realizado `AGENTE`
- **Medido:** a global `DailyProfit` usa `AccountInfoDouble(ACCOUNT_PROFIT)`
  (flutuante). A meta do dia compara com realizado.
- **Mudanca:** renomear/rotular para `DailyFloating` ou calcular realizado — o
  nome de hoje engana quem le o journal.

### IN-04 — `LearningPenaltyEnabled=false` x `EnableLearningLotPenalty=true` `NENHUMA`
- **Registro:** `LearningPenaltyEnabled=false` **nao** e bug — esta documentado
  em `AI/LearningHistory.mqh` (linhas 401, 1030, 1055) como escolha: a memoria
  negativa ajusta lote, nao score.
- **Acao:** nenhuma. Fica aqui para nao ser reaberto como "defeito" numa sessao
  futura.

### IN-05 — Volume de log em producao `AMBOS`
- **Medido:** `EnableVerboseDebug=true`, `DebugTradeDecision=true`,
  `ForwardHeartbeatSec=300`, `EnableForwardLog=true`.
- **Mudanca:** depois do backtest, decidir desligar o verbose em producao e
  manter so `HEALTH MONITOR` / `SYSTEM STATUS` / `RECOVERY` / `[COST]` /
  `[GLOBAL]` / `[EXECUTION]`.

---

## 6. Monitoramento continuo em producao (nao e tarefa, e vigia)

| Linha do journal | O que ela diz | O que fazer se aparecer |
|---|---|---|
| `[VERSION]` | qual binario esta rodando | se nao for o do fonte, **todo** numero do log e suspeito |
| `[COST] BLOCK` | custo passou do teto | medir se esta barrando trade bom (AT-02) |
| `[VALIDATION] AVOID HOUR` | hora proibida em GMT (`18,22`) | conferir se a janela faz sentido para o simbolo |
| `[GLOBAL]` | classe / sessao / fator de lote | conferir classificacao (o bug do USDBRL nasceu aqui) |
| `[CIRCUIT] SAFE MODE` | broker instavel | hoje a histerese exige 3 leituras + 15 s; se voltar a piscar, revisar |
| `RECOVERY_OK` / `HEALTHY` | canais AI/Indicators/Broker/Dataset/JSON/Memory | se um canal cair, o motivo esta na linha `Error:` |
| `[PIPELINE] STANDBY` | outra instancia e a dona da cesta | normal em 15 dos 16 graficos |

---

## 7. Checklist de retomada (10 primeiros minutos de qualquer sessao)

1. `get_workspace_info` nos dois servidores (MetaEditor e MetaTrader).
2. Journal: confirmar `[VERSION]` — **regra de ouro do projeto**.
3. Conta: `balance` / `equity` / posicoes abertas / `Trades: N/100`.
4. `tester_get_status`: se o Testador estiver livre, comece por **AT-01**.
5. Ler **este arquivo**, escolher **um** item e nao misturar codigo com medicao
   na mesma rodada.
6. Ao fechar um item: uma linha no `PROGRESS.md` com o numero que provou, e a
   linha correspondente atualizada aqui.

---

## 8. Ordem de valor (se so houver tempo para tres coisas)

1. **P-01** (WebRequest + token) — devolve a IA ao EA; e configuracao, nao codigo.
2. **P-02 + AT-01** (Stop no Testador + backtest com `.set` correto) — sem isso
   nenhuma mudanca de regra tem prova.
3. **IN-01 / CD-04** (risco real em US$ por trade) — e o que separa "ganhou" de
   "ganhou com risco errado".

---

## 9. Ciclo 93b (2026-11-04 19:35) - medicao bloqueada de novo, preparo concluido

- Testador ocupado: metatester64 8772/12896/4476 e MetaTester64 11832/4212 vivos.
  tester_run_backtest devolveu tester still started e tester_list_result_windows
  devolveu lista vazia. NADA foi medido neste ciclo - nao ha numero novo de PF.
- Pronto para uso assim que o slot libertar: Profiles/Tester/XAI_V12135_PRODGEOM_RT_M15.ini
  (XAUUSD, M15, ticks reais, 2026.09.01..2026.11.01, deposito 10000, SEM .set, para
  correr a geometria de PRODUCAO - RewardRatio 0.65 / MinRewardRatio 0.55 - e nao a
  geometria do .set antigo de teste).
- IA confirmada viva no journal de 19:22 a 19:31: XAUUSD responde com sinal; os outros
  12 simbolos devolvem 357 bytes = available=false com motivo preenchido (gate a trabalhar).
- Conta real continua recusada: PF 0.6206, 41.4 pct de acerto, 10-11 perdas seguidas,
  contra a regra PF > 1.20 e streak <= 8.

---

## 10. Ciclo 93c (2026-11-04 19:47) - drift de feature_version fechado por medicao

MEDIDO (nao alterei codigo nenhum - nao era preciso):

- `Python/ai/feature_contract.py:26` diz `FEATURE_VERSION = 25F-v1`. O modulo NAO e
  importado por ninguem: `findstr /S feature_contract` em backend, Python e Python/ai
  devolve zero linhas. Logo o 25F-v1 e sobra, nao contrato vivo.
- `Python/model_registry.py:52` diz `FEATURE_VERSION = 25F-v2`, mas so serve de
  fallback na linha 108 (`meta.get(feature_version) or FEATURE_VERSION`).
- Prova de que o fallback nunca dispara: 165 ficheiros `*.meta.json` no repo,
  165 trazem `feature_version`, 0 sem. META_TOTAL=165 / COM=165 / SEM=0.
- O runtime nao decide pelo constante: `backend/ai_inference.py:845` le a versao do
  ARTEFATO (`meta.get(feature_version)`) e despacha em 846 para o construtor 30F ou
  para o 25F. E por isso que o XAUUSD H1 serve XAU-30F-v4 com
  feature_hash 5305081777808310 sem partir os outros 80 modelos.

CONCLUSAO: nao ha drift funcional. Os dois constantes sao cosmeticos e o caminho
quente esta correto e provado. Fechar como resolvido; nao vale tocar em Python que
funciona so para alinhar duas etiquetas.

TESTADOR: 2a tentativa as 19:47 devolveu de novo `tester still started`.
Continua bloqueado; nenhum run lancado, nenhum numero novo.

## 11. Ciclo 94 (2026-11-04 19:53) - P1.91: o ADX nunca era lido no Strategy Tester

DEFEITO NOVO, medido, corrigido e deployado neste ciclo (nao e o P-02):

`GetADX()` devolvia `-1.0` quando `BarsCalculated(handle) < ADXPeriod*2`. No tester
o `BarsCalculated` devolve `-1` enquanto o MT5 nao calculou o indicador, e e o
`CopyBuffer` que manda calcular. O guarda impedia o `CopyBuffer`, o handle nunca
aquecia e o guarda nunca deixava de disparar: impasse auto-sustentado, e invisivel
porque saia como "fail-open" em vez de erro.

PROVA (`Tester\logs\20261104.log`, run das 18:08, `XAI_BASE_v131.ini`, XAUUSD H1,
2026.09.01..2026.11.01, Model=1):

```
18:08:33  [ADX] INIT OK | Symbol=XAUUSD | Period=14
18:08:33  [ADX] SEM LEITURA | XAUUSD | BarsCalculated=-1 | tratado como neutro (fail-open)
2026.09.11 [SCANNER] RESUMO | ... | ADX(sem/ok)=2093/0
```

Zero leituras boas em 2093 tentativas, dez dias de simulacao depois do init. Prova
diferencial no MESMO run: `GetATR()` (`Indicators/VolatilityFilter.mqh:61`) chama
`CopyBuffer` directo, sem essa guarda, e devolve `ATR%=0.39` normalmente - portanto
nao e limitacao do tester, e o guarda.

CORRECAO (v1.2.136, uma linha em cada um dos dois sitios de `Indicators/ADX.mqh`):

- `if(calculadas > 0 && calculadas < ADXPeriod * 2)` - o `-1` (sem dado calculado)
  passa a tentar o `CopyBuffer`; o valor positivo pequeno (aquecimento real)
  continua a devolver `-1.0` como antes.
- a mensagem de falha do `CopyBuffer` passa a publicar `BarsCalculated`.

IMPACTO - o ponto que conta para uso real: **todo backtest feito ate hoje mediu um
EA SEM ADX**. Cenario por omissao (`SEM_LEITURA`), gate dinamico de ADX em
fail-open, `DecisionEngine:158` e `ValidationEngine` no ramo "sem leitura". O
**PF 0,6206 nao descreve o EA que corre nos 13 graficos** e tem de ser re-medido
com o build v1.2.136.

CORRECAO DA ANOTACAO ANTERIOR (§9 e §10): dizia-se que o slot estava ocupado por
"runs fantasma" e que `tasklist` e `tester_list_result_windows` discordavam.
MEDIDO agora, as 19:49: o slot esta ocupado por um backtest **REAL** lancado as
18:08:28 com `XAI_BASE_v131.ini`, em 2026.09.11 16:00 (11 de 61 dias, ~18%), CPU
1653->1655 s em 8 s, log a crescer (114 MB). ETA ~8-9 h. O `tester still started`
era VERDADE. Nao ha processos fantasma a matar e nada foi lancado por cima.

VALIDACAO: `Result: 0 errors, 0 warnings` (28316 ms, X64 Regular). ex5 em
04/11/2026 19:53, 834.986 bytes. Em producao nao muda nada: com o mercado aberto o
`BarsCalculated` e > 0 no caminho normal, logo o ramo alterado e o mesmo de antes.

NOVO ITEM ABERTO (medido no mesmo run): `[AI] FILE EM FALTA |
Data\prediction_XAUUSD.json`. O ficheiro existe em `MQL5\Files\Data\` mas o tester
le a sandbox `Tester\Agent-127.0.0.1-3000\MQL5\Files\`, onde ele nao esta - e
`Tester\` e raiz de LEITURA, nao de escrita, portanto a copia nao pode ser feita
por ferramenta. Copiar resolve para UM run e congela a previsao; a solucao real e
o EA procurar a previsao em `FILE_COMMON` (pasta Common `MQL5\Files\Data`) para o
backtest ler o mesmo ficheiro que a producao le.

---

## 12. Ciclo 95 - 04/11/2026 20:10 - P1.92 FECHADO (v1.2.137)

### P1.92 - o Strategy Tester media um EA sem IA (fechado) `FEITO`

**Sintoma medido:** `[AI] FILE EM FALTA | Data\prediction_XAUUSD.json` em todas
as barras do run das 18:08 (`Tester\logs\20261104.log`), embora o ficheiro
existisse em `MQL5\Files\Data\` (1082 B).

**Causa:** dentro do Strategy Tester a sandbox de ficheiros e
`Tester\Agent-<ip>-<porta>\MQL5\Files\`, e o pipeline Python nunca escreve la.
O EA procurava so na raiz LOCAL, que no tester e essa sandbox.

**Correcao:** `AI\AIConnector.mqh::LoadAIPrediction` resolve o ficheiro tentando
primeiro a raiz LOCAL e, se ausente, `FILE_COMMON`; a raiz escolhida e passada
nas flags do `FileOpen` e a linha `[AI] LOAD` publica `ROOT=LOCAL|COMMON`.
`FILE_COMMON` resolve para a pasta Common verdadeira mesmo dentro do tester
(provado na v1.2.45 com o isolamento do `trade_history`).

**Producao:** inalterada. Onde o ficheiro local existe - os 13 graficos ao vivo -
o primeiro teste da LOCAL acerta e o comportamento e o mesmo de antes.

**Copia em Common refrescada:** `Common\Files\Data\prediction_XAUUSD.json` estava
em 521 bytes de `25/08/2026 17:16:47` (70 dias). Passou a 1082 bytes com o
snapshot atual (`SELL`, `confidence 63,6`, `XAU-30F-v4`, `feature_hash
5305081777808310`, `edge +0,0363`, `AUC 0,5630`, 4/5 folds positivos). Aceitavel
porque `age = TimeGMT() - predUtc` satura em 0 num backtest que arranca antes do
`timestamp_utc` - o sinal fica congelado no instante do run, nao evolui por barra.

**Validacao:** `Result: 0 errors, 0 warnings, 27 713 ms elapsed, cpu='X64 Regular'`.
`.ex5` 834.986 B -> **836.938 B** as `20:05:18`.

**Documento:** `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_P192_PREVISAO_FILE_COMMON.md`

Consequencia: **nenhum PF medido ate hoje descreve o EA atual.** O ciclo 94 provou
que o tester nunca leu o ADX; este prova que nunca leu a IA. Os numeros existentes
servem para recusar conta real por prudencia, nao para decidir geometria.

### HG-01 - `#property version` estava oito versoes atras (fechado) `FEITO`

`#property version "1.326"` = minor*100 + patch = v1.2.**126**, contra
`EA_VERSION_STRING "1.2.136"` em `Enterprise\VersionManager.mqh`. O binario
declarava uma versao que nao era a dele. Agora:

- `#property version "1.337"` (v1.2.137)
- `#define EA_VERSION_STRING "1.2.137"`
- cabecalho `// XAU_AI_PRO v1.2.137`

O changelog do `VersionManager.mqh` registra P1.92 e a propria correcao do HG-01.

### P-02 - Testador ocupado (continua) `DONO`

**Re-medido as 20:08** (nao presumido): `Tester\logs\20261104.log` com
**155.572.518 bytes** e mtime `20:08:13`, a crescer durante a medicao
(era 130.885.948 as 19:00). `terminal64` pid 12016, `MetaEditor64` pid 12548,
e nenhuma janela de resultado (`tester_list_result_windows` = `[]`).

**Conclusao:** o run das 18:08:28 com `XAI_BASE_v131.ini` continua **vivo**. Nao
ha processos fantasma a matar, e nada foi lancado por cima. Enquanto durar, AT-01
a AT-03 e a re-medição do PF com `v1.2.137` nao rodam.

**Como fechar:** clicar **Stop** no Testador, ou esperar (ETA ~8-9 h contadas do
inicio do run). **Criterio:** `tester_get_status` sem job ativo.

**Quando fechar, usar `Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini`** (XAUUSD
M15, ticks reais, 2026.09.01..2026.11.01, deposito 10 000, sem `.set`, logo
geometria de producao) e ler o `[AI] LOAD` no journal para confirmar
`ROOT=COMMON` no tester.

## 13. Ciclo 96 - 04/11/2026 20:25 - P1.93/P1.94/P1.95 FECHADOS (v1.2.138)

### P1.93 - Market Intelligence nunca compilou e levou o binario `FEITO`
Causa: colisao de enumeradores (`error 282`), campos inexistentes de `MqlCalendarValue` (6x `error 256`) e `tm.month` (1x `error 256`). Efeito: `Result: 8 errors, 7 warnings` e `.ex5` apagado do disco. Correcao: prefixo `MS_`, calendario nativo via `CalendarValueHistory`/`CalendarEventById`/`CalendarCountryById`, `tm.mon`.

### P1.94 - sessao calculada com a hora do SERVIDOR `FEITO`
Medido as 23:20 UTC: `Sessao: Toquio`, quando a janela correcta era Sydney. Correcao: `TimeGMT()`. Confirmado no journal: `Sessao: Sydney`. Producao muda de valor: a sessao passa a estar certa.

### P1.95 - filtro de moeda aplicado depois do truncamento `FEITO`
Medido: `Proximo evento:  (impacto=0)` com dezenas de releases no calendario. Correcao: filtro dentro do scan (`IntelCurrencyRelevant`).

### P1.96 - `BlockHighImpactNewsMin` continua inerte `DONO`
`GetNextEventForSymbol` devolve evento vazio para XAUUSD/GBPUSD mesmo apos o P1.95. **Nao e buraco de protecao:** o veto de noticia em vigor e o do `NewsFilter` (`DecisionEngine.mqh:632-647`, `IsNewsBlocked(symbol)`). **Como fechar:** comparar, no mesmo instante, `CalendarValueHistory` dentro do EA e `economic_calendar_list_values` do terminal, e publicar `g_nextEventsCount` no journal.

### P-02 - Testador ocupado `DONO`
Ainda a correr (log 163,5 MB -> 163,7 MB em 6 s, 20:11). Criterio: `tester_get_status` sem job activo; depois re-medir com `XAI_V12135_PRODGEOM_RT_M15.ini` e confirmar `[AI] LOAD ... ROOT=COMMON` no journal do tester.
## 14. Ciclo 97 - 04/11/2026 20:31 - P1.96 e P1.97 FECHADOS (v1.2.140)

### P1.96 - o pais do evento nunca era resolvido `FEITO`
`MqlCalendarCountry cn` era declarado e nunca preenchido: a chamada `CalendarCountryById(ev.country_id, cn)` desapareceu na reescrita que moveu o filtro de moeda para dentro do scan (P1.95). Com `cn.currency` vazio, `IntelCurrencyRelevant("")` devolvia `false` para todos os eventos. Correcao: pais reposto antes do filtro, no padrao do `NewsFilter.mqh`.

### P1.97 - moedas do simbolo derivadas com a funcao errada `FEITO`
`IntelSymbolCurrencies` usava `NewsSplitCsv`, que divide CSV por virgula: aplicada a `"USDCAD"` devolvia `["USDCAD"]`, que nunca iguala `"USD"` nem `"CAD"`. Correcao: delega em `SymbolNewsCurrencies` (ja existente no `NewsFilter.mqh`), e `GetNextEventForSymbol` usa a mesma funcao. Prova no journal as 20:31:13.217: `Proximo evento: Licenciamento de Veiculos (Mensal) (impacto=1)` / `Min para evento: 568`.

### P-02 - Testador ocupado `DONO`
Sem alteracao. Criterio: `tester_get_status` sem job activo; depois re-medir com `XAI_V12135_PRODGEOM_RT_M15.ini` e confirmar `[AI] LOAD ... ROOT=COMMON` no journal do tester.

### P-03 / P-04 / P-05 - abertos `DONO`
`DailyProfitTargetUsd 20` vs `DailyProfitTargetMaxUsd 40`; `StoplessEmergencyPoints=0`; notificacoes com `10060 wsa error`.

### `[DATA] SEM LEITURA | ATR=0.000000` em simbolos nao-XAU `DONO`
Medido as 20:19:24 nos graficos nao-XAU do perfil. O XAUUSD le normalmente. Suspeita: historico insuficiente nos simbolos exoticos apos o reload do perfil.
## 15. Ciclo 98/99/100 - 04/11/2026 20:31-20:44 - P1.98 e P1.100 FECHADOS (v1.2.142)

### P1.98 - recusa do gateway publicada como previsao `FEITO`
`[AI] PYTHON | USDCNH | NEUTRAL | PRICE=0.00000 | ... | CONF=0.00%`. O
`ParsePredictionJSON` nao lia a chave `available`, por isso uma recusa legitima
do gate walk-forward (`available:false`, `price 0.0`) era guardada como previsao
`NEUTRAL` e atravessava `AIEngine.mqh:512` porque nem `LoadAIPrediction()` era
`false` nem `AI_Signal` era `UNAVAILABLE`/`ERROR`. Correcao: extrair
`available`/`reason` e, antes do `// SYMBOL MATCH`, devolver `false` com estado
limpo e `[AI] INDISPONIVEL` limitado a 1/hora/simbolo/conta. Provado ao vivo no
build v1.2.141: 13 recusas lidas como indisponibilidade, zero `PRICE=0.00000`,
XAUUSD a manter `SELL CONF=71.90%`.

### P1.100 - codigo de transporte rotulado como backend morto `FEITO`
`[AI] GATEWAY | HTTP 1003 | ... | backend fora do ar | WebRequest=LIGADO (a
chamada SAIU) | corpo=0B`. 1003 nao e codigo HTTP (um HTTP valido termina em
599) e 8 s depois a mesma chamada devolveu 1120 bytes e um SELL real. Nova faixa
`status > 599` testada antes de `status >= 500`, com o texto
`resposta NAO-HTTP (codigo devolvido pelo transporte, nao do servidor ...)`.
Segundo item: removido o `if(logOnce)` duplicado antes do `Print` de
`[AI] LOAD`. **Como fechar a verificacao:** esperar o proximo soluÃ§o de
transporte e confirmar no journal o texto novo em vez de `backend fora do ar`.

### HG-01 - desalinhamento de identidade apanhado e corrigido `FEITO`
Com o cabecalho em v1.2.141 e `EA_VERSION_STRING "1.2.141"`, o `#property
version` ainda lia `"1.340"`. Corrigido para `"1.342"` e reconfirmado por
leitura da linha 22. Regra a manter: identidade = minor*100 + patch, sempre
igual em tres sitios (cabecalho, `EA_VERSION_STRING`, `#property version`).

### `AI_Symbol=""` no ramo do P1.98 `ABERTO`
O ramo novo limpa `AI_Symbol`. Ha duas definicoes (`AIConnector.mqh:1606/1616`,
`AIDataForSymbol()`/`GetAISymbol()`); a busca de chamadores ficou pendente.
**Como fechar:** procurar chamadores e confirmar que string vazia e tratada como
"sem simbolo" e nao como erro.

### P-02 - Testador ocupado `DONO`
Sem alteracao. `tester_list_result_windows` = `[]` com o log do tester a crescer
163.503.296 -> 163.733.688 B em 6 s. Criterio: `tester_get_status` sem job
activo; depois re-medir com `XAI_V12135_PRODGEOM_RT_M15.ini` (XAUUSD M15, ticks
reais, 2026.09.01-2026.11.01, deposito 10000, sem `.set`) e confirmar
`[AI] LOAD ... ROOT=COMMON` no journal do tester.

### P-03 / P-04 / P-05 - abertos `DONO`
`DailyProfitTargetUsd 20` vs `DailyProfitTargetMaxUsd 40`;
`StoplessEmergencyPoints=0`; notificacoes `10060 wsa error`.

### `[DATA] SEM LEITURA | ATR=0.000000` em simbolos nao-XAU `DONO`
Sem alteracao. XAUUSD le normalmente. Suspeita mantida: historico insuficiente
nos simbolos exoticos apos o reload do perfil. `[ADX] SEM LEITURA ... Error=4022
| BarsCalculated=-1` no mesmo conjunto.

### Higiene pendente
pytest ausente da `.venv`; mojibake em `CONVERSAS.md` antigo (visivel em
comentarios do `AIConnector.mqh` como `sÃƒÆ’Ã‚Â­mbolo`); duplo tracking de
`Files/XAU_AI_PRO`.

### Verificacao pos-deploy 20:44-20:55 (ciclo 101 parcial) `AGENTE`
- **Journal do expert v1.2.142:** depois de 20:44, 14 linhas `[AI] GATEWAY`
  (XAUUSD 1122 B + 13 simbolos 357 B); zero `[AI] INDISPONIVEL`; zero
  `PRICE=0.00000` (a ultima e de 20:31:39); zero `backend fora do ar` depois
  de 20:40:21. P1.98 confirmado em journal de producao.
- **P1.100 ainda nao exercitado:** nao houve nova falha de transporte desde o
  deploy, logo a faixa `status > 599` continua sem observacao em journal real.
- **P-02 continua e o retry nao pode ser lancado:** o job em curso arrancou as
  20:26:22 com `v1.2.138` (build anterior ao fix) e ocupa o slot. `tester_stop`
  exige `run_id` e recusa qualquer valor; `tester_get_status` e
  `tester_get_configuration` tambem exigem `run_id`; `tester_list_result_windows`
  = []. `metatester64.exe` PID 152 activo (264 MB). O job em curso **nao mede**
  P1.98/P1.100. Fechar com Stop manual do dono na aba Testador.
- **Candidato novo 1:** no job em curso, `[SAFETY] Daily loss limit: 69.89/60.00`
  imprime 2x por timestamp a cada ~10 s. Investigar spam/duplicacao por simbolo
  antes de mudar regra.
- **Candidato novo 2:** em producao o AI devolve previsao com `AGE` a crescer
  (`[AI] PREDICAO VENCIDA | XAUUSD | AGE=5068s > LIMIT=900s`, `IA=UNAVAILABLE
  0.0%`) apesar de `[AI] GATEWAY` responder 1122 B. Suspeita: cadencia do
  backend/modelo, nao do EA. Medir `as_of` devolvido pelo gateway antes de mexer.

### Verificacao pos-deploy 21:05-21:07 (ciclo 101) `AGENTE`
- **P1.101 corrigido e deployado (v1.2.143).** `AI\AIConnector.mqh` deixou de
  limpar o estado global de IA quando a leitura vencida e de OUTRO simbolo
  (`bool estadoEhDoSimbolo = (AI_Symbol=="" || AI_Symbol==esperado);`); o
  `return false` continua fora da guarda, logo o simbolo pedido segue bloqueado
  com `AllowTradeWithoutAI=false`. Fechar quando aparecer a primeira
  `[AI] PREDICAO VENCIDA` de um simbolo sem modelo SEM que o `[RESUMO]` perca a
  previsao do XAUUSD.
- **`[AI] LOAD ... ROOT=LOCAL` nao e defeito.** A leitura tenta LOCAL primeiro e
  COMMON como fallback (tester tem `MQL5\Files` proprio). Em producao o pipeline
  escreve em `<terminal>\MQL5\Files\Data\prediction_<SIMBOLO>.json`, portanto
  LOCAL e o caminho saudavel; `ROOT=COMMON` so aparece no backtest.
- **Candidato P1.102:** o `[RESUMO]` da instancia master publica o estado de IA
  do simbolo DONO do grafico (USDJPY -> `IA=UNAVAILABLE 0.0%`) e nao o do par
  negociado (XAUUSD -> SELL 79.30%). Nao bloqueia nada, mas le-se como alarme
  falso; medir antes de mexer no texto.
- **P-02 continua aberto (DONO):** job do Testador iniciado 20:26:22 com
  `v1.2.138` (pre-fix). `tester_stop`, `tester_get_status` e
  `tester_get_configuration` exigem um `run_id` que o terminal nao fornece e
  `tester_list_result_windows` = []. So o dono para pela aba Testador; depois
  re-medir com `Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini`.
- **P1.100 ainda nao exercitado ao vivo:** o ramo `status > 599` (resposta
  NAO-HTTP do transporte) so imprime quando houver um codigo fora da faixa HTTP.

### Verificacao pos-deploy 21:16 (ciclo 102) `AGENTE`
- **P1.102 corrigido e deployado (v1.2.144).** O throttle por conta estava
  furado porque o Strategy Tester gravava o tempo SIMULADO do backtest em
  `Common\Files\XAU_AI_PRO\loggate_<tag>.bin` (medido: `2026-09-09 20:00:00`
  contra `2026-11-04 21:14:38`). Com um valor no passado a condicao
  `agora >= ultimo + janela` e sempre verdade. Agora o tester devolve `true` e
  nao escreve nos ficheiros partilhados. **Fechar** quando o P-02 fechar e se
  confirmar 1 linha de `[AI] PREDICAO VENCIDA` por hora (e nao por poll).
- **Efeito pleno depende do P-02.** O job de 20:26:22 corre a v1.2.138 ja
  carregada em memoria; recompilar nao o altera e ele continua a escrever nos
  gates ate terminar.
- **Candidato P1.103 (medido):** quando uma consulta ao gateway falha, o EA cai
  para `Data/prediction_<SIMBOLO>.json`, que em producao esta parado desde
  ~19:28 (`AGE=6090 s` as 21:09), e publica `IA=UNAVAILABLE` durante o ciclo de
  poll mesmo com o gateway vivo (sonda das 21:12: `available=true`). Fail-closed
  esta correto; o que se deve medir e a frequencia das falhas de transporte
  antes de trocar o fallback por "reter a ultima previsao fresca".
- **Candidato P1.104:** o `[RESUMO]` mostra o estado de IA do simbolo dono do
  grafico master (USDJPY -> `IA=UNAVAILABLE 0.0%`) e nao o do par negociado
  (XAUUSD -> SELL 79.30%). Texto, sem efeito de trading, mas le-se como alarme.

### P1.101 FECHADO - prova de campo 21:16:29-21:17:01 (v1.2.144) `AGENTE`
- **Antes da correcao:** `[AI] GATEWAY | XAUUSD | 1122 bytes` +
  `[AI] PYTHON | XAUUSD | SELL` seguidos de `IA=UNAVAILABLE 0.0%` no `[RESUMO]`,
  porque a leitura vencida de OUTRO simbolo chamava `ResetAIState()` (slot unico).
- **Agora, medido no journal:** `21:16:29.446 [AI] PREDICAO VENCIDA | USDCNH |
  AGE=154128s > LIMIT=900s` (simbolo sem modelo, ficheiro local obsoleto) e, na
  MESMA instancia `(USDJPY,H1)`, `21:16:36.648 [AI] GATEWAY | XAUUSD | 1123
  bytes` + `[AI] PYTHON | XAUUSD | SELL | PRICE=4066.850 | CONF=73.60%` e
  `21:17:01.601 [AI] PYTHON | XAUUSD | SELL | PRICE=4068.45 | CONF=79.30%`.
- Ou seja: a leitura vencida de USDCNH deixou de apagar a previsao fresca de
  XAUUSD. Zero `PRICE=0.00000` e zero `IA=UNAVAILABLE` na janela.
- **Criterio cumprido.** O simbolo pedido continua bloqueado quando a SUA
  leitura esta vencida (`return false` fora da guarda), como antes.

### Ciclo 103 - P1.103 fechado no codigo, P-03/P-04 aguardam decisao do dono `AGENTE`
- **P1.103 corrigido e deployado (v1.2.146).** Ver `Docs/CONVERSA_20261105_P1103_V1146.md`.
  **Fechar** quando aparecer uma falha de transporte e o `[RESUMO]` mantiver
  `IA=SELL` em vez de cair para `UNAVAILABLE`.
- **P-03 (`DailyProfitTargetUsd 20` vs `DailyProfitTargetMaxUsd 40`) - `DONO`.**
  Nao e bug de codigo: sao dois limites com semantica diferente (alvo diario e
  teto do alvo). O que falta e a DECISAO de qual valor manda no dia; qualquer
  alteracao muda o comportamento de fecho e nao foi feita.
- **P-04 (`StoplessEmergencyPoints=0`) - `DONO`.** Com 0, uma posicao que fique
  sem stop por falha de modificacao nao tem rede de seguranca em pontos. Ligar
  isto protege a posicao mas pode fechar antes do plano; e decisao de risco.
- **P-02 continua a bloquear a medicao.** O job do Testador (v1.2.138) tem de
  ser parado na GUI antes de correr `XAI_V12135_PRODGEOM_RT_M15.ini`.

### Ciclo 104 - autoupdate entregue (opcao 1); opcao 3 continua recusada `AGENTE`

- **Entregue:** `Tools\auto-deploy.ps1` - gate HG-01/HG-02 -> compilar -> exigir
  `0 errors` -> provar que o `.ex5` existe e e mais recente que as fontes ->
  imprimir o reattach MCP. Com `-Commit` faz commit+push. Documentado em
  `Docs/AUTODEPLOY.md`.
- **Recusado sem confirmacao:** opcao 3 (o EA substituir o proprio binario a partir
  de git/HTTP). Se for pedida, entra como **P-06** com hash/assinatura e trava de
  seguranca; um EA que se auto-substitui e superficie de ataque.
- **P-02 continua `DONO`:** o tester segue ocupado com o job de 20:26:22 (v1.2.138).
- **P1.103 nao exercitada em falha real:** a correcao so actua quando o transporte
  do gateway falha. Teste pendente: parar o gateway e confirmar que `[RESUMO]` mantem
  `IA=SELL` em vez de cair para `UNAVAILABLE`. Se cair, a P1.103 nao esta a funcionar.
- **Novo P-07 `AGENTE`:** o perfil `XAI_P216_LIVE` tem 14 `.chr` mas 15 instancias a
  correr (USDCLP e USDCOP nao estao no perfil em disco). Um `profile_add` a seguir a
  este estado gravaria o que esta em memoria e alinharia os dois. Nao feito neste
  ciclo para nao reescrever o perfil sem o dono ver.
- **`chart14.chr` sem EA - deliberado:** segundo grafico `XAUUSD,H1` do mesmo perfil.
  Se lhe fosse anexado o EA com o mesmo `MagicNumber 2026001` abriria posicoes
  duplicadas no mesmo simbolo.
- **origin (forge.mql5.io) com credenciais expiradas:** `git push origin main`
  devolve `Authentication failed`. So o dono renova.
- **`list_open_charts` nao conta graficos:** devolveu 14 janelas quando estavam 15
  instancias activas. Para contar instancias, usar `get_expert_journal filter=[START]`.

### Ciclo 105 - P1.102/P1.105/P1.106 fechados no codigo (v1.2.147) `AGENTE`

Tres leituras do journal que mentiam. Todas de observabilidade; nenhum limite,
lote, alvo, stop, spread, preco ou regra de entrada/saida foi tocado.

- **P1.102 FEITO no codigo - `[RESUMO]` lia o estado do ultimo simbolo visitado.**
  MEDIDO no journal de 04/11 as 21:27:55: a instancia `(USDJPY,H1)` escreveu
  `[AI] PYTHON | XAUUSD | SELL | CONF=76.80%` e as 21:28:00 o `[RESUMO]` da MESMA
  instancia publicou `IA=UNAVAILABLE 0.0%`. Causa: o pipeline do master percorre
  11 simbolos por volta e `AI_Symbol`/`AI_Signal` sao um slot UNICO, logo as
  recusas seguintes (EURUSD...USDCNH) faziam `ResetAIState()` e o resumo lia o
  ultimo visitado, nao o par dono do grafico.
  Correcao em `AI\AIConnector.mqh`: cache `g_aiState*` de 32 slots +
  `AIRecordState()` / `AIStateForSymbol()`, escrita no sucesso e na recusa.
  `Monitoring\OperatorBrief.mqh` passa a ler o simbolo do grafico e a mostrar a
  idade (`IA=SELL 76.8% (ha 12s)`); se nao houver entrada, cai para o slot global
  com `(ultimo <SIMBOLO>)`. A cache e **so de leitura** para o resumo: nao entra em
  decisao nem altera portao nenhum.
  **Fechar** quando o journal mostrar `[RESUMO] ... IA=<estado do simbolo do
  grafico> (ha Ns)` numa volta com 11 simbolos, incluindo os recusados.
- **P1.105 FEITO no codigo - `[AI] GATEWAY` dizia bytes e nao o que aquilo era.**
  MEDIDO: 55 linhas `[AI] GATEWAY | <simbolo> | H1 | 357 bytes` no dia, todas
  recusas do walk-forward; o `MOTIVO=` so saia 1x/hora na linha `INDISPONIVEL`,
  deixando o resto a ler-se como avaria. Agora a linha leva
  ` | disponivel=true/false`, sem repetir o motivo (o throttle do `INDISPONIVEL`
  continua igual).
- **P1.106 FEITO no codigo - delta de contadores negativo.** MEDIDO as 18:13:56:
  `[SCANNER] RESUMO | ... | ADX(sem/ok)=-2951/-29135` quando o modulo de ADX
  recriou os contadores no reattach e o baseline publicado sobreviveu. `MaxInt0()`
  em `Core\MarketScanner.mqh` poe o delta a 0; o baseline e reescrito logo abaixo
  com o valor actual, logo so a linha daquela janela era afectada.
- **Build e validacao:** `0 errors, 0 warnings`, 19314 ms; `.ex5` 877 320 B as
  21:48:35, mais recente que `XAU_AI_PRO.mq5` (21:48:15);
  `validate_mql5.py` `[OK]`; `pytest tests/test_mql5_compila.py` 2 passed.
  Versao tripla coerente: header `v1.2.147`, `#property version "1.347"`,
  `EA_VERSION_STRING "1.2.147"`.
- **NAO reanexada nesta sessao:** nao ha ferramentas MCP `metatrader5`/`tester`
  neste ambiente, logo a producao continua em `v1.2.146`. Fechar em runtime
  exige reattach pelo dono (ou por um agente com `profile_apply`) e confirmar
  as tres linhas novas no journal.
- **P-02 continua `DONO`:** o slot do Strategy Tester tem de ser libertado
  (Stop na aba Testador) antes de correr `Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini`.
  Sem esse job nao ha numero novo de PF, e sem PF > 1.20 a conversa sobre conta
  real nao avanca.
- **P-07 continua aberto:** `profile_apply`, quando for feito, e a altura certa
  para alinhar `XAI_P216_LIVE` (14 `.chr` em disco) com as 15 instancias activas.
- **origin sem credenciais:** `git push origin main` continua a falhar; so o dono
  renova. O remoto `github` nao foi tocado.
- **Documentacao:** `Docs/CONVERSA_20261105_CICLO105_V1147.md`.

### Ciclo 106 - [SCANNER] Stale USDBRL encerrado como comportamento correcto `AGENTE`

- **Nao e defeito.** `SymbolDataFresh()` (`Core/MarketScanner.mqh:381`) comparou a idade do ultimo tick com `MaxSymbolTickAgeSec=900` e recusou USDBRL com 14 325 s. A idade foi provada exacta ao segundo contra o `update_time` do Market Watch (`2026-11-04 22:59:59` servidor = 17:59:59 de Brasilia, fecho do onshore BRL). Censo no mesmo instante: 12 pares liquidos vivos ao segundo, USDBRL/USDCOP/USDCLP/USDRUB mortos por sessao fechada. Fechado sem alteracao de codigo, risco ou versao.
- **Volume aceitavel:** 8 linhas de detalhe em 3h43m. Balde Stale so reimprime quando o desfecho muda e passa por `AccountLogGatePodeImprimir("scanblock_<simbolo>_Stale", 1800)`.
- **Recusado por falta de razao medida:** alterar o texto "preco morto"; retirar os exotcos da lista `Symbols`; mexer em `MaxSymbolTickAgeSec`. Qualquer um deles e decisao do dono.
- **Novo P1.107 `AGENTE` (por decidir):** o `[RESUMO]` do master nomeia o valor da IA mas nao o simbolo. Medido: master USDJPY publica `IA=UNAVAILABLE 0.0%` enquanto o XAUUSD tem `SELL 55.70%`. O P1.102 tornou o valor honesto; falta o sujeito. Proposta minima `IA(%s)=%s` com `_Symbol`, exige versao nova.
- **v1.2.147 em producao** desde as 22:05:34 (15 simbolos). O ciclo 105 tinha deixado a build compilada mas nao reanexada; agora esta deployada, verificada e commitada.

### Ciclo 107 - P1.107 fechado, v1.2.148 em producao `AGENTE`
- **Fechado.** O `[RESUMO]` passou a publicar `IA(<SIMBOLO>)=<sinal> <conf>%` lendo `_Symbol`. O defeito era o sujeito em falta, nao o valor: o master e o grafico `USDJPY`, sem modelo publicado, logo `UNAVAILABLE` estava certo e o texto mentia por omissao. Provado em runtime com `IA(USDJPY)=UNAVAILABLE 0.0%` as `22:39:55.403`.
- **Build.** `v1.2.148`, `.ex5` `877132 B` as `22:39:24`, `0 errors, 0 warnings`, 15 graficos reanexados.
- **Recusado.** `Error=4022` (aquecimento P2.17, 10 linhas nos 7 s pos-reanexacao); texto `preco morto` (fail-closed correcto, ciclo 106); mojibake cosmetico em `AIConnector.mqh` e documentos antigos.
- **Aberto - P1.103 por exercitar ao vivo.** Parar o gateway e confirmar que o `[RESUMO]` mantem o ultimo `IA=SELL` em vez de cair para `UNAVAILABLE`. Requer parar o processo Python: acao do dono ou autorizacao explicita.
- **Aberto - P-07.** `XAI_P216_LIVE` tem 14 `.chr` no disco mas 15 instancias a correr; `USDCLP` e `USDCOP` nao estao no perfil gravado. Reanexar resolve em memoria, mas o proximo `profile_apply` volta a deixar 13/14.
- **Aberto - P-05.** `git push origin main` continua a falhar (`Credentials are incorrect or have expired` em forge.mql5.io). `github/main` sincronizado.
- **Aberto - P-02 (DONO).** Testador ocupado desde 20:26:22 por job v1.2.138; `tester_list_result_windows` devolve `{"windows":[]}`. Falta correr `Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini` e trazer PF + perdas seguidas.
### Ciclo 108 - GitHub 10/10 nos dois repositorios `AGENTE`
- **Fechado.** `mql5` passou de 19 para **0** alertas de code scanning e de 1 para **0** Dependabot; `XAU_AI_PRO` passou de 1 para **0** code scanning e manteve 0 Dependabot. Provas locais: `npm audit` 0, `npx eslint .` exit 0, `test_cors_allowlist.py` 5 passed, `test_gateway_endpoints.py` + `test_fastapi_auth.py` 53 passed, `validate_mql5.py` [OK].
- **Corrigido no codigo, nao suprimido.** `permissions: contents: read` em `ci.yml` (#3, #9) e `_cors_origin` removendo CR/LF antes da allowlist (#25, #26). Overrides npm: `qs 6.16.1`, `minimatch 11.0.4`.
- **Dismissals com motivo escrito.** 15 no `mql5` (#10-#19 risco aceite, #20 DPAPI, #21 deserializacao com 3 defesas, #22-#24 HMAC de exchange) e 1 no app (DPAPI). A supressao inline `# codeql[...]` **nao funciona** aqui - a via efectiva e a API, com limite de **280 caracteres** por comentario.
- **Deployments.** `XAU_AI_PRO` de 25 para 2 (ambos success). O `6688904` e o deployment activo do environment `github-pages` e nao pode ser apagado enquanto for o unico activo (HTTP 422) - nao e um falhado antigo.
- **Aberto - conta REAL.** Continua recusada por medicao: PF 0,92, 641 trades, -58,14 USD, DD 143,70% contra criterio PF > 1,20 e DD <= 5%. `EnableRealAccountGuard` e `AllowTradeWithoutAI=false` intocados.
- **Aberto - P-02 (DONO).** Slot do Strategy Tester ocupado; sem run novo nao ha PF novo.
- **Aberto - reattach v1.2.149.** Sem ferramentas MCP `metatrader5`/`tester` nesta sessao; producao segue no build anterior em memoria.
- **Aberto - P-05.** `origin` (forge.mql5.io) com credenciais expiradas; so o remoto `github` sincroniza.
- **Documentacao.** `Docs/CONVERSA_20261105_CICLO108_GITHUB_ZERADO.md`.

---

## CICLO 108 - novas pendencias tecnicas

### P1.110 - ABERTO - o simbolo do grafico ainda le a serie de outro par (intermitente, por instancia)
Medido 3 minutos depois do deploy da v1.2.150, mesma barra 03:00 do servidor:

```
2026.11.05 03:00:00,USDJPY,...,0.182,30.02728040685277,41.40582173222608,...   <- correto
2026.11.05 03:00:00,USDJPY,...,28.369,33.26630490148689,0.0,...               <- XAUUSD
2026.11.04 22:59:55.519 XAU_AI_PRO (USDJPY,H1) [CENARIO] USDJPY | VOLATILIDADE_ALTA | ADX=33.3 | ATR%=18.38
```

O valor 33.26630490148689 e identico ao da linha XAUUSD da mesma barra, logo a
leitura de um simbolo estrangeiro foi servida pela serie do simbolo do grafico em
pelo menos uma instancia. Efeito: cenario, lote (x0.60) e alvo (x1.15) decididos
com a volatilidade do ouro.
Proximo passo: gravar a identidade da instancia (simbolo do grafico) numa coluna
propria do dataset para identificar QUAL instancia erra, ou recusar a gravacao
quando o ATR lido for incompativel com a escala do simbolo.

### P1.111 - ABERTO - varias instancias escrevem o mesmo dataset.csv sem sincronizacao
```
...42.6676916264
6481,0.002098819455872317,...        <- linha partida
2026.11.05 02:00:002026.11.05 03:00:00,EURUSD,...   <- duas linhas coladas
```
Um consumidor do CSV pode ler o OHLC de um simbolo com os indicadores de outro.
Correcao recomendada (muda o contrato do pipeline): um ficheiro por instancia
(`dataset_<simbolo>.csv`) ou um unico escritor. Requer decisao do dono.
