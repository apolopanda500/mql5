#ifndef ADX_MQH
#define ADX_MQH

#include "../Core/Config.mqh"

//==================================================
// HANDLE
//==================================================

int adxHandle = INVALID_HANDLE;

double adxBuffer[];


//==================================================
// INIT
//==================================================

bool InitADX()
{
   adxHandle = iADX(
      _Symbol,
      PERIOD_CURRENT,
      ADXPeriod
   );

   if(adxHandle == INVALID_HANDLE)
      return false;

   ArraySetAsSeries(
      adxBuffer,
      true
   );

   return true;
}


//==================================================
// GET ADX
//==================================================

double GetADX()
{
   if(adxHandle == INVALID_HANDLE)
      return 0.0;


   if(CopyBuffer(
      adxHandle,
      0,
      0,
      1,
      adxBuffer
   ) <= 0)
      return 0.0;


   return adxBuffer[0];
}


//==================================================
// ADX FILTER
//==================================================

bool ADX_OK()
{
   return (
      GetADX() >= MinimumADX
   );
}


//==================================================
// RELEASE
//==================================================

void ReleaseADX()
{
   if(adxHandle != INVALID_HANDLE)
   {
      IndicatorRelease(adxHandle);
      adxHandle = INVALID_HANDLE;
   }
}

#endif