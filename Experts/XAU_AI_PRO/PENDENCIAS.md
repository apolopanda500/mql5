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

## P1.116 — FECHADO POR MEDICAO (05/11/2026, v1.2.156) — `[CENARIO] ATR%=sem leitura`
Medido em 04/11 as 23:45:11 e 23:51:42 (build v1.2.154): `[CENARIO] XAUUSD |
TENDENCIA_FORTE | ADX=33.8 | ATR%=sem leitura` e `[CENARIO] USDCNH |
TENDENCIA_FORTE | ADX=26.8 | ATR%=sem leitura`, enquanto EURUSD/GBPUSD/USDJPY/
NZDUSD/USDCAD/USDCHF publicavam 0.10-0.17 na mesma janela. A sonda
`XAI_AtrDiag`, as 23:50:44, leu o ATR dos dois no mesmo segundo
(29.543571 e 0.002889, `copy=1 err=0`), logo o zero vem do getter do EA.
`GetATR(string)` em `Indicators/VolatilityFilter.mqh` tem tres saidas
silenciosas: `XAI_SymbolDataReady` falso, handle invalido, e `CopyBuffer` sem
barras. A v1.2.155 instrumentou as tres com `ATRLogNoRead` (portao por conta,
1 linha/hora/simbolo).
MEDIDO no reload dos 13 graficos as 13:53:25.943 de 05/11: 13 linhas em 240
ms, uma por grafico, ramo 3 de 3: `CopyBuffer sem barras | barsCalc=-1 |
erro=4807` em todos os 13. Os outros dois ramos nunca dispararam neste dia. Causa nomeada, nao suposta — e a partir dai corrigida no P1.117.
## P1.117 — FECHADO POR MEDICAO (05/11/2026, v1.2.156) — `ATRCacheDrop()` nunca era chamado
Causa do P1.116: `void ATRCacheDrop(string symbol)` estava escrito em
`Indicators/VolatilityFilter.mqh` e tinha ZERO chamadas no projecto, e o
comentario que prometia a chamada estava cortado a meio da frase. A guarda de
plausibilidade do P1.112 detectava a troca de serie, escrevia a linha e
devolvia 0.0 sem deitar a entrada fora — o handle envenenado ficava na cache
para sempre e o par nunca sarava (medido as 13:55:06.580: `[CENARIO] USDCNH |
ATR%=sem leitura` horas depois do reload).
Correcao: `ATRCacheDropAllowed()` (portao por simbolo de 60 s,
`ATR_DROP_GATE_SEC`, sobre `g_atrDropSymbol`/`g_atrDropStamp`) e
`ATRCacheDrop(symbol)` chamado no ramo de leitura suspeita antes do
`return 0.0`. O portao existe para nao repetir o P1.108: sem ele, um par
cronicamente mal servido entraria em ciclo criar/libertar e o indicador nunca
aqueceria. A linha `[ATR] LEITURA SUSPEITA` passa tambem a publicar
`barsCalc`, `barrasSerie` e `barrasGrafico`, para a proxima medicao PROVAR a
troca de serie pelo numero de barras em vez de a inferir pela magnitude.
MEDIDO no reload dos 13 graficos as 15:12:30-15:13:07 de 05/11 (build v1.2.156,
commit c54f0983): 12 linhas `[ATR] SEM LEITURA` entre 15:12:30.864 e
15:12:33.966, todas `CopyBuffer sem barras | barsCalc=-1`, 10 com `erro=4807` e
2 com `erro=4022` (as duas do grafico USDBRL,M5). Depois de 15:13:07.936 nao
houve mais NENHUMA linha `[ATR]` na janela: zero `[ATR] LEITURA SUSPEITA` e
zero repeticao a cada 3600 s. Provado: a correcao nao introduziu regressao e o
ruido de ATR continua a ser apenas o do instante do attach. NAO exercitado
nesta janela: o ramo de queda (`ATRCacheDropAllowed` -> `ATRCacheDrop`) nunca
disparou, porque nenhuma leitura suspeita ocorreu em ~2 minutos de vida. Fica
`FECHADO no codigo` com prova de ausencia de regressao, nao com prova de queda
em producao.
CORRECAO a esta leitura (15:14, mesma sessao): a etiqueta `[ATR]` ficou muda,
mas o SINTOMA nao fechou. O `[CENARIO]` continuou a publicar `ATR%=sem leitura`
depois do reload - 15:14:08.104 `RETRATO ... XAUUSD ... ATR%=sem leitura`,
15:14:25.153 `[CENARIO] XAUUSD | ADX=25.8 | ATR%=sem leitura` e 15:14:47.034
`[CENARIO] USDCNH | ADX=51.6 | ATR%=sem leitura`, as tres a sair do grafico
`USDCNH,H1`. O P1.117 fecha o caminho da leitura SUSPEITA (valor absurdo,
guarda do P1.112), nao o caminho da leitura que NAO CHEGA (`CopyBuffer` sem
barras devolve 0.0 sem valor, logo nunca acciona a guarda nem o ATRCacheDrop).
Essa metade e o P1.118 - o handle que nunca aquece - corrigido na v1.2.157.

ABERTO e nao explicado: `[ATR] LEITURA SUSPEITA | USDBRL | ATR=3908.848300 |
preco=5.5123 | ATR%=70911.39` (13:53:26.183). A magnitude nao e o ouro nem o
proprio par; fica a espera de medicao com `barsCalc`/`barrasSerie`.

