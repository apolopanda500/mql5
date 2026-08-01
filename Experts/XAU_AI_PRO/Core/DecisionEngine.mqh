#ifndef DECISIONENGINE_MQH
#define DECISIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/SignalCore.mqh"
#include "../Core/ValidationEngine.mqh"

#include "../Indicators/RSI.mqh"
#include "../Indicators/ADX.mqh"

#include "../AI/AIEngine.mqh"

//==================================================
// DECISION ENGINE
// MULTI SYMBOL
//==================================================

double MarketScore=0.0;


//==================================================
// MARKET SCORE
//==================================================

double CalculateMarketScore(
   int signal,
   string symbol=""
)
{
   if(signal==0)
      return 0.0;


   if(symbol=="")
      symbol=_Symbol;


   //================================================
   // BASE SCORE
   //================================================

   double score=50.0;


   //================================================
   // EMA TREND STRENGTH
   //================================================

   int emaFastHandle=
      iMA(
         symbol,
         PERIOD_CURRENT,
         FastEMA,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   int emaSlowHandle=
      iMA(
         symbol,
         PERIOD_CURRENT,
         SlowEMA,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   double emaStrength=0.0;


   if(
      emaFastHandle!=INVALID_HANDLE &&
      emaSlowHandle!=INVALID_HANDLE
   )
   {
      double fastBuf[];
      double slowBuf[];


      ArrayResize(
         fastBuf,
         3
      );


      ArrayResize(
         slowBuf,
         3
      );


      ArraySetAsSeries(
         fastBuf,
         true
      );


      ArraySetAsSeries(
         slowBuf,
         true
      );


      int fastCopied=
         CopyBuffer(
            emaFastHandle,
            0,
            0,
            3,
            fastBuf
         );


      int slowCopied=
         CopyBuffer(
            emaSlowHandle,
            0,
            0,
            3,
            slowBuf
         );


      if(
         fastCopied>0 &&
         slowCopied>0
      )
      {
         if(
            signal==1 &&
            fastBuf[0]>slowBuf[0]
         )
         {
            emaStrength=20.0;
         }
         else
         if(
            signal==-1 &&
            fastBuf[0]<slowBuf[0]
         )
         {
            emaStrength=20.0;
         }


         score+=emaStrength;
      }
   }


   //================================================
   // RELEASE EMA HANDLES
   //================================================

   if(
      emaFastHandle!=INVALID_HANDLE
   )
   {
      IndicatorRelease(
         emaFastHandle
      );
   }


   if(
      emaSlowHandle!=INVALID_HANDLE
   )
   {
      IndicatorRelease(
         emaSlowHandle
      );
   }


   //================================================
   // RSI QUALITY
   //================================================

   double rsi=
      GetRSI(
         symbol
      );


   double rsiQuality=0.0;


   if(
      rsi>30.0 &&
      rsi<70.0
   )
   {
      rsiQuality=15.0;
   }
   else
   if(
      rsi>20.0 &&
      rsi<80.0
   )
   {
      rsiQuality=10.0;
   }


   score+=rsiQuality;


   //================================================
   // ADX QUALITY
   //================================================

   double adx=
      GetADX(
         symbol
      );


   double adxQuality=0.0;


   if(
      adx>=MinimumADX
   )
   {
      adxQuality=15.0;
   }
   else
   if(
      adx>=MinimumADX*0.8
   )
   {
      adxQuality=10.0;
   }


   score+=adxQuality;


   //================================================
   // AI CONFIDENCE
   //================================================

   double aiConfidence=
      GetAIConfidence(
         signal,
         symbol
      );


   score+=
      (
         aiConfidence*
         0.50
      );


   //================================================
   // LIMIT SCORE
   //================================================

   if(score>100.0)
      score=100.0;


   if(score<0.0)
      score=0.0;


   MarketScore=
      NormalizeDouble(
         score,
         2
      );


   //================================================
   // LOG
   //================================================

   Print(
      "SCORE CALCULATED | Symbol=",
      symbol,
      " | Signal=",
      signal,
      " | EMA=",
      DoubleToString(
         emaStrength,
         2
      ),
      " | RSI=",
      DoubleToString(
         rsiQuality,
         2
      ),
      " | ADX=",
      DoubleToString(
         adxQuality,
         2
      ),
      " | AI=",
      DoubleToString(
         aiConfidence*0.50,
         2
      ),
      " | TOTAL=",
      DoubleToString(
         MarketScore,
         2
      )
   );


   return MarketScore;
}


//==================================================
// ALLOW TRADE
//==================================================

bool AllowTrade(
   int signal,
   string symbol=""
)
{
   if(signal==0)
      return false;


   if(symbol=="")
      symbol=_Symbol;


   //================================================
   // CORREÇÃO PRINCIPAL
   //
   // ValidateTrade espera:
   // 1º = string symbol
   // 2º = int signal
   //================================================

   if(
      !ValidateTrade(
         symbol,
         signal
      )
   )
   {
      return false;
   }


   double score=
      CalculateMarketScore(
         signal,
         symbol
      );


   if(
      score<60.0
   )
   {
      Print(
         "DECISION BLOCKED | Symbol=",
         symbol,
         " | Score=",
         DoubleToString(
            score,
            2
         )
      );

      return false;
   }


   return true;
}


//==================================================
// FINAL DECISION
//==================================================

int GetDecision(
   string symbol=""
)
{
   if(symbol=="")
      symbol=_Symbol;


   int signal=
      GetSignal(
         symbol
      );


   if(signal==0)
   {
      return 0;
   }


   if(
      !AllowTrade(
         signal,
         symbol
      )
   )
   {
      return 0;
   }


   Print(
      "DECISION APPROVED | Symbol=",
      symbol,
      " | SIGNAL=",
      signal,
      " | SCORE=",
      DoubleToString(
         MarketScore,
         2
      )
   );


   return signal;
}


#endif