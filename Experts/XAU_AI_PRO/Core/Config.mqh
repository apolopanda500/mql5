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
input double MinEquityPercent   = 50.0;  // Equity mínima (% do balance) para operar

input int    MaxTradesPerDay    = 10;
input int    MaxOpenPositions   = 1;

//==================================================
// EXECUÇÃO
//==================================================
// MaxSpread (pontos) - limite de spread por símbolo.
// Antes 30.0: em backtest/M15 o GOLD# tem spread ~31,
// o que fazia o ValidateTrade bloquear com
// "[VALIDATION] BLOCK | SPREAD | GOLD# | 31.00/30.00".
// Ajustado para 50.0 para tolerar o spread normal do ouro
// (~30-40 pips) mantendo proteção contra spread anormal.
input double MaxSpread          = 50;
input int    Slippage           = 5;

//==================================================
// STOP
//==================================================
input int StopLossPoints        = 300;
input int TakeProfitPoints      = 600;

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
// IA
//==================================================
input double MinAIConfidence    = 50.0;

//==================================================
// SESSÃO
//==================================================
input int TradeStartHour        = 0;
input int TradeEndHour          = 24;

//==================================================
// INDICADORES
//==================================================
input int FastEMA               = 50;
input int SlowEMA               = 200;

input int RSIPeriod             = 14;
input int ATRPeriod             = 14;
input int ADXPeriod             = 14;

input double MinimumADX         = 18.0;

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
// MULTI SYMBOL
//==================================================
input bool EnableMultiSymbol    = true;

input string Symbols=
"GOLD#,"     // ← ALTERE AQUI para o nome do símbolo da sua corretora
"BTCUSD#,"   // Ex: XAUUSD, XAUUSD.pro, GOLD, etc.
"ETHUSD#,"   // Verifique no Market Watch (Ctrl+M)
"EURUSD#,"   // Nome completo com sufixo se houver
"GBPUSD#,"
"USDJPY#,"
"AUDUSD#,"
"USDCAD#,"
"NZDUSD#";

//==================================================
// DEBUG - NÃO ALTERE
//==================================================
input bool EnableVerboseDebug    = true;  // Logs detalhados para debug

#endif