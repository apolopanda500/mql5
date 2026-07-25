#ifndef ORDERMANAGER_MQH
#define ORDERMANAGER_MQH

#include <Trade/Trade.mqh>
#include "../Core/Config.mqh"

extern CTrade trade;

//==================================================
// INIT
//==================================================

void InitOrderManager()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
}

//==================================================
// BUY
//==================================================

bool OpenBuy(
   string symbol,
   double lot
)
{
   if(symbol=="")
      return false;

   if(lot<=0)
      return false;

   return trade.Buy(
      lot,
      symbol
   );
}

//==================================================
// SELL
//==================================================

bool OpenSell(
   string symbol,
   double lot
)
{
   if(symbol=="")
      return false;

   if(lot<=0)
      return false;

   return trade.Sell(
      lot,
      symbol
   );
}

#endif