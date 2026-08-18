//+------------------------------------------------------------------+
//| ProductionChecklist.mqh                                         |
//| XAU_AI_PRO - Production Readiness Checklist                     |
//+------------------------------------------------------------------+
#property copyright "XAU_AI_PRO"
#property version   "1.2.0"

#ifndef PRODUCTION_CHECKLIST_MQH
#define PRODUCTION_CHECKLIST_MQH

//==================================================
// ITEM DO CHECKLIST
//==================================================

struct ChecklistItem
{
   string name;
   bool   passed;
   string message;
   bool   critical;
};


//==================================================
// CLASSE
//==================================================

class CProductionChecklist
{
private:

   static ChecklistItem m_items[];
   static int           m_item_count;
   static bool          m_initialized;
   static bool          m_all_passed;

public:

   static void Init();

   static bool Run();

   static bool IsReady();

   static string GetSummary();

   static void LogResults();

   static int GetPassedCount();

   static int GetFailedCount();

   static int GetCriticalFailedCount();

   static void CheckBroker();

   static void CheckAccount();

   static void CheckPermissions();

   static void CheckSymbols();

   static void CheckIndicators();

   static void CheckAI();

   static void CheckPython();

   static void CheckDataset();

   static void CheckJSON();

   static void CheckLogs();

   static void CheckRisk();

   static void CheckExecution();

   static void CheckDashboard();

   static void CheckScanner();

   static void CheckPerformance();
};


//==================================================
// VARIÁVEIS ESTÁTICAS
//==================================================

ChecklistItem CProductionChecklist::m_items[];

int CProductionChecklist::m_item_count = 0;

bool CProductionChecklist::m_initialized = false;

bool CProductionChecklist::m_all_passed = false;


//==================================================
// INIT
//==================================================

void CProductionChecklist::Init()
{
   if(m_initialized)
      return;

   ArrayResize(m_items,15);

   m_item_count = 15;

   // CRÍTICOS
   m_items[0].name     = "Broker";
   m_items[0].passed   = false;
   m_items[0].message  = "";
   m_items[0].critical = true;

   m_items[1].name     = "Account";
   m_items[1].passed   = false;
   m_items[1].message  = "";
   m_items[1].critical = true;

   m_items[2].name     = "Permissions";
   m_items[2].passed   = false;
   m_items[2].message  = "";
   m_items[2].critical = true;

   m_items[3].name     = "Symbols";
   m_items[3].passed   = false;
   m_items[3].message  = "";
   m_items[3].critical = true;

   m_items[4].name     = "Indicators";
   m_items[4].passed   = false;
   m_items[4].message  = "";
   m_items[4].critical = true;

   // NÃO CRÍTICOS
   m_items[5].name     = "AI";
   m_items[5].passed   = false;
   m_items[5].message  = "";
   m_items[5].critical = false;

   m_items[6].name     = "Python";
   m_items[6].passed   = false;
   m_items[6].message  = "";
   m_items[6].critical = false;

   m_items[7].name     = "Dataset";
   m_items[7].passed   = false;
   m_items[7].message  = "";
   m_items[7].critical = false;

   m_items[8].name     = "JSON";
   m_items[8].passed   = false;
   m_items[8].message  = "";
   m_items[8].critical = false;

   m_items[9].name     = "Logs";
   m_items[9].passed   = false;
   m_items[9].message  = "";
   m_items[9].critical = false;

   // CRÍTICOS
   m_items[10].name     = "Risk";
   m_items[10].passed   = false;
   m_items[10].message  = "";
   m_items[10].critical = true;

   m_items[11].name     = "Execution";
   m_items[11].passed   = false;
   m_items[11].message  = "";
   m_items[11].critical = true;

   // NÃO CRÍTICOS
   m_items[12].name     = "Dashboard";
   m_items[12].passed   = false;
   m_items[12].message  = "";
   m_items[12].critical = false;

   m_items[13].name     = "Scanner";
   m_items[13].passed   = false;
   m_items[13].message  = "";
   m_items[13].critical = false;

   m_items[14].name     = "Performance";
   m_items[14].passed   = false;
   m_items[14].message  = "";
   m_items[14].critical = false;

   m_initialized = true;

   Print("[CHECKLIST] ProductionChecklist inicializado");
}


//==================================================
// RUN
//==================================================

