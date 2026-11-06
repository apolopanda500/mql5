# BACKLOG - XAU_AI_PRO

**Regra:** todo item tem dono, criterio de aceitacao e evidencia. Item sem
evidencia fica `ABERTO`. Nada se marca `FECHADO` por opiniao.
**Atualizado:** 05/11/2026 22:50 por CMD

Legenda dono: **A**=ALFA, **D**=DELTA, **C**=CMD, **O**=DONO.
Prioridade: **P0** = bloqueia conta real, **P1** = bloqueia 10/10,
**P2** = melhoria.

---

## P0 - Bloqueiam conta real

| ID | Item | Dono | Criterio de aceitacao | Estado |
|---|---|---|---|---|
| B-001 | Kill switch (manual + automatico) | A | fecha todas as posicoes; testado uma vez com hora | ABERTO |
| B-002 | Teto de exposicao total e `MaxPositions` | A | limite aplicado no codigo e observado em teste | ABERTO |
| B-003 | Perda diaria / drawdown bloqueiam entradas | A | teste com conta demo a atingir o limite | ABERTO |
| B-004 | Guarda de spread e slippage | A | entrada recusada acima do limite, com log | ABERTO |
| B-005 | Idempotencia de ordem | A | reenvio nao duplica posicao | ABERTO |
| B-006 | Reconciliacao EA x corretora | A | 0 divergencias em 24 h | ABERTO |
| B-007 | Magic number unico por instancia | A | 13 graficos sem se confundirem | ABERTO |
| B-008 | Deteccao de desconexao / cotacao velha | A | nao opera com tick velho | ABERTO |
| B-009 | Hash dos parametros de risco congelado | C | hash registado em `_SYNC/`; muda -> alerta | ABERTO |
| B-010 | Runbook de incidente | D | escrito e testado uma vez | ABERTO |

## P1 - Bloqueiam 10/10

| ID | Item | Dono | Criterio | Estado |
|---|---|---|---|---|
| B-011 | `Q-001` handles ATR morrem no reload | A | 13/13 com ATR/RSI validos 72 h, 0 `erro=4807` | ABERTO |
| B-012 | `Q-002` IA devolve `BUY=0/SELL=0` | A | 0 sinais degenerados em 1 000 predicoes | ABERTO |
| B-013 | `Q-003` `dataset.csv` multi-escritor | A | 1 escritor eleito; 0 linhas truncadas | ABERTO |
| B-014 | `Q-006` modulos orfaos | A | removidos ou integrados, com decisao | ABERTO |
| B-015 | `Q-009` gateway nao e servico Windows | D | sobe sozinho apos reboot | ABERTO |
| B-016 | `Q-010` commit `6fe56e53` mal rotulado | C | nota de correcao no historico | ABERTO |
| B-017 | `Q-011` PF 0.6206 | D | remedido com periodo e amostra | ABERTO |
| B-018 | `Q-012` dois `D-012` | D | fundidos ou anotados | ABERTO |
| B-019 | Suite Python: 14 falhas de `test_vip_progress` | C | 0 failed (fixture com data relativa) | ABERTO |
| B-020 | Suite Python: 6 modulos sem `tkinter` | C | excluidos ou Tcl/Tk instalado | ABERTO |
| B-021 | Suite Python: 4 errors | C | 0 errors | ABERTO |
| B-022 | CVE alta (dependabot 234) | C | 0 vulnerabilidades altas | ABERTO |
| B-023 | Cobertura de modelo H1 (1 de 21) | O+A | decisao escrita: universo reduzido ou modelos publicados | AGUARDA DONO |
| B-024 | Politica de `AllowTradeWithoutAI` | O | assinada por escrito (hoje `true`) | AGUARDA DONO |
| B-025 | `Q-005` `EnableVolatilityFilter=false` | O | decisao do dono; agente nao altera | AGUARDA DONO |
| B-026 | `Q-004`/`P-006` simbolos x graficos | D | 13 graficos e `Symbols` coerentes | ABERTO |

## P2 - Melhorias

| ID | Item | Dono | Criterio | Estado |
|---|---|---|---|---|
| B-027 | `QUADRO_ESTADO.md` gerado, nao escrito a mao | C | regenerado antes de cada commit | EM CURSO |
| B-028 | Limpeza com `-DryRun` e whitelist | C | relatorio em `_SYNC/` | ABERTO |
| B-029 | Pesquisa de melhorias (web/GitHub) | todos | ideias com fonte no backlog | CONTINUO |
| B-030 | `HANDOFF` obrigatorio ao parar | todos | bloco no diario | EM CURSO |
| B-031 | Backtest reprodutivel (comando salvo) | D | 2 execucoes, mesmo resultado | ABERTO |
| B-032 | Walk-forward | D | metricas por janela | ABERTO |
| B-033 | Forward demo 30 dias | D | >= 100 trades, PF >= 1.2, DD <= 8% | ABERTO |
| B-034 | Migrar motor de IA (LightGBM/ONNX) | A | avaliacao com fonte e custo | ABERTO |

---

## Decisoes que so o DONO toma

| ID | Pergunta | Onde |
|---|---|---|
| Q-013 | universo: 21 simbolos com 1 modelo ou reduzir a XAUUSD? | `INBOX_DONO.md` |
| Q-014 | `AllowTradeWithoutAI=true` fica? | `INBOX_DONO.md` |
| Q-015 | `EnableVolatilityFilter` fica `false`? | `INBOX_DONO.md` |
| Q-016 | autoriza forward demo de 30 dias antes de real? | `INBOX_DONO.md` |

> As perguntas Q-001..Q-012 originais continuam em `INBOX_DONO.md`; aqui so
> entram as novas, para nao duplicar.
