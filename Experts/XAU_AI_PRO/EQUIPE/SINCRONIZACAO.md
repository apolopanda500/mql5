# SINCRONIZACAO DO CANAL EQUIPE

Como os tres agentes (ALFA, DELTA, CMD) e o **DONO** escrevem no mesmo canal sem
se atropelarem. Decidido em `D-015`, `D-016` e `D-017`.

## 1. Duas ferramentas, um unico lock

| Camada | Ferramenta | Comandos |
|---|---|---|
| **escrever** no canal | `tools\sync-agent.ps1` | `post`, `note`, `ask`, `answer`, `id`, `lock`, `log`, `check` |
| **ler, verificar, reparar** | `tools\equipe-sync.ps1` | `status`, `check`, `dono`, `quem`, `pedidos`, `snapshot`, `eol` |
| **lock** | `LOCK.md` (so este) | os dois modulos leem e escrevem o mesmo ficheiro |

Todos os comandos correm a partir da pasta `EQUIPE`:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 <comando>
powershell -NoProfile -ExecutionPolicy Bypass -File tools\sync-agent.ps1 <comando>
```

## 2. As cinco coisas que o DONO faz

| Quero | Comando |
|---|---|
| ver o estado do canal (bytes, linhas, itens abertos, lock) | `equipe-sync.ps1 status` |
| ver **so** as minhas perguntas em aberto | `equipe-sync.ps1 dono` |
| responder a uma pergunta | `sync-agent.ps1 answer -From DONO -Q Q-001 -Resposta "(a)"` |
| ver tudo de uma vez (versao, `.ex5` vs fontes, git, `[START]`, fila) | `sync-agent.ps1 status -Agent DONO` |
| ver os **pedidos de ajuda** que os agentes trocam (`D-020`/`D-021`) | `equipe-sync.ps1 pedidos` |
| confirmar que o canal nao esta corrompido | `equipe-sync.ps1 check` |

**Nenhum agente fecha uma pergunta do dono:** o `answer` exige `-From DONO` e
recusa qualquer outro. Era o furo do canal antigo, em que uma pergunta do dono
podia ficar "resolvida" por quem a fez.

## 3. As cinco regras dos agentes

1. **Antes de escrever:** `equipe-sync.ps1 lock -De <AGENTE> -Motivo "<o que vais fazer>"`. Se recusar, o canal e de outro.
2. **Depois de escrever:** `unlock -De <AGENTE>`.
3. **ID novo** so com `sync-agent.ps1 id -Tipo D|P -From <AGENTE>`. Nunca "o proximo numero" a mao.
4. **Depois de escrever:** `equipe-sync.ps1 check`. EOL do canal e **LF puro**; se acusar `CR=n`, correr `eol` (faz backup antes).
5. **Texto com acento** nunca por linha de comando (o cmd converte-o em 1 byte e estraga o UTF-8): ficheiro UTF-8 + `-CorpoArquivo`.

## 4. O que nenhuma das duas ferramentas faz

`commit`, `push`, `deploy`, `compile`, `reattach`, ordem de mercado, alteracao de
parametro de risco, `git` de escrita, CodeBase. **So medem estado e escrevem nos
`.md` do canal.** O ciclo de commit/push/deploy e do CMD; a zona de codigo e do
ALFA; a conta real continua proibida aos tres.

## 5. Porque isto existe - falhas medidas em 05/11

| Falha | O que a fecha |
|---|---|
| escrita perdida as 22:12 (cabecalho da `INBOX_AGENTE_2.md`, rodape do `DECISOES.md`) | Mutex nomeado + escrita atomica (tmp + move) |
| `D-012` triplo e `D-013` duplo - dois agentes a reservar "o proximo numero" | ledger `IDS.md` reservado dentro do mesmo Mutex |
| compile e reattach em paralelo sobre o mesmo `.ex5` (o binario leva o estado de TODOS os fontes) | `LOCK.md` com dono, motivo e validade |
| dois locks diferentes (`_SYNC\LOCK` e `LOCK.md`) e nenhum agente a ver o do outro | `D-017`: **um** lock, `LOCK.md` |
| EOL misto: `CR=2/6/5/5/9/9/9` em sete ficheiros as 22:30 | comando `eol` (normaliza e faz backup) |
| o dono fora do canal | `INBOX_DONO.md` com `Q-nnn` e campo `RESPOSTA` |

## 6. Ficheiros do canal

`PROTOCOLO.md` (regras) · `QUADRO_ESTADO.md` (estado medido; **manda quando
discordam**) · `DECISOES.md` (`D-nnn`) · `IDS.md` (ledger) · `INBOX_AGENTE_1/2/3.md`
· `INBOX_DONO.md` (`Q-nnn`) · `AGENTE_1/2/3.md` (diarios) · `CONSOLIDACAO.md` ·
`LOCK.md` · `SYNC_LOG.md` · `PEDIDO_DE_AJUDA.md` (protocolo de pedidos) · `CONFIGURACOES.md` (inputs do EA, niveis A/B/C) · `CONFIG_AGENTES.md` (o que cada agente tem e como entrega configuracao) · `_SYNC/` (backups, snapshot, `status.json`).

Ultima alteracao: 05/11/2026 22:47 - DELTA (`D-021`: comando `pedidos` + `CONFIG_AGENTES.md`).
