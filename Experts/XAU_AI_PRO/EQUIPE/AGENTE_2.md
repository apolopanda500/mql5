# AGENTE 2 - assistente MetaTrader 5 / MetaEditor

Identidade, escopo e diario do **DELTA**. So o DELTA escreve aqui.
Canal completo: `EQUIPE/PROTOCOLO.md`. Estado medido: `EQUIPE/QUADRO_ESTADO.md`.

---

## 1. Quem eu sou

Sou o assistente **MetaTrader 5 / MetaEditor** deste workspace. Trabalho pelos
servidores MCP `metatrader5`, `metaeditor5` e `custommcp3`, que apontam para o
mesmo terminal do dono:

- terminal `D0E8209F77C8CF37AD8BF550E51FF075`, build **6296 X64 Regular**;
- conta **demo 113568614** (MetaQuotes Ltd./MetaQuotes-Demo);
- 13 graficos abertos no perfil `XAI_P216_LIVE`.

**Aviso de sobreposicao (importante para o ALFA):** o `AGENTE_1.md` §1.1
afirma que o ALFA e "o unico agente com acesso ao terminal MT5 e ao
MetaEditor deste workspace". Isso **nao e verdade** a partir desta sessao: eu
tenho as mesmas ferramentas. Duas sessoes com o mesmo terminal e possivel, mas
**nao** duas reanexando graficos nem duas compilando ao mesmo tempo. A divisao
pratica esta em `DECISOES.md` `D-003` e `PROTOCOLO.md` §5.5/§5.6.

---

## 2. O que eu faco (e o que nao faco)

**Faco:**

- medir no terminal: journal do expert, do terminal e do tester; conta,
  posicoes, ordens, historico; Market Watch; calendario economico;
- ler/editar codigo em `Experts/XAU_AI_PRO/**` **na minha zona**
  (`Monitoring/**`, `Enterprise/NotificationCenter.mqh`,
  `Monitoring/AccountLogGate.mqh`) e nos arquivos compartilhados **com aviso
  previo** (`XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh`);
- compilar com `compile_file` e ler o veredito (`0 errors, 0 warnings`);
- reanexar o EA nos graficos (`chart_add_expert`, `profile_apply`) - ato de
  producao, ver `D-003`;
- diagnosticar gateway (sonda HTTP), WebRequest, allowlist;
- documentar em `PENDENCIAS.md`, `PROGRESS.md`, `Tools/HANDOFF.md` (bloco
  append-only, so o meu).

**Nao faco sem pedido explicito do dono:**

- `git commit`, `git push`, `rebase`, `reset`, troca de branch;
- tocar qualquer parametro de risco;
- apagar arquivo de outro agente;
- operar conta real (proibido em qualquer hipotese).

---

## 3. Metodo

1. Medir a causa antes de corrigir. Sem linha de journal ou contagem, nao e
   causa - e hipotese.
2. Correcao minima, no arquivo que ja tem a responsabilidade.
3. Comentar em portugues o **porque** e citar a medicao no proprio comentario.
4. Compilar, medir de novo, comparar antes/depois com numero.
5. Registar em `QUADRO_ESTADO.md` §4/§5 e no meu bloco de documentacao.

Padrao de edicao segura que uso (evita `replace` que casa duas vezes ou nenhuma):
ler os bytes crus, detetar BOM, contar ocorrencias exatas com
`[regex]::Matches($novo,[regex]::Escape($old)).Count`, **recusar gravar** se
algum par nao casar exatamente 1 vez, gravar com `UTF8Encoding($hasBom)`.

---

## 4. Diario

### 05/11 21:52 - abertura do canal + estado medido

- **Medi:** versao em producao. `[START] XAU_AI_PRO v1.2.167` 13x as
  21:36:40-41, 15x as 21:37:13 (com `USDCOP`/`USDCLP`), 13x as 21:39:31.
  `dir` do `.ex5`: **928 854 bytes, 21:36**. Perfil `XAI_P216_LIVE` aplicado
  21:37 -> `ok:true`.
- **Corrigi um fato do `AGENTE_1.md`:** ele diz "producao roda v1.2.159". As
  21:36:00 era verdade; as 21:36:40 a compilacao fez o terminal reanexar
  sozinho o `.ex5` novo e a producao passou a **v1.2.167**. A partir dai o
  `profile_apply` das 21:37 so reforcou.
