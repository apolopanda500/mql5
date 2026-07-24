#ifndef BACKTESTANALYZER_MQH
#define BACKTESTANALYZER_MQH


//==================================================
// BACKTEST ANALYZER PRO
//==================================================


int btFile = INVALID_HANDLE;



//==================================================
// INIT
//==================================================

bool BacktestInit()
{

   if(btFile != INVALID_HANDLE)
      FileClose(btFile);



   btFile =
      FileOpen(
         "BacktestReport.csv",
         FILE_COMMON |
         FILE_WRITE |
         FILE_CSV |
         FILE_ANSI
      );



   if(btFile == INVALID_HANDLE)
   {

      Print(
         "Erro BacktestReport.csv | Code: ",
         GetLastError()
      );


      return false;

   }



   FileWrite(
      btFile,
      "Time",
      "Symbol",
      "Signal",
      "Price",
      "Lot",
      "Spread",
      "ATR",
      "ADX",
      "RSI",
      "AI",
      "Result"
   );


   FileFlush(btFile);


   return true;

}



//==================================================
// LOG TRADE
//==================================================

void BacktestLog(
   int signal,
   double price,
   double lot,
   double spread,
   double atr,
   double adx,
   double rsi,
   double aiScore,
   string result
)
{


   if(btFile == INVALID_HANDLE)
      return;



   string sig = "NONE";


   if(signal == 1)
      sig = "BUY";


   if(signal == -1)
      sig = "SELL";



   FileSeek(
      btFile,
      0,
      SEEK_END
   );



   FileWrite(
      btFile,

      TimeToString(
         TimeCurrent(),
         TIME_DATE |
         TIME_SECONDS
      ),

      _Symbol,

      sig,

      DoubleToString(
         price,
         _Digits
      ),

      DoubleToString(
         lot,
         2
      ),

      DoubleToString(
         spread,
         1
      ),

      DoubleToString(
         atr,
         _Digits
      ),

      DoubleToString(
         adx,
         2
      ),

      DoubleToString(
         rsi,
         2
      ),

      DoubleToString(
         aiScore,
         2
      ),

      result
   );


   FileFlush(btFile);

}



//==================================================
// CLOSE
//==================================================

void BacktestClose()
{

   if(btFile != INVALID_HANDLE)
   {

      FileClose(btFile);

      btFile = INVALID_HANDLE;

   }

}



#endif