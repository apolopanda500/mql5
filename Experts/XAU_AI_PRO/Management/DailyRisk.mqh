#ifndef DAILYRISK_MQH
#define DAILYRISK_MQH

#include "../Core/Config.mqh"

//==================================================
// DAILY RISK ENGINE
//==================================================


int dailyTrades = 0;
int lastDayKey = -1;

double dailyStartBalance = 0.0;
bool dailyBlocked = false;



//==================================================
// DAY KEY
//==================================================

int GetDayKey()
{

   MqlDateTime dt;

   TimeToStruct(
      TimeCurrent(),
      dt
   );


   return(
      dt.year * 1000 +
      dt.day_of_year
   );

}



//==================================================
// INIT
//==================================================

void InitDailyRisk()
{

   dailyStartBalance =
      AccountInfoDouble(
         ACCOUNT_BALANCE
      );


   ResetDaily();

}



//==================================================
// RESET
//==================================================

void ResetDaily()
{

   int day =
      GetDayKey();


   if(day != lastDayKey)
   {

      dailyTrades = 0;

      dailyBlocked = false;


      dailyStartBalance =
         AccountInfoDouble(
            ACCOUNT_BALANCE
         );


      lastDayKey = day;

   }

}



//==================================================
// REGISTER
//==================================================

void RegisterDailyTrade()
{

   ResetDaily();

   dailyTrades++;

}



//==================================================
// DAILY LOSS CALCULATION
//==================================================

double GetDailyLossPercentDaily()
{

   if(dailyStartBalance <= 0)
      return 0.0;



   double balance =
      AccountInfoDouble(
         ACCOUNT_BALANCE
      );



   double loss =
      (
       dailyStartBalance -
       balance
      )
      /
      dailyStartBalance
      *
      100.0;



   return NormalizeDouble(
      loss,
      2
   );

}



//==================================================
// DAILY LOSS CHECK
//==================================================

bool CheckDailyLossDaily()
{

   double loss =
      GetDailyLossPercentDaily();



   if(loss >= MaxDailyLossPercent)
   {

      dailyBlocked = true;


      Print(
         "Daily Loss bloqueado: ",
         loss,
         "%"
      );


      return false;

   }


   return true;

}



//==================================================
// ALLOW TRADE TODAY
//==================================================

bool CanTradeToday()
{

   ResetDaily();



   if(dailyBlocked)
      return false;



   if(!CheckDailyLossDaily())
      return false;



   if(dailyTrades >= MaxTradesPerDay)
      return false;



   return true;

}



//==================================================
// DEBUG
//==================================================

void PrintDailyRisk()
{

   Print(
      "Trades hoje: ",
      dailyTrades,
      " | Loss diário: ",
      GetDailyLossPercentDaily(),
      "%"
   );

}



#endif
