# CONVERSAS — registro das sessoes com o dono

> Este arquivo salva o que foi **pedido** (nas palavras do dono), o que foi
> **medido** e o que foi **decidido** em cada sessao de trabalho no
> `XAU_AI_PRO`. E append-only: sessoes novas entram no fim.
>
> Divisao de responsabilidade:
> - **`CONVERSAS.md`** (este) = o pedido e a conversa, em ordem cronologica;
> - **`PROGRESS.md`** = o detalhe tecnico (o que mudou, com que numero, por que);
> - **`README.md`** = indice geral e estado atual.
>
> Toda conversa registrada aqui e seguida de um bloco **"Medido"** com o que o
> journal/conta provaram. Pedido sem medicao e intencao, nao prova.

---

## Indice de sessoes

| # | Quando | Pedido do dono (resumo) | Resultado |
|---|---|---|---|
| 1 | 2026-10-29 (manha/tarde) | "quero EA fazendo tudo automatico e entendendo o que faz"; "desbloquear totalmente o EA para operar sozinho (nao abria nenhuma operacao)" | EA desbloqueado. Causa medida: `AIUnavailableConfidenceCap=40` vs `MinAIConfidence=50` e `ForceSafeMode` persistido por anomalia de ATR. Ver `PROGRESS.md` "Ciclo 2026-10-29". |
| 2 | 2026-10-29 (tarde) | "fazer o EA aprender com o historico de operacoes MANUAIS do dono"; "melhorar a precisao como traders fazem" | `AI/LearningHistory.mqh` criado: diario append-only + ingestao por `HistorySelect` (EA **e** manual), persistido em `Data/XAU_AI_PRO_learning.csv`, sobrevive a recarga. |
| 3 | 2026-10-29 (tarde) | "stop automatico em dolares: armar stop apos o preco andar; mover para entrada quando lucro passa 10 USD; depois travar em 5 USD; alvo 20 USD fecha TP total = meta diaria" | Escada em dolares (`Management/MoneyLadder.mqh`): arma 10, trava 5 depois de 15, alvo 20. Dono unico de SL/TP quando ligada. |
| 4 | 2026-10-29 (tarde) | "implementar TODAS as melhorias aprovadas" ("todos") | Ciclo v1.2.10: risco efetivo observavel, RR minimo, trava por tempo por simbolo, estado de sessao persistente, entre outros. |
| 5 | 2026-10-29 (noite) | "melhorar alvos curtos (short TP)"; "tem mais melhorias?" | Sonda `MQL5\Scripts\XAI_TargetProbe.mq5` provou que o TP **nao** era curto: o break even em 10 pontos fechava tudo em ~0,1 R. Corrigido para break even em **R** (0,60 gatilho / 0,30 trava). |
| 6 | 2026-10-29 (noite) | "proximo pesquisar na web, estudar modulos, codigos para operar no mercado de hoje, ver outros EA com bons resultados ou repositorios e copiar codigos" | Pesquisa pelo indice publico MQL5. Decisao: **nao copiar arquivo alheio** (licenca + estilo); reescrever a ideia no padrao do projeto. |
| 7 | 2026-10-29 (noite) | "proximo melhorar o maximo sem limites para melhoria, adaptar EA para todos tipos de cenarios globais" | v1.2.21 (cenario de mercado: tendencia/lateral/volatil), v1.2.22 (classe de ativo, sessao GMT, correlacao de moeda), v1.2.23 (horas proibidas em GMT). |
| 8 | 2026-10-29 (22:57) | "sim estudar bastante, aprender e melhorar nosso EA, salvar conversas, documentar tudo, atualizar tudo, executar, deixar rodar EA" | v1.2.24 (SAFE MODE com histerese), v1.2.25 (trava de custo). Criado `README.md`. Corrigida a versao que o journal mentia. Ver sessao A abaixo. |
| 9 | 2026-10-30 (05:20) | "salvar tudo conversas" | Este arquivo. Ver sessao B abaixo. |
| 10 | 2026-10-30 (05:25) | "salvar tudo conversas" (continuacao) | Secao 4 do `README.md` corrigida (mojibake + `[COST]` real as 03:47); `PROGRESS.md` recebeu o ciclo 10 com os numeros da madrugada. Ver sessao C abaixo. |
| 11 | 2026-10-30 (05:35) | "anotar todas pendencias que faltam para facilitar os trabalhos no futuro" | Criado `PENDENCIAS.md` (fonte unica, 23 itens com dono e criterio de fechamento) + tabela de monitoramento e checklist de retomada. Ver sessao D abaixo. |
| 12 | 2026-10-30 (20:00 -> 23:35) | "p1 p2 melhorar tudo"; "pesquisar estudar melhorar EA AUTONOMO REAL"; "proximo" (seis vezes) | v1.2.37 -> v1.2.40: guarda de conta real, backup desacoplado, corte de spam do journal, rotacao do `audit_log.csv`. P0.5 respondida por codigo e analise de 99 560 trades do historico. Ver sessao E abaixo. |
| 13 | 2026-10-31 (06:04) | "salvar conversas anotar" | Esta gravacao: indice de sessoes actualizado, sessao E/F escritas e `PROGRESS.md` com o ciclo 18. Nenhum `.mq5`/`.mqh` tocado. Ver sessao F abaixo. |
| 14 | 2026-11-04 (19:20) | "garantir EA par auso real daqui pra frente"; "corrigir todas falhas, erros, avisos, etc.. deixar limpo"; "so com PF > 1.20 e perdas seguidas <= 8 se discute conta real" | 13 graficos revinculados na v1.2.135 (journal prova `[START]`/`[VERSION]`); `Docs/version.json` 1.2.9 provado NAO ser drift (e a versao do APP, nao do EA); documento do ciclo 92 gravado. Ver sessao G abaixo. |
| 15 | 2026-11-04 (22:30) | "sim pode fazer commits push deploy anotar e salvar documentos novos e atualizados e garantir EA par auso real daqui pra frente" | IA provada VIVA nos 13 graficos (journal 19:07:52: XAUUSD 1123 B, 12 simbolos 357 B = available=false com motivo "edge abaixo do minimo"); `Data\prediction_XAUUSD.json` refrescado do gateway com `timestamp_utc` (era 03/11 03:44, ficou 04/11 22:28); documento do ciclo 93 gravado. Tester continua bloqueado. Ver sessao H abaixo. |

---

## Sessao A — 2026-10-29 22:57

**Pedido, nas palavras do dono:** "sim estudar bastante aprender e melhorar
nosso EA salvar conversas documentar tudo atualizar tudo, executar deixar
rodar EA".

### O que foi feito

1. **`Enterprise/CircuitBreaker.mqh` (v1.2.24)** — histerese no SAFE MODE por
   broker. Antes **uma** leitura ruim de `TERMINAL_CONNECTED` parava o EA
   inteiro por 300 s, e esse bloqueio sobrevivia a reinicios: os 16 graficos
   dispararam no mesmo segundo (22:29:26→22:29:30), o que so pode ser estado
   do **terminal**, nao do simbolo. Agora exige 3 leituras **e** 15 s de
   persistencia, com carencia de 30 s no start.
2. **`Filters/CostGate.mqh` (v1.2.25, novo)** — trava de custo: spread +
   comissao convertidos em **dolares** e comparados com o alvo e com o risco
   da entrada. Burado medido: `MaxSpreadPct=0.6` limitava spread como % do
   preco e **nada** comparava custo com alvo; comissao nunca entrava na
   decisao de entrada.
3. **`README.md` (novo)** — o indice que faltava, com mapa dos 113 arquivos,
   ordem real dos portoes e estado ao vivo.
4. **`PROGRESS.md`** — cabecalho atualizado (estava em `2026-09-07 (v1.2.0)`)
   e ciclo 9 registrado.
5. **`Enterprise/VersionManager.mqh`** — `EA_VERSION_STRING` estava em
   `"1.2.23"` enquanto o codigo ja era v1.2.25, e o binario em memoria
   reportava `1.2.15` as 21:31 e `1.2.21` as 23:01. Corrigido para `"1.2.25"`.

### Medido

| Momento | Versao que o binario reportava |
|---|---|
| 21:31 | `[VERSION] v1.2.15` |
| 23:01:26 | `[VERSION] v1.2.21` (ultimo log do binario antigo) |
| 23:01:27 | `[VERSION] v1.2.25` nos 16 graficos |

- Compilacao: **0 erros, 0 avisos** (build 6292 x64). `.ex5` 856.472 B.
- Posicoes abertas as 22:57: **0**. Resultado do dia: **+16,38 USD**. Trades: 3/100.
- `[COST]`: **0 linhas** ate 22:57 — o EA ainda nao tinha tentado entrada.

**Regra que ficou:** conferir `[VERSION]` antes de acreditar em qualquer numero
do journal. Se nao bater com o fonte, o binario nao e o codigo que se esta lendo.

---

## Sessao B — 2026-10-30 05:20

**Pedido, nas palavras do dono:** "salvar tudo conversas".

### O que foi feito

- Criado este `CONVERSAS.md`, registrando as 9 sessoes (o pedido, o que foi
  entregue e onde o detalhe tecnico esta).
- Apurado o que aconteceu **durante a madrugada** com o EA deixado rodando
  (o dono pediu "deixar rodar EA" na sessao A).

### Medido — madrugada de 29 para 30/10

Conta 113568614 (MetaQuotes-Demo, hedging), magic `2026001`.

**O `[COST]` foi confirmado em producao** — primeira linha real do gate novo:

```
2026.10.30 03:47:09.741  XAU_AI_PRO (USDJPY,H1)
[COST] OK | EURUSD | custo=0.06 US$ = 0.6% do alvo | spread=2.0 pts | comissao=0.00 US$ | alvo=312 pts
```

Leitura: custo de 6 centavos contra um alvo de 312 pontos. O gate **aprovou** e
a ordem foi enviada. Isso fecha a pendencia "o CostGate nunca foi visto em
producao" da sessao A.

**Entrada nova (a unica da madrugada):**

| Campo | Valor |
|---|---|
| Posicao | `11171034182` |
| Simbolo / lado | EURUSD `sell` |
| Volume | 0,03 |
| Abertura | 2026-10-30 08:47:10 (servidor) = 03:47 local |
| Preco de abertura | 1,11794 |
| Take profit | 1,11127 |
| Comentario | `XAU_AI_PRO` |

**Estado da conta as 05:21 (local):**

| Item | Valor medido |
|---|---|
| Balance | 12.348,57 USD |
| Equity | 12.342,99 USD |
| Lucro flutuante | **-5,58 USD** |
| Margem usada / livre | 33,54 / 12.309,45 USD |
| Posicoes abertas | 1 (EURUSD sell 0,03) |
| `[CIRCUIT] SAFE MODE` na madrugada | **0 ocorrencias** |
| Conexao | `synchronized`, ping 214 ms |
| Servidor | GMT+2 (servidor 10:21 = local 05:21 = UTC 08:21) |

