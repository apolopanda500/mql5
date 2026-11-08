# AUDITORIA DOS INSTRUMENTOS DE MEDICAO - D-089 / JANELA FORWARD

- **Data:** 08/11/2026, 10:20-10:35 (local)
- **Agente:** DELTA
- **Objeto:** provar, antes de 09/11 00:05, o que a janela forward consegue e o
  que NAO consegue medir. Sem compilar, sem reanexar, sem ordem, sem risco.
- **Metodo:** leitura de `MQL5\Logs\*.log` (log de expert, arquivo real) +
  `metaeditor.log` + journal do terminal + leitura do fonte. Nenhuma escrita
  no EA, nenhum anexo, nenhum teste.

> Motivo de existir: o plano D-089 pede "TREND CONTRA OK com selo Q-079/B",
> "folga ATR em H1", "entradas IA vs nao-IA" e "TOTAL= por simbolo". Antes de
> prometer essa medicao era preciso saber se os instrumentos imprimem, com que
> frequencia e se ja existe linha de base. Existe uma, e ela e' quase toda
> pre-correcao.

---

## 1. Linha de base medida (todo o historico em `MQL5\Logs`)

| Padrao no log | 01/11 | 02/11 | 03/11 | 04/11 | 05/11 | 06/11 | 07/11 | 08/11 | Total |
|---|---|---|---|---|---|---|---|---|---|
| `TREND CONTRA OK` | 1 | 0 | 2 | 0 | 54 | 0 | 0 | 0 | **57** |
| `contramao PERMITIDA` | 1 | 0 | 2 | 0 | 54 | 0 | 0 | 0 | **57** |
| `contramao vetada` | 47 | 91 | 23 | 10 | 165 | 2 | 0 | 0 | **338** |
| `ADX indisponivel` | 0 | 0 | 23 | 0 | 23 | 0 | 0 | 0 | **46** |
| `dentro da folga` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| `Q-079/B` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0** |
| `[SCORE] CALCULATED` | 0 | 0 | 3 | 0 | 1 | 0 | 0 | 0 | **4** |
| `SCORE CALCULATED` (sem tag, legado) | 0 | 60 | 0 | 0 | 0 | 0 | 0 | 0 | **60** |

---

## 2. Achados

### F1 - O caminho da folga ATR (Q-079/B) NUNCA disparou

`dentro da folga` = **0 ocorrencias em todo o historico**.
`Q-079/B` = **0 ocorrencias em todo o historico**.

As 57 linhas de `TREND CONTRA OK` sao **100%** do caminho de fallback, nao da
folga: `contramao PERMITIDA` tem exactamente a mesma contagem (57) e a mesma
distribuicao por dia. Exemplo real:

```
[VALIDATION] TREND CONTRA OK | USDCNH | Signal=1 | contramao PERMITIDA | cenario LATERAL | ADX=0.0 | lote x0.75
```

O selo `Q-079/B` e o texto `contramao dentro da folga de X.XX ATR` existem no
fonte (`Filters/MarketScenario.mqh`) mas **nunca apareceram no log**.

**Consequencia:** o criterio "TREND CONTRA OK com selo Q-079/B" tem linha de
base **0/0**. A janela forward e' o primeiro teste real da folga, nao uma
repeticao de algo ja observado.

### F2 - A janela forward e' o primeiro teste vivo do fix D-086

O fix de ordenacao do ADX (ler `adx` antes da folga + veto `adx<=0.0` antes de
tudo) entrou na **v1.2.187** (08/11 05:40). Entre 05:40 e agora, o mercado
esteve **fechado** (server last_known 06/11 23:59:59): v1.2.187 rodou 21 min
e v1.2.188 roda desde 06:01, ambos sem tick.

Portanto **nao existe uma unica amostra do gate pos-fix**. As 57 amostras de
`TREND CONTRA OK` sao todas pre-fix.

### F3 - Prova documental do bug que o D-086 corrigiu

Em 05/11 o mesmo simbolo (USDCNH) produz, na mesma tarde, os dois
comportamentos opostos:

```
16:00:22  [VALIDATION] BLOCK   | TREND BUY | USDCNH | contramao vetada | ADX indisponivel
...       (23 linhas iguais ate 16:42:02)
16:46:24  [VALIDATION] TREND CONTRA OK | USDCNH | Signal=1 | contramao PERMITIDA | cenario LATERAL | ADX=0.0 | lote x0.75
...       (54 linhas iguais ate 18:57:44)
```

