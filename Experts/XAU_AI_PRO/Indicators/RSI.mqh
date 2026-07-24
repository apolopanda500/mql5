#ifndef RSI_MQH
#define RSI_MQH

#include "../Core/Config.mqh"

//==================================================
// HANDLE
//==================================================

int rsiHandle = INVALID_HANDLE;

//==================================================
// INIT
//==================================================

bool InitRSI()
{
   rsiHandle = iRSI(
      _Symbol,
      PERIOD_CURRENT,
      RSIPeriod,
      PRICE_CLOSE
   );

   return (rsiHandle != INVALID_HANDLE);
}

//==================================================
// RELEASE
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
// GET RSI
//==================================================

double GetRSI()
{
   if(rsiHandle == INVALID_HANDLE)
      return 0.0;

   double buffer[];
   ArraySetAsSeries(buffer,true);

   if(CopyBuffer(rsiHandle,0,0,1,buffer) <= 0)
      return 0.0;

   return buffer[0];
}

//==================================================
// BUY
//==================================================

bool RSI_OK_Buy()
{
   return (GetRSI() < 70.0);
}

//==================================================
// SELL
//==================================================

bool RSI_OK_Sell()
{
   return (GetRSI() > 30.0);
}

#endif