## P1.118 - FECHADO NO CODIGO E MEDIDO EM PRODUCAO, MAS NAO CURA (05/11/2026, v1.2.157) - o handle que nunca aquece
Sintoma medido na MESMA sessao do fecho do P1.117 (build v1.2.156, commit
c54f0983): a etiqueta `[ATR]` ficou muda depois de 15:13:07.936, mas o
`[CENARIO]` continuou a publicar `ATR%=sem leitura` as 15:14:08.104
(`[CENARIO] RETRATO | simbolos=11 | XAUUSD TENDENCIA_FORTE ADX=25.8
ATR%=sem leitura`), 15:14:25.153 (`[CENARIO] XAUUSD | TENDENCIA_FORTE |
ADX=25.8 | ATR%=sem leitura | tendencia=RANGING`) e 15:14:47.034
(`[CENARIO] USDCNH | TENDENCIA_FORTE | ADX=51.6 | ATR%=sem leitura |
tendencia=RANGING`), as tres a sair do grafico `USDCNH,H1`.
Causa: no ramo `CopyBuffer sem barras` a funcao devolve `0.0` sem valor
nenhum, logo nem a guarda de plausibilidade do P1.112 nem o `ATRCacheDrop` do
P1.117 sao accionados. O handle que nunca aqueceu (`barsCalc=-1`, `erro=4807`
no attach) fica na cache para sempre e o par nunca sara. O P1.117 curava a
leitura SUSPEITA (valor absurdo), nao a leitura que NAO CHEGA.
Prova de que o dado existe: sonda `XAI_AtrDiag` as 15:18:10, no MESMO grafico
`USDCNH,H1`, com handle NOVO: `XAUUSD copy=1 atr=22.476429 atrPct=0.5485
bars=60369` e `USDCNH copy=1 atr=0.002087 atrPct=0.0313 bars=66887`. O ATR
nao faltava na serie, faltava no handle.
Correcao (v1.2.157): marca de primeira falha por simbolo (`ATRStaleSlot`,
`ATRStaleExpired`, `ATRStaleClear`) com `ATR_STALE_RECREATE_SEC=180`; so depois
de 180 s da MESMA falha a entrada sai da cache (`ATRCacheDrop`) e se escreve
`[ATR] HANDLE MORTO`. Uma leitura com sucesso limpa a marca, logo um handle que
aquece tarde nunca e deitado fora. Respeita o P1.108: nao se liberta no
primeiro `CopyBuffer` falhado. Nenhum limite, lote, alvo, stop, spread, preco
ou regra de entrada/saida foi alterado. HG-01 fechado: `#property version
"1.357"` <-> `EA_VERSION_STRING "1.2.157"`; compilado 0 errors, 0 warnings
(build 6296, X64 Regular).
FALTA MEDIR (nao esta fechado): reload dos 13 graficos com v1.2.157 e, na mesma
sessao, (a) `[ATR] HANDLE MORTO` aparece UMA vez por simbolo recalcitrante,
(b) `[CENARIO] ATR%=sem leitura` DESAPARECE da janela - a medicao de fecho tem
de correr sobre a etiqueta do sintoma, nao sobre a etiqueta do diagnostico,
(c) nenhum par que aquece normalmente perde o handle.

MEDIDO EM PRODUCAO com a v1.2.157 (o .ex5 gerado as 15:19 ja estava nos graficos
antes deste fecho): 28 `[START] XAU_AI_PRO v1.2.157` as 15:19:59.004-15:19:59.058
(15 graficos) e 15:20:09.339-15:20:09.369 (13 graficos). Entre 15:23:14.590 e
15:25:01.819 sairam 11 linhas `[ATR] HANDLE MORTO`, UMA por simbolo - USDBRL,
USDCNH, USDCHF, USDCAD, AUDUSD, USDJPY, GBPUSD, USDSEK, NZDUSD, USDCZK, USDSGD -
todas com `sem barras ha 180 s | barsCalc=-1 | erro=4807 | entrada removida da
cache`. O P1.118 faz exactamente o que foi desenhado: dispara so depois dos
180 s da MESMA falha, remove a entrada e o portao de 3600 s garante uma linha
por simbolo por hora.
O QUE NAO CURA: as 15:28:14.015 e 15:28:35.864 o grafico `USDCNH,H1` ainda
publicava `[CENARIO] XAUUSD | ... | ATR%=sem leitura` e `[CENARIO] USDCNH | ...
| ATR%=sem leitura`. E, depois de limpar os gates de log
`Common\Files\XAU_AI_PRO\loggate_atr_no_read_*.bin` (estado de log, nao de
trading), as 15:31:05.262-15:32:11.607 sairam 12 `[ATR] SEM LEITURA | <par> |
CopyBuffer sem barras | barsCalc=-1 | erro=4807 | grafico=<o proprio par>` -
ou seja o ramo esta nomeado e e o mesmo em todos os 13 graficos, mesmo DEPOIS
do drop e da recriacao. O handle NOVO volta a ficar em `barsCalc=-1` com
`erro=4807`. O drop/recreate e necessario e insuficiente: nasce o P1.119.
## P1.123 - RESOLVIDO EM CODIGO (05/11/2026, v1.2.161) - as 24 horas sem entrada eram churn de handles no SignalCore

### O que estava medido antes de mexer
Janela 04/11 19:00 -> 05/11 19:40, grafico mestre USDCNH:

| Medida | Valor |
|---|---|
| Abrir posicao | 0 posicoes, 0 ordens |
| Ultima entrada do EA | 04/11 02:00:05 USDCAD |
| `[SIGNAL] BUY` | 13 linhas |
| `[SIGNAL] SELL` | 28 linhas |
| `[SCANNER] SIGNAL OK` | 60 linhas (truncado em 60) |
| Entradas | **0** |

Ou seja: o sinal nao estava morto. O que estava morto era o que vem depois dele.

### A prova que fechou o caso
O journal repetiu o MESMO valor de EMA200 para cinco simbolos diferentes dentro da mesma hora:

| Hora | Simbolo | EMA lida | bid |
|---|---|---|---|
| 16:00:33 | AUDUSD | 44.60460 | 0.69415 |
| 16:15:03 | USDJPY | 44.60460 | 157.78500 |
| 16:40:45 | GBPUSD | 44.60460 | 1.34477 |
| 16:41:23 | USDCAD | 44.60460 | 1.39972 |
| 16:55:46 | EURUSD | 44.60460 | 1.12255 |

E, ao longo do dia, a mesma "EMA" subiu e desceu como um oscilador 0-100:
26.80 -> 29.23 -> 31.51 -> 33.82 -> 34.68 -> 38.33 -> 39.34 -> 42.79 -> 44.60 -> 47.51 -> 49.71 -> 51.61 -> 44.60 -> 43.87.
Nenhum par cotado entre 0.69 e 157 tem EMA200 em 44.6. A familia de valores e RSI/ADX.

Tambem apareceram valores da familia ATR (`EMA=0.00209` XAUUSD, `0.00214` USDCNH,
`0.00180` GBPUSD, `0.00163` EURUSD) e o ADX do proprio simbolo do grafico saiu
como `0.00` (`[VALIDATION] USDCNH | ADX=0.00 | Min=18.00` -> `BLOCK | ADX`).

### A causa
`Core/SignalCore.mqh` criava TRES handles (`iMA` x2 + `iRSI`) e chamava
`IndicatorRelease` nos tres, na MESMA leitura, para cada um dos 11 simbolos, a cada
ciclo de scan: ~33 criacoes/destroicoes por ciclo. O terminal reaproveita os slots
numericos libertados, e um handle de vida longa - EMA de tendencia, ADX, ATR, todos em
cache desde a P1.85 / P1.108 / P1.113 - passa a apontar para o slot de um indicador de
OUTRO tipo.

### O efeito em cadeia (todos medidos)
1. `TrendBuy`/`TrendSell` liam lixo -> `ScenarioTrendGate` respondia **contramao** a todos os sinais:
   `TREND SELL | USDCAD | contramao vetada | tendencia formada | ADX=43.7 >= 22.0`
   `TREND SELL | USDSEK | contramao vetada | tendencia formada | ADX=36.9 >= 22.0`
   `TREND BUY  | USDJPY | contramao vetada | tendencia formada | ADX=31.3 >= 22.0`
   `TREND BUY  | USDCNH | contramao vetada | ADX indisponivel`
