#include <Strategy.mqh>
#ifndef __TRADEMANAGER_MQH__
#define __TRADEMANAGER_MQH__

#include <Trade/Trade.mqh>

extern CTrade trade;

//====================================
// EXISTE POSIÇÃO?
//====================================
bool ExistePosicao()
{
   return PositionSelect(_Symbol);
}

//====================================
// ABRIR COMPRA
//====================================
bool BuyPosition()
{
   if(ExistePosicao())
      return false;

   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   double sl = NormalizeDouble(
      ask - StopLoss * _Point,
      _Digits
   );

   double tp = NormalizeDouble(
      ask + TakeProfit * _Point,
      _Digits
   );

   return trade.Buy(
      Lote,
      _Symbol,
      ask,
      sl,
      tp,
      "XAU_Pro BUY"
   );
}

//====================================
// ABRIR VENDA
//====================================
bool SellPosition()
{
   if(ExistePosicao())
      return false;

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double sl = NormalizeDouble(
      bid + StopLoss * _Point,
      _Digits
   );

   double tp = NormalizeDouble(
      bid - TakeProfit * _Point,
      _Digits
   );

   return trade.Sell(
      Lote,
      _Symbol,
      bid,
      sl,
      tp,
      "XAU_Pro SELL"
   );
}

#endif