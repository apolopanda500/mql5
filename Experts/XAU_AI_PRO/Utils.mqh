#ifndef UTILS_MQH
#define UTILS_MQH

#include "Core/Config.mqh"
#include "Indicators/TrendStrength.mqh"
#include "Indicators/VolatilityFilter.mqh"

//==================================================
// XAU_AI_PRO - UTILS
// Multi-Symbol / Multi-Asset
//==================================================


//==================================================
// NOVA BARRA - SYMBOL/TIMEFRAME ATUAL
//==================================================

bool IsNewBar()
{
   static datetime lastBarTime = 0;

   datetime currentBar =
      iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBar <= 0)
      return false;

   if(currentBar != lastBarTime)
   {
      lastBarTime = currentBar;
      return true;
   }

   return false;
}


//==================================================
// NOVA BARRA - SYMBOL ESPECÍFICO
//==================================================

bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
{
   static string   lastSymbol = "";
   static datetime lastBarTime = 0;

   datetime currentBar =
      iTime(symbol, timeframe, 0);

   if(currentBar <= 0)
      return false;

   if(symbol != lastSymbol)
   {
      lastSymbol  = symbol;
      lastBarTime = currentBar;
      return true;
   }

   if(currentBar != lastBarTime)
   {
      lastBarTime = currentBar;
      return true;
   }

   return false;
}


//==================================================
// UMA OPERAÇÃO POR CANDLE
//==================================================

bool NewTradeAllowed()
{
   static datetime lastTradeBarTime = 0;

   datetime currentBar =
      iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBar <= 0)
      return false;

   if(currentBar != lastTradeBarTime)
   {
      lastTradeBarTime = currentBar;
      return true;
   }

   return false;
}


//==================================================
// UMA OPERAÇÃO POR CANDLE - SYMBOL/TIMEFRAME
//==================================================

bool NewTradeAllowed(
   string symbol,
   ENUM_TIMEFRAMES timeframe
)
{
   static string   lastTradeSymbol = "";
   static datetime lastTradeBarTime = 0;

   datetime currentBar =
      iTime(symbol, timeframe, 0);

   if(currentBar <= 0)
      return false;

   if(symbol != lastTradeSymbol)
   {
      lastTradeSymbol  = symbol;
      lastTradeBarTime = currentBar;
      return true;
   }

   if(currentBar != lastTradeBarTime)
   {
      lastTradeBarTime = currentBar;
      return true;
   }

   return false;
}


//==================================================
// SESSÃO
//==================================================

bool IsGoodSession()
{
   MqlDateTime tm;

   TimeToStruct(
      TimeCurrent(),
      tm
   );

   return (
      tm.hour >= TradeStartHour &&
      tm.hour < TradeEndHour
   );
}


//==================================================
// SESSÃO - SYMBOL
//==================================================

bool IsGoodSession(string symbol)
{
   if(symbol == "")
      symbol = _Symbol;

   MqlDateTime tm;

   TimeToStruct(
      TimeCurrent(),
      tm
   );

   return (
      tm.hour >= TradeStartHour &&
      tm.hour < TradeEndHour
   );
}


//==================================================
// DRAWDOWN ATUAL
//==================================================

double GetCurrentDrawdown()
{
   double balance =
      AccountInfoDouble(
         ACCOUNT_BALANCE
      );

   double equity =
      AccountInfoDouble(
         ACCOUNT_EQUITY
      );

   if(balance <= 0.0)
      return 0.0;

   double drawdown =
      ((balance - equity) / balance) * 100.0;

   if(drawdown < 0.0)
      drawdown = 0.0;

   return NormalizeDouble(
      drawdown,
      2
   );
}


//==================================================
// CHECK DRAWDOWN
//==================================================

bool MaxDrawdownCheck(double maxDD)
{
   if(maxDD <= 0.0)
      return true;

   return (
      GetCurrentDrawdown() < maxDD
   );
}


//==================================================
// MARKET QUALITY
//==================================================

bool MarketQualityFilter()
{
   return true;
}


//==================================================
// MARKET QUALITY - SYMBOL
//==================================================

bool MarketQualityFilter(string symbol)
{
   if(symbol == "")
      symbol = _Symbol;

   if(!SymbolSelect(symbol, true))
      return false;

   double point =
      SymbolInfoDouble(
         symbol,
         SYMBOL_POINT
      );

   double bid =
      SymbolInfoDouble(
         symbol,
         SYMBOL_BID
      );

   double ask =
      SymbolInfoDouble(
         symbol,
         SYMBOL_ASK
      );

   if(point <= 0.0)
      return false;

   if(bid <= 0.0 || ask <= 0.0)
      return false;

   if(ask <= bid)
      return false;

   return true;
}


//==================================================
// BROKER SYMBOL AUTO SUFFIX
//==================================================

