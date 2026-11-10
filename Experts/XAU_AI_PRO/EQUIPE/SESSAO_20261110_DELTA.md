# DELTA - SESSAO D-149 | 10/11/2026 04:00 local (09:00 servidor)

> **Numeracao declarada:** este trabalho e' o **D-149**. O numero **D-148 ja
> estava ocupado** pelo ALFA (registado em `DECISOES.md` linha 6781 e em
> `IDS.md` com a etiqueta `04:05`, G5 medido no run de controlo
> `7706413661306435354`). Pela precedencia ja usada na colisao do D-145 (quem
> registou primeiro fica com o numero), o trabalho do DELTA passa a **D-149** e
> a colisao fica declarada em **P1.3521**. O corpo abaixo foi redigido antes de
> eu saber da colisao e chama-se a si mesmo "D-148"; foi renumerado para D-149
> na integra, sem alterar um unico numero medido.

> **Correcao declarada a uma leitura minha (secao 8 do corpo):** o `LOCK.md` do
> ALFA **nao estava obsoleto nem eterno**. Estava ocupado legitimamente pelo run
> de controlo do G5 e a minha primeira leitura apenas nao via TTL porque o
> ficheiro tinha sido escrito a mao. Factos medidos, uteis para quem repetir:
> `03:48` e `03:50` -> `RECUSADO: LOCK.md ocupado :: ALFA ... :: so o dono
> liberta` (exit 2, duas vezes, sem contorno e sem `-Force`); **`03:54:02` ->
> `OK lock :: DELTA ... expira 04:09:02`** (o ALFA tinha chegado ao fim do
> trabalho); `03:55:15` -> `LOCK.md` reescrito pelo `unlock` do ALFA para
> `ESTADO: LIVRE | Ultimo dono: ALFA | Libertado: 03:55:15`, **sobrepondo-se ao
> meu lock** porque o ficheiro nao guarda a fila de donos; **`03:55:25` ->
> `OK lock :: DELTA ... expira 04:10:25`**, com o qual escrevi esta sessao.
> O defeito de fundo que fica registado (nao corrigido por mim, o script e' do
> CMD): **uma libertacao pode apagar um lock tomado depois dela** - o
> `Remove-Lock` compara o dono com a linha actual do ficheiro e nao com o
> instante da aquisicao.

# DELTA - MEDICAO D-149 (proposta) - 10/11/2026 03:50 local (08:50 servidor)

