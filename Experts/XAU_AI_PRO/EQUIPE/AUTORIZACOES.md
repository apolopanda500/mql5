# AUTORIZACOES - quem pode o que (equipa de 4)

**Vigente desde:** 05/11/2026 22:38, por autorizacao oral do DONO nessa hora.
**Registo:** `DECISOES.md` `D-017`. Alteracoes exigem linha do DONO no `INBOX_DONO.md`.

Participantes: **ALFA** (Agente 1), **DELTA** (Agente 2), **CMD** (Agente 3), **DONO** (Agente 4 - o operador).

---

## 1. Matriz

| Capacidade | ALFA | DELTA | CMD | DONO |
|---|---|---|---|---|
| Pesquisar na web, GitHub, docs MQL5, artigos | sim | sim | sim | sim |
| Estudar melhorias e propor (sem aplicar) | sim | sim | sim | sim |
| Editar codigo na **sua** zona (`D-008`) | sim | sim | sim | sim |
| Compilar | sim (com LOCK) | sim (com LOCK) | sim (com LOCK) | sim |
| Reattach / anexar EA em graficos | sim | sim | **nao** (sem MCP `metatrader5`) | sim |
| Ler conta, journal, tester | sim | sim | **nao** | sim |
| Escrever no canal (`post`, `note`) | sim | sim | sim | sim |
| Reservar ID (`id`) | sim | sim | sim | sim |
| `commit` local | sim | sim | sim | sim |
| `push` para `github` (apolopanda500/mql5) | sim (com LOCK) | sim (com LOCK) | sim (com LOCK) | sim |
| `deploy` = build + publicar `.ex5` na pasta | sim (com LOCK) | sim (com LOCK) | sim (com LOCK) | sim |
| Limpar `MQL5/Files/Temp`, `MQL5/Files/Backup`, logs antigos **dentro** de `MQL5` | sim | sim | sim | sim |
| Limpar pastas do **Windows** fora do terminal | **nao** | **nao** | **nao** | sim |
| Alterar parametro de risco | **nao** | **nao** | **nao** | **so o DONO** |
| Enviar ordem em conta real | **so com G5 escrita** | **so com G5 escrita** | **so com G5 escrita** | sim |
| Publicar no CodeBase / `origin` | **nao** | **nao** | **nao** | so o DONO |
| Fechar uma pergunta `Q-nnn` do dono | **nao** | **nao** | **nao** | **so o DONO** |

**Nota sobre `commit`/`push`/`deploy`:** o dono autorizou os tres. Para nao haver dois commits em cima um do outro, **a operacao e serializada por LOCK**: quem for commitar toma `lock -Acao pegar -From <EU> -Motivo commit`, faz, e liberta. O CMD continua a ser o executor **preferido** (`D-007`), mas deixa de ser exclusivo.

---

## 2. Limites que a autorizacao NAO remove

1. **Raiz do shell.** Um agente so toca em `MQL5`, `Common`, `Tester` e `Logs`. "Limpar o Windows" (Downloads, Temp do sistema, `%WINDIR%`, cache de outros programas, registo, servicos, agendador) **fica fora** dessa raiz e nenhum dos tres pode executa-lo, por muito que o dono autorize em conversa: a ferramenta recusa antes de correr. O DONO faz, ou move os alvos para uma pasta dentro das raizes.
2. **Conta real.** Autorizacao para "trabalhar no projeto" **nao** e autorizacao para enviar ordem em conta real. A ordem real exige `G5` escrita e o degrau de F5.
2. **Segredos.** Token do gateway, credenciais e DSN nunca vao para ficheiro versionado nem para log.
3. **Dados de conta.** Saldo/numeros de conta nao saem do canal interno.
4. **Binarios.** `.ex5`, `.dll`, `Data/*.csv` e `.set` nao se apagam sem ordem explicita.

---

## 3. Obrigacoes de cada um (nao sao opcionais)

| Obrigacao | Como |
|---|---|
| Antes de compilar ou reanexar | `lock -Acao pegar` e `lock -Acao liberar` no fim |
| Antes de abrir um ID | `id -Tipo D\|P1\|T -From <EU> -Assunto "..."` e usar **exactamente** o devolvido |
| Ao escrever no canal | `post` (caixa) ou `note` (`.md` partilhado). Nunca reescrever o ficheiro inteiro |
| Ao terminar um turno | passagem de turno no formato de `ROTINA_E_PASSAGEM.md` |
| Ao medir um facto | numero + hora + fonte, no `QUADRO_ESTADO.md` |
| Ao corrigir um defeito | defeito -> causa raiz -> correcao -> **medicao antes e depois** |
| Ao discordar | escreve na caixa do outro com a **linha** que contradiz, nao no chat |

---

## 4. Poder de veto do DONO

O dono pode, a qualquer momento e sem justificacao: parar o EA num grafico, desligar auto-trading, congelar o canal, mandar reverter um commit, ou proibir um simbolo. Nenhum agente pode reverter uma decisao do dono sem a linha dele.

O dono **nao** pode pedir: esconder atividade, mascarar perdas, falsificar historico, remover Stop Loss obrigatorio, ou enviar ordem sem as portas G1..G5. Nesses casos o agente recusa e explica.