2. `AVOID HOUR` fechava GMT 18 (`GMT=18h | lista=9,11,14,18,20,22`) - 25% do dia em 6 horas.
3. `BLOCK | AI` apareceu em USDCAD/USDSEK (14:54).
4. `BLOCK | ADX` quando o ADX do proprio grafico lia 0.00.

O `[ADV AI]` nao imprimiu uma unica linha em 24 h: `FinalAIAllow` nunca chegou a ser
chamado, logo o veto da IA NAO era o bloqueio visivel nesta janela.

### Correcao aplicada (v1.2.161)
`Core/SignalCore.mqh`: cache de handles por simbolo (`SIG_CACHE_MAX 64`), criados
uma vez com `XAI_WaitSeriesReady`, descartados quando a copia falha (o par sara
sozinho), libertados no `OnDeinit` por `ReleaseSignalHandles`. Desenho identico ao
que ja funciona no ADX (P1.85), no ATR (P1.108/P1.118) e na EMA de tendencia (P1.113).

Nada mais mudou: nenhum limite, regra de entrada/saida, lote, alvo, stop, spread ou RR.
Compilado 0 errors / 0 warnings; `XAU_AI_PRO.ex5` 913720 B as 19:53:30.

### O que falta para provar em producao
Sem reload autorizado os 13 graficos continuam na v1.2.159 e o defeito continua vivo.
Depois do reload, a prova e uma destas duas:
- `[TREND] LEITURA SUSPEITA` deve cair para ~0 por hora (eram ~20/h);
- `[VALIDATION] BLOCK | TREND ...` deve deixar de dizer "contramao" em todos os sinais.

Se a contramao PERSISTIR depois do reload, entao a EMA esta certa e o problema e a
propria regra: o sinal pede pullback (preco abaixo da EMA200) e o gate veta pullback.
Nesse caso a decisao e do dono, nao do codigo.

---

## P1.125 - RESOLVIDO EM CODIGO (05/11/2026, v1.2.162) - o gate da IA nao podia ser satisfeito por nenhum simbolo
**CONFIRMADO EM PRODUCAO (05/11/2026, reload das 20:05:04, 13 graficos a v1.2.162).** O teto deixou de fechar o gate por si. No periodo 20:05-20:39 sairam 12 linhas `[SCANNER] SIGNAL OK` (USDCAD e USDSEK, sempre Signal=-1, todas na instancia mestre USDCNH,H1) e ZERO linhas `[VALIDATION] AI OK` - mas agora cada bloqueio tem causa nomeada: USDSEK fecha no gate de IA porque o gateway responde `disponivel=false` (sem leitura real, o cap de 40 continua a valer, logo o gate continua fechado, que e o comportamento pedido), e o USDCAD fecha ainda antes disso no TREND (`contramao vetada | tendencia formada | ADX=57.8 >= 22.0`, com o retrato a publicar `USDCAD TENDENCIA_FORTE ADX=57.8 TREND_UP`, ou seja um SELL contra a tendencia). O XAUUSD tem `disponivel=true` no gateway e nao gerou sinal no periodo. Zero posicoes e zero ordens na conta.

### O que estava medido antes de tocar em nada

| Medicao (05/11/2026) | Resultado |
|---|---|
| `[VALIDATION] BLOCK | AI` | 25 linhas, fila de AUDUSD (01:00-02:55), USDJPY (02:40-04:07), NZDUSD (05:35), USDCAD e USDSEK (14:54) |
| `AI OK` | 0 linhas |
| `[ADV AI] BLOQUEADO / Score` | 0 linhas |
| sonda ao gateway 9011 | 401 no root e nos 11 simbolos, token ausente |

### Causa, por leitura do codigo

`AI/AIEngine.mqh`:

```mql5
bool AIGateRequired()
{
   if(!EnableAIFilter)          return(false);
   if(EnableAutonomousMode)     return(false);
   return(!AllowTradeWithoutAI);
}
```

Com os inputs dos 13 graficos (`EnableAIFilter=true`, `EnableAutonomousMode=false`,
`AllowTradeWithoutAI=false`) o gate e obrigatorio, e entao `GetAIConfidence` fazia:

```mql5
if(AIGateRequired())
   score = MathMin(score, AIUnavailableConfidenceCap);   // 40.0
```

`40 < MinAIConfidence (60)`, logo `AITradeAllowed()` devolvia `false` no ramo
`confidence<MinAIConfidence` em **todas** as chamadas: com gateway a responder score
95, com gateway a responder 401, ou sem gateway nenhum. O teto era aplicado exactamente
no modo em que a IA e obrigatoria, quando o texto do `Config.mqh` manda capar o
**fallback** (o numero de indicador com nome de IA), nao a leitura real.

Segundo gate, independente e igualmente fechado: `FinalAIAllow()` recusa quando
`LoadAIPrediction` devolve `UNAVAILABLE`/`ERROR` - e com 401 e `AIGatewayToken` vazio e
sempre `UNAVAILABLE`. Nao chegou a imprimir nada porque o primeiro gate barra antes.

### Correcao

`GetAIConfidence` passa a marcar `aiReal = (LoadAIPrediction(symbol) && AI_Signal!="UNAVAILABLE")`
e o teto passa a valer so quando `aiReal` e falso:

```mql5
if(!aiReal)
   score = MathMin(score, AIUnavailableConfidenceCap);
```

Com IA real o score vale o que medir; sem IA o score continua capado em 40 e o gate
continua fechado - que e o comportamento pedido em 23/10/2026, quando se descobriu que
50+15+10+10 passava o piso sem nenhum modelo responder.

Nenhum limite, lote, alvo, stop, spread, RR, regra de entrada ou de saida mudou.

### O que continua ABERTO (decisao do dono, nao do codigo)

O EA continua **sem poder abrir posicao em nenhum simbolo** enquanto o gateway
responder 401 e `AllowTradeWithoutAI=false`. Sao precisos dois passos, nesta ordem:

1. **Token** - o gateway exige `Authorization: Bearer`; sem token nao ha leitura real e
   o gate fica fechado por desenho (`IA real: veta e exige gateway`).
2. **Decisao explicita** sobre `EnableAutonomousMode=true` (IA consultora, deixa de
   vetar e de exigir disponibilidade) - muda a regra de entrada, portanto nao foi
   alterado por iniciativa propria.

E o P1.123 continua a precisar de **reload** para entrar em producao: os 13 graficos
estao a correr v1.2.159 e o ex5 compilado (v1.2.162) nao foi recarregado.

---
## P1.124 - REFORMULADO (05/11/2026, v1.2.162): o bloqueio NAO e cobertura XAUUSD - e HTTP 401 + o teto de confianca do P1.125

