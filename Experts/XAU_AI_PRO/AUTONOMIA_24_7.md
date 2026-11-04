# AUTONOMIA 24/7 - o que esta aprendido, condensado

> Este ficheiro e um RESUMO, nao a fonte. O detalhe medido esta em
> `PENDENCIAS_20261030.md` (46 seccoes numeradas, 334248 B) e `PROGRESS.md` (51 ciclos,
> 204752 B). Regra do projecto: **se um numero aqui divergir do que o comando
> medir, o comando vence** - corrija o numero, nao o comando.
>
> Objectivo deste resumo: responder em minutos a duas perguntas - "o que ja
> funciona sozinho?" e "o que falta para operar 24/7 sem ninguem?".

---

## 0. Cartao de 1 minuto (para um agente novo comecar a trabalhar ja)

Leia so isto se tem pressa. As seccoes seguintes explicam o porque.

1. **Antes de escrever, medir `LastWriteTime`.** Escrita nos ultimos 5 minutos =
   outra sessao a trabalhar: **parar**. Dois agentes no mesmo workspace e a unica
   causa de estrago ja observada (P1.55 abortado).
2. **O que corre nao e o que esta no disco.** `[VERSION]` no journal manda.
   Compilar muda o disco; so `chart_add_expert` muda o que opera.
3. **A autonomia de execucao ja existe.** A IA esta inerte por IDADE
   (`MAX_AGE_READY_SEC` = 5 dias), nao por falta de edge. Refresh dos modelos e
   o item n. 1 da fila.
4. **Nada de risco sem pedido explicito.** `RiskPercent`,
   `MaxDailyLossPercent`, `MaxDrawdownPercent` e a escada em dinheiro nao se
   tocam "para testar".
5. **Escrever sempre por script com backup e verificacao pos-escrita**
   (bytes, CRLF == LF, NUL == 0, marcador unico). Nunca sobrescrever
   `.bak_before_pNNN`.
6. **Veredicto de compilacao = `Result: 0 errors, 0 warnings`**, nunca o exit
   code (o MetaEditor devolve 1 mesmo limpo).
7. **Intocados:** `Files\XAU_AI_PRO\Python\models` (515 MB) e `frontend\dist`.
8. **Se um numero deste resumo divergir do comando, o comando vence.** Corrija
   o numero, nunca o comando.
9. **Armadilhas tecnicas ja pagas: seccao 9.** Ler antes de depurar o que parece
   um defeito novo e ja tem explicacao conhecida.

Tres comandos que respondem a 80 por cento das duvidas:

```powershell
# 1. o que realmente corre (versoes dos 16 graficos)
Select-String -Path "$env:APPDATA\MetaQuotes\Terminal\*\MQL5\Logs\*.log" -Pattern '\[VERSION\]' | Select-Object -Last 16
# 2. o que o EA decidiu nas ultimas horas
Select-String -Path "$env:APPDATA\MetaQuotes\Terminal\*\MQL5\Logs\*.log" -Pattern 'TRADE OPEN|TRADE CLOSE|EXECUTION BLOCK' | Select-Object -Last 20
# 3. a IA esta viva ou inerte?
Get-ChildItem "MQL5\Files\XAU_AI_PRO\Python\models\*.meta.json" | ForEach-Object { $j = Get-Content $_ -Raw | ConvertFrom-Json; "{0,-28} {1,-14} edge={2:N4} pub={3}" -f $j.symbol, $j.timeframe, $j.metrics.edge, $j.publicable }
```

---

## 1. O que o EA ja faz sozinho (medido)

| Capacidade | Prova | Quando |
|---|---|---|
| Abre ordens sem intervencao | 5 `TRADE OPEN` em 29 h (USDJPY 0.08, AUDUSD 0.10 x2, USDCAD 0.04, AUDUSD 0.13) | 01-02/11 |
| Gere a saida sozinho (escada em dinheiro) | 3 posicoes abertas, **todas com SL a favor da entrada** - lucro ja travado: USDJPY SELL 157.800 -> SL 157.736 (~3,25 USD), USDCAD SELL 1.39838 -> SL 1.39789 (~1,40 USD), AUDUSD BUY 0.70221 -> SL 0.70233 (~1,56 USD); flutuante somado **+24,20 USD** | 02/11 05:48 |
| Fecha sozinho | AUDUSD `11188068452` fechada por `Expert`, -8,90 USD | 02/11 04:46 |
| Recusa entrada em simbolo invalido | `EXECUTION BLOCK | SYMBOL ... | Motivo=` + `EventTradeRejected` (`SYMBOL_INVALID`) | v1.2.65+ |
| Filtra por tick (spread, hora, custo) | `Filters/SpreadFilter.mqh` + `CostGate` + `AvoidHoursGMT=9,11,14,18,20,22` | continuo |
| Escreve o dataset a cada vela | `MQL5\Files\Data\dataset.csv` = **3.541.218 B** | 02/11 05:28:07 |
| Reelei o dono do pipeline sem duplicar posicoes | `[RESUMO] master=SIM | posicoes: 3 EA + 0 manual` | 02/11 05:15:30 |
| Diagnostico de arranque consistente | `[VALIDATION]`: 7 graficos `READY=15 W=0 B=0`, 8 graficos `READY=12 W=3 B=0`, USDRUB `READY=11 W=3 B=1` | 02/11 05:28:01 |

**Conclusao medida:** a autonomia de EXECUCAO e de GESTAO ja existe e esta
provada. O que nao existe e autonomia de CONHECIMENTO: os modelos que deviam
decidir estao todos fora de validade (seccao 2.1).

---

## 2. O que impede os 24/7 (por ordem de impacto)

### 2.1 A IA esta inerte - nao por falta de edge, mas por IDADE
- 39 `*.meta.json` no registo; **0 em estado READY**: 28 STALE + 11 ERROR.
- Treinados em **22/10/2026** (BTC/ETH/EUR/GBP/NZD/USDCAD/USDJPY/XAUUSD) e 03/10
  (MULTI_CRYPTO, MULTI_FIAT, MULTI_METALS).
- Exemplo lido a mao (`XAUUSD_H1.meta.json`): `edge 0.1319`, 5 folds todos
  positivos (minimo 0.0685), `publicable: true`, `train_date 2026-10-22`.
- O gate nao e a qualidade: e `MAX_AGE_READY_SEC = 5 dias` no registo. Um modelo
  de edge alto passa a STALE ao 6.o dia.
- **Proximo passo minimo:** job de refresh (retreinar e reescrever `meta.json`
  com `train_date` novo) com cadencia < 5 dias. E isto que torna a IA utilizavel.
