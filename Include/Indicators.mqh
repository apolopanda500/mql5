#include <Config.mqh>
//+------------------------------------------------------------------+
#ifndef __INDICATORS_MQH__
#define __INDICATORS_MQH__

//============================
// HANDLES
//============================
int emaFastHandle;
int emaSlowHandle;
int rsiHandle;
int atrHandle;

//============================
// BUFFERS
//============================
double emaFast[];
double emaSlow[];
double rsi[];
double atr[];

//============================
// INICIALIZA INDICADORES
//============================
bool InitIndicators()
{
   emaFastHandle = iMA(_Symbol,_Period,EMA_Fast,0,MODE_EMA,PRICE_CLOSE);
   emaSlowHandle = iMA(_Symbol,_Period,EMA_Slow,0,MODE_EMA,PRICE_CLOSE);

   rsiHandle = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);

   atrHandle = iATR(_Symbol,_Period,ATR_Period);

   if(emaFastHandle==INVALID_HANDLE) return(false);
   if(emaSlowHandle==INVALID_HANDLE) return(false);
   if(rsiHandle==INVALID_HANDLE) return(false);
   if(atrHandle==INVALID_HANDLE) return(false);

   ArraySetAsSeries(emaFast,true);
   ArraySetAsSeries(emaSlow,true);
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(atr,true);

   return(true);
}

//============================
// ATUALIZA INDICADORES
//============================
bool UpdateIndicators()
{
   if(CopyBuffer(emaFastHandle,0,0,3,emaFast)<=0)
      return(false);

   if(CopyBuffer(emaSlowHandle,0,0,3,emaSlow)<=0)
      return(false);

   if(CopyBuffer(rsiHandle,0,0,3,rsi)<=0)
      return(false);

   if(CopyBuffer(atrHandle,0,0,3,atr)<=0)
      return(false);

   return(true);
}

//============================
// FINALIZA
//============================
void ReleaseIndicators()
{
   IndicatorRelease(emaFastHandle);
   IndicatorRelease(emaSlowHandle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(atrHandle);
}

#endif