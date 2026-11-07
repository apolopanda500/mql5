# FICHA DO DONO - a unica folha que o dono preenche

**Criada:** 07/11/2026 21:05 | **Autor:** CMD | **Fonte da decisao:** resposta
**"ok"** do DONO no chat (07/11/2026 20:58) a proposta de 7 pontos.

**Regra desta ficha:** cada linha tem um **padrao recomendado**. O DONO respondeu
`ok` a todos os 7 padroes. Nada aqui fica "a decidir" - o que fica e **a
executar pelos agentes**. Se o DONO quiser mudar uma linha, muda a coluna
`Resposta` e o agente aplica; nao e preciso recompilar nada (sao inputs,
politica ou calendario).

**Estado:** FECHADA pelo DONO em 07/11/2026. Nenhuma pergunta dos agentes
espera resposta do DONO para o projeto andar.

---

## 1. As sete decisoes

| # | Assunto | Padrao proposto | Resposta do DONO | Onde vive |
|---|---|---|---|---|
| 1 | **Piso sem IA** (`MinMarketScoreNoAI`) | **45,0** | **OK** | input nos 15 graficos + `Core/Config.mqh:1187` |
| 2 | **USDBRL M5** (unico grafico onde a folga Q-079/B nao entra) | **manter M5, sem folga** (conservador) | **OK** | perfil/grafico; sem alteracao |
| 3 | **Gateway 9011 como tarefa/servico do Windows** | **sim** (sobrevive a reboot, modo leitura) | **OK** | `tools/gateway-task.ps1` |
| 4 | **30 dias de forward em demo** | **sim**, contagem comeca na primeira segunda-feira com mercado aberto | **OK** | `MANDATO_ATIVO.json` -> `forward` |
| 5 | **Paragem automatica (auto-stop)** | **perda diaria 60 USD** ou **DD 50%** ou **2 falhas do canal na mesma hora** | **OK** | `MANDATO_ATIVO.json` -> `paragem_automatica` |
| 6 | **Quando o DONO e chamado** | **nunca durante a execucao**; so no fim (100% real) ou em risco de ordem real | **OK** (reforcado 07/11 21:12) | `MANDATO_ATIVO.json` -> `interacao_dono` |
| 7 | **Autorizacao final da conta real** | **pre-assinada condicional**: 11/11 + 30 dias + assinatura do DELTA | **OK** | `MANDATO_ATIVO.json` -> `autorizacao_conta_real` |

## 2. O que cada resposta significa (sem jargao)

**1. Piso sem IA = 45,0.** Quando a IA nao responde (gateway em baixo, simbolo
sem modelo), o EA pode entrar se o MarketScore tecnico for >= 45,0. Com IA real,
o piso continua 65,0. 45,0 e 79,6% do teto tecnico medido (56,52) - e o valor
que o backtest D-090 usou. Mudar para 50,0 ou 40,0 e mudar um input.

**2. USDBRL em M5, sem folga.** A folga de 1 ATR (Q-079/B) so entra em graficos
cujo periodo e igual ao `TrendTF`. O USDBRL e M5; logo nunca tem folga. E o
comportamento **mais conservador** e nao exige mexer em nada.

**3. Gateway como tarefa do Windows.** Hoje o gateway morre quando o terminal
ou o Windows reinicia (morreu 2x hoje). Como tarefa, volta sozinho. Sobe sempre
em **modo leitura** - as 6 flags de execucao ficam a 0 e nao sao parametrizaveis.

**4. 30 dias de forward em demo.** Nao e "30 dias de codigo": e o EA a operar em
conta demo, medido todos os dias, com o GATE_REAL a subir criterio a criterio.
Contagem comeca na primeira segunda-feira com mercado aberto (09/11/2026).

**5. Paragem automatica.** Se num dia a perda passar 60 USD, ou o drawdown
passar 50%, ou o canal falhar 2 vezes na mesma hora, os agentes param a operacao
e registam. Nao ha decisao do DONO para parar - parar e automatico. Retomar
exige causa identificada e registo.

**6. O DONO nao e chamado durante a execucao.** Nem para "escolher entre A e B",
nem para "confirmar isto". Os agentes decidem dentro do mandato e registam.
Contacto so em dois casos: (a) **fim** - quando 11/11 + 30 dias estiverem
cumpridos; (b) **excecao maxima** - tentativa de ordem em conta real sem gate
ou tentativa de remover uma guarda de risco. Nada mais.

**7. Conta real pre-autorizada, condicional.** O DONO ja assinou a autorizacao,
mas ela **so vale** com: 11 de 11 criterios verdes **e** 30 dias de forward
**e** assinatura do DELTA **e** nenhuma paragem automatica ativa. Sem os quatro,
a chave nao vira.

## 3. O que o dono NAO precisa de fazer

- Nao precisa escrever em `INBOX_DONO.md`.
- Nao precisa responder a perguntas dos agentes.
- Nao precisa abrir o terminal, recompilar, mudar input ou reiniciar nada.
- Nao precisa de confirmar o piso 45,0 outra vez: esta respondido nesta ficha.
- Nao precisa de autorizar a conta real no dia: a assinatura e condicional.

## 4. O que fica proibido a todos os agentes

- Proibido escrever `10/10` como estado. O GATE_REAL e medido: hoje **2 de 11**. (A proibicao existe porque 10/10 nao e um estado medido.)
- Dizer que o projeto esta "100% real" antes de **11/11 + 30 dias + DELTA**.
- Tocar em parametros de risco (`RiskPercent`, `MaxDailyLoss`, `MaxDrawdown`,
  exposicao, magic) sem decisao escrita do DONO.
- Abrir ordem em conta real antes dos quatro requisitos do ponto 7.
- Chamar o DONO durante a execucao.

## 5. Assinatura

- **DONO:** resposta `ok` no chat, 07/11/2026 20:58, reforcada as 21:12 com
  "nao chamar nas execucoes, deixar tudo automatico ate chegar aos 100% de
  verdade".
- **Registo:** `D-095` em `DECISOES.md`, `IDS.md` e `MANDATO_ATIVO.json`.
- **Verificacao automatica:** `tools/dono-mandato.ps1 check`.

---

## 6. Reforco do DONO (07/11/2026 21:20)

O DONO escreveu: *"deixar tudo automatico, todas as permissoes e execucoes;
so parar quando der o resultado esperado; manter o endurecer, fazer uns trades
manuais e acompanhar os automaticos ate 30 dias ou mais; depois uso real"*.

Traducao operacional, sem alargar o que nao pode ser alargado:

- **Autonomia total dentro do mandato** - os agentes corrigem, compilam,
  reanexam, reiniciam o gateway, medem e registam sem consultar o DONO.
- **"10/10" continua proibido como estado** - e o alvo, nao uma etiqueta. O
  estado medido e sempre `x/11`.
- **Trades manuais do DONO sao permitidos** e ficam **fora** da estatistica do
  EA e do GATE_REAL. Nao substituem os 30 dias nem contam como forward.
- **Paragem** - o trabalho so para quando o resultado esperado existir:
  11/11 + 30 dias + assinatura do DELTA. Atrasos corrigiveis nao param nada.
- **Conta real** - depois dos 30 dias ou mais, e so com os quatro requisitos
  do ponto 7. "Uso real ok" e a intencao; a chave continua condicional.