- **Regra que nao se mexe:** regra 18.5 - nenhum estado invalido vira BUY/SELL.
  Se o refresh falhar, a IA continua inerte, e isso e o comportamento correcto.

### 2.2 Metade dos simbolos nao tem previsao
- `prediction_<SIMBOLO>.json` existe para **7 de 16**: XAUUSD, USDJPY, USDCAD,
  AUDUSD, NZDUSD, GBPUSD, EURUSD - e todos com data de **08/10/2026 22:00** (25 dias).
- Nao existe para **9**: USDBRL, USDCLP, USDCOP, USDSEK, USDCHF, USDCZK,
  USDCNH, USDRUB, USDSGD.
- Esses 9 falham `AI`, `JSON` e `Python` **com razao** - nao ha ficheiro.
- **Proximo passo minimo:** treinar esses 9 com o mesmo pipeline dos 7.

### 2.3 O binario em disco pode estar a frente do que corre
- `.ex5` em disco: **alvo movel** - cada compilacao muda o tamanho. Nao memorizar o numero: medir.
- **Estado medido em 02/11 05:48: 16/16 graficos correm v1.2.69**, arranque unico as 05:43:15-17 (32 linhas `[VERSION] v1.2.69 | Build=` = 2 por grafico, em 16 simbolos). Binario e execucao em sincronia.
- Ja aconteceu pior: em 02/11 05:14 os graficos corriam **v1.2.61** com v1.2.66
  no disco (5 versoes atras). Compilar **nao** reanexa.
- **Proximo passo minimo:** `chart_add_expert` nos 16 graficos apos cada
  compilacao, e confirmar `[VERSION]` no journal. Sem isto, nada do resto conta.

### 2.4 USDRUB e decisao de negocio, nao defeito
- `[CRITICAL] Execution: FAIL - Spread acima do maximo: 1500.0 pts (max=489.3)`.
- 0,6% de ~80,6 = ~489 pts; a corretora cobra 1500 pts no simbolo. Nao vai passar
  a caber por mudanca de codigo.
- **Decisao pendente do dono:** manter nos 16 (e aceitar que nao opera) ou retirar.

### 2.5 As checklists sao diagnostico, nao portao
- Nada consulta `IsReady()` nem `ValidationChecklistPassed()` desde o P1.44.
- Nao e defeito: e a descricao correcta do mecanismo. O bloqueio real de spread
  e por tick em `Filters/SpreadFilter.mqh`.
- **Nao transformar em portao sem medir** - um checklist que grita sempre deixa
  de ser lido, e ja houve 96 de 96 arranques a gritar por um FAIL falso (P1.54).

### 2.6 Amostra pequena para afirmar "24/7 provado"
- 1 fecho e 5 aberturas em 29 h. Serve para provar que o mecanismo funciona,
  nao para provar robustez.
- **Prova que falta:** N fechos consecutivos sem intervencao, com
  `TRADELOG FALLBACK` contado (o contador existe desde a v1.2.66; o unico fecho
  do periodo foi feito por v1.2.61, que ainda nao o tinha).

---

## 3. A fila mais curta ate a autonomia

| # | Item | Desbloqueia | Esforco |
|---|---|---|---|
| 1 | Refresh dos modelos (`train_date` < 5 dias) | IA sai de inerte; e o maior ganho por hora de trabalho | alto |
| 2 | Reanexar os 16 graficos apos cada compilacao | o codigo novo passa a correr | baixo |
| 3 | Treinar os 9 simbolos sem previsao | `AI`/`JSON`/`Python` passam de 7/16 para 16/16 | alto |
| 4 | Decidir USDRUB | retira o unico BLOCKED permanente | decisao |
| 5 | Contar `TRADELOG FALLBACK` no 1.o fecho com v1.2.66+ | fecha a pendencia de observabilidade | baixo |
| 6 | Idade do JSON na mensagem do item `AI` (proposto P1.56) | um PASS deixa de esconder um ficheiro de 25 dias | baixo |

---

## 4. Invariantes que nao se quebram (nunca, por conveniencia)

1. **Nada de dinheiro para fora:** sem saque, transferencia ou resgate em
   adaptador, rota, cliente ou tela.
2. **Simbolo vazio e recusa com motivo**, nunca um activo por omissao.
3. **Toda a ordem real** exige `confirm=true` + `request_id` e passa por
   `risk_gate`, `intent_log`, `audit_log`.
4. **Nenhum modelo invalido vira BUY/SELL** (regra 18.5).
5. **Parametros de risco** (`RiskPercent`, `MaxDailyLossPercent`,
   `MaxDrawdownPercent`, escada em dinheiro) so mudam com pedido explicito e
   medicao que o sustente.
6. **Nenhum teste afrouxado para parar de reprovar**; toda a correcao leva prova
   negativa (o caso que DEVE reprovar).
7. **`Files\XAU_AI_PRO\Python\models` (515 MB) e `frontend\dist` ficam
   intocados** salvo pedido expresso.

---

## 5. Contrato de dados da IA (para nao partir o que ja funciona)

```text
FEATURE_VERSION   = 25F-v2          FEATURES = 25
feature_hash      = 27727ee00bc30b7f  (tem de bater com o dos meta.json)
PUBLICACAO_MIN_EDGE = 0.05          DIRECAO_TH = 0.4    FORTE_TH = 1.0
JANELA_ATR = 14   ATR_CLIP = 6.0    N_FOLDS = 5   MIN_FOLDS_POSITIVOS = 4
LOOKAHEAD = {M5:1, M15:3, M30:3, H1:2, H4:4, D1:8}
MAX_AGE_READY_SEC = 5 dias
ESTADOS = READY | STALE | UNAVAILABLE | ERROR | TRAINING
```

- Mudar `FEATURES`, `feature_version` ou o hash **invalida os 39 modelos** de uma
  vez. Treinar sempre contra o contrato, nunca contra um formato novo.
- `edge_estavel` exige 5 folds com pelo menos 4 positivos - nao e so a media.

---

## 6. Verificacao de 5 minutos (o que olhar por esta ordem)

1. `[VERSION]` no journal => versao que **realmente corre** (nao a que esta no disco).
2. `[VALIDATION] Resultado:` => `READY=15 W=0` nos 7 com previsao,
   `READY=12 W=3` nos 8 sem, `USDRUB READY=11 W=3 B=1`.
3. `[OPTIONAL] Dataset: PASS` => 16 de 16 (o FAIL era falso ate ao P1.54).
4. Posicoes abertas => **SL melhor que a entrada** em todas = escada a funcionar.
5. Estado do registo da IA => 0 modelos READY = IA inerte, por desenho, nao por avaria.
6. `dataset.csv` a crescer + `prediction_<SYM>.json` com data <= 5 dias.

