# GUIA OPERACIONAL — MT5 ASSISTANT + XAU_AI_PRO

> **O que é este ficheiro.** O passo-a-passo completo para trabalhar neste
> terminal: o que eu consigo e não consigo fazer, como me dar ferramentas
> novas, como corrigir o EA sem quebrar nada, e como repetir isto num
> projecto novo.
>
> **Regra de leitura:** número aqui é medição, não promessa. Se um comando
> discordar deste texto, o comando vence — e o texto deve ser corrigido.
>
> Criado em 2026-11-03. Autor: MetaTrader Assistant (sessão XAU_AI_PRO).
>
> **rev. 2 (2026-11-03):** acrescentadas as secções 13–20 — as ferramentas
> próprias (`new_mq5_project.py`, `audit_project.py`), o catálogo
> sintoma→causa→acção, os padrões de código que se provaram, o protocolo de
> dados/ML, o workflow de patch, o onboarding de 30 minutos e as decisões
> fechadas.

---

## 0. Como abrir uma sessão comigo (copie e cole)

```
Leia MQL5\Experts\XAU_AI_PRO\Docs\GUIA_OPERACIONAL_MT5_ASSISTANT.md
e o AGENTS.md da pasta do EA. Rode o pre-flight dos dois MCP
(metaeditor5, metatrader5), diga as raízes em que está a trabalhar,
e só depois toque em código. Toda a mudança termina com compilação
0 errors/0 warnings e o número medido antes/depois.
```

Isto poupa 5–10 minutos por sessão: sem isto eu começo por descobrir
pastas e permissões.

---

## 1. O que eu consigo e o que não consigo

| Capacidade | Tenho? | Ferramenta |
|---|---|---|
| Ler/escrever em `MQL5` (todo) | Sim | metaeditor5, metatrader5, shell |
| Compilar `.mq5`/`.mqh`/`.mqproj` | Sim | `compile_file`, `build_file` |
| Ler journal do EA e do terminal | Sim | `get_expert_journal`, `get_terminal_journal` |
| Ler conta, posições, histórico | Sim | `get_trading_*` |
| Correr backtest/optimização | Sim | `tester_*` |
| Ler/alterar gráficos, indicadores | Sim | `chart_*` |
| Correr um `.ex5` (script/EA) | **Não** | não existe no MCP da MetaQuotes |
| Ligar `MQL_TRADE_ALLOWED` de um gráfico | **Não** | bit por gráfico, só GUI (F7) |
| Escrever fora de `MQL5`/`Common` | **Não** | raízes fixas do servidor |
| Editar o `config.yaml` do cliente | **Não** | está fora das raízes |
| Colocar ordens | Sim, mas **só com ordem explícita** | `trade_send_*` |

### 1.1 Raízes medidas (`get_workspace_info`)

```
read_roots    : MQL5 | Tester | Logs | Common
write_roots   : MQL5 | Common
execute_roots : MQL5 | Common
compiler_mql5 : true, build 6294, target x64
compiler_python: false          <-- Python não é "compilado", é executado
max_read_file_bytes: 268435456
```

Consequência prática: `Docs/`, `frontend/`, `backend/`, `core/`, `tests/`
do repositório **não** estão nas minhas raízes. Para eu auditar aquilo,
é preciso um MCP de filesystem com essa raiz (secção 3).

---

## 2. Regras que não se tocam (invariantes do projecto)

1. **Nenhum saque, transferência ou movimentação de fundos para fora da
   corretora.** Ler histórico de saldo pode; mover dinheiro nunca.
2. **Símbolo vazio é recusa com motivo**, nunca um activo padrão.
3. **Parâmetros de risco não se alteram sem justificação escrita**
   (`RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`).
4. **Toda ordem exige `confirm=true` + `request_id` idempotente** e passa
   por `risk_gate`, `intent_log`, `audit_log`.
5. **Compilar não reanexa.** `.ex5` novo só entra em vigor quando o EA é
   reanexado ao gráfico (ou o terminal reinicia).
6. **Nunca declarar "pronto" sem número.** Antes/depois, sempre.
7. **Teste verde pode esconder defeito.** Toda a trava precisa de uma
   prova negativa (o caso que *deveria* reprovar).

---

## 3. Instalar um MCP novo (passo-a-passo)

### 3.1 Servidor que já existe: `mt5_assistant`

Ficheiro: `MQL5\Files\XAU_AI_PRO\Mcp\mt5_assistant_mcp.py`
(stdio, só biblioteca padrão, sem `pip install`, sem rede)

