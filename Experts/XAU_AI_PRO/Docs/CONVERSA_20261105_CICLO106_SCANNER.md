# Ciclo 106 - 04/11/2026 22:00-22:12 - [SCANNER] Stale USDBRL (veredicto) + deploy da v1.2.147

## O defeito reportado pelo dono

```
2026.11.04 21:58:44.490  XAU_AI_PRO (USDJPY,H1)  [SCANNER] BLOCK | Stale | USDBRL | preco morto | ultimo tick ha 14325s
```

## Veredicto: NAO e um defeito. E o portao de dados mortos a funcionar como desenhado.

Nenhuma linha de codigo foi alterada por causa deste aviso. Nenhum limite, lote,
alvo, stop, spread, preco ou parametro de risco foi tocado. A versao nao subiu
por este aviso.

## Prova 1 - onde a linha nasce

| Elemento | Valor | Ficheiro |
|---|---|---|
| Emissor | `SymbolDataFresh()` | `Core/MarketScanner.mqh:381-383` |
| Portao | `input int MaxSymbolTickAgeSec = 900` | `Core/Config.mqh:473` |
| Interruptor | `input bool EnableStaleDataGuard = true` | `Core/Config.mqh:472` |
| Chamador | `ScanBlock(SCAN_STALE, symbol, " | " + staleWhy)` | `Core/MarketScanner.mqh:626` |

A comparacao e uma linha:

```mql5
if(MaxSymbolTickAgeSec > 0 && idade > MaxSymbolTickAgeSec)
  {
   motivo = "preco morto | ultimo tick ha " + IntegerToString(idade) + "s";
   return false;
  }
```

`idade = TimeCurrent() - cotacao.time`. 14 325 s esta 15 vezes acima do limite
de 900 s. O portao disparou porque devia.

## Prova 2 - a idade e honesta ao segundo (nao e erro de relogio)

| Passo | Conta |
|---|---|
| Log do journal | 21:58:44.490 local (UTC-3) |
| Convertido para servidor (UTC+2) | 2026-11-05 02:58:44 |
| Idade reportada | 14 325 s = 3h 58m 45s |
| 02:58:44 - 3:58:45 | **2026-11-04 22:59:59** (servidor) |
| `update_time` do USDBRL no Market Watch | **2026-11-04T22:59:59** |

Bate ao segundo. Nao ha desvio entre o relogio do Terminal, o do servidor e o
carimbo do ultimo tick: a idade publicada e verdadeira.

Em hora de Brasilia (UTC-3) esse instante e **17:59:59** - o fecho da sessao
onshore do real. O broker deixou de cotar USDBRL e ainda nao voltou.

## Prova 3 - censo de todos os simbolos no mesmo instante

Medido as 03:04:10 de servidor, pelos `update_time` do Market Watch:

| Simbolo | Ultimo tick (servidor) | Idade |
|---|---|---|
| EURUSD, GBPUSD, USDCHF, USDJPY, USDCNH, AUDUSD, NZDUSD, USDCAD, USDSEK, USDCZK, USDSGD, XAUUSD | 2026-11-05 03:04:09..11 | ~0 s |
| USDBRL | 2026-11-04 22:59:59 | 4h04m |
| USDCOP | 2026-11-04 19:59:32 | 7h04m |
| USDCLP | 2026-11-04 19:29:48 | 7h34m |
| USDRUB | 2026-11-04 16:55:39 | 10h08m |

Os 12 pares liquidos estao vivos ao segundo. Os quatro mortos sao exactamente
os exotcos cuja sessao local ja fechou (BRL, COP, CLP, RUB). O problema nao e
do EA nem do terminal: e o feed desses simbolos.

## Prova 4 - a idade do USDBRL e monotonica, logo nao ha tick nenhum

Todas as linhas de USDBRL do journal, e o instante de ultimo tick que cada uma
implica (hora do log menos a idade):

| Hora do log | Idade | Ultimo tick implicito |
|---|---|---|
| 18:15:02 | 903 s | 17:59:59 |
| 18:45:03 | 2 704 s | 17:59:59 |
| 19:22:42 | 4 963 s | 17:59:59 |
| 19:58:31 | 7 111 s | 17:59:59 |
| 20:28:33 | 8 914 s | 17:59:59 |
| 20:58:38 | 10 719 s | 17:59:59 |
| 21:28:40 | 12 521 s | 17:59:59 |
| 21:58:44 | 14 325 s | 17:59:59 |

Oito medicoes em 3h43m, sempre o mesmo instante de origem. Se houvesse um bug
de leitura da idade, ou um tick a chegar, o valor nao seria monotonico assim.

## Prova 5 - foi este o motivo pelo qual o portao foi escrito

