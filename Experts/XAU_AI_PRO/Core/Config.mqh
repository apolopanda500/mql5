// XAU_AI_PRO v1.2.0
#ifndef CONFIG_MQH
#define CONFIG_MQH

//==================================================
// GERAL
//==================================================
input bool   AutoTrade          = true;
input long   MagicNumber        = 2026001;
input string TradeComment       = "XAU_AI_PRO";

//==================================================
// RISCO
//==================================================
input bool   UseRiskManagement  = true;
input double LotSize            = 0.01;
input double RiskPercent        = 1.0;

input double MaxDailyLossPercent= 5.0;
input double MaxDrawdownPercent = 15.0;
input double MinEquityPercent   = 10.0;  // Equity minima (% do balance) para operar

input double MinFreeMargin      = 10.0;  // Margem livre minima (moeda da conta)

input int    MaxTradesPerDay    = 20;
input int    MaxOpenPositions   = 5;

// v1.3.0 (Etapa 3): quando o risco configurado exige lote abaixo do
// minimo do broker. true = opera no minimo (comportamento antigo,
// risco real maior que o configurado). false = estrito, bloqueia.
input bool   AllowMinLotOverride = true;

//==================================================
// LIMITE DE SPREAD — EM PORCENTAGEM DO PRECO (08/10/2026)
//==================================================
// MEDIDO na conta 391773676 (XMGlobal-MT5 14), terminal aberto, com o EA
// operando BTCUSD H4:
//
//   simbolo   point    spread_preco   spread_pts   limite de 50 pts =   bloqueia?
//   BTCUSD    0.01        40,00000       4000,0           0,50000        SIM
//   ETHUSD    0.01         3,00000        300,0           0,50000        SIM
//   USDSEK    0.00001      0,01550       1579,0           0,00050        SIM
//   GOLD      0.01         0,57000         57,0           0,50000        SIM
//   USDCNH    0.0001       0,00430         43,0           0,00500        nao
//   EURUSD    0.00001      0,00019         19,0           0,00050        nao
//
// 4 de 12 simbolos BLOQUEADOS com spread NORMAL. E o OURO, por 57 contra 50:
// um limite em pontos crus e fragil ate no metal que da nome ao projeto.
//
// A CAUSA: `point` varia mil vezes entre um forex e o BTCUSD. "50 pontos"
// vale $5,00 no BTCUSD e $0,0005 no EURUSD. O mesmo numero nao pode servir
// as duas coisas.
//
// A CAUSA SEGUNDA: o mapa por simbolo nao ACERTAVA para nenhum dos tres que
// ele nomeava. Os nomes tinham `#` no fim (`GOLD#:350`) e a comparacao e
// `StringCompare(sym, symbol, false)` com `symbol = _Symbol`, que e `GOLD` —
// sem `#`. Entao o mapa caia sempre no fallback. (O `CircuitBreaker.mqh:153`
// ja tinha um comentario sobre isso; o comentario estava certo e o codigo
// continuou errado.)
//
// A CORRECAO: o limite passa a ser PORCENTAGEM DO PRECO, e o
// `GetMaxSpread` continua devolvendo PONTOS — derivados do preco e do `point`
// do proprio simbolo. Entao os SEIS lugares que comparam
// (`SymbolValidator:123`, `ValidationEngine:90`, `SpreadFilter:91` e `:145`,
// `SmartExecution:334` e `:341`) nao mudam uma linha, e a unidade do broker
// deixa de importar.
//
// FOLGA MEDIDA com 0,6% de fallback (spread real em % do preco):
//   USDSEK 0,158% -> 3,8x   ETHUSD 0,121% -> 5,0x   USDCNH 0,064% -> 9,4x
//   BTCUSD 0,049% -> 12,3x  NZDUSD 0,055% -> 10,8x  GOLD 0,014% -> 43,6x
// Todos passam, e o mais apertado ainda tem 3,8x antes de a trava fechar.
input double MaxSpreadPct       = 0.6;
// Limites POR SIMBOLO, tambem em porcentagem. Formato "SIMBOLO:pct".
// Sem `#`: o nome e o que o terminal escreve, e `_Symbol` nao tem sufixo.
// Simbolos nao listados usam MaxSpreadPct.
input string MaxSpreadPctBySymbol = "";