Pedido do dono: "nao deixar xauusd como exclusivo, EA operar todos".

Medido antes (P1.98, v1.2.141): o gateway responde `available=true` so para XAUUSD e
`available=false` com motivo para todos os outros simbolos. Com
`AllowTradeWithoutAI=false` e `EnableAIFilter=true`, os outros 10 simbolos ficam
estruturalmente proibidos de passar no portao da IA - nao por regra de risco, por falta
de cobertura do modelo.

Caminhos XAUUSD-only no codigo, ja localizados e ainda NAO alterados:
- `AI/AIConnector.mqh:207` -> `return "XAUUSD";` (alias GOLD/XAU);
- `Core/BrokerConfig.mqh:19-21` -> `TradeGold` resolvido so para XAUUSD/./c;
- `Core/Config.mqh:921` -> lista `Symbols` por omissao a comecar em XAUUSD;
- `Core/SymbolManager.mqh:127` -> ramo especial `baseSymbol == "XAUUSD"`.

Proxima medicao obrigatoria: pedir a rota de predicao para os 11 simbolos e registar
`available`/motivo por simbolo ANTES de tocar em qualquer um destes quatro pontos.
Nenhum destes ramos, por si, impede os outros simbolos de operar; o que impede e a
cobertura do modelo.

### MEDIDO DEPOIS (05/11/2026, 19:55) - a premissa do P1.98 nao se reproduz

A sonda ao gateway (`Files\Temp\gw_probe.ps1`, autorizada pelo dono) devolveu:

| Passo | Resultado |
|---|---|
| TCP 127.0.0.1:9011 | `porta 9011 aberta: True` |
| GET raiz | `status=401` (No Autorizado) |
| GET `/api/ai/predict?symbol=<S>&timeframe=H1` para os 11 simbolos | `401` nos 11, sem `available=true/false` nenhum |
| `XAU_AI_GATEWAY_TOKEN` / `XAU_AI_API_TOKEN` | indefinidos no ambiente (tamanho 0) |
| `AIGatewayToken` nos 13 graficos | vazio em todos |

Ou seja: neste estado nao existe "XAUUSD com cobertura e os outros sem" - o gateway
recusa a chamada antes de olhar ao simbolo. O P1.98 (`available=false` com motivo por
simbolo) foi medido com o token a funcionar e nao se pode reconfirmar agora.

E o journal de 05/11 confirma que o portao da IA nao abriu para NINGUEM, XAUUSD
incluido: 25 linhas `[VALIDATION] BLOCK | AI`, ZERO linhas `AI OK` e ZERO linhas
`[ADV AI]` em todo o dia.

Conclusao deste item: os quatro caminhos XAUUSD-only continuam por tocar, mas nenhum
deles e o que impede os outros simbolos de operar hoje. O que impede esta no P1.125.
---
## P1.119 - ABERTO, MAS REFORMULADO (05/11/2026, v1.2.160) - o iATR do EA nao esta morto: falha nos MESMOS ciclos em que o ADX e o RSI falham
**MEDIDO EM PRODUCAO (05/11/2026, 20:05-20:39, v1.2.162 recem-instalada no reload das 20:05:04, 13 graficos).** A sonda interna do P1.117 passou a publicar o handle e as barras, e o que sai agora nomeia o mecanismo:

| hora | instancia | simbolo lido | ATR | preco | handle | barsCalc | barrasSerie | devolvido |
|---|---|---|---|---|---|---|---|---|
| 20:05:05.225 | USDJPY,H1 | USDJPY | 33.953000 | 157.562 | 10 | 60372 | 100014 | 0.0 |
| 20:05:05.810 | AUDUSD,H1 | AUDUSD | 33.952860 | 0.69326 | 10 | 60372 | 100014 | 0.0 |
| 20:05:06.090 | USDCHF,H1 | USDCHF | 33.952860 | 0.81602 | 10 | 60372 | 100014 | 0.0 |
| 20:05:06.403 | USDSEK,H1 | USDSEK | 33.952860 | 9.80153 | 10 | 60372 | 100014 | 0.0 |
| 20:05:06.607 | NZDUSD,H1 | NZDUSD | 33.952860 | 0.55969 | 10 | 60372 | 100014 | 0.0 |
| 20:16:10.189 | USDCAD,H1 | USDCAD | 33.952860 | 1.40183 | 10 | 60372 | 100014 | 0.0 |
| 20:16:12.258 | GBPUSD,H1 | GBPUSD | 33.952860 | 1.34527 | 10 | 60372 | 100014 | 0.0 |
| 20:16:51.525 | USDCZK,H1 | USDCZK | 33.952860 | 21.67780 | 10 | 60372 | 72096 | 0.0 |
| 20:11:11.643 | USDCNH,H1 | USDCNH | 25.327790 | 6.66418 | 50 | 60372 | 66892 | 0.0 |

Tres leituras que o numero permite fechar:
1. **O valor e o MESMO em oito simbolos** (33.952860 / 33.953000) e corresponde ao ATR do ouro com o bid em 4094.690000 (0.83 por cento do preco), logo nao e o ATR de cada par: AUDUSD a 0.69326 com ATR 33.95 daria 4897 por cento e USDSEK a 9.80153 daria 346 por cento.
2. **barsCalc=60372 em todos os casos**, que e exactamente o total_bars do grafico XAUUSD,H1 (CHART01) neste terminal, enquanto barrasSerie e o numero de barras do proprio par (100014 em sete graficos, 72096 no USDCZK, 66892 no USDCNH). Ou seja: o handle em cache esta a calcular sobre a serie do XAUUSD, e nao sobre a serie do simbolo pedido.
3. O mesmo defeito atinge o ADX, com guarda propria: `[ADX] VALOR DE OUTRO SIMBOLO | XAUUSD | ADX=25.33 | grafico=USDSEK` as 20:05:04.834 e `| grafico=USDJPY` as 20:27:51.154, e 25.33 e o valor que o retrato das 20:30:02 publica para o XAUUSD (ADX=25.3).

O retrato das 20:30:02 mostra ainda o simbolo do proprio grafico mestre sem leitura: `XAUUSD TENDENCIA_FORTE ADX=25.3 ATR%=sem leitura(atr=0.000000,bid=4094.690000)`.

Nada disto chega hoje a decisao com aparencia de verdade - a guarda do P1.112 devolve 0.0 no ATR e a do P1.113 devolve -1.0 no ADX -, mas o custo e real: dez dos treze graficos operam com ATR ausente e o ADX de alguns pares chega ausente, portanto o filtro de volatilidade e o portao de cenario decidem sem essa informacao. **A causa mecanica (porque e que iATR(simbolo,PERIOD_H1,14) devolve um handle preso a serie do XAUUSD) fica por provar: e o que falta medir antes de tocar no codigo.** Nenhum ficheiro foi alterado neste ciclo para este item.

