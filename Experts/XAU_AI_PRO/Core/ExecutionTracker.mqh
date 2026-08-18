// XAU_AI_PRO v1.2.0
#ifndef EXECUTIONTRACKER_MQH
#define EXECUTIONTRACKER_MQH

//======================================================
// EXECUTION TRACKER
//======================================================

int execTotal     = 0;
int execSuccess   = 0;
int execFailed    = 0;


//======================================================
// REGISTER EXECUTION RESULT
//======================================================

void RegisterExecutionResult(bool success)
{
   execTotal++;

   if(success)
      execSuccess++;
   else
      execFailed++;
}


//======================================================
// TRACKER SUCCESS RATE
//======================================================

double GetTrackerSuccessRate()
{
   if(execTotal == 0)
      return 0.0;

   return NormalizeDouble(
      (double)execSuccess * 100.0 / execTotal,
      2
   );
}


//======================================================
// RESET
//======================================================

void ResetExecutionStats()
{
   execTotal   = 0;
   execSuccess = 0;
   execFailed  = 0;
}

#endif