# GATE_REAL - criterios de passagem para conta real (D-055)

> Regra unica: **nenhum item passa por opiniao**. Cada linha cita a medicao, a data e a ferramenta.
> Enquanto houver um VERMELHO nesta tabela, conta real nao se abre - nao por conservadorismo, mas porque converter um backtest de 9 trades em dinheiro real e a forma mais cara de aprender o que o backtest ja podia ter dito.

- Autor: DELTA, 06/11 14:36
- Estado global: **2 verdes de 11** (G2 com ressalva de durabilidade; G3 medido pelo ALFA e **aguarda auditoria do DELTA**) e **9 vermelhos** - medido 07/11 17:20
- Substitui a expressao "pronto a 10/10": esse numero nao existe em trading e nao sera escrito neste projecto como se existisse.

## 1. Tabela do gate

| ID | Criterio de passagem (numerico) | Estado medido | Medido em | Como se prova | Fecha |
|---|---|---|---|---|---|
| **G1** | Conta live num broker real, distinta da demo | **VERMELHO** - servidor `MetaQuotes-Demo`, tipo `demo`, login `113568614`, balance 12636.32 | 06/11 14:35 | `get_trading_account_info` | DONO |
| **G2** | Servico de IA **a correr** na porta que o EA usa e `/api/ai/predict` responde **200**, com credencial **resolvida** por `AIGatewayTokenEfetivo()` (>= 32 caracteres, via `.env`) | **VERDE (com ressalva)** - 9011 no ar (PID 1464); `GET` sem token = **401**, com Bearer do `.env` = **200 / 1122 B**, token errado = **401**; e o EA provou no journal `[AI] GATEWAY RECUPERADO \| falhas=7 \| cego=209s \| resposta=357B`. **Ressalva:** processo manual, sem servico - nao sobrevive a reboot | 06/11 15:50 | `delta_probe_9011.ps1` + `get_expert_journal` + `delta_edge_all.ps1` | DONO (Q-022: subir como servico) |
| **G3** | Score discrimina: **< 50 %** das amostras `[SCORE]` com `TOTAL=100.00` e desvio-padrao **> 5** pontos | **VERDE (proposto; aguarda auditoria do DELTA)** - v1.2.184 (ex5 964 056 B, 16:23:11, MD5 931459A39634DD7A95ED1EA74D412FC4): **0 de 598** (0.00 %) em `TOTAL=100.00`, media 50.95, **sd 7.58**, min 30.43, max 70.97. Lado A v1.2.183: 466 de 529 (88.09 %). D-081 | 07/11 17:20 | `[SCORE]` em `Tester\logs\*.log` | DELTA mede / ALFA corrige (bloqueado em G2) |
| **G4** | Binario que vai a real provado em memoria: `[VERSION]` do log == binario, `[ATR] SEM LEITURA` = **0** e `HANDLE MORTO` = **0** num job de 24 h | **VERMELHO** - metade "binario em memoria" SATISFEITA: `v1.2.176` a correr nos 13 graficos desde 20:09:51 (13x `[START]` com simbolo, conta e saldo + `[VERSION] v1.2.176`, Modulos=16 OK), logo a memoria **e** o binario compilado (corrige o "memoria ainda v1.2.167" de 14:23). Continua VERMELHO por faltar o job de 24 h que prove `[ATR] SEM LEITURA` = 0 e `HANDLE MORTO` = 0 nesse binario | 06/11 20:10 | `[VERSION]` + `contadores_atr_v4.ps1 -Log -Offset` | DONO autoriza reattach / DELTA mede |
| **G5** | **>= 100** trades fechados e **>= 3 meses** de dados no par que vai a real | **VERMELHO** - melhor conjunto A/B: **9 trades** | 06/11 (handoff) | relatorio do tester | ALFA/CMD (F3) |
| **G6** | MaxDD **<= 8 %** no backtest **e** no forward | **VERMELHO** - **61.50 %** num dos lados do A/B (0.58 % no outro; conta o pior) | 06/11 | `tester_get_report` | ALFA |
| **G7** | Profit factor **>= 1.20** com **>= 100** trades | **VERMELHO** - **0.6643** no A/B; `PF 0.6206` em remedicao (Q-011) | 06/11 | relatorio do tester | ALFA |
| **G8** | **>= 30 %** dos trades em short numa amostra >= 100 | **VERMELHO** - **0 shorts**, estrutural em `SignalCore.mqh:372-375` (exige EMA50<EMA200) | 06/11 | `[SIGNAL]` no log | ALFA |
| **G9** | Limites de risco de conta real declarados por escrito: `MaxDailyLossPercent <= 3`, `MaxDrawdownPercent <= 6`, `RiskPercent <= 0.5` | **VERMELHO** - em uso: **10.0 / 15.0 / 1.0** (valores de treino de demo) | 06/11 14:23 | `list_open_charts` | DONO (Q-017) |
| **G10** | Universo coerente: **1** simbolo por grafico, todos com modelo publicado, zero divergencia entre `Symbols`, graficos e Market Watch | **VERMELHO** - 13 graficos vs 11 em `Symbols`; **1** modelo (XAUUSD); `USDCZK`/`USDRUB`/`USDSGD` fora da lista; `EURUSD` sem grafico | 06/11 14:23 | `list_open_charts` + `Data\` | DONO (Q-013) |
| **G11** | Forward **30 dias** em demo com o binario final: PF **>= 1.2**, DD **<= 8 %**, **>= 30** trades, **0** violacoes de risco | **VERMELHO** - **0** dias registados; **0** posicoes desde o reload | 06/11 14:35 | `get_trading_history_positions` | DONO autoriza / DELTA mede |

## 2. Ordem de desbloqueio (nao e livre)

1. **G1 + G2** primeiro. Sem conta real e sem token, todos os outros itens ou sao inmediveis ou medem um robô que nao decide nada.
2. **G4** a seguir: provar o binario em memoria. Medir comportamento de um binario que nao e o que esta a correr e trabalho perdido.
3. **G3** depois de G2: e a primeira medicao que o token torna possivel.
4. **G5 / G6 / G7 / G8** em bloco: sao o mesmo job do ALFA/CMD, lidos por quatro criterios.
5. **G11** so com o binario final e o `.set` final.
6. **G9 / G10** fecham por ultimo, imediatamente antes de abrir conta real.

## 3. O que este gate NAO e

- Nao e promessa de lucro. Um gate todo verde continua a nao garantir resultado futuro.
- Nao e "10/10". E 11 condicoes verificaveis com numero, data e ferramenta.
- Nao e substituivel por autorizacao verbal. "Acesso completo" da acesso a ficheiros; nao substitui o numero que falta em cada linha.

## 4. Registo de passagem

Preencher apenas com medicao. Uma linha por item que passa a verde.

| Data | ID | Valor medido | Evidencia (ficheiro:linha / ferramenta) | Quem mediu |
|---|---|---|---|---|
| 06/11 15:50 | **G2** | 9011 no ar (PID 1464); `GET` com Bearer do `.env` = **200 / 1122 B**; sem token = 401; token errado = 401; EA: `[AI] GATEWAY RECUPERADO \| cego=209s` as 15:44:37 | `delta_probe_9011.ps1`, `get_expert_journal`, `delta_edge_all.ps1` | DELTA |
| | | | | |