---

## 7. Onde esta o detalhe

| Ficheiro | Tamanho | Conteudo |
|---|---|---|
| `PENDENCIAS_20261030.md` | 334248 B | 46 seccoes numeradas: cada defeito com a medicao antes/depois |
| `PROGRESS.md` | 204752 B | 51 ciclos: o que mudou, com que prova, em que versao |
| `AUTONOMIA_24_7.md` (este) | ~11 KB | o resumo: o que funciona, o que falta, o que nao se quebra |

Leitura recomendada para um agente novo: **este ficheiro -> seccao 65 (P1.54,
o ultimo defeito estrutural) -> seccao 59/60 (treino e edge) -> nunca o arquivo
inteiro.**

---

## 8. Convivio (dois agentes no mesmo workspace)

- Antes de escrever: medir `LastWriteTime` dos alvos. Escrita nos ultimos
  minutos = outra sessao a trabalhar: **parar**, nao compilar, nao reanexar.
- Backups `.bak_before_pNNN` nunca sobrescritos; escrita por script com
  verificacao pos-escrita (bytes, CRLF == LF, NUL == 0, marcador unico).
- Compilar: `compile_prod.ps1`; o veredicto e a linha
  `Result: 0 errors, 0 warnings`, **nunca** o exit code (o MetaEditor devolve 1
  mesmo com compilacao limpa).
- **Sem reanexar, nao conta.** Compilar muda o disco; reanexar muda o que opera.
---

## 9. Armadilhas tecnicas que custam horas (ja pagas - nao repetir)

| # | Armadilha | O que acontece | O que fazer |
|---|---|---|---|
| 1 | `FILE_COMMON` | Muda a **raiz** de `MQL5\Files` para `Common\Files`, nao o nome. Foi a causa do P1.54: 4 itens do checklist liam uma pasta onde o EA nunca escrevia | Ler/escrever **sem** `FILE_COMMON` no sandbox, ou com ele quando o ficheiro e mesmo comum. Conferir sempre qual das duas pastas tem o ficheiro |
| 2 | Ficheiro "nao encontrado" com o CSV a crescer | Falta de partilha: outra instancia (`DataLogger`) tem o CSV aberto | `FILE_READ\|FILE_WRITE` **sempre** com `FILE_SHARE_READ\|FILE_SHARE_WRITE` |
| 3 | Exit code do MetaEditor | Devolve **1 mesmo com compilacao limpa**. Assumir `exit=1` = falhou faz reverter trabalho bom | O veredicto e a ultima linha `Result: 0 errors, 0 warnings, N ms elapsed, cpu=...`. `compile_prod.ps1` lanca `throw` se nao for 0/0 |
| 4 | Barra invertida em string MQL5 | `"\d"` e escape: `warning 86: unrecognized character escape sequence` | Duplicar: `"Data\\dataset.csv"` |
| 5 | Backticks dentro de `powershell -Command` | O `cmd.exe` come os backticks e o parser falha com "Token inesperado" | Escrever `.ps1` e correr com `-NoProfile -ExecutionPolicy Bypass -File` |
| 6 | BOM e contagem de bytes | `UTF8Encoding($true)` escreve 3 bytes de BOM que `GetByteCount` **nao** conta | Comparar com `GetByteCount + 3` quando ha BOM; ou contar os bytes do disco depois de escrever |
| 7 | Detectar fim de linha misturado | `Contains("\n\r")` da **falso positivo** | Regex: LF orfao = `[^\r]\n`, CR orfao = `\r[^\n]`. BOM: primeiros 3 bytes `EF BB BF` |
| 8 | Checklists a crescer texto no fim | `FILE_READ\|FILE_WRITE` + `FileSeek(0)` **sem truncar** deixa o rabo do resumo anterior e o texto sai sobreposto (P1.42) | `FILE_WRITE` sozinho, que apaga na abertura |
| 9 | `IsReady()` como se fosse portao | Nada o consulta desde o P1.44; fica impresso como estado actual durante dias | Tratar como diagnostico de init. O bloqueio real e por tick (`SpreadFilter`, `CostGate`) |
| 10 | "Compilei, logo corre" | Compilar muda o **disco**, nao os graficos. Ja houve 5 versoes de atraso | `chart_add_expert` nos 16 + confirmar `[VERSION]` no journal |
| 11 | Grep do MCP com regex | `search_text`/`search_regex` devolveram 0 resultados para padroes que existem | Fallback: `findstr /S /N /I /C:"texto" *.mq5 *.mqh` ou `Select-String` |
| 12 | PowerShell 5.1 | Nao tem operador ternario; `? :` e erro de parser | `if/else`, ou variavel pre-atribuida |
| 13 | Ficheiros que mudam de sitio | `CostGate.mqh` passou de `Enterprise\` para `Filters\` (o include e `../Filters/CostGate.mqh`) | Confirmar o caminho no `#include`, nunca presumir pela pasta do README |
| 14 | Dois agentes no mesmo workspace | Escrita concorrente no mesmo ficheiro: o P1.55 foi abortado assim | Medir `LastWriteTime` antes de escrever; escrita nos ultimos 5 min = parar |

**Regra unica que resume as 14:** *medir antes, medir depois, e nunca confiar
no que o nome do ficheiro, o exit code ou o README dizem sobre o estado real.*

## 10. Estado em 02/11 06:06 (depois do P1.56, P1.57 e P1.58)

- **16 de 16 graficos correm v1.2.72** (`[VERSION] v1.2.72 | Build=2026.11.02`), reanexados entre 06:05:05 e 06:06:05.
- **Procedimento de reload provado:** `chart_save_template` do proprio grafico -> `chart_apply_template`. Substitui "reanexar a mao" e dispensa escrever 308 parametros. NAO e inocuo: se o EA nao inicializar, o grafico fica SEM robo (aconteceu entre 06:01 e 06:05). Provar num grafico antes de correr nos 16, e confirmar `[VERSION]` depois.
- **O EA ja nao precisa de permissao de DLL para carregar** (P1.58): o `#import sqlite3.dll` passou a condicional. Sem a macro `XAI_USE_SQLITE_DLL` a base de dados fica inativa e diz isso no journal, em vez de o programa nao arrancar.
- **As duas checklists deixaram de dar dois vereditos ao mesmo dado** (P1.57): Symbol, AI e JSON com tabela unica de decisao.
- **O item AI diz a idade da previsao** (P1.56): `idade=NNNh` e `STALE` acima de 120 h.
- **Prova de autonomia:** AUDUSD fechou por `Take profit` a `0.70298` com **+10.01 USD** as 06:01:16, exatamente o `LadderTpUsd=10.0`, sem intervencao e no mesmo minuto em que o EA estava a ser reanexado. Somam-se 2 fechos desde o inicio: 1 por Expert (-8.90 USD) e 1 por TP (+10.01 USD).
- **Continua a faltar a autonomia de CONHECIMENTO:** 39 modelos, 0 READY (28 STALE + 11 ERROR), todos acima dos 5 dias (`MAX_AGE_READY_SEC`). O caminho mais curto para 24/7 real e um trabalho de retreino com cadencia < 5 dias; 9 simbolos continuam sem `prediction_<SIMBOLO>.json`.
- **Pendente de decisao:** destino da base SQLite (repor com `-DXAI_USE_SQLITE_DLL` + DLL permitida, ou abandonar); e USDRUB, que e BLOCKED por spread real de 1500 pts contra 489.3 de maximo - decisao de negocio.

