# SESSAO 07/11/2026 - ALFA (turno 2): quatro pendencias medidas

**Papel:** ALFA (codigo, medicao, provas). **Nao assina gate nenhum.**
**Janela:** 07/11/2026 14:35 -> 14:50 (hora do terminal).
**Compile neste turno: ZERO.** Nenhuma linha de codigo foi alterada, nenhum risco,
lote, alvo, stop, spread ou regra de entrada foi tocado, nenhuma ordem foi enviada.

Motivo de nao haver compile: o lock de operacao esteve ocupado por DELTA
(14:32:08 -> ~14:41) e depois por CMD (14:41:13 -> 15:01:13), e a regra do
canal e **um compile por janela**. Este turno e de MEDICAO e de fecho de
pendencias do turno anterior, nao de codigo.

---

## 1. `[CONFIG] EM VIGOR` - pendencia 1 do turno anterior: FECHADA com prova positiva

O turno anterior deixou escrito: "a unica linha `[CONFIG] EM VIGOR` do journal e das
00:07:11 e diz `MaxDD=15.0%`; em v1.2.183 a linha nao foi reemitida; a prova do valor
efectivo e o `.chr`, nao o journal. Reconfirmar num arranque limpo."

Reconfirmado. Prova:

```
14:27:49.964  [CONFIG] Perfil ativo: Conservative
14:27:49.969  [CONFIG] Perfil 'Conservative' e CATALOGO de referencia e NAO entra em decisao
              (GetProfile sem consumidores) | referencia: Lot=0.01 SL=80 TP=160 MaxDD=3.0% Trades=5
              | EM VIGOR: SL=300 pts TP=600 pts Trades/dia=100 MaxDD=50.0% Risk=1.0% MaxDailyLossUsd=60.0
```

Leitura: **Q-071 esta em vigor e agora esta provada pelo journal**, nao apenas pelo
`.chr`: `MaxDD=50.0%` (6.318,16 USD sobre equity 12.636,32), SL 300 / TP 600 /
100 trades-dia / Risk 1.0% / MaxDailyLossUsd 60.0.

### A hipotese do turno anterior estava errada e fica corrigida

Eu tinha escrito "hipotese: Print uma vez por sessao do terminal". **Falso.**
`CConfigManager::LogStatus()` (Enterprise/ConfigManager.mqh:347) esta atras de
`AccountLogGatePodeImprimir("config", 3600)`, ou seja **1x por hora por CONTA**, num
ficheiro comum. Prova cruzada: `Common\Files\XAU_AI_PRO\loggate_config.bin` tem
mtime **14:27:49**; o arranque seguinte, as **14:36:53**, ficou 9 minutos depois,
logo `agora >= ultimo + 3600` era falso e a linha foi suprimida - o silencio nao
era defeito do EA.

### Defeito residual medido (so observabilidade, nao risco)

As 14:27:49.969 sairam **3 linhas identicas** (`XAUUSD`, `USDCLP`, `USDCOP`) no
mesmo milissegundo. O portao faz ler-depois-escrever no ficheiro comum e nao e
atomico entre as 15 instancias - a mesma familia do defeito v1.2.124 (rajada de
`[STOP]`). Efeito: 3 em vez de 1; nenhuma decisao passa por aqui.

---

## 2. P1.137 (guarda de identidade do ATR) - FECHADA com prova positiva em 3 arranques

**Antes** (v1.2.182/183 antes do P1.137), 4 linhas, todas entre 00:07:12 e 00:07:39:

```
[ATR] LEITURA SUSPEITA | USDCLP | ATR=203.576300 | preco=971.0500 | ATR%=20.96  | handle=10 | devolvido=0.0
[ATR] LEITURA SUSPEITA | USDCOP | ATR=73950.940000 | preco=3251.56 | ATR%=2274.32 | handle=10 | devolvido=0.0
```

**Depois** (build publicado as 14:36:53, e ja nas recargas 14:32:39 e 14:34:49):

```
[ATR] IDENTIDADE | USDCLP | serie impossivel descartada | daSerie=203.5763 | ATR%=20.96   | limite=5.00% | mantido doHandle=4.3150
[ATR] IDENTIDADE | USDCOP | serie impossivel descartada | daSerie=73950.94 | ATR%=2274.32 | limite=5.00% | mantido doHandle=14.78
```

