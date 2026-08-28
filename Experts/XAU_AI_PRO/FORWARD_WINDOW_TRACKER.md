# XAU_AI_PRO — FORWARD WINDOW TRACKER (JANELA LIMPA 20.5 → 20.11)

> Criado: 2026-08-28 18:40 UTC | Autor: MetaTrader Assistant
> **Marco oficial da janela limpa: 2026-08-28 18:35 UTC (= 21:35 horário do servidor, UTC+3).**
> Regras da fase: **11 símbolos · zero mudança de código · zero otimização forçada ·
> métricas só da janela limpa.**

---

## 1. CONJUNTO OFICIAL (11 símbolos — congelado)

XAUUSD · EURUSD · USDBRL · AUDUSD · NZDUSD · USDCHF · USDSEK · GBPUSD · USDCAD · USDJPY · USDCNH — todos M5, magic 2026001, SL 300 / TP 600, EMA 50/200, RSI 14/45/55, NewsFilter=0, AIFilter=0, lote 0.01.

**Fora do conjunto (bloqueados até normalização de risco por símbolo):** XAGUSD, US30, US500, USTEC.

---

## 2. MARCO E CHECKPOINTS

| Marco | UTC | Servidor (UTC+3) | Ação |
|---|---|---|---|
| **WINDOW START** | 2026-08-28 18:35 | 2026-08-28 21:35 | ✅ registrado (DAY 01) |
| 20.6 Fase A | 2026-08-29 18:35 | 2026-08-29 21:35 | Endurance 24h — consolidar |
| 20.6 Fase B1 | 2026-08-31 18:35 | 2026-08-31 21:35 | Endurance 72h |
| 20.6 Fase B2 | 2026-09-04 18:35 | 2026-09-04 21:35 | Endurance 7d |
| 20.6 Fase C | 2026-09-27 18:35 | 2026-09-27 21:35 | Endurance 30d + gate financeiro |

---

## 3. EVIDÊNCIA INICIAL (snapshot 28/08 18:40 UTC)

| Item | Valor | Veredito |
|---|---|---|
| Eventos na janela (`forward_test_events.csv`, UTF-16) | **209** após 21:35 servidor | ✅ gravando |
| Sequência final do stream | 11× `SYSTEM_START/FORWARD_TEST_START` (… USDCNH ONLINE) | ✅ reanexação dos 11 |
| `system_status.json` @21:37:40 servidor | HEALTHY · algo ON · risco OPEN · DD 0,69% · AI SELL (conf 36,57) | ✅ backend saudável |
| Posições herdadas (pré-janela, em voo) | GBPUSD SELL #10263362670 · USDCHF BUY #10263362709 · USDCAD BUY #10263363321 | ⏳ resolvem via SL/TP |
| Dataset Python | 173.162.556 B (crescendo) | ✅ coleta ativa |

---

## 4. REGISTRO DIÁRIO (preencher a cada check-in; métricas SOMENTE da janela limpa)

| DAY | Data (UTC) | Trades | Win% | PF | Expectancy | MaxDD | Sharpe | AI acc | Rejeições | Uptime | Recovery | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 01 | 28/08 | — | — | — | — | — | — | — | — | — | — | início 18:35 UTC |
| 02 | 29/08 | | | | | | | | | | | 24h |
| 03 | 30/08 | | | | | | | | | | | |
| 04 | 31/08 | | | | | | | | | | | 72h |
| 05–07 | 01–03/09 | | | | | | | | | | | |
| 08 | 04/09 | | | | | | | | | | | 7d |
| 09–30 | 05–26/09 | | | | | | | | | | | |
| 31 | 27/09 | | | | | | | | | | | 30d + GATE |

---

## 5. RECONCILIAÇÃO (20.8) — contrato de fontes

| Fonte | Arquivo | Papel | Observações |
|---|---|---|---|
| Broker | History (deals magic 2026001) | Verdade de execução | fonte canônica de tickets/px/vol/profit |
| AuditLog | `full_audit.csv` (novo) | Por-deal EA | ignorar `audit_log.csv` (Common, legado Fase 9) |
| EventStream | `forward_test_events.csv` (UTF-16) | Eventos/estado | fonte oficial de eventos |
| Backend | `system_status.json` + `dataset.csv` | Heartbeat/coleta | — |
| Telemetria | `forward_test_session.csv` (Common) | ConnGuard snapshot | não é contrato de trade |

**Critérios de saída (20.8):** 0 missing · 0 duplicates não justificados · 0 mismatch · 0 posições órfãs.

---

## 6. REGRAS VIGENTES (não negociáveis durante a janela)