Ferramentas: `roots_info`, `pipeline_run`, `dataset_info`,
`prediction_get`, `validate_report`. Nenhuma coloca ordens.

**Passo 1 — testar o servidor antes de o instalar**

```powershell
cd "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\XAU_AI_PRO\Mcp"
& "C:\Users\Micro\AppData\Local\Programs\Python\Python312-embed\python.exe" -W error::SyntaxWarning mt5_assistant_mcp.py --selftest
```

Esperado: `total=8 falhas=0`. Se alguma linha não for `OK`, **não instale**.

**Passo 2 — editar o `config.yaml`** (fica em
`%APPDATA%\Block\goose\config\config.yaml`; confirme o caminho, a pasta
pode variar). Dentro de `extensions:`, mesma indentação de `metaeditor5:`:

```yaml
  mt5_assistant:
    enabled: true
    type: stdio
    name: mt5_assistant
    cmd: C:\Users\Micro\AppData\Local\Programs\Python\Python312-embed\python.exe
    args:
      - C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\XAU_AI_PRO\Mcp\mt5_assistant_mcp.py
    envs:
      PYTHONIOENCODING: utf-8
      PYTHONUTF8: "1"
    timeout: 1800
    bundled: false
    description: "MT5 assistant: pipeline XAU, dataset freshness, predicoes, relatorio JSON"
```

`timeout: 1800` porque `train` (5 folds) passa de 10 min; com 300 s o
cliente mata o processo e o erro parece do pipeline.

**Passo 3 — reiniciar o cliente** (o YAML é lido no arranque; não recarrega
a quente).

**Passo 4 — verificar**

| Teste | Esperado |
|---|---|
| `mt5_assistant__roots_info` | `tool_py_exists: true`, `python_exists: true` |
| `mt5_assistant__dataset_info` | `ultimo_bar` = último bar real do CSV |
| `mt5_assistant__pipeline_run` com `command: "del /s"` | `RECUSA: comando recusado` |
| `mt5_assistant__validate_report` | `warnings_count` igual ao `[validate]` |

O terceiro teste é a **prova negativa**: se `del /s` passar, o allowlist
está quebrado e o servidor tem de ser desligado imediatamente.

**Passo 5 — rollback**: `enabled: false` e reiniciar. Nada é apagado.

### 3.2 Servidor novo, do zero

1. Escolher transporte: `stdio` (processo local) ou `streamable_http`/`sse`
   (serviço remoto).
2. Escrever o servidor **primeiro com `--selftest`** que exercita cada
   ferramenta sem depender do cliente.
3. Declarar raízes dentro do próprio servidor (como `roots_info` faz).
   Um MCP sem raízes declaradas é um MCP que acede a tudo.
4. Colar o bloco no `config.yaml`, reiniciar, correr a prova negativa.
5. Só depois lhe dou permissão de escrita.

**Segredos**: sempre `${VARIAVEL}` + `env_keys`, nunca em texto. Nunca
neste repositório.

**Regra de ouro**: `npx -y <pacote>` executa código de terceiros na
primeira chamada. Só instale o que foi lido.

---

## 4. Receitas — as cinco operações que se repetem

### 4.1 Compilar e provar que o binário é o do fonte

```
1) metaeditor5 compile_file  XAU_AI_PRO.mq5        -> esperar "0 errors, 0 warnings"
2) shell: dir /t:w MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5
          dir /t:w MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5
3) O .ex5 tem de ser MAIS RECENTE que o .mq5.
```

Motivo medido: em 03/11 00:35 o `.ex5` (757.204 bytes) era **anterior** ao
`.mq5` (00:39, 85.974 bytes) e o journal mostrava regras antigas
(`ADX < 35.0`) apesar de os inputs já dizerem 18.0. Recompilar moveu o
`.ex5` para 761.018 bytes.

Tempo de compilação medido: **18–21 s**. Se compilar em 2 s, compilou
outra coisa.

### 4.2 Silenciar uma linha de journal (sem esconder o defeito)

```
1) localizar a linha:   findstr /s /n /i "<TEXTO>" Experts\XAU_AI_PRO\*.mqh
2) encontrar o input:   findstr /n "<NOME_DA_TAG>" Core\Config.mqh
3) decidir o critério ANTES de editar:
     - desfecho igual ao anterior   -> DiagGateAllow(sym, "TAG", desfecho, heartbeat)
     - estado normal do ciclo       -> não é ruído, é o ciclo a falar
4) editar 1 linha, com comentário a dizer o número medido
5) compilar 0/0 e medir de novo no journal (contar registos na janela)
```

