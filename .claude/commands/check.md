---
description: Valida estaticamente todas as fontes MQL5 do XAU_AI_PRO (UTF-8, chaves, includes) sem compilar.
---

# /check — validacao estatica

Roda o gate estatico do projeto: UTF-8 estrito, balanceamento de `{}` com
maquina de estados (ignora comentarios e strings) e resolucao de `#include`
em todos os `.mq5`/`.mqh` de `Experts/XAU_AI_PRO`.

## Passos

1. Pre-flight: `get_workspace_info` em `metaeditor5` e em `metatrader5`.
2. Executar:

```powershell
$TK = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\agent-toolkit.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK check
```

3. Interpretar a saida:
   - `arquivos analisados: N` (~106 e o esperado hoje);
   - `UTF-8 OK`, `chaves OK`, `includes OK`;
   - `RESULTADO: OK` = pode seguir para `/build`.

## Se falhar

- `UTF-8 invalido` → reescrever o arquivo com `write_file` (encoding utf-8).
  Nunca "corrigir" com `Set-Content` sem encoding explicito.
- `chave } extra na linha ~N` → ler `read_file_by_lines` na faixa N-20..N+20.
- `#include` nao resolvido → conferir diferenca de maiusculas/minusculas no
  nome do arquivo (MQL5 e case-insensitive em codigo, mas o disco nao).

## Nao faz

Nao compila, nao escreve, nao versiona. E somente leitura.
