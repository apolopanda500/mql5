#ifndef ORDERMANAGER_MQH
#define ORDERMANAGER_MQH

#include <Trade/Trade.mqh>
#include "../Core/Config.mqh"


//==================================================
// INIT
//==================================================

void InitOrderManager()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
}

//==================================================
// OPEN BUY
//==================================================

bool OpenBuy(double lot)
{
   if(lot<=0)
      return false;

   return trade.Buy(lot,_Symbol);
}

//==================================================
// OPEN SELL
//==================================================

bool OpenSell(double lot)
{
   if(lot<=0)
      return false;

   return trade.Sell(lot,_Symbol);
}

#endif