
#ifndef RSI_MQH
#define RSI_MQH

#include "../Core/Config.mqh"

//==================================================
// RSI INDICATOR
// XAU_AI_PRO
// Hardened V1.1
//==================================================

//==================================================
// GLOBAL HANDLE
//==================================================

int rsiHandle = INVALID_HANDLE;

//==================================================
// INITIALIZE RSI
//==================================================

bool InitRSI()
{
   // Evita criar o handle novamente
   if(rsiHandle != INVALID_HANDLE)
   {
      if(BarsCalculated(rsiHandle) >= 0)
         return true;

      IndicatorRelease(rsiHandle);
      rsiHandle = INVALID_HANDLE;
   }

   rsiHandle = iRSI(
      _Symbol,
      PERIOD_CURRENT,
      RSIPeriod,
      PRICE_CLOSE
   );

   if(rsiHandle == INVALID_HANDLE)
   {
      Print(
         "[RSI] INIT ERROR | Symbol=",
         _Symbol,
         " | Period=",
         RSIPeriod,
         " | Error=",
         GetLastError()
      );

      return false;
   }

   Print(
      "[RSI] INIT OK | Symbol=",
      _Symbol,
      " | Period=",
      RSIPeriod
   );

   return true;
}

//==================================================
// RELEASE RSI
//==================================================

void ReleaseRSI()
{
   if(rsiHandle != INVALID_HANDLE)
   {
      IndicatorRelease(rsiHandle);
      rsiHandle = INVALID_HANDLE;
   }
}

//==================================================
// GET RSI — CURRENT SYMBOL
//==================================================

double GetRSI()
{
   if(rsiHandle == INVALID_HANDLE)
      return 0.0;

   if(BarsCalculated(rsiHandle) < 1)
      return 0.0;

   double buffer[1];

   ResetLastError();

   int copied = CopyBuffer(
      rsiHandle,
      0,
      0,
      1,
      buffer
   );

   if(copied != 1)
   {
      return 0.0;
   }

   double value = buffer[0];

   // RSI válido deve estar entre 0 e 100.
   if(value < 0.0 || value > 100.0)
      return 0.0;

   return value;
}

//==================================================
// GET RSI — MULTI SYMBOL
//==================================================

double GetRSI(string symbol)
{
   if(symbol == "")
      return GetRSI();

   if(!SymbolSelect(symbol,true))
      return 0.0;

   int handle = iRSI(
      symbol,
      PERIOD_CURRENT,
      RSIPeriod,
      PRICE_CLOSE
   );

   if(handle == INVALID_HANDLE)
   {
      Print(
         "[RSI] HANDLE ERROR | Symbol=",
         symbol,
         " | Error=",
         GetLastError()
      );

      return 0.0;
   }

   if(BarsCalculated(handle) < 1)
   {
      IndicatorRelease(handle);
      return 0.0;
   }

   double buffer[1];

   ResetLastError();

   int copied = CopyBuffer(
      handle,
      0,
      0,
      1,
      buffer
   );

   double result = 0.0;

   if(copied == 1)
   {
      result = buffer[0];

      if(result < 0.0 || result > 100.0)
         result = 0.0;
   }

   IndicatorRelease(handle);

   return result;
}

//==================================================
// RSI BUY FILTER
//==================================================

bool RSI_OK_Buy()
{
   double rsi = GetRSI();

   if(rsi <= 0.0)
      return false;

   return (rsi < 70.0);
}

//==================================================
// RSI BUY FILTER — MULTI SYMBOL
//==================================================

bool RSI_OK_Buy(string symbol)
{
   double rsi = GetRSI(symbol);

   if(rsi <= 0.0)
      return false;

   return (rsi < 70.0);
}

//==================================================
// RSI SELL FILTER
//==================================================

bool RSI_OK_Sell()
{
   double rsi = GetRSI();

   if(rsi <= 0.0)
      return false;

   return (rsi > 30.0);
}

//==================================================
// RSI SELL FILTER — MULTI SYMBOL
//==================================================

bool RSI_OK_Sell(string symbol)
{
   double rsi = GetRSI(symbol);

   if(rsi <= 0.0)
      return false;

   return (rsi > 30.0);
}

//==================================================
// RSI VALIDATION
//==================================================

bool RSIValid()
{
   double rsi = GetRSI();

   return (
      rsi > 0.0 &&
      rsi < 100.0
   );
}

//==================================================
// END
//==================================================

#endif