**Fechamentos (anteriores a esta sessao, ficam registrados para o historico):**

| Ticket | Simbolo | Lado | Volume | Lucro |
|---|---|---|---|---|
| `11166638047` | USDCNH | sell | 1,36 | **+10,42** |
| `11166734584` | NZDUSD | sell | 0,20 | **+4,20** |
| `11167109885` | AUDUSD | buy | 0,16 | **+1,76** |
| | | | | **+16,38** |

Leitura honesta: 3 de 3 fecharam no positivo, somando os +16,38 USD que o
`[RESUMO]` e o `SYSTEM STATUS` mostram. **Amostra de tres operacoes nao e
estatistica** e nao autoriza concluir nada sobre lucratividade.

### Nota sobre o lote do USDCNH

O lote 1,36 em USDCNH (posicao `11166638047`) estava marcado como pendencia de
revisao. Ele **fechou com +10,42 USD** — ou seja, o resultado foi bom, mas o
tamanho da posicao frente ao `RiskPerTradePercent=0,5` continua merecendo
revisao: ganhar com risco desproporcional nao valida o risco.

### Pendente (nada foi alterado nesta sessao)

1. **WebRequest + `AIGatewayToken`** — os 16 graficos estao com token vazio e o
   gateway responde 401. Depende do dono habilitar `Ferramentas > Opcoes >
   Expert Advisors > Permitir WebRequest para URLs listadas` com
   `http://127.0.0.1:9001`.
2. **Meta efetiva do dia** — `EnableDailyTargetBalancePct=true` com
   `DailyProfitTargetBalancePct=10` e `DailyProfitTargetMaxUsd=100` faz a meta
   ser **100 USD**, nao os 20 do `LadderTpUsd`. Decisao do dono.
3. **Backtest 20-29/10** (`Profiles/Tester/xai_v1300_c5.ini` + `.set`) para
   comparar com o baseline 303 trades / PF 0,8961 / -30,95 / DD 1,68%.
4. **`StoplessEmergencyPoints` = 0** (sem colchao de emergencia).
5. **Sonda `XAI_TargetProbe`** repetir com a escada ativa e comparar
   `realizado_R` x `mfe_R`.
6. Candidatos v1.2.26: alimentar o `CostGate` com **slippage realizado**
   (`Enterprise/ExecutionQuality.mqh` ja registra) e reancorar
   `CostMinViableTargetPoints` por backtest.

---

## Aviso permanente

Este EA envia ordens reais quando anexado a conta real. Nada registrado aqui e
promessa de lucro: 3 fechamentos positivos, um backtest ou uma sessao de journal
nao provam resultado futuro. O padrao do projeto e **medir, registrar e so
entao mudar** — e toda mudanca em risco, lote, stop ou alvo precisa do numero
antes e depois.

---

## Sessao C — 2026-10-30 05:25

**Pedido, nas palavras do dono:** "salvar tudo conversas" (continuacao da
sessao B).

### O que foi feito

- `README.md` secao 4 fechada. A linha do `[COST]` ainda dizia "0 linhas - o EA
  ainda **nao tentou** entrada desde a recarga" quando o journal ja tinha um
  `[COST] OK` real as 03:47. Corrigida.
- Duas travessoes corrompidas (mojibake) no mesmo arquivo trocadas por hifen.
  O defeito nasceu do patch PowerShell anterior: UTF-8 lido como CP1252 e
  regravado. Nao afetava codigo, afetava leitura.
- `PROGRESS.md` recebeu "Ciclo 2026-10-30 (10)" com a madrugada medida:
  `[COST]` em producao, os 3 fechamentos (+16,38 USD), zero `SAFE MODE` e o
  estado da conta as 05:25.
- Scripts e fragmentos temporarios criados em `MQL5\Files\Temp` durante o
  trabalho foram apagados no fim.

### Medido (05:25 local / 10:25 no servidor)

| Item | Valor |
|---|---|
| Balance / Equity | 12.348,57 / 12.342,60 USD |
| Flutuante | -5,97 USD |
| Posicoes | 1 — EURUSD `sell` 0,03 @ 1,11794, ticket `11171034182`, TP 1,11127 |
| Conexao | `synchronized`, ping 214 ms, ultima perda 2026-10-30T01:29:14Z |
| Versao nos 16 graficos | `[VERSION] v1.2.25` |

### Decidido

- Nenhum `.mq5`/`.mqh` tocado neste ciclo: codigo sem pedido e risco sem
  medicao. O binario em producao continua o de 29/10 23:01 (856.472 bytes,
  `v1.2.25`).
- Regra de escrita que fica: `.md` com acento ou travessao se edita por script
  ASCII-only (escape `\uXXXX`) ou por `replace_text_in_file`. Travessao
  digitado direto em `.ps1` corrompe o arquivo, porque o PowerShell 5.1 le
  script sem BOM como ANSI.
- Nenhuma promessa de lucro. +16,38 USD em 3 trades nao e estatistica.

---

## Sessao D — 2026-10-30 05:35

**Pedido, nas palavras do dono:** "anotar todas pendencias que faltam para
facilitar os trabalhos no futuro".

### O que foi feito

- Criado `PENDENCIAS.md` na raiz do EA como **fonte unica** das pendencias:
  23 itens com ID, dono explicitado (`DONO` / `AGENTE` / `AMBOS`), impacto e
  criterio de fechamento, em 5 grupos:

| Grupo | IDs | O que cobre |
|---|---|---|
| Bloqueios do dono | `P-01`..`P-05` | WebRequest + token, Testador ocupado, meta diaria (100 x 20), `StoplessEmergencyPoints=0`, notificacoes mudas |
| Medicoes | `AT-01`..`AT-04` | backtest 20-29/10 com `.set` correto, isolar `CostGate`, isolar gate adaptativo/`MaxCorrelatedTrades`, sonda `XAI_TargetProbe` |
| Codigo v1.2.26 | `CD-01`..`CD-04` | `CostGate` com slippage realizado, reancorar `CostMinViableTargetPoints`, fatiamento, risco em US$ no journal |
| Higiene | `HG-01`..`HG-05` | versao em tres lugares, `VERSION` morto no comentario, scripts velhos em `Files\Temp`, secao 4 do `README`, backup automatico |
| Inconsistencias | `IN-01`..`IN-05` | lote 1,36 do USDCNH, 16 graficos x `Symbols` de 11, `DailyProfit` flutuante, `LearningPenaltyEnabled`, volume de log |

- Incluidas duas secoes de operacao: tabela de **monitoramento continuo** (o
  que cada linha do journal diz e o que fazer quando aparece) e **checklist de
  retomada** (10 primeiros minutos de qualquer sessao futura).
- `README.md` secao 1 ganhou a linha de `PENDENCIAS.md` no indice de documentos.

### Medido antes de escrever (05:35)

| Item | Valor |
|---|---|
| Graficos com o EA | 16 (`chart01`-`chart16`), todos `AutoTrade=true`, `MagicNumber=2026001` |
| Versao | `v1.2.25` (`EA_VERSION_STRING`); `.mq5` ainda com cabecalho `v1.2.9` e `#property version "1.290"` |
| Conta | balance 12.348,57 / equity 12.342,60 / flutuante -5,97 |
| Posicoes | 1 - EURUSD `sell` 0,03 @ 1,11794, ticket `11171034182` |
| Cesta x graficos | `Symbols` tem 11 nomes; 5 com grafico estao fora (USDCLP, USDCOP, USDCZK, USDRUB, USDSGD) e XAUUSD ocupa 2 graficos |
| **Pesos revisados** | `PENDENCIAS.md`: 13.454 bytes, 256 linhas, CRLF puro, UTF-8 sem BOM |

### Decidido

- Separacao de dono explicita em cada item: nada de item "do projeto". O que
  depende de clique no terminal nao pode ficar esperando codigo.
- Ordem de valor registrada no fim do arquivo (se so houver tempo para tres
  coisas): `P-01` (WebRequest + token), `P-02`+`AT-01` (Testador livre e
  backtest com `.set` correto), `IN-01`/`CD-04` (risco real em US$ por trade).
- `IN-04` fica fechado por documentacao: `LearningPenaltyEnabled=false` e
  escolha registrada em `AI/LearningHistory.mqh` (a memoria negativa ajusta
  lote, nao score). Fica anotado para nao ser reaberto como "defeito".
- Nenhum `.mq5`/`.mqh` tocado nesta sessao. O binario em producao continua o de
  29/10 23:01 (856.472 bytes, `v1.2.25`).

## Sessao E - 2026-10-30 20:00 -> 23:35

**Pedido, nas palavras do dono:** "p1 p2 melhorar tudo"; depois
"pesquisar estudar melhorar EA AUTONOMO REAL"; e depois "proximo", seis vezes
seguidas, sempre a pedir o item de maior valor que estivesse pendente.

### O que foi feito, por ordem

| Versao | Item | O que mudou |
|---|---|---|
| v1.2.37 | P1.10 | `Core/RealAccountGuard.mqh`: guarda que so aperta em `ACCOUNT_TRADE_MODE_REAL` (inerte no testador e em demo). Lote minimo acima do tecto bloqueia, vigia do stopless nunca fica em 0R, maximo de 1 posicao sem stop por simbolo, banner `[REAL GUARD]` no arranque. |
| v1.2.38 | P1.11 | Backup deixou de copiar o ficheiro de auditoria inteiro em cada snapshot e passou a detectar corrida entre instancias. |
| v1.2.39 | P1.12 + P1.3 | Journal: bloco `HEALTH MONITOR` de 25 linhas passou a sair 1x/hora; falha de copia do backup 1x/hora com contador de abafadas; scanner passou a emitir UM resumo por minuto em vez de uma linha por simbolo (P1.3, escrita pelo processo paralelo). |
| v1.2.40 | P1.13 | Rotacao por tamanho do `audit_log.csv` (`AuditLogMaxSizeMb = 8`, limite efectivo 16 MB, nada e apagado). |

### Medido

- **Journal (v1.2.32, referencia):** 6 270 linhas/hora. Dentro disso, o bloco
  `========== HEALTH MONITOR ==========` apareceu **2 064 vezes** entre 16:02 e
  21:44 e a falha de copia do backup **2 574 vezes** - os dois com o mercado
  fechado. Alvo declarado: **< 200 linhas/hora** em operacao normal (medicao de
  confirmacao fica para a reabertura de domingo).
