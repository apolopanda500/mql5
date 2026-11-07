# PLANO MESTRE 10/10 - XAU_AI_PRO

**Dono:** o DONO (4o participante) | **Equipa:** ALFA, DELTA, CMD
**Criado:** 05/11/2026 22:45 por CMD (`D-018`) | **Estado:** EM EXECUCAO
**Objetivo final declarado pelo dono:** *"terminar este projeto 10/10 em modo
uso real; uso este projeto em contas reais"*.

> Regra deste documento: **nenhum item e "concluido" sem numero medido e hora.**
> O que nao tem evidencia fica em `BACKLOG.md` como ABERTO, nao como feito.

---

## 1. Como ler o plano

- **Fase** = um bloco de trabalho com um portao (`GATE`) que so abre com
  criterio numerico. Fase aberta nao bloqueia as seguintes, mas **F2 e F6 sao
  bloqueantes para conta real** por definicao.
- **Dono do item** = quem pode editar. Os outros revisam. Ver `D-008`.
- **Evidencia** = comando, ficheiro e hora. "Funciona" nao e evidencia.
- **Estado:** `ABERTO` -> `EM CURSO` -> `MEDIDO` -> `FECHADO`.

### Mapa de donos (D-008, aprovado)

| Zona | Dono | Nunca toca |
|---|---|---|
| `Core/`, `AI/`, `Indicators/`, `Filters/`, `Management/` | ALFA | risco sem o DONO |
| `Monitoring/`, `Enterprise/`, canal `EQUIPE/` | DELTA | codigo de entrada |
| app Python (`Files/XAU_AI_PRO/backend`, `frontend`, `tests`), espelho, `commit`/`push`/`deploy`, auditoria | CMD | parametros de risco |
| `RiskPerTradeUsd`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, `StopLossPoints`, `EnableVolatilityFilter`, conta real, go-live | **DONO** | — |

### Turnos (o dono disse: "pode ter horas ou dias que so 2 podem trabalhar")

Nao ha turno fixo. Ha **regra de continuidade**:

1. Quem para escreve um bloco `## HANDOFF` no seu diario (`AGENTE_n.md`) com:
   `feito | em curso | proximo passo | bloqueio | evidencia`.
2. Quem assume le **dois** ficheiros: `QUADRO_ESTADO.md` e o `HANDOFF` mais
   recente. Se os dois discordarem, ganha o medido mais recente.
3. `CMD` regenera `QUADRO_ESTADO.md` antes de cada `commit`. Um quadro velho
   e pior do que nenhum.

---

## 2. Linha de base medida (05/11/2026 22:40)

| Item | Valor | Fonte |
|---|---|---|
| EA | v1.2.167 | `Enterprise/VersionManager.mqh` |
| Binario | 927 354 B, 05/11 21:57:47 | `XAU_AI_PRO.ex5` |
| Em producao | **v1.2.167 nos 13 graficos** (22:10:47-22:11:06) | journal, `D-014` |
| Compilacao | 0 errors, 0 warnings | MetaEditor 5.0.0.6296 |
| Espelho | **110/110 fontes, 0 divergentes** | `equipe-audit.ps1 mirror` |
| Trades | **0** | `[SCANNER] RESUMO` 22:02:10 |
| Simbolos com modelo H1 | **1 de 21** (so XAUUSD) | `[AI] GATEWAY ... disponivel=false` |
| `MinAIConfidence` vs CONF | 60.0 vs 56.6-63.3 | journal |
| App Python | 1 506 passed / 14 failed / 9 skipped / 4 errors | pytest 22:29 |
| Vulnerabilidades | 1 alta (dependabot 234) | GitHub |

---

## 3. Fases e portoes

### F0 - Governanca e verdade *(EM CURSO - CMD)*

