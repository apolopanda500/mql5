#ifndef WATCHDOG_MQH
#define WATCHDOG_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"
#include "HealthMonitor.mqh"

//==================================================
// WATCHDOG — V1.1 Hardening
// Monitora heartbeat dos modulos criticos
//==================================================

//==================================================
// ULTIMO HEARTBEAT
//==================================================

ulong g_wdATRTime    = 0;
ulong g_wdADXTime    = 0;
ulong g_wdRSITime    = 0;
ulong g_wdAITime     = 0;
ulong g_wdPythonTime = 0;
ulong g_wdCSVTime    = 0;
ulong g_wdJSONTime   = 0;


//==================================================
// CONTADORES DE FALHA
//==================================================

int g_wdATRFailures    = 0;
int g_wdADXFailures    = 0;
int g_wdRSIFailures    = 0;
int g_wdAIFailures     = 0;
int g_wdPythonFailures = 0;
int g_wdCSVFailures    = 0;
int g_wdJSONFailures   = 0;


//==================================================
// CONFIGURACAO
//==================================================

int g_wdMaxFailures  = 3;
int g_wdCheckInterval = 60;


//==================================================
// INICIALIZACAO
//==================================================

bool WatchDogInit()
{
   ulong now = GetTickCount64();

   g_wdATRTime    = now;
   g_wdADXTime    = now;
   g_wdRSITime    = now;
   g_wdAITime     = now;
   g_wdPythonTime = now;
   g_wdCSVTime    = now;
   g_wdJSONTime   = now;

   g_wdATRFailures    = 0;
   g_wdADXFailures    = 0;
   g_wdRSIFailures    = 0;
   g_wdAIFailures     = 0;
   g_wdPythonFailures = 0;
   g_wdCSVFailures    = 0;
   g_wdJSONFailures   = 0;

   LogSystem("WatchDog inicializado");

   return true;
}


//==================================================
// VERIFICA MODULO
//==================================================

bool WatchDogCheckModule(
   string module,
   ulong &lastTime,
   int &failures,
   ulong currentTime
)
{
   if(lastTime == 0)
   {
      failures++;

      if(failures >= g_wdMaxFailures)
      {
         LogWarning(
            "WatchDog: modulo ",
            module,
            " sem heartbeat. Falha critica."
         );

         return false;
      }

      return true;
   }

   ulong elapsedMs = currentTime - lastTime;

   ulong timeoutMs =
      (ulong)g_wdCheckInterval * 1000;

   if(elapsedMs > timeoutMs)
   {
      failures++;

      if(failures >= g_wdMaxFailures)
      {
         LogWarning(
            "WatchDog: modulo ",
            module,
            " sem heartbeat por ",
            IntegerToString(
               (int)(elapsedMs / 1000)
            ),
            " segundos."
         );

         return false;
      }

      return true;
   }

   failures = 0;

   return true;
}


//==================================================
// HEARTBEAT
//==================================================

void WatchDogHeartbeat(string module)
{
   ulong now = GetTickCount64();

   if(module == "ATR")
      g_wdATRTime = now;

   else if(module == "ADX")
      g_wdADXTime = now;

   else if(module == "RSI")
      g_wdRSITime = now;

   else if(module == "AI")
      g_wdAITime = now;

   else if(module == "PYTHON")
      g_wdPythonTime = now;

   else if(module == "CSV")
      g_wdCSVTime = now;

   else if(module == "JSON")
      g_wdJSONTime = now;
}


//==================================================
// CHECK GERAL
//==================================================

bool WatchDogRunCheck()
{
   ulong now = GetTickCount64();

   bool allOK = true;


   if(!WatchDogCheckModule(
      "ATR",
      g_wdATRTime,
      g_wdATRFailures,
      now))
   {
      allOK = false;
   }


   if(!WatchDogCheckModule(
      "ADX",
      g_wdADXTime,
      g_wdADXFailures,
      now))
   {
      allOK = false;
   }


   if(!WatchDogCheckModule(
      "RSI",
      g_wdRSITime,
      g_wdRSIFailures,
      now))
   {
      allOK = false;
   }


   if(!WatchDogCheckModule(
      "AI",
      g_wdAITime,
      g_wdAIFailures,
      now))
   {
      allOK = false;
   }


   if(!WatchDogCheckModule(
      "PYTHON",
      g_wdPythonTime,
      g_wdPythonFailures,
      now))
   {
      allOK = false;
   }


   if(!WatchDogCheckModule(
      "CSV",
      g_wdCSVTime,
      g_wdCSVFailures,
      now))
   {
      allOK = false;
   }


   if(!WatchDogCheckModule(
      "JSON",
      g_wdJSONTime,
      g_wdJSONFailures,
      now))
   {
      allOK = false;
   }


   return allOK;
}


//==================================================
// RESET FAILURES
//==================================================

void WatchDogResetFailures(string module)
{
   if(module == "ATR")
      g_wdATRFailures = 0;

   else if(module == "ADX")
      g_wdADXFailures = 0;

   else if(module == "RSI")
      g_wdRSIFailures = 0;

   else if(module == "AI")
      g_wdAIFailures = 0;

   else if(module == "PYTHON")
      g_wdPythonFailures = 0;

   else if(module == "CSV")
      g_wdCSVFailures = 0;

   else if(module == "JSON")
      g_wdJSONFailures = 0;
}


//==================================================
// RESUMO
//==================================================

string WatchDogSummary()
{
   string summary =
      "=== WATCHDOG ===\n";

   summary +=
      "ATR failures: " +
      IntegerToString(g_wdATRFailures) +
      "\n";

   summary +=
      "ADX failures: " +
      IntegerToString(g_wdADXFailures) +
      "\n";

   summary +=
      "RSI failures: " +
      IntegerToString(g_wdRSIFailures) +
      "\n";

   summary +=
      "AI failures: " +
      IntegerToString(g_wdAIFailures) +
      "\n";

   summary +=
      "Python failures: " +
      IntegerToString(g_wdPythonFailures) +
      "\n";

   summary +=
      "CSV failures: " +
      IntegerToString(g_wdCSVFailures) +
      "\n";

   summary +=
      "JSON failures: " +
      IntegerToString(g_wdJSONFailures) +
      "\n";

   return summary;
}


#endif