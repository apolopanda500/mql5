// recompile-trigger 19:40:47
//==================================================
// XAU_AI_PRO v1.2.0
//==================================================

#property strict
#property version "1.20"

#include <Trade/Trade.mqh>

CTrade trade;


//==================================================
// CORE
//==================================================

#include "Core/Config.mqh"
#include "Core/SystemManager.mqh"
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
// MANAGEMENT
//==================================================

#include "Management/BreakEven.mqh"
#include "Management/DailyRisk.mqh"
#include "Management/EquityProtection.mqh"
#include "Management/PortfolioManager.mqh"


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
// MONITORING
//==================================================

#include "Monitoring/Dashboard.mqh"
#include "Monitoring/TradeLogger.mqh"
#include "Monitoring/PerformanceAnalyzer.mqh"
#include "Monitoring/Statistics.mqh"


//==================================================
// ENTERPRISE
//==================================================

#include "Enterprise/SafetyManager.mqh"
#include "Enterprise/CircuitBreaker.mqh"
#include "Enterprise/RecoveryManager.mqh"
#include "Enterprise/SmartExecution.mqh"
#include "Enterprise/TradeMonitor.mqh"
#include "Enterprise/Scheduler.mqh"
#include "Enterprise/DatabaseManager.mqh"
#include "Enterprise/Telemetry.mqh"


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
   Print("Inicializando mÃ³dulos...");
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

   if(SymbolsPending)
      Print("SYMBOL MANAGER | Simbolos pendentes de sincronizacao (retry automatico ativo)");

   AIClientInit();

   if(!DataLoggerInit())
      Print("DataLogger OFF");

   InitDailyRisk();

   PerformanceInit();

   CSafetyManager::Init();

   CCircuitBreaker::Init();

   CRecoveryManager::Init();

   CSmartExecution::Init();

   //------------------------------------------------
   // v1.2.0 - TRADE LOGGER / DATABASE / SCHEDULER / STATISTICS
   //------------------------------------------------

   if(!InitTradeLogger())
      Print("TradeLogger OFF");

   CDatabaseManager::Init();

   if(EnableDatabase)
   {
      CDatabaseManager::Connect();
      CDatabaseManager::LogStatus();
   }

   CScheduler::Init();

   if(EnableScheduler)
   {
      // Registra tarefa de rotina diaria (ex.: backup)
      CScheduler::LogStatus();
   }

   StatisticsInit();

//------------------------------------------------
   // v1.2.0 - TELEMETRY
   //------------------------------------------------

   if(EnableTelemetry)
   {
      CTelemetry::Init();
      CTelemetry::RecordBrokerLatency(0);
   }
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

   CloseTradeLogger();

   CDatabaseManager::Disconnect();

   ShutdownSystem();
}

