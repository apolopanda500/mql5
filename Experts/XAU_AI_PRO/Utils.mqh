#ifndef UTILS_MQH
#define UTILS_MQH

#include "Core/Config.mqh"
#include "Indicators/TrendStrength.mqh"
#include "Indicators/VolatilityFilter.mqh"

//==================================================
// NOVA BARRA
//==================================================
bool IsNewBar()
{
   static datetime utils_lastBarTime = 0;

   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBar != utils_lastBarTime)
   {
      utils_lastBarTime = currentBar;
      return true;
   }

   return false;
}

//==================================================
// UMA OPERAÇÃO POR CANDLE
//==================================================
bool NewTradeAllowed()
{
   static datetime utils_lastTradeBarTime = 0;

   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBar != utils_lastTradeBarTime)
   {
      utils_lastTradeBarTime = currentBar;
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
   TimeToStruct(TimeCurrent(), tm);

   return (tm.hour >= TradeStartHour && tm.hour < TradeEndHour);
}

//==================================================
// DRAWDOWN
//==================================================
double GetCurrentDrawdown()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   if(balance <= 0)
      return 0.0;

   return ((balance - equity) / balance) * 100.0;
}

//==================================================
bool MaxDrawdownCheck(double maxDD)
{
   return GetCurrentDrawdown() < maxDD;
}

//==================================================
// MARKET FILTER
//==================================================
bool MarketQualityFilter()
{
   return true;
}

//==================================================
// BROKER SYMBOL AUTO SUFFIX
//==================================================

string BrokerSymbol(string base)
{

   string withSuffix =
      base + "c";


   if(SymbolSelect(withSuffix,true))
      return withSuffix;


   if(SymbolSelect(base,true))
      return base;


   return "";

}

#endif
