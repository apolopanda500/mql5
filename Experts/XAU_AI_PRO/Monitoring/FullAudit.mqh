//+------------------------------------------------------------------+
//|                                                    FullAudit.mqh |
//|                         Full Decision Audit System                |
//|                              XAU_AI_PRO v1.2.0                      |
//+------------------------------------------------------------------+
#property copyright "XAU_AI_PRO"
#property version   "1.2.0"

#ifndef FULL_AUDIT_MQH
#define FULL_AUDIT_MQH

//==================================================
// CONFIGURAÇÃO
//==================================================

#define FULL_AUDIT_MAX_RECORDS 1000
#define FULL_AUDIT_FILE        "Data\\audit\\full_audit.csv"

//==================================================
// REGISTRO
//==================================================

struct AuditRecord
{
   datetime time;

   ulong    ticket;

   string   symbol;

   double   price;

   double   rsi;
   double   adx;
   double   atr;
   double   ema;

   double   spread;

   string   session;

   string   ai_signal;

   double   ai_confidence;
   double   ai_score;

   string   entry_reason;
   string   exit_reason;

   double   result;
};

//==================================================
// CLASSE
//==================================================

class CFullAudit
{
private:

   static AuditRecord m_records[];

   static int m_record_count;

   static bool m_initialized;

   static string m_file_path;

public:

   static void Init();

   static void LogDecision(
      string symbol,
      ulong ticket,
      double price,
      double rsi,
      double adx,
      double atr,
      double ema,
      double spread,
      string session,
      string ai_signal,
      double ai_confidence,
      double ai_score,
      string entry_reason
   );

   static void LogExit(
      ulong ticket,
      string exit_reason,
      double result
   );

   static void SaveToFile();

   static string GetAuditSummary();

   static void LogAudit();

   static void Shutdown();
};

//==================================================
// VARIÁVEIS ESTÁTICAS
//==================================================

AuditRecord CFullAudit::m_records[];

int CFullAudit::m_record_count = 0;

bool CFullAudit::m_initialized = false;

string CFullAudit::m_file_path = "";

//==================================================
// INIT
//==================================================

void CFullAudit::Init()
{
   if(m_initialized)
      return;

   m_file_path = FULL_AUDIT_FILE;

   ArrayResize(
      m_records,
      FULL_AUDIT_MAX_RECORDS
   );

   m_record_count = 0;

   m_initialized = true;

   Print(
      "[AUDIT] FullAudit inicializado | Arquivo: ",
      m_file_path
   );
}

//==================================================
// LOG DECISION
//==================================================

void CFullAudit::LogDecision(
   string symbol,
   ulong ticket,
   double price,
   double rsi,
   double adx,
   double atr,
   double ema,
   double spread,
   string session,
   string ai_signal,
   double ai_confidence,
   double ai_score,
   string entry_reason
)
{
   if(!m_initialized)
      Init();


   //================================================
   // BUFFER CHEIO
   //================================================

   if(m_record_count >= FULL_AUDIT_MAX_RECORDS)
   {
      SaveToFile();

      m_record_count = 0;
   }


   int index = m_record_count;


   //================================================
   // DADOS
   //================================================

   m_records[index].time = TimeCurrent();

   m_records[index].ticket = ticket;

   m_records[index].symbol = symbol;

   m_records[index].price = price;

   m_records[index].rsi = rsi;

   m_records[index].adx = adx;

   m_records[index].atr = atr;

   m_records[index].ema = ema;

   m_records[index].spread = spread;

   m_records[index].session = session;

   m_records[index].ai_signal = ai_signal;

   m_records[index].ai_confidence = ai_confidence;

   m_records[index].ai_score = ai_score;

   m_records[index].entry_reason = entry_reason;

   m_records[index].exit_reason = "";

   m_records[index].result = 0.0;


   m_record_count++;


   Print(
      "[AUDIT] Decision registrada | ",
      symbol,
      " | Ticket=",
      (string)ticket,
      " | AI=",
      ai_signal,
      " | Score=",
      DoubleToString(ai_score,2)
   );
}

//==================================================
// LOG EXIT
//==================================================

