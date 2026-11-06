# PLANO MESTRE (ALFA) - SUPERADO pelo `D-018` (CMD)

> **STATUS: HISTORICO / COMPLEMENTO.** O plano mestre canonico da equipa e o do
> **CMD, `DECISOES.md` `D-018`** (fases `F0..F9`, portoes `GATE F0..F7`). Este
> ficheiro **nao** e um segundo plano: fica como complemento e guarda so o que
> o `D-018` nao tem -
>
> 1. a **fila de decisoes do DONO com recomendacao tecnica** (seccao 4 abaixo);
> 2. a proposta de **risco para conta real** (`MaxDailyLossPercent` 10 -> 5 e
>    `MaxDrawdownPercent` 15 -> 10), que o `D-018` trata por hash em `F2.10`;
> 3. a linha de base medida das **22:35**, util para comparar com a das 22:40.
>
> **Nao criar fases novas aqui.** Item novo vai para `BACKLOG.md` (`F9` do
> `D-018`), nao para este ficheiro.

**Dono:** o operador (participante 4 do canal). **Executores:** ALFA, DELTA, CMD.
**Criado:** 05/11/2026 22:38 | **registo:** `DECISOES.md` `D-019` | **superado por:** `D-018` (CMD, 22:45).
**Objetivo final declarado pelo dono:** EA universal (todos os simbolos, nao so XAUUSD), a operar em **conta real**, com risco controlado e trabalho sem interrupcao.

> **Regra dura deste plano:** nada entra em conta real sem passar as portas **G1..G5**.
> Conta real e o fim do caminho, nao o comeco. O que existe hoje ainda **nao abre posicao**:
> 0 trades medidos e a IA a devolver `BUY=0.00% | SELL=0.00%`. Ir a real neste estado seria
> pagar spread para nao operar - ou pior, operar sem sinal valido.

---

## 1. Linha de base medida (05/11/2026 22:35, nao estimada)

| Item | Valor medido | Fonte |
|---|---|---|
| Versao legivel | `v1.2.167` (`#property version "1.367"`) | `Enterprise/VersionManager.mqh`, `XAU_AI_PRO.mq5` |
| Binario | `.ex5` 927 354 B, 21:57:47 | disco |
| Fontes x binario | **BATEM** (nenhum `.mq5`/`.mqh` mais novo) | `sync-agent.ps1 status` |
| Graficos | 13, perfil `XAI_P216_LIVE` | `list_open_charts` |
| Universo do EA | 21 simbolos | `[SCANNER] RESUMO` |
| Conta | demo **113568614**, MetaQuotes-Demo, saldo **12 636.32** | conta do terminal |
| Posicoes abertas | **0** | conta do terminal |
| Trades hoje | **0** (`visitas=1489 sinais=142 trades=0`) | `[SCANNER] RESUMO` 22:02:10 |
| IA | so **XAUUSD H1** publicado (`1121 B`, `disponivel=true`) | `[AI] GATEWAY` |
| IA - lado | `BUY=0.00% SELL=0.00% SCORE=0.00` em **8/8** predicoes | `[AI] PYTHON` 21:36-22:11 |
| IA - confianca | 53.90 a 63.30% contra `MinAIConfidence=60.0` | journal |
| Outros 20 simbolos | `357 B`, `disponivel=false` (sem modelo) | journal |
| ATR | **10 de 13** simbolos sem leitura depois do reload (22:14-22:20) | `[ATR] HANDLE MORTO`, erro 4807 |
| Filtros | `EnableVolatilityFilter=false`, `EnableAIFilter=true`, `AllowTradeWithoutAI=true`, `EnableAutonomousMode=false` | 13 graficos |
| Risco (congelado) | `RiskPercent=1.0`, `MaxDailyLossPercent=10.0`, `MaxDrawdownPercent=15.0` | 13 graficos |
| `PF` reportado | 0.6206 - **invalido**, periodo com 0 trades | `Q-011` |

---

## 2. Fases, donos e criterio de saida

Cada fase so fecha com **numero medido**. "Feito" sem medicao nao conta.

### F1 - Canal e build sob controlo (base para tudo)
- **Dono:** ALFA | **Estado:** em curso
- **Objetivo:** uma unica via de escrita (`sync-agent.ps1`), 1 compile e 1 reattach por vez, passagem de turno obrigatoria.
- **Saida:** `check` = 0 problemas; **7 dias** sem escrita perdida, sem ID colidente e sem compile concorrente.

### F2 - Defeitos que impedem operar (bloqueadores)
- **Donos:** ALFA (codigo), DELTA (medicao), CMD (repo/build)
- **Itens e criterio de saida cada:**
  1. **ATR morto pos-reload** (`Q-001`, `P1.132`): 13/13 simbolos com `ATR != 0` durante **24 h** sem reiniciar. Causa raiz: aceitar handle sem validar `BarsCalculated == Bars(symbol, Period())`.
  2. **IA sem lado** (`Q-002`): todas as predicoes XAUUSD com `BUY` **e** `SELL` > 0 (ou prova de que o campo nao existe e o parser tem de mudar de chave).
  3. **`dataset.csv` multi-instancia** (`Q-003`, `P-004`): **1** escritor por conta, provado por medicao de concorrencia.
  4. **Universo x graficos** (`Q-004`, `P-006`): matriz simbolo -> motivo (entra / veta / sem dados), com **0** "sem leitura".
  5. **`EnableVolatilityFilter`** (`Q-005`): decisao do dono registada, valor igual nos 13 graficos e no `.set`.
