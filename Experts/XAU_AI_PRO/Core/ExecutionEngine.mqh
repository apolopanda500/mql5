#ifndef EXECUTIONENGINE_MQH
#define EXECUTIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/OrderManager.mqh"
#include "../Core/RiskEngine.mqh"
#include "../Core/PositionManager.mqh"

//==================================================
// EXECUTION ENGINE
//==================================================

bool ExecuteTrade(string symbol,int signal)
{
   if(symbol=="")
      return false;

   if(signal==0)
      return false;

   if(!CanOpenPosition(symbol))
      return false;

   double lot=
      CalculateLotByRisk(
         symbol,
         RiskPercent,
         StopLossPoints
      );

   if(lot<=0)
      return false;

   bool result=false;

   if(signal==1)
      result=OpenBuy(symbol,lot);

   if(signal==-1)
      result=OpenSell(symbol,lot);

   if(result)
   {
      Print(
         "TRADE EXECUTADO | ",
         symbol,
         " | SIGNAL=",
         signal,
         " | LOT=",
         DoubleToString(lot,2)
      );
   }
   else
   {
      Print(
         "ERRO EXECUÇÃO ",
         symbol,
         " | ",
         GetLastError()
      );
   }

   return result;
}

//==================================================
// COMPATIBILIDADE
//==================================================

bool ExecuteTrade(int signal)
{
   return ExecuteTrade(_Symbol,signal);
}

#endif