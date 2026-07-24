#include <Indicators.mqh>
#ifndef __DASHBOARD_MQH__
#define __DASHBOARD_MQH__

void Dashboard()
{
   string texto;

   texto =
      "========== XAU_PRO V2 ==========\n";

   texto += "Símbolo: " + _Symbol + "\n";

   texto += "Preço: " +
      DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits) + "\n";

   texto += "EMA Fast: " +
      DoubleToString(emaFast[0],2) + "\n";

   texto += "EMA Slow: " +
      DoubleToString(emaSlow[0],2) + "\n";

   texto += "RSI: " +
      DoubleToString(rsi[0],2) + "\n";

   texto += "ATR: " +
      DoubleToString(atr[0],2) + "\n";

   texto += "Spread: " +
      IntegerToString((int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)) + "\n";

   texto += "Equity: " +
      DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2);

   Comment(texto);
}

#endif