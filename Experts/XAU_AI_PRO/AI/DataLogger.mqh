#ifndef DATALOGGER_MQH
#define DATALOGGER_MQH

#include "../Core/Config.mqh"

#include "../Indicators/VolatilityFilter.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/RSI.mqh"


//==================================================
// DATA LOGGER
// XAU_AI_PRO V1.1
// MULTI SYMBOL
//==================================================

int dataFile=INVALID_HANDLE;


//==================================================
// ESTADO INDEPENDENTE POR SÍMBOLO
//==================================================

string   dlSymbols[];
datetime dlLastClosedBars[];


//==================================================
// LOCALIZAR SÍMBOLO
//==================================================

int DL_FindSymbolIndex(string symbol)
{
   int total=ArraySize(dlSymbols);

   for(int i=0; i<total; i++)
   {
      if(dlSymbols[i]==symbol)
         return i;
   }

   return -1;
}


//==================================================
// CRIAR ESTADO DO SÍMBOLO
//==================================================

int DL_GetOrCreateSymbolIndex(string symbol)
{
   int index=DL_FindSymbolIndex(symbol);

   if(index>=0)
      return index;


   int newSize=ArraySize(dlSymbols)+1;


   if(ArrayResize(dlSymbols,newSize)!=newSize)
   {
      Print(
         "DATA LOGGER | Erro redimensionando símbolos"
      );

      return -1;
   }


   if(ArrayResize(dlLastClosedBars,newSize)!=newSize)
   {
      Print(
         "DATA LOGGER | Erro redimensionando candles"
      );

      return -1;
   }


   index=newSize-1;

   dlSymbols[index]=symbol;
   dlLastClosedBars[index]=0;


   return index;
}


//==================================================
// SPREAD DO CANDLE FECHADO
//==================================================

double DL_GetSpread(
   string symbol,
   ENUM_TIMEFRAMES timeframe,
   int shift
)
{
   long historicalSpread=
      iSpread(
         symbol,
         timeframe,
         shift
      );


   if(historicalSpread>=0)
      return (double)historicalSpread;


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
      return 0.0;
   }


   return(
      (ask-bid)/point
   );
}


//==================================================
// INICIALIZAÇÃO
//==================================================

bool DataLoggerInit()
{
   ArrayFree(dlSymbols);
   ArrayFree(dlLastClosedBars);


   ResetLastError();


   dataFile=
      FileOpen(
         "Data\\dataset.csv",
         FILE_READ |
         FILE_WRITE |
         FILE_CSV |
         FILE_SHARE_READ |
         FILE_SHARE_WRITE,
         ','
      );


   if(dataFile==INVALID_HANDLE)
   {
      Print(
         "DATA LOGGER INIT ERROR | Código=",
         GetLastError()
      );

      return false;
   }


   FileSeek(
      dataFile,
      0,
      SEEK_END
   );


   //================================================
   // CABEÇALHO
   //================================================

   if(FileSize(dataFile)==0)
   {
      FileWrite(
         dataFile,
         "Time",
         "Symbol",
         "Open",
         "High",
         "Low",
         "Close",
         "Volume",
         "Spread",
         "ATR",
         "ADX",
         "RSI"
      );


      FileFlush(dataFile);
   }


   Print(
      "DATA LOGGER MULTI-SYMBOL ONLINE | ",
      "Data\\dataset.csv"
   );


   return true;
}


//==================================================
// SALVAR DADOS DE MERCADO
//==================================================