//==================================================
// GET MAX SPREAD PCT — a porcentagem do simbolo
//==================================================
double GetMaxSpreadPct(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   string list = MaxSpreadPctBySymbol;
   StringTrimLeft(list);
   StringTrimRight(list);
   if(list != "")
   {
      string entries[];
      int n = StringSplit(list, ',', entries);
      for(int i = 0; i < n; i++)
      {
         string kv[];
         int k = StringSplit(entries[i], ':', kv);
         if(k == 2)
         {
            string sym = kv[0];
            StringTrimLeft(sym);
            StringTrimRight(sym);
            string val = kv[1];
            StringTrimLeft(val);
            StringTrimRight(val);
            // Comparacao sem `#`: `_Symbol` nunca tem sufixo, e era exatamente
            // o sufixo que fazia o mapa nunca casar (medido acima).
            if(StringCompare(sym, symbol, false) == 0)
            {
               double pct = StringToDouble(val);
               if(pct > 0.0)
                  return pct;
            }
         }
      }
   }
   return(MaxSpreadPct > 0.0 ? MaxSpreadPct : 0.6);
}

//==================================================
// GET MAX SPREAD — em PONTOS, derivado do preco
//==================================================
// A UNIDADE CONTINUA SENDO PONTO, porque os seis leitores ja comparam com
// `spread = (ask-bid)/point`. O que muda e de onde o numero vem: em vez de
// "50 pontos" escrito a mao, e a porcentagem do preco convertida no `point`
// daquele simbolo.
double GetMaxSpread(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   double pct = GetMaxSpreadPct(symbol);
   if(pct <= 0.0)
      return(50.0);

   double ask  = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Sem ficha do simbolo nao ha preco nem point: nao se chora o limite, e
   // nao se inventa um numero. O fallback e a mesma 50 pontos de antes.
   if(point <= 0.0)
      return(50.0);
   if(ask <= 0.0)
      ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask <= 0.0)
      return(50.0);

   double limitePreco = ask * pct / 100.0;
   double limitePts   = limitePreco / point;
   if(limitePts <= 0.0)
      return(50.0);

   // Teto e piso em PONTOS, para o limite nao virar absurdo em nenhum dos
   // extremos: 1 ponto no minimo (nunca "spread 0"), e 100.000 no maximo.
   if(limitePts < 1.0)
      return(1.0);
   if(limitePts > 100000.0)
      return(100000.0);
   return(limitePts);
}
input int    Slippage           = 5;

//==================================================
// ORDER RETRY v1.2.0
// Parametros centralizados de retry de ordens.
//==================================================
input int    RetryMaxAttempts       = 5;
input int    RetryBaseDelayMs       = 100;
input double RetryDelayMultiplier   = 2.0;
input int    RetryMaxDelayMs        = 2000;
input int    RetryMaxSlippage       = 50;
input int    RetrySlippageIncrement = 2;


//==================================================
// STOP
//==================================================
input int StopLossPoints        = 300;
input int TakeProfitPoints      = 600;

//----------------------------------------------
// Risco por operacao em DINHEIRO (decisao do dono, 08/10/2026)
//----------------------------------------------
// MEDIDO na conta 391773676: `StopLossPoints=300` e PONTOS CRUOS, e ponto nao
// e dinheiro. No GOLD (point 0,01) dava US$ 3,00; no EURUSD (point 0,00001)
// dava US$ 3,00 tambem; no USDJPY daria US$ 20 e no BTCUSD US$ 0,03. Um
// numero so, quatro riscos diferentes.
//
// E o pior: US$ 3,00 contra um orcamento diario de 5% de US$ 12,13 = US$ 0,61.
// Uma operacao estouraria o limite diario inteiro, que foi exatamente o que
// aconteceu: SELL 0,01 GOLD @ 4152,43 com stop em 4155,43 (+3,00), tocado.
//
// Aqui o risco e em DOLARES e vale para todos os simbolos. `RewardRatio = 1.0`
// deixa alvo e stop iguais (2 por 2, 3 por 3); 2.0 volta ao 1:2 antigo.
// Os inputs em PONTOS continuam existindo como caminho de fuga: se
// `RiskPerTradeUsd <= 0` eles voltam a valer, entao nenhum controle fica sem
// consumidor.
input double RiskPerTradeUsd     = 2.0;   // risco do STOP por operacao, em moeda da conta
input double RewardRatio         = 1.0;   // alvo = risco x isto. 1.0 = 1:1

