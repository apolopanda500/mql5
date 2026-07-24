#ifndef BREAKEVEN_MQH
#define BREAKEVEN_MQH


#include "../Core/Config.mqh"

#include <Trade/Trade.mqh>


extern CTrade trade;


//==================================================
// BREAK EVEN
//==================================================


void CheckBreakEven()
{

   if(!EnableBreakEven)
      return;



   for(int i=PositionsTotal()-1;i>=0;i--)
   {


      ulong ticket =
         PositionGetTicket(i);


      if(ticket==0)
         continue;



      string symbol =
         PositionGetString(
            POSITION_SYMBOL
         );



      long type =
         PositionGetInteger(
            POSITION_TYPE
         );



      double openPrice =
         PositionGetDouble(
            POSITION_PRICE_OPEN
         );



      double currentPrice = 0;



      if(type==POSITION_TYPE_BUY)
      {
         currentPrice =
            SymbolInfoDouble(
               symbol,
               SYMBOL_BID
            );
      }


      if(type==POSITION_TYPE_SELL)
      {
         currentPrice =
            SymbolInfoDouble(
               symbol,
               SYMBOL_ASK
            );
      }



      double point =
         SymbolInfoDouble(
            symbol,
            SYMBOL_POINT
         );



      double profitPoints =
         MathAbs(
            currentPrice-openPrice
         )
         /
         point;



      if(profitPoints < BreakEvenTrigger)
         continue;



      double newSL;



      if(type==POSITION_TYPE_BUY)
      {

         newSL =
            openPrice +
            BreakEvenOffset *
            point;

      }
      else
      {

         newSL =
            openPrice -
            BreakEvenOffset *
            point;

      }



      trade.PositionModify(
         symbol,
         newSL,
         PositionGetDouble(
            POSITION_TP
         )
      );

   }

}



#endif