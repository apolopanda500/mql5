#ifndef AIENGINE_MQH
#define AIENGINE_MQH


#include "../Core/Config.mqh"

#include "../Filters/TrendFilter.mqh"
#include "../Filters/SpreadFilter.mqh"

#include "../Indicators/RSI.mqh"
#include "../Indicators/ADX.mqh"
#include "../Indicators/VolatilityFilter.mqh"
#include "../Indicators/TrendStrength.mqh"

#include "../Core/SignalCore.mqh"

#include "AdaptiveWeights.mqh"
#include "AIConnector.mqh"


//==================================================
// PROTOTIPOS
//==================================================

double GetAIConfidence(int signal, string symbol="");
double GetAIVetoThreshold(string symbol="");


//==================================================
// AI FILTER INTERFACE
//==================================================

bool AITradeAllowed(string symbol="")
{

   int signal = GetSignal(symbol);


   if(signal == 0)
      return false;


   double confidence =
      GetAIConfidence(signal, symbol);



   if(confidence < MinAIConfidence)
   {

      Print(
         "AI BLOQUEADO: ",
         DoubleToString(confidence,2),
         " | Symbol=", symbol
      );


      return false;

   }


   // Veto da IA: se a predição do Python contradiz o sinal, bloquear
   if(LoadAIPrediction(symbol))
   {
      if(signal == 1 && AI_Signal == "SELL")
      {
         Print("AI VETO: Python diz SELL mas sinal é BUY | ", symbol);
         return false;
      }

      if(signal == -1 && AI_Signal == "BUY")
      {
         Print("AI VETO: Python diz BUY mas sinal é SELL | ", symbol);
         return false;
      }

      // Se a probabilidade contrária é muito alta, veto
      double contraProb = (signal == 1) ? AI_SellProbability : AI_BuyProbability;
      if(contraProb > 60.0)
      {
         Print("AI VETO: Probabilidade contrária alta (", 
               DoubleToString(contraProb, 2), "%) | ", symbol);
         return false;
      }
   }


   Print(
      "AI APROVADO: ",
      DoubleToString(confidence,2),
      " | Symbol=", symbol
   );


   return true;

}



//==================================================
// CONFIDENCE BASE
//==================================================

double GetAIConfidence(int signal, string symbol="")
{

   if(signal==0)
      return 0;

   if(symbol=="")
      symbol=_Symbol;

   double score = 50.0;

   // Carregar predição do Python
   bool loaded = LoadAIPrediction(symbol);

   if(loaded)
   {
      // Sinal bateu?
      if((signal == 1 && AI_Signal == "BUY") ||
         (signal == -1 && AI_Signal == "SELL"))
      {
         score += 20.0;
      }

      // Score do Python
      score += (AI_Score * 0.40);

      // Probabilidade
      double prob = (signal == 1) ? AI_BuyProbability : AI_SellProbability;
      score += (prob * 0.30);
   }
   else
   {
      // Fallback: heurística local
      if(signal==1 && TrendBuy(symbol))
         score += 15.0;

      if(signal==-1 && TrendSell(symbol))
         score += 15.0;

      double rsi = GetRSI(symbol);
      if(rsi > 30 && rsi < 70)
         score += 10.0;

      if(GetADX(symbol) >= MinimumADX)
         score += 10.0;
   }

   // Limite
   if(score > 100.0)
      score = 100.0;

   return score;

}


//==================================================
// AI VETO THRESHOLD
//==================================================

double GetAIVetoThreshold(string symbol="")
{
   if(symbol=="")
      symbol=_Symbol;

   // Threshold dinâmico baseado em volatilidade
   double atr=GetATR(symbol);
   double atrPoints=0;

   if(atr>0)
   {
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      if(point>0)
         atrPoints=atr/point;
   }

   // Alta volatilidade: threshold maior (mais conservador)
   if(atrPoints>200)
      return 70.0;

   // Volatilidade normal: threshold padrão
   if(atrPoints>50)
      return 60.0;

   // Baixa volatilidade: threshold menor
   return 50.0;
}


//==================================================
// AI LOT ADJUSTMENT
//==================================================

double GetAILotMultiplier(double confidence)
{
   // Ajusta o lote baseado na confiança da IA
   if(confidence >= 80.0)
      return 1.0;   // Confiança alta: lote normal

   if(confidence >= 70.0)
      return 0.75;  // Confiança boa: 75% do lote

   if(confidence >= 60.0)
      return 0.50;  // Confiança média: 50% do lote

   return 0.25;     // Confiança baixa: 25% do lote
}


//==================================================
// AI SIGNAL GENERATOR
// Gera sinal baseado na predição do Python
//==================================================

int GetAISignal(string symbol="")
{
   if(symbol=="")
      symbol=_Symbol;

   if(!LoadAIPrediction(symbol))
      return 0;

   // Score mínimo para gerar sinal
   if(AI_Score < MinAIConfidence)
      return 0;

   // BUY se buy probability > sell probability + margem
   if(AI_BuyProbability > AI_SellProbability + 10.0)
      return 1;

   // SELL se sell probability > buy probability + margem
   if(AI_SellProbability > AI_BuyProbability + 10.0)
      return -1;

   return 0;
}


//==================================================
// AI COMBINED SIGNAL
// Combina sinal técnico com sinal da IA
//==================================================

int GetCombinedSignal(string symbol="")
{
   if(symbol=="")
      symbol=_Symbol;

   int techSignal=GetSignal(symbol);
   int aiSignal=GetAISignal(symbol);

   // Se ambos concordam: sinal forte
   if(techSignal==aiSignal && techSignal!=0)
   {
      Print("AI COMBINED: Técnico e IA concordam | Signal=", techSignal, " | ", symbol);
      return techSignal;
   }

   // Se técnico diz 0 mas IA tem sinal forte (score > 70)
   if(techSignal==0 && aiSignal!=0 && AI_Score > 70.0)
   {
      Print("AI COMBINED: IA gera sinal independente | Signal=", aiSignal, " | ", symbol);
      return aiSignal;
   }

   // Se técnico tem sinal mas IA contradiz: veto
   if(techSignal!=0 && aiSignal!=0 && techSignal!=aiSignal)
   {
      Print("AI COMBINED: IA veta sinal técnico | Tech=", techSignal, " AI=", aiSignal, " | ", symbol);
      return 0;
   }

   // Padrão: usar sinal técnico
   return techSignal;
}


//==================================================
// AI FEEDBACK LOG
// Registra resultado do trade para feedback loop
//==================================================

void LogAIFeedback(string symbol, int signal, double profit, double confidence)
{
   string fileName="Data\\ai_feedback.csv";

   int file=FileOpen(fileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_SHARE_READ|FILE_SHARE_WRITE, ',');

   if(file==INVALID_HANDLE)
      return;

   FileSeek(file, 0, SEEK_END);

   if(FileSize(file)==0)
   {
      FileWrite(file, "Time", "Symbol", "Signal", "Profit", "Confidence", "Result");
   }

   string result = (profit > 0) ? "WIN" : "LOSS";

   FileWrite(file,
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      symbol,
      signal,
      DoubleToString(profit, 2),
      DoubleToString(confidence, 2),
      result
   );

   FileClose(file);
}



#endif
