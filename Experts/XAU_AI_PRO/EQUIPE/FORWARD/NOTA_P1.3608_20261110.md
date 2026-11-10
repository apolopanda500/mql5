# NOTA P1.3608 — inanição do pipeline: causa, correção a quente e correção definitiva

**Data:** 10/11/2026 · **Agente:** DELTA · **Estado:** RESOLVIDO em flight (runtime), correção de código PENDENTE para v1.2.204
**Binário durante toda a intervenção:** v1.2.203 · 1 023 258 B · MD5 `10C4DF68A60CDDB0252F12C30AF4A86A` · 16:56:41 — congelamento intacto, sem recompilar o EA.

---

## 1. Sintoma, medido

| Família | Última emissão antes do corte | Primeira depois da correção | Silêncio |
|---|---|---|---|
| `[SCANNER] RESUMO` | 17:10:12.123 (USDSGD) | 18:27:01.108 (USDSGD) | 76 min 49 s |
| `[CENARIO] RETRATO` | — | 18:27:01.108 | — |
| `[PIPELINE] INICIO/FINALIZADO` | — | 18:26:00.404 / 18:26:00.791 | — |
| `[TRADE PIPELINE] INICIANDO` | 18:04:59.248 (NZDUSD) | n/a (1×/30 min por conta) | n/a |

**`[DIAGSCAN]` calado desde 17:10:50 NÃO é sintoma.** `ReadOnlyScanTick()` (Core/MarketScanner.mqh:436) só é chamada no ramo `if(tradeGate != TG_OK)` do `OnTick` (XAU_AI_PRO.mq5:1210). Com a frota 15/15 em `code=0` (portão ABERTO), esse ramo não corre e a linha desaparece por desenho. Nos dias em que `MQL_TRADE_ALLOWED=0` a linha saía de 5 em 5 min. Portanto: **o desaparecimento do `[DIAGSCAN]` é sinal de frota sã, não de pipeline morto** — o P1.3608 contava-o como segundo sintoma e isso estava errado.

## 2. Causa raiz (cadeia completa, provada)

1. `RunTradePipeline()` (Core/TradePipeline.mqh:129) é o **único** chamador de `ProcessSymbol()`, e `ProcessSymbol()` é o **único** chamador de `ScanFlush()` (Core/MarketScanner.mqh:560). Sem dono a correr o pipeline, não existe resumo possível.
2. `RunTradePipeline()` sai na primeira linha em `if(!PipelineIsMaster())` (:139) — 14 das 15 instâncias ficam em STANDBY e nunca chegam a `ProcessSymbol`.
3. `PipelineIsMaster()` (:27) renova o arrendamento de 180 s em **dois** sítios: `OnTick` e `OnTimer` (30 s, independente de ticks, XAU_AI_PRO.mq5:2365 e :2478).
4. O dono era o gráfico **USDRUB** (chart 86832278255844), cuja cotação morreu às 16:57:25 do servidor. O `OnTick` dele nunca mais passou do guarda `CStalenessGuard::CotacaoVelha()` (XAU_AI_PRO.mq5:1305), mas o `OnTimer` **continuava a renovar o batimento**, logo o arrendamento nunca expirava e a eleição nunca acontecia.
5. `PipelineIsMaster()` **rejeita um dono apenas por `MQL_TRADE_ALLOWED=0`** (`if(!CTradeGate::Mql())`, :49). Não olha para a cotação. É o P1.83 (02/11/2026 21:50:33, dono USDCHF recarregado sem permissão) **um bit mais adiante**: lá era permissão, aqui é frescura do preço.

**Prova empírica, ao segundo** (journal 18:25:13.680):

```
[PIPE] ANTES | dono=86832278255844 | batimento=1794335111 | idade=2s | ttl=180s | estado=DONO VIVO
```

O dono morto tinha renovado o próprio arrendamento **2 segundos antes**. É o defeito inteiro numa linha: dono vivo, pipeline morto.

## 3. Correção a quente, sem recompilar (executada)

As `GlobalVariable` são do **terminal**, não do programa; e `PipelineIsMaster()` deixa passar a instância cujo `ChartID` já está na chave (`if(dono != me && (agora - ultimo) < TTL) return(false)` — `dono == me` cai para o `return(true)`). Logo basta escrever as duas chaves com o `ChartID` escolhido e o `TimeLocal()`:

```
XAI_PRO_PIPE_MASTER_<login>    = ChartID do dono
XAI_PRO_PIPE_MASTER_<login>_T  = TimeLocal()   <-- MESMA escala do EA
```

Ferramenta versionada: **`MQL5\Scripts\XAI_PIPE_FORCE.mq5`** (v1.01, 0 errors / 0 warnings, 663 ms). Não envia ordens, não lê posições, não escreve ficheiros, recusa-se a correr no Strategy Tester.

Execução de 18:25:13 (gráfico descartável EURUSD M1, fechado logo depois):

```
[PIPE] ACAO | bastao entregue | dono_anterior=86832278255844 | dono_novo=86832347520548 | batimento=1794335113
[PIPE] DEPOIS | dono=86832347520548 | batimento=1794335113 | idade=0s
```

## 4. Prova em flight (o pipeline voltou)

```
18:25:26.578  XAU_AI_PRO (USDSGD,H1)  [RESUMO] master=SIM | ... | trades=0
18:25:27.107  XAU_AI_PRO (USDSGD,H1)  [BACKUP] Backup concluido com sucesso | arquivos=99 | snapshot=backup_20261110_182526
18:26:00.404  XAU_AI_PRO (USDSGD,H1)  [PIPELINE] INICIO | Symbols=15
18:26:00.4xx  ... 15 símbolos: [SCANNER] START / BLOCK / [SIGNAL] / [GLOBAL] ...
18:26:00.791  XAU_AI_PRO (USDSGD,H1)  [PIPELINE] FINALIZADO
18:27:01.108  XAU_AI_PRO (USDSGD,H1)  [CENARIO] RETRATO | simbolos=10 | ...
18:27:01.108  XAU_AI_PRO (USDSGD,H1)  [SCANNER] RESUMO | visitas=165 | sinais=0 | trades=0 | bloqueios=165 | Stale=55 NoSignal=110 | ADX(sem/ok)=1/127 | SIG(sem/neutro)=0/110
18:30:26.593  XAU_AI_PRO (USDSGD,H1)  [RESUMO] master=SIM | ...
```

Duas provas independentes confirmam a troca de dono: `[PIPELINE] INICIO` + `[SCANNER] RESUMO` a saírem do gráfico USDSGD (só o dono os pode emitir, porque `RunTradePipeline()` sai em `if(!PipelineIsMaster())`), e o **backup**, que só corre no mestre (`XAU_AI_PRO.mq5:2395`), a disparar 13 s depois da troca.

> **Correcção de uma inferência minha, registada para não voltar a ser usada:** cheguei a apresentar o `Data/system_status.json` (`"trading": {"symbol": "USDSGD"}`) como prova da troca de dono. **Não é.** O ficheiro é escrito por `SystemStatusUpdate()` a partir do `OnTimer` de **qualquer** instância (`XAU_AI_PRO.mq5:2355`), sem guarda de mestre: é last-writer-wins. Às 23:25:56 dizia `USDSGD`; às 23:34:25 dizia `GBPUSD`, que não é o dono do pipeline. **O `system_status.json` não serve para dizer quem é o mestre** — só o journal serve.

**`visitas=165` com `Stale=55`** fecha a aritmética: 165/15 = 11 passagens do pipeline em ~95 s, e 55/11 = **5 símbolos sem cotação por passagem** — exactamente o conjunto medido no censo abaixo. O agregado publicado é coerente com o que foi contado.

## 4b. Adenda 18:37 — prova de dono repetível, e o que NÃO serve como sinal de vida

```
18:35:27.553  XAU_AI_PRO (USDSGD,H1)  [RESUMO] master=SIM | posicoes: 0 EA (+0.00 USD) + 0 manual | trades=0
18:35:56.285  XAU_AI_PRO (USDSGD,H1)  [AI] INDISPONIVEL | NZDUSD | MOTIVO=edge instavel: 2/5 folds positivos (media -0.0081)
18:36:49.096  XAU_AI_PRO (USDSGD,H1)  [AI] GATEWAY | HTTP 1003 | ...?symbol=USDCZK&timeframe=H1 | corpo=0B
18:36:49.133  XAU_AI_PRO (USDSGD,H1)  [AI] GATEWAY RECUPERADO | USDSGD | H1 | falhas=1 | cego=0s | resposta=405B
```

