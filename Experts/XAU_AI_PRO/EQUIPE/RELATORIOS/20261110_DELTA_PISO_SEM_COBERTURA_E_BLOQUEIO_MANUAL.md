# RELATORIO DELTA - piso 0,02 sem cobertura e bloqueio manual sem stop

**Data:** 10/11/2026 10:16 local (15:16 servidor)
**Autor:** DELTA
**Janela de 30 dias abre em:** 11/11 00:05 servidor = 10/11 19:05 local - **faltam 8h 49m**
**Binario:** `XAU_AI_PRO.ex5` 977 654 B | 10/11 02:23:07 | MD5 `71ED34C690C9593D209A69E95F0EFFB6` (inalterado)
**Conta:** 113568614 MetaQuotes-Demo | 12 593,83 / equity 12 623,79 | 4 posicoes | 0 ordens

---

## 1. O que o DONO pediu para confirmar

| pergunta | resposta medida |
|---|---|
| o piso de edge desceu e chegou ao EA? | **sim.** Nenhuma recusa cita +0.0500. Todas dizem `abaixo do minimo +0.0200` (09:46:09 a 09:46:37) |
| isso abriu cobertura? | **nao.** Zero simbolos ganhos. Os 5 candidatos recusam por `stable` (4/5 folds) |
| quais sao os dois bloqueios reais do forward? | **(a)** 4 SELL manuais sem stop no unico simbolo com modelo; **(b)** a estabilidade dos folds, nao o piso |

## 2. O que bloqueia os 609 sinais

`[SCANNER] RESUMO 09:31:50 | visitas=9240 | sinais=609 | trades=0 | bloqueios=9240`

O XAUUSD tem sinal e passa a IA: `[AI] PYTHON | XAUUSD | BUY | PRICE=4078.07 | BUY=64.37% | SELL=35.63% | SCORE=64.40 | CONF=64.40%` (09:44:21, acima de `MinAIConfidence=60`).

E morre aqui, uma vez por minuto, 22 vezes seguidas:

```
[POSITION GUARD] XAUUSD | posicao MANUAL aberta no mesmo simbolo | nova entrada recusada | dir_manual=-1 | desligue EnableManualExposureGuard para ignorar
```

As posicoes que causam isso:

| ticket | lado | volume | abertura (servidor) | SL | TP | flutuante |
|---|---|---|---|---|---|---|
| 11324108563 | sell | 0,10 | 14:37:20 | **nenhum** | 4071,71 | +19,10 |
| 11324122370 | sell | 0,05 | 14:37:55 | **nenhum** | 4069,37 | +5,25 |
| 11324143493 | sell | 0,01 | 14:38:34 | **nenhum** | 4069,37 | +3,11 |
| 11324557698 | sell | 0,01 | 14:58:15 | **nenhum** | 4069,00 | +2,50 |

Todas `reason: Client` (magic 0). **0,17 lotes = 17 oz**: 1 USD de movimento = 17,00 USD, contra `MaxRiskPerTradeUsd=8.00`. O EA nao as gere (filtro por magic) e o vigia `StoplessEmergencyRMult=1.5` tambem nao, porque tambem e' por magic.

**Delta contra o P1.3543 do ALFA:** ele contou tres as 10:10; a quarta abriu as 09:58 local. A exposicao manual **cresceu durante a medicao**.

## 3. O que a descida do piso deu, simbolo a simbolo

| simbolo | edge | folds | media | veredicto |
|---|---|---|---|---|
| USDCAD | +0.0317 | 3/5 | +0.0015 | recusa por instabilidade |
| USDCHF | +0.0253 | 3/5 | +0.0000 | recusa por instabilidade |
| USDJPY | +0.0248 | 3/5 | -0.0145 | recusa por instabilidade |
| NZDUSD | +0.0225 | 2/5 | -0.0081 | recusa por instabilidade |
| USDBRL | +0.0240 | 2/5 | -0.0124 | recusa por instabilidade |
| USDSGD | +0.0193 | 3/5 | +0.0167 | piso **e** instabilidade |
| USDRUB | +0.0166 | 2/5 | -0.0700 | piso **e** instabilidade |
| USDSEK | -0.0403 | 2/5 | -0.0105 | piso **e** instabilidade |
| GBPUSD | -0.0207 | 3/5 | +0.0141 | piso **e** instabilidade |
| XAUUSD | - | - | - | **unico `disponivel=true`** |

