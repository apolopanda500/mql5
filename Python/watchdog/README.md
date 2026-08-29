# XAU_AI_PRO — Heartbeat Watchdog (ETAPA 20.14 Endurance)

Monitora a "vida" do pipeline **sem tocar no EA** (regime passivo):
detecta parada de atualização de `system_status.json` / Event Stream e
gera alerta. Também consolida métricas para os checkpoints.

## Arquivos

| Arquivo | Papel |
|---|---|
| `heartbeat_watchdog.py` | watchdog principal (once / daemon / checkpoint) |
| `smart_read.py` | leitura com detecção de encoding (Event Stream é UTF-16 LE) |
| `iniciar_watchdog.bat` | launcher do daemon (Windows) |

## Uso

```bash
# verificação única (bom para cron/agendador)
python heartbeat_watchdog.py --once

# daemon contínuo (verifica a cada 5 min)
python heartbeat_watchdog.py --daemon --interval 300

# consolidar checkpoint (24h/72h/7d) — imprime status + contagem de eventos
python heartbeat_watchdog.py --checkpoint
```

## Variáveis de ambiente

| Variável | Default | Descrição |
|---|---|---|
| `STATUS_PATH` | `MQL5/Files/Data/system_status.json` | heartbeat do backend/EA |
| `EVENTS_PATH` | `MQL5/Files/Data/forward_test_events.csv` | Event Stream (UTF-16) |
| `AUDIT_PATH` | `MQL5/Files/Data/full_audit.csv` | AuditLog por-deal (opcional) |
| `MAX_IDLE_SEC` | `900` (15 min) | limite sem atualização do status/events |
| `AUDIT_MAX_IDLE_SEC` | `172800` (48 h) | audit atualiza por trade — cobre fim de semana (~43 h) sem falso positivo |
| `ALERT_THROTTLE_SEC` | `3600` | 1 alerta por tipo por hora |
| `SLACK_WEBHOOK_URL` | — | alerta Slack (Incoming Webhook) |
| `PUSHOVER_TOKEN` / `PUSHOVER_USER` | — | alerta Pushover (alternativa) |

## Alertas

Quando detecta problema (`system_status.json` parado, health != HEALTHY/SAFE,
Event Stream parado), envia mensagem via Slack e/ou Pushover (se configurados).
No fim de semana, `AI STALE` é **esperado** (mercado fechado) → não gera alerta.

## Agendamento (Windows Task Scheduler)

Recomendado — agendar `iniciar_agendado.py` a cada 5 min (instância única + auto-recuperação):

```bat
schtasks /Create /SC MINUTE /MO 5 /TN "XAU_AI_PRO_Watchdog" ^
  /TR "\"C:\...\python.exe\" \"C:\...\MQL5\Python\watchdog\iniciar_agendado.py\""
```

`iniciar_agendado.py` usa lock por PID (com checagem do comando do processo,
evitando PID reusado após reboot): daemon já ativo → sai sem duplicar; daemon
caiu → o próximo trigger reinicia. **Não** agendar `--daemon` direto no
triggador (empilharia um processo a cada 5 minutos).

Rodada manual: `iniciar_watchdog.bat` (primeiro preencha `SLACK_WEBHOOK_URL` dentro dele).

## Regras da endurance

- **Não altera** o EA, `system_status.json` nem os CSVs — só lê.
- Não interfere em decisões nem no pipeline.
- O `dup-exec` USDJPY (incidente registrado) permanece **sem intervenção** até o checkpoint; este watchdog só observa.