- **Backups:** 10 snapshots x 109 ficheiros = 1 100 ficheiros, **787,2 MB** no
  total, **78,7-78,8 MB por snapshot**. A limpeza (`BackupMaxKeep = 10`) estava
  correcta - o problema era o conteudo.
- **`audit_log.csv`:** 69 979 KB (**68 MB**) as 22:28, ainda a crescer, copiado
  inteiro em cada snapshot. E o que encheu o disco ate 0,37 GB livres e abortou
  um backtest.
- **Compilacao v1.2.40:** 0 erros, 0 avisos, 23 150 ms, `X64 Regular`, build
  6294, `XAU_AI_PRO.ex5` 639 638 B as 22:31:15.
- **P0.5 (porque entram operacoes sem IA):** respondida por leitura de codigo.
  `AIGateRequired()` devolve `false` com `EnableAutonomousMode=true`
  (`Core/Config.mqh:998`, valor por defeito), logo `AITradeAllowed()` e
  `FinalAIAllow()` nao bloqueiam; o unico veto que resta e `BlockZeroAIScore`
  (`Core/Config.mqh:1017`). **Nao havia contradicao**: a IA e consultiva por
  desenho.
- **Efeito colateral achado:** o "score de IA" que decide o lote, sem IA, e
  100% tecnico (50 base + 15 tendencia + 10 RSI + 10 ADX = 85) e o
  `MemoryBoost` aprendido pode empurra-lo a 100 -> nota ELITE -> **4x lote sem
  nenhum modelo ter respondido**.
- **Analise do historico (`Common\Files\trade_history.csv`):** 99 560 registos
  validos, 371 linhas **partidas** (escrita concorrente de 16 instancias),
  `AI > 0` em 17 de 99 649. XAUUSD por ADX: `>= 35` **+36 152** (WR 82,6%,
  PF 1,295) contra `25-35` **-31 033** (PF 0,592) e `20-25` -17 952 (PF 0,526).
  Piores horas: servidor 16 / UTC 11 **-11 123**, servidor 19 / UTC 14
  **-7 576**, servidor 14 / UTC 9 **-6 443** (soma **-25 141**).
- **Backtest:** lado A (v1.2.35, ticks reais) fechou em -34,68 / PF 0,81 / 296
  trades / MaxDD 83,30. Lado B (`StoplessEmergencyRMult`) correu toda a noite
  (`run_id 7702617382101217572`) e ainda nao fechou.

### Decidido

- **Nao recompilar com backtest a correr:** cada compilacao recarrega o binario
  do agente e falseia a estimativa (ja aconteceu: 00:02/24:35 -> 00:59/11:46 ->
  01:22/10:32).
- **Nada de risco alterado sem o dono:** as tres propostas desta sessao ficam
  registadas em `PENDENCIAS_20261030.md` para decisao (P1.14 `DynADXClear`
  25 -> 35; P1.15 `AvoidHoursGMT` com UTC 9, 11 e 14; P1.16 serializar o
  `TradeLogger`).
- **Re-anexar os 16 graficos exige autorizacao explicita:** e mudanca de
  configuracao de trading a quente (aplica v1.2.40 + `AvoidHoursGMT="18,20,22"`
  + `EnableVerboseDebug=false` + `BlockWhenMinLotExceedsRiskCap=true` +
  `DailyProfitTargetMaxUsd=40`).
- **Duas edicoes ao mesmo ficheiro nunca no mesmo bloco:** a segunda le antes de
  a primeira gravar e perde-se uma das duas (aconteceu com `#property version`).

### Aberto

1. Validar P1.13 em producao (linha `[AUDIT] rotacao ...` e `audit_log.csv` a
   recomecar perto de zero).
2. Confirmar a queda dos snapshots de 78,8 MB para ~11 MB.
3. Medir de novo o journal na reabertura do mercado contra as 6 270 linhas/hora.
4. Fechar o lado B do backtest e comparar com o lado A.
5. Decidir P1.14 / P1.15 / P1.16.
6. `LoggerInit()` nunca e chamado (`LOGGER OFFLINE` em fallback): falta decidir
   se o log passa a ser um ficheiro FILE_COMMON partilhado por 16 graficos.

---

## Sessao F - 2026-10-31 06:04

**Pedido, nas palavras do dono:** "salvar conversas anotar".

### O que foi feito

- `CONVERSAS.md`: indice actualizado (sessoes 12 e 13) e escritas as sessoes E
  (o trabalho de 30/10, v1.2.37 -> v1.2.40 + P0.5 + analise do historico) e F
  (esta).
- `PROGRESS.md`: ciclo 18 acrescentado com a mesma materia, no formato dos
  ciclos anteriores.
- Nada de codigo tocado: nenhum `.mq5`/`.mqh` alterado nesta sessao.

### Medido

- Ficheiros antes da gravacao: `CONVERSAS.md` 14 368 B / 269 linhas (indice
  parado na sessao 11); `PROGRESS.md` 87 128 B / ~1 650 linhas, com o ciclo 17
  escrito pelo processo paralelo.
- Nenhuma compilacao: o backtest nao foi interrompido.

### Aberto

- Os mesmos seis pontos da sessao E. A gravacao nao fecha pendencias tecnicas;
  garante que a proxima sessao saiba exactamente onde parou e por que.

---

## Sessao G - 2026-11-04 19:20

**Pedido, nas palavras do dono:** "sim pode fazer commits push deploy anotar e
salvar documentos novos e atualizados e garantir EA par auso real daqui pra
frente"; "corrigir todas falhas, erros, avisos, etc.. deixar limpo"; "so com
PF > 1.20 e perdas seguidas <= 8 se discute conta real, e mesmo ai com
EnableRealAccountGuard=true e risco baixo".

### O que foi pedido e o que foi medido

- **EA igual ao compilado.** Os 13 graficos foram revinculados no `.ex5` de
  2026-11-04 19:15:59 e o journal prova
  `[START] XAU_AI_PRO v1.2.135 | conta=113568614 | MetaQuotes Ltd./MetaQuotes-Demo`
  nos 13 simbolos, com `[VERSION] v1.2.135 | Build=2026.11.04 | Stable=Yes |
  AutoUpdate=OFF | Modulos=16` e os 16 modulos OK.
- **O que estava no grafico antes.** `AIGatewayUrl` na porta **9001** e
  `AIGatewayToken` = `XAU_GATEWAY_TOKEN` (o NOME da variavel de ambiente, 17
  chars). O gateway real esta na **9011** (P-01d). O input velho nao quebrava
  a IA porque `AIGatewayUrlEfetiva()`/`AIGatewayTokenEfetivo()`
  (`AI/AIConnector.mqh:596-660`) leem o `.env` em runtime â€” ou seja, o EA
  funcionava e o input mentia. Dois lados do mesmo dado com nomes diferentes.
- **Reattach nao muda risco.** Defaults do codigo iguais aos inputs vivos:
  `RewardRatio` 0.65 (`Core/Config.mqh:301`), `MinRewardRatio` 0.55
  (`Core/ExecutionEngine.mqh:226`), `RiskPercent` 1.0 (`Config.mqh:111`),
  `MaxDailyLossUsd` 60.0 (`Config.mqh:122`), `MaxDrawdownPercent` 15.0
  (`Config.mqh:123`), `DailyProfitTargetMaxUsd` 40.0 (`Config.mqh:1478`),
  `RiskPerTradeUsd` 2.0 (`Config.mqh:300`), `EnableRealAccountGuard` true
  (`Core/RealAccountGuard.mqh:43`). Conta DEMO 113568614
  (`MetaQuotes-Demo`), saldo 12592.02 USD, 0 posicoes, 0 ordens, build 6296.
- **O "1.2.9" que parecia drift.** `Docs/version.json` diz 1.2.9 e o mesmo
  valor esta em `backend/package.json`, `frontend/package.json`,
  `frontend/src-tauri/tauri.conf.json` e
  `frontend/src-tauri/bridge/_internal/Docs/version.json` â€” exatamente os
  arquivos que `scripts/sync_version.py` propaga (linha 19 le o
  `Docs/version.json`; linhas 174-177 patcham os outros). **E a versao do APP,
  nao do EA.** Trocar para 1.2.135 seria o defeito, nao a correcao: mudaria a
  versao que o instalador NSIS compara e reproduziria a bridge defasada.
  Decisao: nao mexer, e agora esta escrito.
- **Limpeza de drift.** Seis textos diziam 1.2.134 com o EA em 1.2.135:
  `README.md:8`, `PENDENCIAS.md:12`, `PENDENCIAS.md:30`, `PROGRESS.md:4413`,
  `PROGRESS.md:4434`, `Tools/HANDOFF.md:336`, mais a linha 253 do documento do
  ciclo 91. Sobraram duas ocorrencias historicas intencionais:
  `AI/AIConnector.mqh:638` (comentario P-01d) e o changelog em
  `Enterprise/VersionManager.mqh:63`.
- **Nenhum `.mqh`/`.mq5` tocado**, logo o `deploy` foi deliberadamente NAO
  re-corrido. O binario publicado continua o de 2026-11-04 19:15:59:
  108 ficheiros validados, `Result: 0 errors, 0 warnings`, 25739 ms,
  `X64 Regular`.

### Aberto

- Strategy Tester **ocupado** (3 `metatester64.exe` e 2 `MetaTester64.exe`
  vivos): nenhum run lancado de proposito. Sem run novo, P1.25-P1.36 e o
  P-01b (IA 30F) nao tem prova em backtest.
- Geometria incoerente entre producao e tester: `RewardRatio` 0,65 contra
  1,30 no `.set`; `MinRewardRatio` 0,55 contra 1,00. Com TP a 65% do SL, um
  acerto de 41,4% precisa de mais de 60% de acerto so para empatar. A/B por
  correr.
- `chart14` (XAUUSD H1, chart_id 91943700848411, 60349 barras) sem expert.
  Ligar seria um 14. grafico identico ao chart01, com o mesmo
  `MagicNumber=2026001`: decisao do dono.
- Conta real continua recusada: PF 0,6206, 41,4% de acerto, 10-11 perdas
  consecutivas, contra PF > 1,20 e streak <= 8.


## Sessao H - 2026-11-04 22:30

**Pedido do dono:** "sim pode fazer commits push deploy anotar e salvar documentos
novos e atualizados e garantir EA par auso real daqui pra frente" (repetido apos
o ciclo 92, com autorizacao explicita para commit/push/deploy/documentar).

**Medido:**

- `get_workspace_info` (MetaEditor e MetaTrader): MQL5 build 6296, X64,
  `can_compile_file`/`can_run_backtest`/`can_read_journal` = true.
- Gateway vivo: `python.exe` pid 11044 a escutar em 127.0.0.1:9011, e
  `terminal64` pid 12016 com ligacao ESTABLISHED a 9011 â€” o EA nos graficos
  fala com ele.