## 11. Estado em 02/11 06:24 - P1.60 (v1.2.74)

- **16 de 16 graficos correm v1.2.74**, reanexados entre 06:24:07.542 e 06:24:08.347.
- **P1.59 fechado:** a leitura do `prediction_*.json` passou a ser binaria (`FILE_BIN` + `FileReadArray` +
  `CharArrayToString CP_UTF8`). Prova em producao: 0 registos `sem estrutura basica` apos o reload, contra 35
  entre 05:38 e 06:06.
- **P1.60 fechado:** a checklist e o motor passam a julgar a previsao pelo mesmo limiar (`MaxPredictionAgeSec`,
  900 s). Antes, o item dizia `PASS/READY` para um ficheiro de 24 dias que o motor ja ignorava.
- **Estado real da IA (medido, nao estimado):** 7 simbolos com ficheiro de previsao, todos STALE
  (`idade=2103814s` = 24.3 dias); 9 simbolos sem ficheiro. Os 16 operam hoje em **fallback tecnico** e isso
  agora esta escrito no relatorio de arranque, no lugar de um PASS enganador.
- **O que falta para a autonomia plena:** o pipeline Python tem de escrever previsoes com menos de 900 s de
  idade. Sem isso, a IA nao participa nas decisoes, independentemente de o EA estar corretamente anexado.
