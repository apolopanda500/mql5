#ifndef EQUITYPROTECTION_MQH
#define EQUITYPROTECTION_MQH

//==================================================
// EQUITY PROTECTION (SAFE)
//==================================================
bool EquityProtection(double maxDrawdownPercent = 15.0)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   if(balance <= 0.0)
      return false;

   double drawdown = ((balance - equity) / balance) * 100.0;

   //==================================================
   // BLOQUEIO REAL
   //==================================================
   if(drawdown >= maxDrawdownPercent)
   {
      Print("🚨 EQUITY PROTECTION ATIVADO | DD: ",
            DoubleToString(drawdown, 2), "%");

      return false;
   }

   return true;
}

#endif