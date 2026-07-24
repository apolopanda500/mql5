#ifndef AICONNECTOR_MQH
#define AICONNECTOR_MQH


//==================================================
// AI CONNECTOR PYTHON
//==================================================


string AI_Symbol="";
string AI_Signal="";

double AI_Price=0;
double AI_BuyProbability=0;
double AI_SellProbability=0;
double AI_Score=0;



//==================================================
// LOAD PREDICTION
//==================================================

bool LoadAIPrediction()
{

   string fileName=
      "Data\\prediction.json";


   Print(
      "AI TEST FILE: ",
      fileName
   );


   ResetLastError();



   if(!FileIsExist(fileName))
   {

      Print(
         "AI FILE NOT FOUND"
      );

      return false;

   }



   Print(
      "AI FILE FOUND"
   );



   int file=
      FileOpen(
         fileName,
         FILE_READ|
         FILE_TXT|
         FILE_ANSI
      );



   if(file==INVALID_HANDLE)
   {

      Print(
         "AI FILE ERROR: ",
         GetLastError()
      );

      return false;

   }



   string json="";



   while(!FileIsEnding(file))
   {
      json+=FileReadString(file);
   }



   FileClose(file);



   AI_Symbol=
      ExtractJSON(
         json,
         "symbol"
      );



   AI_Signal=
      ExtractJSON(
         json,
         "signal"
      );



   AI_Price=
      StringToDouble(
         ExtractJSON(
            json,
            "price"
         )
      );



   AI_BuyProbability=
      StringToDouble(
         ExtractJSON(
            json,
            "buy"
         )
      );



   AI_SellProbability=
      StringToDouble(
         ExtractJSON(
            json,
            "sell"
         )
      );



   AI_Score=
      StringToDouble(
         ExtractJSON(
            json,
            "score"
         )
      );



   Print(
      "AI PYTHON | ",
      AI_Symbol,
      " | ",
      AI_Signal,
      " | SCORE: ",
      DoubleToString(
         AI_Score,
         2
      )
   );



   return true;

}



//==================================================
// JSON EXTRACT
//==================================================

string ExtractJSON(
   string json,
   string key
)
{

   string search=
      "\"" + key + "\"";


   int start=
      StringFind(
         json,
         search
      );


   if(start<0)
      return "";



   start=
      StringFind(
         json,
         ":",
         start
      );



   if(start<0)
      return "";



   start++;



   while(
      start<StringLen(json) &&
      (
      StringGetCharacter(json,start)==' ' ||
      StringGetCharacter(json,start)=='\"'
      )
   )
   {
      start++;
   }



   int end=start;



   while(
      end<StringLen(json) &&
      StringGetCharacter(json,end)!=',' &&
      StringGetCharacter(json,end)!='}'
   )
   {
      end++;
   }



   string value=
      StringSubstr(
         json,
         start,
         end-start
      );



   StringReplace(
      value,
      "\"",
      ""
   );



   return value;

}



//==================================================
// GETTERS
//==================================================

string GetAISignal()
{
   return AI_Signal;
}



double GetAIScore()
{
   return AI_Score;
}



double GetAIBuy()
{
   return AI_BuyProbability;
}



double GetAISell()
{
   return AI_SellProbability;
}



double GetAIPrice()
{
   return AI_Price;
}



string GetAISymbol()
{
   return AI_Symbol;
}



#endif