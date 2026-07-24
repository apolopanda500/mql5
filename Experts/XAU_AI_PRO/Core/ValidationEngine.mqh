#ifndef VALIDATIONENGINE_MQH
#define VALIDATIONENGINE_MQH

#include "../Core/Config.mqh"
#include "../Filters/SpreadFilter.mqh"
#include "../Filters/SessionFilter.mqh"
#include "../Filters/TrendFilter.mqh"
#include "../Filters/MultiTimeframeFilter.mqh"
#include "../Indicators/ADX.mqh"
#include "../AI/AIEngine.mqh"

//==================================================
// VALIDAÇÃO FINAL
//==================================================

bool ValidateTrade(const int signal)
{
   //==================================
   // SPREAD
   //==================================

   if(EnableSpreadFilter)
   {
      double spread =
         (SymbolInfoDouble(_Symbol,SYMBOL_ASK) -
          SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;

      if(spread > MaxSpread)
         return false;
   }

   //==================================
   // SESSÃO
   //==================================

   if(EnableSessionFilter)
   {
      if(!IsTradingSession())
         return false;
   }

   //==================================
   // TENDÊNCIA
   //==================================

   if(EnableTrendFilter)
   {
      if(signal==1 && !TrendBuy())
         return false;

      if(signal==-1 && !TrendSell())
         return false;
   }

   //==================================
   // ADX
   //==================================

   if(EnableADXFilter)
   {
      if(!ADX_OK())
         return false;
   }

   //==================================
   // IA
   //==================================

   if(EnableAIFilter)
   {
      if(!AITradeAllowed())
         return false;
   }

   //==================================
   // MULTI TIMEFRAME
   //==================================

   if(EnableMTFConfirmation)
   {
      if(!MTFApproved(signal))
         return false;
   }

   return true;
}

#endif