Escrito em `MQL5\Files\Temp\` porque o canal `EQUIPE\` esta bloqueado por LOCK
obsoleto do ALFA (ver secao 8). Nada foi escrito no canal.

## 1. RESTART DO TERMINAL AS 03:43:38 - fato medido

Cadeia de prova (journal do terminal, `Logs\20261110.log`):

```
02:23:40.356 Terminal  MetaTrader 5 x64 build 6314 started
02:26:48.421 Terminal  exit with code 0
02:26:53.718 Terminal  shutdown with 0
02:29:51.360 Terminal  MetaTrader 5 x64 build 6314 started
02:35:09.592 Terminal  exit with code 0
02:35:15.308 Terminal  shutdown with 0
02:35:33.252 Terminal  MetaTrader 5 x64 build 6314 started
03:00:46.789 127.0.0.1 list of charts requested     <- ultimo evento da sessao
03:43:38.738 Terminal  MetaTrader 5 x64 build 6314 started
03:43:38.752 MCP       started on 127.0.0.1:9001
```

Os tres reinicios anteriores tem `exit with code 0` + `shutdown with 0`. Antes do
`03:43:38` **nao existe nenhuma linha de fecho**. Ultimo sinal de vida do EA
(`MQL5\Logs\20261110.log`): `03:33:14.196 [CENARIO] USDJPY`.

Conclusao: a sessao anterior **morreu de forma anormal** na janela
`03:33:14` -> `03:43:38` (10 min 24 s), sem shutdown limpo. Nao foi reanexo de
EA nem recarga de perfil: foi o **processo do terminal** que caiu e foi relancado.
Os 15 EAs voltaram sozinhos (`expert XAU_AI_PRO (...) loaded successfully`
03:43:45.188 a 03:43:47.686) e imprimiram `[START]` as 03:43:48.326-397.

Binario em disco **nao** mudou: `977654 B`, `02:23:07`,
`MD5 71ED34C690C9593D209A69E95F0EFFB6` - igual ao declarado. O restart nao
tocou no `.ex5`.

## 2. IMPACTO NO G4 - re-ancoragem obrigatoria

GATE_REAL secao 7 diz `G4 | 15/15 [START] as 02:35:37.784-37.915 | 24 h |
11/11 02:35:37`. Esse uptime **acabou** as 03:33:14.

Novo ancora: **10/11 03:43:48** (primeiro `[START]` da vaga nova; carga dos EAs
03:43:45.188). G4 passa a fechar **11/11 03:43:48**, ou seja +1 h 08 min.

Prova adicional do reinicio do relogio:
`03:44:21.006 XAU_AI_PRO (XAUUSD,H1) [HEALTH] HEALTHY | uptime=32s | checks=0`
(32 s de uptime as 03:44:21 -> init ~03:43:49).

Nao e falha de gate: e recontagem. O estado sobreviveu
(`[SESSION] estado salvo | pico=12660.19`, persistencia ON).

## 3. IMPACTO NO FORWARD (G11) - nenhum

A janela ancora em **11/11 00:05 servidor = 10/11 19:05 local**. O restart foi as
03:43 local de 10/11, **15 h 22 min antes** da abertura. Continua **0 de 30**.

Risco aberto: o terminal ja caiu uma vez sem shutdown limpo. Se cair **dentro**
da janela, os 30 dias voltam a zero (D-147). O disco tem **3944 MB livres**
(`terminal_get_info`) e o journal diz `3 / 222 Gb disk` - folga baixa para 30
dias de logs, snapshots de backup e tester.

## 4. FUNIL MEDIDO COM MERCADO ABERTO (sessao nova, 03:43:45 -> 03:48:03)

`[SCANNER] RESUMO | visitas=38 | sinais=0 | trades=0 | bloqueios=38 |
Stale=11 NoSignal=27 | ADX(sem/ok)=1/114 | SIG(sem/neutro)=0/22`

Contagens no ficheiro de Experts do dia (1401 linhas):

| Tag | Contagem |
|---|---|
| `[START] XAU_AI_PRO` | 75 (5 vagas de 15: 02:23:40, 02:29:51, 02:35:33, 03:43:38 + 1 anterior) |
| `[SCORE]` | **1** (01:00:00.281 - unica do dia) |
| `[AI] PYTHON` | 9 |
| `[AI] INDISPONIVEL` | 59 (15 simbolos, 4 cada; EURUSD 3 - fora da lista `Symbols`) |
| `TREND CONTRA OK` | 15 |
| `BLOCK | ADX` | 15 |
| `[CENARIO] RETRATO` | 2 |
| `GATEWAY | HTTP 1003` | 20 |
| `GATEWAY RECUPERADO` | 19 |
| `COTACAO VELHA` | 28 |

`ADX(sem/ok)=1/114` corrige a leitura do D-146 (que via 1879 de 2131 barras sem
leitura): com o binario `71ED34C6` o ADX esta **a ler**. A escassez de sinal nao
vem de falta de ADX.

## 5. ACHADO NOVO - o que mata o sinal hoje (dois bloqueios independentes)

### 5.1 A IA responde, mas o `edge` fica abaixo do minimo em todos os simbolos

```
03:46:09.652 [AI] INDISPONIVEL | AUDUSD | MOTIVO=edge -0.0184 abaixo do minimo +0.0500 (acc 0.3418 vs palpite 0.3602)
03:46:09.740 [AI] INDISPONIVEL | USDCAD | MOTIVO=edge +0.0317 abaixo do minimo +0.0500 (acc 0.3752 vs palpite 0.3435)
03:46:09.843 [AI] INDISPONIVEL | NZDUSD | MOTIVO=edge +0.0225 abaixo do minimo +0.0500 (acc 0.3758 vs palpite 0.3533)
... 15 simbolos, todos com edge entre -0.1256 e +0.0317 contra piso +0.0500
```

O gateway **esta a responder** (`resposta=357B`, `[AI] GATEWAY RECUPERADO`), o
modelo devolve probabilidade, e a margem `acc - palpite` nao chega a **+0.0500**
em **nenhum** dos 15 simbolos. Este bloqueio **nao estava** no inventario de
filtros conhecidos (TREND CONTRA, AVOID HOURS, MinMarketScore, ADX) e explica
`NoSignal=27` melhor que qualquer um deles.

### 5.2 Onde a IA da sinal, o ADX corta

```
03:46:25.324 [SCANNER] SIGNAL OK | XAUUSD | Signal=-1
03:46:25.344 [VALIDATION] TREND CONTRA OK | XAUUSD | Signal=-1 | contramao PERMITIDA | cenario LATERAL | ADX=16.3 | lote x0.75
03:46:25.346 [VALIDATION] XAUUSD | ADX=16.30 | Min=18.00
03:46:25.348 [VALIDATION] BLOCK | ADX | XAUUSD
```

**TREND CONTRA nao bloqueia** o XAUUSD neste estado: em cenario `LATERAL` a
contramao e **PERMITIDA** (15 ocorrencias, todas `OK`). O que bloqueia e o
**ADX 16.30 < 18.00** - 15 de 15 bloqueios de ADX do dia sao XAUUSD.

Ou seja: dos 15 simbolos, 14 morrem no `edge`; o unico com sinal (XAUUSD) morre
no ADX. Zero trades nao e o EA mudo - e o produto de dois pisos.

## 6. `[SCORE]` - P1.3476: `PTS=` saiu, mas o `TOTAL` nao e o que se esperava

Amostra unica do dia:

```
01:00:00.281 [SCORE] CALCULATED | Symbol=XAUUSD | Signal=1 | EMA=20.00 | RSI=0.00 |
            ADX=0.00 | AI=50.00 | WARMUP=SIM | PTS=70.00 | TOTAL=79.89
