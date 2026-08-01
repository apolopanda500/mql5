#ifndef AICONNECTOR_MQH
#define AICONNECTOR_MQH

//==================================================
// AI CONNECTOR
// XAU_AI_PRO V1.1
// MULTI SYMBOL
//==================================================

//==================================================
// GLOBAL AI STATE
// Compatibilidade com módulos antigos
//==================================================

string AI_Symbol="";
string AI_Signal="";

double AI_Price=0.0;
double AI_BuyProbability=0.0;
double AI_SellProbability=0.0;
double AI_Score=0.0;
double AI_Confidence=0.0;


//==================================================
// RESET GLOBAL STATE
//==================================================

void ResetAIState()
{
   AI_Symbol="";
   AI_Signal="";

   AI_Price=0.0;
   AI_BuyProbability=0.0;
   AI_SellProbability=0.0;
   AI_Score=0.0;
   AI_Confidence=0.0;
}


//==================================================
// LOAD AI PREDICTION
//==================================================

bool LoadAIPrediction(string symbol="")
{
   if(symbol=="")
      symbol=_Symbol;

   StringTrimLeft(symbol);
   StringTrimRight(symbol);

   if(symbol=="")
      return false;

   string fileName=
      "Data\\prediction_" +
      symbol +
      ".json";


   Print(
      "AI LOAD | SYMBOL=",
      symbol,
      " | FILE=",
      fileName
   );


   ResetLastError();


   if(!FileIsExist(fileName))
   {
      Print(
         "AI FILE NOT FOUND | ",
         fileName
      );

      return false;
   }


   int file=
      FileOpen(
         fileName,
         FILE_READ |
         FILE_TXT |
         FILE_ANSI
      );


   if(file==INVALID_HANDLE)
   {
      Print(
         "AI FILE ERROR | ",
         symbol,
         " | ERROR=",
         GetLastError()
      );

      return false;
   }


   string json="";


   while(!FileIsEnding(file))
   {
      string line=
         FileReadString(file);

      json+=line;
   }


   FileClose(file);


   if(json=="")
   {
      Print(
         "AI JSON EMPTY | ",
         symbol
      );

      return false;
   }


   //================================================
   // EXTRACT
   //================================================

   string jsonSymbol=
      ExtractJSON(
         json,
         "symbol"
      );


   string jsonSignal=
      ExtractJSON(
         json,
         "signal"
      );


   string jsonPrice=
      ExtractJSON(
         json,
         "price"
      );


   string jsonBuy=
      ExtractJSON(
         json,
         "buy"
      );


   string jsonSell=
      ExtractJSON(
         json,
         "sell"
      );


   string jsonScore=
      ExtractJSON(
         json,
         "score"
      );


   string jsonConfidence=
      ExtractJSON(
         json,
         "confidence"
      );


   //================================================
   // VALIDATE
   //================================================

   if(jsonSymbol=="")
   {
      Print(
         "AI INVALID JSON SYMBOL | ",
         symbol
      );

      return false;
   }


   if(jsonSignal=="")
   {
      Print(
         "AI INVALID JSON SIGNAL | ",
         symbol
      );

      return false;
   }


   //================================================
   // SYMBOL CHECK
   //================================================

   if(
      StringCompare(
         jsonSymbol,
         symbol
      )!=0
   )
   {
      Print(
         "AI SYMBOL MISMATCH | REQUEST=",
         symbol,
         " | JSON=",
         jsonSymbol
      );

      return false;
   }


   //================================================
   // UPDATE GLOBAL STATE
   //================================================

   AI_Symbol=
      jsonSymbol;


   AI_Signal=
      jsonSignal;


   AI_Price=
      StringToDouble(
         jsonPrice
      );


   AI_BuyProbability=
      StringToDouble(
         jsonBuy
      );


   AI_SellProbability=
      StringToDouble(
         jsonSell
      );


   AI_Score=
      StringToDouble(
         jsonScore
      );


   AI_Confidence=
      StringToDouble(
         jsonConfidence
      );


   //================================================
   // COMPATIBILITY
   // Se confidence não existir, usa score
   //================================================

   if(AI_Confidence<=0.0)
      AI_Confidence=AI_Score;


   Print(
      "AI PYTHON | ",
      AI_Symbol,
      " | ",
      AI_Signal,
      " | PRICE=",
      DoubleToString(
         AI_Price,
         _Digits
      ),
      " | BUY=",
      DoubleToString(
         AI_BuyProbability,
         2
      ),
      "%",
      " | SELL=",
      DoubleToString(
         AI_SellProbability,
         2
      ),
      "%",
      " | SCORE=",
      DoubleToString(
         AI_Score,
         2
      ),
      " | CONF=",
      DoubleToString(
         AI_Confidence,
         2
      ),
      "%"
   );


   return true;
}


