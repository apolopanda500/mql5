# ORDEM MASTER - uma ordem do DONO, tudo arranca; uma ordem, tudo fecha

**Criada:** 07/11/2026 21:50 | **Autor:** CMD | **Base:** D-095 / D-096
**Para:** DONO (dar a ordem) + ALFA / DELTA / CMD (executar)

---

## 1. Regra de ouro

O DONO escreve **uma palavra** no chat. Nada mais.

| O DONO escreve | O que acontece |
|---|---|
| `INICIAR` | tudo e' verificado, religado e posto a andar; contagem dos 30 dias comeca sozinha |
| `ESTADO` | uma pagina com o estado medido (gate, dias, gateway, binario) |
| `FINALIZAR` | so fecha se 11/11 + 30 dias + assinatura do DELTA; se faltar algo, **diz o que falta e nao fecha** |

O agente que receber a palavra corre:

```
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\..\EQUIPE\tools\ordem-master.ps1 iniciar
powershell -NoProfile -ExecutionPolicy Bypass -File ...\ordem-master.ps1 estado
powershell -NoProfile -ExecutionPolicy Bypass -File ...\ordem-master.ps1 finalizar
```

(caminho completo: `MQL5\Experts\XAU_AI_PRO\EQUIPE\tools\ordem-master.ps1`)

---

## 2. O que `INICIAR` verifica e liga (medido, nao prometido)

1. **Mandato intacto** - `dono-mandato.ps1 check` tem de dar `OK`. Se nao der,
   `INICIAR` **para** e mostra a violacao. Nao ha "arrancar na mesma".
2. **Ficheiros base** - `FICHA_DONO.md`, `MANUAL_DONO.md`,
   `MANDATO_ATIVO.json`, `GATE_REAL.md`.
3. **Gateway 9011** - se estiver morto, `gateway-start.ps1` religa em modo
   leitura (6 flags de execucao a 0).
4. **Tres tarefas do Windows** - relatorio diario 23:50, keepalive 5 min,
   inicio do forward 09/11 00:05. Se faltar alguma, recria.
5. **Canal** - `sync-agent.ps1 check` tem de dar `OK`.
6. **Binario x fonte** - tem de dizer `BATEM`; se nao disser, avisa e manda
   recompilar pelo `compile-ea.ps1` (com backup antes).
7. **Registo** - escreve `ORDEM_MASTER_ESTADO.json` com o que mediu.
8. **Checklist dos agentes** - imprime o que cada um tem de fazer a partir dali.

`INICIAR` **nao** abre ordens, **nao** altera risco, **nao** mexe em inputs e
**nao** liga conta real.

---

## 3. O que `FINALIZAR` exige (e recusa sem isso)

So fecha com os **quatro** requisitos ao mesmo tempo:

| # | Requisito | Onde e' medido |
|---|---|---|
| 1 | GATE_REAL **11 de 11** | `GATE_REAL.md` (contagem lida, nao escrita) |
| 2 | Forward **>= 30 dias** com medicao diaria | `RELATORIOS/` + `MANDATO_ATIVO.json` |
| 3 | **Assinatura do DELTA** | `DOSSIE_FINAL.md` com linha `ASSINADO POR DELTA` |
| 4 | Nenhuma paragem automatica ativa | `ORDEM_MASTER_ESTADO.json` |

Se faltar qualquer um, `FINALIZAR` **nao** escreve "fechado": escreve o que
falta, com numeros. Quando os quatro existirem, gera o `DOSSIE_FINAL.md` com a
medicao e deixa-o para o DELTA assinar - **o CMD nao assina o que nao fez**.

---

## 4. Quem faz o que (checklist que `INICIAR` imprime)

### ALFA - dono do codigo
- Fechar G3-G8 com medicao (score, trades, DD, PF, shorts).
- Manter `compile-ea.ps1` como unico caminho de compile (backup antes).
- Corrigir P1 abertos dentro do mandato, sem consultar o DONO.
- Nao parar por atraso corrigivel.

### DELTA - dono da medicao e do veredicto
- Medir todos os dias com mercado aberto: `[SCORE]`, `[CENARIO]`,
  `TREND CONTRA OK`, entradas com IA vs sem IA.
- Separar o que o EA fez do que o DONO fez a mao (manual nao conta).
- Assinar `DOSSIE_FINAL.md` so com os 11 criterios verdes e 30 dias medidos.

### CMD - dono da infra e da entrega
- Manter gateway, tarefas, canal, git e CI.
- Rodar `ordem-master.ps1` quando o DONO der a ordem.
- Nunca escrever `10/10` como estado; sempre `x/11`.

### DONO - dono da ordem
- Escreve `INICIAR`, `ESTADO` ou `FINALIZAR`. So isso.
- Pode fazer trades manuais (ficam fora da estatistica do EA).
- Nao e' chamado durante a execucao.

---

## 5. Proibicoes que a ordem nao remove

- `10/10` como estado (o unico estado valido e' `x/11`).
- Conta real sem 11/11 + 30 dias + DELTA.
- Alterar `RiskPercent`, `MaxDailyLoss`, `MaxDrawdown`, exposicao ou magic.
- Remover guarda de risco.
- Chamar o DONO durante a execucao (excepto os 2 casos do mandato).
- Commitar token ou credencial.

---

## 6. Estado de hoje (07/11/2026 21:50)

| Item | Medido |
|---|---|
| GATE_REAL | **2 de 11** |
| Forward | 0 de 30 (arranca 09/11 00:05) |
| Gateway 9011 | OK, modo leitura |
| Binario x fonte | BATEM |
| Tarefas | 3 instaladas |
| Mandato | ATIVO, `dono-mandato.ps1 check` = OK |
| Risco | intocado |
| Ordens | 0 |

**Isto nao e' 10/10. E' o ponto de partida medido.**

---

## 7. Uma frase para o DONO

> Escreva **INICIAR** uma vez. Depois so' **ESTADO** quando quiser ver, e
> **FINALIZAR** quando os 30 dias passarem. Se `FINALIZAR` recusar, e' porque
> ainda falta prova - e ele diz qual.

---

## 8. Autoridade tecnica dos agentes (D-097, 07/11/2026 22:10)

O DONO autorizou os agentes a **destravar o projeto por conta propria**:

| Podem | Exemplos |
|---|---|
| Pesquisar na web | documentacao, motores, MCP, plugins, extensoes, scripts, agentes, repositorios |
| Instalar / atualizar / desinstalar | dependencias, ferramentas, servicos, tarefas |
| Limpar o Windows e o terminal | temporarios, caches, logs antigos, binarios obsoletos |
| Automatizar | tarefas agendadas, MCP, scripts de medicao e entrega |

**Limites que a autoridade nao atravessa:**

1. Nao remover nem desativar guarda de risco.
2. Nao abrir conta real sem 11/11 + 30 dias + assinatura do DELTA.
3. Nao apagar dados pessoais, historico de conta, backups ou o repositorio.
4. Nao imprimir, gravar ou commitar tokens.
5. Limpeza so' com copia de seguranca previa, e registada no `SYNC_LOG.md`.
6. Parametros de risco continuam a exigir decisao escrita do DONO.

Na pratica: se o projeto estiver travado por falta de uma ferramenta, de um
estudo ou de uma limpeza, **o agente resolve e regista** - nao volta a perguntar.

