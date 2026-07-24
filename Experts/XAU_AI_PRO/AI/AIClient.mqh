#ifndef AICLIENT_MQH
#define AICLIENT_MQH


#include "../Core/Config.mqh"

#include "../Indicators/ADX.mqh"
#include "../Indicators/RSI.mqh"


//==================================================
// AI CLIENT
//==================================================

//====================================================
// AI CLIENT
//====================================================


//====================================================
// ESTADO DA CONEXÃO
//====================================================

bool AIClientConnected()
{
   return false;
}


//====================================================
// USO DE IA EXTERNA
//====================================================

bool UseExternalAI()
{
   return false;
}


//====================================================
// REQUEST IA EXTERNA
//====================================================

double RequestExternalAIConfidence(int signal)
{
   if(!AIClientConnected())
      return -1.0;

   return -1.0;
}


//====================================================
// REQUEST SINAL IA EXTERNA
//====================================================

int RequestExternalAISignal()
{
   if(!AIClientConnected())
      return 0;

   return 0;
}


//====================================================
// IA LOCAL FALLBACK
//====================================================

double GetLocalAIFallback(int signal)
{

   double score = 50.0;


   double adx = GetADX();
   double rsi = GetRSI();



   // força da tendência

   if(adx >= 18)
      score += 15;
   else
      score -= 10;



   // BUY

   if(signal == 1)
   {
      if(rsi > 30 && rsi < 70)
         score += 10;

      if(rsi >= 70)
         score -= 10;
   }



   // SELL

   if(signal == -1)
   {
      if(rsi > 30 && rsi < 70)
         score += 10;

      if(rsi <= 30)
         score -= 10;
   }



   // limite

   if(score > 100)
      score = 100;


   if(score < 0)
      score = 0;



   Print(
      "LOCAL AI SCORE: ",
      DoubleToString(score,2),
      " Signal: ",
      signal
   );


   return NormalizeDouble(score,2);
}



//====================================================
// INIT
//====================================================

void AIClientInit()
{
   Print("AI Client iniciado - modo local fallback");
}



//====================================================
// SHUTDOWN
//====================================================

void AIClientShutdown()
{
   Print("AI Client finalizado");
}


#endif
