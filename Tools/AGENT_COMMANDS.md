# AGENT_COMMANDS — Manual operacional para agentes IA

Documento de referência para qualquer agente (Claude Code, Codex, Cursor,
Copilot) que precise **operar este terminal MetaTrader 5 de ponta a ponta**:
compilar, validar, diagnosticar, testar, versionar e publicar.

Regra de ouro: **todo agente começa pelo pré-flight** (seção 0) e nunca
executa ação destrutiva ou de trading sem autorização explícita (seção 8).

---

## 0. Pré-flight obrigatório

Antes de qualquer coisa, chamar `get_workspace_info` nos **dois** servidores MCP:

| Servidor | Ferramenta | Serve para |
|---|---|---|
| `metaeditor5` | `get_workspace_info` | arquivos, leitura/escrita, compilação |
| `metatrader5` | `get_workspace_info` | terminal, conta, símbolos, tester, journal |

Raízes concedidas (não existe acesso fora delas):

```
leitura : ...\MQL5  |  ...\Tester  |  ...\Logs  |  ...\Common
escrita : ...\MQL5  |  ...\Common
execução: ...\MQL5  |  ...\Common
```

Pastas úteis:

```
MQL5              C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5
Temp (rascunho)   ...\MQL5\Files\Temp
Backup            ...\MQL5\Files\Backup
Compilador        C:\Program Files\MetaTrader 5\metaeditor64.exe   (build 6296, x64)
```

> A pasta `...\<TERMINAL>\config` (onde ficam as opções do terminal, incluindo
> a allowlist de WebRequest) **está fora das raízes**. Nenhum agente consegue
> ler nem alterar essas opções por ferramenta. Isso só o dono faz na GUI.

---

## 1. Toolkit local (sem Python)

`Tools/agent-toolkit.ps1` executa o ciclo completo. Sempre usar caminho absoluto
(o shell pode abrir em outra pasta):

```powershell
$TK = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\agent-toolkit.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK status
powershell -NoProfile -ExecutionPolicy Bypass -File $TK check
powershell -NoProfile -ExecutionPolicy Bypass -File $TK compile
powershell -NoProfile -ExecutionPolicy Bypass -File $TK commit -Message "tipo(escopo): descricao"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK push -Remote github -Branch main
powershell -NoProfile -ExecutionPolicy Bypass -File $TK deploy
powershell -NoProfile -ExecutionPolicy Bypass -File $TK full -Message "tipo(escopo): descricao"
```

| Action | O que faz | Falha se |
|---|---|---|
| `status` | working tree, upstream, ahead/behind | nunca |
| `check` | UTF-8 estrito + chaves `{}` + `#include` em todos `.mq5/.mqh` de `Experts/XAU_AI_PRO` | qualquer falha estática |
| `compile` | compila `XAU_AI_PRO.mq5` via `metaeditor64.exe /compile /log` | `error(s)` > 0 |
| `commit` | `git add --all` respeitando `.gitignore` + commit | nada a commitar |
| `push` | `git push` para o remote/branch indicado | rejeição do remoto |
| `deploy` | `check` → `compile` (publica `.ex5` na pasta do EA) | check ou compile |
| `full` | `check` → `compile` → `commit` → `push` | primeira falha |

Nunca faz `reset`, `checkout` destrutivo, `rebase` nem `force-push`.

---

## 2. Catálogo de ferramentas MCP

### 2.1 `metaeditor5` — arquivos e build

| Ferramenta | Uso típico |
|---|---|
| `list_directory` / `find_files_by_glob` / `find_files_by_name_keyword` | mapear a árvore |
| `read_file` / `read_file_by_lines` / `read_binary_file` | ler trechos (preferir `_by_lines`) |
| `write_file` / `create_new_file` / `replace_text_in_file` | editar preservando encoding |
| `delete_file` / `create_new_folder` | housekeeping dentro das raízes |
| `compile_file` | compilar um `.mq5` |
| `build_project` | compilar o `.mqproj` inteiro |
| `syntax_check` | checar sintaxe sem gerar artefato |
| `format_source_code` | aplicar estilo MetaQuotes |
| `open_file_in_editor` / `list_open_documents` | abrir no MetaEditor |
| `send_web_request` | HTTP de saída (diagnóstico de API) |

### 2.2 `metatrader5` — terminal, dados e automação

