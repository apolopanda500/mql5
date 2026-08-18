// XAU_AI_PRO v1.2.0
#ifndef BACKTESTANALYZER_MQH
#define BACKTESTANALYZER_MQH

//==================================================
// XAU_AI_PRO — BACKTEST ANALYZER PRO
//==================================================

int btFile = INVALID_HANDLE;

bool BacktestReady = false;
ulong BacktestTrades = 0;
ulong BacktestWins = 0;
ulong BacktestLosses = 0;

double BacktestProfit = 0.0;


//==================================================
// INIT
//==================================================

bool BacktestInit()
{
   if(btFile != INVALID_HANDLE)
   {
      FileClose(btFile);
      btFile = INVALID_HANDLE;
   }

   BacktestReady = false;

   BacktestTrades = 0;
   BacktestWins = 0;
   BacktestLosses = 0;

   BacktestProfit = 0.0;


   btFile = FileOpen(
      "BacktestReport.csv",
      FILE_COMMON |
      FILE_READ |
      FILE_WRITE |
      FILE_CSV |
      FILE_ANSI |
      FILE_SHARE_READ |
      FILE_SHARE_WRITE
   );


   if(btFile == INVALID_HANDLE)
   {
      Print(
         "BACKTEST ERROR | Code=",
         GetLastError()
      );

      return false;
   }


   FileSeek(
      btFile,
      0,
      SEEK_END
   );


   if(FileSize(btFile) == 0)
   {
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
         "Result",
         "Profit"
      );

      FileFlush(btFile);
   }


   BacktestReady = true;


   Print(
      "BACKTEST ANALYZER | Inicializado"
   );


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
   if(!BacktestReady)
      return;


   if(btFile == INVALID_HANDLE)
      return;


   string sig = "NONE";


   if(signal == 1)
      sig = "BUY";


   if(signal == -1)
      sig = "SELL";


   double profit = 0.0;


   if(result == "WIN")
      BacktestWins++;


   if(result == "LOSS")
      BacktestLosses++;


   BacktestTrades++;


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

      result,

      DoubleToString(
         profit,
         2
      )
   );


   FileFlush(
      btFile
   );
}


//==================================================
// LOG TRADE COM PROFIT
//==================================================

void BacktestLogResult(
   int signal,
   double price,
   double lot,
   double spread,
   double atr,
   double adx,
   double rsi,
   double aiScore,
   string result,
   double profit
)
{
   if(!BacktestReady)
      return;


   if(btFile == INVALID_HANDLE)
      return;


   string sig = "NONE";


   if(signal == 1)
      sig = "BUY";


   if(signal == -1)
      sig = "SELL";


   BacktestTrades++;


   if(profit > 0.0)
      BacktestWins++;
   else
   if(profit < 0.0)
      BacktestLosses++;


   BacktestProfit += profit;


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

      DoubleToString(price,_Digits),

      DoubleToString(lot,2),

      DoubleToString(spread,1),

      DoubleToString(atr,_Digits),

      DoubleToString(adx,2),

      DoubleToString(rsi,2),

      DoubleToString(aiScore,2),

      result,

      DoubleToString(profit,2)
   );


   FileFlush(
      btFile
   );
}


//==================================================
// WIN RATE
//==================================================

double BacktestWinRate()
{
   if(BacktestTrades == 0)
      return 0.0;


   return NormalizeDouble(
      ((double)BacktestWins * 100.0)
      /
      (double)BacktestTrades,
      2
   );
}


//==================================================
// TOTAL TRADES
//==================================================

ulong BacktestTotalTrades()
{
   return BacktestTrades;
}


//==================================================
// TOTAL WINS
//==================================================

ulong BacktestTotalWins()
{
   return BacktestWins;
}


//==================================================
// TOTAL LOSSES
//==================================================

ulong BacktestTotalLosses()
{
   return BacktestLosses;
}


//==================================================
// TOTAL PROFIT
//==================================================

double BacktestTotalProfit()
{
   return NormalizeDouble(
      BacktestProfit,
      2
   );
}


//==================================================
// STATUS
//==================================================

bool BacktestIsReady()
{
   return(
      BacktestReady &&
      btFile != INVALID_HANDLE
   );
}


//==================================================
// CLOSE
//==================================================

void BacktestClose()
{
   if(btFile != INVALID_HANDLE)
   {
      FileFlush(btFile);

      FileClose(btFile);

      btFile = INVALID_HANDLE;
   }


   BacktestReady = false;


   Print(
      "BACKTEST ANALYZER | Finalizado | ",
      "Trades=",
      BacktestTrades,
      " | Wins=",
      BacktestWins,
      " | Losses=",
      BacktestLosses,
      " | WinRate=",
      DoubleToString(
         BacktestWinRate(),
         2
      ),
      "% | Profit=",
      DoubleToString(
         BacktestProfit,
         2
      )
   );
}


#endif