Regra: **suprimir repetição, não suprimir facto**. Se o desfecho muda, a
linha tem de sair.

### 4.3 Actualizar o dado → treinar → publicar → confirmar

```
1) (utilizador) arrastar Scripts\XAI_ExportDataset.ex5 para um gráfico
   -> imprime [EXPORT] FIM | simbolos=16 | linhas=... | ficheiro=...
2) mt5_assistant__dataset_info        -> ultimo_bar deve ser "hoje"
3) editar DATASET_PRIMARY em xau_model_tools.py para o CSV novo
4) mt5_assistant__pipeline_run command=regen
5) mt5_assistant__pipeline_run command=train     (timeout >= 1800)
6) mt5_assistant__pipeline_run command=publish   (só se publicable=true)
7) mt5_assistant__validate_report    -> 0 erros, 0 avisos
8) metatrader5__get_expert_journal   -> [AI] PYTHON | <SIM> | <SINAL> | CONF=...
```

Se o journal disser `[AI] PREDICAO VENCIDA | AGE=... > LIMIT=900s`, o dado
está velho: **não** se aumenta o limite, actualiza-se o dado.

### 4.4 Validar os JSON (o "10/10")

```powershell
cd "…\MQL5\Files\XAU_AI_PRO\Python"
& "…\python.exe" xau_model_tools.py validate
```

Ler a linha `[validate] ficheiros=N ok=N erros=0 avisos=0`. Qualquer aviso
é um ficheiro sem uso real: ou se regenera, ou se arquiva em
`MQL5\Files\Backup\`. **Arquivar ≠ apagar.**

### 4.5 Reanexar o EA sem perder inputs

```
1) ler parâmetros actuais:  get_expert_advisor_parameters(expert_path)
                            + list_open_charts (inputs por gráfico)
2) chart_add_expert com expert_parameters="Nome=Valor,..." completo
3) conferir no journal: [START] vX.Y.Z + [BROKER] ... + [CHECKLIST] 17/17
4) conferir MQL_TRADE_ALLOWED: se 0, o dono liga em F7 > Comum
```

Nunca reanexar sem a lista completa: `chart_add_expert` repõe os defaults
e os defaults mexem em risco real.

---

## 5. Mapa do ruído do journal (onde cada linha nasce)

| Linha | Ficheiro | Como se cala |
|---|---|---|
| `[SCANNER] RESUMO` | `Core\MarketScanner.mqh` | P1.90: silencioso sem exigir `bloqueios==0`; heartbeat `SCAN_SILENT_SEC=900` |
| `[CENARIO]` | `Filters\MarketScenario.mqh:302` | input `EnableScenarioLog` (`Core\Config.mqh:1368`) |
| `[SIGNAL] NEUTRO` | `Core\SignalCore*.mqh` | ainda 11 por ciclo — candidato a DiagGate por símbolo |
| `[PIPELINE] PROCESSANDO` | `Core\TradePipeline.mqh` | P1.46/47: só INICIO/FINALIZADO 1×/hora |
| `[DIAGGATE] N chaves activas` | `Monitoring\DiagGate.mqh` | resumo já sai raramente (medido 0 em 7 min) |
| `[AI] PREDICAO VENCIDA` | `AI\AIConnector.mqh:448` | P1.92: `DiagGateAllow(..., "VENCIDA", 900)` — antes 25×/11 min |
| `[NOTIFY] push desligado` | `Enterprise\NotificationCenter.mqh` | input do terminal, não é defeito |
| `[SYMS] AVISO P1.19` | `Core\SymbolManager.mqh` | gráficos fora da lista `Symbols` |
| `[DATA] logger offline` | `AI\DataLogger.mqh` | cada STOP |
| `[BACKUP] FAIL` | `Enterprise\BackupManager.mqh` | P1.52: 1×/hora |

Método de medição: `get_expert_journal` com `filter` = texto exacto e uma
janela, e contar `records_count`. Sem contagem antes/depois, "ficou mais
limpo" é opinião.

---

## 6. Armadilhas já medidas (leia antes de repetir o erro)

1. **`cmd.exe` trunca no primeiro newline.** Todo o comando tem de ser uma
   linha, com `&&` ou `&`.
2. **`move` para pasta inexistente renomeia.** Em 03/11, um `for ... move`
   com destino `Backup\Backup_crypto_tmp` (sem `\`) colapsou **20 JSON em
   1** de 651 bytes. Faça `mkdir` primeiro, valide com `dir /b`, só depois
   mova. Perdi 19 ficheiros de cripto antigos com isso — estava errado.
3. **`>` do PowerShell escreve UTF-16** e corrompe blob: use `cmd /c`.
4. **`MQL_TRADE_ALLOWED` é por gráfico.** Terminal ligado ≠ gráfico ligado.
   Template/`.chr` não religa (medido).
5. **`.ex5` mais antigo que `.mq5`** = o que corre não é o que está escrito.
6. **Limite de idade da predição = 900 s** (`MaxPredictionAgeSec`). Ficheiro
   fresco com dado velho é aceite — por isso o dado tem de ser medido
   (`dataset_info`), não a data do ficheiro.
7. **O `prediction_<SIM>.json` é reescrito por um gerador de fallback**
   (`dataset_momentum_fallback_v1`, NEUTRAL 51) que não está no fonte MQL5
   (`findstr` = 0, `services_list` = 0). Protecção usada: `attrib +R`.
   Solução definitiva: o pipeline escrever em `Data\Model_<SIM>.json` e o
   connector preferir esse nome.
8. **Compilar não reanexa.** Sem reanexar, o journal continua a mostrar o
   binário antigo e parece que "a correcção não funcionou".
9. **`search_text` do MCP pode devolver 0 fora das pastas permitidas** —
   `findstr` por shell resolve.

---

## 7. Checklist de fim de trabalho (copiar para a resposta final)

```
[ ] Compilação: 0 errors, 0 warnings  (tempo: ____ s)
[ ] .ex5 mais recente que .mq5
[ ] Journal: linha X antes=N depois=M
[ ] Validação JSON: ficheiros=__ ok=__ erros=__ avisos=__
[ ] Ordens: __ posições, P/L __, magic ______
[ ] O que NÃO foi feito, e porquê
[ ] O que exige acção do dono (escrito como pergunta)
```

---

## 8. Criar um projecto novo com este esqueleto

```
Experts\<NOME>/
  <NOME>.mq5            entrada, OnInit/OnTick/OnDeinit magros
  Core/                 Config, Risk*, Execution*, Scanner, Pipeline
  AI/                   AIConnector (JSON), AIEngine, Dataset
  Filters/              News, Spread, Session, Trend, Regime
  Indicators/           ATR, ADX, RSI (handle em OnInit, sem IndicatorRelease)
  Management/           BreakEven, MoneyLadder, EquityProtection
  Monitoring/           Logger, DiagGate, Diagnostics, SystemStatus
  Enterprise/           Backup, Version, FailureMode
