# SESSAO 07/11/2026 - ALFA turno 4 - DECISOES DO DONO E ORDENS DE TRABALHO

- **Papel:** ALFA (lider, revisao; nao faz commit nem push)
- **Origem:** respostas do DONO as 6 perguntas de destravamento, 07/11 19:24
- **Estado do LOCK:** LIVRE (li antes de escrever)
- **Conta 113568614:** 0 posicoes, 0 ordens, 12 636,32 - intocada
- **GATE_REAL:** 2 de 11 (nao muda com estas decisoes)
- **Nada foi compilado, reanexado, sondado ou testado ainda.** Este documento e o
  registo da decisao e a ordem de trabalho; a execucao vem a seguir.

---

## 1. As seis respostas, como foram dadas

| # | Pergunta | Resposta do DONO | Efeito |
|---|---|---|---|
| 1 | R1 - folga vs `EnableAdaptiveTrendGate` | **A** | a folga passa a respeitar `EnableAdaptiveTrendGate=false` |
| 2 | Corrigir e compilar hoje | **SIM** | P1.2337 + P1.2338 + P1.2339 hoje, reattach antes da abertura |
| 3 | Sondar o gateway 9011 | **SIM** | sonda de leitura agora e antes das 19:00 de domingo |
| 4 | Backtest hoje | **SIM** | tester XAUUSD H1 para contar a folga |
| 5 | Piso `MinMarketScore=65` | **REVER** | denominador/condicao do piso vao mudar (P1.140) |
| 6 | 14 simbolos bloqueados por `AllowTradeWithoutAI=false` | **OPERAR TODOS E TUDO** | `AllowTradeWithoutAI=true` nos 15 graficos |

---

## 2. A conta que o DONO tem de ver antes de eu tocar no piso

`DecisionEngine.mqh:462-477`: parcelas maximas = 20 (EMA) + 15 (RSI) + 15 (ADX)
+ 10 (KCI dir) + 5 (KCI vol) = **65 pontos**; a IA vale `0,50 x confianca`, ate 50;
`maxScorePoints = 115`; `MarketScore = 100 x pts / 115`.

- **Sem IA o maximo e 65/115 = 56,52.** O piso 65 **nunca** e atingido sem IA.
- Logo, **(6) sozinho nao faz ninguem entrar**: com `AllowTradeWithoutAI=true` e
  piso 65, os 14 simbolos continuam a ser recusados no `MinMarketScore`.
- **(5) e (6) sao a MESMA decisao.** Sem rever o piso, (6) e decorativo.

Desenho proposto para (5) - **o numero e do DONO, eu nao escolho risco sozinho**:

- `MinMarketScore` mantem **65,0** quando a leitura de IA e **real** (XAUUSD hoje);
- novo input `MinMarketScoreNoAI`, aplicado quando a IA esta **indisponivel**;
- proposta **45,0** = 79,6 % do maximo tecnico (56,52);
- alternativas: **50,0** = 88,5 % (mais exigente) ou **40,0** = 70,8 % (mais permissivo).

Implemento 45,0 como default e fica marcado `P1.2341 - confirmar numero` ate o
DONO dizer outra coisa.

---

## 3. O que (6) custa, dito sem enfeite

`AllowTradeWithoutAI=true` em 14 simbolos remove **a unica guarda** que o projecto
tinha para "nao negociar sem IA" (D-082). E decisao explicita do dono, em **demo**,
e o resto do risco fica intacto: `MaxDrawdownPercent 50`, `MaxDailyLossPercent 10`,
`MaxDailyLossUsd 60`, `MaxTotalRiskPercent 10`, `MaxTotalRiskOpenUsd 60`,
`MaxExposurePercent 20`, magic 2026001, lotes, SL, TP.

Consequencias que ficam registadas:

1. O **G3** (verde auditado, so em tester) deixa de descrever o que corre em
   producao; passa a haver entradas sem parcela de IA.
2. Nesses 14 simbolos o **piso condicional** passa a ser o unico travao de
   qualidade. Se o numero de (5) for frouxo, entra lixo - e em demo, com risco
   limitado, mas entra.
