// XAU_AI_PRO v1.2.0
#ifndef FAILSAFE_MQH
#define FAILSAFE_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"
#include "HealthMonitor.mqh"
#include "WatchDog.mqh"
#include "../Core/PerformanceAnalyzer.mqh"

//==================================================
// XAU_AI_PRO — FAILSAFE ENGINE
// Hardening / Production Safety Layer
//==================================================

enum ENUM_ROBOT_MODE
{
   ROBOT_MODE_AUTO = 0,
   ROBOT_MODE_SAFE = 1
};

//==================================================
// ESTADO GLOBAL
//==================================================

ENUM_ROBOT_MODE g_robotMode = ROBOT_MODE_AUTO;

datetime g_safeModeStart = 0;

// Duração mínima do SAFE_MODE
int g_safeModeDuration = 300;

//==================================================
// LIMITES DE SEGURANÇA
//==================================================

double g_failSafeDrawdownThreshold = 15.0;

int g_failSafeTickTimeout = 15;

int g_failSafeMaxAIErrors = 5;

int g_failSafeMaxBrokerErrors = 10;


//==================================================
// ESTADO DE EVENTOS
//==================================================

bool g_failSafeTriggered = false;

string g_failSafeReason = "";


//==================================================
// INICIALIZAÇÃO
//==================================================

bool FailSafeInit()
{
   g_robotMode = ROBOT_MODE_AUTO;

   g_safeModeStart = 0;

   g_failSafeTriggered = false;

   g_failSafeReason = "";

   LogSystem(
      "FailSafe inicializado | Modo=AUTO"
   );

   return true;
}


//==================================================
// ATIVA SAFE MODE
//==================================================

void FailSafeActivate(string reason)
{
   if(g_robotMode == ROBOT_MODE_SAFE)
      return;

   g_robotMode = ROBOT_MODE_SAFE;

   g_safeModeStart = TimeCurrent();

   g_failSafeTriggered = true;

   g_failSafeReason = reason;

   LogWarning(
      "FAILSAFE ATIVADO",
      "Reason=" + reason
   );

   Print(
      "========================================"
   );

   Print(
      "XAU_AI_PRO FAILSAFE"
   );

   Print(
      "SAFE MODE ATIVADO"
   );

   Print(
      "Motivo: ",
      reason
   );

   Print(
      "========================================"
   );
}


//==================================================
// VERIFICA SE SAFE MODE PODE SER ENCERRADO
//==================================================

bool FailSafeRecoveryCheck()
{
   if(g_robotMode != ROBOT_MODE_SAFE)
      return true;


   datetime now = TimeCurrent();


   int elapsed =
      (int)(now - g_safeModeStart);


   if(elapsed < g_safeModeDuration)
      return false;


   double dd =
      PerformanceCurrentDrawdown();


   int aiErrors =
      HealthGetAIErrors();


   int brokerErrors =
      HealthGetBrokerErrors();


   bool tickOK =
      HealthMonitorCheckTickTimeout(
         g_failSafeTickTimeout
      );


   bool healthOK =
      HealthMonitorCheck();


   if(
      dd < g_failSafeDrawdownThreshold &&
      aiErrors < g_failSafeMaxAIErrors &&
      brokerErrors < g_failSafeMaxBrokerErrors &&
      tickOK &&
      healthOK
   )
   {
      g_robotMode =
         ROBOT_MODE_AUTO;


      g_failSafeTriggered =
         false;


      g_failSafeReason =
         "";


      LogSystem(
         "FailSafe recovery OK | AUTO restaurado"
      );


      return true;
   }


   LogWarning(
      "FailSafe recovery bloqueado"
   );


   return false;
}


//==================================================
// FAILSAFE CHECK PRINCIPAL
//==================================================

bool FailSafeCheck()
{
   //================================================
   // SAFE MODE
   //================================================

   if(g_robotMode == ROBOT_MODE_SAFE)
   {
      return FailSafeRecoveryCheck();
   }


   //================================================
   // AUTO MODE
   //================================================

   double dd =
      PerformanceCurrentDrawdown();


   int aiErrors =
      HealthGetAIErrors();


   int brokerErrors =
      HealthGetBrokerErrors();


   bool tickOK =
      HealthMonitorCheckTickTimeout(
         g_failSafeTickTimeout
      );


   bool healthOK =
      HealthMonitorCheck();


   //================================================
   // DRAWDOWN
   //================================================

   if(dd >= g_failSafeDrawdownThreshold)
   {
      FailSafeActivate(
         "CRITICAL_DRAWDOWN"
      );

      return false;
   }


   //================================================
   // AI
   //================================================

   if(aiErrors >= g_failSafeMaxAIErrors)
   {
      FailSafeActivate(
         "AI_ERRORS"
      );

      return false;
   }


   //================================================
   // BROKER
   //================================================

   if(brokerErrors >= g_failSafeMaxBrokerErrors)
   {
      FailSafeActivate(
         "BROKER_ERRORS"
      );

      return false;
   }


   //================================================
   // TICK
   //================================================

   if(!tickOK)
   {
      FailSafeActivate(
         "TICK_TIMEOUT"
      );

      return false;
   }


   //================================================
   // HEALTH MONITOR
   //================================================

   if(!healthOK)
   {
      FailSafeActivate(
         "HEALTH_CHECK_FAILED"
      );

      return false;
   }


   return true;
}


