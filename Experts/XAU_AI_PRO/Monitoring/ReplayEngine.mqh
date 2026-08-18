// XAU_AI_PRO v1.2.0
#ifndef REPLAYENGINE_MQH
#define REPLAYENGINE_MQH

#include "../Core/Config.mqh"
#include "Logger.mqh"

//==================================================
// REPLAY ENGINE — v1.2.0
// Compatível com Dataset.mqh v1.2.0
//==================================================

int  replayHandle   = INVALID_HANDLE;
bool g_replayActive = false;
int  g_replayLine   = 0;

//==================================================
// INIT
//==================================================

bool ReplayEngineInit(
   string datasetFile = "Data\\trades_dataset.csv"
)
{
   // Fechar replay anterior
   if(replayHandle != INVALID_HANDLE)
   {
      FileClose(replayHandle);
      replayHandle = INVALID_HANDLE;
   }

   g_replayActive = false;
   g_replayLine   = 0;

   ResetLastError();

   replayHandle = FileOpen(
      datasetFile,
      FILE_COMMON |
      FILE_READ   |
      FILE_CSV    |
      FILE_ANSI,
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
   // PULAR CABEÇALHO
   //==================================================

   if(!FileIsEnding(replayHandle))
   {
      // O Dataset.mqh possui 20 colunas.
      for(int i = 0; i < 20; i++)
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
// PRÓXIMO REGISTRO
//==================================================

bool ReplayEngineNextLine(
   datetime &recordTime,
   string &symbol,
   ENUM_TIMEFRAMES &timeframe,
   int &signal,
   double &price,
   double &volume,
   double &spread,
   double &atr,
   double &adx,
   double &rsi,
   double &volatility,
   double &trend,
   double &aiScore,
   double &aiProbability,
   double &executionScore,
   double &sl,
   double &tp,
   double &profit,
   bool &result
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
      LogSystem(
         "ReplayEngine: fim do dataset"
      );

      ReplayEngineClose();

      return false;
   }

   //==================================================
   // LEITURA DOS 20 CAMPOS
   //==================================================

   string timeValue =
      FileReadString(replayHandle);

   string symbolValue =
      FileReadString(replayHandle);

   string timeframeValue =
      FileReadString(replayHandle);

   string signalValue =
      FileReadString(replayHandle);

   string priceValue =
      FileReadString(replayHandle);

   string volumeValue =
      FileReadString(replayHandle);

   string spreadValue =
      FileReadString(replayHandle);

   string atrValue =
      FileReadString(replayHandle);

   string adxValue =
      FileReadString(replayHandle);

   string rsiValue =
      FileReadString(replayHandle);

   string volatilityValue =
      FileReadString(replayHandle);

   string trendValue =
      FileReadString(replayHandle);

   string aiScoreValue =
      FileReadString(replayHandle);

   string aiProbabilityValue =
      FileReadString(replayHandle);

   string executionScoreValue =
      FileReadString(replayHandle);

   string slValue =
      FileReadString(replayHandle);

   string tpValue =
      FileReadString(replayHandle);

   string profitValue =
      FileReadString(replayHandle);

   string resultValue =
      FileReadString(replayHandle);

   g_replayLine++;

   //==================================================
   // VALIDAÇÃO
   //==================================================

   if(
      timeValue == "" &&
      symbolValue == "" &&
      timeframeValue == "" &&
      signalValue == ""
   )
   {
      LogWarning(
         "ReplayEngine: registro vazio na linha ",
         IntegerToString(g_replayLine)
      );

      return false;
   }

   //==================================================
   // TIME
   //==================================================

   recordTime =
      StringToTime(timeValue);

   //==================================================
   // SYMBOL
   //==================================================

   symbol =
      symbolValue;

   //==================================================
   // TIMEFRAME
   //==================================================

   timeframe =
      PERIOD_CURRENT;

   if(timeframeValue == "PERIOD_M1")
      timeframe = PERIOD_M1;
   else
   if(timeframeValue == "PERIOD_M2")
      timeframe = PERIOD_M2;
   else
   if(timeframeValue == "PERIOD_M3")
      timeframe = PERIOD_M3;
   else
   if(timeframeValue == "PERIOD_M5")
      timeframe = PERIOD_M5;
   else
   if(timeframeValue == "PERIOD_M10")
      timeframe = PERIOD_M10;
   else
   if(timeframeValue == "PERIOD_M15")
      timeframe = PERIOD_M15;
   else
   if(timeframeValue == "PERIOD_M30")
      timeframe = PERIOD_M30;
   else
   if(timeframeValue == "PERIOD_H1")
      timeframe = PERIOD_H1;
   else
   if(timeframeValue == "PERIOD_H4")
      timeframe = PERIOD_H4;
   else
   if(timeframeValue == "PERIOD_D1")
      timeframe = PERIOD_D1;

   //==================================================
   // NUMERICOS
   //==================================================

   signal =
      (int)StringToInteger(signalValue);

   price =
      StringToDouble(priceValue);

   volume =
      StringToDouble(volumeValue);

   spread =
      StringToDouble(spreadValue);

   atr =
      StringToDouble(atrValue);

   adx =
      StringToDouble(adxValue);

   rsi =
      StringToDouble(rsiValue);

   volatility =
      StringToDouble(volatilityValue);

   trend =
      StringToDouble(trendValue);

   aiScore =
      StringToDouble(aiScoreValue);

   aiProbability =
      StringToDouble(aiProbabilityValue);

   executionScore =
      StringToDouble(executionScoreValue);

   sl =
      StringToDouble(slValue);

   tp =
      StringToDouble(tpValue);

   profit =
      StringToDouble(profitValue);

   //==================================================
   // RESULTADO
   //==================================================

   StringToLower(resultValue);

    result =
   (resultValue == "true" ||
    resultValue == "1");

   return true;
}

//==================================================
// FECHAR REPLAY
//==================================================

void ReplayEngineClose()
{
   if(replayHandle != INVALID_HANDLE)
   {
      FileClose(
         replayHandle
      );

      replayHandle = INVALID_HANDLE;
   }

   g_replayActive = false;
   g_replayLine   = 0;

   LogSystem(
      "ReplayEngine finalizado"
   );
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

//==================================================
// RESET
//==================================================

void ReplayEngineReset()
{
   ReplayEngineClose();

   g_replayLine = 0;

   LogSystem(
      "ReplayEngine resetado"
   );
}

#endif