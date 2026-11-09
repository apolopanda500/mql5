# SESSAO 2026-11-09 - ALFA (codigo e logica)

Agente: ALFA | inicio 09:52 local (12:52Z) | modo: LEITURA, LOCK de CMD respeitado
nada compilado, nada reanexado, nenhuma ordem, nenhum input de risco alterado.

---

## 1. Estado medido (nao relatado)

### 1.1 Os 15 graficos continuam no build ANTIGO

`list_open_charts` as 12:52Z: 15 graficos, todos `XAU_AI_PRO` v1.2.188, magic
2026001, perfil `XAU_AI_PRO_15CHARTS_Q071`. Os inputs estao corretos:

| Input | Valor medido nos 15 | Fonte por omissao |
|---|---|---|
| `SymbolsFromMarketWatch` | `false` | **`true`** (`Core/Config.mqh:998`) |
| `EnableStoplessEntry` | `false` | **`true`** (`Core/Config.mqh:1217`) |
| `Symbols` | 15 nomes (XAUUSD..USDCNH) | - |
| `RiskPercent` / `MaxDailyLossPercent` / `MaxDrawdownPercent` | 0.5 / 3.0 / 6.0 | G9 preservado |
| `MaxDailyLossUsd` | 60.0 | - |
| `AllowMinLotOverride` | `true` | `true` |

### 1.2 O binario em disco ja e v1.2.189, o forward corre v1.2.188

```
EX5 size=970468  mtime=2026-11-09T12:51:04Z  MD5=DAB9F16B8F0A6648D55C800A17B8114F
backup: Files\Backup\XAU_AI_PRO_v12189_DAB9F16B.ex5
fontes tocadas: VersionManager.mqh 12:46:38Z | XAU_AI_PRO.mq5 12:47:00Z | SafetyManager.mqh 12:47:57Z
```

Tres fontes de versao coerentes entre si agora:
`#property version "1.389"` (mq5:22) e `#define EA_VERSION_STRING "1.2.189"`
(VersionManager.mqh:14). Binario 12:51:04Z e mais novo que o fonte mais novo
(12:47:57Z): binario x fonte BATEM para v1.2.189.

**Mas** o `.ex5` carregado em memoria pelos 15 graficos e o de 969 944 B /
`5C99AF0CDCE1E2C74D39270C21047607` (v1.2.188), que e o MD5 declarado para o
forward. Consequencia dura: as correcoes de P1.3499/P1.3500 que estao no fonte
**nao estao a correr**. Qualquer reanexo passa a carregar DAB9F16B e a janela
09/11 -> 08/12 fica a cavalo de dois builds, sem que isso esteja registado em
nenhum documento. Decisao de DONO/DELTA, nao minha.

### 1.3 Achado novo, ausente de todos os relatorios

`chart01` e **`XAUUSD,M1`**, nao H1. O `SESSAO_20261109_DELTA.md` escreve
"15 graficos (14 H1 + USDBRL M5)"; o simbolo principal esta a correr em M1.
Os outros 14: 13 x H1 + USDBRL M5. Geometria: `chart14` USDRUB e `chart15`
USDSGD a 950x260 (56-57 barras de pagina) contra 998x196 dos restantes.

---

## 2. P1.3499 / P1.3500 - o que NAO se reproduz e o que continua aberto

### 2.1 Nao se reproduz ao nivel do input

`SymbolsFromMarketWatch=false` e `EnableStoplessEntry=false` em **15/15**
graficos, com `Symbols` = os 15 aprovados. O DELTA mediu a 09/11 09:15
`SymbolsFromMarketWatch=true` com 25 simbolos (AMD/MSFT/INTC/NVDA/GOLD a serem
avaliados) e atribuiu a P1.3500 o `EnableStoplessEntry=true`. Nesse instante a
regressao era real; as 12:52Z ja nao existe. Quem fecha o veredicto do dia 1 e
o DELTA com o journal de 09/11 - eu so entrego a medicao contraditoria.

### 2.2 O que continua aberto, e e codigo, nao configuracao

As duas mitigacoes vivem **so nos inputs dos 15 graficos**. As omissoes do
fonte apontam para o lado perigoso:

- `Core/Config.mqh:998`  `input bool SymbolsFromMarketWatch = true;`
- `Core/Config.mqh:1217` `input bool EnableStoplessEntry     = true;`

Um grafico novo, um template sem estes dois campos, ou um `.set` de testador
sem eles, volta a ligar os dois defeitos. Foi exactamente este mecanismo que
fez P1.3499 "regressar" no reanexo de D-113.

### 2.3 Causa-raiz de P1.3500 no codigo (confirmada, linha a linha)

`Core/ExecutionEngine.mqh:524-527`:

