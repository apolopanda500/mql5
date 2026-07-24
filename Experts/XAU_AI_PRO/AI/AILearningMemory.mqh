#ifndef AILEARNINGMEMORY_MQH
#define AILEARNINGMEMORY_MQH


//==================================================
// MEMÓRIA IA
//==================================================

double lastConfidence = 0;
double lastSignalStrength = 0;


//==================================================
// LIMITADOR
//==================================================

double ClampMemory(double value)
{
   if(value > 20)
      return 20;

   if(value < -20)
      return -20;

   return value;
}


//==================================================
// REGISTRA EXPERIÊNCIA
//==================================================

void StoreExperience(
   int signal,
   double confidence,
   bool result
)
{

   lastConfidence = confidence;


   if(result)
      lastSignalStrength += 1;

   else
      lastSignalStrength -= 1;


   lastSignalStrength =
      ClampMemory(lastSignalStrength);


   Print(
      "AI MEMORY | Confidence:",
      DoubleToString(lastConfidence,2),
      " Strength:",
      DoubleToString(lastSignalStrength,2)
   );
}



//==================================================
// BOOST DA MEMÓRIA
//==================================================

double MemoryBoost()
{

   if(lastSignalStrength >= 10)
      return 1.15;


   if(lastSignalStrength >= 5)
      return 1.08;


   if(lastSignalStrength <= -10)
      return 0.80;


   if(lastSignalStrength <= -5)
      return 0.90;


   return 1.0;
}



//==================================================
// APLICA MEMÓRIA NA IA
//==================================================

double ApplyMemoryBoost(double score)
{

   double boosted =
      score * MemoryBoost();


   if(boosted > 100)
      boosted = 100;


   if(boosted < 0)
      boosted = 0;


   return boosted;
}



#endif