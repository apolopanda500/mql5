# RELATORIO DE ABERTURA DA JANELA FORWARD - 10/11/2026

Autor: CMD. Fecho da sequencia de 5 passos + resposta a auditoria DELTA (17:28).
Todas as linhas abaixo sao MEDICAO desta janela; onde ha inferencia esta marcado.

---

## 1. Identidade e janela

| Campo | Valor |
|---|---|
| Binario | `XAU_AI_PRO.ex5` 1 023 258 B · mtime 10/11 16:56:41 · **MD5 `10C4DF68A60CDDB0252F12C30AF4A86A`** |
| Versao | `v1.2.203` (`#property version "1.403"`) |
| Governanca | `CB7D8FD8D5CECAF51BC650FF491B2F6FA1DBCA57621ED140E9EE0C3E661187F7` · 87 `meta.json` |
| Inputs (39 campos) | `4B71E6E1F67F57DD6C8141497251181A9C4046595BD15895168D3C4EB0C46F28` |
| Frota | 15/15 LIGADO · sensor_sem_leitura 0 · **cotacao_morta 3** (USDCLP, USDCOP, USDRUB) |
| Memoria | 15/15 em `v1.2.203` |
| Janela | inicio **10/11/2026 22:31 servidor** (17:31 local, desvio +5 h MEDIDO) · 30 dias → **10/12/2026 22:31** |
| Conta | 113568614 · MetaQuotes-Demo · hedging · equity 12 610,68 USD · 0 posicoes · 0 ordens |

A pre-declaracao das 16:40 esta SUBSTITUIDA por esta.

---

## 2. Os cinco passos

1. **Defaults compilados alinhados** - 15 alvos (13 de `Core/Config.mqh` + `Symbols` 11->15 + `LearningPenaltyEnabled` em `AI/LearningHistory.mqh`). Compilacao 0 erros/0 avisos. Verificado no BINARIO (`get_expert_advisor_parameters`), nao na fonte: 323 inputs, 1 grupo.
2. **Reattach 15/15** com a cadeia de 323 pares e `MinAIConfidence=45.0`. `[STOP] motivo=7` + `[START] v1.2.203` nas 15 (17:10:11->17:10:56); `.chr` gravados 17:11:40-41.
3. **F7 > Comum > Permitir negociacao algoritmica** nos 15 (DONO).
4. **Perm-sweep**: 15/15 `mql=1 term=1 conta=1 expert=1 ligado=1 code=0`, idade < 60 s.
5. **Re-declaracao** com as quatro impressoes. `pulso.jsonl`: `md5_ok=true`, `gov_ok=true`, `frota_on=15`.

---

## 3. Resposta a auditoria DELTA

### R1 - `frota_sem_tick: 0` era enganador - ACEITE E CORRIGIDO
O campo contava SENSOR sem escrita, nao cotacao morta. Passa a haver dois campos com o nome do que medem:
`frota_sensor_sem_leitura: 0` e `frota_cotacao_morta: 3` com a lista, lida do `[DIAGSCAN]` do proprio EA
(`USDCLP ... 9797s`, `USDCOP ... 7860s`, `USDRUB ... 18805`, varredura de 17:10:50).

### R2 - `MCPServerToken` vazio com `EnableMCPServer=true` - REFUTADO por medicao
Nao ha listener exposto. O EA recusa arrancar sem token:
`16:56:42.202 XAU_AI_PRO (USDCLP,H1) [MCP] desligado | token com 0 caracteres, minimo 8`
`16:56:42.202 XAU_AI_PRO (USDCLP,H1) [MCP] nao arrancou | token com 0 caracteres, minimo 8 (input MCPServerToken)`
O caminho e fail-closed (`MCPServer.mqh:647`, `XAU_AI_PRO.mq5:607/624`). **Risco inexistente** na configuracao actual.
Fica uma nota de observabilidade: so 1 das 15 instancias imprimiu a recusa; as outras 14 nao dizem nada.

### R3 - KCI recarregou 8 vezes, nao 1 - ACEITE
Churn de handles entre 17:13:43 e 17:14:28, estabilizado as 17:14:28, sem `expert removed/loaded`. O load esta provado
pelo journal; a confirmacao visual continua em aberto. Parente provavel do `[TREND] LEITURA SUSPEITA ... handle RECRIADO`.

### R4 - material obsoleto em `EQUIPE/FORWARD/` - ACEITE NA CONSTESTACAO, REJEITADA A SOLUCAO
Os tres ficheiros NAO sao sobras: `forward-gate.ps1` LE E ESCREVE `medicao.jsonl`, `FORWARD.md` e `ultima_medicao.log`
(linhas 21-22 e 45-46 do proprio script). Arquivar partiria a serie. O problema real e outro, e e novo - ver P1.3605.
Resolvido por actualizacao (gate corrido as 17:32:57), nao por arquivo.