### A pergunta unica deste item: o terminal deduplica o handle?

RESPOSTA MEDIDA: NAO. A sonda `Scripts/XAI_AtrDiag.mq5` v1.010, corrida as
19:16:10 no grafico `AUDUSD,H1` (build 6296), pediu `iATR` para 14 simbolos e
para dois periodos:

| Passo | Pergunta | Medicao |
|---|---|---|
| A | um handle por simbolo? | `handle=10` XAUUSD `barsCalc=60371` = `barsSerie`; `11` AUDUSD 100013; `12` USDCNH 66891; `20` USDCZK 72095; `21` USDBRL 2206 - cada um com as barras do SEU simbolo |
| C1 | o mesmo par devolve o mesmo handle? | `handle1=10 handle2=10 igual=SIM barsCalc2=60371` |
| C2 / C3 | outro par devolve outro handle? | `igual=NAO` nas duas comparacoes (`10` vs `11`, `11` vs `12`) |
| D1 | o periodo entra na identidade? | `periodo=15 -> handle=24`, `igualAoDe14=NAO` |
| E1 | `iATR(_Symbol,...)` criado por ultimo? | `handle=11 barsCalc=100013` = `barsSerie` do grafico |

Logo, quando o pedido vem de um script: sem deduplicacao por
(nome, periodo, parametros) e sem ligacao a serie errada. A hipotese que este
item mandava testar primeiro fica REFUTADA nesse contexto.

### O que o EA faz de diferente (medido no journal de producao)

1. O ATR NAO esta permanentemente a zero. No mestre `USDCNH,H1`, entre as
   18:51:02 e as 19:07:18 de 05/11: `ATR%=0.03` as 18:51:02, 18:54:23, 18:57:42,
   19:04:14 e 19:07:18; `ATR%=sem leitura(atr=0.000000,bid=6.665560)` as 18:52:10,
   18:55:28, 18:59:02 e 19:05:17. Alterna a cada ~90 s. O valor bom
   (0.0021 sobre 6.6656 = 0.03%) e o ATR correcto do par.
2. As "ondas de hora a hora" nao sao ondas: sao o portao de 3600 s do
   `ATRLogNoRead` (P1.121) a rearmar. O que e continuo e a falha, nao o aviso.
3. O ATR falha no MESMO ciclo em que o ADX e o RSI falham. `[DATA] SEM LEITURA`
   entre 19:00:35 e 19:01:11 de 05/11 em USDCHF, USDCAD, NZDUSD, USDJPY e USDSEK,
   todos com `ATR=0.000000`, `RSI=0.00` e o MESMO `ADX=51.17` - a assinatura ja
   registada no cabecalho de `Indicators/SymbolDataReady.mqh` (P1.113), agora
   medida em cinco graficos no mesmo segundo e imediatamente apos o fecho da
   barra H1 das 19:00.

Portanto o ATR a zero e VITIMA do mesmo evento que contamina o lote de
indicadores (P1.110), e nao um `iATR` que nunca aquece. As duas recuperacoes do
P1.117/P1.118 (`ATRCacheDrop` por suspeita e por 180 s de falha) tratam o
sintoma: quatro horas depois de instaladas, a falha continua a aparecer.

### Codigo deste ciclo (v1.2.160, so diagnostico)

O ramo `CopyBuffer sem barras` do `GetATR` passa a publicar `handle`,
`barrasSerie`, `barrasGrafico` e `serieSync` ao lado de `barsCalc` e do `bid`, e
a linha `[ATR] LEITURA SUSPEITA` passa a publicar o `handle`. Com `barsCalc` (do
handle) ao lado de `barrasSerie` (da serie pedida), a proxima medicao distingue
"serie sem barras" de "handle preso a outra serie" sem sonda externa. Nenhum
limite, lote, alvo, stop, spread, preco, regra de entrada ou de saida, ou
parametro de risco foi alterado: muda o texto de duas linhas de diagnostico.

### O que falta para fechar

Uma medicao DENTRO do EA, que so existe depois de uma recarga autorizada: com
`handle`, `barsCalc`, `barrasSerie` e `serieSync` publicados na linha de falha,
provar se o handle do ATR do par do grafico fica preso ao XAUUSD nos ciclos em
que o `ADX` publicado tem o valor do Ouro (51.17) e o `RSI` sai 0.00.

Historico anterior deste item (mantido): 12 linhas `[ATR] SEM LEITURA | <par> |
CopyBuffer sem barras | barsCalc=-1 | erro=4807` entre 15:31:05.262 e
15:32:11.607, uma por grafico, todas do PROPRIO simbolo do grafico e todas
DEPOIS de o P1.118 ter removido e recriado a entrada da cache; prova cruzada de
que o ADX lia o par certo na mesma linha (`[CENARIO] USDCNH | TENDENCIA_FORTE |
ADX=51.6 | ATR%=sem leitura`) e de que a sonda lia os dois pares com handles de
script (`XAUUSD atr=22.476429 atrPct=0.5485 bars=60369`, `USDCNH atr=0.002087
atrPct=0.0313 bars=66887`).

## Herdadas, ainda abertas
- P1.110: a contaminacao por simbolo reapareceu intermitente e por INSTANCIA - re-medida a 05/11 as 19:00:35-19:01:11 em cinco graficos (USDCHF, USDCAD, NZDUSD, USDJPY, USDSEK) com `ATR=0.000000`, `RSI=0.00` e o MESMO `ADX=51.17`, logo apos o fecho da barra H1; e a causa do ATR a zero que o P1.119 perseguia.
  (rajadas de `ATR=0.000000` as 20:19:24/USDCHF, 21:27:47 e 22:39:42/AUDUSD).
- P1.111: varias instancias escrevem o mesmo `dataset.csv` sem sincronizacao
  (linhas partidas e coladas) — requer decisao do dono.
- Simbolos: `Symbols` com 11 nomes, 13 graficos abertos, EURUSD na lista sem
  grafico, CHART11 em M5, `[CENARIO] RETRATO simbolos=10` vs `[PIPELINE] 11`.
- `EnableVolatilityFilter=false` nos 13 graficos: confirmar se e intencional.
- Gateway de IA: 401 `token RECUSADO` e 1003 `backend fora do ar`; modelo
  publicado espera 30 features e o runtime monta 25 (25F-v2).
- `MCPServerToken` vazio com `EnableMCPServer=false`.
- PF (0.6206) tem de ser re-medidos: descrevem um EA sem ATR/ADX/RSI nos 10
  simbolos nao-grafico.
- ROTULAGEM (fechada em 05/11): `Filters/TrendFilter.mqh` (cabecalho e 4 blocos)
  e `Indicators/ADX.mqh` (2 sitios) diziam v1.2.153/P1.114 a descrever o P1.115; passaram a v1.2.154/P1.115.

