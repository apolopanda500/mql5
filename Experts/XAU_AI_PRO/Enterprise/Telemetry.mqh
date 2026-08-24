//+------------------------------------------------------------------+
//|                                                    Telemetry.mqh |
//|                                  System Telemetry Monitor        |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef TELEMETRY_MQH
#define TELEMETRY_MQH

//==================================================
// TELEMETRY METRIC
//==================================================

struct TelemetryMetric
{
   string   name;
   double   value;
   string   unit;
   datetime timestamp;
   bool     is_healthy;
};


//==================================================
// TELEMETRY CLASS
//==================================================

class CTelemetry
{
private:

   static TelemetryMetric m_metrics[];
   static int             m_metric_count;
   static bool            m_initialized;
   static datetime        m_last_check;
   static int             m_check_interval_sec;

   static void AddMetric(
      string name,
      double value,
      string unit
   );

   static void CheckHealth();


public:

   static void Init();

   static void Run();

   static double GetMetric(
      string name
   );

   static bool IsHealthy(
      string name
   );

   static void RecordExecutionTime(
      string operation,
      int ms
   );

   static void RecordLatency(
      string target,
      int ms
   );

   static void RecordMemoryUsage(
      int bytes
   );

   static void RecordCPUUsage(
      double percent
   );

   static void RecordBrokerLatency(
      int ms
   );

   static void RecordPythonLatency(
      int ms
   );

   static void RecordDatabaseLatency(
      int ms
   );

   static void RecordAILatency(
      int ms
   );

   static string GetSummary();

   static void LogSummary();
};


//==================================================
// STATIC INITIALIZATION
//==================================================

TelemetryMetric CTelemetry::m_metrics[];

int CTelemetry::m_metric_count = 0;

bool CTelemetry::m_initialized = false;

datetime CTelemetry::m_last_check = 0;

int CTelemetry::m_check_interval_sec = 10;


//==================================================
// INIT
//==================================================

void CTelemetry::Init()
{
   if(m_initialized)
      return;

   ArrayResize(
      m_metrics,
      20
   );

   m_metric_count = 0;

   m_last_check = 0;

   m_initialized = true;

   Print(
      "[TELEMETRY] Telemetry initialized"
   );
}


//==================================================
// ADD / UPDATE METRIC
//==================================================

void CTelemetry::AddMetric(
   string name,
   double value,
   string unit
)
{
   if(!m_initialized)
      Init();


   //================================================
   // Atualiza métrica existente
   //================================================

   for(int i = 0; i < m_metric_count; i++)
   {
      if(m_metrics[i].name == name)
      {
         m_metrics[i].value =
            value;

         m_metrics[i].unit =
            unit;

         m_metrics[i].timestamp =
            TimeCurrent();

         m_metrics[i].is_healthy =
            true;

         return;
      }
   }


   //================================================
   // Cria nova métrica
   //================================================

   if(m_metric_count >= ArraySize(m_metrics))
   {
      Print(
         "[TELEMETRY] Metric buffer full: ",
         name
      );

      return;
   }


   TelemetryMetric metric;

   metric.name =
      name;

   metric.value =
      value;

   metric.unit =
      unit;

   metric.timestamp =
      TimeCurrent();

   metric.is_healthy =
      true;


   m_metrics[m_metric_count] =
      metric;

   m_metric_count++;
}


//==================================================
// RUN
//==================================================

void CTelemetry::Run()
{
   if(!m_initialized)
      Init();


   datetime now =
      TimeCurrent();


   if(
      m_last_check > 0 &&
      now - m_last_check <
      m_check_interval_sec
   )
   {
      return;
   }


   m_last_check =
      now;


   //================================================
   // Métricas do sistema
   //================================================

   RecordMemoryUsage(0);

   RecordCPUUsage(0);


   //================================================
   // Health check
   //================================================

   CheckHealth();
}


//==================================================
// HEALTH CHECK
//==================================================