1. Zero alteração no núcleo do EA.
2. Conjunto de símbolos congelado (pode ACRESCENTAR FX, não remover).
3. Métricas financeiras calculadas **exclusivamente** da janela limpa (18:35 UTC 28/08 em diante).
4. Qualidade técnica ≠ resultado financeiro: gate 20.11 só abre com PF ≥ 1,0 + endurance + recovery + reconciliação em evidência.
5. Pendências técnicas (hash ex5 stale, `AIMetrics.mqh` untracked, duplicidades full_audit, `forward_test_trades.csv` vazio) são registradas para 20.10/21 — não corrigidas agora.

---

## 8. TRANSIÇÃO 20.5 → 20.6 (registrada 28/08 18:45 UTC)

### Gate 20.5 — ✅ PASS (operacional)

| Critério | Evidência | Resultado |
|---|---|---|
| 11 charts com EA (M5, magic 2026001) | list_open_charts (11 charts, todos anexados) | ✅ |
| Conjunto congelado (XAG/índices fora) | lista oficial 11 símbolos | ✅ |
| Algoritmos ON | system_status.json `algo_trading_enabled=true` | ✅ |
| Journal sem `Falha ao copiar RSI` / erros | scan tail 600 KB (8.347 linhas) → **0 hits** | ✅ |
| Stream de eventos gravando | 211 eventos na janela; reanexação 11× registrada | ✅ |
| Backend/Python vivos | dataset cresce; system_status atualiza | ✅ |
| Posições herdadas | 3 posições com SL/TP, sem intervenção | ✅ (segue EA) |

### 20.6 — Fase A (24h) — 🔄 IN PROGRESS

- Início: 28/08 21:35 servidor (18:35 UTC)
- Checkpoint: 29/08 21:35 servidor (18:35 UTC)
- Métricas a consolidar no checkpoint: trades da janela, PF, Win%, Expectancy, MaxDD,
  rejeições, uptime, + 1ª rodada de reconciliação 20.8.
- Regime: **passivo** — sem scripts novos, sem alteração de EA/pipeline, sem intervenção.

### DAY 01 — baseline (28/08, 18:40–21:40 UTC)

- Eventos na janela: **212** (stream continua; última escrita 21:29 servidor, transição de estado).
- Backend: HEALTHY · algo ON · DD 0,29% · IA SELL (conf 36,3) · dataset 173.165.220 B.
- **Posições herdadas (pré-janela, abertas 21:05 servidor):** 3 — GBPUSD SELL #10263362670,
  USDCHF BUY #10263362709, USDCAD BUY #10263363321. Seguem com SL/TP.
  - Tratamento de métricas: entram na reconciliação **quando fecharem** (close_time ≥ 21:35 = dentro
    da janela), mas com **entry_time < janela** — sinalizar como "carried (entrada pré-janela)"
    na contagem de trades, para não inflar/contaminar PF/WinRate da janela.
- Trades fechados na janela até aqui: **0** (nenhum deal com close_time ≥ 21:35 até 21:40).

### CONTRATO DO CHECKPOINT 24h (29/08 18:35 UTC) — aceito como oficial

**Entregáveis obrigatórios (DAY 01 / DAY 02):**
Trades novos (janela limpa, close_time ≥ 21:35 servidor) · Win Rate · Profit Factor ·
Expectancy · Max Drawdown · Sharpe · Rejeições · Uptime · Eventos (count/sanity) ·
AI status (READY/STALE/ERROR) · SAFE/RECOVERY count · Reconciliação.

**Escopo da reconciliação no checkpoint — 4 fontes:**
`BROKER (deals magic 2026001)` × `full_audit.csv` × `forward_test_events.csv` ×
`forward_test_trades.csv` — critérios: **missing = 0 · duplicate = 0 (não justificadas) ·
mismatch = 0 · orphan = 0**.

