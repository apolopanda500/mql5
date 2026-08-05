//==================================================
// XAU_AI_PRO v1.10
//==================================================

#property strict
#property version   "1.10"

#include <Trade/Trade.mqh>

CTrade trade;

//==================================================
// CORE
//==================================================

#include "Core/Config.mqh"
#include "Core/BrokerConfig.mqh"
#include "Core/BrokerInfo.mqh"
#include "Core/EnvironmentManager.mqh"
#include "Core/CompatibilityManager.mqh"
#include "Core/PathManager.mqh"
#include "Core/TimeFrameManager.mqh"

//==================================================
// INDICATORS
//==================================================

#include "Indicators/ATR.mqh"
#include "Indicators/ADX.mqh"
#include "Indicators/RSI.mqh"
#include "Indicators/TrendStrength.mqh"
#include "Indicators/VolatilityFilter.mqh"

//==================================================
// FILTERS
//==================================================

#include "Filters/SpreadFilter.mqh"
#include "Filters/SessionFilter.mqh"
#include "Filters/TrendFilter.mqh"
#include "Filters/MultiTimeframeFilter.mqh"
#include "Filters/NewsFilter.mqh"

//==================================================
// AI
//==================================================

#include "AI/AIClient.mqh"
#include "AI/AIConnector.mqh"
#include "AI/AIEngine.mqh"
#include "AI/Dataset.mqh"
#include "AI/DataLogger.mqh"
#include "AI/AdaptiveWeights.mqh"

//==================================================
// SIGNAL
//==================================================

#include "Core/SignalCore.mqh"
#include "Core/DecisionEngine.mqh"
#include "Core/ValidationEngine.mqh"

//==================================================
// EXECUTION
//==================================================

#include "Core/RiskEngine.mqh"
#include "Core/ExecutionEngine.mqh"
#include "Core/OrderManager.mqh"
#include "Core/PositionManager.mqh"

//==================================================
// MULTI SYMBOL
//==================================================

#include "Core/SymbolValidator.mqh"
#include "Core/SymbolManager.mqh"
#include "Core/MarketScanner.mqh"
#include "Core/TradePipeline.mqh"

//==================================================
// MANAGEMENT
//==================================================

#include "Management/BreakEven.mqh"
#include "Management/DailyRisk.mqh"
#include "Management/EquityProtection.mqh"
#include "Management/PortfolioManager.mqh"

//==================================================
// MONITORING
//==================================================

#include "Monitoring/Dashboard.mqh"
#include "Monitoring/TradeLogger.mqh"
#include "Monitoring/PerformanceAnalyzer.mqh"

//==================================================
// ENTERPRISE
//==================================================

#include "Enterprise/SafetyManager.mqh"
#include "Enterprise/CircuitBreaker.mqh"
#include "Enterprise/RecoveryManager.mqh"
#include "Enterprise/SmartExecution.mqh"

//==================================================
// UTILS
//==================================================

#include "Utils.mqh"

//==================================================
// OBJETOS GLOBAIS
//==================================================


//==================================================
// ESTADO DO SISTEMA
//==================================================

bool SystemInitialized = false;
bool TradingEnabled    = true;
bool AIReady           = false;
bool DatasetReady      = false;

//==================================================
// CONTROLE DE TEMPO
//==================================================

datetime LastTick             = 0;
datetime LastBar              = 0;
datetime LastDatasetBar       = 0;
datetime LastPerformanceCheck = 0;
datetime LastHealthCheck      = 0;

//==================================================
// CONTROLE DE ORDENS
//==================================================

ulong LastOrderTicket   = 0;
ulong LastPositionTicket= 0;

int TradesToday         = 0;
int ConsecutiveLosses   = 0;
int ConsecutiveWins     = 0;

//==================================================
// PERFORMANCE
//==================================================

double DailyProfit      = 0.0;
double WeeklyProfit     = 0.0;
double MonthlyProfit    = 0.0;

double PeakEquity       = 0.0;
double CurrentDrawdown  = 0.0;

//==================================================
// IA
//==================================================

bool AIConnected        = false;
string AIStatus         = "OFFLINE";

double AIScore          = 0.0;
double AIConfidence     = 0.0;

//==================================================
// DATASET
//==================================================

int DatasetIndex        = -1;
bool DatasetUpdated     = false;

//==================================================
// DASHBOARD
//==================================================

bool DashboardCreated   = false;

//==================================================
// CIRCUIT BREAKER
//==================================================

bool SafeMode           = false;

//==================================================
// RECOVERY
//==================================================

bool RecoveryRunning    = false;

//==================================================
// SMART EXECUTION
//==================================================

bool ExecutionReady     = false;

//==================================================
// DEBUG
//==================================================

bool VerboseMode = EnableVerboseDebug;

