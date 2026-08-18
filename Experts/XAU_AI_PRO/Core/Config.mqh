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

input double MinFreeMargin      = 20.0;  // Margem livre minima (moeda da conta)

input int    MaxTradesPerDay    = 20;
input int    MaxOpenPositions   = 5;

//==================================================
// EXECUCAO
//==================================================
// MaxSpread (pontos) - limite de spread por simbolo.
// Antes 30.0: em backtest/M15 o GOLD# tem spread ~31,
// o que fazia o ValidateTrade bloquear com
// "[VALIDATION] BLOCK | SPREAD | GOLD# | 31.00/30.00".
// Ajustado para 50.0 para tolerar o spread normal do ouro
// (~30-40 pips) mantendo protecao contra spread anormal.
input double MaxSpread          = 50;
// Limites de spread POR SIMBOLO (pontos), separados por virgula.
// Formato: "SIMBOLO:limite,SIMBOLO:limite"
// Crypto (BTCUSD#, ETHUSD#) tem spread natural alto em pontos
// (~345-1500+), por isso usa limite proprio bem maior.
// Simbolos nao listados usam MaxSpread (fallback).
input string MaxSpreadBySymbol  = "GOLD#:350,BTCUSD#:600,ETHUSD#:600";

//==================================================
// GET MAX SPREAD BY SYMBOL
// Retorna o limite de spread especifico do simbolo
// ou o fallback MaxSpread se nao configurado.
//==================================================
double GetMaxSpread(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   string list = MaxSpreadBySymbol;
   StringTrimLeft(list);
   StringTrimRight(list);
   if(list == "")
      return MaxSpread;

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
         if(StringCompare(sym, symbol, false) == 0)
            return StringToDouble(val);
      }
   }
   return MaxSpread;
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
// NEWS FILTER v1.2.0
// Economic Calendar nativo (filtro real).
// Filtro base: EnableNewsFilter.
// Ajustes de janela/impacto abaixo.
//==================================================
input bool   EnableNewsFilterReal  = false;
input string NewsCurrencies        = "USD,EUR,GBP";
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
// Placeholder para fechamento do agendador/timer.
//==================================================
input bool   EnableScheduler       = true;
input int    SchedulerIntervalSec  = 60;
input bool   EnableWeekendShutdown = true;

//==================================================
// DATABASE / TELEMETRY v1.2.0
// Placeholder para integracao com DatabaseManager,
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
"XAGUSD,"
"US30,"
"US500,"
"USTEC";

//==================================================
// DEBUG - NAO ALTERE
//==================================================
input bool EnableVerboseDebug    = true;  // Logs detalhados para debug

#endif
