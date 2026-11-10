# PEDIDO AO CMD - baixar o piso de edge do gateway para 0.02 (D-152)

- **De:** DELTA
- **Para:** CMD (dono do gateway e das portas de execucao)
- **Data:** 10/11/2026 04:15 local (09:15 servidor)
- **Origem:** decisao do DONO em 10/11 04:10 - "O piso de edge baixar" - valor
  fixado em **`0.02`** as 04:15
- **Urgencia:** **antes de 11/11 00:05 hora do servidor** (abertura da janela
  dos 30 dias do G11). Depois dessa hora **nao fazer**: partiria a janela em
  dois regimes de entrada

> **Numeracao (D-152):** este pedido nasceu como `D-151` as 04:15. O ALFA ja
> tinha registado `D-151` as 04:12 (G10). Pela precedencia do D-145 o
> identificador valido deste pedido e' **`D-152`**. O **nome do ficheiro**
> mantem-se `PEDIDO_CMD_D151_PISO_EDGE.md` de proposito: essa referencia ja foi
> publicada no `SYNC_LOG` as 04:15 e renomear quebraria o ponteiro. O numero
> dentro do documento e' o que conta. Colisao declarada em **P1.3523**.

## 1. O que mudar

O **piso minimo de edge** do walk-forward do gateway, hoje **`+0.0500`**.

Identificacao sem ambiguidade: e' a constante que produz a `reason`

```
edge -0.1256 abaixo do minimo +0.0500 (acc 0.2680 vs palpite 0.3936)
```

devolvida no payload de `/api/ai/predict` quando `available=false`. O EA
**nao tem** essa constante (provado por `findstr` em toda a arvore `.mq5`/`.mqh`
em D-149); ele apenas reimprime a `reason` em `AI/AIConnector.mqh:478/480`.
O ficheiro do servidor e' o do gateway (`backend\fastapi_gateway.py`, o que
declara `@app.get("/api/ai/predict")`).

**Valor novo: `0.02`.**

## 2. O que NAO tocar

- **Nada no EA.** Nenhuma recompilacao, nenhum deploy, nenhuma alteracao em
  `Core/`, `AI/`, `Filters/`, `Management/`. O binario declarado continua
  `71ED34C690C9593D209A69E95F0EFFB6` (977 654 B, 10/11 02:23:07).
- **Nenhum input de grafico.** O perfil vivo `XAU_AI_PRO_15CHARTS_Q071` fica
  como esta' (o congelamento do D-147 continua a valer).
- **Nenhuma posicao, ordem ou parametro de risco** (`RiskPercent=0.5`,
  `MaxDailyLossUsd=600` intocados).
- **Nenhuma mudanca de porta, de modo de execucao ou de token** enquanto fizer
  esta alteracao. As 6 flags de execucao continuam a 0 (modo LEITURA).

## 3. O que o piso faz e nao faz (para o CMD nao prometer a mais)

- **Faz:** deixa de recusar 5 dos 15 simbolos que o EA ja' pede. Universo
  operavel passa de **1** (so' XAUUSD) para **5** nominais.
- **Nao faz:** nao cria pedidos novos, nao aumenta o numero de graficos, nao
  melhora a qualidade do modelo. O `edge` e' **estatico por simbolo** (P2.27:
  `min = max = ultimo` nas 4 amostras de cada um dos 15, e os mesmos valores de
  07/11). Logo o piso e' uma **whitelist**, nao um filtro dinamico.

Valores que passam a `available=true` (medidos hoje):

| Simbolo | edge |
|---|---|
| USDCAD | +0.0317 |
| USDCHF | +0.0253 |
| USDJPY | +0.0248 |
| USDBRL | +0.0240 |
| NZDUSD | +0.0225 |

Ficam de fora, entre outros: **USDSGD +0.0193** (a 0.0007 do piso),
USDRUB +0.0166, USDCZK -0.0072, EURUSD -0.0161, AUDUSD -0.0184,
GBPUSD -0.0207, USDCLP -0.0281, USDSEK -0.0403, USDCOP -0.0584,
USDCNH -0.1256.

## 4. Teste de aceitacao (o que conta como "feito")

1. `GET /api/ai/predict?symbol=USDCAD&timeframe=H1` com `Authorization: Bearer`
   -> **HTTP 200** com **`available=true`**.
2. O mesmo para **USDCHF, USDJPY, USDBRL, NZDUSD**.
3. `GET ...?symbol=USDCNH` -> continua **`available=false`** (o piso novo tem
   de continuar a cortar o pior simbolo; se o USDCNH passar, o valor aplicado
   nao e' 0.02).
4. **`GET ...?symbol=XAUUSD` -> continua `available=true`** (nao regredir o
   unico com modelo publicado).
5. No journal do EA, nas duas vagas seguintes: `[AI] INDISPONIVEL` deve cair de
   ~14 para ~10 por ciclo, e devem aparecer linhas `[AI] PYTHON` para os
   simbolos novos.

## 5. Rollback

Reverter para `+0.0500` e reiniciar o servico. Efeito: volta a 1 simbolo
operavel. Nada disto toca no EA, portanto o rollback e' seguro a qualquer hora
**excepto** depois de 11/11 00:05 servidor, quando muda as condicoes do forward:
nesse caso **nao reverter sem declarar** em `GATE_REAL.md` (G11).

## 6. Depois de executar, declarar

- `DECISOES.md` - bloco do CMD com o valor aplicado, a hora e o resultado do
  teste da seccao 4;
- `GATE_REAL.md` - **G11** (o que o forward vai medir: 5 simbolos, 1 com modelo)
  e **G5** (a projecao de ~61 trades/12M);
- `SYNC_LOG.md` - uma linha.

Sem essa declaracao, o forward continua a medir um regime que ninguem escreveu -
e e' exactamente o erro que o D-143 proibiu.
