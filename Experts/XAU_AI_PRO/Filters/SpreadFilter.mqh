#ifndef SPREADFILTER_MQH
#define SPREADFILTER_MQH


#include "../Core/Config.mqh"


//==================================================
// SPREAD FILTER
//==================================================


//==================================================
// CHECK SPREAD
//==================================================

bool GoodSpread()
{

   double ask =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );


   double bid =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );



   if(
      ask <= 0 ||
      bid <= 0
   )
      return false;



   double spread =
      (ask - bid)
      /
      _Point;



   if(spread > MaxSpread)
   {
      Print(
         "SPREAD BLOCKED: ",
         DoubleToString(spread,1),
         " max: ",
         DoubleToString(MaxSpread,1)
      );

      return false;
   }



   return true;

}



//==================================================
// GET CURRENT SPREAD
//==================================================

double GetCurrentSpread()
{

   double ask =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );


   double bid =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );



   if(ask <= 0 || bid <= 0)
      return 999;



   return(
      (ask-bid)
      /
      _Point
   );

}



//==================================================
// COMPATIBILITY
//==================================================

bool SpreadOK()
{
   return GoodSpread();
}



//==================================================
// DEBUG
//==================================================

void PrintSpreadStatus()
{

   Print(
      "CURRENT SPREAD: ",
      DoubleToString(
         GetCurrentSpread(),
         1
      )
   );

}



#endif
