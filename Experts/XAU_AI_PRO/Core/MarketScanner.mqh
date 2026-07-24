#ifndef MARKETSCANNER_MQH
#define MARKETSCANNER_MQH

#include "../Core/DecisionEngine.mqh"
#include "../Core/ExecutionEngine.mqh"


//==================================================
// PROCESS SYMBOL
//==================================================

void ProcessSymbol(string symbol)
{

   if(symbol=="")
      return;


   if(!SymbolSelect(symbol,true))
      return;


   int signal = GetDecision();


   if(signal==0)
      return;


   ExecuteTrade(signal);

}


#endif