| Grupo | Ferramentas |
|---|---|
| Mercado | `get_marketwatch_symbols`, `add_marketwatch_symbol`, `remove_marketwatch_symbol`, `market_book_subscribe`, `market_book_get`, `market_book_unsubscribe` |
| Histórico | `get_chart_history`, `get_chart_ticks_history` |
| Conta | `get_trading_account_info`, `get_trading_open_positions`, `get_trading_history_orders`, `get_trading_history_positions` |
| Gráficos | `chart_open`, `chart_close`, `chart_set_symbol_period`, `chart_get_properties`, `chart_set_properties`, `chart_navigate`, `chart_save_screenshot`, `list_open_charts` |
| Programas no gráfico | `chart_add_expert`, `chart_remove_expert`, `chart_add_indicator`, `chart_remove_indicator`, **`chart_add_script`** |
| Objetos | `chart_object_create`, `chart_object_update`, `chart_object_get`, `chart_objects_list`, `chart_object_delete` |
| Templates/perfil | `chart_save_template`, `chart_apply_template`, `chart_delete_template`, `profile_list`, `profile_add`, `profile_apply`, `profile_delete` |
| Parâmetros | `get_expert_advisor_parameters`, `get_indicator_parameters`, `get_script_parameters`, `get_service_parameters`, `list_available_mql5_programs`, `list_available_indicators` |
| Logs | `get_expert_journal`, `get_terminal_journal`, `get_tester_journal`, `get_news_list`, `get_news_by_id` |
| Calendário | `economic_calendar_list_*`, `economic_calendar_get_*` |
| Tester | `tester_prepare_config`, `tester_prepare_inputs`, `tester_run_backtest`, `tester_run_optimization`, `tester_wait`, `tester_get_status`, `tester_get_report`, `tester_stop`, `tester_list_result_windows` |
| Serviços | `service_register`, `service_start`, `service_stop`, `service_status`, `services_list`, `service_unregister` |
| Alertas | `alerts_list`, `alerts_create`, `alerts_update`, `alerts_set_enabled`, `alerts_delete` |
| Cálculo (sem ordem) | `trade_order_calc_margin`, `trade_order_calc_profit`, `trade_check_market_order`, `trade_check_pending_order` |
| Trading real | `trade_send_market_order`, `trade_send_pending_order`, `trade_modify_sl_tp`, `trade_close_single_position`, `trade_close_by_position`, `trade_delete_order` |

### 2.3 Lacunas conhecidas do MCP (e o contorno correto)

| Lacuna | Sintoma | Contorno |
|---|---|---|
| `search_text` / `search_regex` | retornam `total_matches: 0` para termos que existem | usar `Select-String` via shell |
| Não há "executar script `.mq5`" | só roda `.ex5` compilado | compilar e usar `chart_add_script` |
| Não há leitura/escrita das opções do terminal | allowlist de WebRequest inacessível | pedir ao dono na GUI (seção 4) |
| `chart_add_script` roda em gráfico existente | precisa de um `chart_id` | `list_open_charts` primeiro |
| Journal colapsado em 1 linha | `message` vem inteiro numa linha | filtrar por substring (`filter`) |

Busca confiável:

```powershell
cd /d "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
powershell -NoProfile -Command "Get-ChildItem 'Experts','Scripts','Include','Indicators' -Recurse -File -Include *.mq5,*.mqh | Select-String -Pattern 'WebRequest|https?://'"
```

---

## 3. Git / GitHub

```
branch  : main
upstream: github/main
github  : https://github.com/apolopanda500/mql5.git   (colaboração, CI)
origin  : https://forge.mql5.io/APOLOPANDA500/mql5.git (CodeBase MQL5)
```

Estado esperado de um repo saudável: `## main...github/main` sem `ahead/behind`,
working tree limpo, ~795 arquivos rastreados.

Fluxo padrão:

```powershell
git status -sb
git rev-list --left-right --count github/main...HEAD    # ahead / behind
$TK full -Message "tipo(escopo): descricao"
```

Commit rejeitado por `fetch first` (remoto à frente):

```powershell
git fetch github main
git merge --no-edit github/main
git push github main
```

CI remoto (`CI MQL5 - Validacao Estatica`), consultável pela integração GitHub:

```powershell
Invoke-RestMethod "https://api.github.com/repos/apolopanda500/mql5/actions/runs?per_page=5" |
  Select-Object -ExpandProperty workflow_runs |
  Select-Object name, head_sha, status, conclusion
```

Nunca publicar em `origin` (CodeBase) sem autorização separada.
Nunca reescrever histórico (`filter-repo`, `BFG`, `force-push`) sem autorização.

---

## 4. Diagnóstico de WebRequest (allowlist do terminal)

O MT5 só permite HTTP se **duas** condições forem verdadeiras ao mesmo tempo:

1. Opção **Ferramentas > Opções > Expert Advisors > "Permitir WebRequest para
   URLs listadas"** marcada;
2. O domínio estar **exatamente** na lista.

Códigos de erro:

| Código | Significado | Onde corrigir |
|---|---|---|
| `4014` | WebRequest **desabilitado** (checkbox desmarcado) | GUI, item 1 acima |
| `4060` | URL **fora da lista** | GUI, item 2 acima |
| `5200` | URL inválida (`http://`/`https://` ou domínio errado) | código/input |
| `5201` | conexão falhou (lista OK, host fora) | serviço/backend |
| `5202` | timeout | latência/`AIRequestTimeoutMs` |
| `5203` | pedido falhou (resposta inválida) | backend |

Teste automatizado (script já compilado, roda em qualquer gráfico):

