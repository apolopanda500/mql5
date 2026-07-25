#ifndef EXECUTIONENGINE_MQH
#define EXECUTIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/OrderManager.mqh"
#include "../Core/RiskEngine.mqh"

//==================================================
// EXECUTION ENGINE
//==================================================

bool ExecuteTrade(int signal)
{
   if(signal==0)
      return false;

   if(PositionSelect(_Symbol))
      return false;

   double lot=CalculateLotByRisk(
      RiskPercent,
      StopLossPoints
   );

   if(lot<=0)
      return false;

   bool result=false;

   switch(signal)
   {
      case 1:
         result=OpenBuy(lot);
         break;

      case -1:
         result=OpenSell(lot);
         break;
   }

   if(result)
   {
      Print(
         "TRADE EXECUTADO | ",
         _Symbol,
         " | SIGNAL=",
         signal,
         " | LOT=",
         DoubleToString(lot,2)
      );
   }
   else
   {
      Print(
         "ERRO EXECUÇÃO: ",
         GetLastError()
      );
   }

   return result;
}

#endif