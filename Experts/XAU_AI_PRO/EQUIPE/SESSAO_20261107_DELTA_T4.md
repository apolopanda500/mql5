# SESSAO 07/11/2026 - DELTA (turno 4): auditoria da v1.2.185 e da "leitura de IA real"

**Papel:** DELTA (mede e assina; nao escreve codigo). **Janela:** 07/11/2026
19:00 -> 19:20. **Disciplina do turno:** 0 compiles, 0 reattach, 0 ordens, 0
linhas de fonte alteradas, 0 parametros de risco tocados, 0 escritas fora do
canal. Leitura de ficheiros, de journal e do .ex5 apenas.

**ID desta auditoria:** **D-086**.

---

## 1. Veredicto em uma linha

O que o operador reclamou **e verdadeiro e foi reproduzido ao byte** - binario,
identidade, reattach, leitura de IA e ausencia de rasto do token. Mas a frase
**"uma leitura real 72,40 >= 65,0"** compara **duas escalas diferentes** e tem de
sair: 72,40 e **confianca de IA**; 65,0 e um piso sobre **MarketScore**. A
comparacao que o codigo faz e `74,96 >= 65,00` (sinal completo, com a parcela de
IA) e `43,48 < 65,00` (o mesmo sinal sem a parcela de IA). **Nada disto e um verde
novo:** GATE_REAL continua **2 de 11**.

---

## 2. Verificacao item a item (reclamado -> medido)