### Reconciliacao de numeros - ACEITE
As duas reguas medem coisas diferentes e ambas ficam registadas:
- regua larga (a minha): 12 diferencas totais entre fonte e vivo, **todas nao-risco** (7 enum-como-numero, 3 escapes `Data\`, 2 listeners deliberadamente `false`);
- regua fina (DELTA): normaliza enum e escapes e chega a **3 desvios de valor** - `EnableExternalBridge` false->true, `EnableMCPServer` false->true, `MinAIConfidence` 60->45.
Nenhuma das duas e "12 desvios de risco". O "12" nao deve ser lido como risco.

---

## 4. Defeitos registados nesta janela

### P1.3603 - os defaults compilados eram o oposto do perfil vivo (fechado)
13 inputs de decisao tinham default compilado invertido: `EnableStoplessEntry` false/true, `AllowTradeWithoutAI` false/true,
`MaxDrawdownPercent` 6.0/50.0, `RiskPercent` 0.5/1.0, 4 filtros true/false, `SymbolsFromMarketWatch` false/true.
Um reattach parcial repunha o perfil de risco inteiro em silencio. Corrigido por alinhamento + recompilacao (0 erros).

### P1.3604 - a impressao digital dos inputs tinha um ponto cego de 25 % do dia (fechado)
`AvoidHoursGMT` fecha 6 horas (9,11,14,18,20,22) e NAO estava na lista de campos declarados: zera-la mudava o universo
medido sem mexer no `inputs_sha256`. O mesmo para o freio de meta diaria e para os tectos de exposicao/posicoes.
Passa de 24 para 39 campos.

**Agrava-se com um defeito de implementacao, achado no ensaio:** o regex dos campos nao estava ancorado ao inicio da
linha, portanto `AvoidHoursGMT` casava dentro de `EnableAvoidHoursGMT=true` e o dossie declarava `AvoidHoursGMT=true`
em vez de `9,11,14,18,20,22`. Uma impressao digital a certificar o CONTRARIO do que corre e pior do que uma ausente.
Corrigido com `(?m)^`. Valor final medido: `9,11,14,18,20,22`.

### P1.3605 - a serie de 30 dias duplica: uma linha por EXECUCAO, nao por dia (ABERTO)
`forward-gate.ps1` declara no cabecalho "uma linha por dia do servidor", mas acrescenta uma linha por execucao.
Medido: `medicao.jsonl` com **13 linhas, todas de `2026-11-10`**, e `FORWARD.md` com **13 linhas na mesma data**.
Ha ainda deriva de esquema (os campos `governanca_*` so aparecem a partir das 10:09) e duas entradas as 16:14:09/16:15:19
com o mesmo MD5. Consequencia: a tabela de 30 dias tera N linhas por dia em vez de 30, e qualquer leitura de
"dias conformes" usa o denominador errado.
Ultima linha (17:32:57) esta correcta: `md5_divergente=false`, `v1.2.203`, `frota 15`, `memoria v1.2.203`.
**Nao foi reescrito o historico**: deduplicar exige ordem do DONO.

---

## 5. Riscos abertos

1. **Mestre do pipeline = USDRUB** - simbolo com 18 800 s sem tick. O `[RESUMO]` sai pelo timer (nao bloqueia), mas o agregador esta sobre um simbolo parado.
2. **3 feeds mortos**: USDCLP, USDCOP, USDRUB. Bloqueiam-se a si mesmos com `COTACAO VELHA` (fail-safe correcto) - sao 3/15 sem amostra. `tick_value=0/tick_size=0` em USDCLP e USDRUB (P1.3514).
3. **Series cruzadas persistentes**: `[TREND] LEITURA SUSPEITA | USDBRL`; `[ADX] VALOR DE OUTRO SIMBOLO | XAUUSD | grafico=USDBRL`.
4. **Margem de confianca estreita**: XAUUSD entre 51,3 % e 55,1 % nas leituras do dia, contra piso 45. Passa, mas com 4-10 pp de folga. Uma deriva do modelo fecha-o sem aviso.
5. **`expertmode=0` no `.chr` dos 15** (linha 67) - facto confirmado. O `.chr` foi gravado 17:11:41, ANTES do F7, por isso a explicacao mais simples e cronologica, nao um defeito. O P1.62 ja mediu que `expertmode` de `.tpl`/`.chr` nao e esta permissao. Teste proposto: grafico-extra descartavel, nunca a frota.
6. **`EnableExternalBridge` / `EnableMCPServer` a default `false`** por decisao deliberada: um reattach que omita estes inputs fecha o listener em vez de o abrir sem token.

---

## 6. Pendente de decisao do DONO

- **Ancora dos 30 dias**: a frota esta ligada e NAO ha bloqueio diario activo. O guard de meta (`ExecutionEngine.mqh`) bloqueia
  so quando `lucroHoje >= meta`; com -61,80 USD < 40,00 a condicao e falsa, e o orcamento de perda e `MIN(600, saldo*3 %) = 378,32`,
  do qual se consumiram 16,3 %. Recomendacao: **contar de hoje**, como declarado.
- **P1.3605**: autorizar deduplicacao por `server_date` (manter a ultima) ou manter a serie como esta.
- **`AvoidHoursGMT`**: 6 h bloqueadas por dia. Confirmar que e o pretendido para a janela.

---

## 7. Fronteira desta actuacao

Escritas desta sessao: `Tools/declarar-forward.ps1` (digest 24->39 campos, ancoragem do regex, campos de frota),
`EQUIPE/FORWARD/DECLARADO.json` (pelo script), `EQUIPE/FORWARD/{medicao.jsonl,FORWARD.md,ultima_medicao.log}`
(acrescento do gate) e este relatorio. Scripts de apoio em `MQL5\Files\Temp`.
**Nao recompilei, nao toquei no `.ex5`, nao escrevi `.chr` nem `.tpl`, nao coloquei nem alterei ordens.**
