// XAU_AI_PRO v1.2.0
#ifndef NEWSFILTER_MQH
#define NEWSFILTER_MQH

#include "../Core/Config.mqh"

//==================================================
// NEWS FILTER
// XAU_AI_PRO
// Economic Calendar nativo MQL5
// Config centralizada em Core/Config.mqh:
//   - EnableNewsFilter      (liga/desliga)
//   - NewsImpactThreshold   (1=low, 2=medium, 3=high)
//   - NewsMinutesBefore     (janela antes)
//   - NewsMinutesAfter      (janela depois)
//==================================================

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
   if(!EnableNewsFilter)
   {
      newsBlocked = false;
      return false;
   }

   datetime now = TimeTradeServer();

   if(now <= 0)
      now = TimeCurrent();

   datetime fromTime =
      now - (NewsMinutesAfter * 60);

   datetime toTime =
      now + (NewsMinutesBefore * 60);

   MqlCalendarValue values[];

   ResetLastError();

   int total = CalendarValueHistory(
      values,
      fromTime,
      toTime
   );

   if(total < 0)
   {
      Print(
         "[NEWS] Calendar error | Error=",
         GetLastError()
      );

      // Falha no calendÃ¡rio nÃ£o deve bloquear
      // automaticamente o EA nesta versÃ£o.
      newsBlocked = false;

      return false;
   }

   for(int i = 0; i < total; i++)
   {
      // Impacto do evento
      ENUM_CALENDAR_EVENT_IMPORTANCE impact;

      impact =
         (ENUM_CALENDAR_EVENT_IMPORTANCE)
         values[i].impact_type;

      if((int)impact < NewsImpactThreshold)
         continue;

      datetime eventTime = values[i].time;

      if(
         now >=
         eventTime -
         NewsMinutesBefore * 60
         &&
         now <=
         eventTime +
         NewsMinutesAfter * 60
      )
      {
         newsBlocked = true;

         Print(
            "[NEWS] BLOCK | EventTime=",
            TimeToString(
               eventTime,
               TIME_DATE | TIME_SECONDS
            ),
            " | Impact=",
            IntegerToString((int)impact)
         );

         return true;
      }
   }

   newsBlocked = false;

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
         "[NEWS] TRADE BLOCKED | ",
         _Symbol
      );

      return false;
   }

   return true;
}

//==================================================
// STATUS
//==================================================

bool IsNewsBlocked()
{
   return newsBlocked;
}

//==================================================
// DEBUG
//==================================================

void PrintNewsStatus()
{
   bool blocked = IsNewsTime();

   Print(
      "[NEWS] ",
      _Symbol,
      " | Filter=",
      EnableNewsFilter ? "ON" : "OFF",
      " | Status=",
      blocked ? "BLOCKED" : "CLEAR"
   );
}

#endif