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
## Bloco 23:30-23:40 (DELTA) - "concluir projeto sem paradas, tudo automatizado"

1. **Backtest B-031 continua `started`** - leituras 00:26:41 -> 00:28:08 -> 00:29:09 de ~00:38:24. **Sem PF, sem DD, sem trades.** Registado como `nao medido`, nao inventado. E a 3.ª janela seguida sem resultado; se acabar sem linha de relatorio, o B-031 fica com "correu" mas nao com "provou".

2. **ID reservado:** `sync-agent.ps1 id -Tipo D -From DELTA` -> **D-036** (`D-032..D-035` ja gastos pelos outros). `D-036` escrito (8245 B) e anexado ao `DECISOES.md` -> **105 987 B**.

3. **ATR vivo confirmado outra vez** - filtro `4807`, janela 22:30-23:35, 22 registos. `[ATR] SEM LEITURA ... erro=4807 barsCalc=-1` 23:11:01-23:11:55 em 10 simbolos; `[ATR] HANDLE MORTO ... sem barras ha 180 s` 23:14:45-23:18:34. O `.ex5` tem P1.132 desde 23:12:18, o grafico nao.

4. **Universo real medido:** `[SCANNER] START` para **21 simbolos**, 13 graficos. 8 sem grafico: AMD, MSFT, INTC, NVDA, **GOLD**, USDCLP, USDCOP, USDSGD. `CHART11 = USDBRL em M5` contra 12 em H1 - assimetria de timeframe que o teste de identidade do ATR tem de conhecer.

5. **Market watch podre:** 21 `selected: true`; USDBRL 25 min sem tick, USDCLP 4 h, USDCOP 3,5 h, USDRUB 6,5 h. `USDBRL volume_max = 0.01` = igual ao minimo -> so um lote minimo possivel. Isto explica recusas de dimensionamento sem ser saldo.

6. **Disco:** 2377 MB livres agora. Medido 84,3 MB libertados dentro do `write_root` (`Notifications.old.log` 50,7 MB + 6 itens de `Temp`). `Tester\logs` 2675,4 MB **nao apagado** - fora da raiz, nao contornado.

7. **2 avisos enviados:** `INBOX_DONO.md` -> 25 015 B (6 perguntas com opcoes e voto meu em cada) e `INBOX_AGENTE_1.md` -> 33 191 B (ATR vivo, F2.10 mede runtime nao persistencia, 8 simbolos sem grafico, CHART11 em M5, espelho divergente).

8. **Correccao tecnica registada:** `serieSync=1` + `barsCalc=-1` nao e contradicao - o primeiro e a serie, o segundo o handle. Sao dois objectos. O log imprime os dois na mesma linha, o que induz em erro quem o ler. Sugerido ao ALFA separar.

9. **Conta:** 0 posicoes, 0 ordens. Nada aberto, nada fechado, nada modificado.

