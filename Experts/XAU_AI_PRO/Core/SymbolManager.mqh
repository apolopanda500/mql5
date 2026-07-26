#ifndef SYMBOLMANAGER_MQH
#define SYMBOLMANAGER_MQH

#include "../Core/Config.mqh"

//==================================================
// SYMBOL STORAGE
//==================================================

string ActiveSymbols[];

//==================================================
// RESOLVE BROKER SYMBOL
//==================================================

string ResolveBrokerSymbol(string symbol)
{
   StringTrimLeft(symbol);
   StringTrimRight(symbol);

   // Strip trailing "c" suffix to normalize symbols like "XAUUSDc" -> "XAUUSD"
   // so they enter the correct broker-mapping branch below
   string baseSymbol = symbol;
   int len = StringLen(baseSymbol);
   if(len > 1 && StringGetCharacter(baseSymbol, len - 1) == 'c')
   {
      baseSymbol = StringSubstr(baseSymbol, 0, len - 1);
   }

   string candidates[];
   ArrayResize(candidates,12);

   candidates[0]=symbol;
   candidates[1]=symbol+"c";
   candidates[2]=symbol+".";
   candidates[3]=symbol+"#";

   if(baseSymbol=="XAUUSD")
   {
      candidates[4]="GOLD";
      candidates[5]="GOLD#";
      candidates[6]="XAUUSDm";
      candidates[7]="XAUUSDmicro";
      candidates[8]="XAUUSD.pro";
      candidates[9]="XAUUSD_i";
      candidates[10]="XAUUSD.cash";
      candidates[11]="XAUUSD.r";
   }
   else
   if(baseSymbol=="BTCUSD")
   {
      candidates[4]="BTCUSD#";
      candidates[5]="BTCUSDc";
      candidates[6]="BTCUSDm";
      candidates[7]="BTCUSD.";
      candidates[8]="BTCUSD.pro";
      candidates[9]="BTCUSD_i";
      candidates[10]="BTCUSD.cash";
      candidates[11]="BTCUSD.r";
   }
   else
   {
      candidates[4]=symbol+"m";
      candidates[5]=symbol+"micro";
      candidates[6]=symbol+"_i";
      candidates[7]=symbol+"pro";
      candidates[8]=symbol+".";
      candidates[9]=symbol+"#";
      candidates[10]=symbol+".cash";
      candidates[11]=symbol+".r";
   }

   for(int i=0;i<ArraySize(candidates);i++)
   {
      if(candidates[i]=="")
         continue;

      if(SymbolSelect(candidates[i],true))
      {
         Print(
            "Broker Symbol: ",
            symbol,
            " -> ",
            candidates[i]
         );

         return candidates[i];
      }
   }

   int total=SymbolsTotal(true);

   for(int i=0;i<total;i++)
   {
      string broker=SymbolName(i,true);

      if(StringFind(broker,symbol)>=0)
      {
         SymbolSelect(broker,true);

         Print(
            "Broker Symbol Auto: ",
            symbol,
            " -> ",
            broker
         );

         return broker;
      }
   }

   Print(
      "Símbolo não encontrado: ",
      symbol
   );

   return "";
}

//==================================================
// INIT
//==================================================

bool InitSymbolManager()
{
   ArrayResize(ActiveSymbols,0);

   if(!EnableMultiSymbol)
   {
      ArrayResize(ActiveSymbols,1);
      ActiveSymbols[0]=ResolveBrokerSymbol(_Symbol);

      if(ActiveSymbols[0]=="")
         ActiveSymbols[0]=_Symbol;

      return true;
   }

   string temp[];

   int count=
      StringSplit(
         Symbols,
         ',',
         temp
      );

   if(count<=0)
   {
      ArrayResize(ActiveSymbols,1);
      ActiveSymbols[0]=ResolveBrokerSymbol(_Symbol);

      if(ActiveSymbols[0]=="")
         ActiveSymbols[0]=_Symbol;

      return true;
   }

    for(int i=0;i<count;i++)
    {
       string symbol=
          ResolveBrokerSymbol(
             temp[i]
          );

       if(symbol=="")
          continue;

       int size=
          ArraySize(
             ActiveSymbols
          );

       ArrayResize(
          ActiveSymbols,
          size+1
       );

       ActiveSymbols[size]=symbol;

       Print(
          "ATIVO REGISTRADO: ",
          symbol
       );
    }

    // Fallback: if no symbols resolved, use _Symbol
    // This prevents INIT_FAILED in Strategy Tester when
    // broker symbol suffixes don't match the Symbols list
    if(ArraySize(ActiveSymbols)==0)
    {
       ArrayResize(ActiveSymbols,1);
       ActiveSymbols[0]=_Symbol;
       Print(
          "FALLBACK: No symbols resolved, using _Symbol: ",
          _Symbol
       );
    }

    return true;
}

//==================================================
// TOTAL
//==================================================

int TotalSymbols()
{
   return ArraySize(ActiveSymbols);
}

//==================================================
// GET SYMBOL
//==================================================

string GetTradeSymbol(int index)
{
   if(index<0 || index>=ArraySize(ActiveSymbols))
      return "";

   return ActiveSymbols[index];
}

//==================================================
// RELEASE
//==================================================

void ReleaseSymbolManager()
{
   ArrayFree(ActiveSymbols);
}

#endif
