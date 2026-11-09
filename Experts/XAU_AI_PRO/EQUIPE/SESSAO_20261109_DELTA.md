# SESSAO DELTA - 09/11/2026 - arranque medido do forward 30 dias (dia 1)

> Autor: DELTA. Hora da medicao: 09:15-09:20 local (12:15-12:20Z). Mandato: D-095 ATIVO.
> Objetivo desta sessao: medir o dia 1 do forward, registar o relatorio diario e dar veredicto.
> Nao executei ordens, nao alterei inputs de risco, nao reanexei EA, nao recompilei.

## 1. Forward - estado medido

| Item | Valor |
|---|---|
| `inicio_medido` | 2026-11-09 (validado pela ferramenta: >= 09/11 e dia util) |
| Relatorio do dia | `EQUIPE/RELATORIOS/20261109.md` criado por `dono-mandato.ps1 relatorio` |
| Forward apos registo | **1 de 30 dias com medicao** |
| Tarefa diaria | `XAU_AI_PRO_DonoRelatorio` as 23:50 regrava o mesmo ficheiro (valores de fim de dia) |

O contador do forward conta **dias com medicao registada**, nao dias de lucro. Um dia com
perda e' dia medido. O que nao conta e' dia sem relatorio (`dia_sem_medicao_nao_conta`).

## 2. Estado do terminal e da conta (medido)

| Item | Valor |
|---|---|
| Conta | 113568614 demo hedging, MetaQuotes-Demo, build 6308 |
| Ligacao | synchronized, ping 213 ms, ultima perda de ligacao 12:14:47Z, reauth 12:14:48Z |
| Saldo / equity | 12 634,12 / 12 635,02 USD |
| Graficos com EA | 15 de 15, `XAU_AI_PRO` v1.2.188, magic 2026001 |
| EA reiniciado | 09:08:25-09:08:26 (os 15 graficos arrancaram de novo hoje) |
| Binario x fonte | BATEM |
| Gateway 9011 | HTTP 401 (modo LEITURA) |
| GATE_REAL | 3 de 11 |
| Mandato | versao 1, ATIVO, `check` OK |

## 3. Resultado do dia 1 ate 09:20

```
[RESUMO] master=SIM | posicoes: 0 EA (+0.00 USD) + 1 manual |
         dia fechado: -119.40 de 40.00 USD (-299%) |
         trades=0 | IA(XAUUSD)=UNAVAILABLE 0.0%
```

Movimentos de hoje (hora do servidor):

| Hora | Ticket | Origem | Movimento | Resultado |
|---|---|---|---|---|
| 02:00:20 | 11290116448 | **Expert** (magic 2026001) | venda 0,06 XAUUSD a 4056,31, **sem SL**, TP 4054,65 | fechou 02:15:14 a 4076,21 = **-119,40** |
| 03:47:35 | 11291969094 | Client (manual) | venda 0,1 XAUUSD a 4120,26, sem SL | fechou 08:54:34 por TP = **+117,20** |
| 14:09:18 | 11301846622 | Client (manual) | compra 0,1 XAUUSD a 4109,04, TP 4110,53, **SL 0** | aberta, +0,90 |

Leitura: o unico trade do EA no dia perdeu **-119,40 USD** contra um limite declarado de
`MaxDailyLossUsd = 60,0` e um orcamento diario de 40,0 USD. O EA passou o resto do dia em
`dia fechado` e nao voltou a operar. Os outros dois movimentos sao do DONO (sem magic),
ficam fora da estatistica do EA e nao contam para o gate.

## 4. Defeitos que contaminam o forward (medidos hoje, nao corrigidos por mim)

- **P1.3499 (regressao, ainda aberta) - fuga de universo.** Os 15 graficos estao com
  `SymbolsFromMarketWatch = true`. Log de hoje:
  `[SYMS] UNIVERSO | marketwatch=25 | deSymbols=15 | adicionadosDoMarketWatch=10 | ativos=25`
  e `[CENARIO]` a avaliar **AMD, MSFT, NVDA** (acoes) e EURUSD. O sistema declarado e' de 15
  simbolos; o que esta a correr e' de 25, com instrumentos fora do universo aprovado.
- **P1.3500 (repetido hoje) - perda diaria violada 2x por um trade.** `EnableStoplessEntry=true`
  deixa entrar sem SL e `AllowMinLotOverride=true` forca 0,06 lote; o resultado foi 2000 pontos
  de excursao sem corte duro. O bloqueio de 60 USD so' disparou **depois** do dano.
