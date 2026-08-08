#ifndef HEALTHMONITOR_MQH
#define HEALTHMONITOR_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"

//==================================================
// XAU_AI_PRO — HEALTH MONITOR
// Sistema central de monitoramento de saúde
//==================================================

//==================================================
// CONTADORES DE ERRO
//==================================================

int g_healthBrokerErrors    = 0;
int g_healthAIErrors        = 0;
int g_healthDatasetErrors   = 0;
int g_healthFileErrors      = 0;
int g_healthJSONErrors      = 0;
int g_healthPythonErrors    = 0;
int g_healthIndicatorErrors = 0;

//==================================================
// TICK MONITOR
//==================================================

datetime g_lastTickTime       = 0;
datetime g_lastSecond         = 0;
datetime g_lastHealthCheck    = 0;

int g_ticksPerSecond         = 0;
int g_ticksThisSecond        = 0;

//==================================================
// ESTADO
//==================================================

bool g_healthInitialized = false;
bool g_healthStatus      = true;


//==================================================
// INIT
//==================================================

bool HealthMonitorInit()
{
   g_lastTickTime =
      TimeCurrent();

   g_lastSecond =
      TimeCurrent();

   g_lastHealthCheck =
      TimeCurrent();

   g_ticksPerSecond =
      0;

   g_ticksThisSecond =
      0;

   g_healthStatus =
      true;

   g_healthInitialized =
      true;

   LogSystem(
      "HealthMonitor inicializado"
   );

   return true;
}


//==================================================
// UPDATE TICKS
//==================================================

void HealthMonitorUpdateTicks()
{
   datetime now =
      TimeCurrent();

   g_lastTickTime =
      now;

   MqlDateTime currentTime;
   MqlDateTime previousTime;

   TimeToStruct(
      now,
      currentTime
   );

   TimeToStruct(
      g_lastSecond,
      previousTime
   );

   // Novo segundo
   if(currentTime.sec != previousTime.sec)
   {
      g_ticksPerSecond =
         g_ticksThisSecond;

      g_ticksThisSecond =
         0;

      g_lastSecond =
         now;
   }

   g_ticksThisSecond++;
}


//==================================================
// TICK TIMEOUT
//==================================================

bool HealthMonitorCheckTickTimeout(
   int maxSeconds = 10
)
{
   if(!g_healthInitialized)
      return false;

   datetime now =
      TimeCurrent();

   int secondsSinceLastTick =
      (int)(
         now -
         g_lastTickTime
      );

   if(secondsSinceLastTick > maxSeconds)
   {
      LogError(
         "HealthMonitor: timeout de tick",
         "Seconds=" +
         IntegerToString(
            secondsSinceLastTick
         )
      );

      return false;
   }

   return true;
}


//==================================================
// REGISTRO DE ERRO
//==================================================

void HealthMonitorLogError(
   string module
)
{
   if(module == "BROKER")
   {
      g_healthBrokerErrors++;
   }
   else
   if(module == "AI")
   {
      g_healthAIErrors++;
   }
   else
   if(module == "DATASET")
   {
      g_healthDatasetErrors++;
   }
   else
   if(module == "FILE")
   {
      g_healthFileErrors++;
   }
   else
   if(module == "JSON")
   {
      g_healthJSONErrors++;
   }
   else
   if(module == "PYTHON")
   {
      g_healthPythonErrors++;
   }
   else
   if(module == "INDICATOR")
   {
      g_healthIndicatorErrors++;
   }
   else
   {
      LogWarning(
         "HealthMonitor: módulo desconhecido",
         "Module=" + module
      );
   }
}


//==================================================
// HEALTH CHECK
//==================================================

