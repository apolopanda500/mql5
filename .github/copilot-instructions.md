# GitHub Copilot — Instruções do repositório

Este arquivo orienta o GitHub Copilot ao trabalhar neste repositório MQL5.

## Projeto

Repositório de código **MQL5** para MetaTrader 5. Artefato principal:
Expert Advisor **XAU_AI_PRO** (trading algorítmico com IA e gestão de risco).

## Estilo / convenções

1. Linguagem do código: **MQL5** (`.mq5`, `.mqh`).
2. Identificadores, funções e nomes de arquivo em **inglês**.
3. Comentários e strings exibidas ao usuário/terminal podem estar em **português**.
4. Manter arquitetura **modular**: risco, execução, IA, filtros e monitoramento
   em arquivos dedicados quando fizer sentido.
5. Codificação dos arquivos-fonte: **UTF-8** (sem acentos "quebrados").

## O que evitar

- **NUNCA** proponha incluir arquivos compilados `.ex5`, `.dll`, `.log` ou
  `Data/*.csv` no controle de versão (ver `.gitignore`).
- Não quebre o balanceamento de chaves `{}` nem `#include` inexistentes.
- Não altere parâmetros de risco de capital (RiskPercent, MaxDailyLossPercent,
  MaxDrawdownPercent) sem justificativa explícita.

## Dicas de geração

- Ao escrever/editar código MQL5, siga os padrões já presentes na base
  (indentação de 3 espaços, estilo MetaQuotes) — veja `Editor.code_style`.
- Complete funções dentro do módulo correto da árvore `Experts/XAU_AI_PRO/`.
- Prefira helpers utilitários (ex.: `Utils.mqh`) para lógica reutilizável.
