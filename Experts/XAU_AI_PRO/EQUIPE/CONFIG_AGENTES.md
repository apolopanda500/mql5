# CONFIGURACOES DO LADO DOS AGENTES

**Criado:** 05/11/2026 22:45 | **registo:** `DECISOES.md` `D-021` (complementa `CONFIGURACOES.md` do `D-020`).
`CONFIGURACOES.md` responde "que parametro do EA posso mexer e quem decide".
Este responde a outra pergunta: **o que e que cada agente tem para trabalhar, e como e que
um agente entrega uma configuracao a outro sem a estragar.**

Tudo abaixo foi lido agora, com `get_workspace_info`, nos tres servidores MCP. Nao e memoria.

---

## 1. Raizes reais (os tres servidores respondem igual)

| Raiz | Caminho | Serve para |
|---|---|---|
| `read_roots` | `...\D0E8209F77C8CF37AD8BF550E51FF075\MQL5`, `...\Tester`, `...\Logs`, `...\Common` | ler, procurar, listar, diff |
| `write_roots` | `...\MQL5`, `...\Common` | criar, escrever, apagar, gerar |
| `execute_roots` | `...\MQL5`, `...\Common` | correr `.ps1`/scripts dos nossos |

**Fora destas quatro pastas nada e permitido a nenhum dos 3 agentes** - nem leitura. E por isso
que instalar Python/pip/npm, mexer na allowlist de WebRequest ou limpar `%TEMP%` e nivel **C**
(so o DONO). Nao e regra de disciplina, e a ferramenta a recusar antes de executar.

Consequencia pratica: `MQL5/Files/Temp` e `MQL5/Files/Backup` sao as duas unicas zonas de
trabalho descartavel que os agentes podem usar - e as duas estao em `write_roots` **e**
`execute_roots`, logo sao tambem a zona correcta para helpers `.ps1`.

---

## 2. O que cada servidor sabe fazer (medido, nao suposto)

| Capacidade | `metaeditor5` | `metatrader5` | `custommcp3` |
|---|---|---|---|
| compilar MQL5 (`compiler_mql5=true`, build **6296**, target x64) | sim | sim | sim |
| `can_run_backtest` / `can_run_optimization` | sim | sim | sim |
| `can_read_terminal_journal` / `can_read_expert_journal` | sim | sim | sim |
| criar/editar/apagar ficheiros nas raizes | sim | sim | sim |
| **`compiler_python`** | **false** | **false** | **false** |
| Visual Studio / MSBuild detectado | sim (`...\VS\18\Enterprise`) | sim | sim |
| conta da comunidade | `APOLOPANDA500` | `APOLOPANDA500`, saldo **0.63 USD** | igual |

**Dois factos que valem decisao:**

1. **`compiler_python=false`** nos tres servidores e a **prova** (nao a hipotese) de que o
   ambiente Python do gateway nao esta instalado/detectado. Isto fecha a duvida do `Q-002`
   sobre "porque e que a IA devolve 0.00%": primeiro falta o motor, nao e so o token.
2. **`can_run_backtest=true` hoje.** F4 (ticks reais + walk-forward) **nao depende de instalar
   nada** - so de um `.ex5` compilado e de um `.set`. A fila do `MCP_E_MOTORES.md` que punha
   "Tester" como 3.o item esta desactualizada: o Tester ja existe, o que falta e o item 1.
3. `max_read_file_bytes=268435456` (256 MB) e `max_directory_tree_depth=32`: ler o canal
   inteiro ou uma arvore de fontes nunca bate no limite.

**Correccao ao `MCP_E_MOTORES.md`:** diz que o `metaeditor5` esta "instalado, desligado".
Nesta sessao ele leu, escreveu, apagou e validou sintaxe de `equipe-sync.ps1` - esta **ligado e
operacional**. O item 1 da fila (G1/F4) deixa de estar bloqueado no "ligar", e passa a estar
bloqueado so na escolha do alvo a compilar.

---

## 3. Como um agente entrega configuracao a outro (5 mecanismos, do mais barato ao mais caro)

