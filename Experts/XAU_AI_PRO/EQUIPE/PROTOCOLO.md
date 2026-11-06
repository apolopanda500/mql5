# PROTOCOLO DO CANAL - equipe de 3 agentes / XAU_AI_PRO

Canal oficial de coordenacao entre **ALFA** (Agente 1), **DELTA** (Agente 2) e
**CMD** (Agente 3). Codenames definidos pelo dono em 05/11 21:46:

| Codename | Agente | Papel |
|---|---|---|
| **ALFA** | Agente 1 | `AI/**`, `Core/SymbolManager.mqh`, `Core/Config.mqh`, `Indicators/**`; mede e corrige |
| **DELTA** | Agente 2 | assistente MetaTrader 5 / MetaEditor; `Monitoring/**`, notificacoes, relogios, build/deploy/diagnostico |
| **CMD** | Agente 3 | terminal/PowerShell, app `MQL5/Files/XAU_AI_PRO/**`, `backend/**`, espelho, testes |

Nas linhas de inbox/diario use **ALFA / DELTA / CMD**. "A1/A2/A3" so em texto
antigo ja escrito - nao corrigir para tras, so nao usar daqui para frente.
Criado em 05/11/2026. Dono do projeto: o operador da conta demo 113568614.

Agentes nao conversam em tempo real. O unico canal confiavel e **arquivo no
repositorio**. Tudo o que for decisao, pedido, medida ou handoff passa por
aqui; nada de "eu avisei no chat".

Pasta unica do canal: **`MQL5/Experts/XAU_AI_PRO/EQUIPE/`** (pasta do projeto
do EA). Decisao do dono em 05/11 21:44: os tres agentes reunidos num lugar so.

---

## 1. Mapa do canal - TUDO numa pasta so

| Arquivo | Papel | Quem escreve |
|---|---|---|
| `EQUIPE/PROTOCOLO.md` | este documento: regras do canal | ninguem edita sem acordo dos 3 |
| `EQUIPE/QUADRO_ESTADO.md` | estado medido unico (versao, build, graficos, fila) | qualquer agente, **com a medida e a hora** |
| `EQUIPE/DECISOES.md` | registro de decisoes com ID (`D-001`, `D-002`, ...) | quem propoe escreve a linha; o dono fecha |
| `EQUIPE/INBOX_AGENTE_1.md` | caixa de entrada do **ALFA** | DELTA e CMD escrevem; ALFA responde na mesma linha |
| `EQUIPE/INBOX_AGENTE_2.md` | caixa de entrada do **DELTA** | ALFA e CMD escrevem; DELTA responde |
| `EQUIPE/INBOX_AGENTE_3.md` | caixa de entrada do **CMD** | ALFA e DELTA escrevem; CMD responde |
| `EQUIPE/AGENTE_1.md` | identidade, escopo e diario do **ALFA** | ALFA (o CMD tambem ja escreveu ali) |
| `EQUIPE/AGENTE_2.md` | identidade, escopo e diario do **DELTA** | so o DELTA |
| `EQUIPE/AGENTE_3.md` | identidade, escopo e diario do **CMD** | so o CMD |

**Caminhos antigos - so atalho, nao escrever la:**

| Caminho antigo | Estado |
|---|---|
| `Experts/XAU_AI_PRO/AGENTE_1.md` | stub de 1 443 B a apontar para `EQUIPE/AGENTE_1.md` |
| `MQL5/AGENTE_3.md` | stub de 1 527 B a apontar para `EQUIPE/AGENTE_3.md` |
| conteudo integral dos dois | copiado **verbatim** para `EQUIPE/` a 05/11 21:42:05 (14 055 B e 8 536 B); depois disso ALFA e CMD reescreveram os seus diarios (o arquivo atual ja nao e a copia) |

Precedencia quando dois arquivos discordam: **`QUADRO_ESTADO.md` manda**, porque
e o unico que exige medida com hora. Diario de agente e opiniao datada.

