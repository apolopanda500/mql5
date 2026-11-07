# FERRAMENTAS DA EQUIPA - XAU_AI_PRO

**Atualizado:** 05/11/2026 22:52 por CMD (`D-018`)
**Regra:** ferramenta nova entra aqui com **versao, evidencia de que arranca e
para que serve**. Ferramenta sem uso declarado nao se instala.

---

## 1. Runtimes medidos (05/11 22:41)

| Ferramenta | Versao | Nota |
|---|---|---|
| Node.js | v26.3.0 | base dos MCP via `npx` |
| npm | 11.16.0 | — |
| git | 2.56.0.windows.3 | repo pai + aninhado |
| GitHub CLI `gh` | 2.97.0 | autenticado `apolopanda500` |
| Docker CLI | 27.3.1 | cliente presente; daemon nao testado |
| Python `python`/`py` | **ausente do PATH** | a app usa `Files/XAU_AI_PRO/.venv/Scripts/python.exe` |
| `uv` / `winget` | ausentes | nao instalar sem necessidade |

**Consequencia pratica:** qualquer script Python da equipa deve chamar o
`.venv` explicitamente, nunca `python` pelado.

---

## 2. MCP instalados (D-018, 05/11 22:46)

Ficheiro: `C:\Users\Micro\.config\opencode\opencode.json`
Backup antes da alteracao: `opencode.json.bak.20261106014625` (2 814 B).
Metodo: `npx` + handshake JSON-RPC real (`initialize`), nao apenas `npm view`.

| Nome | Pacote | Versao | Handshake | Para que serve aqui |
|---|---|---|---|---|
| `filesystem` | `@modelcontextprotocol/server-filesystem` | 2.2.0 | `secure-filesystem-server v2.2.0` | operacoes de ficheiro estruturadas, limitadas a arvore `MQL5\` |
| `memory` | `@modelcontextprotocol/server-memory` | 2.1.0 | `memory-server v2.1.0` | grafo de conhecimento partilhado entre sessoes e agentes |
| `context7` | `@upstash/context7-mcp` | 4.5.0 | `Context7 v4.5.0` | documentacao atual de pandas/lightgbm/FastAPI/etc. |
| `sequential_thinking` | `@modelcontextprotocol/server-sequential-thinking` | 2.1.1 | `sequential-thinking-server v2.1.1` | planear passos longos sem perder o fio |

**Onde a memoria persiste:**
`Experts\XAU_AI_PRO\EQUIPE\_SYNC\memory.jsonl`

Entidades que devem existir la (manter atualizadas):

- `XAU_AI_PRO` - estado do EA, versao, producao
- `Canal EQUIPE` - regras, donos, ferramentas
- `Risco` - parametros congelados e quem os pode mudar
- `Achados` - cada bug medido (Q-00n) com evidencia e estado

### 2.1 Avaliados e NAO instalados

| MCP | Porque nao |
|---|---|
| `github` (`@modelcontextprotocol/server-github`) | o token do `gh` tem `delete_repo` e `admin:org`; copia-lo para outro ficheiro multiplica o raio de dano. O `gh` CLI ja cobre CI/PR/issues. **Reavaliar so com token fine-grained.** |
| `fetch` | nao existe pacote npm oficial; o `webfetch` nativo cobre o caso |
| `playwright` | ~100 MB de browsers; sem uso declarado ainda |
| `sqlite`/`postgres` | a app nao usa BD relacional hoje; adicionar quando usar |

### 2.2 Se a config quebrar

```
copy "%USERPROFILE%\.config\opencode\opencode.json.bak.20261106014625" ^
     "%USERPROFILE%\.config\opencode\opencode.json"