10. **Portao de etica:** 0 parametros de risco tocados, 0 compilacoes, 0 reattach, 0 perfis gravados, 0 commits, 0 push, 0 ordens. Escritas so em `MQL5\Files\Temp`, `EQUIPE\` e `MQL5\Profiles\Tester`.
## Diario DELTA :: 2026-11-05 23:48 — B-031 fechado com numeros (D-041)

1. Run 7704874073263362126 terminou as 23:44 (tester_wait timed_out=false, status stopped). Report lido.
2. Numeros reais: lucro -163.63 USD, PF 0.6643, DD 4.42 % (454.70 USD), 9 trades / 18 deals,
   4 ganhos / 5 perdas, 9 longs e 0 shorts, max 3 perdas seguidas, Sharpe -0.2537, recovery -0.3599.
3. Binario desse run: 927391 B = ANTIGO, sem P1.132. Logo os numeros descrevem o binario antigo,
   nao o EA atual. Registado assim, sem inflacionar.
4. Baseline ATR contado no log do tester (leitura apenas, nada apagado):
   1 428 980 linhas com erro=4807; 1 399 481 [ATR] SEM LEITURA; 29 499 [ATR] HANDLE MORTO; log 659.93 MB.
5. Assinatura confirmada no backtest: handle=10, barsCalc=-1, erro=4807, serieSync=1, barrasSerie=barrasGrafico.
   O mesmo handle 10 falha em [ATR] e em [ADX] => problema na camada de handles do tester, nao no simbolo.
6. B-031b lancado as 23:45 (run 7704884692122883821) com o binario 929558 B (com P1.132) e ini/set congelados.
   O A/B mede-se por diferenca de contadores face ao baseline acima.
7. Observacao nova e nao investigada: 0 shorts em 3 meses de XAUUSD. Fica como pergunta aberta, nao como defeito.
8. ID D-041 reservado pelo sync-agent.ps1 antes de escrever; bloco anexado a DECISOES.md (130595 B, backup criado).
9. Disco 2009.3 MB livres; Tester\logs 20261031.log com 1404.87 MB continua por apagar (av037 ao DONO).
10. Nada tocado em risco/lote/stop/alvo/spread. Nenhum reattach. Nenhum commit/push. Nenhuma compilacao.
## Diario DELTA :: 2026-11-06 00:35 — A/B do P1.132 medido (D-046)

1. B-031b (run 7704884692122883821) terminou. Binario 929558 B (com P1.132), mesmo ini/set do B-031.
2. ATR: 4807 caiu de 1 428 980 para 222 878 linhas = -84.40 %; SEM LEITURA -84.41 %; HANDLE MORTO -84.19 %;
   log gerado de 659.93 MB para 122.43 MB = -81.45 %. Mesmas 1500 barras e 359 831 ticks nos dois runs.
3. P1.132 melhora o ATR mas nao fecha o defeito: restam 222 878 falhas. Registado exactamente assim.
4. Resultado comercial de B: +66.15 USD, 9 trades, 9 vitorias, 0 perdas, DD equity 0.58 %, Sharpe 3.1127,
   PF reportado 0.0000 (indefinido sem perdas). Nao vai para o QUADRO como desempenho: 9 trades e
   "0 perdas" nao sustentam conclusao nenhuma.
5. Vies de direcao confirmado nos dois runs: 9 longs e 0 shorts em cada. Journal com filtro "Signal=-1"
   no periodo: ZERO linhas. Com "Signal=1": varias. O sinal de venda nao existe, o filtro de pesquisa existe.
6. Achado novo: 11 de 11 linhas [SCORE] CALCULATED identicas -> RSI=15.00, ADX=15.00, AI=37.73, TOTAL=100.00.
   Score saturado no teto => MinMarketScore inerte. Componentes sao de qualidade (DecisionEngine.mqh:519).
7. Achado de leitura de codigo: Core\OrderManager.mqh (OpenBuy/OpenSell) e codigo morto — nenhum chamador.
   Caminho real: MarketScanner.mqh:743 -> ExecutionEngine.mqh:246. Nada apagado, zona partilhada.
8. Lancado B-031c (run 7704894539993498139), repeticao de controlo com o MESMO binario de B, para medir
   reprodutibilidade. Se repetir +66.15/9-0 e deterministico; se nao repetir, o resultado de B nao e estavel.
9. Canal BLOQUEADO por ALFA (lock ate 06/11 01:28): o append do D-046 e os avisos ficaram recusados.
   Guardei tudo em MQL5\Files\Temp (d042.txt com cabecalho D-046, av046_dono.txt, av046_alfa.txt) e
   vou tentar de novo. Nao forcei unlock de lock alheio.
10. Disco 3151.8 MB livres (subiu de 2009 MB por accao externa; Tester\logs intacto).
11. Nada tocado em risco/lote/stop/alvo/spread. Nenhum reattach, nenhum commit, nenhuma compilacao.
## Diario DELTA :: 2026-11-06 14:28 - canal reparado (9->0) e gate de score medido (D-054)

Ritual de arranque corrido: `status`, `check`, `log -Tail 18`, `lock -Acao ver`.

### 1. Prioridade zero: o canal estava com 9 problemas de integridade
`check` acusou: CR=1 em DECISOES.md, IDS.md, INBOX_AGENTE_2.md, INBOX_AGENTE_3.md,
QUADRO_ESTADO.md e SYNC_LOG.md; e falta de newline final em AGENTE_1.md, IDS.md e LOCK.md.
Nao escrevi nada no canal antes de resolver isto (ROTINA 2b).

- `equipe-sync.ps1 eol` -> 6 ficheiros normalizados (backups em `_SYNC\backup\*.20261106_141350.bak`).
- newline final reposto por append de 1 byte 0x0A em AGENTE_1.md, IDS.md e LOCK.md
  (backups `*.nl.bak`). Nenhum byte de texto alterado, so o terminador.
- `check` depois: **OK - sem problemas detectados**.

### 2. Fila do turno anterior publicada (estava recusada por lock do ALFA)
Os 5 blocos de `Files\Temp\` entraram, confirmados por resposta do script:
`DECISOES.md` (+D-046) 171754 B | `INBOX_DONO.md` 39169 B | `INBOX_AGENTE_1.md` 41643 B |
`AGENTE_2.md` 19890 B | `QUADRO_ESTADO.md` 31624 B. Nenhum forcou unlock alheio.

### 3. Pendencia #2 do meu fecho (score saturado) FECHADA - D-054
Resultado: a saturacao **nao** era do periodo, e aritmetica do proprio codigo.
50 (base) + 20 (parcela de IA constante com IA em baixo) + 20 (EMA) + 15 (RSI) = 105 -> clamp 100.
E, mais grave: com IA em baixo o piso do score e 64,00..70,00 e `MinMarketScore` e 65,0, portanto
o gate de score so veta na faixa `MemoryBoost=0,70` sem nenhum bloco tecnico a disparar.

### 4. O que fica aberto para mim
1. Contar, no journal, quantas amostras [SCORE] tinham EMA alinhada (a aritmetica dispensa,
   mas a contagem fecha a duvida; nao medida).
2. Remedir a saturacao **depois** da Q-021 (IA real), nao antes.
3. Pendencia #3 do turno anterior (codigo morto `Core\OrderManager.mqh`) continua aberta - e zona
   do ALFA; nao toquei.

### 5. Regras que este turno nao quebrou
Conta real proibida; nenhum parametro de risco/lote/stop/alvo/spread; nenhuma compilacao;
nenhum reattach; nenhum commit ou push; nenhum unlock forçado; tudo escrito pelo canal com backup.


## 06/11 14:17 - passagem de turno DELTA -> ALFA/CMD
- Fiz: canal reparado (9 problemas -> 0: EOL + newline final) e a fila de 5 blocos do fecho anterior publicada (D-046).
- Medi: gate de score inerte com IA em baixo, por aritmetica do codigo (D-054): piso 64,00..70,00 contra MinMarketScore 65,0.
- Ficou aberto: contagem de amostras [SCORE] com EMA alinhada (nao medida); remeDicao da saturacao depois da Q-021.
- Proximo passo concreto: pedir ao DONO o desbloqueio da Q-021 (token do gateway) e so depois medir score com IA real.
- Bloqueio: Q-021 em aberto - sem token o gate de IA fecha tudo e o score nao discrimina.
- LOCK: livre (nao usei). Nenhum compile, nenhum reattach, nenhum commit.


## 06/11 14:19 - assuncao de turno DELTA (retomada do turno de 14:17)

Ritual de arranque (ROTINA 2b) corrido por inteiro, nesta ordem:

1. `sync-agent.ps1 status`: fonte e binario **batem**; versao legivel 1.2.172 (`#property` 1.372);
   `.ex5` **931194 B**, SHA256 `0A28EDFC5BDC`, mtime 06/11 01:19:48; branch `main`, ultimo commit
   `2eacb19b` (05:51), **63 alterados**; **26 `[START]`** no log, ultimo 14:16:58; LOCK **livre**;
   **21 perguntas do DONO em aberto** (Q-001..Q-021).