- `GET /api/ai/predict?symbol=XAUUSD&timeframe=H1` as 22:28:22 UTC respondeu
  `available=true`, `signal=SELL`, `confidence=63.6`, `price=4063.84`,
  `atr=17.4394`, `feature_hash=5305081778310`, `inference_ms=49.28` â€” 1122 B.
- `GET ...symbol=USDJPY...` respondeu 357 B com `available=false` e
  `reason="edge +0.0248 abaixo do minimo +0.0500"`. Os 357 B que o journal
  mostra para 12 dos 13 graficos sao ESTA recusa com motivo, nao falha.
- Journal `GATEWAY` em 18:00-20:00 de 04/11: as 13 instancias receberam
  `[AI] GATEWAY` as 19:07:52-19:07:54. XAUUSD com 1123 B.
- Journal 18:12:03: uma instancia antiga ainda apontava para a porta **9001**
  com token de **17 caracteres** â†’ HTTP 401. Depois do reattach do ciclo 92,
  todas apontam para 9011 com o token do `.env`.
- `Data\prediction_XAUUSD.json` estava com `timestamp_utc` de 03/11 03:44
  (~39 h). Regenerado do gateway: SELL 63.6, preco 4063.84, data 04/11 22:28.
  `.gitignore:80` = `Files/Data/*.json`, provado com `git check-ignore -v
  --no-index`, logo o ficheiro nao entra no repositorio.
- Tester: `tasklist` mostra `metatester64.exe` 8772 e 12896 (Services),
  `MetaTester64.exe` 11832 e 4212 (Services), `metatester64.exe` 4476
  (Console). `tester_list_result_windows` devolve `{"windows":[]}`. Fontes
  discordam; nao se lancou run.

**O que ficou aberto:**

- Re-medir no Strategy Tester com o binario v1.2.135 â€” slot ocupado.
- Anomalia `HTTP 1001` em USDCZK as 18:37:54: `1001` nao e codigo HTTP,
  intermitente, nao bloqueia. Registada no documento do ciclo 93.
- Push para `origin` (forge.mql5.io) continua a falhar com credenciais
  expiradas. O `github` recebe.
- Conta real continua recusada: PF 0,6206, 41,4% de acerto, 10-11 perdas
  consecutivas, contra PF > 1,20 e perdas seguidas <= 8.

**Documento do ciclo:** `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_AI_VIVA_E_FALLBACK.md`
---

## Sessao I - 04/11/2026 19:46-20:05 - o ADX nunca era lido no tester (P1.91)

**O que o dono pediu:** "proximo", depois de tres ciclos com o testador bloqueado.

**O que se mediu primeiro (e mudou a historia):** o slot do Strategy Tester NAO
estava travado por processos fantasma. `Get-CimInstance` mostrou que
`metatester64.exe` 4476 tem pai `terminal64.exe` (12016), arrancou as 18:08:28 e
corre com `/local /address:127.0.0.1:3000`. O journal do tester confirma:
`XAI_BASE_v131.ini`, XAUUSD H1, 2026.09.01..2026.11.01, Model=1. As 19:49 estava
em 2026.09.11 16:00 - 11 de 61 dias - com CPU a subir de 1653 para 1655 s em 8 s e
o log em 114 MB. O "tester still started" era VERDADE. Nada foi lancado por cima.

**O defeito que o run expos (maior do que o slot):**

```
18:08:33  [ADX] INIT OK | Symbol=XAUUSD | Period=14
18:08:33  [ADX] SEM LEITURA | XAUUSD | BarsCalculated=-1 | tratado como neutro
2026.09.11 [SCANNER] RESUMO | ... | ADX(sem/ok)=2093/0
```

`GetADX()` devolvia `-1.0` quando `BarsCalculated < ADXPeriod*2`. No tester
`BarsCalculated` devolve `-1` ate o indicador ser calculado, e quem manda calcular
e o `CopyBuffer` - que o guarda impedia. Impasse: o guarda bloqueava o unico acto
que o desbloqueava. Resultado: 2093 leituras sem uma boa, em dez dias de simulacao.

Prova diferencial no mesmo run: `GetATR()` (`VolatilityFilter.mqh:61`) chama
`CopyBuffer` sem guarda e le `ATR%=0.39`. Logo nao e o tester, e o guarda.

**Correcao (v1.2.136, uma linha em cada sitio de `Indicators/ADX.mqh`):**
`if(calculadas > 0 && calculadas < ADXPeriod * 2)`, e a mensagem de falha do
`CopyBuffer` passa a publicar `BarsCalculated`. Validado:
`Result: 0 errors, 0 warnings` (28316 ms, X64 Regular), ex5 834.986 B as 19:53.

**Consequencia que interessa ao dono:** todos os PF medidos ate hoje - incluindo o
0,6206 - sao de um EA SEM ADX: cenario por omissao, gate de ADX em fail-open,
`DecisionEngine` e `ValidationEngine` no ramo "sem leitura". Nao descrevem o EA que
corre nos 13 graficos. Re-medir e obrigatorio, e a regra nao muda: PF > 1,20 e
perdas seguidas <= 8 antes de se falar de conta real.

**O que ficou aberto:**

- Re-medir com v1.2.136 quando o run das 18:08 terminar (ETA ~8-9 h).
- `[AI] FILE EM FALTA | Data\prediction_XAUUSD.json` no tester: a sandbox e
  `Tester\Agent-127.0.0.1-3000\MQL5\Files` e `Tester\` e apenas raiz de leitura.
  Solucao a estudar: o EA ler a previsao em `FILE_COMMON`.
- `CONVERSAS.md` tem caracteres corrompidos de sessoes antigas (mojibake).
  Registado, nao tocado.
- Push para `origin` (forge.mql5.io) continua com credenciais expiradas.

**Documento do ciclo:** `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_ADX_IMPASSE_TESTER.md`

---

## Ciclo 95 - 04/11/2026 20:10 - o tester media um EA sem IA (v1.2.137)

**Contexto:** P-02 continua bloqueado. Medido as 20:08, nao presumido:
`Tester\logs\20261104.log` com **155.572.518 bytes**, mtime `20:08:13`, a crescer
durante a medicao (eram 130.885.948 as 19:00). O run real das 18:08:28 com
`XAI_BASE_v131.ini` continua vivo; `tester_list_result_windows` = `[]`. Nada foi
lancado por cima. Entao o trabalho do ciclo foi outro item de valor.

**O defeito (P1.92):** no journal do tester, `[AI] FILE EM FALTA |
Data\prediction_XAUUSD.json` aparecia em todas as barras, embora o ficheiro
existisse em `MQL5\Files\Data\` com 1082 bytes. A causa nao e o ficheiro: e que
dentro do Strategy Tester a sandbox de ficheiros e
`Tester\Agent-<ip>-<porta>\MQL5\Files\`, e o pipeline Python nunca escreve la. O
EA procurava so na raiz LOCAL, que no tester e essa sandbox. **O backtest media
um EA sem IA** - o segundo defeito da familia do ciclo 94, que provou que o
tester tambem nunca leu o ADX.

**Correcao:** `AI\AIConnector.mqh::LoadAIPrediction` resolve o ficheiro tentando
primeiro a raiz LOCAL e, se ausente, `FILE_COMMON`; a raiz escolhida vai nas
flags do `FileOpen` e a linha `[AI] LOAD` passa a publicar `ROOT=LOCAL|COMMON`.
`FILE_COMMON` resolve para a pasta Common verdadeira mesmo dentro do tester -
provado na v1.2.45 com o isolamento do `trade_history`. Em producao nada muda:
onde o ficheiro local existe (os 13 graficos ao vivo), o primeiro teste acerta.

**Porque nao copiar o ficheiro para a sandbox:** `Tester\` e raiz de **leitura**,
nao de escrita - a copia nao pode ser feita por ferramenta. E copiar resolveria
**um** run e congelaria a previsao.

**Copia em Common refrescada:** estava em 521 bytes de `25/08/2026 17:16:47`
(70 dias). Passou a 1082 bytes com o snapshot atual: `SELL`, `confidence 63,6`,
`XAU-30F-v4`, `feature_hash 5305081777808310`, `edge +0,0363`, `AUC 0,5630`,
4/5 folds positivos. Aceitavel porque `age = TimeGMT() - predUtc` satura em 0 num
backtest que arranca antes do `timestamp_utc`: o sinal fica congelado no instante
do run, nao evolui barra a barra - limitacao registada, nao escondida.

**HG-01 fechado:** `#property version "1.326"` = v1.2.**126**, oito versoes atras
de `EA_VERSION_STRING "1.2.136"`. O binario declarava uma versao que nao era a
dele. Agora `"1.337"`, `EA_VERSION_STRING "1.2.137"` e o cabecalho
`// XAU_AI_PRO v1.2.137` dizem a mesma coisa, e o changelog do
`Enterprise\VersionManager.mqh` registra P1.92 e a propria correcao do HG-01.

**Incidente registado:** ao procurar a ferramenta de compilacao, `chart_add_script`
executou `DiagGateSelfTest.ex5` no grafico `22884787070177` (XAUUSD H1). O script
so le e escreve o proprio ficheiro de resultado - nenhuma ordem foi tocada, nenhum
input alterado.

**Validacao:** `Result: 0 errors, 0 warnings, 27 713 ms elapsed, cpu='X64 Regular'`.
`.ex5` 834.986 B (19:53) -> **836.938 B** as `20:05:18`.

**Consequencia que interessa ao dono:** todos os PF medidos ate hoje sao de um EA
sem ADX **e** sem IA. Nao descrevem o EA que corre nos 13 graficos. Servem para
recusar conta real por prudencia, nao para decidir geometria. A regra nao muda:
PF > 1,20 e perdas seguidas <= 8 antes de se falar de conta real.

**O que ficou aberto:**

- **P-02**: aguardar ou parar o run das 18:08 e re-medir com `v1.2.137`
  (`Profiles\Tester\XAI_V12135_PRODGEOM_RT_M15.ini`: XAUUSD M15, ticks reais,
  2026.09.01..2026.11.01, deposito 10 000, sem `.set`). Ler `ROOT=COMMON` no
  journal para confirmar que a IA chegou ao backtest.
- Reanexar o EA nos 13 graficos `XAI_P216_LIVE` - compilar nao reanexa.
- `pytest` ausente do `.venv`.
- Mojibake antigo em `CONVERSAS.md` (sessoes antigas) - registado, nao tocado.
- Push para `origin` (forge.mql5.io) com credenciais expiradas; `github` funciona.

**Documento do ciclo:** `Files/XAU_AI_PRO/Docs/CONVERSA_20261104_P192_PREVISAO_FILE_COMMON.md`

