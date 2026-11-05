//+------------------------------------------------------------------+
//| XAI_AtrDiag.mq5 - sonda de leitura ATR por simbolo (P1.116)       |
//| Reproduz, simbolo a simbolo, as chamadas que GetATR faz:          |
//| SymbolSelect, SymbolIsSynchronized, SERIES_SYNCHRONIZED, Bars(),  |
//| iATR + BarsCalculated + CopyBuffer, e o BID que                   |
//| MarketVolatilityPercent usa como divisor. NAO negoceia.           |
//+------------------------------------------------------------------+
#property copyright   "XAU_AI_PRO diagnostico"
#property version     "1.000"
#property description "Sonda ATR por simbolo. Nao negoceia."

input string InpSymbols  = "XAUUSD;USDCNH;EURUSD;GBPUSD;USDCZK";
input int    InpAtrPeriod = 14;

void Sonda(string symbol)
{
   bool sel  = SymbolSelect(symbol, true);
   bool sync = SymbolIsSynchronized(symbol);

   long seriesSync = 0;
   bool seriesOk = SeriesInfoInteger(symbol, PERIOD_CURRENT, SERIES_SYNCHRONIZED, seriesSync);
   int  barras   = Bars(symbol, PERIOD_CURRENT);

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);

   int h = iATR(symbol, PERIOD_CURRENT, InpAtrPeriod);
   int calculadas = (h == INVALID_HANDLE ? -1 : BarsCalculated(h));

   double b[];
   ArraySetAsSeries(b, true);
   int copiadas = (h == INVALID_HANDLE ? -1 : CopyBuffer(h, 0, 0, 1, b));
   double atr = (copiadas > 0 ? b[0] : 0.0);
   int err = GetLastError();

   double atrPct = (bid > 0.0 ? (atr / bid) * 100.0 : -1.0);

   Print("[ATRDIAG] ", symbol,
         " | sel=", (sel ? "1" : "0"),
         " | syncd=", (sync ? "1" : "0"),
         " | seriesSync=", (seriesOk ? "1" : "0"), "/", seriesSync,
         " | bars=", barras,
         " | bid=", DoubleToString(bid, 5),
         " | ask=", DoubleToString(ask, 5),
         " | handle=", h,
         " | barsCalc=", calculadas,
         " | copy=", copiadas,
         " | atr=", DoubleToString(atr, 6),
         " | atrPct=", DoubleToString(atrPct, 4),
         " | err=", err);

   if(h != INVALID_HANDLE)
      IndicatorRelease(h);
}

void OnStart()
{
   Print("[ATRDIAG] inicio | grafico=", _Symbol,
         " | periodo=", EnumToString((ENUM_TIMEFRAMES)Period()),
         " | digitos=", _Digits);

   string partes[];
   int n = StringSplit(InpSymbols, ';', partes);

   for(int i = 0; i < n; i++)
     {
      string s = partes[i];
      StringTrimLeft(s);
      StringTrimRight(s);
      if(s == "")
         continue;
      Sonda(s);
     }

   Print("[ATRDIAG] fim");
}
//+------------------------------------------------------------------+