```

Duas conclusoes, ambas por leitura de fonte (`Core\DecisionEngine.mqh`):

1. **`PTS=` saiu pela primeira vez** (o P1.138/P1.3476 dizia "0 amostras"). O
   emissor funciona: `:533 if(logOnce && DecisionLogDue(symbol,"SCORE",900))`.
2. **`TOTAL` nao e `100*PTS/115`.** A formula existe e e essa (`:471-477`
   `score = 100.0*score/maxScorePoints`, `maxScorePoints=115.0`), mas logo a
   seguir `:505 MarketScore=NormalizeDouble(learnedScore,2)` **substitui** o
   valor pelo score ajustado pelo aprendizado. Conferencia:
   `100*70/115 = 60.87`; com boost `1.3125` -> `79.89`. O `TOTAL` do journal e
   **pos-aprendizado**, nao pos-normalizacao.

   Isto importa porque qualquer teste futuro que exija
   `TOTAL == 100*PTS/115` da **falso alarme**. O teste correto e
   `TOTAL == 100*PTS/115 * fator_aprendizado`.

3. Consequencia pratica: `60.87 < MinMarketScore 65.0` - o sinal do XAUUSD as
   01:00 so passaria do piso de score **por causa do boost de aprendizado**
   (1.3125). Sem aprendizado, o piso de 65.0 barrava-o.

4. Limite da amostra: `WARMUP=SIM`, `RSI=0.00`, `ADX=0.00`, `AI=50.00`. E uma
   amostra de aquecimento, com indicadores neutros. **Nao prova** a escala com
   dados reais. E 1 amostra em 8 h de journal: a taxa de emissao continua baixa
   (1 por dia, nao 1 por 15 min como o `900` sugere) - o `logOnce` e o
   gargalo, nao o `DecisionLogDue`.

## 7. MANUAL vs EA - separado

`get_trading_history_positions` 10/11 00:00-04:00 (hora de servidor):

| # | Simbolo | Tipo | Vol | Abre | Fecha | Preco | Motivo fecho | Lucro | Magic | Origem |
|---|---|---|---|---|---|---|---|---|---|---|
| 11313726232 | XAUUSD | buy | 0.03 | 03:27:34 | 04:34:24 | 4139.88 -> 4115.54 | Expert | **-73.02** | 2026001 | Expert |
| 11314553174 | XAUUSD | buy | 0.03 | 04:45:54 | 05:18:38 | 4113.20 -> 4113.20 | Stop loss | 0.00 | 2026001 | Expert |
| 11315217666 | XAUUSD | buy | 0.03 | 06:00:00 | 06:19:45 | 4111.07 -> 4114.81 | Expert | **+11.22** | 2026001 | Expert |

- **3 trades, todos do EA** (magic `2026001`, `open_reason=Expert`, comentario
  `XAU_AI_PRO`). **0 manuais** (magic 0).
- Liquido **-61.80 USD**, que e exatamente o `dia fechado: -61.80` do
  `[RESUMO]`. Contabilidade fecha.
- 1 loss / 1 breakeven / 1 win. Todos BUY XAUUSD 0.03.
- Conta demo 113568614: balance = equity = **12593.83 USD**, 0 posicoes,
  0 ordens, sem exposicao.
- Pico registado `12660.19` -> drawdown atual **-0.52%** (limite 6.0%).
- Perda diaria -61.80 = **16%** do orcamento efetivo de 379.67 USD (limite
  nominal 600.0 / 3.0%).

Nota: o EA **opera**. O `trades=0` dos `[RESUMO]` e do dia-de-servidor em curso
desde as 19:05 local; os 3 trades acima sao do mesmo dia de servidor.

## 8. BLOQUEIO DO CANAL - LOCK obsoleto sem TTL

`equipe-sync.ps1 lock -De DELTA` devolveu:

```
RECUSADO: LOCK.md ocupado :: ALFA | G5 control run 7706413661306435354 |
ALFA_G5_12M_STALE0.ini + ALFA_G5_D_STALE0.set | EnableStaleDataGuard=false |
so o dono liberta
```

O lock esta **obsoleto e nao expira**:

- O proprio `LOCK.md` diz na `Nota`: "O LOCK esteve LIVRE das 02:44 as 02:46 e
  das 02:52 em diante com o run a correr".
- O `SYNC_LOG` (D-145) regista a libertacao as 02:53.
- O testador esta **parado**: `tester_get_status` -> `{"tester_status":
  "stopped","run_id":"0"}`; o run `7706413661306435354` ja nao existe.
- **Causa raiz**: o ficheiro foi escrito **a mao**, nao pelo `Set-Lock`. O
  script grava `- Tomado:`, `- Expira:` e `- TTL: 15 min`; este ficheiro tem
  `- Adquirido:`, `- ETA:` e `- Nota:`. `Get-LockMd` (linhas 96-116) devolve
  `$null` so quando `Expira` ja passou; **sem `Expira`, o lock e eterno**.

Nao contornei a guarda: nao editei `LOCK.md`, nao usei `-Force`, nao escrevi em
`EQUIPE\`. `unlock` tambem recusa (nao sou o dono).

**Pedido**: o ALFA (ou o DONO) corre
`tools\equipe-sync.ps1 unlock -De ALFA`. Correcao de fundo sugerida: `Get-LockMd`
devolver `$null` tambem quando faltar `- Expira:` (lock sem TTL = invalido) ou
aplicar TTL por omissao de 15 min a partir de `- Adquirido:`.

## 9. Riscos e observacoes laterais

1. **Queda anormal do terminal** (03:33:14 -> 03:43:38) sem shutdown limpo.
   Nao ha dumps dentro das raizes lidas. Agrava: disco com 3944 MB livres,
   `retransmit_percent=4.23`, `ping=219317 us`.
2. **4 simbolos com cotacao velha** (P2.25 vivo): USDRUB 56944 s, USDCLP
   48030 s, USDCOP 45907 s, USDBRL 35060 s, contra `MaxSymbolTickAgeSec=900`.
   `Stale=11` no resumo.
3. **Gateway instavel 1:1**: 20 `HTTP 1003` contra 19 `RECUPERADO`. Bate com o
   D-144 (22/22). Nao ha falha sistemica, mas ha 1 pendente as 03:48:03
   (XAUUSD e USDCNH).
4. **`EURUSD` aparece em `[AI] INDISPONIVEL`** (3x) mas **nao** esta em
   `Symbols` (15 simbolos, sem EURUSD). Algo fora do universo pede predicao.
5. **19 graficos abertos**: 15 com EA (`chart01`-`chart15`) + 4 XAUUSD sem EA
   (`chart16`-`chart19`, `scroll_mode=false`). Ruido no perfil
   `XAU_AI_PRO_15CHARTS_Q071`; nao afeta medicao.
6. `[ATR] IDENTIDADE ... serie impossivel descartada` para USDCLP
   (ATR% 13.55), USDCOP (1555.89), USDBRL (1727.31) as 03:26 - guarda a
   funcionar, series corrompidas descartadas.

## 10. Estado dos gates apos esta medicao

| Gate | Antes | Agora | Nota |
|---|---|---|---|
| G4 | VERMELHO, fecha 11/11 02:35:37 | VERMELHO, **re-ancorado 11/11 03:43:48** | restart 03:43:38 |
| G5 | VERMELHO (~2,8 trades/12M) | VERMELHO, **causa dupla identificada** | `edge<0.05` em 15/15 + `ADX 16.30<18` no XAUUSD |
| G11 | 0/30, janela 11/11 00:05 | **0/30 inalterado** | restart antes da abertura |
| G10 | 15 simbolos no perfil | inalterado | falta Market Watch 25->15 (DONO) |
| P1.3476 | `[SCORE]` mudo, 0 amostras `PTS=` | **parcialmente fechado** | `PTS=70.00` saiu; `TOTAL` e pos-aprendizado |

Nenhum gate muda de cor por declaracao. G4 re-ancorado e fato medido, nao
concessao.

---

## ADENDA D-149 - o que foi medido depois do relatorio acima

Tudo nesta adenda foi medido entre **03:54:02** e **04:00** local, com mercado
aberto, em modo leitura. Nenhuma recompilacao, nenhum deploy, nenhum reinicio,
nenhuma mudanca de input e nenhuma ordem: o congelamento do D-147 fica intacto.

### A.1 Funil da vaga nova (03:43:48 -> 03:54:00, 10 min 12 s)

Ancora de segmento: `MQL5\Logs\20261110.log` linha **1223** (`03:43:48.326`,
`[START] XAU_AI_PRO v1.2.191 | conta=113568614 ... simbolo=AUDUSD`), ate ao fim
do ficheiro (1406 linhas, ultima `03:54:00.474`). Contagens exactas:

| Item | Valor |
|---|---|
| `[START]` | **15** (frota completa, 0 erros) |
| `[CENARIO] RETRATO` | **1** |
| `[SCANNER] RESUMO` | **1** |
| `[AI] PYTHON` | **0** |
| `[AI] INDISPONIVEL` | **14** |
| edge dos 14 (`MOTIVO=edge X abaixo do minimo +0.0500`) | n=14, **min -0.1256, max +0.0317** |
| `[SIGNAL] SIGNAL OK` | **1** (XAUUSD, `Signal=-1`) |
| `[SIGNAL] NEUTRO` / `SEM LEITURA` | 2 / 1 |
| `[VALIDATION] TREND CONTRA OK` | **1** |
| `[VALIDATION] BLOCK` por motivo | **ADX=1** |
| `DECISION BLOCKED` | **0** |
| `TRADE EXECUTADO` | **0** |
| `[SCORE] CALCULATED` | **0** |
| `GATEWAY RECUPERADO` | **1** (03:46:09.645, AUDUSD, `falhas=64 cego=133s resposta=357B`) |
| `HTTP 1003` / `HTTP 1001` | **2** / **3** |

Leitura: **o gargalo da vaga nova e' o mesmo par do D-148 e esta' medido em
minutos, nao em horas.** (1) a IA responde a 14 de 15 simbolos, mas **todos os
14 ficam abaixo do piso de edge +0.0500** (max +0.0317, a 0.018 do piso) - o
gateway devolve `available=false` e o EA fica sem sinal nesses simbolos;
(2) o unico simbolo com sinal e' o XAUUSD e morre uma vez no `ADX 16.30 < 18.00`.
O `TREND CONTRA` **nao** e' culpado: em cenario LATERAL a contramao e'
`PERMITIDA` e o bloco `TREND CONTRA OK` saiu.

### A.2 A origem do piso de edge +0.0500 e' o GATEWAY, nao o EA

Cadeia fechada por leitura de codigo (sem tocar em nada):

- o EA **nao tem** constante de piso de edge. `findstr` em todos os `.mq5`/`.mqh`
  da arvore (excluindo `Files\`, `Backup\`) devolve a string `edge ... abaixo do
  minimo +0.0500 (acc ... vs palpite ...)` **apenas** em `Enterprise\VersionManager.mqh`,
  no texto de historico da v1.2.141, que a descreve como **`reason` devolvida
  pelo endpoint de walk-forward**;
- o unico emissor em runtime e' `AI\AIConnector.mqh:478/480`
  (`"[AI] INDISPONIVEL | " + simbolo + " | MOTIVO=" + reason`) - o EA **reimprime
  a `reason`** que recebeu;
- o payload do gateway e' lido em `prob_buy`/`prob_sell` **0..1** e convertido
  para **0..100** dentro do EA (`AIConnector.mqh` ~470).

**Consequencia para o G5 (decisao do DONO, nao do DELTA):** desbloquear o
`NoSignal` **nao se faz no EA** - o EA esta' congelado por D-147 e nao tem nada
para mudar. Ou se baixa o piso `+0.0500` no gateway/modelo, ou se publica modelo
para os outros 14 simbolos, ou se aceita que o forward mede **1 simbolo e 1
modelo** (o que o G11 ja declara desde o D-143). As tres hipoteses sao de
propriedade do CMD/DONO.

### A.3 `[RESUMO] dia fechado: -61.80 de 40.00 USD (-154%)` NAO e' violacao de risco

Lido em `Monitoring\OperatorBrief.mqh:143` e `:101-104`: o segundo numero do
campo e' **`meta = OperatorBriefDailyTarget()`**, a **meta diaria de lucro**, e
`pctMeta = realizado / meta * 100`. Portanto `-61.80 de 40.00 USD (-154%)`
significa "**-61.80 realizado contra uma meta de +40.00**", e **nao** "perda de
61.80 contra um orcamento de 40.00". O orcamento de risco continua a ser
`MaxDailyLossUsd=600.0` (perfil vivo): 61.80 = **10.3%** do travão, sem
accionamento. Fica escrito porque a linha, lida a correr, parece um guarda de
risco violado por 154%.

### A.4 URLs `symbol=` cruzadas no journal: explicado, nao e' defeito

`03:48:59.681` e `03:54:00.474` saem com `source = XAU_AI_PRO (GBPUSD,H1)` mas
com `symbol=XAUUSD` e `symbol=USDCZK` no URL. Nao e' corrupcao de estado: o
`[RESUMO]` das `03:49:20.015` tem `master=SIM` e vem **do grafico GBPUSD,H1**,
logo o **master e' o GBPUSD** e o pipeline do master percorre os 15 simbolos,
pedindo a IA por simbolo. As linhas de `03:48:03` (fonte XAUUSD -> `symbol=XAUUSD`,
fonte USDCNH -> `symbol=USDCNH`) sao as instancias nao-master a pedir o proprio
simbolo. **Duas origens, dois donos, nenhum cruzamento**.

### A.5 O que isto faz aos gates

| Gate | Antes (D-147) | Depois (D-149) | Nota |
|---|---|---|---|
| **G4** | fecha 11/11 **02:35:37** | fecha 11/11 **03:43:48** | reancorado: a vaga anterior morreu entre 03:33:14 e 03:43:38 sem `shutdown`; 15/15 `[START]` as 03:43:48.326-48.7xx. **Nao e' falha, e' recontagem** (+1 h 08 no fecho) |
| **G11** | 0/30 | **0/30 intacto** | janela abre 11/11 00:05 servidor = 10/11 19:05 local, **15 h 05 min** depois de agora; binario em disco inalterado (`71ED34C6`, 977 654 B, 02:23:07) |
| **G5** | VERMELHO (12.26/12M) | VERMELHO, com **causa dupla medida** | (a) edge < +0.0500 em **14 de 14** respostas; (b) XAUUSD morre no ADX 16.30 < 18 |
| **G3** | verde com ressalvas | verde com ressalvas | a IA responde em producao (`resposta=357B`, `available` calculado), mas **14/14 abaixo do piso** |
| **G2** | falta prova de reboot | falta prova de reboot | o gateway esteve no ar a vaga toda: 5 falhas de transporte (1003/1001) e **1 recuperacao sem intervencao** |
| **G10** | 25 -> 15 no Market Watch | igual | continua a esperar **1 clique do DONO** |

### A.6 Nada foi tocado

Sem recompilacao, sem deploy, sem reinicio do terminal, sem mudanca de inputs no
perfil vivo `XAU_AI_PRO_15CHARTS_Q071`, sem tocar em graficos, sem ordem e sem
parametro de risco. Este D e' **leitura de log e de codigo**. O `LOCK.md` do
canal foi tomado e sera' libertado no fim.

### A.7 Horarios do LOCK: derivados do `expira`, com a deriva de relogio medida em menos de 1 minuto

O `equipe-sync.ps1` imprime a hora de aquisicao/libertacao pelo relogio do
processo. Medido em 10/11 tendo o journal do terminal como referencia
(`get_terminal_journal` carimba as minhas proprias chamadas MCP): as chamadas das
`03:57:33` e `03:57:51` locais sao coerentes com o `OK unlock :: DELTA | 03:57`
emitido logo a seguir. **A deriva e' de menos de 1 minuto** - uma versao
anterior desta adenda dizia "~6 min" e **essa leitura era minha, nao medida**:
vinha de eu ter comparado o carimbo do script com uma hora de relogio que eu
tinha estimado, e nao lido.

Os horarios desta sessao foram reconstruidos a partir do unico campo absoluto
que o script imprime, o `expira` (TTL de 15 min), porque a aquisicao nao sai
carimbada por extenso:

| Evento | Saida do script | Hora derivada |
|---|---|---|
| 1a aquisicao do DELTA | `expira 10/11/2026 04:09:02` | **03:54:02** |
| 2a aquisicao do DELTA | `expira 10/11/2026 04:10:25` | **03:55:25** |
| `unlock -De ALFA` (reescreveu o ficheiro para LIVRE) | `Libertado: 03:55:15` no `LOCK.md` | **03:55:15** |
| 3a aquisicao (a desta escrita) | `expira 10/11/2026 04:12:19` | **03:57:19** |

O que continua a valer, e nao e' deriva de relogio: o `LOCK.md` **nao guarda a
fila de donos**, e o `unlock -De ALFA` das **03:55:15** reescreveu para `LIVRE`
um lock que o DELTA tinha tomado as **03:54:02** (**P2.26**).

Nota de honestidade sobre os titulos: este D esta datado `04:00 local` por
arredondamento; a medicao fechou as **03:58 local / 08:58 servidor**.

## A.8 - D-152 (renumeracao) e G10 fechado - 10/11 04:20

**1. O numero.** Este trabalho estava escrito como **D-151** e passou a **D-152**.
O ALFA registou `## D-151 | ALFA | 2026-11-10 04:12` (G10) antes das 04:15 em que o
bloco do DELTA foi escrito. Precedencia do D-145: **quem registou primeiro fica
com o numero**. Corrigidos `DECISOES.md` (cabecalho + seccao 7), `IDS.md`,
`SYNC_LOG.md` (3 linhas) e `PEDIDO_CMD_D151_PISO_EDGE.md` (H1 + nota de
numeracao). O ficheiro do pedido **nao** foi renomeado: o nome e' ponteiro
publicado no `SYNC_LOG` e renomear quebrava a referencia. Colisao em **P1.3523**,
com a regra preventiva ja escrita: reservar o numero em `IDS.md` antes de
escrever o bloco.

