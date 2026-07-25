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

bool OpenBuy(string symbol,double lot)
{
   if(symbol=="")
      return false;

   if(lot<=0)
      return false;

   double ask=
      SymbolInfoDouble(symbol,SYMBOL_ASK);

   double sl=0;
   double tp=0;

   if(StopLossPoints>0)
      sl=NormalizeDouble(
         ask-(StopLossPoints*_Point),
         (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS)
      );

   if(TakeProfitPoints>0)
      tp=NormalizeDouble(
         ask+(TakeProfitPoints*_Point),
         (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS)
      );

   bool result=
      trade.Buy(
         lot,
         symbol,
         ask,
         sl,
         tp,
         "XAU_AI_PRO BUY"
      );

   if(!result)
   {
      Print(
         "BUY ERROR ",
         symbol,
         " | ",
         trade.ResultRetcode(),
         " | ",
         trade.ResultRetcodeDescription()
      );
   }

   return result;
}

//==================================================
// SELL
//==================================================

bool OpenSell(string symbol,double lot)
{
   if(symbol=="")
      return false;

   if(lot<=0)
      return false;

   double bid=
      SymbolInfoDouble(symbol,SYMBOL_BID);

   double sl=0;
   double tp=0;

   if(StopLossPoints>0)
      sl=NormalizeDouble(
         bid+(StopLossPoints*_Point),
         (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS)
      );

   if(TakeProfitPoints>0)
      tp=NormalizeDouble(
         bid-(TakeProfitPoints*_Point),
         (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS)
      );

   bool result=
      trade.Sell(
         lot,
         symbol,
         bid,
         sl,
         tp,
         "XAU_AI_PRO SELL"
      );

   if(!result)
   {
      Print(
         "SELL ERROR ",
         symbol,
         " | ",
         trade.ResultRetcode(),
         " | ",
         trade.ResultRetcodeDescription()
      );
   }

   return result;
}

//==================================================
// CLOSE POSITION
//==================================================

bool ClosePosition(string symbol)
{
   if(!PositionSelect(symbol))
      return false;

   return trade.PositionClose(symbol);
}

#endif