```powershell
# 1. compilar se o .mq5 mudou
#    metaeditor5__compile_file -> MQL5\Scripts\XAI_WebRequestCheck.mq5
# 2. listar gráficos e pegar um chart_id
#    metatrader5__list_open_charts
# 3. executar
#    metatrader5__chart_add_script  chart_id=<id>
#      script_path=...\MQL5\Scripts\XAI_WebRequestCheck.ex5
# 4. ler o veredito
#    metatrader5__get_expert_journal datetime_from=<agora-5min> filter=WEBREQ
```

Saída esperada por URL: `PERMITIDA` / `BLOQUEADA` + motivo. O script distingue
erro de **lista** (4014/4060/5200) de erro de **rede** (5201/5202/5203).

Pontos de WebRequest do projeto:

| Arquivo | Linha | Destino |
|---|---|---|
| `Experts/XAU_AI_PRO/AI/AIConnector.mqh` | ~637 | `AIGatewayUrl` (`http://127.0.0.1:9001/api/ai/predict`) |
| `Experts/XAU_AI_PRO/Enterprise/NotificationCenter.mqh` | ~228 | `https://api.telegram.org/bot<token>/sendMessage` |

---

## 5. Diagnóstico da API de IA (gateway local)

Sonda dedicada:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1
```

O que ela verifica, em ordem: porta TCP → raiz HTTP → `/api/ai/predict` sem
token → com token (`$env:XAU_AI_GATEWAY_TOKEN`). O token nunca é escrito em
arquivo nem no repositório.

Contrato do gateway (medido em `fastapi_gateway.py`):

- símbolo e timeframe vão por **query string**:
  `/api/ai/predict?symbol=XAUUSD&timeframe=H1`
- autenticação: **somente** `Authorization: Bearer <API_TOKEN>`.
  `X-Gateway-Token` **não** é lido e produz 401 mesmo com token correto.
- o EA só envia o header se `AIGatewayToken` não estiver vazio
  (`if(StringLen(AIGatewayToken) > 0)`).
- corpo: `{}` (o EA manda JSON vazio; os dados vão na query).

Vereditos da sonda:

| Resultado | Significa |
|---|---|
| porta fechada | gateway **não está rodando** → subir o serviço |
| HTTP 200 | gateway OK e sem exigência de token |
| HTTP 401 sem token | gateway **exige token** → preencher `AIGatewayToken` no EA |
| HTTP 401 com token | token divergente do `API_TOKEN` do backend |

---

## 6. Diagnóstico de operação do EA

```powershell
# estado vivo: permissões, equity, módulos
#   metatrader5__get_expert_journal filter=STATUS
# sinais e bloqueios
#   metatrader5__get_expert_journal filter=SIGNAL
#   metatrader5__get_expert_journal filter=VALIDATION
# resumo do scanner
#   metatrader5__get_expert_journal filter=SCANNER
# posições abertas
#   metatrader5__get_trading_open_positions
```

Linha `[STATUS] HEALTHY` traz as 5 permissões que precisam estar em `1`:
`MQL_TRADE_ALLOWED`, `TERMINAL_TRADE_ALLOWED`, `ACCOUNT_TRADE_ALLOWED`,
`ACCOUNT_TRADE_EXPERT`, `TERMINAL_CONNECTED`.

O EA roda hoje em 15 gráficos com `MagicNumber=2026001`.

---

## 7. Strategy Tester

```powershell
# 1. tester_prepare_config   (from_date/to_date, model, symbol, timeframe, programa)
# 2. tester_prepare_inputs   (arquivo .set com os parâmetros)
# 3. tester_run_backtest     (wait=true, timeout_sec)
# 4. tester_get_report       (json inline, ou xml/xlsx salvando em arquivo)
```

Um backtest não é prova de lucratividade. Sempre reportar isso.

---

## 8. Limites e proibições

O agente **pode** fazer sozinho: ler/escrever dentro das raízes, compilar,
rodar scripts e backtests, anexar/remover programas em gráficos, versionar e
publicar no GitHub (fluxo já autorizado do toolkit), criar relatórios.

O agente **precisa de autorização explícita** para:

- qualquer `trade_send_*`, `trade_modify_*`, `trade_close_*`, `trade_delete_*`;
- alterar `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`,
  `MaxOpenPositions`, `MaxTradesPerDay` ou desligar guardas de risco;
- `git reset`/`checkout` destrutivo/`rebase`/`force-push`/reescrita de histórico;
- push para `origin` (MQL5 CodeBase);
- expor token, DSN, credencial ou dado de conta em arquivo/log/commit.

O agente **não deve** construir nada que oculte atividade, mascare perda,
falsifique histórico, contorne limites de risco ou prometa lucro. Pedido de
"operação sem limites" é interpretado como **automação completa com guardas
intactas**, não como remoção de proteções.

---

## 9. Receita rápida de retomada

```powershell
$TK = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\agent-toolkit.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK status
powershell -NoProfile -ExecutionPolicy Bypass -File $TK check
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\api-probe.ps1"
```

Depois: `get_expert_journal filter=STATUS` para saber se o EA está operando.
