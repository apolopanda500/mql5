#ifndef TRENDFILTER_MQH
#define TRENDFILTER_MQH


//==================================================
// TREND FILTER PRO
// EMA 200 HIGHER TIMEFRAME
//==================================================


#define TREND_EMA_PERIOD 200


input ENUM_TIMEFRAMES TrendTF = PERIOD_H1;


//==================================================
// HANDLE
//==================================================

int trendEMAHandle = INVALID_HANDLE;

double trendEMABuffer[];


//==================================================
// INIT
//==================================================

bool InitTrendFilter()
{

   trendEMAHandle =
      iMA(
         _Symbol,
         TrendTF,
         TREND_EMA_PERIOD,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   if(trendEMAHandle == INVALID_HANDLE)
   {
      Print("Erro criando Trend EMA");
      return false;
   }


   ArraySetAsSeries(
      trendEMABuffer,
      true
   );


   return true;

}



//==================================================
// GET EMA
//==================================================

bool GetTrendEMA(double &value)
{

   if(trendEMAHandle == INVALID_HANDLE)
      return false;


   if(
      CopyBuffer(
         trendEMAHandle,
         0,
         0,
         3,
         trendEMABuffer
      ) <= 0
   )
      return false;



   value =
      trendEMABuffer[0];


   return true;

}



//==================================================
// PRICE POSITION
//==================================================

bool PriceAboveTrendEMA()
{

   double ema;


   if(!GetTrendEMA(ema))
      return false;


   double price =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );


   return(
      price > ema
   );

}



bool PriceBelowTrendEMA()
{

   double ema;


   if(!GetTrendEMA(ema))
      return false;


   double price =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );


   return(
      price < ema
   );

}



//==================================================
// TREND BUY
//==================================================

bool TrendBuy()
{

   return PriceAboveTrendEMA();

}



//==================================================
// TREND SELL
//==================================================

bool TrendSell()
{

   return PriceBelowTrendEMA();

}



//==================================================
// TREND SIGNAL
//==================================================

int GetTrendSignal()
{

   if(TrendBuy())
      return 1;


   if(TrendSell())
      return -1;


   return 0;

}



//==================================================
// TREND DISTANCE
//==================================================

double GetTrendDistance()
{

   double ema;


   if(!GetTrendEMA(ema))
      return 0;


   double price =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );


   return NormalizeDouble(
      MathAbs(price-ema)
      /
      _Point,
      2
   );

}



//==================================================
// RELEASE
//==================================================

void ReleaseTrendFilter()
{

   if(trendEMAHandle != INVALID_HANDLE)
   {

      IndicatorRelease(
         trendEMAHandle
      );


      trendEMAHandle = INVALID_HANDLE;

   }

}



#endif