Contagem no `MQL5\Logs\20261107.log`: **14** linhas `[ATR] IDENTIDADE`, **4**
`[ATR] LEITURA SUSPEITA`, e **as 4 sao anteriores a correcao** (a ultima as
00:07:39.487). Depois das 00:07:39 nao houve uma unica leitura suspeita, e nos tres
arranques limpos (14:32:39, 14:34:49, 14:36:54) a guarda agiu nos dois simbolos que
tem o defeito.

**O que isto prova:** a guarda descarta a serie impossivel e mantem o valor do
handle, nos dois simbolos onde o defeito existia, em 3 arranques independentes.
**O que isto NAO prova:** que o valor mantido (`4.3150` e `14.78`) seja o ATR
correto - isso exige mercado aberto e confronto com o ATR do grafico. Fica escrito
como o que e: prova de comportamento, ainda nao de exatidao.

---

## 3. Reconciliacao `min_edge 0.05` x criterio de publicacao - MEDIDA, nenhum limiar alterado

Pendencia do turno anterior: "reconciliar o `min_edge 0.05` do meta dos modelos com o
criterio real de publicacao (`edge_balanced >= 0,0300` **e** `AUC >= 0,5200` **e**
maioria das folds positiva) - 14 de 15 simbolos foram recusados por um piso nunca
validado". Medido nos **87** `*.meta.json` de `Files\XAU_AI_PRO\Python\models`:

| Familia | Ficheiros | Pipeline / schema | Metricas guardadas | Criterio aplicado |
|---|---|---|---|---|
| A - 1 simbolo | **80** | `train_v2.py`, `25F-v2`, RandomForest, 3 classes | accuracy, baseline, edge, folds (sem AUC) | edge >= 0.0500 + folds estaveis |
| B - XAUUSD | **4** | `xau_model_tools.py`, `XAU-30F-v4`, HistGradientBoosting, binario | edge_balanced, balanced_accuracy, AUC, 5 folds | edge_bal >= 0.0300 + AUC >= 0.5200 + 4/5 folds |
| C - MULTI | **3** | `train_multi.py`, `25F-est-v1`, 3 classes | edge, edge_media_folds | edge_media_folds >= 0.0500 |

Recusas, por causa escrita no proprio meta:

| Causa | N |
|---|---|
| piso 0.0500 (familia A) | **76** |
| criterio balanced (familia B) | **3** (XAUUSD M5, M15, H4) |
| instabilidade entre folds | **3** (`USDBRL_H1` +0.0926, `USDRUB_M5` +0.0682, `USDBRL_M15` +0.0547 - 2/5, 1/5 e 2/5 folds positivos) |
| "sem folds para validar" | **1** (`USDBRL_H4`) |
| publicado | **4** (`MULTI_METALS`, `MULTI_CRYPTO`, `MULTI_FIAT`, `XAUUSD_H1`) |

Distribuicao e cobertura das metricas:

- **baseline (o palpite a bater) varia de 0,3333 a 0,5809 - amplitude 0,2476.**
  O mesmo "0,05 de edge" vale muito menos num simbolo cujo palpite ja acerta 58%
  do que num de 33%. E a razao pela qual o piso unico nao e comparavel entre simbolos.
- edge > 0: **32** de 87. edge >= 0,0300: **14**. edge >= 0,0500: **7**.
- **AUC existe em 4 de 87.** balanced_accuracy, idem. O criterio "validado" nunca
  foi calculado para 83 modelos, porque o pipeline da familia A nao produz essas
  metricas.

**Veredicto medido:** baixar o piso de 0,0500 para 0,0300 **nao publicaria nada que
se possa medir hoje** - nao haveria AUC nem balanced accuracy para julgar os 76
recusados, e passar um modelo sem essas duas provas seria trocar um piso por uma
suposicao. **O bloqueio nao e o piso, e o schema do alvo:** 83 modelos foram
treinados com alvo de 3 classes e medidos por acerto bruto; so os 4 XAUUSD usam alvo
binario com AUC e folds. O caminho honesto e o C2 (retreino dos 83 com o schema
`XAU-30F-v4`), nao uma alteracao de limiar.

Consequencia para a pergunta que estava escrita ao CMD: a pergunta certa deixa de ser
"o piso e demasiado alto?" e passa a ser "o retreino dos 83 com o schema binario
entra no C2, e com que profundidade de dataset por simbolo?" - que e exactamente a
segunda pergunta que ja estava aberta.

---

## 4. F2.8 (magic unico por instancia) - MEDIDA

Varridos os **30** `.chr` (15 em `Default`, 15 em `XAU_AI_PRO_15CHARTS_Q071`):

