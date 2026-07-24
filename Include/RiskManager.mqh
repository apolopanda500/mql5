#include <Trade/Trade.mqh>
extern CTrade trade;
#ifndef __RISKMANAGER_MQH__
#define __RISKMANAGER_MQH__

//==============================
// BREAK EVEN
//==============================
void BreakEven()
{
   if(!PositionSelect(_Symbol))
      return;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl        = PositionGetDouble(POSITION_SL);
   double tp        = PositionGetDouble(POSITION_TP);

   ENUM_POSITION_TYPE type =
      (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   if(type==POSITION_TYPE_BUY)
   {
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

      if(bid-openPrice>150*_Point && sl<openPrice)
      {
         trade.PositionModify(_Symbol,openPrice,tp);
      }
   }

   if(type==POSITION_TYPE_SELL)
   {
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

      if(openPrice-ask>150*_Point && sl>openPrice)
      {
         trade.PositionModify(_Symbol,openPrice,tp);
      }
   }
}

//==============================
// TRAILING STOP
//==============================
void TrailingStop()
{
   if(!PositionSelect(_Symbol))
      return;

   double sl=PositionGetDouble(POSITION_SL);
   double tp=PositionGetDouble(POSITION_TP);

   ENUM_POSITION_TYPE type=
      (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   if(type==POSITION_TYPE_BUY)
   {
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

      double novoSL=bid-200*_Point;

      if(novoSL>sl)
      {
         trade.PositionModify(_Symbol,novoSL,tp);
      }
   }

   if(type==POSITION_TYPE_SELL)
   {
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

      double novoSL=ask+200*_Point;

      if(sl==0 || novoSL<sl)
      {
         trade.PositionModify(_Symbol,novoSL,tp);
      }
   }
}

#endif