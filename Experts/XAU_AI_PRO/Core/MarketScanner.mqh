#ifndef MARKETSCANNER_MQH
#define MARKETSCANNER_MQH

#include "../Core/SignalCore.mqh"
#include "../Core/ValidationEngine.mqh"
#include "../Core/ExecutionEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../AI/AIEngine.mqh"

//==================================================
// PROCESS SYMBOL
//==================================================

void ProcessSymbol(string symbol)
{
   if(symbol=="")
   {
      Print(
         "[SCANNER] BLOCK | Empty symbol"
      );

      return;
   }


   Print(
      "[SCANNER] START | ",
      symbol
   );


   //================================================
   // POSITION LIMIT
   //================================================

   if(!CanOpenPosition(symbol))
   {
      Print(
         "[SCANNER] BLOCK | CanOpenPosition | ",
         symbol
      );

      return;
   }


   Print(
      "[SCANNER] POSITION CHECK OK | ",
      symbol
   );


   //================================================
   // SIGNAL
   //================================================

   int signal=
      GetCombinedSignal(
         symbol
      );


   if(signal==0)
   {
      Print(
         "[SCANNER] BLOCK | No Signal | ",
         symbol
      );

      return;
   }


   Print(
      "[SCANNER] SIGNAL OK | ",
      symbol,
      " | Signal=",
      signal
   );


   //================================================
   // VALIDATION
   //================================================

   if(
      !ValidateTrade(
         symbol,
         signal
      )
   )
   {
      Print(
         "[SCANNER] BLOCK | Validation | ",
         symbol,
         " | Signal=",
         signal
      );

      return;
   }


   Print(
      "[SCANNER] VALIDATION OK | ",
      symbol
   );


   //================================================
   // EXECUTION
   //================================================

   if(
      !ExecuteTrade(
         symbol,
         signal
      )
   )
   {
      Print(
         "[SCANNER] BLOCK | Execution Failed | ",
         symbol,
         " | Signal=",
         signal
      );

      return;
   }


   Print(
      "[SCANNER] TRADE SUCCESS | ",
      symbol,
      " | Signal=",
      signal
   );
}

#endif