#ifndef TRENDFILTER_MQH
#define TRENDFILTER_MQH

#include "../Core/Config.mqh"

//==================================================
// TREND FILTER PRO
// XAU_AI_PRO
//
// Tendência principal:
// EMA 200 no H1
//
// Compatível com Multi-Symbol
//==================================================

#define TREND_EMA_PERIOD 200

input ENUM_TIMEFRAMES TrendTF = PERIOD_H1;

//==================================================
// HANDLE DO SYMBOL PRINCIPAL
//==================================================

int trendEMAHandle = INVALID_HANDLE;

double trendEMABuffer[];

//==================================================
// INIT
//==================================================

bool InitTrendFilter()
{
   if(trendEMAHandle != INVALID_HANDLE)
   {
      IndicatorRelease(trendEMAHandle);
      trendEMAHandle = INVALID_HANDLE;
   }

   trendEMAHandle = iMA(
      _Symbol,
      TrendTF,
      TREND_EMA_PERIOD,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   if(trendEMAHandle == INVALID_HANDLE)
   {
      Print(
         "[TREND] ERRO criando EMA ",
         TREND_EMA_PERIOD,
         " | Symbol=",
         _Symbol,
         " | TF=",
         EnumToString(TrendTF),
         " | Error=",
         GetLastError()
      );

      return false;
   }

   ArrayResize(trendEMABuffer, 3);
   ArraySetAsSeries(trendEMABuffer, true);

   Print(
      "[TREND] INIT OK | Symbol=",
      _Symbol,
      " | TF=",
      EnumToString(TrendTF),
      " | EMA=",
      TREND_EMA_PERIOD
   );

   return true;
}

//==================================================
// GET EMA - SYMBOL PRINCIPAL
//==================================================

bool GetTrendEMA(double &value)
{
   value = 0.0;

   if(trendEMAHandle == INVALID_HANDLE)
      return false;

   ResetLastError();

   int copied = CopyBuffer(
      trendEMAHandle,
      0,
      0,
      1,
      trendEMABuffer
   );

   if(copied != 1)
   {
      int error = GetLastError();

      Print(
         "[TREND] CopyBuffer falhou | Symbol=",
         _Symbol,
         " | copied=",
         copied,
         " | Error=",
         error
      );

      return false;
   }

   if(trendEMABuffer[0] <= 0.0)
      return false;

   value = trendEMABuffer[0];

   return true;
}

//==================================================
// GET EMA - MULTI SYMBOL
//==================================================

bool GetTrendEMA(double &value, string symbol)
{
   value = 0.0;

   if(symbol == "")
      symbol = _Symbol;

   // Symbol principal usa o handle persistente
   if(symbol == _Symbol)
      return GetTrendEMA(value);

   // Garante que o símbolo esteja disponível
   if(!SymbolSelect(symbol, true))
   {
      Print(
         "[TREND] SymbolSelect falhou | ",
         symbol,
         " | Error=",
         GetLastError()
      );

      return false;
   }

   // Verifica se existe cotação
   double bid = SymbolInfoDouble(
      symbol,
      SYMBOL_BID
   );

   if(bid <= 0.0)
   {
      Print(
         "[TREND] Sem BID válido | ",
         symbol
      );

      return false;
   }

   ResetLastError();

   int handle = iMA(
      symbol,
      TrendTF,
      TREND_EMA_PERIOD,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   if(handle == INVALID_HANDLE)
   {
      Print(
         "[TREND] EMA handle inválido | ",
         symbol,
         " | Error=",
         GetLastError()
      );

      return false;
   }

   double buffer[];

   ArraySetAsSeries(
      buffer,
      true
   );

   ResetLastError();

   int copied = CopyBuffer(
      handle,
      0,
      0,
      1,
      buffer
   );

   bool success = false;

   if(copied == 1 && buffer[0] > 0.0)
   {
      value = buffer[0];
      success = true;
   }
   else
   {
      Print(
         "[TREND] EMA ainda indisponível | ",
         symbol,
         " | copied=",
         copied,
         " | Error=",
         GetLastError()
      );
   }

   IndicatorRelease(handle);

   return success;
}

//==================================================
// PRICE ABOVE EMA
//==================================================

bool PriceAboveTrendEMA(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   double ema = 0.0;

   if(!GetTrendEMA(ema, symbol))
      return false;

   double bid = SymbolInfoDouble(
      symbol,
      SYMBOL_BID
   );

   if(bid <= 0.0)
      return false;

   return (bid > ema);
}

//==================================================
// PRICE BELOW EMA
//==================================================

bool PriceBelowTrendEMA(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   double ema = 0.0;

   if(!GetTrendEMA(ema, symbol))
      return false;

   double bid = SymbolInfoDouble(
      symbol,
      SYMBOL_BID
   );

   if(bid <= 0.0)
      return false;

   return (bid < ema);
}

//==================================================
// TREND BUY
//==================================================

bool TrendBuy(string symbol="")
{
   return PriceAboveTrendEMA(symbol);
}

//==================================================
// TREND SELL
//==================================================

bool TrendSell(string symbol="")
{
   return PriceBelowTrendEMA(symbol);
}

//==================================================
// TREND SIGNAL - CURRENT SYMBOL
//==================================================

int GetTrendSignal()
{
   return GetTrendSignal(_Symbol);
}

//==================================================
// TREND SIGNAL - MULTI SYMBOL
//==================================================

int GetTrendSignal(string symbol)
{
   if(symbol == "")
      symbol = _Symbol;

   if(TrendBuy(symbol))
      return 1;

   if(TrendSell(symbol))
      return -1;

   return 0;
}

//==================================================
// TREND DISTANCE - CURRENT SYMBOL
//==================================================

double GetTrendDistance()
{
   double ema = 0.0;

   if(!GetTrendEMA(ema))
      return 0.0;

   double bid = SymbolInfoDouble(
      _Symbol,
      SYMBOL_BID
   );

   if(bid <= 0.0)
      return 0.0;

   double point = SymbolInfoDouble(
      _Symbol,
      SYMBOL_POINT
   );

   if(point <= 0.0)
      point = _Point;

   return NormalizeDouble(
      MathAbs(bid - ema) / point,
      2
   );
}

//==================================================
// RELEASE
//==================================================

void ReleaseTrendFilter()
{
   if(trendEMAHandle != INVALID_HANDLE)
   {
      IndicatorRelease(
         trendEMAHandle
      );

      trendEMAHandle = INVALID_HANDLE;
   }

   ArrayFree(
      trendEMABuffer
   );

   Print(
      "[TREND] Released"
   );
}

//==================================================
// END
//==================================================

#endif