bool InitializeModules()
{
   Print("=================================");
   Print("Inicializando módulos...");
   Print("=================================");

   if(!InitSystem())
      return false;

   if(!InitATR())
      Print("ATR OFF");

   if(!InitADX())
      Print("ADX OFF");

   if(!InitRSI())
      Print("RSI OFF");

   if(!InitTrendFilter())
      Print("TrendFilter OFF");

   if(!InitMTF())
      Print("MTF OFF");

   if(!InitSymbolManager())
      return false;

   AIClientInit();

   if(!DataLoggerInit())
      Print("DataLogger OFF");

   InitDailyRisk();

   PerformanceInit();

   CSafetyManager::Init();

   CCircuitBreaker::Init();

   CRecoveryManager::Init();

   CSmartExecution::Init();

   return true;
}

void ShutdownModules()
{
   ReleaseTrendFilter();

   ReleaseATR();

   ReleaseADX();

   ReleaseRSI();

   ReleaseMTF();

   DataLoggerClose();

   AIClientShutdown();

   ShutdownSystem();
}

void UpdatePerformance()
{
   ProcessClosedTrades();

   DailyProfit = AccountInfoDouble(ACCOUNT_PROFIT);

   PeakEquity = MathMax(
      PeakEquity,
      AccountInfoDouble(ACCOUNT_EQUITY)
   );
}

void UpdateSafety()
{
   CSafetyManager::UpdateStats();

   CCircuitBreaker::Run();

   CRecoveryManager::Run();
}

void UpdateDataset()
{
   if(!EnableDataset)
      return;

   datetime candle =
      iTime(
         _Symbol,
         PERIOD_CURRENT,
         0
      );

   if(candle==LastDatasetBar)
      return;

   LastDatasetBar=candle;

   int total=TotalSymbols();

   for(int i=0;i<total;i++)
   {
      string symbol=
         GetTradeSymbol(i);

      if(symbol!="")
         SaveMarketData(symbol);
   }
}

void UpdateDashboard()
{
   if(!EnableDashboard)
      return;

   DashboardUpdate();
}

bool CheckTradingConditions()
{
   if(!TradingEnabled)
      return false;

   if(!AutoTrade)
      return false;

   if(!CheckEquityProtection())
      return false;

   if(!CSafetyManager::CheckAll())
      return false;

   if(!CCircuitBreaker::CanTrade())
      return false;

   return true;
}

//==================================================
// FUNCOES AUXILIARES AUSENTES
//==================================================

// Processa trades fechados para atualizar performance
void ProcessClosedTrades()
{
   datetime from = TimeCurrent() - 86400; // ultimas 24h
   if(!HistorySelect(from, TimeCurrent()))
      return;

   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;

      if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT)
         continue;

      if(HistoryDealGetInteger(deal, DEAL_MAGIC) != MagicNumber)
         continue;

      double profit = HistoryDealGetDouble(deal, DEAL_PROFIT);
      RegisterTradePerformance(profit);
   }
}

// Atualiza o estado do cliente IA (fallback local)
void AIClientUpdate()
{
   // IA local - apenas mantem o estado atualizado
   if(EnableAIFilter)
   {
      AIReady = AIClientConnected();
      AIStatus = AIReady ? "ONLINE" : "OFFLINE";
   }
}

