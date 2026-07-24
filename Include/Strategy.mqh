#ifndef __STRATEGY_MQH__
#define __STRATEGY_MQH__

#include <Indicators.mqh>

//==============================
// TENDÊNCIA DE ALTA
//==============================
bool TrendBuy()
{
   return (emaFast[0] > emaSlow[0]);
}

//==============================
// TENDÊNCIA DE BAIXA
//==============================
bool TrendSell()
{
   return (emaFast[0] < emaSlow[0]);
}

//==============================
// SINAL DE COMPRA
//==============================
bool BuySignal()
{
   if(!TrendBuy())
      return false;

   if(rsi[0] > 55)   // evita sobrecompra
      return false;

   return true;
}

//==============================
// SINAL DE VENDA
//==============================
bool SellSignal()
{
   if(!TrendSell())
      return false;

   if(rsi[0] < 45)   // evita sobrevenda
      return false;

   return true;
}

#endif