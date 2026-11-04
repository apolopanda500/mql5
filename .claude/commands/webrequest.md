---
description: Verifica a allowlist de WebRequest do terminal executando um script e lendo o veredito por URL.
---

# /webrequest — allowlist de WebRequest

Responde: **quais URLs o MT5 realmente deixa o EA acessar?**

O MT5 exige duas condicoes simultaneas:

1. `Ferramentas > Opcoes > Expert Advisors > "Permitir WebRequest para URLs listadas"` marcado;
2. o dominio presente na lista, exatamente como sera chamado.

Nenhuma ferramenta MCP le ou altera essas opcoes (a pasta `config` do terminal
esta fora das raizes). So o dono muda na GUI.

## Passos

1. Pre-flight: `get_workspace_info` em `metaeditor5` e `metatrader5`.

2. Compilar o verificador (se o `.mq5` mudou):

```
metaeditor5__compile_file
  path = ...\MQL5\Scripts\XAI_WebRequestCheck.mq5
```

3. Escolher um grafico:

```
metatrader5__list_open_charts
```

4. Executar:

```
metatrader5__chart_add_script
  chart_id    = <id de um grafico aberto>
  script_path = ...\MQL5\Scripts\XAI_WebRequestCheck.ex5
```

Opcional: passar `script_parameters` com `UrlList=url1;url2;...` para testar
outro conjunto (o input e separado por `;`).

5. Ler o veredito:

```
metatrader5__get_expert_journal datetime_from=<agora-5min> filter=WEBREQ
```

## Como interpretar

| Saida | Significado | Acao |
|---|---|---|
| `PERMITIDA \| ... \| HTTP=200` | URL liberada e respondendo | nada |
| `PERMITIDA \| ... \| HTTP=401` | URL liberada, backend exige auth | preencher token |
| `BLOQUEADA` + `DESABILITADO` | erro **4014**: checkbox desmarcado | dono marca o item 1 |
| `BLOQUEADA` + `FORA DA LISTA` | erro **4060**: URL nao cadastrada | dono adiciona o dominio |
| `BLOQUEADA` + `URL invalida` | erro **5200**: falta `http://` ou dominio errado | corrigir input/codigo |
| `PERMITIDA` + `conexao falhou` | erro **5201**: liberada, host fora | subir o servico |
| `PERMITIDA` + `timeout` | erro **5202**: liberada, host lento | aumentar timeout |

## Pontos de WebRequest do projeto

> **MEDIDO 04/11/2026:** `127.0.0.1:9001` e o **MCP embutido do MT5**
> (`config\assistant.ini`: `[MCP.MetaTrader] Endpoint=http://127.0.0.1:9001/mcp`),
> escutado pelo `terminal64`. O gateway usa `9011` (`XAU_GATEWAY_PORT`) e **nao
> estava no ar**. Um `HTTP=401` contra 9001 e resposta do terminal, nao recusa
> do gateway. Ver `Tools\WEBREQUEST_GATEWAY_UNBLOCK.md` e
> `Tools\verify-gateway.ps1`.

| Arquivo | Destino | Input |
|---|---|---|
| `AI/AIConnector.mqh` | `http://127.0.0.1:9011/api/ai/predict` | `AIGatewayUrl`, `AIGatewayToken` |
| `Enterprise/NotificationCenter.mqh` | `https://api.telegram.org/bot<token>/sendMessage` | `NotifyTelegramToken`, `NotifyTelegramChatID` |

## Checklist de configuracao (para o dono)

- [ ] marcar "Permitir WebRequest para URLs listadas"
- [ ] adicionar `http://127.0.0.1:9011` (o gateway; `9001` e o MCP do MT5)
- [ ] (se for usar Telegram) adicionar `https://api.telegram.org`
- [ ] preencher `AIGatewayToken` se o gateway exigir (ver `/diagnose`)

Depois de mudar a opcao, **re-executar** este comando para confirmar.
