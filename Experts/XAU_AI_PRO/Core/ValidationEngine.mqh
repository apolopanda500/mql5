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

bool ValidateTrade(const int signal, string symbol="")
{
   // Use passed symbol or fallback to _Symbol
   string sym = (symbol != "") ? symbol : _Symbol;

   //==================================
   // SPREAD
   //==================================

   if(EnableSpreadFilter)
   {
      double point = SymbolInfoDouble(sym, SYMBOL_POINT);
      if(point <= 0)
         point = _Point;

      double spread=
         (SymbolInfoDouble(sym,SYMBOL_ASK)-
          SymbolInfoDouble(sym,SYMBOL_BID))
         /point;

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
      if(!AITradeAllowed(sym))
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