- `MagicNumber=2026001` nos **30**. `expertmode=5` nos **30**.
- Cada simbolo aparece **exactamente uma vez por perfil** (15 simbolos, 15 graficos).
- `MagicNumber` e `input long` em `Core/Config.mqh:17`, portanto **configuravel por
  grafico sem compile**.

Leitura: **hoje o risco e latente, nao activo**. O filtro de posicao e
simbolo+magic e nao ha simbolo duplicado num perfil, logo nenhuma instancia gere a
posicao de outra. O risco activa-se no instante em que (a) se abrir um segundo
grafico do mesmo simbolo, ou (b) se carregarem os dois perfis ao mesmo tempo - e
nesse instante duas instancias passam a partilhar a mesma chave.

Proposta para a proxima janela de compile (exige DECISAO, nao tomada agora e nao
tomada por mim): recusar o arranque quando `(magic, simbolo)` ja pertencer a outra
instancia viva, ou derivar o magic por grafico. Nenhuma das duas foi escrita.

---

## 5. O que NAO foi feito (e por que)

1. **Zero compiles.** Lock de DELTA (14:32:08) e de CMD (14:41:13 -> 15:01:13);
   um compile por janela.
2. **Zero alteracoes de codigo e de parametro.** Nenhum limite, lote, alvo, stop,
   spread, regra de entrada ou de saida foi tocado.
3. **Zero escritas no canal neste turno (ate 14:50).** `DECISOES.md` e os `INBOX`
   estavam sob lock do CMD, cujo motivo declarado e "entrega v1.2.183 (D-072),
   INDICE e fecho do newline" - escrever no mesmo ficheiro com o lock activo seria a
   violacao que eu proprio corrigi em 06/11. Reserva do D-073 e `PRESENCA` ficam
   para quando o lock estiver livre.
4. **`[TRADE BLOCK] COTACAO VOLTOU` e `[ADV AI]` nao nulo nos 20 activos: NAO
   provados.** Mercado fechado (sabado). Ultimo tick 06/11 22:59:59; idades medidas
   as 14:37: XAUUSD 74.246 s, USDRUB 95.854 s, USDCLP 86.889 s, USDCZK 70.651 s -
   todas contra `limite=900s`. A previsao falsificavel continua escrita: no proximo
   open tem de sair `COTACAO VOLTOU` e a IA tem de deixar de devolver
   `disponivel=false` nos simbolos com modelo publicado.
5. **GATE_REAL: 1 verde de 11.** Nenhum "10/10" foi escrito, nenhum gate assinado.

---

## 6. Estado medido no fim do turno (14:50)

- **Conta 113568614** (MetaQuotes-Demo, demo, hedging): **0 posicoes, 0 ordens**,
  saldo = equity = **12.636,32 USD**, margem 0,00. Nada foi tocado.
- **Terminal:** build **6308** (era 6306 no fecho da madrugada), sincronizado
  (`last_authorized_at` 17:34:45Z), ping 233 ms, retransmit 0,80%,
  `experts_trade_allowed=true`.
- **Binario:** `XAU_AI_PRO.ex5` **964.160 B**, mtime **14:36:53**; **15x**
  `[START] XAU_AI_PRO v1.2.183` entre 14:36:54.042 e 14:36:56.274.
- **HG-01 alinhada no fonte:** `#property version "1.383"` (`XAU_AI_PRO.mq5:22`)
  contra `EA_VERSION_STRING "1.2.183"` (`Enterprise/VersionManager.mqh:14`) -
  coerente com `minor*100+patch` = 383. Quem fechou foi o DELTA; eu medi, nao
  alterei.
- **Lock:** CMD, 14:41:13 -> 15:01:13.

---

## 7. Pendencias que continuam por dono

**DONO:** Q-017 (numero da perda diaria; hoje `MaxDailyLossPercent=10.0` e
`MaxDailyLossUsd=60.0` - dois numeros para a mesma coisa, o menor e que manda);
token MCP privado; 18 perguntas abertas em `INBOX_DONO.md`.

**CMD:** commit/push dos 7 ficheiros de codigo (agora com HG-01 fechada) com autor
declarado e referencia ao D-072; responder as 2 perguntas do C2 (o `30F-v4` e
especifico de XAUUSD? que 20 simbolos nao tem profundidade de dataset?).

**DELTA:** as 3 provas do F2.2 (recusa acima do tecto, fail-closed com
`ACCOUNT_MARGIN` ilegivel, zero falso positivo abaixo do tecto) e a assinatura.

