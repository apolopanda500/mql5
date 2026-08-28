# XAU_AI_PRO — Registro de Progresso

> Plataforma XAUUSD: modular, auditável, testável e preparada para operação.
> Última atualização: 2026-08-27 (v1.3.1)

---

## Resumo de status (Etapas do roadmap)

| Etapa | Status | Observação |
|---|---|---|
| 1 — SignalCore (entrada + A/B) | ✅ | Baseline aprovado; estratégia B (EMA+ADX+Breakout) experimental |
| 2 — DecisionEngine | ✅ | Auditado; TF da EMA do score alinhado à estratégia; anti-repaint (vela fechada) |
| 3 — ValidationEngine | ✅ | Auditado (9 filtros); código de rejeição estruturado adicionado |
| 4 — RiskEngine | ✅ | Cadeia equity→%→SL→tick→lote completa; drawdown via RiskHub |
| 5 — ExecutionEngine | ✅ | Auditado; não-grava sinais; inclui simulação e blindagem a duplicidade |
| 6 — PositionManager | ✅ | BE, trailing ATR, parcial, controle de posições; padrões registrados |
| 7 — IA/ML (infra) | ✅ | Veto/direção/score/lote/feedback + **AIMetrics** (accuracy/precision/recall) |
| 8 — Backtest protocol | 🔄 | A/B rodados; E (OOS) inconclusivo; F (recente) rodando |
| 9 — Robustez | ⏳ | — |
| 10 — Broker/Environment | ✅ | Detecção automática (símbolo/digits/point/spread/volume/stops/freeze); `ProbeSymbolProfile()` |
| 11 — Data + Telemetry | ✅ (parcial) | código de rejeição integrado; "porquê não entrou" disponível |
| 12 — Dashboard | ✅ | Ampliado: Trend, Regime, IA Dir/Conf, DD RiskHub e mais (build OK) |
| 13 — PLATFORM/BACKEND | ✅ | DatabaseManager (SQLite): analytics reais — `GetTotalProfit/Trades/WinRate/ProfitFactor` implementados |
| 14 — Segurança operacional | ✅ | CircuitBreaker robusto: kill-switch, DD, spread(10x), IA fallback, broker, mercado anormal, persistência, auto-recovery, FailSafe API |
| 15 — Forward test | ⏳ | — |

---

## Resultado A/B (Etapa 1/8) — XAUUSD M5 (14–24/08, ticks reais)

| Métrica | A (baseline RSI) | B (EMA+ADX+Breakout) |
|---|---|---|
| Lucro | **-14,45** | -66,17 |
| Profit Factor | **0,8855** | 0,2033 |
| Trades | 49 | 15 |
| Win rate | 59% | 40% |

**Decisão:** baseline A aprovado como entrada corrente. B mantido experimental (não segue para produção até atingir consistência).

**Requisito de engenharia:** cada backtest every-tick XAU M5 leva ~1h50–2h real. Perfil `TESTE_F_OTIMIZADO.ini` (logs off, Model=2) acelera janelas longas.

## IA — snapshot vs. walk-forward
`prediction_XAUUSD.json` é um snapshot único e estático. Rodar o Teste C/D com ele num período longo é inválido (mesma predição "BUY 87.86" em todas as barras). Só é válido após predição intraperioodal / walk-forward (pipeline Python externo).

## Mudanças v1.3.1 (recentes)
- `ValidationEngine.mqh`: `enum ValidationRejectCode` + `GetLastReject()` + `RejectCodeToString()` — observabilidade sem mudar decisão.
- `DecisionEngine.mqh`: EMA do `MarketScore` alinhada ao TF da estratégia; usa vela fechada `[1]`.
- `SignalCore.mqh`: seletor `XAU_UseNewStrategy` permite A/B em runtime; interfaces `GetSignal()/GetSignal(symbol)` preservadas.
- `SymbolValidator.mqh`: `ProbeSymbolProfile()` consolida detecção broker (digits/point/tick/volume/stops/freeze/spread).
- `Dashboard.mqh`: ampliado com Trend, Regime, IA Dir/Conf, DD (RiskHub).
- Perfis de teste otimizados (`.ini` com logs off) p/ janelas longas.
- Build validado: 0 erros, 0 warnings em todo o projeto.

## Notas de risco
- `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent` não alterados (capital real).