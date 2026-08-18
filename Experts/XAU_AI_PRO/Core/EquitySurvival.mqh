// XAU_AI_PRO v1.2.0
#ifndef EQUITYSURVIVAL_MQH
#define EQUITYSURVIVAL_MQH

#include "Config.mqh"
#include "../Management/EquityProtection.mqh"

//==================================================
// EQUITY SURVIVAL ENGINE - DELEGA PARA EQUITY PROTECTION
//==================================================

bool survivalMode = false;

bool EquitySurvivalCheck()
{
   survivalMode = !CheckEquityProtection();
   return !survivalMode;
}

bool IsSurvivalMode()
{
   return survivalMode;
}

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