// Salva as estatisticas de performance em arquivo
void PerformanceSave()
{
   int handle = FileOpen("XAU_AI_PRO_stats.csv", FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
      return;

   FileWrite(handle, "metric,value");
   FileWrite(handle, "TradesToday", TradesToday);
   FileWrite(handle, "ConsecutiveWins", ConsecutiveWins);
   FileWrite(handle, "ConsecutiveLosses", ConsecutiveLosses);
   FileWrite(handle, "DailyProfit", DoubleToString(DailyProfit, 2));
   FileWrite(handle, "PeakEquity", DoubleToString(PeakEquity, 2));
   FileWrite(handle, "CurrentDrawdown", DoubleToString(CurrentDrawdown, 2));
   FileClose(handle);
}

//==================================================
// ON INIT
//==================================================

int OnInit()
{
   Print("========================================");
   Print("        XAU_AI_PRO v1.10");
   Print("========================================");

   Print("Conta.............: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Corretora.........: ", AccountInfoString(ACCOUNT_COMPANY));
   Print("Servidor..........: ", AccountInfoString(ACCOUNT_SERVER));
   Print("Símbolo...........: ", _Symbol);
   Print("Saldo.............: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   Print("Equity............: ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);

   if(!InitializeModules())
   {
      Print("ERRO: Falha ao inicializar módulos.");
      return INIT_FAILED;
   }

   PeakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   EventSetTimer(30);   // executa a cada 30 segundos

   SystemInitialized = true;

   Print("----------------------------------------");
   Print("Sistema inicializado com sucesso.");
   Print("----------------------------------------");

   return INIT_SUCCEEDED;
}


//==================================================
// ON TICK
//==================================================

void OnTick()
{
   //------------------------------------------------
   // Sistema inicializado?
   //------------------------------------------------

   if(!SystemInitialized)
      return;

   //------------------------------------------------
   // Atualiza horário
   //------------------------------------------------

   LastTick = TimeCurrent();

   //------------------------------------------------
   // Circuit Breaker
   //------------------------------------------------

   CCircuitBreaker::Run();

   if(!CCircuitBreaker::CanTrade())
      return;

   //------------------------------------------------
   // Recovery
   //------------------------------------------------

   CRecoveryManager::Run();

   //------------------------------------------------
   // Safety
   //------------------------------------------------

   if(!CSafetyManager::CheckAll())
      return;

   //------------------------------------------------
   // Equity Protection
   //------------------------------------------------

   if(!CheckEquityProtection())
      return;

   //------------------------------------------------
   // Atualiza Performance
   //------------------------------------------------

   UpdatePerformance();

   //------------------------------------------------
   // Atualiza IA
   //------------------------------------------------

   if(EnableAIFilter)
   {
      AIClientUpdate();
   }

   //------------------------------------------------
   // Atualiza Dataset
   //------------------------------------------------

   UpdateDataset();

   //------------------------------------------------
   // Scanner Multi Symbol
   //------------------------------------------------

   RunTradePipeline();

   //------------------------------------------------
   // Gerenciamento das posições
   //------------------------------------------------

   ManagePositions();

   //------------------------------------------------
   // Dashboard
   //------------------------------------------------

   UpdateDashboard();

}

//==================================================
// ON TRADE TRANSACTION
//==================================================

void OnTradeTransaction(
   const MqlTradeTransaction &trans,
   const MqlTradeRequest &request,
   const MqlTradeResult &result
)
{
   //------------------------------------------------
   // Apenas DEALS
   //------------------------------------------------

   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   ulong deal = trans.deal;

   if(deal == 0)
      return;

   if(!HistoryDealSelect(deal))
      return;

   string symbol =
      HistoryDealGetString(
         deal,
         DEAL_SYMBOL
      );

   double profit =
      HistoryDealGetDouble(
         deal,
         DEAL_PROFIT
      );

   double volume =
      HistoryDealGetDouble(
         deal,
         DEAL_VOLUME
      );

   ENUM_DEAL_ENTRY entry =
      (ENUM_DEAL_ENTRY)
      HistoryDealGetInteger(
         deal,
         DEAL_ENTRY
      );

   //------------------------------------------------
   // Entrada
   //------------------------------------------------

   if(entry == DEAL_ENTRY_IN)
   {
      TradesToday++;

      Print(
         "TRADE OPEN | ",
         symbol,
         " | LOT=",
         DoubleToString(volume,2)
      );

      return;
   }

   //------------------------------------------------
   // Saída
   //------------------------------------------------

   if(entry == DEAL_ENTRY_OUT)
   {
      //------------------------------------------------
      // Performance
      //------------------------------------------------

      RegisterTradePerformance(profit);

      //------------------------------------------------
      // Estatísticas
      //------------------------------------------------

      if(profit > 0)
      {
         ConsecutiveWins++;
         ConsecutiveLosses=0;
      }
      else
      {
         ConsecutiveLosses++;
         ConsecutiveWins=0;
      }

      //------------------------------------------------
      // Dataset
      //------------------------------------------------

      if(EnableDataset)
      {
         UpdateDatasetResult(
            DatasetIndex,
            (profit>0)
         );
      }

      //------------------------------------------------
      // Feedback IA
      //------------------------------------------------

      if(EnableAIFilter)
      {
         LogAIFeedback(
            symbol,
            profit
         );
      }

      //------------------------------------------------
      // Smart Execution
      //------------------------------------------------

      CExecutionStats::UpdateAfterTrade(
         profit
      );

      //------------------------------------------------
      // Dashboard
      //------------------------------------------------

      DashboardUpdate();

      //------------------------------------------------
      // Log
      //------------------------------------------------

      Print(
         "TRADE CLOSED | ",
         symbol,
         " | PROFIT=",
         DoubleToString(
            profit,
            2
         )
      );
   }
}

//==================================================
// ON TIMER
//==================================================

void OnTimer()
{
   //------------------------------------------------
   // Sistema inicializado?
   //------------------------------------------------

   if(!SystemInitialized)
      return;

   //------------------------------------------------
   // Recovery
   //------------------------------------------------

   CRecoveryManager::Run();

   //------------------------------------------------
   // Circuit Breaker
   //------------------------------------------------

   CCircuitBreaker::Run();

   //------------------------------------------------
   // Safety
   //------------------------------------------------

   CSafetyManager::UpdateStats();

   //------------------------------------------------
   // Atualização IA
   //------------------------------------------------

   if(EnableAIFilter)
   {
      AIClientUpdate();
   }

   //------------------------------------------------
   // Sincronizar posições
   //------------------------------------------------

   CSmartExecution::Synchronize();

   //------------------------------------------------
   // Atualizar Dashboard
   //------------------------------------------------

   if(EnableDashboard)
   {
      DashboardUpdate();
   }

   //------------------------------------------------
   // Salvar estatísticas
   //------------------------------------------------

   PerformanceSave();

   //------------------------------------------------
   // Health Check
   //------------------------------------------------

   if(EnableVerboseDebug)
   {
      Print("========== SYSTEM STATUS ==========");
      Print(CRecoveryManager::GetHealthSummary());
      Print(CSmartExecution::GetExecutionSummary());
      Print(CSafetyManager::GetSafetySummary());
      Print("==================================");
   }
}