void CFullAudit::LogExit(
   ulong ticket,
   string exit_reason,
   double result
)
{
   if(!m_initialized)
      Init();


   if(ticket == 0)
      return;


   //================================================
   // PROCURAR TICKET
   //================================================

   for(int i = m_record_count - 1; i >= 0; i--)
   {
      if(m_records[i].ticket != ticket)
         continue;


      m_records[i].exit_reason = exit_reason;

      m_records[i].result = result;


      Print(
         "[AUDIT] Exit registrado | Ticket=",
         (string)ticket,
         " | Result=",
         DoubleToString(result,2),
         " | Reason=",
         exit_reason
      );


      return;
   }


   Print(
      "[AUDIT] Ticket nao encontrado: ",
      (string)ticket
   );
}

//==================================================
// SAVE
//==================================================

void CFullAudit::SaveToFile()
{
   if(!m_initialized)
      Init();


   if(m_record_count <= 0)
      return;


   int handle = FileOpen(
      m_file_path,
      FILE_READ |
      FILE_WRITE |
      FILE_CSV |
      FILE_ANSI |
      FILE_SHARE_READ |
      FILE_SHARE_WRITE,
      ';'
   );


   if(handle == INVALID_HANDLE)
   {
      Print(
         "[AUDIT] Erro ao abrir arquivo | Code=",
         GetLastError()
      );

      return;
   }


   //================================================
   // IR PARA FIM
   //================================================

   FileSeek(
      handle,
      0,
      SEEK_END
   );


   //================================================
   // HEADER
   //================================================

   if(FileSize(handle) == 0)
   {
      FileWrite(
         handle,
         "Time",
         "Ticket",
         "Symbol",
         "Price",
         "RSI",
         "ADX",
         "ATR",
         "EMA",
         "Spread",
         "Session",
         "AI_Signal",
         "AI_Confidence",
         "AI_Score",
         "Entry_Reason",
         "Exit_Reason",
         "Result"
      );
   }


   //================================================
   // RECORDS
   //================================================

   for(int i = 0; i < m_record_count; i++)
   {
      FileWrite(
         handle,

         TimeToString(
            m_records[i].time,
            TIME_DATE | TIME_SECONDS
         ),

         (string)m_records[i].ticket,

         m_records[i].symbol,

         DoubleToString(
            m_records[i].price,
            _Digits
         ),

         DoubleToString(
            m_records[i].rsi,
            2
         ),

         DoubleToString(
            m_records[i].adx,
            2
         ),

         DoubleToString(
            m_records[i].atr,
            _Digits
         ),

         DoubleToString(
            m_records[i].ema,
            _Digits
         ),

         DoubleToString(
            m_records[i].spread,
            2
         ),

         m_records[i].session,

         m_records[i].ai_signal,

         DoubleToString(
            m_records[i].ai_confidence,
            2
         ),

         DoubleToString(
            m_records[i].ai_score,
            2
         ),

         m_records[i].entry_reason,

         m_records[i].exit_reason,

         DoubleToString(
            m_records[i].result,
            2
         )
      );
   }


   FileFlush(handle);

   FileClose(handle);


   Print(
      "[AUDIT] ",
      m_record_count,
      " registros salvos"
   );
}

//==================================================
// SUMMARY
//==================================================

string CFullAudit::GetAuditSummary()
{
   return StringFormat(
      "FullAudit | Records=%d | File=%s | Status=%s",
      m_record_count,
      m_file_path,
      m_initialized ? "READY" : "OFF"
   );
}

//==================================================
// LOG AUDIT
//==================================================

void CFullAudit::LogAudit()
{
   Print(
      "[AUDIT] ",
      GetAuditSummary()
   );
}

//==================================================
// SHUTDOWN
//==================================================

void CFullAudit::Shutdown()
{
   if(!m_initialized)
      return;


   if(m_record_count > 0)
      SaveToFile();


   ArrayFree(
      m_records
   );


   m_record_count = 0;

   m_initialized = false;

   m_file_path = "";


   Print(
      "[AUDIT] FullAudit finalizado"
   );
}

#endif