O proprio cabecalho de `SymbolDataFresh()` o diz, medido em 02/11:

> o USDBRL tinha o feed parado desde 30/10 20:00 e ainda assim gerou 1 771 dos
> 1 839 sinais do dia - 96,3 por cento de todo o ruido do pipeline. O RSI[1]=37.31
> era literalmente o mesmo numero as 05:05, 05:31, 20:13, 20:56 e 20:57. Um preco
> que nao se mexeu nao e um setup: e um dado morto.

[SCANNER] BLOCK | Stale | USDBRL e portanto a prova de que o defeito de 02/11
continua corrigido. Se esta linha desaparecesse, o EA estaria a aceitar um preco
com 4 horas.

## Volume de log: 2 linhas por hora

Oito linhas de detalhe em 3h43m. O balde Stale e um balde "normal", logo so
reimprime quando o desfecho daquele simbolo muda, e ainda passa pelo portao por
CONTA `AccountLogGatePodeImprimir("scanblock_USDBRL_Stale", 1800)`. O
`[SCANNER] RESUMO` continua a publicar a contagem por balde (ex.: `Stale=17`),
portanto nenhuma informacao de decisao se perde.

## O que NAO foi feito, e por que

- **Nao foi alterado o texto "preco morto".** Le-se como avaria quando e apenas
  "fora da janela de cotacao". Mudar isso exige versao nova, compilacao e
  reattach para ganhar so clareza de redacao. Fica como decisao do dono.
- **Nao foi posto USDBRL/USDRUB/USDCLP/USDCOP fora da lista `Symbols`.** Tirar
  um simbolo do scan e uma decisao de estrategia, nao uma correcao; e no dia em
  que o feed voltar o EA tem de o voltar a ver.
- **Nao foi mexido `MaxSymbolTickAgeSec`.** Esta em 900 s, que e o valor que
  trava o caso medido. Baixar apertaria simbolos liquidos em feriado; subir
  deixaria passar precos de horas. Nao ha razao medida para o mexer.

## P1.107 candidato (nao aplicado)

Ao verificar o deploy, o `[RESUMO]` do master publicou:

```
[RESUMO] master=SIM | ... | IA=UNAVAILABLE 0.0% | escada=...
```

O master e o grafico USDJPY, que nao tem modelo publicado - portanto
`UNAVAILABLE` e verdade sobre USDJPY. Mas a linha **nao nomeia o simbolo** a que
o campo `IA=` se refere, e no mesmo instante o XAUUSD tinha
`[AI] PYTHON | XAUUSD | SELL | PRICE=4095.600 | CONF=55.70%`. Quem le continua a
poder concluir "a IA caiu".

A correcao do ciclo 105 (P1.102) tornou o valor honesto; falta tornar o sujeito
visivel. Proposta minima, so de texto: `IA(%s)=%s` com `_Symbol`. Exige versao
nova, por isso fica registada e por decidir.

## Deploy da v1.2.147 neste ciclo

A v1.2.147 estava compilada no disco desde as 21:48 mas **nunca tinha sido
reanexada nem commitada** (o ciclo 105 nao tinha ferramentas MCP
`metatrader5`). ProduÃ§Ã£o continuava em v1.2.146. Fechado agora:

| Passo | Resultado |
|---|---|
| Backup do binario anterior | `Files/Backup/XAU_AI_PRO_v12147_877320.ex5` |
| `Tools/auto-deploy.ps1` - gate de versao | `header=1.2.147`, `#property version="1.347"`, `EA_VERSION_STRING="1.2.147"` |
| Compilacao | `Result: 0 errors, 0 warnings, 25391 ms elapsed, cpu='X64 Regular'` |
| `.ex5` | 876 726 B as 22:05:24, mais recente que a fonte mais recente |
| Reattach | `profile_apply Default` -> `profile_apply XAI_P216_LIVE` |
| Prova de runtime | 29 linhas `[START] XAU_AI_PRO v1.2.147 | conta=113568614 | saldo=12592.02` cobrindo 15 simbolos |

Regressoes verificadas depois do reattach (janela 22:05:34-22:09):

| Verificacao | Resultado |
|---|---|
| `PRICE=0.00000` | **0 registos** (P1.98/P1.105 mantidos) |
| `[AI] GATEWAY ... disponivel=false` | visivel em 12 simbolos - **P1.105 a funcionar** |
| Gateway XAUUSD | `1122 bytes | disponivel=true`, `SELL PRICE=4095.600 CONF=55.70%` |
| `[AI] LOAD` | `SYMBOL=XAUUSD | ROOT=LOCAL` (caminho de producao saudavel) |
| Posicoes abertas | 0 |