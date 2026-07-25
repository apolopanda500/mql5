#ifndef RISKENGINE_MQH
#define RISKENGINE_MQH

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

   double riskMoney=
      balance*riskPercent/100.0;

   double tickValue=
      SymbolInfoDouble(
         symbol,
         SYMBOL_TRADE_TICK_VALUE
      );

   double tickSize=
      SymbolInfoDouble(
         symbol,
         SYMBOL_TRADE_TICK_SIZE
      );

   double point=
      SymbolInfoDouble(
         symbol,
         SYMBOL_POINT
      );

   if(tickValue<=0 || tickSize<=0 || point<=0)
      return 0.01;

   double lossPerLot=
      ((stopPoints*point)/tickSize)
      *tickValue;

   if(lossPerLot<=0)
      return 0.01;

   double lot=
      riskMoney/lossPerLot;

   double minLot=
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_MIN
      );

   double maxLot=
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_MAX
      );

   double step=
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_STEP
      );

   lot=MathMax(minLot,lot);
   lot=MathMin(maxLot,lot);

   lot=MathFloor(lot/step)*step;

   return NormalizeDouble(lot,2);
}

#endif