`master=SIM` vem de `string master = PipelineIsMaster() ? "SIM" : "STANDBY"` (`Monitoring/OperatorBrief.mqh:117`) — avaliado na própria instância, ao contrário do `system_status.json`. **É prova de dono e é repetível.** As linhas `[AI]` com símbolos diferentes (NZDUSD, depois USDCZK) mostram a varredura a avançar.

Duas precisões, para o mesmo erro não voltar:

- `[PIPELINE] INICIO` / `[PIPELINE] FINALIZADO` estão limitados a **1 por hora, por símbolo e por desfecho** — `DiagGateAllow(_Symbol, "PIPELINE_INICIO", IntegerToString(total), 3600)` em `Core/TradePipeline.mqh:181` e `DiagGateAllow(_Symbol, "PIPELINE_FIM", "FINALIZADO", 3600)` em `:259`. Depois das 18:26:00 não reaparecem antes das 19:26, e **a ausência delas não é morte do pipeline**.
- `[SCANNER] RESUMO` silencioso sai no máximo **1×/15 min** (`SCAN_SILENT_SEC = 900`). Até 15 min sem resumo é cadência.

## 5. Censo da frota ao segundo (18:32:33, `XAI_PIPE_FORCE` v1.01)

| Idade do tick | Símbolos |
|---|---|
| 0–32 s (vivos) | USDJPY 0s, USDCAD 0s, NZDUSD 2s, USDSEK 3s, USDCHF 3s, USDCZK 3s, GBPUSD 3s, USDSGD 27s, AUDUSD 31s, USDCNH 32s |
| 1 953 s (32 min) | **XAUUSD**, USDBRL — pararam no MESMO segundo (22:59:59 servidor = 18:00:00 local) |
| 12 762 s / 14 699 s | USDCOP, USDCLP (esparsos, não mortos) |
| 23 707 s (6 h 35) | **USDRUB** (o antigo dono) |

`graficos_com_EA=15 | dono_symbol=USDSGD | dono_idade_tick=27s`.

**Isto corrige uma reserva do dossier.** A "amostra máxima é 12, não 15" fica desactualizada a esta hora: os sem cotação são **5** (XAUUSD, USDBRL, USDCLP, USDCOP, USDRUB), logo o tecto desta janela é **10**. E o símbolo com modelo de IA aprovado — XAUUSD — é um dos que estão sem tick, o que explica `sinais=0` na janela sem invocar o gate de IA.

## 6. Correção definitiva (código) — PENDENTE, não aplicada

Não foi aplicada **de propósito**: alterar `Core/TradePipeline.mqh` deixaria o código à frente do binário congelado, que é precisamente a divergência que a janela de 30 dias tem de poder negar. Fica aqui o patch exacto, para o próximo build (v1.2.204), após o fecho da janela.

`Core/MarketScanner.mqh` é incluído **antes** de `Core/TradePipeline.mqh` (XAU_AI_PRO.mq5:153 e :154), logo `SymbolDataFresh()` já está visível no ponto de inserção — **sem novos inputs** (o `inputs_sha256 4B71E6E1…` de 39 campos não muda) e reutilizando o mesmo critério da varredura (`EnableStaleDataGuard` + `MaxSymbolTickAgeSec`, relógio `TimeTradeServer()`).

Inserir em `Core/TradePipeline.mqh`, imediatamente **antes** de `if(!CTradeGate::Mql())` (:49):

```mql5
   // P1.3608 (v1.2.204) - MEDIDO em 10/11/2026 18:25:13: o dono do pipeline era o
   // grafico USDRUB, com a cotacao morta desde 16:57:25. O OnTick dele nunca mais
   // passou do CStalenessGuard::CotacaoVelha(), mas o OnTimer (30 s, sem ticks)
   // continuava a renovar o arrendamento de 180 s; os outros 14 graficos ficaram
   // em STANDBY e o [SCANNER] calou-se das 17:10:12 as 18:27:01.
   // O guarda rejeitava um dono so por MQL_TRADE_ALLOWED=0 (P1.83) e nunca por
   // preco parado. Um dono sem cotacao nao pode ser dono: sem tick nao ha OnTick,
   // e sem OnTick o pipeline nao corre. Reutiliza o criterio da varredura
   // (SymbolDataFresh): nenhum input novo, nenhum parametro de risco tocado.
   string motivoDono = "";

   if(!SymbolDataFresh(_Symbol, motivoDono))
     {
      if(GlobalVariableCheck(key))
         GlobalVariableDel(key);
      if(GlobalVariableCheck(keyBeat))
         GlobalVariableDel(keyBeat);

      static datetime lastSemCotacao = 0;
      datetime agoraSem = TimeLocal();

      if(agoraSem - lastSemCotacao >= 1800)
        {
         lastSemCotacao = agoraSem;
         Print("[PIPELINE] DONO SEM COTACAO | ", _Symbol, " | ", motivoDono,
               " | bastao libertado: a proxima instancia com preco vivo assume");
        }

      return(false);
     }
```