## P1.120 - FECHADO NO CODIGO (05/11/2026, v1.2.158) - o [CENARIO] escondia PORQUE nao havia ATR

MEDIDO no journal do expert as 15:26:31.831, 15:28:14.015, 15:26:43.146 e
15:28:35.864 de 05/11, build v1.2.157, grafico mestre `USDCNH,H1`:
`[CENARIO] XAUUSD | ADX=25.8 | ATR%=sem leitura` e
`[CENARIO] USDCNH | ADX=51.6 | ATR%=sem leitura`, embora os mesmos dois pares
tivessem publicado `ATR%=0.55` as 14:55:12 e `ATR%=0.54` as 15:01:35 na MESMA
instancia.

O `-1.0` de `MarketVolatilityPercent` tem DUAS origens - `atr<=0.0` lido do
`GetATR`, ou `SymbolInfoDouble(simbolo,SYMBOL_BID)<=0.0` - e a string devolvida
era `sem leitura`, texto fixo, portanto a medicao seguinte ficava a adivinhar
qual das duas era.

Correcao (v1.2.158), so de diagnostico: `ScenarioAtrPctStr` passa a publicar
`sem leitura(atr=<valor>,bid=<valor>)` e o ramo `CopyBuffer sem barras` do
`GetATR` passa a publicar tambem o `bid`. O valor devolvido nao muda (continua
`0.0`), logo nenhuma decisao do EA muda.

## P1.121 - FECHADO NO CODIGO (05/11/2026, v1.2.159) - um build antigo calava um build novo

MEDIDO nos ficheiros do portao em `Common\Files`: o `ATRLogNoRead` gastou a vez
de XAUUSD as 15:12:30.864 e a de USDCNH as 15:12:31.846 (tag
`atr_no_read_<par>`) e a janela e de 3600 s por CONTA. O build seguinte nao
tinha como voltar a falar desses dois pares durante uma hora - foi o que
aconteceu entre as 15:12 e as 15:28 de 05/11.

A chave do portao nao levava nada que mudasse entre builds, portanto o estado
gravado por um build antigo silenciava o build novo.

Correcao (v1.2.159), so de diagnostico: as tres chaves do ATR
(`atr_no_read_`, `atr_handle_morto_`, `atr_absurdo_`) passam a incluir a marca de
COMPILACAO `IntegerToString((long)__DATETIME__)`. Cada build fala uma vez por
simbolo por conta e um build antigo nao gasta a vez do novo; a janela de 3600 s
mantem-se, portanto nao ha aumento de ruido dentro do mesmo build.

## Numeracao e warning deste ciclo

`P1.119` continua a ser o item aberto do ciclo anterior (o `iATR` criado pelo EA
que nunca aquece): os dois itens deste ciclo ficaram `P1.120` e `P1.121` para nao
haver dois itens com o mesmo numero no registo.

A primeira compilacao da v1.2.159 saiu com `0 errors, 1 warnings`
(`VersionManager.mqh(63,147) : warning 86: 'F' - unrecognized character escape
sequence`): `Common\Files` escrito dentro de um literal de string. Corrigido
para `Common\\Files` e recompilado: `0 errors, 0 warnings, 22066 ms`.

## Ciclo de 05/11 (15:40) - v1.2.159 recarregada e o ATR medido no reload

### P1.120 / P1.121 - implementados; o que fica PROVADO e o que NAO fica

O codigo das duas entradas esta em `VolatilityFilter.mqh` (as tres chaves do ATR
levam `IntegerToString((long)__DATETIME__)`), compila com `0 errors, 0 warnings`
e a recarga do perfil `XAI_P216_LIVE` correu sobre o binario novo: os treze
graficos escrevem `[START] XAU_AI_PRO v1.2.159` entre 15:40:14.901 e
15:40:14.935 de 05/11 (e ja tinham escrito o mesmo as 15:39:50.125-15:39:50.926,
no attach anterior).

O que **nao** fica provado nesta janela: que um ficheiro `loggate_*.bin` gravado
por build antigo deixe de calar o build novo. A prova exigiria dois builds
seguidos na mesma janela e, como os `.bin` do ATR foram apagados as 15:31, a
ausencia de silencio nao e atribuivel a `__DATETIME__`. Fica escrito como
implementado-e-compilado, nao como medido.

### P1.119 - causa MEDIDA (item continua ABERTO)

O reload das 15:39:50-15:40:56 expos a assinatura completa. Linhas medidas:

    [ATR] LEITURA SUSPEITA | AUDUSD | ATR=22.597860 | preco=0.69474 | ATR%=3252.71 | grafico=AUDUSD | barsCalc=60369 | barrasSerie=100009 | barrasGrafico=100009 | devolvido=0.0
    [ATR] LEITURA SUSPEITA | USDCHF | ATR=22.597860 | preco=0.81499 | ATR%=2772.78 | grafico=USDCHF | barsCalc=60369 | barrasSerie=100009 ...
    [ATR] LEITURA SUSPEITA | NZDUSD | ATR=22.597860 | preco=0.56088 | ATR%=4029.00 | grafico=NZDUSD | barsCalc=60369 ...
    [ATR] LEITURA SUSPEITA | GBPUSD | ATR=22.597860 | preco=1.34683 | ATR%=1677.86 | grafico=GBPUSD | barsCalc=60369 ...
    [ATR] LEITURA SUSPEITA | USDSEK | ATR=22.597860 | preco=9.79160 | ATR%=230.79 | grafico=USDSEK | barsCalc=60369 ...
    [ATR] LEITURA SUSPEITA | USDCNH | ATR=22.597860 | preco=6.66483 | ATR%=339.06 | grafico=USDCNH | barsCalc=60369 | barrasSerie=66887 ...
    [ATR] LEITURA SUSPEITA | USDCAD | ATR=22.597860 | preco=1.39899 | ATR%=1615.30 | grafico=USDCAD | barsCalc=60369 ...
    [ATR] LEITURA SUSPEITA | USDSGD | ATR=22.597860 | preco=1.27946 | ATR%=1766.20 | grafico=USDSGD | barsCalc=60369 ...
    [ATR] LEITURA SUSPEITA | USDCZK | ATR=22.597860 | preco=21.66700 | ATR%=104.30 | grafico=USDCZK | barsCalc=60369 | barrasSerie=72091 ...
    [ATR] LEITURA SUSPEITA | USDJPY | ATR=22.598000 | preco=157.722 | ATR%=14.33 | grafico=USDJPY | barsCalc=60369 ...
    [ATR] LEITURA SUSPEITA | USDBRL | ATR=3831.556600 | preco=5.5190 | ATR%=69424.83 | grafico=USDBRL | barsCalc=2204 | barrasSerie=24599 | barrasGrafico=24599 | devolvido=0.0

