# LOCK - recurso: MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.ex5

- **Dono:** ALFA
- **Motivo:** B-033 (A/B do EnableVolatilityFilter) a correr com o binario 1.2.172 (931194 B, hash 0A28EDFC5BDC). O `.ex5` tem de ficar byte-identico ate o job fechar.
- **Tomado:** 06/11/2026 02:14
- **Expira:** 06/11/2026 04:00
- **run_id:** 7704922063681257178
- **ESTADO:** OCUPADO

## O que este job mede (A/B, uma unica variavel)

| | B-032 | B-033 |
|---|---|---|
| `EnableVolatilityFilter` | true | **false** |
| binario | 1.2.172 | 1.2.172 |
| janela | 2026.08.01 -> 2026.11.05 | igual |
| `AIUseGateway` / `EnableVerboseDebug` | false / false | false / false |

Config: `equipe_B033_xauusd.ini` + `equipe_B033_xauusd_nofilter.set`.
Offset fixado antes do arranque: **202778546** (`b033_offset.txt`,
`mtime=2026-11-06T02:02:40`, `agora=2026-11-06T02:12:39`).
Contagem final: `contadores_atr_v4.ps1 -Log <log> -Offset 202778546`.

## Criterio de decisao fixado ANTES do resultado

O filtro so sai do estado actual se, na mesma janela e binario:

1. `[VALIDATION] APPROVED` subir de forma material (> +20% sobre 98 do B-032);
2. o resultado liquido nao piorar (equity final >= 10257.16);
3. drawdown maximo do relatorio dentro de 3.0% (limite `MaxDD` do perfil Conservative).

Se 1) acontecer mas 2) ou 3) falharem, a resposta ao DONO e **manter o filtro
ligado** e o AVISO 045 fecha com numero, nao com opiniao. Uma corrida nao prova
rentabilidade: prova apenas o efeito deste input nesta janela.

## Regras enquanto este LOCK estiver activo

1. Fontes (`.mq5`/`.mqh`) sao editaveis; o `.ex5` **nao**.
2. Nenhuma compilacao para `Experts\XAU_AI_PRO` - a compilacao escreve o `.ex5`.
3. Nenhum segundo job de tester (PROTOCOLO 10.1 e 10.2).
4. Quem precisar do recurso, pede por escrito no canal EQUIPE e espera resposta.

## Resultado do B-032 (fechado, D-052)

SEM LEITURA 218214 -> 0 | HANDLE MORTO 4663 -> 0 | SERIE OK 0 -> 1 |
HANDLE RECRIADO 0 -> 1 | equity 10257.16 | APPROVED 98 | BLOCK 662.
