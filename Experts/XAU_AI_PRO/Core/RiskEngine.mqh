#ifndef RISKENGINE_MQH
#define RISKENGINE_MQH

#include "../Management/DailyRisk.mqh"

//==================================================
// RISK ENGINE
//==================================================

double CalculateLotByRisk(double riskPercent,int stopPoints)
{
   return CalculateLotByRisk(
      _Symbol,
      riskPercent,
      stopPoints
   );
}

double CalculateLotByRisk(
   string symbol,
   double riskPercent,
   int stopPoints
)
{
   if(symbol=="")
      return 0.01;

   if(stopPoints<=0)
      stopPoints=100;

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Proteção: equity muito baixa
   double minEquityRatio = MinEquityPercent / 100.0;
   if(equity < balance * minEquityRatio)
   {
      Print("RISK: Equity crítica (", DoubleToString(equity, 2),
            " < ", DoubleToString(balance * minEquityRatio, 2), "), bloqueando operações");
      return 0.01;
   }

   // Verificar stop loss diário
   if(!CheckDailyLossDaily())
   {
      Print("RISK: Limite de perda diária atingido");
      return 0.01;
   }
   
   // Calcular drawdown atual
   double drawdown=0;
   if(balance > 0)
      drawdown = ((balance - equity) / balance) * 100.0;
   
   // Ajustar risco baseado no drawdown
   double adjustedRisk = riskPercent;
   
   if(drawdown > 15.0)
   {
      Print("RISK: Drawdown crítico (", DoubleToString(drawdown, 2), "%), reduzindo risco para 25%");
      adjustedRisk = riskPercent * 0.25;  // Reduz 75%
   }
   else if(drawdown > 10.0)
   {
      Print("RISK: Drawdown alto (", DoubleToString(drawdown, 2), "%), reduzindo risco para 50%");
      adjustedRisk = riskPercent * 0.50;  // Reduz 50%
   }
   else if(drawdown > 5.0)
   {
      Print("RISK: Drawdown moderado (", DoubleToString(drawdown, 2), "%), reduzindo risco para 75%");
      adjustedRisk = riskPercent * 0.75;  // Reduz 25%
   }
   
   double riskMoney = equity * adjustedRisk / 100.0;
   
   double tickValue=SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double point=SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(tickValue<=0 || tickSize<=0 || point<=0)
      return 0.01;

   double lossPerLot=((stopPoints*point)/tickSize)*tickValue;

   if(lossPerLot<=0)
      return 0.01;

   double lot=riskMoney/lossPerLot;

   double minLot=SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   lot=MathMax(minLot,lot);
   lot=MathMin(maxLot,lot);

   lot=MathFloor(lot/step)*step;

   Print("RISK CALC | Balance=", DoubleToString(balance, 2), 
         " | Equity=", DoubleToString(equity, 2),
         " | DD=", DoubleToString(drawdown, 2), "%",
         " | Risk%=", DoubleToString(adjustedRisk, 2),
         " | Lot=", DoubleToString(lot, 2));

   return NormalizeDouble(lot,2);
}

#endif