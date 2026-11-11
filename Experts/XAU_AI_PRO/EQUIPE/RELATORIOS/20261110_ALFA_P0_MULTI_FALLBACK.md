# P0 MULTI_* — mecanismo entregue, fronteira medida

ALFA · 10/11/2026 20:20 (-03:00) · resposta ao pedido CMD de 10/11 19:50
(`resolver simbolo->classe->MULTI_CRYPTO/FIAT/METALS no gateway; sem recompilar
nem reattach`)

Nada foi compilado, nada foi reanexado, nenhum parâmetro de risco foi tocado.
O binário em forward continua o declarado (MD5 `10C4DF68A60CDDB0252F12C30AF4A86A`).

---

## 1. O que mudou — 2 ficheiros, `+180 / -5`

| Ficheiro | Mudança |
|---|---|
| `backend/ai_inference.py` | resolvedor tenta o modelo da CLASSE (`MULTI_*`) como último recurso; terceiro contrato de features `25F-est-v1` (22 features, com `Timeframe_Cod` e `Classe_Cod`); normalização da coluna de volume; gate de plano com consumidor real |
| `backend/asset_classes.py` | `FIAT` passa a incluir `USDCOP`, `USDCLP`, `USDCZK`, `USDRUB`, `USDSGD` |

Três defeitos reais, todos medidos, foram fechados no mesmo caminho:

1. **O resolvedor nunca chamava a classe.** `_carregar` só tentava
   `<SIMBOLO>_<TF>` e `<SIMBOLO>`. `asset_classes.classe_de()` e
   `nome_do_modelo_multi()` existiam desde 02/10 e não tinham chamador.
2. **O contrato de 22 features não existia no runtime.** `inferir()` despachava
   `XAU-30F-v4` ou, para todo o resto, `25F-v2` (25 features). Os três `MULTI_*`
   são `25F-est-v1` (22): o `predict_proba` levantava e o operador lia
   *"erro na inferencia: ..."*. Era contrato trocado, não modelo ausente.
3. **`KeyError: 'Volume'` no caminho 25F.** O gateway entrega as colunas do MT5
   capitalizadas (`Tick_volume`); `t.reamostrar` agrega com
   `Volume=("Volume","sum")`. A inferência morria com um motivo que mandava
   olhar o servidor quando o dado chegava certo com outro nome (AGENTS §5).

Bónus de §9: `limite_multi_modelos()` estava documentada como *"o `inferir()`
trata 0 como só modelo único"* e **não tinha chamador**. Agora tem: plano sem
MULTI não recebe MULTI (falha fechada). Assinatura local medida: `vips`,
`multi_model=True`, `multi_models=8`.

## 2. A fronteira que os testes obrigaram a fixar

Primeira versão tentava o MULTI **antes** de aceitar a recusa do modelo do
ativo. Resultado medido nos testes: **XAUUSD M5** — reprovado pela governança
por edge negativo — passou a responder pelo `MULTI_METALS`. Uma média de classe
contornava uma recusa medida do próprio ativo.

Regra implementada: **o MULTI é COBERTURA, não substituição.** Ele atende o
ativo que **não tem artefato nenhum**; ativo com modelo próprio reprovado
continua recusado, com o motivo do próprio modelo.

Prova negativa: 6 testes reprovaram com a versão permissiva, 3 deles por esta
causa (`test_timeframe_sem_modelo_publicado_e_recusado`,
`test_recusa_diz_onde_o_ativo_opera`, `test_simbolo_e_preservado_ao_carregar`).
Com a regra estrita, **zero** falhas novas.

## 3. Prova em dado real do terminal (H1, 600 candles, 20:15)

| Símbolo | Classe | Artefato que decidiu | Disp. | Medida |
|---|---|---|---|---|
| EURUSD | FIAT | EURUSD | não | edge -0.0161 < +0.0200; 2/5 folds |
| GBPUSD | FIAT | GBPUSD | não | edge -0.0207 < +0.0200; 3/5 folds |
| USDJPY | FIAT | USDJPY | não | edge instável 3/5 |
| AUDUSD | FIAT | AUDUSD | não | edge -0.0184 < +0.0200; 0/5 folds |
| USDBRL | FIAT | USDBRL | não | edge instável 2/5 |
| USDCOP | FIAT | USDCOP | não | edge -0.0584 < +0.0200; 1/5 folds |
| USDCLP | FIAT | USDCLP | não | edge -0.0281 < +0.0200; 0/5 folds |
| USDCZK | FIAT | USDCZK | não | edge -0.0072 < +0.0200; 0/5 folds |
| USDRUB | FIAT | USDRUB | não | edge +0.0166 < +0.0200; 2/5 folds |
| USDSGD | FIAT | USDSGD | não | edge +0.0193 < +0.0200; 3/5 folds |
| **XAUUSD** | METALS | XAUUSD (30F) | **SIM** | SELL conf 52.8% (unitário ganha do MULTI) |
| **XAGUSD** | METALS | **MULTI_METALS** | **SIM** | BUY conf 42.8% edge +0.2497 |
| BTC / ETH / SOL | OUTROS | BTCUSD / ETHUSD / SOLUSD | não | edge negativo; classe `OUTROS` ⇒ sem MULTI |
| BNB / XAUT / AAPL / EURTRY | OUTROS | — | não | sem artefato e sem classe (recusa com motivo) |

