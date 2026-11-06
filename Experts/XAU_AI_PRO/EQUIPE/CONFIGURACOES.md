# CONFIGURACOES - o que o agente muda, o que so o DONO muda

**Criado:** 05/11/2026 22:41 | **registo:** `DECISOES.md` `D-020`.
Tres niveis: **A** = agente faz sozinho | **B** = agente faz com LOCK e aviso | **C** = so o DONO.

---

## 1. Nivel C - so o DONO (esta fora das raizes ou e decisao de dinheiro)

| Configuracao | Onde vive | Porque e do dono |
|---|---|---|
| **Allowlist de WebRequest** | `Ferramentas > Opcoes > Expert Advisors` (GUI) | fora das raizes; sem ela o EA nao fala com o gateway |
| AutoTrading (botao verde) | GUI do terminal | liga/desliga ordens reais |
| Instalar Python / `pip` / `npm` | `site-packages`, `%APPDATA%` | escreve fora das raizes |
| Ficheiro de config de MCP | `C:\Users\Micro\.config\...` | fora das raizes |
| `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, `RiskPerTradeUsd`, `StopLossPoints`, `TakeProfitPoints` | inputs do EA | **risco de capital** |
| `MinAIConfidence` | input do EA | define quantos sinais passam |
| Publicar no CodeBase / `origin` | remotes | exposicao externa |
| Limpeza fora de `MQL5`/`Common`/`Tester`/`Logs` | Windows | fora das raizes |

## 2. Nivel B - agente faz, com LOCK e aviso na caixa

| Configuracao | Nota |
|---|---|
| Anexar/reanexar EA num grafico (`chart_add_expert`) | muda o que corre em producao: **LOCK + 1 parametro por vez + registo** |
| `profile_apply` / aplicar template | pode levar EA com inputs antigos para 13 graficos |
| `EnableVolatilityFilter`, `AllowTradeWithoutAI`, `EnableAIFilter`, `EnableAutonomousMode` | muda taxa de entrada: decisao do dono (`Q-005`), execucao do agente |
| Lista de simbolos / universo | muda o que o EA visita (`Q-004`) |
| `Profiles/Tester/*.set` | congela numeros de teste (`Q-007`) |
| `.gitignore` / o que entra no commit | mexe no historico |

## 3. Nivel A - agente faz sozinho (dentro das raizes)

- `.md` do canal (`post`, `note`), IDs (`id`), LOCK (`lock`).
- `MQL5/Files/Temp`, `MQL5/Files/Backup` (limpeza de regeneravel), logs antigos em `MQL5/Logs`.
- Templates e perfis **novos** (sem sobrescrever os que estao em uso).
- Parametros do proprio `sync-agent.ps1`: `-TtlMin`, `-Tail`, base do ledger.
- Leitura de tudo: conta, journal, tester, graficos, series.

---

## 4. Configuracao actual do EA (medida nos 13 graficos, 05/11 22:35)

| Input | Valor actual | Alvo para conta real | Quem decide | Nota |
|---|---|---|---|---|
| `RiskPercent` | 1.0 | **manter** ate G4 | DONO | congelado |
| `MaxDailyLossPercent` | 10.0 | rever para 5.0 antes de real | DONO | 10% num dia e agressivo a dinheiro real |
| `MaxDrawdownPercent` | 15.0 | rever para 10.0 | DONO | idem |
| `RiskPerTradeUsd` | 2.0 | manter no degrau 1 de F5 | DONO | lote minimo |
| `StopLossPoints` | 300 | **manter** | DONO | nunca operar sem SL |
| `TakeProfitPoints` | 600 | manter | DONO | RR 1:2 |
| `MinAIConfidence` | 60.0 | **nao baixar** para "fazer entrar" | DONO | ver `Q-002` |
| `EnableAIFilter` | true | manter | DONO | |
| `AllowTradeWithoutAI` | true | manter (IA fica consultiva e registada) | DONO | nao desliga o gate, so a obrigacao |
| `EnableAutonomousMode` | false | manter | DONO | |
| `EnableVolatilityFilter` | **false** | `true` **depois** de F2.1 (ATR) | DONO (`Q-005`) | ligar hoje seria filtro cego |

**Recomendacao tecnica de risco, para o dono decidir:** `MaxDailyLossPercent=10` e `MaxDrawdownPercent=15` sao valores de **conta demo de treino**, nao de conta real. Antes de G5, sugiro **5%** e **10%**. Nao altero nada disto - e nivel C.

---

## 5. Configuracoes que faltam e que bloqueiam o 10/10

| Falta | Bloqueia | Quem |
|---|---|---|
| `metaeditor5` ligado | G1 (compilar) e F4 | DONO (1 clique) |
| Python 3 + `pandas`/`numpy` instalado | `Q-002` (IA sem lado) | DONO |
| WebRequest allowlist confirmada para o gateway | IA em producao | DONO (GUI) |
| Modelo publicado para os 20 simbolos OU politica de exclusao | F3 (universalidade) | DONO decide, ALFA executa |
| `.set` do tester decidido (`Q-007`) | F4 reprodutivel | DONO |

---

## 6. Regra de ouro

**Configuracao mudada sem registo nao existe.** Toda alteracao de nivel B ou C vai para `QUADRO_ESTADO.md` com: valor antigo, valor novo, quem, hora, motivo. Sem isso, o proximo agente mede outra coisa e conclui mal - foi o que aconteceu com o `D-011` (`AllowTradeWithoutAI=false` escrito contra `true` medido nos graficos).


## 05/11/2026 23:05 - ALFA - inputs medidos nos 13 graficos + impressao digital do risco e das regras (F2.10)

Fonte: `list_open_charts` as 23:03 (13 graficos, todos com `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`). Nao li ficheiro, nao li `.mqh`, nao li `.set`: leitura do binario carregado, como o `D-021` manda.

### 1. Os 13 graficos tem os MESMOS valores nos 17 campos que contam

| Campo | Valor medido | Igual em 13/13? |
|---|---|---|
| RiskPercent | 1.0 | sim |
| MaxDailyLossPercent | 10.0 | sim |
| MaxDrawdownPercent | 15.0 | sim |
| MaxTotalRiskPercent | 10.0 | sim |
| MaxOpenPositions | 50 | sim |
| MaxTradesPerDay | 100 | sim |
| StopLossPoints / TakeProfitPoints | 300 / 600 | sim |
| RiskPerTradeUsd | 2.0 | sim |
| MinAIConfidence | 60.0 | sim |
| EnableVolatilityFilter | false | sim |
| AllowTradeWithoutAI | true | sim |
| EnableAutonomousMode | false | sim |
| ATRPeriod / ADXPeriod | 14 / 14 | sim |
| MaxSpreadPct | 0.6 | sim |

**Impressao digital (SHA-256) dos 17 campos, ordenados por nome e unidos por `;`:**

```
c79a1fbd210715642b02ed5793f58204e5c92a91a2368b14ed51f10e908e8566
```

Uso: qualquer alteracao de configuracao passa a ser detectavel por um numero, sem discutir. Se este hash mudar sem `D-0nn` a autorizar, **alguem mexeu em configuracao sem registo** - foi o que ja aconteceu no `D-011`.

### 2. Achado que abre o `F2.8`: `MagicNumber` igual nos 13

`MagicNumber=2026001` nos **13** graficos. O `F2.8` pede magic por instancia para os 13 nao se confundirem. Como esta, **nenhuma posicao pode ser atribuida a um grafico**: `Espera`/`reconciliacao` (`F2.7`) ve posicoes do mesmo magic em 13 donos possiveis, e o `MaxOpenPositions`/`MaxTradesPerDay` de cada instancia conta o que nao e dela.

Nao alterei nada: `MagicNumber` nao esta na lista de risco do dono, mas mexe em posse de posicao. Proposta: mapa 13 graficos -> 2026001..2026013, entregue como template por grafico (mecanismo 4 do `CONFIG_AGENTES.md`), com o dono a autorizar antes de reancorar. Pedido enviado ao DELTA e ao CMD.

### 3. Universo e timeframe: 3 divergencias medidas

- `CHART11` e **USDBRL em M5**; os outros 12 sao H1. Um EA H1 num M5 muda `Bars`, ATR e a janela de 900 s do `MaxPredictionAgeSec`.
- `Symbols` tem 11 nomes; os graficos sao 13. **EURUSD** esta em `Symbols` e nao tem grafico; **USDCZK, USDRUB, USDSGD** tem grafico e nao estao em `Symbols` (confirma o `B-026` do DELTA).
- `SymbolsFromMarketWatch=true` ao lado de `Symbols` fixo: duas fontes de verdade para a mesma lista.

### 4. Correccao honesta ao que escrevi as 22:58 sobre os 0 trades

`EnableVolatilityFilter=false` nos 13. Ou seja: **o ATR defeituoso nao veta entradas por este filtro** - o filtro esta desligado. O ATR% aparece no `[CENARIO]` (lote/alvo) e no trailing/partial, por isso o defeito e real, mas **nao e, sozinho, a explicacao dos 0 trades**. Quem quiser fechar o `Q-001`/0 trades tem de olhar tambem para o vetor `[VALIDATION]` (IA a 0.00/0.00, `MinAIConfidence` 60.0, `AvoidHoursGMT`) e medir qual dos vetos dispara. Registado para nao vender causa unica.

Nada compilado, nada reancorado, nenhum parametro alterado.
