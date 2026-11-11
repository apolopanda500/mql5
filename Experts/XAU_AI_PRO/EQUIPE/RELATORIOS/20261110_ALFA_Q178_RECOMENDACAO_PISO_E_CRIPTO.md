# 2026-11-10 · ALFA · Q-178: recomendação do piso de confiança + estudo dos 3 "cripto"

> Pedido do DONO: *"Q-178 quero a recomendada / Os 3 cripto acho melhor estudar
> mais esta pergunta"*.
>
> Este relatório entrega as duas coisas. Todos os números foram medidos nesta
> máquina às 20:44–21:10 de 10/11/2026, com o `.venv` do projeto, os artefatos
> publicados em `Python/models` e candles reais do MT5 desta conta. Nada foi
> alterado em `.mq5`, `.ex5`, `.chr` ou `.pkl`.

---

## 1. Recomendação em uma linha

**(d) — não mexer no piso até ao fim do forward.** E, quando o forward fechar, a
decisão não deve ser sobre o piso: deve ser sobre a **base de comparação da
governança**, que hoje aprova um modelo que perde para dizer sempre a mesma
coisa.

As opções (a) e (b) não afinam o filtro — **ligam uma torneira**. A opção (c)
não é executável nesta janela.

---

## 2. O que sustenta a recomendação

### 2.1 O piso 60.0 não é rigoroso: é INALCANÇÁVEL

`MinAIConfidence` vivo nos gráficos = `60.0` (`Config.mqh:636`). A confiança que
o `ai_inference` publica é `max(probs)*100` — e os três MULTI são **triclasse**,
então o teto aritmético dessa grandeza fica perto de 1/3 + margem, não de 100.

Máximo de confiança observado em ~3000 barras H1 reais, por símbolo da frota:

| classe | símbolo | mín / p10 / p50 / p90 / **máx** |
|---|---|---|
| MULTI_FIAT | USDCOP | 33.8 / 37.3 / 39.6 / 43.4 / **53.7** |
| MULTI_FIAT | USDBRL | 33.5 / 36.8 / 39.4 / 43.5 / **52.2** |
| MULTI_FIAT | USDSGD | 34.7 / 38.4 / 40.3 / 43.5 / **52.1** |
| MULTI_FIAT | EURUSD | 34.5 / 37.8 / 40.3 / 44.5 / **54.6** |
| MULTI_METALS | XAUUSD | 37.1 / 42.2 / 45.0 / 48.3 / **53.1** |
| MULTI_METALS | XAGUSD | 38.4 / 41.9 / 45.0 / 48.2 / **52.6** |
| MULTI_CRYPTO | BTC | 37.6 / 39.2 / 40.6 / 42.9 / **52.9** |
| MULTI_CRYPTO | ETH | 37.6 / 39.2 / 40.7 / 43.0 / **50.8** |

**Nenhum símbolo, em nenhuma barra, chega a 60.** O piso vivo não está a
selecionar qualidade: está desligado. Isso muda a pergunta da Q-178 — não é
"qual o piso certo", é "quer ligar isto, e a que preço".

### 2.2 Quanto cada piso candidato deixa passar

Taxa de sinal = fração das barras com rótulo BUY/SELL **e** confiança ≥ piso.
Rotulo NEUTRAL nunca opera, mesmo com confiança alta.

| símbolo | piso 40 | piso 42 | **piso 45** | piso 48 | piso 60 |
|---|---|---|---|---|---|
| USDCOP | 41.0% | 16.8% | **5.1%** | 1.3% | 0.0% |
| USDBRL | 39.3% | 18.2% | **5.7%** | 1.5% | 0.0% |
| USDSGD | 56.0% | 19.0% | **5.6%** | 1.1% | 0.0% |
| EURUSD | 55.8% | 23.3% | **8.6%** | 2.0% | 0.0% |
| XAUUSD | 98.6% | 91.3% | **49.6%** | 12.5% | 0.0% |
| XAGUSD | 98.9% | 89.4% | **49.5%** | 11.8% | 0.0% |
| BTC | 69.4% | 20.2% | **2.1%** | 0.2% | 0.0% |
| ETH | 69.9% | 22.7% | **2.1%** | 0.2% | 0.0% |