---

## 2. Ciclo de mensagem (obrigatorio)

1. **Antes de tocar em qualquer arquivo de codigo**: leia
   `QUADRO_ESTADO.md` (§3 posse) e a sua `INBOX_AGENTE_n.md`.
2. Escreva no seu diario o que vai fazer, com hora.
3. Faca a alteracao minima.
4. Compile (quem tem MetaEditor) ou peca compilacao na inbox.
5. Atualize `QUADRO_ESTADO.md` **com o numero medido** e a hora.
6. Se precisar de outro agente, abra linha na inbox dele no formato da §3.
7. Se a decisao e do dono, abra linha em `DECISOES.md` com estado `ABERTA`.

Nenhuma pendencia e marcada como resolvida sem numero medido. "Nao medido" e
resposta aceitavel; numero inventado nao e.

---

## 3. Formato de linha (inbox e diario)

```
DE -> PARA | <assunto> | arquivo:linha | precisa: <acao concreta> | estado: ABERTO/RESPONDIDO/FECHADO | <hora>
RESPOSTA (Agente n) | <o que mediu/fez> | evidencia: <linha de journal/contagem> | estado: FECHADO | <hora>
```

Exemplo real:
```
DE -> A2 | confirmar P1.130 duplicado | EQUIPE/DECISOES.md D-002 | precisa: decidir quem fica com o ID | estado: ABERTO | 05/11 21:52
```

---

## 4. Posse por arquivo (regra dura)

Dois agentes **nunca** editam o mesmo arquivo na mesma janela.

| Zona | Dono | Observacao |
|---|---|---|
| `AI/**`, `Core/SymbolManager.mqh`, `Core/Config.mqh`, `Indicators/**` | **Agente 1** | P1.110, P1.113, P1.119, P1.130-universo |
| `Monitoring/**`, `Enterprise/NotificationCenter.mqh`, `Monitoring/AccountLogGate.mqh`, build/deploy/diagnostico de terminal | **Agente 2** | P1.128-P1.131, notificacoes, relogios, `[RESUMO]` |
| `MQL5/Files/XAU_AI_PRO/**` (app), `backend/**`, `Docs/**`, espelho | **Agente 3** | gateway Python, dataset, testes, sync |
| `XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh` | **compartilhado, 1 por vez** | so no fecho de ciclo; anunciar na inbox antes |
| `PENDENCIAS.md`, `PROGRESS.md`, `Tools/HANDOFF.md` | **append-only** | cada agente anexa o proprio bloco; nunca reescrever bloco alheio |

Conflito de posse nao se resolve editando: resolve-se com linha na inbox e, se
durar, com `DECISOES.md`.

---

## 5. Regras da casa (valem para os 3)

1. **Nunca `push`.** `origin` (Forge MQL5) esta com credencial expirada;
   `github` = `apolopanda500/mql5`. Commit e local, com caminhos explicitos, e
   **so com pedido explicito do dono**.
2. **Nunca tocar parametros de risco**: `RiskPercent`, `RiskPerTradeUsd`,
   `MaxDailyLossPercent`, `MaxDailyLossUsd`, `MaxDrawdownPercent`,
   `StopLossPoints`, `TakeProfitPoints`, `RewardRatio`, `MinRewardRatio`,
   `MaxSpreadPct`, `MaxTradesPerDay`, `MaxOpenPositions`, `MinAIConfidence`,
   `AllowTradeWithoutAI`, regras de entrada/saida.
3. **Nunca conta real.** Conta atual: demo 113568614 (MetaQuotes-Demo).
4. **Nunca remover guarda de risco**, ocultar atividade, falsificar historico,
   nem enviar ordem real.
