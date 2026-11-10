# RELATORIO D-153 / P1.3519 - o piso `0.02` foi aplicado e medido: 6 disponiveis, 0 trades novos

**ALFA | 10/11/2026 04:31 -> 04:41 | build 71ED34C6 (977 654 B, mtime 10/11 02:23:07)**

---

## 1. O que o DONO decidiu

Em `P1.3519` o DONO escolheu **B**: baixar o piso de edge do gateway de `+0.0500` para `0.02`, mantendo `AIHasSignalAuthority=true`. Registei como **D-153** e desbloqueei o pedido do CMD.

## 2. O que foi medido, com o mesmo probe, antes e depois

| | 04:31:42 (antes) | 04:37:07 (depois) | Alvo D-153 |
|---|---|---|---|
| `available=true` | **1** (XAUUSD) | **6** | 5 |
| bloqueados | **14** | **9** | 10 |
| com `model` publicado | 1 | **6** (XAUUSD + 5) | - |
| **capazes de decidir** | **1** | **1** | - |
| trades novos | - | **0** | >=1 |

Artefactos: `MQL5\Files\Temp\alfa_baseline_piso.txt` (antes, 1893 B) e `alfa_baseline_piso_after.txt` (depois, 1849 B).

## 3. Duas coisas que a medicao desmentiu - uma delas era minha

**(a) O que abriu os 5 simbolos nao foi o piso, foi `publicable: true`.** Os 9 que continuam fora respondem **a mesma string de sempre**: `abaixo do minimo +0.0500` (357 B). Se o limiar da comparacao fosse `0.02`, a string diria `+0.0200`. Os 5 que entraram respondem `model:"<SYM> 1H"` com 1018-1033 B. E' exactamente o P1.3519: **o piso so' filtra simbolos SEM modelo**. Basta o modelo existir para o piso deixar de pesar. O `0.02` fica aplicado e nao faz mal nenhum - mas nao foi ele que abriu nada.

**(b) O USDBRL entrou, e com ele caiu a minha propria correccao.** As 04:34 publiquei uma seccao 8 a dizer que o USDBRL **nao** entrava (411 B, `edge instavel entre folds`, media -0.0484). As 04:37: `available=true`, `edge +0.0926`, acc 0.4468 - **o melhor do lote**. A reavaliacao dos folds mudou-lhe o veredicto em 6 minutos. A previsao do DELTA (D-151: "o USDBRL entra") era melhor do que a minha correccao. Escrevi-o no canal, com o meu erro ao lado. A seccao 8 fica como registo do estado das 04:31; a seccao 9 e o estado actual.

## 4. O achado que interessa mais do que o piso: a largura nao passa do gateway

| Simbolo | `available` | confianca | `MinAIConfidence=60.0` | `GetAIEngineSignal` |
|---|---|---|---|---|
| XAUUSD | true | **74.7** | acima | decide |
| USDCAD | true | **47.2** | abaixo | 0 |
| USDBRL | true | **45.9** | abaixo | 0 |
| USDCHF | true | **43.1** | abaixo | 0 |
| NZDUSD | true | **42.6** | abaixo | 0 |
| USDJPY | true | **37.6** | abaixo | 0 |

Cadeia: `AI_Score = StringToDouble(jsonConfidence)` (`AIConnector.mqh:576`) -> `if(AI_Score<MinAIConfidence) return 0;` (`AIEngine.mqh:300`) -> com `AIHasSignalAuthority=true`, `GetCombinedSignal` devolve 0 sem fallback tecnico (`AIEngine.mqh:395-400`). E o `AIAuthorityMinScore=75.0` **nao serve de alavanca: esta' morto** (P1.3527 - declarado em `Config.mqh:695`, so' referido num comentario em `AIEngine.mqh:391`).

**`available` 1 -> 6, simbolos capazes de decidir: 1. O piso comprou largura no gateway, nao trades no EA.** Toda a projeccao de G5 a "1.6x fora com 5 efectivos" (D-151/D-152) fica sem base: o G5 nao se move.

## 5. Achado lateral que pode estar a parar o forward (P1.3529)

O `[RESUMO]` do EA repete 54 vezes entre 00:00 e 04:35:

```
dia fechado: -61.80 de 40.00 USD (-154%)      (as 00:00 era -73.02 de 40.00 USD, -183%)
```

O tecto lido no runtime e' **40.00 USD**; o `chart01.chr` declara `MaxDailyLossUsd=600.0` e o D-154 calculou **377.81** para hoje. Se for bloqueio efectivo, **hoje nao se acumula trade nenhum** e qualquer medicao de estrategia desta madrugada esta' contaminada. Nao sei de onde vem o 40.00 - pedido ao CMD e ao DELTA para confirmarem o valor em runtime, sem recompilar nada.

## 6. O que ficou no canal

| Artefacto | Estado |
|---|---|
| `DECISOES.md` | D-153 seccao 8 (correccao 04:34) + seccao 9 (verificacao 04:37); cabecalho e tabela corrigidos in loco |
| `IDS.md` | D-153, P1.3525, **P1.3527** (AIAuthorityMinScore morto), **P1.3528** (o tecto e' a confianca), **P1.3529** (tecto diario 40.00) |
| `SYNC_LOG.md` | 7 linhas (2 da correccao 04:34 + 4 da verificacao 04:37) |
| `INBOX` CMD | correccao do teste de aceitacao + verificacao da execucao + pendencia do 40.00 + data errada no bloco D-155 (`06/11/2026` vs IDS `10/11 04:36:39`) |
| `INBOX` DELTA | 6/9 e nao 5/10, USDBRL entrou, o tecto real e' a confianca |
| `PENDENCIAS.md` | P1.3527 + P1.3528 + P1.3529 anexadas |
| **`CANAL INTEGRO :: 0 problemas`** | confirmado as 04:41 |

## 7. O que o DONO tem de decidir agora

1. **Aceitar que hoje o forward mede 1 simbolo** (XAUUSD) e que o `0.02` nao muda isso - ou
2. **baixar `MinAIConfidence`** (60 -> 40) para deixar os 5 novos decidirem com confianca 37-47. Mesmo perfil de risco que ele ja aceitou na opcao B, mas com o estimador a declarar que nao sabe - **e exige recompilar**, proibido ate' 12/11 pelo D-147;
3. ou **esperar que os modelos novos ganhem confianca** e medir de hora a hora antes de mexer em qualquer coisa. E' a unica via que nao troca rigor por volume.

Nada disto e' um bug: e' o desenho a funcionar. O que falhou foi o rotulo - "5 simbolos operaveis" quando sao 5 simbolos **disponiveis**.

## 8. Guardas

Nenhum ficheiro do EA tocado, nada compilado, nada deployado, nenhum input alterado, nenhuma ordem, nenhum reinicio. **Binario: 977 654 B - mtime 10/11 02:23:07 - MD5 `71ED34C690C9593D209A69E95F0EFFB6`** antes e depois da medicao. Conta `113568614`: 12 593.83 USD, 0 posicoes, 0 ordens.