string BrokerSymbol(string base)
{
   if(base == "")
      return "";
   
   // Símbolo exato
   if(SymbolSelect(base, true))
      return base;


   // Sufixos comuns de corretoras
   string suffixes[] =
   {
      "c",
      "C",
      ".c",
      "_c",
      "-c",
      "m",
      "M",
      ".m",
      "_m",
      "-m",
      "pro",
      "PRO",
      ".pro",
      "_pro",
      "ecn",
      "ECN",
      ".ecn",
      "_ecn"
   };


   int count =
      ArraySize(suffixes);


   for(int i = 0; i < count; i++)
   {
      string candidate =
         base + suffixes[i];

      if(SymbolSelect(candidate, true))
         return candidate;
   }


   // Prefixos comuns
   string prefixes[] =
   {
      "",
      ".",
      "_"
   };


   int prefixCount =
      ArraySize(prefixes);


   for(int p = 0; p < prefixCount; p++)
   {
      string candidate =
         prefixes[p] + base;

      if(SymbolSelect(candidate, true))
         return candidate;
   }


   return "";
}


//==================================================
// VERIFICA SE SYMBOL EXISTE
//==================================================

bool IsValidSymbol(string symbol)
{
   if(symbol == "")
      return false;

   if(!SymbolSelect(symbol, true))
      return false;

   double point =
      SymbolInfoDouble(
         symbol,
         SYMBOL_POINT
      );

   return (
      point > 0.0
   );
}


//==================================================
// NORMALIZA SYMBOL
//==================================================

string ResolveSymbol(string symbol)
{
   if(symbol == "")
      symbol = _Symbol;

   if(IsValidSymbol(symbol))
      return symbol;

   return BrokerSymbol(symbol);
}


//==================================================
// BID
//==================================================

double GetSymbolBid(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   return SymbolInfoDouble(
      symbol,
      SYMBOL_BID
   );
}


//==================================================
// ASK
//==================================================

double GetSymbolAsk(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   return SymbolInfoDouble(
      symbol,
      SYMBOL_ASK
   );
}


//==================================================
// SPREAD EM POINTS
//==================================================

double GetSymbolSpread(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   double point =
      SymbolInfoDouble(
         symbol,
         SYMBOL_POINT
      );

   if(point <= 0.0)
      return 0.0;

   double bid =
      SymbolInfoDouble(
         symbol,
         SYMBOL_BID
      );

   double ask =
      SymbolInfoDouble(
         symbol,
         SYMBOL_ASK
      );

   if(bid <= 0.0 || ask <= 0.0)
      return 0.0;

   return (
      (ask - bid) / point
   );
}


//==================================================
// VOLUME MÍNIMO
//==================================================

double GetMinVolume(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   return SymbolInfoDouble(
      symbol,
      SYMBOL_VOLUME_MIN
   );
}


//==================================================
// VOLUME MÁXIMO
//==================================================

double GetMaxVolume(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   return SymbolInfoDouble(
      symbol,
      SYMBOL_VOLUME_MAX
   );
}


//==================================================
// STEP DE VOLUME
//==================================================

double GetVolumeStep(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   return SymbolInfoDouble(
      symbol,
      SYMBOL_VOLUME_STEP
   );
}


//==================================================
// NORMALIZA VOLUME
//==================================================

double NormalizeVolume(
   string symbol,
   double volume
)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   double minVolume =
      GetMinVolume(symbol);

   double maxVolume =
      GetMaxVolume(symbol);

   double step =
      GetVolumeStep(symbol);

   if(step <= 0.0)
      return volume;

   if(volume < minVolume)
      volume = minVolume;

   if(volume > maxVolume)
      volume = maxVolume;

   volume =
      MathFloor(
         volume / step
      ) * step;

   return NormalizeDouble(
      volume,
      8
   );
}


//==================================================
// PREÇO VÁLIDO
//==================================================

bool IsValidPrice(
   string symbol,
   double price
)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return false;

   if(price <= 0.0)
      return false;

   double point =
      SymbolInfoDouble(
         symbol,
         SYMBOL_POINT
      );

   if(point <= 0.0)
      return false;

   return true;
}


//==================================================
// NORMALIZA PREÇO
//==================================================

double NormalizePrice(
   string symbol,
   double price
)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return price;

   int digits =
      (int)SymbolInfoInteger(
         symbol,
         SYMBOL_DIGITS
      );

   return NormalizeDouble(
      price,
      digits
   );
}


//==================================================
// DISTÂNCIA DE STOP EM POINTS
//==================================================

double GetStopsLevel(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return 0.0;

   long stopsLevel =
      SymbolInfoInteger(
         symbol,
         SYMBOL_TRADE_STOPS_LEVEL
      );

   return (double)stopsLevel;
}


//==================================================
// VOLUME DISPONÍVEL
//==================================================

bool HasTradingVolume(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return false;

   double volume =
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_MIN
      );

   return (
      volume > 0.0
   );
}


//==================================================
// MERCADO ABERTO PARA NEGOCIAÇÃO
//==================================================

bool IsSymbolTradeable(string symbol)
{
   symbol = ResolveSymbol(symbol);

   if(symbol == "")
      return false;

   long tradeMode =
      SymbolInfoInteger(
         symbol,
         SYMBOL_TRADE_MODE
      );

   if(
      tradeMode ==
      SYMBOL_TRADE_MODE_DISABLED
   )
   {
      return false;
   }

   return true;
}


//==================================================
// FINAL
//==================================================

#endif // UTILS_MQH