//==================================================
// PODE OPERAR?
//==================================================

bool FailSafeCanTrade()
{
   return (
      g_robotMode ==
      ROBOT_MODE_AUTO
   );
}


//==================================================
// GET MODE
//==================================================

ENUM_ROBOT_MODE FailSafeGetMode()
{
   return g_robotMode;
}


//==================================================
// GET MODE STRING
//==================================================

string FailSafeGetModeString()
{
   if(
      g_robotMode ==
      ROBOT_MODE_SAFE
   )
   {
      return "SAFE_MODE";
   }


   return "AUTO";
}


//==================================================
// GET REASON
//==================================================

string FailSafeGetReason()
{
   return g_failSafeReason;
}


//==================================================
// GET SAFE MODE ELAPSED
//==================================================

int FailSafeGetElapsed()
{
   if(
      g_robotMode !=
      ROBOT_MODE_SAFE
   )
   {
      return 0;
   }


   return (
      int)(
         TimeCurrent() -
         g_safeModeStart
      );
}


//==================================================
// GET SAFE MODE REMAINING
//==================================================

int FailSafeGetRemaining()
{
   if(
      g_robotMode !=
      ROBOT_MODE_SAFE
   )
   {
      return 0;
   }


   int remaining =
      g_safeModeDuration -
      FailSafeGetElapsed();


   if(remaining < 0)
      remaining = 0;


   return remaining;
}


//==================================================
// FORÇA MODE
//==================================================

void FailSafeSetMode(
   ENUM_ROBOT_MODE mode
)
{
   if(
      mode ==
      ROBOT_MODE_SAFE
   )
   {
      FailSafeActivate(
         "MANUAL_SAFE_MODE"
      );

      return;
   }


   g_robotMode =
      ROBOT_MODE_AUTO;


   g_failSafeTriggered =
      false;


   g_failSafeReason =
      "";


   g_safeModeStart =
      0;


   LogSystem(
      "FailSafe: AUTO definido manualmente"
   );
}


//==================================================
// RESET
//==================================================

void FailSafeReset()
{
   g_robotMode =
      ROBOT_MODE_AUTO;


   g_safeModeStart =
      0;


   g_failSafeTriggered =
      false;


   g_failSafeReason =
      "";


   LogSystem(
      "FailSafe resetado"
   );
}


//==================================================
// STATUS
//==================================================

string FailSafeSummary()
{
   string summary =
      "=== FAILSAFE ===\n";


   summary +=
      "Mode: " +
      FailSafeGetModeString() +
      "\n";


   summary +=
      "CanTrade: " +
      (
         FailSafeCanTrade()
         ? "YES"
         : "NO"
      ) +
      "\n";


   summary +=
      "Reason: " +
      g_failSafeReason +
      "\n";


   if(
      g_robotMode ==
      ROBOT_MODE_SAFE
   )
   {
      summary +=
         "Elapsed: " +
         IntegerToString(
            FailSafeGetElapsed()
         ) +
         "s\n";


      summary +=
         "Remaining: " +
         IntegerToString(
            FailSafeGetRemaining()
         ) +
         "s\n";
   }


   summary +=
      "DD Limit: " +
      DoubleToString(
         g_failSafeDrawdownThreshold,
         2
      ) +
      "%\n";


   summary +=
      "Tick Timeout: " +
      IntegerToString(
         g_failSafeTickTimeout
      ) +
      "s\n";


   summary +=
      "Max AI Errors: " +
      IntegerToString(
         g_failSafeMaxAIErrors
      ) +
      "\n";


   summary +=
      "Max Broker Errors: " +
      IntegerToString(
         g_failSafeMaxBrokerErrors
      );


   return summary;
}


//==================================================
// SHUTDOWN
//==================================================

void FailSafeShutdown()
{
   LogSystem(
      "FailSafe finalizado"
   );
}


#endif