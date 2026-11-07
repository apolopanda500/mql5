# MANUAL DO DONO - o que acontece sem o dono fazer nada

**Criado:** 07/11/2026 21:05 | **Autor:** CMD | **Base:** `FICHA_DONO.md`,
`MANDATO_ATIVO.json`, `PROTOCOLO_CICLO_10_10.md`, `GATE_REAL.md`.

---

## 0. Regra unica

**O dono nao entra em acao ate os agentes concordarem que o projeto fechou.**
Fechar = 11 de 11 criterios do GATE_REAL verdes **+** 30 dias de forward em demo
**+** assinatura do DELTA **+** nenhuma paragem automatica ativa.

Ate la: os agentes executam, medem, corrigem e registam. O dono recebe
**relatorio**, nao pergunta.

---

## 1. O que o dono faz hoje

**Nada.** A ficha esta preenchida (7 respostas), o mandato esta escrito e a
automacao esta instalada. Se quiser conferir, corre:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\dono-mandato.ps1 estado
```

Le uma pagina e sai. Nao altera nada.

---

## 2. O que acontece automaticamente

| Quando | O que | Onde fica |
|---|---|---|
| Todos os dias 23:50 | Relatorio diario do mandato | `EQUIPE/RELATORIOS/AAAAMMDD.md` |
| Todos os dias | Canal verificado (`check`), lock e encoding | `SYNC_LOG.md` |
| Todas as sessoes | Agentes registam decisao (`D-xxx`) e evidencia medida | `DECISOES.md`, `IDS.md` |
| Segunda-feira, mercado aberto | Comeca a contagem dos 30 dias | `MANDATO_ATIVO.json` -> `forward.inicio` |
| Sempre | Cada criterio do GATE_REAL so sobe com prova datada | `GATE_REAL.md` |
| No fim | Dossie final + medicao dos 11 criterios | `GATE_REAL.md` |

O relatorio diario diz, em 10 linhas: dia N de 30, criterios verdes, se o
gateway esta no ar, se o binario bate com a fonte, e o que mudou desde ontem.
**Se nada mudou, o relatorio diz "nada mudou"** - nao inventa progresso.

---

## 3. Quando o dono e chamado

So dois casos:

1. **Fim.** 11/11 + 30 dias + DELTA assinou -> o dono recebe o dossie e a
   autorizacao condicional passa a valer.
2. **Excecao maxima.** Tentativa de ordem em conta real sem gate, ou tentativa
   de remover guarda de risco. Nada mais.

**Nao** e chamado para: piso, USDBRL, reinicio do gateway, reattach, compile,
encoding do canal, pergunta "A ou B" de agente, ou "confirmar isto".

Se um agente chamar o dono fora destes dois casos, o agente esta a violar o
mandato - o registo tem de dizer quem e por que.

---

## 4. Paragem automatica (o dono nao decide parar)

| Gatilho | Limite | Efeito |
|---|---|---|
| Perda no dia | > 60 USD | para de abrir novas entradas no dia |
| Drawdown | > 50% | para a operacao e exige causa registada |
| Canal | 2 falhas na mesma hora | para a operacao e exige causa registada |

Parar e automatico; **retomar exige causa identificada e registo datado**.
O dono nao precisa de autorizar a paragem nem a retomada - so e informado no
relatorio diario.

---

## 5. Calendario dos 30 dias

| Fase | O que acontece | Quem |
|---|---|---|
| **D0** = 1a segunda com mercado aberto (09/11/2026) | contagem arranca; primeira medicao real de mercado | DELTA |
| D1-D30 | operacao demo, medicao diaria, correcao continua | ALFA / DELTA / CMD |
| Falhas | corrigidas dentro do mandato, sem parar a contagem (salvo paragem automatica) | ALFA |
| D30 | fecha a janela; dossie final; 11 criterios auditados | DELTA |
| D30+ | se 11/11 + assinatura -> autorizacao condicional vira ativa | DONO (so le) |

**Nota honesta:** os 30 dias contam **dias de calendario com mercado aberto
medido**, nao "dias desde que alguem escreveu uma data". Se um dia nao tiver
medicao, o dia nao conta - e o relatorio diario mostra o buraco.

---

## 6. Como ler o estado sem jargao

| Se o relatorio disser | Significa |
|---|---|
| `GATE 2/11` | dois criterios provados; faltam nove. **Nao e 10/10** |
| `forward D7/30` | sete dias de mercado medidos; faltam 23 |
| `gateway OK` | a IA respondeu agora (health 200) |
| `gateway DOWN` | a IA nao responde; o EA usa o piso sem IA (45,0) |
| `binario = fonte` | o que corre e o que esta escrito |
| `PARAGEM ATIVA` | uma das tres regras do ponto 4 disparou |

`10/10` nunca aparece como estado. Se aparecer, e erro de escrita: o estado
correto e sempre `x/11`.

---

## 7. Paragem de emergencia manual (o dono pode, mas nao precisa)

Se o dono quiser parar tudo por conta propria, o caminho curto e o botao global
de negociacao algoritmica do terminal (AutoTrading). Isso para entradas novas
em todos os graficos, sem apagar nada e sem alterar risco.

Nao e preciso para o projeto andar. E o travao de mao, nao o travão normal.

---

## 8. O que nunca muda sem o dono escrever

- `RiskPercent`, `MaxDailyLoss`, `MaxDrawdown`, exposicao maxima, magic number.
- Ativacao de conta real.
- Remocao de qualquer guarda de risco.

Tudo o resto (piso 45,0, USDBRL M5, gateway como tarefa, calendario, relatorios)
esta **pre-autorizado** por esta ficha e pelo `MANDATO_ATIVO.json`.

---

## 9. Reforco de 07/11/2026 21:20 - o que muda na pratica

- Os agentes tem **autonomia total dentro do mandato**: corrigir, compilar,
  reanexar, reiniciar o gateway, medir, registar. Nao pedem licenca para isso.
- **Trades manuais do DONO** sao permitidos. Ficam fora da estatistica do EA e
  nao contam para o GATE_REAL nem para os 30 dias.
- O trabalho **nao para** por atraso corrigivel. So para quando o resultado
  esperado existir: 11/11 + 30 dias + assinatura do DELTA.
- Conta real: **depois** dos 30 dias ou mais, e apenas com os quatro requisitos.
  Nao ha atalho por "ja passou tempo".
