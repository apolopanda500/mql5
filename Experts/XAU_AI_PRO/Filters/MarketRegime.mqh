#ifndef MARKETANALYZER_MQH
#define MARKETANALYZER_MQH


#include "../Indicators/VolatilityFilter.mqh"


//====================================================
// TREND ENUM
//====================================================

enum TrendDirection
{
   TREND_NONE = 0,
   TREND_BUY  = 1,
   TREND_SELL = -1
};


//====================================================
// INPUTS
//====================================================

input int MarketMAFastPeriod = 50;
input int MarketMASlowPeriod = 200;


//====================================================
// HANDLES
//====================================================

int maFastHandle = INVALID_HANDLE;
int maSlowHandle = INVALID_HANDLE;


//====================================================
// BUFFERS
//====================================================

double maFastBuffer[];
double maSlowBuffer[];


//====================================================
// INIT
//====================================================

bool InitMarketAnalyzer()
{

   maFastHandle =
      iMA(
         _Symbol,
         PERIOD_CURRENT,
         MarketMAFastPeriod,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   maSlowHandle =
      iMA(
         _Symbol,
         PERIOD_CURRENT,
         MarketMASlowPeriod,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   if(
      maFastHandle == INVALID_HANDLE ||
      maSlowHandle == INVALID_HANDLE
   )
   {
      Print("Erro ao criar MA Market Analyzer");
      return false;
   }



   ArraySetAsSeries(
      maFastBuffer,
      true
   );


   ArraySetAsSeries(
      maSlowBuffer,
      true
   );


   return true;
}


//====================================================
// RELEASE
//====================================================

void ReleaseMarketAnalyzer()
{

   if(maFastHandle != INVALID_HANDLE)
   {
      IndicatorRelease(maFastHandle);
      maFastHandle = INVALID_HANDLE;
   }


   if(maSlowHandle != INVALID_HANDLE)
   {
      IndicatorRelease(maSlowHandle);
      maSlowHandle = INVALID_HANDLE;
   }

}


//====================================================
// UPDATE MA
//====================================================

bool UpdateMA()
{

   if(
      maFastHandle == INVALID_HANDLE ||
      maSlowHandle == INVALID_HANDLE
   )
      return false;



   if(
      CopyBuffer(
         maFastHandle,
         0,
         0,
         3,
         maFastBuffer
      ) <= 0
   )
      return false;



   if(
      CopyBuffer(
         maSlowHandle,
         0,
         0,
         3,
         maSlowBuffer
      ) <= 0
   )
      return false;



   return true;

}


//====================================================
// TREND
//====================================================

TrendDirection GetTrendDirection()
{

   if(!UpdateMA())
      return TREND_NONE;



   double fast =
      maFastBuffer[0];


   double slow =
      maSlowBuffer[0];



   if(fast > slow)
      return TREND_BUY;



   if(fast < slow)
      return TREND_SELL;



   return TREND_NONE;

}


//====================================================
// HELPERS
//====================================================

bool IsBullishTrend()
{
   return(
      GetTrendDirection()
      ==
      TREND_BUY
   );
}



bool IsBearishTrend()
{
   return(
      GetTrendDirection()
      ==
      TREND_SELL
   );
}



bool IsFlatMarket()
{
   return(
      GetTrendDirection()
      ==
      TREND_NONE
   );
}



//====================================================
// TREND STRENGTH
//====================================================

double GetTrendDistance()
{

   if(!UpdateMA())
      return 0;


   double distance =
      MathAbs(
         maFastBuffer[0]
         -
         maSlowBuffer[0]
      )
      /
      _Point;


   return distance;

}



//====================================================
// VOLATILITY
//====================================================

bool IsVolatileMarket()
{

   double atr =
      GetATR();



   if(atr <= 0)
      return false;



   double threshold =
      50 * _Point;



   return(
      atr > threshold
   );

}



//====================================================
// MARKET QUALITY
//====================================================

bool IsGoodMarket()
{

   if(IsFlatMarket())
      return false;


   if(!IsVolatileMarket())
      return false;


   return true;

}



#endif