Docs\
  GUIA_OPERACIONAL_MT5_ASSISTANT.md   (este ficheiro)
  CONVERSA_<AAAAMMDD>_<TEMA>.md        (estado medido de cada ciclo)
```

Regras de arquitectura que se provaram úteis aqui:

- **um módulo, uma responsabilidade**; o `.mq5` só orquestra;
- **log é contrato**: cada linha tem dono, input e gate;
- **sentinela explícita** para "sem leitura" (ADX = -1.0), nunca 0.0;
- **fail-closed** no dado (idade, símbolo vazio, token) e **fail-open** no
  indicador que ainda aquece;
- **versão e changelog** dentro do código (`VersionManager.mqh`), com o
  número medido em cada entrada P1.xx;
- **um teste de compilação real** por sessão (`compile_file`), porque
  nenhum workflow de CI compila MQL5.

---

## 9. Comandos de bolso

```powershell
# compilar+validar manualmente (fora do MCP)
& "C:\Program Files\MetaTrader 5\MetaEditor64.exe" /compile:"…\XAU_AI_PRO.mq5" /log

# medir idades
dir /t:w MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5

# procurar sem depender do MCP
findstr /s /n /i "TEXTO" Experts\XAU_AI_PRO\*.mqh

# datasets e frescura
dir /b /o-d MQL5\Files\Data\*.csv

# validar JSON
cd MQL5\Files\XAU_AI_PRO\Python
& "…\Python312-embed\python.exe" xau_model_tools.py validate

