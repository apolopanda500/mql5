# SESSAO CMD - 10/11/2026 (relatorio final do turno)

**CMD = Agente 3.** Equipa de 4: ALFA (1), DELTA (2), CMD (3), DONO (4).
Canal: `Experts\XAU_AI_PRO\EQUIPE\`. Repo pai `mql5` (main) e repo aninhado
`Files\XAU_AI_PRO` (develop).

---

## 1. Onde o projeto esta (medido as 17:20, hora local)

| Item | Valor |
|---|---|
| Binario em disco | **v1.2.203**, 1 023 258 B @ 16:56:41, MD5 **`10C4DF68A60CDDB0252F12C30AF4A86A`** |
| Em memoria | **15/15** a correr v1.2.203 (igual ao disco) |
| Perfil | **15/15** `.chr` com `MinAIConfidence=45.0`, **15 simbolos**, 7 controlos OK, 4 filtros `true` |
| **Frota** | **0/15** com `MQL_TRADE_ALLOWED` - falta o F7 do DONO (GUI, por grafico) |
| IA a servir | so **XAUUSD** (`available=true`, CONF 55,10%); os 14 recusados pelo **gate de qualidade** |
| Trades / posicoes | **0 / 0**; saldo e equity 12 610,68 inalterados |
| Janela de 30 dias | **nao aberta** - a declaracao esta no v1.2.202 (obsoleto) |

---

## 2. O que o CMD fez neste turno (18 commits, `f24c5c7a` -> `072173b8`)

### 2.1 Ferramentas novas (todas testadas, nenhuma escreve no canal)

| Ficheiro | Para que serve |
|---|---|
| `Tools\equipe-audit.ps1` | auditor **somente-leitura**: UTF-8 estrito byte a byte, artefactos de substituicao, **hash EA x espelho**, estado dos 2 repos |
| `Tools\forward-gate.ps1` | medicao diaria do G11: MD5 do `.ex5`, governanca, **fota**, funil, cobertura de IA, `HTTP 1003`. Sai **codigo 2** se o MD5 divergir |
| `Tools\declarar-forward.ps1` | declaracao **atomica e verificada**: le o MD5 do disco, le a governanca, le os inputs, e **recusa** se a frota nao estiver completa |
| `Tools\pulso-forward.ps1` | estado do forward de **15 em 15 min** (tarefa agendada) -> `_SYNC\pulso.jsonl` |
| `Tools\g11-metrics.py` | trades / wins / losses / **PF** / **DD max** lidos do stream de trades do proprio EA |
| `Tools\journal-ao-vivo.ps1` | leitor do journal **em directo** (o terminal tem o log em escrita exclusiva: `FileShare.ReadWrite`) |
| `Tools\verificar-cadeia.ps1` | comparacao par a par cadeia vs `.chr` vivo; marca `TRUNCADO PELO FORMATO A VIRGULA` |
| `Tools\cadeia-reattach.ps1` | extrai a cadeia do `.chr` **vivo** e aplica so a mudanca pedida |
| `Tools\piso-chr.ps1` | escreve um input nos 15 `.chr` vivos, com backup e `-Reverter` |
| `Tools\fechar-janela.ps1` | **o fecho num comando**: 4 condicoes, e so declara se as 4 passarem |
| `Tools\watcher-equipe.ps1` | deteccao de mudanca no canal/repos |

### 2.2 Correcoes de fundo (todas com medicao)

| # | Achado | Como foi medido |
|---|---|---|
| 1 | **Governanca dos modelos mal aplicada** (meu `D-155`): eu tinha posto `publicable=true` em 5 simbolos **sem verificar os folds** - o USDBRL tem edge agregado +0,0926 mas **2/5 folds positivos e media -0,0484**. Re-derivado pelos folds: **9 modelos com evidencia**, 78 recusados com motivo medido | `audit_modelos.py` sobre os 87 `meta.json` |
| 2 | **`MIN_EDGE` nao era o portao efetivo**: o portao e `MIN_EDGE_BAL` (0,03). O `0,02` que mudei so escrevia o rotulo | leitura do codigo + auditoria dos 87 modelos |
| 3 | **A cache do gateway so via o mtime do `.pkl`** - uma correccao de governanca (que vive no `.meta.json`) nao invalidava nada. Provado com teste reversivel: publicar passou a ser visto **sem reiniciar** | `prova_cache.py` |
| 4 | **O piso de confianca exclui 14/15 simbolos por CONSTRUCAO**: modelos de 3 classes dao 0,34-0,38; so o XAUUSD (binario, 30F) chega a 0,60. Medido com o `MULTI_FIAT` a responder por 4 simbolos reais | `prova_multi2.py` |
| 5 | **13 defaults compilados sao o OPOSTO do perfil vivo** (stopless=true, allowTradeWithoutAI=true, DD 50.0, risk 1.0, 4 filtros=false, MarketWatch=true). Um reattach parcial repunha o perfil de risco **em silencio** | leitura de `Core\Config.mqh` + `.chr` |
| 6 | **A cadeia de inputs e fisicamente inexecutavel**: `chart_add_expert` separa por virgulas e `Symbols`/`AvoidHoursGMT` tem virgulas no valor -> o universo colapsava de 15 para 1. E ha **uma so cadeia** (os 15 `.chr` tem inputs identicos) | `GUIA_OPERACIONAL_MT5_ASSISTANT.md:231` + verificacao par a par |
| 7 | **O desvio do servidor era +5 h, nao +3** (minha constante): medido pelo stream do EA (hora do servidor) contra o journal (hora local). Passou a ser **medido** a cada execucao | `21:48:50` (stream) vs `16:48:12` (journal) |
| 8 | **O `DECLARADO.json` via os inputs** (correccao do DELTA): o piso e o cap vivem no `.chr`, nao no `.ex5` - a janela declarada era cega a uma alteracao que decide se ha trades | `Get-ImpressaoInputs` |

### 2.3 Decisoes registadas

`D-152` (piso de edge 0.05 -> 0.02, opcao B do DONO) · `D-155` (execucao) ·
`D-157` (forward declarado + medicao) · `D-158`/`D-159` (governanca dos modelos
re-derivada) · `D-160`/`D-161` (P0 do stopless, e a correcao da sua causa) ·
`D-162` (gateway reiniciado + governanca no dossier) · `D-164` (hora do
servidor medida) · `D-169`/`D-171` (frota 0/15, sequencia da noite) ·
`D-172` (a 4a opcao medida) · `D-174` (piso 45 + MULTI_*) · `D-175` (os 13
defaults) · `D-176` (a cadeia trunca-se).

---

## 3. Como o forward esta instrumentado (para a equipa e para o DONO)

**Quatro impressoes no dossier** (`EQUIPE\FORWARD\DECLARADO.json`), todas
verificaveis a qualquer momento:

| Impressao | O que garante |
|---|---|
| `md5` | o **binario** que corre |
| `governanca_sha256` | os **modelos** que o gateway serve |
| `inputs_sha256` | o **perfil de risco e de decisao** (24 inputs) |
| `frota_ligada` | os **graficos que podem negociar** (sonda 0) |

Mais: `versao em memoria` (15/15), `offset do servidor` (medido), e o
`pulso.jsonl` de 15 em 15 minutos.

---

## 4. O que falta, e de quem (medido, nao opinions)

| # | Quem | Accao | Bloqueia |
|---|---|---|---|
| 1 | **ALFA** | gateway: ligar `MULTI_FIAT`/`METALS`/`CRYPTO` (3a via `25F-est-v1`, construtor ja existe). **Sem reattach** | a janela medir 1 simbolo em vez de 15 |
| 2 | **ALFA** | `ADX` de outro simbolo em **7 graficos** (AUDUSD, GBPUSD, USDBRL, USDCLP, USDJPY, USDRUB, USDSEK) - ja detetado e nomeado no journal | o gate de ADX desses graficos |
| 3 | **DELTA** | feeds mortos: USDRUB (9 827 s), USDCLP (9 827 s), USDCOP (7 889 s) | 3-4 simbolos sem preco |
| 4 | **DONO** | **F7 > Comum > "Permitir negociacao algoritmica" nos 15** | **a frota toda: 0/15** |
| 5 | **CMD** | `fechar-janela.ps1` -> declara | a abertura da janela |

---

## 5. O que o CMD **nao** faz (e porque)

- **Nao declara** um dossier que descreva uma frota fechada ou um binario
  que nao corre. `declarar-forward.ps1` sai com codigo 3 se a frota nao
  estiver completa; `fechar-janela.ps1` exige as 4 condicoes.
- **Nao recompila o EA**: mudaria o MD5 e zeraria a janela. Todas as
  intervencoes do CMD foram do lado do **gateway** ou do **dossier**.
- **Nao roda o `MCPServerToken`** (em claro nos `.chr` dos 14): partilharia o
  acesso MCP do terminal. Fica para depois da janela.
- **Nao mexe em risco**: `RiskPercent`, `MaxDrawdownPercent`,
  `MaxDailyLossPercent`, `StopLossPoints`, `EnableVolatilityFilter` - a
 alteracao do `MinAIConfidence` foi decidida pelo DONO (`D-174`).

---

## 6. Uma coisa que o CMD errou (registada porque o dossier tem de ser honesto)

O meu `D-155` aplicou o piso de edge **sem verificar a evidencia de cada
modelo**: publiquei 5 simbolos cujos modelos tem 2-3/5 folds positivos e media
~0 - **ruido com luz verde**. O `D-159` corrigeu, e a licao ficou escrita: o
que se publica tem de ter **folds**, nao so um `edge` agregado. A mesma
regra vale para o dossier: **o que se declara tem de ser medido, nao
suposto** - por isso as quatro impressoes.
