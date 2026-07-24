#ifndef NEWSFILTER_MQH
#define NEWSFILTER_MQH


#include "../Core/Config.mqh"

//==================================================
// NEWS FILTER
//==================================================


//==================================================
// CONFIG
//==================================================

input int NewsBlockMinutesBefore = 30;
input int NewsBlockMinutesAfter  = 30;


//==================================================
// ESTADO
//==================================================

datetime lastNewsCheck = 0;
bool newsBlocked = false;


//==================================================
// CHECK NEWS
//==================================================

bool IsNewsTime()
{

   // modo seguro:
   // sem API/calendário conectado
   // mantém operações liberadas


   if(!EnableNewsFilter)
      return false;



   /*
      FUTURO:

      - Economic Calendar MQL5
      - Python bridge
      - JSON API
      - Webhook

   */


   return false;

}



//==================================================
// NEWS STATUS
//==================================================

bool NewsFilterActive()
{

   if(!EnableNewsFilter)
      return false;


   return IsNewsTime();

}



//==================================================
// FINAL PERMISSION
//==================================================

bool CanTradeNews()
{

   if(!EnableNewsFilter)
      return true;



   if(IsNewsTime())
   {

      Print(
         "NEWS FILTER: Operação bloqueada"
      );


      return false;

   }



   return true;

}



//==================================================
// DEBUG
//==================================================

void PrintNewsStatus()
{

   Print(
      "NEWS FILTER: ",
      NewsFilterActive()
      ?
      "BLOCKED"
      :
      "CLEAR"
   );

}



#endif
