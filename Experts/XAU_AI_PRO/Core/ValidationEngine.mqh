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
      double spread=
         (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-
          SymbolInfoDouble(_Symbol,SYMBOL_BID))
         /_Point;

      if(spread>MaxSpread)
      {
         Print("VALIDATION: SPREAD");
         return false;
      }
   }

   //==================================
   // SESSÃO
   //==================================

   if(EnableSessionFilter)
   {
      if(!IsTradingSession())
      {
         Print("VALIDATION: SESSION");
         return false;
      }
   }

   //==================================
   // TENDÊNCIA
   //==================================

   if(EnableTrendFilter)
   {
      if(signal==1 && !TrendBuy())
      {
         Print("VALIDATION: TREND BUY");
         return false;
      }

      if(signal==-1 && !TrendSell())
      {
         Print("VALIDATION: TREND SELL");
         return false;
      }
   }

   //==================================
   // ADX
   //==================================

   if(EnableADXFilter)
   {
      if(!ADX_OK())
      {
         Print("VALIDATION: ADX");
         return false;
      }
   }

   //==================================
   // IA
   //==================================

   if(EnableAIFilter)
   {
      if(!AITradeAllowed())
      {
         Print("VALIDATION: AI");
         return false;
      }
   }

   //==================================
   // MULTI TIMEFRAME
   //==================================

   if(EnableMTFConfirmation)
   {
      if(!MTFApproved(signal))
      {
         Print("VALIDATION: MTF");
         return false;
      }
   }

   return true;
}

#endif