void UpdatePerformance()
{
   //==================================================
   // PERFORMANCE UPDATE
   //
   // NÃƒO chama ProcessClosedTrades() aqui.
   //
   // O registro de trades fechados Ã© responsabilidade
   // exclusiva de OnTradeTransaction() (evento por deal),
   // evitando duplicidade em RegisterTradePerformance().
   //
   // Antes, ProcessClosedTrades() reprocessava as Ãºltimas
   // 24h a cada tick, somando o mesmo profit mÃºltiplas
   // vezes e inflando DailyProfit / ConsecutiveWins /
   // ConsecutiveLosses.
   //==================================================

   DailyProfit =
      AccountInfoDouble(
         ACCOUNT_PROFIT
      );

   double equity =
      AccountInfoDouble(
         ACCOUNT_EQUITY
      );

   if(equity > PeakEquity)
      PeakEquity = equity;

   if(PeakEquity > 0.0)
   {
      CurrentDrawdown =
         (
            (PeakEquity - equity)
            /
            PeakEquity
         )
         * 100.0;
   }
   else
   {
      CurrentDrawdown = 0.0;
   }
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
void UpdateAIStatus()
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
   Print("        XAU_AI_PRO v1.2.0");
   Print("========================================");

   Print("Conta.............: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Corretora.........: ", AccountInfoString(ACCOUNT_COMPANY));
   Print("Servidor..........: ", AccountInfoString(ACCOUNT_SERVER));
   Print("SÃ­mbolo...........: ", _Symbol);
   Print("Saldo.............: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   Print("Equity............: ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);

   if(!InitializeModules())
   {
      Print("ERRO: Falha ao inicializar mÃ³dulos.");
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

//==================================================
// THROTTLE DE LOG (v1.2.0)
// Evita spam de "[TRADE BLOCK]" a cada tick no OnTick.
//==================================================
datetime g_lastBlockPrint = 0;

bool AllowBlockPrint()
{
   datetime now = TimeCurrent();
   if(now - g_lastBlockPrint >= 60)
   {
      g_lastBlockPrint = now;
      return true;
   }
   return false;
}

void OnTick()
{
   //------------------------------------------------
   // Sistema inicializado?
   //------------------------------------------------

   if(!SystemInitialized)
   {
      Print("[TRADE BLOCK] SYSTEM NOT INITIALIZED");
      return;
   }

   //------------------------------------------------
   //------------------------------------------------
   // Algo Trading do terminal habilitado? (v1.2.1)
   //------------------------------------------------

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      if(AllowBlockPrint())
         Print("[TRADE BLOCK] ALGO TRADING OFF | Ative o botao 'Algoritmos' no MT5 (Ferramentas > Opcoes > Expert Advisors)");
      return;
   }

   //------------------------------------------------
   // AutoTrade (input) - v1.2.0
   // O input AutoTrade agora e respeitado no OnTick.
   // Antes ele so era checado em CheckTradingConditions(),
   // que nunca era chamada - o robo ignorava o input.
   //------------------------------------------------

   if(!AutoTrade)
   {
      // v1.2.1 - throttle do log: evita inundar o arquivo a cada tick
      if(AllowBlockPrint())
         Print("[TRADE BLOCK] AUTOTRADE OFF | Ative AutoTrade=true no EA");
      return;
   }

   //------------------------------------------------
   // Atualiza horÃ¡rio
   //------------------------------------------------

   //------------------------------------------------
   // Retry de simbolos pendentes (abertura do terminal)
   //------------------------------------------------

   if(SymbolsPending)
   {
      UpdateSymbolManager();
      if(SymbolsPending)
         return;
   }

   LastTick = TimeCurrent();

   //------------------------------------------------
   // Circuit Breaker
   //------------------------------------------------

   CCircuitBreaker::Run();

   if(!CCircuitBreaker::CanTrade())
   {
      if(AllowBlockPrint())
         Print("[TRADE BLOCK] CIRCUIT BREAKER | State=", CCircuitBreaker::GetStateString(), " | Reason=", CCircuitBreaker::GetTriggerReason());
      return;
   }

   //------------------------------------------------
   // Recovery
   //------------------------------------------------

   CRecoveryManager::Run();

   //------------------------------------------------
   // Safety
   //------------------------------------------------

   if(!CSafetyManager::CheckAll())
   {
      if(AllowBlockPrint())
         Print("[TRADE BLOCK] SAFETY | ", CSafetyManager::GetSafetySummary());
      return;
   }

   //------------------------------------------------
   // Equity Protection
   //------------------------------------------------

   if(!CheckEquityProtection())
   {
      if(AllowBlockPrint())
         Print("[TRADE BLOCK] EQUITY PROTECTION");
      return;
   }

   //------------------------------------------------
   // Atualiza Performance
   //------------------------------------------------

   UpdatePerformance();

   //------------------------------------------------
   // Atualiza IA
   //------------------------------------------------

   if(EnableAIFilter)
   {
      UpdateAIStatus();
   }

   //------------------------------------------------
   // Atualiza Dataset
   //------------------------------------------------

   UpdateDataset();

   //------------------------------------------------
   // Scanner Multi Symbol
   //------------------------------------------------

   if(EnableVerboseDebug)
      Print("[TRADE PIPELINE] INICIANDO");

   RunTradePipeline();

   //------------------------------------------------
   // Gerenciamento das posiÃ§Ãµes
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

      //------------------------------------------------
      // v1.2.0 - POSITION SYNC + DATABASE
      //------------------------------------------------

      CSmartExecution::Synchronize();

      if(EnableDatabase)
      {
         int type = 0;
         CDatabaseManager::Connect();

         CDatabaseManager::InsertTrade(
            deal,
            symbol,
            type,
            volume,
            HistoryDealGetDouble(deal, DEAL_PRICE),
            TimeCurrent(),
            TradeComment
         );
      }

      StatisticsRegisterTrade(0.0);

      return;
   }

   //------------------------------------------------
   // SaÃ­da
   //------------------------------------------------

   if(entry == DEAL_ENTRY_OUT)
   {
      //------------------------------------------------
      // Performance
      //------------------------------------------------

      RegisterTradePerformance(profit);

      //------------------------------------------------
      // EstatÃ­sticas
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

      //------------------------------------------------
      // v1.2.0 - POSITION SYNC
      //------------------------------------------------

      CSmartExecution::Synchronize();

      //------------------------------------------------
      // v1.2.0 - TRADE LOGGER
      //------------------------------------------------

      if(tradeLoggerHandle != INVALID_HANDLE)
      {
         // Usa DEAL_TYPE (mais confiavel em DEAL_ENTRY_OUT,
         // pois a posicao pode ja estar fechada).
         ENUM_DEAL_TYPE dealType =
            (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
         bool isBuy = (dealType == DEAL_TYPE_BUY);

         LogTradeCSV(
            isBuy,
            HistoryDealGetDouble(deal, DEAL_PRICE),
            SymbolInfoDouble(symbol, SYMBOL_BID),
            profit,
            AIScore
         );
      }

      //------------------------------------------------
      // v1.2.0 - DATABASE
      //------------------------------------------------

      if(EnableDatabase)
      {
         CDatabaseManager::Connect();

         CDatabaseManager::UpdateTrade(
            deal,
            SymbolInfoDouble(symbol, SYMBOL_BID),
            TimeCurrent(),
            profit,
            HistoryDealGetDouble(deal, DEAL_COMMISSION),
            HistoryDealGetDouble(deal, DEAL_SWAP)
         );
      }

      //------------------------------------------------
      // v1.2.0 - STATISTICS
      //------------------------------------------------

      StatisticsRegisterTrade(profit);
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

   //------------------------------------------------
   // Retry de simbolos pendentes
   //------------------------------------------------

   if(SymbolsPending)
      UpdateSymbolManager();

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
   // AtualizaÃ§Ã£o IA
   //------------------------------------------------

   if(EnableAIFilter)
   {
      UpdateAIStatus();
   }

   //------------------------------------------------
   // Sincronizar posiÃ§Ãµes
   //------------------------------------------------

   CSmartExecution::Synchronize();

   //------------------------------------------------
   // Scheduler (v1.2.0)
   //------------------------------------------------

   if(EnableScheduler)
   {
      CScheduler::Run();
   }

   //------------------------------------------------
   // Atualizar Dashboard
   //------------------------------------------------

   if(EnableDashboard)
   {
      DashboardUpdate();
   }

   //------------------------------------------------
   // Salvar estatÃ­sticas
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

//==================================================
// ON DEINIT
//==================================================

void OnDeinit(
   const int reason
)
{
   Print(
      "========================================"
   );

   Print(
      "XAU_AI_PRO FINALIZANDO"
   );

   Print(
      "Reason=",
      reason
   );

   //================================================
   // PARAR TIMER
   //================================================

   // v1.2.0 - SALVAR RESUMO (win rate) em FILE_COMMON
   StatisticsSaveSummary();

   EventKillTimer();


   //================================================
   // DESABILITAR SISTEMA
   //================================================

   SystemInitialized=false;

   TradingEnabled=false;


   //================================================
   // SHUTDOWN DOS MÓDULOS
   //================================================

   ShutdownModules();


   //================================================
   // LOG FINAL
   //================================================

   Print(
      "XAU_AI_PRO FINALIZADO"
   );

   Print(
      "========================================"
   );
}
