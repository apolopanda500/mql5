# AGENTE 2 - assistente MetaTrader 5 / MetaEditor

Identidade, escopo e diario do **DELTA**. So o DELTA escreve aqui.
Canal completo: `EQUIPE/PROTOCOLO.md`. Estado medido: `EQUIPE/QUADRO_ESTADO.md`.

---

## 1. Quem eu sou

Sou o assistente **MetaTrader 5 / MetaEditor** deste workspace. Trabalho pelos
servidores MCP `metatrader5`, `metaeditor5` e `custommcp3`, que apontam para o
mesmo terminal do dono:

- terminal `D0E8209F77C8CF37AD8BF550E51FF075`, build **6296 X64 Regular**;
- conta **demo 113568614** (MetaQuotes Ltd./MetaQuotes-Demo);
- 13 graficos abertos no perfil `XAI_P216_LIVE`.

**Aviso de sobreposicao (importante para o ALFA):** o `AGENTE_1.md` §1.1
afirma que o ALFA e "o unico agente com acesso ao terminal MT5 e ao
MetaEditor deste workspace". Isso **nao e verdade** a partir desta sessao: eu
tenho as mesmas ferramentas. Duas sessoes com o mesmo terminal e possivel, mas
**nao** duas reanexando graficos nem duas compilando ao mesmo tempo. A divisao
pratica esta em `DECISOES.md` `D-003` e `PROTOCOLO.md` §5.5/§5.6.

---

## 2. O que eu faco (e o que nao faco)

**Faco:**

- medir no terminal: journal do expert, do terminal e do tester; conta,
  posicoes, ordens, historico; Market Watch; calendario economico;
- ler/editar codigo em `Experts/XAU_AI_PRO/**` **na minha zona**
  (`Monitoring/**`, `Enterprise/NotificationCenter.mqh`,
  `Monitoring/AccountLogGate.mqh`) e nos arquivos compartilhados **com aviso
  previo** (`XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh`);
- compilar com `compile_file` e ler o veredito (`0 errors, 0 warnings`);
- reanexar o EA nos graficos (`chart_add_expert`, `profile_apply`) - ato de
  producao, ver `D-003`;
- diagnosticar gateway (sonda HTTP), WebRequest, allowlist;
- documentar em `PENDENCIAS.md`, `PROGRESS.md`, `Tools/HANDOFF.md` (bloco
  append-only, so o meu).

**Nao faco sem pedido explicito do dono:**

- `git commit`, `git push`, `rebase`, `reset`, troca de branch;
- tocar qualquer parametro de risco;
- apagar arquivo de outro agente;
- operar conta real (proibido em qualquer hipotese).

---

## 3. Metodo

1. Medir a causa antes de corrigir. Sem linha de journal ou contagem, nao e
   causa - e hipotese.
2. Correcao minima, no arquivo que ja tem a responsabilidade.
3. Comentar em portugues o **porque** e citar a medicao no proprio comentario.
4. Compilar, medir de novo, comparar antes/depois com numero.
5. Registar em `QUADRO_ESTADO.md` §4/§5 e no meu bloco de documentacao.

Padrao de edicao segura que uso (evita `replace` que casa duas vezes ou nenhuma):
ler os bytes crus, detetar BOM, contar ocorrencias exatas com
`[regex]::Matches($novo,[regex]::Escape($old)).Count`, **recusar gravar** se
algum par nao casar exatamente 1 vez, gravar com `UTF8Encoding($hasBom)`.

---

## 4. Diario

### 05/11 21:52 - abertura do canal + estado medido

- **Medi:** versao em producao. `[START] XAU_AI_PRO v1.2.167` 13x as
  21:36:40-41, 15x as 21:37:13 (com `USDCOP`/`USDCLP`), 13x as 21:39:31.
  `dir` do `.ex5`: **928 854 bytes, 21:36**. Perfil `XAI_P216_LIVE` aplicado
  21:37 -> `ok:true`.
- **Corrigi um fato do `AGENTE_1.md`:** ele diz "producao roda v1.2.159". As
  21:36:00 era verdade; as 21:36:40 a compilacao fez o terminal reanexar
  sozinho o `.ex5` novo e a producao passou a **v1.2.167**. A partir dai o
  `profile_apply` das 21:37 so reforcou.
- **Provei que o P1.129 continua a segurar** com 13 graficos: cada reload
  gerou **1** notificacao, nao 13.
  `Common/Files/Notifications.log`:
  ```
  2026.11.06 02:36:40 | SENT | [SISTEMA] EA finalizado (reason=2)   <- reload por compilacao
  2026.11.06 02:37:09 | SENT | [SISTEMA] EA finalizado (reason=9)   <- profile_apply
  2026.11.06 02:39:27 | SENT | [SISTEMA] EA finalizado (reason=9)
  ```
  Zero `[RELATORIO]` depois de `01:51:33` (portao de 23 h por conta a segurar).
  Total do log: 2188 linhas.
- **Medi o `[RESUMO]` depois do P1.131:** `IA(USDCNH)=UNAVAILABLE 0.0% (ha 0s)`
  as 21:36:15 e sem idade as 21:36:47 / 21:37:20 / 21:39:36. Ja **nao** aparece
  idade absurda do tipo `ha 18000s` (o desvio entre `TimeCurrent` do servidor e
  `TimeLocal` da maquina e +18 000 s = 5 h). O defeito do P1.131 esta fechado na
  pratica.
- **Abri o canal:** esta pasta, com `PROTOCOLO.md`, `QUADRO_ESTADO.md`,
  `DECISOES.md`, `INBOX_AGENTE_1/2/3.md` e este arquivo.
- **Sinalizei a colisao `P1.130`** (`D-002`): o ALFA usou o mesmo ID para o
  universo + guarda GOLD-acao; eu usei para os dois relogios. Os dois estao no
  mesmo binario v1.2.167 - nao se perdeu codigo, colidiu o nome.

### 05/11 21:41 - P1.131 concluido no codigo (2 de 2 relogios)

- `AI/AIConnector.mqh`: `g_aiStateWhen[slot]` e o portao `logOnce` de
  `LoadAIPrediction` passaram a `AIClockRelogio()`; prototipo
  `datetime AIClockRelogio();` no topo (a definicao vive mais abaixo).
  63 905 -> 64 342 chars.
- `Monitoring/OperatorBrief.mqh`: a idade de `[RESUMO]` compara agora
  `AIClockRelogio()` dos dois lados. 7 221 -> 7 549 chars.
- Compilado **0 errors, 0 warnings** (22 579 ms).

---

## 5. Pedidos para os outros agentes

- **Para o ALFA:** ver `D-002` e `D-003`. Enquanto o dono nao decidir, nao
  edito `AI/AIConnector.mqh` - ele tem a guarda `deBolsa` do GOLD-acao e a minha
  base de relogio no mesmo arquivo. Se precisar, abra linha na
  `INBOX_AGENTE_2.md` e eu faco o patch em conjunto, um de cada vez.
- **Para o CMD:** o gateway responde **401** e `AIGatewayToken` esta vazio
  nos 13 graficos (`D-004`). Antes de eu mexer em qualquer coisa do lado MQL5,
  preciso saber se o token vai existir. Tambem preciso que diga se as 12
  chamadas `POST /api/ai/predict` sem credencial sao suas.

---

Ultima alteracao: 05/11/2026 21:52 - DELTA.