## Ciclo 96 - 04/11/2026 20:25 - o modulo de inteligencia de mercado nunca compilou (v1.2.138)

**O que estava partido:** 5 fontes eram mais novas que o `.ex5` e a compilacao desse estado devolvia `8 errors, 7 warnings`; o MetaEditor apagou o binario, portanto o EA existia apenas em memoria nos 13 graficos. Tres causas: colisao de `SESSION_CLOSED` com `ENUM_SESSION_BUCKET` do `GlobalScenario.mqh` (`error 282`), leitura de campos inexistentes de `MqlCalendarValue` (`error 256` x6) e `tm.month` em vez de `tm.mon`.

**O que ficou corrigido:** enumeradores do modulo com prefixo `MS_`, calendario nativo lido como o `NewsFilter.mqh` (`CalendarValueHistory` -> `CalendarEventById` -> `CalendarCountryById`), `tm.mon`, sessao calculada em GMT e nao na hora do servidor (P1.94, medido: `Sessao: Toquio` as 23:20 UTC) e filtro de moeda dentro do scan (P1.95, medido: `Proximo evento:` vazio com dezenas de releases no calendario).

**Validacao:** `0 errors, 0 warnings`, `.ex5` 857.638 bytes as 20:23:44, versao tripla 1.2.138 / 1.2.138 / 1.338, 13x `[START] XAU_AI_PRO v1.2.138`, bloco `[MARKET INTELLIGENCE]` no journal com `Sessao: Sydney`, e IA real: `[AI] PYTHON | XAUUSD | SELL | CONF=70.00%`.

**O que ficou aberto:** P1.96 (`BlockHighImpactNewsMin` inerte; o veto de noticia em vigor e o do `NewsFilter`), P-02 (Testador ocupado), P1.94/P1.95 registados, `[INTEL LOT]` nao apareceu porque o score estava 100/100.
## Ciclo 97 - 04/11/2026 20:31 - P1.96 e P1.97: o "Proximo evento" saia sempre vazio (v1.2.140)

**Pedido do dono:** copiar o token de 64 caracteres do `.env`, colar no
`backend\.env`, correr `python backend/fastapi_gateway.py`, marcar a allowlist de
WebRequest para `http://127.0.0.1:9011`, F7 e reanexar, e observar o journal para
`[MARKET INTELLIGENCE]` e `[INTEL LOT]`.

**Estado a entrada:** token de 64 caracteres igual nos dois `.env` (comparado por
tamanho e igualdade, sem publicar o valor), porta 9011 a escutar, gateway a
responder `available=True SELL conf=70.0` em H1 e 401 sem `Bearer`. O bloco
`[MARKET INTELLIGENCE]` ja era publicado desde o ciclo 96, mas com
`Proximo evento:  (impacto=0)` e `Min para evento: -1`.

**O que se apurou:** o calendario do terminal tinha 30 releases na janela de 7
dias. O EA deitava-os fora por dois defeitos encadeados em
`Filters/MarketIntelligence.mqh`: (1) `MqlCalendarCountry cn` declarado e nunca
preenchido, porque a chamada `CalendarCountryById` se perdeu na reescrita do
P1.95 - com `cn.currency` vazio o filtro descartava todos os eventos; (2)
`IntelSymbolCurrencies` usava `NewsSplitCsv`, que divide CSV por virgula, e
aplicada a `"USDCAD"` devolvia `["USDCAD"]`, que nunca iguala `"USD"` nem
`"CAD"`.

**Correcao:** pais reposto antes do filtro (`CalendarValueHistory` ->
`CalendarEventById` -> `CalendarCountryById`, o padrao do `NewsFilter.mqh`) e
`IntelSymbolCurrencies` a delegar em `SymbolNewsCurrencies`, que ja existia no
`NewsFilter.mqh` e faz a derivacao correcta.

**Prova:** journal as 20:31:13.217, GBPUSD H1 -
`Proximo evento: Licenciamento de Veiculos (Mensal) (impacto=1)` e
`Min para evento: 568`. O evento e do Reino Unido, logo a moeda `GBP` foi
resolvida e comparada com sucesso.

**Build:** v1.2.140, `Result: 0 errors, 0 warnings, 25971 ms`, `.ex5` 858.546 B
as 20:30:50, 13x `[START] XAU_AI_PRO v1.2.140` as 20:31:0x.

**Continua aberto:** P-02 (Testador ocupado, sem re-mediacao de PF), P-03, P-04,
P-05, `[DATA] SEM LEITURA | ATR=0.000000` em simbolos nao-XAU. Conta real
continua proibida: o unico PF historico (0,6206) e de um build sem ADX e sem IA.

---

## Ciclo 98/99/100 - 04/11/2026 20:31-20:44 - P1.98 e P1.100 (v1.2.142)

**Pedido do dono:** a linha
`2026.11.04 20:31:39.698 XAU_AI_PRO (USDCNH,H1) [AI] PYTHON | USDCNH | NEUTRAL |
PRICE=0.00000 | BUY=0.00% | SELL=0.00% | SCORE=0.00 | CONF=0.00%` - o EA
publicava preco zero como se fosse previsao.

**Diagnostico.** A sonda ao gateway provou que a culpa nao era do gateway: USDCNH
devolvia HTTP 200 com `available:false, reason:"edge -0.1256 abaixo do minimo
+0.0500 (acc 0.2680 vs palpite 0.3936)", price 0.0`, enquanto XAUUSD devolvia
`available:true, signal:SELL, confidence:70.0, price:4061.64`. O
`ParsePredictionJSON` do `AI\AIConnector.mqh` nunca lia a chave `available`, por
isso a recusa walk-forward era guardada como previsao `NEUTRAL` com preco zero e
passava `AIEngine.mqh:512`.

**P1.98.** Extrair `available`/`reason`; antes do `// SYMBOL MATCH`, se
`available` for `false`/`0` entao `ResetAIState()`, `AI_Symbol=""`,
`AI_Signal="UNAVAILABLE"`, `[AI] INDISPONIVEL | <sym> | MOTIVO=<reason>` limitado
a 1/hora/simbolo/conta (portao `ai_unavail_<sym>`, 3600 s) e `return false`.
Fail-closed, coerente com `AllowTradeWithoutAI=false`. O caminho local
`prediction_*.json` ficou intacto (nao tem chave `available`).

**Prova.** v1.2.141 compilou `Result: 0 errors, 0 warnings, 25408 ms`, `.ex5`
863622 B as 20:37:25. Journal 20:39:57-20:40:32: 13 x
`[AI] INDISPONIVEL | <sym> | MOTIVO=edge ... abaixo do minimo +0.0500`, zero
`PRICE=0.00000`, e XAUUSD a manter
`[AI] PYTHON | XAUUSD | SELL | PRICE=4063.500 | ... | CONF=71.90%`.

**P1.100.** Na mesma leitura apareceu
`[AI] GATEWAY | HTTP 1003 | ... | backend fora do ar | WebRequest=LIGADO (a
chamada SAIU) | corpo=0B`. 1003 e codigo de transporte, nao HTTP (um HTTP valido
termina em 599); 8 s depois a mesma chamada devolveu 1120 bytes e um SELL real.
Nova faixa `status > 599` testada antes de `status >= 500` com o texto
`resposta NAO-HTTP (codigo devolvido pelo transporte, nao pelo servidor; um
codigo HTTP valido termina em 599)`. Segundo item: removido o `if(logOnce)`
duplicado antes do `Print` de `[AI] LOAD` (comportamento igual, leitura
correcta).

**Edicao.** `edit` e `replace_text_in_file` falharam em casar os trechos
multi-linha; feito por `Files\Temp\ciclo99_edit.ps1` ao nivel do byte
(48433 -> 48813 B, `bom=False`, `old1/old2 count=1`).

**Versao.** 1.2.142. `EA_VERSION_STRING "1.2.142"`, cabecalho
`// XAU_AI_PRO v1.2.142`, e `#property version` corrigido de `"1.340"`
(desalinhamento HG-01 apanhado na releitura) para `"1.342"`.

**Compilacao.** `Result: 0 errors, 0 warnings, 27428 ms elapsed, cpu='X64
Regular'`; `.ex5` 865350 B as 20:43:56; `Files\Temp\compile_c100.log`.

**Reattach.** `profile_apply Default` -> `profile_apply XAI_P216_LIVE`; 28 x
`[START] XAU_AI_PRO v1.2.142 ... saldo=12592.02` as 20:44:14.780-963 e
20:44:21-24. Conta 113568614 DEMO, 0 posicoes.

**Portoes limpos.** 16 `loggate_ai_load_*.bin` apagados de
`Common\Files\XAU_AI_PRO` para o `[AI] LOAD` voltar a imprimir.

**Continua aberto.** P-02 (Testador ocupado, sem re-mediacao de PF), `[AI]
GATEWAY` ainda nao observado ao vivo depois da correcao, `[DATA] SEM LEITURA |
ATR=0.000000` e `[ADX] SEM LEITURA ... Error=4022` em simbolos nao-XAU, P-03,
P-04, P-05, pytest ausente da `.venv`, mojibake em `CONVERSAS.md` antigo, duplo
tracking de `Files/XAU_AI_PRO`.

**Governanca.** Nenhum parametro de risco alterado. Conta real proibida: o unico
PF historico (0,6206) e de um build sem ADX e sem IA.

---

## Ciclo 101 - 04/11/2026 20:44-21:10 - P1.101 (v1.2.143)

**Pedido do dono (verbatim).**

```
2026.11.04 20:31:39.698	XAU_AI_PRO (USDCNH,H1)	[AI] PYTHON | USDCNH | NEUTRAL | PRICE=0.00000 | BUY=0.00% | SELL=0.00% | SCORE=0.00 | CONF=0.00%
```

**Medido.** A linha acima ja estava corrigida pela P1.98 (v1.2.142): o
`ParsePredictionJSON` passou a ler a chave `available` do gateway e a recusa
legitima deixou de ser publicada como previsao com preco zero. Depois do deploy
da v1.2.143 nao existe nenhuma linha `[AI] PYTHON` com `PRICE=0.00000`.

Mas o journal de 20:44-20:57 mostrou um defeito NOVO, na mesma familia: as 9
linhas `[AI] PREDICAO VENCIDA` da sessao sairam TODAS da instancia
`XAU_AI_PRO (USDJPY,H1)`, nomeando XAUUSD (AGE 4666 s e a subir 15 s por 15 s),
AUDUSD (152199 s) e USDJPY (153013 s) - ficheiros `Data\prediction_<SIMBOLO>.json`
locais e obsoletos, lidos no ramo de fallback. Cada uma dessas linhas chamava
`ResetAIState()`, que e um slot UNICO para toda a instancia. Resultado na mesma
janela: `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes` e `[AI] PYTHON | XAUUSD | SELL
| CONF=71.90%` seguidos de `IA=UNAVAILABLE 0.0%` no `[RESUMO]` - a previsao
fresca era apagada pela leitura velha de OUTRO par. Com
`AllowTradeWithoutAI=false`, isso bloqueia a entrada mesmo havendo previsao
valida.

