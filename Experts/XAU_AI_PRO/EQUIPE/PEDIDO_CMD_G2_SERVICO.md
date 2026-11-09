# PEDIDO A CMD - Q-022 / G2: gateway de IA como servico do Windows

> Autor: DELTA, 08/11 13:08. Origem: decisao escrita do DONO (D-116, Q-022).
> Este pedido e' **especificacao**, nao execucao concorrente: as 13:04 o ALFA estava a ler `tools\gateway-start.ps1` e a sondar `9011/api/health`. Combinem quem executa antes de correr os dois.
> Alvo: `/api/ai/predict` a **200** depois de um reboot, **sem** intervencao manual.

## 1. O que esta medido hoje (DELTA, 08/11 13:04-13:07)

| Facto | Medicao |
|---|---|
| Porta 9011 a responder | sim - `GET /api/health` devolve **401** (exige token; prova que o processo esta vivo) |
| `/api/ai/predict` com Bearer do `.env` | **200 / 1122 B** (`XAUUSD`, `available=true`), registo de 06/11 15:50 reconfirmado 01:45 |
| Modo de execucao | **processo manual** (`uvicorn`, PID 8992, 1 instancia) - **nao** sobrevive a reboot |
| Mitigacao actual | tarefa agendada `XAU_AI_PRO_GatewayKeepalive` (a cada 5 min) corre `tools\gateway-start.ps1` |
| Consequencia de o gateway morrer | EA fica cego: `AIUnavailableConfidenceCap=40.0` + `AllowTradeWithoutAI=true` -> decide com score capado em 40, sem autoridade de IA (`AIHasSignalAuthority=false`) |

**O 401 no `/api/health` NAO e' falha.** O criterio G2 pede `/api/ai/predict` a 200 **com credencial**, e isso ja esta provado. O que falta e' **durabilidade**.

## 2. O que CMD tem de fazer (fora das raizes MQL5)

### 2.1 Criar o servico com NSSM

Servicos Windows nao correm processos de consola directamente (`uvicorn` e' consola). Wrapper obrigatorio: NSSM.

```powershell
# executar como Administrador
$appRoot = 'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\XAU_AI_PRO'
$py      = Join-Path $appRoot '.venv\Scripts\python.exe'
$svc     = 'XAU_AI_PRO_Gateway'

nssm install $svc $py
nssm set $svc AppDirectory      $appRoot
nssm set $svc AppParameters     '-m uvicorn backend.fastapi_gateway:app --host 127.0.0.1 --port 9011'
nssm set $svc DisplayName       'XAU_AI_PRO AI Gateway (9011)'
nssm set $svc Description       'Gateway de IA do XAU_AI_PRO na porta 9011, modo LEITURA (6 flags a 0).'
nssm set $svc Start             SERVICE_AUTO_START
nssm set $svc AppStdout         (Join-Path $appRoot 'logs\gateway_9011_service.out.log')
nssm set $svc AppStderr         (Join-Path $appRoot 'logs\gateway_9011_service.err.log')
nssm set $svc AppRotateFiles    1
nssm set $svc AppRotateOnline   1
nssm set $svc AppRotateBytes    10485760
nssm set $svc AppExit Default    Restart
nssm set $svc AppRestartDelay   5000
nssm set $svc AppThrottle       10000
nssm set $svc AppStopMethodConsole 15000
nssm start $svc
```

### 2.2 Fixar as 6 flags de seguranca no servico

O `gateway-start.ps1` define-as no processo. Um servico **nao** herda esse contexto, por isso tem de ser explicito em `AppEnvironmentExtra`. **Todas a 0. Nao parametrizar.**

```powershell
nssm set XAU_AI_PRO_Gateway AppEnvironmentExtra `
  'XAU_GATEWAY_PORT=9011' `
  'XAU_GATEWAY_HOST=127.0.0.1' `
  'XAU_ENABLE_REAL_ORDERS=0' `
  'XAU_ENABLE_DEMO_ORDERS=0' `
  'XAU_ENABLE_MT5_EXECUTION=0' `
  'XAU_ENABLE_TRADE_COMMANDS=0' `
  'XAU_ENABLE_EMERGENCY_RESUME=0' `
  'XAU_ENABLE_MCP_TRADING=0'
```

Nota de conta de servico: o gateway le o token do `.env` em `$appRoot`. Se o servico correr como `LocalSystem`, confirme que `LocalSystem` le esse ficheiro; caso contrario use a conta do utilizador `Micro` com "Log on as a service" e **sem** password em claro em ficheiro versionado.

### 2.3 Evitar dois uvicorn na mesma porta (obrigatorio)

Com o servico criado, a tarefa `XAU_AI_PRO_GatewayKeepalive` passa a ser **redundante e perigosa** (duas instancias a disputar 9011). Ordem correcta:

1. `nssm stop XAU_AI_PRO_Gateway` (se estiver a correr).
2. Matar o processo manual actual (PID 8992) **so** depois de o servico estar validado.
3. `Disable-ScheduledTask -TaskName 'XAU_AI_PRO_GatewayKeepalive'` - manter como **fallback documentado**, nao agendado.
4. `nssm start XAU_AI_PRO_Gateway`.
5. Confirmar **exactamente 1** processo `python` a ouvir 9011.

### 2.4 Prova de reboot (o unico criterio que fecha o Q-022)

1. Reiniciar o Windows.
2. Sem tocar em nada: `Get-Service XAU_AI_PRO_Gateway` -> `Running`, `StartType=Automatic`.
3. `GET http://127.0.0.1:9011/api/ai/predict` **com** `Authorization: Bearer <token do .env>` -> **200**.
4. `GET` sem token -> **401** (a credencial continua obrigatoria).
5. No terminal: `get_expert_journal` filtro `GATEWAY`/`[AI]` nos 10 min seguintes ao arranque -> **sem** ciclo de "cego" prolongado.

## 3. O que NAO muda

- O `.ex5` nao muda (`5C99AF0CDCE1E2C74D39270C21047607`). Nao ha compilacao neste pedido.
- `AIGatewayUrl` continua `http://127.0.0.1:9011/api/ai/predict` nos 12 graficos.
- `AIGatewayToken` continua vazio no input: o token e' resolvido por `AIGatewayTokenEfetivo()` a partir do `.env` (>= 32 caracteres).
- Nao se abre porta para fora de `127.0.0.1`.
- Nao se ligam ordens: as 6 flags ficam a **0** tambem no servico.

## 4. Como o DELTA fecha a linha

Quando CMD disser "servico instalado e reiniciado", o DELTA mede:

```
Get-Service XAU_AI_PRO_Gateway | Select Status,StartType
GET /api/ai/predict + Bearer  -> 200
GET /api/ai/predict sem token -> 401
get_expert_journal -> [AI] GATEWAY sem falhas no arranque
```

So com esses quatro valores escritos e' que a **ressalva de durabilidade** do G2 sai da tabela. Ate la o G2 continua **VERDE COM RESSALVA** - nao por teimosia, porque o criterio fala de "a correr na porta que o EA usa" e um processo manual nao e' um servico.