**ALFA (proximo turno):** F2.8 na proxima janela de compile; prova de exatidao do
P1.137 em mercado aberto; e a reconciliacao de modelo passa a ser a pergunta do C2,
com os numeros da seccao 3.

---

Assinatura: **ALFA, 07/11/2026 14:50** - medido, nao assinado como fecho de gate.

---

## 8. Turno 3 (14:55-14:57) - D-075 e o acoplamento do F2.8

Depois do fecho de 14:50 ficaram coisas por escrever. Este turno fez quatro delas e nao
tocou em codigo.

**1. Quarto aviso ao DELTA (14:55).** O corpo da adenda ao D-074 estava escrito e nao
postado. Foi entregue em `INBOX_AGENTE_2.md` sem alteracao: o HG-01 do DELTA sai mais forte
(prova no binario de que as duas linhas `#property version "1.290"` nao sobrepoem a 1.383),
a causa das 3 linhas rasgadas do CSV (TTL do `EventLock` roubado a um dono vivo), e os 22
cabecalhos com `v1.2.9`.

**2. D-075 medido e registado.** O F2.8 estava parado a espera de decisao. Medi o que faltava:
`Core/Config.mqh:1257` percorre `PositionsTotal()` - a CONTA - e filtra por magic em `:1264`;
`:1352-1358` faz `envelope = min(10% do saldo, 60 USD)` e `sobra = envelope - RiscoAbertoUSD()`;
`Core/ExecutionEngine.mqh:694-699` recusa com `RISK_ENVELOPE_FULL`. Como as 15 instancias
partilham `MagicNumber = 2026001` (`:17`), **o tecto de 60 USD e hoje um tecto unico da conta**.
Uma frase que circula nas caixas (`INBOX_AGENTE_3.md:1242`) diz que o envelope ve uma so
instancia e que o tecto fica 15x maior - isso pressupoe magics diferentes por instancia, que
e exactamente o que a opcao (B) do F2.8 faria.

**3. A conclusao que interessa.** Se o F2.8 for resolvido por (B) - magic por grafico - sem
alterar o somatorio, o unico limite de exposicao somada que existe cai de 60 USD na conta para
60 USD por grafico, ate 900 USD nos 15, sem ninguem escrever um numero novo. Nao escolhi (A)
nem (B): (B) muda o que o EA pode expor. Avisados DELTA (auditoria), CMD (nao derivar magic
sozinho) e DONO (em portugues simples, 14:56).

**4. Verificacoes.** `.ex5` 964160 B, MD5 `EDC7597D3D71FD2B1ED1A45AEE0178A1`, mtime 14:36:53 -
byte a byte o binario do DELTA, nao recompilei. Conta 113568614 plana: 0 posicoes, 0 ordens.
`git status --porcelain` so com `.md` do canal e este ficheiro por rastrear. `sync-agent check`
depois dos quatro posts: 37 ficheiros, 66 IDs usados / 66 unicos / 66 no ledger, 18 perguntas
abertas, OK.

**Lacunas que este turno deixa declaradas, e nao resolvidas:**
- o somatorio do envelope nao foi provado em execucao (0 posicoes abertas -> devolve 0.0);
- nao verifiquei se `Management/*` filtra por `symbol` antes de mexer numa posicao alheia;
- o D-074 e o D-075 continuam sem assinatura do DELTA.

Assinatura: **ALFA, 07/11/2026 14:57** - medido, nao assinado como fecho de gate.


## 9. Turno 4 (14:57-15:02) - o contador do canal, medido e nao adivinhado, e o custo do F2.8 do outro lado

**1) A pendencia do contador esta' fechada, e nao era um erro de contagem.** O
`check` dizia `usados 66` e `no ledger 67`. Medi as duas expressoes e sao
grandezas diferentes: `Show-Check:759` conta cabecalhos `^##\s+(D-\d{3})` de
`DECISOES.md` (66) e `:768` conta TODAS as linhas `^USADO` do `IDS.md` (67 =
60 `D` + 7 `Q`). Comparar as duas nunca daria igual enquanto houver reservas de
`Q`. O defeito real estava ao lado: `D-073` (assinado pelo DELTA), `D-074` e
`D-075` usam cabecalho descritivo e eram invisiveis ao indice, e o ultimo ID
visivel era `D-072`.

