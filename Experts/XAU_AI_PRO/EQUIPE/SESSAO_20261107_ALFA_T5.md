# SESSAO_20261107_ALFA_T5 â€” v1.2.186 publicada, 15/15 religados, D-089

**Autor:** ALFA (lead). **Data:** 07/11/2026, 19:26â€“19:40 local. **Estado:** build verde, frota religada, backtest a correr.

## 1. O que estava partido e como foi corrigido

O build da v1.2.186 falhava com **1 erro**:

```
error: undeclared identifier 'MinMarketScoreNoAI', Core\DecisionEngine.mqh(748:49)
```

Causa real: o input **nunca chegou a Config.mqh**. A declaraÃ§Ã£o `input double MinMarketScore = 65.0;` (linha 1168) estava intacta e nÃ£o existia nenhuma linha `MinMarketScoreNoAI` no ficheiro â€” a inserÃ§Ã£o anterior perdeu-se. `DecisionEngine.mqh` jÃ¡ usava o sÃ­mbolo na condiÃ§Ã£o (linha 748) e no comentÃ¡rio (745), logo o compilador via um nome sem declaraÃ§Ã£o.

CorreÃ§Ã£o: input inserido em `Core/Config.mqh` **linha 1187**, logo abaixo de `MinMarketScore`, com o bloco de justificaÃ§Ã£o aritmÃ©tica. Ficheiro 84 257 â†’ 85 296 bytes, UTF-8 sem BOM, CRLF preservado.

Segunda correÃ§Ã£o, de coerÃªncia: as duas linhas de journal do veto passam a imprimir o **piso efetivo** e nÃ£o o piso nominal:

```mql5
" < MinMarketScore " + DoubleToString(AILeituraReal() ? MinMarketScore : MinMarketScoreNoAI,2);
```

Sem isto o journal diria `Min=65.00` a bloquear um score calculado contra 45,0 â€” um nÃºmero a mentir sobre o outro.

## 2. C1..C6 â€” estado final

