#ifndef TRADEMONITOR_MQH
#define TRADEMONITOR_MQH


#include "../Core/Config.mqh"

#include "../Core/PerformanceAnalyzer.mqh"

#include "../AI/AIEngine.mqh"

#include "../Indicators/VolatilityFilter.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/RSI.mqh"

//==================================================
// TRADE MONITOR ENGINE
//==================================================

datetime LastProcessedDealTime = 0;



//==================================================
// CHECK CLOSED TRADES
//==================================================

void CheckClosedTrades()
{

   if(!HistorySelect(0,TimeCurrent()))
      return;


   int deals = HistoryDealsTotal();



   for(int i=deals-1;i>=0;i--)
   {


      ulong ticket = HistoryDealGetTicket(i);


      if(ticket==0)
         continue;



      datetime dealTime =
      (datetime)
      HistoryDealGetInteger(
         ticket,
         DEAL_TIME
      );



      if(dealTime<=LastProcessedDealTime)
         break;



      ENUM_DEAL_ENTRY entry =
      (ENUM_DEAL_ENTRY)
      HistoryDealGetInteger(
         ticket,
         DEAL_ENTRY
      );



      if(entry!=DEAL_ENTRY_OUT)
         continue;



      double profit =
      HistoryDealGetDouble(
         ticket,
         DEAL_PROFIT
      );


      double price =
      HistoryDealGetDouble(
         ticket,
         DEAL_PRICE
      );


      double volume =
      HistoryDealGetDouble(
         ticket,
         DEAL_VOLUME
      );


      string symbol =
      HistoryDealGetString(
         ticket,
         DEAL_SYMBOL
      );


      //==================================================
      // AI SCORE
      //==================================================

      int signal =
      (profit>=0 ? 1 : -1);



      double ai =
      GetAIConfidence(signal);



      //==================================================
      // BACKTEST LOG
      //==================================================

      BacktestLog(
         signal,
         price,
         volume,
         0,
         GetATR(),
         GetADX(),
         GetRSI(),
         ai,
         (profit>=0 ? "WIN":"LOSS")
      );



      //==================================================
      // OUTPUT
      //==================================================

      Print(
      "TRADE CLOSED | ",
      symbol,
      " | Profit: ",
      DoubleToString(profit,2),
      " | AI: ",
      DoubleToString(ai,2),
      " | Total Trades: ",
      PA_TotalTrades
      );



      LastProcessedDealTime = dealTime;


   }

}

//==================================================
// BACKTEST LOG
//==================================================

void BacktestLog(
   int signal,
   double price,
   double volume,
   double spread,
   double atr,
   double adx,
   double rsi,
   double ai,
   string result
)

{

   Print(
      "BACKTEST | ",
      "Signal=",
      signal,
      " Price=",
      DoubleToString(price,2),
      " Volume=",
      DoubleToString(volume,2),
      " Spread=",
      DoubleToString(spread,2),
      " ATR=",
      DoubleToString(atr,2),
      " ADX=",
      DoubleToString(adx,2),
      " RSI=",
      DoubleToString(rsi,2),
      " AI=",
      DoubleToString(ai,2),
      " Result=",
      result
   );

}

#endif
