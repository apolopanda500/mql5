# SESSAO 08/11/2026 - DELTA - T2

- **Turno:** 10:20-10:40 (local)
- **Pedido do DONO:** "autorizacao TOTAL"
- **LOCK:** OCUPADO por ALFA desde 10:22 (`P1.3487` + remediacao de G4)
- **Fronteira respeitada:** sem reattach de frota, sem ordem, sem alteracao de
  risco, sem tocar nos ficheiros do P1.3487 (`agente-briefing.ps1`,
  `BRIEFING_ATUAL.md`), sem escrever em `IDS`/`PENDENCIAS`/`PRESENCA`/`SYNC_LOG`
  (a saida do LOCK e' do ALFA, D-108).

---

## 1. Por que esta sessao existe

O plano D-089 promete medir, na janela forward de 09/11 00:05: `TREND CONTRA OK`
com selo Q-079/B, folga ATR em H1, entradas IA vs nao-IA e `TOTAL=` por simbolo.
Com o mercado fechado nao se mede nada - mas da' para auditar **se os
instrumentos existem, imprimem e com que frequencia**. Foi isso que fiz.

Resultado: tres dos quatro criterios tinham premissa errada.

## 2. Achados (detalhe e tabelas em `RELATORIOS/20261108_AUDITORIA_INSTRUMENTOS_DELTA.md`)

| # | Achado | Numero |
|---|---|---|
| F1 | A folga ATR do Q-079/B **nunca disparou** | `dentro da folga` = **0** e `Q-079/B` = **0** em todo o historico |
| F2 | Os 57 `TREND CONTRA OK` sao **100% fallback**, nao folga | `contramao PERMITIDA` = 57 (mesma distribuicao) |
| F3 | O fix D-086 nao tem **nenhuma** amostra viva | v1.2.187 rodou 21 min e v1.2.188 desde 06:01, ambos sem tick |
| F4 | `TOTAL=` existe mas e' raro | **4** linhas em 8 dias, todas `TOTAL=100.00` (pre-v1.2.184) |
| F5 | `PTS=` existe no fonte e **nunca** foi impresso | 0 amostras |
| F6 | O binario de 10:25:59 foi um **compile**, nao reattach | `metaeditor.log`: `0 errors, 0 warnings, 32823 ms, cpu='X64 Regular'` |
| F7 | Frota 15/15 v1.2.188, USDBRL em M5 | `[START]` 09:34:28.139 -> 09:34:29.318; `(USDBRL,M5)` as 09:34:29.311 |

### Prova documental do bug que o D-086 fechou (F3)

Mesmo simbolo, mesma tarde de 05/11, comportamentos opostos:

```
16:00:22  [VALIDATION] BLOCK | TREND BUY | USDCNH | contramao vetada | ADX indisponivel
16:42:02  ... ultima das 23 linhas iguais
16:46:24  [VALIDATION] TREND CONTRA OK | USDCNH | Signal=1 | contramao PERMITIDA | cenario LATERAL | ADX=0.0 | lote x0.75
18:57:44  ... ultima das 54 linhas iguais
```

Vetou e depois **permitiu contra-tendencia com ADX indisponivel**. E' o defeito
que o veto `adx<=0.0` da v1.2.187 corrige. O fonte actual tem a ordem correcta
(`adx` lido e vetado antes da folga) - mas isso e' leitura de codigo, **nao**
evidencia de campo.

## 3. Correcao de premissa que precisa de registo

**P1.3476 estava invertido.** Nao e' "`TOTAL=` nao e' medivel". O tag existe,
imprime o valor e o formato e':

```
[SCORE] CALCULATED | Symbol=<s> | Signal=<n> | EMA= | RSI= | ADX= | AI= | WARMUP= | PTS= | TOTAL=
```

O problema real e' **taxa**: `if(logOnce && DecisionLogDue(symbol,"SCORE",900))`
exige o gate de 1x/minuto **e** os 900 s por simbolo no mesmo tick - na pratica
4 linhas em 8 dias. Para a janela forward isto significa: `TOTAL=` e' medivel,
mas com N quase zero, e `PTS=` nao tem base nenhuma.

Nao editei `IDS.md` nem `PENDENCIAS.md` (LOCK). **Pedido ao ALFA na saida do
LOCK:** reformular P1.3476 de "tag ausente" para "taxa de emissao insuficiente
para amostragem" e abrir entrada para `PTS=` sem amostra.

## 4. Ficheiros criados por mim neste turno

| Ficheiro | Bytes | Natureza |
|---|---|---|
| `EQUIPE/RELATORIOS/20261108_AUDITORIA_INSTRUMENTOS_DELTA.md` | 9 694 | relatorio da auditoria |
| `EQUIPE/tools/delta-captura-d089.ps1` | 5 753 | captura da janela forward, **somente leitura** |
| `EQUIPE/SESSAO_20261108_DELTA_T2.md` | este | registo do turno |

Nao alterei nenhum ficheiro existente de outro agente.

### Validacao do script

Rodado contra dois dias fechados, e reproduziu as contagens feitas a mao:

- `20261105`: Q079=0, fallback=54, vetoADX=23, score=1 (bate 54/23/1);
- `20261108`: Q079=0, fallback=0, vetoADX=0, score=0; IA ON so XAUUSD (3),
  IA OFF nos outros 14 (2 cada) - bate com o estado medido do gateway.

Correccao aplicada durante o teste: `-like '*[AI] PYTHON*'` nunca casava, porque
em PowerShell `[AI]` e' classe de caracteres (casaria `A ` ou `I `). Trocado por
`.Contains('[AI] PYTHON')`.

## 5. Regra de aceitacao que proponho para a janela forward

> So conta como exercicio do Q-079/B a linha de `TREND CONTRA OK` que contiver
> **`dentro da folga`**. `TREND CONTRA OK` por `contramao PERMITIDA` **nao**
> prova o Q-079/B e nao deve promover nada.

Sem esta regra repetimos o erro das 57 linhas antigas: parecem sucesso do gate e
sao o caminho de fallback.

## 6. Risco residual aberto

Diferenca de 224 bytes entre o binario em producao (970 168 B, MD5 `943DB7CB...`,
carregado 09:34:28) e o binario em disco (969 944 B, MD5 `5C99AF0C...`, compile
de 10:25:59). Mesma arvore de fonte (git limpo, fontes congeladas desde 05:58:48;
commit `86d1ac96` de 10:26:16 e' so documentacao), logo e' diferenca de modo de
build (`build_project` vs `compile_file`), nao de codigo. A fechar com A/B
controlado **depois** do LOCK - nao durante.

## 7. Estado no fecho

- `GATE_REAL` **2 de 11** (intocado); forward **0 de 30**, arranca 09/11 00:05.
- Nao existe 10/10 e nao vai ser declarado; o maximo e' x/11.
- Conta real **PROIBIDA** por medicao. Conta 113568614 plana, 12 636,32 USD.
- Mercado fechado: `trade_server_last_known_time = 2026-11-06T23:59:59`.
- **0 compiles meus, 0 corridas de tester, 0 reanexos, 0 ordens, risco intocado.**
