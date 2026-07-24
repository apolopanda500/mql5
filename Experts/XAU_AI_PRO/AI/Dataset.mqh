#ifndef DATASET_MQH
#define DATASET_MQH


//==================================================
// DATA STRUCT (ML READY)
//==================================================

struct TradeData
{
   datetime time;
   string   symbol;
   int      signal;
   double   price;
   double   lot;
   double   spread;
   double   atr;
   double   rsi;
   double   adx;
   double   score;
   bool     result;
};


//==================================================
// CONFIG
//==================================================

#define MAX_DATASET 1000


TradeData dataset[MAX_DATASET];

int datasetIndex = 0;

int LastDatasetIndex = -1;


//==================================================
// SAFE INDEX
//==================================================

int NextIndex()
{
   if(datasetIndex >= MAX_DATASET)
      datasetIndex = 0;

   return datasetIndex;
}


//==================================================
// ADD DATA
//==================================================

int AddToDataset(
   int signal,
   double price,
   double lot,
   double spread,
   double atr,
   double rsi,
   double adx,
   double score
)
{

   int index = NextIndex();


   dataset[index].time   = TimeCurrent();
   dataset[index].symbol = _Symbol;
   dataset[index].signal = signal;
   dataset[index].price  = price;
   dataset[index].lot    = lot;
   dataset[index].spread = spread;
   dataset[index].atr    = atr;
   dataset[index].rsi    = rsi;
   dataset[index].adx    = adx;
   dataset[index].score  = score;
   dataset[index].result = false;


   LastDatasetIndex = index;


   datasetIndex++;


   return index;
}



//==================================================
// UPDATE RESULT
//==================================================

void UpdateDatasetResult(
   int index,
   bool result
)
{

   if(index < 0 || index >= MAX_DATASET)
      return;


   dataset[index].result = result;
}



//==================================================
// TOTAL
//==================================================

int DatasetTotal()
{
   return datasetIndex;
}



//==================================================
// WIN RATE
//==================================================

double GetDatasetWinRate()
{

   int wins = 0;
   int total = 0;


   for(int i=0;i<datasetIndex && i<MAX_DATASET;i++)
   {

      total++;


      if(dataset[i].result)
         wins++;

   }


   if(total==0)
      return 0;


   return NormalizeDouble(
      (double)wins * 100.0 / total,
      2
   );
}



//==================================================
// AVG SCORE
//==================================================

double GetAverageScore()
{

   if(datasetIndex==0)
      return 0;


   double sum=0;


   for(int i=0;i<datasetIndex && i<MAX_DATASET;i++)
      sum += dataset[i].score;


   return NormalizeDouble(
      sum/datasetIndex,
      2
   );
}



//==================================================
// EXPORT CSV
//==================================================

void ExportDatasetCSV()
{

   int file = FileOpen(
   "Data\\trades_dataset.csv",
      FILE_WRITE |
      FILE_CSV
   );


   if(file==INVALID_HANDLE)
   {
      Print("Erro CSV: ",GetLastError());
      return;
   }



   FileWrite(
      file,
      "Time",
      "Symbol",
      "Signal",
      "Price",
      "Lot",
      "Spread",
      "ATR",
      "RSI",
      "ADX",
      "Score",
      "Result"
   );



   for(int i=0;i<datasetIndex && i<MAX_DATASET;i++)
   {

      FileWrite(
         file,
         TimeToString(dataset[i].time),
         dataset[i].symbol,
         dataset[i].signal,
         dataset[i].price,
         dataset[i].lot,
         dataset[i].spread,
         dataset[i].atr,
         dataset[i].rsi,
         dataset[i].adx,
         dataset[i].score,
         dataset[i].result
      );

   }


   FileClose(file);


   Print(
      "Dataset exportado: ",
      datasetIndex,
      " registros"
   );
}



//==================================================
// CLEAR
//==================================================

void ClearDataset()
{

   for(int i=0;i<MAX_DATASET;i++)
   {

      dataset[i].time=0;
      dataset[i].symbol="";
      dataset[i].signal=0;
      dataset[i].price=0;
      dataset[i].lot=0;
      dataset[i].spread=0;
      dataset[i].atr=0;
      dataset[i].rsi=0;
      dataset[i].adx=0;
      dataset[i].score=0;
      dataset[i].result=false;

   }


   datasetIndex=0;
   LastDatasetIndex=-1;

}



#endif