**2) A prova foi por construcao, nao por argumento.** Escrevi o `D-076` como
`## D-076 | ...` e o `check` passou de `66` para `67` cabecalhos exactamente por
causa dessa linha, com o ledger a passar de 67 para 68 reservas. Se a hipotese
estivesse errada, o numero nao mexia. A correccao da ferramenta (uma linha em
`:231` e `:759`) ficou proposta ao CMD, que e' o dono dela; nao a apliquei eu.

**3) O achado tecnico do turno: o F2.8 tem custo nos DOIS sentidos.** Medi os
lacos de gestao e o filtro que decidem em que posicoes cada instancia toca.
`BreakEven.mqh:24` percorre `PositionsTotal()` e `:35` filtra so por
`POSITION_MAGIC`; o simbolo da posicao aparece em `:38` para precificar e nunca
para comparar com `_Symbol`. `EquityProtection.mqh:45/:56` e
`MoneyLadder.mqh:119/:129` tem a mesma forma; `PortfolioManager.mqh:112/:115`
tem magic e symbol, mas `:167` tem so magic. Com `MagicNumber = 2026001`
(`Config.mqh:17`) nas 15 instancias, cada uma actua sobre as posicoes das outras
14. O D-075 tinha medido que (B) derruba o tecto de 60 USD para 60 por grafico;
este D-076 mede que (A) mantem o tecto e mantem a gestao cruzada. Nenhuma das
duas opcoes sai de graca, e nenhuma e' mudanca de input.

**4) Registado e distribuido as 14:59.** `D-076` reservado pelo `sync-agent`
(nunca `IDS.md` a mao), bloco de 4061 caracteres anexado a `DECISOES.md` pela
primitiva atomica `note`, e tres avisos: DELTA (auditar a tabela e dizer se uma
decisao assinada que o canal nao conta compromete a assinatura), CMD (a
correccao de uma linha e uma linha nova de check mais util), DONO (em portugues
simples, porque isto muda a escolha que ele tem de fazer).

**Lacunas que este turno deixa declaradas, e nao resolvidas:**
- nao ha prova em execucao de nada disto: conta plana (0 posicoes, 0 ordens) e
  mercado fechado (`trade_server_last_known_time` = 06/11 23:59:58), logo os
  lacos de gestao nao correm com posicoes reais;
- nao li `MoneyLadder` nem `EquityProtection` linha a linha - medi o filtro, nao
  o efeito;
- nao separei as duas explicacoes do P1.18 (201 `PositionModify` por ticket):
  recalculo do alvo em dinheiro ou 15 escritores concorrentes. As duas produzem
  o mesmo numero e a medicao que as separa ainda nao foi feita;
- o filtro `_Symbol` nos lacos de gestao NAO foi aplicado: e' alteracao de
  codigo que precisa de compile, e este turno teve zero compiles;
- `D-074`, `D-075` e `D-076` continuam sem assinatura do DELTA.


**CORRECCAO AO MEU AVISO DAS 14:59 (ALFA, 07/11/2026 15:03) - a diferenca de
conjuntos tem 8, nao 3.** No aviso anterior escrevi que faltavam ao indice tres
decisoes (D-073, D-074, D-075). Fui medir a diferenca completa em vez de ficar
pela lista que eu conhecia, e sao OITO reservas sem bloco visivel:

```
RESERVADO E INVISIVEL (8): D-027, D-058, D-059, D-060, D-061, D-073, D-074, D-075
CABECALHO SEM RESERVA (14): D-001 ... D-015
```

Os tres ultimos sao os que eu ja tinha nomeado (cabecalho descritivo). Os outros
cinco sao mais antigos e sao de outra natureza: estao reservados no `IDS.md` e
nao tem bloco `##` nenhum, ou seja, foram reservados e o bloco nao ficou escrito,
ou ficou escrito com outro titulo que tambem nao casa. Nao sei qual dos dois sem
abrir o ficheiro nas linhas certas, e nao vou adivinhar: o que a medicao diz e
que **8 IDs foram entregues a alguem e o canal nao consegue mostrar a decisao
deles**.

A outra metade tambem merece ser dita, porque muda a leitura do problema:
`D-001` a `D-015` tem cabecalho e nao tem reserva no ledger. O ledger comecou a
ser escrito depois das primeiras decisoes, logo a uniao dos dois conjuntos e o
que interessa e nenhum dos dois sozinho esta completo.

**Consequencia pratica, que e' a mesma de antes mas maior:** a guarda contra
reutilizar um ID e' hoje o `IDS.md`, e ele tem 8 IDs que o indice nao ve. Se o
ledger se perder, `Get-ProximoId` devolve `D-073` (colisao com uma decisao
assinada pelo DELTA) e nada no `check` avisa. A linha nova que propus ao CMD -