| # | Item | Estado |
|---|---|---|
| F0.1 | Canal unico `EQUIPE/` com 11 ficheiros | FECHADO |
| F0.2 | Um escritor (`sync-agent.ps1`) + um leitor (`equipe-sync.ps1`), lock unico `LOCK.md` | FECHADO (`D-017`) |
| F0.3 | Ledger de IDs (`IDS.md`) - zero colisao | FECHADO |
| F0.4 | Auditor externo somente-leitura (`Tools/equipe-audit.ps1`) | FECHADO (`D-018`) |
| F0.5 | Plano mestre + `BACKLOG.md` + `FERRAMENTAS.md` | FECHADO (`D-018`) |
| F0.6 | `QUADRO_ESTADO.md` regenerado antes de cada commit | ABERTO |

**GATE F0:** `sync-agent.ps1 check` = 0 problemas; `equipe-audit.ps1 verify` =
ok; ledger sem ID duplicado. *(medido 22:40: check 0 problemas)*

### F1 - Continuidade e memoria *(DONO: DELTA)*

| # | Item | Criterio |
|---|---|---|
| F1.1 | `HANDOFF` obrigatorio em cada paragem | bloco presente no diario |
| F1.2 | `QUADRO_ESTADO.md` como ecra unico | gerado, nao escrito a mao |
| F1.3 | MCP `memory` para conhecimento entre sessoes | instalado (`FERRAMENTAS.md`) |
| F1.4 | Arquivo de conversas/decisoes | `DECISOES.md` + `_SYNC/` |

**GATE F1:** um agente sem contexto anterior retoma o trabalho em **< 10 min**
lendo 2 ficheiros (teste real, feito uma vez, com hora).

### F2 - Seguranca de capital *(BLOQUEANTE PARA CONTA REAL - ALFA + DONO)*

| # | Item | Criterio de aceitacao |
|---|---|---|
| F2.1 | Kill switch manual e automatico | 1 clique/palavra para fechar tudo; testado |
| F2.2 | Teto de exposicao total | soma das posicoes <= X% do capital, verificado no codigo - **ABERTO**: implementado em duas voltas. v1.2.180 (D-066) somava margem por `OrderCalcMargin()` filtrando por `MagicNumber`. v1.2.181 (**D-067**, implementada e compilada 0/0, NAO provada, NAO publicada nos 13 graficos) troca a fonte para `AccountInfoDouble(ACCOUNT_MARGIN)` em `Core/PositionManager.mqh`: o teto passa a ser o da CONTA e nao o das posicoes deste magic, logo o F2.8 ja nao o fragmenta em 13 x 20%. `MargemSomadaPosicoes()` fica so como instrumento e e impresso na linha de bloqueio para tornar visivel a divergencia. `EnableExposureCap=true` e `MaxExposurePercent=20.0` (banda 10-50% autorizada pelo DONO na Q-065). O CMD mostrou que o risco aberto somado JA era limitado por `MaxTotalRiskPercent=10.0` (`Config.mqh:336`) -> `RiscoAbertoUSD()` (`1219`) -> `RISK_ENVELOPE_FULL` (`ExecutionEngine.mqh:686-701`); esse envelope **continua a filtrar por `MagicNumber`** e a correccao esta pedida por escrito ao CMD, sem resposta. Falta para fechar: (i) somatorio do RISCO sem filtro de magic (decisao do CMD, nao minha); (ii) prova de recusa acima do teto; (iii) prova de fail-closed; (iv) prova de ausencia de falso positivo; (v) uma unica publicacao da v1.2.181 nos 13 graficos (hoje corre a v1.2.180, cujo modo de falha por simbolo continua vivo). Reabertura registada as **21:29** (o texto anterior dizia 21:40, hora que ainda nao tinha acontecido - corrigido em 21:41 a pedido do DELTA) |
| F2.3 | Limite de posicoes simultaneas | `MaxPositions` aplicado e observado |
| F2.4 | Perda diaria / drawdown | bloqueia novas entradas ao atingir; testado |
| F2.5 | Guarda de spread e slippage | recusa entrada acima do limite; logado |
| F2.6 | Idempotencia de ordem | reenvio nao duplica posicao (teste de falha) |
| F2.7 | Reconciliacao EA x conta | 0 divergencias entre posicoes internas e corretora |
| F2.8 | Magic number por instancia | 13 graficos nao se confundem |
| F2.9 | Deteccao de desconexao/freeze | ultima cotacao velha -> nao opera - **FECHADO v1.2.179 / D-064**: veredicto medido 21/21 sem falso "fresca"; deteccao de transicao no OnTimer porque sem tick o OnTick nao corre (13/13 graficos publicaram `[TRADE BLOCK] COTACAO VELHA (timer)` com `limite=900s`); fonte unica do limite via `CStalenessGuard::Configurar(EnableStaleDataGuard, MaxSymbolTickAgeSec)`; `MarketScanner` passou de `TimeCurrent()` para `TimeTradeServer()`. Falta observar `COTACAO VOLTOU (timer)` na proxima abertura com feed vivo |
| F2.10 | Parametros de risco congelados | hash dos inputs iguais aos aprovados |

