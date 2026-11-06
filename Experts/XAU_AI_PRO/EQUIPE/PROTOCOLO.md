# PROTOCOLO DO CANAL - equipe de 3 agentes / XAU_AI_PRO

Canal oficial de coordenacao entre **ALFA** (Agente 1), **DELTA** (Agente 2) e
**CMD** (Agente 3). Codenames definidos pelo dono em 05/11 21:46:

| Codename | Agente | Papel |
|---|---|---|
| **ALFA** | Agente 1 | `AI/**`, `Core/SymbolManager.mqh`, `Core/Config.mqh`, `Indicators/**`; mede e corrige |
| **DELTA** | Agente 2 | assistente MetaTrader 5 / MetaEditor; `Monitoring/**`, notificacoes, relogios, build/deploy/diagnostico |
| **CMD** | Agente 3 | terminal/PowerShell, app `MQL5/Files/XAU_AI_PRO/**`, `backend/**`, espelho, testes |

Nas linhas de inbox/diario use **ALFA / DELTA / CMD**. "A1/A2/A3" so em texto
antigo ja escrito - nao corrigir para tras, so nao usar daqui para frente.
Criado em 05/11/2026. Dono do projeto: o operador da conta demo 113568614.

Agentes nao conversam em tempo real. O unico canal confiavel e **arquivo no
repositorio**. Tudo o que for decisao, pedido, medida ou handoff passa por
aqui; nada de "eu avisei no chat".

Pasta unica do canal: **`MQL5/Experts/XAU_AI_PRO/EQUIPE/`** (pasta do projeto
do EA). Decisao do dono em 05/11 21:44: os tres agentes reunidos num lugar so.

---

## 1. Mapa do canal - TUDO numa pasta so

| Arquivo | Papel | Quem escreve |
|---|---|---|
| `EQUIPE/PROTOCOLO.md` | este documento: regras do canal | ninguem edita sem acordo dos 3 |
| `EQUIPE/QUADRO_ESTADO.md` | estado medido unico (versao, build, graficos, fila) | qualquer agente, **com a medida e a hora** |
| `EQUIPE/DECISOES.md` | registro de decisoes com ID (`D-001`, `D-002`, ...) | quem propoe escreve a linha; o dono fecha |
| `EQUIPE/INBOX_AGENTE_1.md` | caixa de entrada do **ALFA** | DELTA e CMD escrevem; ALFA responde na mesma linha |
| `EQUIPE/INBOX_AGENTE_2.md` | caixa de entrada do **DELTA** | ALFA e CMD escrevem; DELTA responde |
| `EQUIPE/INBOX_AGENTE_3.md` | caixa de entrada do **CMD** | ALFA e DELTA escrevem; CMD responde |
| `EQUIPE/AGENTE_1.md` | identidade, escopo e diario do **ALFA** | ALFA (o CMD tambem ja escreveu ali) |
| `EQUIPE/AGENTE_2.md` | identidade, escopo e diario do **DELTA** | so o DELTA |
| `EQUIPE/AGENTE_3.md` | identidade, escopo e diario do **CMD** | so o CMD |

**Caminhos antigos - so atalho, nao escrever la:**

| Caminho antigo | Estado |
|---|---|
| `Experts/XAU_AI_PRO/AGENTE_1.md` | stub de 1 443 B a apontar para `EQUIPE/AGENTE_1.md` |
| `MQL5/AGENTE_3.md` | stub de 1 527 B a apontar para `EQUIPE/AGENTE_3.md` |
| conteudo integral dos dois | copiado **verbatim** para `EQUIPE/` a 05/11 21:42:05 (14 055 B e 8 536 B); depois disso ALFA e CMD reescreveram os seus diarios (o arquivo atual ja nao e a copia) |

Precedencia quando dois arquivos discordam: **`QUADRO_ESTADO.md` manda**, porque
e o unico que exige medida com hora. Diario de agente e opiniao datada.

---

## 2. Ciclo de mensagem (obrigatorio)

1. **Antes de tocar em qualquer arquivo de codigo**: leia
   `QUADRO_ESTADO.md` (§3 posse) e a sua `INBOX_AGENTE_n.md`.
2. Escreva no seu diario o que vai fazer, com hora.
3. Faca a alteracao minima.
4. Compile (quem tem MetaEditor) ou peca compilacao na inbox.
5. Atualize `QUADRO_ESTADO.md` **com o numero medido** e a hora.
6. Se precisar de outro agente, abra linha na inbox dele no formato da §3.
7. Se a decisao e do dono, abra linha em `DECISOES.md` com estado `ABERTA`.

Nenhuma pendencia e marcada como resolvida sem numero medido. "Nao medido" e
resposta aceitavel; numero inventado nao e.

---

## 3. Formato de linha (inbox e diario)

```
DE -> PARA | <assunto> | arquivo:linha | precisa: <acao concreta> | estado: ABERTO/RESPONDIDO/FECHADO | <hora>
RESPOSTA (Agente n) | <o que mediu/fez> | evidencia: <linha de journal/contagem> | estado: FECHADO | <hora>
```

Exemplo real:
```
DE -> A2 | confirmar P1.130 duplicado | EQUIPE/DECISOES.md D-002 | precisa: decidir quem fica com o ID | estado: ABERTO | 05/11 21:52
```

---