//----------------------------------------------
// SEM STOP a partir de um LOTE (decisao do dono, 08/10/2026)
//----------------------------------------------
// "apartir de 0.4 nao tem stop, alvos curtos". Implementado como pedido, com o
// numero que o dono escolheu — nao troquei por um que coubesse na conta.
//
// MEDIDO 08/10/2026 na conta 391773676 (balance 12,13, margem livre 15,48):
// 0,4 de lote NAO ABRE. Exige 165,91 no GOLD, 44,87 no EURUSD, 32,72 no
// BTCUSD. O maior lote que passa e 0,05. Portanto ESTA REGRA NAO DISPARA HOJE:
// ela so acende se a conta for funded. E por isso que o log abaixo e alto e
// explicito — quem ler um "sem stop" no journal tem de saber que e uma
// decisao configured, nao um bug.
//
// AVISO DE RISCO, medido e nao teorico: sem stop, uma vela M5 tipica de 0,2
// lote no EURUSD move US$ 6,20 = 51% do balance, e o p90 de 24h move US$ 13,00
// = 107%. O limite diario de 5% (US$ 0,61) BLOQUEIA OPERACOES NOVAS, mas nao
// fecha nem limita a que ja esta aberta. Sem stop, a posicao nao tem teto.
input double NoStopFromLot      = 0.4;   // >= este lote: abrir SEM stop loss

//----------------------------------------------
// Gatilhos de gestao em DINHEIRO (mesma doenca dos pontos crus)
//----------------------------------------------
// MEDIDO 08/10/2026: com SL e TP em dolares, `PartialTrigger`, `BreakEvenTrigger`
// e `BreakEvenOffset` continuaram em PONTOS, e pararam de ter relacao com o
// risco. 150 pontos num trade de US$ 2 e 75% do alvo; no BTCUSD, 150 pontos e
// 1,5% do alvo. Terceira vez que a mesma doenca aparece (spread, SL/TP, agora
// os gatilhos). Todos em dolar, com os inputs em pontos como caminho de fuga
// quando o valor em dollar for <= 0, para nenhum controle ficar sem consumidor.
input double PartialTriggerUsd  = 2.0;   // lucro flutuante que dispara o fechamento parcial
input double BreakEvenTriggerUsd = 1.0;  // lucro flutuante que arma o break-even
input double BreakEvenOffsetUsd = 0.1;   // quanto o SL passa do preco de entrada

//==================================================
// BREAK EVEN
//==================================================
input bool EnableBreakEven      = true;
input int  BreakEvenTrigger     = 80;
input int  BreakEvenOffset      = 10;

//==================================================
// TRAILING
//==================================================
input bool   EnableTrailingATR  = true;
input double ATRMultiplier      = 1.2;

//==================================================
// PARCIAL
//==================================================
input bool   EnablePartialClose = true;
input int    PartialTrigger     = 150;
input double PartialPercent     = 30.0;

//==================================================
// FILTROS
//==================================================
input bool EnableSpreadFilter      = true;
input bool EnableSessionFilter     = false;
input bool EnableTrendFilter       = true;
input bool EnableVolatilityFilter  = false;
input bool EnableADXFilter         = true;
input bool EnableMTFConfirmation   = false;
input bool EnableNewsFilter        = false;
input bool EnableAIFilter          = true;

//==================================================
// NEWS FILTER v1.3.0 (Etapa 6)
// Economic Calendar nativo MQL5 com estados
// NEWS_CLEAR/WARNING/BLOCK/ACTIVE, throttle de
// 60s e filtro por moeda.
// NewsCurrencies vazio = auto-derivacao pelo simbolo
// (XAUUSD->USD, EURUSD->EUR+USD). Lista manual tem
// prioridade sobre a auto-derivacao.
//==================================================
input string NewsCurrencies        = "";
input int    NewsImpactThreshold   = 2;        // 1=low, 2=medium, 3=high
input int    NewsMinutesBefore     = 30;
input int    NewsMinutesAfter      = 30;


//==================================================
// IA
//==================================================
input double MinAIConfidence    = 50.0;

//==================================================
// IA - JSON (v1.2.0)
//==================================================
// RequireAIJSON=false (padrao): o arquivo
// prediction_<SYMBOL>.json e opcional. Quando ausente,
// o AIEngine usa o fallback local (indicadores/score).
// Necessario para backtest, pois o pipeline Python
// nao roda dentro do Strategy Tester.
// RequireAIJSON=true: exige o JSON do pipeline Python
// para liberar o simbolo (modo producao estrito).
input bool   RequireAIJSON      = false;

