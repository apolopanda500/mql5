//+------------------------------------------------------------------+
//| XAI_AtrDiag.mq5 - sonda de leitura ATR por simbolo (P1.116)       |
//| Reproduz, simbolo a simbolo, as chamadas que GetATR faz:          |
//| SymbolSelect, SymbolIsSynchronized, SERIES_SYNCHRONIZED, Bars(),  |
//| iATR + BarsCalculated + CopyBuffer, e o BID que                   |
//| MarketVolatilityPercent usa como divisor. NAO negoceia.           |
//|                                                                  |
//| v1.010 (05/11/2026) - P1.119: acrescenta a IDENTIDADE do handle.  |
//| A primeira parte responde "o dado existe?"; a segunda responde    |
//| "de QUEM e a serie que o handle serve?" - cria um handle por      |
//| simbolo, calcula o ATR de referencia sem indicador (Wilder a      |
//| partir de CopyRates) e compara. E ainda: pede o handle outra vez  |
//| para o mesmo simbolo e para outro, para provar se o terminal      |
//| devolve o MESMO inteiro (deduplicacao) ou um handle novo.         |
//+------------------------------------------------------------------+
#property copyright   "XAU_AI_PRO diagnostico"
#property version     "1.010"
#property description "Sonda ATR por simbolo e de identidade do handle. Nao negoceia."

input string InpSymbols   = "XAUUSD;USDCNH;EURUSD;GBPUSD;USDCZK";
input int    InpAtrPeriod = 14;
input int    InpRefBars   = 400;   // barras para o ATR de referencia

#define AHD_MAX        64
#define AHD_ESPERA_MS  25
#define AHD_TENTATIVAS 40

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

//+------------------------------------------------------------------+
//| ATR de referencia (Wilder) calculado SEM indicador.              |
//| indice 0 = barra corrente (incompleta); o valor final usa a barra|
//| 1 como ultima barra fechada, a mesma que CopyBuffer(0,0,1) le.   |
//+------------------------------------------------------------------+
double RefATR(string symbol, ENUM_TIMEFRAMES tf, int period, int bars, int digits)
{
   if(bars < period + 10)
      bars = period + 10;

   MqlRates r[];
   ArraySetAsSeries(r, true);

   int copiadas = CopyRates(symbol, tf, 0, bars, r);
   if(copiadas < period + 3)
      return -1.0;

   int n = copiadas - 1;
   double tr[];
   ArrayResize(tr, n);

   for(int i = 0; i < n; i++)
     {
      double alto  = r[i].high;
      double baixo = r[i].low;
      double fecho = r[i + 1].close;
      double a = alto - baixo;
      double b = MathAbs(alto - fecho);
      double c = MathAbs(baixo - fecho);
      tr[i] = MathMax(a, MathMax(b, c));
     }

   int maisAntiga = n - 1;
   double atr = 0.0;
   for(int i = 0; i < period; i++)
      atr += tr[maisAntiga - i];
   atr /= period;

   for(int i = maisAntiga - period; i >= 0; i--)
      atr = (atr * (period - 1) + tr[i]) / period;

   return NormalizeDouble(atr, digits);
}

//+------------------------------------------------------------------+
//| Le um handle com insistencia curta: o MT5 calcula em assincrono. |
//+------------------------------------------------------------------+
double LerHandle(int h, int &barsCalc, int &copiadas, int &erro)
{
   double b[];
   ArraySetAsSeries(b, true);

   barsCalc = -1;
   copiadas = -1;
   erro     = 0;

   if(h == INVALID_HANDLE)
      return -1.0;

   for(int t = 0; t < AHD_TENTATIVAS; t++)
     {
      copiadas = CopyBuffer(h, 0, 0, 1, b);
      erro     = GetLastError();
      barsCalc = (int)BarsCalculated(h);
      if(copiadas > 0)
         return b[0];
      Sleep(AHD_ESPERA_MS);
     }

   return -1.0;
}

