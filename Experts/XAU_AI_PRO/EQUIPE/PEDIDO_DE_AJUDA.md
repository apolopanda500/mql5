# PEDIDO DE AJUDA ENTRE AGENTES - protocolo

**Criado:** 05/11/2026 22:41 | **registo:** `DECISOES.md` `D-020`.
**Regra base:** pedir ajuda e **permitido e barato**; ficar parado a espera em silencio e que e caro. Ninguem bloqueia sem escrever que esta bloqueado.

---

## 1. Formato do pedido (8 linhas, uma so vez)

```
DE -> PARA | <assunto> | <arquivo:linha> | o que preciso: <accao concreta> |
porque: <o que desbloqueia> | pronto quando: <criterio medivel> |
prazo: <dd/mm hh:mm> | estado: PEDIDO
```

Exemplo real (o que esta a travar hoje):

```
ALFA -> DELTA | medir se o ATR volta sozinho em 24 h | Indicators/VolatilityFilter.mqh:405 |
o que preciso: contar [ATR] HANDLE MORTO por simbolo entre 22:40 e 06:40 sem reiniciar |
porque: Q-001 so fecha com uma janela de 24 h, e eu nao tenho como vigiar de madrugada |
pronto quando: tabela simbolo x (barras lidas / voltou sozinho?) com hora | prazo: 06/11 07:00 | estado: PEDIDO
```

## 2. Ciclo de estados

| Estado | Quem muda | Significa |
|---|---|---|
| `PEDIDO` | quem pede | pedido escrito, ainda sem dono |
| `ACEITE` | quem recebe | "e minha zona, assumo, comecei as hh:mm" |
| `FEITO` | quem fez | entrega com **numero + hora**, nao com opiniao |
| `DEVOLVIDO` | quem recebe | nao e a minha zona / falta informacao - diz **qual** e **de quem** |
| `BLOQUEADO` | quem recebe | depende do DONO -> abre `Q-nnn` e responde aqui o numero |
| `FECHADO` | quem pediu | confirma que a entrega serve para o que precisava |

**Um pedido sem resposta em 2 turnos nao fica a apodrecer:** quem pediu faz uma de duas coisas - escala ao DONO com `ask`, ou executa ele proprio **com LOCK** e declara na linha que o fez.

## 3. Sete regras para o pedido ser util

1. **Pede a quem tem a zona** (`D-008`): `Indicators/**` e `Core/**` = ALFA; `Monitoring/**` e `Enterprise/**` = DELTA; app/backend/Tools/repo = CMD; raiz partilhada = um de cada vez com LOCK.
2. **Nao pecas o que consegues medir sozinho.** Pedir para "ver se esta bem" e ruido.
3. **Pede uma accao, nao um tema.** "Mede X entre hh:mm e hh:mm" e pedido; "ve la o ATR" nao e.
4. **Criterio de pronto medivel.** Se nao der para verificar, nao esta pronto.
5. **O helper nao edita o ficheiro do outro em silencio.** Se tiver de editar, escreve a linha exacta que mudou e a razao.
6. **Ajuda nao transfere decisao.** Nenhum agente aprova o que e do DONO: risco, conta real, CodeBase. Isso e `ask`, nao `pedido de ajuda`.
7. **Depois de ajudado, agradece na linha e fecha o estado.** Um `FECHADO` poupa a proxima hora de quem entrar.

## 4. Matriz de quem ajuda em que

| Se o bloqueio e... | Pede a | Porque ele |
|---|---|---|
| compilar / publicar `.ex5` / commit / push | **CMD** | tem o repo e o build |
| medir journal, conta, graficos, tester, reattach | **ALFA** ou **DELTA** | tem MCP `metatrader5` |
| ATR/ADX/RSI, `Core/**`, `Filters/**` | **ALFA** | zona dele |
| `Monitoring/**`, `Enterprise/**`, `AIConnector` partilhado | **DELTA** | zona dele, com linha do ALFA |
| dados de teste, walk-forward, `.set` | **CMD** | tester |
| risco, conta real, publicar, segredo, dinheiro | **DONO** | so ele decide (`ask`) |

## 5. Comandos

```powershell
# pedir
sync-agent.ps1 post -From ALFA -To DELTA -Assunto "..." -Precisa "..." -Estado ABERTO -Corpo "<8 linhas>"
# aceitar / entregar / devolver
sync-agent.ps1 post -From DELTA -To ALFA -Assunto "ACEITE: ..." -Estado RESPONDIDO -Corpo "..."
# escalar ao dono
sync-agent.ps1 ask -From ALFA -Pergunta "..." -Opcoes "(a)... (b)..." -Prazo "06/11 12:00"
```

## 6. O que isto evita (medido nesta equipa)

- **Trabalho duplicado:** duas sessoes a corrigir o mesmo defeito porque ninguem disse que ia pegar.
- **Bloqueio silencioso:** o `P-002` (reattach) ficou horas parado porque cada um esperava que o outro fizesse - agora o pedido tem prazo e escalada.
- **Sobreposicao de escrita:** dois a editar `AIConnector.mqh` no mesmo minuto. Pedido + LOCK resolve.
- **Decisao tomada por quem nao podia:** o gate de IA e o risco passam a ir por `ask`, nao por "achei melhor".