5. **Recarregar o EA nos graficos** (`chart_add_expert`, `profile_apply`) e ato
   de **producao**: so com autorizacao explicita na hora. Quem recarrega
   anuncia na inbox dos outros dois **antes** e mede o `[START]` **depois**.
   Um unico agente por vez reanexa - dois reanexando ao mesmo tempo geram
   tempestade de `EA finalizado` e confundem a medicao.
6. **Compilar e livre, mas nao concorrente**: se outro agente acabou de
   compilar, espere o `.ex5` parar de mudar de hora antes de recompilar. O
   `.ex5` gerado carrega o estado de **todos** os fontes no disco, nao apenas o
   seu - compilar por cima do trabalho meio-feito de outro leva o bug do outro
   para dentro do binario.
7. **Um ID de pendencia, um dono.** ID novo so depois de conferir
   `QUADRO_ESTADO.md` (§5) - ja houve colisao (ver `D-002`).
8. **Codificacao**: os `.mqh` do EA **nao tem BOM** e alguns tem UTF-8 quebrado
   (`AI/AIConnector.mqh` linha ~1309). Ao reescrever arquivo, preserve o BOM
   original ou a aritmetica de `#include`/diff muda.
9. **Ferramenta que mente**: `search_text`/`search_regex` do MCP devolvem 0
   para termos existentes. Use `findstr` ou `Select-String` dentro de `.ps1`.
10. **Documentar no mesmo ciclo**: `PENDENCIAS.md`, `PROGRESS.md` e
    `Tools/HANDOFF.md`, em bloco append-only, com a evidencia.

---

## 6. Definicoes do dono (preencher)

- [ ] Quem reanexa o EA nos graficos: ( ) Agente 1 ( ) Agente 2 ( ) so o dono
- [ ] Quem commita: ( ) Agente 1 ( ) Agente 2 ( ) so o dono
- [ ] Gate de IA: ( ) provisionar token ( ) `EnableAutonomousMode=true`
- [ ] Apagar orfaos `Management/PartialClose.mqh` e `Management/TrailingStop.mqh`?
- [ ] Commit de `Profiles/Tester/XAU_AI_PRO.set`?

Ate o dono responder, os agentes tratam cada item como **PROIBIDO**.

---

## 7. Reuniao em pasta unica (05/11 21:44)

Ordem do dono: "reunir os 3 agentes em unico lugar e pasta do projeto".

- tudo o que e canal vive agora em `Experts/XAU_AI_PRO/EQUIPE/`;
- `Experts/XAU_AI_PRO/AGENTE_1.md` e `MQL5/AGENTE_3.md` passaram a **stub**
  de redirecionamento (nao apagar, nao escrever la);
- nenhum conteudo foi perdido: copia verbatim as 21:42:05.

Regra nova: **ficheiro de canal novo so nasce em `EQUIPE/`**. Ficheiro de
coordenacao fora de `EQUIPE/` e erro de processo.

---

---

## 8. Sincronizacao e o 4o participante: o DONO (D-015, 05/11 22:23)

Ordem do dono: "crie e autorize scripts ou modulos de sincronizacao entre 3
agentes e o quarto eu o DONO". Autorizado, executado e registado em `D-015`.
Este bloco e **acrescentado**: nada do que estava escrito acima foi alterado.

### 8.1 O DONO no canal

| Elemento | Regra |
|---|---|
| `EQUIPE/INBOX_DONO.md` | fila do dono, IDs `Q-0NN`. So o dono fecha; os agentes anexam. |
| Quem escreve | qualquer agente, no formato da §3, com `-> DONO` |
| Como o dono responde | no chat basta: o agente que recebeu a resposta escreve `RESPOSTA (DONO) ... estado: FECHADO` |
| Precedencia | decisao do dono > `QUADRO_ESTADO.md` > diario de agente |

