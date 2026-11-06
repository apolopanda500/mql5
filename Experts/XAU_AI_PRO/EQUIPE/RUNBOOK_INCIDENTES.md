# RUNBOOK DE INCIDENTES - XAU_AI_PRO

**Criado:** 05/11/2026 23:10 por DELTA | **registo:** `D-027` | **backlog:** `B-010`
**Regra:** cada linha responde a **sintoma -> o que medir -> o que fazer -> quem -> quando parar.**
Nenhuma accao deste runbook altera parametro de risco. Se for preciso mexer em risco, e `ask` ao DONO.

---

## 0. Regra zero

Antes de tocar em qualquer coisa: **medir**. Ordem fixa e barata:

```powershell
# 1. o canal esta integro?
tools\equipe-sync.ps1 check
# 2. quem esta a escrever agora?
tools\equipe-sync.ps1 lockstatus
# 3. versao e configuracao reais (nao as do fonte)
#    list_open_charts + get_expert_advisor_parameters do .ex5
# 4. o que o EA disse nas ultimas 2 horas
#    get_expert_journal (filter [VALIDATION], [ATR], [AI], [SCANNER])
```

Se o passo 3 mostrar `.ex5` diferente do que os 13 graficos carregaram, **para tudo**: o que se mede deixa de ser o que corre.

---

## 1. O EA nao abre nenhuma ordem ha mais de 24 h

| Campo | Conteudo |
|---|---|
| **Sintoma** | `[SCANNER] RESUMO` com `trades=0` por varias horas; nenhuma posicao nova |
| **Medir** | `get_expert_journal` filtrando `[VALIDATION]` (o motivo de recusa por simbolo), `[SCANNER]` e `[ATR]` na mesma janela |
| **Classificar** | (a) `ATR%=sem leitura` -> ver incidente 2; (b) `[AI] BUY=0.00 SELL=0.00` -> incidente 3; (c) `ADX abaixo do minimo` -> mercado, nao defeito; (d) `spread acima` -> incidente 5; (e) nada registado -> incidente 7 (EA parado) |
| **Fazer** | so a accao do incidente classificado. **Nunca** baixar `MinAIConfidence` nem `MinimumADX` "para ver se entra" |
| **Quem** | quem tem MCP `metatrader5` (ALFA ou DELTA) mede; ALFA corrige codigo |
| **Parar quando** | houver uma linha de `[VALIDATION]` por simbolo a dizer o motivo exacto |
| **Proibido** | mexer em risco ou em gates para "destravar" |

## 2. `[ATR] HANDLE MORTO | erro=4807`

| Campo | Conteudo |
|---|---|
| **Sintoma** | `[ATR] HANDLE MORTO | barsCalc=-1 | erro=4807` em varios simbolos; `ATR%=sem leitura` no `[CENARIO]` |
| **Medir** | quantos simbolos, hora exacta, se o handle voltou sozinho na leitura seguinte (contar `[ATR]` bom depois do morto) |
| **Causa conhecida** | `Indicators/VolatilityFilter.mqh`: handle aceito sem validar `BarsCalculated`; `ATRCacheDrop` liberta e o uso seguinte no mesmo tick nao recria |
| **Fazer** | **nao reiniciar o terminal** (apaga a prova); registar simbolo x hora e abrir/actualizar pedido `R-nnn` ao ALFA. Se 13/13 morrerem, e bloqueio de dados do servidor: verificar `Market Watch` e ligacao |
| **Quem** | mede DELTA, corrige ALFA (`Indicators/**` e zona dele) |
| **Parar quando** | 13/13 com ATR valido durante 72 h sem `4807` (criterio do `B-011`) |

## 3. IA devolve `BUY=0.00 / SELL=0.00 / SCORE=0.00`

| Campo | Conteudo |
|---|---|
| **Sintoma** | 8 predicoes seguidas com score degenerado (21:36-22:11 de 05/11) |
| **Medir** | `compiler_python` no pre-flight (esta **false** nos 3 servidores), se a porta 9011 responde, e o codigo HTTP: `401` = token, `200` com zeros = modelo/features |
| **Causa** | duas em serie: **primeiro** o motor Python nao existe/detectado; **depois** token e features (30F vs 25F medido) |
| **Fazer** | (a) confirmar Python instalado (DONO); (b) `Tools\api-probe.ps1` para ver a rota com e sem token; (c) `BlockZeroAIScore=true` no EA **deve** impedir entrada com score 0 - se entrar, e defeito de codigo e vai para o ALFA |
| **Quem** | DONO instala Python; CMD mede o gateway; ALFA o gate |
| **Parar quando** | 1 000 predicoes sem score degenerado (`B-012`) |

## 4. `WebRequest` bloqueado / erro 4060

| Campo | Conteudo |
|---|---|
| **Sintoma** | journal com `WebRequest` a falhar ou `4060` |
| **Medir** | compilar `Scripts\XAI_WebRequestCheck.mq5`, correr no grafico, ler journal com filtro `WEBREQ` |
| **Fazer** | a allowlist esta na GUI (`Ferramentas > Opcoes > Expert Advisors`) e **fora das raizes**: so o DONO altera. Pedir por `ask` com o URL exacto `http://127.0.0.1:9011` |
| **Quem** | DONO (1 clique), agente confirma depois |
| **Parar quando** | o script de teste devolver `WEBREQ OK` com o URL do gateway |

