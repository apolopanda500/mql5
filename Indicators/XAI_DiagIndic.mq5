//+------------------------------------------------------------------+
//| XAI_DiagIndic.mq5 - sonda de handles multi-simbolo (v1.0)         |
//| Diagnostico apenas: nao negocia, nao escreve ficheiros, nao       |
//| altera nada. Imprime uma linha por simbolo com o que o terminal   |
//| devolve para iATR/iADX/iRSI criados sobre OUTRO simbolo.          |
//+------------------------------------------------------------------+
#property copyright "XAU_AI_PRO diag"
#property version   "1.000"
#property description "Sonda read-only de leituras multi-simbolo"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_NONE
#property indicator_label1  "diag"

double diagBuf[];

input string SondaSimbolos = "XAUUSD,GBPUSD,USDJPY,USDSEK,USDCNH";
input int    SondaPeriodo  = 14;
input bool   Sonda2Passes  = true;

static int sondaPasses = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, diagBuf, INDICATOR_DATA);
   ArrayInitialize(diagBuf, 0.0);
   Print("[XAIDIAG] INIT | grafico=", _Symbol,
         " | periodo=", EnumToString((ENUM_TIMEFRAMES)_Period),
         " | PERIOD_CURRENT=", (int)PERIOD_CURRENT,
         " | digitos=", _Digits);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void Sondar(const string tag)
{
   string lista[];
   int n = StringSplit(SondaSimbolos, ',', lista);
   for(int i = 0; i < n; i++)
   {
      string s = lista[i];
      StringTrimLeft(s);
      StringTrimRight(s);
      if(s == "")
         continue;

      ResetLastError();
      int hA = iATR(s, PERIOD_CURRENT, SondaPeriodo);
      int errA = GetLastError();
      ResetLastError();
      int hD = iADX(s, PERIOD_CURRENT, SondaPeriodo);
      int errD = GetLastError();
      ResetLastError();
      int hR = iRSI(s, PERIOD_CURRENT, SondaPeriodo, PRICE_CLOSE);
      int errR = GetLastError();

      double a = 0.0, d = 0.0, r = 0.0;
      double b[];
      ArraySetAsSeries(b, true);
      if(hA != INVALID_HANDLE && CopyBuffer(hA, 0, 0, 1, b) > 0)
         a = b[0];
      ArraySetAsSeries(b, true);
      if(hD != INVALID_HANDLE && CopyBuffer(hD, 0, 0, 1, b) > 0)
         d = b[0];
      ArraySetAsSeries(b, true);
      if(hR != INVALID_HANDLE && CopyBuffer(hR, 0, 0, 1, b) > 0)
         r = b[0];

      int bcA = (hA != INVALID_HANDLE ? BarsCalculated(hA) : -1);
      int bcD = (hD != INVALID_HANDLE ? BarsCalculated(hD) : -1);

      Print("[XAIDIAG] ", tag,
            " | sym=", s,
            " | bid=", DoubleToString(SymbolInfoDouble(s, SYMBOL_BID), 6),
            " | atr=", DoubleToString(a, 6),
            " | adx=", DoubleToString(d, 2),
            " | rsi=", DoubleToString(r, 2),
            " | barsSym=", Bars(s, PERIOD_CURRENT),
            " | barsCalcATR=", bcA,
            " | barsCalcADX=", bcD,
            " | hATR=", hA, "/e", errA,
            " | hADX=", hD, "/e", errD,
            " | hRSI=", hR, "/e", errR);

      if(hA != INVALID_HANDLE)
         IndicatorRelease(hA);
      if(hD != INVALID_HANDLE)
         IndicatorRelease(hD);
      if(hR != INVALID_HANDLE)
         IndicatorRelease(hR);
   }
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(!Sonda2Passes && sondaPasses > 0)
      return(rates_total);

   sondaPasses++;
   if(sondaPasses > 2)
      return(rates_total);

   Sondar("pass" + IntegerToString(sondaPasses));
   return(rates_total);
}
//+------------------------------------------------------------------+
