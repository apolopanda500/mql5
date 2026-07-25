#ifndef MARKETSCANNER_MQH
#define MARKETSCANNER_MQH

#include "../Core/SignalCore.mqh"
#include "../Core/ValidationEngine.mqh"
#include "../Core/ExecutionEngine.mqh"
#include "../Core/PositionManager.mqh"

//==================================================
// PROCESS SYMBOL
//==================================================

void ProcessSymbol(string symbol)
{
   if(symbol=="")
      return;

   if(!SymbolSelect(symbol,true))
      return;

   if(!CanOpenPosition(symbol))
      return;

   int signal=GetSignal(symbol);

   if(signal==0)
      return;

   if(!ValidateTrade(signal))
      return;

   if(!ExecuteTrade(signal))
      return;

   Print(
      "MARKET SCANNER | ",
      symbol,
      " | SIGNAL=",
      signal
   );
}

#endif