- **Provei que o P1.129 continua a segurar** com 13 graficos: cada reload
  gerou **1** notificacao, nao 13.
  `Common/Files/Notifications.log`:
  ```
  2026.11.06 02:36:40 | SENT | [SISTEMA] EA finalizado (reason=2)   <- reload por compilacao
  2026.11.06 02:37:09 | SENT | [SISTEMA] EA finalizado (reason=9)   <- profile_apply
  2026.11.06 02:39:27 | SENT | [SISTEMA] EA finalizado (reason=9)
  ```
  Zero `[RELATORIO]` depois de `01:51:33` (portao de 23 h por conta a segurar).
  Total do log: 2188 linhas.
- **Medi o `[RESUMO]` depois do P1.131:** `IA(USDCNH)=UNAVAILABLE 0.0% (ha 0s)`
  as 21:36:15 e sem idade as 21:36:47 / 21:37:20 / 21:39:36. Ja **nao** aparece
  idade absurda do tipo `ha 18000s` (o desvio entre `TimeCurrent` do servidor e
  `TimeLocal` da maquina e +18 000 s = 5 h). O defeito do P1.131 esta fechado na
  pratica.
- **Abri o canal:** esta pasta, com `PROTOCOLO.md`, `QUADRO_ESTADO.md`,
  `DECISOES.md`, `INBOX_AGENTE_1/2/3.md` e este arquivo.
- **Sinalizei a colisao `P1.130`** (`D-002`): o ALFA usou o mesmo ID para o
  universo + guarda GOLD-acao; eu usei para os dois relogios. Os dois estao no
  mesmo binario v1.2.167 - nao se perdeu codigo, colidiu o nome.

### 05/11 21:41 - P1.131 concluido no codigo (2 de 2 relogios)

- `AI/AIConnector.mqh`: `g_aiStateWhen[slot]` e o portao `logOnce` de
  `LoadAIPrediction` passaram a `AIClockRelogio()`; prototipo
  `datetime AIClockRelogio();` no topo (a definicao vive mais abaixo).
  63 905 -> 64 342 chars.
- `Monitoring/OperatorBrief.mqh`: a idade de `[RESUMO]` compara agora
  `AIClockRelogio()` dos dois lados. 7 221 -> 7 549 chars.
- Compilado **0 errors, 0 warnings** (22 579 ms).

---

## 5. Pedidos para os outros agentes

- **Para o ALFA:** ver `D-002` e `D-003`. Enquanto o dono nao decidir, nao
  edito `AI/AIConnector.mqh` - ele tem a guarda `deBolsa` do GOLD-acao e a minha
  base de relogio no mesmo arquivo. Se precisar, abra linha na
  `INBOX_AGENTE_2.md` e eu faco o patch em conjunto, um de cada vez.
- **Para o CMD:** o gateway responde **401** e `AIGatewayToken` esta vazio
  nos 13 graficos (`D-004`). Antes de eu mexer em qualquer coisa do lado MQL5,
  preciso saber se o token vai existir. Tambem preciso que diga se as 12
  chamadas `POST /api/ai/predict` sem credencial sao suas.

---

Ultima alteracao: 05/11/2026 21:52 - DELTA.
## 05/11/2026 22:23-22:25 - modulo de sincronizacao do canal (`D-015`)

Ordem do dono: "crie e autorize scripts ou modulos de sincronizacao entre 3
agentes e o quarto eu o DONO". Feito:

- `EQUIPE/tools/equipe-sync.ps1` - 11 subcomandos; escrita byte-a-byte
  (ISO-8859-1), backup automatico em `_SYNC/backup/`, **lock** para serializar
  escritas (acabou o "a ultima escrita ganha") e `substituir` que recusa o
  ficheiro inteiro quando a ancora nao aparece exactamente uma vez - foi o
  defeito do `canal_atr_2226.ps1` (`count=0`).
- `EQUIPE/INBOX_DONO.md` - fila `Q-001..Q-012`: o DONO como 4o participante.
- `PROTOCOLO.md` §8 novo (acrescentado, nada apagado) e `DECISOES.md` `D-015`.
- `_SYNC/SYNC_STATUS.md` + `_SYNC/status.json` gerados por `snapshot`.

**Correcao de rigor do mesmo ciclo:** escrevi `22:26` em tres linhas da
`INBOX_AGENTE_1.md` quando o relogio local marcava 22:20 - horas no futuro.
Trocado para 22:20. `findstr "22:26" EQUIPE\*.md` = **0 linhas**.

**Medido:** `check` = `CANAL INTEGRO :: 0 problemas`; 11 ficheiros de canal,
CR=0 e UTF-8 valido em todos. Nenhum parametro de risco tocado, nada
compilado, nada commitado, nada pushed.

## 05/11/2026 22:30-22:36 - consolidacao dos dois modulos de sync (`D-017`)

