# PROTOCOLO DO CICLO 10/10 - como fechamos o projeto

Status: proposta do DELTA em 06/11/2026 23:40, sob **D-070**. Ratificacao: DONO.
Ack obrigatorio: ALFA e CMD (regra 14). Enquanto nao houver ack, o protocolo vale para quem o escreveu.
Regra de leitura: se um numero aqui divergir do que o comando mede, **o comando vence** - corrige-se o numero, nao o comando.

---

## 1. O que "10/10" significa (e o que nao significa)

Definicao operacional, unica aceita neste ciclo:

1. `GATE_REAL` com **11 de 11** criterios verdes, cada um com prova positiva **e** prova negativa;
2. **30 dias de forward em DEMO** sem intervencao manual, com os criterios da regra 10;
3. **autorizacao escrita do DONO** para conta real.

10/10 nao e rotulo, e resultado de medicao. Nenhum agente escreve "10/10", "pronto", "F2 verde" ou "100%" antes de 11/11 medido. Quem escrever e reprovado na auditoria do dia e o texto e corrigido no mesmo dia, com a hora da correcao.

Medido hoje (06/11 22:49): **1 verde de 11** (G2). Isso nao muda por plano; muda por prova.
O EA pode e deve operar em **DEMO** muito antes de 10/10. 10/10 e a condicao de REAL, nao a de teste.

---

## 2. Reorganizacao da EQUIPE - uma responsabilidade, uma mao

| Agente | Papel neste ciclo | Escreve em | NAO escreve em | Quem assina a entrega |
|---|---|---|---|---|
| **ALFA** | DONO DO CODIGO DO EA - unica mao que edita e compila o EA | `Experts/XAU_AI_PRO/**`, `AI/**`, `Core/**`, `Indicators/**`, `SignalCore`, modelos de IA | canal `EQUIPE/*.md`, `Tools/**`, git | DELTA |
| **CMD** | INTEGRADOR - unica mao que faz commit, push, deploy e infra | `app/`, `backend/`, `Tools/**`, `EQUIPE/QUADRO_ESTADO.md`, `EQUIPE/PLANO_10_10.md`, git/CI/instalador/gateway | `Experts/**`, `AI/**`, `Core/**`, `Indicators/**` | DELTA |
| **DELTA** | MEDIDOR E AUDITOR - mede, prova, assina ou recusa | `Monitoring/**`, dossies de medicao, relatorio diario, este protocolo | codigo do EA, git, `QUADRO_ESTADO.md`, `PLANO_10_10.md` | DONO (leitura) |
| **DONO** | DECISOR - responde Q, autoriza risco e conta real | perguntas e autorizacoes | qualquer arquivo de codigo | - |

Canal (`EQUIPE/*.md`): escrito por todos, **sempre** sob `LOCK.md`, nunca por dois ao mesmo tempo.
`DECISOES.md` e append-only: qualquer agente escreve, mas **so depois de reservar o ID em `IDS.md`**.
Regra de ouro: se um trabalho precisa de duas maos, ele e **duas entregas com dois IDs**, nao uma entrega com duas assinaturas.

Corrente do ciclo, em uma frase:
**DONO decide -> ALFA escreve o codigo -> CMD entrega (commit/push/deploy) -> DELTA mede e assina -> DONO autoriza REAL.**

---

## 3. As cinco faixas de trabalho (e o dono de cada uma)

| Faixa | Conteudo | Dono | Mede |
|---|---|---|---|
| **L1 Codigo do EA** | parser (D-068), F2.2 provas, G8 shorts, handles de ATR, kill switch automatico | ALFA | DELTA |
| **L2 Dados e IA** | modelos para os 20 simbolos sem modelo, edge minimo, disponibilidade do gateway | ALFA + CMD | DELTA |
| **L3 Infra e entrega** | gateway como servico, build, instalador, CI, git, deploy | CMD | DELTA |
| **L4 Medicao e gates** | GATE_REAL 11 criterios, provas negativas, dossie, auditoria diaria do canal | DELTA | DONO |
| **L5 Operacao forward** | 30 dias em demo, relatorio diario, criterios de aprovacao | DONO decide, DELTA mede | - |

Nenhuma faixa avanca por narrativa: avanca por prova anexada.

---

## 4. Fases do ciclo (calendario)

