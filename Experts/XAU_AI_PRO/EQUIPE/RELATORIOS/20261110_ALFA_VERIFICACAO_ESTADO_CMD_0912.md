# ALFA - verificacao do relatorio de estado do CMD (09:12)

**Data:** 10/11/2026 09:12 (local, UTC-3)
**Conta:** 113568614 (MetaQuotes-Demo, build 6314, hedging) - **12 593,83** / 0 posicoes / 0 ordens
**Binario:** `XAU_AI_PRO.ex5` - **977 654 B** - 10/11 02:23:07 - MD5 **71ED34C690C9593D209A69E95F0EFFB6** - **intacto**

---

## 1. Tres correccoes ao que estava publicado

| # | O que estava escrito | O que se mediu | Efeito |
|---|---|---|---|
| 1 | P1.3529: o tecto de perda lido no runtime e' **40,00 USD** | Os 40,00 sao `DailyProfitTargetMaxUsd` - o tecto da **meta de lucro**. O guarda de perda nao dispara | P1.3529 **retractado** -> P1.3530 |
| 2 | ALFA 04:37: o `publicable true` do D-155 nao teve efeito pratico | Ha `[AI] PYTHON` real em **6** simbolos; sem isso nao havia sinal nenhum | D-155 teve efeito; o meu aviso das 04:37 estava exagerado |
| 3 | ALFA: o grafico 13 (USDBRL) em M5 e' desalinhamento | O EA pergunta no **timeframe do grafico**: `[AI] GATEWAY \| USDBRL \| M5 \| 1029 bytes` | Nao e' defeito; suspeita retirada |

## 2. De onde vem o 40,00 (P1.3530)

| Passo | Codigo | Com banca 12 593,83 |
|---|---|---|
| base | `DailyProfitTargetUsd` | 20,00 |
| 10% da banca | `saldo x DailyProfitTargetBalancePct/100` | 1 259,38 |
| vence o maior | `max(...)` | 1 259,38 |
| tecto absoluto | `DailyProfitTargetMaxUsd` | **40,00** |

`OperatorBrief.mqh:143` imprime `(realizado, meta, razao)` -> `-61,80 de 40,00 (-154%)`.
O guarda e' `lucroHoje >= meta` (`ExecutionEngine.mqh:455`) -> `-61,80 >= 40,00` = **falso**.
**A meta diaria esta' a 101,80 USD de distancia e nao bloqueia nada.** O rotulo "dia fechado" devia dizer "realizado hoje" - correccao de string, so' depois de 12/11.

## 3. O bloqueio mudou tres vezes de sitio - e agora e' o MTF (P1.3531)

| Hora | Portao | Evidencia |
|---|---|---|
| 04:24 | ADX | `ADX=15.19 \| Min=18.00` |
| 08:43 | AVOID HOUR | `GMT=11h \| lista=9,11,14,18,20,22` |
| 09:00 / 09:05 | **MTF** | `AI OK \| XAUUSD` + `BLOCK \| MTF` + `DECISION BLOCKED \| Signal=1` |

`[SCANNER] RESUMO` 09:01:24: **`visitas=8970 | sinais=83 | trades=0 | bloqueios=8970 | Stale=2392 NoSignal=6495 AllowTrade=83`**

**83 sinais, 0 trades.** A linha `[VALIDATION] AI OK` prova que o P1.3528 **nao** esta' a travar o XAUUSD agora - baixar `MinAIConfidence` nao resolveria o dia de hoje.

## 4. Inventario do que esta' a operar

| Item | Medido |
|---|---|
| Graficos abertos | **15** (nao 19) |
| Simbolos com inferencia real | **6** (XAUUSD 60,50/59,00; NZDUSD 50,30; USDCHF 48,10; USDBRL 43,30 M5; USDJPY 41,10; USDCAD 35,00) |
| Cotacao velha | **2 392** visitas - USDCOP 63 910 s, USDCLP 66 033 s, USDBRL 53 062 s (limite 900 s) |
| Horas fechadas por desenho | **6 h/dia** (GMT 9,11,14,18,20,22) = ~25% do mercado |
| Reinicio do terminal | **Nao** - `uptime=18061s` as 08:44:51; 08:57:20 so' perda/reautorizacao da ligacao |

## 5. O binario de 929 558 B nao existe (P1.3532)

Varredura recursiva de `MQL5\Experts` para `*.ex5` entre 900 000 e 1 000 000 B:

| Ficheiro | Bytes | mtime | MD5 |
|---|---|---|---|
| `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` | **977 654** | 10/11 02:23:07 | 71ED34C690C9593D209A69E95F0EFFB6 |

Nao existe 929 558 B nem 931 006 B nesta arvore. O G11 ancora no MD5: se 929 558 B entrar num relatorio fechado, a medicao seguinte contradiz.

## 6. Os 4 pontos pendentes, respondidos

| # | Item | Resposta do ALFA |
|---|---|---|
| 1 | B-031b -> compilar P1.133 -> reattach | **Proibido antes de 12/11.** Recompilar muda o MD5 e repoe os 30 dias do G11 (D-147). O terminal nao reiniciou, logo a janela esta' limpa - nao a estragar |
| 2 | Provisionar `XAU_GATEWAY_TOKEN` (Q-021) | **Nao e' bloqueio.** `AIGatewayToken` esta' vazio nos 15 graficos e o gateway responde em 6 simbolos via `.env`. Arrumacao, pode esperar |
| 3 | Gravar config viva nos `.chr` + mtime (DELTA) | **Objecto, por escrito.** Escrever inputs durante o forward e' mudar configuracao a meio da medicao |
| 4 | Conta real bloqueada F2/F6 | Correcto e nao contestado |

## 7. O que o DONO tem de decidir

1. Manter tudo e deixar o forward medir o que o EA quiser fazer. Custo zero, lento.
2. `EnableMTFConfirmation=false` - devolve volume, tira confirmacao. **Muda MD5, proibido ate 12/11.**
3. Encurtar `AvoidHoursGMT` para as horas medidas como perdedoras. **Mesmo problema de MD5.**
4. **Recomendado agora:** nao tocar em nada ate 12/11 e usar hoje como linha de base de bloqueios. Os `83 sinais / 0 trades` ja' sao um numero util e honesto.

## 8. Guardas respeitadas

- Binario **nao** recompilado, **nao** substituido: MD5 igual antes e depois da publicacao.
- Nenhum input alterado; nenhum `.chr` escrito; nenhum reattach.
- Nenhuma ordem enviada; conta com 0 posicoes e 0 ordens antes e depois.
- `CANAL INTEGRO :: 0 problemas` apos a publicacao.
- P1.3529 mantido no ficheiro como registo historico do meu erro - nao apagado.