# servidor MCP: prova de vida
& "…\python.exe" -W error::SyntaxWarning mt5_assistant_mcp.py --selftest
```

---

## 10. Estado medido em 2026-11-03 (referência)

| Item | Valor |
|---|---|
| Conta | 113568614 · MetaQuotes-Demo · hedging · saldo 12 562,44 |
| EA | XAU_AI_PRO (magic 2026001), 15 gráficos, `Symbols` = 11 símbolos |
| Compilação | 0 errors, 0 warnings · 18 046 ms · X64 Regular |
| Validação JSON | `ficheiros=35 ok=35 erros=0 avisos=0` |
| Dataset | `dataset_mt5_20261101.csv` · 1 494 248 linhas · 16 símbolos · último bar `2026.11.02 01:30:00` (0 malformadas) |
| Barra mais curta | USDBRL 24 357 · USDCLP 73 824 · USDCOP 96 067 (restantes 100 000) |
| Modelo XAU | `random_forest_xau_v3` · H1 · SELL 69,02 · edge +0,0363 · AUC 0,5630 · 4/5 folds |
| MCP próprio | `mt5_assistant` **1.2.0** · 27 ferramentas · selftest **11/11** · protocolo 2024-11-05 |
| Ferramentas | `new_mq5_project.py` (selftest 11/11, demo compila 0/0 em 931 ms) · `audit_project.py` (selftest 10/10; XAU **10,0/10**; `NEG_PROVA` **5,1/10 exit 1**) |
| Ruído | `[SCANNER] RESUMO` 2× em 54 min (antes 1×/min por gráfico) |
| Aberto | reanexar o EA (P1.92), exportar dataset novo, `MQL_TRADE_ALLOWED=0` no gráfico XAUUSD |

---

## 11. O que pedir a mim (frases que funcionam)

- "Compila e diz-me se o `.ex5` ficou mais novo que o `.mq5`."
- "Conta quantas linhas `[X]` saíram no journal nos últimos 20 minutos."
- "Antes de editar, diz-me em que ficheiro vive essa linha e qual é o input."
- "Faz a prova negativa: o que devia reprovar aqui?"
- "Mede o dataset e diz-me a idade do último bar."
- "Mostra o antes/depois com números, e o que não fizeste."

E o que **não** deve pedir sem intenção: "reanexa tudo", "apaga os ficheiros
antigos", "aumenta o limite de idade da predição" — as três escondem um
defeito em vez de o resolver.

---

## 12. As minhas ferramentas (o que já não se faz à mão)

Três ficheiros em `MQL5\Files\XAU_AI_PRO\` fazem o trabalho que antes era
conversa: gerar projecto, auditar projecto, e medir o pipeline. Todos têm
`--selftest` com prova negativa — um teste que só passa não prova nada.

| Ferramenta | O que faz | Medido |
|---|---|---|
| `Tools\new_mq5_project.py` | gera um projecto MQL5 modular **compilável** (9 ficheiros) | selftest **11/11**; `DEMO_SKELETON` compilou **0 errors / 0 warnings, 931 ms** |
| `Tools\audit_project.py` | auditor estático, nota 0–10, 30 códigos | selftest **10/10**; XAU_AI_PRO **10,0/10**; `NEG_PROVA` **5,1/10 com 4 ERROS e exit 1** |
| `Mcp\mt5_assistant_mcp.py` | 27 ferramentas MCP (ficheiros, git, pipeline, auditor, gerador) | versão **1.2.0**, selftest **11/11** |

### 12.1 Gerar um projecto novo

```powershell
cd MQL5\Files\XAU_AI_PRO\Tools
& "…\Python312-embed\python.exe" new_mq5_project.py --name MEU_EA
& "…\Python312-embed\python.exe" new_mq5_project.py --name MEU_EA --root "…\MQL5\Files\Temp\Demo" --force
& "…\Python312-embed\python.exe" new_mq5_project.py --list
```

Gera `MEU_EA.mq5` + `Core\Config.mqh`, `Core\RiskCenter.mqh`,
`Filters\SessionFilter.mqh`, `Indicators\AtrFilter.mqh`,
`Monitoring\DiagGate.mqh`, `Monitoring\Logger.mqh`, `Docs\README_MEU_EA.md`,
`AGENTS.md`. **Não** gera `.mqproj` (o MetaEditor cria) e **não** negoceia:
`InpEnableTrading=false` e `SignalStub()` devolve 0 — o esqueleto compila e
fica calado até alguém escrever o sinal.

Pelo MCP, sem shell: `scaffold_new {name:"MEU_EA"}` → escreve em
`XAU_AI_PRO\Scaffolds\MEU_EA`. Medido: `DEMO_MCP` compilou **0/0 em 1 157 ms**.

### 12.2 Auditar um projecto (o "10/10" que não é conversa)

```powershell
& "…\python.exe" audit_project.py "…\MQL5\Experts\XAU_AI_PRO" --json "…\audit.json"
```

Códigos e o que significam:

| Código | Nível | Significado |
|---|---|---|
| `A001` | ERRO | não há `.mq5`/`.mqh` na pasta |
| `A002` | ERRO | ficheiro não é UTF-8 |
| `A003` | INFO | N ficheiros com BOM (o compilador aceita; só inconsistência) |
| `A004` | ERRO | chaves `{ }` desbalanceadas (ignora strings e comentários) |
| `A005` | AVISO | TAB onde o projecto usa 3 espaços |
| `A006` | ERRO | `#include` que não resolve (caminho errado ou ficheiro ausente) |
| `B000` | INFO | nenhuma chamada de negociação (esqueleto ou EA de leitura) |
| `B001` | ERRO | sem `RiskPercent` / `MaxDailyLoss` / `MaxDrawdown` |
| `B002` | ERRO | sem magic number |
| `B003` | ERRO | negoceia sem verificar `retcode` |
| `B004` | AVISO | negoceia sem verificar `MQL_TRADE_ALLOWED` |
| `B005` | AVISO | `PositionSelect` sem filtro `POSITION_MAGIC` |
| `B006` | INFO | marcadores TODO/FIXME |
| `B007` | INFO | `DiagGateAllow` usado N× (log com anti-repetição) |
| `B008` | AVISO | mais de 10 `Print()` sem gate |
| `B009` | AVISO | handle de indicador sem `IndicatorRelease` |
| `B010` | AVISO | `OnTick` sem guarda de barra nova |
| `C001` | AVISO | nenhum `.ex5` compilado |
| `C003` | ERRO | `.ex5` **mais velho** que o `.mq5` → o terminal corre código antigo |
| `D001` | ERRO | JSON inválido em `Files\Data` |

