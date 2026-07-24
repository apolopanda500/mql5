#ifndef CONFIG_MQH
#define CONFIG_MQH

//==================================================
// GERAL
//==================================================
input bool   AutoTrade    = true;
input long   MagicNumber  = 2026001;
input string TradeComment = "XAU_AI_PRO";


//==================================================
// RISCO GLOBAL
//==================================================
input bool   UseRiskManagement   = true;
input double LotSize             = 0.01;
input double RiskPercent         = 1.0;

input double MaxDailyLossPercent = 5.0;
input double MaxDrawdownPercent  = 15.0;

input int    MaxTradesPerDay     = 10;
input int    MaxOpenPositions    = 1;


//==================================================
// EXECUÇÃO
//==================================================
input double MaxSpread = 30.0;
input int    Slippage  = 5;


//==================================================
// STOP / TAKE PROFIT
//==================================================
input int StopLossPoints   = 300;
input int TakeProfitPoints = 600;


//==================================================
// BREAK EVEN
//==================================================
input bool EnableBreakEven  = true;
input int  BreakEvenTrigger = 150;
input int  BreakEvenOffset  = 10;


//==================================================
// TRAILING STOP
//==================================================
input bool   EnableTrailingATR = true;
input double ATRMultiplier     = 2.0;


//==================================================
// FECHAMENTO PARCIAL
//==================================================
input bool   EnablePartialClose = true;
input int    PartialTrigger     = 300;
input double PartialPercent     = 50.0;


//==================================================
// FILTROS
//==================================================
input bool EnableNewsFilter       = false;
input bool EnableSessionFilter    = false;
input bool EnableTrendFilter      = true;
input bool EnableAIFilter         = true;
input bool EnableVolatilityFilter = false;


//==================================================
// IA
//==================================================
input double MinAIConfidence = 50.0;


//==================================================
// SESSÃO
//==================================================
input int TradeStartHour = 0;
input int TradeEndHour   = 24;


//==================================================
// INDICADORES
//==================================================
input int RSIPeriod = 14;
input int ADXPeriod = 14;
input int ATRPeriod = 14;

input int FastEMA = 50;
input int SlowEMA = 200;


//==================================================
// FILTROS AVANÇADOS
//==================================================

input bool EnableADXFilter = true;
input double MinimumADX = 18.0;

input bool EnableSpreadFilter = true;

input bool EnableMTFConfirmation = false;


//==================================================
// DATASET / ML
//==================================================
input bool EnableDataset     = true;
input bool SaveDatasetCSV    = true;
input bool EnableBacktestLog = true;


//==================================================
// DEBUG / UI
//==================================================
input bool EnableLogs      = true;
input bool EnableDashboard = true;


//==================================================
// MODO DEBUG DE ENTRADA
//==================================================

input bool DebugTradeDecision = true;

//====================================
// MULTI SYMBOL
//====================================

input bool EnableMultiSymbol = true;

input string Symbols =
"XAUUSDc,BTCUSDc,ETHUSDc,EURUSDc,GBPUSDc,USDJPYc,AUDUSDc,USDCADc,NZDUSDc";

#endif
