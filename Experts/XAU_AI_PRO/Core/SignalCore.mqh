#ifndef SIGNALCORE_MQH
#define SIGNALCORE_MQH


//==================================================
// SIGNAL CORE
// XAU_AI_PRO
//==================================================


//==================================================
// SIGNAL DO GRÁFICO
//==================================================

int GetSignal()
{

   double fast =
      iMA(
         _Symbol,
         PERIOD_CURRENT,
         50,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );


   double slow =
      iMA(
         _Symbol,
         PERIOD_CURRENT,
         200,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );



   double rsi =
      iRSI(
         _Symbol,
         PERIOD_CURRENT,
         14,
         PRICE_CLOSE
      );



   if(
      fast > slow &&
      rsi < 35
   )
   {

      Print(
         "SIGNAL CORE BUY"
      );

      return 1;

   }



   if(
      fast < slow &&
      rsi > 65
   )
   {

      Print(
         "SIGNAL CORE SELL"
      );

      return -1;

   }



   return 0;

}



//==================================================
// MULTI SYMBOL
//==================================================

int GetSignal(string symbol)
{

   if(symbol=="")
      return 0;



   double fast =
      iMA(
         symbol,
         PERIOD_CURRENT,
         50,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );



   double slow =
      iMA(
         symbol,
         PERIOD_CURRENT,
         200,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );



   double rsi =
      iRSI(
         symbol,
         PERIOD_CURRENT,
         14,
         PRICE_CLOSE
      );



   if(
      fast > slow &&
      rsi < 35
   )
   {

      Print(
         symbol,
         " BUY"
      );


      return 1;

   }



   if(
      fast < slow &&
      rsi > 65
   )
   {

      Print(
         symbol,
         " SELL"
      );


      return -1;

   }



   return 0;

}



#endif