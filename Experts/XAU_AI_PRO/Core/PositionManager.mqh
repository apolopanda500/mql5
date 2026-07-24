#ifndef POSITIONMANAGER_MQH
#define POSITIONMANAGER_MQH

#include "../Core/Config.mqh"

#include <Trade/Trade.mqh>

extern CTrade trade;


//==================================================
// POSITION MANAGER
//==================================================


//==================================================
// VERIFICA POSIÇÃO
//==================================================

bool HasPosition(string symbol)
{

   for(int i=PositionsTotal()-1;i>=0;i--)
   {

      ulong ticket =
         PositionGetTicket(i);


      if(ticket==0)
         continue;


      string posSymbol =
         PositionGetString(
            POSITION_SYMBOL
         );


      if(posSymbol==symbol)
         return true;

   }


   return false;

}



//==================================================
// POSIÇÃO ATUAL DO EA
//==================================================

bool HasOpenPosition()
{

   return HasPosition(_Symbol);

}



//==================================================
// CONTAR POSIÇÕES
//==================================================

int CountPositions()
{

   int total=0;


   for(int i=PositionsTotal()-1;i>=0;i--)
   {

      ulong ticket =
         PositionGetTicket(i);


      if(ticket>0)
         total++;

   }


   return total;

}



//==================================================
// PERMITE ABRIR
//==================================================

bool CanOpenPosition(string symbol)
{

   if(HasPosition(symbol))
      return false;


   if(
      CountPositions()
      >=
      MaxOpenPositions
   )
      return false;


   return true;

}



//==================================================
// DIREÇÃO
//==================================================

int GetPositionDirection(string symbol)
{

   if(!PositionSelect(symbol))
      return 0;



   long type =
      PositionGetInteger(
         POSITION_TYPE
      );


   if(type==POSITION_TYPE_BUY)
      return 1;


   if(type==POSITION_TYPE_SELL)
      return -1;


   return 0;

}



//==================================================
// FECHAR POSIÇÃO
//==================================================

bool CloseSymbolPosition(string symbol)
{

   if(!PositionSelect(symbol))
      return false;



   CTrade closeTrade;


   closeTrade.SetExpertMagicNumber(
      MagicNumber
   );


   return
      closeTrade.PositionClose(
         symbol
      );

}



//==================================================
// GERENCIAMENTO
//==================================================

void ManagePositions()
{

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


      if(symbol=="")
         continue;


      // futuro:
      // trailing stop
      // break even
      // parcial

   }

}



#endif