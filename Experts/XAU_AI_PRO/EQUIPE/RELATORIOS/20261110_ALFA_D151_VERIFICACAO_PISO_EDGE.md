# RELATÓRIO DE ETAPA — ALFA — D-151: verificação numérica do piso 0.02 — 10/11/2026 04:18 (local)

**Autor:** ALFA · **Etapa:** verificação independente do relatório D-151 do DELTA + fecho da numeração + correcção do critério de aceitação
**Estado:** etapa fechada. Sem compilação, sem deploy, sem reinício, sem input alterado, sem ordem.

---

## 1. Veredicto em três linhas

1. **Os números do DELTA estão certos.** Os 14 registos `[AI] INDISPONIVEL` das 03:46 batem valor a valor com a tabela dele.
2. **O alvo do teste de aceitação está errado por um.** Com o piso em `0.02`, o `[AI] INDISPONIVEL` por ciclo cai de **14 para 9** — não para "~10".
3. **O critério "contar linhas `[AI] PYTHON`" não é mensurável** no build de produção `71ED34C6`: dá **0 registos**, apesar de a predição ser consumida. Tem de ser substituído (P1.3525).

---

## 2. Verificação independente (journal do EA, ciclo das 03:46)

Fonte: `get_expert_journal`, filtro `INDISPONIVEL`, 14 registos, todos com a mesma forma
`[AI] INDISPONIVEL | <SYM> | MOTIVO=edge <x> abaixo do minimo +0.0500 (acc ... vs palpite ...)`.

| Símbolo | edge medido | com piso 0.02 | com piso 0.05 (hoje) |
|---|---|---|---|
| USDCAD | **+0.0317** | **entra** | fora |
| USDCHF | **+0.0253** | **entra** | fora |
| USDJPY | +0.0248 | **entra** | fora |
| USDBRL | +0.0240 | **entra** (mas cotação de 09/11 22:59 — não opera, P2.25) | fora |
| NZDUSD | +0.0225 | **entra** | fora |
| USDSGD | +0.0193 | fora por **0.0007** | fora |
| USDRUB | +0.0166 | fora | fora |
| USDCZK | −0.0072 | fora | fora |
| AUDUSD | -0.0184 | fora | fora |
| GBPUSD | -0.0207 | fora | fora |
| USDCLP | -0.0281 | fora | fora |
| USDSEK | -0.0403 | fora | fora |
| USDCOP | -0.0584 | fora | fora |
| USDCNH | **-0.1256** | **fica fora** (não pode virar `true`) | fora |
| XAUUSD | modelo publicado | entra | entra |

**Conclusão:** 5 símbolos passam o piso novo, 9 continuam bloqueados. Universo nominal 6, efectivo 5 (USDBRL partido por cotação velha).

---

## 3. Correção 1 — o alvo é 9, não "~10"

O ciclo visita **15** símbolos; **14** recebem `[AI] INDISPONIVEL` (o `XAUUSD` tem modelo e nunca entra nessa linha). Dos 14, **5** têm `edge >= 0.02`. Logo:

`14 − 5 = 9` linhas `[AI] INDISPONIVEL` por ciclo completo, se o piso for exactamente `0.02`.

Se o número medido depois da aplicação for **10**, o valor aplicado não é `0.02` (é `0.0193` ou mais baixo, e o `USDSGD` entrou); se for **14**, nada foi aplicado. Este é o teste de aceitação corrigido, e é binário.

---

## 4. Correção 2 — "contar linhas `[AI] PYTHON`" não mede nada (P1.3525)

Filtros no journal de produção, 03:46 → 04:11 (~40 min):

| filtro | registos |
|---|---|
| `[AI] PYTHON` | **0** |
| `SCORE=` | **0** |
| `PRICE=` | **0** |

E no entanto a predição **é consumida**:

```
04:01:16.193  [AI] GATEWAY RECUPERADO | XAUUSD | H1 | falhas=367 | cego=795s | resposta=1122B
04:01:16.207  [VALIDATION] TREND CONTRA OK | XAUUSD | Signal=-1 | ... ADX=15.4
04:01:16.xxx  [VALIDATION] XAUUSD | ADX=15.41 | Min=18.00
04:01:16.xxx  [VALIDATION] BLOCK | ADX | XAUUSD
```

14 ms entre a resposta do gateway e o `Signal=-1`. O build `71ED34C6` (977 654 B) **não imprime** a linha de score/preço que o build do tester imprime — a instrumentação é diferente, não a lógica. Exigir linhas `PYTHON` no forward é exigir zero para sempre.

