# AUDITORIA ETAPA 2 — PARTE 1: Config + SymbolManager + Utils (21/08/2026)

**Método:** leitura integral + varredura de usos cruzados + prova por compilação.

---

## MÓDULO 1 — Core/Config.mqh (260 linhas) — ✅ SAUDÁVEL

**Papel:** fonte única de todos os `input` do EA (AutoTrade, risco, spread, sessão, KCI, multi-symbol, debug).

Achados:
- Estrutura limpa; helper `GetMaxSpread(symbol)` resolve limite por símbolo com fallback global (GOLD#:350, BTCUSD#/ETHUSD#:600, global 50).
- `RequireAIJSON=false` → modo IA não-estrito (IA é opcional no gate — coerente com regra "IA não tem autoridade absoluta").
- `EnableVerboseDebug=true` em produção gera ~1MB/min de log (anomalia A10 — recomendação: input de produção ou rotação).
- `TradeStartHour=0/TradeEndHour=24` → janela 24h (sessão efetivamente desligada como filtro).
- Nenhum conflito com outros módulos: é o include raiz de quase tudo.

**Veredito:** manter como está. Nenhuma ação obrigatória.

## MÓDULO 2 — Core/SymbolManager.mqh (389 linhas) — ✅ SAUDÁVEL (após v1.2.1)

**Papel:** resolve os 12 símbolos configurados para a nomenclatura da corretora (16 candidatos + fallbacks Market Watch), gate `SymbolsPending` com retry em OnTick/OnTimer.

Achados:
- Corrigido nesta sessão: cap `SYMBOL_RETRY_MAX=12` e remoção da setagem de pending por erro !=4301 em candidatos (causa do travamento histórico do pipeline).
- Comportamento atual validado em produção: reinits por queda de rede não geram mais pendência; pipeline inicia imediatamente.
- `IsSymbolTradeable` trata TRADE_MODE_DISABLED/CLOSEONLY com log — correto.
- US30/US500/USTEC: inexistentes na corretora — falham silenciosamente por design agora.

**Veredito:** manter. Pendência cosmética: reduzir verbosidade da init (imprime Market Watch inteiro a cada retry).

## MÓDULO 3 — Utils.mqh (672 linhas, 20 funções) — ❌ CÓDIGO MORTO (REMOVIDO)

**Prova por varredura:** 19/20 funções com ZERO usos externos. A 20ª (`NormalizeVolume`) colide por nome com `CVolumeValidator::NormalizeVolume` (classe Enterprise, a que realmente é usada). Única referência externa a qualquer função (`IsGoodSession`) vinha do ValidationChecklist.mqh — ele próprio órfão.

**Duplicações que o Utils carregava (agora eliminadas do build):**
- Sessão → já coberta por Filters/SessionFilter
- Volume min/max/step/normalize → já coberta por Enterprise/VolumeValidator
- Resolução de símbolo → já coberta por Core/SymbolManager
- Stops level/preço → já coberta por SmartExecution/BrokerAnalyzer

**Ação executada:** movido para `MQL5\Files\Backup\XAU_AI_PRO_orfaos_v122\`, include removido do XAU_AI_PRO.mq5, entrada removida do .mqproj (JSON validado). **Prova final: compilação sem ele = 0 erros, 0 warnings.**

## LIMPEZA EXECUTADA NESTA SESSÃO (tudo reversível em MQL5\Files\Backup\XAU_AI_PRO_orfaos_v122\)

| Arquivo | Motivo |
|---|---|
| Utils.mqh | 100% morto em runtime (prova acima) |
| APILayer.mqh | Órfão — API externa inexistente |
| PluginSystem.mqh | Órfão — plugins nunca ativos |
| EventManager.mqh | Órfão |
| ExecutionTracker.mqh | Órfão |
| Trend Flasher_AK.mq5 | EA de terceiro solto na pasta (A1) |
| prediction.json (raiz) | Legado duplicado de Data\ (A7) |
| XAU_AI_PRO.mqproj.bak | Backup do projeto pré-limpeza |

## PRÓXIMA PARTE (ETAPA 2 — Parte 2)

DecisionEngine + ValidationEngine + Filters: rastrear o caminho completo do sinal (por que entra/não entra) e preparar a hierarquia de risco da ETAPA 3.