Leitura honesta destes numeros:

1. `ATR=22.597860` ao sexto decimal em nove instrumentos diferentes e o ATR do
   OURO (o `[START]` do XAUUSD e o primeiro, 15:39:50.125);
2. `barsCalc=60369` e o numero de barras do grafico `XAUUSD,H1`, nao o de cada
   par - `AUDUSD` tem `barrasSerie=100009`, `USDCNH` 66887, `USDCZK` 72091;
3. portanto o handle em cache, em cada instancia, le UMA serie que nao e a do
   simbolo pedido - e o mesmo padrao que o P1.113 ja tinha medido no ADX/RSI
   (sete pares com `ADX=33.77` e `RSI=82.72` no mesmo segundo);
4. isto acontece no simbolo do PROPRIO grafico, com a serie provada no instante
   da leitura (`barrasSerie=100009`), pelo que a hipotese escrita no ciclo
   anterior ("o handle nasce antes de a serie ter barras") **nao explica** o
   observado: `XAI_WaitSeriesReady` devolve verdadeiro e o handle continua a ler
   outra serie;
5. a cura automatica tambem nao cura: as 15:40:51 (USDSGD) e 15:40:56 (USDCZK),
   depois da queda do handle pelo portao do P1.117, o handle NOVO volta a ler
   22.597860. O `ATRCacheDrop` esta a ser chamado (ramo `LEITURA SUSPEITA`,
   portao de 60 s) e o resultado e o mesmo;
6. o `XAUUSD` em si falha em sentido contrario no arranque:
   `[ATR] SEM LEITURA | XAUUSD | CopyBuffer sem barras | barsCalc=-1 | erro=4807`;
7. `USDBRL,M5` fecha o quadro: `ATR=3831.556600` com `barsCalc=2204` contra
   `barrasSerie=24599` - tambem nao e a serie do proprio grafico.

Consequencia para risco (importante e favoravel): **nenhum ATR errado chega as
decisoes**. Todas as linhas acima terminam em `devolvido=0.0`, porque a guarda de
plausibilidade do P1.112 as intercepta. O custo e de DADOS (o par fica sem ATR,
logo sem candle no dataset), nao de risco.

O que falta para fechar, e que NAO foi feito nesta janela: uma sonda isolada que
responda a uma pergunta unica - o terminal deduplica a instancia do indicador por
(nome, periodo, parametros) ignorando o simbolo, ou o handle nasce ligado a serie
errada? Enquanto essa pergunta nao tiver resposta medida, qualquer "correcao"
seria uma aposta. Nao se embarcou nenhuma alteracao de codigo para o P1.119.
## Encerramento do ciclo 112 (v1.2.159) - o que fecha e o que fica aberto

| Item | Estado no fecho | Prova |
|---|---|---|
| P1.120 | implementado e compilado (v1.2.158) | codigo no binario que corre; mecanismo nao exercitado |
| P1.121 | implementado e compilado (v1.2.159) | idem; prova estrita nao obtida |
| P1.119 | ABERTO | causa medida (ATR do XAUUSD em nove pares, `barsCalc=60369`); falta a sonda de deduplicacao |
| P1.118 | implementado | nao voltou a disparar porque a falha mudou de forma |
| USDBRL M5 | ABERTO | `barsCalc=2204` contra `barrasSerie=24599` |
| P1.110 / P1.111 | herdados, abertos | `dataset.csv` por varias instancias |
| simbolos | herdado, aberto | 11 pares em `Symbols`, 13 graficos, EURUSD sem grafico |
| gateway IA | herdado, aberto | 401/1003, 30F contra 25F, sem gateway a correr |
| PF 0.6206 | nao remedido neste ciclo | conta real continua proibida |
| `push` | nunca feito | 379 commits locais; so o dono |

Nenhum item foi fechado por etiqueta: o que fecha, fecha por medida; o que nao tem medida fica registado como ABERTO. Neste fecho nao houve alteracao de codigo, de inputs, de ordens ou de configuracao. HEAD `44b4bfaf`.

---

## Ciclo 113 - P1.126 / P1.127 / P1.128 - reconexao autonoma do gateway de IA (PROVADA)

Build **v1.2.165** (XAU_AI_PRO.ex5 = 923.626 B, 05/11/2026 20:27), conta demo 113568614.
Simulacao REAL: gateway Python parado com taskkill e relancado, sem tocar no EA nem no terminal.

| Passo | Hora local | Evidencia medida |
|---|---|---|
| v1.2.165 reattach a 14 graficos | 20:28:52 / 20:28:57 | 14x `[START] XAU_AI_PRO v1.2.165` |
| gateway vivo (pid 7912) | 20:29:00.846 | `[AI] GATEWAY | XAUUSD | H1 | 1120 bytes | disponivel=true` |
| gateway MORTO (taskkill /PID 7912) | 20:29:00 | `tasklist` python.exe = 0 processos |
| **FALHA visivel** | 20:29:09.157 | `[AI] GATEWAY | HTTP 1001 | .../predict?symbol=EURUSD&timeframe=H1 | resposta NAO-HTTP ... | corpo=0B` |
| FALHA repetida (portao 300 s) | 20:34:09.379 | mesma linha, symbol=USDCAD, 300.2 s depois |
| gateway RELANCADO (pid 14992) | ~20:34:55 | uvicorn `Application startup complete` |
| **RECUPERACAO autonoma** | 20:35:04.522 | `[AI] GATEWAY RECUPERADO | USDCAD | H1 | falhas=159 | cego=357s | resposta=357B | sem intervencao` |

### O que fica PROVADO
- O EA deteta a queda do gateway e recupera **sozinho**: sem reattach do EA, sem reiniciar o terminal, sem accao do operador.
- Pela primeira vez o journal tem **as duas metades** da mesma paragem: falha (20:29:09) e recuperacao (20:35:04).
- O portao de 300 s da classe transporte e respeitado ao segundo (20:29:09 para 20:34:09).
- Canal independente: o stdout do uvicorn relancado mostra o assalto de pedidos do EA nos primeiros segundos (`GET /api/ai/predict?symbol=... HTTP/1.1" 200 OK` para USDCAD, NZDUSD, USDCHF, USDSEK, USDCNH, XAUUSD, EURUSD, GBPUSD, USDJPY, AUDUSD).

### Causa raiz corrigida neste ciclo
O rasto da metade FALHA estava mudo por **tres relogios** que mediam tempo com `TimeCurrent()` (hora do servidor, que CONGELA quando o link ao broker cai) em vez de `TimeLocal()`:
1. `Monitoring/AccountLogGate.mqh` (linhas ~79 e ~89) - portao por conta/tag: o valor gravado nunca avancava, logo o aviso era filtrado para sempre.
2. Ramo HTTP != 200 em `AI/AIConnector.mqh` - janela unica de 1800 s por conta, tambem em `TimeCurrent()`.
3. Portao do poll (15 s) e teste de frescura em `AIConnector.mqh` - comparavam `TimeCurrent()` (servidor) com um valor gravado por `AIClockRelogio()` (local): desvio medido +18000 s, o que degenerava o poll para uma chamada por tick.
`AIClockRelogio()` devolve `TimeLocal()` em producao e `TimeCurrent()` dentro de `MQL_TESTER`, para os backtests continuarem a medir tempo MODELADO como antes.

