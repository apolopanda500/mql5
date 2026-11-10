# RELATÓRIO DE ETAPA — ALFA — G10 / Market Watch — 10/11/2026 04:12 (local)

**Pedido do DONO:** "G10 — 1 clique: remover os 10 símbolos extra do Market Watch (25 → 15). me ajude nao estou condeguindo"

**Resultado: feito e medido.** Market Watch está agora com **15 símbolos**, exatamente o universo do EA.

---

## 1. Como foi feito (e por que não é "automação de teclado")

Usei a ferramenta do próprio terminal/MCP **`remove_marketwatch_symbol`**, que altera apenas a lista local do Market Watch. Não houve clique automatizado, nem foco de janela, nem teclado simulado — por isso não colide com a regra que proíbe automatizar a GUI.

**Removidos (04:06:00.926 → 04:06:02.869 local = 09:06 servidor):**

| Símbolo | id | O que era na verdade |
|---|---|---|
| EURUSD | 4252 | moeda, fora do universo |
| AMD | 77045 | ação (XNAS) |
| MSFT | 69545 | ação (XNAS) |
| INTC | 69209 | ação (XNAS) |
| NVDA | 70327 | ação (XNAS) |
| GOLD | 71136 | **ação da Barrick Gold** — não é ouro |
| COP | 72813 | **ação ConocoPhillips** — não é o peso colombiano |
| USD | 78008 | **ETF ProShares Ultra Semiconductors** |
| JPY | 81222 | **ETF Lazard Japanese Equity** |
| CNH | 88916 | **ação CNH Industrial** |

**Mantido:** `XAUUSD` (id 375) — é o símbolo que o EA negoceia e o dos 4 gráficos sem EA.

> Armadilha que explica parte da confusão: `GOLD`, `COP`, `USD`, `JPY`, `CNH` **têm nome de moeda mas são ações/ETFs**. Quem remove "por suposição" apaga o símbolo errado. Removi por **nome exato**, com o id anotado para repor.

## 2. Prova (3 fontes independentes)

1. **Terminal** (`get_terminal_journal`, 03:55–04:20): 10 linhas `market watch symbol <X> removed`, todas entre `04:06:00.926` e `04:06:02.869`. Nada mais foi alterado.
2. **Estado atual** (`get_marketwatch_symbols` às 04:06:05): **15** símbolos, todos `selected: true`:
   `GBPUSD, USDCHF, USDJPY, USDCNH, AUDUSD, NZDUSD, USDCAD, USDSEK, XAUUSD, USDBRL, USDCLP, USDCOP, USDCZK, USDRUB, USDSGD`
   → **idêntico** ao input `Symbols` do EA e aos 15 gráficos com EA. **Divergência zero.**
3. **EA saudável:** nenhum recarregamento de expert no terminal (o G4 não foi tocado); o pipeline processou `XAUUSD` às `04:06:15.885` e `04:06:16.479`; conta demo 113568614 continua **12593.83**, margem 0, **0 posições**.

## 3. Estado do G10

**Critério cumprido por medição:** Market Watch (15) = `Symbols` (15) = 15 gráficos com EA.
O `GATE_REAL` é redeclarado pelo **CMD** (D-139/D-143/D-147) e eu não escrevo nesse ficheiro; o DELTA fixou a secção 7 às 04:20 como `VERMELHO - accao do Market Watch CONCLUIDA, criterio nao fecha`, que é a leitura correcta. O facto ficou registado em **D-151**.

## 4. Se precisar de repor os 10

`add_marketwatch_symbol` com os nomes exatos: `EURUSD, AMD, MSFT, INTC, NVDA, GOLD, COP, USD, JPY, CNH`.
Remover do Market Watch **não apaga histórico** — afeta apenas a subscrição/visibilidade local.

## 5. Se quiser fazer na GUI (para a próxima)

1. `Ctrl+U` abre a janela **Market Watch** (se estiver fechada).
2. Clique direito dentro dela → **Símbolos** (*Symbols*).
3. Selecionar o símbolo na coluna da esquerda → botão **Eliminar** (*Delete*)*.*
4. `OK`.

> Se o botão **Eliminar** estiver inativo, é porque o símbolo está em uso por um **gráfico aberto** — é a razão mais comum de "não estou conseguindo". Nenhum dos 10 estava em gráfico, mas `EURUSD` costuma estar no gráfico default de alguns perfis.

## 6. Guardas respeitadas

Sem compilação, sem deploy, sem alteração de inputs, sem tocar nos gráficos, sem ordem, sem parâmetro de risco. O congelamento do D-147 (11/11 00:05 servidor → 12/11) ainda não abriu e esta ação não mexe em nada do que ele congela.

**Identidade do binário (inalterada):** v1.2.191 · 977 654 B · MD5 `71ED34C690C9593D209A69E95F0EFFB6`.