bool HealthMonitorCheck()
{
   if(!g_healthInitialized)
      return false;

   datetime now =
      TimeCurrent();

   // Não executa análise completa
   // em todos os ticks.
   if(
      now -
      g_lastHealthCheck < 60
   )
   {
      return g_healthStatus;
   }

   g_lastHealthCheck =
      now;

   bool healthy =
      true;


   //================================================
   // TICK
   //================================================

   if(
      !HealthMonitorCheckTickTimeout(
         15
      )
   )
   {
      LogWarning(
         "HealthMonitor: tick timeout"
      );

      healthy =
         false;
   }


   //================================================
   // BROKER
   //================================================

   if(g_healthBrokerErrors > 5)
   {
      LogError(
         "HealthMonitor: erros de broker",
         IntegerToString(
            g_healthBrokerErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // AI
   //================================================

   if(g_healthAIErrors > 3)
   {
      LogError(
         "HealthMonitor: erros de IA",
         IntegerToString(
            g_healthAIErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // DATASET
   //================================================

   if(g_healthDatasetErrors > 2)
   {
      LogError(
         "HealthMonitor: erros de dataset",
         IntegerToString(
            g_healthDatasetErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // FILE
   //================================================

   if(g_healthFileErrors > 2)
   {
      LogError(
         "HealthMonitor: erros de arquivo",
         IntegerToString(
            g_healthFileErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // JSON
   //================================================

   if(g_healthJSONErrors > 2)
   {
      LogError(
         "HealthMonitor: erros de JSON",
         IntegerToString(
            g_healthJSONErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // PYTHON
   //================================================

   if(g_healthPythonErrors > 1)
   {
      LogError(
         "HealthMonitor: erros de Python",
         IntegerToString(
            g_healthPythonErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // INDICADORES
   //================================================

   if(g_healthIndicatorErrors > 5)
   {
      LogError(
         "HealthMonitor: erros de indicadores",
         IntegerToString(
            g_healthIndicatorErrors
         )
      );

      healthy =
         false;
   }


   //================================================
   // RESULTADO
   //================================================

   g_healthStatus =
      healthy;


   if(healthy)
   {
      LogInfo(
         "HealthMonitor: HEALTH OK"
      );
   }
   else
   {
      LogWarning(
         "HealthMonitor: HEALTH FAILURE"
      );
   }


   return healthy;
}


//==================================================
// GETTERS
//==================================================

int HealthGetBrokerErrors()
{
   return g_healthBrokerErrors;
}


int HealthGetAIErrors()
{
   return g_healthAIErrors;
}


int HealthGetDatasetErrors()
{
   return g_healthDatasetErrors;
}


int HealthGetFileErrors()
{
   return g_healthFileErrors;
}


int HealthGetJSONErrors()
{
   return g_healthJSONErrors;
}


int HealthGetPythonErrors()
{
   return g_healthPythonErrors;
}


int HealthGetIndicatorErrors()
{
   return g_healthIndicatorErrors;
}


//==================================================
// TICK METRICS
//==================================================

int HealthGetTicksPerSecond()
{
   return g_ticksPerSecond;
}


int HealthGetSecondsSinceTick()
{
   if(!g_healthInitialized)
      return -1;

   return(
      int)(
         TimeCurrent() -
         g_lastTickTime
      );
}


//==================================================
// STATUS
//==================================================

bool HealthIsHealthy()
{
   return g_healthStatus;
}


//==================================================
// SUMMARY
//==================================================

string HealthMonitorSummary()
{
   string summary =
      "=== HEALTH MONITOR ===\n";


   summary +=
      "Status: " +
      (
         g_healthStatus
         ? "HEALTHY"
         : "FAILURE"
      ) +
      "\n";


   summary +=
      "Ticks/seg: " +
      IntegerToString(
         g_ticksPerSecond
      ) +
      "\n";


   summary +=
      "Segundos sem tick: " +
      IntegerToString(
         HealthGetSecondsSinceTick()
      ) +
      "\n\n";


   summary +=
      "Broker errors: " +
      IntegerToString(
         g_healthBrokerErrors
      ) +
      "\n";


   summary +=
      "AI errors: " +
      IntegerToString(
         g_healthAIErrors
      ) +
      "\n";


   summary +=
      "Dataset errors: " +
      IntegerToString(
         g_healthDatasetErrors
      ) +
      "\n";


   summary +=
      "File errors: " +
      IntegerToString(
         g_healthFileErrors
      ) +
      "\n";


   summary +=
      "JSON errors: " +
      IntegerToString(
         g_healthJSONErrors
      ) +
      "\n";


   summary +=
      "Python errors: " +
      IntegerToString(
         g_healthPythonErrors
      ) +
      "\n";


   summary +=
      "Indicator errors: " +
      IntegerToString(
         g_healthIndicatorErrors
      );


   return summary;
}


//==================================================
// RESET ERRORS
//==================================================

void HealthMonitorResetErrors()
{
   g_healthBrokerErrors =
      0;

   g_healthAIErrors =
      0;

   g_healthDatasetErrors =
      0;

   g_healthFileErrors =
      0;

   g_healthJSONErrors =
      0;

   g_healthPythonErrors =
      0;

   g_healthIndicatorErrors =
      0;


   g_healthStatus =
      true;


   LogSystem(
      "HealthMonitor: contadores resetados"
   );
}


//==================================================
// SHUTDOWN
//==================================================

void HealthMonitorShutdown()
{
   LogSystem(
      "HealthMonitor finalizado"
   );

   g_healthInitialized =
      false;
}


#endif