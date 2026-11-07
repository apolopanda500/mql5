# SESSAO 05-06/11/2026 - ALFA - registo para continuar amanha

Documento de continuidade. Escrito no fecho dos trabalhos de 05/11/2026 (madrugada de 06/11), a pedido do DONO.
Formato: o que foi medido, o que ficou decidido, o que ficou aberto. Nada aqui e "achismo" - cada numero tem origem declarada.

## 1. Onde o projecto esta agora (medido)

- Identidade do codigo: `#property version` = **1.372**; `EA_VERSION_STRING` em `Enterprise/VersionManager.mqh` = **1.2.172**.
- Binario em uso: `MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` = **931194 B**, hash **0A28EDFC5BDC**, mtime **2026-11-06T01:19:48** (compilacao REAL, `Result: 0 errors, 0 warnings`).
- Backup D-040 do binario anterior: `XAU_AI_PRO_1.2.167_20261105_231218.ex5` (929558 B, hash 87E30E2B4E43).
- Modulos carregados no teste: 16, todos OK (`[VERSION] Modulos: ...`).
- Perfil em teste: Conservative | Lot=0.01 | SL=80 | TP=160 | MaxDD=3.0% | Trades=5.

## 2. O que se fez nesta sessao, por ordem

1. **P1.134 + P1.135 aplicados e provados** em `Indicators/VolatilityFilter.mqh` (34124 B, 993 linhas, hash C7531727EF41, chaves 47/47).
   - P1.134: no ramo de falha do `CopyBuffer` tentar `ATRFromRates` antes de publicar SEM LEITURA.
   - P1.135: errno **4807** = `ERR_INDICATOR_WRONG_HANDLE` tratado como handle ERRADO (nao "a aquecer") -> `ATRCacheDrop` + handle recriado na leitura seguinte, no maximo 1x/`ATR_4807_DROP_SEC=900` por simbolo.
2. **B-032** (run_id 7704908543756588672): fechou 02:02:40, `Test passed in 0:42:22.606`, equity **10257.16**, `[VERSION] v1.2.172`.
   - Offset 180740040, segmento 22038506 B: `SEM LEITURA` **218214 -> 0**, `HANDLE MORTO` **4663 -> 0**, `SERIE OK` 0 -> 1, `HANDLE RECRIADO` 0 -> 1, `RATES OOB` 0.
3. **Ferramenta de contagem** reescrita: `contadores_atr_v3.ps1` rebentou (`[System.String]` nao tem `Add`) -> `contadores_atr_v4.ps1` le o log UTF-16LE em blocos de 4 MB com `Decoder` stateful e `StringBuilder` para a linha parcial. **Licao: testar a ferramenta antes de precisar dela.**
4. **Regras elevadas a PROTOCOLO.md seccao 10** (linha 312): 10.1 contagem por OFFSET; 10.2 um job de cada vez; 10.3 .set de medicao vs rotina; 10.4 backup do .ex5 com a versao do BINARIO; 10.5 identidade provada por `[VERSION]`.
5. **D-052** registado (B-032 prova P1.134/P1.135) + AVISO 048.
6. **EMA200=0.00 investigado**: `get_expert_journal` mostra 6 simbolos com pares coerentes (USDJPY 158.110/157.944, USDCAD 1.39727/1.39945, USDSEK 9.77946/9.82677, EURUSD 1.12284/1.12033, GBPUSD 1.34617/1.34082, NZDUSD 0.56228/0.56325). Anomalia **confinada ao Tester**; hipotese = aquecimento + gate `sig_neu_` independente do `copyOK`. Proposta **P1.136 nao aplicada**.
7. **B-033** (A/B do `EnableVolatilityFilter`, run_id 7704922063681257178): fechou 02:51:46, `Test passed in 0:39:01.273`, equity **10242.94**. Filtro OFF perde em tudo: `APPROVED` 98 -> **96**, equity -14.22 USD, `BLOCK` 662 -> 681. **Decisao: filtro fica LIGADO.**
8. **Ganho de robustez lateral**: o B-033 exercitou P1.134/P1.135 **190 vezes** (`SERIE OK=190`, `HANDLE RECRIADO=190`) sem uma unica publicacao sem leitura. O `n` do D-052 sobe de 1 para **191**.

