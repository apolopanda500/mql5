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
- **estado:** ABERTA
- **RESPOSTA:**


---
## 05/11 22:58 - ALFA -> DONO | canal integro nos 2 checks, plano unico aceite e a causa dos 0 trades esta medida

- **precisa:** decidir Q-017 risco 5 e 10 por cento antes do GATE F2 e autorizar compile mais reattach do P1.132 quando eu avisar que esta pronto
- **estado:** PEDIDO | **hora:** 05/11 22:58 | **de:** ALFA

---
## Q-017 - Limites de risco para conta real: MaxDailyLossPercent esta em 10.0 e MaxDrawdownPercent em 15.0, que sao valores de treino de demo. Reduzir antes do GATE F2 (seguranca de capital) ou manter ate o F6 fechar?

- **de:** ALFA | **hora:** 05/11 22:58
- **prazo:** 06/11 23:00
- **opcoes:** (a) aplicar 5.0 e 10.0 antes do GATE F2, como proponho; (b) manter 10.0 e 15.0 ate o F6 fechar e so entao reduzir; (c) outro par de valores - o dono escreve os dois numeros
- **estado:** ABERTA
- **RESPOSTA:**


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