Ler a fila do dono inteira num comando:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 dono
```

### 8.2 `EQUIPE/tools/equipe-sync.ps1` - o que faz

| Comando | Para que serve |
|---|---|
| `status` | tabela medida: bytes, linhas, CR, ABERTO/RESP/FECHADO, UTF-8, hora |
| `check` | integridade: LF puro, UTF-8 valido, IDs `D-`/`P-`/`Q-` duplicados, ficheiros obrigatorios |
| `dono` | imprime so os blocos ABERTOS da fila do dono |
| `quem` | conta itens ABERTOS por destino (ALFA/DELTA/CMD/DONO) |
| `snapshot` | escreve `_SYNC/SYNC_STATUS.md` + `_SYNC/status.json` (retrato unico) |
| `append` | anexa texto, com backup previo em `_SYNC/backup/` |
| `substituir` | substitui **uma** ancora; recusa o ficheiro inteiro se o count != 1 |
| `aviso` | cria bloco `## <data> - X -> Y: assunto` na inbox do destino |
| `lock` / `unlock` / `lockstatus` | serializa escritas: um agente de cada vez |

Regras que a ferramenta aplica:

1. **Escrita byte-a-byte** com ISO-8859-1 (28591): preserva BOM e bytes UTF-8
   quebrados. Nunca reescreve o ficheiro inteiro.
2. **Backup antes de escrever**: `_SYNC/backup/<nome>.<AAAAMMDD_HHMMSS>.bak`.
3. **Lock**: quem vai escrever cria `_SYNC/LOCK` com `-De ALFA|DELTA|CMD|DONO`;
   se ja existir, a ferramenta **recusa** e diz de quem e. Substitui o "a
   ultima escrita ganha", que ja custou dois rodapes e um cabecalho.
4. **Ancora unica**: `substituir` so grava se a ancora aparecer
   **exactamente uma vez**; caso contrario nao grava e imprime `count=N`.
5. **Texto com acento nunca por linha de comando.** O `cmd` converte-o para 1
   byte e estraga o UTF-8 do canal (aconteceu as 22:25 com `§`, corrigido as
   22:27). Corpo com acento vai num ficheiro UTF-8, passado com
   `-CorpoArquivo <caminho>`; a ferramenta **recusa** corpo nao-ASCII inline.

### 8.3 O que a ferramenta NUNCA faz

Compilar, reanexar, commitar, fazer push, mexer em parametro de risco, apagar
ficheiro de outro agente. Nao escreve fora de `EQUIPE/*.md` e `EQUIPE/_SYNC/`.

### 8.4 Ciclo recomendado

1. `equipe-sync.ps1 status` - ver o canal antes de tocar em nada.
2. `equipe-sync.ps1 lock -De <EU> -Motivo "..."` antes de editar.
3. Editar com `append` ou `substituir` (backup automatico).
4. `equipe-sync.ps1 unlock -De <EU>`.
5. `equipe-sync.ps1 check` - 0 problemas = canal integro.
6. No fecho de ciclo: `equipe-sync.ps1 snapshot` - o dono le **um** ficheiro.

---

Ultima alteracao: 05/11/2026 22:25 - DELTA (`§8`: sincronizacao + DONO como 4o participante; `D-015`).

---

## 8.5 Consolidacao (D-017, 05/11 22:36) - um lock, um caminho de escrita

As 22:29 existiam **dois** modulos e **dois** locks. Nenhum agente via o lock do outro. Fica assim:

| Camada | Ferramenta |
|---|---|
| escrever no canal | `tools\sync-agent.ps1` (Mutex + escrita atomica + ledger `IDS.md`) |
| ler / verificar / reparar | `tools\equipe-sync.ps1` (`status`, `check`, `dono`, `snapshot`, `eol`) |
| lock | **`LOCK.md`** - unico; os dois modulos leem e escrevem o mesmo ficheiro |

Regras que passam a valer para os quatro (ALFA, DELTA, CMD, DONO):

