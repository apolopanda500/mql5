#ifndef EXECUTIONENGINE_MQH
#define EXECUTIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/OrderManager.mqh"
#include "../Core/RiskEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../Core/TradeController.mqh"
#include "../Core/SymbolValidator.mqh"
#include "../Management/DailyRisk.mqh"
#include "../Management/PortfolioManager.mqh"
#include "../AI/AIEngine.mqh"
#include "../Enterprise/SmartExecution.mqh"
#include "../Enterprise/SimulationEngine.mqh"

//==================================================
// EXECUTION ENGINE
//==================================================

bool ExecuteTrade(string symbol,int signal)
{
   if(symbol=="")
      return false;

   if(signal==0)
      return false;

   if(!CanTrade(symbol))
   {
      Print("EXECUTION FAIL | CanTrade=false | symbol=",symbol);
      Print("  - LastTradeTime=",LastTradeTime," | Now=",TimeCurrent());
      return false;
   }

   if(!CanOpenPosition(symbol))
   {
      Print("EXECUTION FAIL | CanOpenPosition=false | symbol=",symbol);
      return false;
   }

   // Verificar limite diario
   if(!CanTradeToday())
   {
      Print("EXECUTION: Limite diario atingido");
      return false;
   }

   double lot=
      CalculateLotByRisk(
         symbol,
         RiskPercent,
         StopLossPoints
      );

   if(lot<=0)
   {
      Print("EXECUTION: LOTE INVALIDO");
      return false;
   }

   // Ajustar lote baseado na confianca da IA
   double aiConfidence=GetAIConfidence(signal, symbol);
   double lotMultiplier=GetAILotMultiplier(aiConfidence);
   double adjustedLot=lot*lotMultiplier;

   // Normalizar para o step do simbolo
   double step=SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minLot=SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

   if(step>0)
      adjustedLot=MathFloor(adjustedLot/step)*step;
   adjustedLot=MathMax(minLot, adjustedLot);

   Print("EXECUTION: Lote ajustado por IA | Base=", DoubleToString(lot,2),
         " | AI Confidence=", DoubleToString(aiConfidence,2),
         " | Multiplier=", DoubleToString(lotMultiplier,2),
         " | Final=", DoubleToString(adjustedLot,2));

   lot=adjustedLot;

   //------------------------------------------------
   // DELEGAR PARA SMART EXECUTION
   //------------------------------------------------

   ExecRequest req;
   req.symbol  = symbol;
   req.volume  = lot;
   req.magic   = MagicNumber;
   req.comment = TradeComment;

   // Calcular preco de entrada
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;

   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   if(signal == 1) // BUY
   {
      req.type  = ORDER_TYPE_BUY;
      req.price = SymbolInfoDouble(symbol, SYMBOL_ASK);

      if(StopLossPoints > 0)
         req.sl = NormalizeDouble(req.price - (StopLossPoints * point), digits);

      if(TakeProfitPoints > 0)
         req.tp = NormalizeDouble(req.price + (TakeProfitPoints * point), digits);
   }
   else if(signal == -1) // SELL
   {
      req.type  = ORDER_TYPE_SELL;
      req.price = SymbolInfoDouble(symbol, SYMBOL_BID);

      if(StopLossPoints > 0)
         req.sl = NormalizeDouble(req.price + (StopLossPoints * point), digits);

      if(TakeProfitPoints > 0)
         req.tp = NormalizeDouble(req.price - (TakeProfitPoints * point), digits);
   }
   else
   {
      return false;
   }

   if(req.price <= 0.0)
   {
      Print("EXECUTION: PRECO INVALIDO | ", symbol);
      return false;
   }

//------------------------------------------------
   // SIMULATION - Pre-execucao
   // Avalia a operacao antes de envia-la ao broker.
   // Fase de SIMULATION do pipeline v1.2.0.
   //------------------------------------------------
   CSimulationEngine::Init();   // idempotente

   SimulationResult simResult =
      CSimulationEngine::Evaluate(
         symbol,
         req.type,
         lot,
         req.price,
         req.sl,
         req.tp
      );

   if(!CSimulationEngine::ShouldExecute(simResult))
   {
      Print(
         "EXECUTION: SIMULACAO BLOQUEADA | ",
         symbol,
         " | Signal=",
         signal,
         " | Razao=",
         simResult.reason,
         " | Prob=",
         DoubleToString(simResult.probability_success,2),
         " | RR=",
         DoubleToString(simResult.risk_reward,2)
      );

      return false;
   }

   Print(
      "EXECUTION: SIMULACAO APROVADA | ",
      symbol,
      " | Prob=",
      DoubleToString(simResult.probability_success,2),
      " | RR=",
      DoubleToString(simResult.risk_reward,2)
   );
   ulong ticket = 0;
   ExecResult execResult = CSmartExecution::OpenPosition(req, ticket);

   if(execResult == EXEC_SUCCESS)
   {
      RegisterTrade();
      RegisterDailyTrade();

      Print(
         "TRADE EXECUTADO | ",
         symbol,
         " | SIGNAL=",
         signal,
         " | LOT=",
         DoubleToString(lot,2),
         " | Ticket=",
         IntegerToString(ticket)
      );

      return true;
   }
   else
   {
      Print(
         "ERRO EXECUCAO | ",
         symbol,
         " | Signal=",
         signal,
         " | Result=",
         EnumToString(execResult)
      );

      return false;
   }
}

//==================================================
// COMPATIBILIDADE
//==================================================

bool ExecuteTrade(int signal)
{
   return ExecuteTrade(
      _Symbol,
      signal
   );
}

#endif
