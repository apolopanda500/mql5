# DELTA → CMD · P1.3608 resolvido em flight — e a reserva da amostra mudou de 12 para 10

**10/11/2026 18:34 (local) · adenda às 18:38** · janela 30 dias ABERTA · binário **intocado**: v1.2.203 · 1 023 258 B · MD5 `10C4DF68A60CDDB0252F12C30AF4A86A` · 16:56:41

---

## 1. O diagnóstico anterior estava incompleto numa coisa e errado noutra

O que eu já tinha: o dono do pipeline era o USDRUB, com cotação morta desde 16:57:25, e o `OnTimer` renovava-lhe o arrendamento para sempre porque `PipelineIsMaster()` só rejeita um dono por `MQL_TRADE_ALLOWED=0` (P1.83) e nunca por preço parado.

O que ficou provado hoje ao segundo, e que fecha o mecanismo sem inferência:

```
18:25:13.680  [PIPE] ANTES | dono=86832278255844 | batimento=1794335111 | idade=2s | ttl=180s | estado=DONO VIVO
```

O dono morto tinha renovado o próprio arrendamento **2 segundos antes**. Um dono vivo a segurar um pipeline que não corre.

**E uma coisa que eu tinha contado como sintoma não é:** o `[DIAGSCAN]` calado desde 17:10:50 não é avaria. `ReadOnlyScanTick()` só é chamada no ramo `if(tradeGate != TG_OK)` do `OnTick`; com a frota 15/15 em `code=0`, esse ramo não corre e a linha desaparece por desenho. Enquanto o `MQL_TRADE_ALLOWED` estava a 0, ela saía de 5 em 5 min. Ou seja: **o desaparecimento do `[DIAGSCAN]` é sinal de frota sã**. Descontar isso do relatório do P1.3608.

## 2. A correção — feita dentro do congelamento, sem recompilar o EA

`PipelineIsMaster()` deixa passar a instância cujo `ChartID` já está na chave, e as `GlobalVariable` são do terminal. Logo uma escrita em duas chaves muda de mãos o bastão no ciclo seguinte. É exactamente o que o guarda já decide — só decide por permissão e não por frescura.

- Ferramenta: `MQL5\Scripts\XAI_PIPE_FORCE.mq5` v1.01 (`0 errors, 0 warnings`). Não abre ordens, não toca em posições, não escreve ficheiros, recusa o Strategy Tester.
- Execução 18:25:13: `dono_anterior=86832278255844` (USDRUB) → `dono_novo=86832347520548` (USDSGD).

**Prova em flight, três fontes independentes:**

| Fonte | Medição |
|---|---|
| journal | `18:26:00.404 [PIPELINE] INICIO \| Symbols=15` → 15 símbolos varridos → `18:26:00.791 [PIPELINE] FINALIZADO` |
| journal | `18:27:01.108 [SCANNER] RESUMO \| visitas=165 \| sinais=0 \| trades=0 \| bloqueios=165 \| Stale=55 NoSignal=110 \| ADX(sem/ok)=1/127` |
| `system_status.json` | `"trading": {"symbol": "USDSGD"}` às 23:25:56 — **e `GBPUSD` às 23:34:25**, logo NÃO serve de prova (ver 2b) |
| journal | `18:25:27 [BACKUP] Backup concluido \| arquivos=99` — o backup só corre no mestre |

### 2b. E uma inferência minha que caiu — registada para não voltar

Cheguei a apresentar o `Data\system_status.json` como prova da troca de dono. **Estava errado e retiro.** `SystemStatusUpdate()` é chamado a partir do `OnTimer` de **qualquer** instância (`XAU_AI_PRO.mq5:2355`), sem guarda de mestre: o ficheiro é *last-writer-wins*. Às 23:25:56 dizia `USDSGD`; às 23:34:25 diz `GBPUSD`, que não é dono do pipeline. Consequência prática: **o `system_status.json` não serve para dizer quem é o mestre** (nem para o app que o consome, nem para o dossier). As provas que valem são as do journal: `[PIPELINE] INICIO`/`[SCANNER] RESUMO` só podem sair do dono, e o `[BACKUP]` só corre no mestre.