Nota: cada **código** desconta no máximo 3× (um achado cosmético repetido 28
vezes não vale mais do que 28 defeitos reais). Exit code **1** se houver erro,
para poder entrar em CI. Pelo MCP: `audit_run {}`.

**O que o auditor NÃO faz:** não compila e não substitui o compilador. Forma
certa ≠ comportamento certo. Um 10/10 aqui significa "não há defeito
estrutural visível", não "o EA ganha dinheiro".

---

## 13. Catálogo sintoma → causa → acção

Tudo abaixo foi medido neste terminal. A coluna "prova" é o que confirma o
conserto — sem ela, é opinião.

| Sintoma no journal | Causa real | Acção | Prova |
|---|---|---|---|
| `[SCANNER] BLOCK | NoSignal` em todos os símbolos | predição com idade > `MaxPredictionAgeSec` (900 s) ou ausente | exportar dataset novo, `regen`→`train`→`publish` | `[AI] PYTHON | XAUUSD | SELL | CONF=…` |
| `[AI] PREDICAO VENCIDA | AGE=924s` 25× em 11 min | log sem gate | `DiagGateAllow(sym,"ai_stale","VENCIDA",900)` | contagem da linha antes/depois |
| `[AI] GATEWAY | HTTP 401` | `AIGatewayToken` ausente/inválido | obter token **ou** desligar a tentativa de gateway | linha desaparece |
| `[TRADE BLOCK] MQL_TRADE_ALLOWED=0` | bit **por gráfico**, não do terminal nem do `.ex5` | F7 → Comum → Permitir negociação algorítmica, **ou** reanexar pela GUI | `[TRADE] … permitido` |
| `SYSTEM STATUS WRITE ERROR | Code=5004` | ficheiro de estado aberto por ~17 instâncias | abafar 1×/sessão (`s_avisouStatusWrite`) | 1 linha em vez de N |
| `[SCANNER] RESUMO` 1×/min por gráfico | critério de silêncio exigia `bloqueios==0` | bloquear é o estado **normal**; heartbeat 900 s | 2–3 registos em ~50 min |
| `[AI] Client shutdown` / `[DATA] logger offline` a cada STOP | OnDeinit verboso | gate de saída | 1 linha por STOP |
| EA não muda comportamento após editar | `.ex5` mais velho que o `.mq5`, ou EA não reanexado | compilar **e** reanexar | `C004` na auditoria + hora do `.ex5` |
| `prediction_X.json` volta a `NEUTRAL 51.13` | escritor **externo** ao EA (fallback) | `attrib +R` (reversível) ou pipeline escrever `Model_<SIM>.json` | conteúdo do ficheiro, não a data |
| `[AI] LOAD | FILE=Data\prediction_…` mas sinal não aparece | nome do símbolo do broker tem sufixo (`XAUUSD#`, `.PRO`) | normalização + alias `GOLD/XAU` | `FILE=` correcto no log |
| 20 avisos de validação "predição com mais de 24h" | JSON de cripto de agosto em `Data` | arquivar em `Files\Backup\`, nunca apagar às cegas | `validate` com `avisos=0` |
| `#include` não resolve mas o MetaEditor abre | maiúsculas/minúsculas ou `\` vs `/` | nome igual ao disco; o MQL5 é *case-sensitive* para ficheiros | `A006` limpo |
| `'X' - undeclared identifier` | falta `#include` ou o nome mudou | incluir o módulo; não renomear público sem pedido | compilação 0/0 |
| `possible loss of data due to type conversion` | `int` a receber `long`/`double` | `long` para datas, `(int)MathRound()` explícito | 0 warnings |
| `wrong parameters count` | assinatura de `.mqh` mudou | ler a assinatura actual antes de chamar | 0/0 |
| `cmd.exe` "não fez nada" e exit 0 | comando com newline: o `cmd` trunca na 1ª linha | tudo numa linha com `&&` | saída real do comando |
| `move` para pasta inexistente "funcionou" | destino sem `\` final = nome de ficheiro | criar a pasta primeiro, destino com `\` | `dir` da pasta |
| `git status` → `bad signature 0x00000000` | índice zerado, não o repositório | `git read-tree HEAD` | `git status` normal |
| ficheiro com 0 bytes de conteúdo e mesmo tamanho | ficheiro destruído, não "binário" | ler bytes; recuperar do source map/`git cat-file` | conteúdo legível |

---

## 14. Os oito padrões de código que se provaram

1. **Gate de log** — toda a linha que pode repetir passa por aqui:

```mql5
if(DiagGateAllow(_Symbol, "risco", motivo, 300))
   LogWarn("RISCO", motivo);