Mesmo simbolo, mesmo `ADX=0.0`, 4 minutos de diferenca: veta e depois **permite
contra-tendencia com ADX indisponivel**. E' exactamente o defeito que o veto
`adx<=0.0` da v1.2.187 fecha. O fonte actual confirma a ordem correcta:

```mql5
if(adx <= 0.0){ reason="contramao vetada | ADX indisponivel"; return false; }   // antes de tudo
if(ScenarioTrendAtrSlack > 0.0 && Period() == TrendTF){ ... }                    // folga so depois
```

Isto vale como evidencia historica do bug, **nao** como evidencia de que o fix
funciona. O fix nao tem amostra.

### F4 - `TOTAL=` e' medivel, mas com taxa de emissao quase nula (P1.3476 corrigido)

O instrumento existe e imprime o valor correcto:

```
[SCORE] CALCULATED | Symbol=USDCHF | Signal=-1 | EMA=20.00 | RSI=0.00 | ADX=15.00 | AI=37.50 | WARMUP=SIM | TOTAL=100.00
```

Mas: **4 ocorrencias em 8 dias** (03/11 20:35, 20:36, 21:00 e 05/11 22:35),
nenhuma depois de 05/11 22:35. A causa e' o gate duplo no fonte
(`Core/DecisionEngine.mqh`): `if(logOnce && DecisionLogDue(symbol,"SCORE",900))`
- exige `logOnce` (1x/minuto) **e** o intervalo de 900 s por simbolo no mesmo
tick. Na pratica quase nunca coincide.

**P1.3476 fica reformulado:** nao e' "TOTAL nao e' impresso". E' "TOTAL e'
impresso 1 vez a cada 2 dias por frota, logo nao serve como instrumento de
amostragem". As 4 amostras existentes sao todas `TOTAL=100.00` - pre-fix de
normalizacao (v1.2.184), portanto **nao validam** o score actual.

### F5 - `PTS=` existe no fonte e nunca foi observado

O fonte actual (`DecisionEngine.mqh`, 22 954 B, 08/11 05:58:07) imprime
`| PTS=<pts> | TOTAL=<score>`. Todas as 64 linhas historicas de `SCORE
CALCULATED` (4 com tag + 60 legado sem tag) mostram **apenas `TOTAL=`**, sem
`PTS=`. Ou seja: `PTS=` e' adicao recente, o binario em producao nunca a
imprimiu com mercado aberto e nao ha uma unica amostra.

### F6 - Binario de 10:25:59 atribuido: foi um compile, nao um reattach

`metaeditor.log`:

```
2026.11.08 10:25:59.252  Compile ...\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5 - 0 errors, 0 warnings, 32823 ms elapsed, cpu='X64 Regular'
```

Compilacao single-file, 0 erros / 0 avisos, feita na janela do ALFA
(ultima accao 10:22:24, proxima 10:26:14 - DELTA). Nao houve reanexo: a frota
segue no build carregado as **09:34:28** e `loggate_version_1.2.188.bin` continua
com mtime 09:34:28.

Estado dos tres binarios:

| Binario | Bytes | MD5 | Origem |
|---|---|---|---|
| v1.2.187 (backup) | 967 328 | `10212E87...` | 08/11 05:40 |
| v1.2.188 **em producao** | 970 168 | `943DB7CB6955299C6A470141B942BC54` | 08/11 05:59:42, carregado 09:34:28 |
| v1.2.188 em disco agora | 969 944 | `5C99AF0CDCE1E2C74D39270C21047607` | 08/11 10:25:59, compile single-file |