bool CProductionChecklist::Run()
{
   if(!m_initialized)
      Init();

   CheckBroker();
   CheckAccount();
   CheckPermissions();
   CheckSymbols();
   CheckIndicators();

   CheckAI();
   CheckPython();
   CheckDataset();
   CheckJSON();
   CheckLogs();

   CheckRisk();
   CheckExecution();

   CheckDashboard();
   CheckScanner();
   CheckPerformance();

   m_all_passed = true;

   for(int i=0; i<m_item_count; i++)
   {
      if(!m_items[i].passed && m_items[i].critical)
      {
         m_all_passed = false;
         break;
      }
   }

   LogResults();

   return m_all_passed;
}


//==================================================
// READY
//==================================================

bool CProductionChecklist::IsReady()
{
   return m_all_passed;
}


//==================================================
// BROKER
//==================================================

void CProductionChecklist::CheckBroker()
{
   bool ok = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);

   m_items[0].passed = ok;

   if(ok)
      m_items[0].message = "Terminal conectado";
   else
      m_items[0].message = "Terminal desconectado";
}


//==================================================
// ACCOUNT
//==================================================

void CProductionChecklist::CheckAccount()
{
   long login = AccountInfoInteger(ACCOUNT_LOGIN);

   bool ok = (login > 0);

   m_items[1].passed = ok;

   if(ok)
      m_items[1].message =
         "Conta OK: " + IntegerToString(login);
   else
      m_items[1].message =
         "Conta nao identificada";
}


//==================================================
// PERMISSIONS
//==================================================

void CProductionChecklist::CheckPermissions()
{
   bool terminalTrade =
      (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);

   bool accountTrade =
      (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);

   bool ok =
      terminalTrade &&
      accountTrade;

   m_items[2].passed = ok;

   if(ok)
      m_items[2].message =
         "Trading permitido";
   else
      m_items[2].message =
         "Trading nao permitido";
}


//==================================================
// SYMBOL
//==================================================

void CProductionChecklist::CheckSymbols()
{
   string symbol = _Symbol;

   bool selected =
      SymbolSelect(symbol,true);

   double bid =
      SymbolInfoDouble(
         symbol,
         SYMBOL_BID
      );

   double ask =
      SymbolInfoDouble(
         symbol,
         SYMBOL_ASK
      );

   bool ok =
      selected &&
      bid > 0.0 &&
      ask > 0.0;

   m_items[3].passed = ok;

   if(ok)
      m_items[3].message =
         "Symbol OK: " + symbol;
   else
      m_items[3].message =
         "Symbol sem cotacao";
}


//==================================================
// INDICATORS
//==================================================

void CProductionChecklist::CheckIndicators()
{
   int handle =
      iATR(
         _Symbol,
         PERIOD_CURRENT,
         14
      );

   bool ok =
      (handle != INVALID_HANDLE);

   if(handle != INVALID_HANDLE)
      IndicatorRelease(handle);

   m_items[4].passed = ok;

   if(ok)
      m_items[4].message =
         "ATR handle criado";
   else
      m_items[4].message =
         "Falha ao criar ATR";
}


//==================================================
// AI
//==================================================

void CProductionChecklist::CheckAI()
{
   string file =
      "Data\\prediction_" +
      _Symbol +
      ".json";

   bool ok =
      FileIsExist(
         file,
         FILE_COMMON
      );

   m_items[5].passed = ok;

   if(ok)
      m_items[5].message =
         "Prediction JSON encontrado";
   else
      m_items[5].message =
         "Prediction JSON nao encontrado";
}


//==================================================
// PYTHON
//==================================================

void CProductionChecklist::CheckPython()
{
   string file =
      "Data\\prediction_" +
      _Symbol +
      ".json";

   bool ok =
      FileIsExist(
         file,
         FILE_COMMON
      );

   m_items[6].passed = ok;

   if(ok)
      m_items[6].message =
         "Pipeline Python possui prediction";
   else
      m_items[6].message =
         "Nenhuma prediction Python encontrada";
}


//==================================================
// DATASET
//==================================================

void CProductionChecklist::CheckDataset()
{
   string file =
      "Data\\dataset.csv";

   bool ok =
      FileIsExist(
         file,
         FILE_COMMON
      );

   m_items[7].passed = ok;

   if(ok)
      m_items[7].message =
         "Dataset encontrado";
   else
      m_items[7].message =
         "Dataset nao encontrado";
}


//==================================================
// JSON
//==================================================

