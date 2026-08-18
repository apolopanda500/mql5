#ifndef MARKETSCANNER_MQH
#define MARKETSCANNER_MQH

#include "../Core/Config.mqh"
#include "../Core/SignalCore.mqh"
#include "../Core/ValidationEngine.mqh"
#include "../Core/ExecutionEngine.mqh"
#include "../Core/PositionManager.mqh"
#include "../AI/AIEngine.mqh"

//==================================================
// LATCH DE SINAL v1.2.0
// Evita re-entrada na MESMA vela fechada [1].
// 1 operacao por vela fechada por simbolo.
//==================================================

struct TradedSignal
{
   string   symbol;
   datetime barTime;
};

TradedSignal g_tradedSignals[];

bool AlreadyTradedThisBar(string symbol, datetime barTime)
{
   for(int i = 0; i < ArraySize(g_tradedSignals); i++)
   {
      if(g_tradedSignals[i].symbol == symbol &&
         g_tradedSignals[i].barTime == barTime)
         return true;
   }
   return false;
}

void MarkTradedBar(string symbol, datetime barTime)
{
   for(int i = 0; i < ArraySize(g_tradedSignals); i++)
   {
      if(g_tradedSignals[i].symbol == symbol)
      {
         g_tradedSignals[i].barTime = barTime;
         return;
      }
   }
   int size = ArraySize(g_tradedSignals);
   ArrayResize(g_tradedSignals, size + 1);
   g_tradedSignals[size].symbol = symbol;
   g_tradedSignals[size].barTime = barTime;
}

//==================================================
// PROCESS SYMBOL
//==================================================

void ProcessSymbol(string symbol)
{
   // Log de diagnostico 1x por minuto (evita spam a cada tick)
   static datetime lastLogTime = 0;
   datetime now = TimeCurrent();
   bool logOnce = (now - lastLogTime >= 60);
   if(logOnce)
      lastLogTime = now;

   if(symbol=="")
   {
      if(logOnce)
         Print(
            "[SCANNER] BLOCK | Empty symbol"
         );

      return;
   }


   if(logOnce)
      Print(
         "[SCANNER] START | ",
         symbol
      );


   //================================================
   // POSITION LIMIT
   //================================================

   if(!CanOpenPosition(symbol))
   {
      if(logOnce)
         Print(
            "[SCANNER] BLOCK | CanOpenPosition | ",
            symbol
         );

      return;
   }


   //================================================
   // LATCH v1.2.0 - 1 operacao por vela fechada
   //================================================

   datetime signalBar = iTime(symbol, PERIOD_CURRENT, 1);

   if(signalBar > 0 && AlreadyTradedThisBar(symbol, signalBar))
   {
      if(logOnce)
         Print(
            "[SCANNER] BLOCK | Sinal ja negociado nesta vela | ",
            symbol
         );

      return;
   }

   if(logOnce)
      Print(
         "[SCANNER] POSITION CHECK OK | ",
         symbol
      );


   //================================================
   // SIGNAL
   //================================================

   int signal=
      GetCombinedSignal(
         symbol
      );


   if(signal==0)
   {
      if(logOnce)
         Print(
            "[SCANNER] BLOCK | No Signal | ",
            symbol
         );

      return;
   }


   if(logOnce)
      Print(
         "[SCANNER] SIGNAL OK | ",
         symbol,
         " | Signal=",
         signal
      );


   //================================================
   // VALIDATION
   //================================================

   if(
      !ValidateTrade(
         symbol,
         signal
      )
   )
   {
      if(logOnce)
         Print(
            "[SCANNER] BLOCK | Validation | ",
            symbol,
            " | Signal=",
            signal
         );

      return;
   }


   if(logOnce)
      Print(
         "[SCANNER] VALIDATION OK | ",
         symbol
      );


   //================================================
   // EXECUTION
   //================================================

   if(
      !ExecuteTrade(
         symbol,
         signal
      )
   )
   {
      if(logOnce)
         Print(
            "[SCANNER] BLOCK | Execution Failed | ",
            symbol,
            " | Signal=",
            signal
         );

      return;
   }


   // v1.2.0 - marca a vela como negociada (evita reentrada)
   if(signalBar > 0)
      MarkTradedBar(symbol, signalBar);

   if(logOnce)
      Print(
         "[SCANNER] TRADE SUCCESS | ",
         symbol,
         " | Signal=",
         signal
      );
}

#endif

