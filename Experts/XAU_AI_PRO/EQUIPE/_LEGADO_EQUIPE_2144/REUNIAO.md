# REUNIAO DA EQUIPE - pauta unica

Este e o **ponto de encontro dos 3 agentes**. Tudo que precisa das tres
cabecas (ou do dono) e discutido aqui, num so lugar, com ata.

Regra: nao se abre discussao paralela. Se um agente quer mudar algo, escreve
aqui, na pauta correspondente, com numero medido.

---

## ATA 001 - 05/11/2026 21:45

**Convocados:** Agente 1 (MT5/EA), Agente 2 (documentacao/revisao), Agente 3
(gateway/IA/dataset).

**Presentes:** Agente 1 - **presente**. Agente 2 - **convocado, aguardando
cartao de identidade**. Agente 3 - **convocado, aguardando cartao de
identidade**.

> Enquanto o cartao de identidade nao estiver preenchido em `AGENTE_2.md` e
> `AGENTE_3.md`, esta ata registra "ausente" e o Agente 1 nao delega. Nao e
> formalidade: sem saber o que o outro consegue executar, qualquer delegacao
> vira retrabalho.

### Pauta

1. Estado medido do projeto - `QUADRO.md` (informativo).
2. **Bloqueio P-001**: gateway em 401 x modo autonomo - decisao do dono.
3. Divisao de escopo e dono de arquivo - D-008.
4. Fila de tarefas T-001..T-011 e quem pega cada uma.
5. Regras de convivencia (8 limites) - D-001 a D-009.
6. Proximo ponto de sincronizacao.

### Deliberacoes

**1. Estado.** O projeto tem uma fila de correcoes prontas e nao publicadas:
v1.2.161 (P1.123 - cache de handle por simbolo), v1.2.162 (P1.125 - gate de IA
insatisfativel), v1.2.166 (P1.126-P1.129 - reconexao do gateway, relogio que
nao congela, 1 notificacao por conta) e v1.2.167 (P1.130 - universo universal
+ guarda do GOLD-acao). Os 13 graficos rodam **v1.2.159**. Nada disso chegou ao
mercado. Deliberado: a atualizacao de producao depende do dono (P-002).

**2. Bloqueio P-001.** O EA nao abre posicao em **nenhum** simbolo porque o
gateway responde **401** e `AllowTradeWithoutAI=false`. Nenhum dos tres agentes
pode resolver: nao se afrouxa `MinAIConfidence`, nao se mexe em
`AIUnavailableConfidenceCap`, nao se liga `AllowTradeWithoutAI` (D-006).
Deliberado: escalar ao dono e registrar a espera. Alternativas:
(a) token no gateway + `AIGatewayToken` nos 13 graficos; (b)
`EnableAutonomousMode=true` (IA consultora).

**3. Escopo.** Aprovada a divisao da secao 5 do `QUADRO.md`:
codigo `.mq5/.mqh` e **exclusivo do Agente 1**; documentacao e do **Agente 2**;
gateway, dataset, `Tools/*.ps1` e do **Agente 3**. Nenhum arquivo tem dois
donos. Quem identificar defeito fora do seu escopo **aponta com linha e
evidencia**, nao corrige.

**4. Fila.** T-001 (Agente 1), T-002 (Agente 2), T-007/T-008/T-009 (Agente 3)
estao atribuidas e abertas. T-003 e T-004 sao do dono e bloqueiam T-005.
T-006 e T-010 sao do Agente 1.

**5. Regras.** Fechadas como D-001..D-009: sem `push`; sem recarga sem
autorizacao; sem tocar risco; universo = `Symbols` + Market Watch + grafico;
`GOLD` so vira `XAUUSD` se nao for de bolsa; nao afrouxar o gate de IA; so o
Agente 1 tem terminal; um dono por arquivo; medir antes de afirmar.

**6. Sincronizacao.** Cada agente fecha o seu bloco escrevendo na propria
caixa. A proxima ata (002) so abre quando: (i) os cartoes de identidade
estiverem preenchidos; **ou** (ii) o dono responder P-001/P-002; **ou** (iii)
o v1.2.167 estiver commitado.

### Acoes

| # | Acao | Dono | Prazo | Estado |
|---|---|---|---|---|
| A-01 | commitar v1.2.167 (P1.130) local, caminho explicito, sem push e sem reload | Agente 1 | proximo ciclo | aberto |
| A-02 | completar changelog v1.2.167 com o universo universal + guarda GOLD | Agente 2 | apos A-01 | aberto |
| A-03 | preencher cartao de identidade e diario inicial | Agente 2 | imediato | aberto |
| A-04 | preencher cartao de identidade, diario inicial e contrato do `/api/ai/predict` | Agente 3 | imediato | aberto |
| A-05 | decidir token do gateway x `EnableAutonomousMode` | **dono** | bloqueante | aberto |
| A-06 | autorizar (ou nao) a recarga dos 13 graficos | **dono** | bloqueante | aberto |
| A-07 | investigar `[ATR] LEITURA SUSPEITA | USDBRL` (3 leituras comparadas) | Agente 1 | proximo ciclo | aberto |
| A-08 | propor desenho de escrita unica do `dataset.csv` (P1.111) | Agente 3 | 2 ciclos | aberto |

---

## PAUTA ABERTA (para a ATA 002)

Adicione topicos aqui, um por linha, com o numero medido que os sustenta.

1. _(vazio)_

---

## Regras de conducao da reuniao

1. Um topico por mensagem; sem misturar decisao com opiniao.
2. Quem propoe traz numero. "Acho que" nao entra em ata.
3. Decisao fechada sai daqui e vira `D-NNN` em `DECISOES.md`.
4. Decisao que depende do dono vira `P-NNN` e fica esperando - nao se contorna.
5. Ata nao se reescreve: correcao entra como "erratum" na ata seguinte.
