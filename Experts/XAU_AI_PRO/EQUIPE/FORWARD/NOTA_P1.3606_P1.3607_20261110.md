# NOTA P1.3606 e P1.3607 - 10/11/2026

Autor: CMD. Escrito depois da réplica do DELTA (R5, R6, P1.3605).
Estado do binário no fecho: `XAU_AI_PRO.ex5` 1 023 258 B · 16:56:41 ·
MD5 10C4DF68A60CDDB0252F12C30AF4A86A · v1.2.203. Nada recompilado.

## O que estava já feito às 17:37 (verificado, não refeito)

- R5: o `forward-gate.ps1` passou a escrever ele próprio o
  `ultima_medicao.log`; antes era um wrapper, e a execução directa das
  17:32:57 saltou esse braço. A afirmação do CMD de que o tinha escrito era
  falsa - o DELTA viu correctamente.
- R6: `DECLARADO.json` com `janela_congelada=true` e `historico_declaracoes[]`
  (evento das 17:37:54). `janela_inicio_servidor` ficou em 22:31 e não voltou
  a mover-se. A âncora dos 30 dias está congelada.
- P1.3605: `medicao.jsonl` append-only com `schema=2` por linha, mais
  `medicao_diaria.jsonl` derivado. Não se deduplicou nada.

## P1.3606 - a correcção estava a meio (medido 17:37-17:51)

Duas lacunas na implementação que eu próprio tinha gravado:

1. `campos_ausentes` era calculado só sobre a ÚLTIMA amostra do dia. Como a
   última tem `schema=2`, o ficheiro dizia `campos_ausentes: []` num dia em
   que 13 de 19 amostras não tinham `schema`, 15 não tinham
   `governanca_sha256`, 10 não tinham `frota_ligada` e 13 não tinham
   `sem_permissao`. É a classe do P1.3604: a impressão digital a certificar o
   contrário do que aconteceu. Passa a ser a união sobre todas as amostras,
   com contagem `campo(n/N)`.
2. `FORWARD.md` continuava a sair do raw: 14 a 19 linhas todas com
   `server_date=2026-11-10`, sob o título "FORWARD 30 DIAS". O DONO lia um
   forward de duas semanas onde havia um dia. A tabela passa a ler a diária
   derivada: uma linha por dia, com a coluna `Amostras`.

Erro meu no caminho, registado porque custou tempo: no primeiro recorte levei
também o bloco que CARREGA o `medicao.jsonl`, e o gate escreveu uma tabela
vazia com ar de sucesso. Segundo erro: duas escritas paralelas no mesmo
ficheiro - a segunda apagou a primeira. Backup do estado anterior em
`Files\Backup\forward-gate.ps1.bak_r5r6`.

## P1.3607 - o relógio da medição (o que importa)

O gate carimbava tudo com a hora da execução. Medido no `MQL5\Logs\20261110.log`:

| tag | emissões hoje | última | usada pelo gate para |
|---|---|---|---|
| `[STATUS] HEALTHY` | 1 | 09:09:35 | P/L dia, DD %, Equity, perda %, Orders, Positions |
| `[SCANNER] RESUMO` | 51 | 17:10:12 | sinais, trades, AllowTrade, visitas |
| `HTTP 1003` | 82 | 17:09:04 | contador 1003 |

Ou seja: a linha das 17:51 da tabela mostrava `sinais=11`, `trades=0` e
`P/L=-61.8` lidos às 17:10 e às 09:09. Explica também o `equity=12593.83` que
o gate registava contra os 12 610,68 da conta: não era divergência de conta,
era um instantâneo das 09:09.

Correcção: cada linha do raw passa a levar `leitura_status_em`,
`leitura_resumo_em` e `leitura_1003_em`; a diária herda-os; o
`ultima_medicao.log` imprime-os; e a tabela ganhou a coluna
`Dados ate (resumo)` - hoje lê-se `17:10:12`, ao lado de uma amostra das
17:51. O número deixa de poder mentir sobre a hora a que foi lido.

## P1.3608 - mudez do agregado desde 17:10:50 (ABERTO)

`[SCANNER] RESUMO` (de 15 em 15 min, sem uma única falta desde 00:02) e
`[DIAGSCAN]` (de 5 em 5 min) calam-se às 17:10:12 e 17:10:50, ou seja na
recarga dos 15 gráficos (17:10:56). O EA continua vivo - `[AI]` 55 linhas na
hora, `[SESSION]` 9 na hora, ficheiro escrito às 17:52. Não é a regra de hora
evitada: o RESUMO saiu às 15:52, 16:07, 16:23, 16:39 e 16:54, todas dentro de
horas evitadas.

Consequência: a partir de 17:10 o funil agregado não é observável. O gate lê
o que existe, mas o que existe é de antes da recarga. Não há correcção
possível sem recompilar, e recompilar está proibido pela declaração. Opções
para o DONO: (a) recarregar os 15 gráficos (não muda o `.ex5`, mas arrisca
outra queda do bit de permissão e exige F7 de novo); (b) aceitar a lacuna e
alimentar o ledger por `[SESSION]`/deals em vez do `[RESUMO]`.

## Hora evitada - verificada, sem defeito

`AvoidHoursGMT=9,11,14,18,20,22` está a ser aplicado a `TimeGMT()` e a regra
bate certo com o relógio:

| bloqueio local | GMT impresso pelo EA | na lista |
|---|---|---|
| 06:00:00 | `GMT=9h` | sim |
| 08:00:00 | `GMT=11h` | sim |
| 15:30:49 | `GMT=18h` | sim |
| 17:00:00 | `GMT=20h` | sim |

Relação de relógios: local = GMT − 3; servidor = local + 5 = GMT + 2. O bloco
das 17:00 locais, portanto, é a hora evitada a funcionar como configurada -
parte do `trades=0` de agora é regra, não avaria.

## Estado no fecho (17:52 local / 22:52 servidor)

- frota 15/15 LIGADO, `code=0`, idades 3-56 s; 0 `[TRADE BLOCK] PROGRAMA sem permissao` desde 17:36.
- 0 posições, 0 ordens, equity = balance = 12 610,68 USD.
- `forward-gate.ps1` 26 168 B, CRLF 519, LF-so 0, 0 erros de sintaxe.
- `medicao.jsonl` 19 linhas append-only; `medicao_diaria.jsonl` 1 linha.
- Declaração: `inputs_sha256` 4B71E6E1… (39 campos), `governanca_sha256`
  CB7D8FD8… (87 modelos), âncora 22:31 servidor, `janela_congelada=true`.