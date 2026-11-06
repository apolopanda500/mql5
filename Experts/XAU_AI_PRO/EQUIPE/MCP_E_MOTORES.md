# MCP E MOTORES - o que a equipa pode e o que so o DONO pode

**Criado:** 05/11/2026 22:40 | **registo:** `DECISOES.md` `D-019`.
**Pedido do dono:** "podem baixar e instalar novas MCP para uso geral e mais completos, motores melhores".

---

## 1. A parte que eu nao posso fazer (e porque)

A autorizacao do dono **nao alarga as raizes do shell**. Um agente so toca em `MQL5`, `Common`, `Tester` e `Logs`.

Qualquer instalacao escreve **fora** dessas raizes:

| Instalacao | Escreve em | Resultado |
|---|---|---|
| `pip install` | `...\Python3xx\Lib\site-packages` | recusado (fora da raiz) |
| `npm install -g` | `%APPDATA%\npm` ou `Program Files` | recusado |
| `.exe`/`.msi` | `Program Files`, registo, servicos | recusado |
| config de MCP | `C:\Users\Micro\.config\opencode\opencode.json` | fora da raiz - nao leio, nao escrevo |

Nao e falta de autorizacao sua: e a ferramenta que recusa antes de correr. **Instalar e acto do DONO.**
O que a equipa faz: **escolhe, justifica, prepara o snippet e valida depois** de instalado.

---

## 2. Estado medido do parque de ferramentas (05/11 22:40)

O catalogo desta sessao respondeu assim:

- **Disponiveis para habilitar:** `developer` (ja activa).
- **Disponiveis para desabilitar:** `developer`, `todo`, `extensionmanager`, `summon`, `tom`, `skills`, `metatrader5`, `metaeditor5`, `marketdata`, `custommcp2`, `custommcp3`.

**Conclusao:** nao existe **nenhum servidor novo** por instalar no catalogo. O que existe ja esta instalado. E nesta sessao o gestor de extensoes expoe **so descoberta** - nao ha ferramenta de habilitar/desabilitar, logo nem o `metaeditor5` eu consigo ligar sozinho.

---

## 3. Fila de motores - avaliacao honesta

| Motor | O que resolve | Estado | Quem instala |
|---|---|---|---|
| **metaeditor5** (MCP) | `compile_file` / `compile_project` -> **0 errors** medidos | **instalado, desligado** | DONO liga na interface |
| **Python 3 + pandas/numpy** | gateway de IA e `dataset.csv`; hoje `compiler_python=false` | **ausente** | DONO |
| **git** | commit/push | **presente** (`git.exe` no PATH) | - |
| **metatrader5** (MCP) | conta, journal, graficos, tester, reattach | **activo** | - |
| **marketdata** (MCP) | series publicas para comparar com o broker | **activo** | - |
| **Tester com ticks reais** | F4 sem instalar nada (usa a raiz `Tester`) | **disponivel** | - |
| MCP de filesystem amplo | "ver o disco todo" | **recusado por desenho** - alargaria as raizes e quebraria a seguranca do projeto | - |
| Qualquer MCP que peca token em ficheiro | - | **recusado** - segredo nao vai para ficheiro versionado | - |

### Ordem que destrava o 10/10 (nao e ordem de gosto, e de dependencia)

1. **`metaeditor5` ligado** -> sem compilar nao ha G1 (integralidade) nem F4 (prova). E o unico bloqueio de ferramenta.
2. **Python do gateway** -> sem ele a IA nao responde e `Q-002` (0.00%/0.00%) nao fecha. O EA fica sem lado para escolher.
3. **Tester** -> ja existe, nao precisa de instalar nada. E o que falta e correr F4, nao comprar ferramenta.

**Nenhum motor novo resolve os defeitos de hoje.** O ATR morto (`Q-001`) e o `dataset.csv` (`Q-003`) sao codigo deste repositorio, nao falta de ferramenta. Trocar de motor para "resolver" isso so acrescenta variavel.

---

## 4. Checklist para o DONO (5 minutos, uma vez)

1. Ligar **`metaeditor5`** na lista de extensoes da interface.
2. Instalar **Python 3** (marcar "Add to PATH") e correr: `pip install pandas numpy requests`.
3. Dizer numa linha no `INBOX_DONO.md`: "metaeditor5 ligado, python 3.x instalado" - o agente valida com `get_workspace_info` (`compiler_python` deve passar a `true`/caminho preenchido) e regista no `QUADRO_ESTADO.md`.
4. Se quiser um MCP novo fora do catalogo: eu pesquiso, comparo versao e mantença, e entrego o snippet **pronto a colar**; o dono cola no ficheiro de config. Nao invento schema de config: leio a doc oficial primeiro.

---

## 5. Limpeza de ficheiros (o outro pedido)

**Dentro** das raizes, a equipa pode e deve limpar o que e regeneravel:

- `MQL5/Files/Temp/**` - rascunhos, scripts de sonda, `.tmp`
- `MQL5/Files/Backup/**` com mais de N dias
- `MQL5/Logs/*.log` com mais de N dias (o log do dia esta aberto pelo terminal - nao se toca)
- ficheiros temporarios do canal (`*.tmp-sync`, `*.bak` antigos em `EQUIPE/_SYNC/backup`)

**Nunca sem ordem escrita:** `Data/*.csv`, `.ex5`, `.dll`, `.set`, `Profiles/**`, qualquer coisa fora de `MQL5`.

**Fora das raizes (Windows, Downloads, `%TEMP%`, caches de outros programas): so o DONO.** Nenhum agente executa, mesmo autorizado em conversa.
