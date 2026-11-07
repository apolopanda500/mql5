# SESSAO 07/11/2026 - CMD (turno 4): auditoria do G3 entregue, errata da v1.2.184

**Papel:** CMD (git/CI/entrega). **Janela:** 07/11/2026 18:08 -> 18:37.
**Compile:** ZERO. **Reattach:** ZERO. **Ordens:** ZERO. **Linhas de codigo tocadas:** ZERO.
Nenhum parametro de risco alterado. Nenhum gate assinado por mim.

Este turno commita o que o ALFA (turno 8) e o DELTA (auditoria D-083) entregaram
no canal. Nao ha codigo novo: os unicos ficheiros alterados sao `.md` de EQUIPE.

---

## 1. O que foi publicado

| Fonte | Conteudo |
|---|---|
| ALFA, turno 8 | **D-082** - a "IA" do A/B nao e uma IA: 90,02 % das amostras sao o fallback capado `AI=20.00` (confianca 40 = `AIUnavailableConfidenceCap`); 9,66 % sao um `prediction_XAUUSD.json` estatico lido 48 vezes; 176 `[AI] GATEWAY` com erro 4014 (o Strategy Tester nao faz WebRequest) |
| ALFA, turno 8 | Errata do D-081: 466/506 = **92,09 %** (nao 466/529 = 88,09 %); sd A **4,05** / B **7,47** (nao 10,97 / 7,58). O indicador que decide (0 saturados em B) e 0 nos dois cortes |
| DELTA, D-083 | G3 **auditado e confirmado**: A/B reproduzido ao centavo (27->7 deals, PF 1,0645->0,4156, profit +15,71->-121,51, tecto 70,97) |
| DELTA, P1.2336 | O contador `trades=` do `[SCANNER] RESUMO` declara **0 em 7429 janelas** enquanto 34 deals reais existem - **o "0 trades" medido por RESUMO nao prova nada** |
| DELTA, funil | Sinais 11 122 -> 11 336; AllowTrade 9 823 -> 11 301; ExecFail 1 299 -> 35; deals 27 -> 7. O piso 65,00 deixa passar **9 de 621 (1,4 %)** |

## 2. Errata que fica registada sobre o commit 3ce229f9

O commit `3ce229f9` (v1.2.184, autor ALFA) esta publicado e **nao e reescrito**
(sem force-push, por regra). O texto dele contem dois numeros agora corrigidos:

| No commit 3ce229f9 | Medido depois (D-083) |
|---|---|
| `[SCORE] em 100.00 466/529 = 88,09 %` | **466/506 = 92,09 %** (fronteira real do run) |
| `sd 10.97 -> 7.58` | **A 4,05 / B 7,47** |

O veredicto nao muda: **0 de 621** amostras saturadas em B e sd 7,47 > 5. A
errata vive no canal (D-082, D-083, este ficheiro), nao no historico do git.

Da mesma forma, o meu `SESSAO_20261107_CMD_T3.md` repetiu "0 trades" a partir do
RESUMO. **Retirado por P1.2336.** A prova de "0 trades" passa a ser apenas a
conta: 0 posicoes, 0 ordens, sem deals no historico. O RESUMO e corroboracao
invalida.

## 3. O que o G3 e agora, sem inflacao

**VERDE AUDITADO (DELTA, D-083), com tres ressalvas escritas:**

1. medido **so no tester**;
2. amostra **troteada** - `[SCORE]` passa por `DecisionLogDue(symbol,"SCORE",900)`, 1127 amostras para ~22 458 sinais (~5 %);
3. no tester a **IA e constante** (fallback 40), logo 65 dos 115 pontos do denominador sao inalcancaveis e o tecto real e 70,97.

Em producao continua **inobservavel** (D-079): 100 % dos sinais morre no passo 1
mudo de `AllowTradeEx`; a v1.2.184 nunca correu fora do tester.

`GATE_REAL`: **2 de 11** (G2 com ressalva; G3 auditado com as tres ressalvas).
Nao existe "10/10".

## 4. O que muda na decisao do piso (nao e minha)

O DELTA mediu a distribuicao do score em B: P10=P25=P50=**47,83**, P75=P90=**60,87**,
maximo 70,97 - **bimodal**. A grelha 65/55/45/35 nao e uma escala de calibracao:
e um comutador entre regime quase fechado (1,4 %) e quase aberto (91,3 %).

Posicoes tecnicas de ALFA e DELTA, convergem:

- **Q-079: (B)** - folga de 1 ATR no portao de tendencia. (A) e (C) tornam o portao uma tautologia do sinal e apagam a guarda.
- **Piso:** nao recalibrar com dados de tester. Duas saidas: (a) denominador condicional (com `aiReal=false` o maximo desce de 115 para 65; candidato P1.140), ou (b) medir o piso em demo com gateway vivo.
- **Ordem:** Q-079 + piso -> **1 compile** -> reattach -> janela. Reattach primeiro consome a unica variavel limpa.

## 5. Estado medido no fim do turno

| Item | Valor |
|---|---|
| Outer `apolopanda500/mql5` | `main` sincronizado com `github/main` (commit deste turno) |
| Nested `XAU_AI_PRO` | `main` `603b244` (20/20) · `develop` `a033832` (12/12) |
| Canal | 44 `.md`, 72 IDs D usados, 78 no ledger, 19 perguntas, `check` **OK** |
| `.ex5` | 964 056 B, 16:23:11, MD5 `931459A39634DD7A95ED1EA74D412FC4` (intocado) |
| A correr | **v1.2.183** nos 15 graficos (sem reattach) |
| Conta 113568614 | Demo, equity 12 636,32, 0 posicoes, 0 ordens |

## 6. O que este turno NAO fez

- Nao compilou, nao reanexou, nao enviou ordens.
- Nao alterou `MinMarketScore`, lote, SL, TP nem regras de entrada/saida.
- Nao reescreveu o commit `3ce229f9` (sem force): a errata e no canal.
- Nao assinou o G3 - a auditoria e do DELTA (D-083); o CMD so a publica.
- Nao escreveu "10/10" em ficheiro, commit ou log.
