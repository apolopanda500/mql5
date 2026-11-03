---
description: Diagnostico completo e somente-leitura do EA, do terminal, da API e do repositorio.
---

# /diagnose — diagnostico de ponta a ponta

Somente leitura. Nao compila, nao escreve, nao negocia. Serve para responder
"o EA esta operando? se nao, o que esta bloqueando?".

## Passos

1. Pre-flight: `get_workspace_info` em `metaeditor5` e `metatrader5`.

2. Arquivos versionados e estado do repo:

```powershell
cd /d "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
git status -sb
git rev-list --left-right --count github/main...HEAD
```

3. Terminal e conta:

```
metatrader5__terminal_get_info
metatrader5__get_trading_account_info
metatrader5__get_trading_open_positions
```

4. Graficos e programas anexados:

```
metatrader5__list_open_charts
```

Conferir: quantos graficos, qual expert, quais inputs criticos
(`AutoTrade`, `AIGatewayUrl`, `AIGatewayToken`, `NotifyTelegramToken`).

5. Saude do EA (ultimos 30 min):

```
metatrader5__get_expert_journal datetime_from=<agora-30min> filter=STATUS
metatrader5__get_expert_journal datetime_from=<agora-30min> filter=SCANNER
metatrader5__get_expert_journal datetime_from=<agora-30min> filter=VALIDATION
```

`[STATUS] HEALTHY` deve trazer as 5 permissoes em `1`:
`MQL_TRADE_ALLOWED`, `TERMINAL_TRADE_ALLOWED`, `ACCOUNT_TRADE_ALLOWED`,
`ACCOUNT_TRADE_EXPERT`, `TERMINAL_CONNECTED`.

6. Falhas de transporte (as que mais aparecem):

```
metatrader5__get_expert_journal filter=GATEWAY
metatrader5__get_expert_journal filter=NOTIFY
```

7. API local:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\api-probe.ps1"
```

8. WebRequest (allowlist): ver `/webrequest`.

## Como ler o resultado

| Achado | Leitura correta |
|---|---|
| `[SCANNER] trades=0` com `bloqueios` alto | EA analisa e veta; olhar `[VALIDATION] BLOCK` para o motivo dominante |
| `ADX indisponivel` repetido | handles de ADX nao prontos no simbolo; nao e falha de sinal |
| `erro=4014` no GATEWAY | WebRequest desligado no terminal — configuracao do dono |
| HTTP 401 no probe da API | gateway exige `AIGatewayToken` — input vazio no EA |
| Excelente status + 0 trades | nao e bug: e o conjunto de filtros vetando |

## Regra

Relatar o que foi encontrado, separando **configuracao** (o dono resolve na GUI)
de **codigo** (o agente resolve). Nunca "consertar" risco para destravar trade.