| Fase | O que fecha | Inicio | Fim previsto | Portao de saida |
|---|---|---|---|---|
| **F0 Saneamento** | canal sem contradicao, contadores alinhados, IDs reservados, `check` 0 problemas | 06/11 23:40 | 07/11 12:00 | `check` 0 problemas + ack dos 3 agentes |
| **F1 Parser (D-068)** | EA consegue DECIDIR (hoje nao decide: `AI_Score=0.0` sempre) | 07/11 | 09/11 antes da abertura | compile unico 0/0 + `[AI] PYTHON` com BUY/SELL nao nulos + `[START]` da versao nova |
| **F2 Guardas provadas** | F2.9 (5 de 6 falhas em falta), F2.2 (recusa, fail-closed, falso-positivo), kill switch automatico | 09/11 | 20/11 | 3 provas por guarda, com hora e recusa observada |
| **F3 Dados e IA** | modelos para os 20 simbolos OU decisao de operar a tecnico neles | 09/11 | 27/11 | modelo publicado com edge >= +0.0500, ou Q respondida pelo DONO |
| **F4 Forward 30 dias** | o EA operando em demo, medido todos os dias | no dia em que F1 fechar | +30 dias de calendario | criterios da regra 10 |
| **F5 GATE_REAL 11/11** | os 11 criterios verdes com historico | fim de F4 | - | dossie final + assinatura do DELTA |
| **F6 REAL** | conta real | apos F5 | - | autorizacao escrita do DONO |

F2, F3 e F4 correm em paralelo. F1 e a unica fase com prazo duro, porque sem ela o EA nao decide e nenhuma outra fase produz dado real.

---

## 5. Regras de evidencia - o que conta como prova

1. Toda afirmacao numerica leva **valor + hora + de onde veio** (comando e saida, ou `arquivo:linha`). Sem isso e opiniao, e opiniao nao fecha gate.
2. Toda trava tem **prova positiva e prova negativa**: o caso que deveria reprovar tem de reprovar. Um teste que so passa nao prova que a guarda funciona.
3. "Nao medido" e resposta valida; "deve funcionar" nao e.
4. Numero que nao se repete nao e identidade. **MD5 de `.ex5` nao e identidade de build** (build 6306 nao e reprodutivel: mesmo fonte e mesma versao deram 961058 / 961746 / 961800 bytes). Identidade = versao declarada + estado da fonte + log 0 errors 0 warnings + hora.
5. Nunca "identidade vigente": escreve-se **"ultima observacao as HH:MM:SS"**.
6. Percentual sem denominador nao entra no canal: "0% de shorts" tem de vir com "0 de N".
7. Duas fontes discordando do mesmo nome e defeito do **consumidor**, nao do produtor: antes de acusar o servidor, leia quem le o campo.

---

## 6. Ritual diario (cadencia obrigatoria)

Ate 21:00 local, **cada agente** publica 6 linhas fixas no seu INBOX + 1 linha no `SYNC_LOG.md`:

```
1. FEITO HOJE: <item> - prova: <numero/hora/arquivo:linha>
2. NAO FEITO: <item> - porque: <motivo>
3. BLOQUEIO: <item> - dependo de: <agente/DONO/Q-nnn>
4. NUMEROS: conta=<saldo/equity> posicoes=<n> ordens=<n> gates=<x de 11> ex5=<tamanho hora>
5. AMANHA: <1 a 3 itens>
6. PEDIDO AO DONO: <Q-nnn aberto | nenhum>
```

- `equipe-sync.ps1 check` **2x/dia**: ALFA 09:00, CMD 15:00, DELTA 21:00. O resultado vai para o `SYNC_LOG`. **Canal com problema para o trabalho** daquele agente ate fechar.
- Uma escrita = um `LOCK`, TTL 15 min, LF puro (sem CR), corpo em ASCII.
- **Auditoria**: DELTA le o canal 1x/dia e reprova, com medida na mao, qualquer alegacao sem prova. Reprovar nao e opiniao: vem com o numero ao lado.

---

## 7. Definition of Done - por entrega (as 6 condicoes)

Uma entrega so fecha com as seis:

1. escrito na zona do dono (codigo ou documento);
2. **compila 0 errors 0 warnings** (quando e codigo) - log anexado;
3. **provas** positiva e negativa, com hora;
4. **commit + push** declarando autor e conteudo (CMD);
5. **anotacao no canal**: ID reservado em `IDS.md`, bloco em `DECISOES.md`, aviso no INBOX do destinatario, linha no `SYNC_LOG`;
6. **assinatura do DELTA** ou recusa escrita com motivo.

Faltando uma, o item esta **aberto**. Nao existe "quase pronto", "implementado mas nao provado" contando como feito, nem "publicado" sem `[START]` medido.

---

## 8. Regra do compile unico

- **Um compile por janela**, anunciado no canal com hora, versao e motivo, com o log 0/0 anexado.
- Duas mudancas no mesmo compile = efeito nao atribuivel. Se precisa de duas, sao **dois compiles em duas janelas** (foi o motivo do voto conservador no D-068).
- Depois do compile, reattach e acao de producao: quem faz, anuncia; a prova e o `[START]` com a versao nova nos 13 graficos.
- Ja aconteceu 4 compiles em 9 minutos e o binario mudar 4 vezes: isso nao e velocidade, e falta de prova. Neste ciclo, cada janela tem uma versao e uma hora.

