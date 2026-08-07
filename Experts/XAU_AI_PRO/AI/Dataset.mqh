#ifndef DATASET_MQH
#define DATASET_MQH

//==================================================
// XAU_AI_PRO ENTERPRISE DATASET
//==================================================

#define MAX_DATASET        100000
#define MAX_SYMBOL_MEMORY     128

struct TradeData
{
   datetime time;

   string symbol;

   ENUM_TIMEFRAMES timeframe;

   int signal;

   double price;

   double volume;

   double spread;

   double atr;

   double adx;

   double rsi;

   double volatility;

   double trend;

   double ai_score;

   double ai_probability;

   double execution_score;

   double sl;

   double tp;

   double profit;

   bool result;
};

static TradeData Dataset[];

static int DatasetCount=0;
static int LastDatasetIndex=-1;

//==================================================

void DatasetInit()
{
   ArrayResize(Dataset,MAX_DATASET);

   DatasetCount=0;
   LastDatasetIndex=-1;
}

//==================================================

int DatasetNext()
{
   if(DatasetCount>=MAX_DATASET)
      DatasetCount=0;

   return DatasetCount;
}

//==================================================

int AddToDataset(
   string symbol,
   ENUM_TIMEFRAMES tf,
   int signal,
   double price,
   double volume,
   double spread,
   double atr,
   double adx,
   double rsi,
   double volatility,
   double trend,
   double aiScore,
   double aiProb,
   double executionScore,
   double sl,
   double tp
)
{
   int id=DatasetNext();

   Dataset[id].time=TimeCurrent();
   Dataset[id].symbol=symbol;
   Dataset[id].timeframe=tf;

   Dataset[id].signal=signal;

   Dataset[id].price=price;
   Dataset[id].volume=volume;

   Dataset[id].spread=spread;

   Dataset[id].atr=atr;
   Dataset[id].adx=adx;
   Dataset[id].rsi=rsi;

   Dataset[id].volatility=volatility;
   Dataset[id].trend=trend;

   Dataset[id].ai_score=aiScore;
   Dataset[id].ai_probability=aiProb;
   Dataset[id].execution_score=executionScore;

   Dataset[id].sl=sl;
   Dataset[id].tp=tp;

   Dataset[id].profit=0.0;
   Dataset[id].result=false;

   LastDatasetIndex=id;

   DatasetCount++;

   return id;
}

//==================================================

void UpdateDatasetResult(
   int index,
   double profit
)
{
   if(index<0)
      return;

   if(index>=MAX_DATASET)
      return;

   Dataset[index].profit=profit;
   Dataset[index].result=(profit>0);
}

//==================================================

int DatasetTotal()
{
   return DatasetCount;
}

//==================================================

double DatasetWinRate()
{
   if(DatasetCount==0)
      return 0;

   int wins=0;

   for(int i=0;i<DatasetCount;i++)
   {
      if(Dataset[i].result)
         wins++;
   }

   return
      NormalizeDouble(
         (double)wins*100.0/DatasetCount,
         2
      );
}

//==================================================

double DatasetAverageProfit()
{
   if(DatasetCount==0)
      return 0;

   double total=0;

   for(int i=0;i<DatasetCount;i++)
      total+=Dataset[i].profit;

   return NormalizeDouble(total/DatasetCount,2);
}

//==================================================

double DatasetAverageAIScore()
{
   if(DatasetCount==0)
      return 0;

   double total=0;

   for(int i=0;i<DatasetCount;i++)
      total+=Dataset[i].ai_score;

   return NormalizeDouble(total/DatasetCount,2);
}

//==================================================

void ExportDatasetCSV()
{
   int total = MathMin(DatasetCount, MAX_DATASET);

   int file = FileOpen(
      "Data\\trades_dataset.csv",
      FILE_WRITE | FILE_CSV | FILE_ANSI
   );

   if(file == INVALID_HANDLE)
   {
      Print("Erro CSV: ", GetLastError());
      return;
   }

   FileWrite(
      file,
      "Time",
      "Symbol",
      "Timeframe",
      "Signal",
      "Price",
      "Volume",
      "Spread",
      "ATR",
      "ADX",
      "RSI",
      "Volatility",
      "Trend",
      "AIScore",
      "AIProbability",
      "ExecutionScore",
      "SL",
      "TP",
      "Profit",
      "Result"
   );

   for(int i=0; i<total; i++)
   {
      FileWrite(
         file,
         TimeToString(Dataset[i].time, TIME_DATE|TIME_SECONDS),
         Dataset[i].symbol,
         EnumToString(Dataset[i].timeframe),
         Dataset[i].signal,
         Dataset[i].price,
         Dataset[i].volume,
         Dataset[i].spread,
         Dataset[i].atr,
         Dataset[i].adx,
         Dataset[i].rsi,
         Dataset[i].volatility,
         Dataset[i].trend,
         Dataset[i].ai_score,
         Dataset[i].ai_probability,
         Dataset[i].execution_score,
         Dataset[i].sl,
         Dataset[i].tp,
         Dataset[i].profit,
         Dataset[i].result
      );
   }

   FileClose(file);

   Print("Dataset exportado: ", total, " registros");
}

//==================================================

void ClearDataset()
{
   DatasetCount = 0;
   LastDatasetIndex = -1;

   ArrayResize(Dataset, MAX_DATASET);

   for(int i=0; i<MAX_DATASET; i++)
   {
      ZeroMemory(Dataset[i]);
   }
}

#endif