- **P1.3502 (novo) - ciclo de FAILURE MODE por ligacao.** 09:13:32
  `TERMINAL_CONNECTED=0 / ACCOUNT_TRADE_ALLOWED=0`, seguido de
  `SAFE_MODE -> RECOVERY -> REVALIDATE` a cada 60 s. O terminal caiu e voltou (`connection lost`
  12:14:47Z, reauth 12:14:48Z). Enquanto durar, o EA nao abre nada.
- **P1.3503 (novo) - IA indisponivel em todos os simbolos.** `[AI] INDISPONIVEL` 17 vezes
  (XAUUSD 14, XAUUSD/M5 3) e `IA(XAUUSD)=UNAVAILABLE 0.0%`. Com gateway em 401 o EA cai no piso
  `MinMarketScoreNoAI = 45,0`. Nao e' defeito do gateway (modo LEITURA e' decisao D-095), mas o
  forward esta a correr **sem IA**, e o dossie tem de dizer isso.
- **P1.3504 (novo) - feed morto em 4 simbolos.** `COTACAO VELHA` com idade de 227 337 s (USDBRL),
  238 152 s (USDCOP), 239 981 s (USDCLP), 5 023 s (USDRUB). O guarda bloqueia corretamente;
  significa que 4 dos 15 simbolos nao estao a ser medidos.
- **P1.3505 (novo) - XAUUSD sem leitura de ADX.** `[CENARIO] XAUUSD SEM_LEITURA ADX=sem leitura`,
  o que tira o simbolo principal da adaptacao por regime.
- `[COST] BLOQUEADO` em USDCZK: custo 2,76 USD = 303% do alvo. Comportamento correto do
  CostGate, registado como evidencia e nao como defeito.

## 5. Veredicto do DELTA

1. **Forward: INICIADO e dia 1 MEDIDO (1/30).** O arranque esta registado e reproduzivel:
   `dono-mandato.ps1 estado` mostra `forward 1/30`; o dia 2 passa a contar quando houver
   relatorio de 10/11.
2. **O dia 1 nao e' dia valido para o dossie final enquanto P1.3499 estiver aberto.** O forward
   esta a medir 25 simbolos, nao os 15 declarados. Conta como dia medido (o contador e' de
   medicao), mas fica anotado como **contaminado** e nao serve de prova do sistema de 15 simbolos.
3. **Assinatura do DELTA continua bloqueada.** Faltam 8 criterios do GATE_REAL, faltam 29 dias
   e a configuracao tem de estar a que foi aprovada. Nao existe 10/10 e nao ha qualquer base
   para conta real.
4. **Risco imediato:** a posicao manual 11301846622 (0,1 XAUUSD, **SL 0**) esta aberta sem
   protecao. E' do DONO, nao do EA, e eu nao a fecho por conta propria.

## 6. O que nao fiz e por que

- **Nao fechei 11301846622.** Fechar posicao exige instrucao explicita do DONO com o ticket.
- **Nao corrigi `SymbolsFromMarketWatch` nem `AllowMinLotOverride`.** Alterar input em 15 graficos
  obriga a reanexar o EA, muda o MD5 e mata o uptime do forward. E' decisao de ALFA/CMD com
  registo em `DECISOES.md`, nao do DELTA a meio de um dia medido.
- **Nao recompilei, nao reanexei, nao mexi em risco.** `RiskPercent`, `MaxDailyLossPercent`,
  `MaxDrawdownPercent`, `MaxDailyLossUsd` ficaram exatamente como estavam (0,5 / 3,0 / 6,0 / 60,0).
- **Nao escrevi em `DECISOES.md` nem em `IDS.md`.** O registo formal de ID e' do CMD; deixo o
  pedido no fim deste ficheiro.

## 7. Pedido ao CMD

Registar, com ID novo, os defeitos medidos hoje: P1.3499 (reaberta por evidencia de 09/11),
P1.3500 (repeticao com -119,40), P1.3502, P1.3503, P1.3504, P1.3505. E decidir, com o DONO,
se o arranque do forward deve ser re-medido em 10/11 depois de fechar P1.3499 - a minha
recomendacao e' **sim**: um forward de 30 dias com o universo errado produz um dossie inutil.

---
DELTA | medicao de 09/11/2026 09:20 local | sem ordens, sem edicao de risco