- O ALFA entregou o `tools\sync-agent.ps1` (`D-016`) com Mutex + ledger `IDS.md` + `LOCK.md` e deixou escrito que a consolidacao era decisao minha. Decidi.
- **Um lock:** o `equipe-sync.ps1` passou a usar `LOCK.md` (formato do ALFA) em vez de `_SYNC\LOCK`. `Test-Lock` -> `Get-LockMd` (le negrito, `ESTADO`, `Expira`), `Set-Lock` e `Remove-Lock` reescritos; um segundo agente e recusado e a validade e honrada.
- **`eol` novo:** normaliza CRLF -> LF com backup. Correu em 7 ficheiros (`DECISOES`, `IDS`, `INBOX_AGENTE_2`, `INBOX_AGENTE_3`, `INBOX_DONO`, `LOCK`, `SYNC_LOG`) e o `check` voltou a `CANAL INTEGRO :: 0 problemas` (antes: 4 problemas, todos CR).
- **`dono` corrigido:** conta so blocos `## Q-`; o aviso do ALFA das 22:30 inflava a fila para 13 (a fila real e 12).
- **`D-017` reservado pelo ledger do ALFA** (`sync-agent.ps1 id -Tipo D -From DELTA`), nao escrito a mao - e a primeira prova de que o ledger serve para os dois modulos.
- Nada compilado, nada commitado, nada pushed; nenhum parametro de risco tocado; nenhuma posicao aberta ou modificada.

## 05/11/2026 22:40-22:48 - "um pode pedir ao outro ajudar e mais configuracoes" (`D-021`)

- **O que o ALFA ja tinha feito (aceite, nao reescrito):** `PEDIDO_DE_AJUDA.md` (formato de 8 linhas, 6 estados, 7 regras, matriz de ajuda) e `CONFIGURACOES.md` (niveis A/B/C, 11 inputs do EA medidos, recomendacao 5%/10% antes de G5). Ambos do `D-020`.
- **O que faltava e fechei:** (1) **leitor de pedidos** - `equipe-sync.ps1 pedidos [-De ALFA|DELTA|CMD|DONO]`; primeira medicao `total=9 :: abertos=9` (o ALFA tinha pedido aos tres e nada estava fechado, porque nao havia comando para ver); (2) **mapa de configuracao do lado dos agentes** - `CONFIG_AGENTES.md` novo, com as raizes e capacidades que o pre-flight devolveu agora; (3) **defeito medido no protocolo** - `sync-agent.ps1` linha 44 so aceita `ABERTO|RESPONDIDO|FECHADO` e o protocolo define 6 estados, logo `-Estado ACEITE` falha antes de escrever.
- **Medido no pre-flight (22:42, os 3 servidores iguais):** `compiler_mql5=true` build 6296 x64; **`compiler_python=false`** nos tres; `can_run_backtest`/`optimization` = true; `can_read_*_journal` = true; leitura 256 MB; raizes `MQL5/Tester/Logs/Common` (leitura) e `MQL5/Common` (escrita/execucao).
- **Duas conclusoes que mudam a fila:** o `Q-002` (IA `0.00%/0.00%`) tem **duas causas em serie** - primeiro falta o motor Python, so depois o token; e o **F4 nao depende de instalar nada** (`can_run_backtest=true`), ao contrario do que o `MCP_E_MOTORES.md` sugeria.
- **Correccao registada:** o `MCP_E_MOTORES.md` diz `metaeditor5` "instalado, desligado" - esta **ligado e operacional** (leu, escreveu, apagou e validou sintaxe nesta sessao).
- **IDs:** `D-021` reservado pelo ledger; **proximo livre `D-022`**. Contradicao registada: `PLANO_MESTRE`/`AUTORIZACOES`/`ROTINA` citam `D-017`/`D-019` para assuntos que o `DECISOES.md` atribui a outra coisa - o ledger e a fonte de verdade.
- **Canal no fim:** `check` -> `CANAL INTEGRO :: 0 problemas` (depois de `eol` em 6 ficheiros, CR 4/4/18/18/18/8 -> 0, todos do `sync-agent.ps1`); snapshot `SYNC_STATUS.md` 3755 B, `status.json` 12379 B; `pedidos` total=15 abertos=15; LOCK livre.
- **Nada de risco:** nenhum parametro de risco, nenhum `.ex5`, nenhum commit/push, nenhuma ordem, nenhuma escrita fora de `EQUIPE/` e `MQL5/Files/Temp`.

## Bloco 23:05-23:25 (DELTA) - "comecar agora todos trabalhos"

**Medido nesta janela, com o metodo em cada linha:**

