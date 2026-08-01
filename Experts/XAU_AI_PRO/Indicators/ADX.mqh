#ifndef ADX_MQH
#define ADX_MQH

#include "../Core/Config.mqh"

//==================================================
// ADX INDICATOR
// XAU_AI_PRO V1.1
// MULTI SYMBOL
//==================================================


//==================================================
// GLOBAL HANDLE
// Compatibilidade com o símbolo principal
//==================================================

int adxHandle=INVALID_HANDLE;


//==================================================
// GLOBAL BUFFER
//==================================================

double adxBuffer[];


//==================================================
// INIT ADX
//==================================================

bool InitADX()
{
   adxHandle=
      iADX(
         _Symbol,
         PERIOD_CURRENT,
         ADXPeriod
      );


   if(
      adxHandle==
      INVALID_HANDLE
   )
   {
      Print(
         "ADX INIT ERROR | ",
         _Symbol
      );

      return false;
   }


   ArrayResize(
      adxBuffer,
      2
   );


   ArraySetAsSeries(
      adxBuffer,
      true
   );


   Print(
      "ADX INIT OK | ",
      _Symbol,
      " | Period=",
      ADXPeriod
   );


   return true;
}


//==================================================
// GET ADX - CURRENT SYMBOL
//==================================================

double GetADX()
{
   if(
      adxHandle==
      INVALID_HANDLE
   )
   {
      return 0.0;
   }


   if(
      CopyBuffer(
         adxHandle,
         0,
         0,
         1,
         adxBuffer
      )<=0
   )
   {
      return 0.0;
   }


   return adxBuffer[0];
}


//==================================================
// GET ADX - MULTI SYMBOL
//==================================================

double GetADX(
   string symbol
)
{
   if(symbol=="")
      return GetADX();


   if(
      !SymbolSelect(
         symbol,
         true
      )
   )
   {
      Print(
         "ADX SYMBOL ERROR | ",
         symbol
      );

      return 0.0;
   }


   int handle=
      iADX(
         symbol,
         PERIOD_CURRENT,
         ADXPeriod
      );


   if(
      handle==
      INVALID_HANDLE
   )
   {
      Print(
         "ADX HANDLE ERROR | ",
         symbol
      );

      return 0.0;
   }


   double buffer[];


   ArrayResize(
      buffer,
      2
   );


   ArraySetAsSeries(
      buffer,
      true
   );


   double result=0.0;


   if(
      CopyBuffer(
         handle,
         0,
         0,
         1,
         buffer
      )>0
   )
   {
      result=
         buffer[0];
   }


   IndicatorRelease(
      handle
   );


   return result;
}


//==================================================
// ADX FILTER - CURRENT SYMBOL
//==================================================

bool ADX_OK()
{
   double adx=
      GetADX();


   return(
      adx>=MinimumADX
   );
}


//==================================================
// ADX FILTER - MULTI SYMBOL
//==================================================

bool ADX_OK(
   string symbol
)
{
   if(symbol=="")
      symbol=_Symbol;


   double adx=
      GetADX(
         symbol
      );


   if(adx<=0.0)
   {
      Print(
         "ADX INVALID | ",
         symbol
      );

      return false;
   }


   return(
      adx>=MinimumADX
   );
}


//==================================================
// ADX STRENGTH
//==================================================

double GetADXStrength(
   string symbol=""
)
{
   if(symbol=="")
      symbol=_Symbol;


   double adx=
      GetADX(
         symbol
      );


   if(adx<=0.0)
      return 0.0;


   if(adx>=40.0)
      return 100.0;


   if(adx>=30.0)
      return 80.0;


   if(adx>=25.0)
      return 65.0;


   if(adx>=MinimumADX)
      return 50.0;


   if(adx>=MinimumADX*0.8)
      return 30.0;


   return 0.0;
}


//==================================================
// RELEASE ADX
//==================================================

void ReleaseADX()
{
   if(
      adxHandle!=
      INVALID_HANDLE
   )
   {
      IndicatorRelease(
         adxHandle
      );

      adxHandle=
         INVALID_HANDLE;
   }


   ArrayFree(
      adxBuffer
   );
}


//==================================================
// END
//==================================================

#endif