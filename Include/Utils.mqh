#include <Config.mqh>
#ifndef __UTILS_MQH__
#define __UTILS_MQH__

//==================================
// VERIFICA SPREAD
//==================================
bool SpreadOK()
{
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(spread > MaxSpread)
      return(false);

   return(true);
}

//==================================
// NOVA BARRA
//==================================
bool NewBar()
{
   static datetime lastBar = 0;

   datetime currentBar = iTime(_Symbol, _Period, 0);

   if(currentBar != lastBar)
   {
      lastBar = currentBar;
      return(true);
   }

   return(false);
}

#endif