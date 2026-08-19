---
name: review-mql5-code
description: Revisa código-fonte MQL5 (Expert Advisors, Indicators e Includes) buscando bugs, riscos, problemas de estilo e oportunidades de melhoria. Use quando o usuário pedir revisão, auditoria, code review ou melhoria de código MQL5 neste repositório.
---

# Revisão de código MQL5

Esta skill orienta a revisão de código MQL5 neste repositório (projeto
**XAU_AI_PRO** para MetaTrader 5), focando em qualidade, segurança e
manutenibilidade sem quebrar a compilação.

## Quando usar

- Usuário pede: "revise", "audite", "review", "melhore", "code review",
  "encontre problemas", "otimizações" em código `.mq5`/`.mqh`.

## Fluxo

1. **Localize** o arquivo real na árvore (o README idealiza a estrutura;
   confira a árvore real antes).
2. **Leia** o arquivo completo antes de opinar.
3. **Verifique** automaticamente:
   - Balanceamento de chaves `{}` (sem função de máquina de estados).
   - `#include` existentes (case-sensitive em Linux).
   - Encoding UTF-8 válido.
   - CRLF / terminações consistentes.
4. **Analise** nas categorias abaixo e reporte com severidade:
   - `Alta` — risco de perda de capital, bug funcional, vazamento de memória,
     loop infinito, ordem não fechada.
   - `Média` — problemas de estilo, duplicação, legibilidade, performance.
   - `Baixa` — sugestões cosméticas/refactor.
5. **Nunca altere** parâmetros de risco reais (RiskPercent, MaxDailyLossPercent,
   MaxDrawdownPercent) sem justificativa explícita e sem confirmar com o usuário.

## Checklist por categoria

### Risco / dinheiro
- Lote calculado corretamente? Margem livre verificada?
- Stop loss / take profit sempre definidos quando esperado?
- Gerenciamento de "magic number" e símbolo consistentes?

### Execução / ordens
- Tratamento de retorno de `OrderSend`/`OrderSendAsync` e códigos de erro?
- Retry com backoff exponencial sem risco de loop infinito?
- Slippage e spread tratados?

### IA / integração
- Leitura/escrita de arquivos (dataset/prediction) com checagem de erro?
- Fallback quando o modelo não está disponível?

### Ciclo de vida
- `OnInit`/`OnTick`/`OnDeinit` equilibrados? Handles de indicadores liberados?
- Funções `static`/globais com risco de estado vazado entre ticks?

### Estilo / manutenibilidade
- Nomes em inglês, comentários em português (padrão do projeto)?
- Lógica duplicada que deveria ir para `Utils.mqh`?

## Saída

Entregue uma **lista priorizada** (Alta/Média/Baixa) com: localização
(arquivo + função/linha), descrição do problema, impacto e sugestão de correção.
Ao final, proponha aplicar as correções de Alta/Média caso o usuário queira.
