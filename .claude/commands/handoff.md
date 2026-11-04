---
description: Gera o handoff deste terminal para outro agente IA continuar o trabalho sem perder contexto.
---

# /handoff — passagem de contexto entre agentes

Objetivo: qualquer agente novo entende o estado real do terminal em poucos
minutos, sem depender do historico de conversa.

## Passos

1. Coletar os fatos (tudo somente leitura):

```
metatrader5__terminal_get_info
metatrader5__get_trading_account_info
metatrader5__list_open_charts
metatrader5__get_expert_journal   (filter=STATUS, ultimos 30 min)
metaeditor5__list_available_mql5_programs
metaeditor5__list_open_documents
```

```powershell
cd /d "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
git status -sb
git rev-list --left-right --count github/main...HEAD
git log --oneline -5
```

2. Escrever/atualizar `Tools/HANDOFF.md` com o template abaixo, substituindo
   cada marcador por dado medido. Nada de suposicao.

```markdown
# HANDOFF — <data hora local>

## Terminal
- build / x64 / conexao / ping
## Conta
- login, servidor, tipo, moeda, balance, equity, posicoes abertas
## EA em operacao
- quantos graficos, expert, magic, versao
- inputs criticos (sem segredos): AutoTrade, AIGatewayUrl, token preenchido? S/N
- ultimo [STATUS] e o que ele diz
## Bloqueios conhecidos
| # | Sintoma | Causa raiz | Dono da correcao |
## Repositorio
- HEAD, ahead/behind, working tree, arquivos rastreados
## Feito nesta sessao
- lista de mudancas com arquivo e commit
## Proximo passo recomendado
- acao concreta, com o comando exato
```

3. Commitar o handoff:

```powershell
$TK = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\agent-toolkit.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK commit -Message "docs(handoff): atualiza passagem de contexto entre agentes"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK push
```

## Regras

- Nunca escrever token, senha, DSN, numero de conta completo ou dado pessoal
  no `HANDOFF.md` — ele vai para o repositorio publico. Use "preenchido? S/N".
- `HANDOFF.md` descreve estado, nao intencao. Fato medido ou nada.
- Se um bloqueio depende da GUI do terminal, marcar explicitamente como
  "dono da correcao: operador".
