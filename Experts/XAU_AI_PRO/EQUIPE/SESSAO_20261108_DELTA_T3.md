# SESSAO 2026-11-08 - DELTA T3 (execucao do "avancar tudo agora")

> Autor: DELTA, 08/11 13:07 (local) = 16:07Z. Mandato: DONO "avancar tudo agora" (D-116).
> Papel: medir, registar, NAO reanexar enquanto outro agente opera.
> Este documento nao substitui `GATE_REAL.md` nem `IDS.md`; e' o registo de medicao desta sessao.

## 0. Coordenacao (medido, nao presumido)

| Hora | Evento | Fonte |
|---|---|---|
| 13:02:03 | ALFA salva template `ALFA_G10_BASE` (chart `#22884787070177`) | `Logs\20261108.log` |
| 13:02:33 | ALFA cria perfil `XAU_AI_PRO_15CHARTS_PRE_G10_ALFA` | idem |
| 13:02:37 | `LOCK.md` libertado (`sistema`) - **e ALFA continua a operar** | `EQUIPE\LOCK.md` |
| 13:02:52-55 | ALFA fecha os 5 graficos sem modelo (USDCLP, USDCOP, USDCZK, USDRUB, USDSGD) | idem |
| 13:02:58 + 13:03:04 | ALFA abre **EURUSD duas vezes** (`#95180320674740` e `#95180392818145`) | idem |
| 13:03:10 | Template aplicado a `#95180392818145` (EURUSD **com** EA) e a `#35819338055848` | idem |
| 13:03:20 e 13:03:37 | ALFA repoe `USDBRL` em **M5** (anula a minha passagem para H1 das 13:02:58) | idem |
| 13:03:49 | ALFA cria perfil `XAU_AI_PRO_11CHARTS_Q072_ALFA` | idem |
| 13:04:00 | ALFA escreve `DECISOES.md`, `PRESENCA.md`, `SYNC_LOG.md` | `dir EQUIPE` |
| 13:04:19-13:04:40 | ALFA le `EQUIPE\tools\gateway-start.ps1`, sonda `9011/api/health` (**401**), `find files probe` -> **ALFA esta no tema G2 agora** | `Logs\20261108.log` |

**Conclusao operacional:** a partir das 13:02 o G10 deixou de ser meu e passou a ser executado pelo ALFA. Nao duplico. O que faco nesta sessao e' medir o resultado dele e fechar as lacunas que sobram, sem segundo reanexo.

**Falha de protocolo a corrigir (P1.3494):** `LOCK.md` dizia **LIVRE** as 13:02:37 enquanto o ALFA aplicava templates ate 13:03:49 e escrevia ficheiros ate 13:04:00. Um lock libertado no meio do trabalho nao protege nada. Proposta: o lock tem de ser mantido ate ao **ultimo** artefacto escrito, com `Libertado` preenchido depois desse instante.

## 1. G9 - Q-017: VERDE na medida dos tres valores nomeados

Medido 08/11 13:05 com `list_open_charts` em **todos** os graficos com EA (12 de 12):

| Input | Valor em uso (todos os graficos) | Limite declarado D-116 | Estado |
|---|---|---|---|
| `RiskPercent` | **0.5** | <= 0.5 | OK |
| `MaxDailyLossPercent` | **3.0** | <= 3.0 | OK |
| `MaxDrawdownPercent` | **6.0** | <= 6.0 | OK |

Os tres valores passaram de "declarados por escrito" (D-116) a **em uso** no terminal. O `.ex5` nao mudou: a alteracao e' de inputs.

**Ressalvas escritas (nao fecham o G9, mas ficam registadas - P1.3495):**
- `MaxTotalRiskPercent = 10.0` e `MaxTotalRiskOpenUsd = 60.0` continuam valores de treino: permitem somar ate 10 % de risco aberto contra um limite diario de 3 %. O G9 nao nomeia estes campos; o espirito do criterio sim.
- `MaxTradesPerDay = 100` e `MaxOpenPositions = 50` tambem continuam de treino.
- `MaxDailyLossUsd = 60.0` (0,47 % do saldo 12 636,32) e' mais apertado que os 3 % (379,09) - coerente, nao conflitante.
- `RiskPerTradePercent = 0.5` + `MaxRiskPerTradePercentCap = 3.0` + `MaxRiskPerTradeUsd = 8.0`: o cap por trade e' 6x o risco base. Nao viola o G9, mas e' o proximo valor a apertar antes de conta real.

## 2. G10 - Q-013: universo corrigido no input; sobram 2 divergencias medidas

**O que ficou resolvido (medido, 13:05):**

