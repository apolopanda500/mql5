# CICLO_FINAL - contrato de trabalho da EQUIPE ate ao 10/10

**Aberto:** 06/11/2026 23:37 (hora lida do relogio no momento da escrita)
**Autor:** ALFA
**Ordem do DONO (06/11 23:36):** "reorganizar EQUIPE, informar a todos como vai ser daqui pra frente ate concluir o projeto 10/10 100% - commitar, push, deploy, anotar, salvar, documentar, testar, simular, aprovar, validar, EA operar 30 dias para endurecer antes de uso REAL".
**Estado:** VIGENTE a partir desta hora. Substitui qualquer rotina anterior em conflito.

---

## 0. A regra que muda tudo: quem faz nao assina

O defeito estrutural do ciclo anterior foi este: o mesmo agente escrevia o codigo, media o resultado e declarava o gate fechado. Isso produziu um "quase 10/10" que ninguem podia verificar.

A partir de agora:

| Quem | Faz | Assina |
|---|---|---|
| ALFA | plano, codigo MQL5, compilacao, canal, publicacao | **nada** dos seus proprios gates |
| DELTA | mede, contesta, valida | GATE F2, GATE F6, GATE_REAL |
| CMD | pipeline Python, modelos, testes, gateway, deploy de artefactos | testes e artefactos que produz, com evidencia |
| DONO | decide dinheiro, universo e a assinatura final | a autorizacao de conta real |

Nenhum gate fecha por afirmacao. Fecha por **linha de evidencia citada**: comando, saida, hora.

---

## 1. O que significa "10/10 100%" neste projeto

"10/10" nao e uma nota. Sao **dez provas**. Enquanto uma faltar, o numero nao se escreve - nem no canal, nem ao DONO, nem no README.

| # | Prova | Como se mede | Quem assina |
|---|---|---|---|
| 1 | Compila limpo e esta publicado | 0 erros 0 avisos em `metaeditor5__compile_file`; `[START] v1.3.x` em 15/15 graficos no journal | DELTA |
| 2 | Seguranca de capital fechada (F2) | 6 falhas simuladas recusadas, com log de cada uma | DELTA |
| 3 | Fila do PLANO_10_10 fechada | F2.1..F2.10 com prova individual | DELTA |
| 4 | IA com voz em todos os ativos operados | `AI_Score != 0` e `publicable=true` por simbolo operado | CMD + DELTA |
| 5 | GATE_REAL completo | 11 verdes de 11, nao 1 de 11 | DELTA |
| 6 | Forward 30 dias em demo | >=100 trades, PF >=1.2, DD <=8%, 0 falhas de execucao nao explicadas | DELTA |
| 7 | Canal sem deriva | `sync-agent check` OK em 10 execucoes consecutivas, 0 carimbos manuais, 0 IDs em falta | DELTA |
| 8 | Repositorio = binario publicado | `main` = working tree = .ex5 provado por `[START]`; commit + push a cada fecho de fase | DELTA |
| 9 | Runbook testado | 3 incidentes simulados resolvidos por procedimento escrito, sem improviso | CMD |
| 10 | Assinatura do DONO para real | decisao explicita registada (D-nnn), nunca inferida | DONO |

**Regra dura:** 9 provas verdes e 1 vermelha = **0/10**. Nao existe "quase".

---

## 2. As fases do ciclo (C0 a C7)

Cada fase tem entrada, saida e assinador. Uma fase nao comeca antes de a anterior estar assinada.

### C0 - Reorganizacao e contrato (06/11, hoje)
- **Entrada:** ordem do DONO das 23:36.
- **Saida:** este documento, D-069 no DECISOES.md, post a DELTA e a CMD, nota no QUADRO_ESTADO, commit + push.
- **Gate:** nenhum (e contratual).
- **Assinador:** DONO reconhece a leitura.

### C1 - Fecho da seguranca de capital (segunda 09/11, mercado aberto)
- **Entrada:** Q-071 respondida (15% ou 50%).
- **Saida:** F2.2 provado por tres testes (recusa acima do teto, fail-closed com `ACCOUNT_MARGIN` ilegivel, ausencia de falso positivo abaixo do teto), F2.3 a F2.10 fechados, **GATE F2 com as 6 falhas simuladas**.
- **Gate:** GATE F2.
- **Assinador:** DELTA.
- **Nota:** F2 e BLOQUEANTE para conta real. Nao se avanca sem ele.

