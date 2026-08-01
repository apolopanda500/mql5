#ifndef TRADEPIPELINE_MQH
#define TRADEPIPELINE_MQH

#include "../Core/Config.mqh"
#include "../Core/SymbolManager.mqh"
#include "../Core/MarketScanner.mqh"
#include "../Core/SystemManager.mqh"

//==================================================
// TRADE PIPELINE
// XAU_AI_PRO V1.1
// MULTI SYMBOL
//
// FLUXO:
//
// SystemReady
//      ↓
// AutoTrade
//      ↓
// SymbolManager
//      ↓
// MarketScanner
//      ↓
// Signal
//      ↓
// Validation
//      ↓
// AI
//      ↓
// Execution
//==================================================


//==================================================
// RUN TRADE PIPELINE
//==================================================

void RunTradePipeline()
{
   //================================================
   // SYSTEM CHECK
   //================================================

   if(!IsSystemReady())
   {
      return;
   }


   //================================================
   // AUTO TRADE
   //================================================

   if(!AutoTrade)
   {
      return;
   }


   //================================================
   // TOTAL SYMBOLS
   //================================================

   int total=
      TotalSymbols();


   if(total<=0)
   {
      Print(
         "TRADE PIPELINE | Nenhum símbolo disponível"
      );

      return;
   }


   //================================================
   // PROCESS SYMBOLS
   //================================================

   for(
      int i=0;
      i<total;
      i++
   )
   {
      string symbol=
         GetTradeSymbol(
            i
         );


      if(symbol=="")
         continue;


      //=============================================
      // PROCESS SYMBOL
      //=============================================

      ProcessSymbol(
         symbol
      );
   }
}


//==================================================
// PROCESS SINGLE SYMBOL
// Compatibilidade / uso individual
//==================================================

bool RunTradePipelineSymbol(
   string symbol
)
{
   if(!IsSystemReady())
      return false;


   if(!AutoTrade)
      return false;


   if(symbol=="")
      return false;


   if(!SymbolSelect(
      symbol,
      true
   ))
   {
      return false;
   }


   ProcessSymbol(
      symbol
   );


   return true;
}


#endif