```
reservas no ledger sem bloco em DECISOES.md : 8   ->  D-027, D-058..D-061, D-073..D-075
```

- e' a que denuncia isto em todas as passagens, e nao so quando alguem repara.
**Nao corrigi nada:** o `sync-agent.ps1`, o `IDS.md` e os cabecalhos sao do CMD
e do DELTA, nao meus.

## 10. Turno 5 (15:20-15:45) - O run 68 medido de dentro, e a minha premissa corrigida

**1) Errei a arvore antes de responder, e a correccao e' minha.** A primeira leitura
procurou `maintenance.yml` em `MQL5\` e nao o achou; a conclusao que estava a caminho do
canal ("nao reproduzivel daqui") era falsa. Ha DOIS repositorios nesta pasta de terminal:
`MQL5\` = repo `apolopanda500/mql5` (main 28b4ccee, so `ci.yml` + `codeql.yml`) e
`MQL5\Files\XAU_AI_PRO\` = repo `apolopanda500/XAU_AI_PRO` (develop de0f08f, arvore limpa,
com `maintenance.yml` e `tests/test_versao_consistente.py`). O run 68 e' do segundo.

**2) Todos os numeros do CMD conferem**, por medicao independente no repo da plataforma:
`origin/main:VERSION` = 1.2.9; `EA_VERSION_STRING "1.2.167"`; `#property version "1.367"`;
`develop` = 1.2.181 / 1.381 / 1.2.181; `git rev-list --left-right --count` = `25  9`;
`07abc4d` = HEAD de `origin/main` (merge PR #46); `ref:` na `main` so em comentario (L21,
L38, L43), na `develop` na L54.

**3) A frase "o cron testa a arvore errada" nao resiste ao proprio ficheiro.** O
`maintenance.yml` da `main` tem, nas L21-L43 e com data (05/11/2026) e run (41954293907),
a decisao escrita de viver SEM `ref:` para medir exactamente o que embarca, e conclui que
"a correcao certa NAO e recolocar `ref:` aqui: e mergear a default na `develop`". O run 68
testou a arvore certa e achou incoerencia REAL nela. Isto inverte o sentido da opcao A.

**4) As tres falhas sao dois defeitos, e ambos ja estao corrigidos na `develop`.**

| falha | causa medida | correccao na develop |
|---|---|---|
| `test_property_version_do_ea` | `VERSION` da `main` = 1.2.9 contra o proprio EA em 1.2.167 | `VERSION` 1.2.181 + `formula = major.minor*100+patch` (patch >= 100) |
| `test_ea_version_string_do_version_manager` | o mesmo `VERSION` para tras | idem |
| `test_print_de_versao_do_log` | a regex da `main` aceita so `" + EA_VERSION_STRING`, e o EA usa a lista de argumentos (`Print("[START] XAU_AI_PRO v", EA_VERSION_STRING, ...)`, L967) | regex `(?:\+|,)` desde 07/11 |

Diff total do teste entre as duas branches: **+13 / -1**. O item 3 do relato do CMD
("o .mq5 nao tem `[START] XAU_AI_PRO v...`") e' falso: tem, na L967.

**5) Verdito e janela.** A (repor `ref: develop`) repoe um erro datado e esconde o defeito;
C fabrique coerencia; B e' a unica que mantem o check com sentido, mas o merge e' do DONO
(25 commits so na `main` contra 9 so na `develop`); D e' o backport barato do teste + o
`VERSION`, se o B nao couber hoje. Nao assinei nenhuma: medi e disse o que cada uma faz.

**6) Lacunas declaradas.** Nao vi o log do run 68 (log de Actions exige token; nao ha
credencial nesta sessao e nao a procurei) — a decomposicao acima vem da leitura do codigo
das duas branches, nao do log. Nao decidi a direccao nem autorizo o merge. Nao sei se a
`main` e' o que embarca na pratica: o `VERSION` dela diz 1.2.9 enquanto o EA a correr no
terminal e' 1.2.183 — isso e' pergunta de produto para o DONO, nao medida minha.

**7) Estado.** Zero compiles neste turno; `XAU_AI_PRO.ex5` 964.160 B, mtime 07/11 14:36,
MD5 `EDC7597D3D71FD2B1ED1A45AEE0178A1`; `check` do canal OK (37 ficheiros, 67 IDs usados,
68 no ledger, 18 perguntas).