- **Saida:** os 5 itens com evidencia no `QUADRO_ESTADO.md`.

### F3 - Universalidade real (o pedido central do dono)
- **Dono:** ALFA | **Depende de:** F2.1 e F2.4
- **Objetivo:** o EA decide **por simbolo**, nao por suposicao. Para os 20 sem modelo publicado: ou se publica modelo, ou se define politica explicita (operar sem IA com regra tecnica + log, ou excluir).
- **Saida:** para os 21 simbolos, uma linha com: tem modelo? entra? com que regra? Porque nao entra quando nao entra. **0** simbolos em estado ambiguo.

### F4 - Prova quantitativa antes de qualquer euro
- **Dono:** CMD (tester), revisao ALFA
- **Objetivo:** Strategy Tester com o build atual, **walk-forward** em 3 janelas, mais out-of-sample.
- **Saida (todas obrigatorias):** `>= 100` trades; `PF > 1.20` na janela out-of-sample (nao na de optimizacao); `MaxDrawdown < 15%`; expectancy positiva; resultado **repetivel** em 2 execucoes.
- **Nota honesta:** o `PF 0.6206` atual nao serve - veio de um periodo com 0 trades. Backtest aprovado **nao** garante lucro futuro.

### F5 - Conta real, faseada
- **Dono decide, ALFA executa com LOCK, CMD registra**
- **Escada:** (1) 1 simbolo, lote minimo, 10 dias uteis supervisionados -> (2) 3 simbolos -> (3) universo de F3.
- **Saida de cada degrau:** 20 dias uteis sem incidente, drawdown dentro do limite, journal sem erro critico.
- **Nunca:** aumentar lote ou numero de simbolos no mesmo dia em que se corrige codigo.

### F6 - Operacao continua
- **Rodizio** dos 3 (ver `ROTINA_E_PASSAGEM.md`)
- **Saida:** 0 dias sem agente activo; todo incidente com runbook e causa registada.

---

## 3. Portas (gates) - o que trava a passagem a real

| Porta | Pergunta | Criterio | Quem assina |
|---|---|---|---|
| **G1** Integridade | O binario corresponde as fontes? | `status` diz `BATEM`; `check` = 0 | ALFA |
| **G2** Funcional | O EA abre e fecha posicao em demo, com SL/TP corretos? | >= 5 ciclos completos, journal sem erro, SL/TP no preco esperado | ALFA + DELTA |
| **G3** Estatistico | Passou F4 em out-of-sample? | todos os numeros de F4 | CMD |
| **G4** Risco | Limites e kill-switch testados? | `RiskPercent`/`MaxDailyLoss`/`MaxDrawdown` inalterados e documentados; kill-switch accionado em teste | ALFA |
| **G5** Autorizacao | O dono autorizou, por escrito? | linha do dono no `INBOX_DONO.md` | **DONO** |

**Sem G1..G5 escritos, nenhum agente envia ordem em conta real.** Esta e a unica regra deste plano que nao tem excepcao.

---

## 4. Fila de decisoes do DONO (com recomendacao, para aprovar depressa)

| # | Pergunta | Recomendacao tecnica |
|---|---|---|
| 1 | `Q-001` ATR morto | **Corrigir agora** - e a unica porta que nao fecha sozinha; sem ATR o filtro e o lote por volatilidade ficam cegos |
| 2 | `Q-002` IA a 0.00%/0.00% | **Investigar antes de operar** - nao ha lado para escolher; sem isto o gate de IA nunca aprova |
| 3 | `Q-005` `EnableVolatilityFilter=false` | **Manter `false` ate F2.1 fechar**, depois ligar em **1** simbolo e medir 1 semana |
| 4 | `Q-003` `dataset.csv` | **Entra ja** - 13 escritores no mesmo ficheiro corrompe o historico que a IA usa |
| 5 | `Q-004` Universo x graficos | **Alinhar ao perfil (13)** e depois crescer por F3 |
| 6 | `Q-008` push do espelho | **Push autorizado para `github`** fica com o CMD; `origin`/CodeBase continua proibido |

---

## 5. O que ja esta proibido dentro deste plano

- Alterar `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, `RiskPerTradeUsd`, `StopLossPoints`, `TakeProfitPoints`, `MinAIConfidence` sem ordem escrita do dono.
- Operar sem Stop Loss.
- Enviar dados de conta, token ou credencial para fora, ou gravar segredos em ficheiro versionado.
- Apagar `.ex5`, `.dll`, `Data/*.csv` ou `.set` sem ordem explicita.
- Publicar no CodeBase / `origin`.
- Declarar "concluido" sem medicao no `QUADRO_ESTADO.md`.
