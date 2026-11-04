# Conversa - 04/11/2026 20:31 - P1.96 e P1.97: o "Proximo evento" saia sempre vazio

Ciclo 97 do XAU_AI_PRO. Build final **v1.2.140**.

## 1. Ponto de partida

O ciclo 96 tinha fechado o P1.93 (o modulo `Filters/MarketIntelligence.mqh`
nunca compilava), o P1.94 (sessao calculada com a hora do servidor) e o P1.95
(filtro de moeda aplicado depois do truncamento a 20 vagas). O bloco
`[MARKET INTELLIGENCE]` passou a ser publicado, mas duas linhas continuavam
erradas em todos os 13 graficos:

```
Proximo evento:  (impacto=0)
Min para evento: -1
```

## 2. O que foi medido

| Instante | Build | Fonte | Linha |
|---|---|---|---|
| 20:24:18 | v1.2.138 | USDCZK H1 | `Proximo evento:  (impacto=0)` |
| 20:28:53 | v1.2.139 | USDCAD H1 | `Proximo evento:  (impacto=0)` |
| 20:31:13 | v1.2.140 | GBPUSD H1 | `Proximo evento: Licenciamento de Veiculos (Mensal) (impacto=1)` |

Em paralelo, `economic_calendar_list_values` para a janela 04/11 20:00 ->
12/11 00:00 devolveu **30 releases** (truncado), com `time` a partir de
2026-11-04T23:00:00. Ou seja: o calendario do terminal tinha dado; quem o
estava a deitar fora era o EA.

## 3. Duas causas, ambas na leitura do calendario

### 3.1 P1.96 - o pais nunca era resolvido

Em `RefreshEconomicCalendar` a variavel `MqlCalendarCountry cn` era
**declarada e nunca preenchida**: a chamada `CalendarCountryById(ev.country_id,
cn)` desapareceu na reescrita que moveu o filtro de moeda para dentro do scan
(P1.95). Consequencia: `cn.currency` era a string vazia e
`IntelCurrencyRelevant("", relevant)` devolvia `false` para **todos** os
eventos, logo o `continue` esvaziava a lista antes de encher `g_nextEvents`.

Correcao: reposta a resolucao do pais antes do filtro, com o mesmo padrao que o
`Filters/NewsFilter.mqh` ja usava e que sempre funcionou:

```
CalendarValueHistory(values, from, to)
  -> CalendarEventById(values[i].event_id, ev)
  -> CalendarCountryById(ev.country_id, cn)
  -> filtro de moeda
```

### 3.2 P1.97 - as moedas do simbolo eram derivadas com a funcao errada

Depois de reposta a resolucao do pais, o bloco **continuava vazio**
(medido as 20:28:53). A causa estava uma linha acima:
`IntelSymbolCurrencies` chamava `NewsSplitCsv(symbol, currencies)`.
`NewsSplitCsv` divide uma **lista CSV por virgula**; aplicada a `"USDCAD"`
devolve um unico elemento `"USDCAD"`, que nunca iguala a moeda de um evento
(`"USD"` ou `"CAD"`). Com o filtro dentro do scan, o resultado passou a ser zero
de forma deterministica em todos os 13 graficos.

O `NewsFilter.mqh` ja tinha a funcao correcta desde antes:
`SymbolNewsCurrencies()`, que parte o simbolo em blocos de 3 caracteres, valida
cada um com `IsFxCurrency`, limpa sufixos (`#`, `.pro`, `micro`, `_i`, `.r`,
`.cash`) e cai em `USD` quando nao reconhece nada.

Correcao: `IntelSymbolCurrencies` passa a delegar em `SymbolNewsCurrencies`, e
`GetNextEventForSymbol` passa a usar a mesma funcao em vez de repetir a
heuristica.

## 4. Prova

Journal as 20:31:13.217, grafico GBPUSD H1, build v1.2.140:

```
=== [MARKET INTELLIGENCE] ===
Simbolo: GBPUSD
Sessao: Sydney
Dia: MS_DAY_NORMAL | Semana: OK
Feriado: NAO
Min para fechar sessao: 1409
Min para fechar mercado: 2789
Proximo evento: Licenciamento de Veiculos (Mensal) (impacto=1)
Min para evento: 568
Score Inteligencia: 100.0/100
Nivel: MS_INTEL_EXPERT
Pode negociar: SIM |
============================
```

`Licenciamento de Veiculos` e um release do Reino Unido, portanto a moeda do
evento (`GBP`) foi resolvida e comparada com sucesso contra a lista derivada do
simbolo (`GBP` + `USD`). `Min para evento: 568` corresponde a 568 minutos
depois das 23:31 de servidor, isto e 09:59 do dia seguinte - coerente com o
horario do release.

## 5. Impacto em producao

`BlockHighImpactNewsMin` e os minutos para o evento deixam de ser inertes: o
`GetNextEventForSymbol` devolve evento real e o score de inteligencia passa a
poder descontar por proximidade de noticia de impacto alto.

Nenhum limite, regra de entrada ou de saida, lote, alvo, stop, spread, preco ou
parametro de risco foi alterado. Mudou a derivacao de uma lista de moedas a
partir do nome do simbolo e a leitura de um campo de calendario que estava a ser
lido como vazio.

## 6. Estado do build

| Item | Valor |
|---|---|
| `EA_VERSION_STRING` | `1.2.140` |
| `#property version` | `"1.340"` (HG-01 alinhado) |
| Compilacao | `Result: 0 errors, 0 warnings, 25971 ms elapsed, cpu='X64 Regular'` |
| `.ex5` | 858.546 B, 04/11/2026 20:30:50 |
| Reattach | `profile_apply Default` -> `XAI_P216_LIVE`; 13x `[START] XAU_AI_PRO v1.2.140` |
| Conta | 113568614 DEMO, saldo 12.592,02, 0 posicoes, 0 ordens |
| Gateway | 127.0.0.1:9011 no ar; H1 `available=True SELL conf=70.0` |
| Testador | OCUPADO - P-02 continua aberto |

## 7. O que continua aberto

- **P-02 (DONO):** o run das 18:08 continua vivo; sem ele nao ha re-mediacao de
  PF com este build.
- **P-03 / P-04 / P-05:** alvo diario duplicado, `StoplessEmergencyPoints=0`,
  notificacoes com `10060 wsa error`.
- **`[DATA] SEM LEITURA | ATR=0.000000`** em simbolos nao-XAU (medido 20:19:24).
- **Conta real:** continua proibida por regra. O unico PF historico (0,6206) foi
  medido num build sem ADX e sem IA e nao descreve este EA.