- **Nada foi relaxado:** `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, o portao de edge 0.05 e o
  bloqueio de spread por tick continuam intactos.

## 12. Estado em 02/11 08:35 - P1.62 (v1.2.76)

- **16 de 16 graficos correm v1.2.76** - 48 registos [VERSION] as 08:34:24
  (3 por chart), apos reaplicar os 16 templates.
- **AUtocarga nao existe**: compilar o .ex5 nao recarrega os EAs. De 08:31 a
  08:34 as 16 charts continuavam a imprimir a mensagem antiga. Todo o deploy
  tem de incluir o reload explicito; isto esta medido e documentado.
- **O EA conta a verdade sobre si proprio**: o heartbeat passou de
  "autotrading":true (08:17) para "autotrading":false,
  "terminal_trade_allowed":true, "trade_gate_code":3 (08:34). Quem le o
  ficheiro deixa de concluir que o EA pode negociar quando nao pode.
- **Nada negoceia**: MQL_TRADE_ALLOWED=0 nas 16 charts e na chart de sonda,
  com TERMINAL_TRADE_ALLOWED=1, ACCOUNT_TRADE_ALLOWED=1, ACCOUNT_TRADE_EXPERT=1
  e TERMINAL_CONNECTED=1. Conta 113568614 (MetaQuotes-Demo), saldo 12357.54,
  0 posicoes, 0 ordens.
- **O que falta e humano e nao e codigo**: marcar a caixa de negociacao
  algoritmica nas propriedades do EA (1 clique por chart) ou reanexar o EA
  pela GUI. Nenhuma API MQL5 escreve este bit, e nenhum template o religa -
  ambos medidos hoje.
- **Hipotese descartada**: expertmode de .tpl/.chr nao e a permissao do
  programa (4 medicoes independentes, ver PENDENCIAS 71.4).
- **O que continua igual**: risco, spread, portao de IA 0.05, modelos e
  frontend/dist intocados. Nada foi relaxado para "fazer negociar".
- **Autonomia 24/7**: o EA corre, le a conta, mantem risco, heartbeat e
  validacao. O unico bloqueio e a permissao por programa do MT5.
## 13. Estado em 02/11 08:53 - P1.63 (v1.2.77)

- **O que mudou**: o bloco PERMISSOES do diagnostico deixou de ler um unico bit
  e passou a ler o portao de 5 bits (Core/TradeGate.mqh), publicando a causa.
  Antes: "Permissoes: VERDE" enquanto as 16 charts nao podiam negociar. Agora:
  a mesma frase que o heartbeat e o journal usam, com o bit que falta nomeado.
- **Deploy provado**: 16 templates reaplicados as 08:52:31-08:52:38; 64
  registos "[VERSION] v1.2.77" no journal (4 por chart, 16/16 charts) e a linha
  "[TRADE BLOCK] ... | MQL_TRADE_ALLOWED=0 TERMINAL_TRADE_ALLOWED=1
  ACCOUNT_TRADE_ALLOWED=1 ACCOUNT_TRADE_EXPERT=1 TERMINAL_CONNECTED=1".
- **O que NAO mudou e nao vai mudar por conveniencia**: MQL_TRADE_ALLOWED
  continua 0. Nenhuma API MQL5 escreve este bit, nenhum template o religa
  (expertmode=5 medido de novo) e recompilar nao recarrega EAs. O que falta e
  humano: marcar "negociacao algoritmica" nas propriedades do EA (1 clique por
  chart) ou reanexar pela GUI.
- **Conta**: 113568614 (MetaQuotes-Demo), saldo e equity 12357.54 USD, margem 0,
  0 posicoes, 0 ordens.
- **O que o EA faz sozinho enquanto esta barrado**: inicializa 15 modulos, le a
  conta, mantem risco, heartbeat, auditoria, dataset e validacao; escreve no
  journal a causa do bloqueio a cada ciclo. Autonomia 24/7 operacional, sem
  permissao de execucao.
- **Intocado**: MaxSpreadPct 0.6, MinAIConfidence 60.0, MinMarketScore 65.0,
  portao de IA 0.05, modelos (515 MB) e frontend/dist.
- **Proximo passo tecnico**: alinhar os 12 ficheiros que ainda leem bits crus
  (fila em PROGRESS Ciclo 61) para que nenhum artefacto volte a dar um veredicto
  diferente do portao.


## 14. Estado em 02/11 08:59 - P1.64 (v1.2.78)

**O que mudou**: o portao de negociacao passou a testar a LIGACAO antes de tudo.
Novo `TG_DISCONNECTED = 5` em `Core/TradeGate.mqh`; `Evaluate()` devolve-o quando
`TERMINAL_CONNECTED=0`, em vez de devolver `TG_OK`. Os tres sitios que liam o bit
cru (Diagnostics, ProductionChecklist item 0, ValidationChecklist item 8) leem
agora a mesma fonte e escrevem a mesma frase.

**Porque foi feito**: medido no codigo, nao suposto. O portao respondia "trading
permitido" com o terminal desligado, e as checklists respondiam "desconectado"
em tres frases diferentes. Era a unica resposta de permissao que ainda nao vinha
da fonte unica.

**Deploy provado**: compilacao `0 errors, 0 warnings` (15607 ms), .ex5 702120 B
as 08:58:30; 16 templates reaplicados; 64 registos `[VERSION] v1.2.78` no
journal, 4 por chart, 16/16 charts.

**O que NAO vai mudar por conveniencia**: `MaxSpreadPct=0.6`,
`MinAIConfidence=60.0`, `MinMarketScore=65.0`, portao de edge 0.05, limites de
risco por trade (8 USD / 3%), `EnableRealAccountGuard=true`. Nenhum destes
valores foi tocado neste ciclo.

**Conta**: 113568614 (MetaQuotes-Demo), saldo e equity 12357.54 USD, margem 0,
0 posicoes, 0 ordens. Nada negoceia porque `MQL_TRADE_ALLOWED=0` nas 16 charts -
o unico bloqueio que so um humano resolve (caixa de negociacao algoritmica nas
propriedades do EA, por chart, ou reanexacao pela GUI).

**O que o EA continua a fazer sozinho**: carregar 16 charts, verificar o portao a
cada tick e nomear a causa, gravar heartbeat e diario de auditoria, gerir
cortes de risco (circuit breaker, streak brake, equity protection), monitorizar
saude e backups horarios. O que nao pode fazer sozinho e religar um bit que o
MT5 nao expoe a API.

**Proximo passo tecnico**: alinhar os leitores de bits crus restantes - mas so os
que decidem permissao. Os que apenas reportam estado (SystemStatus, FailureMode,
RecoveryManager, CircuitBreaker, ConnectionGuard, EAHeartbeat, ExternalBridge)
ficam para quando houver medicao de divergencia, nao por arrasto.

## 15. Estado em 02/11 09:02 - P1.65 (v1.2.79)

**O que mudou**: a frase do `[TRADE BLOCK]` quando o bit em falta e o do programa.
Antes mandava o operador para as propriedades do EA; agora diz o que foi medido
(terminal com Algo Trading LIGADO, `TERMINAL_TRADE_ALLOWED=1`), lista as duas
hipoteses por testar e mantem a lista do que ja foi rejeitado por medicao
(template com `expertmode=5` as 08:14 e 08:58; anexacao por API as 08:15).

**Porque**: a mensagem anterior fazia o operador procurar uma caixa que nao e a
causa medida. Um diagnostico que aponta para o sitio errado custa mais tempo do
que um diagnostico que falta.

**Deploy provado**: compilacao `0 errors, 0 warnings` (15817 ms), .ex5 702612 B
as 09:01:35; 16 templates reaplicados; 48 registos `v1.2.79` no journal
(3 por chart, 16/16 charts); mensagem nova a disparar as 09:01:39.955 em diante.

**O que NAO vai mudar por conveniencia**: `MaxSpreadPct=0.6`,
`MinAIConfidence=60.0`, `MinMarketScore=65.0`, portao de edge 0.05, risco 8 USD
por trade e 3% de cap, `EnableRealAccountGuard=true`. Nada disto foi tocado.

**Conta**: 113568614 (MetaQuotes-Demo), saldo e equity 12357.54 USD, margem 0,
0 posicoes, 0 ordens. O EA continua a recusar negociar porque
`MQL_TRADE_ALLOWED=0` nas 16 charts - e recusar e o comportamento correto
enquanto a permissao do programa faltar.

**O que o EA faz sozinho**: 16 charts carregados, portao avaliado a cada tick com
a causa nomeada, heartbeat e auditoria a gravar, risco gerido (circuit breaker,
streak brake, equity protection), saude e backups horarios monitorizados.

**O que so um humano pode fazer**: religar o bit por programa. Duas vias, ambas
com GUI: desligar/religar o botao Algo Trading da barra do terminal, ou reanexar
o EA no grafico confirmando a permissao no dialogo de anexacao.

---

## 16. Estado em 02/11 14:05 - P1.66 (v1.2.79): a IA e consultiva e o bloqueio e UM bit

**Execucao:** presa a `MQL_TRADE_ALLOWED=0` (`trade_gate_code=3` no heartbeat,
298 B, `autotrading=false`, `terminal_trade_allowed=true`). Os quatro bits
anteriores passam, porque `Evaluate()` devolve o primeiro que falha e `Mql()` e
o ultimo. Religar exige GUI: 5 hipoteses ja reprovadas (template expertmode=5,
attach por API, reload automatico pos-build).

**IA:** consultiva, nao bloqueia. `AIGateRequired()` e false com
`EnableAutonomousMode=true` (valor nos 16 graficos). `BlockZeroAIScore` so
barra score 0, e o score e local.

**Edge medido:** 58 combinacoes em M5/M15/H1/H4 sobre
`dataset_mt5_20261101.csv` (1.494.248 linhas, 16 simbolos). Zero publicaveis.
O melhor numero com estabilidade (USDCZK M15 +0,0021, USDCHF M15 +0,0038) esta
muito abaixo do piso 0,05. Os numeros grandes (USDBRL H1 +0,1124) tem 1/5
folds positivos — sao ruido, e a porta de estabilidade recusa-os.

**Transporte da IA:** partido em tres pontos independentes — porta 9001 tomada
pelo servidor MCP, rota GET contra POST do EA, e fastapi/uvicorn ausentes.
Nenhum deles bloqueia operacao; todos bloqueiam a LEITURA da IA.

**Intocado por regra:** `Python\models` (515,1 MB, 78 ficheiros),
`frontend\dist`, piso de edge 0,05, e todos os inputs de risco.

**Proximo passo que nao depende de mim:** religar o botao Algo Trading pela
GUI. O que eu verifico no mesmo instante: `trade_gate_code` -> 0 e
`[TRADE BLOCK]` a desaparecer do journal.

## 17. Estado em 02/11 14:20 - P1.67 (v1.2.80): um dado, um veredicto

**Corrigido:** o mesmo "sem tick" produzia dois veredictos no HEALTH MONITOR
(HEALTHY com backoff nivel 0 e FAILURE com backoff nivel 11, na mesma janela) e
o backoff de 1920 s deixava o watchdog cego 32 min. Agora o teste de tick fica
guardado em `tickEmFalta` e a falha dos heartbeats so conta quando houve tick.

**Numeros:** `HealthMonitor.mqh` 26818 -> 27996 B (CRLF 925 -> 945, LF_soltos 0,
NUL 0); `VersionManager.mqh` 61418 -> 62892 B; `.mq5` so o `#property version`.
Build `0 errors, 0 warnings`; `.ex5` 703094 B, 14:16:47; 16 graficos reanexados
e a reportar `v1.2.80`.

