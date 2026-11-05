//+------------------------------------------------------------------+
//| XAI_DiagIndic.mq5                                                |
//| Sonda de leitura: prova se iATR/iADX devolvem o simbolo pedido.  |
//| Nao negocia, nao escreve ficheiros, nao altera o terminal.       |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs
#property version   "1.00"

input string SondaSimbolos = "XAUUSD,EURUSD,USDJPY,USDCHF";   // CSV de simbolos a sondar
input int    SondaPeriodo  = 14;                              // Periodo ATR/ADX

void Snapshot(const string tag, const string symbol)
{
   int hAtr = iATR(symbol, PERIOD_CURRENT, SondaPeriodo);
   int hAdx = iADX(symbol, PERIOD_CURRENT, SondaPeriodo);

   double ab[];
   double xb[];
   ArraySetAsSeries(ab, true);
   ArraySetAsSeries(xb, true);

   int ca = -1;
   int cx = -1;

   if(hAtr != INVALID_HANDLE)
      ca = CopyBuffer(hAtr, 0, 0, 3, ab);

   if(hAdx != INVALID_HANDLE)
      cx = CopyBuffer(hAdx, 0, 0, 1, xb);

   Print("[XAIDIAG] ", tag,
         " | sym=", symbol,
         " | bid=", DoubleToString(SymbolInfoDouble(symbol, SYMBOL_BID), 5),
         " | digits=", (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS),
         " | hATR=", hAtr, " cop=", ca,
         " atr0=", (ca > 0 ? DoubleToString(ab[0], 6) : "n/a"),
         " atr1=", (ca > 1 ? DoubleToString(ab[1], 6) : "n/a"),
         " | hADX=", hAdx, " cop=", cx,
         " adx0=", (cx > 0 ? DoubleToString(xb[0], 2) : "n/a"));

   if(hAtr != INVALID_HANDLE)
      IndicatorRelease(hAtr);

   if(hAdx != INVALID_HANDLE)
      IndicatorRelease(hAdx);
}

void OnStart()
{
   Print("[XAIDIAG] chart | _Symbol=", _Symbol,
         " | period=", EnumToString((ENUM_TIMEFRAMES)_Period),
         " | _Digits=", _Digits,
         " | _Point=", DoubleToString(_Point, 8));

   Snapshot("chart", _Symbol);

   string parts[];
   int n = StringSplit(SondaSimbolos, ',', parts);

   for(int i = 0; i < n; i++)
   {
      string s = parts[i];
      StringTrimLeft(s);
      StringTrimRight(s);

      if(s == "")
         continue;

      Snapshot("lista", s);
   }

   // Segundo par de handles do simbolo do grafico, criado DEPOIS de libertar
   // o primeiro: prova se a reutilizacao de handle troca o simbolo lido.
   Snapshot("chart2", _Symbol);

   Print("[XAIDIAG] FIM");
}
//+------------------------------------------------------------------+