**2. A lacuna do G10 que dependia do Market Watch fechou - e eu verifiquei.** Medicao propria as 09:08 hora do servidor:
`get_marketwatch_symbols` devolve **15** simbolos, todos `selected=true` -
GBPUSD, USDCHF, USDJPY, USDCNH, AUDUSD, NZDUSD, USDCAD, USDSEK, XAUUSD, USDBRL,
USDCLP, USDCOP, USDCZK, USDRUB, USDSGD. E' exactamente o input `Symbols=15` e os
15 graficos com EA. **Divergencia zero.** A lacuna que mantinha o G10 vermelho
desde o D-120 de 08/11 era o Market Watch com 25 simbolos; hoje tem 15.

**3. O G10 NAO passa a verde: duas das tres clausulas provadas, uma nao.** Fechar o G10 e' higiene de universo: o
EA nunca leu o Market Watch (`SymbolsFromMarketWatch=false`), logo o G10 nao muda
um unico sinal. O que continua aberto e' o que mexe no dinheiro: o **piso de
edge** (`0.02`, D-152, pedido ao CMD), o **G11 a 0/30** e a **P1.3522** (5
simbolos a 0.5% = **2.5% de exposicao simultanea** no pior caso, contra 0.5% hoje).

**3b. O que fica provado e o que nao fica.** Provado: `Symbols=15` = **15 graficos
com EA, um simbolo cada** = **15 no Market Watch**, todos `selected=true` as
09:08 servidor - divergencia zero. **Nao provado:** o criterio exige *todos com
modelo publicado* e o universo tem **15 simbolos com 1 modelo** (so' XAUUSD,
**P1.3519**); `edge` calculado (**P2.27**) nao e' modelo publicado. **Residual
novo:** 19 graficos abertos = 15 com EA + **4 XAUUSD sem EA** (`CHART16`-`CHART19`,
zero indicadores) -> **P1.3524**. Por isso o G10 **nao** vira verde hoje: fica
**2 de 3 clausulas** provadas.

**4. Nada foi tocado por mim.** Sem recompilacao, sem deploy, sem reinicio, sem
inputs, sem ordem. O congelamento do D-147 continua de pe. Binario unico em
memoria: `71ED34C690C9593D209A69E95F0EFFB6` (977 654 B, 10/11 02:23:07).

**5. O que falta e nao e' meu.** O piso `0.02` e' do **CMD** e tem de estar
aplicado e declarado **antes de 11/11 00:05 servidor**. Sem isso, a janela do
G11 abre com o piso `+0.0500` e o universo operavel fica no **1 simbolo** de
hoje - o que muda o que os 30 dias medem. Nao e' papel: e' a diferenca entre
medir 1 ou 5 simbolos.