**Sustos do ciclo:** o primeiro build falhou com 40 erros (aspas duplas dentro
do literal do changelog) e o MetaEditor APAGA o `.ex5` quando falha - a producao
ficou ~90 s sem binario. Ja existe copia do binario bom em
`Files\Backup\XAU_AI_PRO_v1280_ok.ex5`; regra nova: copiar antes de compilar.

**Intocado por regra:** `Python\models` (515,1 MB, 78 ficheiros),
`frontend\dist`, piso de edge 0,05, e todos os inputs de risco.

**Continua a ser o unico bloqueio de dinheiro:** `MQL_TRADE_ALLOWED=0`
(`trade_gate_code=3`). So a GUI religa esse bit.

**Verificado 14:18-14:32:** zero `FAILURE`; os graficos de 0 ticks passaram de
`nivel=11 intervalo_efetivo=1920s` para `nivel=0 intervalo_efetivo=60s`;
16/16 `HEALTHY` no arranque. O watchdog ja nao fica cego 32 min.


## 18. Estado em 02/11 15:58 - P1.68 (v1.2.81): journal legivel

- O journal de producao tinha 138 702 linhas num dia e nenhuma leitura:
  `[SCANNER] BLOCK` 18 532, `SYMBOL MANAGER` 7 955, `[TRADE BLOCK]` 7 272,
  586 blocos `SYSTEM STATUS`, 152 blocos `HEALTH MONITOR`.
- Quatro correcoes de impressao (nenhuma de decisao): retratos numa so linha;
  `[TRADE BLOCK]` por causa com 10 min de heartbeat; `[SCANNER] BLOCK` por
  mudanca de desfecho com 30 min; `SYMBOL MANAGER | Resolved` so quando o
  nome do broker difere do pedido.
- Medido depois do deploy: `[TRADE BLOCK]` de 11,8 linhas/min para 0,
  `[STATUS]` e `[HEALTH]` completos em 1 linha cada.
- A PERMISSAO continua a ser o unico bloqueio de dinheiro:
  `terminal_get_info` 18:46Z `experts_trade_allowed=false`; heartbeat do EA
  15:52:30 `trade_gate_code=1` `TG_TERMINAL_OFF`, `TERMINAL_TRADE_ALLOWED=0`,
  `ACCOUNT_TRADE_ALLOWED=1`, `ACCOUNT_TRADE_EXPERT=1`, `TERMINAL_CONNECTED=1`.
  Isto e o botao `Algoritmos` do terminal: acto humano, nenhuma API o escreve.
- Modelos (515,1 MB) e `frontend\dist` intocados. Portao 0.05 intocado.

## 19. Estado em 02/11 16:22 - P1.70 (v1.2.83): journal minimo e o bit que falta

- O TERMINAL ja autoriza: `terminal_get_info` 19:14Z da `experts_trade_allowed: true` e o journal do terminal registou "automated trading is enabled" as 16:13:17.
- O EA continua barrado por um bit POR PROGRAMA: as 16:16:46 e 16:21:3x imprime `MQL_TRADE_ALLOWED=0 TERMINAL_TRADE_ALLOWED=1 ACCOUNT_TRADE_ALLOWED=1 ACCOUNT_TRADE_EXPERT=1 TERMINAL_CONNECTED=1`, ou seja `trade_gate_code=3` (TG_MQL_OFF).
- Rejeitado por medicao neste ciclo: `expertmode=5` e `expertmode=7` dentro de um template copiado do proprio grafico e aplicado por `chart_apply_template`. O bit nao vem do template nesta build.
- Falta a caixa **Permitir Algo Trading** das propriedades do EA (F7 > Geral). Assim que estiver marcada num grafico, o template desse grafico revela o valor exacto de `expertmode` e os outros 15 podem ser corrigidos por API numa passada.
- Journal: P1.70 (v1.2.83) tirou da producao o retrato QUANT MATRIX / BENCHMARK / BACKTEST ANALYZER (so tester) e passou o `[SESSION] estado salvo` a sair apenas quando o resumo muda (heartbeat 30 min).

## 20. Estado em 02/11 16:45 - P1.71 (v1.2.84) e o resultado NEGATIVO do perfil

### 20.1 Journal

O P1.71 fechou as duas ultimas fontes que nao dependiam de evento de mercado: `[NOTIFY]` (1 850 linhas no dia, push do terminal desligado e `SendNotification` chamado na mesma) e `DATA LOGGER OFFLINE` (364 linhas de carimbo de `OnDeinit`). Com P1.68 + P1.69 + P1.70 + P1.71, o journal deixou de repetir retratos e passou a escrever eventos.

### 20.2 O bit por programa: dois resultados medidos e um que falta

**Medido 1 - onde o bit esta guardado.** Os perfis `XAI_V1232_ROLLBACK_20261030` e `Default` tinham `expertmode=5` nos 16 `chartNN.chr`; o perfil ATIVO `XAI_V1243_20261031` tinha `expertmode=0` nos 16. E exactamente o valor que o changelog do P1.30 ja registava: `o perfil que negociava trazia 5`.

**Medido 2 - `profile_apply` nao serve para isto.** Aplicar um perfil por API neste build (6294) recria os graficos VAZIOS: 16 graficos todos em EURUSD e SEM Expert Advisor, apesar de os 16 ficheiros `.chr` terem `symbol=` e bloco `<expert>` corretos e `expertmode=5`. Ou seja: o perfil e lido, mas simbolo, periodo e EA nao sao restaurados. Anexar o EA a seguir (`chart_add_expert`) repoe tudo menos a permissao, que volta a 0. Conclusao: `expertmode` no `.chr` NAO chega ao programa em execucao por nenhuma via de API disponivel.

