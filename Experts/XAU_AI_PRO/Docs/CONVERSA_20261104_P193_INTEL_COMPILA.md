# Ciclo 96 - 04/11/2026 20:25 - P1.93: o modulo Market Intelligence nunca compilou (v1.2.138)

## 1. Estado medido a entrada

| Item | Medido |
|---|---|
| `git status` | 12 ficheiros modificados + 2 novos (`Filters/MarketIntelligence.mqh`, `Profiles/Tester/XAU_V3_majors.set`) |
| Fontes mais novas que o binario | **sim**: `AIEngine.mqh` 20:07:22, `Config.mqh` 20:07:32, `DecisionEngine.mqh` 20:06:58, `ExecutionEngine.mqh` 20:08:05, `MarketIntelligence.mqh` 20:07:41, `XAU_AI_PRO.mq5` 20:06:39, contra `.ex5` de 20:05:18 |
| Compilacao desse estado | `Result: 8 errors, 7 warnings` |
| `.ex5` depois da compilacao falhada | **AUSENTE do disco** (o MetaEditor apagou o binario) |
| Strategy Tester | ainda ocupado: `Tester\logs\20261104.log` 163.503.296 -> 163.733.688 bytes em 6 s |

O EA corria nos 13 graficos com o binario em memoria, mas nao havia ficheiro para reanexar: qualquer reinicio deixaria o terminal sem robo.

## 2. O defeito - tres causas independentes

1. `Filters/MarketIntelligence.mqh` declarava `SESSION_CLOSED`, `SESSION_TOKIO`, `SESSION_LONDRES`, `SESSION_NOVA_YORK` e `SESSION_OVERLAP` no escopo global, onde `Filters/GlobalScenario.mqh` ja declara `SESSION_CLOSED` dentro de `ENUM_SESSION_BUCKET` -> `error 282: identifier 'SESSION_CLOSED' already used`, mais `warning 42` de conversao implicita entre os dois enums.
2. `RefreshEconomicCalendar()` chamava `CalendarValueLast(changeId, values, NULL, NULL)` e depois lia `values[i].currency`, `.event_name`, `.impact`, `.actual`, `.forecast`, `.previous` - campos que nao existem em `MqlCalendarValue` -> seis `error 256: undeclared identifier`.
3. `UpdateMarketContext()` usava `tm.month`, mas `MqlDateTime` so tem `tm.mon` -> `error 256: undeclared identifier 'month'`.

## 3. Correcoes

- Enumeradores do modulo passam a ter prefixo `MS_` (`MS_CLOSED`, `MS_SYDNEY`, `MS_TOKIO`, `MS_LONDRES`, `MS_NOVA_YORK`, `MS_OVERLAP`, `MS_DAY_*`, `MS_INTEL_*`). `GlobalScenario.mqh` nao foi tocado - e mais antigo e partilhado.
- Calendario lido como o `NewsFilter.mqh` ja fazia: `CalendarValueHistory` -> `CalendarEventById` (nome, importancia, `country_id`) -> `CalendarCountryById` (moeda). O erro 4014 do Strategy Tester passa a ser tratado como condicao permanente (1 linha, nao falha).
- `tm.month` -> `tm.mon`.

## 4. P1.94 e P1.95, medidos logo apos o primeiro arranque

- **P1.94 - sessao calculada com hora do servidor.** As 23:20 UTC o journal publicou `Sessao: Toquio` quando a janela correcta era Sydney (22:00-01:00 GMT): o codigo usava `tm.hour` de `TimeCurrent()` (servidor em UTC+3) embora o cabecalho de `GetMarketSession` diga GMT. Passa a `TimeGMT()` para sessao, fecho de sessao e fecho de mercado.
- **P1.95 - filtro de moeda depois do truncamento.** O scan enchia 20 vagas e so depois filtrava moeda, portanto as vagas podiam encher-se com moedas irrelevantes: `Proximo evento:  (impacto=0)` com dezenas de releases no calendario do terminal (medido com `economic_calendar_list_values`: 10+ eventos entre 04/11 e 11/11). O filtro passa para dentro do scan (`IntelCurrencyRelevant`), como no `NewsFilter.mqh`.

## 5. Checklist do dono executada

| Passo pedido | Resultado medido |
|---|---|
| Token de 64 caracteres em `MQL5\Files\XAU_AI_PRO\.env` | presente: `token_len=64` |
| Mesmo token em `backend\.env` (`XAU_GATEWAY_TOKEN`) | presente e **igual**: `iguais=True` (comprovado sem publicar o valor) |
| Gateway Python a correr | porta 9011 a escuta (`Test-NetConnection` = True) |
| Allowlist / WebRequest no MT5 | NAO e alteravel por ferramenta (fica na GUI, fora das raizes MCP). Provado indirectamente: o EA recebeu `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes`, logo a URL ja esta autorizada |
| Recompilar e reanexar | feito: `profile_apply Default` -> `profile_apply XAI_P216_LIVE`, 13x `[START] XAU_AI_PRO v1.2.138` as 20:19:21 |
| Journal `[MARKET INTELLIGENCE]` | 13 linhas as 20:24:18 (bloco completo; `Sessao: Sydney` depois da correcao P1.94) |
| Journal `[INTEL LOT]` | nao apareceu: so imprime quando o fator < 1.0 (score < 70). Medido: score 100/100, nivel `MS_INTEL_EXPERT` |

## 6. Validacao

- `Result: 0 errors, 0 warnings, 19288 ms elapsed, cpu='X64 Regular'`
- `.ex5` 857.638 bytes, `04/11/2026 20:23:44`
- Versao tripla alinhada: `EA_VERSION_STRING "1.2.138"`, cabecalho `// XAU_AI_PRO v1.2.138`, `#property version "1.338"`
- IA real confirmada no journal: `[AI] GATEWAY | XAUUSD | H1 | 1122 bytes` e `[AI] PYTHON | XAUUSD | SELL | PRICE=4062.39 | CONF=70.00%`
- Gateway medido directamente: H1 `available=True signal=SELL conf=70.0 model=XAUUSD 1H`; M15/M5/M30 `available=False` com motivo do gate walk-forward; sem token HTTP 401 (fail-closed)

## 7. O que fica aberto

- **P1.96** (novo): `BlockHighImpactNewsMin=15` continua inerte porque `GetNextEventForSymbol` devolve evento vazio. O veto de noticia em vigor e o do `NewsFilter` (usado pelo `DecisionEngine`), portanto nao ha buraco de protecao, mas o input de inteligencia nao morde.
- **P-02**: Testador ocupado (log a crescer). Re-medir com v1.2.138 quando libertar.
- **P-03/P-04/P-05**, `pytest` ausente do `.venv`, mojibake antigo em `CONVERSAS.md`, duplo rastreio de `Files/XAU_AI_PRO`.
- `[DATA] SEM LEITURA | ATR=0.000000` em varios simbolos nao-XAU (medido 20:19:24) - investigar em ciclo proprio.

## 8. Ficheiros tocados

`Filters/MarketIntelligence.mqh` (reescrito: enums MS_, calendario nativo, GMT, filtro de moeda), `Enterprise/VersionManager.mqh` (1.2.138 + changelog), `XAU_AI_PRO.mq5` (cabecalho + `#property version "1.338"`), `XAU_AI_PRO.ex5` (recompilado), docs.