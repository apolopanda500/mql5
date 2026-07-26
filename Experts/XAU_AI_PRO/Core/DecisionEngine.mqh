#ifndef DECISIONENGINE_MQH
#define DECISIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/SignalCore.mqh"
#include "../Core/ValidationEngine.mqh"

//==================================================
// DECISION ENGINE
//==================================================

double MarketScore=0;

//==================================================
// MARKET SCORE
//==================================================

double CalculateMarketScore(int signal)
{
   if(signal==0)
      return 0;

   double score=50;

   score+=20;

   if(score>100)
      score=100;

   MarketScore=NormalizeDouble(score,2);

   return MarketScore;
}

//==================================================
// ALLOW TRADE
//==================================================

bool AllowTrade(int signal, string symbol="")
{
   if(signal==0)
      return false;

   if(!ValidateTrade(signal, symbol))
      return false;

   double score=
      CalculateMarketScore(signal);

   if(score<60)
      return false;

   return true;
}

//==================================================
// FINAL DECISION
//==================================================

int GetDecision(string symbol="")
{
   int signal=
      GetSignal(symbol);

   if(signal==0)
      return 0;

   if(!AllowTrade(signal, symbol))
      return 0;

   Print(
      "DECISION | SIGNAL=",
      signal,
      " SCORE=",
      DoubleToString(MarketScore,2)
   );

   return signal;
}

#endif