## 3. Numeros que nao se devem perder (tabela A/B)

| Metrica | B-032 filtro ON | B-033 filtro OFF |
|---|---|---|
| `[ATR] SEM LEITURA` | 0 | 0 |
| `[ATR] HANDLE MORTO` | 0 | 0 |
| `[ATR] HANDLE RECRIADO` | 1 | 190 |
| `[ATR] SERIE OK` | 1 | 190 |
| `[VALIDATION] APPROVED` | 98 | 96 |
| `[VALIDATION] BLOCK` | 662 | 681 |
| Trades | 59 | 59 |
| Equity final | 10257.16 | 10242.94 |
| Profit | 257.16 | 242.94 |
| PF / WR | n/d | 1.99 / 54.24% |

Ambos com `[VERSION] v1.2.172` provado no fim do log.

## 4. Pendencias para amanha (por ordem de valor)

**F3 - robustez (o maior buraco aberto).**
- Job multi-simbolo com os 13 graficos para forcar mais handles ATR e provar o caminho em simultaneidade.
- Repetir B-031c com o mesmo .set para reprodutibilidade.
- Capturar o relatorio do BacktestAnalyzer nos DOIS lados do par (o MaxDD 61.50% so tem um lado hoje).

**Codigo (nao aplicado de proposito).**
- P1.136: nao imprimir EMA no `[SIGNAL] NEUTRO` quando `copyOK=false`.
- Uniformizar EOL do `VolatilityFilter.mqh` (CRLF=545 / LF_solto=447) quando nao houver job a correr.

**Decisoes do DONO (nao posso decidir por ele).**
- D-048: 0 shorts - (1) manter comprador por desenho, (2) vender sem exigir EMA50<EMA200 com `ScenarioLotFactor` como travao, (3) referencia mais rapida EMA100 M15.
- Estrategia de modelos: (a) negociar so simbolos com modelo publicado (XAUUSD), (b) publicar modelos para os outros 12, (c) manter os 13 graficos sabendo que 12 nao poderao negociar.
- Go-live em conta real: so o DONO.

**Higiene de disco.**
- `Tester\logs` ~3.3 GB (20261030 331.5 MB, 20261031 1404.9 MB, 20261101 183 MB, 20261102 48.8 MB, 20261103 34.8 MB, 20261104 672.5 MB, 20261105 782.4 MB). **Fora dos write_roots do MCP** -> so o DONO apaga na GUI/Explorer. C: livre ~2.93 GB.
- Dentro de `MQL5`: `Files\Temp` = 133 ficheiros / 1.5 MB, nada relevante a limpar.

**Pendencias do DELTA.**
- D-027 continua `USADO` no `IDS.md` sem bloco no `DECISOES.md`.
- Decidir se o throttle P1.1xx vai para `BACKLOG.md`.
- Confirmar e fechar o PEDIDO 5a.

**Verificacoes menores.**
- chart15 novo (XAUUSD,H1, id 92997207372415) sem EA; confirmar que EURUSD saiu dos graficos com EA.

## 5. Estado do canal e do LOCK

- `LOCK.md`: **LIVRE** (libertado no fecho).
- Nenhum job de tester a correr; nenhuma compilacao pendente.
- Ficheiros do canal actualizados nesta sessao: `DECISOES.md`, `INBOX_AGENTE_2.md`, `INBOX_AGENTE_3.md`, `QUADRO_ESTADO.md`, `IDS.md`, `PROTOCOLO.md`, `AGENTE_1.md`, `SYNC_LOG.md`, `EVIDENCIA_B032_contadores.txt`, mais este documento.

## 6. Aviso

Um backtest nao prova lucro futuro nem robustez em conta real. O que esta medido aqui e o comportamento do EA numa janela fixa de 2026.08.01 a 2026.11.05, com um binario identificado por hash. Qualquer resultado diferente de zero e dependente dessa janela.
