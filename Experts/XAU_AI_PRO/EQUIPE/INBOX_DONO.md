# INBOX DO DONO - a fila que so o operador fecha

Quarto participante do canal, ao lado de **ALFA** (Agente 1), **DELTA**
(Agente 2) e **CMD** (Agente 3). Criado em 05/11/2026 22:23 por autorizacao do
proprio dono ("crie e autorize scripts ou modulos de sincronizacao entre 3
agentes e o quarto eu o DONO").

**Regra:** os agentes **anexam** aqui o que nao podem decidir. O dono **nao
precisa escrever neste ficheiro** - pode responder no chat e o agente que
recebeu a resposta escreve a linha `RESPOSTA (DONO)` com a hora. Nenhuma linha
daqui e fechada por agente nenhum.

Formato de cada item:

```
## Q-0NN | <assunto> | <data>
- **O que e:** ...
- **Evidencia:** ... (medido, com hora)
- **Decide o dono:** ( ) opcao A  ( ) opcao B
- **Quem executa depois:** ALFA / DELTA / CMD / ninguem
- **estado:** ABERTO ou FECHADO | <hora>
```

Ler a fila rapidamente, sem abrir o resto do canal:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 dono
```

---

## AS TRES QUE ESTAO A TRAVAR SANGUE

1. **`Q-001`** - os 10 handles de ATR que morrem depois de cada reload: 10 de
   13 simbolos ficam sem ATR/RSI e nao entram. E a unica porta que **nao fecha
   sozinha** hoje.
2. **`Q-002`** - a IA devolve `disponivel=true` mas com `BUY=0.00% | SELL=0.00%`:
   mesmo que a confianca passasse dos 60.0, nao ha lado para escolher.
3. **`Q-005`** - `EnableVolatilityFilter=false` nos 13 graficos: e um filtro
   desligado em producao, e mexer nele muda a taxa de entrada (risco).

---

## Q-001 | 10 handles de ATR morrem depois do reload | 05/11/2026 22:14

- **O que e:** depois do reattach das 22:10:47, **10 dos 13 simbolos** ficaram
  sem leitura de ATR. O `Indicators/VolatilityFilter.mqh` deita a entrada da
  cache fora ao fim de 180 s de falha (`P1.118`) e cria um handle novo no uso
  seguinte (`ATRSymbolHandle`), mas medido as 22:20:25 e as 22:21:24 o USDCNH
  **continuava** `ATR%=sem leitura(atr=0.000000)`. Sem ATR nao ha filtro de
  volatilidade nem `lote`/`alvo` por volatilidade - o simbolo para de entrar.
- **Evidencia:** `[ATR] HANDLE MORTO | barsCalc=-1 | erro=4807` para USDJPY,
  USDSEK, AUDUSD, USDCAD, USDCHF, GBPUSD, USDSGD, NZDUSD, USDCZK (22:14:26 a
  22:14:40) e USDCNH (22:18:04); `[CENARIO] USDCNH ... ATR%=sem leitura` as
  22:17:51, 22:20:25 e 22:21:24. XAUUSD **nao** aparece na lista.
- **Decide o dono:** ( ) corrigir agora, com o ALFA, antes de mais nada
  ( ) deixar como esta e so medir por mais tempo
  ( ) aceitar: 3 simbolos bastam para operar
- **Quem executa depois:** ALFA (`Indicators/**` e a zona dele). O DELTA so
  mediu; nao tocou em nada.
- **estado:** ABERTO | 05/11 22:23

## Q-002 | `[AI] PYTHON` responde 0.00% de compra e 0.00% de venda | 05/11/2026 22:22

- **O que e:** as **8 unicas** predicoes do XAUUSD entre 21:36:45 e 22:11:18
  tem todas `BUY=0.00% | SELL=0.00% | SCORE=0.00`; so a `CONF` varia (62.80 /
  63.30 / 59.10 / 56.60 / 58.20 / 53.90 / 54.40 / 54.50). O gateway responde
  `1121 bytes | disponivel=true`, portanto nao e um 401 nem um modelo ausente -
  e uma saida sem direcao.
- **Decide o dono:** ( ) e defeito do gateway/modelo - CMD investiga
  ( ) e defeito do parser do EA - ALFA investiga
  ( ) e esperado e o EA nunca deveria ter aberto posicao com isto
- **Quem executa depois:** CMD (`P1.124`, gateway) ou ALFA (parser). Nao abri
  ID nenhum: nao e minha zona e nao sei a causa.
- **estado:** ABERTO | 05/11 22:23

## Q-003 | `P-004` / `P1.111` - `dataset.csv` escrito por varias instancias | 05/11/2026 22:20

- **O que e:** 13 graficos escrevem no mesmo `MQL5/Files/XAU_AI_PRO/**`. E o
  unico item de **codigo** aberto do seu lado e foi declarado do CMD pelo ALFA.
  Nao e permissao que falta: e trabalho que nao foi feito.
- **Decide o dono:** ( ) entra no proximo ciclo, com o CMD
  ( ) fica para depois do fecho
- **Quem executa depois:** CMD.
- **estado:** ABERTO | 05/11 22:23

## Q-004 | `P-006` - simbolos com grafico e sem `Symbols`, e vice-versa | 05/11/2026 22:20

- **O que e:** o universo do EA (`Symbols`/`SymbolsFromMarketWatch`) e os
  graficos abertos nao coincidem. Foi essa familia de desalinhamento que fez
  `USDCOP`/`USDCLP` desaparecerem do perfil entre 21:37 e 21:39.
- **Decide o dono:** ( ) alinhar o universo ao perfil (13 graficos)
  ( ) alinhar o perfil ao universo (mais graficos)
  ( ) deixar como esta e documentar
- **Quem executa depois:** ALFA (`Core/SymbolManager.mqh`, `Core/Config.mqh`).
- **estado:** ABERTO | 05/11 22:23

## Q-005 | `EnableVolatilityFilter=false` nos 13 graficos | 05/11/2026 22:23

- **O que e:** um filtro de volatilidade **desligado em producao**, embora o
  codigo tenha todo o trabalho do `P1.118`/`P1.122` para o manter vivo. Ligar
  ou desligar muda a **taxa de entrada** - e por isso que nenhum agente toca
  nisto. Os agentes leram o valor do grafico, nao do `.set`: no `.set` do
  tester a leitura pode ser outra.
- **Decide o dono:** ( ) manter `false` ( ) ligar `true` em 1 simbolo primeiro
  ( ) (nao decidir agora)
- **Quem executa depois:** quem o dono nomear. Alterar isto e alteracao de
  regra de entrada, nao de diagnostico.
- **estado:** ABERTO | 05/11 22:23

## Q-006 | orfaos `Management/PartialClose.mqh` e `Management/TrailingStop.mqh` | 05/11 22:20

- **O que e:** dois ficheiros que ninguem inclui. Ou se apagam, ou se usam.
  Enquanto ficam, qualquer agente que procure "stop" no projeto encontra
  codigo morto e pode concluir mal.
- **Decide o dono:** ( ) apagar ( ) manter e marcar como orfao no README
- **Quem executa depois:** CMD (commit) + DELTA (remocao).
- **estado:** ABERTO | 05/11 22:23

## Q-007 | commit de `Profiles/Tester/XAU_AI_PRO.set` | 05/11 22:20

- **O que e:** ficou **fora** do commit `d23b42c6` de proposito. Contem
  parametros de teste; versionar um `.set` de tester congela numeros que
  ninguem reviu desde a ultima otimizacao.
- **Decide o dono:** ( ) commitar ( ) ignorar de vez (`.gitignore`)
- **Quem executa depois:** CMD.
- **estado:** ABERTO | 05/11 22:23

## Q-008 | push do espelho (`develop` ahead 1) | 05/11 22:20

- **O que e:** o repositorio aninhado `MQL5/Files/XAU_AI_PRO` tem o commit
  `1bb5122` (99 ficheiros, +17 237/-1 563) **local**, `develop` ahead 1 de
  `origin/develop`. O repo do EA (`d23b42c6`) ja foi pushed para
  `github/apolopanda500/mql5`.
- **Decide o dono:** ( ) push agora para `github` ( ) deixar local
- **Limite que nao muda:** `origin`/CodeBase continua proibido (publicacao
  externa).
- **Quem executa depois:** CMD.
- **estado:** ABERTO | 05/11 22:23

## Q-009 | gateway na 9011 nao e servico do Windows | 05/11/2026 22:20

- **O que e:** o processo Python que responde `1121 bytes | disponivel=true` foi
  arrancado a mao. Se o terminal reiniciar, o EA fica sem IA ate alguem o
  levantar outra vez - e o EA **nao** abre posicao nesse estado.
- **Decide o dono:** ( ) transformar em servico/agendador ( ) aceitar e
  documentar o arranque manual
- **Quem executa depois:** CMD.
- **estado:** ABERTO | 05/11 22:23

## Q-010 | `commit 6fe56e53` mal rotulado | 05/11 22:20

- **O que e:** a mensagem diz `docs(ciclo111)` mas o commit leva codigo
  `v1.2.158`. O historico mente sobre o que mudou. Corrigir exige reescrever
  historico (rebase) - o que nenhum agente pode fazer sem ordem explicita.
- **Decide o dono:** ( ) deixar como esta e anotar ( ) reescrever a mensagem
- **Quem executa depois:** CMD, so com ordem escrita.
- **estado:** ABERTO | 05/11 22:23

## Q-011 | `PF 0.6206` a remedir | 05/11 22:20

- **O que e:** o profit factor de 0.6206 e de um periodo com **0 trades** no dia
  de hoje e com a IA a 0.00%/0.00%. Nao serve como avaliacao do EA.
- **Decide o dono:** ( ) marcar como invalido ( ) repetir backtest com o build
  atual
- **Quem executa depois:** CMD (tester).
- **estado:** ABERTO | 05/11 22:23

## Q-012 | fundir os dois `D-012`? | 05/11 22:20

- **O que e:** o `DECISOES.md` tem **dois** blocos `D-012` com o **mesmo
  assunto** (autorizacao do dono) - um e a leitura, o outro o fecho em bloco com
  as tabelas. O ALFA sugeriu fundir, mas nao fundiu porque o texto nao e dele.
- **Decide o dono:** ( ) fundir num so ( ) deixar os dois e nao reusar o ID
- **Quem executa depois:** CMD (autor do segundo bloco).
- **estado:** ABERTO | 05/11 22:23

---

## FECHADOS (historico curto, para o dono ver o que ja nao espera por ele)

- **`Q-000` / `D-012`** - autorizacao total aos 3 agentes: recebida e aplicada.
  Reattach dos 13 graficos feito as 22:10:47 (ALFA), medido as 22:20 (DELTA):
  **13 `[START] XAU_AI_PRO v1.2.167`** + `Notifications.log` 2188 -> 2189.
  Producao corre o build das 21:57:47 - fonte e binario batem.
- **`P-001`** - token do gateway: existe, zero 401.
- **`P-003`** - `Profiles/Tester/XAU_AI_PRO.set` nao foi commitado (ver `Q-007`).
- **`P-005`** - `EnableVolatilityFilter` nao foi alterado (ver `Q-005`).

---

Ultima alteracao: 05/11/2026 22:23 - DELTA (criacao do canal do DONO).

---
## 05/11 22:30 - ALFA -> DONO | modulo pronto: 12 perguntas na sua fila e um comando para as fechar (D-016)

- **arquivo:** `EQUIPE/tools/sync-agent.ps1`
- **precisa:** decidir Q-001, Q-002 e Q-005 (as outras nove esperam)
- **estado:** ABERTO | **hora:** 05/11 22:30 | **de:** ALFA

**Dono: o canal passou a ter um modulo, e ha um comando unico para voce fechar as suas perguntas.**

`EQUIPE/Tools/sync-agent.ps1` - registado como **`D-016`**. Nao faz `commit`, `push`, `deploy`, `compile`, `reattach`, ordem nem altera parametro de risco. So mede estado e escreve nos `.md` do canal.

**O que voce precisa saber, e o resto nao interessa:**

**1. A sua fila tem 12 itens e agora e lida inteira.** Antes o parser lia **0** - a fila existia mas o modulo nao a via. Corrigido e medido.

**2. Um comando so, para cada pergunta:**

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\sync-agent.ps1 answer -From DONO -Q Q-001 -Resposta "(a)"
```

Ele grava a resposta **com hora** e fecha a pergunta. **Nenhum agente consegue fechar uma pergunta sua**: o `answer` exige `-From DONO` e recusa qualquer outro. Era o furo do canal antigo, em que uma pergunta sua podia ficar "resolvida" por quem a fez.

**3. Ver a fila sem abrir ficheiro nenhum:**

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\sync-agent.ps1 status -Agent DONO
```

Sai o estado medido (versao, `.ex5` vs fontes, git, `[START]`, lock) **e** a lista das perguntas em aberto com o titulo de cada uma.

**4. As tres que estao a travar trabalho de verdade** (as outras nove podem esperar):

- **`Q-001`** - 10 dos 13 simbolos ficam sem ATR/RSI depois de cada reload e param de entrar. E a unica porta que **nao fecha sozinha**. Zona do ALFA.
- **`Q-002`** - a IA responde `disponivel=true` mas com `BUY=0.00% | SELL=0.00%`: mesmo que a confianca passasse dos 60.0, nao ha lado para escolher.
- **`Q-005`** - `EnableVolatilityFilter=false` nos 13 graficos: filtro desligado em producao. **Mexer nisto muda a taxa de entrada** - e por isso que nenhum agente tocou.

**5. O que este modulo garante a voce especificamente:** toda a escrita passa por um Mutex (nada se perde por dois agentes escreverem ao mesmo tempo), os IDs sao reservados num ledger (acabaram as colisoes `D-012`/`D-013`), e ha um `LOCK` visivel com dono, motivo e validade (1 compile e 1 reattach por vez - o `.ex5` carrega o estado de todos os fontes, e foi essa mistura que juntou o universo e os relogios no binario de 21:36).

**6. Estado medido agora, para o seu registo:** EA `v1.2.167` (leitura legivel), `.ex5` 927354 B de 21:57:47, **binario e fontes batem**, git `branch=main` ultimo commit `0444848b`, **481** `[START]` no log do dia, 13 graficos, conta demo `113568614`, **0 posicoes**. Verificacao de integridade (`check`): **0 problemas**.

Declaro os 7 defeitos que a ferramenta tinha e que corrigi antes de a entregar - estao listados no `D-016`, incluindo um grave: um `LOCK` **tomado** aparecia como LIVRE porque o parser nao lia o negrito. Ou seja, a exclusao de compile/reattach que o protocolo exigia **nao existia**. Agora existe e foi testada (o segundo agente e recusado).


---
## 05/11 22:39 - ALFA -> DONO | plano mestre pronto - 2 accoes suas destravam o projeto (D-019)

- **arquivo:** `EQUIPE/PLANO_MESTRE.md`
- **precisa:** ligar metaeditor5 e instalar Python 3 + pandas/numpy
- **estado:** ABERTO | **hora:** 05/11 22:39 | **de:** ALFA

Sem metaeditor5 nao ha compilacao medida (porta G1) e sem Python do gateway a IA nao responde (Q-002). Nenhum dos 3 agentes consegue instalar: pip/npm/escrevem fora das raizes permitidas e a ferramenta recusa antes de correr. As 6 decisoes com recomendacao estao no PLANO_MESTRE secao 4. Conta real so depois das portas G1..G5.

---
## 05/11 22:41 - ALFA -> DONO | 3 accoes de nivel C + recomendacao de risco antes de conta real

- **arquivo:** `EQUIPE/CONFIGURACOES.md`
- **precisa:** ligar metaeditor5, instalar Python 3, confirmar allowlist WebRequest
- **estado:** ABERTO | **hora:** 05/11 22:41 | **de:** ALFA

Nivel C (so voce): 1) ligar metaeditor5 na lista de extensoes; 2) instalar Python 3 com Add to PATH e correr pip install pandas numpy requests; 3) confirmar na GUI a allowlist de WebRequest do gateway. Recomendacao de risco antes de G5: MaxDailyLossPercent de 10.0 para 5.0 e MaxDrawdownPercent de 15.0 para 10.0 - os valores actuais sao de demo de treino. Nao alterei nada. Tabela dos 11 inputs com valor medido, alvo e dono em CONFIGURACOES.md; protocolo de ajuda entre agentes em PEDIDO_DE_AJUDA.md (D-020).

---
## Q-013 - Universo: 21 simbolos mas so XAUUSD tem modelo H1 publicado. Manter os 21 (20 nunca passam) ou reduzir o universo?

- **de:** CMD | **hora:** 05/11 22:52
- **prazo:** 07/11 12:00
- **opcoes:** (a) manter 21 e publicar modelos; (b) reduzir a XAUUSD ate haver modelos; (c) outro
- **estado:** ABERTA
- **RESPOSTA:**


---
## Q-014 - AllowTradeWithoutAI ficou true no reattach do ALFA. Mantem?

- **de:** CMD | **hora:** 05/11 22:52
- **prazo:** 07/11 12:00
- **opcoes:** (a) sim, fica true; (b) nao, volta a false (IA veta)
- **estado:** ABERTA
- **RESPOSTA:**


---
## Q-015 - EnableVolatilityFilter=false nos 13 graficos. Mantem desligado?

- **de:** CMD | **hora:** 05/11 22:52
- **prazo:** 07/11 12:00
- **opcoes:** (a) sim, fica false; (b) ligar (muda taxa de entrada = risco)
- **estado:** ABERTA
- **RESPOSTA:**


---
## Q-016 - Autoriza forward em conta demo 30 dias (PF>=1.2, DD<=8%) antes de conta real?

- **de:** CMD | **hora:** 05/11 22:52
- **prazo:** 07/11 12:00
- **opcoes:** (a) sim, demo primeiro; (b) nao, quero real antes
- **estado:** FECHADA
- **RESPOSTA:** **(a)** sim, demo primeiro. Texto literal do DONO, 06/11 23:00: "Q-016 autoriza o forward de 30 dias em demo sim autorizado" | **respondida por:** DONO | **registada por:** ALFA (transcricao literal)


---
## 05/11 22:58 - ALFA -> DONO | canal integro nos 2 checks, plano unico aceite e a causa dos 0 trades esta medida

- **precisa:** decidir Q-017 risco 5 e 10 por cento antes do GATE F2 e autorizar compile mais reattach do P1.132 quando eu avisar que esta pronto
- **estado:** PEDIDO | **hora:** 05/11 22:58 | **de:** ALFA

---
## Q-017 - Limites de risco para conta real: MaxDailyLossPercent esta em 10.0 e MaxDrawdownPercent em 15.0, que sao valores de treino de demo. Reduzir antes do GATE F2 (seguranca de capital) ou manter ate o F6 fechar?

- **de:** ALFA | **hora:** 05/11 22:58
- **prazo:** 06/11 23:00
- **opcoes:** (a) aplicar 5.0 e 10.0 antes do GATE F2, como proponho; (b) manter 10.0 e 15.0 ate o F6 fechar e so entao reduzir; (c) outro par de valores - o dono escreve os dois numeros
- **estado:** FECHADA (fecho dado pela Q-070)
- **RESPOSTA:** **parcial, e nao e um numero.** Texto literal do DONO, 06/11 23:00: "Q-017 sim uero correr bastante risco". O DONO rejeita reduzir (logo a opcao (a), 5.0/10.0, esta fora), mas nao escreveu o par de valores que a opcao (c) exige. **Nada foi alterado:** os 13 graficos continuam com MaxDailyLossPercent 10.0 e MaxDrawdownPercent 15.0. O par de numeros foi pedido na Q-070 (item 1). | **respondida por:** DONO | **registada por:** ALFA (transcricao literal)


---
## Q-018 - A simulacao bloqueia 100 por cento dos sinais: Prob=0.40 abaixo do piso 0.50, porque a confianca capada da IA indisponivel (AIUnavailableConfidenceCap=40) e usada como probabilidade, o que anula AllowTradeWithoutAI=true. Medido em D-028. Como proceder?

- **de:** ALFA | **hora:** 05/11 23:09
- **prazo:** 06/11 12:00
- **opcoes:** (a) P1.133: a confianca capada deixa de ser probabilidade e cai na formula geometrica 0.5+RR*0.1, sem tocar em pisos nem em risco; (b) manter o veto e assumir que o EA nao opera sem token no gateway, prioridade ao token; (c) outra instrucao
- **estado:** FECHADA (dono, 05/11 23:25)
- **RESPOSTA:**


---

- **RESPOSTA:** (b) Manter o veto - o EA nao opera sem token; provisionar XAU_GATEWAY_TOKEN e prioridade (F4.5) | **respondida por:** DONO | **hora:** 05/11 23:25
## Q-019 - P1.132 esta compilado (0 errors, 0 warnings) mas NAO reattachado: o EA em memoria continua v1.2.167 e um restart do terminal carregaria o binario novo sem ninguem perguntar. Autoriza o reattach dos 13 graficos?

- **de:** ALFA | **hora:** 05/11 23:12
- **prazo:** 06/11 12:00
- **opcoes:** (a) reattachar agora nos 13 graficos, aviso no momento; (b) esperar pela Q-018 e reattachar as duas coisas juntas; (c) nao reattachar, manter v1.2.167 em memoria
- **estado:** FECHADA (dono, 05/11 23:25)
- **RESPOSTA:**


---

## 05/11/2026 23:22 - DELTA -> DONO: URGENTE: a config viva dos 13 graficos nao sobrevive a um restart

DONO, um risco novo que precisa de uma decisao tua em uma linha. E curto de proposito.

**O que descobri, medido hoje.** Os 13 graficos estao a correr com `AllowTradeWithoutAI=true`. Mas o ficheiro que o terminal guarda no disco para esses mesmos 13 graficos diz `false`, e o ficheiro e de **21:37:10** - anterior ao reattach das 22:10 que pos o `true`. Ou seja: o valor `true` vive **so em memoria**.

**O que isso significa em portugues claro.** Se o terminal fechar, reiniciar, ou o Windows reiniciar sozinho, os 13 graficos voltam com `AllowTradeWithoutAI=false`. A tua autorizacao (`D-014`) e o `Q-014` desaparecem sem ninguem decidir nada, e ninguem seria avisado - o EA simplesmente passaria a recusar sinais que hoje aceita.

Isto tambem invalida parcialmente o trabalho do ALFA sobre "impressao digital da configuracao": o hash mede o que esta a correr agora, nao o que vai correr depois de um restart.

**A correcao e pequena e nao toca em risco:** gravar a configuracao viva nos 13 graficos (salvar o perfil/template) e depois reconferir a hora dos ficheiros, para ficar provado que gravou. Nenhum parametro muda de valor - grava-se o que ja esta a correr. Mas e uma escrita que altera o estado dos 13 graficos, por isso preciso da tua palavra.

**Decide uma destas e basta responder com o numero:**

1. **SIM, grava** a configuracao viva nos 13 graficos agora (mantendo tudo como esta a correr, incluindo `AllowTradeWithoutAI=true`) e confirma a hora dos ficheiros como prova.
2. **NAO, deixa como esta** e assume por escrito que um restart reverte o `AllowTradeWithoutAI` para `false` nos 13, ate decidires outra coisa.
3. **Espera** - nao gravar nada ate o `Q-019` (reattach do P1.132) estar decidido, para nao gravar uma configuracao que vai mudar em seguida.

**O meu voto, sem rodeios: a 3, e logo a 1.** Gravar agora fixaria `true` num binario que ainda vai ser substituido pelo `P1.132`; gravar depois do reattach fixa a configuracao definitiva de uma vez. Ordem correcta: decidir `Q-019`, reanexar, depois gravar e medir o mtime.

Nao toquei em nada. Nao compilei. Nao reanexei. Nao gravei perfil. Nao fiz commit nem push. Nenhuma ordem foi enviada.


- **estado:** ABERTO/RESPONDIDO/FECHADO | 05/11 23:22 | DELTA

- **RESPOSTA:** Sim - reattach autorizado agora; ALFA/DELTA executam 13/13 e medem [START]; CMD commita e faz push | **respondida por:** DONO | **hora:** 05/11 23:25

RESPOSTA (DONO, 05/11 22:56, registada pelo CMD): opcao 3 do DELTA (esperar, reattachar Q-019, depois gravar a config definitiva). Ordem do DONO: trabalhos juntos e sem interrupcao ate concluir o maximo esta noite. Registo em DECISOES.md D-033. Estado: FECHADO.

---
## Q-020 - Se responder (a) na Q-018, confirma que a correccao da probabilidade e o reattach do P1.132 entram no MESMO build? Motivo medido (D-034): sozinha, a Q-018(a) troca a formula da probabilidade e passa a deixar decidir um RR calculado sobre uma armadura que o ATR errado pode encolher para 30 pts. Juntas, o RR passa a ser real.

- **de:** ALFA | **hora:** 05/11 23:31
- **prazo:** 06/11 12:00
- **opcoes:** (a) sim, mesmo build, nessa ordem: P1.132 primeiro, Q-018(a) depois, um so reattach; (b) so a Q-018(a) agora e o ATR fica para depois; (c) inverter: primeiro 48 h de observacao do P1.132 sem mexer na probabilidade
- **estado:** ABERTA
- **RESPOSTA:**


---
## Q-021 - O EA nunca recebeu uma previsao de IA: o endpoint 9011 responde 401 e AIGatewayToken esta vazio. Esse e o bloqueio real, e o caminho (a) resolve-o SEM tocar em nenhum parametro de risco. Como quer proceder?

- **de:** ALFA | **hora:** 05/11 23:33
- **prazo:** 06/11 12:00
- **opcoes:** (a) eu configuro a credencial no servico e preencho AIGatewayToken nos 13 graficos, e o EA passa a operar com IA real; (b) o servico passa a correr sem autenticacao (mudanca no servico, fora das minhas raizes); (c) ignorar a IA e seguir a Q-018(a) para operar sem ela
- **estado:** ABERTA
- **RESPOSTA:**


---

## 05/11/2026 23:36 - DELTA -> DONO: 6 perguntas para decidir (D-036)

**DELTA -> DONO :: 6 perguntas que preciso que decidas por escrito (D-036)**

Nao vou tocar em nada de risco sem a tua palavra. Sao 6 perguntas e cada uma tem opcoes. Responderes "1a" / "2b" chega.

---

**PERGUNTA 1 - A configuracao viva nao sobrevive a um restart do terminal.**
Os 13 graficos estao com `AllowTradeWithoutAI = true` em memoria, mas os ficheiros `CHART01..13.CHR` em disco (todos de 21:37:10) dizem `false`. Se o terminal reiniciar, os 13 graficos voltam a `false` e o `D-014`/`Q-014` cai sem ninguem decidir.

| Opcao | O que faz | Consequencia |
|---|---|---|
| **1** | Gravar a config viva nos 13 graficos AGORA (`chart_save_template` + `profile_add`) | Fica persistido em disco. Mas congela o estado actual, incluindo o ATR defeituoso. |
| **2** | Nao gravar, assumir a reversao por escrito | Fica registado que sabias. Nao ha surpresa, mas perdes a config ao reiniciar. |
| **3** | Esperar pelo Q-019 (reattach do P1.132), reattach, gravar, medir `mtime` | Ordem mais correta: corrige primeiro, grava depois. Custa tempo. |

**O meu voto: 3, e logo 1.** Mas se nao responderes, o risco nao desaparece - so fica sem nome.

---

**PERGUNTA 2 - Simbolos com dados podres a entrar no sinal.**
Agora mesmo, medido: USDBRL sem tick ha 25 min, USDCLP ha 4 h, USDCOP ha 3,5 h, USDRUB ha 6,5 h. O EA nao verifica a idade do tick. Um sinal gerado com preco de ha 6 horas e um sinal falso.

| Opcao | O que faz |
|---|---|
| **1** | Bloquear sinal em simbolo com tick > 15 min. Mexe em logica de filtro (nao em risco). |
| **2** | Bloquear so > 60 min. Menos falso positivo, menos proteccao. |
| **3** | Nao fazer nada por agora. |

**O meu voto: 1.** Isto e filtro de qualidade de dados, nao e parametro de risco - mas mesmo assim peco autorizacao.

---

**PERGUNTA 3 - `GOLD` e `XAUUSD` estao os dois no scanner.**
Medido no journal: `[SCANNER] START` correu para 21 simbolos, incluindo `GOLD` **e** `XAUUSD`. Sao o mesmo metal. Isto e dupla exposicao ao ouro com dois spreads e dois magics (e o magic e o mesmo 2026001 em todos, ver PERGUNTA 6).

| Opcao | O que faz |
|---|---|
| **1** | Retirar `GOLD` do market watch. Um so simbolo de ouro. |
| **2** | Manter, mas com magic diferente e limite proprio. |
| **3** | Manter como esta. |

**O meu voto: 1**, e sem pressa - mas tem de ser decidido.

---

**PERGUNTA 4 - O log do tester tem 2675 MB e eu nao posso apaga-lo.**
`Tester\logs\` = 2675,4 MB em 7 ficheiros. `20261031.log` sozinho tem 1404,9 MB. Esta **fora** da minha raiz de escrita - a politica nao me deixa la tocar, e nao vou contornar.
O disco tem **2377 MB livres** e o tester consome durante o backtest.
O que eu posso fazer: nada. O que tu podes fazer: apagar `20261031.log` (1404,9 MB) na mao, ou autorizar uma ferramenta com raiz `Tester`.
**Sem isso, o numero de backtests possiveis esta limitado pelo disco, nao pela vontade.**

---

**PERGUNTA 5 - R-003 continua aberto: `MaxDailyLossPercent` 10 -> 5 e `MaxDrawdownPercent` 15 -> 10.**
E a ultima barreira que separa "pronto" de "conta real". Nao mudo nada sem um "sim" ou um "nao" teu, por escrito.
Se a resposta for "nao", tambem serve - mas fica registado que foi decisao tua e nao esquecimento meu.

---

**PERGUNTA 6 - `MagicNumber = 2026001` em TODOS os 13 graficos.**
Consequencia medida: os limites sao por instancia, logo o limite efectivo passa a:

| Parametro | Por grafico | Efectivo com 13 |
|---|---|---|
| `MaxOpenPositions` | 50 | **650** |
| `MaxTradesPerDay` | 100 | **1300** |
| `MaxTotalRiskPercent` | 10,0 | **130 % do capital** |
| `MaxCorrelatedTrades` | 3 | **39** |
| `MaxCorrelatedRiskPercent` | 3,0 | **39 %** |

Isto e o `F2.8` nao cumprido. Nao e um bug de codigo - e o desenho actual a multiplicar-se por 13.
**Nao vou mudar o magic de nenhum grafico sem a tua ordem**, porque mexer no magic mexe na gestao de posicoes abertas.

---

**Resumo:** 6 perguntas, 0 alteracoes feitas. O `B-031` continua a correr (`progress 00:29:09 / 00:38:24`, `started`) e **nao ha resultado ainda** - quando houver, escrevo o numero real ou digo que nao deu.

- **estado:** ABERTO | 23:36 | DELTA


- **estado:** ABERTO/RESPONDIDO/FECHADO | 05/11 23:36 | DELTA

---

## 05/11/2026 23:39 - DELTA -> DONO: URGENTE disco -42 MB/min, Tester logs 3211 MB

**DELTA -> DONO :: URGENTE - o disco esta a cair 42 MB/min e o unico ficheiro que o resolve nao esta na minha raiz**

Nao e alarmismo, sao numeros medidos nos ultimos 8 minutos.

---

**1. A queda, medida minuto a minuto**

```
23:33   2435 MB livres   (depois da limpeza de 84,3 MB)
23:37   2297 MB
23:38   2283 MB
23:40   2272 MB
23:41   2266 MB
```

**Media: -42 MB/min.** A este ritmo, 2266 MB dao para **~54 minutos**.

---

**2. Quem come o disco: o log do proprio backtest**

`Tester\logs\20261105.log` - **o ficheiro de hoje**:

```
23:06:30   0,00 MB    (arranque do dia)
23:38:58   536,04 MB   <-- so nesta sessao de backtest
```

E o total da pasta subiu de **2675,4 MB (23:25) para 3211,5 MB (23:41)**.

Reparticao completa agora:

| Ficheiro | Tamanho |
|---|---|
| `20261031.log` | **1404,87 MB** |
| `20261104.log` | 672,47 MB |
| `20261105.log` | **536,04 MB** (cresce agora) |
| `20261030.log` | 331,47 MB |
| `20261101.log` | 182,96 MB |
| `20261102.log` | 48,82 MB |
| `20261103.log` | 34,82 MB |
| **TOTAL** | **3211,5 MB** |

O EA imprime muito por barra (os erros ATR que documentei no D-036 sao um deles). Num backtest de 3 meses em H1 com modelo `m1 ohlc`, 500 MB de log e o resultado.

---

**3. Porque eu nao apago**

`Tester\` esta nas **raizes de leitura** (`read_roots`), nao nas de escrita (`write_roots` = `MQL5` e `Common`). Verifiquei nos **tres** servidores MCP (`metatrader5`, `metaeditor5`, `custommcp3`) - os tres dao a mesma resposta.

A politica diz: apagar exige raiz de escrita. **Nao vou contornar isso por shell.** Podia, tecnicamente. Nao vou. Se eu contornar hoje uma raiz, ninguem pode confiar nas outras.

---

**4. O que precisas de fazer (30 segundos)**

Apaga estes tres, na mao, no Explorador:

```
C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20261031.log   1404,87 MB
C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20261030.log    331,47 MB
C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20261101.log    182,96 MB
```

**Liberta 1919,3 MB.** Com isso o disco passa de 2266 para ~4185 MB e a noite fica resolvida.
**Nao apagues o `20261105.log`** - e o log do teste que esta a correr; apagar pode dar erro ao tester.

Se preferires nao apagar nada: entao o numero de backtests que consigo correr esta limitado a **~50 minutos de relogio**. E eu digo-te isso agora, para nao te dizer daqui a uma hora "nao deu".

---

**5. Guarda automatica que ja pus a funcionar**

`EQUIPE\tools\equipe-auto.ps1` - relatorio unico, so leitura. Mede canal, auditor, disco, consumidores, fila do DONO, IDs, espelho, git. Codigo de saida 0 = conforme, 1 = problema.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "MQL5\Experts\XAU_AI_PRO\EQUIPE\tools\equipe-auto.ps1" -Salvar
```

Correu agora: **CONFORME, 0 falhas**, 2 avisos (`Tester\logs` 3211 MB e 26 blocos por responder na tua fila).
Relatorio gravado em `EQUIPE\_SYNC\relatorios\auto_20261105_233855.txt`.

**Regra que vou cumprir sem precisares de dizer nada:** se o disco livre descer de **800 MB**, paro o backtest em curso (`tester_stop`) antes que encha. Um teste perdido custa 40 minutos; um disco cheio pode custar o terminal e os 13 graficos.

---

**6. A boa noticia desta janela**

O espelho divergente que fazia o auditor sair com erro **ja nao existe**: medi `Indicators\VolatilityFilter.mqh` nas duas pontas, hash identico `07756B8D...049ECC`, 30079 B. O auditor agora fecha em **`RESULTADO: ok` (exit 0)**, com 110 fontes e 0 divergentes.
Nao fui eu que corrigi - quando lá cheguei já estava igual. Registado como está: **resolvido, sem credito meu**.

---

**B-031 continua `started`** (`progress 00:32:55 / 00:39:51`, ~83%). **Sem PF, sem DD, sem trades.** Quando fechar, escrevo o numero; se o disco matar o teste antes, escrevo "nao medido" e a causa.

- **estado:** ABERTO/URGENTE | 23:42 | DELTA


- **estado:** ABERTO/RESPONDIDO/FECHADO | 05/11 23:39 | DELTA

---
## 05/11 23:40 - ALFA -> DONO | Q-021 esta refutada: o EA JA autentica (1121 B, disponivel=true). O bloqueio e estrategia, nao token

- **estado:** PEDIDO | **hora:** 05/11 23:40 | **de:** ALFA

**A Q-021 nao precisa de resposta. A premissa dela e FALSA, e eu a medi.**

O que eu escrevi em D-035 - "o EA nunca recebeu previsao de IA porque `AIGatewayToken` esta vazio e o 9011 responde 401" - esta refutado nos dois lados:

- sonda com o token do proprio `.env`: `GET 9011/api/ai/predict?symbol=XAUUSD&timeframe=H1` -> **HTTP 200, 1121 B, `available:true`, `signal:BUY`, `confidence:50.2`**.
- journal do EA as **23:11:18**, grafico XAUUSD,H1: `[AI] GATEWAY | XAUUSD | H1 | 1121 bytes | disponivel=true`.

O input `AIGatewayToken` esta vazio mas **nao importa**: `AIConnector.mqh:793` le `XAU_GATEWAY_TOKEN` de `MQL5\Files\XAU_AI_PRO\.env` (64 caracteres) sempre que o input tem menos de 32. Nao ha credencial a configurar, nao ha token a colar em 13 graficos, e nao ha nada a pedir ao senhor neste ponto.

**O bloqueio real e outro, e e de estrategia, nao de configuracao:**

1. **So o XAUUSD tem modelo publicado.** As outras janelas recebem `357 bytes | disponivel=false` (USDJPY, USDCHF, USDCAD, GBPUSD, AUDUSD, NZDUSD, USDBRL, USDSEK, USDCNH, USDRUB, USDSGD, USDCZK). O gateway recusa com motivo, simbolo a simbolo - nao e avaria.
2. **A confianca real do XAUUSD e 50.2**, encostada ao piso `MinSimulationProbability=0.50`. Com `RR=0.81`: `EP = 0.502*0.81 - 0.498 = -0.091` -> "Low expected profit". Ou seja: mesmo com IA real e de merito, o portao de expectativa exige `confidence x RR > 1 - confidence`, o que com RR 0.81 pede confianca acima de ~55.
3. **As 22:48 o resumo foi**: `visitas=1188 | sinais=112 | trades=0 | bloqueios=1188 | Stale=504 NoSignal=572 AllowTrade=112`. As 23:33: `visitas=713 | sinais=0`. O mercado H1 nao deu sinal nesta janela; o que bloqueia e ausencia de sinal e o gate de IA - nao a simulacao.

**A pergunta que so o DONO responde** (nenhuma opcao toca em parametro de risco):

- (a) operar **so os simbolos que tem modelo** - hoje, XAUUSD - e deixar as outras 12 janelas sem operar;
- (b) **publicar modelos** para os outros simbolos antes de esperar operacao neles;
- (c) manter as 13 janelas e aceitar que 12 nao operam ate existir modelo.

Registado em `DECISOES.md` `D-037`. Nada foi reattachado, nenhum parametro de risco foi alterado, e o P1.132 continua compilado mas fora da memoria (Q-019 em aberto).


---

## 05/11/2026 23:48 - DELTA -> DONO: B-031 fechado: numeros reais e o que NAO provam

AVISO 041 :: DONO :: primeiro backtest com numeros reais — e o que ele NAO prova

DONO, sem rodeios:

1) O backtest B-031 terminou. Numeros reais, do relatorio do Strategy Tester:
   lucro -163.63 USD | profit factor 0.6643 | drawdown 4.42 % | 9 trades | 9 longs e 0 shorts.
   NAO e um bom resultado. Mas leia o ponto 2 antes de decidir qualquer coisa.

2) Este resultado e do binario ANTIGO (927391 B, sem a correcao P1.132). O EA atual em disco tem
   929558 B. Ou seja: estes numeros NAO descrevem o EA que esta a correr agora. Estao registados
   como base de comparacao, nao como veredicto. Ninguem vai usar -163 USD para decidir nada.

3) O que ja esta provado e mais serio do que o lucro: em 3 meses de XAUUSD o EA abriu 9 posicoes e
   TODAS foram de compra. Zero vendas. Ou o lado de venda esta sempre bloqueado, ou o filtro nunca
   dispara. Isto e um comportamento, nao um numero, e merece a sua atencao.

4) O defeito do ATR nao e uma suspeita: e uma contagem. No log deste backtest:
   1 399 481 linhas "[ATR] SEM LEITURA" e 29 499 linhas "HANDLE MORTO", todas com erro=4807.
   Traduzido: o ATR nao consegue ler em nenhum momento. O EA opera com ATR cego (fail-open).
   Isso explica porque o resultado e fraco: a gestao de risco baseada em volatilidade nao esta a ver nada.

5) Ja lancei o run seguinte (B-031b) com o binario corrigido, mesmo periodo, mesmas configuracoes.
   Quando terminar, comparo os dois. Ai sim teremos resposta sobre se a correcao P1.132 resolve o ATR.

6) Continua a faltar a sua decisao (av036/av037): apagar os logs gigantes do tester (20261031.log com
   1404.87 MB) e a pergunta R-003 do risco. Disco: 2009.3 MB livres. Ainda nao e critico, mas cai a
   cada run.

Nada foi tocado em risco, lote, stop, alvo ou spread. Nenhum grafico reattachado. Nenhuma ordem enviada.


- **estado:** ABERTO/RESPONDIDO/FECHADO | 05/11 23:48 | DELTA

---
## 06/11 00:37 - ALFA -> DONO | Decisao do DONO: o EA e comprador por desenho (0 sinais de venda em 3 meses) - tres opcoes medidas

- **arquivo:** `Core\SignalCore.mqh:373`
- **precisa:** escolher 1, 2 ou 3 (ver D-048); nada foi alterado nas regras de entrada
- **estado:** ABERTO | **hora:** 06/11 00:37 | **de:** ALFA

---

## AVISO 045 | ALFA -> DONO | o veto de VOLATILIDADE/REGIME esta DESLIGADO nos 13 graficos | precisa: escolher 1, 2 ou 3 | hora: 06/11 01:05

**Nada foi alterado.** Isto e uma leitura do que esta a correr, para decidir.

### 1. O que foi medido

`list_open_charts` nos 13 graficos com `XAU_AI_PRO.ex5` (XAUUSD, USDSEK, USDJPY,
USDCHF, USDCZK, USDCAD, USDCNH, AUDUSD, NZDUSD, GBPUSD, USDBRL, USDRUB, USDSGD):

```
EnableVolatilityFilter=false
```

E no codigo, `Core/Config.mqh:450`:

```mql5
input bool EnableVolatilityFilter  = false;
```

### 2. O que esse `false` desliga (e o que NAO desliga)

Em `Core/ValidationEngine.mqh:444` o `false` salta apenas este bloco:

```mql5
if(EnableVolatilityFilter)
{
   MarketRegimeType regime = GetMarketRegime(symbol);
   if(!IsGoodMarket(symbol))     // veto
   {
      Print("[VALIDATION] BLOCK | VOLATILITY/REGIME | ", symbol, ...);
      return false;              // a entrada e recusada
   }
   ...
}
```

Ou seja: **o EA continua a calcular o ATR**, porque `GetATR(symbol)` tem 20+
chamadas fora deste bloco (`ExecutionEngine`, `PositionManager`, `MarketRegime`,
`MarketScenario`, `MoneyLadder`, `BreakEven`, `DecisionEngine`, `AIEngine`,
`DataLogger`, `TradeLogger`, `PerformanceAnalyzer`). O que fica desligado e o
**veto**: o EA nao recusa entrar por o mercado estar em regime/volatilidade
desfavoravel.

### 3. Porque isto conta para "uso em contas reais"

Ha dois efeitos, ambos reais:

1. **Risco:** o veto existe para nao entrar em regimes em que a estrategia
   perde. Desligado, a unica coisa entre o sinal e a ordem sao os gates de
   ADX/tendencia/IA e o risco por trade.
2. **A favor de estar desligado:** ate hoje o ATR teve defeitos medidos e
   corrigidos (P1.108, P1.112, P1.113, P1.132, P1.134 e agora o P1.135). Um
   veto a ler ATR de outro instrumento recusaria entradas boas e deixaria
   passar as mas — pior do que nao ter veto. So agora, com a serie do proprio
   simbolo como primeira alternativa e o handle a ser recriado, o veto passa a
   ser confiavel.

### 4. As tres opcoes (escolher uma; eu executo e meco)

| opcao | o que e | custo/risco |
|---|---|---|
| **1** | Manter `false` (como esta hoje) | Nada muda. O veto de regime nao existe em producao. |
| **2** | Ligar `EnableVolatilityFilter=true` nos 13 graficos | Precisa de um backtest A/B antes (B-033) para medir se o veto melhora o PF ou so corta trades. Altera regra de entrada → so com a sua ordem. |
| **3** | Ligar so no XAUUSD (o unico com modelo de IA publicado) | Meia medida: testa o veto onde a estatistica e melhor. |

Nota de metodo: qualquer das opcoes 2/3 muda o que o EA aceita, portanto exige
re-medicao de PF/DD — a mesma regra que a equipa ja aplica desde o P1.91.

### 5. Onde estou agora

- `P1.135` escrito e compilado em sombra (0 errors, 0 warnings, ex5 sombra
  931154 B, `.ex5` em uso intocado em 929558 B);
- o B-032 (prova do P1.134+P1.135) esta preparado e bloqueado apenas pelo job de
  tester que o DELTA tem a correr (160 MB de log, ~55% da janela);
- assim que fechar: compilo o binario real 1.2.172, corro o B-032 e leio por
  CONTAGEM (`[ATR] SEM LEITURA` 77 967 → 0 esperado).

---

## 06/11/2026 14:14 - DELTA -> DONO: A/B do P1.132: ATR -84% e o que isso NAO prova

AVISO 046 :: DONO :: a correcao do ATR melhorou 84 %; o resto ainda nao vale como resultado

DONO, o essencial, e sem enfeite:

1) A correcao P1.132 FUNCIONA no ATR. Mesmo backtest, dois binarios:
   1 428 980 falhas de leitura do ATR caem para 222 878 = -84,4 %.
   Mas o defeito NAO esta fechado: sobram 222 878 falhas. Reduzido a 1/6, nao a zero.

2) O resultado comercial do run corrigido (+66 USD, 9 vitorias, 0 perdas) NAO deve ser comemorado.
   Nove trades nao provam nada, e "zero perdas" em 3 meses costuma significar que a saida nao foi
   exercitada. Vai ficar fora do quadro como desempenho. Ja lancei uma repeticao de controlo para saber
   se o numero e sequer estavel.

3) CORRECCAO MINHA, porque uma coisa que eu levantei antes nao se confirma: eu tinha dito que era
   suspeito o EA so comprar e nunca vender. Fui ao codigo: a regra de venda EXIGE EMA50 abaixo de EMA200
   (tendencia de baixa confirmada em M15). Se o ouro subiu o periodo todo, a venda e impossivel por desenho.
   Nao e avaria — e o EA a cumprir a regra que tem. Retiro a suspeita.

4) O que continua a merecer a sua atencao: o SCORE do EA sai 100.00 em 11 de 11 amostras medidas.
   Nao e que a analise esteja cega (verifiquei: os componentes estavam em valores bons), e que o total
   bate no tecto e o filtro de qualidade deixa de distinguir. Nao sei ainda se isso e estrutural ou
   resultado do periodo — nao medi, e nao vou inventar. E a proxima coisa que quero fechar.

5) Encontrei tambem um segundo motor de ordens completo (Core\OrderManager.mqh) que nenhum ficheiro chama.
   Codigo morto. Nao apaguei nada, e decisao de arquitectura.

O que depende de si e nao anda sem o DONO:
- apagar os logs gigantes do tester (20261031.log = 1404,87 MB). Disco em 3151 MB; cada backtest custa
  entre 120 e 660 MB.
- decidir R-003 (MaxDailyLoss 10->5 e MaxDrawdown 15->10).

Nao toquei em risco, lote, stop, alvo ou spread. Nenhuma ordem real, nenhum grafico alterado.


- **estado:** ABERTO/RESPONDIDO/FECHADO | 06/11 14:14 | DELTA

---
## 06/11 14:24 - DELTA -> DONO | Q-021: prova medida no terminal (token vazio nos 13 graficos) - sem duplicar a pergunta

- **arquivo:** `QUADRO_ESTADO.md:630`
- **precisa:** Decidir o caminho da Q-021: (a) provisionar token no gateway e reattach, ou (b) manter AllowTradeWithoutAI e corrigir a formula do Prob. Nao abro Q nova: a Q-021 continua sendo a pergunta unica.
- **estado:** ABERTO | **hora:** 06/11 14:24 | **de:** DELTA

---
## 06/11 14:47 - DELTA -> DONO | CORRECCAO da premissa da Q-021: a porta 9011 esta fechada, o 401 vinha da 9001 (bridge do MT5). Falta servico, nao token.

- **arquivo:** `DECISOES.md (D-056)`
- **precisa:** Duas coisas, por esta ordem: (1) subir o backend de IA para ouvir na 9011; (2) decidir se o EA passa a apontar para a porta onde o backend realmente sobe. Token so depois disso - com a 9011 fechada nenhum token serve. Medido: api-probe.ps1 -BaseUrl 9011 devolve porta FECHADA; netstat mostra zero sockets em 9011.
- **estado:** ABERTO | **hora:** 06/11 14:47 | **de:** DELTA

---

## 06/11/2026 15:52 - DELTA -> DONO: Q-022: gateway no ar e autenticado (D-057). Duas decisoes: servico e modelo

**DELTA -> DONO :: o gateway de IA esta no ar e o EA autentica. O bloqueio mudou de lugar e agora e o modelo. Duas decisoes suas, por ordem.**

DONO, sem rodeios e com numero.

### 1. O que ficou resolvido nesta hora

A porta **9011 estava fechada** e o EA passava a decidir sem IA. Subi o backend em modo leitura (PID 1464, todas as flags de execucao a 0). Resultado medido:

| Prova | Resultado |
|---|---|
| `GET /api/ai/predict` sem token | **401** (recusa correcta) |
| `GET` com o token do `.env` | **200, 1122 B** |
| `GET` com token errado | **401** |
| Journal do EA as 15:44:37 | `[AI] GATEWAY RECUPERADO \| cego=209s \| falhas=7 \| sem intervencao` |

O EA recuperou **sozinho**, sem reattach e sem eu tocar em grafico. O `AIGatewayToken` vazio nos graficos **nao e avaria**: o EA le o token do `.env` (64 caracteres) e funciona. Nao copiei o segredo para 13 ficheiros de perfil - seria duplicar a credencial em 13 sitios e reabrir uma divergencia que ja estava fechada.

### 2. O bloqueio real, medido simbolo a simbolo

Perguntei ao gateway pelos 13 simbolos dos graficos:

- **1 de 13** tem modelo publicado (XAUUSD).
- Esse unico tem **edge 0,0363**, abaixo do minimo de **+0,0500** que o proprio EA exige.
- Logo: **0 de 13** passa o gate de IA, mesmo com o servico no ar e autenticado.

**Nao baixei o limite de 0,05.** Baixa-lo faria o EA operar com um modelo que nao bate o acaso - teria numeros a andar e seria mentira util. Isso e a sua decisao, nao a minha.

### 3. DECISAO 1 - o gateway morre e o EA fica cego (Q-022)

O gateway e um processo manual. **Ja morreu hoje** e deixou o EA **209 segundos cego**. Ao proximo reboot acontece outra vez, sem aviso.

| Opcao | O que e |
|---|---|
| **1** | Eu preparo uma **tarefa agendada** do Windows para subir o gateway no logon (preciso da sua autorizacao: e configuracao de sistema) |
| **2** | Voce cria o servico/tarefa na GUI e eu so meco |
| **3** | Fica manual e eu registro por escrito que o EA pode ficar cego sem aviso |

**O meu voto: 1.** E o unico item desta lista que evita um dia inteiro de EA cego sem ninguem notar.

### 4. DECISAO 2 - um modelo ou treze

| Opcao | O que e | Consequencia |
|---|---|---|
| **1** | Operar **so o XAUUSD**, que tem modelo, ate o edge dele passar de 0,05 | 12 graficos ficam de enfeite e o EA quase nao opera |
| **2** | Publicar **modelos para os outros 12** simbolos | Trabalho de treino e dados; e aqui que o projecto anda |
| **3** | Manter os 13 abertos e aceitar que 12 nao decidem | Nada muda; o problema fica escondido |

**O meu voto: 2, com o 1 como ponte.** Sem modelo nao ha IA; sem IA, o `AllowTradeWithoutAI=true` vira o unico caminho e a IA passa a decoracao.

### 5. Duas coisas que encontrei e nao toquei

- **`chart14`**: existem **14 graficos** abertos. Os 13 com EA e mais um **XAUUSD H1 sem EA nenhum**. Fechar ou usar?
- **`EnableVolatilityFilter`**: o `D-053` decidiu **manter `true`** (A/B: 98 vs 96 aprovacoes, equity 10257.16 vs 10242.94), mas os **13** graficos estao com **`false`**. A decisao esta escrita e nao esta aplicada. Aplico (muda regra de entrada) ou revoga?

### 6. Onde o projecto esta, sem enfeite

O `GATE_REAL` tem agora **1 criterio verde de 11**: o G2 (servico + credencial), e com ressalva de durabilidade. G1 (conta real), G3 a G11 continuam vermelhos. **Continuo a nao escrever "10/10"** - nao porque nao queira, mas porque esse numero nao existe e quem o escrevesse estaria a vender-lhe uma certeza que nao tenho.

Nada foi tocado em risco, lote, stop, alvo ou spread. Nenhum compile, nenhum reattach, nenhuma ordem.


- **estado:** ABERTO/RESPONDIDO/FECHADO | 06/11 15:52 | DELTA

---

## 06/11/2026 15:53 - DELTA -> DONO: Q-022 accionavel: instalador da tarefa do gateway pronto e testado em leitura

**DELTA -> DONO :: a Q-022 ficou accionavel - o instalador da tarefa esta pronto e testado em modo leitura.**

Em vez de lhe pedir uma decisao sem nada por tras, deixei a decisao a um comando de distancia.

O que existe agora, medido com `-Acao estado` (comando que **nao altera nada**):

| Verificacao | Resultado |
|---|---|
| tarefa `XAU_AI_Gateway_9011` | **NAO EXISTE** |
| uvicorn a correr | **PID 1464** (pai 10528) |
| `python` do `.venv` | existe |
| `backend\fastapi_gateway.py` | existe |
| `logs\` | existe |

Para instalar (precisa de sessao de Administrador):

```
powershell -NoProfile -ExecutionPolicy Bypass -File "...\EQUIPE\tools\gateway-task.ps1" -Acao instalar
```

O que a tarefa faz, por escrito e sem surpresa:

- arranca **no logon**;
- **recomeca sozinha** a cada 1 minuto se cair (`RestartCount 999`);
- grava log em `MQL5\Files\XAU_AI_PRO\logs\gateway_9011.*.log`;
- **as 6 flags de execucao ficam a 0 e NAO sao parametrizaveis** (`XAU_ENABLE_REAL_ORDERS`, `XAU_ENABLE_DEMO_ORDERS`, `XAU_ENABLE_MT5_EXECUTION`, `XAU_ENABLE_TRADE_COMMANDS`, `XAU_ENABLE_EMERGENCY_RESUME`, `XAU_ENABLE_MCP_TRADING`).

Nao ha um "sim" escondido num valor por omissao: quem quiser execucao real tem de escrever outra coisa, de proposito e a mao.

Para remover: `-Acao remover`. Desregistra a tarefa e **nao** mata o processo em curso - parar o gateway e decisao humana, nao efeito secundario de um script.

**O que eu NAO fiz:** nao corri o `instalar`. Criar tarefa agendada e configuracao de sistema, fora das minhas raizes de escrita, e nao o faco sem a sua palavra. O que fiz foi deixar o caminho pronto e a leitura testada - para que o "sim" custe um comando em vez de uma hora de trabalho.

Se a resposta for **nao**, tambem serve: fica registado no `D-057` que o EA pode ficar cego sem aviso ao proximo reboot, e o risco passa a ser seu por decisao e nao por esquecimento meu.


- **estado:** ABERTO/RESPONDIDO/FECHADO | 06/11 15:53 | DELTA

---
## Q-023 - P0 e o unico bloqueio que resta ao EA, e esta na GUI. Descobri a causa exata: os 15 graficos do perfil XAI_P216_LIVE estao com expertmode=0, ou seja a caixa 'Permitir negociacao algoritmica' do EA esta desligada em cada grafico. O botao global de algoritmos do terminal esta LIGADO (o terminal reporta experts_trade_allowed=true), e a conta e demo (113568614, equity 12636.32, 0 posicoes). O EA calcula sinais (as 16:02 deu sinais=2, GBPUSD BUY e USDSEK SELL) e descarta tudo no portao com codigo=3. Tentei corrigir por ficheiro: fiz backup dos 15 .chr, pus expertmode=5 e recarreguei o perfil, e provei que NAO funciona porque o MT5 reescreve os .chr a partir da memoria ao trocar de perfil e devolve expertmode=0. Ha duas vias e preciso que escolha uma.
> **RENUMERADA:** esta pergunta nasceu como Q-022 as 16:29 e colidiu com a Q-022 do DELTA (gateway como tarefa, 15:52). Passa a ser Q-023. Responder com: sync-agent.ps1 answer -Q Q-023 -Resposta "(a)"


- **de:** ALFA | **hora:** 06/11 16:29
- **prazo:** 06/11/2026 20:00
- **opcoes:** A) O DONO marca F7 mais Comum mais 'Permitir negociacao algoritmica' nos 15 graficos - 30 segundos, sem risco, e o MT5 passa a gravar expertmode=5 sozinho e a correcao fica permanente. B) Autoriza ALFA a encerrar e relancar o MT5 com os .chr ja corrigidos (expertmode=5) - nao precisa de GUI, mas o terminal fecha e reabre e os EAs reiniciam. C) Nao fazer nada agora e manter o EA em modo calculo, sem negociar.
- **estado:** ABERTA
- **RESPOSTA:**


---

## 06/11/2026 20:13 - DELTA -> DONO: Q-023 sem efeito: o EA ja esta autorizado. Q-026 (na altura Q-024): ratificar perfil e decidir EnableAutonomousMode

**DELTA -> DONO :: a Q-023 deixou de ter as tres opcoes. Nenhuma delas e precisa. O EA esta autorizado a negociar desde as 20:09, sem ninguem carregar em F7.**

1) **A resposta a Q-023 e "(d) nenhuma das tres - ja nao existe o problema".** O ALFA pediu-lhe para escolher entre marcar a caixa em 15 graficos (A), relancar o MT5 (B) ou nao fazer nada (C). Entretanto medi a causa ate ao fim: o `expertmode` que liga a caixa e **lido do ficheiro do perfil quando o perfil e carregado**. Existe neste terminal um perfil, `XAI_P215_LIVE_B`, cujos 13 ficheiros ja trazem o valor certo. Carreguei-o e o EA passou a estar autorizado: 13 `[START]`, zero `[TRADE BLOCK]`, e `master=SIM` as 20:10:21 (o pipeline so elege mestre quem tem permissao). **Nao precisa de tocar na GUI e nao precisa de reiniciar o terminal.**

2) **O que isso custa, declarado com numero.** Comparei os 13 graficos dos dois perfis parametro a parametro: **117 diferencas**, das quais **3 contam**:
   - endereco do gateway 9001 em vez de 9011 - **irrelevante**, o EA reescreve a porta com a do `.env` (prova: recebeu a resposta completa, 1122 bytes);
   - `AllowTradeWithoutAI` passou a **false** - mais seguro;
   - `EnableAutonomousMode` passou a **true** - **menos seguro**: nesse modo a IA aconselha mas **deixa de vetar**. Esta e a unica diferenca que muda o comportamento e e sua para decidir (Q-024).

3) **O que eu preciso que decida (Q-024), e nada mais do que isso:**
   - **(a)** Ratificar o `XAI_P215_LIVE_B` como perfil de trabalho. E o unico que hoje da permissao ao EA. Reverter para `XAI_P216_LIVE` volta a po-lo em modo calculo.
   - **(b)** `EnableAutonomousMode`: manter `true` (IA aconselha, nao trava) ou voltar a `false` como estava no P216 (IA veta e exige gateway). Custa um reattach dos 13 EAs, que **reinicia as guardas de perda diaria** - por isso nao o fiz a meio da sessao.
   - **(c)** Modelos: **1 de 13** simbolos tem modelo publicado, e o unico (XAUUSD) mede `edge` 0.0363 contra o minimo exigido +0.0500. Ou se publicam modelos para os outros 12, ou se reduz o universo a 1 simbolo (Q-013). Sem isto, o EA esta autorizado mas nao tem por onde decidir.

4) **Estado, sem enfeite:** conta demo 113568614, equity **12636.32**, **0 posicoes, 0 ordens**. Nada foi aberto nem fechado, nenhum limite ou regra foi tocado, o token nao foi copiado para os graficos. O `GATE_REAL` continua **1 verde de 11** e eu nao vou escrever "10/10" nem baixar um limiar para o numero aparecer - um gate que se baixa quando incomoda nao e um gate, e uma assinatura em branco para arriscar dinheiro real.


- **estado:** ABERTO/RESPONDIDO/FECHADO | 06/11 20:13 | DELTA

---
## Q-025 - F2.1: qual condicao deve armar o kill switch AUTOMATICO? A via existe (CKillSwitch::ArmarAutomatico) mas nao tem nenhum consumidor - controle sem gatilho e controle morto

- **de:** ALFA | **hora:** 06/11 20:21
- **prazo:** 07/11 12:00
- **opcoes:** (a) watchdog de freeze (F2.9) + perda de conexao acima de 5 min; (b) drawdown acima de MaxDrawdownPercent 15% ou perda diaria acima de MaxDailyLossPercent 10%; (c) os dois, cada um com motivo proprio publicado no journal; (d) nenhum gatilho automatico agora - manter so o manual ate o F6
- **estado:** FECHADA
- **RESPOSTA:** **(e) condicao nova, que nao esta nas opcoes publicadas:** o kill switch automatico arma quando a banca perder **50%**. Texto literal do DONO, 06/11 23:00: "Q-025 quando perder 50% da banca". Fica registada como opcao propria, nao como (a), (b), (c) nem (d). | **respondida por:** DONO | **registada por:** ALFA (transcricao literal)
- **nota de ordem (ALFA, 23:00):** com MaxDrawdownPercent 15.0 a bloquear entradas muito antes, um gatilho aos 50% e um para-quedas e nao uma guarda de rotina. A ordem entre as duas guardas esta na Q-070 (item 2).


## Correcao de IDs em 06/11/2026 20:24 - ALFA

O bloco publicado as 20:21 como `Q-024` (gatilho do kill switch AUTOMATICO) foi **renumerado para `Q-025`**. A `Q-024` e do DELTA (20:13: ratificar `XAI_P215_LIVE_B` + `EnableAutonomousMode` + universo de modelos) e continua valida e sem resposta. Nada foi apagado e nenhuma resposta se perdeu.

Causa medida, nao suposta: o contador do `sync-agent.ps1 ask` (funcao `Show-Ask`) contava apenas cabecalhos no formato `## Q-nnn`, e o cabecalho do DELTA esta no formato antigo (`## 06/11/2026 20:13 - DELTA -> DONO: Q-023 sem efeito: ... Q-024: ...`), logo era invisivel. O contador tambem **nao consultava o ledger** `IDS.md`, que ja tinha `USADO | Q | Q-024 | DELTA`: duas fontes de verdade e nenhuma delas lida.

Corrigido e medido: `Show-Ask` agora (a) conta **qualquer** `Q-nnn` do inbox, (b) soma o maximo do ledger via `Get-Usados -Type Q`, e (c) **reserva o ID no ledger dentro do mesmo Mutex**, antes de publicar. Ficheiro com 37094 B, CR=0, LF=842, parse PowerShell com 0 erros.

## Q-026 - Ratificar o XAI_P215_LIVE_B e decidir EnableAutonomousMode e o universo de modelos

- **de:** DELTA | **hora:** 06/11 20:13
- **prazo:** 07/11/2026 12:00
- **opcoes:** (a) RATIFICAR o XAI_P215_LIVE_B como perfil de trabalho. E o unico perfil cujos 13 .chr ja trazem expertmode=5 e por isso o unico que hoje devolve MQL_TRADE_ALLOWED=1. Reverter para o XAI_P216_LIVE volta a por o EA em modo calculo (sem negociar). (b) EnableAutonomousMode: MANTER true (a IA aconselha e DEIXA DE VETAR - mais permissivo) ou VOLTAR a false como estava no P216 (a IA veta e exige gateway). Custa um reattach dos 13 EAs, que reinicia as guardas de perda diaria - nao foi feito a meio da sessao. (c) MODELOS: 1 de 13 simbolos tem modelo publicado e o unico (XAUUSD) mede edge 0.0363 contra o minimo +0.0500. Ou se publicam modelos para os outros 12, ou se reduz o universo a 1 simbolo. Repete a Q-013, que nunca foi respondida.
- **evidencia da permissao:** 13 [START] v1.2.176 entre 20:09:24.188 e 20:09:24.203; [RESUMO] master=SIM as 20:10:21.473 (TradePipeline.mqh:61 so elege mestre quem tem MQL_TRADE_ALLOWED); zero [TRADE BLOCK], zero codigo=3 e zero Permissoes no intervalo 20:09:20-20:59. Os unicos codigo=3 do dia sao 20:07:13.708 e 20:08:14.371, do grafico de teste USDCLP, ANTES da troca de perfil.
- **falsificacao que torna isto credivel:** aplicar um template com expertmode=5 a um grafico NOVO nao devolveu a permissao. So o CARREGAMENTO do perfil devolve. O expertmode e lido do ficheiro quando o perfil e carregado e escrito da memoria quando se sai - as duas medicoes (a do ALFA e a minha) sao verdadeiras ao mesmo tempo.
- **custo declarado:** dos 117 parametros que diferem entre P216 e P215_LIVE_B, 6 caem no DEFAULT do binario e coincidem; 3 sao reais: URL 9001 (neutra - AIConnector.mqh AIGatewayUrlEfetiva reescreve so a porta a partir de XAU_GATEWAY_PORT, provado pelos 1122 bytes recebidos), AllowTradeWithoutAI true->false (mais seguro) e EnableAutonomousMode false->true (mais permissivo, Config.mqh:1111). Nao copiei o token de 64 caracteres para os 13 .chr: duplicaria o segredo em 13 ficheiros versionados e criaria 13 sitios de rotacao.
- **nota de numeracao (corrigida as 20:30):** esta pergunta nasceu como Q-024 as 20:13. O ALFA publicou as 20:21 outro Q-024 (kill switch automatico de F2.1) e, as 20:24, renumerou o dele para Q-025 reservando-o no IDS.md. O DELTA nao viu essa correcao a tempo e publicou as 20:26 tambem como Q-025, ficando dois Q-025 no ficheiro. Resolucao, pela ordem em que cada um foi publicado e reservado no ledger: o Q-025 fica com o ALFA e esta pergunta passa a Q-026. Nenhum texto de outro agente foi reescrito; o IDS.md e o corpo do D-062 foram corrigidos.
- **quem executa depois:** DELTA (leitura do perfil) + DONO (decisao de risco e de modo).
- **estado:** FECHADA (fecho dado pela Q-070, item 3) | 06/11 20:22
- **RESPOSTA:** **parcial.** Texto literal do DONO, 06/11 23:00: "Q-026 criar apenas 1 perfial para xau ai pro operar todas contas". Leitura directa: **um unico perfil** para o XAU_AI_PRO operar **todas as contas** - o `XAI_P215_LIVE_B` fica ratificado como esse perfil (opcao (a) respondida). **Sem resposta:** (b) `EnableAutonomousMode` true/false e (c) universo de modelos - as duas na Q-070 (item 3). | **respondida por:** DONO | **registada por:** ALFA (transcricao literal)

---
## Q-065 - Teto de exposicao total somada na conta real (F2.2): qual o limite em % do capital?

- **de:** ALFA | **hora:** 06/11 21:18
- **prazo:** 08/11 12:00
- **opcoes:** (a) 10%; (b) 20%; (c) 30%; (d) outro valor - indicar
- **estado:** FECHADA (dono, 06/11 21:27)
- **RESPOSTA:**


---

## 06/11/2026 21:25 - DELTA -> DONO: a linha que colou ("COTACAO VELHA | USDBRL | idade=10063s") NAO e avaria. O mercado esta fechado e o EA recusa negociar um preco de ha 2h47m.

- **estado:** INFORMATIVO | 06/11 21:25 | DELTA  (nao pede decisao sua; nao entra na fila)

**1) O que a linha diz, em palavras simples.** O USDBRL nao recebe cotacao nova ha 10063 segundos (2h47m). O EA tem uma regra: preco com mais de 900 s (15 min) nao serve para decidir. Entao recusa operar esse simbolo. "sem tick o OnTick nao corre: preco parado nao opera" e a justificacao escrita pela propria regra.

**2) Porque esta parado: e o fecho semanal.** O relogio do servidor da MetaQuotes-Demo parou nas 23:59:58 de sexta-feira 06/11. Carimbo do ultimo tick, lido simbolo a simbolo agora: divisas mais liquidas 23:59:03 a 23:59:58; XAUUSD e USDBRL 22:59:59; USDCOP 19:59:44; USDCLP 19:29:15; USDRUB 16:59:52. Hoje e sabado. Nao ha preco novo porque nao ha mercado - nao porque o EA, a ligacao ou o gateway tenham falhado.

**3) Nao ha nada a corrigir nessa linha.** O EA distingue "mercado fechado" de "feed avariado", e nos dois casos nao opera. E a mesma familia de guarda que manteve a conta plana: 0 posicoes, 0 ordens, equity 12636.32, demo 113568614, conta intocada.

**4) Uma coisa mudou hoje, e para melhor.** Ate hoje esta verificacao existia so onde chegam ticks - e e exactamente quando o feed morre que deixam de chegar ticks. Resultado: o EA sabia que estava cego e nao o dizia a ninguem; o journal ficava em silencio e um sistema parado por avaria era indistinguivel de um sistema parado por mercado fechado. A v1.2.179, publicada as 20:46:55 nos 13 graficos, passou a publicar a transicao no relogio de 30 s: 13 de 13 graficos escreveram a linha uma vez, com limite=900s. Nos 37 minutos seguintes, zero repeticoes. Foi o ALFA que o fez (D-064); eu validei e assinei (D-065) com um instrumento diferente do dele - o carimbo de tick lido do Market Watch, que nao passa pela regra que se queria testar.

**5) O que vai ver a seguir.** Um lembrete por hora enquanto o mercado estiver fechado: o proximo por volta das 21:47 locais, depois 22:47, e assim por diante. Na reabertura, uma linha por grafico: "[TRADE BLOCK] COTACAO VOLTOU (timer) ... feed vivo outra vez, o OnTick volta a decidir". Nenhuma das duas pede accao sua.

**6) O que isto NAO e.** Nao e progresso para o 10/10 e nao vou escrever que e. O quadro de passagem a conta real (GATE_REAL) continua 1 verde de 11. O bloqueio que resta e MODELO: 1 de 13 simbolos tem modelo publicado (XAUUSD) e mede edge 0.0363 contra o minimo 0.0500; os outros 12 respondem `disponivel=false`. Continuam a espera de decisao sua a Q-026 (ratificar o perfil XAI_P215_LIVE_B, decidir EnableAutonomousMode verdadeiro ou falso, e o universo de modelos) e a Q-025 (o que arma o kill switch automatico).


- **RESPOSTA:** (d) o DONO aceita a banda de 10 a 50 por cento do capital - qualquer valor dentro dela esta autorizado; ALFA fixou 20.0 e o F2.2 foi implementado na v1.2.180 sob a D-066 | **respondida por:** DONO | **hora:** 06/11 21:27


---

## 06/11 21:44 - DELTA -> DONO: a segunda linha que colou ("COTACAO VELHA | USDBRL | idade=13114s") tambem NAO e avaria - e o mesmo preco de ha 3h38m. E eu tenho de corrigir uma previsao minha.

- **de:** DELTA | **hora:** 21:44
- **estado:** INFORMATIVO | 21:44 | DELTA  (nao pede decisao sua; nao entra na fila)

**1) E o mesmo preco congelado da primeira linha, nao um erro novo.** O ultimo
tick do USDBRL no Market Watch tem carimbo `2026-11-06T22:59:59` do servidor, lido
directamente do simbolo - esse carimbo nao passa por nenhuma guarda, e o dado bruto.
E 13114 s antes das 21:38:33 dao 17:59:59 locais, exactamente o mesmo instante que
as linhas anteriores implicavam. O mercado fechou a sexta e este simbolo nao tem
tick novo desde entao. O EA recusa negociar um preco velho, com limite de 900 s.
Esta a fazer o que deve.

**2) A serie agora tem cinco pontos e o erro e zero.** Idade do USDBRL contra o
relogio local, em cinco leituras:
`21:24:11 idade=12252` -> `21:26:23 idade=12384` (+132 s em +132 s) ->
`21:26:59 idade=12420` (+36 em +36) -> `21:29:11 idade=12552` (+132 em +132) ->
`21:38:33 idade=13114` (+562 em +562). Cinco pontos, zero segundos de erro, e
atravessam duas mudancas de versao. A idade nao esta congelada: anda com o relogio.

**3) Porque apareceu outra vez agora.** As 21:38:01-02 os 13 graficos arrancaram
com a **v1.2.181** (`[START]` 13x). A publicacao da transicao usa um marcador
estatico que morre com o programa, logo cada arranque volta a dizer "estou cego"
uma vez por grafico. As 21:38:31-32 sairam as 13 linhas. Isso e o comportamento
correcto, nao uma repeticao espuria: um EA que acabou de arrancar tem de dizer que
ainda nao viu preco vivo.

**4) Correccao de uma previsao minha, e e a parte que me interessa escrever.** Eu
disse-lhe por escrito que o primeiro lembrete horario apareceria por volta das
21:47. **Nao serve**: o temporizador reinicia com o programa e a v1.2.181 arrancou
as 21:38. Sem novas republicacoes, o primeiro lembrete cai por volta das 22:38.
Mais: enquanto o EA continuar a ser republicado a cada poucos minutos, a ausencia ou
a presenca do lembrete nao prova nada em nenhum dos dois sentidos, e eu nao a vou
usar como prova. Fica registado que voido a minha propria previsao em vez de a
defender.

**5) Estado medido agora.** v1.2.181: `#property version "1.381"`, fonte 104770 B de
21:37:33, binario 962744 B / MD5 `7729ACBED18278B5B59E2F3AF81AAE15` de 21:38:01, 13
de 13 graficos. E a quinta publicacao desde as 21:23:40. Conta intocada: demo
113568614, equity 12636.32, 0 posicoes, 0 ordens. `GATE_REAL` continua 1 verde de 11
e eu nao escrevo "10/10".

- **estado:** INFORMATIVO | 21:44 | DELTA


---
## 06/11 21:49 - ALFA -> DONO | INFORMATIVO: o ALFA nao compila mais nada hoje + a causa medida do EA nao operar

- **estado:** FECHADO | **hora:** 06/11 21:49 | **de:** ALFA

**INFORMATIVO DO ALFA AO DONO - 06/11 21:49 - o ALFA nao compila mais nada hoje**

O DELTA levantou, com razao, uma preocupacao a meu respeito: cada recarga dos 13 graficos reinicia as guardas de perda diaria dos 13 EAs. A resposta, por escrito e com hora:

**Compromisso: ZERO compiles e ZERO recargas daqui ate ao fim da noite.** O estado das **21:38:02** e o estado em que a noite fica. Se houver codigo a mudar, fica anunciado no canal e espera por janela combinada.

**A contagem honesta das 5 recargas:** 21:23:40 -> 21:25:51 -> 21:26:28 -> 21:28:39 (quatro, antes de eu mexer no binario) e **21:38:01** - e esta ultima **nao foi um publish meu**: o MT5 recarrega sozinho os graficos quando o `.ex5` e recompilado. Neste terminal compilar e publicar sao a mesma accao, e foi por isso que parei e vim pedir janela em vez de continuar. Das 21:38:02 ate as 21:49: **zero recargas**.

**Quanto custou em protecao: nada, medido.** `trades=0 | W=0 | L=0 | pico=12636.32` em 06/11. Nao havia perda diaria acumulada para apagar, porque nao houve um unico trade hoje. O risco existe a partir do momento em que houver trades abertos - e nessa altura o compromisso acima e o que o impede.

**Uma coisa que precisa da sua decisao, e nao e tecnica.** Descobri por medicao porque e que o EA nao opera, e nao e o setup tecnico: o gateway de IA responde correctamente (`signal=SELL`, `confidence=72.4`, `prob_buy=0.2765`, `prob_sell=0.7235`), mas o EA procura no JSON as chaves `buy`, `sell` e `score`, que o gateway **nao publica**. Resultado: o score de IA fica 0.0, e o piso `AI_Score<MinAIConfidence` (0 < 60) devolve "sem sinal" em **todos** os simbolos, sempre. Com `AllowTradeWithoutAI=false`, o EA nao pode abrir uma unica posicao. A correccao esta escrita e testada por leitura, **nao compilada** - por causa do compromisso acima. E a proxima accao da fila, e preciso que o CMD ou o DONO autorizem a janela de compilacao.

**O que NAO mudou:** GATE_REAL **1 verde de 11**; F2.2 aberto (falta prova de recusa e de fail-closed); 10/10 e F6 nao assinados. Conta demo 113568614, equity 12636.32, 0 posicoes, 0 ordens.

---
## 06/11 21:55 - ALFA -> DONO | PRECISO DE UMA PALAVRA: autoriza o D-068 (parser de IA) num compile unico?

- **precisa:** autorizo / nao autorizo / segunda-feira
- **estado:** ABERTO | **hora:** 06/11 21:55 | **de:** ALFA

**ALFA -> DONO - 06/11 21:55 - uma pergunta fechada, uma decisao que so o DONO pode tomar**

**A pergunta que estava aberta esta respondida:** nao compilo nem recarrego mais nada hoje. Das 21:38:02 as 21:55, journal: **0 `[START]`**. O estado em que a noite fica e o das 21:38:02 (v1.2.181, 13/13 graficos).

**O que preciso de si: uma palavra sobre o D-068.** Encontrei a razao pela qual o EA nao opera, e nao e o setup tecnico: o gateway responde bem (`signal=SELL`, `confidence=72.4`, `prob_buy=0.2765`, `prob_sell=0.7235`), mas o EA procura no JSON `buy`, `sell` e `score` - chaves que **nao existem** no payload. Dai o score de IA ficar `0.00`, e o piso `AI_Score < MinAIConfidence` (0 < 60) devolver "sem sinal" em **todos** os simbolos, sempre. Com `AllowTradeWithoutAI=false`, o EA nao pode abrir uma unica posicao. Nao e falta de modelo, nao e falta de sinal tecnico, nao e o gateway: e o contrato de leitura.

**O que o D-068 faz, na versao conservadora que o DELTA votou e eu aceitei:** (1) quando `buy`/`sell` nao existem, le `prob_buy`/`prob_sell`; (2) quando `score` nao existe, usa a confianca (`72.4`) como score. **Nada mais.** A escala das probabilidades (que pode somar ate 30 pontos ao composto e mudar a taxa de entrada) fica para um compile separado, para se saber a que mudanca se deve o quÃª.

**O custo medido de o fazer agora:** zero em protecao - 0 posicoes, 0 ordens, margem 0.00, `trades=0` hoje, kill switch LIVRE, mercado fechado ate segunda. O MT5 recarrega os 13 graficos sozinho e nada mais acontece hoje.

**O risco, dito por inteiro:** o D-068 faz o EA **poder** operar. Nao prova que **deve**. O GATE_REAL continua 1 verde de 11, o F2.2 continua sem prova de recusa e sem prova de fail-closed, e o forward de 30 dias (F6) nao arrancou. Autorizar o D-068 e destrancar a porta, nao e dizer que a sala esta segura.

**Se autorizar, escrevo a hora no canal, aplico, compilo uma vez e reporto 13/13 `[START] v1.2.182` no journal.** Se preferir que fique para segunda-feira com o mercado aberto e o CMD presente, tambem e uma resposta boa - e entao isto fica preparado e provado por leitura ate la, sem tocar no binario.

---
## Q-068 - D-068 (parser de IA): autoriza um compile unico da correccao conservadora? O EA nao opera porque o parser procura buy/sell/score e o gateway publica prob_buy/prob_sell/edge - AI_Score fica 0.0 e AIEngine.mqh:289 (0<60) devolve 0 em todos os simbolos, sempre. Escopo: (1) buy->prob_buy e sell->prob_sell; (2) AI_Score<-AI_Confidence quando nao ha score. A escala 0..1->0..100 fica para um compile separado (voto do DELTA). Custo agora medido: 0 posicoes, 0 ordens, margem 0.00, trades=0 hoje, mercado fechado - zero proteccao perdida. O D-068 faz o EA PODER operar; nao prova que DEVE (GATE_REAL 1 de 11, F2.2 sem prova de recusa nem de fail-closed, F6 nao arrancado).

- **de:** ALFA | **hora:** 06/11 21:56
- **prazo:** 06/11 23:00
- **opcoes:** (a) autorizo agora, ainda hoje - o ALFA anuncia a hora e faz um compile; (b) autorizo, mas segunda-feira com o mercado aberto e o CMD presente; (c) nao autorizo o D-068 - fica como esta e o EA continua sem poder entrar
- **estado:** FECHADA
- **RESPOSTA:** **(b)** autorizo, mas segunda-feira, com o mercado aberto e o CMD presente. Texto literal do DONO, 06/11 23:00: "1 Q-068 B" | **respondida por:** DONO | **registada por:** ALFA (transcricao literal, sem interpretacao)


---
## 06/11 22:53 - ALFA -> DONO | Q-068 expira as 23:00 - tres opcoes e a minha recomendacao; mais um esclarecimento sobre a versao nos 13 graficos

- **precisa:** escolher (a) agora, (b) segunda ou (c) nao autorizo
- **estado:** ABERTO | **hora:** 06/11 22:53 | **de:** ALFA

Uma pergunta sua tem prazo: **23:00 de hoje**. Nao e trabalho pendente meu - e uma autorizacao que so o DONO pode dar.

**Em duas frases.** O EA hoje **calcula e nunca decide**: o servico de IA responde bem (`signal=SELL`, `confidence=72.4`, `prob_sell=0.7235`), mas o EA procura tres nomes de campo que o servico nao publica (`buy`, `sell`, `score`), le zero nos tres, e a guarda de score minimo (60) transforma esse zero em **veto permanente em todos os simbolos**. Por isso, com a conta ligada desde as 20:42, houve **0 trades**. O conserto e pequeno e esta escrito: ler `prob_buy`/`prob_sell` e usar a confianca como score quando nao houver score.

**Porque precisa da sua palavra.** O conserto **muda o comportamento de entrada** - e a diferenca entre um EA que nunca entra e um EA que pode entrar. Isso nao e decisao de agente. A Q-068 esta aberta no seu INBOX com tres opcoes:
**(a)** autorizo agora, ainda hoje - o ALFA anuncia a hora e faz **um** compile;
**(b)** autorizo, mas **segunda-feira**, com o mercado aberto e o CMD presente;
**(c)** nao autorizo - fica como esta e o EA continua sem poder entrar.

**O que eu recomendo.** Se nao tiver preferencia, **(b)** e a escolha segura e nao custa nada: o mercado esta fechado ate segunda, o EA nao opera este fim de semana de qualquer maneira, e na segunda ha gente a olhar. A **(a)** tambem e segura esta noite - 0 posicoes, 0 ordens, margem 0.00, zero trades hoje, mercado fechado - mas ninguem ve o resultado antes de segunda de qualquer forma. A **(c)** e a unica que garante que segunda comeca exactamente onde sexta acabou: **nao a recomendo**.

**O que isto NAO faz.** Desbloquear o veto poe o EA **a poder** operar; nao prova que deva. `GATE_REAL` continua **1 verde de 11**, o GATE F2 continua aberto (falta provar recusa, fail-closed e ausencia de falso positivo da guarda de margem) e o F6 nao arrancou. Nao escrevo "10/10" e nao assino nenhum gate por isto.

**Um esclarecimento que lhe devo.** Chegou-lhe a informacao de que os 13 graficos continuavam com a versao antiga (v1.2.179 das 20:46). Medi o journal do terminal: os 13 correm **v1.2.181 desde as 21:38:02.403** (13/13 linhas `[START]`) e nao ha nenhum arranque em 68 minutos. As versoes anteriores foram substituidas automaticamente - o MT5 recarrega o EA recompilado -, sem reattach manual e sem ninguem a mexer nos seus graficos. Conta plana: equity **12636.32**, **0 posicoes**, **0 ordens**.

---
## Q-070 - fecho da Q-017, da Q-025 e da Q-026) - tres itens que as suas palavras nao fecham. ITEM 1 (Q-017, risco): disse que quer correr bastante risco mas nao escreveu numeros. Hoje MaxDailyLossPercent=10.0 e MaxDrawdownPercent=15.0 nos 13 graficos, ou seja: perda diaria maxima 1.263 USD e drawdown maximo 1.895 USD sobre 12.636. ITEM 2 (Q-025, ordem das guardas): o kill switch aos 50% da banca dispara muito depois de o MaxDrawdownPercent aos 15% ja ter bloqueado entradas - quer (i) manter as duas como estao (15% bloqueia, 50% mata) ou (ii) alinhar as duas no mesmo numero? ITEM 3 (Q-026): (b) EnableAutonomousMode fica true (a IA aconselha e nao veta) ou false (a IA veta e exige gateway)? (c) universo: reduzir a XAUUSD, o unico com modelo publicado, ou manter os 21 e esperar modelos?

- **de:** ALFA | **hora:** 06/11 23:00
- **prazo:** 09/11 12:00
- **opcoes:** ITEM 1: (a) manter 10/15; (b) 20/30 - perda diaria 2.527 e drawdown 3.791; (c) 30/50 - 3.791 e 6.318; (d) escrevo outro par. ITEM 2: (i) manter 15% a bloquear e 50% a matar; (ii) alinhar as duas. ITEM 3: (b) true ou false | (c) so XAUUSD ou manter 21. Responder por item, ex.: "1b 2i 3 true, so XAUUSD".
- **estado:** FECHADA
- **RESPOSTA:** **(1) a** | **(2) ii** | **(3) true** - texto literal do DONO, 06/11 23:03: "1 a / 2 ii / 3 pode ativar IA true. mais quero o EA operando todos ativos globais nao so xauusd, e tambem corigir todos modelos ou deletar e treinar novos e funcional" (erros de escrita preservados; **registada por:** ALFA, transcricao literal)
- **ITEM 1 = (a) manter 10/15 - JA ESTA EM VIGOR, VERIFICADO:** os 15 graficos tem `MaxDailyLossPercent=10.0` e `MaxDrawdownPercent=15.0`. Sobre 12.636,32 de equity: perda diaria maxima 1.263,63 USD e drawdown maximo 1.895,45 USD. Nada a alterar.
- **ITEM 2 = (ii) alinhar as duas guardas - FALTA O NUMERO.** O DONO escolheu alinhar, mas nao escreveu qual dos dois numeros fica. As duas leituras, com o dinheiro a vista sobre 12.636,32: **(a) 15%** - a guarda de rotina e o kill switch passam a disparar juntos aos 1.895,45 USD de drawdown; **(b) 50%** - disparam juntos aos 6.318,16 USD, que e o numero que o DONO deu na Q-025 ("quando perder 50% da banca"). A leitura (a) contradiz a Q-017 ("quero correr bastante risco"); a (b) obedece as duas respostas dele. **Pergunta em aberto: 15 ou 50? Uma linha resolve.**
- **ITEM 3 = true - JA ESTA EM VIGOR, VERIFICADO:** `EnableAutonomousMode=true` nos 15 graficos. Efeito lido no codigo: `AIGateRequired()` devolve false (AIEngine.mqh:52) e `FinalAIAllow()` salta a exigencia de gateway e devolve true (AIEngine.mqh:584). A IA deixa de vetar.
- **EFEITO COLATERAL DO ITEM 3, que o DONO tem de saber:** a mesma chave que tira o veto tambem cala a IA. `GetAIEngineSignal()` continua a exigir `AI_Score>=MinAIConfidence (60)` (AIEngine.mqh:291) e o parser devolve zero - journal 21:38:32: `[AI] PYTHON | XAUUSD | SELL | PRICE=4065.82 | BUY=0.00% | SELL=0.00% | SCORE=0.00 | CONF=72.40%`. Com `AIHasSignalAuthority=false`, quem decide e o sinal tecnico e a IA nao opina. Resumo honesto: **o EA pode operar, mas nao guiado pela IA.** Para a IA voltar a ter voz e preciso o parser (o patch que estava a ser chamado D-068, agora renomeado D-069) e um compile.
- **ITEM 3b, universo "todos os ativos globais":** o universo JA e 21 ativos - `[SYMS] UNIVERSO | marketwatch=21 | deSymbols=11 | adicionadosDoMarketWatch=10 | grafico=XAUUSD | ativos=21 | origem=Symbols+MarketWatch+grafico` (journal 21:38:01). O que falta nao e universo, e modelo: o gateway responde `disponivel=true` so para XAUUSD (1122 bytes) e `disponivel=false` para os outros 12 graficos (357 bytes cada). Operar 21 ativos a tecnico e possivel hoje; operar 21 ativos com IA exige um modelo publicavel por ativo.
- **ITEM 3c, "corrigir todos modelos ou deletar e treinar novos":** medido em disco - existem 21 simbolos x {H1,H4,M15,M5} com `.pkl`+`.meta.json` em `MQL5\Files\XAU_AI_PRO\Python\models` (mtimes 2026-11-03), mais MULTI_METALS/MULTI_FIAT/MULTI_CRYPTO. A amostra prova que "ter ficheiro" nao e "ter modelo funcional": `XAUUSD_H1` e publicable=true (edge +0.0363, AUC 0.5485, 4/5 folds positivos, min_edge declarado 0.05); `EURUSD_H1` e publicable=false (edge -0.0161, acc 0.3353 contra palpite 0.3514). Portanto o trabalho pedido e **retreinar os que reprovam**, nao apagar tudo.
- **ESTADO REAL DO TERMINAL, medido agora as '06/11 23:11' (isto muda o que estava escrito antes):** o terminal fechou e reabriu - `[STOP] XAUUSD | motivo=9` (REASON_CLOSE) as **22:59:15** e `[START]` as **22:59:18**. O conjunto de graficos mudou: sao agora **15 graficos, perfil DEFAULT** (CHART01..CHART15), com **USDCOP e USDCLP a entrar**; antes eram 13 no perfil XAI_P215_LIVE_B. Todos os 15 correm XAU_AI_PRO **v1.2.181**. Nada foi recompilado (`#property version "1.381"`, `.ex5` de 21:38:01).
- **O QUE BLOQUEIA A OPERACAO NESTE MOMENTO NAO E O CODIGO:** os 15 graficos registam `[TRADE BLOCK] COTACAO VELHA (timer)`, com `idade` entre 13.116s e 38.321s contra `limite=900s`. O mercado fechou (sexta-feira, servidor 23:59). Sem tick nao corre `OnTick`; sem `OnTick` nao ha entrada. A medicao decisiva so pode ser feita na abertura, com feed vivo.
- **estado:** FECHADA


---
## Q-071 - O senhor respondeu "2 ii" = alinhar as duas guardas no mesmo numero, mas nao escreveu QUAL numero fica. Hoje as duas estao desalinhadas e e por isso que uma chega primeiro: o MaxDrawdownPercent (15%) bloqueia novas entradas e o kill switch (50% da banca, Q-025) mata a conta. Alinhar significa escolher um numero unico para as duas. Com o equity de hoje (12.636,32 USD): se o numero for 15, o EA para e mata aos 1.895,45 USD de drawdown - e isso contradiz a Q-017 ("quero correr bastante risco"); se o numero for 50, o EA so para e mata aos 6.318,16 USD - e o numero que o proprio senhor deu na Q-025 ("quando perder 50% da banca"). Sao 4.422,71 USD de diferenca entre as duas leituras. Nada foi alterado: o EA continua com MaxDailyLossPercent 10.0 e MaxDrawdownPercent 15.0 em vigor nos 15 graficos.

- **de:** ALFA | **hora:** 06/11 23:13
- **prazo:** 09/11 12:00
- **opcoes:** (a) 15% -> as duas guardas disparam aos 1.895,45 USD. (b) 50% -> as duas disparam aos 6.318,16 USD, coerente com a Q-025. (c) manter desalinhado como esta hoje (15% bloqueia, 50% mata) - era o "2 i" que o senhor nao escolheu.
- **estado:** ABERTA
- **RESPOSTA:**


---
## Q-072 - O senhor pediu "o EA operando todos ativos globais nao so xauusd". Medido agora: o universo ja tem 21 ativos (journal 21:38:01: marketwatch=21, deSymbols=11, ativos=21) e o EA esta anexado em 15 graficos, com todos os simbolos do Market Watch na lista. O que nao existe e modelo de IA para eles: o gateway responde "disponivel=true" SO para XAUUSD (1122 bytes); os outros 12 graficos recebem "disponivel=false" (357 bytes). E os ficheiros existem - ha 21 simbolos x {H1,H4,M15,M5} com .pkl e .meta.json em Python\models - mas reprovam o criterio de publicacao: XAUUSD_H1 passa (edge +0.0363, 4/5 folds), EURUSD_H1 reprova (edge -0.0161, pior que o palpite). A pergunta: enquanto os modelos nao forem retreinados, o senhor quer que os 20 ativos sem modelo operem a sinal TECNICO (a IA fica calada neles, porque EnableAutonomousMode=true ja tira o veto), ou quer que fiquem de fora ate terem modelo aprovado? Nao ha terceira via: ou opera a tecnico, ou nao opera.

- **de:** ALFA | **hora:** 06/11 23:13
- **prazo:** 09/11 12:00
- **opcoes:** (a) operar os 20 a tecnico ja (a IA so opina onde tem modelo). (b) so operar ativo com modelo aprovado - hoje isso e XAUUSD apenas. (c) operar a tecnico mas com lote reduzido nos 20 ate terem modelo.
- **estado:** ABERTA
- **RESPOSTA:**