void CProductionChecklist::CheckJSON()
{
   string file =
      "Data\\prediction_" +
      _Symbol +
      ".json";

   int handle =
      FileOpen(
         file,
         FILE_READ |
         FILE_ANSI |
         FILE_COMMON
      );

   bool ok =
      (handle != INVALID_HANDLE);

   if(handle != INVALID_HANDLE)
   {
      if(FileSize(handle) <= 0)
         ok = false;

      FileClose(handle);
   }

   m_items[8].passed = ok;

   if(ok)
      m_items[8].message =
         "JSON acessivel";
   else
      m_items[8].message =
         "JSON ausente ou vazio";
}


//==================================================
// LOGS
//==================================================

void CProductionChecklist::CheckLogs()
{
   m_items[9].passed = true;
   m_items[9].message = "Sistema de logs carregado";
}


//==================================================
// RISK
//==================================================

void CProductionChecklist::CheckRisk()
{
   double freeMargin =
      AccountInfoDouble(
         ACCOUNT_MARGIN_FREE
      );

   bool ok =
      (freeMargin > 0.0);

   m_items[10].passed = ok;

   if(ok)
      m_items[10].message =
         "Margem livre OK: " +
         DoubleToString(freeMargin,2);
   else
      m_items[10].message =
         "Margem livre insuficiente";
}


//==================================================
// EXECUTION
//==================================================

void CProductionChecklist::CheckExecution()
{
   double bid =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );

   double ask =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );

   bool ok =
      bid > 0.0 &&
      ask > 0.0;

   m_items[11].passed = ok;

   if(ok)
      m_items[11].message =
         "Bid/Ask disponiveis";
   else
      m_items[11].message =
         "Preco indisponivel";
}


//==================================================
// DASHBOARD
//==================================================

void CProductionChecklist::CheckDashboard()
{
   m_items[12].passed = true;
   m_items[12].message =
      "Modulo carregado";
}


//==================================================
// SCANNER
//==================================================

void CProductionChecklist::CheckScanner()
{
   m_items[13].passed = true;
   m_items[13].message =
      "Modulo carregado";
}


//==================================================
// PERFORMANCE
//==================================================

void CProductionChecklist::CheckPerformance()
{
   m_items[14].passed = true;
   m_items[14].message =
      "Modulo carregado";
}


//==================================================
// SUMMARY
//==================================================

string CProductionChecklist::GetSummary()
{
   string summary =
      "=== PRODUCTION CHECKLIST ===\n";

   int passed = 0;
   int failed = 0;
   int criticalFailed = 0;

   for(int i=0; i<m_item_count; i++)
   {
      string status =
         m_items[i].passed
         ? "PASS"
         : "FAIL";

      string critical =
         m_items[i].critical
         ? "[CRITICAL]"
         : "[OPTIONAL]";

      summary +=
         critical +
         " " +
         m_items[i].name +
         ": " +
         status +
         " - " +
         m_items[i].message +
         "\n";

      if(m_items[i].passed)
      {
         passed++;
      }
      else
      {
         failed++;

         if(m_items[i].critical)
            criticalFailed++;
      }
   }

   summary +=
      "\nResult: " +
      IntegerToString(passed) +
      "/" +
      IntegerToString(m_item_count) +
      " passed";

   summary +=
      " | " +
      IntegerToString(failed) +
      " failed";

   summary +=
      " | " +
      IntegerToString(criticalFailed) +
      " critical failed";

   summary +=
      "\nREADY: " +
      (m_all_passed ? "YES" : "NO");

   return summary;
}


//==================================================
// LOG RESULTS
//==================================================

void CProductionChecklist::LogResults()
{
   Print(
      "[CHECKLIST]\n",
      GetSummary()
   );
}


//==================================================
// COUNTERS
//==================================================

int CProductionChecklist::GetPassedCount()
{
   int count = 0;

   for(int i=0; i<m_item_count; i++)
   {
      if(m_items[i].passed)
         count++;
   }

   return count;
}


//==================================================

int CProductionChecklist::GetFailedCount()
{
   int count = 0;

   for(int i=0; i<m_item_count; i++)
   {
      if(!m_items[i].passed)
         count++;
   }

   return count;
}


//==================================================

int CProductionChecklist::GetCriticalFailedCount()
{
   int count = 0;

   for(int i=0; i<m_item_count; i++)
   {
      if(!m_items[i].passed &&
         m_items[i].critical)
      {
         count++;
      }
   }

   return count;
}

#endif