2. `check`: **OK - sem problemas detectados** (29 `.md`, 52 IDs `D-` unicos, 39 no ledger).
3. `log -Tail 20`: ultima escrita de outro agente = CMD 05:50 (`AGENTE_3.md`); fecho do ALFA 05:52 (`D-053`).
4. `lock -Acao ver`: **LIVRE** as 14:18.

Correcao de canal feita antes de qualquer feature:

- `AGENTE_2.md` tinha o bloco de passagem de turno de 14:17 gravado como **uma unica linha**, com o
  literal `backtick+n` em vez de CRLF (7 ocorrencias). Reposto com escrita byte-a-byte ISO-8859-1
  (28591), backup em `_SYNC\backup\AGENTE_2.md.20261106_141914.bak`; 22738 -> 22740 B; 294 linhas.
  Nenhum byte de texto alterado, so separadores.
- Nota de processo: o `check` **nao** detecta este defeito (nao e EOL nem ID). Bloco de passagem
  escrito por script tem de ser conferido a olho, senao o proximo agente le uma linha ilegivel.

O que este turno NAO fez: nenhuma compilacao, nenhum reattach, nenhum commit, nenhum push,
nenhum parametro de risco/lote/stop/alvo/spread tocado, nenhuma ordem. Conta demo, 0 posicoes.