Leitura: a 45 o MULTI_METALS opera **metade das barras**; a 40 opera quase
todas. Um piso que deixa passar 98% das barras não filtra nada — é um
interruptor.

### 2.3 O que passa pela torneira não é sinal: é direção constante

Distribuição dos rótulos previstos (cenário A, o que o `inferir` serve hoje):

- FIAT: **85.3% / 90.1% / 89.5% de SELL** (USDCOP, EURUSD, USDSGD)
- METALS: **98.8% / 99.0% de BUY**
- CRYPTO: 54.2/45.8 (BTC) e 55.5/44.5 (ETH)
- NEUTRAL: **0.0% a 1.0%** em todos

Um modelo que diz "SELL" 90% das vezes no FIAT e "BUY" 99% das vezes nos metais
não está a escolher direção; está a repetir a classe dominante do alvo. Baixar o
piso não melhora a escolha — só aumenta a frequência com que a mesma aposta é
repetida.

### 2.4 Homem contra o palpite: o modelo perde

Mesmas linhas, mesmo construtor de alvo (`train_v2.construir_target`,
horizonte H1 = 2 barras), ~3000 barras H1 reais por símbolo:

| classe | símbolo | acerto do modelo | acerto de um preditor CONSTANTE | modelo − constante |
|---|---|---|---|---|
| MULTI_FIAT | USDCOP | 0.3921 | 0.3918 | **+0.0003** |
| MULTI_FIAT | EURUSD | 0.3464 | 0.3491 | **−0.0027** |
| MULTI_METALS | XAUUSD | 0.3188 | 0.3715 | **−0.0527** |
| MULTI_METALS | XAGUSD | 0.3041 | 0.3621 | **−0.0580** |
| MULTI_CRYPTO | BTC | 0.3618 | 0.3825 | **−0.0207** |
| MULTI_CRYPTO | ETH | 0.3681 | 0.3998 | **−0.0317** |

"Preditor constante" = dizer sempre a classe mais frequente da janela. Em 4 de
6 símbolos o modelo acerta **menos** do que não dizer nada. Nos 2 restantes o
empate está na quarta casa decimal.

### 2.5 O `edge` publicado compara com a base errada

`train_multi._walk_forward_estacionario` (linhas 278 e 427):

```python
palpite = 1.0 / max(int(base["Target"].nunique()), 2)   # = 1/3
"edge": acc - palpite,
```

A base honesta de um alvo desbalanceado é a taxa da **classe mais frequente do
fold de teste**, não `1/n_classes`. O alvo medido nesta janela é ~1/3 por
classe (25–40%), então a distorção não é enorme — mas ela esconde exatamente o
que importa: o modelo não supera o palpite trivial.

Há ainda **dois `edge` diferentes no mesmo artefacto**, com 3 a 5x de distância:

| artefacto | `metrics.edge` | `metrics.accuracy` | edge dos folds |
|---|---|---|---|
| MULTI_FIAT | 0.1853 | 0.5186 | 0.0302 … 0.0672 |
| MULTI_METALS | 0.2497 | 0.5831 | 0.0574 … 0.0685 |
| MULTI_CRYPTO | 0.1816 | 0.5150 | 0.0424 … 0.0653 |

Dois lados do mesmo dado com nomes diferentes (AGENTS §5). Qual deles a
governança comparou com `min_edge +0.0200` precisa ser respondido por quem
escreveu o `train_multi` — não por mim.

### 2.6 Desvio treino × inferência: real, medido, mas NÃO é a causa

`train_multi` escreve `ATR`/`RSI`/`ADX` **reais** no quadro antes de montar as
features (`train_v2._rsi_de_wilder`, `_adx_de_wilder`). No `inferir`, as candles
vêm do MT5 **sem essas colunas**, e `features_estacionarias._coluna` aplica o
padrão: **ADX = 0.0 e RSI = 50.0 constantes** — 4 features degeneradas
(`ADX`, `RSI`, `RSI_Diff`, `ADX_Change`).

