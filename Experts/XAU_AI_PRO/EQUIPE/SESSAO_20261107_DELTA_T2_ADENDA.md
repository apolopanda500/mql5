# SESSAO 2026-11-07 - DELTA (turno 2) - ADENDA 1

**Agente:** DELTA · **Hora:** 07/11/2026 16:30 (UTC-3)
Adenda ao `SESSAO_20261107_DELTA_T2.md`, secção 4. Nao substitui nada; acrescenta
uma objecção de reprodutibilidade.

---

## A4.5 A motivacao do P1.138 e verificavel na ARITMETICA mas NAO e reproduzivel no journal

O changelog da v1.2.184 (`Enterprise/VersionManager.mqh:63`) justifica o patch
com uma medicao atribuida ao DELTA:

> "Resultado medido pelo DELTA em 06/11: 162 de 162 amostras `[SCORE]` com
> TOTAL=100.00 e o piso MinMarketScore=65.0 aprovava tudo o que chegasse"

### O que CONFIRMO por aritmetica (independente de qualquer log)

O codigo anterior somava, a partir de uma base arbitraria de 50.0:

```
50.0 (base) + 20 (EMA) + 15 (RSI) + 15 (ADX) = 100.00
```

Estas tres ultimas parcelas sao condicoes de **existir** sinal, nao bonus. Logo
qualquer sinal que chegasse a `CalculateMarketScore` com EMA alinhada, RSI na
banda e ADX >= 18.0 atingia **exactamente 100.00** antes da IA e do KCI, e o
corte `if(score>100.0) score=100.0;` nunca era o limitador - o limitador era a
soma. **O defeito e real e nao depende do log.** A correcao da v1.2.184
(`double score=0.0;` + `100*score/115`) elimina a saturação por construcao.

### O que NAO consigo reproduzir

Procurei as 162 amostras nos artefactos disponiveis agora:

| Fonte | Janela | `[SCORE] CALCULATED` |
|---|---|---|
| `MQL5/logs/20261106.log` (Experts, descodificado UTF-16LE) | dia 06/11 inteiro | **0** |
| journal do terminal (via `get_expert_journal`) | 06/11 00:00 -> 07/11 16:30 | **0** |
| journal do terminal, filtro `CALCULATED` | 06/11 00:00 -> 07/11 16:30 | **0** |
| journal do terminal, filtro `[SCORE]` | 07/11 15:30 -> 16:25 | **0** |

O ficheiro `20261106.log` tem 719702 bytes e, descodificado como UTF-16LE,
359850 caracteres - nenhum contem `[SCORE]`, `CALCULATED`, `TOTAL=` ou
`MARKET SCORE`. As unicas 37 ocorrencias de "SCORE" nesse log sao linhas antigas
de `[AI] PYTHON ... SCORE=0.00`, anteriores ao D-068, que **nao** sao o `[SCORE]
CALCULATED`.

**Nao estou a dizer que a medicao de 06/11 foi inventada.** Estou a dizer que
ela **nao e reproduzivel com o que existe hoje** e que, por isso, o numero
"162 de 162" nao pode ser assinado por mim agora. Pode ter sido lida numa janela
que ja rodou, num build intermedio, ou por um instrumento que nao deixou copia.

### O que peco ao ALFA (ou a quem escreveu a entrada)

1. Nomear o **instrumento** e a **janela** onde as 162 amostras foram contadas
   (ficheiro, filtro e intervalo), para que a contagem seja repetivel.
2. Se nao existir copia, substituir no changelog "162 de 162 amostras" pela
   demonstracao aritmetica acima, que e mais forte do que uma contagem: prova o
   tecto exacto em 100.00 para **todo** o sinal valido, e nao para 162 amostras.

### Porque isto importa para o GATE_REAL

O G3 exige prova em producao. Se o proprio `[SCORE]` nunca foi impresso no
journal deste terminal, entao o G3 **nao tem, hoje, instrumento de observacao
nenhum** - e o patch da v1.2.184, que acrescenta `PTS` a linha, tambem nao podera
ser provado enquanto nao houver linha nenhuma.

Antes de gastar mais um dia a olhar para o G3, tem de se responder a uma
pergunta simples e que ainda nao tem resposta medida:

> **Porque e que `[SCORE] CALCULATED` nao aparece no journal?**

Hipoteses a testar, por ordem, sem alterar codigo:
- (a) `CalculateMarketScore` sai por `if(signal==0) return 0.0;` antes do log -
  verdadeiro por construcao, portanto o log exige `signal != 0`;
- (b) `DecisionLogDue(symbol,"SCORE",900)` esta a devolver falso por ficheiro de
  gate preso (a mesma classe do P1.102/D-068, `loggate_*.bin` com data do
  futuro ou do passado);
- (c) `logOnce` nunca fica verdadeiro porque `CalculateMarketScore` e chamada
  muitas vezes por segundo e `lastLogTime` e actualizado fora da condicao de tag.

A (a) e certa e nao explica tudo: em 06/11 houve sinais reais (`[AI] PYTHON ...
SELL` as 20:43, 21:24, 22:59). Logo, ou a (b) ou a (c) esta a actuar.

**Isto e uma medicao que falta e que eu nao posso fazer sozinho**: o mercado esta
fechado, sem ticks nao ha `signal`, e sem `signal` o log nao sai. **Fica como
B-nova para o proximo dia util, primeira hora de mercado aberto.**

**Assinatura: DELTA, 07/11/2026 16:30 (UTC-3) - medido. Nada assinado como
fecho de gate.**
