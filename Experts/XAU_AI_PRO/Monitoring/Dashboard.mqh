#ifndef DASHBOARD_MQH
#define DASHBOARD_MQH


#include "../Core/SignalCore.mqh"
#include "../Core/DecisionEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../Core/RiskEngine.mqh"
#include "../Core/PerformanceAnalyzer.mqh"

#include "../Indicators/TrendStrength.mqh"
#include "../Indicators/RSI.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/VolatilityFilter.mqh"



//==================================================
// INIT
//==================================================

void DashboardInit()
{

   Comment(
      "XAU_AI_PRO iniciado..."
   );

}



//==================================================
// UPDATE
//==================================================

void DashboardUpdate()
{

   double balance =
      AccountInfoDouble(
         ACCOUNT_BALANCE
      );


   double equity =
      AccountInfoDouble(
         ACCOUNT_EQUITY
      );



   int signal =
      GetSignal();



   string signalText="WAIT";


   if(signal==1)
      signalText="BUY";


   if(signal==-1)
      signalText="SELL";



   string positionText =
      HasOpenPosition()
      ?
      "SIM"
      :
      "NAO";



   double atr =
      GetATR();



   double adx =
      GetADX();



   double rsi =
      GetRSI();



   Comment(

      "========== XAU_AI_PRO ==========",

      "\nSymbol: ",
      _Symbol,


      "\nBalance: ",
      DoubleToString(balance,2),


      "\nEquity: ",
      DoubleToString(equity,2),


      "\nSignal: ",
      signalText,


      "\nPosition: ",
      positionText,


      "\nATR: ",
      DoubleToString(atr,2),


      "\nADX: ",
      DoubleToString(adx,2),


      "\nRSI: ",
      DoubleToString(rsi,2),


      "\nTrades: ",
      PerformanceTrades(),


      "\nWinRate: ",
      DoubleToString(
         PerformanceWinRate(),
         2
      )

   );

}



//==================================================
// DESTROY
//==================================================

void DashboardDestroy()
{

   Comment("");

}


#endif