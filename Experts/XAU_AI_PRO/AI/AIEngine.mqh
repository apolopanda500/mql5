#ifndef AIENGINE_MQH
#define AIENGINE_MQH


#include "../Core/Config.mqh"

#include "../Filters/TrendFilter.mqh"
#include "../Filters/SpreadFilter.mqh"

#include "../Indicators/RSI.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/VolatilityFilter.mqh"
#include "../Indicators/TrendStrength.mqh"

#include "../Core/SignalCore.mqh"

#include "AdaptiveWeights.mqh"
#include "AIConnector.mqh"


//==================================================
// PROTOTIPOS
//==================================================

double GetAIConfidence(int signal);


//==================================================
// AI FILTER INTERFACE
//==================================================

bool AITradeAllowed(string symbol="")
{

   int signal = GetSignal(symbol);


   if(signal == 0)
      return false;


   double confidence =
      GetAIConfidence(signal);



   if(confidence < MinAIConfidence)
   {

      Print(
         "AI BLOQUEADO: ",
         DoubleToString(confidence,2)
      );


      return false;

   }


   return true;

}



//==================================================
// CONFIDENCE BASE
//==================================================

double GetAIConfidence(int signal)
{

   if(signal==0)
      return 0;


   double score = 50;



   // Tendência

   if(signal==1 && TrendBuy())
      score += 20;


   if(signal==-1 && TrendSell())
      score += 20;



   // RSI

   double rsi = GetRSI();


   if(rsi > 30 && rsi < 70)
      score += 10;



   // ADX

   if(GetADX() >= MinimumADX)
      score += 10;



   // Limite

   if(score > 100)
      score = 100;



   return score;

}



#endif