void SaveMarketData(string symbol="")
{
   if(symbol=="")
      symbol=_Symbol;


   StringTrimLeft(symbol);
   StringTrimRight(symbol);


   if(symbol=="")
      return;


   if(dataFile==INVALID_HANDLE)
   {
      Print(
         "DATA LOGGER | Arquivo não inicializado"
      );

      return;
   }


   if(!SymbolSelect(symbol,true))
   {
      Print(
         "DATA LOGGER | Símbolo indisponível | ",
         symbol
      );

      return;
   }


   ENUM_TIMEFRAMES timeframe=
      PERIOD_CURRENT;


   const int shift=1;


   //================================================
   // CANDLE FECHADO
   //================================================

   datetime closedBarTime=
      iTime(
         symbol,
         timeframe,
         shift
      );


   if(closedBarTime<=0)
      return;


   //================================================
   // ESTADO INDEPENDENTE POR SÍMBOLO
   //================================================

   int symbolIndex=
      DL_GetOrCreateSymbolIndex(
         symbol
      );


   if(symbolIndex<0)
      return;


   if(
      dlLastClosedBars[symbolIndex]
      ==
      closedBarTime
   )
   {
      return;
   }


   //================================================
   // OHLCV
   //================================================

   double open=
      iOpen(
         symbol,
         timeframe,
         shift
      );


   double high=
      iHigh(
         symbol,
         timeframe,
         shift
      );


   double low=
      iLow(
         symbol,
         timeframe,
         shift
      );


   double close=
      iClose(
         symbol,
         timeframe,
         shift
      );


   long volume=
      iVolume(
         symbol,
         timeframe,
         shift
      );


   //================================================
   // VALIDAÇÃO DO CANDLE
   //================================================

   if(
      open<=0.0 ||
      high<=0.0 ||
      low<=0.0 ||
      close<=0.0
   )
   {
      Print(
         "DATA LOGGER | OHLC inválido | ",
         symbol
      );

      return;
   }


   if(
      high<low ||
      high<open ||
      high<close ||
      low>open ||
      low>close
   )
   {
      Print(
         "DATA LOGGER | Estrutura OHLC inválida | ",
         symbol
      );

      return;
   }


   //================================================
   // INDICADORES
   //================================================

   double spread=
      DL_GetSpread(
         symbol,
         timeframe,
         shift
      );


   double atr=
      GetATR(
         symbol
      );


   double adx=
      GetADX(
         symbol
      );


   double rsi=
      GetRSI(
         symbol
      );


   if(
      atr<=0.0 ||
      adx<0.0 ||
      rsi<0.0 ||
      rsi>100.0
   )
   {
      Print(
         "DATA LOGGER | Indicadores inválidos | ",
         symbol,
         " | ATR=",
         DoubleToString(atr,6),
         " | ADX=",
         DoubleToString(adx,2),
         " | RSI=",
         DoubleToString(rsi,2)
      );

      return;
   }


   //================================================
   // GRAVAÇÃO
   //================================================

   FileSeek(
      dataFile,
      0,
      SEEK_END
   );


   uint written=
      FileWrite(
         dataFile,

         TimeToString(
            closedBarTime,
            TIME_DATE |
            TIME_SECONDS
         ),

         symbol,

         open,
         high,
         low,
         close,

         volume,

         spread,

         atr,
         adx,
         rsi
      );


   if(written==0)
   {
      Print(
         "DATA LOGGER WRITE ERROR | ",
         symbol,
         " | Código=",
         GetLastError()
      );

      return;
   }


   FileFlush(dataFile);


   // Atualiza somente depois da gravação correta
   dlLastClosedBars[symbolIndex]=
      closedBarTime;


   Print(
      "DATA LOGGER SAVED | ",
      symbol,
      " | TIME=",
      TimeToString(
         closedBarTime,
         TIME_DATE |
         TIME_SECONDS
      )
   );
}


//==================================================
// FECHAR DATA LOGGER
//==================================================

void DataLoggerClose()
{
   if(dataFile!=INVALID_HANDLE)
   {
      FileFlush(dataFile);
      FileClose(dataFile);

      dataFile=INVALID_HANDLE;
   }


   ArrayFree(dlSymbols);
   ArrayFree(dlLastClosedBars);


   Print(
      "DATA LOGGER OFFLINE"
   );
}


#endif