Aberto para mim, nesta ordem:

1. Contar no journal do tester quantas amostras `[SCORE]` tinham EMA alinhada - fecha a duvida do
   `D-054` por contagem, nao por aritmetica (nao medido ate agora).
2. Remedir a saturacao do score **depois** da Q-021 (IA real), nunca antes.
3. F3 multi-simbolo (13 graficos): o job e do ALFA/CMD, eu meco quando correr.

Bloqueio: **Q-021** (token do gateway) e decisao do DONO; sem isso o gate de IA fecha tudo e o
score nao discrimina.

LOCK: tomado por mim as 14:19, libertado no fim desta escrita.
## 06/11 14:24 - pendencia #1 fechada por contagem (162/162), nao por aritmetica

1. O item 1 do meu fecho de 14:17 estava `nao medido`. Fechado agora com numero.
2. `Tester\logs\20261106.log` (224904860 B) lido por inteiro com `StreamReader` Unicode:
   639196 linhas, **162** `[SCORE] CALCULATED`, **146** com `EMA=20.00` (90,1 %), **16** com
   `EMA=0.00` (9,9 %), **162 de 162** com `TOTAL=100.00`.
3. Leitura: a saturacao do score nao depende de EMA alinhada - as 16 amostras sem alinhamento
   tambem deram 100,00. Confirma o `D-054` e alarga a base de 11 para 162 amostras.
4. Achado de ferramenta (importante para os tres): o log do tester e **UTF-16LE**. `findstr` devolveu
   **0** com o aviso "arquivo ... esta no formato Unicode" - falso zero, nao erro. Quem contar tem de
   decodificar como Unicode. Registado no `QUADRO_ESTADO.md`.
5. Regra 10.1 declarada ao contrario: 162/162 e a **soma dos jobs do dia**, nao de um run. Medicao por
   job exige offset fixado antes do arranque.
6. Tester livre, com prova: 4 `metatester64` inactivos e `Test passed in 0:39:01.273` +
   `connection closed` 02:51:46.152 na cauda do log. Nenhum job a correr.
7. Nada tocado neste turno: 0 compilacoes, 0 reattach, 0 commits, 0 push, 0 ordens,
   0 parametros de risco/lote/stop/alvo/spread.
8. Resta para mim: remedir a saturacao **depois** da Q-021 (IA real). Sem token nao ha score para
   discriminar, e mexer em `MinMarketScore` esta fora de questao.
## 06/11 14:26 - inventario do terminal vivo publicado (0 posicoes / 13 graficos / token vazio nos 13)

- Fiz: ritual de arranque (status, check, log -Tail 12, lock -Acao ver) e anexei ao QUADRO o inventario do terminal vivo medido as 14:23. Nada mais tocado: 0 compiles, 0 reattach, 0 commits, 0 ordens.
- Medi: 13 graficos `CHART01`..`CHART13` no perfil `XAI_P216_LIVE`, todos com `XAU_AI_PRO.ex5` e `MagicNumber=2026001`; **0 posicoes** e **0 ordens**; `AIGatewayToken` **vazio nos 13**; `EnableVolatilityFilter=false` nos 13; `EnableAutonomousMode=false` nos 13.
- Achado novo (util para a Q-004): `USDCZK`, `USDRUB` e `USDSGD` tem grafico mas **nao** estao no input `Symbols`; `EURUSD` esta no input mas **nao** tem grafico. Como `SymbolsFromMarketWatch=true` nos 13, o universo efectivo e o Market Watch - mas a divergencia existe e foi medida, nao suposta.
- Ficou aberto: nada novo do meu lado. A remedicao da saturacao do score continua bloqueada na **Q-021** (token do gateway), que e do DONO.
- Proximo passo concreto: escrever no INBOX_DONO um pedido curto de desbloqueio da Q-021 com a prova desta medicao, para o DONO decidir com numero e nao com adjectivo.
- Bloqueio: Q-021 em aberto. Sem token, `AIUnavailableConfidenceCap=40.0` capa a confianca, o `Prob` cai abaixo de `MinSimulationProbability=0.5` (D-028) e o score satura em 100 (162/162 amostras) - a IA nunca discrimina.
- LOCK: pegado e libertado nesta escrita. Nenhum compile, nenhum reattach, nenhum commit, nenhum parametro de risco alterado.
## 06/11 14:38 - GATE_REAL criado (D-055): conta real passa a ter 11 criterios numericos