//+------------------------------------------------------------------+
//| P1.119 - de QUEM e a serie que o handle serve.                   |
//+------------------------------------------------------------------+
void SondaIdentidade(string &syms[], int total)
{
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();
   int periodo = InpAtrPeriod;

   Print("[AHD] inicio | grafico=", _Symbol,
         " | tf=", EnumToString(tf),
         " | periodo=", periodo,
         " | barrasGrafico=", Bars(_Symbol, tf),
         " | build=", TerminalInfoInteger(TERMINAL_BUILD),
         " | simbolos=", total);

   int    h1[AHD_MAX];
   double v1[AHD_MAX];
   double ref[AHD_MAX];
   int    bc1[AHD_MAX];
   int    cp1[AHD_MAX];
   int    er1[AHD_MAX];

   //--- PASSO A: um handle por simbolo, na ordem da lista -------------
   for(int i = 0; i < total; i++)
     {
      string sym = syms[i];
      SymbolSelect(sym, true);

      h1[i] = iATR(sym, tf, periodo);
      v1[i] = LerHandle(h1[i], bc1[i], cp1[i], er1[i]);

      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      ref[i] = RefATR(sym, tf, periodo, InpRefBars, digits);

      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double pct = (bid > 0.0 && v1[i] > 0.0) ? (v1[i] / bid) * 100.0 : -1.0;

      Print("[AHD] A", IntegerToString(i, 2, '0'), " | ", sym,
            " | handle=", h1[i],
            " | barsCalc=", bc1[i],
            " | barsSerie=", Bars(sym, tf),
            " | copiadas=", cp1[i],
            " | erro=", er1[i],
            " | atrHandle=", DoubleToString(v1[i], 8),
            " | atrRef=", DoubleToString(ref[i], 8),
            " | bid=", DoubleToString(bid, digits),
            " | atrPct=", DoubleToString(pct, 4));
     }

   //--- PASSO B: compara o valor de cada handle com a referencia de
   //--- TODOS os simbolos. Igualar a referencia de outro par significa
   //--- que a serie servida nao e a pedida.
   for(int i = 0; i < total; i++)
     {
      if(v1[i] <= 0.0)
        {
         Print("[AHD] B", IntegerToString(i, 2, '0'), " | ", syms[i],
               " | sem valor lido (atrHandle<=0) - nada a comparar");
         continue;
        }

      int    melhor = -1;
      double melhorDif = 0.0;

      for(int j = 0; j < total; j++)
        {
         if(ref[j] <= 0.0)
            continue;
         double dif = MathAbs(v1[i] - ref[j]) / ref[j];
         if(melhor < 0 || dif < melhorDif)
           {
            melhor    = j;
            melhorDif = dif;
           }
        }

      string veredicto = "indeterminado";
      if(melhor >= 0)
        {
         if(melhorDif <= 0.00005)
            veredicto = (melhor == i ? "PROPRIA serie" : "SERIE DE " + syms[melhor]);
         else
            veredicto = "nenhuma referencia (dif minimo " + DoubleToString(melhorDif * 100.0, 4) + "%)";
        }

      Print("[AHD] B", IntegerToString(i, 2, '0'), " | ", syms[i],
            " | atrHandle=", DoubleToString(v1[i], 8),
            " | melhorCandidato=", (melhor >= 0 ? syms[melhor] : "?"),
            " | dif=", DoubleToString(melhorDif * 100.0, 5), "%",
            " | veredicto=", veredicto);
     }

   //--- PASSO C: o terminal devolve o MESMO inteiro para outro par? ---
   if(total > 0)
     {
      int hMesmo = iATR(syms[0], tf, periodo);
      Print("[AHD] C1 | mesmo simbolo ", syms[0],
            " | handle1=", h1[0],
            " | handle2=", hMesmo,
            " | igual=", (hMesmo == h1[0] ? "SIM" : "NAO"),
            " | barsCalc2=", (hMesmo == INVALID_HANDLE ? -1 : (int)BarsCalculated(hMesmo)));
     }

   if(total > 1)
     {
      int hOutro = iATR(syms[1], tf, periodo);
      Print("[AHD] C2 | outro simbolo ", syms[1],
            " | handle=", hOutro,
            " | handle1(", syms[0], ")=", h1[0],
            " | igual=", (hOutro == h1[0] ? "SIM" : "NAO"),
            " | barsCalc=", (hOutro == INVALID_HANDLE ? -1 : (int)BarsCalculated(hOutro)),
            " | barsCalc1=", bc1[0]);
     }

   if(total > 2)
     {
      int hTerceiro = iATR(syms[2], tf, periodo);
      Print("[AHD] C3 | terceiro simbolo ", syms[2],
            " | handle=", hTerceiro,
            " | igualAoPrimeiro=", (hTerceiro == h1[0] ? "SIM" : "NAO"),
            " | igualAoAnterior=", (hTerceiro == h1[2] ? "SIM" : "NAO"),
            " | barsCalc=", (hTerceiro == INVALID_HANDLE ? -1 : (int)BarsCalculated(hTerceiro)));
     }

   //--- PASSO D: a deduplicacao inclui os parametros? ----------------
   if(total > 0)
     {
      int hPeriodo = iATR(syms[0], tf, periodo + 1);
      int bcP, cpP, erP;
      double vP = LerHandle(hPeriodo, bcP, cpP, erP);
      Print("[AHD] D1 | ", syms[0],
            " | periodo=", periodo + 1,
            " | handle=", hPeriodo,
            " | igualAoDe14=", (hPeriodo == h1[0] ? "SIM" : "NAO"),
            " | barsCalc=", bcP,
            " | atr=", DoubleToString(vP, 8));
     }

   //--- PASSO E: o simbolo do grafico, criado por ULTIMO --------------
   {
      int hGrafico = iATR(_Symbol, tf, periodo);
      int bcG, cpG, erG;
      double vG = LerHandle(hGrafico, bcG, cpG, erG);
      int digitsG = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double refG = RefATR(_Symbol, tf, periodo, InpRefBars, digitsG);

      Print("[AHD] E1 | grafico=", _Symbol,
            " | handle=", hGrafico,
            " | barsCalc=", bcG,
            " | barsSerie=", Bars(_Symbol, tf),
            " | copiadas=", cpG,
            " | erro=", erG,
            " | atrHandle=", DoubleToString(vG, 8),
            " | atrRef=", DoubleToString(refG, 8));
     }

   Print("[AHD] fim");
}

void OnStart()
{
   Print("[ATRDIAG] inicio | grafico=", _Symbol,
         " | periodo=", EnumToString((ENUM_TIMEFRAMES)Period()),
         " | digitos=", _Digits);

   string partes[];
   int n = StringSplit(InpSymbols, ';', partes);

   string limpos[AHD_MAX];
   int total = 0;

   for(int i = 0; i < n; i++)
     {
      string s = partes[i];
      StringTrimLeft(s);
      StringTrimRight(s);
      if(s == "")
         continue;

      Sonda(s);

      if(total < AHD_MAX)
        {
         limpos[total] = s;
         total++;
        }
     }

   Print("[ATRDIAG] fim | simbolos=", total);

   //--- P1.119: identidade do handle, com os mesmos simbolos ---------
   if(total > 0)
      SondaIdentidade(limpos, total);
}
//+------------------------------------------------------------------+