---

## 9. Regra do deploy

Deploy so acontece com, nesta ordem:

1. compile 0/0 + log;
2. CI verde no repositorio;
3. provas no canal (positiva + negativa);
4. `equipe-sync.ps1 check` = 0 problemas;
5. registro do deploy: versao, hora, hash do artefato, graficos afetados, `[START]` medido.

Quem **publica** e o CMD. Quem **aprova** e o DELTA. Quem **autoriza producao real** e o DONO.

---

## 10. Os 30 dias de forward - a parte que endurece

Objetivo: sair de "1 verde de 11" para "11 verdes com historico", **em DEMO**.

- **Janela**: 30 dias de calendario a contar do primeiro dia em que o parser estiver corrigido e o EA decidir.
- **Amostra minima**: 100 trades. Menos que isso, o numero nao vale como aprovacao.
- **Medicao diaria (DELTA)**: trades, acerto, fator de lucro, drawdown maximo, expectancia, disponibilidade da IA, bloqueios por motivo, desvio de relogio, intervencoes manuais (meta: 0).
- **Criterios de aprovacao** (proposta do DELTA; o numero final e do DONO, e ja existe Q-016 no canal com PF>=1.2 e DD<=8%):
  - fator de lucro >= **1.2**
  - drawdown maximo <= **8%**
  - >= **100 trades**
  - disponibilidade de IA >= **95%** dos polls
  - **zero** bloqueio sem motivo publicado no journal
  - **zero** alteracao de parametro ou codigo durante a janela
- Se reprovar, **repete a janela**. Nao se "ajusta" o criterio para passar. Ajustar criterio para ficar verde e o unico defeito que reprova um agente em definitivo.
- Correcao de seguranca obvia: pausa a janela, corrige, reinicia a contagem do dia 1. Sem excecao.

---

## 11. Escalonamento e paragem

Parar tudo e chamar o DONO quando:

- o canal reprovar **2x na mesma hora**;
- um numero publicado **nao reproduzir** na medicao seguinte;
- houver risco de ordem real sem autorizacao;
- o desvio de relogio passar de **60 s** em qualquer calculo de idade de cotacao;
- algum agente quiser fechar gate **sem prova**.

Quem para: **DELTA** (auditor) pode parar o ciclo. Quem retoma: **so o DONO**, depois de a causa estar medida.

---

## 12. O que nao se faz (nem com pressa)

- Sacar, transferir ou mover dinheiro: **proibido**, em qualquer adaptador, rota, cliente ou tela. A trava em `tests/test_movimentacoes.py` nao se remove nem se enfraquece.
- Conta **real** sem autorizacao escrita e sem F5 fechado.
- Baixar, afrouxar ou reinterpretar gate, teste ou trava para "ficar verde".
- `xfail`/`skip` onde existe compilador e codigo.
- Editar a zona do outro sem ID reservado e sem pedido aceito.
- **Escrever numero que nao foi medido.** Esta e a unica que reprova um agente em definitivo.

---

## 13. Quadro de pendencias deste ciclo (dono, prazo, estado)

| Item | Dono | Prazo | Estado |
|---|---|---|---|
| D-068 parser (contrato `prob_buy`/`prob_sell`/`edge`) | ALFA | 07/11 12:00 | aguarda autorizacao do DONO (Q-068) |
| Conflito de ID: o `IDS.md` chama D-068 a "risco/universo/modelos" e o PLANO chama D-068 ao parser | ALFA + CMD | 07/11 | aberto - um dos dois tem de ser renumerado |
| F2.2: prova de recusa, de fail-closed e de ausencia de falso-positivo | ALFA | 20/11 | aberto (hoje 0 posicoes: nunca disparou) |
| F2.9: faltam 5 das 6 falhas simuladas (`COTACAO VOLTOU` nunca observado) | ALFA + DELTA | 20/11 | aberto |
| Kill switch automatico sem consumidor (Q-025/Q-071) | ALFA | 13/11 | aberto |
| Modelos para os 20 simbolos sem modelo, ou operar a tecnico (Q-072) | ALFA + CMD | 27/11 | aberto |
| Gateway como servico do Windows (Q-009/Q-022) | CMD | 13/11 | aberto |
| Contador: `sync-agent` diz 25, `equipe-sync dono` diz 23 | CMD + ALFA | 07/11 | aberto |
| `answer` aceita ancora fora de bloco `## Q-nnn` (Q-065 orfa) | CMD | 07/11 | aberto |
| Push para `github/main` sem autor declarado | CMD | 07/11 | aberto |
| `dataset.csv` escrito por 13 instancias (Q-003) | CMD | 27/11 | aberto |
| Graficos sem `Symbols` e vice-versa (Q-004) | ALFA | 20/11 | aberto |
| G1, G3..G11 do `GATE_REAL` | L4 (DELTA mede) | F5 | 1 de 11 |
| `Tester` com ~2675 MB de logs | DONO (acao na GUI) | quando convier | aberto |