## 4. Posse por arquivo (regra dura)

Dois agentes **nunca** editam o mesmo arquivo na mesma janela.

| Zona | Dono | Observacao |
|---|---|---|
| `AI/**`, `Core/SymbolManager.mqh`, `Core/Config.mqh`, `Indicators/**` | **Agente 1** | P1.110, P1.113, P1.119, P1.130-universo |
| `Monitoring/**`, `Enterprise/NotificationCenter.mqh`, `Monitoring/AccountLogGate.mqh`, build/deploy/diagnostico de terminal | **Agente 2** | P1.128-P1.131, notificacoes, relogios, `[RESUMO]` |
| `MQL5/Files/XAU_AI_PRO/**` (app), `backend/**`, `Docs/**`, espelho | **Agente 3** | gateway Python, dataset, testes, sync |
| `XAU_AI_PRO.mq5`, `Enterprise/VersionManager.mqh` | **compartilhado, 1 por vez** | so no fecho de ciclo; anunciar na inbox antes |
| `PENDENCIAS.md`, `PROGRESS.md`, `Tools/HANDOFF.md` | **append-only** | cada agente anexa o proprio bloco; nunca reescrever bloco alheio |

Conflito de posse nao se resolve editando: resolve-se com linha na inbox e, se
durar, com `DECISOES.md`.

---

## 5. Regras da casa (valem para os 3)

1. **Nunca `push`.** `origin` (Forge MQL5) esta com credencial expirada;
   `github` = `apolopanda500/mql5`. Commit e local, com caminhos explicitos, e
   **so com pedido explicito do dono**.
2. **Nunca tocar parametros de risco**: `RiskPercent`, `RiskPerTradeUsd`,
   `MaxDailyLossPercent`, `MaxDailyLossUsd`, `MaxDrawdownPercent`,
   `StopLossPoints`, `TakeProfitPoints`, `RewardRatio`, `MinRewardRatio`,
   `MaxSpreadPct`, `MaxTradesPerDay`, `MaxOpenPositions`, `MinAIConfidence`,
   `AllowTradeWithoutAI`, regras de entrada/saida.
3. **Nunca conta real.** Conta atual: demo 113568614 (MetaQuotes-Demo).
4. **Nunca remover guarda de risco**, ocultar atividade, falsificar historico,
   nem enviar ordem real.
5. **Recarregar o EA nos graficos** (`chart_add_expert`, `profile_apply`) e ato
   de **producao**: so com autorizacao explicita na hora. Quem recarrega
   anuncia na inbox dos outros dois **antes** e mede o `[START]` **depois**.
   Um unico agente por vez reanexa - dois reanexando ao mesmo tempo geram
   tempestade de `EA finalizado` e confundem a medicao.
6. **Compilar e livre, mas nao concorrente**: se outro agente acabou de
   compilar, espere o `.ex5` parar de mudar de hora antes de recompilar. O
   `.ex5` gerado carrega o estado de **todos** os fontes no disco, nao apenas o
   seu - compilar por cima do trabalho meio-feito de outro leva o bug do outro
   para dentro do binario.
7. **Um ID de pendencia, um dono.** ID novo so depois de conferir
   `QUADRO_ESTADO.md` (§5) - ja houve colisao (ver `D-002`).
8. **Codificacao**: os `.mqh` do EA **nao tem BOM** e alguns tem UTF-8 quebrado
   (`AI/AIConnector.mqh` linha ~1309). Ao reescrever arquivo, preserve o BOM
   original ou a aritmetica de `#include`/diff muda.
9. **Ferramenta que mente**: `search_text`/`search_regex` do MCP devolvem 0
   para termos existentes. Use `findstr` ou `Select-String` dentro de `.ps1`.
10. **Documentar no mesmo ciclo**: `PENDENCIAS.md`, `PROGRESS.md` e
    `Tools/HANDOFF.md`, em bloco append-only, com a evidencia.

---

## 6. Definicoes do dono (preencher)

- [ ] Quem reanexa o EA nos graficos: ( ) Agente 1 ( ) Agente 2 ( ) so o dono
- [ ] Quem commita: ( ) Agente 1 ( ) Agente 2 ( ) so o dono
- [ ] Gate de IA: ( ) provisionar token ( ) `EnableAutonomousMode=true`
- [ ] Apagar orfaos `Management/PartialClose.mqh` e `Management/TrailingStop.mqh`?
- [ ] Commit de `Profiles/Tester/XAU_AI_PRO.set`?

Ate o dono responder, os agentes tratam cada item como **PROIBIDO**.

---

## 7. Reuniao em pasta unica (05/11 21:44)

Ordem do dono: "reunir os 3 agentes em unico lugar e pasta do projeto".

- tudo o que e canal vive agora em `Experts/XAU_AI_PRO/EQUIPE/`;
- `Experts/XAU_AI_PRO/AGENTE_1.md` e `MQL5/AGENTE_3.md` passaram a **stub**
  de redirecionamento (nao apagar, nao escrever la);
- nenhum conteudo foi perdido: copia verbatim as 21:42:05.

Regra nova: **ficheiro de canal novo so nasce em `EQUIPE/`**. Ficheiro de
coordenacao fora de `EQUIPE/` e erro de processo.

---

Ultima alteracao: 05/11/2026 21:46 - Agente 2.