**GATE F2:** simulacao de 6 falhas (desconexao, requote, spread anormal,
duplicacao, reinicio a meio, conta sem margem) **sem abrir ordem indevida** e
com log de cada decisao. Sem este gate, **nao ha conta real.**

### F3 - Robustez do EA *(ALFA)*

| # | Item | Evidencia atual |
|---|---|---|
| F3.1 | `Q-001` handles ATR mortos no reload | 9x `erro=4807` as 22:14:26-40; 10 de 13 simbolos sem ATR/RSI |
| F3.2 | `Q-002` IA devolve `BUY=0.00 / SELL=0.00` | 8 predicoes 21:36:45-22:11:18 |
| F3.3 | `Q-003` `dataset.csv` multi-escritor | `AI/Dataset.mqh` |
| F3.4 | `Q-006` modulos orfaos | `Management/PartialClose.mqh`, `TrailingStop.mqh` |
| F3.5 | Inicializacao deterministica | ordem de init documentada e testada |
| F3.6 | Versao unica nos 13 graficos | hash do `.ex5` igual em todos |

**GATE F3:** 13/13 graficos com ATR/RSI validos **72 h** sem `erro=4807`;
`dataset.csv` com **1 escritor eleito** e 0 linhas truncadas.

### F4 - IA e gateway *(ALFA + DONO no modelo)*

| # | Item | Criterio |
|---|---|---|
| F4.1 | Cobertura de modelo por simbolo/TF | 21/21 com modelo publicado, ou decisao explicita de universo |
| F4.2 | Rejeitar score degenerado | `BUY=0 e SELL=0` nunca e sinal valido |
| F4.3 | Calibracao da confianca | CONF vs resultado real, com amostra |
| F4.4 | Staleness | predicao velha nao opera |
| F4.5 | Politica de fallback | `AllowTradeWithoutAI` documentado por escrito (hoje `true` no reattach) |
| F4.6 | Gateway como servico | `Q-009`: porta 9011 sobrevive a reboot |

**GATE F4:** 0 sinais degenerados em 1 000 predicoes; gateway sobe sozinho
apos reboot; politica de fallback assinada pelo DONO.

### F5 - App Python *(CMD)*

| # | Item | Evidencia |
|---|---|---|
| F5.1 | 14 falhas de `test_vip_progress.py` | fixture com data fixa expirada (2026-10-01) |
| F5.2 | 6 modulos sem `tkinter` | excluir da suite ou instalar Tcl/Tk |
| F5.3 | 4 errors | identificar e fechar |
| F5.4 | 1 CVE alta (dependabot 234) | atualizar dependencia |
| F5.5 | Paridade de config app x EA | `.env` x inputs |

**GATE F5:** suite **verde** (0 failed, 0 errors) excluindo GUI declaradamente;
0 vulnerabilidades altas.

