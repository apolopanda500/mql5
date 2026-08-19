# CLAUDE.md

Guia de contexto para o **Claude Code** trabalhar neste repositório.

## Projeto

Repositório **MQL5** para MetaTrader 5. Artefato principal: Expert Advisor
**XAU_AI_PRO** — trading algorítmico com IA, gestão de risco e arquitetura
modular enterprise.

## Regras de ouro

1. Nunca quebre a compilação: valide chaves `{}`, `#include` e UTF-8.
2. Identificadores e nomes de arquivo em **inglês**; comentários/strings de
   terminal podem estar em **português**.
3. Não edite binários `.ex5`, `.dll` nem `Data/*.csv`; respeite o `.gitignore`.
4. Arquitetura **modular** (risco, execução, IA, filtros, monitoramento).
5. Não altere parâmetros de risco reais (RiskPercent, MaxDailyLossPercent,
   MaxDrawdownPercent) sem justificativa explícita.

## Skills disponíveis

Skills locais em `.claude/skills/`:

- **compile-validate-mql5** — valida/compila código MQL5.
- **review-mql5-code** — revisão estruturada de código MQL5.

## Validação

- Estática: `python .github/scripts/validate_mql5.py` (na pasta do EA).
- Compilação real: MetaEditor sobre `Experts/XAU_AI_PRO/XAU_AI_PRO.mqproj`.