### C2 - IA com voz e modelos (segunda 09/11, noite)
- **Entrada:** GATE F2 assinado; Q-068 = (b) cumprido (compilar com mercado aberto e CMD presente).
- **Saida:** patch do parser aplicado (D-069 do parser: `prob_buy`/`prob_sell` -> `buy`/`sell`, `AI_Score = AI_Confidence` quando o gateway nao publica score), **1 compile**, prova por journal de `AI_Score != 0.0`. Retreino dos 83 modelos reprovados no pipeline `XAU-30F-v4`.
- **Gate:** IA nao muda nenhum preco de entrada sem `AIHasSignalAuthority=true` - e essa decisao e do DONO, nao nossa.
- **Assinador:** DELTA para o parser; CMD para os modelos.

### C3 - Forward congelado de 30 dias (arranque 10/11, demo)
- **Entrada:** C1 e C2 fechados; parametros congelados (hash dos inputs dos 15 graficos registado).
- **Saida:** diario de metricas por dia: trades, WR, PF, DD, equity, falhas por simbolo.
- **Gate:** nenhum durante a corrida. **Congelamento:** qualquer alteracao de parametro suspende o forward e reinicia a contagem - sem excepcao, sem "so esta vez".

### C4 - Checkpoint do dia 15
- **Saida:** relatorio de meio de caminho; decisao por simbolo (manter / cortar / reduzir lote), com numero.
- **Assinador:** DELTA.
- **Gate:** se DD > 8% em qualquer momento, o forward para e vira incidente.

### C5 - Fecho do forward (dia 30)
- **Saida:** relatorio final, comparacao backtest x forward, GATE F6.
- **Gate:** **GATE F6** (>=100 trades, PF >=1.2, DD <=8%).
- **Assinador:** DELTA.

### C6 - Pre-real
- **Saida:** GATE_REAL 11/11, runbook testado (3 incidentes simulados), checklist de conta real preenchida, `EnableRealAccountGuard` e kill switch provados.
- **Gate:** **GATE_REAL completo.**
- **Assinador:** DELTA mede, **DONO assina**.

### C7 - Conta real com micro-lote
- **Entrada:** assinatura do DONO.
- **Saida:** rampa documentada (risco por trade e lote maximo por etapa), revisao semanal.
- **Regra:** nenhum aumento de risco sem 2 semanas limpas na etapa anterior.

---

## 3. Papeis redefinidos

**ALFA (executor e dono do plano)**
- Escreve codigo MQL5, compila, publica, mantem o canal.
- Mede tudo o que afirma e cita a fonte (comando + saida + hora).
- **Nao assina** os seus gates. **Nao declara** "10/10". **Nao escolhe** por deducao o que e decisao do DONO.

**DELTA (verificador)**
- Mede por conta propria; se a medicao de ALFA nao reproduzir, **o numero de ALFA cai**.
- Pode recusar um gate. Recusar e trabalho, nao obstrucao.
- Assina GATE F2, F6 e GATE_REAL, e mais nada.

**CMD (dados, modelos, servicos)**
- Pipeline Python, treino, `pytest`, gateway em `127.0.0.1:9001`, deploy de artefactos.
- Nao toca no EA nem nos parametros de risco.
- Responde por: modelos publicados, testes verdes, disponibilidade do gateway.

**DONO (dinheiro e destino)**
- Decide tres coisas e so tres: **quanto pode perder** (Q-071), **que ativos operam sem modelo** (Q-072), **quando vai a real** (assinatura C6).
- Prazo de resposta: 48h. **Sem resposta = fica o conservador** e o silencio e registado como decisao.

---

## 4. Protocolo de evidencia (obrigatorio em cada afirmacao)

Toda a afirmacao tecnica no canal leva quatro elementos:

1. **o que** se mediu;
2. **com que comando** (caminho completo);
3. **que saida** (citada, nao resumida quando o numero importa);
4. **a que hora**, lida do relogio no momento da escrita.

Sem os quatro, e **opiniao** e nao entra em gate. Carimbo escrito a mao e defeito, nao detalhe.

---

## 5. Cadencia

- **Diario:** 1 post no SYNC_LOG com o que mudou; 1 `sync-agent check`; LOCK sempre respeitado.
- **Por fase:** 1 relatorio de fecho com a tabela das 10 provas atualizada.
- **Semanal (segunda):** revisao de risco com o DONO em 10 linhas, sem jargao.
- **A cada compile:** registar versao, hora, e provar publicacao por `[START]` no journal - MD5 de `.ex5` nao serve (nao e deterministico).

---

## 6. Doutrina dos modelos (decisao medida, nao palpite)

Censo de 06/11 23:18, leitura dos 87 `*.meta.json`:

- **4 publicaveis:** `XAUUSD_H1` (edge 0.0363, AUC 0.5485, 4/5 folds) + `MULTI_METALS` / `MULTI_FIAT` / `MULTI_CRYPTO`.
- **83 reprovados:** 76 por edge abaixo de +0.0500, 3 por edge instavel entre folds, 3 por balanced edge e AUC abaixo do minimo, 1 sem folds.
- **80 dos 87 sao `25F-v2`** (RandomForest) e **nao trazem AUC, folds nem edge balanceado**. Nao sao modelos avariados: sao de um pipeline que nao mede o criterio.

**Portanto:** o pedido do DONO ("corrigir todos os modelos ou deletar e treinar novos") resolve-se por **retreino no pipeline `XAU-30F-v4`**, nao por reparacao nem por apagamento. Apagar 83 de 87 deixaria a IA muda em 20 dos 21 simbolos - o oposto do que foi pedido.

**Criterio de publicacao (unico, aplicado a todos):** edge balanceado >= 0.0300 **e** AUC >= 0.5200 **e** maioria de folds positivos. `min_edge 0.05` no meta e um valor declarado que nao corresponde ao criterio real - fica registado como inconsistencia a corrigir no meta, nao como regra.

**Ordem de retreino:** primeiro os 14 simbolos com grafico; dentro desses, os melhores por edge medido (GBPUSD_M15 0.0360, USDCOP_M5 0.0364, USDSEK_M15 0.0351, USDCAD_M15 0.0350, USDCAD_H1 0.0317); depois os restantes; por fim os `MULTI_*` com AUC e folds no meta.

---

## 7. Critérios de promocao e de corte por simbolo (21 ativos)

Um simbolo opera quando: tem modelo publicavel **ou** o DONO autorizou tecnico puro (Q-072), tem grafico, tem spread dentro de `MaxSpreadPct` e tem historico suficiente. Sem estas quatro, nao opera - e o motivo fica escrito, nao subentendido.

Um simbolo sai quando, no forward: DD do simbolo > 3% do capital, ou PF < 1.0 com >= 20 trades, ou 3 falhas de execucao no mesmo dia. Corte com numero, nao com impressao.

---

## 8. O que o DONO tem de decidir (e ate quando)

| # | Pergunta | Opcoes | Prazo | Se nao houver resposta |
|---|---|---|---|---|
| Q-071 | Qual o numero unico das duas guardas | 15% = 1.895,45 USD | 50% = 6.318,16 USD | 09/11 12:00 | fica 10/15 como esta hoje, registado como silencio |
| Q-072 | Os 20 sem modelo operam? | (a) tecnico ja / (b) so com modelo / (c) tecnico com lote reduzido | 09/11 12:00 | fica (b) - so XAUUSD opera |
| D-nnn | Autorizacao de conta real | sim / nao | depois de C5 | nao ha real |

**O que o DONO nao tem de decidir:** versao, nomes de ficheiro, ordem das fases, quem assina o que. Isso e execucao e e nossa.

---

## 9. O que nunca se faz (independentemente de quem pede)

1. Escrever "10/10" com um gate vermelho.
2. Assinar o proprio trabalho.
3. Ir a conta real sem GATE_REAL 11/11 e sem forward fechado.
4. Remover ou enfraquecer uma guarda de risco sem decisao escrita do DONO.
5. Declarar publicacao sem `[START]` no journal.
6. Alterar parametros a meio do forward.
7. Escolher por deducao o que e decisao de dinheiro.
8. Esconder um erro. Erro registado e erro pago; erro escondido e divida.

---

## 10. Estado de partida medido (para nao haver ambiguidade)

- **GATE_REAL: 1 verde de 11.**
- **GATE F2:** nao assinado. F2.2 "ligada, nao provada".
- **GATE F6:** nao aplicavel ainda - 0 trades no forward.
- **Conta:** demo 113568614, equity/balanco 12.636,32 USD, 0 posicoes, 0 ordens.
- **Graficos:** 15, perfil DEFAULT (CHART01..CHART15), todos `XAU_AI_PRO` v1.2.181, `.ex5` de 21:38:01. EURUSD esta em `Symbols` mas **nao tem grafico**.
- **Universo:** 21 ativos (`[SYMS] UNIVERSO | marketwatch=21 | ativos=21`).
- **IA:** `EnableAutonomousMode=true`, `BlockZeroAIScore=true`, `AIHasSignalAuthority=false`; gateway so responde `disponivel=true` para XAUUSD.
- **Mercado fechado** (sexta a noite): os blocos de hoje sao `COTACAO VELHA`, nao defeito de codigo.
- **Zero compiles hoje** - Q-068 = (b): compilar so segunda, mercado aberto, com CMD presente.

---

## 11. Como o projeto termina

Termina quando as 10 provas da seccao 1 estiverem verdes **e** o DONO assinar. Nesse dia:

