#ifndef SESSIONFILTER_MQH
#define SESSIONFILTER_MQH


#include "../Core/Config.mqh"

//==================================================
// SESSION FILTER
//==================================================


//==================================================
// SESSION CHECK
//==================================================

bool IsTradingSession()
{

   if(!EnableSessionFilter)
      return true;


   MqlDateTime tm;

   TimeToStruct(
      TimeCurrent(),
      tm
   );


   if(tm.hour >= TradeStartHour &&
      tm.hour < TradeEndHour)
   {
      return true;
   }


   return false;

}



//==================================================
// LEGACY COMPATIBILITY
//==================================================

bool IsMarketSession()
{
   return IsTradingSession();
}



//==================================================
// DEBUG
//==================================================

void PrintSessionStatus()
{

   Print(
      "SESSION FILTER: ",
      IsTradingSession()
      ?
      "OPEN"
      :
      "CLOSED"
   );

}



#endif