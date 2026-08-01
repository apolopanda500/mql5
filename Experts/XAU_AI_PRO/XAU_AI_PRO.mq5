#property strict
#property version "1.10"

#include <Trade/Trade.mqh>

CTrade trade;

datetime lastDatasetCandle = 0;


//==================================================
// CONFIG
//==================================================
#include "Core/Config.mqh"


//==================================================
// INDICADORES
//==================================================
#include "Indicators/TrendStrength.mqh"
#include "Indicators/RSI.mqh"
#include "Indicators/VolatilityFilter.mqh"
#include "Indicators/ADX.mqh"


//==================================================
// FILTROS
//==================================================
#include "Filters/SpreadFilter.mqh"
#include "Filters/SessionFilter.mqh"
#include "Filters/TrendFilter.mqh"
#include "Filters/MultiTimeframeFilter.mqh"
#include "Filters/NewsFilter.mqh"


//==================================================
// IA
//==================================================
#include "AI/AIClient.mqh"
#include "AI/AIEngine.mqh"
#include "AI/Dataset.mqh"
#include "AI/AdaptiveWeights.mqh"
#include "AI/DataLogger.mqh"
#include "AI/AIConnector.mqh"


//==================================================
// CORE
//==================================================

#include "Core/RiskEngine.mqh"
#include "Core/SignalCore.mqh"
#include "Core/DecisionEngine.mqh"
#include "Core/ValidationEngine.mqh"
#include "Core/ExecutionEngine.mqh"
#include "Core/OrderManager.mqh"
#include "Core/PositionManager.mqh"
#include "Core/SymbolValidator.mqh"
#include "Core/PerformanceAnalyzer.mqh"
#include "Core/SymbolManager.mqh"
#include "Core/MarketScanner.mqh"
#include "Core/BrokerConfig.mqh"
#include "Core/TimeFrameManager.mqh"
#include "Core/PathManager.mqh"
#include "Core/BrokerInfo.mqh"
#include "Core/EnvironmentManager.mqh"
#include "Core/CompatibilityManager.mqh"
#include "Core/SystemManager.mqh"
#include "Core/TradePipeline.mqh"



//==================================================
// MANAGEMENT
//==================================================
#include "Management/BreakEven.mqh"
#include "Management/DailyRisk.mqh"
#include "Management/EquityProtection.mqh"


//==================================================
// MONITORING
//==================================================
#include "Monitoring/Dashboard.mqh"
#include "Monitoring/TradeLogger.mqh"


//==================================================
// UTILS
//==================================================
#include "Utils.mqh"



//==================================================
// PROCESS CLOSED TRADES
//==================================================
void ProcessClosedTrades()
{
   static ulong lastTicket = 0;

   if(!HistorySelect(0, TimeCurrent()))
      return;

   int total = HistoryDealsTotal();

   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);

      if(ticket == 0)
         continue;

      if(ticket == lastTicket)
         break;

      ENUM_DEAL_ENTRY entry =
         (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);

      if(entry != DEAL_ENTRY_OUT)
         continue;

      double profit =
         HistoryDealGetDouble(ticket, DEAL_PROFIT);

      string dealSymbol =
         HistoryDealGetString(ticket, DEAL_SYMBOL);

      RegisterTradePerformance(profit);

      if(EnableDataset)
      {
         UpdateDatasetResult(
            LastDatasetIndex,
            (profit > 0)
         );
      }

      // Feedback loop da IA: registrar resultado do trade
      if(EnableAIFilter)
      {
         double aiConfidence=GetAIConfidence(
            (profit > 0) ? 1 : -1,
            dealSymbol
         );
         LogAIFeedback(dealSymbol, 0, profit, aiConfidence);
      }

      lastTicket = ticket;

      break;
   }
}


//==============================
// ONINIT
//==============================

int OnInit()
{

   Print(
   "TESTER PATH: ",
   TerminalInfoString(TERMINAL_DATA_PATH)
   );

   Print("========================================");
   Print("  XAU_AI_PRO v1.10 - DEBUG MODE");
   Print("========================================");
   Print("Symbolo atual: ", _Symbol);
   Print("Conta: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("Corretora: ", AccountInfoString(ACCOUNT_COMPANY));
   Print("Servidor: ", AccountInfoString(ACCOUNT_SERVER));
   Print("Saldo: ", AccountInfoDouble(ACCOUNT_BALANCE));
   Print("Moeda: ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("========================================");
   Print("");

   Print("Inicializando XAU_AI_PRO");


   trade.SetExpertMagicNumber(
      MagicNumber
   );


   trade.SetDeviationInPoints(
      Slippage
   );
   
   InitOrderManager();

   if(!InitSystem())
{
   Print("ERRO INIT SYSTEM");
   return INIT_FAILED;
}


    if(!InitATR())
       Print("AVISO: InitATR falhou");

    if(!InitADX())
       Print("AVISO: InitADX falhou");

    if(!InitRSI())
       Print("AVISO: InitRSI falhou");

    if(!InitTrendFilter())
       Print("AVISO: InitTrendFilter falhou");

    if(!InitMTF())
       Print("AVISO: InitMTF falhou");
    
    if(!InitSymbolManager())
    {
       Print("ERRO SYMBOL MANAGER");
       return INIT_FAILED;
    }


    AIClientInit();


    InitDailyRisk();


    PerformanceInit();
    

    if(!DataLoggerInit())
    {
       Print("AVISO: DataLoggerInit falhou - continuando sem dataset");
    }
    else
    {
       Print("DATA LOGGER OK");
    }


   Print("XAU_AI_PRO iniciado");


   return INIT_SUCCEEDED;


}



//==============================
// ONTICK
//==============================

void OnTick()
{
   // Proteção de equity - verifica antes de tudo
   if(!CheckEquityProtection())
      return;

   ProcessClosedTrades();

   RunTradePipeline();

   ManagePositions();

   if(EnableDataset)
   {
      datetime candle=iTime(_Symbol,PERIOD_CURRENT,0);

      if(candle!=lastDatasetCandle)
      {
         lastDatasetCandle=candle;

         // Salvar dados de todos os símbolos do pipeline
         int total=TotalSymbols();
         for(int i=0;i<total;i++)
         {
            string sym=GetTradeSymbol(i);
            if(sym!="")
               SaveMarketData(sym);
         }
      }
   }

   DashboardUpdate();
}



//==============================
// DEINIT
//==============================

void OnDeinit(const int reason)
{


   ReleaseTrendFilter();

   ReleaseATR();

   ReleaseADX();

   ReleaseRSI();

   ReleaseMTF();
   
   ShutdownSystem();


   DataLoggerClose();


   AIClientShutdown();


   Print(
      "XAU_AI_PRO finalizado"
   );


}
