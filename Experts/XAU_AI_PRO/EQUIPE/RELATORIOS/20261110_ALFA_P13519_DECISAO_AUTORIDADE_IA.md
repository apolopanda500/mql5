# RELATÓRIO DE ETAPA — ALFA — P1.3519 MEDIDO: o piso 0.02 compra ruído, não modelos — 10/11/2026 04:22

**Autor:** ALFA · **Para:** DONO (decisão) e CMD (não executar antes de ler) · **Etapa:** medição do gateway e especificação da correcção
**Estado:** nada compilado, nada deployado, nada reiniciado, nenhum input alterado, nenhuma ordem.

---

## 1. O que eu fui medir e o que apareceu

O P1.3519 dizia: "só o XAUUSD tem modelo; os outros 14 são inoperáveis com `AIHasSignalAuthority=true`". Fui ao gateway (HTTP 200, token do `.env` local, valor nunca impresso) pedir a previsão símbolo a símbolo. Resultado literal:

| Símbolo | available | model | signal | edge | accuracy | price | atr |
|---|---|---|---|---|---|---|---|
| **XAUUSD** | **true** | `"XAUUSD 1H"` | SELL (73.2) | **+0.0363** | 0.5361 | 4116.96 | 17.42 |
| USDCAD | false | `""` | NEUTRAL | null | null | 0 | 0 |
| USDCHF | false | `""` | NEUTRAL | null | null | 0 | 0 |
| USDCNH | false | `""` | NEUTRAL | null | null | 0 | 0 |

Razão devolvida: `edge +0.0317 abaixo do minimo +0.0500 (acc 0.3752 vs palpite 0.3435)`.

---

## 2. Duas descobertas que mudam a decisão

### 2.1 O piso **não** mede a qualidade do modelo publicado — mede só o caminho sem modelo

O `XAUUSD` tem **edge +0.0363**, portanto **abaixo** do piso `+0.0500`, e mesmo assim recebe `available=true`, com `reason="inferencia real do modelo publicado"`. Ou seja: **o piso só se aplica a símbolos sem modelo**. Baixá-lo de `0.05` para `0.02` não "abre 5 modelos" — abre 5 símbolos **sem** modelo.

### 2.2 Os 5 símbolos que o piso 0.02 deixa entrar operam a 4 pontos do aleatório

`acc 0.3752 vs palpite 0.3435`: num alvo de 3 classes (compra/venda/neutro), o aleatório é **0.333**. Isto é um estimador a **+4.2 p.p.** do aleatório, com `model:""`, `price 0`, `atr 0` — e o `edge +0.0317` é literalmente `0.3752 − 0.3435`.

Com `AIHasSignalAuthority=true`, o código (`AI/AIEngine.mqh:395-400`) faz:

```
if(AIHasSignalAuthority)
  {
   if(ai!=0) return ai;   // a IA MANDA
   return 0;              // sem IA: nao opera, o tecnico nem e' consultado
  }
```

Portanto, se o piso baixar e esses 5 passarem a `available=true`, **a decisão de abrir ordem em 5 símbolos passa a ser de um estimador quase aleatório, com o sinal técnico silenciado**. Isto não é "largura, não qualidade" (D-152) — é **largura comprada com ruído**, e a autoridade da IA garante que o ruído ganha ao técnico.

---

## 3. O que está realmente ligado no perfil vivo (`chart01.chr`)

| Input | Valor |
|---|---|
| `AIHasSignalAuthority` | **true** |
| `AIAuthorityMinScore` | 75.0 |
| `AIConflictMinScore` | 80.0 |
| `AllowTradeWithoutAI` | true |
| `RequireAIJSON` | **true** |
| `MinAIConfidence` | 60.0 |
| `RiskPercent` / `MaxDailyLossUsd` | 0.5 / 600.0 |
| `Symbols` | 15 nomes |

Nota: `RequireAIJSON=true` (modo produção estrito) **mais** `AIHasSignalAuthority=true` é dupla exigência de IA — e é coerente com o resultado: 1 símbolo opera, 14 não.

---

## 4. As quatro opções (custo e consequência)

