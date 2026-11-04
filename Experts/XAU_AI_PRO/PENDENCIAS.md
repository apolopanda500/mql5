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
> - Ultima revisao desta lista: 2026-11-04 05:58 (conta 113568614, v1.2.131).

---

## 1. Bloqueios que so o dono resolve (sem isso, o resto fica em modo degradado)

### P-01 — WebRequest desligado e `AIGatewayToken` vazio `DONO`
- **Medido:** erro `4014` (WebRequest nao permitido) e `AIGatewayToken=""` nos
  16 graficos; o gateway em `http://127.0.0.1:9001/api/ai/predict` responde
  `401`.
- **Por que importa:** com `RequireAIJSON=false` e `AllowTradeWithoutAI=false`, o
  portao de IA roda em **fallback** (`Files\Data\prediction_<SIMBOLO>.json`,
  `MaxPredictionAgeSec=900`). O EA opera, mas nao com a IA de verdade.
- **Como fechar:** no terminal, `Ferramentas > Opcoes > Expert Advisors > marcar
  "Permitir WebRequest para URLs listadas"` e adicionar `http://127.0.0.1:9001`;
  depois preencher `AIGatewayToken` nos 16 graficos (mesmo valor em todos).
- **Criterio:** journal sem `4014` e sem falha de IA, e uma predicao valida
  consumida (`[AI] ... score=...`). Fechar registrando a data no `PROGRESS.md`.
- **Medido (04/11 05:55, evidencia no journal):** o `WebRequest` esta
  **LIGADO** (a chamada sai) e o `401` e recusa de credencial: os graficos
  enviam **17 caracteres** e o `XAU_GATEWAY_TOKEN` do `.env` tem **64**.
  Ate o dono colar o valor exato, o `401` continua - agora com o motivo certo.

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