Os dois v1.2.188 vem da **mesma arvore de fonte** (git limpo, fontes congeladas
desde 05:58:48; o commit `86d1ac96` de 10:26:16 e' so documentacao). A diferenca
de 224 bytes e' modo de build (`build_project` vs `compile_file`), nao divergencia
de codigo. Fica como risco residual a fechar com um A/B controlado **depois** do
LOCK.

### F7 - Frota confirmada 15/15 v1.2.188, incluindo USDBRL em M5

`MQL5\Logs\20261108.log`, 09:34:28.139 -> 09:34:29.318: 15 linhas
`[START] XAU_AI_PRO v1.2.188 | conta=113568614 | MetaQuotes Ltd./MetaQuotes-Demo`.
A linha `09:34:29.311 ... XAU_AI_PRO (USDBRL,M5)` fecha **P1.3481** com
evidencia dupla (chart + log).

### F8 - Nada disto pode ser medido hoje

`trade_server_last_known_time = 2026-11-06T23:59:59`; `[HEALTH] HEALTHY |
uptime=0s | checks=0 | sem tick=11s`. Sem tick nao ha `ScoreMarket`, nao ha
`ValidateTrade`, nao ha `TREND CONTRA OK`. Qualquer medicao antes de
09/11 00:05 e' fabricacao.

---

## 3. O que a janela forward consegue medir (e o que nao consegue)

| Criterio D-089 | Medivel? | Instrumento | Base actual |
|---|---|---|---|
| `TREND CONTRA OK` com selo `Q-079/B` | **Sim**, se a folga disparar | `[VALIDATION] TREND CONTRA OK ... contramao dentro da folga ... Q-079/B ... ADX=` | **0** |
| Veto `ADX indisponivel` (fix D-086) | **Sim** | `[VALIDATION] BLOCK ... contramao vetada \| ADX indisponivel` | 46 (todas pre-fix) |
| Folga ATR calculada em H1 | **Parcial** - so via `Period() == TrendTF`; o log nao imprime o TF | reason string nao traz TF | 0 |
| Entradas IA vs nao-IA | **Sim** | `[AI] PYTHON` / `[AI] INDISPONIVEL` + `MinMarketScore` vs `MinMarketScoreNoAI` | ver F1 |
| `TOTAL=` por simbolo | **Sim, mas raro** | `[SCORE] CALCULATED ... TOTAL=` (1x/15 min/simbolo, gate duplo) | 4, todas `100.00` |
| `PTS=` por simbolo | **Nao observado** | `[SCORE] CALCULATED ... PTS=` | 0 |
| Score pos-normalizacao v1.2.184 | **Nao provado** | idem - 0 amostras pos-fix | 0 |

**Regra que decorre disto:** nao se pode escrever "TREND CONTRA OK = N" como
sucesso do gate se `N` vier todo de `contramao PERMITIDA`. So conta como
exercicio do Q-079/B a linha que contiver **`dentro da folga`**. Isto tem de
ficar explicito no criterio de aceitacao da janela, senao repetimos o erro das
57 linhas antigas.

---

## 4. Plano de captura a partir de 09/11 00:05

Script pronto: `EQUIPE\tools\delta-captura-d089.ps1` (leitura apenas).

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  "EQUIPE\tools\delta-captura-d089.ps1" -Dia 20261109
```

Separa, por simbolo:

1. `Q079` - `TREND CONTRA OK` **que contenham** `dentro da folga` (o criterio real);
2. `TREND_OK_FALLBACK` - `TREND CONTRA OK` por `contramao PERMITIDA` (nao conta para o Q-079/B);
3. `VETO_ADX` - `contramao vetada | ADX indisponivel`;
4. `SCORE` - `[SCORE] CALCULATED` com `PTS=` e `TOTAL=` (prova da normalizacao);
5. `IA` - `[AI] PYTHON` vs `[AI] INDISPONIVEL`.

Sequencia obrigatoria na abertura:

1. 00:04 confirmar `loggate_version_1.2.188.bin` com mtime 09:34:28 (frota nao mudou);
2. 00:05-00:10 primeira leitura: `[HEALTH] ... sem tick` deve cair e aparecer `[SCORE]`/`[VALIDATION]`;
3. primeira hora: se `Q079 = 0` e `TREND_OK_FALLBACK > 0`, o gate **nao** foi exercitado - registar assim, sem promover.

---

## 5. O que este relatorio NAO faz

- nao compila, nao reanexa, nao envia ordem, nao toca em risco (LOCK do ALFA activo);
- nao altera `GATE_REAL` (**2 de 11**), `IDS`, `PENDENCIAS`, `PRESENCA`, `SYNC_LOG` - o LOCK reserva a saida (D-108) ao ALFA;
- nao promove forward: **0 de 30** dias, arranca 09/11 00:05;
- nao declara 10/10: nao existe, e o maximo e' x/11.

Fecho: 0 compiles meus, 0 corridas de tester, 0 reanexos, 0 ordens, risco intocado.
