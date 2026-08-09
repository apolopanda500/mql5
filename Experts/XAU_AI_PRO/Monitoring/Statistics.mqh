#ifndef STATISTICS_MQH
#define STATISTICS_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"

//==================================================
// XAU_AI_PRO — STATISTICS ENGINE V2.0
// Estatísticas diárias, semanais e mensais
//==================================================

datetime g_statsDayStart   = 0;
datetime g_statsWeekStart  = 0;
datetime g_statsMonthStart = 0;

int g_statsTodayTrades = 0;
int g_statsWeekTrades  = 0;
int g_statsMonthTrades = 0;
int g_statsTotalTrades = 0;

int g_currentWinStreak  = 0;
int g_currentLossStreak = 0;
int g_maxWinStreak      = 0;
int g_maxLossStreak     = 0;

double g_statsTodayProfit = 0.0;
double g_statsWeekProfit  = 0.0;
double g_statsMonthProfit = 0.0;
double g_statsTotalProfit = 0.0;

double g_statsTodayLoss = 0.0;
double g_statsWeekLoss  = 0.0;
double g_statsMonthLoss = 0.0;
double g_statsTotalLoss = 0.0;

//==================================================
// CALCULA INICIO DO DIA
//==================================================

datetime StatisticsGetDayStart(datetime value)
{
   MqlDateTime dt;

   if(!TimeToStruct(value, dt))
      return 0;

   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;

   return StructToTime(dt);
}

//==================================================
// CALCULA INICIO DA SEMANA
// Segunda-feira = 0
//==================================================

datetime StatisticsGetWeekStart(datetime value)
{
   MqlDateTime dt;

   if(!TimeToStruct(value, dt))
      return 0;

   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;

   datetime dayStart = StructToTime(dt);

   int daysFromMonday = dt.day_of_week - 1;

   if(daysFromMonday < 0)
      daysFromMonday = 6;

   return dayStart - (daysFromMonday * 86400);
}

//==================================================
// CALCULA INICIO DO MES
//==================================================

datetime StatisticsGetMonthStart(datetime value)
{
   MqlDateTime dt;

   if(!TimeToStruct(value, dt))
      return 0;

   dt.day  = 1;
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;

   return StructToTime(dt);
}

//==================================================
// INIT
//==================================================

bool StatisticsInit()
{
   datetime now = TimeCurrent();

   g_statsDayStart =
      StatisticsGetDayStart(now);

   g_statsWeekStart =
      StatisticsGetWeekStart(now);

   g_statsMonthStart =
      StatisticsGetMonthStart(now);

   LogSystem(
      "Statistics inicializado"
   );

   return true;
}

//==================================================
// ATUALIZA PERIODOS
//==================================================

void StatisticsUpdateTimeframes()
{
   datetime now = TimeCurrent();

   datetime newDayStart =
      StatisticsGetDayStart(now);

   datetime newWeekStart =
      StatisticsGetWeekStart(now);

   datetime newMonthStart =
      StatisticsGetMonthStart(now);

   //================================================
   // NOVO DIA
   //================================================

   if(newDayStart != g_statsDayStart)
   {
      g_statsTodayTrades = 0;
      g_statsTodayProfit = 0.0;
      g_statsTodayLoss   = 0.0;

      g_statsDayStart =
         newDayStart;

      LogSystem(
         "Statistics: novo dia iniciado"
      );
   }

   //================================================
   // NOVA SEMANA
   //================================================

   if(newWeekStart != g_statsWeekStart)
   {
      g_statsWeekTrades = 0;
      g_statsWeekProfit = 0.0;
      g_statsWeekLoss   = 0.0;

      g_statsWeekStart =
         newWeekStart;

      LogSystem(
         "Statistics: nova semana iniciada"
      );
   }

   //================================================
   // NOVO MES
   //================================================

   if(newMonthStart != g_statsMonthStart)
   {
      g_statsMonthTrades = 0;
      g_statsMonthProfit = 0.0;
      g_statsMonthLoss   = 0.0;

      g_statsMonthStart =
         newMonthStart;

      LogSystem(
         "Statistics: novo mes iniciado"
      );
   }
}

//==================================================
// REGISTRA TRADE
//==================================================

void StatisticsRegisterTrade(double profit)
{
   StatisticsUpdateTimeframes();

   //================================================
   // CONTADORES
   //================================================

   g_statsTotalTrades++;
   g_statsTodayTrades++;
   g_statsWeekTrades++;
   g_statsMonthTrades++;

   //================================================
   // WIN
   //================================================

   if(profit > 0.0)
   {
      g_statsTotalProfit += profit;
      g_statsTodayProfit += profit;
      g_statsWeekProfit  += profit;
      g_statsMonthProfit += profit;

      g_currentWinStreak++;
      g_currentLossStreak = 0;

      if(g_currentWinStreak > g_maxWinStreak)
         g_maxWinStreak =
            g_currentWinStreak;
   }

   //================================================
   // LOSS
   //================================================

   else if(profit < 0.0)
   {
      double loss =
         MathAbs(profit);

      g_statsTotalLoss += loss;
      g_statsTodayLoss += loss;
      g_statsWeekLoss  += loss;
      g_statsMonthLoss += loss;

      g_currentLossStreak++;
      g_currentWinStreak = 0;

      if(g_currentLossStreak > g_maxLossStreak)
         g_maxLossStreak =
            g_currentLossStreak;
   }

   LogTrade(
      "Statistics trade registrado",
      (profit > 0.0 ? "WIN" : "LOSS"),
      DoubleToString(profit, 2)
   );
}