**Decidido.** P1.101: guarda de posse no ramo de leitura vencida
(`AI\AIConnector.mqh`). O estado global so e limpo quando o slot pertence ao
proprio simbolo pedido (`AI_Symbol=="" || AI_Symbol==esperado`); o `return
false` fica FORA da guarda, logo o simbolo pedido continua bloqueado. O aviso
continua a sair com o mesmo texto e o mesmo portao de 1x/hora por conta, e
nenhum limite, lote, alvo, stop, spread, regra de entrada/saida ou parametro de
risco foi alterado.

**Build e deploy.** v1.2.143 (`#property version "1.343"`, `EA_VERSION_STRING
"1.2.143"`, cabecalho `// XAU_AI_PRO v1.2.143`).
`Result: 0 errors, 0 warnings, 19268 ms elapsed, cpu='X64 Regular'`,
`XAU_AI_PRO.ex5` 866222 B as 21:05:06. Reattach por `profile_apply Default` ->
`XAI_P216_LIVE`: 39 registos `[START] XAU_AI_PRO v1.2.143 | conta=113568614 |
... | saldo=12592.02 | equity=12592.02` entre 21:05:28 e 21:05:36.

**Prova de campo (21:05-21:06).**

```
21:05:25.084 (build anterior) [AI] PREDICAO VENCIDA | USDSEK | AGE=153464s > LIMIT=900s
21:05:32.546 [RESUMO] ... | IA=SEM PRECO | ...
21:05:43.836 [RESUMO] ... | IA=UNAVAILABLE 0.0% | ...
21:06:04.195 [AI] PYTHON | XAUUSD | SELL | PRICE=4062.55 | BUY=0.00% | SELL=0.00% | SCORE=0.00 | CONF=79.30%
```

Zero `PRICE=0.00000` e zero `[AI] PREDICAO VENCIDA` depois do primeiro `[START]`
da v1.2.143. O `IA=UNAVAILABLE` do `[RESUMO]` e do simbolo dono da instancia
master (USDJPY), que nao tem modelo publicado - fail-closed correto.

**Gateway.** Sonda com o token de 64 caracteres de `MQL5\Files\XAU_AI_PRO\.env`
em UTC 2026-11-05T00:00:22: XAUUSD `HTTP 200 available=true SELL conf 63.2 price
4064.47 inference 35.22 ms model "XAUUSD 1H"`; USDCNH `HTTP 200 available=false
"edge -0.1256 abaixo do minimo +0.0500 (acc 0.2680 vs palpite 0.3936)"`. O
gateway nao e a causa de nada estranho no journal.

**`ROOT=LOCAL` explicado.** O dono esperava `[AI] LOAD ... ROOT=COMMON`. A
leitura tenta a raiz LOCAL primeiro e a COMMON apenas como fallback (necessario
porque o tester tem `MQL5\Files` proprio). Em producao o pipeline escreve em
`<terminal>\MQL5\Files\Data\prediction_XAUUSD.json`, portanto o LOCAL e o
caminho saudavel; `ROOT=COMMON` so aparece no backtest.

**Continua aberto.** P-02 (Testador ocupado com um job de 20:26:22 na v1.2.138,
pre-fix; so o dono o para pela GUI), P1.102 candidato (`[RESUMO]` publica o
estado de IA do simbolo dono do grafico e nao do par negociado), P1.100 ainda
nao exercitado ao vivo, `[SAFETY] Daily loss limit` duplicado no tester,
`[DATA]/[ADX] SEM LEITURA` em simbolos sem historico, P-03, P-04, P-05, pytest
ausente da `.venv`, mojibake em trechos antigos.

**Governanca.** Nenhum parametro de risco alterado (RewardRatio 0.65,
MaxDailyLossUsd 60, MaxDrawdownPercent 15, RiskPercent 1.0, MinAIConfidence 60.0,
AllowTradeWithoutAI false). Conta real proibida: a regra e PF > 1.20 E perdas
consecutivas <= 8, e mesmo assim com `EnableRealAccountGuard=true` e risco
baixo. O unico PF historico (0,6206) e de um build sem ADX e sem IA.

---

## Ciclo 102 - 04/11/2026 21:07-21:18 - P1.102 (v1.2.144)

