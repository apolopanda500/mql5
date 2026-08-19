---
name: compile-validate-mql5
description: Valida e compila código-fonte MQL5 deste repositório. Use quando o usuário pedir para compilar, verificar, corrigir erros de compilação ou validar sintaxe de arquivos .mq5/.mqh no projeto XAU_AI_PRO.
---

# Compilação e validação MQL5

Esta skill descreve como validar/compilar código MQL5 neste repositório
(mesmo sem MetaEditor disponível em todos os ambientes).

## Validação estática (recomendada e portátil)

Na pasta do EA (`Experts/XAU_AI_PRO/`), rode:

```
python ../../.github/scripts/validate_mql5.py
```

O script cobre (veja `.github/workflows/ci.yml`):

1. **Encoding UTF-8** — detecta acentos "quebrados";
2. **Balanceamento de chaves `{}`** — erros de bloco;
3. **Integridade de `#include`** — includes locais existentes;
4. **Avisos** — `TODO`/`FIXME` e fim-de-linha CRLF.

O fluxo falha (exit 1) apenas em problema real.

## Compilação real (MetaEditor / Windows)

Se o MetaEditor estiver disponível, compile o projeto:

- Projeto: `Experts/XAU_AI_PRO/XAU_AI_PRO.mqproj`
- Verifique o `XAU_AI_PRO.log` gerado para erros.

## Antes de encerrar

- Confirmar UTF-8 válido nos arquivos editados.
- Confirmar balanceamento de chaves e integridade dos `#include`.
- Maioria das falhas de CI vem de encoding ou include quebrado, não da lógica.