| # | Política | Símbolos que podem operar | G5 (12M) | Risco novo | Custo |
|---|---|---|---|---|---|
| **A** | manter: autoridade ON + piso 0.05 | **1** | 12.26 → **8.2× fora** | nenhum de ruído | **0** |
| **B** | piso 0.02 + autoridade ON (pedido do DELTA ao CMD) | 5 efetivos (6 nominais) | ~61 → 1.6× fora | **5 símbolos decididos por estimador a 4 p.p. do aleatório**, técnico silenciado; exposição simultânea ~2.5% | 0 no EA (executa-se no gateway) |
| **C** | autoridade **OFF** (só input, sem recompilar) | 15 (o técnico decide) | a medir | muda a política que o DONO pediu em 05/10 ("a IA decide"); e 97.3% dos sinais morrem em VALIDATION (D-148) | 1 input por gráfico → reload → G4 re-ancora |
| **D** | **autoridade por símbolo**: a IA manda onde há modelo, o técnico onde não há | 1 com IA + 14 com técnico | a medir (maior que A, sem ruído a decidir) | baixo: o técnico já é o motor auditado no D-141 | **código + recompilar + deploy + G4** (tem de estar estável antes de 11/11 00:05) |

---

## 5. Recomendação do ALFA

**Duas decisões, nesta ordem:**

1. **Imediata (hoje, antes de 11/11 00:05): NÃO aplicar o piso `0.02` com a autoridade da IA ligada.** Segurar o pedido do DELTA ao CMD (aviso enviado). Se o DONO quiser mesmo a largura de 5 símbolos agora, tem de vir **junto** com a opção C, senão o ruído manda.
2. **Estrutural: opção D** — é a única que responde ao P1.3519 sem trocar qualidade por quantidade, e a única que faz o forward medir 15 símbolos em vez de 1.

**Especificação do D (pronta a executar, não executada):**

- `Core/Config.mqh` — novo input, junto de `AIHasSignalAuthority`:
  `input bool AIFallbackToTechWhenNoModel = false;  // P1.3519: sem modelo publicado, o tecnico decide (a IA mantem veto)`
- `AI/AIEngine.mqh` — helper e 2 linhas em `GetCombinedSignal`:

```
// P1.3519: o gateway respondeu com previsao real? (nao NEUTRAL/UNAVAILABLE)
bool AIModelAnswered(string symbol="")
{
   if(!LoadAIPrediction(symbol))                     return(false);
   if(AI_Signal=="UNAVAILABLE" || AI_Signal=="ERROR") return(false);
   return(AI_Confidence > 0.0);
}
...
if(AIHasSignalAuthority)
  {
   if(ai!=0) return ai;
   if(AIFallbackToTechWhenNoModel && !AIModelAnswered(symbol))
      return tech;          // simbolo sem modelo: decide a regra tecnica
   return 0;                // com modelo e calado: continua a nao operar
  }
```

- Ordem de execução: backup do `.ex5` (PROTOCOLO §10.4) → editar → compilar (0 erros) → backtest de fumo → deploy nos 15 gráficos → re-ancorar G4 → medir 1 hora de journal → só depois declarar a identidade nova.
- **Janela:** tem de estar feito e estável **antes de 11/11 00:05 servidor**. Se não houver tempo seguro, a decisão é A (manter) e o D fica para depois da janela.

---

## 6. O que muda no que o DELTA pediu ao CMD

O pedido `PEDIDO_CMD_D151_PISO_EDGE.md` continua tecnicamente correcto na descrição do alvo, mas a **consequência** está subestimada: os 5 nomes entram com `model:""`. O teste de aceitação também tem de mudar (P1.3525: `[AI] PYTHON` é invisível neste build). Enviei aviso ao CMD para **não executar** antes de o DONO escolher A/B/C/D.

---

## 7. Provas

- Gateway: 5 pedidos HTTP 200 (XAUUSD 1121 B; os outros 357 B), token lido de `MQL5\Files\XAU_AI_PRO\.env` (64 caracteres, valor nunca impresso nem registado).
- Código: `AI/AIEngine.mqh:377-403` (`GetCombinedSignal`), `AI/AIEngine.mqh:300` (`GetAIEngineSignal` devolve 0 sem previsão), `AI/AIConnector.mqh:446-471` (`available=false` → `AI_Signal="UNAVAILABLE"`).
- Perfil: `MQL5\Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071\chart01.chr` linhas 172-184 e 254.
- Binário inalterado: 977 654 B · mtime 10/11 02:23:07 · MD5 `71ED34C690C9593D209A69E95F0EFFB6`.
