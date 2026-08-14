#ifndef SIGNALCORE_MQH
#define SIGNALCORE_MQH

//==================================================
// SIGNAL CORE
//==================================================

int GetSignal()
{
   return GetSignal(_Symbol);
}

//==================================================
// MULTI SYMBOL
//==================================================

int GetSignal(string symbol)
{
   if(symbol=="")
      return 0;

   // Indicadores
   int emaFastHandle=iMA(
      symbol,
      PERIOD_CURRENT,
      50,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   int emaSlowHandle=iMA(
      symbol,
      PERIOD_CURRENT,
      200,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   int signalRSIHandle=iRSI(
      symbol,
      PERIOD_CURRENT,
      14,
      PRICE_CLOSE
   );

   // Valida handles
   if(emaFastHandle==INVALID_HANDLE)
   {
      Print("SIGNAL ERROR: EMA Fast inválido para ", symbol);
      return 0;
   }

   if(emaSlowHandle==INVALID_HANDLE)
   {
      Print("SIGNAL ERROR: EMA Slow inválido para ", symbol);
      IndicatorRelease(emaFastHandle);
      return 0;
   }

   if(signalRSIHandle==INVALID_HANDLE)
   {
      Print("SIGNAL ERROR: RSI inválido para ", symbol);
      IndicatorRelease(emaFastHandle);
      IndicatorRelease(emaSlowHandle);
      return 0;
   }

   double fast[];
   double slow[];
   double rsi[];

   ArrayResize(fast,2);
   ArrayResize(slow,2);
   ArrayResize(rsi,2);

   ArraySetAsSeries(fast,true);
   ArraySetAsSeries(slow,true);
   ArraySetAsSeries(rsi,true);

   // Copiar buffers
   bool copyOK=true;

   if(CopyBuffer(emaFastHandle,0,0,2,fast)<=0)
   {
      Print("SIGNAL ERROR: Falha ao copiar EMA Fast para ", symbol);
      copyOK=false;
   }

   if(CopyBuffer(emaSlowHandle,0,0,2,slow)<=0)
   {
      Print("SIGNAL ERROR: Falha ao copiar EMA Slow para ", symbol);
      copyOK=false;
   }

   if(CopyBuffer(signalRSIHandle,0,0,2,rsi)<=0)
   {
      Print("SIGNAL ERROR: Falha ao copiar RSI para ", symbol);
      copyOK=false;
   }

   // Liberar handles em todos os casos
   IndicatorRelease(emaFastHandle);
   IndicatorRelease(emaSlowHandle);
   IndicatorRelease(signalRSIHandle);

   if(!copyOK)
      return 0;

   // Lógica de sinal
   if(fast[0]>slow[0] && rsi[0]<50.0)
   {
      Print(symbol," SIGNAL BUY");
      return 1;
   }

   if(fast[0]<slow[0] && rsi[0]>50.0)
   {
      Print(symbol," SIGNAL SELL");
      return -1;
   }

   return 0;
}

#endif