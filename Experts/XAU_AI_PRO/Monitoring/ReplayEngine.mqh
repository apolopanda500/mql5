#ifndef REPLAYENGINE_MQH
#define REPLAYENGINE_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"

//==================================================
// REPLAY ENGINE — V1.1
// Reproduz dataset CSV para validação
//==================================================

int replayHandle = INVALID_HANDLE;
bool g_replayActive = false;
int g_replayLine = 0;

//==================================================
// INICIALIZA REPLAY
//==================================================

bool ReplayEngineInit(string datasetFile = "dataset.csv")
{
   // Fecha handle anterior
   if(replayHandle != INVALID_HANDLE)
   {
      FileClose(replayHandle);
      replayHandle = INVALID_HANDLE;
   }

   g_replayActive = false;
   g_replayLine = 0;

   ResetLastError();

   replayHandle = FileOpen(
      datasetFile,
      FILE_COMMON | FILE_READ | FILE_CSV | FILE_ANSI,
      ','
   );

   if(replayHandle == INVALID_HANDLE)
   {
      LogError(
         "ReplayEngine: falha ao abrir dataset. Erro: ",
         IntegerToString(GetLastError())
      );

      return false;
   }

   //==================================================
   // PULA CABEÇALHO
   //==================================================

   if(!FileIsEnding(replayHandle))
   {
      // Como o arquivo é CSV, precisamos consumir
      // os campos do cabeçalho.
      for(int i = 0; i < 8; i++)
      {
         if(FileIsEnding(replayHandle))
            break;

         FileReadString(replayHandle);
      }

      g_replayLine = 1;
   }

   g_replayActive = true;

   LogSystem(
      "ReplayEngine inicializado. Dataset: ",
      datasetFile
   );

   return true;
}

//==================================================
// LE PRÓXIMA LINHA DO DATASET
//==================================================

bool ReplayEngineNextLine(
   double &rsi,
   double &adx,
   double &atr,
   double &emaFast,
   double &emaSlow,
   double &aiScore,
   double &profit
)
{
   if(replayHandle == INVALID_HANDLE)
      return false;

   if(!g_replayActive)
      return false;

   //==================================================
   // FIM DO ARQUIVO
   //==================================================

   if(FileIsEnding(replayHandle))
   {
      LogSystem("ReplayEngine: fim do dataset");

      ReplayEngineClose();

      return false;
   }

   //==================================================
   // FORMATO ESPERADO
   //
   // Time
   // RSI
   // ADX
   // ATR
   // EMA_Fast
   // EMA_Slow
   // AI_Score
   // Profit
   //==================================================

   string timeValue   = FileReadString(replayHandle);
   string rsiValue    = FileReadString(replayHandle);
   string adxValue    = FileReadString(replayHandle);
   string atrValue    = FileReadString(replayHandle);
   string emaFastValue = FileReadString(replayHandle);
   string emaSlowValue = FileReadString(replayHandle);
   string aiScoreValue = FileReadString(replayHandle);
   string profitValue  = FileReadString(replayHandle);

   g_replayLine++;

   //==================================================
   // VALIDAÇÃO BÁSICA
   //==================================================

   if(timeValue == "" &&
      rsiValue == "" &&
      adxValue == "" &&
      atrValue == "" &&
      emaFastValue == "" &&
      emaSlowValue == "" &&
      aiScoreValue == "" &&
      profitValue == "")
   {
      LogWarning(
         "ReplayEngine: linha vazia: ",
         IntegerToString(g_replayLine)
      );

      return false;
   }

   //==================================================
   // CONVERSÃO
   //==================================================

   rsi     = StringToDouble(rsiValue);
   adx     = StringToDouble(adxValue);
   atr     = StringToDouble(atrValue);
   emaFast = StringToDouble(emaFastValue);
   emaSlow = StringToDouble(emaSlowValue);
   aiScore = StringToDouble(aiScoreValue);
   profit  = StringToDouble(profitValue);

   //==================================================
   // VALIDAÇÃO DOS DADOS
   //==================================================

   if(rsi < 0.0 ||
      adx < 0.0 ||
      atr < 0.0)
   {
      LogWarning(
         "ReplayEngine: dados inválidos na linha ",
         IntegerToString(g_replayLine)
      );

      return false;
   }

   return true;
}

//==================================================
// FECHA REPLAY
//==================================================

void ReplayEngineClose()
{
   if(replayHandle != INVALID_HANDLE)
   {
      FileClose(replayHandle);
      replayHandle = INVALID_HANDLE;
   }

   g_replayActive = false;
   g_replayLine = 0;

   LogSystem("ReplayEngine finalizado");
}

//==================================================
// STATUS
//==================================================

bool ReplayEngineIsActive()
{
   return g_replayActive;
}

//==================================================
// LINHA ATUAL
//==================================================

int ReplayEngineCurrentLine()
{
   return g_replayLine;
}

#endif