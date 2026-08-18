// XAU_AI_PRO v1.2.0
#ifndef ADVANCEDAI_MQH
#define ADVANCEDAI_MQH

#include "../Core/Config.mqh"

#include "../AI/AIEngine.mqh"
#include "../AI/AdaptiveWeights.mqh"

#include "../Filters/TrendFilter.mqh"
#include "../Filters/SpreadFilter.mqh"

#include "../Indicators/TrendStrength.mqh"
#include "../Indicators/VolatilityFilter.mqh"

//==================================================
// ADVANCED AI ENGINE v1.2.0
//==================================================

double ClampScore(double value)
{
   if(value < 0.0)
      return 0.0;

   if(value > 100.0)
      return 100.0;

   return value;
}

//==================================================

double AdvancedAIScore(int signal)
{
   if(signal == 0)
      return 0.0;

   double score = 0.0;

   //------------------------------------------
   // AI BASE
   //------------------------------------------

   score +=
      GetAIConfidence(signal) *
      GetExecutionWeight();

   //------------------------------------------
   // TREND
   //------------------------------------------

   if(StrongTrend())
      score += 100.0 * GetTrendWeight();
   else
      score -= 40.0 * GetTrendWeight();

   //------------------------------------------
   // TREND STRENGTH
   //------------------------------------------

   double trend = GetADX();

   if(trend > 100.0)
   trend = 100.0;

   score +=
   trend *
   GetStrengthWeight();

   //------------------------------------------
   // SPREAD
   //------------------------------------------

   if(GoodSpread())
      score +=
         100.0 *
         GetMarketWeight();
   else
      score -=
         60.0 *
         GetMarketWeight();

   //------------------------------------------
   // VOLATILITY
   //------------------------------------------

   if(GoodVolatility(30))
      score += 8.0;
   else
      score -= 12.0;

   //------------------------------------------
   // BONUS
   //------------------------------------------

   if(signal > 0 && TrendBuy())
      score += 6.0;

   if(signal < 0 && TrendSell())
      score += 6.0;

   score = ClampScore(score);

   return NormalizeDouble(score,2);
}

//==================================================

bool FinalAIAllow(int signal)
{
   if(signal==0)
      return false;

   double score=
      AdvancedAIScore(signal);

   PrintFormat(
      "[ADV AI] Score %.2f | Min %.2f",
      score,
      MinAIConfidence
   );

   return(score>=MinAIConfidence);
}

//==================================================

bool StrongTrend()
{
   return
   (
      TrendBuy() ||
      TrendSell()
   );
}

#endif