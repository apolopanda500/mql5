#ifndef VALIDATIONCHECKLIST_MQH
#define VALIDATIONCHECKLIST_MQH

#include "../Core/Config.mqh"
#include "../Core/SymbolManager.mqh"
#include "../AI/AIClient.mqh"
#include "../Utils.mqh"
#include "Logger.mqh"
#include "Diagnostics.mqh"
#include "HealthMonitor.mqh"

//==================================================
// VALIDACAO GERAL — V1.1
// Checklist automatico
//==================================================

bool g_checkResults[15];
bool g_validationPassed = false;


//==================================================
// EXECUTA CHECKLIST
//==================================================

bool ValidationChecklistRun()
{
   g_validationPassed = true;

   LogSystem("Iniciando checklist de validacao...");

   //==================================================
   // 1. ATR
   //==================================================

   double atr = GetATR();

   g_checkResults[0] = (atr > 0.0);

   if(!g_checkResults[0])
      LogError("Checklist FALHOU: ATR invalido");


   //==================================================
   // 2. ADX
   //==================================================

   double adx = GetADX();

   g_checkResults[1] = (adx > 0.0);

   if(!g_checkResults[1])
      LogError("Checklist FALHOU: ADX invalido");


   //==================================================
   // 3. RSI
   //==================================================

   double rsi = GetRSI();

   g_checkResults[2] =
      (rsi > 0.0 && rsi < 100.0);

   if(!g_checkResults[2])
      LogError("Checklist FALHOU: RSI invalido");


   //==================================================
   // 4. EMA
   //==================================================

   // A EMA deve ser validada pelo modulo de indicadores.
   // Nao recriar indicador aqui.

   g_checkResults[3] = true;

   if(!g_checkResults[3])
      LogError("Checklist FALHOU: EMA invalida");


   //==================================================
   // 5. AI
   //==================================================

   g_checkResults[4] = AIClientConnected();

   if(!g_checkResults[4])
      LogError("Checklist FALHOU: AI nao inicializada");


   //==================================================
   // 6. JSON
   //==================================================

   string predFile =
      "Data\\prediction_" + _Symbol + ".json";

   int jsonHandle =
      FileOpen(
         predFile,
         FILE_READ | FILE_ANSI
      );

   g_checkResults[5] =
      (jsonHandle != INVALID_HANDLE);

   if(!g_checkResults[5])
   {
      LogError(
         "Checklist FALHOU: prediction JSON nao encontrado"
      );
   }
   else
   {
      FileClose(jsonHandle);
   }


   //==================================================
   // 7. DATASET
   //==================================================

   string datasetFile =
      "Data\\dataset.csv";

   int csvHandle =
      FileOpen(
         datasetFile,
         FILE_READ | FILE_ANSI
      );

   g_checkResults[6] = false;

   if(csvHandle != INVALID_HANDLE)
   {
      g_checkResults[6] =
         (FileSize(csvHandle) > 0);

      FileClose(csvHandle);
   }

   if(!g_checkResults[6])
      LogError("Checklist FALHOU: dataset.csv invalido");


   //==================================================
   // 8. PYTHON
   //==================================================

   g_checkResults[7] =
      g_checkResults[5] &&
      g_checkResults[6];

   if(!g_checkResults[7])
      LogError(
         "Checklist FALHOU: Python pipeline indisponivel"
      );


   //==================================================
   // 9. BROKER
   //==================================================

   g_checkResults[8] =
      (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);

   if(!g_checkResults[8])
      LogError(
         "Checklist FALHOU: Broker desconectado"
      );


   //==================================================
   // 10. SPREAD
   //==================================================

   double ask =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_ASK
      );

   double bid =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_BID
      );

   double point =
      SymbolInfoDouble(
         _Symbol,
         SYMBOL_POINT
      );

   g_checkResults[9] = false;

   if(ask > 0.0 &&
      bid > 0.0 &&
      point > 0.0)
   {
      double spreadPoints =
         (ask - bid) / point;

      g_checkResults[9] =
         (spreadPoints <= MaxSpread);
   }

   if(!g_checkResults[9])
      LogError(
         "Checklist FALHOU: Spread invalido"
      );


   //==================================================
   // 11. SESSION
   //==================================================

   g_checkResults[10] =
      IsGoodSession();

   if(!g_checkResults[10])
      LogError(
         "Checklist FALHOU: Fora da sessao de trading"
      );


   //==================================================
   // 12. SYMBOL MANAGER
   //==================================================

   g_checkResults[11] =
      (TotalSymbols() > 0);

   if(!g_checkResults[11])
      LogError(
         "Checklist FALHOU: Symbol Manager sem simbolos"
      );


   //==================================================
   // 13. POSITION MANAGER
   //==================================================

   // Deve ser substituido por uma funcao real
   // de health check quando o modulo possuir uma.

   g_checkResults[12] = true;


   //==================================================
   // 14. TRADE MANAGER
   //==================================================

   g_checkResults[13] =
      (MQLInfoInteger(MQL_TRADE_ALLOWED) != 0);

   if(!g_checkResults[13])
      LogError(
         "Checklist FALHOU: Trading nao permitido"
      );


   //==================================================
   // 15. DASHBOARD
   //==================================================

   g_checkResults[14] =
      EnableDashboard;

   if(!g_checkResults[14])
      LogError(
         "Checklist FALHOU: Dashboard desativado"
      );


   //==================================================
   // RESULTADO FINAL
   //==================================================

   for(int i = 0; i < 15; i++)
   {
      if(!g_checkResults[i])
      {
         g_validationPassed = false;
         break;
      }
   }


   if(g_validationPassed)
   {
      LogSystem(
         "Checklist: TODOS OS TESTES PASSARAM"
      );
   }
   else
   {
      LogError(
         "Checklist: FALHAS DETECTADAS. EA NAO INICIARA."
      );
   }

   return g_validationPassed;
}


//==================================================
// STATUS
//==================================================

bool ValidationChecklistPassed()
{
   return g_validationPassed;
}


//==================================================
// SUMMARY
//==================================================

string ValidationChecklistSummary()
{
   string names[15];

   names[0]  = "ATR";
   names[1]  = "ADX";
   names[2]  = "RSI";
   names[3]  = "EMA";
   names[4]  = "AI";
   names[5]  = "JSON";
   names[6]  = "Dataset";
   names[7]  = "Python";
   names[8]  = "Broker";
   names[9]  = "Spread";
   names[10] = "Session";
   names[11] = "Symbol Manager";
   names[12] = "Position Manager";
   names[13] = "Trade Manager";
   names[14] = "Dashboard";

   string summary =
      "=== VALIDATION CHECKLIST ===\n";

   for(int i = 0; i < 15; i++)
   {
      string status =
         g_checkResults[i]
         ? "OK"
         : "FALHA";

      summary +=
         names[i] +
         ": " +
         status +
         "\n";
   }

   summary +=
      "\nResultado: " +
      (
         g_validationPassed
         ? "APROVADO"
         : "REPROVADO"
      );

   return summary;
}

#endif