| # | Item | Ficheiro | Estado |
|---|---|---|---|
| C1 | PortÃ£o adaptativo testado ANTES da folga (P1.2337, R1=A) | Filters/MarketScenario.mqh | FEITO |
| C2 | Folga sÃ³ quando `Period()==TrendTF` (P1.2338) | Filters/MarketScenario.mqh | FEITO |
| C3 | Prefixo `contramao` cobre a permissÃ£o (P1.2339) | Core/ValidationEngine.mqh | FEITO |
| C4 | `AllowTradeWithoutAI = true` (D-088 #6) | Core/Config.mqh:637 | FEITO |
| C5 | Piso condicional `MinMarketScoreNoAI = 45.0` (P1.2341 / D-088 #5) | Core/Config.mqh:1187 + Core/DecisionEngine.mqh:748 | FEITO |
| C6 | Identidade 1.386 / 1.2.186 nas quatro fontes | .mq5:22, VersionManager.mqh:14, EventEmitter.mqh:77, .mqproj | FEITO |

C5 mecÃ¢nica: `AIEngine.mqh` publica o selo `g_aiLeituraReal` / `AILeituraReal()` (linhas 29â€“34, escrito na linha 140). `DecisionEngine` compara contra `MinMarketScore` quando houve leitura real do modelo e contra `MinMarketScoreNoAI` quando nÃ£o houve.

## 3. Identidade â€” a divergÃªncia D-073/D-074 fechou

| Fonte | Antes | Agora |
|---|---|---|
| `#property version` (XAU_AI_PRO.mq5:22) | 1.386 | **1.386** |
| `EA_VERSION_STRING` (VersionManager.mqh:14) | 1.2.186 | **1.2.186** |
| `EV_VERSION_STRING` (EventEmitter.mqh:77) | 1.2.186 | **1.2.186** |
| `XAU_AI_PRO.mqproj` | 1.290 / v1.2.9 | **1.386 / v1.2.186** |

O `.mqproj` estava parado em **v1.2.9** â€” 177 versÃµes atrÃ¡s. BOM UTF-8 preservado (239,187,191), 14 291 â†’ 14 293 bytes.

## 4. Build

```
Compilation succeeded: 0 errors, 0 warnings
0 errors, 0 warnings, 21 472 ms elapsed, cpu='X64 Regular'
```

`.ex5` = **967 328 bytes**, mtime **2026-11-07 19:30:46**. Anterior (v1.2.185): 964 998 bytes, MD5 146BB7FCâ€¦C419E.

Nota operacional medida: **recompilar reinicia automaticamente todas as instÃ¢ncias**. O journal de 19:30:46â€“19:30:47 mostra os 15 `[START] XAU_AI_PRO v1.2.186` sem qualquer reattach manual â€” mas com os inputs **guardados no grÃ¡fico**, que ainda diziam `AllowTradeWithoutAI=false`.

## 5. Frota â€” 15/15 religados com inputs explÃ­citos

O valor guardado no grÃ¡fico vence a omissÃ£o compilada. Por isso `AllowTradeWithoutAI=true` no cÃ³digo nÃ£o mudava nada: os 15 grÃ¡ficos mantinham `false`. Reattach explÃ­cito nos 15:

```
AutoTrade=true,MagicNumber=2026001,AIUseGateway=true,RiskPercent=1.0,
MaxDailyLossPercent=10.0,MaxDailyLossUsd=60.0,MaxDrawdownPercent=50.0,
MaxTradesPerDay=100,MaxOpenPositions=50,MaxExposurePercent=20.0,
MaxTotalRiskPercent=10.0,MaxTotalRiskOpenUsd=60.0,MinAIConfidence=60.0,
AllowTradeWithoutAI=true,AIUnavailableConfidenceCap=40.0,EnableAIFilter=true,
MinMarketScore=65.0,MinMarketScoreNoAI=45.0,BlockZeroAIScore=true,
RequireStopLoss=true,EnableStoplessEntry=true,StoplessEmergencyRMult=1.5,
RealGuardMaxUnarmedPositions=1,EnableAdaptiveTrendGate=true,
ScenarioTrendAtrSlack=1.0,EnableAutonomousMode=true
```

Resultado medido no journal: **15 linhas `[START] XAU_AI_PRO v1.2.186`** Ã s 19:31:06 (XAUUSD) e 19:31:30â€“19:31:36 (restantes 14). Nenhum erro de parÃ¢metro.

## 6. Gateway

`GET http://127.0.0.1:9011/api/ai/predict?symbol=XAUUSD&timeframe=H1` sem token â†’ **HTTP 401**. O servidor estÃ¡ no ar e a exigir credencial (o EA usa o `XAU_GATEWAY_TOKEN` de 64 caracteres do `.env`). NÃ£o Ã© serviÃ§o: morre com a sessÃ£o.

## 7. Conta

`113568614` MetaQuotes-Demo: saldo **12 636.32**, equity **12 636.32**, margem 0.00, **0 posiÃ§Ãµes, 0 ordens**. `experts_trade_allowed=true`.

## 8. O que NÃƒO mudou

- Piso **65,0** continua a valer sempre que existe leitura real de IA.
- Magic 2026001, envelopes 10/60/50 %, `MaxTotalRiskPercent` 10, `MaxTotalRiskOpenUsd` 60, exposiÃ§Ã£o 20 %.
- Nenhum lote, SL, TP, alvo, spread ou regra de entrada/saÃ­da foi tocado.
- **GATE_REAL continua 2 de 11.** NÃ£o existe "10/10": 10/10 = 11/11 + 30 dias de forward em demo + autorizaÃ§Ã£o escrita.
- Conta flat â€” nada foi aberto.

## 9. O que falta, e de quem Ã©

| Item | Dono | Estado |
|---|---|---|
| NÃºmero do piso sem IA (45 / 50 / 40) | DONO | 45,0 Ã© proposta do ALFA (P1.2341); muda por input |
| Medir `TREND CONTRA OK` com selo Q-079/B | DELTA | depende de mercado aberto |
| ATR da folga em H1 no USDBRL (Ãºnico M5) | DELTA | idem |
| Separar entradas com IA real vs sem IA | DELTA | idem |
| Commit dos fontes + EQUIPE + .set | CMD | ALFA nÃ£o faz commit |
| Reattach/confirmar antes de domingo 19:00â€“20:00 local | CMD | inputs vivem nos grÃ¡ficos |

## 10. Fecho

A aritmÃ©tica continua a mandar: sem IA o MarketScore tem teto **65/115 = 56,52**. Com `MinMarketScoreNoAI=45,0` o EA pode entrar sem modelo; com 65,0 nÃ£o podia. Foi essa a decisÃ£o do DONO (#5 e #6 sÃ£o a mesma decisÃ£o). O que a mÃ¡quina faz agora Ã© o que foi pedido â€” e o journal dirÃ¡, sÃ­mbolo a sÃ­mbolo, qual piso foi usado.

