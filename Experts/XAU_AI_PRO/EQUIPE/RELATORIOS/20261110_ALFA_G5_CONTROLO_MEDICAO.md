# RELATORIO DE ETAPA - ALFA - 10/11/2026 03:55 (hora local medida as 03:55:15)

**Agente:** ALFA (Agente 1) | **Mandato:** D-095 ATIVO, modo ZERO_INTERRUPCOES_DURANTE_EXECUCAO
**Binario em producao:** v1.2.191, 977 654 B, MD5 `71ED34C690C9593D209A69E95F0EFFB6`, mtime 10/11 02:23:07 (inalterado)
**Conta:** demo 113568614 (MetaQuotes-Demo) | **Janela forward:** ancora 11/11 00:05 servidor, **0 de 30** | **GATE_REAL: 3 de 11** (inalterado)

---

## 1. O que esta etapa fez

Fechei a medição que faltava para o **G5**: o run de controlo `7706413661306435354` (12 meses, XAUUSD H1, `Model=2`, `EnableStaleDataGuard=false` como única divergência da produção, binário `71ED34C6`).

Duas descobertas mudaram a leitura do resultado:

1. **O run foi truncado** — não chegou a 2026.11.09.
2. **O meu próprio medidor de funil estava cego** — e isso invalidava qualquer número que eu publicasse antes de o corrigir.

---

## 2. Factos medidos

### 2.1 O run e o segmento declarado

| Item | Valor |
|---|---|
| `run_id` | 7706413661306435354 |
| config | `ALFA_G5_12M_STALE0.ini` + `ALFA_G5_D_STALE0.set` |
| período pedido | 2025.11.09 00:00 → 2026.11.09 00:00 |
| **última barra simulada** | **2026.08.04 08:00:00** |
| **fatia realmente medida** | **268 de 365 dias = 73.4%** |
| lançado / morto | 02:40:53.798 / 03:43:44.843 (`Cloud servers switched off`) |
| causa da morte | **restart do terminal às 03:43:38** (não foi conclusão normal) |
| relatório do testador | **não existe** (`tester_list_result_windows` = `[]`) |
| segmento do log | `Tester\logs\20261110.log` linhas **53355..124304** = bytes **14900494..35053000** |

**Armadilha registada:** o log do testador é **UTF-16LE** (35 053 000 B = 2 × 17 526 499 chars + 2). Citar "offset em bytes" contando caracteres erra por factor 2. A baseline `ALFA_G5_TAIL_offset.txt` está em `35053000` = EOF, com **0 bytes novos** — prova independente de que o run está morto.

### 2.2 O funil (fonte: `[SIGNAL]`, `DECISION BLOCKED`, `TRADE EXECUTADO`)

| Etapa | Número | % |
|---|---|---|
| ciclos H1 | 4218 | — |
| ciclos com `sinais=1` | 366 | — |
| `[SIGNAL]` direccionais | **365** (152 BUY / 213 SELL) | 100 % |
| bloqueados na `VALIDATION` | **355** | **97.3 %** |
| chegaram à execução | **10** (9 trades + 1 `ExecFail` em 2025.11.19) | 2.7 % |

**O funil fecha exactamente: 355 bloqueios + 10 execuções = 365 sinais.** Nenhum sinal desaparece sem rasto no log.

Motivos de bloqueio: **TREND SELL 116**, **AVOID HOUR 112**, **TREND BUY 84**, **ADX 29**.
As duas primeiras são **64.2 %** dos bloqueios: as 6 horas GMT proibidas (`AvoidHoursGMT=9,11,14,18,20,22`) e o veto de contramão.

### 2.3 O resultado