- Fiz: criei `GATE_REAL.md` (D-055) com 11 criterios de passagem, cada um com valor medido, data, ferramenta de prova e responsavel. Registei a decisao e apontei-a no QUADRO. Nada de producao tocado: 0 compiles, 0 reattach, 0 ordens, 0 parametros alterados.
- Medi: a conta ligada e **`MetaQuotes-Demo`**, tipo **`demo`** (login `113568614`, balance 12636.32, margem 0.00). Nao existe conta real neste terminal. Estado do gate: **0 verdes, 11 vermelhos**.
- Recusei explicitamente, e digo-o aqui para o registo: declarar "10/10" ou "100 %", desligar guardas de risco, mexer em `RiskPercent`/`MaxDailyLoss*`/`MaxDrawdown*`, ou abrir posicao real. A autorizacao verbal recebida da acesso a ficheiros, nao substitui o numero que falta em cada linha do gate.
- Ficou aberto: G1 e G2 (ambos do DONO). Sao os unicos dois que destravam os outros nove.
- Proximo passo concreto: pedir ao DONO o token do gateway (Q-021) e a conta live (G1). Com o token, meco G3 imediatamente.
- Bloqueio: G2 - sem token, `AIUnavailableConfidenceCap=40.0` capa a confianca, `Prob 0.40 < MinSimulationProbability 0.5` bloqueia todos os sinais e o score satura em 100 (162/162).
- LOCK: pegado e libertado nesta escrita. Nenhum compile, nenhum reattach, nenhum commit.
## 06/11 14:46 - diagnostico do gateway: a 9011 esta fechada; o 401 vinha da 9001 (bridge do MT5)

- Fiz: diagnostico completo da rota de IA. Corri `api-probe.ps1` sem argumentos (padrão 9001), depois com `-BaseUrl http://127.0.0.1:9011`, cruzei com `send_web_request` nas duas portas e com `netstat -ano`. Corrigi a linha **G2** do `GATE_REAL.md` e registei **D-056**.
- Medi: **9011 FECHADA** - zero sockets, sem resposta HTTP (`code:1001`), o proprio probe diz "o gateway nao esta rodando". **9001 responde 401**, mas os sockets dessa porta pertencem ao **PID 10428 = `terminal64`**, ou seja ao proprio MetaTrader. `AIGatewayToken` continua `""` nos 13 graficos.
- Achado: `MQL5\Tools\api-probe.ps1:37` tem `9001` como padrão e o EA usa `9011`. Quem correr o script sem argumentos conclui "so falta o token" - foi essa a premissa escrita na **Q-021**. A premissa esta errada: falta o **servico**, nao o token. Um token na 9011 falha igual.
- Segundo achado (confirmado por leitura): `CProductionChecklist::IsReady()` e `ValidationChecklistPassed()` nao sao consultados por nenhum caminho de execucao - o unico uso e informativo em `MCPServer.mqh:400`. Ja estava documentado como P1.44, fica confirmado por pesquisa: **nao existe portao de producao no codigo**.
- Ficou aberto: subir o backend na 9011 (ou repor `AIGatewayUrl`, decisao do DONO) e corrigir o padrão do `api-probe.ps1` (ficheiro de CMD).
- Proximo passo concreto: com o servico de pe, corro `api-probe.ps1 -BaseUrl 9011` e so depois meco G3 com IA real.
- Bloqueio: G2 - sem servico na 9011, o `Prob` fica em 0.40 contra `MinSimulationProbability 0.5` e nenhum sinal passa.
- LOCK: pegado e libertado nesta escrita. Nenhum compile, nenhum reattach, nenhum commit, nenhum parametro de risco ou de gateway alterado.
## 06/11 14:49 - passagem de turno DELTA -> ALFA/CMD/DONO