**Ganho medido do piso 0,02: zero simbolos.** A decisao nao foi errada (0,05 era arbitrariamente alto e a porta de estabilidade e' legitima), mas foi **insuficiente**, e o dossier tem de dizer isso em vez de "cobertura criada".

## 4. Relojoaria: as duas prazas do plano caem depois da janela

Offset medido: **servidor = local + 5h** (utc 13:01:13Z / local 10:01:13 / servidor 15:01:13).
Janela: **11/11 00:05 servidor = 10/11 19:05 local**.

| prazo do plano | se for hora local | se for hora servidor |
|---|---|---|
| "ALFA MD5 ate' 19:00" | 00:00 servidor - **5 min antes** da janela | 14:00 local - **ja' passou**, `.ex5` de 02:23:07 |
| "deploy 15/15 antes das 20:30" | **01:30 servidor de 11/11 - 1h25 DEPOIS da abertura** | 15:30 local - em minutos |

Nenhuma leitura satisfaz as duas condicoes. **Precisa de decisao escrita (P1.3546).**

## 5. O vigia automatico nao ve o dia 1

`schtasks /query "\XAU_AI_PRO Forward Gate"` -> proxima execucao **11/11 00:20:00 local** = **11/11 05:20 servidor**. Nao ha' execucao em 10/11 19:05 local. O dia 1 da janela fica sem medicao automatica (P1.3547).

## 6. A correcao do cache nao esta' no processo que serve

| objecto | hora |
|---|---|
| 92 `.meta.json` gravados | 09:34:15 |
| processo do gateway (PID 17208) arranca | **09:35:39** |
| `backend/ai_inference.py` (correcao do cache) gravado | **09:38:03** |

O processo arrancou **antes** da correcao: corre o codigo antigo, com a chave de cache so' no mtime do `.pkl`. Quem fez o piso 0,02 valer foi o **reinicio**, nao a correcao - e a prova e' que os metadados sao 84 segundos anteriores ao arranque.
**Consequencia pratica:** qualquer `.meta.json` publicado agora **so'** e' lido se o gateway reiniciar. Republicar um modelo as 18:00 e reiniciar so' o EA deixa o gateway a servir a metadada das 09:34 (P1.3545).

## 7. Indicadores do XAUUSD

```
09:45:09.093  [ATR] HANDLE RECRIADO | XAUUSD | erro=4807 (ERR_INDICATOR_WRONG_HANDLE) | barsCalc=-1
10:00:00.131  [ADX] SEM LEITURA | XAUUSD | ADX=0.00 | tratado como neutro (fail-open)
10:00:00.131  [DATA] SEM LEITURA | XAUUSD | ATR=15.330000 | ADX=-1.00 | RSI=3.55
```

RSI 3,55 num H1 de ouro nao e' leitura plausivel. O pipeline corre no grafico do GBPUSD (`dono=35819305996467`) e le' dados do XAUUSD (P1.3548).

## 8. Binario: a reivindicacao de 929 558 B continua a nao existir

| ficheiro | bytes | mtime | MD5 |
|---|---|---|---|
| `XAU_AI_PRO.ex5` | **977 654** | 11-10 02:23:07 | `71ED34C690C9593D209A69E95F0EFFB6` |
| `DiagGateSelfTest.ex5` | 18 634 | 11-04 23:43:54 | `5020B8C7DB2BEEF782F805A80A71D79B` |

Nao existe nenhum `.ex5` de 929 558 B nem de 931 006 B (P1.3520 mantem-se).

## 9. Frota e freeze

- `[START]` entre 08:30 e 10:05: **zero**. `shutdown` no journal do terminal: **zero**.
- Frota nao reanexada, ancora G4 (11/11 03:43:48) intacta, D-147 respeitado.
- `EnableStoplessEntry=true` e `StoplessEmergencyRMult=1.5` no perfil: a D-161 nao se sustenta; a P1.3542 do ALFA sustenta-se.

## 10. O que NAO fiz, e por que

- **Nao fechei as 4 posicoes manuais.** Sao do DONO (magic 0, `reason: Client`). Fechar posicao real sem instrucao explicita do ticket nao e' permitido; e o dossier nao ganha nada em fechar a perder nem a ganhar.
- **Nao desliguei `EnableManualExposureGuard`.** Alterar input agora muda o MD5 e repoe a janela a zero.
- **Nao reiniciei o gateway.** Reiniciar e' do CMD; e a janela abre em 8h49m, com o risco de o EA ficar cego durante o reinicio.
- **Nao recompilei nem reanexei.** Nada mudou no EA.

## 11. O que exige accao do dono - como pergunta

1. **As 4 posicoes manuais em XAUUSD (0,17 lote, sem stop) ficam abertas durante a janela?** Enquanto existirem, o EA nao abre nada em XAUUSD - que e' o unico simbolo com modelo. Se a resposta for "ficam", o forward de 30 dias mede zero operacoes do EA e o G11 fica em 0/30.
2. **As prazas "19:00" e "20:30" sao hora local ou hora servidor?** Se forem locais, o deploy cai 1h25 depois de a janela abrir.
3. **Quem reinicia o gateway depois da publicacao dos modelos?** Sem reinicio, o piso e a governanca que ficaram no disco nao chegam ao processo.

## 12. Numeros do estado

| metrica | valor |
|---|---|
| simbolos no Market Watch | 15 = universo do EA = 15 graficos |
| graficos com EA | 15 (CHART01-CHART15), 1 simbolo cada |
| graficos sem EA | 4 (CHART16-CHART19, XAUUSD) - P1.3524 |
| simbolos com modelo publicado | **1** (XAUUSD) de 15 |
| sinais gerados na ultima hora | 609 |
| ordens do EA na ultima hora | **0** |
| posicoes manuais abertas | **4** (0,17 lote, sem SL) |
| criterios GATE_REAL a verde | 0 de 11 |
| accoes concluidas | 1 de 11 (G10 Market Watch) |
| G11 trades | 0 de 30 |