1. Antes de escrever: `tools\equipe-sync.ps1 lock -De <AGENTE> -Motivo "<o que vais fazer>"`. Se recusar, o canal e de outro.
2. Depois de escrever: `unlock -De <AGENTE>`.
3. O EOL do canal e **LF puro**. Depois de qualquer escrita: `tools\equipe-sync.ps1 check`. Se acusar `CR=n`, correr `eol` (faz backup antes).
4. Um ID novo so se reserva com `tools\sync-agent.ps1 id -Tipo D|P -From <AGENTE>`. Nunca "o proximo numero" a mao - foi isso que criou tres `D-012` e dois `D-013`.
5. Texto com acento nunca por linha de comando (o cmd converte-o em 1 byte e estraga o UTF-8 do canal): escreve-se num ficheiro UTF-8 e passa-se por `-CorpoArquivo`.
6. O DONO fecha so as suas: `tools\sync-agent.ps1 answer -From DONO -Q Q-nnn -Resposta "..."`. Nenhum agente fecha uma pergunta do dono.

Ultima alteracao: 05/11/2026 22:36 - DELTA (`8.5`: consolidacao de locks; `D-017`).


---

## 9. Equipe de 4 em regime de producao (D-018, 05/11 22:55)

Autorizacao do DONO (22:43): ferramentas novas, pesquisa, git, limpeza de
lixo regeneravel, trabalho sem interrupcao - para concluir o projeto
**10/10 em uso real**. Este bloco e **acrescentado**; nada acima foi alterado.

### 9.1 Documentos de comando

| Ficheiro | Para que serve | Quem mantem |
|---|---|---|
| `PLANO_10_10.md` | fases `F0`..`F9`, portoes numericos, definicao de 10/10 | CMD |
| `BACKLOG.md` | `B-001`..`B-034` com dono, criterio e estado | todos |
| `FERRAMENTAS.md` | runtimes, MCP, scripts, contrato de limpeza | CMD |
| `QUADRO_ESTADO.md` | ecra unico do estado medido | CMD antes de cada commit |

**Precedencia:** decisao do DONO > `DECISOES.md` > `PLANO_10_10.md` >
`QUADRO_ESTADO.md` > `BACKLOG.md` > diario de agente.

### 9.2 Continuidade (pode haver dias com so 2 agentes)

1. Quem para escreve `## HANDOFF` no seu diario:
   `feito | em curso | proximo passo | bloqueio | evidencia`.
2. Quem assume le **dois** ficheiros: `QUADRO_ESTADO.md` e o HANDOFF mais
   recente. Se discordarem, ganha o medido mais recente.
3. Nenhum agente espera por outro para **medir**; so para **decidir** o que
   nao e seu.

### 9.3 Regra de evidencia

- Todo item do `BACKLOG.md` fecha com **numero + comando + hora**.
- "Funciona" nao e evidencia. "13/13 `[START] v1.2.167` as 22:11" e.
- Quem nao mediu nao assina.

### 9.4 Conta real - portoes intransponiveis

`F2` (seguranca de capital) e `F6` (30 dias demo, PF >= 1.2, DD <= 8%)
fechados **antes** de qualquer ordem em conta real. O DONO aprova por escrito.
Parametros de risco continuam exclusivos do DONO, mesmo com autorizacao total
de execucao.

### 9.5 Limpeza (lixo regeneravel)

- `-DryRun` por omissao; lista antes de apagar; relatorio em `_SYNC/`.
- Permitido: `%TEMP%\opencode`, `__pycache__`, `.pytest_cache`,
  `_SYNC/backup` > 14 dias, logs > 30 dias, `dist/`, `build/`, `.mypy_cache`.
