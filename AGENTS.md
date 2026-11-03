# AGENTS.md

Guia de contexto para agentes de programação (Claude Code, Cline, Cursor,
GitHub Copilot, etc.) que trabalham neste repositório MQL5.

---

## O que é este projeto

Este é um repositório de código **MQL5** para MetaTrader 5. O artefato
principal é o Expert Advisor **XAU_AI_PRO** v1.2.0, um robô de trading
algorítmico com integração de IA, gestão de risco e arquitetura modular.

Público-alvo do código: MetaTrader 5 (MT5), compilado com MetaEditor/MetaQuotes.

## Stack e ferramentas

- **Linguagem:** MQL5 (`.mq5` script/EA, `.mqh` include headers)
- **IDE:** MetaEditor (MetaQuotes Language Editor)
- **Modelos/IA:** pipeline Python opcional (dataset + predição)
- **CI:** GitHub Actions (validação estática — veja `.github/workflows/ci.yml`)
- **Sincronização:** dois remotes — `origin` (MQL5 CodeBase) e `github`

## Estrutura relevante (não alterar sem motivo)

```
Experts/XAU_AI_PRO/
├── XAU_AI_PRO.mq5      # EA principal (entry point)
├── XAU_AI_PRO.mqproj   # Projeto MetaEditor
├── Utils.mqh           # Utilitários
├── Core/               # Módulos centrais (Config, Risk, Execution...)
├── AI/                 # Módulos de IA (AIEngine, Dataset...)
├── Indicators/         # Indicadores técnicos
├── Filters/            # Filtros de entrada
├── Management/         # Gestão de posições
├── Monitoring/         # Logs e monitoramento
├── Enterprise/         # Recursos enterprise
└── Data/               # Dados (ignorados pelo git)
```

> **Atenção:** o diretório `Experts/XAU_AI_PRO/` listado no README documenta
> uma estrutura modular idealizada. Em alguns estados do repositório os
> submódulos podem estar achatados (arquivos direto na pasta do EA). Sempre
> confira a árvore real antes de assumir a localização de um arquivo.

## Regras de ouro

1. **Nunca quebre a compilação.** Sempre valide o balanceamento de chaves `{}`,
   a integridade dos `#include` e o encoding UTF-8 antes de encerrar.
2. **MQL5 é case-insensitive para identificadores**, mas **sensitive para
   arquivos** em sistemas Linux (`#include`), portanto mantenha os nomes de
   arquivos consistentes com o disco.
3. **Não edite arquivos binários/compilados** (`.ex5`, `.dll`) nem os `Data/*.csv`.
4. **Respeite o `.gitignore`** — não force a inclusão de `.ex5`, `.log`, `.dat`
   ou `Data/*.csv` no controle de versão.
5. **Preferência por arquitetura modular**: cada responsabilidade (risco,
   execução, IA, monitoramento) deve ter seu módulo/arquivo dedicado.
6. **Comentários em português** para mensagens voltadas ao usuário/terminal;
   identificadores e nomes de arquivo em inglês (padrão atual do projeto).
7. **Não altere inputs/parâmetros de risco** sem justificativa explícita, pois
   afetam capital real (RiskPercent, MaxDailyLossPercent, MaxDrawdownPercent).

## Compilação e validação

- Compilar: use MetaEditor sobre `Experts/XAU_AI_PRO/XAU_AI_PRO.mqproj`
  (construção real só funciona em Windows com MetaEditor instalado).
- Validação estática (sem MetaEditor): rode
  `python ../../.github/scripts/validate_mql5.py` direto na pasta do EA. No
  Windows, use `py -3 ../../.github/scripts/validate_mql5.py` quando `python`
  não estiver no `PATH`.

## Skills compartilhadas

O Codex descobre as skills do projeto em `.agents/skills/`. As entradas desse
diretório apontam para as definições canônicas em `.claude/skills/`, mantendo
Claude e Codex sincronizados:

- `compile-validate-mql5` — validação estática e compilação MQL5;
- `review-mql5-code` — revisão estruturada de código MQL5.

Ao alterar um procedimento compartilhado, edite a definição correspondente em
`.claude/skills/`; o Codex carregará a versão atualizada pelo encaminhamento.

## Integrações do Codex

- **Git local:** preserve alterações existentes no worktree e nunca faça
  `commit`, `push`, `merge`, `reset` ou troca de branch sem pedido explícito.
- **GitHub:** o repositório remoto principal para colaboração é
  `apolopanda500/mql5` (`github`). Use a integração GitHub para consultar CI,
  issues e pull requests; qualquer escrita externa exige intenção explícita.
- **MQL5 CodeBase:** o remote `origin` aponta para o Forge MQL5. Não presuma que
  sincronizar com GitHub também autoriza publicar no CodeBase.
- **Vercel:** a conta pode ser usada por ferramentas auxiliares web, mas este
  repositório MQL5 não é um alvo Vercel por padrão. Não execute `vercel link`,
  `deploy` ou crie projeto sem um artefato web e autorização explícita.
- **Slack:** use o plugin conectado para leitura e preparação de atualizações.
  Prefira rascunho; enviar, editar ou apagar mensagens requer pedido explícito.
- **Sentry:** a configuração local pode apontar para componentes Python do
  projeto. Confirme organização/projeto antes de mutações, releases ou deploys;
  não registre tokens, DSNs ou conteúdo sensível no repositório.
- **Segredos:** credenciais de GitHub, Vercel, Slack e Sentry pertencem aos
  armazenamentos globais/seguros de cada ferramenta, nunca a arquivos
  versionados deste projeto.

## Workflow sugerido

1. Entenda o estado atual (git status, árvore real dos arquivos).
2. Faça a alteração cirúrgica, respeitando os módulos.
3. Valide (compilação ou script estático).
4. Documente mudanças relevantes no README/versionamento quando aplicável.
