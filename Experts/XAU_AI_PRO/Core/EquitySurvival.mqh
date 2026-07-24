#ifndef EQUITYSURVIVAL_MQH
#define EQUITYSURVIVAL_MQH


#include "Config.mqh"

//==================================================
// EQUITY SURVIVAL ENGINE
// PROTEÇÃO DE CAPITAL
//==================================================


//==================================================
// ESTADO
//==================================================

bool survivalMode = false;



//==================================================
// CHECK EQUITY
//==================================================

bool EquitySurvivalCheck()
{

   double balance =
      AccountInfoDouble(ACCOUNT_BALANCE);


   double equity =
      AccountInfoDouble(ACCOUNT_EQUITY);



   if(balance <= 0)
      return false;



   double dd =
      ((balance - equity) / balance) * 100.0;



   double warningLevel =
      MaxDrawdownPercent * 0.8;



   //================================================
   // MODO SOBREVIVÊNCIA
   //================================================

   if(dd >= warningLevel)
   {

      survivalMode = true;


      Print(
         "🚨 EQUITY SURVIVAL MODE | DD: ",
         DoubleToString(dd,2),
         "%"
      );


      return false;

   }



   survivalMode = false;


   return true;

}



//==================================================
// STATUS
//==================================================

bool IsSurvivalMode()
{
   return survivalMode;
}



//==================================================
// DEBUG
//==================================================

void PrintEquitySurvival()
{

   double balance =
      AccountInfoDouble(ACCOUNT_BALANCE);


   double equity =
      AccountInfoDouble(ACCOUNT_EQUITY);



   double dd = 0;


   if(balance > 0)
      dd =
      ((balance-equity)/balance)*100;



   Print("==============================");
   Print("EQUITY SURVIVAL");
   Print("Balance : ",DoubleToString(balance,2));
   Print("Equity  : ",DoubleToString(equity,2));
   Print("DD      : ",DoubleToString(dd,2),"%");
   Print("Status  : ",
         survivalMode ? "BLOCK" : "OK");
   Print("==============================");

}



#endif
