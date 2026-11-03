//+------------------------------------------------------------------+
//| XAI_DiagSignal.mq5 - MEDICAO (nao altera o EA)                   |
//| Responde: a regra do GetSignal (EMA50/EMA200 + RSI pullback)     |
//| dispara em H1 nos 11 simbolos? Quantas vezes nas ultimas 24 h?   |
//| Grava o resultado no journal (Experts) e em Files\Temp CSVs.     |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

input string SymbolsList = "XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH";
input int    FastEMA     = 50;
input int    SlowEMA     = 200;
input int    RSIPeriod   = 14;
input double RSIPullBuy  = 45.0;
input double RSIPullSell = 55.0;
input int    BarsToEval  = 24;    // ultimas N velas H1 fechadas

//+------------------------------------------------------------------+
double EmaAt(const double &close[], int idx, int period)
  {
   // close[] em serie: idx 0 = vela mais recente
   int n = ArraySize(close);
   if(idx < 0 || idx + period >= n + 1) return 0.0;
   // EMA classica: comeca com SMA em (idx+period-1) e avanca para idx
   int startBar = idx + period - 1;
   if(startBar > n - 1) return 0.0;
   double sum = 0.0;
   for(int k = 0; k < period; k++) sum += close[startBar - k];
   double ema = sum / period;
   double k2  = 2.0 / (period + 1.0);
   for(int b = startBar - 1; b >= idx; b--)
      ema = close[b] * k2 + ema * (1.0 - k2);
   return ema;
  }

double RsiAt(const double &close[], int idx, int period)
  {
   int need = idx + period + 1;
   if(need > ArraySize(close) - 1) return 0.0;
   double gain = 0.0, loss = 0.0;
   for(int k = 1; k <= period; k++)
     {
      double d = close[idx + k - 1] - close[idx + k];
      if(d > 0) gain += d; else loss -= d;
     }
   gain /= period; loss /= period;
   for(int b = idx + period; b >= idx + 1; b--)
     {
      double d = close[b - 1] - close[b];
      double g = (d > 0 ? d : 0.0);
      double l = (d < 0 ? -d : 0.0);
      gain = (gain * (period - 1) + g) / period;
      loss = (loss * (period - 1) + l) / period;
     }
   if(loss <= 0.0) return 100.0;
   double rs = gain / loss;
   return 100.0 - 100.0 / (1.0 + rs);
  }

//+------------------------------------------------------------------+
void OnStart()
  {
   string syms[];
   int n = StringSplit(SymbolsList, ',', syms);

   Print("[DIAGSIG] INICIO | simbolos=", n, " | EMA ", FastEMA, "/", SlowEMA,
         " | RSI ", RSIPeriod, " | pullback ", DoubleToString(RSIPullBuy,1), "/",
         DoubleToString(RSIPullSell,1), " | velas=", BarsToEval);

   for(int s = 0; s < n; s++)
     {
      string sym = syms[s];
      StringTrimLeft(sym);
      StringTrimRight(sym);
      if(sym == "") continue;

      if(!SymbolSelect(sym, true))
        {
         Print("[DIAGSIG] ", sym, " | SymbolSelect FALHOU");
         continue;
        }

      int bars = Bars(sym, PERIOD_H1);
      if(bars < SlowEMA + 10)
        {
         Print("[DIAGSIG] ", sym, " | BARRAS H1 INSUFICIENTES = ", bars);
         continue;
        }

      double close[];
      int need = SlowEMA + BarsToEval + 10;
      int copied = CopyClose(sym, PERIOD_H1, 0, need, close);
      if(copied <= 0)
        {
         Print("[DIAGSIG] ", sym, " | CopyClose FALHOU err=", GetLastError());
         continue;
        }
      ArraySetAsSeries(close, true);

      int buyHits = 0, sellHits = 0;
      int trendUp = 0, trendDown = 0;

      for(int i = 1; i <= BarsToEval; i++)
        {
         double f = EmaAt(close, i, FastEMA);
         double sl = EmaAt(close, i, SlowEMA);
         double r1 = RsiAt(close, i, RSIPeriod);
         double r2 = RsiAt(close, i + 1, RSIPeriod);
         if(f <= 0.0 || sl <= 0.0 || r1 <= 0.0 || r2 <= 0.0) continue;

         if(f > sl) trendUp++; else trendDown++;

         if(f > sl && r1 < RSIPullBuy && r1 > r2) buyHits++;
         if(f < sl && r1 > RSIPullSell && r1 < r2) sellHits++;
        }

      double f1 = EmaAt(close, 1, FastEMA);
      double s1 = EmaAt(close, 1, SlowEMA);
      double r1v = RsiAt(close, 1, RSIPeriod);
      double r2v = RsiAt(close, 2, RSIPeriod);

      Print("[DIAGSIG] ", sym,
            " | barsH1=", bars,
            " | EMA", FastEMA, "=", DoubleToString(f1, 5),
            " | EMA", SlowEMA, "=", DoubleToString(s1, 5),
            " | fast>slow=", (f1 > s1 ? "SIM" : "NAO"),
            " | RSI[1]=", DoubleToString(r1v, 2),
            " | RSI[2]=", DoubleToString(r2v, 2),
            " | BUYrule=", (f1 > s1 && r1v < RSIPullBuy && r1v > r2v ? "SIM" : "NAO"),
            " | SELLrule=", (f1 < s1 && r1v > RSIPullSell && r1v < r2v ? "SIM" : "NAO"),
            " | velas24h: up=", trendUp, " down=", trendDown,
            " BUYhits=", buyHits, " SELLhits=", sellHits);
     }

   Print("[DIAGSIG] FIM");
  }
//+------------------------------------------------------------------+