## 5. Spread anomalo / requotes em serie

| Campo | Conteudo |
|---|---|
| **Sintoma** | `[VALIDATION] spread acima do limite` repetido; recusas de execucao com `10004`/`10006` |
| **Medir** | `MaxSpreadPct=0.6` (medido), spread actual por simbolo, hora (abertura de sessao e noticias sao as causas normais) |
| **Fazer** | **nada no EA**. Confirmar se e horario (noticia/abertura) e esperar. Se persistir fora de noticia, e condicao da corretora: registar e informar o DONO |
| **Quem** | qualquer agente mede; ninguem altera `MaxSpreadPct` |
| **Parar quando** | spread voltar ao normal ou houver registo datado do contrario |

## 6. Duas versoes diferentes a correr

| Campo | Conteudo |
|---|---|
| **Sintoma** | `list_open_charts` mostra `.ex5` com datas diferentes, ou `version` diferente entre graficos |
| **Medir** | `get_expert_advisor_parameters` por grafico: `size`, `build_time`, `version` |
| **Fazer** | parar compilacoes; reanexar o mesmo `.ex5` em todos os graficos **com LOCK** e registar no `QUADRO_ESTADO.md` (valor antigo, novo, quem, hora) |
| **Quem** | DELTA ou ALFA (tem MCP), CMD compila |
| **Parar quando** | 13/13 com o mesmo `size` e `build_time` (`B-007`/`F3.6`) |

## 7. EA parado no grafico (sem `[SCANNER]` novo)

| Campo | Conteudo |
|---|---|
| **Sintoma** | nenhuma linha do EA no journal ha mais de 10 min com mercado aberto |
| **Medir** | `list_open_charts` (EA anexado? `expert` presente?), AutoTrading do terminal, `EnableLogs=true` |
| **Fazer** | reanexar o mesmo `.ex5` com LOCK; se o `OnInit` falhar, ler o `INIT_*` devolvido e reportar ao ALFA |
| **Quem** | quem tem MCP `metatrader5` |
| **Parar quando** | `[SCANNER] RESUMO` voltar a aparecer |

## 8. Canal `EQUIPE/` com problema (`check` != 0)

| Campo | Conteudo |
|---|---|
| **Sintoma** | `CANAL COM N PROBLEMAS` (CR, UTF-8, ID duplicado, BOM) |
| **Fazer** | `tools\equipe-sync.ps1 eol` (normaliza CR e faz backup) e repetir `check`; UTF-8 invalido -> restaurar de `_SYNC\backup\<ficheiro>.<data>.bak` |
| **Quem** | DELTA (canal e zona dele) |
| **Parar quando** | `CANAL INTEGRO :: 0 problemas` |
| **Nota** | o `check` do `sync-agent.ps1` **nao** acusa CRLF puro (so misturado) - usar os dois (`R-001`) |

## 9. Sincronizacao entre agentes falhou (pedido sem resposta)

| Campo | Conteudo |
|---|---|
| **Sintoma** | `R-nnn` em `PEDIDO` ha mais de 2 turnos |
| **Fazer** | quem pediu: (a) escala ao DONO com `ask`, ou (b) executa com LOCK e escreve na linha que o fez |
| **Quem** | quem pediu |
| **Parar quando** | o `R-nnn` sair de `PEDIDO` |

## 10. Perda diaria / drawdown atingido

| Campo | Conteudo |
|---|---|
| **Sintoma** | `MaxDailyLossPercent=10.0` ou `MaxDrawdownPercent=15.0` activados; entradas bloqueadas |
| **Fazer** | **e o comportamento correcto.** Nao reiniciar contadores, nao aumentar limites, nao reabrir posicoes. Registar o numero e informar o DONO |
| **Quem** | ninguem desbloqueia sem o DONO |
| **Parar quando** | o DONO decidir, por escrito |

---

## Escada de escalada

1. **Agente mede e classifica** (5 min). Sem numero, nao ha incidente.
2. **Se e zona de outro**: `equipe-sync.ps1 pedir -De X -Para Y -Assunto "..." -Precisa "..." -Prazo "dd/mm hh:mm"` -> `R-nnn`.
3. **Se e nivel C** (risco, conta real, CodeBase, allowlist, instalar): `ask` ao DONO e `INBOX_DONO.md`. **Nunca se resolve sozinho.**
4. **Se e dinheiro em risco agora**: primeiro **fechar/parar** (kill switch do EA ou remover o EA do grafico com LOCK), depois medir. Ordem invertida custa dinheiro.

## O que este runbook nunca autoriza

Alterar `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`, `RiskPerTradeUsd`, `StopLossPoints`, `TakeProfitPoints`, `MinAIConfidence`; desligar `RequireStopLoss`; operar em conta real sem as portas `G1..G5`; publicar em `origin`/CodeBase; apagar `.ex5`/`.dll`/`Data/*.csv`.