```mql5
double oneRDist = NoiseDistancePointsForRisk(symbol);

if(!EnableStoplessEntry && slRefPts > 0)
   oneRDist = (double)slRefPts;
```

Com `EnableStoplessEntry=true` o `oneRDist` fica na **distancia de ruido**, nao
na distancia que a posicao pode percorrer sem stop. O `perLot1R` sai pequeno, o
`riscoFinal` parece caber no teto de `MaxRiskPerTradeUsd=8.0`, o ramo
`MIN_LOT_EXCEEDS_RISK_CAP` (linha 568) nunca dispara e a ordem segue sem SL.
Medido em 09/11: 0,06 lote XAUUSD sem SL, 2000 pontos ate 4076,21 = **-119,40
USD** contra um teto de 8 USD por operacao e 60 USD por dia.

Ou seja: a v1.2.189 muda a **fonte** do limite diario (saldo -> deals do dia por
magic, `SafetyManager.mqh:640-686`) e desliga a entrada sem stop por
configuracao, mas **o buraco logico do cap de risco continua la**. Se alguem
voltar a ligar `EnableStoplessEntry`, o -119,40 repete-se com o gate novo.

Revisao da correcao que ja esta no fonte (lei as 590-740 de `SafetyManager.mqh`):

- soma `DEAL_PROFIT + DEAL_SWAP + DEAL_COMMISSION` dos deals de HOJE com
  `DEAL_MAGIC == MagicNumber` - correcto, idempotente, auto-corrigivel;
- se `HistorySelect` falhar mantem o valor anterior e nao cai para zero -
  fail-safe correcto;
- `Passo` e recalculado a cada actualizacao com `HistorySelect` do dia. Com 15
  instancias, sao 15 varrimentos do dia por ciclo. Nao e erro; e custo, e vale
  medir antes de subir para o testador de 12 meses.

### 2.4 Proposta ALFA (nao executada - exige decisao do DONO)

Tres opcoes, por ordem de risco:

1. **Flipping das omissoes no fonte** (`SymbolsFromMarketWatch=false`,
   `EnableStoplessEntry=false`). Torna a proteccao independente do anexo. Custo:
   muda o build e portanto o MD5 declarado do forward. Exige decisao escrita do
   DONO porque toca em parametro de risco.
2. **Cap de risco coerente no caminho sem stop**: usar
   `StoplessEmergencyRMult * ATR` (ou `StoplessArmMinPoints`) como `oneRDist`
   quando `EnableStoplessEntry` for true, em vez da distancia de ruido. Corrige
   o buraco sem mexer em omissao nenhuma.
3. Aceitar configuracao e registar a fragilidade como risco conhecido.

A 1 e a 2 nao se excluem.

---

## 3. G10 - divergencia que sobra

Market Watch tem 25 simbolos. `EURUSD` esta no Market Watch e **nao** esta em
`Symbols`; e os 9 nao-modelo (AMD, MSFT, INTC, NVDA, GOLD, COP, USD, JPY, CNH)
continuam no Market Watch. O criterio G10 diz "zero divergencia entre Symbols,
graficos e Market Watch" - continua vermelho por desenho, nao por defeito.

---

## 4. O que eu NAO fiz, e por que

LOCK de CMD (D-120) tomado as 09:45:48, expira 11:15:48. Enquanto durar: sem
compile, sem reanexo, sem ordem, sem tocar em input de risco. Tambem nao
escrevi em `DECISOES.md`, `IDS.md`, `SYNC_LOG.md` nem `PRESENCA.md`: o canal
esta sob o mesmo lock. Registro pendente para quando o lock fechar:

| ID a abrir | Assunto |
|---|---|
| P1.3506 | omissoes do fonte `SymbolsFromMarketWatch=true` / `EnableStoplessEntry=true` contrariam os 15 graficos |
| P1.3507 | cap de risco usa distancia de ruido quando a entrada e sem stop (`ExecutionEngine.mqh:524`) |
| P1.3508 | forward 09/11 -> 08/12 a cavalo de dois builds (5C99AF0C v1.2.188 em memoria, DAB9F16B v1.2.189 em disco) |
| P1.3509 | `chart01` corre XAUUSD,M1 e nenhum documento o diz |

---

## 5. Proximo passo natural

1. DELTA reconcilia o dia 1 contra o journal de 09/11 com esta medicao na mao.
2. DONO decide sobre 2.4 (1, 2 ou 3) e sobre a janela do forward apos o build
   novo.
3. Com o lock livre: reanexo dos 15 a v1.2.189, prova `(SYMBOL,PERIOD) [START]`
   no journal, MD5 novo declarado, e so depois continuar a contagem.
