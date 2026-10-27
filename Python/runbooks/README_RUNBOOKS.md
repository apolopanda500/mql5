# XAU_AI_PRO — RUNBOOKS (automação read-only)

Runbooks Python para **checkpoint, reconciliação e matriz** — TUDO LEITURA:
**nunca enviam ordens, nunca alteram EA/inputs/símbolos.**

Pré-requisito: `py -3 -m pip install MetaTrader5` (pacote oficial MetaQuotes, já instalado em 30/08).

## Arquivos

| Script | Função | Uso |
|---|---|---|
| `checkpoint_20_14.py` | Executa os 9 passos do checkpoint 20.14 (§10.9): watchdog + métricas da janela + reconciliação + veredito PASS/INVESTIGATE/FAIL | `py -3 runbooks\checkpoint_20_14.py` |
| `reconcile_sources.py` | Reconciliação 4 fontes (Broker MT5 × full_audit × events × backend) com barra de gate 20.8 | `py -3 runbooks\reconcile_sources.py [--json]` |
| `matrix_runner.py` | Lista perfis/relatórios de backtest, varre logs por 4807, confere hash do ex5 | `py -3 runbooks\matrix_runner.py --list / --report / --check-logs / --check-hash` |

## Notas

- Janela limpa hardcoded: início **28/08 21:35 servidor (UTC+3)** = 18:35 UTC. Ajustável nas constantes.
- `MetaTrader5` conecta ao terminal **read-only**; qualquer erro de conexão aparece no relatório sem efeito.
- O lançamento real dos backtests (matriz 20.15) é feito pelo MetaTrader MCP com **pausa ≥ 60s entre
  jobs** (evita queda do agente Core 1 — ocorrência operacional documentada §11.2b).
- Veredito é **sugestão**: a decisão final de PASS/INVESTIGATE/FAIL é do usuário + trilha de evidências.