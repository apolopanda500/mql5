# ALFA - APLICADO: `EnableStoplessEntry=false` em 15/15 e forward pronto a correr

Data: 10/11/2026 10:20 (local) | Ordem do DONO: "aplicar autorizado avancar iniciar forward"
Binario: XAU_AI_PRO v1.391 (v1.2.191) | 977 654 B | MD5 `71ED34C690C9593D209A69E95F0EFFB6` | mtime 2026-11-10T02:23:07

---

## 1. O que mudou, exactamente

Uma coisa: `EnableStoplessEntry` passou de `true` para `false` nos 15 graficos do perfil `XAU_AI_PRO_15CHARTS_Q071`.

Efeito pretendido: o SL passa a ir na propria ordem (`StopLossPoints=300`) e a posicao deixa de nascer sem stop a espera de um vigia de software. No XAUUSD a 0,01 lote, 300 pontos = **3,00 USD** de risco - dentro do tecto `MaxRiskPerTradeUsd=8.00`. E' isto que desbloqueia o `MIN_LOT_EXCEEDS_RISK_CAP` reportado em P1.3540 (21,18 USD com o vigia a 1,5R).

## 2. Prova, em cadeia

| passo | ferramenta | medido |
|---|---|---|
| 1 | `get_expert_advisor_parameters` | `EnableStoplessEntry` = indice 192, `bool`, default `true` -> mudanca de input, **nao exige recompilar** |
| 2 | leitura dos 15 `.chr` | `true` 15/15, 901 372 B |
| 3 | `alfa_aplicar_stopless_v2.ps1` | round-trip byte-a-byte OK 15/15 **antes** de gravar; depois `false=15 true=0 semCampo=0 bomDuplo=0`; 901 402 B (+2 B/ficheiro) |
| 4 | `profile_apply XAU_AI_PRO_15CHARTS_Q071` | `ok:false` 2x |
| 5 | 15 x `chart_save_template` + flip + 15 x `chart_apply_template` | `ok:true` 15/15 |
| 6 | 15 x `chart_save_template` (prova do EA vivo) | `ALFA_SLV_01..15`: `false` 15/15, EA presente 15/15 |
| 7 | `Get-FileHash` no fim | 977 654 B, MD5 `71ED34C6...`, mtime inalterado |

O passo 6 e' o que conta: ler o `.chr` prova o disco, nao o EA em memoria. O re-save do template le' o EA vivo e e' a unica leitura autoritativa dos 323 inputs disponivel aqui.

## 3. Campos que nao podiam ser arrastados (medidos antes e depois, 15/15 iguais)

`MaxDrawdownPercent=6.0` | `EnableMTFConfirmation=true` | `AIHasSignalAuthority=true` | `SymbolsFromMarketWatch=false` | `Symbols` = 15 (XAUUSD,USDCLP,USDCOP,USDCZK,USDRUB,USDSGD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH) | `StopLossPoints=300` | `LadderArmUsd=5.0` | `MaxDailyLossPercent=3.0` | `EnableMoneyLadder=true`

## 4. A armadilha que quase custou caro

O `.tpl` do MT5 carrega `symbol=`, `period_type`, `period_size`, `digits` e a escala fixa. Aplicar UM template aos 15 graficos teria transformado os 15 em USDCZK. Foram 15 templates distintos, cada um tirado do proprio grafico. Regra registada (P1.3562).

## 5. Estado do terminal as 10:20

- 15 graficos, EA ligado em 15/15, `[START] XAU_AI_PRO v1.2.191 | conta=113568614 | saldo=12593.83 | equity=12632.63`
- `[SYMS] UNIVERSO | marketwatch=16 | deSymbols=15 | ativos=15 | origem=Symbols+grafico`
- 16 modulos OK, `[KILL SWITCH] LIVRE`
- 4 posicoes MANUAIS sem SL em XAUUSD (`reason=Client`): `#11324108563` 0.10, `#11324122370` 0.05, `#11324143493` 0.01, `#11324557698` 0.01 - todas fora do orcamento diario do EA pelo filtro de magic. O EA recusa XAUUSD por `ManualGuard`. Nao toquei em nenhuma.

## 6. Rasto operacional desta ronda (para nao se repetir)

- `profile_apply` devolve `ok:false` neste terminal -> usar a rota dos templates (P1.3561).
- O canal esteve bloqueado por `LOCK :: DELTA | edit | expira 10/11 10:18` e recusou 5 escrituras minhas; ficou tudo registado em P1.3566.
- O DELTA tomou P1.3545..P1.3550 nesse intervalo, por isso os meus IDs sao **P1.3560..P1.3568**.
- `PENDENCIAS.md` (fora de `EQUIPE/`, sem lock) duplicou um bloco numa segunda passagem; corrigido por cirurgia de bytes, uma copia unica.
- `append` e `aviso` exigem `-De` alem de `-Arquivo`/`-Para`: sem isso respondem "quem escreve tem de ser o dono do lock" mesmo com o lock na nossa mao.

## 7. O que falta, e de quem depende

| # | item | dono |
|---|---|---|
| 1 | `MaxRiskPerTradeUsd` 8.0 -> 3.0 e `MaxTotalRiskOpenUsd` 60 -> 10 | DONO |
| 2 | `MaxDailyLossPercent` fica em 3.0: os 30% ao dia sao inalcancaveis com `MaxDrawdownPercent=6.0` (P1.3537) | DONO |
| 3 | as 4 posicoes manuais sem SL: fechar / por SL / deixar | DONO |
| 4 | contador de perda BRUTA (P1.3538) exige recompilar -> reinicia os 30 dias | DONO decide o que vale mais |
| 5 | `XAU_GATEWAY_TOKEN` nos graficos (Q-021) | operador |
| 6 | conta real, bloqueada por F2/F6 | fora do alcance daqui |

## 8. Regras da janela que continuam de pe (D-147)

1. Ate' ao fim da janela nao ha recompile nem deploy: qualquer MD5 diferente de `71ED34C6` depois de 11/11 00:05 **reinicia os 30 dias a zero**.
2. Nao reiniciar o terminal antes de 11/11 02:35:37 (o G4 precisa de 24 h).
3. Nao mexer nos inputs do perfil vivo `XAU_AI_PRO_15CHARTS_Q071`.
4. So o CMD toca, e so com autorizacao do DONO.

Estado: **a config esta' aplicada e provada; o forward tem o que precisa para arrancar as 11/11 00:05 servidor sem tocar no binario.**