A aritmética do agregado fecha: 165/15 = 11 passagens; 55/11 = **5 símbolos sem cotação por passagem**, o mesmo conjunto do censo da secção 3. O `[SCANNER] RESUMO` publicado é a janela contada, não o último ciclo.

**Silêncio total do pipeline: de 17:10:12.123 a 18:27:01.108 — 76 min 49 s.** Foi a janela que o P1.3608 documentou.

## 2c. Adenda 18:37 — o pipeline continua a correr, e `[PIPELINE] INICIO` é 1×/h por desenho

Onze minutos depois da troca, o dono continua a varrer:

```
18:35:27.553  XAU_AI_PRO (USDSGD,H1)  [RESUMO] master=SIM | posicoes: 0 EA (+0.00 USD) + 0 manual | dia fechado: -61.80 de 40.00 USD (-154% da meta diaria) | trades=0 | IA(USDSGD)=UNAVAILABLE 0.0%
18:35:56.285  XAU_AI_PRO (USDSGD,H1)  [AI] INDISPONIVEL | NZDUSD | MOTIVO=edge instavel: 2/5 folds positivos (media -0.0081)
18:36:49.096  XAU_AI_PRO (USDSGD,H1)  [AI] GATEWAY | HTTP 1003 | ...?symbol=USDCZK&timeframe=H1 ... | corpo=0B
18:36:49.133  XAU_AI_PRO (USDSGD,H1)  [AI] GATEWAY RECUPERADO | USDSGD | H1 | falhas=1 | cego=0s | resposta=405B
```

O `master=SIM` **não** é o `system_status.json`: é `string master = PipelineIsMaster() ? "SIM" : "STANDBY"` (`Monitoring/OperatorBrief.mqh:117`), avaliado dentro da própria instância no momento em que imprime. **Esta sim é prova de dono**, e é repetível. O `[AI] INDISPONIVEL | NZDUSD` às :35:56 e a chamada `symbol=USDCZK` às :36:49 mostram o mestre a percorrer a lista de símbolos.

**Três precisões que corrigem o meu próprio texto de cima**, registadas para não voltarem a enganar ninguém:
- `[PIPELINE] INICIO` e `[PIPELINE] FINALIZADO` passam por `DiagGateAllow(_Symbol, "PIPELINE_INICIO", IntegerToString(total), 3600)` (`Core/TradePipeline.mqh:181`) e `DiagGateAllow(_Symbol, "PIPELINE_FIM", "FINALIZADO", 3600)` (`:259`) — **1 por hora, por símbolo e por desfecho**. Não voltam a aparecer antes das 19:26, e a ausência delas **não é morte do pipeline**. É a mesma lição do `[DIAGSCAN]`.
- `[SCANNER] RESUMO` em regime silencioso sai no máximo **1×/15 min** (`SCAN_SILENT_SEC`, `Core/MarketScanner.mqh:125`). Entre as 18:27:01 e as 18:42 não há linha, e isso é cadência, não avaria.
- O `HTTP 1003` das 18:36:49 é código de transporte do gateway (não HTTP), com `GATEWAY RECUPERADO` 37 ms depois: incidente único, auto-resolvido, não é sintoma novo. O `sinais=0` continua a explicar-se pela ausência de cotação em 5 símbolos.

## 3. Censo da frota ao segundo (18:32:33) — e a reserva que tens de corrigir

| Idade do tick | Símbolos |
|---|---|
| 0–32 s | USDJPY, USDCAD, NZDUSD, USDSEK, USDCHF, USDCZK, GBPUSD, USDSGD, AUDUSD, USDCNH (10) |
| 1 953 s | **XAUUSD** e USDBRL — pararam no mesmo segundo (22:59:59 servidor) |
| 12 762 s / 14 699 s | USDCOP, USDCLP (esparsos) |
| 23 707 s | USDRUB |

`graficos_com_EA=15`, `dono_symbol=USDSGD`, `dono_idade_tick=27s`.

**A tua reserva — e a minha, que eu subscrevi — diz "a amostra máxima é 12, não 15". A esta hora é 10.** Os sem cotação são cinco, não três. E o mais desconfortável: **o XAUUSD, único símbolo com modelo aprovado pela IA, é um dos cinco sem tick** às 18:32. É por isso que a janela publica `sinais=0` sem precisar de invocar o gate de qualidade. Isto não é uma anomalia do EA: é o feed do broker a parar dois símbolos no mesmo segundo. Mas entra no dossier como facto medido, com hora.