//==================================================
// TRADES
//==================================================

int StatsTodayTrades()
{
   return g_statsTodayTrades;
}

int StatsWeekTrades()
{
   return g_statsWeekTrades;
}

int StatsMonthTrades()
{
   return g_statsMonthTrades;
}

int StatsTotalTrades()
{
   return g_statsTotalTrades;
}

//==================================================
// PROFIT
//==================================================

double StatsTodayProfit()
{
   return g_statsTodayProfit;
}

double StatsWeekProfit()
{
   return g_statsWeekProfit;
}

double StatsMonthProfit()
{
   return g_statsMonthProfit;
}

double StatsTotalProfit()
{
   return g_statsTotalProfit;
}

//==================================================
// LOSS
//==================================================

double StatsTodayLoss()
{
   return g_statsTodayLoss;
}

double StatsWeekLoss()
{
   return g_statsWeekLoss;
}

double StatsMonthLoss()
{
   return g_statsMonthLoss;
}

double StatsTotalLoss()
{
   return g_statsTotalLoss;
}

//==================================================
// NET
//==================================================

double StatsTodayNet()
{
   return
      g_statsTodayProfit -
      g_statsTodayLoss;
}

double StatsWeekNet()
{
   return
      g_statsWeekProfit -
      g_statsWeekLoss;
}

double StatsMonthNet()
{
   return
      g_statsMonthProfit -
      g_statsMonthLoss;
}

double StatsTotalNet()
{
   return
      g_statsTotalProfit -
      g_statsTotalLoss;
}

//==================================================
// WIN STREAK
//==================================================

int StatsCurrentWinStreak()
{
   return g_currentWinStreak;
}

int StatsCurrentLossStreak()
{
   return g_currentLossStreak;
}

int StatsMaxWinStreak()
{
   return g_maxWinStreak;
}

int StatsMaxLossStreak()
{
   return g_maxLossStreak;
}

//==================================================
// SUMMARY
//==================================================

string StatisticsSummary()
{
   StatisticsUpdateTimeframes();

   string summary =
      "=== ESTATISTICAS ===\n";

   summary +=
      "--- Hoje ---\n";

   summary +=
      "Trades: " +
      IntegerToString(g_statsTodayTrades) +
      "\n";

   summary +=
      "Profit: " +
      DoubleToString(g_statsTodayProfit, 2) +
      "\n";

   summary +=
      "Loss: " +
      DoubleToString(g_statsTodayLoss, 2) +
      "\n";

   summary +=
      "Net: " +
      DoubleToString(StatsTodayNet(), 2) +
      "\n\n";

   summary +=
      "--- Semana ---\n";

   summary +=
      "Trades: " +
      IntegerToString(g_statsWeekTrades) +
      "\n";

   summary +=
      "Profit: " +
      DoubleToString(g_statsWeekProfit, 2) +
      "\n";

   summary +=
      "Loss: " +
      DoubleToString(g_statsWeekLoss, 2) +
      "\n";

   summary +=
      "Net: " +
      DoubleToString(StatsWeekNet(), 2) +
      "\n\n";

   summary +=
      "--- Mes ---\n";

   summary +=
      "Trades: " +
      IntegerToString(g_statsMonthTrades) +
      "\n";

   summary +=
      "Profit: " +
      DoubleToString(g_statsMonthProfit, 2) +
      "\n";

   summary +=
      "Loss: " +
      DoubleToString(g_statsMonthLoss, 2) +
      "\n";

   summary +=
      "Net: " +
      DoubleToString(StatsMonthNet(), 2) +
      "\n\n";

   summary +=
      "--- Total ---\n";

   summary +=
      "Trades: " +
      IntegerToString(g_statsTotalTrades) +
      "\n";

   summary +=
      "Profit: " +
      DoubleToString(g_statsTotalProfit, 2) +
      "\n";

   summary +=
      "Loss: " +
      DoubleToString(g_statsTotalLoss, 2) +
      "\n";

   summary +=
      "Net: " +
      DoubleToString(StatsTotalNet(), 2) +
      "\n\n";

   summary +=
      "Sequencia atual WIN: " +
      IntegerToString(g_currentWinStreak) +
      "\n";

   summary +=
      "Sequencia atual LOSS: " +
      IntegerToString(g_currentLossStreak) +
      "\n";

   summary +=
      "Maior sequencia WIN: " +
      IntegerToString(g_maxWinStreak) +
      "\n";

   summary +=
      "Maior sequencia LOSS: " +
      IntegerToString(g_maxLossStreak) +
      "\n";

   return summary;
}

//==================================================
// RESET
//==================================================

void StatisticsReset()
{
   g_statsTodayTrades = 0;
   g_statsWeekTrades  = 0;
   g_statsMonthTrades = 0;
   g_statsTotalTrades = 0;

   g_statsTodayProfit = 0.0;
   g_statsWeekProfit  = 0.0;
   g_statsMonthProfit = 0.0;
   g_statsTotalProfit = 0.0;

   g_statsTodayLoss = 0.0;
   g_statsWeekLoss  = 0.0;
   g_statsMonthLoss = 0.0;
   g_statsTotalLoss = 0.0;

   g_currentWinStreak  = 0;
   g_currentLossStreak = 0;
   g_maxWinStreak      = 0;
   g_maxLossStreak     = 0;

   StatisticsInit();

   LogSystem(
      "Statistics resetadas"
   );
}

#endif