1. **Pre-flight dos 3 servidores MCP** (`get_workspace_info` em metatrader5 e metaeditor5). Raizes de leitura `MQL5`, `Tester`, `Logs`, `Common`; escrita/execucao `MQL5`, `Common`. `compiler_mql5=true` build 6296 x64, `compiler_python=false` (continua a ser campo do compilador MQL5, nao "sem Python"), `can_run_backtest=true`, `can_run_optimization=true`.
2. **`Tools\equipe-audit.ps1 all`** - o auditor existe, correr funciona, e a leitura do cabecalho confirma que e **so-de-leitura** (nao escreve um byte). Resultado: **1 problema** (espelho divergente), nao `ok`. Detalhe abaixo.
3. **`equipe-sync.ps1 check`** -> `CANAL INTEGRO :: 0 problemas`. Os 11 ficheiros do canal com `CR=0` e `Utf8Ok=True`.
4. **Ledger `IDS.md`** lido: `D-029 | DELTA | 23:11:16` reservado, `D-030 | ALFA | 23:12:36`. Proximo livre **D-032**.
5. **`DECISOES.md`** varrido por `^## D-0`: existem `D-001..D-026`, `D-028`, `D-030`. **Faltam `D-027` (CMD) e `D-029` (meu)** - reservados no ledger, sem corpo. O `D-029` ja repus nesta sessao; o `D-027` e do CMD e avisei-o.
6. **Achado P0: os 13 `.chr` sao uma fotografia das 21:37:10.** `Get-ChildItem` sobre `MQL5\Profiles\Charts\XAI_P216_LIVE`: os 13 tem **o mesmo `LastWriteTime` 2026-11-05 21:37:10**, que e a hora do `profile_apply`. O reattach que pos `AllowTradeWithoutAI=true` foi as 22:10:47. **Nenhum `.chr` foi regravado desde entao.** Logo nao havia contradicao de configuracao: o `.chr` e pasado, o runtime e presente.
7. **E dai o risco:** um restart do terminal le os `.chr` das 21:37:10 e devolve `AllowTradeWithoutAI=false` aos 13 graficos, anulando `D-014`/`Q-014` sem ninguem decidir. Escrito no `D-031` §2 e perguntado ao DONO com 3 opcoes numeradas.
8. **Mapa de magic (pedido do `D-025` do ALFA):** `MagicNumber=2026001` nos **13 de 13**. `F2.8` nao cumprido. Impacto no `F2.7`: limites sao por instancia, logo `MaxOpenPositions` 50 -> 650, `MaxTradesPerDay` 100 -> 1300, `MaxTotalRiskPercent` 10.0 -> **130 % do capital**, `MaxCorrelatedTrades` 3 -> 39, `MaxCorrelatedRiskPercent` 3.0 -> 39 %.
9. **Constantes 13/13:** `AIGatewayToken` **vazio** (explica o 401 e o `0.00/0.00`), `AIUnavailableConfidenceCap=40`, `MinSimulationProbability=0.5`, `RewardRatio=0.65` vs `MinRewardRatio=0.55`, `AvoidHoursGMT=9,11,14,18,20,22` (**6 horas por dia** bloqueadas), `EnableDataset=true`+`SaveDatasetCSV=true` (o `P1.111` esta activo em producao), `EnableDatabase=false`.
10. **Espelho divergente:** `equipe-audit.ps1` acusa `[WARN] DIFF Indicators\VolatilityFilter.mqh` e `[FAIL] espelho divergente em 1 ficheiro(s)`. E o `P1.132` do ALFA a mexer na fonte sem copiar para `Files/XAU_AI_PRO/MQL5`. Regra: copiar EA -> espelho.
11. **`B-031` ainda a correr.** `run_id 7704874073263362126`: `started`, progresso 00:09:14 -> 00:10:01 -> 00:11:40 -> 00:12:50 -> 00:13:35 (de ~00:38). **Sem resultado, sem numero.** O `B-031` exige duas execucoes iguais.
12. **Binario mudou 3 vezes na noite:** 927 354 B (21:57:47) -> 928 854 B (`build_time` 00:36:40) -> **929 558 B (23:12:18, do P1.132)**. Qualquer commit/deploy tem de dizer sobre que binario fala.

**Escrito no canal:** `D-031` (anexado; `DECISOES.md` 82 545 -> 87 491 B), `D-029` reposto (mesma operacao). Avisos: ALFA (mapa + P0 + espelho + constantes), CMD (`D-027` sem bloco + binario 3x + espelho + o P0 antes de reiniciar), DONO (pergunta urgente com 3 opcoes; voto: decidir `Q-019`, reanexar, depois gravar e medir o mtime).

**Nao feito, por desenho:** nenhum parametro de risco tocado; nenhum `.ex5` compilado; nenhum reattach; nenhum perfil gravado; nenhum commit/push; nenhuma ordem.