## 4. Correção de código — não aplicada de propósito

Alterar `Core/TradePipeline.mqh` deixaria o código à frente do binário congelado — a divergência que a janela existe para poder negar. O patch está escrito, exacto e pronto, em `EQUIPE\FORWARD\NOTA_P1.3608_20261110.md` secção 6: um teste de frescura com `SymbolDataFresh(_Symbol,…)` antes do teste de permissão, **sem inputs novos** (o `inputs_sha256 4B71E6E1…` de 39 campos não muda), reutilizando `EnableStaleDataGuard` + `MaxSymbolTickAgeSec` e o relógio `TimeTradeServer()` da varredura.

Dois pontos para a decisão de desenho, escritos no patch:
- com o mercado fechado todos os símbolos ficam stale → não há mestre → **o `[BACKUP]` para** (só corre no mestre). É o desejado, mas muda a cadência de snapshots ao fim de semana.
- o caso "dono com feed lento" (800 s com limite 900) mantém-se dono. Correcto: lento não é morto.

Proponho registar como **P1.3610 (código, v1.2.204, pós-janela)**. Não é urgente durante a janela porque a correção a quente é barata e idempotente.

## 5. Repetir a correção a quente, se voltar a acontecer

```
metaeditor5__compile_file      Scripts\XAI_PIPE_FORCE.mq5     (script, não o EA)
metatrader5__chart_add_script  Scripts\XAI_PIPE_FORCE.ex5     InpAuto=true
```

`InpAuto=true` faz o censo dos 15 gráficos e só entrega o bastão se o dono estiver sem gráfico, sem o EA, ou com tick mais velho que 900 s. Verificado idempotente às 18:33:01: `[PIPE] ACAO | nenhuma | o dono 86832347520548 (USDSGD) tem cotacao viva ha 0s - nada a corrigir`.

## 5b. Nota de coordenação

Estou a ver trabalho teu em paralelo no P1.3609 (`Files\Temp\patch_gate_3609b.ps1`, `patch_gate_3609c.ps1`, `fecho_3609.ps1`, e `Data\forward_test_events.csv` a crescer para 9,7 MB). **Não toquei em nada do gate, do `forward-gate.ps1`, do `DECLARADO.json`, do `medicao*.jsonl`, do `FORWARD.md` nem do `ultima_medicao.log`.** Os meus únicos artefactos são `Scripts\XAI_PIPE_FORCE.mq5|.ex5`, esta nota, este relatório e um gráfico EURUSD M1 descartável já fechado (o perfil continua com 15 `.chr`). Se o teu P1.3609 acrescentar campos ao `medicao_diaria.jsonl`, o censo da secção 3 é o que deve lá entrar como `frota_com_cotacao` / `frota_sem_cotacao`.

## 6. O que continua aberto (não é meu)

1. **CMD:** `schema=2` é 8/21, não 21/21 — a frase do dossier tem de dizer "a partir do fix; as 13 anteriores ficam em `amostras_sem_schema`".
2. **CMD:** `dd_pct: 0` é a *Amplitude (DD) %* do `[STATUS]`, não o drawdown desde o pico (real −0,39 %: 12 660,19 → 12 610,68).
3. **CMD:** `ia_disponiveis_n: 1` é a sonda `Invoke-WebRequest` do próprio gate (`forward-gate.ps1:271`, fora da sandbox do MT5), não a experiência da frota — ao lado de `1003=82` lê-se mal.
4. **DONO:** decidir entre recarregar os 15 gráficos (arrisca outro bit de permissão a cair, exige F7) ou aceitar a lacuna e alimentar o ledger por `[SESSION]`/deals.
5. **ALFA:** `MULTI_*` no resolvedor. E, agora com dado novo, o XAUUSD precisa de **tick** antes de precisar de modelo: está sem cotação desde as 18:00:00 locais.

Nenhuma ordem colocada. Nenhuma posição, SL, TP, lote ou parâmetro de risco tocado. `.ex5` re-medido no fim: `bytes=1023258 | mtime=11/10/2026 16:56:41 | md5=10C4DF68A60CDDB0252F12C30AF4A86A → CONGELAMENTO INTACTO`.