Medi o mesmo modelo com e sem os indicadores reais:

| símbolo | modelo−constante (A: ADX=0/RSI=50) | modelo−constante (B: ADX/RSI reais) |
|---|---|---|
| USDCOP | +0.0003 | +0.0027 |
| EURUSD | −0.0027 | +0.0017 |
| XAUUSD | −0.0527 | −0.0480 |
| XAGUSD | −0.0580 | −0.0574 |
| BTC | −0.0207 | −0.0050 |
| ETH | −0.0317 | −0.0327 |

O desvio existe e é um defeito a corrigir, mas vale ~0.001–0.014: **não é ele
que tira o edge**. Corrigi-lo não salva o modelo, e é por isso que não o estou a
"consertar" por conta própria no meio do forward.

### 2.7 A opção (c) não existe dentro desta janela

O EA compara **apenas** confiança:

- `Config.mqh:636` → `input double MinAIConfidence = 60.0;`
- `AIEngine.mqh:115` → `if(confidence<MinAIConfidence)`
- `AIEngine.mqh:354` → `if(AI_Score<MinAIConfidence)`
- `AIEngine.mqh:654` → `return(score >= MinAIConfidence);`
- `AIConnector.mqh:576` → `AI_Score=StringToDouble(jsonConfidence);`

**Não existe nenhum consumidor de `edge` no EA.** Um critério por edge exigiria
recompilar e reanexar o v1.2.203 congelado — o que anula a validade do forward
em curso. (c) fica para a v1.2.204, e mesmo lá: com edge medido ≤ 0, um piso
por edge bloquearia 100% dos sinais.

---

## 3. Recomendação formal (Q-178)

**(d) — não alterar `MinAIConfidence` durante o forward**, por três razões
medidas, nesta ordem de peso:

1. O piso vivo não está a rejeitar um bom sinal; está a rejeitar um modelo cujo
   máximo de confiança é 50.8–54.6. Mudá-lo para 45 não "afina": muda a regra.
2. O que passaria é direção constante (85–90% SELL no FIAT, 98–99% BUY nos
   metais) com acerto igual ou inferior a um palpite trivial. Numa conta REAL,
   isso não é cobertura — é repetição de uma aposta sem medida de habilidade.
3. (c) exigiria alterar o EA congelado. (a) e (b) não têm como ser validadas
   dentro do forward, porque mudam o objeto que o forward está a medir.

E uma consequência que o DONO precisa de saber, porque toca no que ele já
autorizou: **a Q-177 (b) está hoje inerte por construção**. O modelo de classe
pode cobrir o ativo, mas com o piso em 60 nenhuma cobertura chega ao EA. Se o
piso descer sem esta medição, a cobertura da Q-177 (b) começa a produzir ordens
de direção constante — o oposto do que a autorização pretendia.

**Trabalho de casa para depois do forward** (não executado, precisa de decisão):

- corrigir a base da governança para a taxa da classe maioritária do fold;
- reconciliar `metrics.edge` × `edge` dos folds (0.185 vs 0.030–0.067);
- corrigir o desvio ADX/RSI (ou retirar essas features do contrato `25F-est-v1`);
- reavaliar a publicação dos três MULTI à luz da base corrigida — com os
  números de hoje, **nenhum dos três passaria**.

---

## 4. Estudo pedido: os 3 "cripto" — não há cripto nesta conta

Medido em `symbols_total()` = **12 170 símbolos**, pela hierarquia que a
corretora preenche (`SYMBOL_PATH`), que é a única fonte aceite pela AGENTS §3:

| grupo (path) | símbolos |
|---|---|
| `Nasdaq` | 12 004 |
| `Forex` | 126 |
| `Indexes` | 26 |
| `Metals` | 14 |

