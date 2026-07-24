#ifndef __CONFIG_MQH__
#define __CONFIG_MQH__

input double Lote = 0.01;

input int StopLoss = 300;
input int TakeProfit = 600;

input int EMA_Fast = 50;
input int EMA_Slow = 200;

input int RSI_Period = 14;
input int ATR_Period = 14;

input ulong Magic = 20260629;

input bool UsarTrailing = true;
input bool UsarBreakEven = true;

input int MaxSpread = 30;

#endif