#ifndef EXECUTIONENGINE_MQH
#define EXECUTIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/OrderManager.mqh"
#include "../Core/RiskEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../Core/TradeController.mqh"

//==================================================
// EXECUTION ENGINE
//==================================================

bool ExecuteTrade(string symbol,int signal)
{
   if(symbol=="")
      return false;

   if(signal==0)
      return false;

   if(!CanTrade(symbol))
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
   {
      Print("EXECUTION: LOTE INVÁLIDO");
      return false;
   }

   bool result=false;

   switch(signal)
   {
      case 1:
      {
         result=
            OpenBuy(
               symbol,
               lot
            );
         break;
      }

      case -1:
      {
         result=
            OpenSell(
               symbol,
               lot
            );
         break;
      }

      default:
         return false;
   }

   if(result)
   {
      RegisterTrade();

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
         "ERRO EXECUÇÃO | ",
         symbol,
         " | ERROR=",
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
   return ExecuteTrade(
      _Symbol,
      signal
   );
}

#endif