//==================================================
// IA - STALENESS (ETAPA 15.3)
// Idade maxima aceita para o timestamp_utc do
// prediction JSON, em segundos. 0 = verificacao
// desativada. Previsao mais antiga que o limite
// e tratada como INDISPONIVEL (o AIEngine cai no
// fallback local ou bloqueia, conforme politica).
// Padrao 900s = 15 min (~3 candles M5).
//==================================================
input int    MaxPredictionAgeSec = 900;

//==================================================
// KCI v1.2.0
// Parametros centralizados dos indicadores KCI.
//==================================================
input int    KCI_VD_Period        = 14;
input int    KCI_DX_BasePeriod    = 9;
input int    KCI_DX_ZScorePeriod  = 30;
input double KCI_DX_Sensitivity   = 1.5;
input double KCI_DX_MainThreshold = 30.0;


//==================================================
// SESSAO
//==================================================
input int TradeStartHour        = 0;
input int TradeEndHour          = 24;

//==================================================
// INDICADORES
//==================================================
input ENUM_TIMEFRAMES SignalTF     = PERIOD_CURRENT;
input int FastEMA               = 50;
input int SlowEMA               = 200;

input int RSIPeriod             = 14;

//==================================================
// SINAL PULLBACK v1.2.0
// Niveis de RSI (vela fechada) para entrada por pullback:
//  - BUY  exige RSI fechado ABAIXO de RSIPullbackBuy  (dip na tendencia de alta)
//  - SELL exige RSI fechado ACIMA  de RSIPullbackSell (rally na tendencia de baixa)
// Valores 40/60 = mais seletivo (menos sinais, maior qualidade)
// Valores 45/55 = moderado (padrao)
// Valores 50/50 = comportamento antigo (muito permissivo)
//==================================================
input double RSIPullbackBuy     = 45.0;
input double RSIPullbackSell    = 55.0;

input int ATRPeriod             = 14;
input int ADXPeriod             = 14;

input double MinimumADX         = 18.0;

//==================================================
// SCHEDULER v1.2.0
// Agendador interno: intervalo de execucao + shutdown de fim de semana.
//==================================================
input bool   EnableScheduler       = true;
input int    SchedulerIntervalSec  = 60;
input bool   EnableWeekendShutdown = true;

//==================================================
// DATABASE / TELEMETRY v1.2.0
// Integracao com DatabaseManager,
// TradeLogger e Statistics.
//==================================================
input bool   EnableDatabase        = false;
input string DatabasePath          = "XAU_AI_PRO.db";
input bool   EnableTelemetry       = true;


//==================================================
// DATASET
//==================================================
input bool EnableDataset        = true;
input bool SaveDatasetCSV       = true;
input bool EnableBacktestLog    = true;

//==================================================
// DASHBOARD
//==================================================
input bool EnableDashboard      = true;
input bool EnableLogs           = true;
input bool DebugTradeDecision   = true;

//==================================================
// MONITORING & AUDITORIA (ETAPA 6)
// HealthMonitor absorveu o WatchDog (heartbeat dos
// modulos ATR/ADX/RSI/AI/PYTHON/CSV/JSON).
// AuditLog absorveu o FullAudit (registro estruturado
// de entrada/saida por ticket em Data\full_audit.csv).
//==================================================
input bool EnableHealthMonitor   = true;   // HealthMonitor + WatchDog integrado
input int  HealthCheckInterval   = 60;     // segundos entre health checks completos
input int  HealthWatchdogInterval= 120;    // segundos sem heartbeat para contar falha (liveness)
input int  HealthPipelineProgressTimeout= 0;  // 0 = auto (2x cadencia da vela, min WatchdogInterval)
input bool EnableAuditLog        = true;   // Auditoria (decisoes + full audit)
input bool EnableDiagnostics     = true;   // Diagnostico completo no OnInit

