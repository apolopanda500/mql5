#ifndef AICONNECTOR_MQH
#define AICONNECTOR_MQH

//==================================================
// AI CONNECTOR
// XAU_AI_PRO V1.1
// MULTI SYMBOL
//
// RESPONSABILIDADE:
// - Ler prediction_<SYMBOL>.json
// - Validar o símbolo
// - Armazenar os dados da IA
// - Disponibilizar getters
//
// OBS:
// A função AITradeAllowed() NÃO fica aqui.
// Ela pertence ao AIEngine.mqh.
//==================================================


//==================================================
// GLOBAL AI STATE
//==================================================

string AI_Symbol="";
string AI_Signal="";

double AI_Price=0.0;
double AI_BuyProbability=0.0;
double AI_SellProbability=0.0;
double AI_Score=0.0;
double AI_Confidence=0.0;


//==================================================
// RESET AI STATE
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


   //================================================
   // FILE EXISTS
   //================================================

   if(!FileIsExist(fileName))
   {
      Print(
         "AI FILE NOT FOUND | ",
         fileName
      );

      return false;
   }


   //================================================
   // OPEN FILE
   //================================================

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


   //================================================
   // READ JSON
   //================================================

   string json="";


   while(!FileIsEnding(file))
   {
      string line=
         FileReadString(file);

      json+=line;
   }


   FileClose(file);


   //================================================
   // VALIDATE JSON
   //================================================

   if(json=="")
   {
      Print(
         "AI JSON EMPTY | ",
         symbol
      );

      return false;
   }


   //================================================
   // EXTRACT VALUES
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
   // VALIDATE SYMBOL
   //================================================

   if(jsonSymbol=="")
   {
      Print(
         "AI INVALID JSON SYMBOL | ",
         symbol
      );

      return false;
   }


   //================================================
   // VALIDATE SIGNAL
   //================================================

   if(jsonSignal=="")
   {
      Print(
         "AI INVALID JSON SIGNAL | ",
         symbol
      );

      return false;
   }


   //================================================
   // SYMBOL MATCH
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
   // FALLBACK CONFIDENCE
   //================================================

   if(AI_Confidence<=0.0)
      AI_Confidence=
         AI_Score;


   //================================================
   // LOG
   //================================================

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


   //================================================
   // SKIP SPACES
   //================================================

   while(start<length)
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
         ch=='\n'
      )
      {
         start++;
      }
      else
      {
         break;
      }
   }


   //================================================
   // CHECK QUOTED VALUE
   //================================================

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


   //================================================
   // READ VALUE
   //================================================

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
// BUY SIGNAL CHECK
//==================================================

bool AIBuyAllowed(
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


   return(
      AI_Signal=="BUY"
   );
}


//==================================================
// SELL SIGNAL CHECK
//==================================================

bool AISellAllowed(
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


   return(
      AI_Signal=="SELL"
   );
}


//==================================================
// GET AI SIGNAL
//==================================================

string GetAISignal()
{
   return AI_Signal;
}


//==================================================
// GET AI SCORE
//==================================================

double GetAIScore()
{
   return AI_Score;
}


//==================================================
// GET AI CONFIDENCE
//==================================================

double GetAIConfidence()
{
   return AI_Confidence;
}


//==================================================
// GET AI BUY PROBABILITY
//==================================================

double GetAIBuy()
{
   return AI_BuyProbability;
}


//==================================================
// GET AI SELL PROBABILITY
//==================================================

double GetAISell()
{
   return AI_SellProbability;
}


//==================================================
// GET AI PRICE
//==================================================

double GetAIPrice()
{
   return AI_Price;
}


//==================================================
// GET AI SYMBOL
//==================================================

string GetAISymbol()
{
   return AI_Symbol;
}


//==================================================
// CHECK DATA FOR SYMBOL
//==================================================

bool AIDataForSymbol(
   string symbol
)
{
   if(symbol=="")
      return false;


   return(
      AI_Symbol==
      symbol
   );
}


//==================================================
// END
//==================================================

#endif