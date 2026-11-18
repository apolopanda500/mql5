# Política de Segurança — XAU_AI_PRO (MQL5)

Este documento define como o projeto trata segurança da plataforma. Ele vale
para todo o código deste repositório (EA, includes, scripts, ferramentas) e
para como reportamos problemas.

---

## Escopo

- `Experts/XAU_AI_PRO/` — Expert Advisor e seus módulos (Core, AI, Indicators,
  Filters, Management, Monitoring, Enterprise, Integration, Scripts).
- `Tools/` e scripts de suporte — build, validação e verificações de WebRequest.
- `CI/` — workflows e regras de validação estática.

O que **não** está no escopo deste documento: o app desktop/mobile e o
gateway Python (repositório `XAU_AI_PRO`). Lá valem as regras próprias de
segurança daquele repositório.

---

## Princípios (não negociáveis)

1. **Nenhuma movimentação externa de fundos.** Nenhuma rota, módulo ou
   script do EA pode sacar, transferir ou mover dinheiro para fora da
   corretora. Operação de compra/venda é a única interação possível com a
   conta. O EA é uma via de entrada no mercado, não um canal de liquidação.
2. **Local-First, Fail-Closed.** O EA só age quando todos os portões de risco
   concordam (`TradeGate` / `RiskCenter` / `CTradeGate`). Sem `Ok()` de
   nenhum portão, **nenhuma ordem é aberta**. Sem IA disponível e com
   `AllowTradeWithoutAI=false`, o EA deixa de operar (fail-closed correto).
3. **Segredos nunca versionados.** Tokens, senhas, chaves de API, DSNs,
   credenciais de corretora e instruções do bridge ficam fora do git. `.env`
   e arquivos compilados (`.ex5`, `.dll`) não são commitados. O repositório
   contém apenas o código e a documentação.
4. **Contas reais exigem permissão explícita.** A abertura em conta real passa
   pelo `RealAccountGuard.mqh`, que registra e exige a condição de mercado
   aprovada antes de liberar qualquer ordem real. Isso é deliberadamente
   rígido e não é contornado por nenhuma configuração.

---

## Camadas de defesa que você encontrará no código

| Camada | Componente / arquivo | O que protege |
|---|---|---|
| Conta real | `Enterprise/RealAccountGuard.mqh` | decide se a conta é real ou demo; exige cenário/prova aprovados antes de operar em dinheiro real |
| Permissões do terminal | `Core/TradeGate.mqh` (`CTradeGate::Ok()`) | 5 bits de permissão (`TERMINAL_...`); qualquer bit em falha → EA parado, sem ordens |
| Stale feed | `Enterprise|Core/StalenessGuard.mqh` | preço parado ou `TimeTradeServer()` muito antigo → recusa operar sobre mercado congelado |
| Custo de execução | `Filters/CostGate.mqh` | protege contra slippage e spreads adversos da XAU/USD |
| Risco por operação | `Core/ExecutionEngine.mqh` / `Core/RiskEngine.mqh` | trava de risco em USD por ideia (`MaxRiskPerTradeUsd`), teto de perda diária (`MaxDailyLoss*`) |
| Slippage | `Monitoring/SlippageTracker.mqh` (v1.2.192+) | derrapagem real entra no gate de risco via ponte FFI |
| Concorrência | Padrão F4 (`Core/`) | serialização de decisões, eleição do gráfico-mestre |
| Proteção posicional | `Management/BreakEven.mqh`, `Management/MoneyLadder.mqh` | break-even, armadilhas e vencimento de ordens garantidos pelo EA |

---

## Versões suportadas

| Versão | Suporte |
|---|---|
| v1.2.214 / `1.414` (canônica, em produção) | ✅ suportada / forward test vigente |
| v1.2.191 – v1.2.213 | ⚠️ suporte apenas para correção de regressão |
| anterior a v1.2.191 | ❌ não suportada |

Nota: o EA canônico (v1.2.214) opera a janela de forward test; a cópia
espelho do repositório (`1.391` / v1.2.191) está versionada só para
visualização das alterações. Qualquer correção de segurança deve ser aplicada
aos dois.

---

## Reportar uma vulnerabilidade

**Não abra issue pública para falha de segurança.** Use o GitHub **Security
Advisories** (relatório privado de vulnerabilidade) em:

https://github.com/apolopanda500/mql5/security/advisories/new

Inclua:

- componente afetado (arquivo, função, módulo);
- reprodução e impacto (conta real vs. demo);
- versão/build do EA (`#property version` + `EA_VERSION_STRING`);
- evidência de desligamento ou ordem não autorizada, se houver.

O que esperar após o reporte:

| Situação | Prazo típico | Resultado |
|---|---|---|
| Confirmação de recebimento | até 72h | acuse de recebimento + número do advisory |
| Triagem inicial | até 7 dias | severidade (CVSS) e escopo |
| Correção (para componentes canônicos) | janela de manutenção | patch + tag + nota no CHANGELOG |
| Divulgação pública | após mitigação disponível | advisory publicado + changelog |

Falhas de autenticação, execução não autorizada em conta real ou bypass
de `TradeGate`/`RealAccountGuard` são tratadas como severidade crítica e
pularão para o topo da fila.

---

## Regras operacionais para colaboradores

- **Nunca** credite token, senha, DSN ou chave em código, log, commit, PR,
  screenshot ou print do journal. Use o input/`Caracteres` anônimos apenas.
- **Nunca** desabilite uma trava (`TradeGate`, `RealAccountGuard`,
  `CostGate`, `StalenessGuard`, teto diário) para "testar" — use
  simulação/demo e ambientes de teste.
- **Nunca** adicione um caminho de saque/transferência — nem mesmo
  "simulação" — e nunca degrade as permissões de leitura para escrita.
- Se um teste precisar simular uma falha de segurança, faça-o com dubles
  controlados em `tests/`, nunca com dados reais nem na conta real.
- Todo PR que tocar risco, permissões ou conta real exige revisão explícita
  do dono e execução completa de `check → compile` antes de merge.

---

## Prova de conformidade

- `validate_mql5.py` garante integridade mínima (UTF-8, balanceamento de
  chaves, resolução de includes) — não é suficiente por si só.
- `pytest -q tests/test_mql5_compila.py` (pasta do app) invoca o MetaEditor
  de verdade e exige `0 errors` para o merge.
- `Tools/agent-toolkit.ps1 check` aplica o mesmo conjunto no Windows.
- O `Forward Test` da janela atual demonstra comportamento fail-closed em
  condições de mercado reais.

---
*Última atualização: 2026-11-17. Política versionada junto com o código.*