| # | Mecanismo | Quando | Nivel |
|---|---|---|---|
| 1 | `aviso -Para X -CorpoArquivo f.txt` | texto que tem de sobreviver (com `§`, acentos, numeros) | A |
| 2 | `append -Arquivo DECISOES.md` + ID do ledger | decisao que muda o que os outros fazem | A |
| 3 | `.set` em `MQL5/Profiles/Tester` | configurar o tester igual dos dois lados: numeros congelados, reproduzivel | B |
| 4 | `chart_save_template` / `profile_add` | replicar os 13 graficos de uma vez, com EA e inputs | B (muda o que corre) |
| 5 | `get_expert_advisor_parameters` do `.ex5` | ler a config **real do binario** - nao a do fonte, nao a do `.set` | A (so leitura) |

**Regra nova que sai daqui:** sempre que se discute "o EA esta com X", a fonte de verdade e o
**binario carregado no grafico** (`get_expert_advisor_parameters` + `list_open_charts`), nunca
o `.mqh` nem o `.set`. Foi exactamente esta confusao que produziu o `D-011`
(`AllowTradeWithoutAI=false` escrito, `true` medido em 13 graficos).

**Mecanismo 3 e 4 sao nivel B porque mudam o que o EA faz em producao.** Entregar um `.set` nao
muda nada; aplicar um template muda. Por isso o `.set` pode ir por aviso, o `profile_apply` nao.

---

## 4. O que cada agente precisa de pedir (e a quem)

| Preciso de | Peco a | Mecanismo | Porque nao consigo sozinho |
|---|---|---|---|
| compilar / publicar `.ex5` / commit / push | **CMD** | aviso + LOCK | build e repo sao a zona dele |
| ler journal, conta, graficos, tester, reattach | **ALFA** ou **DELTA** | pedido `PEDIDO`/`ABERTO` | ambos tem MCP `metatrader5` |
| `Indicators/**`, `Core/**`, `Filters/**` | **ALFA** | pedido + `arquivo:linha` | zona dele (`D-008`) |
| `Monitoring/**`, `Enterprise/**`, `AIConnector` | **DELTA** | pedido | zona dele |
| Python/gateway, dados de teste, walk-forward | **CMD** | pedido | tester + `Profiles/Tester` |
| allowlist WebRequest, AutoTrading, risco, CodeBase | **DONO** | `ask` (`Q-nnn`) | fora das raizes ou e dinheiro |

**Ver em qualquer momento o que me pediram:** `tools\equipe-sync.ps1 pedidos -De <AGENTE>`.
Sem `-De` mostra o canal todo. Primeira medicao (22:44): **total=9, abertos=9**
(DELTA 3, CMD 3, DONO 3, ALFA 0) - ou seja, o ALFA pediu a todos e ninguem tinha fechado.

---

## 5. Defeito medido no protocolo do `D-020` (por corrigir, zona do ALFA)

`tools\sync-agent.ps1` linha 44:

```powershell
[ValidateSet('ABERTO', 'RESPONDIDO', 'FECHADO')]
[string]$Estado = 'ABERTO',
```

Os estados do `PEDIDO_DE_AJUDA.md` §2 sao `PEDIDO / ACEITE / FEITO / DEVOLVIDO / BLOQUEADO /
FECHADO`. Metade deles **falha na validacao do parametro** antes de escrever: `-Estado ACEITE`
nao entra. Prova: os 9 blocos criados pelo `post` estao todos com `estado: ABERTO`.

Mapa provisorio ate o ALFA alinhar (nao toquei no ficheiro dele):

| Estado do protocolo | `-Estado` a usar hoje | Marca no assunto |
|---|---|---|
| `PEDIDO` | `ABERTO` | - |
| `ACEITE` | `RESPONDIDO` | `ACEITE: ...` |
| `FEITO` | `FECHADO` | `FEITO: ...` |
| `DEVOLVIDO` | `RESPONDIDO` | `DEVOLVIDO: ...` |
| `BLOQUEADO` | `ABERTO` | `BLOQUEADO: Q-0nn` |

O `pedidos` le os dois vocabularios: conta como fechado o que estiver `FECHADO` ou `FEITO`.

---

## 6. Regra de ouro deste ficheiro

**Configuracao partilhada sem numero medido nao e partilha, e boato.** Cada linha deste
documento tem de poder ser re-medida por outro agente em menos de 1 minuto. Se um valor aqui
envelhecer (build, saldo, `compiler_python`), quem o encontrar desactualizado corrige **e
escreve a hora** - como no `QUADRO_ESTADO.md`.