| Métrica | Valor |
|---|---|
| trades fechados | **9** (todos SELL, `SIGNAL=-1`, `LOT=0.26`, tickets #2..#20) |
| WIN | 2 × +100.10 = **+200.20** |
| LOSS | 7 × −78.00 = **−546.00** |
| líquido | **−345.80 USD** |
| win rate | **22.22 %** |
| profit factor | **0.3667** |
| drawdown máx. (curva de trades fechados) | **3.50 %** (pico 12 736.42 → vale 12 290.52) |
| projeção linear a 12 meses | **12.26 trades** |

> O DD de 3.50 % é calculado sobre a curva de trades **fechados**; não inclui flutuante intra-trade. Não substitui o relatório do testador, que não existe.

---

## 3. Leitura dos gates (o que este run decide)

| Gate | Estado | Provado por |
|---|---|---|
| **G5** ≥ 100 trades (piso Q-026) | **VERMELHO — fora de alcance (8.2×)** | 12.26 projetados vs 100. Não é falta de janela: é desenho. |
| **G7** PF ≥ 1.20 | **VERMELHO** | PF **0.3667**; quatro runs agora abaixo de 1.2 (0.3667 / 0.6643 / 0.6603 / 0.6206). |
| **G6** DD ≤ 8 % | não reprova | 3.50 % no backtest; **quem decide é o forward**. |
| **G8** ≥ 30 % short | **não invocável** | o backtest é 100 % SELL por causa da IA congelada — não serve de prova. |
| **G3** (IA) | **não fecha por backtest** | ver §4. |

---

## 4. A IA no testador está congelada — confirmado por medição (P1.3515)

Em **4218 barras** o log mostra **um único `PRICE=4063.84`** e **um único `SCORE=36.35`**; em produção o `SCORE` varia 65.8–82.8. Somam-se **755** linhas `erro=4014` (WebRequest não permitido no testador) e **3794** linhas `Erro=5004` (falha de rotação de log, `fallback=sem truncagem`).

Consequência prática: **nenhum gate que dependa da IA se fecha por backtest.** O `PF 0.3667` mede o caminho técnico com a IA congelada, não a estratégia completa.

---

## 5. Correções a mim mesmo (registadas, não escondidas)

1. **D-146 projetava ~2.8 trades/12M — está errado.** Aquele número saiu de um run de **3M com a guarda de cotação velha LIGADA** (medido agora: 178 `[SIGNAL]` → **0** `TRADE EXECUTADO`). Um run com a guarda ligada mede o bloqueio da guarda. Número corrigido para **12.26/12M**. A conclusão qualitativa do D-146 mantém-se: **97.3 % dos sinais morrem na VALIDATION**.
2. **P1.3520 (aberta):** o `[SCANNER] RESUMO` aparece em **três formatos** para a mesma linha: `NoSignal=1` (sem sinal), `AllowTrade=1` (sinal sem trade) e — no ciclo que **abre ordem** — `trades=1 | bloqueios=0` **sem campo de estado nenhum**. A minha primeira regex ancorou em `NoSignal`, casou **3852 de 4218** linhas e somou `sinais=0`, escondendo **366** ciclos com sinal. Corrigido **antes** de publicar qualquer número. Regra nova: o funil mede-se por `[SIGNAL]` / `DECISION BLOCKED` / `TRADE EXECUTADO`, **nunca** pelo `RESUMO`.

---

## 6. O que foi escrito no canal

- `EQUIPE/DECISOES.md` → **D-148** (bloco completo, 8 secções).
- `EQUIPE/SYNC_LOG.md` → 4 linhas (decisão, nota do truncamento, correção ao D-146, abertura da P1.3520).
- `EQUIPE/IDS.md` → **D-148** e **P1.3520** reservados.
- `XAU_AI_PRO/PENDENCIAS.md` → **P1.3520** (secção completa com o formato das duas variantes).
- Este relatório.

Todas as escritas por `equipe-sync.ps1 append` (append puro, byte-a-byte, sem reescrever blocos de outros agentes).

---

## 7. O que não fiz (e porquê)

- **Não recompilei, não fiz deploy, não mexi em gráficos, não mudei inputs, não abri ordem.** O congelamento do D-147 (11/11 00:05 → 12/11) continua intacto; esta etapa foi leitura de log.
- **Não toquei em parâmetros de risco.** `RiskPercent 0.5`, `MaxDailyLossPercent 3.0`, `MaxDailyLossUsd 600.0`, `MaxDrawdownPercent 6.0` como estavam.
- **Não corri outro backtest.** O testador é single-instance e o D-147 fecha a janela; um novo run agora só reproduziria a mesma fatia sem mudar o G5.
- **Não "fechei" o G5 por declaração.** Está vermelho com número.

---

## 8. O que precisa de decisão do DONO (não é atraso corrigível por mim)

1. **G5 — o piso de 100 trades (Q-026) é inalcançável com este desenho.** Duas saídas: (a) mudar o desenho de entrada (hoje 64.2 % dos bloqueios são AVOID HOUR + veto de contramão), ou (b) baixar o piso de 100 para um número compatível com ~12 trades/12M. A escolha é do DONO — eu não altero critério de gate nem parâmetro de estratégia.
2. **G10 — 1 clique:** remover do Market Watch os 10 símbolos que não são do universo (25 → 15). É a única ação que falta e é manual por regra.
3. **Reboot para o G2:** o auto-arranque do gateway está instalado e medido (`AIGateway9011_Watchdog`, `LastTaskResult 0`, 401 sem token / 200 com Bearer), mas a prova do reboot só existe com um reboot real — e um reboot agora reiniciaria o relógio do G4 (que fecha sozinho em 11/11 02:35:37).

---

## 9. Próximo passo (ALFA)

- Sem intervenção até **12/11** (D-147).
- **11/11 00:05 servidor:** abre a janela do G11. Acompanho por leitura de journal, sem tocar em nada, e reporto o dia 1 com número medido.
- Depois de 12/11: fechar a P1.3520 pelo caminho (a) — campos com nome estável no log — é compilação, e fica para depois do congelamento.

---

**Assinatura de identidade:** binário `71ED34C690C9593D209A69E95F0EFFB6` / 977 654 B / mtime 10/11 02:23:07 — **inalterado** desde o início da etapa. Nenhum ficheiro `.mq5`/`.mqh` foi modificado neste turno.