void CTelemetry::CheckHealth()
{
   for(
      int i = 0;
      i < m_metric_count;
      i++
   )
   {
      m_metrics[i].is_healthy =
         true;


      //================================================
      // MEMORY
      //================================================

      if(
         m_metrics[i].name ==
         "Memory"
      )
      {
         if(
            m_metrics[i].value >
            500000000
         )
         {
            m_metrics[i].is_healthy =
               false;
         }
      }


      //================================================
      // CPU
      //================================================

      if(
         m_metrics[i].name ==
         "CPU"
      )
      {
         if(
            m_metrics[i].value >
            80.0
         )
         {
            m_metrics[i].is_healthy =
               false;
         }
      }


      //================================================
      // LATENCY
      //================================================

      if(
         StringFind(
            m_metrics[i].name,
            "Latency"
         ) >= 0
      )
      {
         if(
            m_metrics[i].value >
            1000.0
         )
         {
            m_metrics[i].is_healthy =
               false;
         }
      }
   }
}


//==================================================
// GET METRIC
//==================================================

double CTelemetry::GetMetric(
   string name
)
{
   if(!m_initialized)
      Init();


   for(
      int i = 0;
      i < m_metric_count;
      i++
   )
   {
      if(
         m_metrics[i].name ==
         name
      )
      {
         return m_metrics[i].value;
      }
   }


   return 0.0;
}


//==================================================
// HEALTH
//==================================================

bool CTelemetry::IsHealthy(
   string name
)
{
   if(!m_initialized)
      Init();


   for(
      int i = 0;
      i < m_metric_count;
      i++
   )
   {
      if(
         m_metrics[i].name ==
         name
      )
      {
         return m_metrics[i].is_healthy;
      }
   }


   return true;
}


//==================================================
// RECORD EXECUTION TIME
//==================================================

void CTelemetry::RecordExecutionTime(
   string operation,
   int ms
)
{
   AddMetric(
      "Exec_" + operation,
      (double)ms,
      "ms"
   );
}


//==================================================
// RECORD LATENCY
//==================================================

void CTelemetry::RecordLatency(
   string target,
   int ms
)
{
   AddMetric(
      "Latency_" + target,
      (double)ms,
      "ms"
   );
}


//==================================================
// MEMORY
//==================================================

void CTelemetry::RecordMemoryUsage(
   int bytes
)
{
   AddMetric(
      "Memory",
      (double)bytes,
      "bytes"
   );
}


//==================================================
// CPU
//==================================================

void CTelemetry::RecordCPUUsage(
   double percent
)
{
   AddMetric(
      "CPU",
      percent,
      "%"
   );
}


//==================================================
// BROKER LATENCY
//==================================================

void CTelemetry::RecordBrokerLatency(
   int ms
)
{
   AddMetric(
      "Broker_Latency",
      (double)ms,
      "ms"
   );
}


//==================================================
// PYTHON LATENCY
//==================================================

void CTelemetry::RecordPythonLatency(
   int ms
)
{
   AddMetric(
      "Python_Latency",
      (double)ms,
      "ms"
   );
}


//==================================================
// DATABASE LATENCY
//==================================================

void CTelemetry::RecordDatabaseLatency(
   int ms
)
{
   AddMetric(
      "DB_Latency",
      (double)ms,
      "ms"
   );
}


//==================================================
// AI LATENCY
//==================================================

void CTelemetry::RecordAILatency(
   int ms
)
{
   AddMetric(
      "AI_Latency",
      (double)ms,
      "ms"
   );
}


//==================================================
// SUMMARY
//==================================================

string CTelemetry::GetSummary()
{
   if(!m_initialized)
      Init();


   string result =
      StringFormat(
         "Metrics: %d | ",
         m_metric_count
      );


   for(
      int i = 0;
      i < m_metric_count;
      i++
   )
   {
      string health =
         m_metrics[i].is_healthy
         ? "OK"
         : "WARN";


      result +=
         StringFormat(
            "%s: %.1f%s(%s) ",
            m_metrics[i].name,
            m_metrics[i].value,
            m_metrics[i].unit,
            health
         );
   }


   return result;
}


//==================================================
// LOG
//==================================================

void CTelemetry::LogSummary()
{
   Print(
      "[TELEMETRY] ",
      GetSummary()
   );
}


//==================================================
// END
//==================================================

#endif // TELEMETRY_MQH