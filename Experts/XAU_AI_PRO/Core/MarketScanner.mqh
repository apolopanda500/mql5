#ifndef MARKETSCANNER_MQH
#define MARKETSCANNER_MQH

#include "../Core/SignalCore.mqh"
#include "../Core/ValidationEngine.mqh"
#include "../Core/ExecutionEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../AI/AIEngine.mqh"

//==================================================
// PROCESS SYMBOL
// Usa GetCombinedSignal (técnico + IA) em vez de apenas GetSignal
//==================================================

void ProcessSymbol(string symbol)
{
   if(symbol=="")
      return;

   if(!SymbolSelect(symbol,true))
      return;

   if(!CanOpenPosition(symbol))
      return;

   // Sinal combinado: técnico + IA
   int signal=GetCombinedSignal(symbol);

   if(signal==0)
      return;

    if(!ValidateTrade(symbol,signal))
      return;

   if(!ExecuteTrade(symbol,signal))
      return;

   Print(
      "MARKET SCANNER | ",
      symbol,
      " | SIGNAL=",
      signal,
      " | AI Score=",
      DoubleToString(AI_Score, 2)
   );
}

#endif