**Falta** o ato na GUI, que nenhuma API expoe: clique direito no grafico > Expert Advisors > Propriedades (F7) > aba Geral > marcar `Permitir Algo Trading` > OK. Assim que `trade_gate_code` for 0 e `autotrading` for true, guardar o template desse grafico (`chart_save_template`) e ler o `expertmode` que o build 6294 escreve - esse valor e replicavel aos outros 15 por API.

### 20.3 Estado atual (medido)

`terminal_get_info`: `experts_trade_allowed: true`, sincronizado em MetaQuotes-Demo. Heartbeat: `terminal_trade_allowed:true`, `autotrading:false`, `trade_gate_code:3` (TG_MQL_OFF). Conta 113568614, 12 535,64 USD, sem posicoes e sem ordens. 16 graficos com v1.2.84.

## 21. Estado em 02/11 19:00 - P1.72 (v1.2.85) e a fronteira do que o codigo pode fazer

### 21.1 O que ficou medido neste ciclo

Janela estavel de 59 minutos antes do reload: 586 linhas/hora, dominadas por sete frases
repetidas por 16 instancias a ritmo fixo ([TRADE BLOCK] 68,1/h; [SESSION] 34,6/h;
[LOGGER OFFLINE] 33,6/h; [CIRCUIT] 33,6/h; [LEARN] 32,5/h; AI GATEWAY 32,5/h; [BACKUP]
21,4/h). Nenhuma delas era um evento de mercado. As sete janelas foram alargadas ou
condicionadas a rajada, e o aviso de estado ocupado passou a 1x por sessao com o codigo.

### 21.2 A fronteira que continua igual

O portao de dinheiro continua em trade_gate_code=3 (TG_MQL_OFF) com
terminal_trade_allowed=true, ACCOUNT_TRADE_ALLOWED=1, ACCOUNT_TRADE_EXPERT=1 e
TERMINAL_CONNECTED=1. Falta MQL_TRADE_ALLOWED, que e um bit POR PROGRAMA gravado pelo
terminal quando o operador autoriza aquele EA naquele grafico. Quatro rotas ja foram
medidas como insuficientes neste build (6294): template com expertmode=5, template com
expertmode=7, chart_add_expert e profile_apply de um perfil cujos 16 .chr tinham
expertmode=5. Nenhuma escrita de ficheiro ou chamada de API chega a esse bit: ele e escrito
a partir do estado do terminal, nao lido do ficheiro (o MT5 reescreveu os 16 .chr de 5 para
0 durante a sessao).

Consequencia pratica: enquanto ninguem marcar a caixa no dialogo do EA, o EA continua a
analisar, a registar e a recusar entradas - e o journal continua a dizer, uma vez por hora
por grafico, exatamente qual dos cinco bits falta.

### 21.3 O que fazer a seguir, por ordem

1. Humano: num grafico, F7 > aba Geral > marcar "Permitir Algo Trading" > OK.
2. Confirmar trade_gate_code=0 e autotrading=true no heartbeat no mesmo instante.
3. chart_save_template desse grafico e leitura do expertmode que o build 6294 grava com a
   caixa marcada; replicar aos outros 15 por API.
4. So entao medir trades autonomos: open_reason=Expert, comment=XAU_AI_PRO, N fechos
   consecutivos sem intervencao.

### 21.4 Fila tecnica que nao bloqueia dinheiro

[LOGGER OFFLINE] continua a 33,6/h porque LoggerInit() nunca e chamado: ligar um ficheiro
comum escrito por 17 instancias exige decidir o crescimento em disco (2,5 GB livres) e a
rotacao. [SCANNER] e SYMBOL MANAGER ja estao a 0/h na janela estavel. WebRequest 4014
continua aberto (config\common.ini com WebRequest=0 e WebRequestUrl vazio) e nao afecta
dinheiro porque a IA e consultiva (AIGateRequired() devolve false com
EnableAutonomousMode=true).
## 22. P1.73 - um journal util, nao um journal a repetir-se (02/11/2026)

Regra que este ciclo fixou: **o journal tem de ser util para uma pessoa que o le**. Se a mesma
frase aparece 16 vezes porque ha 16 graficos, a informacao nao e 16 vezes maior - e 16 vezes
mais dificil de ler.