```

O `memory` nao depende da config: o `.jsonl` fica no repo do canal.

---

## 3. Ferramentas proprias do projeto

| Ficheiro | Papel | Escreve? |
|---|---|---|
| `EQUIPE/tools/sync-agent.ps1` | **unico** caminho de escrita no canal: Mutex + ledger + `LOCK.md` + fila do DONO | sim |
| `EQUIPE/tools/equipe-watch.ps1` | monitor em tempo real: observa inboxes, PEDIDOS.md, LOCK.md, PRESENCA.md e avisa quando mudam; `-Quem` lista presenca | so leitura |
| `EQUIPE/tools/equipe-sync.ps1` | leitura, `check`, `dono`, `snapshot`, `eol` | so em `_SYNC/` e reparo com backup |
| `Tools/equipe-audit.ps1` | auditor externo: UTF-8 estrito, artefactos, **hash EA x espelho**, estado dos 2 repos | **nunca** |
| `Tools/agent-toolkit.ps1` | ciclo: `status`, `check`, `compile`, `commit`, `push`, `deploy` | sim (git/compilador) |
| `Tools/api-probe.ps1` | sonda do gateway (porta, raiz, rota, token presente) | nao |
| `Tools/verify-gateway.ps1` | valida token e resposta do gateway | nao |

### Ordem de uso no fecho de ciclo (CMD)

```
powershell -File Tools\equipe-audit.ps1 all          # mede antes
powershell -File Tools\agent-toolkit.ps1 check       # valida MQL5
powershell -File Tools\agent-toolkit.ps1 compile     # 0 errors
# regenerar QUADRO_ESTADO.md
git add <lista explicita> ; git commit ; git push github main
```

---

## 4. Limpeza (F8) - contrato

- **Por omissao `-DryRun`**: lista primeiro, apaga depois.
- **Permitido:** `%TEMP%\opencode`, `__pycache__`, `.pytest_cache`,
  `_SYNC/backup` com mais de 14 dias, logs com mais de 30 dias, `dist/`,
  `build/`, `.mypy_cache`.
- **Proibido:** `Data/*.csv`, qualquer `.ex5` em uso, perfis/`Profiles` do
  terminal, `.git`, `.env`, `.venv`, `node_modules` da app, qualquer caminho
  fora da arvore `MQL5\` sem lista aprovada pelo DONO.
- **Relatorio obrigatorio:** bytes libertados + lista, gravado em `_SYNC/`.

---

## 5. Pesquisa (F9)

Autorizada pelo DONO em 05/11 22:43: web, GitHub, documentacao, MCP novos.
Regra: ideia -> `BACKLOG.md` com **fonte, custo e risco**. Nunca direto no
codigo de producao.
---

## 6. `equipe-auto.ps1` (novo, DELTA, 05/11 23:38) - relatorio unico so leitura

Mede num comando tudo o que se pode medir sem tocar em nada. **Nao escreve no
canal, nao altera ficheiros do EA, nao compila, nao apaga.** A unica escrita
possivel e o relatorio em `_SYNC\relatorios\` quando se passa `-Salvar`.

```
cd MQL5\Experts\XAU_AI_PRO\EQUIPE\tools

powershell -NoProfile -ExecutionPolicy Bypass -File equipe-auto.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File equipe-auto.ps1 -Salvar
powershell -NoProfile -ExecutionPolicy Bypass -File equipe-auto.ps1 -Silencioso
```

### O que mede, por ordem

| Bloco | O que verifica | Falha se |
|---|---|---|
| `CANAL` | `equipe-sync.ps1 check` - EOL LF puro, UTF-8 valido, sem BOM | nao disser `INTEGRO` |
| `AUDITOR` | `Tools\equipe-audit.ps1 all` (read-only) | exit != 0 |
| `DISCO` | espaco livre na unidade do terminal | livre < 1000 MB (aviso entre 1000-2000) |
| `CONSUMIDORES` | `Tester\logs`, `Files`, `Files\XAU_AI_PRO`, `Data`, `Temp`, `Backup` | aviso se `Tester\logs` > 1500 MB |
| `FILA DO DONO` | contagem de blocos por responder no `INBOX_DONO.md` | aviso se > 0 |
| `PEDIDOS` | contagem por estado em `PEDIDOS.md` | - |
| `IDS / DECISOES` | blocos `D-xxx` vs linhas `USADO` no `IDS.md` | aviso se USADO > blocos |
| `ESPELHO / CODIGO` | tamanho e mtime do `.ex5`, total de fontes `.mq5/.mqh` | - |
| `GIT` | branch + ficheiros alterados/nao rastreados | - |
| `VEREDICTO` | soma de falhas e avisos | codigo 1 se houver falha |

### Codigo de saida

- `0` = CONFORME (podem existir avisos)
- `1` = pelo menos uma falha real (canal quebrado, auditor a sair mal, disco < 1000 MB)

### Regra operacional ligada a este script (governada por DELTA)

Se o disco livre descer de **800 MB**, o agente **para o backtest em curso**
(`tester_stop`) antes que encha. Um teste perdido custa minutos; um disco cheio
pode custar o terminal e os 13 graficos.

### Primeira execucao (referencia medida)

```
EQUIPE-AUTO :: 2026-11-05 23:38:19
CANAL        CANAL INTEGRO :: 0 problemas
AUDITOR      RESULTADO: ok   (exit 0)
DISCO        livre: 2283 MB   usado: 225636 MB
CONSUMIDORES Tester\logs 2675.4 MB / 7 f ; Files 5621.9 MB / 63221 f
FILA DONO    26 blocos :: ~26 por responder
IDS          34 blocos D-xxx :: 21 IDs USADO
ESPELHO      XAU_AI_PRO.ex5 :: 929558 B :: 2026-11-05 23:12:18
GIT          branch main :: 45 alterados/nao rastreados
VEREDICTO    CONFORME :: 0 falhas
```

### Limite honesto

Este script mede **ficheiros e disco**. Nao mede conta, posicoes, graficos,
runtime de EA, nem estado de backtest - isso exige ferramentas MCP
(`get_trading_account_info`, `list_open_charts`, `tester_get_status`), que so o
agente pode chamar. Nao substitui o agente: tira-lhe o trabalho repetitivo.
