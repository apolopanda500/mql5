#ifndef TRADEPIPELINE_MQH
#define TRADEPIPELINE_MQH

#include "SignalCore.mqh"
#include "DecisionEngine.mqh"
#include "ExecutionEngine.mqh"

bool RunTradePipeline()
{
   int decision = GetDecision();

   if(decision == 0)
      return false;

   return ExecuteTrade(decision);
}

#endif