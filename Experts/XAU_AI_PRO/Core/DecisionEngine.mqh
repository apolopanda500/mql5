#ifndef DECISIONENGINE_MQH
#define DECISIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/SignalCore.mqh"


//==================================================
// DECISION ENGINE
//==================================================


double MarketScore = 0;


//==================================================
// SCORE BASE
//==================================================

double CalculateMarketScore(int signal)
{

   if(signal == 0)
      return 0;


   double score = 50;


   if(signal == 1 || signal == -1)
      score += 20;


   if(score > 100)
      score = 100;


   MarketScore = score;


   return score;

}



//==================================================
// PERMISSÃO
//==================================================

bool AllowTrade(int signal)
{

   if(signal == 0)
      return false;


   double score =
      CalculateMarketScore(signal);



   if(score < 60)
      return false;



   return true;

}



//==================================================
// DECISÃO FINAL
//==================================================

int GetDecision()
{

   int signal =
      GetSignal();


   if(signal == 0)
      return 0;


   if(!AllowTrade(signal))
      return 0;


   return signal;

}



#endif