#ifndef ADAPTIVEWEIGHTS_MQH
#define ADAPTIVEWEIGHTS_MQH


//==================================================
// PESOS GLOBAIS
//==================================================

double wTrend     = 0.30;
double wMomentum  = 0.25;
double wStrength  = 0.20;
double wMarket    = 0.15;
double wExec      = 0.10;


//==================================================
// LIMITADOR
//==================================================

double ClampWeight(double value)
{
   if(value < 0.05)
      return 0.05;

   if(value > 0.60)
      return 0.60;

   return value;
}


//==================================================
// NORMALIZAÇÃO
//==================================================

void NormalizeWeights()
{
   double sum =
      wTrend +
      wMomentum +
      wStrength +
      wMarket +
      wExec;


   if(sum <= 0)
      return;


   wTrend    /= sum;
   wMomentum /= sum;
   wStrength /= sum;
   wMarket   /= sum;
   wExec     /= sum;
}


//==================================================
// AJUSTE DINÂMICO
//==================================================

void AdjustWeights(double winRate)
{

   if(winRate < 40)
   {
      wTrend    += 0.03;
      wMomentum -= 0.01;
   }


   if(winRate < 35)
   {
      wExec   += 0.03;
      wMarket -= 0.02;
   }


   if(winRate > 60)
   {
      wMomentum += 0.02;
      wTrend    -= 0.01;
   }



   // proteção

   wTrend    = ClampWeight(wTrend);
   wMomentum = ClampWeight(wMomentum);
   wStrength = ClampWeight(wStrength);
   wMarket   = ClampWeight(wMarket);
   wExec     = ClampWeight(wExec);



   NormalizeWeights();


   Print(
      "AI WEIGHTS | ",
      "Trend:",DoubleToString(wTrend,2),
      " Momentum:",DoubleToString(wMomentum,2),
      " Strength:",DoubleToString(wStrength,2),
      " Market:",DoubleToString(wMarket,2),
      " Exec:",DoubleToString(wExec,2)
   );
}



#endif