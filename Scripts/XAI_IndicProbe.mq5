//+------------------------------------------------------------------+
//| XAI_IndicProbe.mq5                                               |
//| Sonda de diagnostico: le ATR/ADX/RSI por simbolo e compara com o |
//| preco do proprio simbolo, para provar (ou refutar) contaminacao   |
//| entre simbolos na leitura dos indicadores.                        |
//| SOMENTE LEITURA: nao envia, altera ou cancela ordens.            |
//+------------------------------------------------------------------+
#property copyright "XAU_AI_PRO diagnostic"
#property version   "1.00"
#property script_show_inputs
#property strict

input string InpSymbols  = "XAUUSD,GBPUSD,USDJPY,AUDUSD,USDSEK,USDCNH"; // Simbolos (virgula)
input int    InpATRPeriod = 14;   // ATR
input int    InpADXPeriod = 14;   // ADX
input int    InpRSIPeriod = 14;   // RSI
input int    InpWaitMs    = 2500; // Espera maxima por aquecimento

//+------------------------------------------------------------------+
string TrimBoth(string s)
{
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
}

//+------------------------------------------------------------------+
void Probe(string symbol)
{
   if(!SymbolSelect(symbol, true))
   {
      Print("[PROBE] ", symbol, " | SymbolSelect FALHOU");
      return;
   }

   int    bars  = Bars(symbol, PERIOD_CURRENT);
   double bid   = SymbolInfoDouble(symbol, SYMBOL_BID);
   int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits <= 0) digits = _Digits;

   int hATR = iATR(symbol, PERIOD_CURRENT, InpATRPeriod);
   int hADX = iADX(symbol, PERIOD_CURRENT, InpADXPeriod);
   int hRSI = iRSI(symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);

   int bcA = -1, bcD = -1, bcR = -1;
   int waited = 0;
   while(waited < InpWaitMs)
   {
      bcA = (hATR == INVALID_HANDLE ? -1 : BarsCalculated(hATR));
      bcD = (hADX == INVALID_HANDLE ? -1 : BarsCalculated(hADX));
      bcR = (hRSI == INVALID_HANDLE ? -1 : BarsCalculated(hRSI));
      if(bcA > 0 && bcD > 0 && bcR > 0)
         break;
      Sleep(50);
      waited += 50;
   }

   double atr = 0.0, adx = 0.0, rsi = 0.0;
   double b[];

   if(hATR != INVALID_HANDLE && CopyBuffer(hATR, 0, 0, 1, b) > 0) atr = b[0];
   if(hADX != INVALID_HANDLE && CopyBuffer(hADX, 0, 0, 1, b) > 0) adx = b[0];
   if(hRSI != INVALID_HANDLE && CopyBuffer(hRSI, 0, 0, 1, b) > 0) rsi = b[0];

   double atrPct = (bid > 0.0 ? (atr / bid) * 100.0 : -1.0);

   Print("[PROBE] ", symbol,
         " | bars=", bars,
         " | bid=", DoubleToString(bid, digits),
         " | ATR=", DoubleToString(atr, 6),
         " | ATR%=", DoubleToString(atrPct, 4),
         " | ADX=", DoubleToString(adx, 2),
         " | RSI=", DoubleToString(rsi, 2),
         " | BarsCalc A/D/R=", bcA, "/", bcD, "/", bcR,
         " | H A/D/R=", hATR, "/", hADX, "/", hRSI);

   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hADX != INVALID_HANDLE) IndicatorRelease(hADX);
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
}

//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== XAI_INDIC_PROBE | chart=", _Symbol,
         " | chartTF=", EnumToString((ENUM_TIMEFRAMES)Period()),
         " | build=", TerminalInfoInteger(TERMINAL_BUILD), " ===");

   // Referencia: o simbolo do grafico, lido primeiro.
   Probe(_Symbol);

   string parts[];
   int n = StringSplit(InpSymbols, ',', parts);
   for(int i = 0; i < n; i++)
   {
      string s = TrimBoth(parts[i]);
      if(s == "")
         continue;
      Probe(s);
   }

   Print("=== XAI_INDIC_PROBE FIM ===");
}
//+------------------------------------------------------------------+