**Substituto:** as duas observações da secção 3 (`INDISPONIVEL` 14 → 9) mais o aparecimento de `[VALIDATION] TREND CONTRA OK | <SYM> | Signal=<n>` nos 5 nomes novos.

---

## 5. Colisão de numeração — fechada, uma vez cada

| ID | Autor | Hora | Conteúdo |
|---|---|---|---|
| **D-151** | ALFA | 04:12 | G10: Market Watch 25 → 15 |
| **D-152** | DELTA | 04:15 | piso de edge 0.02 |

Itinerário (registo honesto): ALFA escreveu D-151 às 04:12; DELTA escreveu o seu bloco também como D-151 às 04:15; ALFA renumerou o seu para D-152 às 04:20 **para libertar o ID** e DELTA renumerou o dele para D-152 no mesmo minuto pela precedência do D-145 — *lost update*, dois D-152. DELTA corrigiu o cabeçalho do ALFA para D-151; ALFA confirmou por leitura às 04:17: `DECISOES.md` L7121 `## D-151 | ALFA`, L7166 `## D-152 | DELTA`, `IDS.md` L177 D-151, L179 D-152. **Zero duplicados, zero lacunas.** ALFA não renumera mais este bloco.

Regra que fecha a causa (já escrita pelo DELTA em P1.3523): **reservar em `IDS.md` primeiro, escrever em `DECISOES.md` depois.**

---

## 6. O que verifiquei no `GATE_REAL` (ficheiro do CMD — não escrevo nele)

Leitura às 04:17 (147 linhas):

- **L7** — última revisão: `DELTA, 10/11 04:20 - D-152`.
- **L135** — G10: `VERMELHO - accao do Market Watch CONCLUIDA, criterio nao fecha`, com `feito: 10 simbolos removidos as 04:06:00.926-04:06:02.869; resta a clausula do modelo - 14 dos 15 sem modelo publicado (P1.3519)`.
- **L8** — `Estado global: 3 verdes de 11` (texto de 08/11, não reflecte D-141/D-152).
- **L24** — linha do critério ainda com o texto de 08/11 (`VERMELHO com 1 lacuna`, `Symbols` = 11).

**Concordo com o DELTA: o G10 não fica verde.** O critério tem três cláusulas — (a) 1 símbolo por gráfico, (b) zero divergência `Symbols`/gráficos/Market Watch, (c) *todos com modelo publicado*. (a) e (b) estão provadas; (c) **não** (15 símbolos, 1 modelo, P1.3519). O que fechou foi a **acção** que faltava. Corrigi o meu próprio relatório do G10, que dizia "critério cumprido".

**Alerta que não é meu, mas o DONO tem de saber:** às 04:16 o DELTA registou que o `GATE_REAL` foi **reescrito por outro agente enquanto ele editava** e reverteu 2 das suas 3 edições (ficheiro de 39 145 → 41 827 B com 147 linhas nas duas leituras). Há, portanto, um **terceiro escritor** nesse ficheiro. O `GATE_REAL` é do CMD (D-139/D-143/D-147) — enquanto houver escrita concorrente, o estado do gate não é auditável por leitura.

---

## 7. Estado medido desta máquina (inalterado)

| Item | Valor |
|---|---|
| Binário | 977 654 B · mtime 10/11 02:23:07 · MD5 `71ED34C690C9593D209A69E95F0EFFB6` |
| Conta | demo 113568614 · **12 593.83** · margem 0 · **0 posições** |
| Market Watch | **15** símbolos, todos `selected=true`, idênticos a `Symbols` |
| Congelamento D-147 | não aberto (11/11 00:05 servidor → 12/11) — nada recompilado, nada deployado |

---

## 8. O que fica à espera

1. **CMD** aplicar o piso `0.02` no gateway → ALFA mede `INDISPONIVEL` **14 → 9** e os 5 `TREND CONTRA OK`. Se der 10, o valor não é `0.02`.
2. **CMD** redeclarar no `GATE_REAL`: L24 (critério G10 com 2 de 3 cláusulas) e L8 (estado global). Sem isso o gate não reflecte o dia.
3. **DONO** decidir o que só ele decide: P1.3519 (14 símbolos sem modelo ⇒ o G10 nunca fecha por medição) e o piso de 100 trades do G5 (P1.3522 mede o risco simultâneo de 2.5%).
4. **P1.3525** fica aberta até o piso ser aplicado e medido.
