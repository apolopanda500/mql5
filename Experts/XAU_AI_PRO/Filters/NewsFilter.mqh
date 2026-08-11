#ifndef NEWSFILTER_MQH
#define NEWSFILTER_MQH

#include "../Core/Config.mqh"

//==================================================
// NEWS FILTER
// XAU_AI_PRO
// Economic Calendar nativo MQL5
//==================================================

input int NewsBlockMinutesBefore = 30;
input int NewsBlockMinutesAfter  = 30;

// 0 = baixo
// 1 = médio
// 2 = alto
input int NewsMinimumImpact = 2;

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
      now - (NewsBlockMinutesAfter * 60);

   datetime toTime =
      now + (NewsBlockMinutesBefore * 60);

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

      // Falha no calendário não deve bloquear
      // automaticamente o EA nesta versão.
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

      if((int)impact < NewsMinimumImpact)
         continue;

      datetime eventTime = values[i].time;

      if(
         now >=
         eventTime -
         NewsBlockMinutesBefore * 60
         &&
         now <=
         eventTime +
         NewsBlockMinutesAfter * 60
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