# SESSAO 2026-11-08 - ALFA (v1.2.188)

## Autorizacao do DONO nesta sessao

1. (a) P1.3479 - tags `__DATETIME__` no log-gate.
2. (b) P1.2336 (contador `trades=` do `[SCANNER] RESUMO`) e P1.139 (passo 1 silencioso
   do `AllowTradeEx`).
3. (c) Reanexo da frota de 15 graficos.

Registo no canal: **D-107** (DECISOES.md), linha em IDS.md, PRESENCA.md e SYNC_LOG.md.

## O que foi medido antes de mexer

- `__DATETIME__` e macro de **compilacao**: `loggate_atr_no_read_XAUUSD_1793915847.bin`
  repete-se em todas as chamadas do mesmo build. Remover o marcador libertaria
  **zero** vagas -> a hipotese inicial foi abandonada e o P1.121 mantido.
- Censo de tags: 94 chamadas, 83 bases; 7 tags do ATR x 15 simbolos = 105 vagas, mais
  ~20 familias por simbolo -> universo **> 400** contra `TESTER_GATE_MAX_TAGS = 128`.
- Ao encher, o ramo antigo devolvia `true` sem registar a tag -> throttle desligado ate
  ao fim da corrida. Origem das 278 536 linhas de `[TREND] LEITURA SUSPEITA`.

## Alteracoes (3 defeitos + 3 bump de versao)

| Ficheiro | Mudanca |
|---|---|
| `Monitoring/AccountLogGate.mqh` | `TESTER_GATE_MAX_TAGS` 128 -> 512; evicao LRU (padrao P1.114 do DiagGate); aviso `[DIAG] LOGGATE TESTER tabela cheia` 1x/h |
| `Core/MarketScanner.mqh` | reset dos contadores de janela so dentro de `if(publicouResumo)`; `g_scanJanela = now` incondicional |
| `Core/DecisionEngine.mqh` | `DECISION BLOCKED \| VALIDATION` com tag `dblock_` + `ValidationGateTag`, janela 3600 s |
| `XAU_AI_PRO.mq5` | `#property version "1.388"` |
| `Enterprise/VersionManager.mqh` | `EA_VERSION_STRING "1.2.188"` + changelog em `m_current.changes` |
| `Monitoring/EventEmitter.mqh` | `EV_VERSION_STRING "1.2.188"` (lido por `Integration/ExternalBridge.mqh:90`) |

`Indicators/VolatilityFilter.mqh` ficou **intacto** (as 7 tags do ATR continuam com
`__DATETIME__`, por decisao medida).

## Compilacao

`EQUIPE\tools\compile-ea.ps1` -> backup `XAU_AI_PRO_v12188_20261108_055917.ex5`
(966 012 B, MD5 `CAE840F6...`); **0 errors / 0 warnings / 24 856 ms**; `.ex5`
**970 168 B** as 05:59:42 **MD5 `943DB7CB6955299C6A470141B942BC54`**.

## Reanexo (como se faz sem automacao de foco - D-103)

`profile_apply` do perfil **selecionado** devolve `ok=false`. Aplicar um perfil **nao
selecionado** funciona e reinicia os EAs (carregam o `.ex5` do disco):

1. `profile_add` de um perfil temporario qualquer (para o alvo deixar de ser o selecionado);
2. `profile_apply <perfil alvo>`;
3. `profile_delete` dos temporarios.

Alternativa testada e util para **um** grafico: `chart_save_template` do proprio grafico
seguido de `chart_apply_template` (motivo=7 -> `[STOP]` + `[START]` com a versao nova).

**Armadilha medida:** o journal do MCP fica atras do ficheiro. A prova de reanexo faz-se
em `MQL5\Logs\<AAAAMMDD>.log` (`Select-String '\[START\] XAU_AI_PRO v'`), nunca pelo
`get_expert_journal`, que devolveu 0 registos para uma janela que ja tinha 15 `[START]`.

Resultado: **15/15 `[START] XAU_AI_PRO v1.2.188`** (USDCLP 06:01:45 por template, os
outros 14 as 06:01:54 por `profile_apply`), perfil `XAU_AI_PRO_15CHARTS_Q071` continua o
selecionado, zero ordens, conta demo flat, mercado fechado.

## Pendente / entregue a outros

- **DELTA** mede e fecha (criterios escritos no D-107): saturacao do log-gate, `trades=N`
  do RESUMO e a linha `DECISION BLOCKED | VALIDATION`.
- **CMD**: nada pendente deste lado; o binario do forward de 09/11 00:05 passa a ser
  `943DB7CB...` (v1.2.188).
- Continua por autorizar: `EQUIPE/tools/agente-briefing.ps1` (falso "gateway DOWN" por
  `-SkipHttpErrorCheck` inexistente em PS 5.1, e "1.386?" fixo no rodape).
- **GATE_REAL 2 de 11, forward 0 de 30 - nao existe 10/10.**
