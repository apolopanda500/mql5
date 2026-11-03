---
description: Compila o EA XAU_AI_PRO com o MetaEditor e exige 0 errors antes de seguir.
---

# /build — compilacao

Compila `Experts/XAU_AI_PRO/XAU_AI_PRO.mq5` e publica o `.ex5` na pasta do EA.

## Passos

1. Pre-flight: `get_workspace_info` em `metaeditor5` e `metatrader5`.
2. Preferir a ferramenta MCP para ter o diagnostico estruturado:

```
metaeditor5__compile_file
  path = ...\MQL5\Experts\XAU_AI_PRO\XAU_AI_PRO.mq5
```

3. Alternativa/atalho (mesma coisa, via toolkit):

```powershell
$TK = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\agent-toolkit.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK deploy
```

`deploy` = `check` + `compile`.

## Criterio de aceite

`0 errors`. Warnings devem ser zero tambem; qualquer warning de conversao
implicita, perda de dado, variavel nao usada ou codigo inalcancavel precisa ser
corrigido ou justificado no relatorio.

## Se falhar

1. Ler o erro exato (arquivo + linha) na saida do compilador.
2. `read_file_by_lines` na faixa do erro (nao no arquivo inteiro).
3. Corrigir com `replace_text_in_file` (patch cirurgico), nunca reescrevendo
   um arquivo grande de uma vez.
4. Recompilar. Repetir ate 0 errors.

## Importante

- Nao alterar `RiskPercent`, `MaxDailyLossPercent`, `MaxDrawdownPercent`,
  `MaxOpenPositions`, `MaxTradesPerDay` para "fazer compilar".
- Nao editar `.ex5`, `.dll` nem `Data/*.csv`.
- Se o EA estiver anexado a graficos, o `.ex5` novo so entra em vigor quando o
  grafico recarrega o programa — avisar no relatorio.