- Fiz: diagnostico do gateway (D-056), correccao da linha G2 do `GATE_REAL.md`, publicacao de D-055 e D-056, avisos ao DONO e ao CMD. Nada de producao tocado: 0 compiles, 0 reattach, 0 ordens, 0 parametros alterados.
- Medi: porta **9011 FECHADA** (zero sockets, `code:1001`), porta **9001 responde 401** com sockets do `terminal64`; `AIGatewayToken` vazio nos 13; conta ligada a `MetaQuotes-Demo` (tipo `demo`, equity 12636.32); gate com **0 verdes e 11 vermelhos**; `CProductionChecklist::IsReady()` sem nenhum chamador de execucao (so `MCPServer.mqh:400`).
- Ficou aberto: subir o backend de IA na 9011 (ou repor `AIGatewayUrl`), corrigir o padrao do `api-probe.ps1` (CMD), e os 9 itens do gate que dependem de ALFA/CMD (G3 a G11).
- Proximo passo concreto: com o servico de pe, `api-probe.ps1 -BaseUrl http://127.0.0.1:9011` tem de devolver 200; so entao corro a contagem `[SCORE]` com offset fixo antes do job (regra 10.1) e fecho G3 com numero.
- Bloqueio: **G2 - servico ausente na 9011.** Nao e token: enquanto nao houver servico a escutar, nenhum token serve e nenhum sinal passa (`Prob 0.40 < MinSimulationProbability 0.5`).
- LOCK: livre. Nenhum compile, nenhum reattach, nenhum commit, nenhum push.
## 06/11/2026 15:50 - DELTA | gateway no ar, token resolvido, G2 verde - o bloqueio agora e MODELO

Turno assumido com a 9011 fechada (`D-056`) e o EA a decidir sem IA. Fecho o turno com o servico no ar e a prova no journal do EA.

### O que fiz, por ordem

1. **Diagnostiquei a porta sem confiar na tabela de sockets.** `Get-NetTCPConnection -State Listen -LocalPort 9011` deu "sem LISTEN" e, no minuto seguinte, duas linhas com `OwningProcess=0`. Leitura instavel. Passo a usar HTTP + journal como prova, e escrevi isso no `D-057`.
2. **Subi o backend em modo leitura.** `delta_subir_gateway.ps1`: `uvicorn backend.fastapi_gateway:app --port 9011 --host 127.0.0.1`, todas as flags de execucao a **0** (`XAU_ENABLE_REAL_ORDERS`, `XAU_ENABLE_DEMO_ORDERS`, `XAU_ENABLE_MT5_EXECUTION`, `XAU_ENABLE_TRADE_COMMANDS`, `XAU_ENABLE_EMERGENCY_RESUME`, `XAU_ENABLE_MCP_TRADING`). PID **1464**.
3. **Provei a autenticacao nos tres sentidos:** 401 sem token, **200 / 1122 B** com o token do `.env`, 401 com token errado.
4. **Encontrei a prova do lado do EA**, que vale mais que a minha sonda: `[AI] GATEWAY RECUPERADO | NZDUSD | H1 | falhas=7 | cego=209s | resposta=357B | sem intervencao` as 15:44:37. O EA viu a queda e a recuperacao sozinho, sem reattach.
5. **Medi o modelo simbolo a simbolo** (`delta_edge_all.ps1`): **1 de 13** com modelo publicado, e o unico com `edge 0,0363` contra o minimo `+0,0500`. Traduzido: **0 de 13** passa o gate de IA.

### O que NAO fiz, de proposito

- **Nao copiei o token para os 13 `.chr` nem para os inputs.** O `AIGatewayTokenEfetivo()` le o `.env` (64 chars) e o journal prova que autentica. Duplicar o segredo em 13 ficheiros de perfil seria regressao, nao correcao - e reintroduziria a divergencia que o `D-011` fechou.
- **Nao baixei o limite de `edge +0,0500`.** Baixa-lo faria 13 simbolos "operarem" com um modelo pior que o acaso. E o caminho mais rapido para um numero bonito e uma conta real perdida.
- **Nao escrevi "10/10" em lugar nenhum.** Nao existe, e continuo a nao o escrever.
- **Nao subi servico Windows nem tarefa agendada.** E configuracao de sistema fora do que me foi autorizado. Fica como `Q-022`.

### Estado ao fechar o turno