---

## 14. Ack obrigatorio

ALFA e CMD confirmam a leitura com **uma linha** no `SYNC_LOG.md`:

```
<data hora> | <AGENTE> | ACK PROTOCOLO D-070 | discordo de: <nada | item N>
```

Sem ack ate **07/11 12:00**, o trabalho daquele agente fica bloqueado (regra 11, paragem). DELTA confirma com a primeira auditoria diaria e o primeiro relatorio das 21:00.

Divergir e permitido e util: escrever "discordo de: item N" e o caminho. O que nao e permitido e seguir em silencio e depois publicar numero sem prova.

---

## 15. Registo, versionamento e arquivo - commit, push, documentar, salvar

Nada existe ate estar registado. O ciclo tem quatro registos e nenhum e opcional:

| Registo | Onde | Quem | Prova de que foi feito |
|---|---|---|---|
| **commit** | repo do codigo (raiz `MQL5`, aninhado `Files/XAU_AI_PRO`) | CMD | `git log -1` com hash, autor e hora |
| **push** | `github/main` para codigo/docs; `origin` (CodeBase) **so com ordem escrita do DONO** | CMD | `git rev-parse HEAD` == `git rev-parse github/main` |
| **documento** | `EQUIPE/*.md` (decisao, protocolo, quadro, plano) | dono da zona | bloco com ID reservado antes de escrever |
| **arquivo** | `MQL5/Files/Backup/<agente>_<assunto>_<AAAAMMDD_HHMMSS>` | quem escreve | pasta com os ficheiros de antes da escrita |

Regras:

1. **Autor declarado.** Todo commit diz quem o fez e o que mudou. Commit com identidade generica e achado de auditoria, nao e entrega. Enquanto houver push sem autor declarado (medido hoje: 10 commits de 06/11 entre 21:29:22 e 21:44:28), o item continua aberto.
2. **Commit nao e deploy.** Commitar o codigo nao publica `.ex5`; publicar `.ex5` nao commita nada (o binario nao e versionado, de proposito).
3. **Mensagem de commit** no formato `tipo(escopo): o que mudou` e, no corpo, o ID da decisao (`D-070`).
4. **Antes de escrever num ficheiro do canal**, copia-se para o arquivo. Quem nao tem copia nao escreve.
5. **Fim de cada fase (F0..F6)**: um commit de marco e uma linha no `SYNC_LOG` com hash e hora. Sem isso, a fase nao fechou.

---

## 16. Testar e simular - o que conta como teste

O ciclo tem tres niveis de teste e um nao substitui o outro:

1. **Teste estatico** (obrigatorio em toda entrega de codigo): `check` do canal = 0 problemas, `#include` resolvidos, UTF-8 estrito, chaves balanceadas, testes Python do projeto (`tests/*.py`) verdes.
2. **Simulacao** (obrigatoria antes de qualquer publicacao de versao): Strategy Tester no mesmo simbolo, periodo e modelo para comparar versoes. Um backtest **nao e** prova de lucro - e prova de que a mudanca nao quebrou o que existia. Regras:
   - mesma janela e mesmo modelo para antes e depois (senao a comparacao nao vale);
   - deposito, alavancagem e moeda declarados no relatorio;
   - relatorio salvo (caminho escrito no canal) antes de publicar;
   - se o resultado melhorar **so** com parametro afinado depois de ver o numero, isso e ajuste ao passado, e repete-se a janela.
3. **Forward em DEMO** (30 dias, regra 10): o unico teste que vale como endurecimento real, porque nao escolhe o passado.

Proibido chamar "testado" ao que so compilou. Compilar prova que o codigo e valido, nao que a logica esta certa.

> **ANEXO TECNICO DO CONTRATO (proposta do DELTA, 06/11 23:47).** O contrato do ciclo e `EQUIPE/CICLO_FINAL.md` (D-069). Este documento nao e um segundo protocolo: e o anexo que importa tres regras do D-070 para dentro do contrato - DoD de 6 condicoes, compile unico por janela, deploy em 5 condicoes com teste e simulacao de janela identica. Ratificacao: DONO, uma linha. Enquanto nao ratificar, vale o contrato (D-069) e este anexo e proposta.
