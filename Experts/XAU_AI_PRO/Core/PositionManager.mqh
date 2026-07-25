#ifndef POSITIONMANAGER_MQH
#define POSITIONMANAGER_MQH

#include "../Core/Config.mqh"
#include <Trade/Trade.mqh>

extern CTrade trade;

//==================================================
// EXISTE POSIÇÃO DO EA
//==================================================

bool HasPosition(string symbol)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);

      if(ticket==0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL)!=symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber)
         continue;

      return true;
   }

   return false;
}

//==================================================
// POSIÇÃO NO SÍMBOLO ATUAL
//==================================================

bool HasOpenPosition()
{
   return HasPosition(_Symbol);
}

//==================================================
// CONTAR POSIÇÕES DO EA
//==================================================

int CountPositions()
{
   int total=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);

      if(ticket==0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber)
         continue;

      total++;
   }

   return total;
}

//==================================================
// PODE ABRIR
//==================================================

bool CanOpenPosition(string symbol)
{
   if(HasPosition(symbol))
      return false;

   if(CountPositions()>=MaxOpenPositions)
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

   if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber)
      return 0;

   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

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

   if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber)
      return false;

   return trade.PositionClose(symbol);
}

//==================================================
// GERENCIAR
//==================================================

void ManagePositions()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);

      if(ticket==0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber)
         continue;

      // BreakEven();
      // TrailingStop();
      // PartialClose();
   }
}

#endif