| Item | Antes (06/11) | Agora (08/11 13:05) |
|---|---|---|
| Graficos | 15 | **12** |
| Simbolos em `Symbols` | 15 entradas (incluia USDCLP, USDCOP, USDCZK, USDRUB, USDSGD) | **11 canonicos** |
| `SymbolsFromMarketWatch` | (nao gerido) | **false** em 12 de 12 graficos |
| Graficos sem modelo | USDCLP, USDCOP, USDCZK, USDRUB, USDSGD | **0 fechados / 0 restantes** (fechados 13:02:52-55) |
| EURUSD | sem grafico | **com EA** em `#95180392818145` |
| `RiskPercent` / `MaxDailyLossPercent` / `MaxDrawdownPercent` | 1.0 / 10.0 / 50.0 | **0.5 / 3.0 / 6.0** |

`Symbols` = `XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH` nos 12 graficos.

**Achado que muda o G10 de "cosmetico" para "estrutural":** o `Core\SymbolManager.mqh:319-341` (v1.2.167, P1.130) constroi `ActiveSymbols = Symbols + Market Watch + simbolo do grafico`. Com `SymbolsFromMarketWatch = true` o EA herdava **todos** os simbolos visiveis no Market Watch - incluindo `AMD`, `MSFT`, `INTC`, `NVDA`, `GOLD`, `COP`, `USD`, `JPY`, `CNH`. Ou seja: arranjar os graficos sozinho **nao** fechava o G10. Foi o `SymbolsFromMarketWatch = false` que separou o universo do EA do Market Watch. Isto e' o nucleo do fecho do G10 e tem de ficar escrito.

**Divergencias que restam (medidas, nao opiniao):**

1. **12 graficos para 11 simbolos.** `EURUSD` tem dois graficos:
   - `#95180392818145` - **com** `XAU_AI_PRO` (valido);
   - `#95180320674740` - **sem EA, sem indicadores** (aberto no 2.o `chart_open` das 13:03:04).
   Prova no perfil do ALFA: `Profiles\Charts\XAU_AI_PRO_11CHARTS_Q072_ALFA\chart11.chr` = **7 450 B**, enquanto os outros 11 variam entre 19 046 e 19 084 B. Perfil com 12 ficheiros apesar do nome "11CHARTS". -> **falta fechar `#95180320674740`**.
2. **Market Watch com 25 simbolos** (EURUSD, GBPUSD, USDCHF, USDJPY, USDCNH, AUDUSD, NZDUSD, USDCAD, USDSEK, AMD, MSFT, INTC, NVDA, GOLD, XAUUSD, USDBRL, USDCLP, USDCOP, USDCZK, USDRUB, USDSGD, COP, USD, JPY, CNH). Ja **nao polui** o universo do EA (`SymbolsFromMarketWatch=false`), mas o texto literal do G10 fala de "zero divergencia entre `Symbols`, graficos e Market Watch". Fica a divergencia **declarada**, nao silenciosa: ou se aceita o desacoplamento como fecho do criterio, ou se limpa o Market Watch para os 11.

**Periodo USDBRL = M5 (nao H1):** decisao do ALFA tomada duas vezes (13:03:20 e 13:03:37) e gravada no perfil `ALFA_V_USDBRL`. Nao e' divergencia de simbolo; o EA usa `TrendTF=16385` (H1) e `V2_EntryTF=15` (M15) por input, nao pelo periodo do grafico. Registo como escolha do ALFA, nao a reverto.

## 3. G5 - Q-026: janela de 12 meses reposta e a correr

O run original `7705829861381623325` (12:55) foi **morto pelo reinicio do terminal** as 12:58:32. Relancado por mim as 13:00:

| Campo | Valor |
|---|---|
| `run_id` | **`7705831697789824952`** |
| Config | `MQL5\Profiles\Tester\DELTA_G5_12M.ini` |
| Inputs | `MQL5\Profiles\Tester\DELTA_186_A.set` |
| Janela | **2025.11.09 -> 2026.11.09** (12 meses) |
| Simbolo / periodo | XAUUSD / H1 |
| Modelo | `Model=1` (m1 ohlc) |
| Deposito / alavanca | 12 636,32 / 100 |
| Estado as 13:07 | `started`, progresso `00:02:44 / 02:50:50` |

Piso de **100 trades mantido** (o DONO nao baixou a fasquia). O criterio G5 fica fechado quando o relatorio mostrar **>= 100 trades fechados** nesta janela de 12 meses.

**Precedente medido que justifica a janela:** 37 trades em 3 meses (run `7705790507266947777`) = 12,3/mes -> 100 trades exigem ~8,1 meses. A janela de 12 meses cobre isso com folga de 4 meses.

## 4. G2 - Q-022: 401 no `/api/health` e' o obstaculo, e e' de CMD

Medido por mim e reconfirmado pelo ALFA as 13:04:32:

```
web request GET http://127.0.0.1:9011/api/health failed with code 401
```

