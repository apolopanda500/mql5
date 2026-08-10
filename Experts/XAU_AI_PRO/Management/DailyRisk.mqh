#ifndef DAILYRISK_MQH
#define DAILYRISK_MQH

#include "../Core/Config.mqh"

int dailyTrades = 0;
int lastDayKey = -1;

double dailyStartBalance = 0.0;
bool dailyBlocked = false;

int GetDayKey()
{
MqlDateTime dt;

TimeToStruct(
TimeCurrent(),
dt
);

return(
dt.year * 1000 +
dt.day_of_year
);
}

void InitDailyRisk()
{
dailyStartBalance =
AccountInfoDouble(
ACCOUNT_BALANCE
);

ResetDaily();

PrintFormat(
"[DAILYRISK] dayKey=%d blocked=%s trades=%d/%d lossCheck=%s",
GetDayKey(),
dailyBlocked ? "true" : "false",
dailyTrades,
MaxTradesPerDay,
CheckDailyLossDaily() ? "OK" : "FAIL"
);
}

void ResetDaily()
{
int day = GetDayKey();

if(day != lastDayKey)
{
dailyTrades = 0;
dailyBlocked = false;


  dailyStartBalance =
     AccountInfoDouble(
        ACCOUNT_BALANCE
     );

  lastDayKey = day;


}
}

void RegisterDailyTrade()
{
ResetDaily();

dailyTrades++;
}

double GetDailyLossPercentDaily()
{
if(dailyStartBalance <= 0.0)
return 0.0;

double balance =
AccountInfoDouble(
ACCOUNT_BALANCE
);

double loss =
(
dailyStartBalance -
balance
)
/
dailyStartBalance
*
100.0;

return NormalizeDouble(
loss,
2
);
}

bool CheckDailyLossDaily()
{
double loss =
GetDailyLossPercentDaily();

if(loss >= MaxDailyLossPercent)
{
dailyBlocked = true;


  Print(
     "Daily Loss bloqueado: ",
     DoubleToString(loss, 2),
     "%"
  );

  return false;


}

return true;
}

bool CanTradeToday()
{
ResetDaily();

if(dailyBlocked)
return false;

if(!CheckDailyLossDaily())
return false;

if(dailyTrades >= MaxTradesPerDay)
return false;

return true;
}

void PrintDailyRisk()
{
Print(
"Trades hoje: ",
dailyTrades,
" | Loss diário: ",
DoubleToString(
GetDailyLossPercentDaily(),
2
),
"%"
);
}

#endif
