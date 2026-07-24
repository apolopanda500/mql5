#ifndef ADVANCEDAI_MQH
#define ADVANCEDAI_MQH


#include "../Core/Config.mqh"

#include "../AI/AIEngine.mqh"

#include "../Filters/TrendFilter.mqh"
#include "../Filters/SpreadFilter.mqh"

#include "../Indicators/TrendStrength.mqh"
#include "../Indicators/VolatilityFilter.mqh"


//==================================================
// ADVANCED AI ENGINE
//==================================================

//==================================================
// ADVANCED AI SCORE
//==================================================

double AdvancedAIScore(int signal)
{

   double base = GetAIConfidence(signal);


   double score = base;


   // Consistência de tendência
   if(StrongTrend())
      score += 10;
   else
      score -= 5;


   // Qualidade do spread
   if(GoodSpread())
      score += 5;
   else
      score -= 10;


   // Volatilidade adequada
   if(GoodVolatility(30))
      score += 10;
   else
      score -= 5;



   if(score > 100)
      score = 100;


   if(score < 0)
      score = 0;



   return NormalizeDouble(score,2);
}



//==================================================
// AI DECISION
//==================================================

bool FinalAIAllow(int signal)
{

   if(signal == 0)
      return false;


   double score = AdvancedAIScore(signal);


   Print(
      "ADVANCED AI SCORE: ",
      score
   );


   return(score >= MinAIConfidence);
}


//==================================================
// STRONG TREND WRAPPER
//==================================================

bool StrongTrend()
{

   if(TrendBuy())
      return true;


   if(TrendSell())
      return true;


   return false;

}

#endif