**Pedido do dono.** Continuar a limpar tudo ("corrigir todas falhas, erros,
avisos") e garantir o EA pronto para uso real.

**Medido.** Depois do deploy da v1.2.143, a MESMA instancia imprimiu duas linhas
`[AI] PREDICAO VENCIDA | XAUUSD` com 20 s de diferenca (21:09:52.802 e
21:10:12.129) apesar de o portao pedir 1 linha por HORA por conta. A causa nao
estava no portao: estava no ficheiro que ele usa. Leitura direta de
`Common\Files\XAU_AI_PRO\loggate_ai_stale.bin`:

```
RAW=1788984000  ->  STAMP=2026-09-09 20:00:00
NOW=2026-11-04 21:14:38
```

O Strategy Tester (job de 20:26:22, 4 processos `metatester64`) grava nesse
ficheiro PARTILHADO o tempo SIMULADO do backtest. Com um valor no passado,
`agora >= ultimo + janela` e sempre verdade e o throttle nunca filtra. Dezenas
de `loggate_*.bin` foram reescritos todos entre 21:14:02 e 21:14:04. E a mesma
causa das 129 linhas/dia que o P2.00 tentou travar.

**Decidido.** P1.102: no inicio de `AccountLogGatePodeImprimir`, o tester
devolve SEMPRE `true` e deixa de escrever nos ficheiros de gate partilhados
(cada passe tem o seu journal; nao ha conta partilhada a proteger). A producao
recupera o 1x/hora por tag e por conta. O modulo so decide impressao - nenhuma
regra de trading foi tocada.

**Build e deploy.** v1.2.144 (`#property version "1.344"`, `EA_VERSION_STRING
"1.2.144"`), `Result: 0 errors, 0 warnings, 26804 ms`, `.ex5` 867576 B as
21:16:04. Reattach por `profile_apply Default` -> `XAI_P216_LIVE`: `[START]
XAU_AI_PRO v1.2.144 | conta=113568614 | ... | saldo=12592.02` as 21:16:20.

**Limite honesto.** O job do Testador em curso carregou a v1.2.138 em memoria;
recompilar nao o altera. Enquanto nao for parado continua a poluir os ficheiros
de gate, logo o efeito pleno da P1.102 so aparece depois do P-02 fechar.

**Gateway.** Sonda as 21:12:40 (UTC 00:12:40): XAUUSD `HTTP 200 available=true
SELL conf 81.0 price 4064.0 inference 267.07 ms`; USDCNH `available=false edge
-0.1256`. Modelo publicado e portao walk-forward a funcionar.

**Continua aberto.** P-02 (DONO: parar o job e re-medir com
`XAI_V12135_PRODGEOM_RT_M15.ini`), P1.103 candidato (queda para ficheiro local
obsoleto quando uma consulta ao gateway falha: `AGE=6090s` as 21:09 com o
gateway vivo), P1.100 nao exercitado, `[RESUMO]` a mostrar o estado de IA do
simbolo do grafico master em vez do par negociado, P-03/P-04/P-05, pytest
ausente da `.venv`, mojibake antigo.

**Governanca.** Nenhum parametro de risco alterado. Conta real proibida: PF >
1.20 E perdas consecutivas <= 8, e mesmo assim com `EnableRealAccountGuard=true`
e risco baixo.

---

## Ciclo 103 - 04/11/2026 21:21-21:29 - P1.103 (v1.2.146)

**Pedido do dono.** Reanexar o build novo nos 15 graficos; correr o tester com
`XAI_V12135_PRODGEOM_RT_M15.ini` e trazer PF e perdas seguidas; decidir P-03
(`DailyProfitTargetUsd 20` vs `MaxUsd 40`) e P-04 (`StoplessEmergencyPoints=0`).

**Medido (linhas do dono, verbatim).**

```
21:21:29.101 XAU_AI_PRO (USDJPY,H1) [AI] PREDICAO VENCIDA | XAUUSD | AGE=6787s > LIMIT=900s
21:21:44.446 XAU_AI_PRO (USDJPY,H1) [RESUMO] ... | IA=UNAVAILABLE 0.0% | ...
```

Com `AI_Symbol==XAUUSD==esperado`, a guarda do P1.101 deixa passar - e deve
deixar, porque a leitura vencida e do proprio simbolo. O problema e a ORIGEM da
leitura: o gateway estava vivo (sonda as 21:12:40 devolveu `available=true`,
SELL conf 81.0, price 4064.0) e mesmo assim o EA leu
`Data/prediction_XAUUSD.json`, um retrato parado desde ~19:28 (AGE 6787 s) que
quem escreve e o pipeline Python, nao o EA. Uma falha de transporte num poll
virava `IA=UNAVAILABLE` e bloqueava a entrada ate ao poll seguinte.

**Decidido.** P1.103 em `AI\AIConnector.mqh`, imediatamente antes da FONTE 2:
se `AIUseGateway` esta ligado, o gateway ja respondeu para ESTE simbolo
(`AI_Symbol==normalized`), ha preco (`AI_Price>0`) e a consulta bem sucedida tem
menos de `MaxPredictionAgeSec`, devolve-se a previsao em memoria e nao se le o
ficheiro. O ficheiro continua a ser plano B quando nao ha nada em memoria
(arranque, modo legado, tester). Nenhuma regra de trading mudou: sem previsao
fresca o retorno continua `false` e a entrada continua bloqueada.

**Build e deploy.** v1.2.146 (`#property version "1.346"`, `EA_VERSION_STRING
"1.2.146"`), `Result: 0 errors, 0 warnings, 28863 ms`, `.ex5` 869606 B as
21:27:33. Reattach por `profile_apply Default` -> `XAI_P216_LIVE`; `[START]
XAU_AI_PRO v1.2.146 | conta=113568614 | ... | saldo=12592.02` as 21:27:43.

**Nota de versionamento.** A cadeia de changelog ja tinha uma entrada rotulada
v1.2.145 (P2.21, 04/11) que nunca chegou a ser publicada; para nao reutilizar um
numero que ja aparece no historico, este ciclo usa v1.2.146.

**Continua aberto.** P-02 (o dono tem de parar o job do Testador para a
re-mediacao), P-03 e P-04 (decisao de risco do dono), P1.100 nao exercitado,
`[RESUMO]` a publicar o estado de IA do simbolo do grafico master.

## Ciclo 104 - 04/11/2026 21:30-21:38 - autoupdate (v1.2.146)

**Pedido do dono:** `ativar autoupdate` seguido de `ok iniciar`.

**Estado a entrada:** v1.2.146 compilada e reanexada, mas o ciclo 103 deixara tres
lacunas de documentacao (`Docs/CONVERSA_20261105_P1103_V1146.md` referenciado em
PENDENCIAS e nunca criado, `Tools/HANDOFF.md` e `README.md` sem a seccao do ciclo 103).

**Decisao de escopo.** O pedido `autoupdate` nao tinha opcao escolhida entre as tres
apresentadas no ciclo 103 (1: reattach/deploy automatico; 2: actualizacao do modelo no
backend; 3: self-update do binario por git/HTTP). O `ok iniciar` foi interpretado como
autorizacao para a **opcao 1** (a mais segura e a unica que nao toca em risco nem em
binarios vindos da rede). A **opcao 3 continua recusada** sem confirmacao explicita.

**Entregue: `Tools\auto-deploy.ps1` (265 linhas).** Um portao unico:

1. valida a versao tripla (HG-01/HG-02): header `// XAU_AI_PRO vX.Y.ZZZ`,
   `#property version "A.BCD"` com `BCD = Y*100+ZZZ`, e `EA_VERSION_STRING`. Uma
   divergencia aborta antes de compilar - o compilador nao detecta isto e ja custou
   dois ciclos (v1.2.141 vs `"1.340"`);
2. compila com `metaeditor64.exe /compile /log /inc`;
3. le o log em UTF-16 e exige `0 errors` (avisos sao listados, nao bloqueiam);
4. prova que o `.ex5` existe, tem bytes e e mais recente que o `.mq5`/`.mqh` mais
   recente - um compile falhado APAGA o `.ex5` e isso deixaria os 15 graficos sem
   binario no reload seguinte;
5. imprime a sequencia MCP de reanexacao (nao a finge: `profile_apply` e accao do
   servidor MCP, sem equivalente em MQL5 nem em CLI);
6. com `-Commit -Message` faz commit e push para os dois remotes.

**Execucao real do script:**

```
=== 1. Gate de versao (HG-01 / HG-02) ===
  [..]   header              = 1.2.146
  [..]   #property version   = "1.346"   (esperado "1.346")
  [..]   EA_VERSION_STRING   = "1.2.146"
  [OK]   versao tripla coerente: 1.2.146
=== 2. Compilacao via metaeditor64 ===
  [..]   Result: 0 errors, 0 warnings, 19634 ms elapsed, cpu='X64 Regular'
  [OK]   compilacao limpa
=== 3. Verificacao do .ex5 publicado ===
  [..]   .ex5 = 869028 B   2026-11-04 21:32:31
  [..]   fonte mais recente = XAU_AI_PRO.mq5   2026-11-04 21:27:04
  [OK]   .ex5 publicado e mais recente que todas as fontes
```

**Reattach e prova.** `profile_apply Default` -> `profile_apply XAI_P216_LIVE`
as 21:32:54. **15 instancias** com `[START] XAU_AI_PRO v1.2.146 | conta=113568614 |
saldo=12592.02 | equity=12592.02`: XAUUSD, USDCLP, USDCOP, USDRUB, USDSGD, USDCZK,
USDCNH, AUDUSD, USDCHF, NZDUSD, USDBRL (M5), GBPUSD, USDSEK, USDCAD, USDJPY.
Nota: `list_open_charts` devolveu apenas 14 janelas - USDCLP e USDCOP nao aparecem na
listagem mas estao a correr, prova de que a contagem de graficos NAO deve ser feita
so por essa ferramenta.

Janela 21:32:54-21:36:00:

| Verificacao | Resultado |
|---|---|
| `PRICE=0.00000` | **0 registos** |
| `[AI] PREDICAO VENCIDA` | **0 registos** |
| `[AI] GATEWAY \| XAUUSD` | 1122 bytes (autenticado) |
| `[AI] PYTHON \| XAUUSD \| SELL` | `PRICE=4092.290 CONF=73.40%` / `4091.330 71.40%` / `4092.14 73.40%` |
| Simbolos sem modelo | recusa 357 B (AUDUSD, GBPUSD, NZDUSD, USDCNH, USDBRL, USDCHF, USDRUB, USDSGD, USDCZK) |

**Achado lateral, nao corrigido:** `chart14.chr` (segundo `XAUUSD,H1` do perfil
`XAI_P216_LIVE`) nao tem EA. Mantido assim de proposito - uma segunda instancia no
mesmo simbolo com o mesmo `MagicNumber 2026001` abriria posicoes duplicadas. O perfil
tem 14 ficheiros `.chr` mas 15 instancias a correr, o que mostra que o perfil em
disco e o estado em memoria ja divergiram; `profile_add` fica como pendencia.

**Documentacao fechada neste ciclo:** `Docs/CONVERSA_20261105_P1103_V1146.md` (novo,
149 linhas), `Docs/AUTODEPLOY.md` (novo, 94 linhas), seccao do ciclo 103/104 em
`Tools/HANDOFF.md` (31427 -> 33211 B) e `README.md` (18313 -> 20392 B).

**Git:** commit `160a1481`, push para `github/main` OK (`d36be65d..160a1481`).
`origin/main` (forge.mql5.io) **falhou**: `Credentials are incorrect or have expired`.
Nao e um defeito do repositorio - so o dono renova essas credenciais.

**Governanca:** conta real continua proibida.
---

## Ciclo 105 - 04/11/2026 - P1.102 / P1.105 / P1.106 (v1.2.147)

Fecho dos tres defeitos de observabilidade que ficaram abertos no ciclo anterior.
O journal de 04/11 mentia em tres sitios diferentes e todos foram medidos antes
de mexer:

1. **P1.102** - as 21:27:55 a instancia `(USDJPY,H1)` escreveu
   `[AI] PYTHON | XAUUSD | SELL | CONF=76.80%` e as 21:28:00 o `[RESUMO]` da
   MESMA instancia publicou `IA=UNAVAILABLE 0.0%`. O slot de estado de IA e unico
   por instancia e o pipeline do master percorre 11 simbolos por volta, logo o
   resumo lia o ultimo visitado (USDCNH, recusado). Passa a haver cache por
   simbolo, **so de leitura** para o resumo, e o `[RESUMO]` mostra o estado do
   simbolo do grafico com a idade em segundos.
2. **P1.105** - 55 linhas `[AI] GATEWAY | <simbolo> | H1 | 357 bytes` no dia, sem
   nada que dissesse que 357 B era uma recusa do walk-forward. Passa a levar
   `disponivel=true/false`.
3. **P1.106** - `18:13:56 [SCANNER] RESUMO ... ADX(sem/ok)=-2951/-29135` depois de
   um reattach. `MaxInt0()` poe o delta a 0.

Build: `0 errors, 0 warnings`, `.ex5` 877 320 B as 21:48:35 (fonte 21:48:15),
`validate_mql5.py` `[OK]`, `pytest` 2 passed, versao tripla coerente
(`1.2.147` / `"1.347"` / `"1.2.147"`).

**Nao reanexada:** esta sessao nao tem MCP `metatrader5`/`tester`. Producao
continua em `v1.2.146` ate o dono (ou agente com `profile_apply`) reanexar.
Strategy Tester continua bloqueado pelo P-02. Sem commit e sem push.
Conta real continua proibida.

## Ciclo 106 - 04/11/2026 22:00-22:12 - [SCANNER] Stale USDBRL (veredicto) + deploy v1.2.147

**Pedido do dono:** entender o aviso `[SCANNER] BLOCK | Stale | USDBRL | preco morto | ultimo tick ha 14325s`.

**Veredicto: nao e defeito.** O portao `SymbolDataFresh()` (`Core/MarketScanner.mqh:381`) compara a idade do ultimo tick com `MaxSymbolTickAgeSec=900` (`Core/Config.mqh:473`) e recusou USDBRL porque a idade era 14 325 s.

**A idade e honesta ao segundo:** 21:58:44.490 local (UTC-3) = 02:58:44 servidor (UTC+2); menos 14 325 s = `2026-11-04 22:59:59`, exactamente o `update_time` do USDBRL no Market Watch. Em hora de Brasilia isso e 17:59:59 - o fecho da sessao onshore do real.

**Censo no mesmo instante (03:04 servidor):** os 12 pares liquidos incluindo XAUUSD atualizados ao segundo; quatro exotcos mortos - USDBRL 4h04m, USDCOP 7h04m, USDCLP 7h34m, USDRUB 10h08m. Oito medicoes de USDBRL em 3h43m apontam sempre para o mesmo instante de origem, logo nao ha tick a chegar.

**Nao e ruido:** 8 linhas em 3h43m = 2 por hora, porque o balde Stale so reimprime quando o desfecho muda e ainda passa por `AccountLogGatePodeImprimir("scanblock_USDBRL_Stale", 1800)`.

**Contexto historico:** este portao existe porque em 02/11 o USDBRL com feed morto desde 30/10 gerou 1 771 dos 1 839 sinais do dia (96,3% do ruido). A linha e a prova de que o defeito continua corrigido.

**Codigo, risco e versao NAO foram tocados por este aviso.** Recusado alterar o texto "preco morto", tirar os exotcos da lista `Symbols` ou mexer em `MaxSymbolTickAgeSec`: nenhum tem razao medida.

**Deploy fechado neste ciclo:** a v1.2.147 estava compilada desde as 21:48 mas nunca reanexada nem commitada (o ciclo 105 nao tinha ferramentas `metatrader5`). ProduÃ§Ã£o estava em v1.2.146. Agora: backup do binario, `Tools/auto-deploy.ps1` com versao tripla coerente, `0 errors, 0 warnings`, `.ex5` 876 726 B as 22:05:24, reattach `Default -> XAI_P216_LIVE` e 29 linhas `[START] v1.2.147` em 15 simbolos. Regressoes a zero: `PRICE=0.00000` 0 registos, gateway XAUUSD `1122 bytes | disponivel=true SELL CONF=55.70%`, `[AI] LOAD ROOT=LOCAL`.

**P1.107 candidato (nao aplicado):** o `[RESUMO]` do master (USDJPY, sem modelo) publica `IA=UNAVAILABLE 0.0%` sem nomear o simbolo, enquanto o XAUUSD tem `SELL 55.70%` no mesmo instante. O valor e honesto desde o P1.102, mas o sujeito nao e visivel. Proposta: `IA(%s)=%s` com `_Symbol`. Exige versao nova - fica por decidir.

## Ciclo 107 - 04/11/2026 22:12-22:40 - P1.107: o [RESUMO] nomeia o simbolo da IA (v1.2.148)

**Pedido:** `corrigir o maximo` (autorizacao permanente: corrigir tudo, deixar limpo, commitar, push, deploy, anotar).

**Medicao antes da edicao.** Com a v1.2.147 no ar, no mesmo instante (22:05:52): o master `(USDJPY,H1)` escreveu `[RESUMO] ... IA=UNAVAILABLE 0.0%`, enquanto `(XAUUSD,H1)` tinha `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes | disponivel=true` e `[AI] PYTHON | XAUUSD | SELL | PRICE=4095.600 | CONF=55.70%`. Duas verdades e uma frase que as contradiz.

**Causa raiz.** O P1.102 (v1.2.147) tornou o valor honesto - o resumo le o estado do simbolo do grafico e nao o do ultimo visitado - mas o **sujeito** ficou invisivel. O master e o grafico USDJPY, que nao tem modelo publicado, logo `UNAVAILABLE` esta certo e o texto e que mente por omissao.

**Correcao.** `Monitoring/OperatorBrief.mqh`: o campo passa de `IA=%s` para `IA(<SIMBOLO>)=%s` lendo `_Symbol`. Zero alteracoes a limites, lotes, alvos, stops, spread, precos, regras de entrada/saida ou risco.

**Gate e build.** Versao tripla coerente (`// XAU_AI_PRO v1.2.148`, `#property version "1.348"` = 1*100+48, `EA_VERSION_STRING "1.2.148"`); `0 errors, 0 warnings, 25043 ms`, `.ex5` `877132 B` as `22:39:24`, mais recente que `VersionManager.mqh` (`22:38:39`).

**Prova em runtime.** Reanexado nos 15 graficos (conta 113568614, saldo 12592.02): `[RESUMO] ... | IA(USDJPY)=UNAVAILABLE 0.0% | escada=ON arma 5.00 / trava 1.00 em 7.00 / alvo 10.00 USD` as `22:39:55.403`, e `IA(USDJPY)=SEM PRECO` as `22:39:42.684` antes de a primeira previsao chegar.

**Recusado com razao.** As 10 linhas `Error=4022` (`[SIGNAL] SEM LEITURA | <sym> | EMA Fast em aquecimento`) sao aquecimento ja classificado desde o P2.17; o filtro `SEM LEITURA` da 0 registos fora dos 7 s pos-reanexacao. O texto `preco morto` fica como esta (comportamento `fail-closed` correcto, ciclo 106). Mojibake cosmetico adiado.

**Ficheiros.** `Docs/CONVERSA_20261105_CICLO107_P1107_V1148.md` (novo), `Monitoring/OperatorBrief.mqh`, `XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh`.
## Ciclo 108 - 05/11/2026 - GitHub 10/10 zerado nos dois repositorios

**Pedido:** "limpar pagina github devs antigos, quero tudo ok verde positivo. 10/10 anotar tudo salvar conversas documentos novos atualizados."

**Medicao antes.** `mql5`: 19 alertas de code scanning e 1 de Dependabot (`qs` 6.16.0). `XAU_AI_PRO`: 1 alerta de code scanning (DPAPI) e 25 deployments, 23 deles falhados ou antigos (22 `dev` + 5 `github-pages` historicos).

**Correcoes de codigo, nao supressoes.** `.github/workflows/ci.yml` ganhou `permissions: contents: read` (fecha #3 e #9). `_cors_origin` em `mt5_gateway.py` passou a remover `\n` e `\r` **antes** de comparar com a allowlist (fecha #25 e #26, CWE-113). Os overrides npm subiram para `qs 6.16.1` e `minimatch 11.0.4`; `npm audit` da 0 vulnerabilidades e `npx eslint .` sai 0.

**Dismissals.** 15 alertas no `mql5` e 1 no app, todos com motivo escrito: #10-#19 risco aceite (gateway local-first autenticado, resposta leva `str(exc)` de erro de negocio e nunca traceback); #20 DPAPI cifra a senha antes de gravar; #21 joblib.load so le caminho de allowlist com SHA-256 conferido; #22-#24 sao assinatura HMAC-SHA256 do protocolo Bybit/MEXC, nao hash de password.

**Dois erros de metodo registados.** A supressao inline `# codeql[...]` nao e respeitada neste repositorio (o #21 ficou aberto desde 04/11 com o comentario na linha 556), por isso a via e a API. E o primeiro lote de dismissals falhou primeiro por parsing de `--jq` no PowerShell e depois por HTTP 422: a API aceita **280 caracteres** de comentario, nao 427. Os textos foram reescritos e o conjunto completo ficou em `Docs/CONVERSA_20261105_CICLO108_GITHUB_ZERADO.md`.

**Deployments.** 23 removidos por `gh api -X DELETE`. Sobram 2, ambos success; o `6688904` e o deployment activo do environment `github-pages` e a API recusa apaga-lo (HTTP 422), o que e correcto - nao e um falhado antigo.

**Estado final medido.** `mql5`: 0 code scanning, 0 Dependabot, CI e CodeQL verdes em `28cf65cf`. `XAU_AI_PRO`: 0 code scanning, 0 Dependabot, 7/7 workflows verdes. **Conta real continua recusada**: o ultimo backtest valido deu PF 0,92, 641 trades, -58,14 USD e DD 143,70%, contra o criterio PF > 1,20 e DD <= 5%.

**Ficheiros.** `Docs/CONVERSA_20261105_CICLO108_GITHUB_ZERADO.md` (novo), `.github/workflows/ci.yml`, `Files/XAU_AI_PRO/backend/mt5_gateway.py`, `backend/package.json`, `backend/package-lock.json`, `PROGRESS.md`, `PENDENCIAS.md`, `CONVERSAS.md`.

---

## CICLO 108 - 04/11/2026 22:20-23:05 - v1.2.149 (P1.108) e v1.2.150 (P1.109)

Detalhe completo: `Docs\CONVERSA_20261105_CICLO108_P1108_P1109_V1149_V1150.md`

### P1.108 - FECHADO (v1.2.149)
`[DATA] SEM LEITURA | USDSEK | ATR=0.000000 | ADX=42.12 | RSI=42.99` (22:39:42).
O `GetATR(string)` criava `iATR()` e chamava `IndicatorRelease()` na MESMA leitura,
logo o handle era destruido antes do primeiro `CopyBuffer` bom e o indicador nunca
aquecia. Passou a `ATR_SYMBOL_CACHE` (256) + `ATRSymbolHandle()` +
`ATRReleaseSymbolHandles()`, o padrao que o ADX ja usava desde a v1.2.96 (P1.85).
Prova por efeito: `dataset.csv` passou a gravar USDSEK `0.01426` e USDCNH
`0.00278`; zero `[DATA] SEM LEITURA` entre 22:45:40 e 23:10:00.

### P1.109 - PARCIAL (v1.2.150), reaberto como P1.110
`[CENARIO] USDJPY | VOLATILIDADE_ALTA | ADX=33.2 | ATR%=17.97` (22:46:55) publicou
a volatilidade do OURO num par de iene. Prova aritmetica com a base do proprio EA
(mesma barra 02:00): USDJPY ATR=0.195 ADX=26.25 / XAUUSD ATR=28.39 ADX=33.156;
`28.39/158.354*100 = 17.93` (~17.97) e 33.156 (~33.2). O preco estava certo
(158.354 = bid USDJPY): so a leitura de indicador vazou.
Correcao: `GetATR()` / `GetADX()` / `GetRSI()` passaram a ser wrappers que delegam
em `GetATR(_Symbol)` / `GetADX(_Symbol)` / `GetRSI(_Symbol)` (o caminho por cache,
que produz as linhas certas); as leituras antigas ficaram em `*Instance()`; o
`HighVolatility` passou a usar `ATRSymbolHandle(_Symbol)` na media de 20 barras.

### Validacao
Gate HG-01/HG-02 `[OK] versao tripla coerente: 1.2.150`; compilacao
`0 errors, 0 warnings` (33317 ms); `.ex5` 879812 B as 22:58:26;
`profile_apply Default` -> `profile_apply XAI_P216_LIVE`;
15 `[START] XAU_AI_PRO v1.2.150` entre 22:58:40.304 e 22:58:51.683.

### Nao fechado neste ciclo
P1.110 (a mesma falha reapareceu, intermitente e por instancia),
P1.111 (varias instancias escrevem o mesmo `dataset.csv` sem sincronizacao,
produzindo linhas partidas e coladas). Nenhum limite, lote, alvo, stop, spread,
preco, regra de entrada/saida ou parametro de risco foi alterado.

### Ciclo 109 — P1.112 a P1.116 (v1.2.151 a v1.2.155)
Cinco ciclos, todos de leitura de indicador e de observabilidade. Nenhum
limite, lote, alvo, stop, spread, preco, regra de entrada/saida ou parametro de
risco foi alterado.
**Antes** (23:16:40-23:17:31, build v1.2.151): dez pares escreveram
`[ATR] LEITURA SUSPEITA ... ATR=29.454290` — o ATR do ouro — com ATR% a chegar
a 5222.11 no NZDUSD, cada um seguido de `[DATA] SEM LEITURA` com o mesmo
ADX=33.77 e RSI=82.72, e a vela deixava de ser gravada.
**Depois** (23:50:44, sonda `XAI_AtrDiag` no grafico USDCNH,H1): cada par com o
seu ATR — XAUUSD 29.543571 (0.7145 %), USDCNH 0.002889 (0.0433 %), EURUSD
0.001401, GBPUSD 0.001304, USDCZK 0.029471.
O que ainda nao fecha e o `[CENARIO] XAUUSD/USDCNH | ATR%=sem leitura` das
23:45:11 e 23:51:42: como a sonda le os dois pares no mesmo segundo, o zero nao
vem da serie nem do indicador, vem do getter do EA. `MarketVolatilityPercent`
devolve `-1.0` quando `GetATR(symbol)` devolve `0.0`, e `GetATR` tinha tres
saidas silenciosas. A v1.2.155 instrumentou as tres com `ATRLogNoRead` e a linha
`[ATR] SEM LEITURA | <simbolo> | <motivo> | grafico=<_Symbol>`; a causa corrige-se
depois de o journal a nomear.
Compilacao final: 0 errors, 0 warnings (build 6296, X64 Regular, 18979 ms),
`XAU_AI_PRO.ex5` 897.702 bytes, `#property version "1.355"` alinhado com
`EA_VERSION_STRING "1.2.155"` (HG-01). Detalhe completo em
`Docs/CONVERSA_20261105_P1112_P1116_V1151_V1155.md`.