3. `GATE_REAL` continua **2 de 11**. Isto nao acrescenta verde nenhum.
4. Nao e 10/10 e nao se escreve "pronto a 10/10".

---

## 4. Ordens de trabalho (codigo)

| ID | Ficheiro | Alteracao exacta |
|---|---|---|
| C1 | `Filters/MarketScenario.mqh:199-222` | mover o bloco da folga para **depois** de `if(!EnableAdaptiveTrendGate)`. Com `false` volta a ser veto absoluto; com `true` mantem folga + ADX/cenario |
| C2 | `Indicators/VolatilityFilter.mqh` + `MarketScenario.mqh` | a folga passa a medir ATR de **H1** (`TrendTF`), nao `Period()`. **Nao** reutilizar `g_atrCache*`: essa cache e indexada so por simbolo e usa `Period()` - reutiliza-la corrompe o ATR do grafico. Criar `GetATRH1(symbol)` com cache propria, ou (mais barato) so aplicar a folga quando `Period()==(int)TrendTF` |
| C3 | `Core/ValidationEngine.mqh:363` | `StringFind(trendWhy,"contramao PERMITIDA")==0` -> `StringFind(trendWhy,"contramao")==0`, para a folga tambem imprimir `[VALIDATION] TREND CONTRA OK` |
| C4 | `Core/Config.mqh:637` | `AllowTradeWithoutAI` default `false` -> `true`, com comentario a citar a autorizacao do DONO de 07/11/2026 |
| C5 | `Core/Config.mqh` + `Core/DecisionEngine.mqh:744` | novo `input double MinMarketScoreNoAI = 45.0` e comparacao condicional (65 com IA real, NoAI sem IA) |
| C6 | `XAU_AI_PRO.mqproj` + `Monitoring/EventEmitter.mqh` | identidades divergentes (D-073/D-074): `.mqproj` diz `1.290/v1.2.9` e `EV_VERSION_STRING` diz `1.2.9`. Alinhar com `1.2.186` / `#property 1.386` |

---

## 5. Facto operacional que se falha sempre

**Os inputs vivem nos graficos.** Mudar o default no `Config.mqh` **nao** muda os 15
graficos ja anexados - eles guardam o valor com que foram postos.

O reattach tem de passar **explicitamente**:

```
AllowTradeWithoutAI=true,MinMarketScoreNoAI=45.0,AIGatewayToken=,MinMarketScore=65.0,MagicNumber=2026001,MaxDrawdownPercent=50.0,MaxDailyLossUsd=60.0,MaxTotalRiskPercent=10.0,MaxTotalRiskOpenUsd=60.0,MaxExposurePercent=20.0
```

`AIGatewayToken` fica **vazio** de proposito: `AIGatewayTokenEfetivo()` le o `.env`
(64 chars) quando o input tem menos de 32 - `AIConnector.mqh:845`.

---

## 6. Medicao

- **Gateway 9011** (autorizado): sonda de leitura agora e **antes das 19:00 de
  domingo**. Nao e servico: morre com a sessao. Se estiver em baixo a abertura, o
  XAUUSD responde `disponivel=false`.
- **Tester** (autorizado): XAUUSD H1, 01/10-06/11. O portao de tendencia
  (`ValidationEngine.mqh:345`) e avaliado **antes** da IA (`:478`), e em tester
  `ValidationLogAllowed` devolve `true` sem rate-limit (`:161`), logo conta-se
  `Q-079/B` e `TREND CONTRA OK`. Limite: tester nao faz WebRequest (D-082), nao
  mede rentabilidade.
- **Janela real:** ultimo tick medido `06/11 23:59:58` server; primeira barra da
  semana `02/11 01:00` server. Reabertura estimada **domingo 19:00-20:00 local**
  (segunda 00:00-01:00 server).
- **G11 (30 dias forward):** so precisa de data de inicio = primeiro dia com trade
  real em demo. Nao se adianta por decreto.

---

## 7. O que NAO mudou

Conta plana em **12 636,32**, 0 posicoes, 0 ordens. **GATE_REAL 2 de 11.**
Zero compiles, zero reattach, zero sondas, zero backtests ate este momento.
Nenhum parametro de risco tocado.

- ALFA, 07/11/2026 19:25
