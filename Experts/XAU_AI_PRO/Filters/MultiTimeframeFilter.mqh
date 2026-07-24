#ifndef MULTITIMEFRAMEFILTER_MQH
#define MULTITIMEFRAMEFILTER_MQH


//==================================================
// CONFIG
//==================================================

input ENUM_TIMEFRAMES ConfirmTF1 = PERIOD_M15;

input int MTF_FastEMA = 20;
input int MTF_SlowEMA = 50;


//==================================================
// HANDLES
//==================================================

int mtfFastEMAHandle = INVALID_HANDLE;
int mtfSlowEMAHandle = INVALID_HANDLE;


//==================================================
// BUFFERS
//==================================================

double mtfFastBuffer[];
double mtfSlowBuffer[];


//==================================================
// INIT
//==================================================

bool InitMTF()
{

   mtfFastEMAHandle =
      iMA(
         _Symbol,
         ConfirmTF1,
         MTF_FastEMA,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   mtfSlowEMAHandle =
      iMA(
         _Symbol,
         ConfirmTF1,
         MTF_SlowEMA,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   if(
      mtfFastEMAHandle == INVALID_HANDLE ||
      mtfSlowEMAHandle == INVALID_HANDLE
   )
   {
      Print("Erro criando filtro MTF");
      return false;
   }


   ArraySetAsSeries(
      mtfFastBuffer,
      true
   );


   ArraySetAsSeries(
      mtfSlowBuffer,
      true
   );


   return true;

}


//==================================================
// RELEASE
//==================================================

void ReleaseMTF()
{

   if(mtfFastEMAHandle != INVALID_HANDLE)
   {
      IndicatorRelease(mtfFastEMAHandle);
      mtfFastEMAHandle = INVALID_HANDLE;
   }


   if(mtfSlowEMAHandle != INVALID_HANDLE)
   {
      IndicatorRelease(mtfSlowEMAHandle);
      mtfSlowEMAHandle = INVALID_HANDLE;
   }

}


//==================================================
// UPDATE
//==================================================

bool UpdateMTF()
{

   if(
      mtfFastEMAHandle == INVALID_HANDLE ||
      mtfSlowEMAHandle == INVALID_HANDLE
   )
      return false;



   if(
      CopyBuffer(
         mtfFastEMAHandle,
         0,
         0,
         3,
         mtfFastBuffer
      ) <= 0
   )
      return false;



   if(
      CopyBuffer(
         mtfSlowEMAHandle,
         0,
         0,
         3,
         mtfSlowBuffer
      ) <= 0
   )
      return false;



   return true;

}


//==================================================
// BUY CONFIRMATION
//==================================================

bool ConfirmBuyMTF()
{

   if(!UpdateMTF())
      return false;


   return(
      mtfFastBuffer[0]
      >
      mtfSlowBuffer[0]
   );

}


//==================================================
// SELL CONFIRMATION
//==================================================

bool ConfirmSellMTF()
{

   if(!UpdateMTF())
      return false;


   return(
      mtfFastBuffer[0]
      <
      mtfSlowBuffer[0]
   );

}


//==================================================
// MTF STRENGTH
//==================================================

double GetMTFStrength()
{

   if(!UpdateMTF())
      return 0;


   double distance =
      MathAbs(
         mtfFastBuffer[0]
         -
         mtfSlowBuffer[0]
      )
      /
      _Point;


   if(distance > 300)
      return 100;


   if(distance > 150)
      return 75;


   if(distance > 50)
      return 50;


   return 25;

}


//==================================================
// FINAL FILTER
//==================================================

bool MTFApproved(int signal)
{

   if(signal == 1)
      return ConfirmBuyMTF();


   if(signal == -1)
      return ConfirmSellMTF();


   return false;

}


#endif