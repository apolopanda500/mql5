// XAU_AI_PRO v1.2.0
#ifndef BREAKEVEN_MQH
#define BREAKEVEN_MQH

#include "../Core/Config.mqh"
#include "../Indicators/VolatilityFilter.mqh"
#include <Trade/Trade.mqh>

extern CTrade trade;

// Retorna o stop level do broker em pontos (fallback: BreakEvenOffset)
// MEDIDO 08/10/2026: com SL/TP em DOLARES, `BreakEvenOffset` em PONTOS parou de
// ter relacao com o risco — 10 pontos e US$ 0,10 no GOLD/EURUSD e US$ 0,001 no
// BTCUSD. Agora o offset e derivado do valor em dollar quando existe.
double GetBreakEvenOffsetPoints(string symbol, double volume)
{
   if(BreakEvenOffsetUsd > 0.0)
   {
      double pontos = DistanciaPontosParaRiscoUSD(symbol, volume, BreakEvenOffsetUsd);

      if(pontos > 0.0)
         return(pontos);
   }

   long level = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);

   if(level > 0)
      return((double)level);

   return((double)BreakEvenOffset);
}

void CheckBreakEven()
{
if(!EnableBreakEven)
return;

for(int i = PositionsTotal() - 1; i >= 0; i--)
{
ulong ticket = PositionGetTicket(i);


  if(ticket == 0)
     continue;

  if(!PositionSelectByTicket(ticket))
     continue;

  if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
     continue;

  string symbol = PositionGetString(POSITION_SYMBOL);
  long type = PositionGetInteger(POSITION_TYPE);

  double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double currentSL = PositionGetDouble(POSITION_SL);
  double currentTP = PositionGetDouble(POSITION_TP);

  double currentPrice = 0.0;

  if(type == POSITION_TYPE_BUY)
     currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
  else if(type == POSITION_TYPE_SELL)
     currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
  else
     continue;

  if(currentPrice <= 0.0)
     continue;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

  if(point <= 0.0)
     point = _Point;

double atr = GetATR(symbol);
   double triggerPoints = 0.0;

   // Gatilho em DINHEIRO (decisao do dono, 08/10/2026). `POSITION_PROFIT` ja
   // e a moeda da conta: comparar lucro com ponto era comparar dinheiro com
   // distancia, e o resultado dependia do simbolo.
   double volume = PositionGetDouble(POSITION_VOLUME);

   if(BreakEvenTriggerUsd > 0.0)
   {
      triggerPoints = DistanciaPontosParaRiscoUSD(symbol, volume, BreakEvenTriggerUsd);

      // ATR pode dar um gatilho MENOR que o pedido em dinheiro; o dono pediu
      // um minimo, entao o maior dos dois manda.
      if(atr > 0.0)
         triggerPoints = MathMax(triggerPoints, atr / point);
   }
   else if(atr > 0.0)
   {
      triggerPoints = MathMax(BreakEvenTrigger, atr / point);
   }
   else
   {
      triggerPoints = BreakEvenTrigger;
   }

   // v1.2.0 fix: trigger deve ser MAIOR que o offset (SL valido)
   double offsetPoints = GetBreakEvenOffsetPoints(symbol, volume);
   if(offsetPoints >= triggerPoints)
      triggerPoints = offsetPoints + 1.0;

  if(triggerPoints <= 0.0)
     continue;

  double profitPoints = 0.0;

  if(type == POSITION_TYPE_BUY)
     profitPoints = (currentPrice - openPrice) / point;
  else
     profitPoints = (openPrice - currentPrice) / point;

  if(profitPoints < triggerPoints)
     continue;

double newSL = 0.0;

   // `offsetPoints` ja foi calculado acima com o volume desta posicao.
   if(type == POSITION_TYPE_BUY)
   {
      newSL = openPrice + offsetPoints * point;

      if(currentSL > 0.0 && newSL <= currentSL)
         continue;
   }
   else
   {
      newSL = openPrice - offsetPoints * point;

      if(currentSL > 0.0 && newSL >= currentSL)
         continue;
   }

  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  newSL = NormalizeDouble(newSL, digits);

  ResetLastError();

  if(!trade.PositionModify(symbol, newSL, currentTP))
  {
     PrintFormat(
        "[BREAK EVEN] Falha #%I64u | %s | SL %.5f | Erro %d",
        ticket,
        symbol,
        newSL,
        GetLastError()
     );
  }
  else
  {
     PrintFormat(
        "[BREAK EVEN] Ativado #%I64u | %s | SL %.5f | Trigger %.1f",
        ticket,
        symbol,
        newSL,
        triggerPoints
     );
  }


}
}

#endif
