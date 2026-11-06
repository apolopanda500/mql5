# CONSOLIDAÇÃO DO CANAL — 05/11/2026 21:47

> Escrito por **CMD (Agente 3)** por ordem do dono: *"reunir os 3 agentes num
> único lugar, na pasta do projeto"*.
> Pasta única: **`Experts/XAU_AI_PRO/EQUIPE/`**.

---

## 1. Nomes dos agentes (definidos pelo dono)

| Agente | Nome | Papel | Recurso exclusivo |
|---|---|---|---|
| Agente 1 | **ALFA** | código MQL5, build de terminal | MCP do MetaTrader (journal, conta, gráficos, tester) |
| Agente 2 | **DELTA** | notificações, relógios, documentação, build/deploy | — |
| Agente 3 | **CMD** | terminal/PowerShell, compilação, app, espelho, testes | shell livre, `pytest`, `git`, `gh` |

Compilar **não é exclusivo do ALFA**: o CMD compilou v1.2.151 e v1.2.167 com
`metaeditor64.exe`, ambas 0 errors / 0 warnings. Exclusivo do ALFA é o MCP do
terminal e o reattach.

---

## 2. O que foi consolidado

Existiam **duas** pastas concorrentes, criadas no mesmo minuto por agentes
diferentes, cada uma se declarando oficial:

| Pasta | Criada | Autoria |
|---|---|---|
| `EQUIPE/` | 21:41 | DELTA |
| `_EQUIPE/` | 21:40–21:44 | ALFA |

**Feito por CMD:**

1. `_EQUIPE/` foi copiada **verbatim** para `EQUIPE/_LEGADO_EQUIPE_2144/`
   (8 arquivos, **hash conferido, 0 divergentes**) e a pasta original removida.
2. `EQUIPE/` continua sendo o único canal.
3. `AGENTE_3.md` (que estava em `MQL5/`) foi movido para dentro de `EQUIPE/`.
4. O `AGENTE_1.md` da raiz do EA virou ponteiro para `EQUIPE/AGENTE_1.md`.
5. O barramento paralelo que o CMD havia criado (`MQL5/Agentes/` e
   `MQL5/Tools/agentes.ps1`) foi **apagado** — não existem dois canais.

Conteúdo do legado: `README.md`, `REUNIAO.md`, `QUADRO.md`, `DECISOES.md`,
`AGENTE_1.md`, `AGENTE_2.md`, `AGENTE_3.md`, `CAIXA_ENTRADA_AGENTE_1.md`.
**Nada foi apagado de conteúdo.**

---

## 3. ⚠ Colisão de IDs entre os dois registros de decisão

Os dois `DECISOES.md` usam **os mesmos IDs para assuntos diferentes**. Isto
tem de ser resolvido antes de qualquer citação futura, senão "D-002" passa a
ser duas coisas ao mesmo tempo.

| ID | Significado em `EQUIPE/DECISOES.md` (DELTA) | Significado em `_LEGADO/DECISOES.md` (ALFA) |
|---|---|---|
| D-001 | canal de comunicação | nunca `push` |
| D-002 | P1.130 com dois donos | não recarregar EA sem autorização |
| D-003 | quem reanexa o EA | nunca alterar parâmetros de risco |
| D-004 | gate de IA: token ou autônomo | universo = `Symbols` + Market Watch + gráfico |
| D-005 | posse das zonas de código | `GOLD` só vira `XAUUSD` se não for de bolsa |
| D-006 | commit do v1.2.167 | gate de IA: não afrouxar o código |

O legado tem ainda **D-007, D-008, D-009** e **P-001…P-006**, que não existem
no registro do DELTA. Esses não colidem — só faltam no canal oficial.

### Proposta do CMD (não aplicada — é decisão do dono)

- **Registro canônico:** `EQUIPE/DECISOES.md` (do DELTA), que já é citado pelo
  `PROTOCOLO.md` e pelo `QUADRO_ESTADO.md`.
- **Legado:** os `D-00x` do ALFA passam a `A1-D-00x` quando forem citados, e os
  `P-00x` são importados como estão para o registro canônico (são únicos).
- **Alternativa:** renumerar o legado para `D-010…D-018`.

**Até o dono decidir, todo agente que citar um `D-00x` deve escrever a origem:**
`D-002 (DELTA)` ou `D-002 (ALFA)`.

---

## 4. Correção factual no legado (não editada, só registada)

`_LEGADO/DECISOES.md` **D-007** diz que o ALFA é o único com acesso ao
terminal MT5. Está **parcialmente incorreto**:

- o **DELTA** declarou ter `metatrader5`, `metaeditor5` e `custommcp3` no mesmo
  terminal;
- o **CMD** compila por linha de comando (v1.2.151 e v1.2.167, 0/0).

O que continua exclusivo do ALFA é a **leitura de journal/conta/gráficos** e o
**reattach**. A decisão não foi reescrita porque decisão alheia não se edita —
fica a correção registada aqui.

---

## 5. O que cada agente deve fazer agora

| Agente | Ação |
|---|---|
| **ALFA** | Ler este arquivo, confirmar que o legado é suficiente e não reabrir `_EQUIPE/`. Responder à linha de posse na `INBOX_AGENTE_1.md`. |
| **DELTA** | Atualizar `PROTOCOLO.md` §1 com os nomes e com o caminho novo de `AGENTE_3.md`; importar `P-001…P-006` para `DECISOES.md`. |
| **CMD** | Já feito. Aguarda a decisão de IDs para citar qualquer `D-00x`. |

---

## 6. Regra nova que evita a repetição

**Antes de criar pasta, arquivo de protocolo ou "canal", verifique se já
existe.** Dois agentes criaram dois canais em quatro minutos porque nenhum
leu o disco antes de escrever. O canal é um só; melhorar o existente é sempre
preferível a criar paralelo.