//==================================================
// EXTRACT JSON VALUE
//==================================================

string ExtractJSON(
   string json,
   string key
)
{
   string search=
      "\"" +
      key +
      "\"";


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


   int length=
      StringLen(
         json
      );


   while(
      start<length
   )
   {
      int ch=
         StringGetCharacter(
            json,
            start
         );


      if(
         ch==' ' ||
         ch=='\t' ||
         ch=='\r' ||
         ch=='\n' ||
         ch=='"'
      )
      {
         start++;
      }
      else
      {
         break;
      }
   }


   bool quoted=false;


   if(
      start<length &&
      StringGetCharacter(
         json,
         start
      )=='"'
   )
   {
      quoted=true;
      start++;
   }


   int end=start;


   if(quoted)
   {
      while(
         end<length &&
         StringGetCharacter(
            json,
            end
         )!='"'
      )
      {
         end++;
      }
   }
   else
   {
      while(
         end<length &&
         StringGetCharacter(
            json,
            end
         )!=',' &&
         StringGetCharacter(
            json,
            end
         )!='}' &&
         StringGetCharacter(
            json,
            end
         )!='\r' &&
         StringGetCharacter(
            json,
            end
         )!='\n'
      )
      {
         end++;
      }
   }


   if(end<=start)
      return "";


   string value=
      StringSubstr(
         json,
         start,
         end-start
      );


   StringTrimLeft(
      value
   );


   StringTrimRight(
      value
   );


   StringReplace(
      value,
      "\"",
      ""
   );


   return value;
}


//==================================================
// AI TRADE ALLOWED
// Compatibilidade com ValidationEngine antigo
//==================================================

bool AITradeAllowed(
   string symbol=""
)
{
   if(symbol=="")
      symbol=_Symbol;


   if(
      AI_Symbol!=symbol
   )
   {
      if(
         !LoadAIPrediction(
            symbol
         )
      )
      {
         return false;
      }
   }


   if(AI_Signal=="")
      return false;


   if(
      AI_Signal=="HOLD"
   )
   {
      return false;
   }


   if(
      AI_Signal=="BUY"
   )
   {
      return true;
   }


   if(
      AI_Signal=="SELL"
   )
   {
      return true;
   }


   return false;
}


//==================================================
// AI SIGNAL MATCH
//==================================================

bool AIBuyAllowed(
   string symbol=""
)
{
   if(
      symbol==""
   )
   {
      symbol=_Symbol;
   }


   if(
      AI_Symbol!=symbol
   )
   {
      if(
         !LoadAIPrediction(
            symbol
         )
      )
      {
         return false;
      }
   }


   return(
      AI_Signal=="BUY"
   );
}


//==================================================
// AI SELL MATCH
//==================================================

bool AISellAllowed(
   string symbol=""
)
{
   if(
      symbol==""
   )
   {
      symbol=_Symbol;
   }


   if(
      AI_Symbol!=symbol
   )
   {
      if(
         !LoadAIPrediction(
            symbol
         )
      )
      {
         return false;
      }
   }


   return(
      AI_Signal=="SELL"
   );
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


double GetAIConfidence()
{
   return AI_Confidence;
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


//==================================================
// CHECK SYMBOL
//==================================================

bool AIDataForSymbol(
   string symbol
)
{
   if(symbol=="")
      return false;


   return(
      AI_Symbol==symbol
   );
}


#endif