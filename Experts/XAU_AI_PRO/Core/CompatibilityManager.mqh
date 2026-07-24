#ifndef COMPATIBILITYMANAGER_MQH
#define COMPATIBILITYMANAGER_MQH

#include "BrokerInfo.mqh"
#include "BrokerConfig.mqh"
#include "SymbolManager.mqh"
#include "PathManager.mqh"
#include "EnvironmentManager.mqh"
#include "TimeFrameManager.mqh"

//==================================================
// COMPATIBILITY MANAGER
//==================================================

bool InitCompatibility()
{

   Print("========================================");
   Print("XAU_AI_PRO COMPATIBILITY CHECK");
   Print("========================================");

   if(!InitBrokerInfo())
      return false;

   if(!InitEnvironment())
      return false;

   if(!InitPathManager())
      return false;

   if(!InitTimeFrames())
      return false;

   LoadBrokerSymbols();

   if(!InitSymbolManager())
   {
      Print("ERRO SymbolManager");
      return false;
   }

   Print("----------------------------------------");
   Print("Broker     : ",GetBrokerName());
   Print("Servidor   : ",GetBrokerServer());
   Print("Símbolos   : ",TotalSymbols());
   Print("Entrada TF : ",TimeFrameToString(GetEntryTF()));
   Print("Trend TF   : ",TimeFrameToString(GetTrendTF()));
   Print("Filtro TF  : ",TimeFrameToString(GetFilterTF()));
   Print("----------------------------------------");

   Print("Compatibility OK");

   return true;

}

#endif