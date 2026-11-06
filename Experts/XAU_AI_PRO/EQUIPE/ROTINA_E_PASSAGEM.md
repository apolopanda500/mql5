# ROTINA E PASSAGEM DE TURNO - equipa de 4

**Registo:** `DECISOES.md` `D-017`. Vale a partir de 05/11/2026 22:38.
Objetivo: **o projeto nao parar** quando um agente sai, e **nenhum agente depender da memoria do chat**.

---

## 1. Modelo de cobertura

| Situacao | Quem trabalha | Regra |
|---|---|---|
| 3 agentes activos | ALFA (codigo), DELTA (medicao), CMD (repo/build) | cada um na sua zona, tudo pelo canal |
| 2 agentes activos | **ALFA + CMD** (codigo + build). O DELTA entra depois para medir | se faltar o CMD, ALFA acumula build **com LOCK**; se faltar o ALFA, ninguem mexe em `Indicators/**` |
| 1 agente activo | **so medicao e documentacao** | sem compile e sem commit a solo, para nao criar estado que os outros nao conhecem |
| 0 agentes | — | ver §4 (vigia) |

**Trabalho nunca fica a meio de um compile:** quem compila tem LOCK e liberta ou expira. Um compile a meio e pior do que um compile adiado: o `.ex5` leva o estado de **todos** os fontes do disco.

---

## 2. Passagem de turno (obrigatoria, 6 linhas)

Quem termina escreve em `AGENTE_<n>.md` **e** na caixa de quem continua:

```
## <dd/mm hh:mm> - passagem de turno <DE> -> <PARA>
- Fiz: <o que mudou de facto>
- Medi: <numero + hora + fonte>
- Ficou aberto: <item, com ID se houver>
- Proximo passo concreto: <a primeira accao, nao o objectivo>
- Bloqueio: <do que espero, de quem>
- LOCK: <livre | tomado por mim ate hh:mm>
```

Sem estas 6 linhas o turno nao esta entregue. Um item sem "proximo passo" concreto nao conta.

---

## 2b. Ritual de arranque (30 segundos, todo o turno)

```
sync-agent.ps1 status            # versao, binario x fontes, git, [START], lock, fila do dono
sync-agent.ps1 check             # integridade: IDs, BOM, U+FFFD, caixas, lock vencido
sync-agent.ps1 log -Tail 15      # o que os outros fizeram desde o meu ultimo turno
sync-agent.ps1 lock -Acao ver    # alguem esta a compilar/reanexar?
```

Se `check` der problema: **o problema e a prioridade zero** do turno, antes de qualquer feature.

---

## 3. Checklist diario

- [ ] `status` + `check` + `log` (ritual de arranque)
- [ ] `QUADRO_ESTADO.md` ainda diz a verdade? (versao, `[START]`, posicoes, trades)
- [ ] Quantas perguntas do DONO em aberto? As 3 bloqueantes estao respondidas?
- [ ] O EA abriu/fechou posicao nas ultimas 24 h? Se 0, porque - com **uma** razao medida
- [ ] Algum simbolo sem `ATR`/`RSI`? (regressao de `Q-001`)
- [ ] Journal com erro critico (`4807`, `4756`, `10027`, `Invalid stops`)?
- [ ] `git status` do repo dentro de `MQL5`: ha ficheiro de estado a mais para commitar?
- [ ] Limpeza permitida: `MQL5/Files/Temp`, `MQL5/Files/Backup`, logs `MQL5/Logs` com mais de N dias (nunca `Data/*.csv`, `.ex5`, `.dll`, `.set`)

---

## 4. Vigia (quando ninguem escreve)

Se o canal ficar **> 12 h sem uma linha de ninguem**, o primeiro agente que entrar:

1. Corre o ritual de arranque e registra no `SYNC_LOG.md`.
2. Mede se o EA esta vivo: `[START]`/`[STOP]` no log e posicoes na conta.
3. Escreve uma **passagem de turno de retomada** no `AGENTE_<n>.md` dizendo o que encontrou.
4. Se o EA estiver parado ou a conta sem dados, abre `Q-nnn` para o DONO - nao decide sozinho.

**Um agente nunca "assume" o trabalho do outro sem escrever que o fez.**

---

## 5. Runbook de incidentes (sintoma -> primeira accao)

| Sintoma | Primeira accao | Nunca |
|---|---|---|
| 24 h sem trades com sinais a existir | ler o motivo do veto no journal (linha `[VALIDATION]`), classificar em ATR / IA / ADX / spread, e **so depois** tocar em algo | mexer em `MinAIConfidence` ou em risco para "ver se entra" |
| `[ATR] HANDLE MORTO` / `ATR%=sem leitura` | confirmar quantos simbolos; se >= 3, e `Q-001` a reabrir | reiniciar o EA a espera que sara - o auto-curativo ja falhou 3x |
| `[AI] PYTHON` com `0.00%` nos dois lados | verificar gateway (bytes, `disponivel`), depois parser | aumentar confianca para compensar |
| EA desapareceu do grafico | `list_open_charts`, ver `[STOP] ... motivo=` no journal | reanexar sem LOCK |
| `.ex5` mais velho que as fontes | e compile pendente: tomar LOCK, compilar, ver "0 errors", reanexar | commitar binario sem compilar |
| Drawdown a passar o limite | parar entradas (auto-trading off no grafico) e abrir `Q` para o DONO | "esperar que recupere" |
| Conta sem dados / sem ligacao | verificar terminal primeiro, nao o codigo | atribuir ao EA |

---

## 6. Documentacao (o que "salvar conversa" quer dizer)

| Onde | O que fica | Quem escreve |
|---|---|---|
| `DECISOES.md` | decisao + autor + hora. **Uma** decisao por bloco, ID do ledger | quem decide |
| `QUADRO_ESTADO.md` | estado medido, com numero e hora | quem mediu |
| `AGENTE_<n>.md` | diario do agente: o que fiz, o que falhou, o que aprendi | cada um |
| `INBOX_AGENTE_<n>.md` | pedidos entre agentes, com `estado:` | quem pede |
| `INBOX_DONO.md` | so o que o dono decide (`Q-nnn`) | qualquer agente |
| `SYNC_LOG.md` | rasto automatico de escrita/ID/lock | `sync-agent.ps1` |
| `PLANO_MESTRE.md` / `AUTORIZACOES.md` / `ROTINA_E_PASSAGEM.md` | plano, permissoes, rotina | ALFA mantem, dono aprova |

**Regra de ouro:** se um facto so existe no chat, ele **nao existe**. Chat perde-se; ficheiro fica.