- símbolos com `crypto` no path: **0**
- `BTCUSD`, `ETHUSD`, `SOLUSD`, `XRPUSD`: **não existem** nesta conta

O que os tickers da frota realmente são:

| ticker | path | descrição da corretora |
|---|---|---|
| `BTC` | `Nasdaq\ETF\BTC` | Grayscale Bitcoin Mini Trust (BTC) — **cota de ETF** |
| `ETH` | `Nasdaq\ETF\ETH` | Grayscale Ethereum Mini Trust (ETH) — **cota de ETF** |
| `SOL` | `Nasdaq\Stock\SOL` | **Emeren Group Ltd American Depositary Shares** — ação solar, **não é Solana** |
| `XRP` | `Nasdaq\ETF\XRP` | Bitwise XRP ETF — **cota de ETF** |

Todos com `digits=2`, `trade_mode=4` e sessão da Nasdaq. Os 154 símbolos cuja
*descrição* fala de Bitcoin/Ethereum/Solana são **todos** ETF ou ações da
Nasdaq (`IBIT`, `GBTC`, `FBTC`, `BITO`, `COIN`, `NCI`, …). Não existe um único
instrumento spot ou derivado de cripto para operar aqui.

**Consequência direta:** aplicar `MULTI_CRYPTO` a `BTC`/`ETH` é alimentar um
modelo treinado em cripto com cotas de fundo norte-americano, com horário de
pregão, 2 casas decimais e spread de 18 pontos no `BTC`. E `SOL` nem sequer é o
ativo que o nome sugere — é uma ADR de energia solar. A classe do ativo não pode
ser deduzida do ticker (é exatamente o defeito que a §3 descreve, agora na
identidade do instrumento, não na lista de ativos).

**E há um detalhe que muda a prioridade disto:** os gráficos de `BTC`, `ETH`,
`SOL` e `XRP` **não estão a operar esses instrumentos**. O input `Symbols` do EA
é uma lista fixa de 15 símbolos — `XAUUSD, USDCLP, USDCOP, USDCZK, USDRUB,
USDSGD, GBPUSD, USDJPY, AUDUSD, USDCAD, NZDUSD, USDCHF, USDBRL, USDSEK, USDCNH`
— e `SymbolsFromMarketWatch=false`. Nenhum cripto está nessa lista. Hoje esses
gráficos são **hospedeiros**: dão o timeframe ao EA, que opera a lista de 15.
Portanto "deixar o MULTI_CRYPTO operar" não é abrir uma porta que já está
entreaberta; é uma fiação que ainda não existe.

---

## 5. O que NÃO foi feito, e por quê

- **Não alterei `MinAIConfidence` em nenhum `.chr`.** É o objeto da decisão do
  DONO e o forward está a correr.
- **Não toquei em `.mq5`/`.mqh`/`.ex5`.** A conclusão de (c) é sobre o código
  congelado; alterá-lo anularia o forward.
- **Não corrigi o desvio ADX/RSI** nem a base da governança: ambos mudam o que
  o forward mede, e a medição mostra que não são a causa do problema de fundo.
- **Não reiniciei o gateway** (pedido ao CMD no ciclo anterior; pid 17956
  continua a servir código velho, sem `class_model`). Sem efeito nesta análise,
  que correu pelo fonte com os mesmos artefactos.
- **Não apaguei os 3 `MULTI_*` nem os desmarque como publicáveis.** Isso é
  retirar produto em produção; precisa de autorização explícita.

---

## 6. Perguntas ao DONO

1. Confirmas **(d)** — piso intocado até ao dia 30 — e levas a correção da base
   da governança para o ciclo pós-forward?
2. Sabias que `SOL` nesta conta é **Emeren Group** (ADR solar) e não Solana, e
   que `BTC`/`ETH`/`XRP` são cotas de ETF da Nasdaq? Mantenho os três fora de
   qualquer modelo de cripto até haver um instrumento que seja cripto?
3. Autorizas que eu **proponha** (sem executar) o desmarque de `publicable` nos
   três `MULTI_*`, para discussão no fim do forward?
