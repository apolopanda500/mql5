# INDICE DO CANAL - XAU_AI_PRO

**Leia este ficheiro primeiro.** Tudo o resto e complemento.
Atualizado: 05/11/2026 22:58 (CMD).

## 1. Ordem de leitura (agente novo em 10 min)

1. `QUADRO_ESTADO.md` - estado medido (versao, binario, trades, suite).
2. `DECISOES.md` - o que ja foi decidido (D-001..D-023).
3. `PLANO_10_10.md` - fases F0..F9 e portoes (plano canonico, `D-018`/`D-022`).
4. `BACKLOG.md` - o que falta, com dono e criterio.
5. `AUTORIZACOES.md` - quem pode o que.
6. `CONFIGURACOES.md` + `CONFIG_AGENTES.md` - o que se pode mudar.
7. `PROTOCOLO.md` - regras do canal e da sincronizacao.
8. `FERRAMENTAS.md` - runtimes, MCP, scripts, limpeza.

## 2. Mapa de ficheiros

| Ficheiro | Dono | Proposito | Leitura |
|---|---|---|---|
| `QUADRO_ESTADO.md` | CMD | estado medido (ecra unico) | diaria |
| `DECISOES.md` | CMD (regista) | decisoes fechadas | ao assumir |
| `IDS.md` | ledger | IDs reservados (D/P1/T) | ao escrever |
| `PLANO_10_10.md` | CMD | plano mestre canonico | ao assumir |
| `PLANO_MESTRE.md` | ALFA | historico/complemento (`D-022`) | opcional |
| `BACKLOG.md` | todos | itens com dono e criterio | diaria |
| `AUTORIZACOES.md` | ALFA | matriz de autorizacoes | ao assumir |
| `CONFIGURACOES.md` | ALFA | niveis A/B/C de parametros EA | ao tocar em input |
| `CONFIG_AGENTES.md` | DELTA | o que cada agente tem e como usar | ao assumir |
| `ROTINA_E_PASSAGEM.md` | DELTA | turnos, handoff, runbook | ao parar |
| `SINCRONIZACAO.md` | DELTA | como os 4 escrevem sem colidir | ao escrever |
| `PROTOCOLO.md` | DELTA | regras do canal + sync | ao escrever |
| `PEDIDO_DE_AJUDA.md` | ALFA | como pedir ajuda entre agentes | ao bloquear |
| `FERRAMENTAS.md` | CMD | runtimes, MCP, scripts, limpeza | ao usar ferramenta |
| `MCP_E_MOTORES.md` | ALFA | politica de MCP/motores | ao instalar |
| `INDICE.md` | CMD | este ficheiro | primeiro |
| `AGENTE_1/2/3.md` | cada um | diario + HANDOFF | ao parar |
| `INBOX_AGENTE_1/2/3.md` | cada um | pedidos dirigidos | ao assumir |
| `INBOX_DONO.md` | todos | fila Q-0NN do DONO | ao precisar do DONO |
| `CONSOLIDACAO.md` | CMD | consolidacao da pasta | historico |
| `_LEGADO_EQUIPE_2144/` | — | canal antigo do ALFA (preservado) | so referencia |
| `tools/sync-agent.ps1` | DELTA | unico caminho de escrita | ao escrever |
| `tools/equipe-sync.ps1` | DELTA | leitura, check, dono, snapshot, eol | ao medir |
| `_SYNC/` | runtime | SYNC_STATUS, status.json, memory.jsonl, backups, lock | nao editar a mao |

## 3. Ferramentas externas (fora do canal)

| Ficheiro | Papel | Escreve? |
|---|---|---|
| `Tools/equipe-audit.ps1` | auditor externo: UTF-8 estrito, artefactos, hash EA x espelho, estado dos repos | nunca |
| `Tools/agent-toolkit.ps1` | status, check, compile, commit, push, deploy | sim (git/compilador) |
| `Tools/api-probe.ps1` | sonda do gateway | nao |
| `Tools/verify-gateway.ps1` | valida token e resposta do gateway | nao |

## 4. Regra de ouro de organizacao

- **Um plano canonico:** `PLANO_10_10.md`. `PLANO_MESTRE.md` e historico.
- **Um escritor de canal:** `sync-agent.ps1`. Sem `git add -A`.
- **Um ecra unico:** `QUADRO_ESTADO.md`, regenerado antes de cada commit.
- **Uma lista de trabalho:** `BACKLOG.md`. Se nao esta la, nao conta.
- Se um facto so existe no chat, **nao existe**.
