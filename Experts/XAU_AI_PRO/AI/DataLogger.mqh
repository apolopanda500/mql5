#ifndef DATALOGGER_MQH
#define DATALOGGER_MQH


#include "../Core/Config.mqh"

#include "../Indicators/VolatilityFilter.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/RSI.mqh"

int dataFile = INVALID_HANDLE;


//==================================================

bool DataLoggerInit()

{

   dataFile = FileOpen(
      "Data\\dataset.csv",
      FILE_READ |
      FILE_WRITE |
      FILE_CSV |
      FILE_SHARE_READ |
      FILE_SHARE_WRITE,
      ','
   );


   if(dataFile == INVALID_HANDLE)
   {
      Print("Erro DataLogger: ",GetLastError());
      return false;
   }


   FileSeek(dataFile,0,SEEK_END);



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



   Print("DATA LOGGER V2 ONLINE");


   return true;

}



//==================================================

void SaveMarketData()

{

   static datetime lastBar=0;


   datetime bar=iTime(
      _Symbol,
      PERIOD_CURRENT,
      0
   );


   if(bar==lastBar)
      return;


   lastBar=bar;



   if(dataFile==INVALID_HANDLE)
      return;



   double ask =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );


   double bid =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );


   double spread =
      (ask-bid)/_Point;



   FileSeek(
      dataFile,
      0,
      SEEK_END
   );



   FileWrite(

      dataFile,

      TimeToString(
         iTime(
            _Symbol,
            PERIOD_CURRENT,
            1
         ),
         TIME_DATE|TIME_SECONDS
      ),


      _Symbol,


      iOpen(
         _Symbol,
         PERIOD_CURRENT,
         1
      ),


      iHigh(
         _Symbol,
         PERIOD_CURRENT,
         1
      ),


      iLow(
         _Symbol,
         PERIOD_CURRENT,
         1
      ),


      iClose(
         _Symbol,
         PERIOD_CURRENT,
         1
      ),


      (long)iVolume(
         _Symbol,
         PERIOD_CURRENT,
         1
      ),


      spread,


      GetATR(),

      GetADX(),

      GetRSI()

   );



   FileFlush(dataFile);


}



//==================================================

void DataLoggerClose()

{

   if(dataFile!=INVALID_HANDLE)

   {

      FileClose(dataFile);

      dataFile=INVALID_HANDLE;

   }

}


#endif