```

2. **Sentinela explícita** para "sem leitura": `-1.0`, nunca `0.0`
   (`0.0` é um valor válido e esconde o aquecimento).

3. **Fail-closed no dado, fail-open no indicador**: idade/token/símbolo vazio
   recusam; ATR/ADX ainda a aquecer não bloqueiam.

4. **Uma decisão por barra**:

```mql5
const datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
if(bar == 0 || bar == g_lastBar) return;
g_lastBar = bar;
```

5. **Volume pela ficha do símbolo**, nunca por constante:
   `SYMBOL_VOLUME_STEP/MIN/MAX` + `SYMBOL_TRADE_TICK_VALUE/TICK_SIZE`.

6. **Risco num só sítio** (`RiskCenterAllows`) que devolve **motivo escrito**;
   o `OnTick` não calcula risco.

7. **`retcode` obrigatório**: `10009` = feito; qualquer outro é erro tratado,
   não ignorado.

8. **Log com dono**: cada linha tem tag, ficheiro e input que a desliga. Se não
   se sabe desligar, não se escreve.

---

## 15. Protocolo de dados e ML (reutilizável)

Formato do dataset (`Files\Data\dataset_mt5_<AAAAMMDD>.csv`, sem cabeçalho):

```
0=time 1=symbol 2=open 3=high 4=low 5=close 6=tickvol 7=spread 8..14=0.0
```

Regras que custaram tempo:

- **frescura primeiro**: se o último bar tem mais de `MaxPredictionAgeSec`
  (~15 min), o EA recusa a predição — e faz bem. Não se aumenta o limite;
  exporta-se dado novo (`Scripts\XAI_ExportDataset.mq5` → arrastar no gráfico).
- **sem dado fresco não se treina.** Nunca inventar `timestamp_utc`.
- **métrica**: balanced accuracy + AUC contra a classe maioritária. `accuracy`
  simples engana com deriva de alta.
- **walk-forward purgado, 5 folds**; candidato escolhido nas 2 primeiras folds
  e medido nas 3 últimas (senão é escolha olhando o resultado).
- **gates**: `MIN_EDGE_BAL=0.03`, `MIN_AUC=0.52`, estável em ≥4/5 folds;
  `publicable=false` caso contrário.
- **comandos**: `probe | regen | train | publish | validate | stamp`.
- **ciclo completo**: `probe` → `regen` → `train` → `publish` → `validate` →
  confirmar no journal `[AI] PYTHON | <SIM> | <SINAL> | CONF=…`.
- Medição honesta desta conta: M5 `+0,0069`/AUC `0,5184`, M15 `-0,0012`/`0,5070`,
  H4 `-0,0123`/`0,5047`, **H1 `+0,0363`/`0,5630` 4/5**. Só o H1 passa — e é
  edge pequeno, medido fora de conta real.

---

## 16. Corrigir sem quebrar (workflow de patch)

1. **Localizar antes de ler**: `search_text`/`findstr` pela linha exacta do
   journal → ficheiro:linha.
2. **Reler o ficheiro antes de editar** — outro agente pode ter mexido.
3. **Patch pequeno**: uma linha por edição funciona. Bloco multilinha falha com
   "No match found" / `replacements: 0`. Encadear linhas.
4. **Se o patch estraga a estrutura** (aconteceu: a lista `TOOLS` perdeu 13
   entradas), não remendar: **script de reparação determinístico** com backup
   `.bak_before_repair`, e medir bytes antes/depois.
5. **Compilar sempre**: `compile_file` → 0 errors / 0 warnings, com tempo.
6. **Journal**: contar a linha antes e depois (número, não impressão).
7. **Prova negativa**: escrever o caso que *deveria* reprovar e confirmar que
   reprova (`NEG_PROVA` → 4 ERROS, exit 1).

O que **nunca** se faz para o sintoma desaparecer: aumentar limite de idade,
`xfail`, afrouxar trava, apagar a linha de log, `attrib +R` sem dizer (é
paliativo, não conserto).

---

## 17. Onboarding de um projecto desconhecido em 30 minutos

```
0. get_workspace_info nos dois MCP; dizer as raízes.          (2 min)
1. audit_project.py "<pasta>"        -> nota, erros, .ex5 velho  (1 min)
2. list_dir depth=2 + Docs\*.md      -> arquitectura real        (5 min)
3. compile_file do .mq5              -> baseline 0/0?            (1 min)
4. get_expert_journal últimos 20 min -> ruído por tag, contar    (5 min)
5. search_text da tag mais ruidosa   -> ficheiro:linha + input   (5 min)
6. chart/list_open_charts            -> símbolos, EA anexado?    (2 min)
7. get_trading_open_positions        -> o que está em mercado    (2 min)
8. Escrever: estado medido + 3 riscos + 1 próxima acção          (5 min)
```

O que **não** se faz no minuto 1: reescrever ficheiros, "limpar" pastas,
recompilar tudo, mexer em parâmetros de risco.

---

## 18. Erros frequentes e o que significam

| Mensagem | Significado prático |
|---|---|
| `INIT_PARAMETERS_INCORRECT` | input inválido no `OnInit` — validar antes de tudo |
| `INIT_FAILED` | falha de recurso (handle, ficheiro, memória) |
| `10009` | `TRADE_RETCODE_DONE` — ordem executada |
| `10016` | stops inválidos (lado, distância mínima, freeze level) |
| `10018` | mercado fechado |
| `10019` | sem dinheiro suficiente |
| `4756` | `OrderSend` recusado no servidor — ler `retcode` e `comment` |
| `4014` | sem ticks no tester/mercado fechado — motivo para fail-open |
| `5004` | ficheiro ocupado por outra instância (multi-gráfico) |
| `4109` | `OrderSend` sem permissão de negociação (`MQL_TRADE_ALLOWED`) |
| `4802` | símbolo não seleccionado no Market Watch |

---

## 19. Decisões fechadas (não reabrir sem número novo)

| Decisão | Valor | Porquê |
|---|---|---|
| `DynADXClear` | **35.0** | PnL por banda: `ADX<20 -14 102`, `20–25 -17 952`, `25–35 -31 033`, `≥35 +36 153` (WR 82,6 %, PF 1,295) |
| `NewsTrendMinADX` | **18.0** | exclusivo do veto de notícia, não do filtro geral |
| `MaxPredictionAgeSec` | **900** | fail-closed correcto; o conserto é dado novo, não mais tolerância |
| Magic | **2026001** | separa posições do EA das do dono |
| Métrica de treino | balanced acc + AUC | `accuracy` engana com deriva |
| JSON sem uso | **arquivar** em `Files\Backup\` | apagar perde a prova do que existiu |
| `prediction_XAUUSD.json` | `attrib +R` | escritor externo; paliativo declarado, reversível com `attrib -R` |

---

## 20. Fim

Este guia é para ser corrigido. Se um número deixar de bater, ou se um passo
novo se provar necessário, acrescente-se aqui — e a próxima sessão começa mais
longe do que esta. Regra final: **o comando vence o texto, e o número vence a
opinião.**