## 4. O achado que muda o P0

**Os 10 símbolos da frota não estão sem modelo: eles TÊM modelo próprio, e é o
modelo próprio que os recusa por governança.** `USDCOP_H1.pkl`, `USDCLP_H1.pkl`
e companhia existem no disco com edge medido — vários negativos. O que faltava
não era o resolvedor: era edge.

Por isso a regra estrita destrava **um** símbolo nesta conta (XAGUSD), e a
regra permissiva destravaria os 10 — ao preço de sobrepor 10 recusas medidas.

## 5. A segunda parede, medida: o piso de confiança

Confiança que o `MULTI_FIAT` atribuiu a cada par na medição de 20:15:

`USDCLP 34.1 · USDBRL 34.1 · GBPUSD 35.1 · USDJPY 38.0 · USDCOP 38.1 ·
USDCZK 38.6 · EURUSD 39.3 · AUDUSD 40.4 · USDRUB 42.7 · USDSGD 47.6`

Com o piso autorizado **45** (D-174): passaria **1 de 10** (USDSGD).
Com o valor **vivo** nos gráficos (**60.0**, medido hoje): passaria **nenhum**.
`XAGUSD` (42.8%) também ficaria abaixo de 45.

Ou seja: destravar por MULTI, sozinho, **não produz sinal** com o piso atual. O
piso 45 continua não aplicado nos 15 `.chr` — é o passo 3 da cadeia, e sem ele
o P0 não se traduz em operação.

## 6. Estado do gateway: código no fonte, processo no ar ainda velho

- Porta 9011 escutando; o dono do socket não é resolvível
  (`OwningProcess = 0`, `CommandLine` vazio) — processo de outra sessão ou
  elevado. **Não reiniciei nada.**
- Prova de que o processo está velho: `/api/ai/predict?symbol=USDCOP&timeframe=H1`
  responde com o motivo antigo (`edge -0.0584 ...`), e não pelo caminho novo.
- O que falta: **reiniciar o gateway** (é o mesmo uvicorn do fonte; não exige
  rebuild nem build do Tauri). Quem iniciou o processo é que deve reiniciá-lo.

## 7. Validação

```
pytest -q tests/test_ai_inference.py tests/test_governanca_multi.py
→ 111 passed, 3 failed
```

As 3 falhas são **anteriores** a este patch e nenhuma passa pelo código novo:

1. `test_inferencia_usa_as_mesmas_features_do_treino` — espera o hash `25F-v2`;
   o XAUUSD H1 publicado é `XAU-30F-v4` (o teste é anterior ao contrato 30F).
2. `test_usdt_carrega_modelo_usd` e 3. `test_timeframes_capazes_por_ativo` —
   o `BTCUSD_H1` existe mas **não é publicável** na governança de hoje
   (edge -0.0233). `timeframes_capazes` não foi tocado pelo patch e `BTCUSDT`
   cai em `OUTROS`, logo percorre exatamente o mesmo caminho de antes.

`py_compile` 0 erros nos dois ficheiros. Nenhum `.mq5`/`.mqh` alterado.

## 8. Nota lateral (não corrigida)

`InconsistentVersionWarning`: os `.pkl` foram gravados com scikit-learn **1.9.0**
e o `.venv` roda **1.9.1**. Vale para todos os 87 artefatos e já vinha de antes.
Não é o defeito desta noite, mas é um risco de reprodutibilidade a registar.

## 9. Perguntas abertas

**Ao DONO (capital):** o MULTI pode sobrepor a recusa de governança do modelo
do ativo?
 (a) **não** — é o que está implementado; EURUSD/GBPUSD/USDCOP/USDCLP/USDCZK/
     USDRUB/USDSGD continuam recusados;
 (b) sim, para toda a classe (destrava 10, com o rótulo do modelo de classe no
     payload);
 (c) sim, mas só para FIAT, nunca para METALS.

**Ao CMD:** o piso 45 (D-174) continua a faltar nos 15 `.chr` — `MinAIConfidence`
medido **60.0**. Sem ele, mesmo a opção (b) não gera sinal (§5).