1. `main` = working tree = `.ex5` publicado, com `[START]` a provar.
2. Relatorio final de 1 pagina: as 10 provas, com o numero e a data de cada uma.
3. Forward fechado com o pacote de metricas anexado.
4. DECISOES.md com a decisao de real e o seu numero.
5. O "10/10" e escrito **uma vez**, com data, por quem assinou - nao por quem executou.

Depois disso o trabalho nao acaba, muda de natureza: **manutencao**. Retreino mensal dos modelos que reprovarem, revisao trimestral de risco com o DONO, e o runbook de incidentes vivo. O EA nao fica "pronto" - fica **sob vigilancia**.

---

## 12. Primeiro dia do ciclo (segunda 09/11) - ordem exacta

1. `sync-agent check` + leitura do LOCK. (5 min)
2. Ler Q-071 e Q-072. Se respondidas, aplicar; se nao, fica o conservador e registar. (10 min)
3. F2.2: escrever os 3 testes, correr, colar a saida. (60 min)
4. F2.3 a F2.10 pela ordem, 1 prova por item. (resto da manha)
5. GATE F2 com as 6 falhas simuladas -> pedir assinatura ao DELTA. (tarde)
6. Se GATE F2 assinado: patch do parser + 1 compile + prova de `AI_Score != 0`. (noite, com CMD)
7. Commit + push + nota no canal no fim do dia, com a tabela das 10 provas atualizada.

**Nenhum passo deste dia inclui conta real.**

---

## 13. Convergencia com o PROTOCOLO_CICLO_10_10 (proposta do DELTA, 06/11 23:37)

As 23:37 o DELTA publicou `PROTOCOLO_CICLO_10_10.md`. Os dois documentos foram escritos na mesma hora, sem se verem. Ha convergencia no essencial e **duas divergencias reais**. Nenhuma delas se resolve por decreto de um dos lados: fica escrito o que e igual, o que difere, e a regra interina para o trabalho nao parar.

**Igual nos dois (nao se discute mais):**
- "10/10" e resultado de medicao, nao rotulo. Ninguem escreve "10/10", "100%", "pronto" ou "F2 verde" antes da prova.
- Quem faz nao assina. A entrega e auditada por outra mao.
- DEMO primeiro; REAL so com forward fechado e autorizacao escrita do DONO.
- Fases com entrada, saida e assinador; nada de trabalho solto.
- Toda a afirmacao leva evidencia citada (comando, saida, hora).

**Divergencia 1 - quem escreve no canal e quem faz commit/push.**
- Este documento: ALFA mantem o canal e faz commit/push dos documentos que escreve.
- O protocolo do DELTA: ALFA escreve so codigo do EA; CMD e a unica mao de git/commit/push/deploy e escreve `QUADRO_ESTADO.md` e `PLANO_10_10.md`.
- **Regra interina ate o DONO ratificar:** o canal continua a ser escrito por quem tem o LOCK (o LOCK ja serializa, e foi assim que os dois documentos nasceram sem colisao); **commit e push dos documentos fica com ALFA ate C1**, e **a partir de C1 passa para CMD**, que junta codigo + deploy + artefactos num unico ponto de publicacao. Se o DONO preferir a versao do DELTA desde ja, CMD assume hoje e eu entrego por LOCK como qualquer outro.
- **O que a regra interina NAO permite:** dois agentes a fazer push do mesmo ramo no mesmo dia. Publicacao e sempre de uma mao por dia, e quem publica regista o hash no SYNC_LOG.

**Divergencia 2 - a fronteira do ALFA.**
- O protocolo do DELTA fecha o ALFA no codigo do EA e retira-lhe o canal.
- A minha posicao: o plano, a medicao e o canal sao o mesmo trabalho - separa-los foi o que produziu o "quase 10/10" nao verificavel. Aceito ceder a autoria do canal **desde que** a medicao continue a ser publicada por quem a fez, com o comando e a hora, e que a auditoria do DELTA seja independente.
- **Compromisso proposto:** ALFA escreve o plano, o codigo e as medicoes; DELTA audita e assina; CMD publica. O canal e o registo dessa corrente, nao propriedade de ninguem. Quem tiver objecao diz hoje.

**Estado do commit desta convergencia:** `278f7518` (06/11 23:39) levou `CICLO_FINAL.md`, `PROTOCOLO_CICLO_10_10.md`, D-069 e o canal, e foi enviado para `github/main`. Foi um commit de documentos, sem tocar em codigo nem em parametros - e por isso nao colide com a Q-068 = (b).

**O que o DONO tem de dizer (uma linha resolve):** o commit/push fica comigo ate segunda e passa ao CMD em C1, ou passa ao CMD ja?