### O que NAO fica provado (registo honesto)
- Codigos 5201 / 5202 / 5203: nunca observados nesta maquina. Com o gateway parado o `WebRequest` devolve **1001** (codigo de transporte, nao -1), portanto a linha real e o ramo `[AI] GATEWAY | HTTP 1001 | ...` e nao `[AI] GATEWAY falhou | erro=5201`.
- Queda do link ao **broker**: o EA nao pode forcar a reconexao terminal->broker; `Enterprise/ConnectionGuard.mqh` e `Enterprise/RecoveryManager.mqh` apenas LEEM `TERMINAL_CONNECTED` e `ACCOUNT_TRADE_ALLOWED`. Essa camada pertence ao terminal.
- Reboot do PC: o gateway e um processo comum (`uvicorn`), nao um servico Windows; nao sobrevive a um reinicio.
- Relogios residuais, sem efeito nesta prova: `AIConnector.mqh` linha ~1295 `datetime logNow = TimeCurrent();` (portao logOnce de 1800 s do `LoadAIPrediction`) e linha ~139 `g_aiStateWhen[slot]=TimeCurrent();`.

### Inalterado (deliberado)
Nenhum limite, lote, alvo, stop, spread, preco, regra de entrada/saida ou parametro de risco foi tocado. `AllowTradeWithoutAI=false` e `MinAIConfidence=60.0` mantidos. 5201/5203 continuam sem cooldown; 4014/4060/5200 continuam com 1800 s. Sem push (380 commits locais). Conta real PROIBIDA.

### Porque o EA continua sem abrir operacoes (diagnostico anterior, ainda valido)
O gateway responde 200 mas devolve `available=false` em 12 de 13 simbolos com `edge ... abaixo do minimo +0.0500` (EURUSD -0.0161, GBPUSD -0.0207, USDJPY +0.0248, AUDUSD -0.0184, USDCAD +0.0317, NZDUSD +0.0225, USDCHF +0.0253, USDSEK -0.0403, USDCNH -0.1256, USDCZK -0.0072, USDSGD +0.0193, USDRUB +0.0166, USDBRL M5 +0.0240). So XAUUSD/H1 devolve `available=true`, e XAUUSD nao esta na lista de pares negociados. O bloqueio e de MODELO (edge), nao de infraestrutura.

## Ciclo 114 - P1.129 / v1.2.166 - a notificacao push repetida por GRAFICO (corrigida e medida)

Pergunta do dono: `2026.11.05 20:29:32.969 Notifications notification '[RELATORIO] Profit=0.00 | Trades=0 | WinRate=0.00%' sent to '7AC1F3B4'`.
Resposta medida: nao era reenvio da mesma instancia, eram as 14 instancias a enviar a MESMA mensagem.

| Passo | Hora local | Evidencia medida |
|---|---|---|
| Antes (v1.2.165) - relatorio | 20:28:21 e 20:29:29-30 (Common/Files/Notifications.log) | 8 + 12 linhas `[RELATORIO]` identicas |
| Antes (v1.2.165) - encerramento | 20:28:49 e 20:28:54 | 13 + 13 linhas `[SISTEMA] EA finalizado (reason=9)` |
| Antes (v1.2.165) - encerramento | 20:50:32.598 - 20:50:35.051 (journal do terminal) | 13 pushes `EA finalizado (reason=2)`, um a cada ~200 ms |
| Depois (v1.2.166) - encerramento | 20:50:54.593 | **1** push `EA finalizado (reason=9)` |
| Depois (v1.2.166) - relatorio | 20:51:34.589 | **1** push `[RELATORIO]`, igual ao que o dono citou |
| Duas recargas seguidas (Default e XAI_P216_LIVE) | 20:50:57 e 20:51:03 | 14 `[START] XAU_AI_PRO v1.2.166` em cada, e o relatorio saiu UMA vez pelas duas |

Causa raiz, medida por leitura de codigo (duas fontes independentes):

1. `XAU_AI_PRO.mq5` bloqueava o relatorio diario com `TimeCurrent() - g_lastDailyReport >= 86400`, e `g_lastDailyReport` e uma variavel POR INSTANCIA que nasce a zero em cada carga. Consequencia: cada recarga de qualquer grafico satisfazia a condicao no primeiro tick e todas as instancias enviavam no mesmo segundo.
2. `OnDeinit` chamava `CNotificationCenter::SendSystemAlert("EA finalizado ...")` sem portao nenhum, e os motivos REASON_RECOMPILE, REASON_TEMPLATE, REASON_ACCOUNT e REASON_CLOSE acordam TODAS as instancias no mesmo segundo.
3. O `CNotificationCenter::Send` tem cooldown e deduplicacao, mas o estado (`m_last_send`, `m_last_message`) e POR INSTANCIA de proposito - logo nunca podia impedir 14 envios.

Correcao (so notificacao, nenhuma regra de negociacao tocada):
- relatorio: `AccountLogGatePodeImprimir("relatorio_diario", 82800)` - portao por CONTA em `Common/Files/XAU_AI_PRO/loggate_relatorio_diario.bin`, 1 por conta e por dia;
- encerramento: nos motivos simultaneos, eleicao de dona do pipeline (`PipelineMasterFresh()` + `ChartID() == PipelineMasterChart()`, a mesma do `[STOP]` do P2.14) MAIS o portao `ea_finalizado_<motivo>` de 120 s; os outros motivos ficam so no portao;
- cooldown/dedup do NotificationCenter continuam por instancia DE PROPOSITO, porque ABERTURA e FECHAMENTO sao eventos do grafico que executou e nao da conta.

Residual honesto: (a) a primeira utilizacao de um ficheiro de portao pode deixar passar mais do que uma instancia no mesmo segundo (licao do P2.14) - nao aconteceu nesta medicao, o relatorio saiu uma unica vez; (b) o conteudo do relatorio (DailyProfit, TradesToday) e o da instancia que o envia; (c) o segundo reload seguido de 20:51:03 nao gerou o seu `EA finalizado` porque caiu dentro dos 120 s do portao - um encerramento isolado continua a sair.

Compilacao: 0 errors, 0 warnings (`XAU_AI_PRO.ex5`, 926.192 B, 05/11/2026 20:50). 14 graficos com v1.2.166. Sem push, sem commit (380 commits locais). Conta real continua PROIBIDA.