**Tratamento das posições herdadas:** 3 posições (GBPUSD SELL #10263362670, USDCHF BUY
#10263362709, USDCAD BUY #10263363321) — NÃO contam como trades novos. Se fecharem com
close_time ≥ início da janela, entram como **carried (entrada pré-janela)** na reconciliação,
com nota explícita, sem impacto em PF/WinRate novos.

**Regra de evidência (inalterada):** amostra curta NÃO é prova de qualidade de estratégia.
PF/WinRate só são considerados com janela limpa suficientemente longa (20.6-B 72h → 20.6-C 7d
→ 30d) + reconciliação + recovery. Nenhuma "melhoria" de código durante o experimento.

**Sequência pós-24h (PASS):** 20.6-B (72h) → 20.6-C (7d) → 20.7 Recovery → 20.8 Reconciliação
final → 20.10 Release → 20.11 Gate financeiro.

---

### 9. FIM DE SEMANA — MERCADO FECHADO (sexta 28/08)

- Fechamento confirmado: 28/08 ~23:59:58 servidor (UTC+3) = 20:59 UTC = **17:59 Brasília**.
- Status no fechamento: HEALTHY · algo ON · 5 entradas no dia · DD 2,05% · IA **STALE** (esperado: pipeline sem predições novas com mercado fechado — recupera na reabertura; é um **recovery natural**).
- Fim de semana: **sem ticks → sem trades novos, sem eventos**; EA/processo permanecem vivos.
- Posições herdadas/abertas antes do fechamento ficam **carried** (swap de sexta→segunda aplica; conta demo). Não contam como trades novos.

### 9.1 CALENDÁRIO AJUSTADO (checkpoints em HORAS DE MERCADO ATIVO)

| Marco | Critério | Data prevista | Hora Brasília |
|---|---|---|---|
| Reopen check | mercado reabre domingo ~21:00 UTC | dom 30/08 | ~17:00–18:00 |
| **20.6-A · 24h ativo** | 24h com ticks (28/08 18:35 UTC + fechamento) | **seg 31/08** | ~15:35–16:35 |
| 20.6-B · 72h ativo | +3 sessões | ~qui 03/09 | — |
| 20.6-C · 7d ativo | ~7 sessões de mercado | ~seg 07/09 | — |
| 30d ativo / gate | ~30 sessões | ~meados out | — |

> Nota: marcos em **horas de mercado ativo** substituem o relógio de parede. O 24h **ativo** cai na segunda 31/08 (~15:35–16:35 Brasília) — coincide com o marco 72h de parede; mantemos ambos registrados. Nenhuma alteração de código.

---

## 10. ETAPA 20.14 — ENDURANCE PROFISSIONAL (registro oficial)

> Adicionado: 2026-08-28 20:51 UTC (MetaTrader Assistant)
> Regime: **passivo** — nenhuma alteração de EA/código/pipeline durante a janela.
> Protocolo completo: `ETAPA_20_14_ENDURANCE.md` (repo XAU_AI_PRO).

### 10.1 Baseline DAY 01 (snapshot 28/08 23:59:58 servidor)

| Item | Valor | Veredito |
|---|---|---|
| Estado | HEALTHY · terminal OK · algo ON · trade OK | ✅ |
| Símbolos (congelado) | 11 charts M5, 1 EA cada (magic 2026001) | ✅ |
| Drawdown | 2,07% | ⚠️ dentro do limite (15%) |
| Trades hoje | 5 (aberturas) | — |
| Balance / Equity | 116,81 / 114,40 | — |
| AI | STALE (mercado fechado — esperado, recupera na reabertura) | ⏳ recovery natural |
| Dataset | 173.230.046 B (crescendo) | ✅ |
| Posições abertas | 5: GBPUSD SELL, USDCHF BUY, USDCAD BUY, **2× USDJPY BUY** | ⚠️ ver 10.2 |

### 10.2 🔴 ACHADO — duplicação de execução USDJPY (EM INVESTIGAÇÃO)

- **2 posições BUY USDJPY abertas em 22:15:02/03** (mesmo candle, mesmo preço 160.118, SL 300/TP 600):
  - `#10264640104` (22:15:02) e `#10264640153` (22:15:03), ambas volume 0.02 (full_audit), lotes 0.01
- **Não** é chart duplicado (11 charts, 1 EA cada — auditado via list_open_charts).
- **full_audit.csv confirma 2 tickets reais distintos** (não é log duplicado).
- Explicação provável: retry de execução duplicado no OrderManager (2 envios no mesmo tick) OU
  MarketScanner/TradePipeline chamado 2× no mesmo tick para o mesmo símbolo.
- **Sem intervenção** (regra passiva): posições seguem com SL/TP; entram na reconciliação com tag `dup-exec`.
- Ação futura (FORA da janela, pós-20.14): revisar guarda de deduplicação por símbolo/tick no OrderManager.
- Impacto em métricas: **NFU x2 no mesmo símbolo** — registrar manualmente no checkpoint para não
  inflar PF (`dup-exec` conta como 1 decisão, 2 execuções).

### 10.3 Contrato do checkpoint 24h (mantido do tracker §8)

Entregáveis: trades novos da janela, WinRate, PF, Expectancy, MaxDD, Sharpe, rejeições, uptime,
eventos, AI status, SAFE/RECOVERY, reconciliação 4 fontes (BROKER × full_audit × events ×
forward_test_trades). Tratamento das posições herdadas: `carried` (entrada pré-janela), sem impacto
em PF/WinRate novos. Duplicação USDJPY: tag `dup-exec`.