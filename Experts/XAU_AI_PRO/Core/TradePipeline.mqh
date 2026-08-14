#ifndef TRADEPIPELINE_MQH
#define TRADEPIPELINE_MQH

#include "../Core/SymbolManager.mqh"
#include "../Core/MarketScanner.mqh"

//==================================================
// TRADE PIPELINE
// XAU_AI_PRO
// MULTI SYMBOL + DIAGNOSTIC
//==================================================

void RunTradePipeline()
{
   int total=
      TotalSymbols();

   Print(
      "[PIPELINE] INICIO | Symbols=",
      total
   );

   if(total<=0)
   {
      Print(
         "[PIPELINE] BLOQUEADO | Nenhum símbolo configurado"
      );

      return;
   }


   for(int i=0; i<total; i++)
   {
      string symbol=
         GetTradeSymbol(i);

      if(symbol=="")
      {
         Print(
            "[PIPELINE] Symbol vazio | Index=",
            i
         );

         continue;
      }


      Print(
         "[PIPELINE] PROCESSANDO | Index=",
         i,
         " | Symbol=",
         symbol
      );


      if(!SymbolSelect(symbol,true))
      {
         Print(
            "[PIPELINE] BLOQUEADO | SymbolSelect | ",
            symbol,
            " | Error=",
            GetLastError()
         );

         continue;
      }


      ProcessSymbol(symbol);
   }


   Print(
      "[PIPELINE] FINALIZADO"
   );
}


//==================================================
// PROCESS SINGLE SYMBOL
//==================================================

bool RunTradePipelineSymbol(
   string symbol
)
{
   if(symbol=="")
      return false;


   if(!SymbolSelect(symbol,true))
   {
      Print(
         "[PIPELINE] SymbolSelect falhou | ",
         symbol,
         " | Error=",
         GetLastError()
      );

      return false;
   }


   ProcessSymbol(symbol);

   return true;
}

#endif