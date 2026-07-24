#ifndef RISKENGINE_MQH
#define RISKENGINE_MQH


//==================================================
// RISK ENGINE
// MULTI ASSET
//==================================================



//==================================================
// CALCULA LOTE PADRÃO
//==================================================

double CalculateLotByRisk(
   double riskPercent,
   int stopPoints
)
{

   return CalculateLotByRisk(
      _Symbol,
      riskPercent,
      stopPoints
   );

}



//==================================================
// CALCULA LOTE POR SÍMBOLO
//==================================================

double CalculateLotByRisk(
   string symbol,
   double riskPercent,
   int stopPoints
)
{


   if(symbol=="")
      return 0.01;



   double balance =
      AccountInfoDouble(
         ACCOUNT_BALANCE
      );



   double riskMoney =
      balance *
      riskPercent /
      100.0;



   double tickValue =
      SymbolInfoDouble(
         symbol,
         SYMBOL_TRADE_TICK_VALUE
      );



   double tickSize =
      SymbolInfoDouble(
         symbol,
         SYMBOL_TRADE_TICK_SIZE
      );



   if(
      tickValue<=0 ||
      tickSize<=0
   )
      return 0.01;



   double point =
      SymbolInfoDouble(
         symbol,
         SYMBOL_POINT
      );



   double lossPerLot =
      (
         stopPoints *
         point /
         tickSize
      )
      *
      tickValue;



   if(lossPerLot<=0)
      return 0.01;



   double lot =
      riskMoney /
      lossPerLot;



   double minLot =
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_MIN
      );


   double maxLot =
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_MAX
      );


   double step =
      SymbolInfoDouble(
         symbol,
         SYMBOL_VOLUME_STEP
      );



   lot =
      MathFloor(
         lot /
         step
      )
      *
      step;



   if(lot < minLot)
      lot=minLot;


   if(lot > maxLot)
      lot=maxLot;



   return NormalizeDouble(
      lot,
      2
   );

}



#endif