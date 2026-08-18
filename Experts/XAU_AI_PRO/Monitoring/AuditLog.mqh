// XAU_AI_PRO v1.2.0
#ifndef AUDITLOG_MQH
#define AUDITLOG_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"

//==================================================
// XAU_AI_PRO - AUDIT LOG
// Enterprise Decision Audit
//==================================================

int auditHandle = INVALID_HANDLE;


//==================================================
// INICIALIZA
//==================================================

bool AuditLogInit()
{
   if(auditHandle != INVALID_HANDLE)
      return true;

   auditHandle =
      FileOpen(
         "audit_log.csv",
         FILE_COMMON |
         FILE_READ |
         FILE_WRITE |
         FILE_CSV |
         FILE_ANSI
      );

   if(auditHandle == INVALID_HANDLE)
   {
      LogError(
         "AuditLog: falha ao abrir arquivo. Erro: ",
         IntegerToString(
            GetLastError()
         )
      );

      return false;
   }


   FileSeek(
      auditHandle,
      0,
      SEEK_END
   );


   if(FileSize(auditHandle) == 0)
   {
      FileWrite(
         auditHandle,

         "Time",
         "Symbol",
         "Timeframe",

         "Direction",

         "RSI",
         "ADX",
         "ATR",

         "EMA_Fast",
         "EMA_Slow",

         "AI_Score",
         "AI_Confidence",

         "Technical_Score",
         "Combined_Score",

         "Spread",
         "Session",

         "Result",

         "Ticket",

         "Profit"
      );

      FileFlush(
         auditHandle
      );
   }


   LogSystem(
      "AuditLog inicializado"
   );

   return true;
}


//==================================================
// REGISTRA DECISÃO
//==================================================

void AuditLogDecision(
   string symbol,
   string direction,

   double rsi,
   double adx,
   double atr,

   double emaFast,
   double emaSlow,

   double aiScore,
   double aiConfidence,

   double technicalScore,
   double combinedScore,

   double spread,

   string session,

   string result = "",

   ulong ticket = 0,

   double profit = 0.0
)
{
   if(auditHandle == INVALID_HANDLE)
      return;


   if(symbol == "")
      symbol = _Symbol;


   FileSeek(
      auditHandle,
      0,
      SEEK_END
   );


   FileWrite(
      auditHandle,

      TimeToString(
         TimeCurrent(),
         TIME_DATE |
         TIME_SECONDS
      ),

      symbol,

      EnumToString(
         (ENUM_TIMEFRAMES)Period()
      ),

      direction,

      DoubleToString(
         rsi,
         2
      ),

      DoubleToString(
         adx,
         2
      ),

      DoubleToString(
         atr,
         _Digits
      ),

      DoubleToString(
         emaFast,
         _Digits
      ),

      DoubleToString(
         emaSlow,
         _Digits
      ),

      DoubleToString(
         aiScore,
         2
      ),

      DoubleToString(
         aiConfidence,
         2
      ),

      DoubleToString(
         technicalScore,
         2
      ),

      DoubleToString(
         combinedScore,
         2
      ),

      DoubleToString(
         spread,
         2
      ),

      session,

      result,

      (
         ticket > 0
         ?
         IntegerToString(
            (long)ticket
         )
         :
         ""
      ),

      DoubleToString(
         profit,
         2
      )
   );


   FileFlush(
      auditHandle
   );
}


//==================================================
// REGISTRA DECISÃO SIMPLIFICADA
//==================================================

void AuditLogSimple(
   string symbol,
   string direction,
   string result,
   double score
)
{
   if(auditHandle == INVALID_HANDLE)
      return;


   if(symbol == "")
      symbol = _Symbol;


   FileSeek(
      auditHandle,
      0,
      SEEK_END
   );


   FileWrite(
      auditHandle,

      TimeToString(
         TimeCurrent(),
         TIME_DATE |
         TIME_SECONDS
      ),

      symbol,

      EnumToString(
         (ENUM_TIMEFRAMES)Period()
      ),

      direction,

      "",
      "",
      "",

      "",
      "",

      DoubleToString(
         score,
         2
      ),

      "",

      "",
      DoubleToString(
         score,
         2
      ),

      "",

      "",

      result,

      "",

      "0.00"
   );


   FileFlush(
      auditHandle
   );
}


//==================================================
// REGISTRA RESULTADO DE TRADE
//==================================================

void AuditLogTradeResult(
   string symbol,
   ulong ticket,
   double profit,
   string result
)
{
   if(auditHandle == INVALID_HANDLE)
      return;


   if(symbol == "")
      symbol = _Symbol;


   FileSeek(
      auditHandle,
      0,
      SEEK_END
   );


   FileWrite(
      auditHandle,

      TimeToString(
         TimeCurrent(),
         TIME_DATE |
         TIME_SECONDS
      ),

      symbol,

      EnumToString(
         (ENUM_TIMEFRAMES)Period()
      ),

      "",

      "",
      "",
      "",

      "",
      "",

      "",
      "",

      "",
      "",

      "",

      "",

      result,

      IntegerToString(
         (long)ticket
      ),

      DoubleToString(
         profit,
         2
      )
   );


   FileFlush(
      auditHandle
   );
}


//==================================================
// FECHA
//==================================================

void AuditLogClose()
{
   if(auditHandle != INVALID_HANDLE)
   {
      FileFlush(
         auditHandle
      );

      FileClose(
         auditHandle
      );

      auditHandle =
         INVALID_HANDLE;
   }
}


//==================================================
// STATUS
//==================================================

bool AuditLogIsReady()
{
   return (
      auditHandle != INVALID_HANDLE
   );
}


//==================================================

#endif // AUDITLOG_MQH