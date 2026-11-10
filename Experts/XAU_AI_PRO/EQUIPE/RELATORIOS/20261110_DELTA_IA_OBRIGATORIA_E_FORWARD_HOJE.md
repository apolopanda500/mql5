# RELATORIO DELTA - 10/11/2026 10:33 local (servidor 15:33)

**Etapa: respostas do DONO executadas + duvida de versao resolvida.**
Papel DELTA (medicao de mercado vivo + dossier). Nao declarei GATE_REAL nem
assinei `DOSSIE_FINAL.md`. Nao compilei, nao reiniciei gateway, nao mexi no
binario.

---

## 1. "1.391" NAO e' outro EA - e' o mesmo v1.2.191

O DONO viu na propriedade/aba do programa `1.391` e estranhou, porque o journal
diz `v1.2.191`. Sao a mesma coisa, e a razao esta' escrita no proprio fonte:

- `XAU_AI_PRO.mq5:32` -> `#property version "1.391"`. O compilador MQL5 so'
  aceita `xxx.yyy` (dois numeros); sem isso da' `warning 68: version ... is
  incompatible with MQL5 Market`.
- Cabecalho do mesmo ficheiro (linhas 12-20) documenta a codificacao:
  **identidade numerica = `minor*100 + patch`**. Assim `1.2.191` ->
  `2*100 + 191 = 391` -> `"1.391"`.
- A versao de produto vive em `Enterprise/VersionManager.mqh`:
  `#define EA_VERSION_STRING "1.2.191"`, e e' a que o EA publica no arranque.

**Provas medidas (nao declaradas):**

| Prova | Resultado |
|---|---|
| `[START]` no journal, 15 graficos, 10:27:05.528-10:27:10.336 | `XAU_AI_PRO v1.2.191` em **15/15** |
| `list_available_mql5_programs` (Experts) | **um unico** `XAU_AI_PRO`, um unico caminho, build `2026-11-10T05:23:07Z` |
| MD5 do `.ex5` | `71ED34C690C9593D209A69E95F0EFFB6`, 977654 B, mtime `2026-11-10T02:23:07` |
| Templates de prova dos 15 graficos | `path=Experts\XAU_AI_PRO\XAU_AI_PRO.ex5` em 15/15 |

Regra que fica: **autoridade e' o MD5**, nunca a etiqueta de versao.

## 2. O que foi executado hoje (ordem do DONO, 10:25)

1. **IA obrigatoria**: `AllowTradeWithoutAI` `true` -> `false` nos **15/15**
   graficos. Rota provada: `chart_save_template` -> flip cirurgico no `.tpl`
   (UTF-16LE) -> `chart_apply_template` (15/15 `ok:true`) -> `chart_save_template`
   de novo como prova. Outros 14 inputs criticos com **uma unica variante em
   15/15** (ver P1.3576 no `IDS.md`). **Binario intacto.** Backups dos `.tpl`
   originais em `MQL5\Files\Backup\AI_SWITCH_20261110\`.
2. **MTF fica LIGADO** (o DONO nao decidiu; desligar muda o que se mede e e'
   decisao de capital). Consequencia escrita: o forward mede quantos sinais o
   filtro M15 deixa passar.
3. **Forward re-ancorado para HOJE**: ancora **10/11 15:27 servidor** (10:27
   local), janela de 30 dias ate' **10/12/2026 15:27 servidor**. O congelamento
   D-147 (11/11 00:05 servidor) cai 8h38m dentro da janela. **CMD** tem de
   reescrever as linhas 136 e 144-145 do `GATE_REAL.md`; eu nao declaro.
4. **Fechos manuais eram do DONO** (10/10). +16,85 USD. O contador `dia fechado`
   do EA nao os soma: resultado do dia = EA + manual.

## 3. As quatro portas fechadas (medidas hoje)

| Porta | Medicao | Quem abre |
|---|---|---|
| Algo trading por programa | `MQL_TRADE_ALLOWED=0` as **10:27:05.692** (USDCAD), persistente desde 10:10:05.637 | **DONO na GUI** |
| IA | `[AI] GATEWAY | HTTP 1003`, resposta nao-HTTP, corpo **0B**; ultima opiniao **62,0%** | CMD (gateway/Q-021) |
| Limiar da IA | `AIAuthorityMinScore=75,0` > 62,0 medido | DONO (se quiser baixar) |
| MTF | **42 recusados de 42** sinais hoje | DONO (se quiser medir sem) |

Conclusao honesta e escrita: com estas quatro portas, o numero esperado de
trades e' **zero**. O forward arranca hoje como o DONO mandou; o que as
primeiras horas medem e' **pre-condicao**, nao desempenho. G11 continua 0/30.

## 4. O que precisa de terceiros (nao e' clique meu)

- **DONO**: ligar Algo Trading (sem isso nada executa); decidir se mantem
  `AIAuthorityMinScore=75,0`; decidir se o MTF continua ligado no forward.
- **CMD**: (a) reancorar `GATE_REAL.md`; (b) hoje, uma execucao do
  `\XAU_AI_PRO Forward Gate` (a tarefa so' corre as 00:20 local, o dia 1 fica
  sem leitura); (c) consertar o `[AI] GATEWAY | HTTP 1003` (token/caminho).

## 5. Registos do canal

- `DECISOES.md` -> **D-167**.
- `IDS.md` -> reserva `D-167` + **P1.3576** (IA obrigatoria 15/15),
  **P1.3577** (HTTP 1003), **P1.3578** (`MQL_TRADE_ALLOWED=0` remedido, fecha
  P1.3570), **P1.3579** (aritmetica do zero), **P1.3580** (1.391 = 1.2.191),
  **P1.3581** (Forward Gate sem dia 1).
- `SYNC_LOG.md` -> 2 decisoes + 3 alertas + 2 notas, hora 10:33.
- Ficheiros: DECISOES 648 896 B / IDS 71 811 B / SYNC_LOG 72 166 B, todos
  CR=0, NUL=0.

---

*DELTA - cada numero acima foi lido do terminal ou do disco, nao inferido.*