### F6 - Validacao *(DELTA mede, DONO aprova)*

| # | Item | Criterio |
|---|---|---|
| F6.1 | Backtest reprodutivel | periodo, spread, modelo, comando salvos |
| F6.2 | Walk-forward | sem sobreajuste; metricas por janela |
| F6.3 | Forward em demo >= 30 dias | >= 100 trades |
| F6.4 | Metricas minimas | PF >= 1.2, max DD <= 8%, expectancy > 0 |
| F6.5 | `Q-011` PF 0.6206 | remedir com amostra e periodo explicito |

**GATE F6:** 30 dias demo com os numeros acima **e** relatorio assinado.

### F7 - Go-live em conta real *(SO O DONO)*

| # | Item | Regra |
|---|---|---|
| F7.1 | Conta real | decisao do DONO, por escrito |
| F7.2 | Sizing escalonado | 0.01 lote -> rampa aprovada |
| F7.3 | Limites duros | iguais aos do F2, verificados no servidor |
| F7.4 | Revisao diaria | 15 min, checklist |
| F7.5 | Rollback | voltar a versao anterior em 1 comando |
| F7.6 | Runbook de incidente | quem faz o que, em que ordem |

**GATE F7:** F2 + F6 fechados, runbook impresso, DONO presente.

### F8 - Higiene e limpeza *(CMD)*

| # | Item | Regra |
|---|---|---|
| F8.1 | Limpeza com `-DryRun` por omissao | lista antes de apagar |
| F8.2 | Whitelist | `%TEMP%`, `__pycache__`, `.pytest_cache`, `_SYNC/backup` > 14 dias, logs > 30 dias |
| F8.3 | Proibido | `Data/*.csv`, `.ex5` em uso, perfis do terminal, `.git`, `.env`, fora da arvore MQL5 sem lista explicita |
| F8.4 | Relatorio | bytes libertados + ficheiros, em `_SYNC/` |

**GATE F8:** limpeza executada com relatorio; nada da lista proibida tocado.

### F9 - Pesquisa e melhoria continua *(todos)*

Pesquisa web/GitHub autorizada pelo DONO (05/11 22:43). Regra: **toda ideia
entra em `BACKLOG.md` com fonte e custo estimado**, nunca direto no codigo.
Revisao de backlog 1x por dia de trabalho.

---

## 4. Ordem de ataque (proximos 7 dias)

| Dia | Foco | Dono |
|---|---|---|
| 1 | F0 fechar, F5.1-F5.3 (suite), `QUADRO_ESTADO` | CMD |
| 2 | F3.1 ATR handles (o unico que nao fecha sozinho) | ALFA |
| 3 | F3.2/F3.3 score degenerado + dataset 1 escritor | ALFA |
| 4 | F2.1-F2.4 kill switch e limites | ALFA + DONO |
| 5 | F4.6 gateway como servico + F4.1 cobertura | DELTA |
| 6 | F2.5-F2.9 falhas simuladas | ALFA + DELTA |
| 7 | F6.1 backtest reprodutivel + revisao | DELTA |

> O universo de 21 simbolos com 1 modelo e uma **decisao de negocio**, nao um
> bug. Entra em `F4.1` para o DONO decidir com numero na mao.

---

## 5. Definicao de "10/10 100%" (para nao haver discussao depois)

1. `GATE F0` a `GATE F6` fechados com evidencia datada.
2. Suite Python verde; 0 CVE alta; EA compila 0/0.
3. 30 dias demo positivos com PF >= 1.2 e DD <= 8%.
4. Kill switch e reconciliacao testados em falha simulada.
5. 13 graficos na mesma versao, hash conferido.
6. Risco congelado e documentado; nenhuma alteracao sem o DONO.
7. Runbook de incidente escrito e testado uma vez.

Falta qualquer um destes -> **nao e 10/10**, e o `BACKLOG.md` diz por que.
