#ifndef TRADEPIPELINE_MQH
#define TRADEPIPELINE_MQH

#include "../Core/SymbolManager.mqh"
#include "../Core/MarketScanner.mqh"

//==================================================
// TRADE PIPELINE
//==================================================

void RunTradePipeline()
{
   int total=TotalSymbols();

   if(total<=0)
      return;

   for(int i=0;i<total;i++)
   {
      string symbol=GetTradeSymbol(i);

      if(symbol=="")
         continue;

      ProcessSymbol(symbol);
   }
}

#endif