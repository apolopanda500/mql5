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
// VALIDATION ENGINE
// XAU_AI_PRO V1.1
// MULTI SYMBOL
//==================================================

bool ValidateTrade(
   string symbol,
   const int signal
)
{
   //================================================
   // BASIC VALIDATION
   //================================================

   if(symbol=="")
      return false;

   if(signal==0)
      return false;


   //================================================
   // SELECT SYMBOL
   //================================================

   if(!SymbolSelect(symbol,true))
   {
      Print(
         "VALIDATION BLOCK | SYMBOL NOT AVAILABLE | ",
         symbol
      );

      return false;
   }


   //================================================
   // SPREAD
   //================================================

   if(EnableSpreadFilter)
   {
      double ask=
         SymbolInfoDouble(
            symbol,
            SYMBOL_ASK
         );

      double bid=
         SymbolInfoDouble(
            symbol,
            SYMBOL_BID
         );

      double point=
         SymbolInfoDouble(
            symbol,
            SYMBOL_POINT
         );

      if(
         ask<=0.0 ||
         bid<=0.0 ||
         point<=0.0
      )
      {
         Print(
            "VALIDATION BLOCK | INVALID PRICE | ",
            symbol
         );

         return false;
      }

      double spread=
         (ask-bid)/point;

      if(spread>MaxSpread)
      {
         Print(
            "VALIDATION BLOCK | SPREAD | ",
            symbol,
            " | Spread=",
            DoubleToString(
               spread,
               2
            ),
            " | Max=",
            DoubleToString(
               MaxSpread,
               2
            )
         );

         return false;
      }
   }


   //================================================
   // SESSION
   //================================================

   if(EnableSessionFilter)
   {
      if(!IsTradingSession())
      {
         Print(
            "VALIDATION BLOCK | SESSION | ",
            symbol
         );

         return false;
      }
   }


   //================================================
   // TREND
   //================================================

   if(EnableTrendFilter)
   {
      if(
         signal==1 &&
         !TrendBuy(symbol)
      )
      {
         Print(
            "VALIDATION BLOCK | TREND BUY | ",
            symbol
         );

         return false;
      }

      if(
         signal==-1 &&
         !TrendSell(symbol)
      )
      {
         Print(
            "VALIDATION BLOCK | TREND SELL | ",
            symbol
         );

         return false;
      }
   }


   //================================================
   // ADX
   // MULTI SYMBOL
   //================================================

   if(EnableADXFilter)
   {
      if(
         !ADX_OK(
            symbol
         )
      )
      {
         Print(
            "VALIDATION BLOCK | ADX | ",
            symbol,
            " | ADX=",
            DoubleToString(
               GetADX(
                  symbol
               ),
               2
            ),
            " | MIN=",
            DoubleToString(
               MinimumADX,
               2
            )
         );

         return false;
      }
   }


   //================================================
   // AI
   // MULTI SYMBOL
   //================================================

   if(EnableAIFilter)
   {
      if(
         !AITradeAllowed(
            symbol
         )
      )
      {
         Print(
            "VALIDATION BLOCK | AI | ",
            symbol
         );

         return false;
      }
   }


   //================================================
   // MULTI TIMEFRAME
   // MULTI SYMBOL
   //================================================

   if(EnableMTFConfirmation)
   {
      if(
         !MTFApproved(
            signal,
            symbol
         )
      )
      {
         Print(
            "VALIDATION BLOCK | MTF | ",
            symbol
         );

         return false;
      }
   }


   //================================================
   // APPROVED
   //================================================

   Print(
      "VALIDATION APPROVED | ",
      symbol,
      " | SIGNAL=",
      signal
   );

   return true;
}


//==================================================
// COMPATIBILITY OVERLOAD
// MANTÉM MÓDULOS ANTIGOS FUNCIONANDO
//==================================================

bool ValidateTrade(
   const int signal
)
{
   return ValidateTrade(
      _Symbol,
      signal
   );
}


#endif