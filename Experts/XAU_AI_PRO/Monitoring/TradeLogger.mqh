#ifndef TRADELOGGER_MQH
#define TRADELOGGER_MQH


#include "../Indicators/VolatilityFilter.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/RSI.mqh"


//==================================================
// TRADE LOGGER ENGINE
//==================================================

int tradeLoggerHandle = INVALID_HANDLE;



//==================================================
// INIT
//==================================================

bool InitTradeLogger()
{

   tradeLoggerHandle = FileOpen(
      "trade_history.csv",
      FILE_COMMON |
      FILE_CSV |
      FILE_READ |
      FILE_WRITE |
      FILE_ANSI
   );


   if(tradeLoggerHandle == INVALID_HANDLE)
   {

      Print(
         "Erro TradeLogger: ",
         GetLastError()
      );

      return false;

   }



   if(FileSize(tradeLoggerHandle)==0)
   {

      FileWrite(
         tradeLoggerHandle,
         "Time",
         "Symbol",
         "Type",
         "Entry",
         "Exit",
         "Profit",
         "ATR",
         "ADX",
         "RSI",
         "AI"
      );


      FileFlush(tradeLoggerHandle);

   }


   return true;

}



//==================================================
// LOG TRADE
//==================================================

void LogTrade(
   bool isBuy,
   double entry,
   double exit,
   double profit,
   double aiScore
)
{


   if(tradeLoggerHandle==INVALID_HANDLE)
      return;



   FileSeek(
      tradeLoggerHandle,
      0,
      SEEK_END
   );



   FileWrite(
      tradeLoggerHandle,

      TimeToString(
         TimeCurrent(),
         TIME_DATE|TIME_SECONDS
      ),

      _Symbol,

      (isBuy ? "BUY":"SELL"),

      DoubleToString(
         entry,
         _Digits
      ),

      DoubleToString(
         exit,
         _Digits
      ),

      DoubleToString(
         profit,
         2
      ),

      DoubleToString(
         GetATR(),
         _Digits
      ),

      DoubleToString(
         GetADX(),
         2
      ),

      DoubleToString(
         GetRSI(),
         2
      ),

      DoubleToString(
         aiScore,
         2
      )
   );



   FileFlush(tradeLoggerHandle);

}



//==================================================
// CLOSE
//==================================================

void CloseTradeLogger()
{

   if(tradeLoggerHandle!=INVALID_HANDLE)
   {

      FileClose(tradeLoggerHandle);

      tradeLoggerHandle=INVALID_HANDLE;

   }

}


#endif
