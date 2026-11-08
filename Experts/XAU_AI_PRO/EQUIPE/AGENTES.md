# AGENTES - a pagina que qualquer agente le antes de trabalhar

**Criada:** 07/11/2026 22:30 | **Autor:** CMD | **Base:** D-095, D-096, D-097
**Substitui como ponto de entrada:** leitura dispersa de INBOX_*, PRESENCA e
SYNC_LOG. Aqui esta o que e' preciso para comecar em 2 minutos.

---

## 1. Arranque em um comando

```
powershell -NoProfile -ExecutionPolicy Bypass -File Experts\XAU_AI_PRO\EQUIPE\tools\agente-briefing.ps1
```

Imprime e grava `EQUIPE/BRIEFING_ATUAL.md`: HEAD, ficheiros sujos, versao nas 4
fontes, GATE_REAL, mandato, forward, gateway, tarefas, ultimos commits, CI e a
lista de trabalho por agente. **Nao altera nada.**

Antes de publicar:

```
powershell ... -File Experts\XAU_AI_PRO\EQUIPE\tools\sync-agent.ps1 check
powershell ... -File Experts\XAU_AI_PRO\EQUIPE\tools\dono-mandato.ps1 check
```

---

## 2. Quem e' quem

| Agente | Papel | Zona de escrita | Nao faz |
|---|---|---|---|
| **ALFA** | codigo e logica | `Experts/XAU_AI_PRO/**` (fonte), compiles | medir veredicto final, assinar dossie |
| **DELTA** | medicao e veredicto | `EQUIPE/SESSAO_DELTA*`, `GATE_REAL.md` (evidencia), `DOSSIE_FINAL.md` (assinatura) | alterar fonte sem pedir, abrir conta real |
| **CMD** | infra e entrega | `EQUIPE/**`, `tools/**`, git, CI, tarefas, gateway | assinar medicao no lugar do DELTA |
| **DONO** | ordem | escreve `INICIAR` / `ESTADO` / `FINALIZAR` | executar |

Regra de autoria: **quem faz nao assina o que fez**. CMD entrega, DELTA mede.

---

## 3. Ferramentas que todos tem

| Ferramenta | Para que serve | Como |
|---|---|---|
| `sync-agent.ps1` | canal: status, check, post, ask, answer, lock | `... sync-agent.ps1 check` |
| `dono-mandato.ps1` | mandato do DONO: estado, check, relatorio | `... dono-mandato.ps1 estado` |
| `ordem-master.ps1` | ordem unica: iniciar, estado, finalizar | `... ordem-master.ps1 estado` |
| `compile-ea.ps1` | compile com backup do `.ex5` antes | `... compile-ea.ps1` |
| `gateway-start.ps1` | religar o gateway 9011 em modo leitura | `... gateway-start.ps1` |
| `gateway-task.ps1` | estado/instalar/remover a tarefa de sistema | `... gateway-task.ps1 -Acao estado` |
| `agente-briefing.ps1` | contexto completo para agente novo | `... agente-briefing.ps1` |
| `mcp-check.ps1` | verificar MCP e servicos externos | `... mcp-check.ps1` |

---

## 4. MCP e servicos externos

O ambiente tem servidores MCP ligados ao agente (ex.: Context7 para
documentacao de bibliotecas, Supabase, Render, OpenCode Console). Regras:

- **Ler** documentacao e estado por MCP e' permitido e recomendado.
- **Escrever** (deploy, migracao, mensagem, release) exige pedido explicito do
  DONO ou estar dentro do mandato.
- Nunca colar tokens, DSNs ou credenciais em prompts de MCP.
- Se um MCP cair, `mcp-check.ps1` diz qual; instalar/reparar e' autorizado por
  D-097 (registar no `SYNC_LOG.md`).

---

## 5. Autoridade tecnica (D-097)

Os agentes podem pesquisar na web, instalar/desinstalar ferramentas, limpar
temporarios e automatizar **para destravar o projeto**. Limites:

1. Nao remover guarda de risco.
2. Nao abrir conta real sem 11/11 + 30 dias + DELTA.
3. Nao apagar dados pessoais, historico, backups ou o repositorio.
4. Nao expor tokens.
5. Limpeza destrutiva so com backup previo e registo.
6. Risco continua a exigir decisao escrita do DONO.

---

## 6. Regras de trabalho (nao negociaveis)

- Nunca `git add -A`; caminhos explicitos.
- Publicar so em `github`/`main`; **nunca** no Forge (`origin`).
- Commits com autoria declarada (`-c user.name=... -c user.email=...`).
- Canal: UTF-8 sem BOM, LF puro, lock antes de escrever.
- `10/10` nunca e' estado; o estado e' `x/11`.
- Compile so por `compile-ea.ps1` (backup antes).
- Nao chamar o DONO durante a execucao (2 excepcoes do mandato).
- Toda alteracao relevante: decisao `D-xxx`, linha no `IDS.md`, linha no
  `SYNC_LOG.md`, `PRESENCA.md`.

---

## 7. O que esta em jogo agora

| Item | Estado |
|---|---|
| GATE_REAL | **2 de 11** |
| Forward | 0 de 30 (arranca 09/11 00:05) |
| Gateway 9011 | OK (modo leitura; keepalive 5 min) |
| Binario x fonte | BATEM (v1.2.186) |
| Tarefas | 3 do mandato + Dashboard |
| Conta | demo 113568614, plana |
| Risco | intocado |

O objetivo comum e' **11/11 + 30 dias + assinatura do DELTA**, e so entao o
DONO decide o dia da conta real. Nada antes disso e' "100% real".

---

## 8. MCP instalados no OpenCode (D-098, 07/11/2026 22:40)

Servidores ativos em `~/.config/opencode/opencode.json` (backup automatico
antes de cada alteracao):

| Servidor | Para que serve |
|---|---|
| `filesystem` | ler/escrever dentro de `MQL5` |
| `memory` | memoria partilhada dos agentes (`EQUIPE/_SYNC/memory.jsonl`) |
| `context7` | documentacao atualizada de bibliotecas |
| `sequential_thinking` | raciocinio estruturado em passos |
| **`playwright`** (novo) | navegar e testar na web (25 ferramentas) |
| **`sentry`** (novo) | erros e telemetria (70 ferramentas) |
| `supabase`, `render` | servicos externos ja existentes |

Verificacao: `tools/mcp-check.ps1` (0 falhas).

**Nota de seguranca:** o ficheiro de configuracao contem uma credencial de um
servico externo. Nao e' versionado no repositorio, mas deve ser rotacionada pelo
DONO quando for conveniente; nenhum agente a copia para o canal ou para o git.