Isto **nao** contradiz o G2: o criterio pede `/api/ai/predict` a **200** com credencial resolvida, e o registo de 06/11 15:50 ja provou 200/1122 B com Bearer. O 401 no `/api/health` mostra apenas que o endpoint de saude exige o mesmo token. O que continua **aberto** e' a **durabilidade**:

- o gateway corre como **processo manual** (PID 8992, 1 uvicorn), sem servico Windows;
- um reboot mata-o e o EA fica cego (`AIUnavailableConfidenceCap=40.0`, `AllowTradeWithoutAI=true` -> passa a decidir com score capado em 40);
- a correcao e' **fora das raizes MQL5** (servico + NSSM + politica de execucao), logo **CMD**. Pedido escrito em `EQUIPE\PEDIDO_CMD_G2_SERVICO.md`.

O ALFA esta a ler `tools\gateway-start.ps1` neste momento; para nao colidir, o pedido a CMD e' **especificacao**, nao execucao concorrente.

## 5. G1 - DONO: nada a fazer por agente

Conta `MetaQuotes-Demo`, login `113568614`, tipo `demo`, balance = equity **12 636,32**, margem 0. Sem conta real num broker real, o G1 nao tem acao de agente possivel. Nao invento numero nem antecipo data.

## 6. Placar honesto desta sessao (13:07)

| Item | Antes (D-116 12:54) | Agora | O que falta |
|---|---|---|---|
| **G1** | VERMELHO | VERMELHO | conta real (DONO) |
| **G2** | VERDE com ressalva | VERDE com ressalva | servico Windows (CMD) |
| **G3** | VERDE auditado (3 ressalvas) | igual | nada nesta sessao |
| **G4** | VERMELHO | VERMELHO | 24 h sem reanexo; **o reanexo das 13:02-13:03 zerou o uptime outra vez** |
| **G5** | VERMELHO (janela incomp.) | **em medicao** (12 meses a correr) | >= 100 trades no relatorio |
| **G6** | VERMELHO | VERMELHO | forward |
| **G7** | VERMELHO (PF 0,66) | VERMELHO | PF >= 1.20 |
| **G8** | VERMELHO (44 trades) | VERMELHO | amostra >= 100 no build final |
| **G9** | VERMELHO | **VERDE** (0.5 / 3.0 / 6.0 em 12/12) | apertar `MaxTotalRiskPercent` (ressalva) |
| **G10** | VERMELHO | **VERMELHO com 1 lacuna** | fechar `#95180320674740`; declarar Market Watch |
| **G11** | VERMELHO (0/30) | VERMELHO (0/30) | forward 09/11 00:05 |

**Placar: 3 verdes de 11** (G2 com ressalva, G3 auditado, **G9 novo**) e **8 vermelhos**, com G5 em medicao. O "10/10" continua a nao existir.

## 7. Problemas novos registados

- **P1.3494** - `LOCK.md` libertado as 13:02:37 enquanto o ALFA escrevia ate 13:04:00. Lock sem margem de fecho.
- **P1.3495** - G9 fecha nos tres valores nomeados mas `MaxTotalRiskPercent=10.0` / `MaxTotalRiskOpenUsd=60.0` / `MaxRiskPerTradePercentCap=3.0` continuam de treino.
- **P1.3496** - 2.o grafico EURUSD `#95180320674740` sem EA (perfil `chart11.chr` 7 450 B) -> 12 graficos para 11 simbolos.
- **P1.3497** - `SymbolsFromMarketWatch=true` era fuga de universo: o EA herdava `AMD/MSFT/INTC/NVDA/GOLD/COP/USD/JPY/CNH` do Market Watch (`Core\SymbolManager.mqh:319-341`). Corrigido para `false` nos 12 graficos; fica como defeito de desenho a documentar no codigo.
- **P1.3498** - run G5 `7705829861381623325` perdido no reinicio do terminal as 12:58:32; reposto como `7705831697789824952`. Nao ha persistencia de job de tester a reinicio.

## 8. O que eu NAO fiz (e porque)

- Nao fechei `#95180320674740`: o ALFA estava a operar nos graficos as 13:04:40. Fechar um grafico de outro agente no meio da escrita dele produz 12 vs 11 irreproduzivel. Fica para o proximo turno ou para o ALFA.
- Nao re-apliquei template nem reanexei EA: **um** reanexo so, e ja foi feito (13:02-13:03). Cada reanexo adicional custa o uptime do G4.
- Nao compilei: `P1.3486`/`P1.3478` adiados para 09/12 por decisao A+B; o binario declarado `5C99AF0CDCE1E2C74D39270C21047607` nao se toca.
- Nao alterei `RiskPercent`/`MaxDailyLossPercent`/`MaxDrawdownPercent` na fonte: o G9 e' de **inputs**, e os inputs ja estao certos.
