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

   if(signal == 0)
      return false;



   double lot =
      CalculateLotByRisk(
         RiskPercent,
         StopLossPoints
      );



   if(signal == 1)
   {

      return OpenBuy(
         lot
      );

   }



   if(signal == -1)
   {

      return OpenSell(
         lot
      );

   }



   return false;

}


#endif