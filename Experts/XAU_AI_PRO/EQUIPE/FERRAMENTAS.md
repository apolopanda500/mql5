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
