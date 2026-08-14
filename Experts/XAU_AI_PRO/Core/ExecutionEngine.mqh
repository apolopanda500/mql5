#ifndef EXECUTIONENGINE_MQH
#define EXECUTIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Core/OrderManager.mqh"
#include "../Core/RiskEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../Core/TradeController.mqh"
#include "../Management/DailyRisk.mqh"
#include "../AI/AIEngine.mqh"

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

   // Verificar limite diário
   if(!CanTradeToday())
   {
      Print("EXECUTION: Limite diário atingido");
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
      Print("EXECUTION: LOTE INVÁLIDO");
      return false;
   }

   // Ajustar lote baseado na confiança da IA
   double aiConfidence=GetAIConfidence(signal, symbol);
   double lotMultiplier=GetAILotMultiplier(aiConfidence);
   double adjustedLot=lot*lotMultiplier;

   // Normalizar para o step do símbolo
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

   bool result=false;

   switch(signal)
   {
      case 1:
      {
         result=
            OpenBuy(
               symbol,
               lot
            );
         break;
      }

      case -1:
      {
         result=
            OpenSell(
               symbol,
               lot
            );
         break;
      }

      default:
         return false;
   }

   if(result)
   {
      RegisterTrade();
      RegisterDailyTrade();

      Print(
         "TRADE EXECUTADO | ",
         symbol,
         " | SIGNAL=",
         signal,
         " | LOT=",
         DoubleToString(lot,2)
      );
   }
   else
   {
      Print(
         "ERRO EXECUÇÃO | ",
         symbol,
         " | ERROR=",
         GetLastError()
      );
   }

   return result;
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