//==================================================
// REPLAY & BACKUP (ETAPA 7)
// ReplayEngine: reproduz decisoes/eventos historicos
// sem interferir na execucao real (REPLAY != LIVE).
// BackupManager: snapshots em FILE_COMMON + local,
// com wildcards, manifesto e restauracao validada.
//==================================================
input bool   EnableReplay          = false;  // REPLAY: reproduz historico, bloqueia trades reais
input string ReplayDatasetFile     = "Data\\trades_dataset.csv"; // decisoes (Dataset.mqh export)
input string ReplayOHLCFile        = "Data\\dataset.csv";        // OHLC/tick (DataLogger.mqh)
input string ReplayAuditFile       = "Data\\full_audit.csv";     // entradas/saidas (AuditLog.mqh)
input string ReplaySymbolFilter    = "";     // vazio = todos; ex: "XAUUSD" ou "GOLD#"
input bool   EnableBackupManager   = true;   // Backup automatico dos dados do EA
input int    BackupIntervalMinutes = 60;     // 0 = somente manual (OnInit)
input int    BackupMaxKeep         = 10;     // snapshots mantidos (limpeza automatica)

//==================================================
// BACKTEST ANALYZER & BENCHMARK (ETAPA 8)
// BacktestAnalyzer: registra cada trade do tester
// em BacktestReport.csv e calcula metricas (win rate,
// profit factor, drawdown, sharpe, expectativa).
// BenchmarkEngine: compara estrategias (Technical,
// AI, Hybrid, Ensemble) e elege a melhor.
//==================================================
input bool EnableBacktestAnalyzer = true;   // ANALISE: log + metricas de backtest
input bool EnableBenchmark        = true;   // BENCHMARK: comparacao de estrategias

//==================================================
// NOTIFICATION CENTER (ETAPA 9)
// Camada de observabilidade (Push nativo + Telegram).
// NUNCA bloqueia o trading: falha de notificacao apenas
// conta e registra, sem interferir no fluxo do EA.
//==================================================
input bool   EnableNotifications     = true;   // Central de notificacoes
input bool   NotifyPushEnabled       = true;   // Push nativo MT5 (SendNotification)
input string NotifyTelegramToken     = "";     // Token do bot Telegram (vazio = OFF)
input string NotifyTelegramChatID    = "";     // Chat ID do Telegram
input int    NotifyCooldownSec       = 30;     // cooldown entre mensagens (mesma categoria)
input int    NotifyMaxPerMinute      = 10;     // limite anti-spam global
input bool   NotifyTradeEvents       = true;   // notificar abertura/fechamento
input bool   NotifyErrors            = true;   // notificar erros
input bool   NotifyDrawdown          = true;   // notificar drawdown
input double NotifyDrawdownThreshold = 5.0;    // % minimo de drawdown para alertar
input bool   NotifyHealth            = true;   // notificar falha de HealthMonitor
input bool   NotifyCircuitBreaker    = true;   // notificar Circuit Breaker / SAFE
input bool   NotifyExecutionFailures = true;   // notificar rejeicoes de ordem

//==================================================
// MULTI SYMBOL
//==================================================
input bool EnableMultiSymbol    = true;

input string Symbols=
"XAUUSD,"    // Conta DEMO - nomes reais sem sufixo
"EURUSD,"
"GBPUSD,"
"USDJPY,"
"AUDUSD,"
"USDCAD,"
"NZDUSD,"
"USDCHF,"
"USDBRL,"
"USDSEK,"

"USDCNH";

//==================================================
// RISCO EM DINHEIRO -> DISTANCIA EM PONTOS
//==================================================
// Definicao UNICA do "quanto de preco corresponde a N dolares de risco" para um
// simbolo e um lote. `ExecutionEngine` e `OrderManager` consomem ISTA funcao.
//
// Se cada um dividisse por conta propria, um deles acabaria com um numero e o
// outro com outro — e o sintoma seria o mesmo que ja-investigamos: o cliente
// lendo um nome e o servidor entregando outra medida.
//
// `distancia = risco_usd / (contrato x volume x point)`
//
// `SYMBOL_TRADE_CONTRACT_SIZE` e propriedade DOUBLE, nao enum inteiro: no MT5 o
// tamanho de contrato pode ser fracionario, e o compilador rejeita com
// "cannot convert enum" quando ele e pedido como `SymbolInfoInteger`. Medido
// em 08/10/2026: e o primeiro erro que aparece ao compilar este trecho.
double DistanciaPontosParaRiscoUSD(
   string symbol,
   double volume,
   double risco_usd
)
{
   if(risco_usd <= 0.0 || volume <= 0.0)
      return(0.0);

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double contrato = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   if(point <= 0.0 || contrato <= 0.0)
      return(0.0);

   return(risco_usd / (contrato * volume * point));
}

//==================================================
// DEBUG - NAO ALTERE
//==================================================
input bool EnableVerboseDebug    = true;  // Logs detalhados para debug

#endif
