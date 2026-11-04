//+------------------------------------------------------------------+
//| XAI_ExportDataset.mq5                                            |
//| Exporta barras M5 para Data\dataset_mt5_<data>.csv               |
//|                                                                  |
//| PORQUE EXISTE: o pipeline Python usa                                |
//| Data\dataset_mt5_20261101.csv com 16 simbolos x 100 000 barras M5. |
//| Esse ficheiro termina em 2026.11.02 01:30; 28 h depois a predicao  |
//| do modelo passa o limite de 900 s do EA e o simbolo cai em        |
//| NoSignal (fail-closed correto). Sem exportacao nova nao ha dado    |
//| fresco para treinar nem para prever.                              |
//|                                                                  |
//| FORMATO (posicional, sem cabecalho, igual ao dataset existente):  |
//| 0=time 1=symbol 2=open 3=high 4=low 5=close 6=tickvol 7=spread    |
//| 8..14 = 0.0 (colunas de reserva do layout antigo)                 |
//|                                                                  |
//| NAO negocia: so le barras e escreve texto.                        |
//+------------------------------------------------------------------+
#property script_show_inputs
#property version   "1.00"
#property description "Exporta barras M5 para Data\\dataset_mt5_<data>.csv"

input string InpSymbols  = "XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH,USDCLP,USDCOP,USDCZK,USDRUB,USDSGD";
input int    InpBars      = 100000;                          // barras por simbolo
input string InpFile      = "Data\\dataset_mt5_20261103.csv"; // destino em MQL5\Files
input bool   InpVerbose   = false;                            // uma linha por simbolo

//+------------------------------------------------------------------+
void OnStart()
{
   string parts[];
   int n = StringSplit(InpSymbols, ',', parts);
   if(n <= 0)
     {
      Print("[EXPORT] lista de simbolos vazia");
      return;
     }

   ResetLastError();
   int h = FileOpen(InpFile, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h == INVALID_HANDLE)
     {
      Print("[EXPORT] ERRO ao abrir ", InpFile, " | code=", GetLastError(),
            " | o caminho e relativo a MQL5\\Files");
      return;
     }

   int totalLinhas = 0;
   int totalSimbolos = 0;
   int falhas = 0;

   for(int i = 0; i < n; i++)
     {
      string sym = parts[i];
      StringTrimLeft(sym);
      StringTrimRight(sym);
      if(sym == "")
         continue;

      if(!SymbolSelect(sym, true))
        {
         Print("[EXPORT] SKIP | ", sym, " | simbolo indisponivel na corretora");
         falhas++;
         continue;
        }

      MqlRates rates[];
      ResetLastError();
      int got = CopyRates(sym, PERIOD_M5, 0, InpBars, rates);
      if(got <= 0)
        {
         Print("[EXPORT] SKIP | ", sym, " | sem barras M5 | code=", GetLastError());
         falhas++;
         continue;
        }

      ArraySetAsSeries(rates, false);
      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(digits <= 0)
         digits = 2;

      for(int k = 0; k < got; k++)
        {
         string linha = TimeToString(rates[k].time, TIME_DATE|TIME_SECONDS) + "," +
                        sym + "," +
                        DoubleToString(rates[k].open,  digits) + "," +
                        DoubleToString(rates[k].high,  digits) + "," +
                        DoubleToString(rates[k].low,   digits) + "," +
                        DoubleToString(rates[k].close, digits) + "," +
                        IntegerToString((long)rates[k].tick_volume) + "," +
                        IntegerToString((int)rates[k].spread) +
                        ",0.0,0.0,0.0,0.0,0.0,0.0,0.0\r\n";
         FileWriteString(h, linha);
        }

      totalLinhas += got;
      totalSimbolos++;
      if(InpVerbose)
         Print("[EXPORT] ", sym, " | barras=", got,
               " | ", TimeToString(rates[0].time, TIME_DATE|TIME_MINUTES),
               " -> ", TimeToString(rates[got-1].time, TIME_DATE|TIME_MINUTES));
     }

   FileClose(h);

   Print("[EXPORT] FIM | simbolos=", totalSimbolos, " | falhas=", falhas,
         " | linhas=", totalLinhas, " | ficheiro=MQL5\\Files\\", InpFile);

   if(totalLinhas == 0)
      Print("[EXPORT] AVISO: nenhuma linha escrita; o dataset antigo NAO foi substituido");
}
//+------------------------------------------------------------------+
