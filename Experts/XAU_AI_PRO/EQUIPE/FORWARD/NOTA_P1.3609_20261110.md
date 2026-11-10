# NOTA P1.3609 - o gate lia as tags que o EA deixou de escrever

**Data:** 10/11/2026 18:22 (local) = 23:22 (servidor)
**Alcance:** `Tools\forward-gate.ps1`, `Tools\pulso-forward.ps1`. **Nenhum** `.ex5`,
`.chr`, `.tpl` ou ordem foi tocado. O binario continua
`10C4DF68A60CDDB0252F12C30AF4A86A` / 1 023 258 B / 16:56:41 / v1.2.203.

---

## 1. O defeito

O P1.3607 corrigiu o carimbo da hora, mas deixou o gate a ler **tags que a
instancia em curso nao escreve**. Medido no journal `MQL5\Logs\20261110.log`
(6 751 linhas):

| tag | emissoes hoje | ultima | de onde o gate tirava |
|---|---|---|---|
| `[STATUS] HEALTHY` | 1 | 09:09:35 | P/L dia, Equity, DD, Orders, Positions, perda % |
| `[SCANNER] RESUMO` | 51 | 17:10:12 | sinais, trades, AllowTrade, visitas |
| `[RESUMO] master=` | 175 | 18:19:11 (5 min) | **nao era lida** |
| `[HEALTH] HEALTHY` | 18 | 18:10:41 | **nao era lida** |
| `HTTP 1003` | 82 | 17:09:04 | contador 1003 |

A frota foi recarregada as **17:10:11** (`[HEALTH] uptime=3630s` as 18:10:41). A
instancia nova escreve o resumo **de 5 em 5 minutos** como `[RESUMO] master=SIM`
- outra tag, com o P/L do dia, os trades e as posicoes la dentro:

```
18:08:41 [RESUMO] master=SIM | posicoes: 0 EA (+0.00 USD) + 0 manual |
         dia fechado: -61.80 de 40.00 USD (-154% da meta diaria) |
         flutuante conta: +0.00 | trades=0 | IA(USDRUB)=UNAVAILABLE 0.0% (ha 0s)
```

O `[SCANNER] RESUMO` (15 min) foi emitido pela instancia **USDSGD** e parou as
17:10:12, um segundo depois do reload. Nao voltou em 70 minutos. O gate, ao nao
encontrar tags novas, continuava a mostrar `sinais=11 / trades=0 / P/L=-61.8`
como se fossem de agora. **E a mesma classe do P1.3604 e do P1.3606:** o
instrumento a certificar o que nao aconteceu.

## 2. O que foi corrigido (sem recompilar)

1. **`[RESUMO] master=`** passa a ser lida. P/L do dia, trades e posicoes vem
   dela quando ela e **mais recente** do que as outras fontes; a origem fica
   escrita por campo (`origem: {pl_dia: master, trades_dia: master, ...}`).
2. **`Files\Data\system_status.json`** passa a ser lido: e o retrato que o
   proprio EA escreve de minuto a minuto (`generated_at` em hora do servidor).
   Daqui vem `equity_live` (12 610,68), `balance`, `gate_ok`, `health`,
   `posicao`. A equity do jornal (12 593,83) **continua registada** ao lado,
   com a hora 09:09:35 - nao se apaga a prova, acrescenta-se a fonte boa.
3. **DD % ao vivo**: `(pico - equity) / pico`, com o `pico=` do
   `[SESSION] estado salvo` (12 660,19) e a equity ao vivo. Hoje: **0,39 %**
   (limite 6,0 %). Antes a coluna dizia `0`, que era a `Amplitude` de uma linha
   das 09:09. Se a leitura ao vivo faltar, cai para a `Amplitude` antiga.
4. **Cada numero leva a hora da fonte**: a tabela ganhou a coluna
   `Dados ate (P/L,funil)` = `18:19:11,17:10:12`; o `ultima_medicao.log` imprime
   as quatro horas (status, master, funil, 1003) e a equity ao vivo.
5. **`pulso-forward.ps1`** deixou de ter a mesma cegueira: cada linha do
   `_SYNC\pulso.jsonl` passa a levar `dados_resumo` e `dados_master`, e os
   `trades` vem da fonte mais recente.

## 3. O que continua aberto (P1.3608 - e do EA, nao do gate)

O `[SCANNER] RESUMO` (15 min) e o `[DIAGSCAN]` (5 min) **nao voltaram** depois
do reload das 17:10:11. O EA esta vivo: `[AI]` 16 linhas na hora 18, `[SESSION]`
a 18:06:22, `[RESUMO] master=` a 18:19:11, ficheiros de permissao reescritos a
18:18-18:19. **Nao ha correcao sem recompilar** - e recompilar reinicia a janela
declarada. Consequencia pratica: a coluna `Sinais`/`AllowTrade` fica congelada
no valor das 17:10:12 (hoje: 11 e 11) ate o EA ser reconstruido.

**Opcoes para o DONO (decisao, nao tecnica):**
- (a) aceitar a lacuna: P/L, trades, equity, DD e frota continuam medidos ao
  vivo; perde-se so a contagem de sinais por dia;
- (b) recarregar os 15 graficos: nao mexe no `.ex5`, mas arrisca nova queda do
  bit de permissao e exige F7 nos 15 (foi o que aconteceu as 17:10);
- (c) recompilar para corrigir a cadencia: **anula os 30 dias** pela regra
  D-139/D-141. Nao recomendado dentro da janela.

## 4. Estado no fecho

- Declaracao: dia 1 = 10/11/2026, janela ate **10/12/2026 22:31 (servidor)**,
  `janela_inicio_servidor` **intacta** em `10/11/2026 22:31`, `janela_congelada=true`,
  `historico_declaracoes[]` com 2 eventos (17:37:54 e 18:11:13).
- Gate 18:22:36: 23 amostras no dia, MD5 `sim`, governanca `sim`, frota 15/15,
  P/L -61,80 (master 18:19:11), DD 0,39 %, equity ao vivo 12 610,68.
- Frota: 15/15 LIGADO, `code=0`, 0 desligado.
- Conta: 0 posicoes, 0 ordens, equity 12 610,68 USD.