- Proibido: `Data/*.csv`, `.ex5` em uso, `Profiles/` do terminal, `.git`,
  `.env`, `.venv`, `node_modules` da app, e fora da arvore `MQL5\` sem lista
  aprovada pelo DONO.

### 9.6 Pesquisa e melhoria

Web, GitHub e documentacao autorizados. Toda ideia entra no `BACKLOG.md` com
**fonte, custo e risco** antes de virar codigo. Revisao de backlog a cada dia
de trabalho.


## 10. Medicao de backtest - regras que vieram dos incidentes (D-051, 06/11 01:26)

Estas tres regras nasceram de erros reais de medicao. Aplicam-se aos tres
agentes e sao obrigatorias antes de qualquer conclusao apoiada em contagens de
log do Strategy Tester.

### 10.1 Contagem por OFFSET, nunca por ficheiro inteiro

O tester escreve num unico ficheiro por dia:
`<terminal>\Tester\logs\AAAAMMDD.log`. Dois jobs no mesmo dia partilham o
ficheiro e as contagens somam-se. Um grep ao ficheiro inteiro mede a soma de
todos os jobs do dia, nao o job que se quer medir ("mentira aritmetica").

Procedimento obrigatorio, por esta ordem:

1. **Antes** de lancar o job, fixar a linha de base:
   `b032_offset.ps1` -> grava `offset=<Length>|mtime=<...>|agora=<...>` em
   `MQL5\Files\Temp\<job>_offset.txt`.
2. Lancar o job.
3. **Depois** de fechar, contar so o segmento novo:
   `contadores_atr_v3.ps1 -Log <log> -Offset <offset fixado>`.
4. Registar no `DECISOES.md` o offset usado e a hora, para que o numero seja
   reproduzivel por outra pessoa.

Se o offset foi fixado depois do arranque do job, a medicao e invalida e o
teste tem de ser repetido.

### 10.2 Um job de cada vez

Enquanto um job de tester estiver a correr, nenhum agente lanca um segundo
job, mesmo noutro simbolo ou com outro `.set`: ver 10.1. Quem precisa do
recurso pede no canal EQUIPE e espera. O `LOCK.md` marca quem esta a usar.

Guarda de exclusividade antes de qualquer `tester_run_backtest`: contar
`metatester64`, mas **provar** que o job anterior terminou pela cauda do log
(`Test passed in ...` / `connection closed` + `mtime` parado), porque processos
`metatester64` inactivos continuam a existir depois do fim do teste.

### 10.3 Medicao e rotina usam `.set` diferentes - e diz-se qual foi

- Backtest de **medicao** (contagens, A/B de um caminho de codigo): correr com
  o `.set` original do job de referencia e declarar as diferencas que
  restarem. Comparar antes/depois so e legitimo para o caminho de codigo
  medido, nao como reprodutibilidade exacta de inputs.
- Backtest de **rotina**: `xai_lownoise.set`.
- Todo registo de resultado indica: ficheiro `.ini`, ficheiro `.set`, janela
  `FromDate`/`ToDate`, modelo, tamanho e hash do `.ex5` usado.

### 10.4 Backup do `.ex5` antes de compilar (D-040)

Antes de qualquer compilacao que escreva
`Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`, copiar o binario em uso para
`MQL5\Files\Backup\ex5\XAU_AI_PRO_<versao_do_binario>_<AAAAMMDD_HHMMSS>.ex5`
e registar tamanho e hash. O `<versao_do_binario>` e a versao que o binario
imprime em `[VERSION]` (ou a que o log do tester mostra), **nao** a versao nova
do fonte - foi exactamente esse engano que se corrigiu no D-051.

### 10.5 Identidade de versao tem de ser provada, nao presumida

`#property version` aceita apenas `xxx.yyy` ("1.372"); a versao legivel
(`EA_VERSION_STRING`, hoje "1.2.172") vive em
`Enterprise/VersionManager.mqh`. Antes de atribuir um resultado a uma
alteracao de codigo, provar no log do job qual versao correu:
`[VERSION] vX.Y.ZZZ`. Um job que mostra uma versao anterior a alteracao nao
mede a alteracao - foi o achado central do D-051.
