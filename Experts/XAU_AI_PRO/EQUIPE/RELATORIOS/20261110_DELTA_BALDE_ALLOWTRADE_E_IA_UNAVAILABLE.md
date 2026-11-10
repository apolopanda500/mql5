# RELATORIO DELTA - 10/11/2026 10:20 local (servidor 15:20)

**Leitura ao vivo do journal do EA, janela 10:16:00 - 10:19:00.**
Papel: DELTA (medicao de mercado vivo + dossier). Nao declarei GATE_REAL nem
assinei DOSSIE_FINAL.md. Nao assinei nada. Nada foi compilado, publicado ou
reiniciado por mim nesta ronda.

---

## 1. O que mudou desde o ultimo relatorio

1. **Os quatro SELL manuais de XAUUSD foram fechados a mao** as 15:16:19-15:16:21
   servidor: +10,60 +2,34 +2,00 +1,91 = **+16,85 USD**. O `[POSITION GUARD]`
   deixou de disparar (ultima linha 10:16:02.885). Saldo 12593,83 -> 12610,68.
   O P1.3549 (quatro posicoes sem stop) fica FECHADO por medicao.
2. **O bloqueio mudou de dono**: ja' nao sao as posicoes manuais, e' o **MTF**.
   As 10:16:21.7, primeiro ciclo com o caminho livre, o XAUUSD passou
   `Spread=13.00 | Max=2445.25`, `ADX=37.48 | Min=18.00`, `REGIME OK | TREND_UP`
   e `AI OK`, e parou em `[VALIDATION] BLOCK | MTF` ->
   `DECISION BLOCKED | Reason=VALIDATION: MTF`.
3. **Correcao da minha propria leitura (D-166)**: no RESUMO,
   `CanOpen=240 Stale=564 NoSignal=3384 AllowTrade=42` soma exatamente
   `bloqueios=4230`. Ou seja, **`AllowTrade` e' um balde de BLOQUEIO, nao de
   permissao**. A conclusao do D-165 nao muda (42 de 42 sinais morreram na
   VALIDACAO), mas a frase que publiquei estava errada na letra e fica corrigida.

## 2. O que esta' a acontecer agora (10:18:58)

| Item | Valor medido |
|---|---|
| Posicoes EA / manuais | 0 / 0 |
| Ordens pendentes | 0 |
| Saldo / equity / margem | 12610,68 / 12610,68 / 0,00 |
| Trades do EA hoje | 0 |
| Ultimo sinal | XAUUSD BUY, 10:16:21.753, recusado pelo MTF |
| IA (XAUUSD) | **UNAVAILABLE 0.0%** (era `BUY 62.0% (ha 0s)` as 10:12:57) |
| Portao do gateway | vivo (`HTTP 401` sem token em `127.0.0.1:9011`) |
| `dia fechado` | -61,80 de 40,00 USD (-154%) - inalterado depois dos +16,85 |

## 3. Dois factos novos que o DONO tem de saber, em linguagem simples

**a) A IA desapareceu do jogo e ninguem travou nada.**
As 10:12:57 o robo tinha uma opiniao da IA (compra, 62% de confianca, fresca).
As 10:17:57 ja' nao tem: escreve `UNAVAILABLE 0.0%`. O servico de IA esta' de
pe' - respondeu-me `HTTP 401` agora mesmo, que e' o que ele responde a quem nao
leva token. Portanto nao e' o servico que caiu: e' o robo que deixou de receber
opiniao nova. E o problema pratico e' este: como `AllowTradeWithoutAI=true`,
**se o MTF aprovasse um sinal, o robo entrava sem IA nenhuma**. A "autoridade da
IA" existe no papel, mas hoje esta' ausente e nao trava.

**b) O indicador do sistema esta' a ser recarregado sem parar.**
No journal do terminal, o indicador `KCI_Directional_Matrix` e' recarregado nos
15 simbolos a cada 3-7 segundos, e em paralelo aparecem
`[ATR] HANDLE RECRIADO | erro=4807` em nove simbolos. Isto e' o robo a recriar
handles de indicador em ciclo: gasta CPU, enche o log e e' a explicacao mais
provavel das leituras absurdas que ja' vimos (`EMA=59958` com preco a 3277,
`ATR=59958`). Nao se corrige agora: mexer nisto e' mexer em codigo, e o binario
esta' congelado (MD5 71ED34C690C9593D209A69E95F0EFFB6). Fica medido.

## 4. O que eu NAO fiz (de proposito)

- **Nao desliguei o MTF.** Desliga-lo faria entrar trades, mas mudaria o que
  estamos a medir no forward de 30 dias. E' decisao escrita do DONO, nao minha.
- Nao toquei em nenhum input, nao recompilei, nao reiniciei o gateway.
- Nao declarei GATE_REAL verde nenhum. G11 continua 0/30.

## 5. Tres perguntas ao DONO (precisam de resposta escrita)

1. **Quer medir o forward com o MTF ligado (como esta') ou desligado por um
   periodo declarado?** Com o MTF ligado, a medicao diz "o filtro M15 corta
   quase tudo". Com ele desligado, medimos o resto do sistema. As duas coisas
   sao uteis; nao sao a mesma coisa, e o dossier tem de dizer qual foi.
2. **Quer a IA obrigatoria no forward?** Hoje `AllowTradeWithoutAI=true`, e com
   a IA em `UNAVAILABLE` isso significa que o robo pode entrar sem ela. Se a
   resposta for "a IA manda", o valor tem de ser mudado ANTES das 11/11 00:05
   servidor - depois disso o congelamento fecha a porta.
3. **Os fechos manuais de hoje foram seus?** Se sim, fica registado que os
   +16,85 sao manuais e nao do robo (o contador do dia nem os soma). Se houver
   novas intervencoes manuais dentro da janela, o forward de 30 dias fica
   contaminado do mesmo jeito que a leitura de hoje.

## 6. Registos do canal

- `DECISOES.md` -> **D-166** (correcao de leitura do D-165).
- `IDS.md` -> **P1.3572** (balde AllowTrade), **P1.3573** (IA UNAVAILABLE com
  portao vivo + `AllowTradeWithoutAI`), **P1.3574** (`dia fechado` nao absorve
  manuais), **P1.3575** (recarga continua do custom indicator).
- `SYNC_LOG.md` -> 1 decisao + 3 alertas + 1 nota, todos com hora 10:20.
- Lock `edit` do DELTA tomado as 10:19 e libertado no fim da escrita.

---

*DELTA - medicao, nao declaracao. Qualquer numero acima foi lido, nao inferido.*