| Item reclamado | Como medi | Resultado |
|---|---|---|
| `.ex5` 964 998 B, 18:56:31, MD5 `146BB7FC...C419E` | `Get-FileHash -Algorithm MD5` + `Get-ChildItem` | **CONFIRMADO**: 964 998 B, 07/11 18:56:31, MD5 `146BB7FCE9E977E88A49A3AE007C419E` |
| `#property 1.385` | `Select-String` em `*.mq5/*.mqh` | **CONFIRMADO**: `XAU_AI_PRO.mq5:22` |
| `EA_VERSION_STRING 1.2.185` | idem | **CONFIRMADO**: `Enterprise/VersionManager.mqh:14` |
| changelog v1.2.185 | idem | **CONFIRMADO**: `m_current.changes = "v1.2.185 (07/11/2026) - Q-079 = B ..."` |
| Compile 0 errors / 0 warnings | `get_expert_advisor_parameters` no `.ex5` | **CONFIRMADO indirecto**: binario valido, `version "1.385"`, `build_time 2026-11-07T21:56:31Z`, `compiler_build 6308`, 323 parametros |
| `ScenarioTrendAtrSlack = 1.0` no codigo | leitura de fonte + parametros do binario | **CONFIRMADO**: `Core/Config.mqh:1515` (input) e parametro **#227** do `.ex5` com `default_value "1.0"` |
| Portao com folga, guarda intacta | leitura `Filters/MarketScenario.mqh:199-222` | **CONFIRMADO**: ver §4 |
| Reattach 15/15 em v1.2.185 as 18:58:30 | `get_expert_journal` filtro `[START]` | **CONFIRMADO**: 15 linhas `[START] XAU_AI_PRO v1.2.185` |
| IA real em XAUUSD, 1123 B, `disponivel=true` | `get_expert_journal` filtro `GATEWAY` | **CONFIRMADO**: 15 linhas as **18:59:02**, XAUUSD `1123 bytes \| disponivel=true`, 14 simbolos `357 bytes \| disponivel=false` |
| `[AI] PYTHON XAUUSD SELL BUY 27.65 SELL 72.35 SCORE 72.40` | idem | **CONFIRMADO** (27,65 + 72,35 = 100,00; SCORE = CONF = 72,40) |
| `[CENARIO] = 0` e `[VALIDATION] BLOCK = 0` pos-arranque | `get_expert_journal` filtros `CENARIO` e `VALIDATION` | **CONFIRMADO**: 0 registos em ambos, 18:57->19:06 |
| Journal sem `Bearer` / sem o token | `get_expert_journal` filtro `Bearer` | **CONFIRMADO**: 0 registos |
| Conta plana | `get_trading_open_positions` + `terminal_get_info` | **CONFIRMADO**: 0 posicoes, 0 ordens; `last_authorized_at 2026-11-07T21:58:29Z` (=18:58:29 local), conexao `synchronized` |
| Risco intocado | parametros do binario | **CONFIRMADO**: `MinMarketScore 65.0` (#189), `MagicNumber 2026001` (#1), `MaxDailyLossPercent 10.0` (#13), `MaxDailyLossUsd 60.0` (#14), `MaxDrawdownPercent 50.0` (#15), `EnableAdaptiveTrendGate true` (#222) |

Nada do que o operador afirmou falhou. Duas frases do relatorio precisam de
correcao - nao de facto, de escala (§3) e de alcance (§5).

---

## 3. A contradicao 9001 vs 9011 - resolvida, e a minha suspeita anterior morre

O relatorio diz "gateway 9011 vivo (pid 13276)" e **todos** os graficos tem no
input `AIGatewayUrl = http://127.0.0.1:9001/api/ai/predict`. Nao ha contradicao:

1. `MQL5\Files\XAU_AI_PRO\.env` declara `XAU_GATEWAY_PORT = 9011` (4 caracteres) e
   `XAU_GATEWAY_TOKEN` com **64** caracteres (valor lido com mascara; nunca
   impresso).
2. `AIGatewayPortaEnv()` (`AI/AIConnector.mqh:891-941`) abre
   `XAU_AI_PRO\.env` e so aceita a porta se **todos** os caracteres forem digitos.
3. `AIGatewayUrlEfetiva()` (`AI/AIConnector.mqh:942-966`) **substitui a porta** da
   URL do input, mantendo esquema, host, rota e placeholders.

O input guardado em 9001 e o **eco do anexo**: o MT5 guarda as entradas com que o
grafico foi anexado e elas ganham a omissao do codigo. Isto e exactamente o
desenho do **P-01d (v1.2.134)**. O EA chamou **9011**.

Prova adicional pelo **payload**, que nao depende de confiar no input nem no
relatorio: a resposta traz o contrato do gateway Python
(`available`, `signal`, `confidence`, `prob_buy/prob_sell`, `edge`, `accuracy`,
`model`) e o texto de recusa `edge -0.0207 abaixo do minimo +0.0500 (acc 0.3583
vs palpite 0.3790)`. O servidor em 9001 e o **MCP embutido do terminal** e
responde **401 a tudo** (medido em 04/11, P-01b). Um 200 com 1123 B de inferencia
nao pode vir de 9001.

**Regra que fica para o canal:** `input guardado != endereco efetivo`. Antes de
acusar contradicao de porta, ler `AIGatewayUrlEfetiva()` e o `.env`.

---

## 4. Achado principal (D-086): "72,40 >= 65,0" compara duas escalas

`CalculateMarketScore` (`Core/DecisionEngine.mqh:462-477`, v1.2.184/P1.138):

```
parcelas: 20 EMA + 15 RSI + 15 ADX + 10 KCI_dir + 5 KCI_vol + 50 IA(=0,50*confianca)
maxScorePoints = 115.0
scorePoints = score de parcelas brutas
MarketScore = 100.0 * scorePoints / 115.0      (limitado a 0..100)
```

O piso `MinMarketScore = 65.0` compara-se com **MarketScore** (0..100).

| Sinal | Parcelas | Pontos | MarketScore | Piso 65,00 |
|---|---|---|---|---|
| Completo (EMA+RSI+ADX+IA 72,40) | 20+15+15+36,20 | 86,20 | **74,96** | **passa** (+9,96) |
| Mesmo sinal **sem** parcela de IA | 20+15+15 | 50,00 | **43,48** | recusado (-21,52) |
| Fracos (ADX < minimo, RSI fora da banda) | ~30-40 | ~35-46 | 30-40 | recusado |

Portanto:

- **A confianca 72,40 nunca e comparada com 65,00.** Ela entra como
  `0,50 * 72,40 = 36,20` pontos de 115, ou seja **31,48 pontos na escala do piso**.
- A IA e **decisiva** para o piso: sem ela o sinal vale 43,48 e e recusado; com
  ela vale 74,96 e passa. Mas isso e uma conclusao **aritmetica sobre o codigo**,
  nao uma medicao de producao.
- Frase correcta a publicar: «a parcela de IA vale 31,48 dos 100 pontos do piso;
  sozinha nao chega, somada as parcelas tecnicas maximas leva o sinal a 74,96 e
  fai-lo passar 65,00».

**Consequencia dura:** o piso **continua sem uma unica amostra** em producao. Uma
leitura de sabado, um simbolo, mercado fechado, com `[SCORE]` = 0 linhas, nao
calibra nada. O "limite honesto" do proprio relatorio ja o dizia - e a frase dos
72,40 contradizia o seu proprio limite honesto.

**Regra que fica para o canal:** `confianca de IA != MarketScore`. Nunca comparar
uma com o outro sem passar por `100 * pontos / 115`.

---

## 5. A folga de 1 ATR: tamanho medido, escopo e limite

Codigo verificado (`Filters/MarketScenario.mqh:199-222`):

```
if(ScenarioTrendAtrSlack > 0.0)
   emaRef = GetTrendEMA(symbol); bidRef = SYMBOL_BID; atrRef = GetATR(symbol)
   if(EMA lida && bid>0 && atr>0):
      folga = ScenarioTrendAtrSlack * atrRef
      if(|bid - emaRef| <= folga) -> PERMITE, com reason "... | Q-079/B"
// sem leitura de EMA ou ATR -> o bloco NAO entra -> rigor antigo intacto
// acima da folga -> ADX (ScenarioCounterTrendMaxADX=22) + cenario como antes
```

Factos medidos:

- `GetATR()` devolve o ATR em **unidades de preco** (`Indicators/VolatilityFilter.mqh:597-651`,
  `NormalizeDouble(buf[0], symbolDigits)`), nao em percentagem. Logo
  `1,0 * ATR` e uma distancia de preco - a folga **nao e codigo morto**.
- Tamanho real hoje: ATR(14) H1 XAUUSD calculado sobre as 14 ultimas velas H1 de
  06/11 (`get_chart_history`): soma de TR = 236,10 -> **ATR = 16,86 USD**; a sonda
  de 05/11 leu **22,48 USD**. Ou seja **1 ATR = 17-22 USD = 0,42-0,55 % do preco
  (~4065)**.
- A folga e **simetrica** (`MathAbs`): isenta as duas direccoes. Um SELL com bid
  ate 1 ATR **acima** da EMA200 tambem passa. Q-079/B diz "contra-tendencia dentro
  de 1 ATR", logo esta dentro do pedido - mas o efeito e mais largo do que o
  defeito original descrito em D-079 (o pullback que **fura** a EMA200 por pouco).
  E uma banda de ~0,5 % do preco, nao um fio de cabelo.
- O `reason` publica `dist=`, `ATR=` e `Q-079/B`: cada uso da folga fica
  **auditavel por linha de journal**. Ponto a favor do implementador.

**Nao assino "a folga funciona".** `[CENARIO] = 0` desde 18:58:30: sem tick nao ha
sinal, logo a folga **nunca foi exercitada**. Ela e hoje um caminho nao percorrido.

---

## 6. Dois efeitos que o relatorio nao diz

**(a) 14 de 15 graficos estao estruturalmente impedidos de operar.** Os 14
simbolos devolveram `disponivel=false` e `AllowTradeWithoutAI=false` (#104 do
`.ex5`, confirmado no `.CHR` de CHART01). O portao de IA recusa-os antes de
qualquer sinal. "15 graficos em v1.2.185" **nao** significa 15 instrumentos
operaveis: e **1** (XAUUSD) e 14 bloqueados por desenho. A janela de segunda mede
XAUUSD - e isso tem de ser dito antes de se falar em "medir o piso com numeros
reais" no plural.

**(b) O perfil gravado em disco ja nao e registo fiavel dos inputs em uso.**
`CHART01.CHR` (perfil `XAU_AI_PRO_15CHARTS_Q071`) **nao contem**
`ScenarioTrendAtrSlack`: foi gravado antes do reattach. Hoje e inofensivo (a
omissao compilada e 1,0, portanto o valor seria o mesmo), mas mostra que a leitura
de inputs tem de ser feita no **binario vivo** (`get_expert_advisor_parameters`
e/ou `list_open_charts`), nunca no `.CHR`. Severidade baixa, registada aqui.

---

## 7. O que continua por medir (e o que isso custa)

| Item | Estado |
|---|---|
| Folga de 1 ATR | **nao exercitada** (0 `[CENARIO]`, 0 `[VALIDATION]`, 0 `[SCORE]`) |
| Piso 65 em producao | **0 amostras** |
| Leitura de IA como gate | 1 simbolo, 1 instante, mercado fechado |
| `MaxDD` / `Sharpe` do A/B | **nao auditaveis** (sem curva de capital; `tester_list_result_windows` devolve `{"windows":[]}`) |
| GATE_REAL | **2 de 11** (G2 com ressalva de durabilidade; G3 auditado em tester, nao em producao) |
| P1.2336 (`trades=` do RESUMO sempre 0) | aberto (ALFA) |
| P1.139 (passo 1 de `AllowTradeEx` mudo) | aberto (ALFA) |

A v1.2.185 **nao acrescenta verde nenhum**. Acrescenta **capacidade de medir** -
que e o que faltava para a folga e para o piso, e nada mais.

---

## 8. Assinatura

**ASSINO (D-086):**

1. O `.ex5` em disco e o do build reclamado: 964 998 B, 18:56:31 local
   (21:56:31Z), MD5 `146BB7FCE9E977E88A49A3AE007C419E`, `#property 1.385`,
   `EA_VERSION_STRING 1.2.185`, changelog presente.
2. A folga de Q-079/B esta **implementada com a guarda intacta** (ADX + cenario
   abaixo dela; rigor antigo quando falta leitura de EMA ou ATR) e o input
   `ScenarioTrendAtrSlack` existe no binario com default 1,0.
3. Os **15 graficos** correm **v1.2.185** desde 18:58:30 e o gateway respondeu
   com **inferencia real** a XAUUSD as 18:59:02 (1123 B, `disponivel=true`,
   SELL 72,35 %, confianca 72,40 %), com o token vindo do `.env` e **zero**
   ocorrencias de `Bearer` ou do valor no journal.
4. A conta esta plana: 12636,32 USD, 0 posicoes, 0 ordens; risco intocado.
5. Os 14 simbolos sem modelo publicado sao **recusados com motivo** (`edge`
   abaixo de +0,05), e isso e comportamento correcto - nao e avaria.

**NAO ASSINO:**

1. "o piso calibra-se com a leitura 72,40 >= 65,0" - **escalas diferentes** (§4);
2. "a IA real valida o piso" / "medir o piso com numeros reais" no estado actual -
   0 amostras de `[SCORE]`, mercado fechado;
3. "a folga de 1 ATR funciona" - nao exercitada (§5);
4. qualquer "10/10", qualquer "pronto", qualquer verde novo no GATE_REAL.

---

## 9. Pedidos (nao cobrancas)

**CMD - errata textual do relatorio (sem reescrever historia):**

- onde esta "uma leitura real (72,40 >= 65,0)", escrever
  **«a parcela de IA vale 36,20 pts de 115 = 31,48 na escala do piso; com as
  parcelas tecnicas maximas o sinal vale 74,96 >= 65,00; sem a parcela de IA vale
  43,48 e seria recusado»**;
- acrescentar que **14 de 15 graficos** estao impedidos de operar por
  `disponivel=false` + `AllowTradeWithoutAI=false`;
- manter o resto: o resto esta medido e certo.

**ALFA:**

- revisao independente de `Filters/MarketScenario.mqh:199-222` e `Core/Config.mqh:1505-1516`
  (pendente, e o operador tambem a declarou pendente);
- P1.2336 (`trades=` do `[SCANNER] RESUMO` sempre 0) e P1.139 (passo 1 de
  `AllowTradeEx` sem `Print`) continuam abertos e sao os dois que impedem medir o
  funil de producao.

**DONO:**

- a decisao do piso (`MinMarketScore`) so faz sentido **depois** de uma janela de
  mercado aberto; a tabela de percentis auditada no turno 3 (65 -> 1,4 %;
  55 -> 29,6 %; 50 -> 31,9 %; 45 -> 91,3 %) continua a ser a unica base medida;
- decidir se quer **1 ATR inteiro de folga simetrica** (~17-22 USD em XAUUSD,
  0,42-0,55 % do preco) ou meia folga, sabendo que a isencao vale para as duas
  direccoes.

---

## 10. Estado medido no fim do turno (19:20)

| Item | Valor |
|---|---|
| Versao em producao | **v1.2.185** (15/15 graficos, desde 18:58:30) |
| `.ex5` | 964 998 B, 18:56:31, MD5 `146BB7FCE9E977E88A49A3AE007C419E` |
| `#property` / `EA_VERSION_STRING` | 1.385 / 1.2.185 |
| Graficos abertos | 17 (15 com EA, 2 XAUUSD H1 vazios) |
| IA | XAUUSD `disponivel=true` 1123 B; 14 simbolos `disponivel=false` |
| `[CENARIO]` / `[VALIDATION]` / `[SCORE]` desde 18:58:30 | 0 / 0 / 0 |
| Conta | 113568614, saldo = equity 12636,32 USD, 0 posicoes, 0 ordens |
| Gateway | 9011 (efectivo, via `.env`); vivel em modo leitura; **nao e servico** |
| GATE_REAL | **2 de 11** |
| Compiles / reattach / ordens neste turno | 0 / 0 / 0 |
