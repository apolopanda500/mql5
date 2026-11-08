# INDICE DO CANAL - XAU_AI_PRO

**Leia este ficheiro primeiro.** Tudo o resto e complemento.
Atualizado: 08/11/2026 06:20 (DELTA: datas, `D-001..D-107`, GATE 2/11, ficheiros de 08/11). Base anterior: 07/11/2026 14:41 (CMD).

## 1. Ordem de leitura (agente novo em 10 min)

1. `QUADRO_ESTADO.md` - estado medido (versao, binario, trades, suite).
2. `CICLO_FINAL.md` - contrato ate ao 10/10 (`D-069`), ratificado em `D-071`.
3. `PROTOCOLO_CICLO_10_10.md` - anexo tecnico do contrato (`D-070`).
4. `DECISOES.md` - o que ja foi decidido (`D-001..D-107`).
5. `GATE_REAL.md` - os 11 portoes e o estado medido (hoje **2 verdes de 11**, forward 0 de 30).
6. `PLANO_10_10.md` - fases F0..F9 e portoes (plano canonico, `D-018`/`D-022`).
7. `BACKLOG.md` - o que falta, com dono e criterio.
8. `AUTORIZACOES.md` - quem pode o que.
9. `CONFIGURACOES.md` + `CONFIG_AGENTES.md` - o que se pode mudar.
10. `PROTOCOLO.md` - regras do canal e da sincronizacao.
11. `FERRAMENTAS.md` - runtimes, MCP, scripts, limpeza.
12. `SESSAO_*.md` - registos de sessao (o que foi feito e medido no fecho).

> Os `SESSAO_*.md` **nao substituem o canal**: `DECISOES.md`, `IDS.md`,
> `SYNC_LOG.md` e as caixas continuam a ser a fonte. Sao o diario de bordo.

## 2. Mapa de ficheiros

| Ficheiro | Dono | Proposito | Leitura |
|---|---|---|---|
| `QUADRO_ESTADO.md` | CMD | estado medido (ecra unico) | diaria |
| `CICLO_FINAL.md` | ALFA | contrato ate ao 10/10 (`D-069`, ratificado `D-071`) | ao assumir |
| `PROTOCOLO_CICLO_10_10.md` | DELTA | anexo tecnico do contrato (`D-070`): papeis, fases, evidencias | ao assumir |
| `GATE_REAL.md` | DELTA | os 11 portoes do GATE_REAL e o estado medido | ao medir |
| `DECISOES.md` | CMD (regista) | decisoes fechadas (`D-001..D-107`) | ao assumir |
| `IDS.md` | ledger | IDs reservados (D/P1/T) | ao escrever |
| `PLANO_10_10.md` | CMD | plano mestre canonico | ao assumir |
| `PLANO_MESTRE.md` | ALFA | historico/complemento (`D-022`) | opcional |
| `BACKLOG.md` | todos | itens com dono e criterio | diaria |
| `AUTORIZACOES.md` | ALFA | matriz de autorizacoes | ao assumir |
| `CONFIGURACOES.md` | ALFA | niveis A/B/C de parametros EA | ao tocar em input |
| `CONFIG_AGENTES.md` | DELTA | o que cada agente tem e como usar | ao assumir |
| `ROTINA_E_PASSAGEM.md` | DELTA | turnos, handoff, runbook | ao parar |
| `RUNBOOK_INCIDENTES.md` | DELTA | resposta a incidentes | ao falhar |
| `SINCRONIZACAO.md` | DELTA | como os 4 escrevem sem colidir | ao escrever |
| `PROTOCOLO.md` | DELTA | regras do canal + sync | ao escrever |
| `PEDIDO_DE_AJUDA.md` | ALFA | como pedir ajuda entre agentes | ao bloquear |
| `PEDIDOS.md` | todos | pedidos inter-agente | ao bloquear |
| `FERRAMENTAS.md` | CMD | runtimes, MCP, scripts, limpeza | ao usar ferramenta |
| `MCP_E_MOTORES.md` | ALFA | politica de MCP/motores | ao instalar |
| `INDICE.md` | CMD | este ficheiro | primeiro |
| `AGENTE_1/2/3.md` | cada um | diario + HANDOFF | ao parar |
| `INBOX_AGENTE_1/2/3.md` | cada um | pedidos dirigidos | ao assumir |
| `INBOX_DONO.md` | todos | fila Q-0NN do DONO | ao precisar do DONO |
| `SESSAO_20251106_ALFA.md` | ALFA | registo da sessao de 06/11 | historico |
| `SESSAO_20261107_ALFA.md` | ALFA | registo de 07/11: autorizacoes do DONO, provas, pendencias | historico |
| `SESSAO_20261107_CMD.md` | CMD | registo de 07/11: commits, ferramentas, estado medido | historico |
| `SESSAO_20261107_DELTA.md` | DELTA | registo de 07/11: medicao, diagnostico, fecho | historico |
| `SESSAO_DELTA_AB_PISO_20261107.md` | DELTA | par A/B do piso 45 vs 40 vs 50 (medido) | ao comparar pisos |
| `SESSAO_20261108_ALFA.md` | ALFA | registo de 08/11: v1.2.188 e D-107 | historico |
| `SESSAO_20261108_DELTA.md` | DELTA | registo de 08/11: sincronizacao de documentos | historico |
| `RELATORIOS/` | CMD | relatorio diario (`YYYYMMDD.md`) gerado as 23:50 | diaria |
| `BRIEFING_ATUAL.md` | CMD | briefing curto gerado por `tools/agente-briefing.ps1` | primeiro |
| `CONSOLIDACAO.md` | CMD | consolidacao da pasta | historico |
| `PRESENCA.md` | cada um | quem esta online e o que mediu | diaria |
| `LOCK.md` | runtime | lock de escrita do canal | antes de escrever |
| `SYNC_LOG.md` | runtime | trilho de locks, posts e ACK | ao medir |
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
- **Um contrato:** `CICLO_FINAL.md` (`D-069`/`D-071`); `PROTOCOLO_CICLO_10_10.md`
  e o anexo tecnico (`D-070`).
- **Um escritor de canal:** `sync-agent.ps1`. Sem `git add -A`.
- **Um ecra unico:** `QUADRO_ESTADO.md`, regenerado antes de cada commit.
- **Uma lista de trabalho:** `BACKLOG.md`. Se nao esta la, nao conta.
- Se um facto so existe no chat, **nao existe**.
- **Quem faz nao assina:** ALFA escreve e mede, CMD entrega, DELTA mede e
  assina, DONO autoriza REAL. Nenhum "10/10" sem 11/11 do GATE_REAL + 30 dias
  de forward em demo + autorizacao escrita.