Como se mediu: contagem por tag no journal real do dia (`MQL5\Logs\20261102.log`), nao no
`Logs\` do terminal (esse tem 727 KB de ruido de rede e engana). 171 949 linhas no total.

O que se fez: o throttle passou de por-grafico para por-CONTA, num ficheiro comum
(`Monitoring\AccountLogGate.mqh`). Falha de ficheiro devolve sempre `true`, para que um problema
de log nunca esconda informacao. [TRADE BLOCK] com a mesma causa: 1 linha/hora por conta
(era 1/hora por grafico); causa nova: 1/2 min. [SESSION]: 1/10 min. [HEALTH]: 1/hora, mas
mudanca de estado continua a sair na hora.

Prova de que esta vivo: os ficheiros `loggate_*.bin` existem no disco comum e mudaram as 19:10:59,
depois do reload para v1.2.86. 16/16 graficos confirmados na versao nova por leitura do log.

Estado do dinheiro: `trade_gate_code=3`. `MQLInfoInteger(MQL_TRADE_ALLOWED)=0` e um bit POR
PROGRAMA e nao se liga por codigo. Novidade medida: `expertmode=5` nos 16 `.chr` = 1 (EA) + 4 (DLL),
com o bit 2 (negociacao ao vivo) em falta. O valor correto e 7. Editar o `.chr` nao serve (o MT5
escreve-o a partir do estado dele); tem de ser marcado no dialogo.

## 23. P1.74 - o mesmo facto nao precisa de dezasseis linhas (02/11/2026)

A regra que este ciclo fixou: se dezasseis graficos partilham a mesma conta, o mesmo
simbolo configurado e o mesmo ficheiro, a decima sexta copia de "modulo X
inicializado" nao acrescenta informacao - acrescenta 15 linhas iguais.

O journal passa a ter tres tipos de linha e mais nada:

1. facto unico, com tag e valores ([START], [SYMS], [BROKER], [CHECKLIST], [LEARN],
   [RECOVERY], [STOP]);
2. evento de dinheiro (ordem, bloqueio, falha de rede, mudanca de estado);
3. nada. Quando nao ha nada, nao se escreve nada.

Medicao que sustentou a decisao: 263 linhas por arranque antes, 96 depois (-63%);
1 532 linhas no reload dos 16 graficos contra cerca de 3 600 no formato antigo; as
linhas sem tag cairam de 55,5% para 23% do total.

O proximo degrau esta identificado e nao foi feito por ser o mais invasivo: as ~26
linhas de inicializacao de modulo continuam a sair por grafico. A solucao ja existe e
ja foi provada em runtime no P1.73 (AccountLogGatePodeImprimir, ficheiro comum por
conta); falta aplica-la a esses 26 pontos de chamada.
## 24. P1.75 - um encerramento, uma linha (02/11/2026)

O fecho de uma instancia dizia cinco coisas: "XAU_AI_PRO FINALIZANDO", "Reason=N", "XAU_AI_PRO FINALIZADO", "SYSTEM CLOSED" e uma linha de resumo. Sao quatro linhas para dizer que o programa parou e por que motivo. Passa a uma: [STOP] <simbolo> | motivo=<reason> | equity=<valor> | estado, resumo e relatorios gravados.

A regra que justifica a mudanca: um facto que cabe numa linha nao pode ocupar cinco. Se o motivo do fecho for preciso para diagnostico, ele esta na linha; se nao estiver, o problema e a linha nao ter o dado, nao faltar uma segunda linha.

## 25. P1.76 - a causa uma vez, nao dezasseis (02/11/2026)

O diagnostico de permissoes imprimia a causa completa de TG_MQL_OFF - cerca de 900 caracteres, com as duas hipoteses por testar e as rotas ja recusadas - uma vez por instancia, 16 vezes por arranque. O leitor humano do journal lia o mesmo texto 16 vezes para aprender zero coisas novas na segunda.

Regra: o codigo do portao (codigo=3) identifica o bit que falhou sem ambiguidade. O texto longo continua a existir, mas uma vez por conta, no [TRADE BLOCK]. Diagnostico por instancia carrega o codigo; explicacao carrega-se uma vez.

## 26. P1.77 - uma linha do journal pertence sempre a um namespace (02/11/2026)

O criterio de 10/10 para o journal nao e o numero de linhas: e que nenhuma linha seja anonima. Uma linha sem tag nao se filtra, nao se agrega e nao se apaga sem tocar no codigo. Medido em 02/11: 55,5 por cento sem tag antes do P1.74, 23,3 antes do P1.75, 7,8 antes do P1.76, 2,5 antes do P1.77 e 0,0 depois.

O que sobra nao e ruido de formato, e duplicacao: o mesmo facto escrito uma vez por grafico ([VERSION] 86, [INIT] 80, [LEARN] 80, [NOTIFY] 59, [CONFIG] 59 numa janela de 1 280 linhas). O proximo passo do journal e o portao de conta - a primeira instancia escreve, as outras quinze calam-se - e nao mais compressao de texto.

## Secao 27 - autonomia medida no ciclo 20:26 (v1.2.92)

- O EA opera sozinho quando o bit por programa esta ligado: as 20:13-20:16 o master USDCHF varreu 57 simbolos, gerou sinais, aplicou [VALIDATION] BLOCK com motivo (contramao vetada, ADX 39.8 >= 22.0) e escreveu [RESUMO] master=SIM com a escada de dinheiro armada.
- O que o codigo NAO consegue: o bit MQL_TRADE_ALLOWED (TG_MQL_OFF=3). Tres medicoes hoje provam que qualquer reload o apaga.
- Regra de ciclo: cada vez que o EA for recarregado, avisar o operador para dar UM clique em Permitir Algo Trading no grafico que deve ser master.
- Journal: 1 linha anonima em 900 (0,1 por cento) - criterio 10/10 mantido; proximo alvo e a linha USDBRL SIGNAL BUY do SignalCore.

## Secao 28 - autonomia medida no ciclo 20:43 (v1.2.93)
- O EA opera sozinho quando o bit por programa esta ligado: as 04:00, 06:00, 07:00 e 10:13 abriu 4 posicoes Expert sem intervencao.
- O que o codigo NAO consegue: religar MQL_TRADE_ALLOWED (TG_MQL_OFF=3). Cada reload de template devolve o bit a 0; medido as 20:26 e outra vez as 20:43.
- Regra de ciclo: entregar codigo, recarregar, e SO DEPOIS pedir o clique do operador. Ordem inversa fecha o portao outra vez.
- Porque nao operou desde as 10:13: os sinais existem (3 a 10 por minuto no mestre) mas 100 por cento morrem em AllowTradeEx; o unico simbolo com sinal repetido e o USDBRL com RSI congelado em 37.31.
- Journal: 1 linha anonima em 1 499 (0,1%). Criterio 10/10 mantido; proximo alvo e a linha SYSTEM STATUS WRITE ERROR.

## Secao 29 - autonomia de auditoria (v1.2.93, 20:52)

- O agente consegue, sozinho: varrer 1322 JSON em 4 raizes, validar sintaxe,
  detectar BOM, detectar encoding estragado, achar chaves duplicadas e provar
  coerencia VERSION/version.json. Tudo sem tocar em dinheiro.
- O agente NAO consegue, sozinho: religar `MQL_TRADE_ALLOWED` (TG_MQL_OFF=3).
  Nenhuma API MQL5 escreve esse bit. F7 > Geral > "Permitir Algo Trading" e humano.
- O agente NAO consegue, sozinho: gerar previsao para simbolo sem o pipeline Python.
  Os 10 simbolos sem `prediction_*.json` continuam sem IA ate o pipeline correr.
- Custo medido desta auditoria: 0 ficheiros alterados, 0 recompilacoes, 0 ordens.

## Secao 30 - o que a opcao B provou e o que ela custa (v1.2.93, 21:10)

- O agente consegue, sozinho: ler o journal pela API, medir ADX por simbolo, comparar o caminho `GetADX()` (handle persistente, so `_Symbol`) com `GetADX(symbol)` (handle novo por chamada), e provar que o defeito esta no tratamento de `0.0` como leitura valida.
- O agente NAO consegue, sozinho: (1) religar `MQL_TRADE_ALLOWED` depois de um reload (precisa de F7 no grafico USDCHF); (2) correr um script de diagnostico novo dentro do terminal nesta sessao - a base de programas do servidor MCP nao reconhece ficheiros criados depois do arranque (`specified script not found in base`, idem para `chart_add_indicator`).
- Custo medido desta ronda: 0 ficheiros do EA alterados, 0 recompilacoes, 0 ordens, 1 script de diagnostico criado fora do EA (`MQL5\Scripts\XAI_DiagSignal.mq5`, nao registado, sem .ex5).
- Regra operacional nova: medir pelo journal da API. O ficheiro `Logs\20261102.log` foi truncado a meio da sessao (187 957 -> 5 408 linhas).