Notas de desenho, para o revisor:

- **Fail-closed, não fail-open**: sem cotação própria a instância não é dona. É o mesmo sentido do `CStalenessGuard` do `OnTick`.
- **Efeito colateral aceite e conhecido**: com o mercado fechado *todos* os símbolos ficam stale e não há mestre — logo o `[BACKUP]` (que só corre no mestre) para. É o comportamento desejado (não se faz backup de um mercado morto às 03:00) mas tem de estar escrito, porque muda a cadência de snapshots ao fim de semana.
- **Não resolve sozinho o caso "dono vivo com feed lento"**: se a cotação do dono tem 800 s e o limite é 900 s, ele continua dono. Isso é correcto: 800 s é feed lento, não feed morto.
- Uma alternativa mais barata (sem tocar no EA) seria eleger sempre o gráfico com o tick mais fresco; foi rejeitada por precisar de `ChartFirst/ChartNext` dentro do EA e por mudar a semântica do guarda em vez de a completar.

## 7. Como repetir a correção a quente nos próximos 30 dias

```
metaeditor5__compile_file      Scripts\XAI_PIPE_FORCE.mq5      (só o script)
metatrader5__chart_add_script  Scripts\XAI_PIPE_FORCE.ex5      parâmetros: InpAuto=true
```

`InpAuto=true` é **idempotente**: faz o censo, e só entrega o bastão se o dono actual estiver sem gráfico, sem o EA, ou com tick mais velho que `InpFreshSec` (900 s). Correr várias vezes ao dia não faz nada enquanto o dono tiver cotação viva — verificado às 18:33:01: `[PIPE] ACAO | nenhuma | o dono 86832347520548 (USDSGD) tem cotacao viva ha 0s - nada a corrigir`.

`InpClear=true` apaga as chaves e devolve o bastão à corrida (não recomendado: o USDRUB também participa da corrida, via `OnTimer`).

## 8. O que NÃO foi feito

- Nenhuma recompilação do EA. `.ex5` re-medido depois da intervenção: 1 023 258 B · 16:56:41 · `10C4DF68A60CDDB0252F12C30AF4A86A`.
- Nenhuma escrita em `.chr`, `.tpl`, `DECLARADO.json`, `FORWARD.md`, `medicao.jsonl`, `medicao_diaria.jsonl`, `ultima_medicao.log`.
- Nenhuma ordem, nenhuma alteração de posição, SL, TP, lote, alvo, piso de IA ou parâmetro de risco.
- Nenhuma alteração de código do EA (ver secção 6).
- O gráfico descartável usado (EURUSD M1) foi fechado; o perfil `XAU_AI_PRO_15CHARTS_Q071` continua com **15** `.chr` (chart01…chart15), sem `chart16`.

## 9. Para o CMD

1. **P1.3608 fecha** com prova em flight e sem violar o congelamento. O segundo sintoma que eu tinha associado (`[DIAGSCAN]` calado) é falso positivo — ver secção 1.
2. **P1.3608 → P1.3610 (novo, código):** `PipelineIsMaster()` não tem teste de frescura. Patch pronto na secção 6; entra em v1.2.204, depois do fecho da janela. Não é urgente *durante* a janela porque a correção a quente está disponível e é barata.
3. **Frota, esta hora:** 10 com cotação viva, 5 sem. O tecto de amostra da janela é 10, não 12 — e o XAUUSD (único com modelo aprovado) está entre os 5. Actualizar a reserva do dossier.
4. **O `[BACKUP]` voltou** com a troca de dono (snapshot `backup_20261110_182526`, 99 ficheiros). O buraco de backups entre 18:13:42 e 18:25:26 é consequência do mesmo defeito, não uma segunda avaria.