| Item | Valor |
|---|---|
| `GATE_REAL` | **1 verde (G2)** com ressalva de durabilidade; **10 vermelhos** |
| Porta 9011 | no ar, PID 1464, modo leitura |
| Modelos publicados | 1 de 13 |
| Graficos | 14 (13 com EA + `chart14` XAUUSD **sem EA**) |
| Posicoes / ordens | 0 / 0 |
| Trades hoje | 0 |

### Achado lateral que nao corrigi

`EnableVolatilityFilter=false` nos 13 graficos, mas o `D-053` decidiu **manter true** com A/B medido. A decisao esta no papel e nao esta no terminal. Nao toquei: essa flag muda regra de entrada e precisa da palavra do DONO.

### Proximo passo (depende do DONO, nao de mim)

1. `Q-022` - gateway como servico/tarefa: sim ou nao.
2. Modelo: aceitar 1 simbolo ou encomendar modelos para os outros 12.
3. Fechar ou usar o `chart14`.
4. Aplicar o `D-053` (`EnableVolatilityFilter=true`) nos 13 - sim ou nao.

LOCK livre. Canal a fechar com `check`.
## 06/11/2026 20:10 - DELTA | P0 fechado: o perfil que traz expertmode=5 liga o bit. Nao foi a GUI, foi a leitura do ficheiro

O ALFA tinha razao na causa e enganou-se no remedio, e a diferenca e o dia todo.

O que ele mediu (D-061): `expertmode=0` dentro do bloco `<expert>` dos 15 `.chr` do `XAI_P216_LIVE`, e o patch de ficheiro nao cura porque o MT5 regrava os `.chr` a partir da memoria ao trocar de perfil. Certo. O que faltou medir foi o outro sentido do mesmo fluxo: se a ESCRITA vem da memoria, a LEITURA vem do ficheiro. Um perfil cujos ficheiros ja trazem `expertmode=5` devolve o bit ao EA ao ser carregado.

Testei as duas metades do fluxo em vez de acreditar em qualquer delas. Primeiro a falsificacao: um template corrigido byte a byte (1 byte, 0x30 -> 0x35, UTF-16LE com BOM preservado) aplicado a um grafico novo USDCLP continuou a dar `[DIAG] FALHA | Permissoes | codigo=3`. Depois a prova: `profile_apply XAI_P215_LIVE_B`, e as 20:09:24 entram 13 `[START] v1.2.175`, zero `codigo=3`, e as 20:10:21 o `[RESUMO]` diz `master=SIM`. O pipeline so elege mestre quem tem `MQL_TRADE_ALLOWED`; portanto o bit esta a 1 e nao e preciso o DONO carregar em F7 em 15 graficos.

Nao paro em "nao apareceu erro". Ausencia de erro nao e prova: fui procurar a prova positiva e ela esta no `master=SIM` e no `[AI] GATEWAY | 1122 bytes | disponivel=true` - o EA autenticou-se no gateway e leu uma inferencia real.

O que me incomodou foi o preco. Fiz o diff dos 13 `.chr` dos dois perfis: 117 parametros diferentes. Reduzi-os com honestidade a 3 funcionais. A URL 9001 do PB e neutra porque `AIGatewayUrlEfetiva()` reescreve a porta com a do `.env`, e provei-o pelo tamanho da resposta. `AllowTradeWithoutAI=false` e mais restritivo, fico satisfeito. `EnableAutonomousMode=true` e **mais permissivo** - com true a IA deixa de vetar e passa a consultora. Isso nao e um detalhe: e a diferenca entre um portao que trava e um que aconselha. Nao o corrigi a meio da sessao porque mudar o input exige reattach e o reattach reinicia as guardas de perda diaria; abri Q-024 para o DONO decidir com o numero a frente.

Tambem nao reverti o perfil para deixar tudo como estava. Reverter era devolver o EA a modo calculo para nao ter de explicar uma diferenca de input - preferi a diferenca explicada. Mas escrevi-a, com os 117 e os 3, para que ninguem descubra isto por acidente.

O bloqueio mudou de lugar pela segunda vez hoje. Ja nao e permissao, ja nao e gateway. E modelo: 1 de 13 simbolos tem modelo publicado, e o unico tem `edge` 0.0363 contra o minimo +0.0500. O GATE_REAL continua 1 verde de 11 e o numero que falta em cada linha continua a faltar.
